import rateLimit from 'express-rate-limit';

// General API rate limiter - 100 requests per minute
export const generalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many requests',
    message: 'Please try again later',
  },
});

// Strict rate limiter for auth-related endpoints - 10 requests per minute
export const authLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many authentication attempts',
    message: 'Please try again in a minute',
  },
});

// User sync endpoint - 5 requests per minute (prevents abuse)
export const syncLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many sync requests',
    message: 'Please try again in a minute',
  },
});

// Search endpoints - 30 requests per minute
export const searchLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many search requests',
    message: 'Please slow down your searches',
  },
});
