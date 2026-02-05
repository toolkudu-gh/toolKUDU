import { Router, Request, Response, NextFunction } from 'express';
import { query, queryOne, queryReturning } from '../db';
import { requireUser } from '../middleware/auth';
import { badRequest, notFound, forbidden, conflict } from '../middleware/errorHandler';
import { isValidUUID, isValidTrackerType, VALID_TRACKER_TYPES } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { ToolTracker, TrackerResponse } from '../models/types';

export const locationRoutes = Router();

// Check if user owns tool via toolbox
async function checkToolOwnership(
  toolId: string,
  userId: string
): Promise<{ tool_id: string; tool_name: string; toolbox_id: string } | null> {
  return queryOne<{ tool_id: string; tool_name: string; toolbox_id: string }>(
    `SELECT t.id as tool_id, t.name as tool_name, t.toolbox_id
     FROM tools t
     INNER JOIN toolboxes tb ON tb.id = t.toolbox_id
     WHERE t.id = $1 AND tb.user_id = $2`,
    [toolId, userId]
  );
}

// Convert DB tracker to response
function toTrackerResponse(tracker: ToolTracker, toolName: string): TrackerResponse {
  return {
    id: tracker.id,
    toolId: tracker.tool_id,
    toolName,
    trackerType: tracker.tracker_type,
    trackerIdentifier: tracker.tracker_identifier,
    trackerName: tracker.tracker_name,
    location:
      tracker.last_latitude !== null && tracker.last_longitude !== null
        ? {
            latitude: parseFloat(tracker.last_latitude.toString()),
            longitude: parseFloat(tracker.last_longitude.toString()),
            accuracy: tracker.last_location_accuracy
              ? parseFloat(tracker.last_location_accuracy.toString())
              : null,
          }
        : null,
    lastSeen: tracker.last_seen,
    isActive: tracker.is_active,
    createdAt: tracker.created_at,
  };
}

// GET /api/trackers - Get all trackers for current user's tools
locationRoutes.get('/', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await query<ToolTracker & { tool_name: string }>(
      `SELECT tt.*, t.name as tool_name
       FROM tool_trackers tt
       INNER JOIN tools t ON t.id = tt.tool_id
       INNER JOIN toolboxes tb ON tb.id = t.toolbox_id
       WHERE tb.user_id = $1 AND tt.is_active = true
       ORDER BY tt.last_seen DESC NULLS LAST`,
      [req.userId]
    );

    const trackers = result.rows.map((t) => toTrackerResponse(t, t.tool_name));

    res.json(trackers);
  } catch (error) {
    next(error);
  }
});

// GET /api/tools/:id/location - Get location of a specific tool
locationRoutes.get('/tools/:id/location', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolId } = req.params;

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    const ownership = await checkToolOwnership(toolId, req.userId!);
    if (!ownership) {
      throw forbidden('You do not own this tool');
    }

    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1 AND is_active = true',
      [toolId]
    );

    if (!tracker) {
      throw notFound('No active tracker on this tool');
    }

    res.json(toTrackerResponse(tracker, ownership.tool_name));
  } catch (error) {
    next(error);
  }
});

// POST /api/tools/:id/tracker - Add tracker to a tool
locationRoutes.post('/tools/:id/tracker', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolId } = req.params;
    const { trackerType, trackerIdentifier, trackerName } = req.body;

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    if (!trackerType || !trackerIdentifier) {
      throw badRequest('trackerType and trackerIdentifier are required');
    }

    if (!isValidTrackerType(trackerType)) {
      throw badRequest(`Invalid tracker type. Valid types: ${VALID_TRACKER_TYPES.join(', ')}`);
    }

    const ownership = await checkToolOwnership(toolId, req.userId!);
    if (!ownership) {
      throw forbidden('You do not own this tool');
    }

    // Check for existing tracker
    const existingTracker = await queryOne(
      'SELECT 1 FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );
    if (existingTracker) {
      throw conflict('Tool already has a tracker. Remove it first.');
    }

    const tracker = await queryReturning<ToolTracker>(
      `INSERT INTO tool_trackers (tool_id, tracker_type, tracker_identifier, tracker_name)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [toolId, trackerType, trackerIdentifier, trackerName || null]
    );

    if (!tracker) {
      throw badRequest('Failed to add tracker');
    }

    res.status(201).json(toTrackerResponse(tracker, ownership.tool_name));
  } catch (error) {
    next(error);
  }
});

// PUT /api/tools/:id/tracker - Update tracker location
locationRoutes.put('/tools/:id/tracker', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolId } = req.params;
    const { latitude, longitude, accuracy } = req.body;

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    if (latitude === undefined || longitude === undefined) {
      throw badRequest('latitude and longitude are required');
    }

    if (latitude < -90 || latitude > 90) {
      throw badRequest('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw badRequest('Longitude must be between -180 and 180');
    }

    const ownership = await checkToolOwnership(toolId, req.userId!);
    if (!ownership) {
      throw forbidden('You do not own this tool');
    }

    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1 AND is_active = true',
      [toolId]
    );

    if (!tracker) {
      throw notFound('No active tracker on this tool');
    }

    // Update tracker
    await query(
      `UPDATE tool_trackers
       SET last_latitude = $1, last_longitude = $2, last_location_accuracy = $3, last_seen = CURRENT_TIMESTAMP
       WHERE id = $4`,
      [latitude, longitude, accuracy || null, tracker.id]
    );

    // Add to location history
    await query(
      `INSERT INTO location_history (tracker_id, latitude, longitude, accuracy)
       VALUES ($1, $2, $3, $4)`,
      [tracker.id, latitude, longitude, accuracy || null]
    );

    res.json({
      message: 'Location updated',
      location: { latitude, longitude, accuracy },
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/tools/:id/tracker - Remove tracker from tool
locationRoutes.delete('/tools/:id/tracker', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolId } = req.params;

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    const ownership = await checkToolOwnership(toolId, req.userId!);
    if (!ownership) {
      throw forbidden('You do not own this tool');
    }

    const result = await query(
      'DELETE FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );

    if (result.rowCount === 0) {
      throw notFound('No tracker found on this tool');
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// GET /api/tools/:id/location/history - Get location history
locationRoutes.get('/tools/:id/location/history', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolId } = req.params;
    const { page, pageSize, offset } = getPagination(req, 50);

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    const ownership = await checkToolOwnership(toolId, req.userId!);
    if (!ownership) {
      throw forbidden('You do not own this tool');
    }

    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );

    if (!tracker) {
      throw notFound('No tracker on this tool');
    }

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM location_history WHERE tracker_id = $1',
      [tracker.id]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<{
      latitude: number;
      longitude: number;
      accuracy: number | null;
      recorded_at: Date;
    }>(
      `SELECT latitude, longitude, accuracy, recorded_at
       FROM location_history
       WHERE tracker_id = $1
       ORDER BY recorded_at DESC
       LIMIT $2 OFFSET $3`,
      [tracker.id, pageSize, offset]
    );

    const history = result.rows.map((h) => ({
      latitude: parseFloat(h.latitude.toString()),
      longitude: parseFloat(h.longitude.toString()),
      accuracy: h.accuracy ? parseFloat(h.accuracy.toString()) : null,
      recordedAt: h.recorded_at,
    }));

    res.json(paginate(history, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});
