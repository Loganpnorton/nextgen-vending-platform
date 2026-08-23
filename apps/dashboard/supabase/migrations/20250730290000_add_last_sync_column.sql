-- Add last_sync column to machines table
-- This column will be used to track when machines last checked in

-- Add last_sync column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'machines' 
    AND column_name = 'last_sync'
  ) THEN
    ALTER TABLE machines ADD COLUMN last_sync TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Add index for better performance on last_sync queries
CREATE INDEX IF NOT EXISTS idx_machines_last_sync ON machines(last_sync);

-- Update the machine_checkin function to also update battery_level and total_stock_level
CREATE OR REPLACE FUNCTION machine_checkin(
  p_machine_id UUID,
  p_status JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_machine_exists BOOLEAN;
  v_result JSONB;
  v_battery_level INTEGER;
  v_stock_level INTEGER;
BEGIN
  -- Get the current user ID from the JWT token
  v_user_id := auth.uid();
  
  -- Check if the user is authenticated
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Authentication required'
    );
  END IF;
  
  -- Check if the machine exists and belongs to the authenticated user
  SELECT EXISTS(
    SELECT 1 FROM machines 
    WHERE id = p_machine_id 
    AND user_id = v_user_id
  ) INTO v_machine_exists;
  
  IF NOT v_machine_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Machine not found or access denied'
    );
  END IF;
  
  -- Extract battery and stock level from status data
  v_battery_level := COALESCE((p_status->>'battery')::INTEGER, 100);
  v_stock_level := COALESCE((p_status->>'stock_level')::INTEGER, 0);
  
  -- Update the machine with new status data and sync time
  UPDATE machines 
  SET 
    last_sync = NOW(),
    status_data = p_status,
    battery_level = v_battery_level,
    total_stock_level = v_stock_level,
    connection_status = 'online',
    is_online = true,
    updated_at = NOW()
  WHERE id = p_machine_id;
  
  -- Return success response
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Machine check-in successful',
    'machine_id', p_machine_id,
    'timestamp', NOW()
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Error updating machine status: ' || SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION machine_checkin(UUID, JSONB) TO authenticated; 