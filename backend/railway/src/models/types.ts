// ==================== USER TYPES ====================

export interface User {
  id: string;
  clerk_id: string;
  email: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  latitude: number | null;
  longitude: number | null;
  zipcode: string | null;
  location_source: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface UserProfile {
  id: string;
  username: string;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
  followersCount: number;
  followingCount: number;
  isFollowing?: boolean;
  isBuddy?: boolean;
}

export interface BuddyRequest {
  id: string;
  requester_id: string;
  target_id: string;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: Date;
  responded_at: Date | null;
}

// ==================== TOOLBOX TYPES ====================

export type VisibilityType = 'private' | 'buddies' | 'public';

export interface Toolbox {
  id: string;
  user_id: string;
  name: string;
  description: string | null;
  visibility: VisibilityType;
  icon: string | null;
  color: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface ToolboxResponse {
  id: string;
  userId: string;
  name: string;
  description: string | null;
  visibility: VisibilityType;
  icon: string | null;
  color: string | null;
  toolCount: number;
  createdAt: Date;
  updatedAt: Date;
}

// ==================== TOOL TYPES ====================

export interface Tool {
  id: string;
  toolbox_id: string;
  name: string;
  description: string | null;
  category: string | null;
  brand: string | null;
  model: string | null;
  serial_number: string | null;
  purchase_date: Date | null;
  purchase_price: number | null;
  notes: string | null;
  is_available: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface ToolImage {
  id: string;
  tool_id: string;
  s3_key: string;
  s3_bucket: string;
  order_index: number;
  created_at: Date;
}

export interface ToolResponse {
  id: string;
  toolboxId: string;
  name: string;
  description: string | null;
  category: string | null;
  brand: string | null;
  model: string | null;
  serialNumber: string | null;
  purchaseDate: Date | null;
  purchasePrice: number | null;
  notes: string | null;
  isAvailable: boolean;
  images: ToolImageResponse[];
  hasTracker: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface ToolImageResponse {
  id: string;
  url: string;
  orderIndex: number;
}

// ==================== TRACKER TYPES ====================

export type TrackerType = 'airtag' | 'tile' | 'gps_cellular' | 'gps_satellite' | 'other';

export interface ToolTracker {
  id: string;
  tool_id: string;
  tracker_type: TrackerType;
  tracker_identifier: string;
  tracker_name: string | null;
  last_latitude: number | null;
  last_longitude: number | null;
  last_location_accuracy: number | null;
  last_seen: Date | null;
  is_active: boolean;
  created_at: Date;
}

export interface TrackerResponse {
  id: string;
  toolId: string;
  toolName: string;
  trackerType: TrackerType;
  trackerIdentifier: string;
  trackerName: string | null;
  location: {
    latitude: number;
    longitude: number;
    accuracy: number | null;
  } | null;
  lastSeen: Date | null;
  isActive: boolean;
  createdAt: Date;
}

// ==================== LENDING TYPES ====================

export type LendingStatus = 'pending' | 'approved' | 'denied' | 'active' | 'returned' | 'cancelled';

export interface LendingRequest {
  id: string;
  tool_id: string;
  requester_id: string;
  owner_id: string;
  status: LendingStatus;
  message: string | null;
  response_message: string | null;
  requested_at: Date;
  responded_at: Date | null;
}

export interface LendingHistory {
  id: string;
  tool_id: string;
  borrower_id: string;
  owner_id: string;
  lending_request_id: string;
  borrowed_at: Date;
  returned_at: Date | null;
}
