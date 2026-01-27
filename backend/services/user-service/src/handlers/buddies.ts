import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  query,
  queryOne,
  authenticate,
  success,
  created,
  noContent,
  badRequest,
  notFound,
  conflict,
  forbidden,
  serverError,
  paginated,
  parseBody,
  getPathParam,
  getQueryParam,
  getQueryParamInt,
  isValidUUID,
} from '@toolkudu/shared';
import { User, UserProfile, BuddyRequest, BuddyRequestWithUser } from '../models/user';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

// Send a buddy request ("Be my Buddy")
export async function sendBuddyRequest(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const targetUserId = getPathParam(event, 'id');

    if (!targetUserId || !isValidUUID(targetUserId)) {
      return badRequest('Invalid user ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('Current user not found');
    }

    if (currentUserId === targetUserId) {
      return badRequest('Cannot send buddy request to yourself');
    }

    // Check if target user exists
    const targetUser = await queryOne<User>(
      'SELECT id FROM users WHERE id = $1',
      [targetUserId]
    );
    if (!targetUser) {
      return notFound('User not found');
    }

    // Check if already buddies
    const existingBuddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [currentUserId, targetUserId]
    );
    if (existingBuddy) {
      return conflict('Already buddies with this user');
    }

    // Check if pending request already exists (either direction)
    const existingRequest = await queryOne<BuddyRequest>(
      `SELECT * FROM buddy_requests
       WHERE ((requester_id = $1 AND target_id = $2) OR (requester_id = $2 AND target_id = $1))
         AND status = 'pending'`,
      [currentUserId, targetUserId]
    );

    if (existingRequest) {
      // If the other user already sent us a request, auto-accept it
      if (existingRequest.requester_id === targetUserId) {
        await query(
          `UPDATE buddy_requests
           SET status = 'accepted', responded_at = CURRENT_TIMESTAMP
           WHERE id = $1`,
          [existingRequest.id]
        );
        return success({ message: 'Buddy request accepted (mutual request)' });
      }
      return conflict('Buddy request already pending');
    }

    // Create buddy request
    const request = await queryOne<BuddyRequest>(
      `INSERT INTO buddy_requests (requester_id, target_id)
       VALUES ($1, $2)
       RETURNING *`,
      [currentUserId, targetUserId]
    );

    return created(request);
  } catch (error) {
    console.error('Error sending buddy request:', error);
    return serverError('Failed to send buddy request');
  }
}

// Respond to a buddy request
export async function respondToBuddyRequest(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const requestId = getPathParam(event, 'id');
    const body = parseBody<{ accept: boolean }>(event);

    if (!requestId || !isValidUUID(requestId)) {
      return badRequest('Invalid request ID');
    }

    if (!body || typeof body.accept !== 'boolean') {
      return badRequest('Must specify accept: true or false');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('Current user not found');
    }

    // Get the buddy request
    const request = await queryOne<BuddyRequest>(
      'SELECT * FROM buddy_requests WHERE id = $1',
      [requestId]
    );

    if (!request) {
      return notFound('Buddy request not found');
    }

    // Only the target can respond
    if (request.target_id !== currentUserId) {
      return forbidden('Cannot respond to this buddy request');
    }

    if (request.status !== 'pending') {
      return conflict('Buddy request already responded to');
    }

    const newStatus = body.accept ? 'accepted' : 'rejected';

    // Update the request (buddy relationship is created via trigger if accepted)
    await query(
      `UPDATE buddy_requests
       SET status = $1, responded_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [newStatus, requestId]
    );

    return success({ message: `Buddy request ${newStatus}` });
  } catch (error) {
    console.error('Error responding to buddy request:', error);
    return serverError('Failed to respond to buddy request');
  }
}

// Get pending buddy requests
export async function getBuddyRequests(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const type = getQueryParam(event, 'type') || 'incoming';
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('Current user not found');
    }

    const offset = (page - 1) * pageSize;

    let countQuery: string;
    let dataQuery: string;

    if (type === 'outgoing') {
      countQuery = `SELECT COUNT(*) as count FROM buddy_requests
                    WHERE requester_id = $1 AND status = 'pending'`;
      dataQuery = `
        SELECT br.*, u.id as user_id, u.username, u.display_name, u.avatar_url, u.bio
        FROM buddy_requests br
        INNER JOIN users u ON u.id = br.target_id
        WHERE br.requester_id = $1 AND br.status = 'pending'
        ORDER BY br.created_at DESC
        LIMIT $2 OFFSET $3`;
    } else {
      countQuery = `SELECT COUNT(*) as count FROM buddy_requests
                    WHERE target_id = $1 AND status = 'pending'`;
      dataQuery = `
        SELECT br.*, u.id as user_id, u.username, u.display_name, u.avatar_url, u.bio
        FROM buddy_requests br
        INNER JOIN users u ON u.id = br.requester_id
        WHERE br.target_id = $1 AND br.status = 'pending'
        ORDER BY br.created_at DESC
        LIMIT $2 OFFSET $3`;
    }

    const countResult = await queryOne<{ count: string }>(countQuery, [currentUserId]);
    const total = parseInt(countResult?.count || '0');

    const result = await query<BuddyRequest & {
      user_id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
      bio: string | null;
    }>(dataQuery, [currentUserId, pageSize, offset]);

    const requests: BuddyRequestWithUser[] = result.rows.map((row) => ({
      id: row.id,
      requester_id: row.requester_id,
      target_id: row.target_id,
      status: row.status,
      created_at: row.created_at,
      responded_at: row.responded_at,
      requester: {
        id: row.user_id,
        username: row.username,
        displayName: row.display_name,
        avatarUrl: row.avatar_url,
        bio: row.bio,
        followersCount: 0,
        followingCount: 0,
      },
    }));

    return paginated(requests, total, page, pageSize);
  } catch (error) {
    console.error('Error getting buddy requests:', error);
    return serverError('Failed to get buddy requests');
  }
}

// Get buddies list
export async function getBuddies(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('Current user not found');
    }

    const offset = (page - 1) * pageSize;

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM buddies WHERE user_id = $1',
      [currentUserId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       INNER JOIN buddies b ON b.buddy_id = u.id
       WHERE b.user_id = $1
       ORDER BY u.username
       LIMIT $2 OFFSET $3`,
      [currentUserId, pageSize, offset]
    );

    const buddies: UserProfile[] = result.rows.map((user) => ({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt(user.followers_count) || 0,
      followingCount: 0,
      isBuddy: true,
    }));

    return paginated(buddies, total, page, pageSize);
  } catch (error) {
    console.error('Error getting buddies:', error);
    return serverError('Failed to get buddies');
  }
}

// Remove a buddy
export async function removeBuddy(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const buddyId = getPathParam(event, 'id');

    if (!buddyId || !isValidUUID(buddyId)) {
      return badRequest('Invalid buddy ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('Current user not found');
    }

    // Remove both directions of the buddy relationship
    const result = await query(
      `DELETE FROM buddies
       WHERE (user_id = $1 AND buddy_id = $2) OR (user_id = $2 AND buddy_id = $1)`,
      [currentUserId, buddyId]
    );

    if (result.rowCount === 0) {
      return notFound('Buddy relationship not found');
    }

    return noContent();
  } catch (error) {
    console.error('Error removing buddy:', error);
    return serverError('Failed to remove buddy');
  }
}
