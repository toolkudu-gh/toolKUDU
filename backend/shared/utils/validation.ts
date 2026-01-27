import { APIGatewayProxyEvent } from 'aws-lambda';

export interface ValidationError {
  field: string;
  message: string;
}

export function parseBody<T>(event: APIGatewayProxyEvent): T | null {
  if (!event.body) {
    return null;
  }

  try {
    return JSON.parse(event.body) as T;
  } catch {
    return null;
  }
}

export function getPathParam(
  event: APIGatewayProxyEvent,
  name: string
): string | null {
  return event.pathParameters?.[name] || null;
}

export function getQueryParam(
  event: APIGatewayProxyEvent,
  name: string
): string | null {
  return event.queryStringParameters?.[name] || null;
}

export function getQueryParamInt(
  event: APIGatewayProxyEvent,
  name: string,
  defaultValue: number
): number {
  const value = getQueryParam(event, name);
  if (!value) return defaultValue;

  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? defaultValue : parsed;
}

export function isValidUUID(str: string): boolean {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function isNonEmptyString(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}

export function validateRequired(
  obj: Record<string, unknown>,
  fields: string[]
): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const field of fields) {
    const value = obj[field];
    if (value === undefined || value === null || value === '') {
      errors.push({
        field,
        message: `${field} is required`,
      });
    }
  }

  return errors;
}

export function validateStringLength(
  value: string,
  field: string,
  min: number,
  max: number
): ValidationError | null {
  if (value.length < min) {
    return {
      field,
      message: `${field} must be at least ${min} characters`,
    };
  }
  if (value.length > max) {
    return {
      field,
      message: `${field} must not exceed ${max} characters`,
    };
  }
  return null;
}

export function validateEnum(
  value: string,
  field: string,
  allowedValues: string[]
): ValidationError | null {
  if (!allowedValues.includes(value)) {
    return {
      field,
      message: `${field} must be one of: ${allowedValues.join(', ')}`,
    };
  }
  return null;
}

// Generic validator builder
export type Validator<T> = (value: T) => ValidationError[];

export function validate<T>(
  data: T,
  ...validators: Validator<T>[]
): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const validator of validators) {
    errors.push(...validator(data));
  }

  return errors;
}

export function formatValidationErrors(errors: ValidationError[]): string {
  return errors.map((e) => `${e.field}: ${e.message}`).join('; ');
}
