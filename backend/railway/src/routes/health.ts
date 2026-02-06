import { Router } from 'express';
import { db } from '../db';

export const healthRoutes = Router();

// Basic health check - always returns 200 so container can start
healthRoutes.get('/', async (_req, res) => {
  let dbStatus = 'unknown';
  let dbTime = null;

  try {
    const result = await db.query('SELECT NOW() as time');
    dbStatus = 'connected';
    dbTime = result.rows[0].time;
  } catch (error) {
    dbStatus = 'disconnected: ' + (error as Error).message;
  }

  // Always return 200 for container health check
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    database: dbStatus,
    dbTime: dbTime,
    environment: process.env.NODE_ENV || 'development',
  });
});

healthRoutes.get('/ready', async (_req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ ready: true });
  } catch {
    res.status(503).json({ ready: false });
  }
});
