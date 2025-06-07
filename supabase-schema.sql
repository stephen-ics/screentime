-- =====================================================
-- ScreenTime App - Supabase Database Schema
-- Migration from Core Data to Supabase
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLES
-- =====================================================

-- Profiles table (extends auth.users with app-specific data)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    name TEXT NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('parent', 'child')),
    parent_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    UNIQUE(id)
);

-- Screen time balances table
CREATE TABLE screentime_balances (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    available_seconds FLOAT8 DEFAULT 0,
    daily_limit_seconds FLOAT8 DEFAULT 7200, -- 2 hours default
    weekly_limit_seconds FLOAT8 DEFAULT 50400, -- 14 hours default
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_timer_active BOOLEAN DEFAULT FALSE,
    last_timer_start TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table
CREATE TABLE tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    title TEXT NOT NULL,
    task_description TEXT,
    reward_seconds FLOAT8 DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    is_approved BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_frequency TEXT CHECK (recurring_frequency IN ('daily', 'weekly', 'monthly')),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Approved apps table
CREATE TABLE approved_apps (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    name TEXT NOT NULL,
    bundle_identifier TEXT NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    daily_limit_seconds FLOAT8 DEFAULT 0,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Time requests table (for parent-child time request workflow)
CREATE TABLE time_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    child_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    requested_seconds FLOAT8 NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    response_message TEXT,
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Parent-child relationships table
CREATE TABLE parent_child_links (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    child_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(parent_id, child_id)
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE screentime_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE approved_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_child_links ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Parents can view their children's profiles" ON profiles
    FOR SELECT USING (
        auth.uid() = id OR 
        auth.uid() IN (
            SELECT parent_id FROM parent_child_links 
            WHERE child_id = profiles.id AND is_active = TRUE
        )
    );

-- Screen time balances policies
CREATE POLICY "Users can manage their own screen time balance" ON screentime_balances
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Parents can view children's screen time balance" ON screentime_balances
    FOR SELECT USING (
        auth.uid() = user_id OR
        auth.uid() IN (
            SELECT parent_id FROM parent_child_links 
            WHERE child_id = screentime_balances.user_id AND is_active = TRUE
        )
    );

CREATE POLICY "Parents can update children's screen time balance" ON screentime_balances
    FOR UPDATE USING (
        auth.uid() = user_id OR
        auth.uid() IN (
            SELECT parent_id FROM parent_child_links 
            WHERE child_id = screentime_balances.user_id AND is_active = TRUE
        )
    );

-- Tasks policies
CREATE POLICY "Users can view their assigned tasks" ON tasks
    FOR SELECT USING (
        auth.uid() = assigned_to OR 
        auth.uid() = created_by
    );

CREATE POLICY "Parents can create tasks for their children" ON tasks
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        (assigned_to IS NULL OR 
         assigned_to IN (
             SELECT child_id FROM parent_child_links 
             WHERE parent_id = auth.uid() AND is_active = TRUE
         ))
    );

CREATE POLICY "Users can update tasks they created or are assigned to" ON tasks
    FOR UPDATE USING (
        auth.uid() = created_by OR 
        auth.uid() = assigned_to
    );

CREATE POLICY "Users can delete tasks they created" ON tasks
    FOR DELETE USING (auth.uid() = created_by);

-- Approved apps policies
CREATE POLICY "Users can manage their own approved apps" ON approved_apps
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Parents can manage children's approved apps" ON approved_apps
    FOR ALL USING (
        auth.uid() = user_id OR
        auth.uid() IN (
            SELECT parent_id FROM parent_child_links 
            WHERE child_id = approved_apps.user_id AND is_active = TRUE
        )
    );

-- Time requests policies
CREATE POLICY "Children can create time requests to their parents" ON time_requests
    FOR INSERT WITH CHECK (
        auth.uid() = child_id AND
        parent_id IN (
            SELECT parent_id FROM parent_child_links 
            WHERE child_id = auth.uid() AND is_active = TRUE
        )
    );

CREATE POLICY "Users can view time requests they're involved in" ON time_requests
    FOR SELECT USING (
        auth.uid() = child_id OR 
        auth.uid() = parent_id
    );

CREATE POLICY "Parents can update time requests from their children" ON time_requests
    FOR UPDATE USING (
        auth.uid() = parent_id AND
        child_id IN (
            SELECT child_id FROM parent_child_links 
            WHERE parent_id = auth.uid() AND is_active = TRUE
        )
    );

-- Parent-child links policies
CREATE POLICY "Parents can manage their child links" ON parent_child_links
    FOR ALL USING (auth.uid() = parent_id);

CREATE POLICY "Children can view their parent links" ON parent_child_links
    FOR SELECT USING (auth.uid() = child_id);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to handle updated_at timestamps
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all tables
CREATE TRIGGER handle_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_screentime_balances_updated_at
    BEFORE UPDATE ON screentime_balances
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_approved_apps_updated_at
    BEFORE UPDATE ON approved_apps
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_time_requests_updated_at
    BEFORE UPDATE ON time_requests
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Function to automatically create profile and screen time balance on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert profile (will be updated by the app with actual data)
    INSERT INTO profiles (id, name, user_type)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', 'New User'), 'child');
    
    -- Create screen time balance for the user
    INSERT INTO screentime_balances (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to handle new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to automatically approve time requests and add time to balance
CREATE OR REPLACE FUNCTION handle_time_request_approval()
RETURNS TRIGGER AS $$
BEGIN
    -- If the request was just approved, add time to the child's balance
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        UPDATE screentime_balances 
        SET available_seconds = available_seconds + NEW.requested_seconds,
            updated_at = NOW()
        WHERE user_id = NEW.child_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for time request approval
CREATE TRIGGER on_time_request_approved
    AFTER UPDATE ON time_requests
    FOR EACH ROW EXECUTE FUNCTION handle_time_request_approval();

-- Function to add screen time when tasks are completed and approved
CREATE OR REPLACE FUNCTION handle_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- If task was just completed and is approved, add reward time
    IF NEW.completed_at IS NOT NULL AND OLD.completed_at IS NULL AND NEW.is_approved = TRUE THEN
        UPDATE screentime_balances 
        SET available_seconds = available_seconds + NEW.reward_seconds,
            updated_at = NOW()
        WHERE user_id = NEW.assigned_to;
    -- If task was just approved after being completed, add reward time
    ELSIF NEW.is_approved = TRUE AND OLD.is_approved = FALSE AND NEW.completed_at IS NOT NULL THEN
        UPDATE screentime_balances 
        SET available_seconds = available_seconds + NEW.reward_seconds,
            updated_at = NOW()
        WHERE user_id = NEW.assigned_to;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for task completion rewards
CREATE TRIGGER on_task_completed
    AFTER UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION handle_task_completion();

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes on foreign keys and frequently queried columns
CREATE INDEX idx_profiles_user_type ON profiles(user_type);
CREATE INDEX idx_profiles_parent_id ON profiles(parent_id);
CREATE INDEX idx_screentime_balances_user_id ON screentime_balances(user_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_completed_at ON tasks(completed_at);
CREATE INDEX idx_approved_apps_user_id ON approved_apps(user_id);
CREATE INDEX idx_approved_apps_bundle_identifier ON approved_apps(bundle_identifier);
CREATE INDEX idx_time_requests_child_id ON time_requests(child_id);
CREATE INDEX idx_time_requests_parent_id ON time_requests(parent_id);
CREATE INDEX idx_time_requests_status ON time_requests(status);
CREATE INDEX idx_parent_child_links_parent_id ON parent_child_links(parent_id);
CREATE INDEX idx_parent_child_links_child_id ON parent_child_links(child_id);
CREATE INDEX idx_parent_child_links_active ON parent_child_links(is_active);

-- =====================================================
-- INITIAL DATA (Optional)
-- =====================================================

-- You can add any initial configuration data here
-- For example, default app limits, system settings, etc.

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE profiles IS 'User profiles extending auth.users with app-specific data';
COMMENT ON TABLE screentime_balances IS 'Screen time tracking and limits for users';
COMMENT ON TABLE tasks IS 'Tasks that can be completed to earn screen time';
COMMENT ON TABLE approved_apps IS 'Apps that are monitored for screen time tracking';
COMMENT ON TABLE time_requests IS 'Requests from children to parents for additional screen time';
COMMENT ON TABLE parent_child_links IS 'Relationships between parent and child accounts';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on sequences to authenticated users
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Grant permissions on tables to authenticated users (RLS policies will control access)
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role; 