-- Add max_stock_recorded field to machine_products table
ALTER TABLE public.machine_products 
ADD COLUMN max_stock_recorded INTEGER DEFAULT 0;

-- Update existing records to set max_stock_recorded to current_stock if it's greater than 0
UPDATE public.machine_products 
SET max_stock_recorded = current_stock 
WHERE current_stock > 0 AND max_stock_recorded = 0; 