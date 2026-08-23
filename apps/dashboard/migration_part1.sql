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
  machine_token UUID DEFAULT gen_random_uuid() UNIQUE,
  is_paired BOOLEAN DEFAULT false,
  last_offline_timestamp TIMESTAMP WITH TIME ZONE,
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
  mime_type TEXT DEFAULT 'image/jpeg' CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
  machine_token UUID,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  pending_link_id UUID;
  new_machine_id UUID;
  new_machine_token UUID;
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
  machine_token UUID,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  found_machine_id UUID;
  found_machine_token UUID;
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
