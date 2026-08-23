-- Create a completely new pairing function with a different name
-- This avoids any potential caching or conflict issues

-- Drop the old function completely
DROP FUNCTION IF EXISTS pair_machine_with_code(TEXT, TEXT, TEXT, TEXT);

-- Create a new function with a different name and approach
CREATE OR REPLACE FUNCTION pair_machine_with_code_v2(
  p_pairing_code TEXT,
  p_machine_name TEXT,
  p_location TEXT,
  p_machine_code TEXT
)
RETURNS JSON AS $$
DECLARE
  v_pending_link_id UUID;
  v_new_machine_id UUID;
  v_new_machine_token UUID;
  v_current_user_id UUID;
  v_result JSON;
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
    v_result := json_build_object(
      'machine_id', NULL,
      'machine_token', NULL,
      'success', false,
      'message', 'Invalid or expired pairing code'
    );
    RETURN v_result;
  END IF;
  
  -- Create new machine (allow null user_id for machine-initiated pairing)
  INSERT INTO public.machines (name, location, machine_code, user_id, is_paired)
  VALUES (p_machine_name, p_location, p_machine_code, v_current_user_id, true)
  RETURNING id, machine_token INTO v_new_machine_id, v_new_machine_token;
  
  -- Update the pending link to mark it as paired
  UPDATE public.pending_machine_links
  SET status = 'paired', machine_id = v_new_machine_id, updated_at = NOW()
  WHERE id = v_pending_link_id;
  
  -- Return success result
  v_result := json_build_object(
    'machine_id', v_new_machine_id,
    'machine_token', v_new_machine_token,
    'success', true,
    'message', 'Machine paired successfully'
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the original function name that calls the new one
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
  v_result JSON;
BEGIN
  -- Call the new function
  v_result := pair_machine_with_code_v2(p_pairing_code, p_machine_name, p_location, p_machine_code);
  
  -- Return the result as a table
  RETURN QUERY SELECT 
    (v_result->>'machine_id')::UUID as machine_id,
    (v_result->>'machine_token')::UUID as machine_token,
    (v_result->>'success')::BOOLEAN as success,
    v_result->>'message' as message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users and anon
GRANT EXECUTE ON FUNCTION pair_machine_with_code(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION pair_machine_with_code_v2(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon; 