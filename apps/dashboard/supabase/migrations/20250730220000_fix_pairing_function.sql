-- Fix pairing function and ensure it works correctly
-- Drop and recreate the function to ensure it's properly created

-- Drop the existing function if it exists
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
  pending_link_id UUID;
  new_machine_id UUID;
  new_machine_token UUID;
BEGIN
  -- Find the pending link
  SELECT id INTO pending_link_id
  FROM public.pending_machine_links
  WHERE pairing_code = p_pairing_code 
    AND status = 'pending' 
    AND expires_at > NOW();
  
  -- If no valid pending link found
  IF pending_link_id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::UUID as machine_id,
      NULL::UUID as machine_token,
      false as success,
      'Invalid or expired pairing code' as message;
    RETURN;
  END IF;
  
  -- Create new machine
  INSERT INTO public.machines (name, location, machine_code, user_id, is_paired)
  VALUES (p_machine_name, p_location, p_machine_code, auth.uid(), true)
  RETURNING id, machine_token INTO new_machine_id, new_machine_token;
  
  -- Update the pending link to mark it as paired
  UPDATE public.pending_machine_links
  SET status = 'paired', machine_id = new_machine_id, updated_at = NOW()
  WHERE id = pending_link_id;
  
  RETURN QUERY SELECT 
    new_machine_id as machine_id,
    new_machine_token as machine_token,
    true as success,
    'Machine paired successfully' as message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION pair_machine_with_code(TEXT, TEXT, TEXT, TEXT) TO authenticated; 