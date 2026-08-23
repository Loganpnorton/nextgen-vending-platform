-- Add machine pairing support

-- Enable pg_cron extension for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create pending_machine_links table for pairing flow
CREATE TABLE public.pending_machine_links (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  pairing_code TEXT NOT NULL UNIQUE CHECK (pairing_code ~ '^[0-9]{6}$'),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paired')),
  machine_id UUID REFERENCES public.machines(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add machine_token column to machines table for secure machine access
ALTER TABLE public.machines 
ADD COLUMN IF NOT EXISTS machine_token UUID DEFAULT gen_random_uuid() UNIQUE,
ADD COLUMN IF NOT EXISTS is_paired BOOLEAN DEFAULT false;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_pairing_code ON public.pending_machine_links(pairing_code);
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_status ON public.pending_machine_links(status);
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_expires_at ON public.pending_machine_links(expires_at);
CREATE INDEX IF NOT EXISTS idx_machines_machine_token ON public.machines(machine_token);

-- Enable RLS on pending_machine_links
ALTER TABLE public.pending_machine_links ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for pending_machine_links
-- Anyone can create a pending link (for unpaired machines)
CREATE POLICY "Anyone can create pending machine links" ON public.pending_machine_links
  FOR INSERT WITH CHECK (true);

-- Only authenticated users can view pending links
CREATE POLICY "Authenticated users can view pending machine links" ON public.pending_machine_links
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Only authenticated users can update pending links
CREATE POLICY "Authenticated users can update pending machine links" ON public.pending_machine_links
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Create function to generate random 6-digit pairing code
CREATE OR REPLACE FUNCTION generate_pairing_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists_already BOOLEAN;
BEGIN
  LOOP
    -- Generate a random 6-digit code
    code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    
    -- Check if code already exists and is not expired
    SELECT EXISTS(
      SELECT 1 FROM public.pending_machine_links 
      WHERE pairing_code = code AND expires_at > NOW()
    ) INTO exists_already;
    
    -- If code doesn't exist or is expired, we can use it
    IF NOT exists_already THEN
      RETURN code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create function to create a new pending machine link
CREATE OR REPLACE FUNCTION create_pending_machine_link()
RETURNS TABLE(
  id UUID,
  pairing_code TEXT,
  expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  new_id UUID;
  new_code TEXT;
  new_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Generate unique pairing code
  new_code := generate_pairing_code();
  
  -- Set expiration to 10 minutes from now
  new_expires_at := NOW() + INTERVAL '10 minutes';
  
  -- Insert new pending link
  INSERT INTO public.pending_machine_links (pairing_code, expires_at)
  VALUES (new_code, new_expires_at)
  RETURNING id, pairing_code, expires_at INTO new_id, new_code, new_expires_at;
  
  RETURN QUERY SELECT new_id, new_code, new_expires_at;
END;
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

-- Create function for machines to get their assigned machine_id using pairing code
CREATE OR REPLACE FUNCTION get_machine_id_by_pairing_code(p_pairing_code TEXT)
RETURNS TABLE(
  machine_id UUID,
  machine_token UUID,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  found_machine_id UUID;
  found_machine_token UUID;
BEGIN
  -- Find the paired machine
  SELECT pml.machine_id, m.machine_token
  INTO found_machine_id, found_machine_token
  FROM public.pending_machine_links pml
  JOIN public.machines m ON m.id = pml.machine_id
  WHERE pml.pairing_code = p_pairing_code 
    AND pml.status = 'paired';
  
  -- If no paired machine found
  IF found_machine_id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::UUID as machine_id,
      NULL::UUID as machine_token,
      false as success,
      'No paired machine found for this code' as message;
    RETURN;
  END IF;
  
  RETURN QUERY SELECT 
    found_machine_id as machine_id,
    found_machine_token as machine_token,
    true as success,
    'Machine found' as message;
END;
$$ LANGUAGE plpgsql;

-- Create function to clean up expired pending links
CREATE OR REPLACE FUNCTION cleanup_expired_pending_links()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.pending_machine_links
  WHERE expires_at < NOW() AND status = 'pending';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at on pending_machine_links
CREATE TRIGGER update_pending_machine_links_updated_at
  BEFORE UPDATE ON public.pending_machine_links
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Enhanced RLS policies for machines to support machine token access
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view their own machines" ON public.machines;
DROP POLICY IF EXISTS "Users can insert their own machines" ON public.machines;
DROP POLICY IF EXISTS "Users can update their own machines" ON public.machines;
DROP POLICY IF EXISTS "Users can delete their own machines" ON public.machines;

-- Create new enhanced policies
CREATE POLICY "Users can view their own machines or machines with valid token" ON public.machines
  FOR SELECT USING (
    auth.uid() = user_id OR 
    (machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = machine_token::text)
  );

CREATE POLICY "Users can insert their own machines" ON public.machines
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own machines or machines with valid token" ON public.machines
  FOR UPDATE USING (
    auth.uid() = user_id OR 
    (machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = machine_token::text)
  );

CREATE POLICY "Users can delete their own machines" ON public.machines
  FOR DELETE USING (auth.uid() = user_id);

-- Enhanced RLS policies for machine_products to support machine token access
DROP POLICY IF EXISTS "Users can view machine products for their machines" ON public.machine_products;
DROP POLICY IF EXISTS "Users can insert machine products for their machines" ON public.machine_products;
DROP POLICY IF EXISTS "Users can update machine products for their machines" ON public.machine_products;
DROP POLICY IF EXISTS "Users can delete machine products for their machines" ON public.machine_products;

CREATE POLICY "Users can view machine products for their machines or with valid token" ON public.machine_products
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND 
        (m.user_id = auth.uid() OR 
         (m.machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = m.machine_token::text))
    )
  );

CREATE POLICY "Users can insert machine products for their machines" ON public.machine_products
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
    ) AND
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = machine_products.product_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update machine products for their machines or with valid token" ON public.machine_products
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND 
        (m.user_id = auth.uid() OR 
         (m.machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = m.machine_token::text))
    )
  );

CREATE POLICY "Users can delete machine products for their machines" ON public.machine_products
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
    )
  );

-- Enhanced RLS policies for stock_transactions to support machine token access
DROP POLICY IF EXISTS "Users can view stock transactions for their machines" ON public.stock_transactions;
DROP POLICY IF EXISTS "Users can insert stock transactions for their machines" ON public.stock_transactions;

CREATE POLICY "Users can view stock transactions for their machines or with valid token" ON public.stock_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = stock_transactions.machine_id AND 
        (m.user_id = auth.uid() OR 
         (m.machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = m.machine_token::text))
    )
  );

CREATE POLICY "Users can insert stock transactions for their machines or with valid token" ON public.stock_transactions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = stock_transactions.machine_id AND 
        (m.user_id = auth.uid() OR 
         (m.machine_token IS NOT NULL AND current_setting('request.headers')::json->>'x-machine-token' = m.machine_token::text))
    ) AND
    (auth.uid() = performed_by OR 
     (current_setting('request.headers')::json->>'x-machine-token' IS NOT NULL))
  );

-- Create a scheduled job to clean up expired pending links (runs every hour)
-- Note: This requires pg_cron extension which may not be available in all Supabase projects
-- For now, we'll handle cleanup manually or through application logic
-- SELECT cron.schedule(
--   'cleanup-expired-pending-links',
--   '0 * * * *', -- Every hour
--   'SELECT cleanup_expired_pending_links();'
-- ); 