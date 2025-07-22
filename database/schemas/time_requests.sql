-- =====================================================
-- TIME REQUESTS SCHEMA
-- Description: Manages screen time requests from children to parents
-- =====================================================

-- Create time_requests table
CREATE TABLE IF NOT EXISTS time_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Request details
    child_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    requested_seconds DECIMAL(10,2) NOT NULL CHECK (requested_seconds > 0),
    requested_minutes INTEGER NOT NULL CHECK (requested_minutes > 0),
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    response_message TEXT,
    responded_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    
    -- Additional metadata
    child_email TEXT NOT NULL,
    parent_email TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_response_timing 
        CHECK ((status = 'pending' AND responded_at IS NULL) OR 
               (status IN ('approved', 'denied') AND responded_at IS NOT NULL))
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_time_requests_child_id ON time_requests(child_id);
CREATE INDEX IF NOT EXISTS idx_time_requests_parent_id ON time_requests(parent_id);
CREATE INDEX IF NOT EXISTS idx_time_requests_status ON time_requests(status);
CREATE INDEX IF NOT EXISTS idx_time_requests_created_at ON time_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_time_requests_pending ON time_requests(parent_id, status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_time_requests_realtime ON time_requests(created_at DESC, status);

-- Enable Row Level Security
ALTER TABLE time_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Children can only see their own requests
CREATE POLICY "Children can view own requests" 
    ON time_requests FOR SELECT 
    TO authenticated 
    USING (
        child_id = auth.uid() OR 
        child_id IN (
            SELECT id FROM profiles 
            WHERE user_id = auth.uid() AND user_type = 'child'
        )
    );

-- Parents can see requests for their children
CREATE POLICY "Parents can view family requests" 
    ON time_requests FOR SELECT 
    TO authenticated 
    USING (
        parent_id = auth.uid() OR 
        parent_id IN (
            SELECT id FROM profiles 
            WHERE user_id = auth.uid() AND user_type = 'parent'
        ) OR
        child_id IN (
            SELECT child.id FROM profiles child
            JOIN profiles parent ON child.family_code = parent.family_code
            WHERE parent.user_id = auth.uid() AND parent.user_type = 'parent'
        )
    );

-- Children can create requests
CREATE POLICY "Children can create requests" 
    ON time_requests FOR INSERT 
    TO authenticated 
    WITH CHECK (
        child_id IN (
            SELECT id FROM profiles 
            WHERE user_id = auth.uid() AND user_type = 'child'
        )
    );

-- Parents can update requests (approve/deny)
CREATE POLICY "Parents can update family requests" 
    ON time_requests FOR UPDATE 
    TO authenticated 
    USING (
        parent_id IN (
            SELECT id FROM profiles 
            WHERE user_id = auth.uid() AND user_type = 'parent'
        ) OR
        child_id IN (
            SELECT child.id FROM profiles child
            JOIN profiles parent ON child.family_code = parent.family_code
            WHERE parent.user_id = auth.uid() AND parent.user_type = 'parent'
        )
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_time_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_time_requests_updated_at
    BEFORE UPDATE ON time_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_time_requests_updated_at();

-- Create function to handle time request approval
CREATE OR REPLACE FUNCTION approve_time_request(
    request_id UUID,
    response_msg TEXT DEFAULT NULL
)
RETURNS time_requests AS $$
DECLARE
    updated_request time_requests;
BEGIN
    UPDATE time_requests 
    SET 
        status = 'approved',
        response_message = response_msg,
        responded_at = NOW(),
        processed_at = NOW()
    WHERE id = request_id
      AND status = 'pending'
    RETURNING * INTO updated_request;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Time request not found or already processed';
    END IF;
    
    RETURN updated_request;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle time request denial
CREATE OR REPLACE FUNCTION deny_time_request(
    request_id UUID,
    response_msg TEXT DEFAULT 'Request denied'
)
RETURNS time_requests AS $$
DECLARE
    updated_request time_requests;
BEGIN
    UPDATE time_requests 
    SET 
        status = 'denied',
        response_message = response_msg,
        responded_at = NOW(),
        processed_at = NOW()
    WHERE id = request_id
      AND status = 'pending'
    RETURNING * INTO updated_request;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Time request not found or already processed';
    END IF;
    
    RETURN updated_request;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE time_requests;

COMMENT ON TABLE time_requests IS 'Manages screen time requests from children to parents with real-time updates'; 