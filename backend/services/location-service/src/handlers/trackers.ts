import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  query,
  queryOne,
  queryReturning,
  authenticate,
  success,
  created,
  noContent,
  badRequest,
  notFound,
  forbidden,
  conflict,
  serverError,
  paginated,
  parseBody,
  getPathParam,
  getQueryParamInt,
  isValidUUID,
  validateRequired,
  formatValidationErrors,
} from '@toolkudu/shared';
import {
  ToolTracker,
  TrackerResponse,
  LocationHistory,
  LocationHistoryResponse,
  AddTrackerInput,
  UpdateLocationInput,
  TrackerType,
} from '../models/tracker';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

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

// Get all trackers for current user's tools
export async function getTrackers(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const result = await query<ToolTracker & { tool_name: string }>(
      `SELECT tt.*, t.name as tool_name
       FROM tool_trackers tt
       INNER JOIN tools t ON t.id = tt.tool_id
       INNER JOIN toolboxes tb ON tb.id = t.toolbox_id
       WHERE tb.user_id = $1 AND tt.is_active = true
       ORDER BY tt.last_seen DESC NULLS LAST`,
      [currentUserId]
    );

    const trackers: TrackerResponse[] = result.rows.map((t) => ({
      id: t.id,
      toolId: t.tool_id,
      toolName: t.tool_name,
      trackerType: t.tracker_type,
      trackerIdentifier: t.tracker_identifier,
      trackerName: t.tracker_name,
      location:
        t.last_latitude !== null && t.last_longitude !== null
          ? {
              latitude: parseFloat(t.last_latitude.toString()),
              longitude: parseFloat(t.last_longitude.toString()),
              accuracy: t.last_location_accuracy
                ? parseFloat(t.last_location_accuracy.toString())
                : null,
            }
          : null,
      lastSeen: t.last_seen,
      isActive: t.is_active,
      createdAt: t.created_at,
    }));

    return success(trackers);
  } catch (error) {
    console.error('Error getting trackers:', error);
    return serverError('Failed to get trackers');
  }
}

// Get location of a specific tool
export async function getToolLocation(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const ownership = await checkToolOwnership(toolId, currentUserId);
    if (!ownership) {
      return forbidden('You do not own this tool');
    }

    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1 AND is_active = true',
      [toolId]
    );

    if (!tracker) {
      return notFound('No active tracker on this tool');
    }

    const response: TrackerResponse = {
      id: tracker.id,
      toolId: tracker.tool_id,
      toolName: ownership.tool_name,
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

    return success(response);
  } catch (error) {
    console.error('Error getting tool location:', error);
    return serverError('Failed to get tool location');
  }
}

// Add tracker to a tool
export async function addTracker(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<AddTrackerInput>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!body) {
      return badRequest('Invalid request body');
    }

    const errors = validateRequired(body, ['trackerType', 'trackerIdentifier']);
    if (errors.length > 0) {
      return badRequest(formatValidationErrors(errors));
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const ownership = await checkToolOwnership(toolId, currentUserId);
    if (!ownership) {
      return forbidden('You do not own this tool');
    }

    // Check for existing tracker
    const existingTracker = await queryOne(
      'SELECT 1 FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );
    if (existingTracker) {
      return conflict('Tool already has a tracker. Remove it first.');
    }

    const { trackerType, trackerIdentifier, trackerName } = body;

    // Validate tracker type
    const validTypes: TrackerType[] = ['airtag', 'tile', 'gps_cellular', 'gps_satellite', 'other'];
    if (!validTypes.includes(trackerType)) {
      return badRequest(`Invalid tracker type. Valid types: ${validTypes.join(', ')}`);
    }

    const tracker = await queryReturning<ToolTracker>(
      `INSERT INTO tool_trackers (tool_id, tracker_type, tracker_identifier, tracker_name)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [toolId, trackerType, trackerIdentifier, trackerName || null]
    );

    if (!tracker) {
      return serverError('Failed to add tracker');
    }

    const response: TrackerResponse = {
      id: tracker.id,
      toolId: tracker.tool_id,
      toolName: ownership.tool_name,
      trackerType: tracker.tracker_type,
      trackerIdentifier: tracker.tracker_identifier,
      trackerName: tracker.tracker_name,
      location: null,
      lastSeen: tracker.last_seen,
      isActive: tracker.is_active,
      createdAt: tracker.created_at,
    };

    return created(response);
  } catch (error) {
    console.error('Error adding tracker:', error);
    return serverError('Failed to add tracker');
  }
}

// Update tracker location
export async function updateTracker(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<UpdateLocationInput>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!body) {
      return badRequest('Invalid request body');
    }

    const errors = validateRequired(body, ['latitude', 'longitude']);
    if (errors.length > 0) {
      return badRequest(formatValidationErrors(errors));
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const ownership = await checkToolOwnership(toolId, currentUserId);
    if (!ownership) {
      return forbidden('You do not own this tool');
    }

    // Get tracker
    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1 AND is_active = true',
      [toolId]
    );

    if (!tracker) {
      return notFound('No active tracker on this tool');
    }

    const { latitude, longitude, accuracy } = body;

    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      return badRequest('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      return badRequest('Longitude must be between -180 and 180');
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

    return success({
      message: 'Location updated',
      location: { latitude, longitude, accuracy },
    });
  } catch (error) {
    console.error('Error updating tracker:', error);
    return serverError('Failed to update tracker');
  }
}

// Remove tracker from tool
export async function removeTracker(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const ownership = await checkToolOwnership(toolId, currentUserId);
    if (!ownership) {
      return forbidden('You do not own this tool');
    }

    const result = await query(
      'DELETE FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );

    if (result.rowCount === 0) {
      return notFound('No tracker found on this tool');
    }

    return noContent();
  } catch (error) {
    console.error('Error removing tracker:', error);
    return serverError('Failed to remove tracker');
  }
}

// Get location history for a tool
export async function getLocationHistory(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 50);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const ownership = await checkToolOwnership(toolId, currentUserId);
    if (!ownership) {
      return forbidden('You do not own this tool');
    }

    // Get tracker
    const tracker = await queryOne<ToolTracker>(
      'SELECT * FROM tool_trackers WHERE tool_id = $1',
      [toolId]
    );

    if (!tracker) {
      return notFound('No tracker on this tool');
    }

    const offset = (page - 1) * pageSize;

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM location_history WHERE tracker_id = $1',
      [tracker.id]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<LocationHistory>(
      `SELECT * FROM location_history
       WHERE tracker_id = $1
       ORDER BY recorded_at DESC
       LIMIT $2 OFFSET $3`,
      [tracker.id, pageSize, offset]
    );

    const history: LocationHistoryResponse[] = result.rows.map((h) => ({
      latitude: parseFloat(h.latitude.toString()),
      longitude: parseFloat(h.longitude.toString()),
      accuracy: h.accuracy ? parseFloat(h.accuracy.toString()) : null,
      recordedAt: h.recorded_at,
    }));

    return paginated(history, total, page, pageSize);
  } catch (error) {
    console.error('Error getting location history:', error);
    return serverError('Failed to get location history');
  }
}
