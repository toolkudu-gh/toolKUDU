import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { clerkMiddleware } from '@clerk/express';
import { db } from './db';
import { errorHandler } from './middleware/errorHandler';
import { healthRoutes } from './routes/health';
import { toolboxRoutes } from './routes/toolboxes';
import { toolRoutes } from './routes/tools';
import { userRoutes } from './routes/users';
import { buddyRoutes } from './routes/buddies';
import { locationRoutes } from './routes/location';
import { sharingRoutes } from './routes/sharing';
import { setupRoutes } from './routes/setup';

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
      return callback(null, true);
    }
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));

// Clerk authentication middleware (attaches auth to request)
app.use(clerkMiddleware());

// Routes
app.use('/api/health', healthRoutes);
app.use('/api/setup', setupRoutes);
app.use('/api/toolboxes', toolboxRoutes);
app.use('/api/tools', toolRoutes);
app.use('/api/users', userRoutes);
app.use('/api/buddy-requests', buddyRoutes);
app.use('/api/trackers', locationRoutes);
app.use('/api', sharingRoutes); // Lending routes at /api/tools/:id/lend-request and /api/lending/*

// Error handler (must be last)
app.use(errorHandler);

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await db.end();
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log(`ToolKUDU API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;
