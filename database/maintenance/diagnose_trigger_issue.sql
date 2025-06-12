-- =====================================================
-- DIAGNOSE TRIGGER ISSUE
-- Description: Find out why the trigger isn't creating family profiles
-- =====================================================

\echo '🔍 DIAGNOSING TRIGGER ISSUE...'

-- =====================================================
-- STEP 1: CHECK TRIGGER STATUS
-- =====================================================

\echo '📋 Step 1: Trigger Status Check'

-- Check if trigger exists and is enabled
SELECT 
    'Trigger exists and status' as check,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    trigger_schema,
    event_object_schema,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created_family';

-- Check function exists
SELECT 
    'Function exists' as check,
    routine_name,
    routine_type,
    security_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'handle_new_family_user';

-- =====================================================
-- STEP 2: CHECK RECENT AUTH USERS
-- =====================================================

\echo '👥 Step 2: Recent Auth Users'

-- Show recent users and their metadata
SELECT 
    'Recent auth users' as info,
    id,
    email,
    raw_user_meta_data,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- =====================================================
-- STEP 3: CHECK FAMILY PROFILES TABLE
-- =====================================================

\echo '🏠 Step 3: Family Profiles State'

-- Show all family profiles
SELECT 
    'All family profiles' as info,
    COUNT(*) as total_count
FROM family_profiles;

-- Show specific profiles for recent users
SELECT 
    'Profiles for recent users' as info,
    u.email,
    u.id as user_id,
    fp.id as profile_id,
    fp.name,
    fp.role,
    fp.created_at as profile_created
FROM auth.users u
LEFT JOIN family_profiles fp ON u.id = fp.auth_user_id
WHERE u.created_at > NOW() - INTERVAL '1 day'
ORDER BY u.created_at DESC;

-- =====================================================
-- STEP 4: TEST TRIGGER FUNCTION MANUALLY
-- =====================================================

\echo '🧪 Step 4: Manual Trigger Test'

-- Test if we can call the function manually
DO $$
DECLARE
    test_user_record RECORD;
    result_text TEXT;
BEGIN
    -- Get the most recent user for testing
    SELECT id, email, raw_user_meta_data, email_confirmed_at, created_at
    INTO test_user_record
    FROM auth.users 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF test_user_record.id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user: % (ID: %)', test_user_record.email, test_user_record.id;
        RAISE NOTICE 'User metadata: %', test_user_record.raw_user_meta_data;
        
        -- Check if this user already has a profile
        IF EXISTS (SELECT 1 FROM family_profiles WHERE auth_user_id = test_user_record.id) THEN
            RAISE NOTICE 'User already has a family profile - trigger worked previously';
        ELSE
            RAISE NOTICE 'User has no family profile - trigger did not work';
            
            -- Try to create profile manually using the same logic
            IF test_user_record.raw_user_meta_data ? 'name' THEN
                RAISE NOTICE 'User has name in metadata: %', test_user_record.raw_user_meta_data->>'name';
                
                -- Manually insert to test if there are permission issues
                BEGIN
                    INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
                    VALUES (
                        test_user_record.id,
                        test_user_record.raw_user_meta_data->>'name',
                        'parent',
                        (test_user_record.email_confirmed_at IS NOT NULL)
                    );
                    RAISE NOTICE '✅ Manual insert successful - trigger should work';
                    
                    -- Clean up the test insert
                    DELETE FROM family_profiles WHERE auth_user_id = test_user_record.id;
                    RAISE NOTICE '🧹 Test data cleaned up';
                    
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE '❌ Manual insert failed: %', SQLERRM;
                END;
            ELSE
                RAISE NOTICE '❌ User metadata missing name field';
            END IF;
        END IF;
    ELSE
        RAISE NOTICE 'No users found to test with';
    END IF;
END $$;

-- =====================================================
-- STEP 5: CHECK TRIGGER LOGS
-- =====================================================

\echo '📝 Step 5: Check for Trigger Execution'

-- Check if there are any NOTICE messages from the trigger
-- (These might appear in Supabase logs)
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '💡 TRIGGER LOG CHECK:';
    RAISE NOTICE 'If the trigger fired, you should see NOTICE messages like:';
    RAISE NOTICE '  "Creating family profile for user: ..."';
    RAISE NOTICE '  "Successfully created family profile for user: ..."';
    RAISE NOTICE 'Check your Supabase Dashboard → Logs for these messages';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- STEP 6: RECREATE TRIGGER WITH ENHANCED LOGGING
-- =====================================================

\echo '🔧 Step 6: Recreating Trigger with Enhanced Logging'

-- Drop and recreate the function with more detailed logging
CREATE OR REPLACE FUNCTION handle_new_family_user()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE '🔔 TRIGGER FIRED: handle_new_family_user for user %', NEW.email;
    RAISE NOTICE '📊 User ID: %', NEW.id;
    RAISE NOTICE '📊 Email confirmed: %', (NEW.email_confirmed_at IS NOT NULL);
    RAISE NOTICE '📊 Raw metadata: %', NEW.raw_user_meta_data;
    
    -- Check if metadata has name field
    IF NEW.raw_user_meta_data ? 'name' THEN
        RAISE NOTICE '✅ Name found in metadata: %', NEW.raw_user_meta_data->>'name';
        
        BEGIN
            RAISE NOTICE '🔄 Attempting to insert into family_profiles...';
            
            INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
            VALUES (
                NEW.id,
                NEW.raw_user_meta_data->>'name',
                'parent',
                (NEW.email_confirmed_at IS NOT NULL)
            );
            
            RAISE NOTICE '✅ SUCCESS: Family profile created for user %', NEW.email;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ ERROR creating family profile for user %: %', NEW.email, SQLERRM;
            RAISE NOTICE '❌ SQLSTATE: %', SQLSTATE;
            -- Don't fail the auth signup, just log the error
        END;
    ELSE
        RAISE NOTICE '❌ No name in metadata for user %. Metadata: %', NEW.email, NEW.raw_user_meta_data;
    END IF;
    
    RAISE NOTICE '🏁 TRIGGER COMPLETE for user %', NEW.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger to ensure it's properly attached
DROP TRIGGER IF EXISTS on_auth_user_created_family ON auth.users;
CREATE TRIGGER on_auth_user_created_family
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_family_user();

-- =====================================================
-- STEP 7: MANUAL TRIGGER TEST FOR EXISTING USER
-- =====================================================

\echo '🎯 Step 7: Manual Profile Creation for Existing User'

-- Create profile for the user who doesn't have one
DO $$
DECLARE
    target_email TEXT := 'stephenni1234@gmail.com';
    user_record RECORD;
    profile_exists BOOLEAN;
BEGIN
    -- Find the user
    SELECT id, email, raw_user_meta_data, email_confirmed_at
    INTO user_record
    FROM auth.users 
    WHERE email = target_email;
    
    IF user_record.id IS NOT NULL THEN
        -- Check if profile already exists
        SELECT EXISTS(SELECT 1 FROM family_profiles WHERE auth_user_id = user_record.id)
        INTO profile_exists;
        
        IF NOT profile_exists THEN
            RAISE NOTICE 'Creating missing profile for user: %', target_email;
            
            IF user_record.raw_user_meta_data ? 'name' THEN
                INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
                VALUES (
                    user_record.id,
                    user_record.raw_user_meta_data->>'name',
                    'parent',
                    (user_record.email_confirmed_at IS NOT NULL)
                );
                RAISE NOTICE '✅ Profile created successfully for %', target_email;
            ELSE
                -- Fallback: use email prefix as name
                INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
                VALUES (
                    user_record.id,
                    split_part(target_email, '@', 1),
                    'parent',
                    (user_record.email_confirmed_at IS NOT NULL)
                );
                RAISE NOTICE '✅ Profile created with fallback name for %', target_email;
            END IF;
        ELSE
            RAISE NOTICE 'Profile already exists for user: %', target_email;
        END IF;
    ELSE
        RAISE NOTICE 'User % not found', target_email;
    END IF;
END $$;

-- =====================================================
-- STEP 8: VERIFICATION
-- =====================================================

\echo '✅ Step 8: Final Verification'

-- Show final state
SELECT 
    'Final verification' as check,
    u.email,
    u.id as user_id,
    fp.name as profile_name,
    fp.role,
    fp.created_at as profile_created
FROM auth.users u
LEFT JOIN family_profiles fp ON u.id = fp.auth_user_id
WHERE u.email = 'stephenni1234@gmail.com';

-- Count profiles
SELECT 'Total family profiles' as info, COUNT(*) as count FROM family_profiles;

RAISE NOTICE '';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '🎯 TRIGGER DIAGNOSIS COMPLETE';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '';
RAISE NOTICE '🔍 What to check:';
RAISE NOTICE '   1. Look for NOTICE messages above starting with 🔔';
RAISE NOTICE '   2. Check if profile was created for stephenni1234@gmail.com';
RAISE NOTICE '   3. Test signup with a NEW user account';
RAISE NOTICE '   4. Check Supabase Dashboard → Logs for trigger messages';
RAISE NOTICE '';
RAISE NOTICE '📱 Next steps:';
RAISE NOTICE '   1. Sign out and sign back in to your app';
RAISE NOTICE '   2. Try creating a new test account';
RAISE NOTICE '   3. Verify the trigger now works with enhanced logging';
RAISE NOTICE ''; 