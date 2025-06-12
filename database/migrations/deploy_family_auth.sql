-- =====================================================
-- FAMILY AUTHENTICATION SYSTEM - COMPLETE DEPLOYMENT
-- Run this script in your Supabase SQL Editor
-- =====================================================

-- =====================================================
-- STEP 1: DROP EXISTING TRIGGERS (IF MIGRATING)
-- =====================================================

-- Uncomment these if you're migrating from the old system
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user();

-- =====================================================
-- STEP 2: CREATE FAMILY PROFILES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS family_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    email_verified BOOLEAN DEFAULT FALSE,
    
    -- Constraints to ensure data integrity
    CONSTRAINT family_profiles_name_check CHECK (length(trim(name)) > 0),
    CONSTRAINT family_profiles_name_length CHECK (length(name) <= 100)
);

-- =====================================================
-- STEP 3: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Partial unique index to enforce exactly one parent per auth_user_id
DROP INDEX IF EXISTS idx_one_parent_per_auth_user;
CREATE UNIQUE INDEX idx_one_parent_per_auth_user 
ON family_profiles (auth_user_id) 
WHERE role = 'parent';

-- Performance indexes
DROP INDEX IF EXISTS idx_family_profiles_auth_user_id;
CREATE INDEX idx_family_profiles_auth_user_id ON family_profiles (auth_user_id);

DROP INDEX IF EXISTS idx_family_profiles_role;
CREATE INDEX idx_family_profiles_role ON family_profiles (role);

-- =====================================================
-- STEP 4: ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE family_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own family profiles" ON family_profiles;
DROP POLICY IF EXISTS "Users can insert their own family profiles" ON family_profiles;
DROP POLICY IF EXISTS "Users can update their own family profiles" ON family_profiles;
DROP POLICY IF EXISTS "Users can delete their own family profiles" ON family_profiles;

-- Create RLS policies
CREATE POLICY "Users can view their own family profiles" ON family_profiles
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert their own family profiles" ON family_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update their own family profiles" ON family_profiles
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can delete their own family profiles" ON family_profiles
    FOR DELETE USING (auth.uid() = auth_user_id);

-- =====================================================
-- STEP 5: CREATE UTILITY FUNCTIONS
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_family_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to enforce exactly one parent per auth user
CREATE OR REPLACE FUNCTION enforce_one_parent_per_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    -- If inserting or updating to parent role
    IF NEW.role = 'parent' THEN
        -- Check if a parent already exists for this auth user
        IF EXISTS (
            SELECT 1 FROM family_profiles 
            WHERE auth_user_id = NEW.auth_user_id 
            AND role = 'parent' 
            AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        ) THEN
            RAISE EXCEPTION 'Only one parent profile allowed per authenticated user';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically create parent profile on user signup
CREATE OR REPLACE FUNCTION handle_new_family_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create profile if user has name metadata (indicating they went through our signup)
    IF NEW.raw_user_meta_data ? 'name' THEN
        RAISE NOTICE 'Creating family profile for user: % with name: %', NEW.email, NEW.raw_user_meta_data->>'name';
        
        INSERT INTO family_profiles (auth_user_id, name, role, email_verified)
        VALUES (
            NEW.id,
            NEW.raw_user_meta_data->>'name',
            'parent',
            (NEW.email_confirmed_at IS NOT NULL)
        );
        
        RAISE NOTICE 'Successfully created family profile for user: %', NEW.email;
    ELSE
        RAISE NOTICE 'Skipping family profile creation for user % - no name in metadata. Metadata: %', NEW.email, NEW.raw_user_meta_data;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: CREATE TRIGGERS
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_family_profiles_updated_at_trigger ON family_profiles;
DROP TRIGGER IF EXISTS enforce_one_parent_per_auth_user_trigger ON family_profiles;
DROP TRIGGER IF EXISTS on_auth_user_created_family ON auth.users;

-- Trigger for automatic updated_at management
CREATE TRIGGER update_family_profiles_updated_at_trigger
    BEFORE UPDATE ON family_profiles
    FOR EACH ROW EXECUTE FUNCTION update_family_profiles_updated_at();

-- Trigger to enforce the one parent rule
CREATE TRIGGER enforce_one_parent_per_auth_user_trigger
    BEFORE INSERT OR UPDATE ON family_profiles
    FOR EACH ROW EXECUTE FUNCTION enforce_one_parent_per_auth_user();

-- Trigger for automatic parent profile creation on signup
CREATE TRIGGER on_auth_user_created_family
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_family_user();

-- =====================================================
-- STEP 7: ADD COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE family_profiles IS 'Family profiles - one parent and multiple children per auth user';
COMMENT ON COLUMN family_profiles.auth_user_id IS 'References the single family auth account';
COMMENT ON COLUMN family_profiles.role IS 'Either parent or child - exactly one parent per auth_user_id';
COMMENT ON COLUMN family_profiles.name IS 'Display name for the profile (parent or child name)';

-- =====================================================
-- STEP 8: CREATE TEST DATA (OPTIONAL - FOR DEVELOPMENT)
-- =====================================================

-- Uncomment this section if you want to create test data for development

/*
-- Create a test family account (you'll need to sign up through your app first)
-- This is just an example of what the data structure looks like

-- Example: If you create a test account with email 'test@family.com'
-- The trigger will automatically create a parent profile
-- You can then manually add child profiles like this:

INSERT INTO family_profiles (auth_user_id, name, role)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'test@family.com' LIMIT 1),
    'Test Child 1',
    'child'
),
(
    (SELECT id FROM auth.users WHERE email = 'test@family.com' LIMIT 1),
    'Test Child 2', 
    'child'
);
*/

-- =====================================================
-- STEP 9: VERIFICATION QUERIES
-- =====================================================

-- Run these queries to verify the setup worked correctly:

-- Check if the table was created properly
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'family_profiles'
ORDER BY ordinal_position;

-- Check if indexes were created
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'family_profiles';

-- Check if triggers were created
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'family_profiles'
OR event_object_table = 'users';

-- Check if RLS policies were created
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'family_profiles';

-- =====================================================
-- DEPLOYMENT COMPLETE! 
-- =====================================================

-- Your family authentication system is now ready to use.
-- 
-- Next steps:
-- 1. Update your iOS app to use the new FamilyAuthCoordinator
-- 2. Test the signup flow to ensure parent profiles are created automatically
-- 3. Test profile creation, management, and security features
-- 
-- For any issues, check the FAMILY_AUTH_IMPLEMENTATION.md guide
-- for troubleshooting and integration instructions. 