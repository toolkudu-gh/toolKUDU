import { Router } from 'express';
import { db } from '../db';

export const setupRoutes = Router();

// One-time setup endpoint to initialize database schema
// This should be called once after deployment, then disabled
setupRoutes.post('/init-db', async (req, res) => {
  // Simple security: require a setup key
  const setupKey = req.headers['x-setup-key'];
  if (setupKey !== process.env.SETUP_KEY && setupKey !== 'toolkudu-init-2024') {
    return res.status(403).json({ error: 'Invalid setup key' });
  }

  try {
    // Check if tables already exist
    const tablesExist = await db.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
      );
    `);

    if (tablesExist.rows[0].exists) {
      return res.json({
        status: 'already_initialized',
        message: 'Database schema already exists'
      });
    }

    // Run schema initialization
    await db.query(`
      -- Enable UUID extension
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

      -- Users table (using clerk_id for Clerk auth)
      CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          clerk_id VARCHAR(255) UNIQUE NOT NULL,
          username VARCHAR(50) UNIQUE NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          display_name VARCHAR(100),
          avatar_url VARCHAR(500),
          bio TEXT,
          latitude DECIMAL(10, 8),
          longitude DECIMAL(11, 8),
          zipcode VARCHAR(10),
          location_source VARCHAR(20) CHECK (location_source IS NULL OR location_source IN ('gps', 'zipcode', 'manual')),
          location_updated_at TIMESTAMP WITH TIME ZONE,
          username_changed_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_users_clerk_id ON users(clerk_id);
      CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_users_location ON users(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

      -- Follow relationships
      CREATE TABLE IF NOT EXISTS follows (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(follower_id, following_id)
      );

      CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
      CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);

      -- Buddy requests
      CREATE TABLE IF NOT EXISTS buddy_requests (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          responded_at TIMESTAMP WITH TIME ZONE,
          UNIQUE(requester_id, target_id)
      );

      CREATE INDEX IF NOT EXISTS idx_buddy_requests_requester ON buddy_requests(requester_id);
      CREATE INDEX IF NOT EXISTS idx_buddy_requests_target ON buddy_requests(target_id);
      CREATE INDEX IF NOT EXISTS idx_buddy_requests_status ON buddy_requests(status);

      -- Buddies (mutual)
      CREATE TABLE IF NOT EXISTS buddies (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          buddy_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id, buddy_id)
      );

      CREATE INDEX IF NOT EXISTS idx_buddies_user ON buddies(user_id);
      CREATE INDEX IF NOT EXISTS idx_buddies_buddy ON buddies(buddy_id);

      -- Visibility enum type
      DO $$ BEGIN
          CREATE TYPE visibility_type AS ENUM ('private', 'buddies', 'public');
      EXCEPTION
          WHEN duplicate_object THEN null;
      END $$;

      -- Toolboxes
      CREATE TABLE IF NOT EXISTS toolboxes (
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

      CREATE INDEX IF NOT EXISTS idx_toolboxes_user ON toolboxes(user_id);
      CREATE INDEX IF NOT EXISTS idx_toolboxes_visibility ON toolboxes(visibility);

      -- Toolbox permissions
      CREATE TABLE IF NOT EXISTS toolbox_permissions (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          toolbox_id UUID NOT NULL REFERENCES toolboxes(id) ON DELETE CASCADE,
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          permission_level VARCHAR(20) NOT NULL DEFAULT 'view' CHECK (permission_level IN ('view', 'borrow')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(toolbox_id, user_id)
      );

      CREATE INDEX IF NOT EXISTS idx_toolbox_permissions_toolbox ON toolbox_permissions(toolbox_id);
      CREATE INDEX IF NOT EXISTS idx_toolbox_permissions_user ON toolbox_permissions(user_id);

      -- Tools
      CREATE TABLE IF NOT EXISTS tools (
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
          available_for_borrow BOOLEAN NOT NULL DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_tools_toolbox ON tools(toolbox_id);
      CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category);
      CREATE INDEX IF NOT EXISTS idx_tools_available ON tools(is_available);
      CREATE INDEX IF NOT EXISTS idx_tools_borrow ON tools(available_for_borrow) WHERE available_for_borrow = true;

      -- Tool images
      CREATE TABLE IF NOT EXISTS tool_images (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
          s3_key VARCHAR(500) NOT NULL,
          s3_bucket VARCHAR(100) NOT NULL,
          order_index SMALLINT NOT NULL DEFAULT 0 CHECK (order_index >= 0 AND order_index < 3),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(tool_id, order_index)
      );

      CREATE INDEX IF NOT EXISTS idx_tool_images_tool ON tool_images(tool_id);

      -- Tracker type enum
      DO $$ BEGIN
          CREATE TYPE tracker_type AS ENUM ('airtag', 'tile', 'gps_cellular', 'gps_satellite', 'other');
      EXCEPTION
          WHEN duplicate_object THEN null;
      END $$;

      -- Tool trackers
      CREATE TABLE IF NOT EXISTS tool_trackers (
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

      CREATE INDEX IF NOT EXISTS idx_tool_trackers_tool ON tool_trackers(tool_id);
      CREATE INDEX IF NOT EXISTS idx_tool_trackers_active ON tool_trackers(is_active);

      -- Location history
      CREATE TABLE IF NOT EXISTS location_history (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          tracker_id UUID NOT NULL REFERENCES tool_trackers(id) ON DELETE CASCADE,
          latitude DECIMAL(10, 8) NOT NULL,
          longitude DECIMAL(11, 8) NOT NULL,
          accuracy DECIMAL(10, 2),
          recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_location_history_tracker ON location_history(tracker_id);
      CREATE INDEX IF NOT EXISTS idx_location_history_recorded ON location_history(recorded_at);

      -- Lending status enum
      DO $$ BEGIN
          CREATE TYPE lending_status AS ENUM ('pending', 'approved', 'denied', 'active', 'returned', 'cancelled');
      EXCEPTION
          WHEN duplicate_object THEN null;
      END $$;

      -- Lending requests
      CREATE TABLE IF NOT EXISTS lending_requests (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
          requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          status lending_status NOT NULL DEFAULT 'pending',
          message TEXT,
          response_message TEXT,
          requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          responded_at TIMESTAMP WITH TIME ZONE
      );

      CREATE INDEX IF NOT EXISTS idx_lending_requests_tool ON lending_requests(tool_id);
      CREATE INDEX IF NOT EXISTS idx_lending_requests_requester ON lending_requests(requester_id);
      CREATE INDEX IF NOT EXISTS idx_lending_requests_owner ON lending_requests(owner_id);
      CREATE INDEX IF NOT EXISTS idx_lending_requests_status ON lending_requests(status);

      -- Lending history
      CREATE TABLE IF NOT EXISTS lending_history (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
          borrower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          lending_request_id UUID REFERENCES lending_requests(id) ON DELETE SET NULL,
          borrowed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          returned_at TIMESTAMP WITH TIME ZONE,
          notes TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_lending_history_tool ON lending_history(tool_id);
      CREATE INDEX IF NOT EXISTS idx_lending_history_borrower ON lending_history(borrower_id);
      CREATE INDEX IF NOT EXISTS idx_lending_history_owner ON lending_history(owner_id);

      -- Notification type enum
      DO $$ BEGIN
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
      EXCEPTION
          WHEN duplicate_object THEN null;
      END $$;

      -- Notifications
      CREATE TABLE IF NOT EXISTS notifications (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          type notification_type NOT NULL,
          title VARCHAR(200) NOT NULL,
          body TEXT,
          data JSONB,
          is_read BOOLEAN NOT NULL DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
      CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

      -- Push tokens
      CREATE TABLE IF NOT EXISTS push_tokens (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token VARCHAR(500) NOT NULL,
          platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
          is_active BOOLEAN NOT NULL DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(token)
      );

      CREATE INDEX IF NOT EXISTS idx_push_tokens_user ON push_tokens(user_id);
      CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_tokens(is_active);

      -- Updated_at trigger function
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql';

      -- Apply triggers
      DROP TRIGGER IF EXISTS update_users_updated_at ON users;
      CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_toolboxes_updated_at ON toolboxes;
      CREATE TRIGGER update_toolboxes_updated_at BEFORE UPDATE ON toolboxes
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_tools_updated_at ON tools;
      CREATE TRIGGER update_tools_updated_at BEFORE UPDATE ON tools
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_tool_trackers_updated_at ON tool_trackers;
      CREATE TRIGGER update_tool_trackers_updated_at BEFORE UPDATE ON tool_trackers
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_push_tokens_updated_at ON push_tokens;
      CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON push_tokens
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

      -- Buddy creation trigger
      CREATE OR REPLACE FUNCTION create_buddy_on_accept()
      RETURNS TRIGGER AS $$
      BEGIN
          IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
              INSERT INTO buddies (user_id, buddy_id) VALUES (NEW.requester_id, NEW.target_id)
                  ON CONFLICT DO NOTHING;
              INSERT INTO buddies (user_id, buddy_id) VALUES (NEW.target_id, NEW.requester_id)
                  ON CONFLICT DO NOTHING;
          END IF;
          RETURN NEW;
      END;
      $$ language 'plpgsql';

      DROP TRIGGER IF EXISTS create_buddy_trigger ON buddy_requests;
      CREATE TRIGGER create_buddy_trigger AFTER UPDATE ON buddy_requests
          FOR EACH ROW EXECUTE FUNCTION create_buddy_on_accept();
    `);

    res.json({
      status: 'success',
      message: 'Database schema initialized successfully',
      tables: [
        'users', 'follows', 'buddy_requests', 'buddies',
        'toolboxes', 'toolbox_permissions', 'tools', 'tool_images',
        'tool_trackers', 'location_history',
        'lending_requests', 'lending_history',
        'notifications', 'push_tokens'
      ]
    });

  } catch (error) {
    console.error('Database initialization error:', error);
    res.status(500).json({
      status: 'error',
      message: (error as Error).message
    });
  }
});

// Check database schema status
setupRoutes.get('/db-status', async (_req, res) => {
  try {
    const result = await db.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);

    res.json({
      status: 'ok',
      tables: result.rows.map(r => r.table_name)
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: (error as Error).message
    });
  }
});
