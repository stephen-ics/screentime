-- =====================================================
-- SCHEMA: family_profiles.sql
-- Description: Family-based profiles with single auth per family
-- Dependencies: auth.users from Supabase Auth
-- =====================================================

-- Drop existing table if transforming
-- DROP TABLE IF EXISTS profiles CASCADE;

CREATE TABLE IF NOT EXISTS family_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints to ensure data integrity
    CONSTRAINT family_profiles_name_check CHECK (length(trim(name)) > 0),
    CONSTRAINT family_profiles_name_length CHECK (length(name) <= 100),
    
    -- Unique constraint to ensure exactly one parent per auth user
    CONSTRAINT unique_parent_per_auth_user UNIQUE (auth_user_id, role) 
        DEFERRABLE INITIALLY DEFERRED
);

-- Partial unique index to enforce exactly one parent per auth_user_id
CREATE UNIQUE INDEX idx_one_parent_per_auth_user 
ON family_profiles (auth_user_id) 
WHERE role = 'parent';

-- Index for performance on common queries
CREATE INDEX idx_family_profiles_auth_user_id ON family_profiles (auth_user_id);
CREATE INDEX idx_family_profiles_role ON family_profiles (role);

-- Enable Row Level Security (RLS)
ALTER TABLE family_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own family profiles" ON family_profiles
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert their own family profiles" ON family_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update their own family profiles" ON family_profiles
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can delete their own family profiles" ON family_profiles
    FOR DELETE USING (auth.uid() = auth_user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_family_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for automatic updated_at management
CREATE TRIGGER update_family_profiles_updated_at_trigger
    BEFORE UPDATE ON family_profiles
    FOR EACH ROW EXECUTE FUNCTION update_family_profiles_updated_at();

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

-- Trigger to enforce the one parent rule
CREATE TRIGGER enforce_one_parent_per_auth_user_trigger
    BEFORE INSERT OR UPDATE ON family_profiles
    FOR EACH ROW EXECUTE FUNCTION enforce_one_parent_per_auth_user();

-- Function to automatically create parent profile on user signup
CREATE OR REPLACE FUNCTION handle_new_family_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create profile if user has name metadata (indicating they went through our signup)
    IF NEW.raw_user_meta_data ? 'name' THEN
        INSERT INTO family_profiles (auth_user_id, name, role)
        VALUES (
            NEW.id,
            NEW.raw_user_meta_data->>'name',
            'parent'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for automatic parent profile creation on signup
DROP TRIGGER IF EXISTS on_auth_user_created_family ON auth.users;
CREATE TRIGGER on_auth_user_created_family
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_family_user();

-- Comments for documentation
COMMENT ON TABLE family_profiles IS 'Family profiles - one parent and multiple children per auth user';
COMMENT ON COLUMN family_profiles.auth_user_id IS 'References the single family auth account';
COMMENT ON COLUMN family_profiles.role IS 'Either parent or child - exactly one parent per auth_user_id';
COMMENT ON CONSTRAINT unique_parent_per_auth_user ON family_profiles IS 'Ensures exactly one parent profile per authenticated family account'; 