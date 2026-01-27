export type PermissionLevel = 'view' | 'borrow';
export type LendingStatus = 'pending' | 'approved' | 'denied' | 'active' | 'returned' | 'cancelled';

export interface ToolboxPermission {
  id: string;
  toolbox_id: string;
  user_id: string;
  permission_level: PermissionLevel;
  created_at: Date;
}

export interface ToolboxPermissionResponse {
  id: string;
  userId: string;
  username: string;
  displayName: string | null;
  avatarUrl: string | null;
  permissionLevel: PermissionLevel;
  createdAt: Date;
}

export interface AddPermissionInput {
  userId: string;
  permissionLevel?: PermissionLevel;
}

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

export interface LendingRequestResponse {
  id: string;
  tool: {
    id: string;
    name: string;
    description: string | null;
  };
  requester: {
    id: string;
    username: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  owner: {
    id: string;
    username: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  status: LendingStatus;
  message: string | null;
  responseMessage: string | null;
  requestedAt: Date;
  respondedAt: Date | null;
}

export interface LendingHistory {
  id: string;
  tool_id: string;
  borrower_id: string;
  owner_id: string;
  lending_request_id: string | null;
  borrowed_at: Date;
  returned_at: Date | null;
  notes: string | null;
}

export interface CreateLendingRequestInput {
  message?: string;
}

export interface RespondToRequestInput {
  approve: boolean;
  message?: string;
}
