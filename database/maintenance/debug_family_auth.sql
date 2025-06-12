-- =====================================================
-- DEBUG FAMILY AUTH SYSTEM
-- Description: Debug script to check the current state of family auth
-- Run this in Supabase SQL Editor to diagnose issues
-- =====================================================

\echo '🔍 DEBUGGING FAMILY AUTH SYSTEM...'

-- =====================================================
-- STEP 1: CHECK CURRENT USER AND METADATA
-- =====================================================

\echo '📋 Step 1: Current User Information'

SELECT 
    'Current Auth Users' as info,
    COUNT(*) as count
FROM auth.users;

-- Show recent users with their metadata
SELECT 
    'Recent Users (last 5)' as info,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    raw_user_meta_data,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- =====================================================
-- STEP 2: CHECK FAMILY PROFILES TABLE
-- =====================================================

\echo '🏠 Step 2: Family Profiles Information'

-- Check if table exists
SELECT 
    'family_profiles table exists' as info,
    EXISTS(
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'family_profiles'
    ) as exists;

-- Count profiles if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'family_profiles') THEN
        PERFORM (
            SELECT 
                'Family Profiles Count' as info,
                COUNT(*) as count
            FROM family_profiles
        );
        
        -- Show all profiles
        RAISE NOTICE 'All Family Profiles:';
        FOR r IN 
            SELECT id, auth_user_id, name, role, email_verified, created_at
            FROM family_profiles
            ORDER BY created_at DESC
        LOOP
            RAISE NOTICE 'Profile: % | User: % | Name: % | Role: % | Verified: %', 
                r.id, r.auth_user_id, r.name, r.role, r.email_verified;
        END LOOP;
    ELSE
        RAISE NOTICE 'family_profiles table does not exist!';
    END IF;
END $$;

-- =====================================================
-- STEP 3: CHECK TRIGGERS AND FUNCTIONS
-- =====================================================

\echo '⚙️ Step 3: Triggers and Functions'

-- Check active triggers on auth.users
SELECT 
    'Active Triggers on auth.users' as info,
    trigger_name,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- Check if family auth function exists
SELECT 
    'handle_new_family_user function exists' as info,
    EXISTS(
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_family_user'
    ) as exists;

-- Check if old conflicting function exists
SELECT 
    'handle_new_user function exists (should be false)' as info,
    EXISTS(
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user'
    ) as exists;

-- =====================================================
-- STEP 4: CHECK TABLE SCHEMA
-- =====================================================

\echo '📊 Step 4: Table Schema'

-- Show family_profiles schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'family_profiles'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 5: CHECK RLS POLICIES
-- =====================================================

\echo '🔒 Step 5: Row Level Security'

-- Check RLS is enabled
SELECT 
    'family_profiles RLS enabled' as info,
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'family_profiles') as enabled;

-- Show active policies
SELECT 
    'Active RLS Policies' as info,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename = 'family_profiles';

-- =====================================================
-- STEP 6: TEST TRIGGER MANUALLY (optional)
-- =====================================================

\echo '🧪 Step 6: Manual Trigger Test'

-- This will show what happens when the trigger is called
-- (Commented out to avoid creating test data)

/*
-- Uncomment this section to test trigger manually:

-- Test the trigger function directly
SELECT handle_new_family_user() AS test_result;

-- Or create a test user (BE CAREFUL - this creates real auth data)
-- INSERT INTO auth.users (id, email, raw_user_meta_data, email_confirmed_at)
-- VALUES (
--     gen_random_uuid(),
--     'test@example.com',
--     '{"name": "Test Parent"}',
--     NOW()
-- );
*/

-- =====================================================
-- SUMMARY
-- =====================================================

\echo '📋 SUMMARY'

DO $$
DECLARE
    user_count INTEGER;
    profile_count INTEGER;
    trigger_count INTEGER;
    rls_enabled BOOLEAN;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO user_count FROM auth.users;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'family_profiles') THEN
        SELECT COUNT(*) INTO profile_count FROM family_profiles;
    ELSE
        profile_count := -1; -- Table doesn't exist
    END IF;
    
    SELECT COUNT(*) INTO trigger_count 
    FROM information_schema.triggers 
    WHERE trigger_name = 'on_auth_user_created_family';
    
    SELECT COALESCE((SELECT relrowsecurity FROM pg_class WHERE relname = 'family_profiles'), false) 
    INTO rls_enabled;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '🎯 FAMILY AUTH DEBUG SUMMARY';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '';
    RAISE NOTICE '👥 Total auth users: %', user_count;
    RAISE NOTICE '🏠 Family profiles: %', CASE WHEN profile_count = -1 THEN 'TABLE MISSING' ELSE profile_count::text END;
    RAISE NOTICE '⚙️ Family auth triggers: %', trigger_count;
    RAISE NOTICE '🔒 RLS enabled: %', rls_enabled;
    RAISE NOTICE '';
    
    -- Diagnosis
    IF profile_count = -1 THEN
        RAISE NOTICE '🔴 ISSUE: family_profiles table missing!';
        RAISE NOTICE '   → Run deploy_family_auth.sql first';
    ELSIF trigger_count = 0 THEN
        RAISE NOTICE '🔴 ISSUE: Family auth trigger missing!';
        RAISE NOTICE '   → Run fix_family_auth_conflict.sql and deploy_family_auth.sql';
    ELSIF user_count > profile_count AND profile_count >= 0 THEN
        RAISE NOTICE '⚠️ ISSUE: More users than profiles!';
        RAISE NOTICE '   → Some users were created before family auth was set up';
        RAISE NOTICE '   → Check user metadata for missing name fields';
    ELSIF profile_count = 0 AND user_count = 0 THEN
        RAISE NOTICE '🟡 STATUS: No users yet - system ready for testing';
    ELSIF profile_count = user_count THEN
        RAISE NOTICE '🟢 STATUS: All users have profiles - system working correctly';
    END IF;
    
    RAISE NOTICE '';
END $$; 