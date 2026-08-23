-- Final fix for ambiguous column reference in pairing function
-- Use completely different variable names to avoid any ambiguity

-- Drop the existing function
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
  
  RETURN QUERY SELECT 
    v_new_machine_id as machine_id,
    v_new_machine_token as machine_token,
    true as success,
    'Machine paired successfully' as message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users and anon
GRANT EXECUTE ON FUNCTION pair_machine_with_code(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon; 