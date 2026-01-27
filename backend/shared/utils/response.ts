import { APIGatewayProxyResult } from 'aws-lambda';

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

const defaultHeaders: Record<string, string> = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

export function success<T>(data: T, statusCode = 200): APIGatewayProxyResult {
  return {
    statusCode,
    headers: defaultHeaders,
    body: JSON.stringify({
      success: true,
      data,
    } as ApiResponse<T>),
  };
}

export function created<T>(data: T): APIGatewayProxyResult {
  return success(data, 201);
}

export function noContent(): APIGatewayProxyResult {
  return {
    statusCode: 204,
    headers: defaultHeaders,
    body: '',
  };
}

export function error(
  message: string,
  statusCode = 500,
  details?: string
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: defaultHeaders,
    body: JSON.stringify({
      success: false,
      error: message,
      message: process.env.NODE_ENV === 'development' ? details : undefined,
    } as ApiResponse),
  };
}

export function badRequest(message = 'Bad request'): APIGatewayProxyResult {
  return error(message, 400);
}

export function unauthorized(message = 'Unauthorized'): APIGatewayProxyResult {
  return error(message, 401);
}

export function forbidden(message = 'Forbidden'): APIGatewayProxyResult {
  return error(message, 403);
}

export function notFound(message = 'Not found'): APIGatewayProxyResult {
  return error(message, 404);
}

export function conflict(message = 'Conflict'): APIGatewayProxyResult {
  return error(message, 409);
}

export function serverError(
  message = 'Internal server error',
  details?: string
): APIGatewayProxyResult {
  return error(message, 500, details);
}

// CORS preflight response
export function cors(): APIGatewayProxyResult {
  return {
    statusCode: 200,
    headers: defaultHeaders,
    body: '',
  };
}

// Paginated response
export interface PaginatedData<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export function paginated<T>(
  items: T[],
  total: number,
  page: number,
  pageSize: number
): APIGatewayProxyResult {
  return success<PaginatedData<T>>({
    items,
    total,
    page,
    pageSize,
    hasMore: page * pageSize < total,
  });
}
