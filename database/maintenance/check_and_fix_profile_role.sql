-- =====================================================
-- CHECK AND FIX PROFILE ROLE ISSUE
-- Description: Fix the incorrect profile role and show current state
-- =====================================================

-- First, let's see what we currently have
SELECT 
    'Current Family Profiles:' as info,
    fp.id,
    fp.auth_user_id,
    fp.name,
    fp.role,
    u.email,
    fp.created_at
FROM family_profiles fp
JOIN auth.users u ON fp.auth_user_id = u.id
ORDER BY fp.created_at DESC;

-- Check user metadata to understand how the profile was created
SELECT 
    'User Metadata:' as info,
    email,
    raw_user_meta_data,
    email_confirmed_at IS NOT NULL as email_confirmed
FROM auth.users
ORDER BY created_at DESC
LIMIT 3;

-- Now let's fix the role issue
-- The main user (stephenni1234@gmail.com) should be a parent, not a child

DO $$
DECLARE
    user_email TEXT := 'stephenni1234@gmail.com';
    user_id UUID;
    profile_id UUID;
    fixed_count INTEGER := 0;
BEGIN
    -- Find the user ID
    SELECT id INTO user_id 
    FROM auth.users 
    WHERE email = user_email;
    
    IF user_id IS NULL THEN
        RAISE NOTICE 'User % not found!', user_email;
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found user: % (ID: %)', user_email, user_id;
    
    -- Check current profile
    SELECT id INTO profile_id
    FROM family_profiles 
    WHERE auth_user_id = user_id 
    AND role = 'child';
    
    IF profile_id IS NOT NULL THEN
        -- Fix the role from child to parent
        UPDATE family_profiles 
        SET role = 'parent',
            updated_at = NOW()
        WHERE id = profile_id;
        
        fixed_count := 1;
        RAISE NOTICE 'Fixed profile role: % is now a parent', user_email;
    ELSE
        -- Check if already a parent
        SELECT id INTO profile_id
        FROM family_profiles 
        WHERE auth_user_id = user_id 
        AND role = 'parent';
        
        IF profile_id IS NOT NULL THEN
            RAISE NOTICE 'Profile % is already a parent - no fix needed', user_email;
        ELSE
            RAISE NOTICE 'No profile found for user % - this is unexpected', user_email;
        END IF;
    END IF;
    
    -- Show the result
    IF fixed_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ FIXED: Profile role updated successfully!';
        RAISE NOTICE '📱 Now your app should show the "Add Child" button';
        RAISE NOTICE '';
    END IF;
END $$;

-- Show the final state
SELECT 
    'Updated Family Profiles:' as info,
    fp.id,
    fp.auth_user_id,
    fp.name,
    fp.role,
    u.email,
    fp.updated_at
FROM family_profiles fp
JOIN auth.users u ON fp.auth_user_id = u.id
ORDER BY fp.updated_at DESC;

-- Verify the trigger is working correctly
SELECT 
    'Trigger Status:' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created_family';

RAISE NOTICE '';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '🎯 PROFILE ROLE FIX COMPLETE';
RAISE NOTICE '🎯 =====================================================';
RAISE NOTICE '';
RAISE NOTICE '📋 What was fixed:';
RAISE NOTICE '   1. Changed your profile role from "child" to "parent"';
RAISE NOTICE '   2. This will enable the "Add Child" button in your app';
RAISE NOTICE '';
RAISE NOTICE '📋 Next steps:';
RAISE NOTICE '   1. Sign out and sign back in to your app';
RAISE NOTICE '   2. You should now see "Stephen Ni (Parent)" instead of "Stephen Ni (Child)"';
RAISE NOTICE '   3. The "Add Child" button should now appear';
RAISE NOTICE '   4. Test creating a child profile';
RAISE NOTICE ''; 