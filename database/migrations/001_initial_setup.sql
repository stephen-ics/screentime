-- =====================================================
-- MIGRATION: 001_initial_setup.sql
-- Description: Initial database setup with extensions
-- Date: 2024-01-01
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Add migration tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    description TEXT
);

-- Record this migration
INSERT INTO schema_migrations (version, description) 
VALUES ('001', 'Initial setup with extensions')
ON CONFLICT (version) DO NOTHING;

-- Success message
SELECT 'Migration 001: Initial setup completed' AS status; 