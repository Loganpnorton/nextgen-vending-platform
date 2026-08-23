-- Enhance machines table with additional fields for monitoring
ALTER TABLE public.machines 
ADD COLUMN IF NOT EXISTS battery_level INTEGER DEFAULT 100 CHECK (battery_level >= 0 AND battery_level <= 100),
ADD COLUMN IF NOT EXISTS last_ping TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS alerts_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_stock_level INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS connection_status TEXT DEFAULT 'online' CHECK (connection_status IN ('online', 'warning', 'offline'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_machines_user_id ON public.machines(user_id);
CREATE INDEX IF NOT EXISTS idx_machines_status ON public.machines(status);
CREATE INDEX IF NOT EXISTS idx_machines_connection_status ON public.machines(connection_status);
CREATE INDEX IF NOT EXISTS idx_machines_last_ping ON public.machines(last_ping);

-- Create a function to update machine status based on last ping
CREATE OR REPLACE FUNCTION update_machine_connection_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Update connection status based on last ping
  IF NEW.last_ping IS NULL OR NEW.last_ping < (NOW() - INTERVAL '5 minutes') THEN
    NEW.connection_status = 'offline';
    NEW.is_online = false;
  ELSIF NEW.last_ping < (NOW() - INTERVAL '2 minutes') THEN
    NEW.connection_status = 'warning';
    NEW.is_online = true;
  ELSE
    NEW.connection_status = 'online';
    NEW.is_online = true;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update connection status
CREATE TRIGGER update_machine_connection_status_trigger
  BEFORE UPDATE ON public.machines
  FOR EACH ROW
  EXECUTE FUNCTION update_machine_connection_status();

-- Create a function to calculate total stock level for a machine
CREATE OR REPLACE FUNCTION calculate_machine_stock_level(machine_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_stock INTEGER;
  total_capacity INTEGER;
  stock_percentage INTEGER;
BEGIN
  -- Calculate total stock and capacity
  SELECT 
    COALESCE(SUM(current_stock), 0),
    COALESCE(SUM(par_level), 0)
  INTO total_stock, total_capacity
  FROM public.machine_products 
  WHERE machine_id = machine_uuid;
  
  -- Calculate percentage
  IF total_capacity > 0 THEN
    stock_percentage = (total_stock * 100) / total_capacity;
  ELSE
    stock_percentage = 0;
  END IF;
  
  RETURN stock_percentage;
END;
$$ LANGUAGE plpgsql;

-- Create a function to update machine stock level
CREATE OR REPLACE FUNCTION update_machine_stock_level()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the machine's total stock level
  UPDATE public.machines 
  SET total_stock_level = calculate_machine_stock_level(NEW.machine_id)
  WHERE id = NEW.machine_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update machine stock level when machine_products change
CREATE TRIGGER update_machine_stock_level_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.machine_products
  FOR EACH ROW
  EXECUTE FUNCTION update_machine_stock_level(); 