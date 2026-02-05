import { Request } from 'express';

export interface PaginationParams {
  page: number;
  pageSize: number;
  offset: number;
}

export function getPagination(req: Request, defaultPageSize = 20): PaginationParams {
  const page = Math.max(1, parseInt(req.query.page as string) || 1);
  const pageSize = Math.min(100, Math.max(1, parseInt(req.query.pageSize as string) || defaultPageSize));
  const offset = (page - 1) * pageSize;

  return { page, pageSize, offset };
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
    hasMore: boolean;
  };
}

export function paginate<T>(
  data: T[],
  total: number,
  page: number,
  pageSize: number
): PaginatedResponse<T> {
  const totalPages = Math.ceil(total / pageSize);

  return {
    data,
    pagination: {
      page,
      pageSize,
      total,
      totalPages,
      hasMore: page < totalPages,
    },
  };
}
