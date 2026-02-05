import { Router } from 'express';
import { db } from '../db';

export const healthRoutes = Router();

healthRoutes.get('/', async (_req, res) => {
  try {
    const result = await db.query('SELECT NOW() as time');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
      dbTime: result.rows[0].time,
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: (error as Error).message,
    });
  }
});

healthRoutes.get('/ready', async (_req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ ready: true });
  } catch {
    res.status(503).json({ ready: false });
  }
});
