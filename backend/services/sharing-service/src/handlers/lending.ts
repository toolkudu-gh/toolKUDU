import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  query,
  queryOne,
  queryReturning,
  transaction,
  authenticate,
  success,
  created,
  badRequest,
  notFound,
  forbidden,
  conflict,
  serverError,
  paginated,
  parseBody,
  getPathParam,
  getQueryParam,
  getQueryParamInt,
  isValidUUID,
} from '@toolkudu/shared';
import {
  LendingRequest,
  LendingRequestResponse,
  LendingHistory,
  CreateLendingRequestInput,
  RespondToRequestInput,
  LendingStatus,
} from '../models/sharing';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

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
): LendingRequestResponse {
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

// Request to borrow a tool
export async function requestLend(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<CreateLendingRequestInput>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
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
      return notFound('Tool not found');
    }

    // Get toolbox owner
    const toolbox = await queryOne<{ user_id: string; visibility: string }>(
      'SELECT user_id, visibility FROM toolboxes WHERE id = $1',
      [tool.toolbox_id]
    );

    if (!toolbox) {
      return notFound('Toolbox not found');
    }

    const ownerId = toolbox.user_id;

    // Cannot borrow own tool
    if (ownerId === currentUserId) {
      return badRequest('Cannot request to borrow your own tool');
    }

    // Check if tool is available
    if (!tool.is_available) {
      return conflict('Tool is currently not available');
    }

    // Check access to toolbox
    const hasAccess = await checkToolboxAccess(tool.toolbox_id, currentUserId, toolbox.visibility);
    if (!hasAccess) {
      return forbidden('You do not have access to this tool');
    }

    // Check for existing pending request
    const existingRequest = await queryOne(
      `SELECT 1 FROM lending_requests
       WHERE tool_id = $1 AND requester_id = $2 AND status IN ('pending', 'active')`,
      [toolId, currentUserId]
    );

    if (existingRequest) {
      return conflict('You already have a pending or active request for this tool');
    }

    const message = body?.message || null;

    const request = await queryReturning<LendingRequest>(
      `INSERT INTO lending_requests (tool_id, requester_id, owner_id, message)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [toolId, currentUserId, ownerId, message]
    );

    if (!request) {
      return serverError('Failed to create lending request');
    }

    return created({
      id: request.id,
      status: request.status,
      message: 'Lending request created',
    });
  } catch (error) {
    console.error('Error creating lending request:', error);
    return serverError('Failed to create lending request');
  }
}

// Get incoming lending requests (requests for your tools)
export async function getIncomingRequests(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const status = getQueryParam(event, 'status');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const offset = (page - 1) * pageSize;

    let statusFilter = '';
    const params: unknown[] = [currentUserId];

    if (status && ['pending', 'approved', 'denied', 'active', 'returned', 'cancelled'].includes(status)) {
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

    return paginated(requests, total, page, pageSize);
  } catch (error) {
    console.error('Error getting incoming requests:', error);
    return serverError('Failed to get incoming requests');
  }
}

// Get outgoing lending requests (your requests for others' tools)
export async function getOutgoingRequests(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const status = getQueryParam(event, 'status');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const offset = (page - 1) * pageSize;

    let statusFilter = '';
    const params: unknown[] = [currentUserId];

    if (status && ['pending', 'approved', 'denied', 'active', 'returned', 'cancelled'].includes(status)) {
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

    return paginated(requests, total, page, pageSize);
  } catch (error) {
    console.error('Error getting outgoing requests:', error);
    return serverError('Failed to get outgoing requests');
  }
}

// Respond to a lending request (approve or deny)
export async function respondToRequest(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const requestId = getPathParam(event, 'id');
    const body = parseBody<RespondToRequestInput>(event);

    if (!requestId || !isValidUUID(requestId)) {
      return badRequest('Invalid request ID');
    }

    if (!body || typeof body.approve !== 'boolean') {
      return badRequest('Must specify approve: true or false');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the request
    const request = await queryOne<LendingRequest>(
      'SELECT * FROM lending_requests WHERE id = $1',
      [requestId]
    );

    if (!request) {
      return notFound('Lending request not found');
    }

    // Only owner can respond
    if (request.owner_id !== currentUserId) {
      return forbidden('You are not the owner of this tool');
    }

    if (request.status !== 'pending') {
      return conflict('Request has already been responded to');
    }

    const { approve, message } = body;

    if (approve) {
      // Approve: update request and mark tool as unavailable, create lending history
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
      // Deny
      await query(
        `UPDATE lending_requests
         SET status = 'denied', response_message = $1, responded_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [message || null, requestId]
      );
    }

    return success({
      message: approve ? 'Request approved' : 'Request denied',
    });
  } catch (error) {
    console.error('Error responding to request:', error);
    return serverError('Failed to respond to request');
  }
}

// Return a borrowed tool
export async function returnTool(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const requestId = getPathParam(event, 'id');

    if (!requestId || !isValidUUID(requestId)) {
      return badRequest('Invalid request ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the request
    const request = await queryOne<LendingRequest>(
      'SELECT * FROM lending_requests WHERE id = $1',
      [requestId]
    );

    if (!request) {
      return notFound('Lending request not found');
    }

    // Either borrower or owner can mark as returned
    if (request.owner_id !== currentUserId && request.requester_id !== currentUserId) {
      return forbidden('You are not involved in this lending');
    }

    if (request.status !== 'active') {
      return conflict('Tool is not currently lent out');
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

    return success({ message: 'Tool returned' });
  } catch (error) {
    console.error('Error returning tool:', error);
    return serverError('Failed to return tool');
  }
}

// Get lending history
export async function getLendingHistory(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const offset = (page - 1) * pageSize;

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM lending_history
       WHERE owner_id = $1 OR borrower_id = $1`,
      [currentUserId]
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
      [currentUserId, pageSize, offset]
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

    return paginated(history, total, page, pageSize);
  } catch (error) {
    console.error('Error getting lending history:', error);
    return serverError('Failed to get lending history');
  }
}

// Get tools currently lent out (owner view)
export async function getSharedTools(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const result = await query<{
      id: string;
      name: string;
      description: string | null;
      borrower_username: string;
      borrowed_at: Date;
    }>(
      `SELECT t.id, t.name, t.description, u.username as borrower_username, lh.borrowed_at
       FROM tools t
       INNER JOIN toolboxes tb ON tb.id = t.toolbox_id
       INNER JOIN lending_history lh ON lh.tool_id = t.id AND lh.returned_at IS NULL
       INNER JOIN users u ON u.id = lh.borrower_id
       WHERE tb.user_id = $1 AND t.is_available = false
       ORDER BY lh.borrowed_at DESC`,
      [currentUserId]
    );

    return success(result.rows.map((t) => ({
      id: t.id,
      name: t.name,
      description: t.description,
      borrowerUsername: t.borrower_username,
      borrowedAt: t.borrowed_at,
    })));
  } catch (error) {
    console.error('Error getting shared tools:', error);
    return serverError('Failed to get shared tools');
  }
}

// Get tools currently borrowed (borrower view)
export async function getBorrowedTools(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const result = await query<{
      id: string;
      name: string;
      description: string | null;
      owner_username: string;
      borrowed_at: Date;
      lending_request_id: string;
    }>(
      `SELECT t.id, t.name, t.description, u.username as owner_username, lh.borrowed_at, lh.lending_request_id
       FROM lending_history lh
       INNER JOIN tools t ON t.id = lh.tool_id
       INNER JOIN users u ON u.id = lh.owner_id
       WHERE lh.borrower_id = $1 AND lh.returned_at IS NULL
       ORDER BY lh.borrowed_at DESC`,
      [currentUserId]
    );

    return success(result.rows.map((t) => ({
      id: t.id,
      name: t.name,
      description: t.description,
      ownerUsername: t.owner_username,
      borrowedAt: t.borrowed_at,
      lendingRequestId: t.lending_request_id,
    })));
  } catch (error) {
    console.error('Error getting borrowed tools:', error);
    return serverError('Failed to get borrowed tools');
  }
}

// Helper: Check toolbox access
async function checkToolboxAccess(
  toolboxId: string,
  userId: string,
  visibility: string
): Promise<boolean> {
  if (visibility === 'public') return true;

  // Check explicit permission
  const permission = await queryOne(
    `SELECT 1 FROM toolbox_permissions
     WHERE toolbox_id = $1 AND user_id = $2 AND permission_level = 'borrow'`,
    [toolboxId, userId]
  );
  if (permission) return true;

  if (visibility === 'buddies') {
    // Check buddy relationship with toolbox owner
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
