-- Complete database cleanup script
-- This script removes all existing tables, functions, views, and storage buckets
-- Run this BEFORE applying the new migration to ensure a clean slate

-- =====================================================
-- DROP STORAGE BUCKETS
-- =====================================================

-- Drop storage bucket policies first
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Product images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own machine snapshots" ON storage.objects;

-- Delete storage bucket records from the buckets table
DELETE FROM storage.buckets WHERE id = 'avatars';
DELETE FROM storage.buckets WHERE id = 'product-images';
DELETE FROM storage.buckets WHERE id = 'machine-snapshots';

-- =====================================================
-- DROP VIEWS
-- =====================================================

DROP VIEW IF EXISTS machine_stock_trend_v;

-- =====================================================
-- DROP TRIGGERS (before functions to avoid dependency issues)
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_preferences_updated_at ON public.user_preferences;
DROP TRIGGER IF EXISTS update_machines_updated_at ON public.machines;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS update_machine_products_updated_at ON public.machine_products;
DROP TRIGGER IF EXISTS update_user_2fa_updated_at ON public.user_2fa;
DROP TRIGGER IF EXISTS update_pending_machine_links_updated_at ON public.pending_machine_links;
DROP TRIGGER IF EXISTS trigger_update_camera_status ON public.machine_cameras;
DROP TRIGGER IF EXISTS trigger_update_machine_cameras_updated_at ON public.machine_cameras;

-- =====================================================
-- DROP FUNCTIONS (in reverse order of creation)
-- =====================================================

DROP FUNCTION IF EXISTS pair_machine_with_code_v2(uuid, text, text, text);
DROP FUNCTION IF EXISTS create_pending_machine_link_kiosk();
DROP FUNCTION IF EXISTS complete_machine_pairing(text, text, text);
DROP FUNCTION IF EXISTS calculate_machine_stock_level(uuid);
DROP FUNCTION IF EXISTS get_machine_id_by_pairing_code(text);
DROP FUNCTION IF EXISTS cleanup_expired_pending_links();
DROP FUNCTION IF EXISTS pair_machine_with_code(text, text, text, text);
DROP FUNCTION IF EXISTS create_pending_machine_link();
DROP FUNCTION IF EXISTS generate_pairing_code();
DROP FUNCTION IF EXISTS update_camera_status();
DROP FUNCTION IF EXISTS update_machine_cameras_updated_at();
DROP FUNCTION IF EXISTS get_machine_snapshot_url(uuid, text);
DROP FUNCTION IF EXISTS create_live_stream_offer(uuid, jsonb);
DROP FUNCTION IF EXISTS cleanup_expired_live_stream_offers();
DROP FUNCTION IF EXISTS mark_offline_machines();
DROP FUNCTION IF EXISTS machine_checkin(uuid, jsonb);
DROP FUNCTION IF EXISTS get_machine_stock_trend_aggregate(uuid, text, timestamptz, timestamptz, text);
DROP FUNCTION IF EXISTS get_machine_stock_trend(uuid, uuid, text, timestamptz, timestamptz, text);
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- DROP TABLES (in reverse dependency order)
-- =====================================================

-- Drop tables with foreign key dependencies first
DROP TABLE IF EXISTS stock_transactions;
DROP TABLE IF EXISTS machine_products;
DROP TABLE IF EXISTS product_images;
DROP TABLE IF EXISTS live_stream_ice_candidates;
DROP TABLE IF EXISTS live_stream_answers;
DROP TABLE IF EXISTS live_stream_offers;
DROP TABLE IF EXISTS stream_frames;
DROP TABLE IF EXISTS machine_cameras;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS pending_machine_links;
DROP TABLE IF EXISTS machines;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS user_2fa;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS profiles;

-- =====================================================
-- DROP EXTENSIONS (optional - only if you want to remove them)
-- =====================================================

-- Note: Uncomment these if you want to remove the extensions as well
-- DROP EXTENSION IF EXISTS "uuid-ossp";
-- DROP EXTENSION IF EXISTS "pg_cron";

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================

-- Run this query after cleanup to verify everything is removed
-- SELECT
--   schemaname,
--   tablename,
--   tableowner
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;
