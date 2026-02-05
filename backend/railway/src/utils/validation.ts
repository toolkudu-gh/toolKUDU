// UUID validation regex
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isValidUUID(value: string): boolean {
  return UUID_REGEX.test(value);
}

export function validateRequired<T extends object>(
  body: T,
  fields: (keyof T)[]
): string[] {
  const errors: string[] = [];
  for (const field of fields) {
    if (body[field] === undefined || body[field] === null || body[field] === '') {
      errors.push(`${String(field)} is required`);
    }
  }
  return errors;
}

export function formatValidationErrors(errors: string[]): string {
  return errors.join(', ');
}

// Allowed image content types
export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

export function isValidImageType(contentType: string): boolean {
  return ALLOWED_IMAGE_TYPES.includes(contentType);
}

// Visibility types
export type VisibilityType = 'private' | 'buddies' | 'public';
export const VALID_VISIBILITIES: VisibilityType[] = ['private', 'buddies', 'public'];

export function isValidVisibility(value: string): value is VisibilityType {
  return VALID_VISIBILITIES.includes(value as VisibilityType);
}

// Tracker types
export type TrackerType = 'airtag' | 'tile' | 'gps_cellular' | 'gps_satellite' | 'other';
export const VALID_TRACKER_TYPES: TrackerType[] = ['airtag', 'tile', 'gps_cellular', 'gps_satellite', 'other'];

export function isValidTrackerType(value: string): value is TrackerType {
  return VALID_TRACKER_TYPES.includes(value as TrackerType);
}

// Lending statuses
export type LendingStatus = 'pending' | 'approved' | 'denied' | 'active' | 'returned' | 'cancelled';
export const VALID_LENDING_STATUSES: LendingStatus[] = ['pending', 'approved', 'denied', 'active', 'returned', 'cancelled'];

export function isValidLendingStatus(value: string): value is LendingStatus {
  return VALID_LENDING_STATUSES.includes(value as LendingStatus);
}
