-- =====================================================
-- MAIN DEPLOYMENT SCRIPT
-- Description: Complete database setup in correct order
-- =====================================================

-- Start transaction
BEGIN;

\echo '🚀 Starting ScreenTime Database Deployment...'

-- =====================================================
-- STEP 1: MIGRATIONS (Extensions and basic setup)
-- =====================================================

\echo '📦 Step 1: Running migrations...'
\i migrations/001_initial_setup.sql

-- =====================================================
-- STEP 2: SCHEMAS (Create all tables)
-- =====================================================

\echo '🏗️  Step 2: Creating schemas...'
\i schemas/profiles.sql
\i schemas/time_banks.sql  
\i schemas/tasks_and_apps.sql

-- =====================================================
-- STEP 3: FUNCTIONS (Create all stored procedures)
-- =====================================================

\echo '⚙️  Step 3: Creating functions...'
\i functions/common_functions.sql
\i functions/auth_functions.sql
\i functions/time_bank_functions.sql
\i maintenance/cleanup_scripts.sql

-- =====================================================
-- STEP 4: INDEXES (Create performance indexes)
-- =====================================================

\echo '🚀 Step 4: Creating indexes...'
\i indexes/performance_indexes.sql

-- =====================================================
-- STEP 5: TRIGGERS (Setup automated functionality)
-- =====================================================

\echo '🔄 Step 5: Creating triggers...'
\i triggers/database_triggers.sql

-- =====================================================
-- STEP 6: SECURITY (Row Level Security policies)
-- =====================================================

\echo '🔒 Step 6: Setting up security policies...'
\i policies/row_level_security.sql

-- =====================================================
-- STEP 7: SAMPLE DATA (Development only)
-- =====================================================

\echo '🌱 Step 7: Loading sample data (if in development)...'
-- Uncomment the next line for development environments
-- \i seeds/sample_data.sql

-- =====================================================
-- DEPLOYMENT COMPLETE
-- =====================================================

-- Record deployment
INSERT INTO schema_migrations (version, description) 
VALUES ('DEPLOY_' || to_char(NOW(), 'YYYYMMDDHH24MISS'), 'Full database deployment')
ON CONFLICT (version) DO NOTHING;

-- Final verification
DO $$
DECLARE
    table_count INT;
    function_count INT;
    policy_count INT;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name IN ('profiles', 'time_banks', 'time_ledger_entries', 'unlocked_sessions', 'tasks', 'approved_apps', 'offline_transaction_queue');
    
    -- Count functions
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
      AND routine_name IN ('update_time_bank', 'start_unlocked_session', 'process_offline_transactions', 'handle_new_user');
    
    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    -- Results
    RAISE NOTICE '';
    RAISE NOTICE '🎉 =====================================================';
    RAISE NOTICE '🎉 SCREENTIME DATABASE DEPLOYMENT COMPLETED!';
    RAISE NOTICE '🎉 =====================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Core tables created: %/7', table_count;
    RAISE NOTICE '✅ Core functions created: %/4', function_count;
    RAISE NOTICE '✅ RLS policies created: %', policy_count;
    RAISE NOTICE '';
    
    IF table_count = 7 AND function_count = 4 AND policy_count > 10 THEN
        RAISE NOTICE '🟢 DEPLOYMENT STATUS: SUCCESS';
        RAISE NOTICE '📱 Your ScreenTime app is ready to use!';
    ELSE
        RAISE NOTICE '🔴 DEPLOYMENT STATUS: INCOMPLETE';
        RAISE NOTICE '⚠️  Some components may not have been created correctly.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '   1. Update your SupabaseConfig.plist with project credentials';
    RAISE NOTICE '   2. Build and run your iOS app';
    RAISE NOTICE '   3. Test user signup and time bank functionality';
    RAISE NOTICE '';
END $$;

COMMIT; 