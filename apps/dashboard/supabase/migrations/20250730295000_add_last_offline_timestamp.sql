-- Add last_offline timestamp column to machines table
-- This column will be used to track when machines last went offline

-- Add last_offline column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'machines' 
    AND column_name = 'last_offline'
  ) THEN
    ALTER TABLE machines ADD COLUMN last_offline TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Add index for better performance on last_offline queries
CREATE INDEX IF NOT EXISTS idx_machines_last_offline ON machines(last_offline);

-- Create a function to update last_offline when connection_status changes to offline
CREATE OR REPLACE FUNCTION update_last_offline_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- If connection_status is changing to 'offline', set last_offline timestamp
  IF NEW.connection_status = 'offline' AND 
     (OLD.connection_status IS NULL OR OLD.connection_status != 'offline') THEN
    NEW.last_offline = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update last_offline timestamp
CREATE TRIGGER update_last_offline_timestamp_trigger
  BEFORE UPDATE ON machines
  FOR EACH ROW
  EXECUTE FUNCTION update_last_offline_timestamp();

-- Add comment to document the column
COMMENT ON COLUMN machines.last_offline IS 'Timestamp when the machine last went offline'; 