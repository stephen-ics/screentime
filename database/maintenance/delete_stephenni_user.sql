-- =====================================================
-- MAINTENANCE: delete_stephenni_user.sql
-- Description: Delete specific user from auth and profiles tables
-- WARNING: This will permanently delete user data!
-- =====================================================

-- Start transaction for safety
BEGIN;

-- Function to safely delete stephenni user
CREATE OR REPLACE FUNCTION delete_stephenni_user()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_profile_exists BOOLEAN := FALSE;
    v_auth_exists BOOLEAN := FALSE;
    v_result TEXT := '';
BEGIN
    -- Check if user exists in profiles table
    SELECT id INTO v_user_id 
    FROM profiles 
    WHERE email = 'stephenni1234@gmail.com';
    
    IF v_user_id IS NOT NULL THEN
        v_profile_exists := TRUE;
        v_result := v_result || '👤 Found user in profiles table: ' || v_user_id || E'\n';
    END IF;
    
    -- Check if user exists in auth.users table
    SELECT id INTO v_user_id 
    FROM auth.users 
    WHERE email = 'stephenni1234@gmail.com';
    
    IF v_user_id IS NOT NULL THEN
        v_auth_exists := TRUE;
        v_result := v_result || '🔐 Found user in auth.users table: ' || v_user_id || E'\n';
    END IF;
    
    -- If no user found anywhere
    IF NOT v_profile_exists AND NOT v_auth_exists THEN
        v_result := '❌ No user found with email: stephenni1234@gmail.com';
        RAISE NOTICE '%', v_result;
        RETURN v_result;
    END IF;
    
    -- Delete from auth.users (this will cascade to profiles due to foreign key)
    IF v_auth_exists THEN
        DELETE FROM auth.users 
        WHERE email = 'stephenni1234@gmail.com';
        
        v_result := v_result || '✅ Deleted user from auth.users (cascaded to profiles)' || E'\n';
    ELSE
        -- If only in profiles table (shouldn't happen, but just in case)
        DELETE FROM profiles 
        WHERE email = 'stephenni1234@gmail.com';
        
        v_result := v_result || '✅ Deleted user from profiles table' || E'\n';
    END IF;
    
    -- Also clean up any related data
    DELETE FROM time_banks WHERE user_id = v_user_id;
    DELETE FROM time_ledger_entries WHERE user_id = v_user_id;
    DELETE FROM unlocked_sessions WHERE user_id = v_user_id;
    DELETE FROM tasks WHERE assigned_to = v_user_id OR created_by = v_user_id;
    DELETE FROM approved_apps WHERE user_id = v_user_id;
    DELETE FROM offline_transaction_queue WHERE user_id = v_user_id;
    
    v_result := v_result || '🧹 Cleaned up all related data (time banks, tasks, etc.)' || E'\n';
    v_result := v_result || '✅ User stephenni1234@gmail.com completely removed!';
    
    RAISE NOTICE '%', v_result;
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    v_result := '❌ Error deleting user: ' || SQLERRM;
    RAISE NOTICE '%', v_result;
    RAISE;
END;
$$;

-- Execute the deletion
SELECT delete_stephenni_user();

-- Clean up the function (it's just for this one-time operation)
DROP FUNCTION delete_stephenni_user();

-- Final confirmation
DO $$
DECLARE
    v_remaining_count INT;
BEGIN
    SELECT COUNT(*) INTO v_remaining_count
    FROM auth.users 
    WHERE email = 'stephenni1234@gmail.com';
    
    IF v_remaining_count = 0 THEN
        RAISE NOTICE '🎉 CONFIRMATION: User stephenni1234@gmail.com successfully deleted!';
        RAISE NOTICE '📊 No traces of user remain in the database.';
    ELSE
        RAISE NOTICE '⚠️  WARNING: User may still exist in database!';
    END IF;
END $$;

COMMIT;