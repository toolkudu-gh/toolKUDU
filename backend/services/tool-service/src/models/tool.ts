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

export interface CreateToolboxInput {
  name: string;
  description?: string;
  visibility?: VisibilityType;
  icon?: string;
  color?: string;
}

export interface UpdateToolboxInput {
  name?: string;
  description?: string;
  visibility?: VisibilityType;
  icon?: string;
  color?: string;
}

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

export interface CreateToolInput {
  name: string;
  description?: string;
  category?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  purchaseDate?: string;
  purchasePrice?: number;
  notes?: string;
}

export interface UpdateToolInput {
  name?: string;
  description?: string;
  category?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  purchaseDate?: string;
  purchasePrice?: number;
  notes?: string;
  toolboxId?: string; // Allow moving to different toolbox
}

export interface AddImageInput {
  s3Key: string;
  orderIndex?: number;
}
