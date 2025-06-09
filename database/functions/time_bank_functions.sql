-- =====================================================
-- FUNCTIONS: time_bank_functions.sql
-- Description: Core time banking system functions
-- Dependencies: time_banks.sql
-- =====================================================

-- Function to atomically update time bank balance
CREATE OR REPLACE FUNCTION update_time_bank(
    p_user_id UUID,
    p_seconds_delta BIGINT,
    p_description TEXT,
    p_source TEXT,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE (
    new_balance BIGINT,
    transaction_id UUID
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_balance BIGINT;
    v_new_balance BIGINT;
    v_transaction_id UUID;
BEGIN
    -- Validate inputs
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'user_id cannot be null';
    END IF;
    
    IF p_seconds_delta = 0 THEN
        RAISE EXCEPTION 'seconds_delta cannot be zero';
    END IF;
    
    IF length(trim(p_description)) = 0 THEN
        RAISE EXCEPTION 'description cannot be empty';
    END IF;

    -- Lock the time bank row for update to prevent race conditions
    SELECT current_balance_seconds INTO v_current_balance
    FROM time_banks 
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    -- Handle case where time bank doesn't exist
    IF v_current_balance IS NULL THEN
        RAISE EXCEPTION 'Time bank not found for user: %', p_user_id;
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance + p_seconds_delta;
    
    -- Prevent negative balance
    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', 
            v_current_balance, ABS(p_seconds_delta);
    END IF;
    
    -- Update time bank with proper lifetime tracking
    UPDATE time_banks 
    SET 
        current_balance_seconds = v_new_balance,
        lifetime_earned_seconds = CASE 
            WHEN p_seconds_delta > 0 THEN lifetime_earned_seconds + p_seconds_delta 
            ELSE lifetime_earned_seconds 
        END,
        lifetime_spent_seconds = CASE 
            WHEN p_seconds_delta < 0 THEN lifetime_spent_seconds + ABS(p_seconds_delta) 
            ELSE lifetime_spent_seconds 
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Create ledger entry for audit trail
    INSERT INTO time_ledger_entries (
        user_id, 
        transaction_type, 
        seconds_delta, 
        balance_after_seconds,
        description, 
        metadata, 
        source, 
        created_by
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
$$;

-- Function to start an unlocked session
CREATE OR REPLACE FUNCTION start_unlocked_session(
    p_user_id UUID,
    p_duration_minutes INT,
    p_device_identifier TEXT DEFAULT NULL
)
RETURNS TABLE (
    session_id UUID,
    ends_at TIMESTAMPTZ,
    new_balance BIGINT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_cost_seconds INT := p_duration_minutes * 60;
    v_session_id UUID;
    v_ends_at TIMESTAMPTZ;
    v_new_balance BIGINT;
    v_transaction_id UUID;
BEGIN
    -- Validate inputs
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'user_id cannot be null';
    END IF;
    
    IF p_duration_minutes <= 0 OR p_duration_minutes > 480 THEN -- Max 8 hours
        RAISE EXCEPTION 'duration_minutes must be between 1 and 480 (8 hours)';
    END IF;

    -- Generate session details
    v_session_id := uuid_generate_v4();
    v_ends_at := NOW() + INTERVAL '1 minute' * p_duration_minutes;
    
    -- Deduct time from bank (this will validate sufficient balance)
    SELECT update_time_bank.new_balance, update_time_bank.transaction_id
    INTO v_new_balance, v_transaction_id
    FROM update_time_bank(
        p_user_id,
        -v_cost_seconds,
        format('Started %s minute unlocked session', p_duration_minutes),
        'unlocked_session',
        jsonb_build_object(
            'session_id', v_session_id, 
            'duration_minutes', p_duration_minutes,
            'device_identifier', p_device_identifier
        )
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
$$;

-- Function to process offline transactions
CREATE OR REPLACE FUNCTION process_offline_transactions(
    p_user_id UUID
)
RETURNS INT 
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction RECORD;
    v_processed_count INT := 0;
    v_failed_count INT := 0;
BEGIN
    -- Validate input
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'user_id cannot be null';
    END IF;

    -- Process all pending transactions for this user in chronological order
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
            
            -- Mark as successfully processed
            UPDATE offline_transaction_queue 
            SET processed_at = NOW() 
            WHERE id = v_transaction.id;
            
            v_processed_count := v_processed_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Log error and mark as failed, but continue processing
            UPDATE offline_transaction_queue 
            SET 
                processed_at = NOW(),
                error_message = SQLERRM,
                retry_count = retry_count + 1
            WHERE id = v_transaction.id;
            
            v_failed_count := v_failed_count + 1;
            
            -- Log the failure
            RAISE WARNING 'Failed to process offline transaction %: %', 
                v_transaction.id, SQLERRM;
        END;
    END LOOP;
    
    -- Log summary
    RAISE NOTICE 'Processed % offline transactions (% successful, % failed)', 
        v_processed_count + v_failed_count, v_processed_count, v_failed_count;
    
    RETURN v_processed_count;
END;
$$;

-- Comments for documentation
COMMENT ON FUNCTION update_time_bank(UUID, BIGINT, TEXT, TEXT, JSONB) IS 'Atomically updates time bank balance and creates audit log entry';
COMMENT ON FUNCTION start_unlocked_session(UUID, INT, TEXT) IS 'Starts an unlocked session by deducting time from users balance';
COMMENT ON FUNCTION process_offline_transactions(UUID) IS 'Processes queued offline transactions for a user in chronological order'; 