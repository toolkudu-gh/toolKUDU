import { Router, Request, Response, NextFunction } from 'express';
import { query, queryOne, queryReturning } from '../db';
import { requireUser } from '../middleware/auth';
import { badRequest, notFound, forbidden, conflict } from '../middleware/errorHandler';
import { isValidUUID } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { BuddyRequest, User, UserProfile } from '../models/types';

export const buddyRoutes = Router();

// GET /api/buddy-requests - Get pending buddy requests
buddyRoutes.get('/', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const type = (req.query.type as string) || 'incoming';
    const { page, pageSize, offset } = getPagination(req);

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

    const countResult = await queryOne<{ count: string }>(countQuery, [req.userId]);
    const total = parseInt(countResult?.count || '0');

    const result = await query<BuddyRequest & {
      user_id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
      bio: string | null;
    }>(dataQuery, [req.userId, pageSize, offset]);

    const requests = result.rows.map((row) => ({
      id: row.id,
      requesterId: row.requester_id,
      targetId: row.target_id,
      status: row.status,
      createdAt: row.created_at,
      respondedAt: row.responded_at,
      user: {
        id: row.user_id,
        username: row.username,
        displayName: row.display_name,
        avatarUrl: row.avatar_url,
        bio: row.bio,
      },
    }));

    res.json(paginate(requests, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// PUT /api/buddy-requests/:id - Respond to a buddy request
buddyRoutes.put('/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { accept } = req.body;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid request ID');
    }

    if (typeof accept !== 'boolean') {
      throw badRequest('Must specify accept: true or false');
    }

    const request = await queryOne<BuddyRequest>(
      'SELECT * FROM buddy_requests WHERE id = $1',
      [id]
    );

    if (!request) {
      throw notFound('Buddy request not found');
    }

    if (request.target_id !== req.userId) {
      throw forbidden('Cannot respond to this buddy request');
    }

    if (request.status !== 'pending') {
      throw conflict('Buddy request already responded to');
    }

    const newStatus = accept ? 'accepted' : 'rejected';

    await query(
      `UPDATE buddy_requests
       SET status = $1, responded_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [newStatus, id]
    );

    // If accepted, create buddy relationship (both directions)
    if (accept) {
      await query(
        `INSERT INTO buddies (user_id, buddy_id)
         VALUES ($1, $2), ($2, $1)
         ON CONFLICT DO NOTHING`,
        [request.requester_id, request.target_id]
      );
    }

    res.json({ message: `Buddy request ${newStatus}` });
  } catch (error) {
    next(error);
  }
});

// POST /api/users/:id/buddy-request - Send a buddy request (mounted on user routes)
// This is also accessible via userRoutes, but we include the handler here for reference
export async function sendBuddyRequest(req: Request, res: Response, next: NextFunction) {
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
      throw conflict('Already buddies with this user');
    }

    // Check if pending request already exists (either direction)
    const existingRequest = await queryOne<BuddyRequest>(
      `SELECT * FROM buddy_requests
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
      throw conflict('Buddy request already pending');
    }

    // Create buddy request
    const request = await queryReturning<BuddyRequest>(
      `INSERT INTO buddy_requests (requester_id, target_id)
       VALUES ($1, $2)
       RETURNING *`,
      [req.userId, targetUserId]
    );

    res.status(201).json(request);
  } catch (error) {
    next(error);
  }
}

// Mount the buddy request sender on the buddy routes as well
buddyRoutes.post('/send/:id', requireUser, sendBuddyRequest);
