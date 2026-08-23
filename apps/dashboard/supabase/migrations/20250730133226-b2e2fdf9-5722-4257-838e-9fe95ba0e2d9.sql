-- Create machines table
CREATE TABLE public.machines (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  machine_code TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'offline')),
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create products table
CREATE TABLE public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  product_code TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,
  base_price DECIMAL(10,2) NOT NULL,
  description TEXT,
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create product images table
CREATE TABLE public.product_images (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID NOT NULL,
  image_url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create machine products table (stock levels per machine)
CREATE TABLE public.machine_products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  machine_id UUID NOT NULL,
  product_id UUID NOT NULL,
  current_stock INTEGER NOT NULL DEFAULT 0,
  par_level INTEGER NOT NULL DEFAULT 50,
  price_override DECIMAL(10,2), -- Optional machine-specific pricing
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(machine_id, product_id)
);

-- Create stock transactions table (restock history)
CREATE TABLE public.stock_transactions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  machine_id UUID NOT NULL,
  product_id UUID NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('restock', 'sale', 'removal', 'adjustment')),
  quantity_change INTEGER NOT NULL, -- Positive for additions, negative for removals
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  performed_by UUID NOT NULL, -- user_id who performed the transaction
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add foreign key constraints
ALTER TABLE public.machines ADD CONSTRAINT machines_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.products ADD CONSTRAINT products_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.product_images ADD CONSTRAINT product_images_product_id_fkey 
  FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.machine_products ADD CONSTRAINT machine_products_machine_id_fkey 
  FOREIGN KEY (machine_id) REFERENCES public.machines(id) ON DELETE CASCADE;

ALTER TABLE public.machine_products ADD CONSTRAINT machine_products_product_id_fkey 
  FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.stock_transactions ADD CONSTRAINT stock_transactions_machine_id_fkey 
  FOREIGN KEY (machine_id) REFERENCES public.machines(id) ON DELETE CASCADE;

ALTER TABLE public.stock_transactions ADD CONSTRAINT stock_transactions_product_id_fkey 
  FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.stock_transactions ADD CONSTRAINT stock_transactions_performed_by_fkey 
  FOREIGN KEY (performed_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Enable Row Level Security
ALTER TABLE public.machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machine_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for machines
CREATE POLICY "Users can view their own machines" ON public.machines
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own machines" ON public.machines
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own machines" ON public.machines
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own machines" ON public.machines
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for products
CREATE POLICY "Users can view their own products" ON public.products
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own products" ON public.products
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own products" ON public.products
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products" ON public.products
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for product images
CREATE POLICY "Users can view product images for their products" ON public.product_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert product images for their products" ON public.product_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update product images for their products" ON public.product_images
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete product images for their products" ON public.product_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id AND p.user_id = auth.uid()
    )
  );

-- Create RLS policies for machine products
CREATE POLICY "Users can view machine products for their machines" ON public.machine_products
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
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

CREATE POLICY "Users can update machine products for their machines" ON public.machine_products
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete machine products for their machines" ON public.machine_products
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = machine_products.machine_id AND m.user_id = auth.uid()
    )
  );

-- Create RLS policies for stock transactions
CREATE POLICY "Users can view stock transactions for their machines" ON public.stock_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = stock_transactions.machine_id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert stock transactions for their machines" ON public.stock_transactions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.machines m 
      WHERE m.id = stock_transactions.machine_id AND m.user_id = auth.uid()
    ) AND
    auth.uid() = performed_by
  );

-- Create triggers for timestamp updates
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

-- Create storage bucket for product images
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true);

-- Create storage policies for product images
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

-- Insert sample data for testing
-- First, insert some sample machines
INSERT INTO public.machines (name, location, machine_code, user_id) VALUES
('Machine A1', 'Main Lobby', 'VM-A001', auth.uid()),
('Machine B4', 'Break Room Floor 2', 'VM-B004', auth.uid()),
('Machine C2', 'Cafeteria', 'VM-C002', auth.uid());

-- Insert sample products
INSERT INTO public.products (name, product_code, category, base_price, user_id) VALUES
('Coca-Cola Classic', 'P001', 'Beverages', 2.50, auth.uid()),
('Lay''s Original Chips', 'P002', 'Snacks', 1.75, auth.uid()),
('Snickers Bar', 'P003', 'Candy', 2.00, auth.uid()),
('Dasani Water', 'P004', 'Beverages', 1.50, auth.uid()),
('Oreo Cookies', 'P005', 'Snacks', 2.25, auth.uid());

-- Insert machine-product relationships with stock levels
INSERT INTO public.machine_products (machine_id, product_id, current_stock, par_level)
SELECT 
  m.id as machine_id,
  p.id as product_id,
  CASE 
    WHEN p.product_code = 'P001' THEN 45
    WHEN p.product_code = 'P002' THEN 72
    WHEN p.product_code = 'P003' THEN 15
    WHEN p.product_code = 'P004' THEN 85
    WHEN p.product_code = 'P005' THEN 28
  END as current_stock,
  CASE 
    WHEN p.product_code = 'P001' THEN 60
    WHEN p.product_code = 'P002' THEN 80
    WHEN p.product_code = 'P003' THEN 50
    WHEN p.product_code = 'P004' THEN 100
    WHEN p.product_code = 'P005' THEN 40
  END as par_level
FROM public.machines m
CROSS JOIN public.products p
WHERE m.user_id = auth.uid() AND p.user_id = auth.uid();