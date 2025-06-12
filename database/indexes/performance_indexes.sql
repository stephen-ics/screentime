-- =====================================================
-- INDEXES: performance_indexes.sql
-- Description: Performance indexes for all tables
-- Dependencies: All schema files
-- =====================================================

-- =====================================================
-- PROFILES TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
-- Foreign key indexes
CREATE INDEX IF NOT EXISTS idx_profiles_parent_id ON profiles(parent_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON profiles(user_type);

-- =====================================================
-- FAMILY PROFILES TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_family_profiles_auth_user_id ON family_profiles(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_family_profiles_role ON family_profiles(role);

-- =====================================================
-- TIME BANKS TABLE INDEXES
-- =====================================================

-- Primary key and unique constraint indexes are automatically created
CREATE INDEX IF NOT EXISTS idx_time_banks_user_id ON time_banks(user_id);
CREATE INDEX IF NOT EXISTS idx_time_banks_current_balance ON time_banks(current_balance_seconds);
CREATE INDEX IF NOT EXISTS idx_time_banks_updated_at ON time_banks(updated_at);

-- =====================================================
-- TIME LEDGER ENTRIES TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_time_ledger_user_id ON time_ledger_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_time_ledger_created_at ON time_ledger_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_time_ledger_transaction_type ON time_ledger_entries(transaction_type);
CREATE INDEX IF NOT EXISTS idx_time_ledger_source ON time_ledger_entries(source);
CREATE INDEX IF NOT EXISTS idx_time_ledger_created_by ON time_ledger_entries(created_by);

-- Composite index for user transaction history queries
CREATE INDEX IF NOT EXISTS idx_time_ledger_user_created ON time_ledger_entries(user_id, created_at DESC);

-- =====================================================
-- UNLOCKED SESSIONS TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_user_id ON unlocked_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_status ON unlocked_sessions(status);
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_ends_at ON unlocked_sessions(ends_at);
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_started_at ON unlocked_sessions(started_at);

-- Composite index for finding active sessions
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_active ON unlocked_sessions(user_id, status, ends_at) 
    WHERE status = 'active';

-- Composite index for session history queries
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_user_time ON unlocked_sessions(user_id, started_at DESC);

-- =====================================================
-- TASKS TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks(completed_at);
CREATE INDEX IF NOT EXISTS idx_tasks_is_approved ON tasks(is_approved);
CREATE INDEX IF NOT EXISTS idx_tasks_is_recurring ON tasks(is_recurring);

-- Composite index for task management queries
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status ON tasks(assigned_to, is_approved, completed_at);

-- =====================================================
-- APPROVED APPS TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
-- Unique constraint index is automatically created
CREATE INDEX IF NOT EXISTS idx_approved_apps_user_id ON approved_apps(user_id);
CREATE INDEX IF NOT EXISTS idx_approved_apps_bundle_identifier ON approved_apps(bundle_identifier);
CREATE INDEX IF NOT EXISTS idx_approved_apps_is_enabled ON approved_apps(is_enabled);

-- Composite index for finding enabled apps
CREATE INDEX IF NOT EXISTS idx_approved_apps_enabled ON approved_apps(user_id, is_enabled) 
    WHERE is_enabled = true;

-- =====================================================
-- OFFLINE TRANSACTION QUEUE TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_offline_queue_user_id ON offline_transaction_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_queue_processed ON offline_transaction_queue(processed_at);
CREATE INDEX IF NOT EXISTS idx_offline_queue_client_timestamp ON offline_transaction_queue(client_timestamp);
CREATE INDEX IF NOT EXISTS idx_offline_queue_retry_count ON offline_transaction_queue(retry_count);

-- Composite index for finding pending transactions
CREATE INDEX IF NOT EXISTS idx_offline_queue_pending ON offline_transaction_queue(user_id, client_timestamp ASC) 
    WHERE processed_at IS NULL;

-- Composite index for finding failed transactions
CREATE INDEX IF NOT EXISTS idx_offline_queue_failed ON offline_transaction_queue(user_id, retry_count, processed_at) 
    WHERE processed_at IS NOT NULL AND error_message IS NOT NULL;

-- =====================================================
-- SCHEMA MIGRATIONS TABLE INDEXES
-- =====================================================

-- Primary key index is automatically created
CREATE INDEX IF NOT EXISTS idx_schema_migrations_applied_at ON schema_migrations(applied_at);

-- Comments for documentation
COMMENT ON INDEX idx_time_ledger_user_created IS 'Optimizes user transaction history queries with ordering';
COMMENT ON INDEX idx_unlocked_sessions_active IS 'Optimizes finding active sessions for a user';
COMMENT ON INDEX idx_tasks_pending IS 'Optimizes finding incomplete tasks for a user';
COMMENT ON INDEX idx_approved_apps_enabled IS 'Optimizes finding enabled apps for a user';
COMMENT ON INDEX idx_offline_queue_pending IS 'Optimizes finding unprocessed offline transactions in chronological order'; 