import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

export function errorHandler(
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction
) {
  console.error('Error:', err);

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // Clerk errors
  if (err.message === 'Unauthenticated') {
    return res.status(401).json({ error: 'Authentication required' });
  }

  // Database errors
  if ((err as any).code === '23505') {
    return res.status(409).json({ error: 'Resource already exists' });
  }

  if ((err as any).code === '23503') {
    return res.status(400).json({ error: 'Referenced resource not found' });
  }

  // Default error
  res.status(500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message
  });
}

// Helper functions for common errors
export const badRequest = (message: string) => new AppError(message, 400);
export const unauthorized = (message = 'Unauthorized') => new AppError(message, 401);
export const forbidden = (message = 'Forbidden') => new AppError(message, 403);
export const notFound = (message = 'Not found') => new AppError(message, 404);
export const conflict = (message: string) => new AppError(message, 409);
