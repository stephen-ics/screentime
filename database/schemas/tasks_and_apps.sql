-- =====================================================
-- SCHEMA: tasks_and_apps.sql
-- Description: Tasks and approved applications
-- Dependencies: profiles.sql
-- =====================================================

-- Tasks - Tasks that can be completed to earn time
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL CHECK (length(title) > 0 AND length(title) <= 200),
    task_description TEXT CHECK (length(task_description) <= 1000),
    reward_seconds INT NOT NULL CHECK (reward_seconds > 0),
    completed_at TIMESTAMPTZ,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_frequency TEXT CHECK (
        recurring_frequency IS NULL OR 
        recurring_frequency IN ('daily', 'weekly', 'monthly')
    ),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Business logic constraints
    CONSTRAINT tasks_recurring_frequency CHECK (
        (is_recurring = false AND recurring_frequency IS NULL) OR
        (is_recurring = true AND recurring_frequency IS NOT NULL)
    ),
    CONSTRAINT tasks_completion_approval CHECK (
        (completed_at IS NULL) OR 
        (completed_at IS NOT NULL AND is_approved = true)
    )
);

-- Approved Apps - Apps that users can access (simplified, no per-app limits)
CREATE TABLE IF NOT EXISTS approved_apps (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) > 0 AND length(name) <= 100),
    bundle_identifier TEXT NOT NULL CHECK (
        length(bundle_identifier) > 0 AND 
        length(bundle_identifier) <= 200 AND
        bundle_identifier ~ '^[a-zA-Z0-9._-]+$'
    ),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate bundle IDs per user
    CONSTRAINT approved_apps_unique_bundle UNIQUE (user_id, bundle_identifier)
);

-- Comments for documentation
COMMENT ON TABLE tasks IS 'Tasks that users can complete to earn time in their time bank';
COMMENT ON COLUMN tasks.reward_seconds IS 'Amount of time earned when task is completed and approved';
COMMENT ON COLUMN tasks.is_recurring IS 'Whether this task can be completed multiple times';
COMMENT ON COLUMN tasks.recurring_frequency IS 'How often recurring tasks can be completed';

COMMENT ON TABLE approved_apps IS 'Applications that users are allowed to access when they have unlocked sessions';
COMMENT ON COLUMN approved_apps.bundle_identifier IS 'iOS app bundle identifier (e.g., com.apple.mobilesafari)';
COMMENT ON COLUMN approved_apps.is_enabled IS 'Whether this app is currently accessible during unlocked sessions'; 