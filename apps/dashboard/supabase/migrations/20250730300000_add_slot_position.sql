-- Add slot_position field to machine_products table
ALTER TABLE public.machine_products 
ADD COLUMN slot_position INTEGER;

-- Add comment to explain the field
COMMENT ON COLUMN public.machine_products.slot_position IS 'Optional slot position for the product in the machine (e.g., slot 1, 2, 3, etc.)'; 