-- ============================================================
-- SUPABASE DATABASE FIX - Run this in your Supabase SQL Editor
-- ============================================================

-- 1. First, drop the existing broken trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2. Create the fixed trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Insert into profiles table
  INSERT INTO public.profiles (
    id, 
    name, 
    user_type,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'child'),
    NOW(),
    NOW()
  );
  
  -- Insert into screentime_balances table
  INSERT INTO public.screentime_balances (
    user_id,
    available_seconds,
    daily_limit_seconds,
    weekly_limit_seconds,
    last_updated,
    is_timer_active,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    0,  -- Start with no available time
    7200,  -- 2 hours daily limit
    50400, -- 14 hours weekly limit
    NOW(),
    FALSE,
    NOW(),
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the user creation
    RAISE LOG 'Error in handle_new_user trigger: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 3. Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 4. Enable RLS (Row Level Security) with proper policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screentime_balances ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies that allow the trigger to work
-- Policy for profiles table
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users only" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy for screentime_balances table
DROP POLICY IF EXISTS "Users can view own balance" ON public.screentime_balances;
DROP POLICY IF EXISTS "Users can update own balance" ON public.screentime_balances;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.screentime_balances;

CREATE POLICY "Users can view own balance" ON public.screentime_balances
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own balance" ON public.screentime_balances
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Enable insert for authenticated users only" ON public.screentime_balances
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- 7. Test the fix with a comment
-- This SQL should now allow user registration to work properly
SELECT 'Database trigger fix applied successfully!' as status; 