-- Allow WebP uploads by extending CHECK constraint on product_images.mime_type
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.constraint_column_usage ccu
    JOIN information_schema.table_constraints tc
      ON tc.constraint_name = ccu.constraint_name
     AND tc.table_schema = ccu.table_schema
    WHERE tc.table_name = 'product_images'
      AND tc.constraint_type = 'CHECK'
      AND tc.constraint_name = 'check_mime_type'
  ) THEN
    -- Drop and recreate with webp
    ALTER TABLE product_images DROP CONSTRAINT IF EXISTS check_mime_type;
  END IF;
END $$;

ALTER TABLE product_images
  ADD CONSTRAINT check_mime_type
  CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp'));









