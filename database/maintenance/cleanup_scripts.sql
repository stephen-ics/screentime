-- =====================================================
-- MAINTENANCE: cleanup_scripts.sql
-- Description: Database maintenance and cleanup scripts
-- Dependencies: All schema files
-- =====================================================

-- =====================================================
-- EXPIRED SESSION CLEANUP
-- =====================================================

-- Function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_cleanup_count INT;
BEGIN
    -- Update expired sessions
    UPDATE unlocked_sessions 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active' AND ends_at < NOW();
    
    GET DIAGNOSTICS v_cleanup_count = ROW_COUNT;
    
    RAISE NOTICE 'Marked % expired sessions', v_cleanup_count;
    RETURN v_cleanup_count;
END;
$$;

-- =====================================================
-- OLD DATA ARCHIVAL
-- =====================================================

-- Function to archive old ledger entries (older than 1 year)
CREATE OR REPLACE FUNCTION archive_old_ledger_entries()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_archive_count INT;
    v_cutoff_date TIMESTAMPTZ := NOW() - INTERVAL '1 year';
BEGIN
    -- Create archive table if it doesn't exist
    CREATE TABLE IF NOT EXISTS time_ledger_entries_archive AS 
    SELECT * FROM time_ledger_entries WHERE false;
    
    -- Move old entries to archive
    WITH moved_entries AS (
        DELETE FROM time_ledger_entries 
        WHERE created_at < v_cutoff_date
        RETURNING *
    )
    INSERT INTO time_ledger_entries_archive 
    SELECT * FROM moved_entries;
    
    GET DIAGNOSTICS v_archive_count = ROW_COUNT;
    
    RAISE NOTICE 'Archived % old ledger entries from before %', v_archive_count, v_cutoff_date;
    RETURN v_archive_count;
END;
$$;

-- =====================================================
-- FAILED OFFLINE TRANSACTION CLEANUP
-- =====================================================

-- Function to clean up old failed offline transactions
CREATE OR REPLACE FUNCTION cleanup_failed_offline_transactions()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_cleanup_count INT;
    v_cutoff_date TIMESTAMPTZ := NOW() - INTERVAL '7 days';
BEGIN
    -- Delete old failed transactions (older than 7 days)
    DELETE FROM offline_transaction_queue 
    WHERE processed_at IS NOT NULL 
      AND error_message IS NOT NULL 
      AND processed_at < v_cutoff_date;
    
    GET DIAGNOSTICS v_cleanup_count = ROW_COUNT;
    
    RAISE NOTICE 'Cleaned up % old failed offline transactions from before %', v_cleanup_count, v_cutoff_date;
    RETURN v_cleanup_count;
END;
$$;

-- =====================================================
-- DATABASE STATISTICS AND HEALTH CHECK
-- =====================================================

-- Function to get database health statistics
CREATE OR REPLACE FUNCTION get_database_health_stats()
RETURNS TABLE (
    metric_name TEXT,
    metric_value TEXT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Users'::TEXT, COUNT(*)::TEXT, 
           CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'WARNING' END
    FROM profiles
    
    UNION ALL
    
    SELECT 'Active Sessions'::TEXT, COUNT(*)::TEXT,
           CASE WHEN COUNT(*) < 1000 THEN 'OK' ELSE 'WARNING' END
    FROM unlocked_sessions 
    WHERE status = 'active'
    
    UNION ALL
    
    SELECT 'Pending Offline Transactions'::TEXT, COUNT(*)::TEXT,
           CASE WHEN COUNT(*) < 100 THEN 'OK' ELSE 'WARNING' END
    FROM offline_transaction_queue 
    WHERE processed_at IS NULL
    
    UNION ALL
    
    SELECT 'Failed Offline Transactions'::TEXT, COUNT(*)::TEXT,
           CASE WHEN COUNT(*) < 50 THEN 'OK' ELSE 'WARNING' END
    FROM offline_transaction_queue 
    WHERE error_message IS NOT NULL AND processed_at > NOW() - INTERVAL '24 hours'
    
    UNION ALL
    
    SELECT 'Average Time Bank Balance'::TEXT, 
           ROUND(AVG(current_balance_seconds/60.0), 2)::TEXT || ' minutes',
           'INFO'
    FROM time_banks
    
    UNION ALL
    
    SELECT 'Total Time Earned Today'::TEXT,
           ROUND(SUM(seconds_delta)/60.0, 2)::TEXT || ' minutes',
           'INFO'
    FROM time_ledger_entries 
    WHERE transaction_type = 'earn' 
      AND created_at >= CURRENT_DATE
    
    UNION ALL
    
    SELECT 'Total Time Spent Today'::TEXT,
           ROUND(ABS(SUM(seconds_delta))/60.0, 2)::TEXT || ' minutes',
           'INFO'
    FROM time_ledger_entries 
    WHERE transaction_type = 'spend' 
      AND created_at >= CURRENT_DATE;
END;
$$;

-- =====================================================
-- MAINTENANCE RUNNER FUNCTION
-- =====================================================

-- Function to run all maintenance tasks
CREATE OR REPLACE FUNCTION run_daily_maintenance()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_result TEXT := '';
    v_count INT;
BEGIN
    v_result := v_result || '🧹 Daily Maintenance Report' || E'\n';
    v_result := v_result || '=========================' || E'\n';
    
    -- Clean up expired sessions
    SELECT cleanup_expired_sessions() INTO v_count;
    v_result := v_result || '• Expired sessions cleaned: ' || v_count || E'\n';
    
    -- Clean up failed offline transactions
    SELECT cleanup_failed_offline_transactions() INTO v_count;
    v_result := v_result || '• Failed transactions cleaned: ' || v_count || E'\n';
    
    -- Update statistics
    ANALYZE;
    v_result := v_result || '• Database statistics updated' || E'\n';
    
    v_result := v_result || '✅ Maintenance completed at ' || NOW() || E'\n';
    
    RAISE NOTICE '%', v_result;
    RETURN v_result;
END;
$$;

-- =====================================================
-- EMERGENCY RESET FUNCTIONS (USE WITH CAUTION)
-- =====================================================

-- Function to reset a user's time bank (emergency use only)
CREATE OR REPLACE FUNCTION emergency_reset_user_time_bank(
    p_user_id UUID,
    p_new_balance_minutes INT DEFAULT 0,
    p_reason TEXT DEFAULT 'Emergency reset'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_balance_seconds BIGINT := p_new_balance_minutes * 60;
    v_old_balance BIGINT;
BEGIN
    -- Validate inputs
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'user_id cannot be null';
    END IF;
    
    IF p_new_balance_minutes < 0 THEN
        RAISE EXCEPTION 'new_balance_minutes cannot be negative';
    END IF;
    
    -- Get current balance
    SELECT current_balance_seconds INTO v_old_balance
    FROM time_banks 
    WHERE user_id = p_user_id;
    
    IF v_old_balance IS NULL THEN
        RAISE EXCEPTION 'Time bank not found for user: %', p_user_id;
    END IF;
    
    -- Reset the balance
    UPDATE time_banks 
    SET 
        current_balance_seconds = v_new_balance_seconds,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Create audit log entry
    INSERT INTO time_ledger_entries (
        user_id, transaction_type, seconds_delta, balance_after_seconds,
        description, source, created_by
    ) VALUES (
        p_user_id,
        'adjustment',
        v_new_balance_seconds - v_old_balance,
        v_new_balance_seconds,
        'EMERGENCY RESET: ' || p_reason,
        'admin_adjustment',
        p_user_id
    );
    
    RAISE WARNING 'EMERGENCY: Reset user % time bank from % to % minutes. Reason: %', 
        p_user_id, v_old_balance/60, p_new_balance_minutes, p_reason;
    
    RETURN TRUE;
END;
$$;

-- Comments for documentation
COMMENT ON FUNCTION cleanup_expired_sessions() IS 'Marks expired unlocked sessions as expired';
COMMENT ON FUNCTION archive_old_ledger_entries() IS 'Archives ledger entries older than 1 year';
COMMENT ON FUNCTION get_database_health_stats() IS 'Returns key database health metrics';
COMMENT ON FUNCTION run_daily_maintenance() IS 'Runs all daily maintenance tasks';
COMMENT ON FUNCTION emergency_reset_user_time_bank(UUID, INT, TEXT) IS 'Emergency function to reset a users time bank balance'; 