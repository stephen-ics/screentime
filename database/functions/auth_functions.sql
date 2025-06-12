-- =====================================================
-- FUNCTIONS: auth_functions.sql
-- Description: Authentication and user management functions
-- Dependencies: profiles.sql, time_banks.sql
-- =====================================================

-- Function to automatically create profile and time bank on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER -- Runs with elevated privileges to bypass RLS
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert profile (bypasses RLS due to SECURITY DEFINER)
    INSERT INTO public.profiles (id, email, name, user_type, is_parent)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'user_type', 'child'),
        (COALESCE(NEW.raw_user_meta_data->>'user_type', 'child') = 'parent'),
        (NEW.email_confirmed_at IS NOT NULL)
    );
    
    -- Create time bank for the user
    INSERT INTO public.time_banks (user_id, current_balance_seconds)
    VALUES (NEW.id, 0);
    
    -- Log successful creation
    RAISE NOTICE 'Created profile and time bank for user: %', NEW.email;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log the error but don't fail the signup process
    RAISE WARNING 'Failed to create profile/time bank for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Comments for documentation
COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates user profile and time bank when new user signs up through Supabase Auth'; 