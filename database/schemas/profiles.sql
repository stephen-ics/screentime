-- =====================================================
-- SCHEMA: profiles.sql
-- Description: User profiles and authentication data
-- Dependencies: None (references auth.users from Supabase)
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('parent', 'child')),
    is_parent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Constraints
    CONSTRAINT profiles_email_check CHECK (length(email) > 0),
    CONSTRAINT profiles_name_check CHECK (length(name) > 0),
    CONSTRAINT profiles_parent_logic_check CHECK (
        (user_type = 'parent' AND is_parent = true) OR 
        (user_type = 'child' AND is_parent = false)
    )
);

-- Comments for documentation
COMMENT ON TABLE profiles IS 'User profiles linked to Supabase auth.users';
COMMENT ON COLUMN profiles.user_type IS 'Either parent or child - determines app permissions';
COMMENT ON COLUMN profiles.is_parent IS 'Computed field for quick parent checks';
COMMENT ON COLUMN profiles.parent_id IS 'Links child accounts to their parent'; 