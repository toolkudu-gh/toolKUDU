export interface User {
  id: string;
  cognito_sub: string;
  username: string;
  email: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
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

export interface CreateUserInput {
  cognitoSub: string;
  username: string;
  email: string;
  displayName?: string;
}

export interface UpdateUserInput {
  displayName?: string;
  bio?: string;
  avatarUrl?: string;
}

export interface Follow {
  id: string;
  follower_id: string;
  following_id: string;
  created_at: Date;
}

export interface BuddyRequest {
  id: string;
  requester_id: string;
  target_id: string;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: Date;
  responded_at: Date | null;
}

export interface Buddy {
  id: string;
  user_id: string;
  buddy_id: string;
  created_at: Date;
}

export interface BuddyRequestWithUser extends BuddyRequest {
  requester: UserProfile;
}
