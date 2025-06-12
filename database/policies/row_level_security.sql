-- =====================================================
-- POLICIES: row_level_security.sql
-- Description: Row Level Security policies for all tables
-- Dependencies: All schema files
-- =====================================================

-- =====================================================
-- PROFILES TABLE POLICIES
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;  
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;  
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (true); -- Allow trigger to insert during signup

DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;
CREATE POLICY "Service role can manage profiles" ON profiles
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- FAMILY PROFILES TABLE POLICIES
-- =====================================================

ALTER TABLE family_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own family profiles" ON family_profiles;
CREATE POLICY "Users can view their own family profiles" ON family_profiles
    FOR SELECT USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can insert their own family profiles" ON family_profiles;
CREATE POLICY "Users can insert their own family profiles" ON family_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can update their own family profiles" ON family_profiles;
CREATE POLICY "Users can update their own family profiles" ON family_profiles
    FOR UPDATE USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can delete their own family profiles" ON family_profiles;
CREATE POLICY "Users can delete their own family profiles" ON family_profiles
    FOR DELETE USING (auth.uid() = auth_user_id);

-- =====================================================
-- TIME BANKS TABLE POLICIES
-- =====================================================

ALTER TABLE time_banks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own time bank" ON time_banks;
CREATE POLICY "Users can view own time bank" ON time_banks
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage time banks" ON time_banks;
CREATE POLICY "Service role can manage time banks" ON time_banks
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- TIME LEDGER ENTRIES TABLE POLICIES  
-- =====================================================

ALTER TABLE time_ledger_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own ledger entries" ON time_ledger_entries;
CREATE POLICY "Users can view own ledger entries" ON time_ledger_entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage ledger entries" ON time_ledger_entries;
CREATE POLICY "Service role can manage ledger entries" ON time_ledger_entries
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- UNLOCKED SESSIONS TABLE POLICIES
-- =====================================================

ALTER TABLE unlocked_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own unlocked sessions" ON unlocked_sessions;
CREATE POLICY "Users can view own unlocked sessions" ON unlocked_sessions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage unlocked sessions" ON unlocked_sessions;
CREATE POLICY "Service role can manage unlocked sessions" ON unlocked_sessions
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- TASKS TABLE POLICIES
-- =====================================================

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view assigned tasks" ON tasks;
CREATE POLICY "Users can view assigned tasks" ON tasks
    FOR SELECT USING (auth.uid() = assigned_to);

DROP POLICY IF EXISTS "Users can view created tasks" ON tasks;
CREATE POLICY "Users can view created tasks" ON tasks
    FOR SELECT USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Service role can manage tasks" ON tasks;
CREATE POLICY "Service role can manage tasks" ON tasks
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- APPROVED APPS TABLE POLICIES
-- =====================================================

ALTER TABLE approved_apps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own approved apps" ON approved_apps;
CREATE POLICY "Users can view own approved apps" ON approved_apps
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage approved apps" ON approved_apps;
CREATE POLICY "Service role can manage approved apps" ON approved_apps
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- OFFLINE TRANSACTION QUEUE POLICIES
-- =====================================================

ALTER TABLE offline_transaction_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own queued transactions" ON offline_transaction_queue;
CREATE POLICY "Users can view own queued transactions" ON offline_transaction_queue
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage queued transactions" ON offline_transaction_queue;
CREATE POLICY "Service role can manage queued transactions" ON offline_transaction_queue
    FOR ALL USING (current_setting('role') = 'service_role');

-- =====================================================
-- SCHEMA MIGRATIONS TABLE POLICIES (Admin only)
-- =====================================================

ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage migrations" ON schema_migrations;
CREATE POLICY "Service role can manage migrations" ON schema_migrations
    FOR ALL USING (
        current_setting('role') = 'service_role' OR 
        current_setting('role') = 'postgres'
    );

-- Comments for documentation
COMMENT ON POLICY "Users can view own profile" ON profiles IS 'Users can only see their own profile data';
COMMENT ON POLICY "Service role can manage profiles" ON profiles IS 'Service role bypasses RLS for system operations';
COMMENT ON POLICY "Users can view own time bank" ON time_banks IS 'Users can only see their own time bank balance';
COMMENT ON POLICY "Users can view own ledger entries" ON time_ledger_entries IS 'Users can only see their own transaction history';
COMMENT ON POLICY "Service role can manage tasks" ON tasks IS 'Service role bypasses RLS for system operations'; 