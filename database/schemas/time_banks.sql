-- =====================================================
-- SCHEMA: time_banks.sql
-- Description: Core time banking system tables
-- Dependencies: profiles.sql
-- =====================================================

-- Time Banks - The central balance for each user
CREATE TABLE IF NOT EXISTS time_banks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    current_balance_seconds BIGINT NOT NULL DEFAULT 0 CHECK (current_balance_seconds >= 0),
    lifetime_earned_seconds BIGINT NOT NULL DEFAULT 0 CHECK (lifetime_earned_seconds >= 0),
    lifetime_spent_seconds BIGINT NOT NULL DEFAULT 0 CHECK (lifetime_spent_seconds >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure balance consistency
    CONSTRAINT time_banks_balance_check CHECK (
        lifetime_earned_seconds >= lifetime_spent_seconds
    )
);

-- Time Ledger - Immutable audit log of all transactions
CREATE TABLE IF NOT EXISTS time_ledger_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'adjustment')),
    seconds_delta BIGINT NOT NULL, -- Positive for earning, negative for spending
    balance_after_seconds BIGINT NOT NULL CHECK (balance_after_seconds >= 0),
    description TEXT NOT NULL CHECK (length(description) > 0),
    metadata JSONB DEFAULT '{}',
    source TEXT NOT NULL CHECK (source IN ('task_completion', 'unlocked_session', 'parent_grant', 'admin_adjustment')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Ensure transaction logic
    CONSTRAINT time_ledger_earn_positive CHECK (
        (transaction_type = 'earn' AND seconds_delta > 0) OR 
        (transaction_type != 'earn')
    ),
    CONSTRAINT time_ledger_spend_negative CHECK (
        (transaction_type = 'spend' AND seconds_delta < 0) OR 
        (transaction_type != 'spend')
    )
);

-- Unlocked Sessions - Active sessions where all apps are accessible
CREATE TABLE IF NOT EXISTS unlocked_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    duration_seconds INT NOT NULL CHECK (duration_seconds > 0),
    cost_seconds INT NOT NULL CHECK (cost_seconds > 0),
    started_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    device_identifier TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure session timing logic
    CONSTRAINT unlocked_sessions_timing CHECK (ends_at > started_at),
    CONSTRAINT unlocked_sessions_duration CHECK (
        EXTRACT(EPOCH FROM (ends_at - started_at)) = duration_seconds
    )
);

-- Offline Transaction Queue - For offline sync capabilities
CREATE TABLE IF NOT EXISTS offline_transaction_queue (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'adjustment')),
    seconds_delta BIGINT NOT NULL,
    description TEXT NOT NULL CHECK (length(description) > 0),
    metadata JSONB DEFAULT '{}',
    source TEXT NOT NULL CHECK (source IN ('task_completion', 'unlocked_session', 'parent_grant', 'admin_adjustment')),
    client_timestamp TIMESTAMPTZ NOT NULL,
    device_identifier TEXT,
    processed_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INT DEFAULT 0 CHECK (retry_count >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments for documentation
COMMENT ON TABLE time_banks IS 'Central time balance for each user in the time banking system';
COMMENT ON TABLE time_ledger_entries IS 'Immutable audit log of all time bank transactions';
COMMENT ON TABLE unlocked_sessions IS 'Active sessions where user has access to all approved apps';
COMMENT ON TABLE offline_transaction_queue IS 'Queue for transactions made while offline'; 