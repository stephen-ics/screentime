-- =====================================================
-- FUNCTIONS: common_functions.sql
-- Description: Common utility functions used across the database
-- Dependencies: None
-- =====================================================

-- Function to automatically handle updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Comment for documentation
COMMENT ON FUNCTION update_updated_at_column() IS 'Trigger function to automatically update updated_at column'; 