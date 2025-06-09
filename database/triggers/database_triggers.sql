-- =====================================================
-- TRIGGERS: database_triggers.sql
-- Description: All database triggers for automated functionality
-- Dependencies: functions/common_functions.sql, functions/auth_functions.sql
-- =====================================================

-- =====================================================
-- UPDATED_AT TRIGGERS
-- =====================================================

-- Profiles table updated_at trigger
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Time banks table updated_at trigger
DROP TRIGGER IF EXISTS update_time_banks_updated_at ON time_banks;
CREATE TRIGGER update_time_banks_updated_at 
    BEFORE UPDATE ON time_banks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Unlocked sessions table updated_at trigger
DROP TRIGGER IF EXISTS update_unlocked_sessions_updated_at ON unlocked_sessions;
CREATE TRIGGER update_unlocked_sessions_updated_at 
    BEFORE UPDATE ON unlocked_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Tasks table updated_at trigger
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Approved apps table updated_at trigger
DROP TRIGGER IF EXISTS update_approved_apps_updated_at ON approved_apps;
CREATE TRIGGER update_approved_apps_updated_at 
    BEFORE UPDATE ON approved_apps 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- AUTHENTICATION TRIGGERS
-- =====================================================

-- Trigger for automatic profile and time bank creation on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Comments for documentation
COMMENT ON TRIGGER update_profiles_updated_at ON profiles IS 'Automatically updates updated_at timestamp when profile is modified';
COMMENT ON TRIGGER update_time_banks_updated_at ON time_banks IS 'Automatically updates updated_at timestamp when time bank is modified';
COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 'Automatically creates profile and time bank when new user signs up'; 