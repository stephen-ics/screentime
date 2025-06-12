-- =====================================================
-- FIX NAVIGATION ISSUES - PROFILE ROLE FIX
-- Description: Fix profile role and verify database setup
-- Run this FIRST in Supabase SQL Editor
-- =====================================================

-- First, run the trigger diagnosis script
\i diagnose_trigger_issue.sql

-- Then fix the specific user's profile role
DO $$
DECLARE
    user_email TEXT := 'stephenni1234@gmail.com';
    user_id UUID;
    profile_id UUID;
BEGIN
    -- Find the user
    SELECT id INTO user_id 
    FROM auth.users 
    WHERE email = user_email;
    
    IF user_id IS NOT NULL THEN
        -- Check current profile role
        SELECT id INTO profile_id
        FROM family_profiles 
        WHERE auth_user_id = user_id;
        
        IF profile_id IS NOT NULL THEN
            -- Update role to parent
            UPDATE family_profiles 
            SET role = 'parent',
                updated_at = NOW()
            WHERE id = profile_id;
            
            RAISE NOTICE '✅ Fixed profile role for % - now set as parent', user_email;
        ELSE
            -- Create missing profile
            INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
            VALUES (
                user_id,
                'Stephen Ni',
                'parent',
                true
            );
            RAISE NOTICE '✅ Created missing parent profile for %', user_email;
        END IF;
    ELSE
        RAISE NOTICE '❌ User % not found', user_email;
    END IF;
END $$;

-- Verify the fix
SELECT 
    'Profile verification' as check,
    u.email,
    fp.name,
    fp.role,
    fp.id
FROM auth.users u
JOIN family_profiles fp ON u.id = fp.auth_user_id
WHERE u.email = 'stephenni1234@gmail.com';

RAISE NOTICE '';
RAISE NOTICE '🎯 PROFILE ROLE FIX COMPLETE';
RAISE NOTICE 'Your profile should now be set as "parent"';
RAISE NOTICE 'This will fix the "parentAuthRequired" error';
RAISE NOTICE ''; 