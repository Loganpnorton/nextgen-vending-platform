-- Fix storage policies for the new folder structure (user_id/product_id/filename)
-- Drop existing storage policies
DROP POLICY IF EXISTS "Users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their product images" ON storage.objects;

-- Create new storage policies that work with user_id/product_id/filename structure
CREATE POLICY "Users can upload product images" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'product-images' AND 
  auth.uid()::text = (storage.foldername(name))[1] AND
  (storage.foldername(name))[2] IS NOT NULL
);

CREATE POLICY "Users can update their product images" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'product-images' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their product images" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'product-images' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Also update the product_images RLS policies to be more permissive for viewing
-- Users should be able to view images for products they own, regardless of who uploaded them
DROP POLICY IF EXISTS "Users can view product images for their products" ON public.product_images;
CREATE POLICY "Users can view product images for their products" ON public.product_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

-- Users should be able to update/delete images for their products, regardless of who uploaded them
DROP POLICY IF EXISTS "Users can update images they uploaded" ON public.product_images;
CREATE POLICY "Users can update images for their products" ON public.product_images
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete images they uploaded" ON public.product_images;
CREATE POLICY "Users can delete images for their products" ON public.product_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  ); 