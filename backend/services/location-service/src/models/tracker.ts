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
  updated_at: Date;
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

export interface LocationHistory {
  id: string;
  tracker_id: string;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  recorded_at: Date;
}

export interface LocationHistoryResponse {
  latitude: number;
  longitude: number;
  accuracy: number | null;
  recordedAt: Date;
}

export interface AddTrackerInput {
  trackerType: TrackerType;
  trackerIdentifier: string;
  trackerName?: string;
  toolboxId?: string; // If tool needs to be categorized
}

export interface UpdateLocationInput {
  latitude: number;
  longitude: number;
  accuracy?: number;
}
