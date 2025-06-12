-- =====================================================
-- CREATE MISSING FAMILY PROFILES
-- Description: Manually creates family profiles for existing users who don't have them
-- Use this if users signed up before the family auth system was properly configured
-- =====================================================

-- =====================================================
-- STEP 1: IDENTIFY USERS WITHOUT PROFILES
-- =====================================================

\echo '🔍 Finding users without family profiles...'

-- Show users who don't have family profiles
SELECT 
    'Users without family profiles' as status,
    u.id,
    u.email,
    u.raw_user_meta_data,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    u.created_at
FROM auth.users u
LEFT JOIN family_profiles fp ON u.id = fp.auth_user_id
WHERE fp.auth_user_id IS NULL
ORDER BY u.created_at DESC;

-- =====================================================
-- STEP 2: CREATE MISSING PROFILES
-- =====================================================

\echo '🏗️ Creating missing family profiles...'

DO $$
DECLARE
    user_record RECORD;
    created_count INTEGER := 0;
    skipped_count INTEGER := 0;
    user_name TEXT;
BEGIN
    -- Ensure family_profiles table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'family_profiles') THEN
        RAISE EXCEPTION 'family_profiles table does not exist! Run deploy_family_auth.sql first.';
    END IF;
    
    -- Loop through users who don't have family profiles
    FOR user_record IN 
        SELECT u.id, u.email, u.raw_user_meta_data, u.email_confirmed_at, u.created_at
        FROM auth.users u
        LEFT JOIN family_profiles fp ON u.id = fp.auth_user_id
        WHERE fp.auth_user_id IS NULL
    LOOP
        -- Try to get name from metadata
        IF user_record.raw_user_meta_data ? 'name' THEN
            user_name := user_record.raw_user_meta_data->>'name';
        ELSE
            -- Fallback to email prefix if no name in metadata
            user_name := split_part(user_record.email, '@', 1);
        END IF;
        
        -- Validate name
        IF user_name IS NOT NULL AND length(trim(user_name)) > 0 THEN
            -- Create family profile
            INSERT INTO family_profiles (auth_user_id, name, role, email_verified, created_at, updated_at)
            VALUES (
                user_record.id,
                trim(user_name),
                'parent', -- Default to parent role
                (user_record.email_confirmed_at IS NOT NULL),
                user_record.created_at,
                user_record.created_at
            );
            
            created_count := created_count + 1;
            RAISE NOTICE 'Created profile for %: %', user_record.email, user_name;
        ELSE
            skipped_count := skipped_count + 1;
            RAISE WARNING 'Skipped user % - could not determine name', user_record.email;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Profile creation complete:';
    RAISE NOTICE '   📊 Created: % profiles', created_count;
    RAISE NOTICE '   ⚠️ Skipped: % users', skipped_count;
    RAISE NOTICE '';
    
    IF created_count > 0 THEN
        RAISE NOTICE '🎉 Successfully created % family profiles!', created_count;
    END IF;
    
    IF skipped_count > 0 THEN
        RAISE NOTICE '⚠️ % users were skipped - you may need to handle these manually', skipped_count;
    END IF;
END $$;

-- =====================================================
-- STEP 3: VERIFICATION
-- =====================================================

\echo '✅ Verifying profile creation...'

-- Show current status
SELECT 
    'Final Status' as info,
    (SELECT COUNT(*) FROM auth.users) as total_users,
    (SELECT COUNT(*) FROM family_profiles) as total_profiles,
    (SELECT COUNT(*) FROM auth.users u LEFT JOIN family_profiles fp ON u.id = fp.auth_user_id WHERE fp.auth_user_id IS NULL) as users_without_profiles;

-- Show all family profiles
SELECT 
    'All Family Profiles' as status,
    fp.id,
    fp.auth_user_id,
    fp.name,
    fp.role,
    fp.email_verified,
    u.email,
    fp.created_at
FROM family_profiles fp
JOIN auth.users u ON fp.auth_user_id = u.id
ORDER BY fp.created_at DESC;

RAISE NOTICE '';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '🎯 MANUAL PROFILE CREATION COMPLETE';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '';
RAISE NOTICE '📋 Next steps:';
RAISE NOTICE '   1. Test signing in with your app';
RAISE NOTICE '   2. Verify profiles are loaded correctly';
RAISE NOTICE '   3. Check app logs for any remaining issues';
RAISE NOTICE ''; 