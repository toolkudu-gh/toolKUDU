-- ToolKUDU Database Schema
-- PostgreSQL

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================
-- USERS & AUTHENTICATION
-- =====================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cognito_sub VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_cognito_sub ON users(cognito_sub);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- =====================
-- SOCIAL / BUDDIES
-- =====================

-- Follow relationships (one-way)
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- Buddy requests (mutual buddy relationship)
CREATE TABLE buddy_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(requester_id, target_id)
);

CREATE INDEX idx_buddy_requests_requester ON buddy_requests(requester_id);
CREATE INDEX idx_buddy_requests_target ON buddy_requests(target_id);
CREATE INDEX idx_buddy_requests_status ON buddy_requests(status);

-- Buddies (mutual, created when buddy request accepted)
CREATE TABLE buddies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    buddy_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, buddy_id)
);

CREATE INDEX idx_buddies_user ON buddies(user_id);
CREATE INDEX idx_buddies_buddy ON buddies(buddy_id);

-- =====================
-- TOOLBOXES & TOOLS
-- =====================

-- Visibility enum type
CREATE TYPE visibility_type AS ENUM ('private', 'buddies', 'public');

CREATE TABLE toolboxes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    visibility visibility_type NOT NULL DEFAULT 'private',
    icon VARCHAR(50),
    color VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_toolboxes_user ON toolboxes(user_id);
CREATE INDEX idx_toolboxes_visibility ON toolboxes(visibility);

-- Granular permissions for specific users to access toolboxes
CREATE TABLE toolbox_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    toolbox_id UUID NOT NULL REFERENCES toolboxes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) NOT NULL DEFAULT 'view' CHECK (permission_level IN ('view', 'borrow')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(toolbox_id, user_id)
);

CREATE INDEX idx_toolbox_permissions_toolbox ON toolbox_permissions(toolbox_id);
CREATE INDEX idx_toolbox_permissions_user ON toolbox_permissions(user_id);

-- Tools
CREATE TABLE tools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    toolbox_id UUID NOT NULL REFERENCES toolboxes(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    brand VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    purchase_date DATE,
    purchase_price DECIMAL(10, 2),
    notes TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tools_toolbox ON tools(toolbox_id);
CREATE INDEX idx_tools_category ON tools(category);
CREATE INDEX idx_tools_available ON tools(is_available);

-- Tool images (up to 3 per tool)
CREATE TABLE tool_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
    s3_key VARCHAR(500) NOT NULL,
    s3_bucket VARCHAR(100) NOT NULL,
    order_index SMALLINT NOT NULL DEFAULT 0 CHECK (order_index >= 0 AND order_index < 3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tool_id, order_index)
);

CREATE INDEX idx_tool_images_tool ON tool_images(tool_id);

-- =====================
-- GPS TRACKING
-- =====================

CREATE TYPE tracker_type AS ENUM ('airtag', 'tile', 'gps_cellular', 'gps_satellite', 'other');

CREATE TABLE tool_trackers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
    tracker_type tracker_type NOT NULL,
    tracker_identifier VARCHAR(255) NOT NULL,
    tracker_name VARCHAR(100),
    last_latitude DECIMAL(10, 8),
    last_longitude DECIMAL(11, 8),
    last_location_accuracy DECIMAL(10, 2),
    last_seen TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tool_id)
);

CREATE INDEX idx_tool_trackers_tool ON tool_trackers(tool_id);
CREATE INDEX idx_tool_trackers_active ON tool_trackers(is_active);

-- Location history for tracked tools
CREATE TABLE location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracker_id UUID NOT NULL REFERENCES tool_trackers(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(10, 2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_location_history_tracker ON location_history(tracker_id);
CREATE INDEX idx_location_history_recorded ON location_history(recorded_at);

-- =====================
-- LENDING SYSTEM
-- =====================

CREATE TYPE lending_status AS ENUM ('pending', 'approved', 'denied', 'active', 'returned', 'cancelled');

CREATE TABLE lending_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status lending_status NOT NULL DEFAULT 'pending',
    message TEXT,
    response_message TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(tool_id, requester_id, status) -- Prevent duplicate pending requests
);

CREATE INDEX idx_lending_requests_tool ON lending_requests(tool_id);
CREATE INDEX idx_lending_requests_requester ON lending_requests(requester_id);
CREATE INDEX idx_lending_requests_owner ON lending_requests(owner_id);
CREATE INDEX idx_lending_requests_status ON lending_requests(status);

CREATE TABLE lending_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
    borrower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lending_request_id UUID REFERENCES lending_requests(id) ON DELETE SET NULL,
    borrowed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    returned_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

CREATE INDEX idx_lending_history_tool ON lending_history(tool_id);
CREATE INDEX idx_lending_history_borrower ON lending_history(borrower_id);
CREATE INDEX idx_lending_history_owner ON lending_history(owner_id);

-- =====================
-- NOTIFICATIONS
-- =====================

CREATE TYPE notification_type AS ENUM (
    'buddy_request',
    'buddy_accepted',
    'new_follower',
    'lending_request',
    'lending_approved',
    'lending_denied',
    'tool_returned',
    'tool_reminder'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- Push notification tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(token)
);

CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(is_active);

-- =====================
-- FUNCTIONS & TRIGGERS
-- =====================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_toolboxes_updated_at BEFORE UPDATE ON toolboxes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tools_updated_at BEFORE UPDATE ON tools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tool_trackers_updated_at BEFORE UPDATE ON tool_trackers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON push_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create mutual buddy relationship when request is accepted
CREATE OR REPLACE FUNCTION create_buddy_on_accept()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        -- Create bidirectional buddy entries
        INSERT INTO buddies (user_id, buddy_id) VALUES (NEW.requester_id, NEW.target_id)
            ON CONFLICT DO NOTHING;
        INSERT INTO buddies (user_id, buddy_id) VALUES (NEW.target_id, NEW.requester_id)
            ON CONFLICT DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER create_buddy_trigger AFTER UPDATE ON buddy_requests
    FOR EACH ROW EXECUTE FUNCTION create_buddy_on_accept();
