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

DROP POLICY IF EXISTS "Users can view own transactions" ON time_ledger_entries;
CREATE POLICY "Users can view own transactions" ON time_ledger_entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert transactions" ON time_ledger_entries;
CREATE POLICY "System can insert transactions" ON time_ledger_entries
    FOR INSERT WITH CHECK (true); -- Allow functions to insert

-- =====================================================
-- UNLOCKED SESSIONS TABLE POLICIES
-- =====================================================

ALTER TABLE unlocked_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own sessions" ON unlocked_sessions;
CREATE POLICY "Users can view own sessions" ON unlocked_sessions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own sessions" ON unlocked_sessions;
CREATE POLICY "Users can manage own sessions" ON unlocked_sessions
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- TASKS TABLE POLICIES
-- =====================================================

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view assigned tasks" ON tasks;
CREATE POLICY "Users can view assigned tasks" ON tasks
    FOR SELECT USING (auth.uid() = assigned_to OR auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can update assigned tasks" ON tasks;
CREATE POLICY "Users can update assigned tasks" ON tasks
    FOR UPDATE USING (auth.uid() = assigned_to OR auth.uid() = created_by);

DROP POLICY IF EXISTS "Parents can create tasks" ON tasks;
CREATE POLICY "Parents can create tasks" ON tasks
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND 
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND is_parent = true
        )
    );

-- =====================================================
-- APPROVED APPS TABLE POLICIES
-- =====================================================

ALTER TABLE approved_apps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own apps" ON approved_apps;
CREATE POLICY "Users can view own apps" ON approved_apps
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own apps" ON approved_apps;
CREATE POLICY "Users can manage own apps" ON approved_apps
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- OFFLINE TRANSACTION QUEUE TABLE POLICIES
-- =====================================================

ALTER TABLE offline_transaction_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own queue" ON offline_transaction_queue;
CREATE POLICY "Users can manage own queue" ON offline_transaction_queue
    FOR ALL USING (auth.uid() = user_id);

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
COMMENT ON POLICY "Users can view own transactions" ON time_ledger_entries IS 'Users can only see their own transaction history';
COMMENT ON POLICY "Parents can create tasks" ON tasks IS 'Only parent accounts can create tasks for children'; 