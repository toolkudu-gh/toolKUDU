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
  serverError,
  paginated,
  getPathParam,
  getQueryParamInt,
  isValidUUID,
} from '@toolkudu/shared';
import { User, UserProfile } from '../models/user';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

// Follow a user
export async function followUser(
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
      return badRequest('Cannot follow yourself');
    }

    // Check if target user exists
    const targetUser = await queryOne<User>(
      'SELECT id FROM users WHERE id = $1',
      [targetUserId]
    );
    if (!targetUser) {
      return notFound('User not found');
    }

    // Check if already following
    const existingFollow = await queryOne(
      'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
      [currentUserId, targetUserId]
    );
    if (existingFollow) {
      return conflict('Already following this user');
    }

    // Create follow relationship
    await query(
      'INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)',
      [currentUserId, targetUserId]
    );

    return created({ message: 'Successfully followed user' });
  } catch (error) {
    console.error('Error following user:', error);
    return serverError('Failed to follow user');
  }
}

// Unfollow a user
export async function unfollowUser(
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

    const result = await query(
      'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
      [currentUserId, targetUserId]
    );

    if (result.rowCount === 0) {
      return notFound('Not following this user');
    }

    return noContent();
  } catch (error) {
    console.error('Error unfollowing user:', error);
    return serverError('Failed to unfollow user');
  }
}

// Get followers of current user
export async function getFollowers(
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

    // Get total count
    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM follows WHERE following_id = $1',
      [currentUserId]
    );
    const total = parseInt(countResult?.count || '0');

    // Get followers
    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       INNER JOIN follows f ON f.follower_id = u.id
       WHERE f.following_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [currentUserId, pageSize, offset]
    );

    const followers: UserProfile[] = result.rows.map((user) => ({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt(user.followers_count) || 0,
      followingCount: 0,
    }));

    return paginated(followers, total, page, pageSize);
  } catch (error) {
    console.error('Error getting followers:', error);
    return serverError('Failed to get followers');
  }
}

// Get users that current user is following
export async function getFollowing(
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

    // Get total count
    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM follows WHERE follower_id = $1',
      [currentUserId]
    );
    const total = parseInt(countResult?.count || '0');

    // Get following
    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       INNER JOIN follows f ON f.following_id = u.id
       WHERE f.follower_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [currentUserId, pageSize, offset]
    );

    const following: UserProfile[] = result.rows.map((user) => ({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt(user.followers_count) || 0,
      followingCount: 0,
    }));

    return paginated(following, total, page, pageSize);
  } catch (error) {
    console.error('Error getting following:', error);
    return serverError('Failed to get following');
  }
}
