-- Add product drafts table for saving incomplete product creations
CREATE TABLE IF NOT EXISTS public.product_drafts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  product_code TEXT,
  category TEXT,
  base_price DECIMAL(10,2),
  description TEXT,
  form_data JSONB NOT NULL DEFAULT '{}',
  selected_machines UUID[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.product_drafts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own product drafts" ON public.product_drafts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own product drafts" ON public.product_drafts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own product drafts" ON public.product_drafts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own product drafts" ON public.product_drafts
  FOR DELETE USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_product_drafts_user_id ON public.product_drafts(user_id);
CREATE INDEX IF NOT EXISTS idx_product_drafts_created_at ON public.product_drafts(created_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_product_drafts_updated_at_trigger
  BEFORE UPDATE ON public.product_drafts
  FOR EACH ROW EXECUTE FUNCTION update_product_drafts_updated_at();

