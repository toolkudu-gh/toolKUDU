import { Router, Request, Response, NextFunction } from 'express';
import { clerkClient } from '@clerk/express';
import { query, queryOne, queryReturning } from '../db';
import { requireUser, optionalAuth, authenticate, attachUserId } from '../middleware/auth';
import { badRequest, notFound } from '../middleware/errorHandler';
import { isValidUUID } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { User, UserProfile, Toolbox, Tool, ToolResponse } from '../models/types';
import { getPublicUrl } from '../services/r2';

export const userRoutes = Router();

// Convert DB user to profile format
function toUserProfile(
  user: User & { followers_count?: string; following_count?: string },
  isFollowing = false,
  isBuddy = false
): UserProfile {
  return {
    id: user.id,
    username: user.username,
    displayName: user.display_name,
    avatarUrl: user.avatar_url,
    bio: user.bio,
    followersCount: parseInt(user.followers_count || '0'),
    followingCount: parseInt(user.following_count || '0'),
    isFollowing,
    isBuddy,
  };
}

// GET /api/users/check-username - Check if username is available (no auth required)
userRoutes.get('/check-username', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const username = req.query.username as string;

    if (!username || username.length < 3) {
      throw badRequest('Username must be at least 3 characters');
    }

    // Validate username format
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.json({
        available: false,
        error: 'Username can only contain letters, numbers, and underscores',
      });
    }

    const existing = await queryOne(
      'SELECT 1 FROM users WHERE LOWER(username) = LOWER($1)',
      [username]
    );

    if (existing) {
      // Generate suggestions
      const base = username.toLowerCase();
      const currentYear = new Date().getFullYear();
      const random = Math.floor(Math.random() * 1000);
      const suggestions = [
        `${base}_${random}`,
        `${base}_tools`,
        `${base}_${currentYear}`,
      ];

      return res.json({
        available: false,
        suggestions,
      });
    }

    res.json({ available: true });
  } catch (error) {
    next(error);
  }
});

// POST /api/users/sync - Sync user from Clerk to database
userRoutes.post('/sync', authenticate, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const auth = (req as any).auth;
    const clerkUserId = auth?.userId;

    if (!clerkUserId) {
      throw badRequest('No Clerk user ID found');
    }

    // Get user info from Clerk
    const clerkUser = await clerkClient.users.getUser(clerkUserId);
    const email = clerkUser.emailAddresses[0]?.emailAddress;

    if (!email) {
      throw badRequest('No email found in Clerk user');
    }

    // Check if user exists by Clerk ID
    let user = await queryOne<User>(
      'SELECT * FROM users WHERE clerk_id = $1',
      [clerkUserId]
    );

    if (user) {
      // User already synced
      return res.json(toUserProfile(user));
    }

    // Check if user exists by email (migration from Cognito)
    user = await queryOne<User>(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (user) {
      // Link Clerk ID to existing user
      await query(
        'UPDATE users SET clerk_id = $1 WHERE id = $2',
        [clerkUserId, user.id]
      );
      user.clerk_id = clerkUserId;
      return res.json(toUserProfile(user));
    }

    // Create new user
    const username = generateUsername(email);
    const displayName = clerkUser.firstName
      ? `${clerkUser.firstName} ${clerkUser.lastName || ''}`.trim()
      : username;

    user = await queryReturning<User>(
      `INSERT INTO users (clerk_id, email, username, display_name, avatar_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [clerkUserId, email, username, displayName, clerkUser.imageUrl || null]
    );

    if (!user) {
      throw badRequest('Failed to create user');
    }

    res.status(201).json(toUserProfile(user));
  } catch (error) {
    next(error);
  }
});

// GET /api/users/me - Get current user profile
userRoutes.get('/me', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await queryOne<User & { followers_count: string; following_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count
       FROM users u
       WHERE u.id = $1`,
      [req.userId]
    );

    if (!user) {
      throw notFound('User not found');
    }

    res.json(toUserProfile(user));
  } catch (error) {
    next(error);
  }
});

// PUT /api/users/me - Update current user profile
userRoutes.put('/me', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { displayName, bio, avatarUrl, username } = req.body;

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
    if (username !== undefined) {
      // Check if username is available
      const existing = await queryOne(
        'SELECT 1 FROM users WHERE username = $1 AND id != $2',
        [username, req.userId]
      );
      if (existing) {
        throw badRequest('Username is already taken');
      }
      updates.push(`username = $${paramIndex++}`);
      values.push(username);
    }

    if (updates.length === 0) {
      throw badRequest('No fields to update');
    }

    values.push(req.userId);

    const result = await queryOne<User>(
      `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    if (!result) {
      throw notFound('User not found');
    }

    res.json(toUserProfile(result));
  } catch (error) {
    next(error);
  }
});

// GET /api/users/me/buddies - Get current user's buddies
userRoutes.get('/me/buddies', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, pageSize, offset } = getPagination(req);

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM buddies WHERE user_id = $1',
      [req.userId]
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
      [req.userId, pageSize, offset]
    );

    const buddies = result.rows.map((user) => toUserProfile(user, false, true));

    res.json(paginate(buddies, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// DELETE /api/users/me/buddies/:id - Remove a buddy
userRoutes.delete('/me/buddies/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid buddy ID');
    }

    const result = await query(
      `DELETE FROM buddies
       WHERE (user_id = $1 AND buddy_id = $2) OR (user_id = $2 AND buddy_id = $1)`,
      [req.userId, id]
    );

    if (result.rowCount === 0) {
      throw notFound('Buddy relationship not found');
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// GET /api/users/me/followers - Get followers
userRoutes.get('/me/followers', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, pageSize, offset } = getPagination(req);

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM follows WHERE following_id = $1',
      [req.userId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       INNER JOIN follows f ON f.follower_id = u.id
       WHERE f.following_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, pageSize, offset]
    );

    const followers = result.rows.map((user) => toUserProfile(user));

    res.json(paginate(followers, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// GET /api/users/me/following - Get following
userRoutes.get('/me/following', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, pageSize, offset } = getPagination(req);

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM follows WHERE follower_id = $1',
      [req.userId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<User & { followers_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
       FROM users u
       INNER JOIN follows f ON f.following_id = u.id
       WHERE f.follower_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, pageSize, offset]
    );

    const following = result.rows.map((user) => toUserProfile(user, true));

    res.json(paginate(following, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// GET /api/users/search - Search users
userRoutes.get('/search', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const searchQuery = req.query.q as string;
    const { page, pageSize, offset } = getPagination(req);

    if (!searchQuery || searchQuery.length < 2) {
      throw badRequest('Search query must be at least 2 characters');
    }

    const searchPattern = `%${searchQuery}%`;

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM users
       WHERE username ILIKE $1 OR display_name ILIKE $1`,
      [searchPattern]
    );
    const total = parseInt(countResult?.count || '0');

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

    const users = result.rows.map((user) => toUserProfile(user));

    res.json(paginate(users, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// GET /api/users/:id - Get user by ID
userRoutes.get('/:id', optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid user ID');
    }

    // Get user ID if authenticated
    if (req.clerkUserId && !req.userId) {
      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [req.clerkUserId]
      );
      if (user) req.userId = user.id;
    }

    const user = await queryOne<User & { followers_count: string; following_count: string }>(
      `SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count
       FROM users u
       WHERE u.id = $1`,
      [id]
    );

    if (!user) {
      throw notFound('User not found');
    }

    let isFollowing = false;
    let isBuddy = false;

    if (req.userId) {
      const followCheck = await queryOne(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
        [req.userId, id]
      );
      isFollowing = !!followCheck;

      const buddyCheck = await queryOne(
        'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
        [req.userId, id]
      );
      isBuddy = !!buddyCheck;
    }

    res.json(toUserProfile(user, isFollowing, isBuddy));
  } catch (error) {
    next(error);
  }
});

// POST /api/users/:id/follow - Follow a user
userRoutes.post('/:id/follow', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid user ID');
    }

    if (id === req.userId) {
      throw badRequest('Cannot follow yourself');
    }

    await queryReturning(
      `INSERT INTO follows (follower_id, following_id)
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING
       RETURNING *`,
      [req.userId, id]
    );

    res.status(201).json({ message: 'Followed' });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/users/:id/follow - Unfollow a user
userRoutes.delete('/:id/follow', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid user ID');
    }

    await query(
      'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
      [req.userId, id]
    );

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// POST /api/users/:id/buddy-request - Send a buddy request
userRoutes.post('/:id/buddy-request', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: targetUserId } = req.params;

    if (!isValidUUID(targetUserId)) {
      throw badRequest('Invalid user ID');
    }

    if (req.userId === targetUserId) {
      throw badRequest('Cannot send buddy request to yourself');
    }

    // Check if target user exists
    const targetUser = await queryOne<User>(
      'SELECT id FROM users WHERE id = $1',
      [targetUserId]
    );
    if (!targetUser) {
      throw notFound('User not found');
    }

    // Check if already buddies
    const existingBuddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [req.userId, targetUserId]
    );
    if (existingBuddy) {
      return res.status(409).json({ error: 'Already buddies with this user' });
    }

    // Check if pending request already exists (either direction)
    const existingRequest = await queryOne<{ id: string; requester_id: string }>(
      `SELECT id, requester_id FROM buddy_requests
       WHERE ((requester_id = $1 AND target_id = $2) OR (requester_id = $2 AND target_id = $1))
         AND status = 'pending'`,
      [req.userId, targetUserId]
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

        // Create buddy relationship
        await query(
          `INSERT INTO buddies (user_id, buddy_id)
           VALUES ($1, $2), ($2, $1)
           ON CONFLICT DO NOTHING`,
          [req.userId, targetUserId]
        );

        return res.json({ message: 'Buddy request accepted (mutual request)' });
      }
      return res.status(409).json({ error: 'Buddy request already pending' });
    }

    // Create buddy request
    const request = await queryReturning(
      `INSERT INTO buddy_requests (requester_id, target_id)
       VALUES ($1, $2)
       RETURNING *`,
      [req.userId, targetUserId]
    );

    res.status(201).json(request);
  } catch (error) {
    next(error);
  }
});

// GET /api/users/:userId/toolboxes - Get user's toolboxes
userRoutes.get('/:userId/toolboxes', optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { userId } = req.params;
    const { page, pageSize, offset } = getPagination(req);

    if (!isValidUUID(userId)) {
      throw badRequest('Invalid user ID');
    }

    // Get current user ID if authenticated
    if (req.clerkUserId && !req.userId) {
      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [req.clerkUserId]
      );
      if (user) req.userId = user.id;
    }

    let isBuddy = false;
    if (req.userId && req.userId !== userId) {
      const buddyCheck = await queryOne(
        'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
        [req.userId, userId]
      );
      isBuddy = !!buddyCheck;
    }

    // Build visibility filter
    let visibilityFilter: string;
    const params: unknown[] = [userId];

    if (req.userId === userId) {
      visibilityFilter = '';
    } else if (isBuddy) {
      visibilityFilter = "AND (tb.visibility = 'public' OR tb.visibility = 'buddies')";
    } else {
      visibilityFilter = "AND tb.visibility = 'public'";
    }

    // Also check for explicit permissions
    let permissionCheck = '';
    if (req.userId && req.userId !== userId) {
      permissionCheck = `
        OR tb.id IN (
          SELECT toolbox_id FROM toolbox_permissions WHERE user_id = $${params.length + 1}
        )`;
      params.push(req.userId);
    }

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM toolboxes tb
       WHERE tb.user_id = $1 ${visibilityFilter} ${permissionCheck}`,
      params
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.user_id = $1 ${visibilityFilter} ${permissionCheck}
       ORDER BY tb.created_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, pageSize, offset]
    );

    const toolboxes = result.rows.map((tb) => ({
      id: tb.id,
      userId: tb.user_id,
      name: tb.name,
      description: tb.description,
      visibility: tb.visibility,
      icon: tb.icon,
      color: tb.color,
      toolCount: parseInt(tb.tool_count || '0'),
      createdAt: tb.created_at,
      updatedAt: tb.updated_at,
    }));

    res.json(paginate(toolboxes, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// Helper: Generate username from email
function generateUsername(email: string): string {
  const base = email.split('@')[0].replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
  const suffix = Math.floor(Math.random() * 1000);
  return `${base}_${suffix}`;
}
