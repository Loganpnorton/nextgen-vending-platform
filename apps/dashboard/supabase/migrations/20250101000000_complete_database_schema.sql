-- Complete database schema for vending machine management system
-- This migration creates all necessary tables, functions, policies, and indexes

-- =====================================================
-- EXTENSIONS
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- =====================================================
-- TABLES
-- =====================================================

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  company_name TEXT,
  is_onboarded BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User preferences table
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  unit_system TEXT NOT NULL DEFAULT 'imperial' CHECK (unit_system IN ('imperial', 'metric')),
  timezone TEXT NOT NULL DEFAULT 'UTC',
  default_machine_view TEXT NOT NULL DEFAULT 'grid' CHECK (default_machine_view IN ('grid', 'list', 'map')),
  notifications_low_inventory BOOLEAN NOT NULL DEFAULT true,
  notifications_machine_errors BOOLEAN NOT NULL DEFAULT true,
  notifications_weekly_reports BOOLEAN NOT NULL DEFAULT false,
  theme TEXT NOT NULL DEFAULT 'dark' CHECK (theme IN ('light', 'dark', 'auto')),
  default_landing_page TEXT NOT NULL DEFAULT 'dashboard' CHECK (default_landing_page IN ('dashboard', 'machines', 'analytics')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Machines table
CREATE TABLE IF NOT EXISTS public.machines (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  machine_code TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'offline')),
  connection_status TEXT NOT NULL DEFAULT 'offline' CHECK (connection_status IN ('online', 'warning', 'offline')),
  battery_level INTEGER DEFAULT 100 CHECK (battery_level >= 0 AND battery_level <= 100),
  last_ping TIMESTAMP WITH TIME ZONE,
  last_sync TIMESTAMP WITH TIME ZONE,
  alerts_count INTEGER NOT NULL DEFAULT 0,
  total_stock_level INTEGER NOT NULL DEFAULT 0,
  is_online BOOLEAN NOT NULL DEFAULT false,
  status_data JSONB DEFAULT '{}',
  machine_token TEXT UNIQUE,
  is_paired BOOLEAN DEFAULT false,
  last_offline TIMESTAMP WITH TIME ZONE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  product_code TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,
  base_price DECIMAL(10,2) NOT NULL,
  description TEXT,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Product images table
CREATE TABLE IF NOT EXISTS public.product_images (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  mime_type TEXT,
  file_hash TEXT,
  file_name TEXT,
  file_size INTEGER,
  height INTEGER,
  width INTEGER,
  metadata JSONB,
  uploader_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Machine products table (stock levels per machine)
CREATE TABLE IF NOT EXISTS public.machine_products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  current_stock INTEGER NOT NULL DEFAULT 0,
  par_level INTEGER NOT NULL DEFAULT 50,
  price_override DECIMAL(10,2),
  slot_position INTEGER,
  max_stock_recorded INTEGER,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(machine_id, product_id)
);

-- Stock transactions table (audit trail)
CREATE TABLE IF NOT EXISTS public.stock_transactions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('restock', 'sale', 'removal', 'adjustment')),
  quantity_change INTEGER NOT NULL,
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  performed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  machine_id UUID REFERENCES public.machines(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('sale', 'low_stock', 'error', 'warning', 'info', 'success')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  machine_code TEXT,
  machine_name TEXT,
  location TEXT,
  sale_amount DECIMAL(10,2),
  items_sold INTEGER,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User 2FA table
CREATE TABLE IF NOT EXISTS public.user_2fa (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  secret TEXT NOT NULL,
  backup_codes TEXT[] DEFAULT '{}',
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Pending machine links table (for pairing flow)
CREATE TABLE IF NOT EXISTS public.pending_machine_links (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  pairing_code TEXT NOT NULL UNIQUE CHECK (pairing_code ~ '^[0-9]{6}$'),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paired')),
  machine_id UUID REFERENCES public.machines(id) ON DELETE CASCADE,
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  machine_id UUID REFERENCES public.machines(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('sale', 'low_stock', 'error', 'warning', 'info', 'success')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  machine_code TEXT,
  machine_name TEXT,
  location TEXT,
  sale_amount DECIMAL(10,2),
  items_sold INTEGER,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Machine cameras table
CREATE TABLE IF NOT EXISTS public.machine_cameras (
  machine_id UUID PRIMARY KEY REFERENCES public.machines(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'unknown' CHECK (status IN ('unknown', 'No camera', 'Permission denied', 'Error', 'Healthy', 'Detected')),
  has_camera BOOLEAN DEFAULT false,
  permission TEXT CHECK (permission IN ('granted', 'denied', 'prompt', 'unknown')),
  device_label_hash TEXT,
  device_id_hash TEXT,
  facing TEXT CHECK (facing IN ('environment', 'user', 'unknown')),
  resolution TEXT,
  fps INTEGER,
  last_error TEXT,
  snapshot_url TEXT,
  snapshot_at TIMESTAMPTZ,
  snapshot_requested_at TIMESTAMPTZ,
  last_seen TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Live stream offers table (WebRTC)
CREATE TABLE IF NOT EXISTS public.live_stream_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  offer JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT now() + interval '5 minutes',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired'))
);

-- Live stream answers table (WebRTC)
CREATE TABLE IF NOT EXISTS public.live_stream_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES public.live_stream_offers(id) ON DELETE CASCADE,
  answer JSONB NOT NULL,
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ICE candidates table (WebRTC)
CREATE TABLE IF NOT EXISTS public.live_stream_ice_candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES public.live_stream_offers(id) ON DELETE CASCADE,
  candidate JSONB NOT NULL,
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Stream frames table (for video streaming)
CREATE TABLE IF NOT EXISTS public.stream_frames (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
  image_data TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT now(),
  frame_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data ->> 'full_name');

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$;

-- Function to generate pairing code
CREATE OR REPLACE FUNCTION generate_pairing_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists_already BOOLEAN;
BEGIN
  LOOP
    code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

    SELECT EXISTS(
      SELECT 1 FROM public.pending_machine_links
      WHERE pairing_code = code AND expires_at > NOW()
    ) INTO exists_already;

    IF NOT exists_already THEN
      RETURN code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to create pending machine link
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
  new_code := generate_pairing_code();
  new_expires_at := NOW() + INTERVAL '10 minutes';

  INSERT INTO public.pending_machine_links (pairing_code, expires_at)
  VALUES (new_code, new_expires_at)
  RETURNING id, pairing_code, expires_at INTO new_id, new_code, new_expires_at;

  RETURN QUERY SELECT new_id, new_code, new_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Function to pair machine with code
CREATE OR REPLACE FUNCTION pair_machine_with_code(
  p_pairing_code TEXT,
  p_machine_name TEXT,
  p_location TEXT,
  p_machine_code TEXT
)
RETURNS TABLE(
  machine_id UUID,
  machine_token TEXT,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  pending_link_id UUID;
  new_machine_id UUID;
  new_machine_token TEXT;
BEGIN
  SELECT id INTO pending_link_id
  FROM public.pending_machine_links
  WHERE pairing_code = p_pairing_code
    AND status = 'pending'
    AND expires_at > NOW();

  IF pending_link_id IS NULL THEN
    RETURN QUERY SELECT
      NULL::UUID as machine_id,
      NULL::UUID as machine_token,
      false as success,
      'Invalid or expired pairing code' as message;
    RETURN;
  END IF;

  INSERT INTO public.machines (name, location, machine_code, user_id, is_paired)
  VALUES (p_machine_name, p_location, p_machine_code, auth.uid(), true)
  RETURNING id, machine_token INTO new_machine_id, new_machine_token;

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

-- Function to get machine ID by pairing code
CREATE OR REPLACE FUNCTION get_machine_id_by_pairing_code(p_pairing_code TEXT)
RETURNS TABLE(
  machine_id UUID,
  machine_token TEXT,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  found_machine_id UUID;
  found_machine_token TEXT;
BEGIN
  SELECT pml.machine_id, m.machine_token
  INTO found_machine_id, found_machine_token
  FROM public.pending_machine_links pml
  JOIN public.machines m ON m.id = pml.machine_id
  WHERE pml.pairing_code = p_pairing_code
    AND pml.status = 'paired';

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

-- Function to clean up expired pending links
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

-- Function to calculate machine stock level
CREATE OR REPLACE FUNCTION calculate_machine_stock_level(machine_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_stock INTEGER := 0;
BEGIN
  SELECT COALESCE(SUM(current_stock), 0)
  INTO total_stock
  FROM machine_products
  WHERE machine_id = machine_uuid;

  RETURN total_stock;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete machine pairing
CREATE OR REPLACE FUNCTION complete_machine_pairing(
  pairing_code_param TEXT,
  machine_code_param TEXT,
  machine_token_param TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  pending_link_record RECORD;
BEGIN
  -- Find the pending link
  SELECT * INTO pending_link_record
  FROM pending_machine_links
  WHERE pairing_code = pairing_code_param
    AND status = 'pending'
    AND expires_at > NOW();

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Invalid or expired pairing code';
    RETURN;
  END IF;

  -- Update the machine with the pairing information
  UPDATE machines
  SET machine_token = machine_token_param,
      is_paired = true,
      updated_at = NOW()
  WHERE machine_code = machine_code_param;

  -- Mark the pairing link as used
  UPDATE pending_machine_links
  SET status = 'paired',
      machine_id = (SELECT id FROM machines WHERE machine_code = machine_code_param),
      used_at = NOW(),
      updated_at = NOW()
  WHERE id = pending_link_record.id;

  RETURN QUERY SELECT true, 'Machine paired successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create pending machine link for kiosk
CREATE OR REPLACE FUNCTION create_pending_machine_link_kiosk()
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
  RETURNING pending_machine_links.id, pairing_code, expires_at INTO new_id, new_code, new_expires_at;

  RETURN QUERY SELECT new_id, new_code, new_expires_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to pair machine with code v2
CREATE OR REPLACE FUNCTION pair_machine_with_code_v2(
  p_pairing_code TEXT,
  p_machine_name TEXT,
  p_location TEXT,
  p_machine_code TEXT
)
RETURNS JSON AS $$
DECLARE
  result JSON;
  pending_link_id UUID;
  new_machine_id UUID;
BEGIN
  -- Find the pending link
  SELECT id INTO pending_link_id
  FROM public.pending_machine_links
  WHERE pairing_code = p_pairing_code
    AND status = 'pending'
    AND expires_at > NOW();

  -- If no valid pending link found
  IF pending_link_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Invalid or expired pairing code'
    );
  END IF;

  -- Create new machine
  INSERT INTO public.machines (name, location, machine_code, user_id, is_paired)
  VALUES (p_machine_name, p_location, p_machine_code, auth.uid(), true)
  RETURNING id INTO new_machine_id;

  -- Update the pending link to mark it as paired
  UPDATE public.pending_machine_links
  SET status = 'paired', machine_id = new_machine_id, used_at = NOW(), updated_at = NOW()
  WHERE id = pending_link_id;

  RETURN json_build_object(
    'success', true,
    'message', 'Machine paired successfully',
    'machine_id', new_machine_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get machine stock trend
CREATE OR REPLACE FUNCTION get_machine_stock_trend(
  p_machine_id UUID,
  p_product_id UUID DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_from_ts TIMESTAMPTZ DEFAULT NULL,
  p_to_ts TIMESTAMPTZ DEFAULT NULL,
  p_bucket TEXT DEFAULT 'day'
)
RETURNS TABLE (
  ts TIMESTAMPTZ,
  stock_units INTEGER,
  capacity_units INTEGER,
  product_id UUID,
  product_name TEXT,
  product_category TEXT,
  restock_delta INTEGER,
  sold_out BOOLEAN
) AS $$
BEGIN
  IF p_from_ts IS NULL THEN
    p_from_ts := NOW() - INTERVAL '30 days';
  END IF;

  IF p_to_ts IS NULL THEN
    p_to_ts := NOW();
  END IF;

  RETURN QUERY
  SELECT
    t.ts,
    t.stock_units,
    mp.par_level as capacity_units,
    t.product_id,
    p.name as product_name,
    p.category as product_category,
    t.restock_delta,
    t.sold_out
  FROM machine_stock_trend_v t
  JOIN products p ON t.product_id = p.id
  LEFT JOIN machine_products mp ON t.machine_id = mp.machine_id AND t.product_id = mp.product_id
  WHERE t.machine_id = p_machine_id
    AND t.bucket_type = p_bucket
    AND t.ts >= p_from_ts
    AND t.ts <= p_to_ts
    AND (p_product_id IS NULL OR t.product_id = p_product_id)
    AND (p_category IS NULL OR p.category = p_category)
  ORDER BY t.ts ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get aggregate machine stock trend
CREATE OR REPLACE FUNCTION get_machine_stock_trend_aggregate(
  p_machine_id UUID,
  p_category TEXT DEFAULT NULL,
  p_from_ts TIMESTAMPTZ DEFAULT NULL,
  p_to_ts TIMESTAMPTZ DEFAULT NULL,
  p_bucket TEXT DEFAULT 'day'
)
RETURNS TABLE (
  ts TIMESTAMPTZ,
  total_stock_units INTEGER,
  total_capacity_units INTEGER,
  restock_events INTEGER,
  sold_out_events INTEGER
) AS $$
BEGIN
  IF p_from_ts IS NULL THEN
    p_from_ts := NOW() - INTERVAL '30 days';
  END IF;

  IF p_to_ts IS NULL THEN
    p_to_ts := NOW();
  END IF;

  RETURN QUERY
  SELECT
    t.ts,
    SUM(t.stock_units) as total_stock_units,
    SUM(COALESCE(mp.par_level, 0)) as total_capacity_units,
    COUNT(t.restock_delta) FILTER (WHERE t.restock_delta IS NOT NULL) as restock_events,
    COUNT(*) FILTER (WHERE t.sold_out) as sold_out_events
  FROM machine_stock_trend_v t
  JOIN products p ON t.product_id = p.id
  LEFT JOIN machine_products mp ON t.machine_id = mp.machine_id AND t.product_id = mp.product_id
  WHERE t.machine_id = p_machine_id
    AND t.bucket_type = p_bucket
    AND t.ts >= p_from_ts
    AND t.ts <= p_to_ts
    AND (p_category IS NULL OR p.category = p_category)
  GROUP BY t.ts
  ORDER BY t.ts ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update camera status
CREATE OR REPLACE FUNCTION update_camera_status()
RETURNS TRIGGER
AS $$
BEGIN
  IF NEW.has_camera = false THEN
    NEW.status = 'No camera';
  ELSIF NEW.permission = 'denied' THEN
    NEW.status = 'Permission denied';
  ELSIF NEW.last_error IS NOT NULL AND NEW.last_error != '' THEN
    NEW.status = 'Error';
  ELSIF NEW.snapshot_at IS NOT NULL AND NEW.snapshot_at > now() - interval '10 minutes' THEN
    NEW.status = 'Healthy';
  ELSE
    NEW.status = 'Detected';
  END IF;

  NEW.last_seen = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create live stream offer
CREATE OR REPLACE FUNCTION create_live_stream_offer(
  machine_id_param UUID,
  offer_param JSONB
)
RETURNS UUID
SECURITY DEFINER
AS $$
DECLARE
  offer_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_id_param
    AND m.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  INSERT INTO public.live_stream_offers (machine_id, offer)
  VALUES (machine_id_param, offer_param)
  RETURNING id INTO offer_id;

  RETURN offer_id;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired live stream offers
CREATE OR REPLACE FUNCTION cleanup_expired_live_stream_offers()
RETURNS void
AS $$
BEGIN
  UPDATE public.live_stream_offers
  SET status = 'expired'
  WHERE expires_at < now() AND status = 'pending';
END;
$$ LANGUAGE plpgsql;

-- Function to get machine snapshot URL
CREATE OR REPLACE FUNCTION get_machine_snapshot_url(machine_id_param UUID, file_path TEXT)
RETURNS TEXT
SECURITY DEFINER
AS $$
DECLARE
  signed_url TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_id_param
    AND m.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT storage.sign_url(
    'machine-snapshots',
    file_path,
    interval '24 hours'
  ) INTO signed_url;

  RETURN signed_url;
END;
$$ LANGUAGE plpgsql;

-- Machine checkin function
CREATE OR REPLACE FUNCTION machine_checkin(
  p_machine_id UUID,
  p_status JSONB
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
  machine_record RECORD;
BEGIN
  -- Get machine info
  SELECT * INTO machine_record FROM machines WHERE id = p_machine_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Machine not found',
      'timestamp', extract(epoch from now())
    );
  END IF;

  -- Update machine status
  UPDATE machines SET
    status_data = p_status,
    battery_level = COALESCE((p_status->>'battery')::integer, battery_level),
    last_ping = now(),
    connection_status = 'online',
    is_online = true,
    updated_at = now()
  WHERE id = p_machine_id;

  -- Update camera status if present
  IF p_status ? 'camera' THEN
    INSERT INTO machine_cameras (machine_id, status, has_camera, permission, device_label_hash, device_id_hash, facing, resolution, fps, last_error)
    VALUES (
      p_machine_id,
      CASE
        WHEN (p_status->'camera'->>'hasCamera')::boolean = false THEN 'No camera'
        WHEN (p_status->'camera'->>'permission') = 'denied' THEN 'Permission denied'
        WHEN (p_status->'camera'->>'error') IS NOT NULL THEN 'Error'
        ELSE 'Detected'
      END,
      COALESCE((p_status->'camera'->>'hasCamera')::boolean, false),
      (p_status->'camera'->>'permission'),
      (p_status->'camera'->>'deviceLabelHash'),
      (p_status->'camera'->>'deviceIdHash'),
      (p_status->'camera'->>'facing'),
      (p_status->'camera'->>'resolution'),
      (p_status->'camera'->>'fps')::integer,
      (p_status->'camera'->>'error')
    )
    ON CONFLICT (machine_id) DO UPDATE SET
      status = EXCLUDED.status,
      has_camera = EXCLUDED.has_camera,
      permission = EXCLUDED.permission,
      device_label_hash = EXCLUDED.device_label_hash,
      device_id_hash = EXCLUDED.device_id_hash,
      facing = EXCLUDED.facing,
      resolution = EXCLUDED.resolution,
      fps = EXCLUDED.fps,
      last_error = EXCLUDED.last_error,
      updated_at = now();
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Machine check-in successful',
    'machine_id', p_machine_id,
    'timestamp', extract(epoch from now())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark offline machines
CREATE OR REPLACE FUNCTION mark_offline_machines()
RETURNS void AS $$
BEGIN
  UPDATE machines
  SET
    connection_status = 'offline',
    is_online = false,
    last_offline_timestamp = now()
  WHERE last_ping < now() - interval '5 minutes'
    AND connection_status != 'offline';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_preferences_updated_at
  BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_machines_updated_at
  BEFORE UPDATE ON public.machines
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_machine_products_updated_at
  BEFORE UPDATE ON public.machine_products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_2fa_updated_at
  BEFORE UPDATE ON public.user_2fa
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_pending_machine_links_updated_at
  BEFORE UPDATE ON public.pending_machine_links
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Create trigger for camera status updates
CREATE TRIGGER trigger_update_camera_status
  BEFORE INSERT OR UPDATE ON public.machine_cameras
  FOR EACH ROW
  EXECUTE FUNCTION update_camera_status();

-- Function to update machine cameras timestamp
CREATE OR REPLACE FUNCTION update_machine_cameras_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_machine_cameras_updated_at
  BEFORE UPDATE ON public.machine_cameras
  FOR EACH ROW
  EXECUTE FUNCTION update_machine_cameras_updated_at();

-- Trigger to create profile and preferences on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- INDEXES
-- =====================================================

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_pairing_code ON public.pending_machine_links(pairing_code);
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_status ON public.pending_machine_links(status);
CREATE INDEX IF NOT EXISTS idx_pending_machine_links_expires_at ON public.pending_machine_links(expires_at);
CREATE INDEX IF NOT EXISTS idx_machines_machine_token ON public.machines(machine_token);
CREATE INDEX IF NOT EXISTS idx_machines_user_id ON public.machines(user_id);
CREATE INDEX IF NOT EXISTS idx_machine_products_machine_product ON public.machine_products(machine_id, product_id);
CREATE INDEX IF NOT EXISTS idx_stock_transactions_machine_product_time ON public.stock_transactions(machine_id, product_id, created_at);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_machine_cameras_status ON public.machine_cameras(status);
CREATE INDEX IF NOT EXISTS idx_machine_cameras_last_seen ON public.machine_cameras(last_seen);
CREATE INDEX IF NOT EXISTS idx_machine_cameras_snapshot_requested ON public.machine_cameras(snapshot_requested_at);
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_machine_id ON public.live_stream_offers(machine_id);
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_status ON public.live_stream_offers(status);
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_expires_at ON public.live_stream_offers(expires_at);
CREATE INDEX IF NOT EXISTS idx_live_stream_answers_offer_id ON public.live_stream_answers(offer_id);
CREATE INDEX IF NOT EXISTS idx_live_stream_ice_candidates_offer_id ON public.live_stream_ice_candidates(offer_id);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machine_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_2fa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_machine_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machine_cameras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_stream_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_stream_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_stream_ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stream_frames ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- User preferences policies
CREATE POLICY "Users can view their own preferences"
ON public.user_preferences FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
ON public.user_preferences FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences"
ON public.user_preferences FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Machines policies
CREATE POLICY "Users can view their own machines or machines with valid token"
ON public.machines FOR SELECT
USING (
  auth.uid() = user_id OR
  (machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = machine_token::text)
);

CREATE POLICY "Users can insert their own machines"
ON public.machines FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own machines or machines with valid token"
ON public.machines FOR UPDATE
USING (
  auth.uid() = user_id OR
  (machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = machine_token::text)
);

CREATE POLICY "Users can delete their own machines"
ON public.machines FOR DELETE
USING (auth.uid() = user_id);

-- Products policies
CREATE POLICY "Users can view their own products"
ON public.products FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own products"
ON public.products FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own products"
ON public.products FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products"
ON public.products FOR DELETE
USING (auth.uid() = user_id);

-- Product images policies
CREATE POLICY "Users can view product images for their products"
ON public.product_images FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert product images for their products"
ON public.product_images FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Users can update product images for their products"
ON public.product_images FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete product images for their products"
ON public.product_images FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
  )
);

-- Machine products policies
CREATE POLICY "Users can view machine products for their machines or with valid token"
ON public.machine_products FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_products.machine_id AND
      (m.user_id = auth.uid() OR
       (m.machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = m.machine_token::text))
  )
);

CREATE POLICY "Users can insert machine products for their machines"
ON public.machine_products FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
  ) AND
  EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.id = machine_products.product_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Users can update machine products for their machines or with valid token"
ON public.machine_products FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_products.machine_id AND
      (m.user_id = auth.uid() OR
       (m.machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = m.machine_token::text))
  )
);

CREATE POLICY "Users can delete machine products for their machines"
ON public.machine_products FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
  )
);

-- Stock transactions policies
CREATE POLICY "Users can view stock transactions for their machines or with valid token"
ON public.stock_transactions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = stock_transactions.machine_id AND
      (m.user_id = auth.uid() OR
       (m.machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = m.machine_token::text))
  )
);

CREATE POLICY "Users can insert stock transactions for their machines or with valid token"
ON public.stock_transactions FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = stock_transactions.machine_id AND
      (m.user_id = auth.uid() OR
       (m.machine_token IS NOT NULL AND current_setting('request.headers', true)::json->>'x-machine-token' = m.machine_token::text))
  ) AND
  (auth.uid() = performed_by OR
   (current_setting('request.headers', true)::json->>'x-machine-token' IS NOT NULL))
);

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
ON public.notifications FOR INSERT
WITH CHECK (true);

-- User 2FA policies
CREATE POLICY "Users can view their own 2FA settings"
ON public.user_2fa FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own 2FA settings"
ON public.user_2fa FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own 2FA settings"
ON public.user_2fa FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own 2FA settings"
ON public.user_2fa FOR DELETE
USING (auth.uid() = user_id);

-- Pending machine links policies
CREATE POLICY "Anyone can create pending machine links"
ON public.pending_machine_links FOR INSERT
WITH CHECK (true);

CREATE POLICY "Authenticated users can view pending machine links"
ON public.pending_machine_links FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update pending machine links"
ON public.pending_machine_links FOR UPDATE
USING (auth.uid() IS NOT NULL);

-- Machine cameras policies
CREATE POLICY "Users can view their own machine cameras"
ON public.machine_cameras FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_cameras.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Users can update their own machine cameras"
ON public.machine_cameras FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = machine_cameras.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Machine token can insert camera data"
ON public.machine_cameras FOR INSERT
WITH CHECK (true);

CREATE POLICY "Machine token can update camera data"
ON public.machine_cameras FOR UPDATE
USING (true);

-- Live stream offers policies
CREATE POLICY "Users can manage their own live stream offers"
ON public.live_stream_offers FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = live_stream_offers.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Machine token can view live stream offers"
ON public.live_stream_offers FOR SELECT
USING (
  machine_id IN (
    SELECT id FROM public.machines
    WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::text
  )
);

-- Live stream answers policies
CREATE POLICY "Users can view their own live stream answers"
ON public.live_stream_answers FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = live_stream_answers.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Machine token can insert live stream answers"
ON public.live_stream_answers FOR INSERT
WITH CHECK (
  machine_id IN (
    SELECT id FROM public.machines
    WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::text
  )
);

-- Live stream ICE candidates policies
CREATE POLICY "Users can view their own live stream ICE candidates"
ON public.live_stream_ice_candidates FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = live_stream_ice_candidates.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Machine token can manage live stream ICE candidates"
ON public.live_stream_ice_candidates FOR ALL
USING (
  machine_id IN (
    SELECT id FROM public.machines
    WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::text
  )
);

-- Stream frames policies
CREATE POLICY "Users can view their own machine stream frames"
ON public.stream_frames FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id = stream_frames.machine_id
    AND m.user_id = auth.uid()
  )
);

CREATE POLICY "Machine token can insert stream frames"
ON public.stream_frames FOR INSERT
WITH CHECK (
  machine_id IN (
    SELECT id FROM public.machines
    WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::text
  )
);

-- =====================================================
-- STORAGE BUCKETS
-- =====================================================

-- Create avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create product-images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create machine-snapshots bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'machine-snapshots',
  'machine-snapshots',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/jpg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Avatar storage policies
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Product images storage policies
CREATE POLICY "Product images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

CREATE POLICY "Users can upload product images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their product images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their product images"
ON storage.objects FOR DELETE
USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Machine snapshots storage policies
CREATE POLICY "Users can view their own machine snapshots"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'machine-snapshots' AND
  EXISTS (
    SELECT 1 FROM public.machines m
    WHERE m.id::text = (storage.foldername(name))[1]
    AND m.user_id = auth.uid()
  )
);

-- =====================================================
-- VIEWS
-- =====================================================

-- Create machine stock trend view
CREATE OR REPLACE VIEW machine_stock_trend_v AS
WITH stock_changes AS (
  SELECT
    machine_id,
    product_id,
    created_at,
    quantity_change,
    transaction_type,
    SUM(quantity_change) OVER (
      PARTITION BY machine_id, product_id
      ORDER BY created_at
      ROWS UNBOUNDED PRECEDING
    ) as running_stock
  FROM stock_transactions
  WHERE transaction_type IN ('restock', 'sale', 'removal', 'adjustment')
),
time_buckets AS (
  SELECT
    machine_id,
    product_id,
    date_trunc('hour', created_at) as ts_hour,
    date_trunc('day', created_at) as ts_day,
    LAST_VALUE(running_stock) OVER (
      PARTITION BY machine_id, product_id, date_trunc('hour', created_at)
      ORDER BY created_at
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as stock_units_hour,
    LAST_VALUE(running_stock) OVER (
      PARTITION BY machine_id, product_id, date_trunc('day', created_at)
      ORDER BY created_at
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as stock_units_day,
    CASE WHEN transaction_type = 'restock' AND quantity_change > 0 THEN quantity_change ELSE NULL END as restock_delta,
    CASE WHEN running_stock <= 0 THEN true ELSE false END as sold_out
  FROM stock_changes
)
SELECT
  machine_id,
  product_id,
  ts_hour as ts,
  'hour' as bucket_type,
  stock_units_hour as stock_units,
  restock_delta,
  sold_out
FROM time_buckets
WHERE stock_units_hour IS NOT NULL

UNION ALL

SELECT
  machine_id,
  product_id,
  ts_day as ts,
  'day' as bucket_type,
  stock_units_day as stock_units,
  restock_delta,
  sold_out
FROM time_buckets
WHERE stock_units_day IS NOT NULL;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for views and functions
GRANT SELECT ON machine_stock_trend_v TO authenticated;
GRANT EXECUTE ON FUNCTION get_machine_stock_trend TO authenticated;
GRANT EXECUTE ON FUNCTION get_machine_stock_trend_aggregate TO authenticated;
GRANT EXECUTE ON FUNCTION create_live_stream_offer TO authenticated;
GRANT EXECUTE ON FUNCTION get_machine_snapshot_url TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_machine_stock_level TO authenticated;
GRANT EXECUTE ON FUNCTION complete_machine_pairing TO authenticated;
GRANT EXECUTE ON FUNCTION create_pending_machine_link_kiosk TO authenticated;
GRANT EXECUTE ON FUNCTION pair_machine_with_code_v2 TO authenticated;
