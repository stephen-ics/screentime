-- =====================================================
-- SCREENTIME APP - COMPLETE DATABASE SETUP
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- PROFILES TABLE (User Management)
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('parent', 'child')),
  is_parent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  parent_id UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;  
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;  
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =====================================================
-- TIME BANK SYSTEM TABLES
-- =====================================================

-- Time Banks - The central balance for each user
CREATE TABLE IF NOT EXISTS time_banks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    current_balance_seconds INT8 NOT NULL DEFAULT 0,
    lifetime_earned_seconds INT8 NOT NULL DEFAULT 0,
    lifetime_spent_seconds INT8 NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time Ledger - Immutable audit log of all transactions
CREATE TABLE IF NOT EXISTS time_ledger_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'adjustment')),
    seconds_delta INT8 NOT NULL, -- Positive for earning, negative for spending
    balance_after_seconds INT8 NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    source TEXT NOT NULL CHECK (source IN ('task_completion', 'unlocked_session', 'parent_grant', 'admin_adjustment')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Unlocked Sessions - Active sessions where all apps are accessible
CREATE TABLE IF NOT EXISTS unlocked_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    duration_seconds INT NOT NULL,
    cost_seconds INT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    device_identifier TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks - Tasks that can be completed to earn time
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    title TEXT NOT NULL,
    task_description TEXT,
    reward_seconds INT NOT NULL,
    completed_at TIMESTAMPTZ,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_frequency TEXT CHECK (recurring_frequency IN ('daily', 'weekly', 'monthly')),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Approved Apps (simplified - no per-app limits)
CREATE TABLE IF NOT EXISTS approved_apps (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    name TEXT NOT NULL,
    bundle_identifier TEXT NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Offline Transaction Queue
CREATE TABLE IF NOT EXISTS offline_transaction_queue (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'adjustment')),
    seconds_delta INT8 NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    source TEXT NOT NULL CHECK (source IN ('task_completion', 'unlocked_session', 'parent_grant', 'admin_adjustment')),
    client_timestamp TIMESTAMPTZ NOT NULL,
    device_identifier TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to automatically handle updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_time_banks_updated_at ON time_banks;
CREATE TRIGGER update_time_banks_updated_at 
  BEFORE UPDATE ON time_banks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_unlocked_sessions_updated_at ON unlocked_sessions;
CREATE TRIGGER update_unlocked_sessions_updated_at 
  BEFORE UPDATE ON unlocked_sessions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON tasks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_approved_apps_updated_at ON approved_apps;
CREATE TRIGGER update_approved_apps_updated_at 
  BEFORE UPDATE ON approved_apps 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger first, then create it
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- TIME BANK FUNCTIONS
-- =====================================================

-- Function to atomically update time bank balance
CREATE OR REPLACE FUNCTION update_time_bank(
    p_user_id UUID,
    p_seconds_delta INT8,
    p_description TEXT,
    p_source TEXT,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE (
    new_balance INT8,
    transaction_id UUID
) AS $$
DECLARE
    v_current_balance INT8;
    v_new_balance INT8;
    v_transaction_id UUID;
BEGIN
    -- Lock the time bank row for update
    SELECT current_balance_seconds INTO v_current_balance
    FROM time_banks 
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    -- Calculate new balance
    v_new_balance := v_current_balance + p_seconds_delta;
    
    -- Prevent negative balance
    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', v_current_balance, ABS(p_seconds_delta);
    END IF;
    
    -- Update time bank
    UPDATE time_banks 
    SET 
        current_balance_seconds = v_new_balance,
        lifetime_earned_seconds = CASE WHEN p_seconds_delta > 0 THEN lifetime_earned_seconds + p_seconds_delta ELSE lifetime_earned_seconds END,
        lifetime_spent_seconds = CASE WHEN p_seconds_delta < 0 THEN lifetime_spent_seconds + ABS(p_seconds_delta) ELSE lifetime_spent_seconds END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Create ledger entry
    INSERT INTO time_ledger_entries (
        user_id, transaction_type, seconds_delta, balance_after_seconds,
        description, metadata, source, created_by
    ) VALUES (
        p_user_id,
        CASE WHEN p_seconds_delta > 0 THEN 'earn' ELSE 'spend' END,
        p_seconds_delta,
        v_new_balance,
        p_description,
        p_metadata,
        p_source,
        p_user_id
    ) RETURNING id INTO v_transaction_id;
    
    RETURN QUERY SELECT v_new_balance, v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Function to start an unlocked session
CREATE OR REPLACE FUNCTION start_unlocked_session(
    p_user_id UUID,
    p_duration_minutes INT,
    p_device_identifier TEXT DEFAULT NULL
)
RETURNS TABLE (
    session_id UUID,
    ends_at TIMESTAMPTZ,
    new_balance INT8
) AS $$
DECLARE
    v_cost_seconds INT := p_duration_minutes * 60;
    v_session_id UUID;
    v_ends_at TIMESTAMPTZ;
    v_new_balance INT8;
    v_transaction_id UUID;
BEGIN
    -- Start the session
    v_session_id := uuid_generate_v4();
    v_ends_at := NOW() + INTERVAL '1 minute' * p_duration_minutes;
    
    -- Deduct time from bank
    SELECT update_time_bank.new_balance, update_time_bank.transaction_id
    INTO v_new_balance, v_transaction_id
    FROM update_time_bank(
        p_user_id,
        -v_cost_seconds,
        format('Started %s minute unlocked session', p_duration_minutes),
        'unlocked_session',
        jsonb_build_object('session_id', v_session_id, 'duration_minutes', p_duration_minutes)
    );
    
    -- Create session record
    INSERT INTO unlocked_sessions (
        id, user_id, duration_seconds, cost_seconds,
        started_at, ends_at, device_identifier
    ) VALUES (
        v_session_id, p_user_id, v_cost_seconds, v_cost_seconds,
        NOW(), v_ends_at, p_device_identifier
    );
    
    RETURN QUERY SELECT v_session_id, v_ends_at, v_new_balance;
END;
$$ LANGUAGE plpgsql;

-- Function to process offline transactions
CREATE OR REPLACE FUNCTION process_offline_transactions(
    p_user_id UUID
)
RETURNS INT AS $$
DECLARE
    v_transaction RECORD;
    v_processed_count INT := 0;
BEGIN
    -- Process all pending transactions for this user
    FOR v_transaction IN 
        SELECT * FROM offline_transaction_queue 
        WHERE user_id = p_user_id AND processed_at IS NULL
        ORDER BY client_timestamp ASC
    LOOP
        BEGIN
            -- Apply the transaction
            PERFORM update_time_bank(
                v_transaction.user_id,
                v_transaction.seconds_delta,
                v_transaction.description,
                v_transaction.source,
                v_transaction.metadata
            );
            
            -- Mark as processed
            UPDATE offline_transaction_queue 
            SET processed_at = NOW() 
            WHERE id = v_transaction.id;
            
            v_processed_count := v_processed_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Log error but continue processing other transactions
            UPDATE offline_transaction_queue 
            SET 
                processed_at = NOW(),
                metadata = metadata || jsonb_build_object('error', SQLERRM)
            WHERE id = v_transaction.id;
        END;
    END LOOP;
    
    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_time_banks_user_id ON time_banks(user_id);
CREATE INDEX IF NOT EXISTS idx_time_ledger_user_id ON time_ledger_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_time_ledger_created_at ON time_ledger_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_user_id ON unlocked_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_unlocked_sessions_status ON unlocked_sessions(status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approved_apps_user_id ON approved_apps(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_queue_user_id ON offline_transaction_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_queue_processed ON offline_transaction_queue(processed_at);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Time Banks
ALTER TABLE time_banks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own time bank" ON time_banks;
CREATE POLICY "Users can view own time bank" ON time_banks
  FOR SELECT USING (auth.uid() = user_id);

-- Time Ledger
ALTER TABLE time_ledger_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own transactions" ON time_ledger_entries;
CREATE POLICY "Users can view own transactions" ON time_ledger_entries
  FOR SELECT USING (auth.uid() = user_id);

-- Unlocked Sessions  
ALTER TABLE unlocked_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own sessions" ON unlocked_sessions;
CREATE POLICY "Users can view own sessions" ON unlocked_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- Tasks
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view assigned tasks" ON tasks;
CREATE POLICY "Users can view assigned tasks" ON tasks
  FOR SELECT USING (auth.uid() = assigned_to OR auth.uid() = created_by);

-- Approved Apps
ALTER TABLE approved_apps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own apps" ON approved_apps;
CREATE POLICY "Users can view own apps" ON approved_apps
  FOR SELECT USING (auth.uid() = user_id);

-- Offline Queue
ALTER TABLE offline_transaction_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own queue" ON offline_transaction_queue;
CREATE POLICY "Users can manage own queue" ON offline_transaction_queue
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 ScreenTime database setup completed successfully!';
    RAISE NOTICE '✅ All tables, functions, and policies created';
    RAISE NOTICE '✅ Row Level Security enabled';
    RAISE NOTICE '✅ Time Bank system ready';
    RAISE NOTICE '';
    RAISE NOTICE '📱 You can now use the ScreenTime app!';
END $$; 