-- Add machine_checkin function and related changes
-- This function allows machines to check in with their status data

-- Create the machine_checkin function
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
  
  -- Update the machine with new status data and sync time
  UPDATE machines 
  SET 
    last_sync = NOW(),
    status_data = p_status,
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

-- Add status_data column to machines table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'machines' 
    AND column_name = 'status_data'
  ) THEN
    ALTER TABLE machines ADD COLUMN status_data JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Update RLS policies to allow machine check-in
DROP POLICY IF EXISTS "Users can update their own machines" ON machines;
CREATE POLICY "Users can update their own machines" ON machines
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create a function to mark machines as offline if they haven't checked in recently
CREATE OR REPLACE FUNCTION mark_offline_machines()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update machines that haven't synced in the last 10 minutes
  UPDATE machines 
  SET 
    connection_status = 'offline',
    updated_at = NOW()
  WHERE 
    last_sync IS NULL 
    OR last_sync < NOW() - INTERVAL '10 minutes';
END;
$$;

-- Grant execute permission to the function
GRANT EXECUTE ON FUNCTION mark_offline_machines() TO authenticated;

-- Create a cron job to run the offline check every 5 minutes (if pg_cron is available)
-- Note: This requires pg_cron extension to be enabled in Supabase
DO $$
BEGIN
  -- Only create the cron job if pg_cron is available
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    -- Remove existing job if it exists (ignore errors if job doesn't exist)
    BEGIN
      PERFORM cron.unschedule('mark_offline_machines_job');
    EXCEPTION
      WHEN OTHERS THEN
        -- Job doesn't exist, which is fine
        NULL;
    END;
    
    -- Schedule the job to run every 5 minutes
    PERFORM cron.schedule(
      'mark_offline_machines_job',
      '*/5 * * * *',
      'SELECT mark_offline_machines();'
    );
  END IF;
END $$; 