import { Router, Request, Response, NextFunction } from 'express';
import { query, queryOne, queryReturning, transaction } from '../db';
import { requireUser } from '../middleware/auth';
import { badRequest, notFound, forbidden, conflict } from '../middleware/errorHandler';
import { isValidUUID, isValidLendingStatus } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { LendingRequest, LendingHistory, Toolbox } from '../models/types';

export const sharingRoutes = Router();

// Convert DB lending request to response format
function toLendingRequestResponse(
  request: LendingRequest & {
    tool_name: string;
    tool_description: string | null;
    requester_username: string;
    requester_display_name: string | null;
    requester_avatar_url: string | null;
    owner_username: string;
    owner_display_name: string | null;
    owner_avatar_url: string | null;
  }
) {
  return {
    id: request.id,
    tool: {
      id: request.tool_id,
      name: request.tool_name,
      description: request.tool_description,
    },
    requester: {
      id: request.requester_id,
      username: request.requester_username,
      displayName: request.requester_display_name,
      avatarUrl: request.requester_avatar_url,
    },
    owner: {
      id: request.owner_id,
      username: request.owner_username,
      displayName: request.owner_display_name,
      avatarUrl: request.owner_avatar_url,
    },
    status: request.status,
    message: request.message,
    responseMessage: request.response_message,
    requestedAt: request.requested_at,
    respondedAt: request.responded_at,
  };
}

// Check toolbox access for lending
async function checkToolboxAccess(
  toolboxId: string,
  userId: string,
  visibility: string
): Promise<boolean> {
  if (visibility === 'public') return true;

  const permission = await queryOne(
    `SELECT 1 FROM toolbox_permissions
     WHERE toolbox_id = $1 AND user_id = $2 AND permission_level = 'borrow'`,
    [toolboxId, userId]
  );
  if (permission) return true;

  if (visibility === 'buddies') {
    const toolbox = await queryOne<{ user_id: string }>(
      'SELECT user_id FROM toolboxes WHERE id = $1',
      [toolboxId]
    );
    if (toolbox) {
      const buddy = await queryOne(
        'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
        [userId, toolbox.user_id]
      );
      return !!buddy;
    }
  }

  return false;
}

// POST /api/tools/:id/lend-request - Request to borrow a tool
sharingRoutes.post('/tools/:id/lend-request', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  // This route is mounted at /api, so full path is /api/tools/:id/lend-request
  try {
    const { id: toolId } = req.params;
    const { message } = req.body;

    if (!isValidUUID(toolId)) {
      throw badRequest('Invalid tool ID');
    }

    // Get the tool and its owner
    const tool = await queryOne<{
      id: string;
      name: string;
      description: string | null;
      toolbox_id: string;
      is_available: boolean;
    }>('SELECT id, name, description, toolbox_id, is_available FROM tools WHERE id = $1', [toolId]);

    if (!tool) {
      throw notFound('Tool not found');
    }

    // Get toolbox owner
    const toolbox = await queryOne<{ user_id: string; visibility: string }>(
      'SELECT user_id, visibility FROM toolboxes WHERE id = $1',
      [tool.toolbox_id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    const ownerId = toolbox.user_id;

    if (ownerId === req.userId) {
      throw badRequest('Cannot request to borrow your own tool');
    }

    if (!tool.is_available) {
      throw conflict('Tool is currently not available');
    }

    const hasAccess = await checkToolboxAccess(tool.toolbox_id, req.userId!, toolbox.visibility);
    if (!hasAccess) {
      throw forbidden('You do not have access to this tool');
    }

    // Check for existing pending request
    const existingRequest = await queryOne(
      `SELECT 1 FROM lending_requests
       WHERE tool_id = $1 AND requester_id = $2 AND status IN ('pending', 'active')`,
      [toolId, req.userId]
    );

    if (existingRequest) {
      throw conflict('You already have a pending or active request for this tool');
    }

    const request = await queryReturning<LendingRequest>(
      `INSERT INTO lending_requests (tool_id, requester_id, owner_id, message)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [toolId, req.userId, ownerId, message || null]
    );

    if (!request) {
      throw badRequest('Failed to create lending request');
    }

    res.status(201).json({
      id: request.id,
      status: request.status,
      message: 'Lending request created',
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/lending/incoming - Get incoming lending requests
sharingRoutes.get('/incoming', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const status = req.query.status as string;
    const { page, pageSize, offset } = getPagination(req);

    let statusFilter = '';
    const params: unknown[] = [req.userId];

    if (status && isValidLendingStatus(status)) {
      statusFilter = 'AND lr.status = $2';
      params.push(status);
    }

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM lending_requests lr
       WHERE lr.owner_id = $1 ${statusFilter}`,
      params
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<LendingRequest & {
      tool_name: string;
      tool_description: string | null;
      requester_username: string;
      requester_display_name: string | null;
      requester_avatar_url: string | null;
      owner_username: string;
      owner_display_name: string | null;
      owner_avatar_url: string | null;
    }>(
      `SELECT lr.*,
        t.name as tool_name, t.description as tool_description,
        req.username as requester_username, req.display_name as requester_display_name, req.avatar_url as requester_avatar_url,
        own.username as owner_username, own.display_name as owner_display_name, own.avatar_url as owner_avatar_url
       FROM lending_requests lr
       INNER JOIN tools t ON t.id = lr.tool_id
       INNER JOIN users req ON req.id = lr.requester_id
       INNER JOIN users own ON own.id = lr.owner_id
       WHERE lr.owner_id = $1 ${statusFilter}
       ORDER BY lr.requested_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, pageSize, offset]
    );

    const requests = result.rows.map(toLendingRequestResponse);

    res.json(paginate(requests, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// GET /api/lending/outgoing - Get outgoing lending requests
sharingRoutes.get('/outgoing', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const status = req.query.status as string;
    const { page, pageSize, offset } = getPagination(req);

    let statusFilter = '';
    const params: unknown[] = [req.userId];

    if (status && isValidLendingStatus(status)) {
      statusFilter = 'AND lr.status = $2';
      params.push(status);
    }

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM lending_requests lr
       WHERE lr.requester_id = $1 ${statusFilter}`,
      params
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<LendingRequest & {
      tool_name: string;
      tool_description: string | null;
      requester_username: string;
      requester_display_name: string | null;
      requester_avatar_url: string | null;
      owner_username: string;
      owner_display_name: string | null;
      owner_avatar_url: string | null;
    }>(
      `SELECT lr.*,
        t.name as tool_name, t.description as tool_description,
        req.username as requester_username, req.display_name as requester_display_name, req.avatar_url as requester_avatar_url,
        own.username as owner_username, own.display_name as owner_display_name, own.avatar_url as owner_avatar_url
       FROM lending_requests lr
       INNER JOIN tools t ON t.id = lr.tool_id
       INNER JOIN users req ON req.id = lr.requester_id
       INNER JOIN users own ON own.id = lr.owner_id
       WHERE lr.requester_id = $1 ${statusFilter}
       ORDER BY lr.requested_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, pageSize, offset]
    );

    const requests = result.rows.map(toLendingRequestResponse);

    res.json(paginate(requests, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// PUT /api/lending/:id/respond - Respond to a lending request
sharingRoutes.put('/:id/respond', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: requestId } = req.params;
    const { approve, message } = req.body;

    if (!isValidUUID(requestId)) {
      throw badRequest('Invalid request ID');
    }

    if (typeof approve !== 'boolean') {
      throw badRequest('Must specify approve: true or false');
    }

    const request = await queryOne<LendingRequest>(
      'SELECT * FROM lending_requests WHERE id = $1',
      [requestId]
    );

    if (!request) {
      throw notFound('Lending request not found');
    }

    if (request.owner_id !== req.userId) {
      throw forbidden('You are not the owner of this tool');
    }

    if (request.status !== 'pending') {
      throw conflict('Request has already been responded to');
    }

    if (approve) {
      await transaction(async (client) => {
        await client.query(
          `UPDATE lending_requests
           SET status = 'active', response_message = $1, responded_at = CURRENT_TIMESTAMP
           WHERE id = $2`,
          [message || null, requestId]
        );

        await client.query(
          'UPDATE tools SET is_available = false WHERE id = $1',
          [request.tool_id]
        );

        await client.query(
          `INSERT INTO lending_history (tool_id, borrower_id, owner_id, lending_request_id)
           VALUES ($1, $2, $3, $4)`,
          [request.tool_id, request.requester_id, request.owner_id, requestId]
        );
      });
    } else {
      await query(
        `UPDATE lending_requests
         SET status = 'denied', response_message = $1, responded_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [message || null, requestId]
      );
    }

    res.json({
      message: approve ? 'Request approved' : 'Request denied',
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/lending/:id/return - Return a borrowed tool
sharingRoutes.post('/:id/return', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: requestId } = req.params;

    if (!isValidUUID(requestId)) {
      throw badRequest('Invalid request ID');
    }

    const request = await queryOne<LendingRequest>(
      'SELECT * FROM lending_requests WHERE id = $1',
      [requestId]
    );

    if (!request) {
      throw notFound('Lending request not found');
    }

    if (request.owner_id !== req.userId && request.requester_id !== req.userId) {
      throw forbidden('You are not involved in this lending');
    }

    if (request.status !== 'active') {
      throw conflict('Tool is not currently lent out');
    }

    await transaction(async (client) => {
      await client.query(
        `UPDATE lending_requests SET status = 'returned' WHERE id = $1`,
        [requestId]
      );

      await client.query(
        'UPDATE tools SET is_available = true WHERE id = $1',
        [request.tool_id]
      );

      await client.query(
        `UPDATE lending_history SET returned_at = CURRENT_TIMESTAMP
         WHERE lending_request_id = $1 AND returned_at IS NULL`,
        [requestId]
      );
    });

    res.json({ message: 'Tool returned' });
  } catch (error) {
    next(error);
  }
});

// GET /api/lending/history - Get lending history
sharingRoutes.get('/history', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, pageSize, offset } = getPagination(req);

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM lending_history
       WHERE owner_id = $1 OR borrower_id = $1`,
      [req.userId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<LendingHistory & {
      tool_name: string;
      borrower_username: string;
      owner_username: string;
    }>(
      `SELECT lh.*,
        t.name as tool_name,
        b.username as borrower_username,
        o.username as owner_username
       FROM lending_history lh
       INNER JOIN tools t ON t.id = lh.tool_id
       INNER JOIN users b ON b.id = lh.borrower_id
       INNER JOIN users o ON o.id = lh.owner_id
       WHERE lh.owner_id = $1 OR lh.borrower_id = $1
       ORDER BY lh.borrowed_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, pageSize, offset]
    );

    const history = result.rows.map((h) => ({
      id: h.id,
      toolId: h.tool_id,
      toolName: h.tool_name,
      borrowerId: h.borrower_id,
      borrowerUsername: h.borrower_username,
      ownerId: h.owner_id,
      ownerUsername: h.owner_username,
      borrowedAt: h.borrowed_at,
      returnedAt: h.returned_at,
    }));

    res.json(paginate(history, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});
