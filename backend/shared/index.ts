// Database
export {
  getPool,
  query,
  queryOne,
  queryReturning,
  getClient,
  transaction,
  closePool,
  DatabaseConfig,
} from './db/client';

// Authentication
export {
  verifyToken,
  extractToken,
  authenticate,
  withAuth,
  CognitoConfig,
  CognitoUser,
  AuthenticatedEvent,
} from './auth/cognito';

// Response utilities
export {
  success,
  created,
  noContent,
  error,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  cors,
  paginated,
  ApiResponse,
  PaginatedData,
} from './utils/response';

// Validation utilities
export {
  parseBody,
  getPathParam,
  getQueryParam,
  getQueryParamInt,
  isValidUUID,
  isValidEmail,
  isNonEmptyString,
  validateRequired,
  validateStringLength,
  validateEnum,
  validate,
  formatValidationErrors,
  ValidationError,
  Validator,
} from './utils/validation';
