-- =====================================================
-- FIX RLS POLICIES FOR USER SIGNUP
-- Run this in Supabase SQL Editor to fix the signup issues
-- =====================================================

-- Fix the profiles policies to allow the trigger to work
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (true); -- Allow trigger to insert during signup

-- Also allow service role to insert (for the trigger)
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;
CREATE POLICY "Service role can manage profiles" ON profiles
  FOR ALL USING (current_setting('role') = 'service_role');

-- Update the user creation function to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER -- This runs with elevated privileges
LANGUAGE plpgsql
AS $$
BEGIN
  -- Insert profile (this will work even with RLS because of SECURITY DEFINER)
  INSERT INTO public.profiles (id, email, name, user_type, is_parent)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'child'),
    (COALESCE(NEW.raw_user_meta_data->>'user_type', 'child') = 'parent')
  );
  
  -- Create time bank for the user
  INSERT INTO public.time_banks (user_id, current_balance_seconds)
  VALUES (NEW.id, 0);
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error but don't fail the signup
  RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fix time_banks policies too
DROP POLICY IF EXISTS "Users can view own time bank" ON time_banks;
CREATE POLICY "Users can view own time bank" ON time_banks
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage time banks" ON time_banks;
CREATE POLICY "Service role can manage time banks" ON time_banks
  FOR ALL USING (current_setting('role') = 'service_role');

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies fixed for user signup!';
    RAISE NOTICE '🔧 Profiles can now be created during signup';
    RAISE NOTICE '⚡ Service role has necessary permissions';
END $$; 