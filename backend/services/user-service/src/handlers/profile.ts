import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  query,
  queryOne,
  authenticate,
  success,
  badRequest,
  notFound,
  serverError,
  paginated,
  parseBody,
  getPathParam,
  getQueryParam,
  getQueryParamInt,
  isValidUUID,
  validateRequired,
  formatValidationErrors,
} from '@toolkudu/shared';
import { User, UserProfile, UpdateUserInput } from '../models/user';

// Get current user's profile
export async function getProfile(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);

    const user = await queryOne<User>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count
       FROM users u
       WHERE cognito_sub = $1`,
      [cognitoUser.sub]
    );

    if (!user) {
      return notFound('User not found');
    }

    const profile: UserProfile = {
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt((user as unknown as { followers_count: string }).followers_count) || 0,
      followingCount: parseInt((user as unknown as { following_count: string }).following_count) || 0,
    };

    return success(profile);
  } catch (error) {
    console.error('Error getting profile:', error);
    return serverError('Failed to get profile');
  }
}

// Update current user's profile
export async function updateProfile(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const body = parseBody<UpdateUserInput>(event);

    if (!body) {
      return badRequest('Invalid request body');
    }

    const { displayName, bio, avatarUrl } = body;

    // Build update query dynamically
    const updates: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (displayName !== undefined) {
      updates.push(`display_name = $${paramIndex++}`);
      values.push(displayName);
    }
    if (bio !== undefined) {
      updates.push(`bio = $${paramIndex++}`);
      values.push(bio);
    }
    if (avatarUrl !== undefined) {
      updates.push(`avatar_url = $${paramIndex++}`);
      values.push(avatarUrl);
    }

    if (updates.length === 0) {
      return badRequest('No fields to update');
    }

    values.push(cognitoUser.sub);

    const result = await queryOne<User>(
      `UPDATE users SET ${updates.join(', ')}
       WHERE cognito_sub = $${paramIndex}
       RETURNING *`,
      values
    );

    if (!result) {
      return notFound('User not found');
    }

    const profile: UserProfile = {
      id: result.id,
      username: result.username,
      displayName: result.display_name,
      avatarUrl: result.avatar_url,
      bio: result.bio,
      followersCount: 0,
      followingCount: 0,
    };

    return success(profile);
  } catch (error) {
    console.error('Error updating profile:', error);
    return serverError('Failed to update profile');
  }
}

// Get user by ID
export async function getUserById(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const userId = getPathParam(event, 'id');

    if (!userId || !isValidUUID(userId)) {
      return badRequest('Invalid user ID');
    }

    let currentUserId: string | null = null;
    try {
      const cognitoUser = await authenticate(event);
      const currentUser = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE cognito_sub = $1',
        [cognitoUser.sub]
      );
      currentUserId = currentUser?.id || null;
    } catch {
      // User is not authenticated, that's okay
    }

    const user = await queryOne<User & { followers_count: string; following_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count
       FROM users u
       WHERE u.id = $1`,
      [userId]
    );

    if (!user) {
      return notFound('User not found');
    }

    let isFollowing = false;
    let isBuddy = false;

    if (currentUserId) {
      const followCheck = await queryOne(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
        [currentUserId, userId]
      );
      isFollowing = !!followCheck;

      const buddyCheck = await queryOne(
        'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
        [currentUserId, userId]
      );
      isBuddy = !!buddyCheck;
    }

    const profile: UserProfile = {
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt(user.followers_count) || 0,
      followingCount: parseInt(user.following_count) || 0,
      isFollowing,
      isBuddy,
    };

    return success(profile);
  } catch (error) {
    console.error('Error getting user:', error);
    return serverError('Failed to get user');
  }
}

// Search users
export async function searchUsers(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    await authenticate(event);

    const searchQuery = getQueryParam(event, 'q');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    if (!searchQuery || searchQuery.length < 2) {
      return badRequest('Search query must be at least 2 characters');
    }

    const offset = (page - 1) * pageSize;
    const searchPattern = `%${searchQuery}%`;

    // Get total count
    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM users
       WHERE username ILIKE $1 OR display_name ILIKE $1`,
      [searchPattern]
    );
    const total = parseInt(countResult?.count || '0');

    // Get users
    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       WHERE username ILIKE $1 OR display_name ILIKE $1
       ORDER BY
         CASE WHEN username ILIKE $2 THEN 0 ELSE 1 END,
         username
       LIMIT $3 OFFSET $4`,
      [searchPattern, `${searchQuery}%`, pageSize, offset]
    );

    const users: UserProfile[] = result.rows.map((user) => ({
      id: user.id,
      username: user.username,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      followersCount: parseInt(user.followers_count) || 0,
      followingCount: 0,
    }));

    return paginated(users, total, page, pageSize);
  } catch (error) {
    console.error('Error searching users:', error);
    return serverError('Failed to search users');
  }
}
