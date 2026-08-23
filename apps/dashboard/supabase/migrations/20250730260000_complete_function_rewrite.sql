-- Complete rewrite of the pairing function to avoid ambiguous column issues
-- Use a different approach with explicit column aliases

-- Drop the existing function completely
DROP FUNCTION IF EXISTS pair_machine_with_code(TEXT, TEXT, TEXT, TEXT);

-- Create function to pair a machine with a pairing code
CREATE OR REPLACE FUNCTION pair_machine_with_code(
  p_pairing_code TEXT,
  p_machine_name TEXT,
  p_location TEXT,
  p_machine_code TEXT
)
RETURNS TABLE(
  machine_id UUID,
  machine_token UUID,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_pending_link_id UUID;
  v_new_machine_id UUID;
  v_new_machine_token UUID;
  v_current_user_id UUID;
  v_result_record RECORD;
BEGIN
  -- Get current user ID, default to null if not authenticated
  v_current_user_id := COALESCE(auth.uid(), NULL);
  
  -- Find the pending link
  SELECT id INTO v_pending_link_id
  FROM public.pending_machine_links
  WHERE pairing_code = p_pairing_code 
    AND status = 'pending' 
    AND expires_at > NOW();
  
  -- If no valid pending link found
  IF v_pending_link_id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::UUID as machine_id,
      NULL::UUID as machine_token,
      false as success,
      'Invalid or expired pairing code' as message;
    RETURN;
  END IF;
  
  -- Create new machine (allow null user_id for machine-initiated pairing)
  INSERT INTO public.machines (name, location, machine_code, user_id, is_paired)
  VALUES (p_machine_name, p_location, p_machine_code, v_current_user_id, true)
  RETURNING id, machine_token INTO v_new_machine_id, v_new_machine_token;
  
  -- Update the pending link to mark it as paired
  UPDATE public.pending_machine_links
  SET status = 'paired', machine_id = v_new_machine_id, updated_at = NOW()
  WHERE id = v_pending_link_id;
  
  -- Return the result using a record to avoid column ambiguity
  v_result_record := ROW(v_new_machine_id, v_new_machine_token, true, 'Machine paired successfully');
  RETURN QUERY SELECT 
    v_result_record.column1 as machine_id,
    v_result_record.column2 as machine_token,
    v_result_record.column3 as success,
    v_result_record.column4 as message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users and anon
GRANT EXECUTE ON FUNCTION pair_machine_with_code(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon; 