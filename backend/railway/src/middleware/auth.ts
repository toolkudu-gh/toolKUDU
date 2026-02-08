import { Request, Response, NextFunction } from 'express';
import { requireAuth, getAuth } from '@clerk/express';
import { queryOne } from '../db';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      userId?: string;
      clerkUserId?: string;
    }
  }
}

// Require authentication (Clerk)
export const authenticate = requireAuth();

// Get user ID from database (after Clerk auth)
export async function attachUserId(req: Request, res: Response, next: NextFunction) {
  try {
    const auth = getAuth(req);

    if (!auth?.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    req.clerkUserId = auth.userId;

    // Get database user ID from Clerk ID
    const user = await queryOne<{ id: string }>(
      'SELECT id FROM users WHERE clerk_id = $1',
      [auth.userId]
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found. Please sync your account.' });
    }

    req.userId = user.id;
    next();
  } catch (error) {
    console.error('Auth error:', error);
    res.status(401).json({ error: 'Authentication failed' });
  }
}

// Optional authentication (for routes that work with or without auth)
export async function optionalAuth(req: Request, res: Response, next: NextFunction) {
  try {
    const auth = getAuth(req);

    if (auth?.userId) {
      req.clerkUserId = auth.userId;

      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [auth.userId]
      );

      if (user) {
        req.userId = user.id;
      }
    }

    next();
  } catch {
    // Continue without auth
    next();
  }
}

// Combined middleware: authenticate + attach user ID
export const requireUser = [authenticate, attachUserId];
