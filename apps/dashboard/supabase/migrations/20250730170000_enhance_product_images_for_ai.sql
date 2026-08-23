-- Enhance product_images table for AI training and image management
-- Add metadata fields for AI training
ALTER TABLE public.product_images 
ADD COLUMN file_name TEXT,
ADD COLUMN file_size INTEGER,
ADD COLUMN width INTEGER,
ADD COLUMN height INTEGER,
ADD COLUMN mime_type TEXT,
ADD COLUMN uploader_id UUID REFERENCES auth.users(id),
ADD COLUMN file_hash TEXT, -- For duplicate detection
ADD COLUMN metadata JSONB DEFAULT '{}'; -- For additional metadata

-- Add indexes for performance
CREATE INDEX idx_product_images_product_id ON public.product_images(product_id);
CREATE INDEX idx_product_images_is_primary ON public.product_images(is_primary);
CREATE INDEX idx_product_images_file_hash ON public.product_images(file_hash);
CREATE INDEX idx_product_images_uploader_id ON public.product_images(uploader_id);

-- Add constraint to ensure only one primary image per product
CREATE UNIQUE INDEX idx_product_primary_image 
ON public.product_images(product_id) 
WHERE is_primary = true;

-- Add constraint for file size limit (5MB = 5 * 1024 * 1024 bytes)
ALTER TABLE public.product_images 
ADD CONSTRAINT check_file_size 
CHECK (file_size <= 5242880);

-- Add constraint for minimum dimensions
ALTER TABLE public.product_images 
ADD CONSTRAINT check_minimum_dimensions 
CHECK (width >= 500 AND height >= 500);

-- Add constraint for allowed file types
ALTER TABLE public.product_images 
ADD CONSTRAINT check_mime_type 
CHECK (mime_type IN ('image/jpeg', 'image/png'));

-- Update RLS policies to include uploader_id
DROP POLICY IF EXISTS "Users can insert product images for their products" ON public.product_images;
CREATE POLICY "Users can insert product images for their products" ON public.product_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    ) AND
    uploader_id = auth.uid()
  );

-- Add policy for users to view images they uploaded
CREATE POLICY "Users can view images they uploaded" ON public.product_images
  FOR SELECT USING (uploader_id = auth.uid());

-- Add policy for users to update images they uploaded
CREATE POLICY "Users can update images they uploaded" ON public.product_images
  FOR UPDATE USING (uploader_id = auth.uid());

-- Add policy for users to delete images they uploaded
CREATE POLICY "Users can delete images they uploaded" ON public.product_images
  FOR DELETE USING (uploader_id = auth.uid()); 