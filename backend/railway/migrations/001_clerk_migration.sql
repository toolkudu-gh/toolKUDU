-- Migration: Update schema for Clerk authentication
-- Rename cognito_sub to clerk_id and add location fields

-- Check if column exists before renaming (idempotent)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'cognito_sub'
    ) THEN
        ALTER TABLE users RENAME COLUMN cognito_sub TO clerk_id;
        DROP INDEX IF EXISTS idx_users_cognito_sub;
        CREATE INDEX IF NOT EXISTS idx_users_clerk_id ON users(clerk_id);
    END IF;
END $$;

-- Add location fields to users table (for tool search)
ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS zipcode VARCHAR(10);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_source VARCHAR(20) CHECK (location_source IS NULL OR location_source IN ('gps', 'zipcode', 'manual'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMP WITH TIME ZONE;

-- Add username change tracking
ALTER TABLE users ADD COLUMN IF NOT EXISTS username_changed_at TIMESTAMP WITH TIME ZONE;

-- Create index for location-based queries
CREATE INDEX IF NOT EXISTS idx_users_location ON users(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Add tool availability status for search
ALTER TABLE tools ADD COLUMN IF NOT EXISTS available_for_borrow BOOLEAN DEFAULT true;
CREATE INDEX IF NOT EXISTS idx_tools_borrow ON tools(available_for_borrow) WHERE available_for_borrow = true;
