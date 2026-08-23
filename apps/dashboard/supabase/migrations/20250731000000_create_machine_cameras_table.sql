-- Create machine_cameras table for camera reporting and snapshot functionality
-- This table stores camera capabilities and status for each machine

CREATE TABLE IF NOT EXISTS public.machine_cameras (
    machine_id UUID PRIMARY KEY REFERENCES public.machines(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'unknown' CHECK (status IN ('unknown', 'No camera', 'Permission denied', 'Error', 'Healthy', 'Detected')),
    has_camera BOOLEAN DEFAULT false,
    permission TEXT CHECK (permission IN ('granted', 'denied', 'prompt', 'unknown')),
    device_label_hash TEXT, -- masked/hashed label from kiosk
    device_id_hash TEXT, -- sha256 hash of deviceId
    facing TEXT CHECK (facing IN ('environment', 'user', 'unknown')),
    resolution TEXT, -- e.g., '1280x720'
    fps INTEGER,
    last_error TEXT,
    snapshot_url TEXT,
    snapshot_at TIMESTAMPTZ,
    snapshot_requested_at TIMESTAMPTZ,
    last_seen TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_machine_cameras_status ON public.machine_cameras(status);
CREATE INDEX IF NOT EXISTS idx_machine_cameras_last_seen ON public.machine_cameras(last_seen);
CREATE INDEX IF NOT EXISTS idx_machine_cameras_snapshot_requested ON public.machine_cameras(snapshot_requested_at);

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_update_machine_cameras_updated_at ON public.machine_cameras;
DROP TRIGGER IF EXISTS trigger_update_camera_status ON public.machine_cameras;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_machine_cameras_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_machine_cameras_updated_at
    BEFORE UPDATE ON public.machine_cameras
    FOR EACH ROW
    EXECUTE FUNCTION update_machine_cameras_updated_at();

-- Create RLS policies
ALTER TABLE public.machine_cameras ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own machine cameras" ON public.machine_cameras;
DROP POLICY IF EXISTS "Users can update their own machine cameras" ON public.machine_cameras;
DROP POLICY IF EXISTS "Machine token can insert camera data" ON public.machine_cameras;
DROP POLICY IF EXISTS "Machine token can update camera data" ON public.machine_cameras;

-- Owners can select/update rows for machines they own
CREATE POLICY "Users can view their own machine cameras" ON public.machine_cameras
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id = machine_cameras.machine_id
            AND m.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own machine cameras" ON public.machine_cameras
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id = machine_cameras.machine_id
            AND m.user_id = auth.uid()
        )
    );

-- Allow machine token to insert/update (for kiosk check-ins)
CREATE POLICY "Machine token can insert camera data" ON public.machine_cameras
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Machine token can update camera data" ON public.machine_cameras
    FOR UPDATE USING (true);

-- Create storage bucket for machine snapshots
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'machine-snapshots',
    'machine-snapshots',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png']
) ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Users can view their own machine snapshots" ON storage.objects;

-- Create storage policies for machine-snapshots bucket
CREATE POLICY "Users can view their own machine snapshots" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'machine-snapshots' AND
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id::text = (storage.foldername(name))[1]
            AND m.user_id = auth.uid()
        )
    );

-- Function to generate signed URLs for machine snapshots
CREATE OR REPLACE FUNCTION get_machine_snapshot_url(machine_id_param UUID, file_path TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    signed_url TEXT;
BEGIN
    -- Check if user owns the machine
    IF NOT EXISTS (
        SELECT 1 FROM public.machines m
        WHERE m.id = machine_id_param
        AND m.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;
    
    -- Generate signed URL valid for 24 hours
    SELECT storage.sign_url(
        'machine-snapshots',
        file_path,
        interval '24 hours'
    ) INTO signed_url;
    
    RETURN signed_url;
END;
$$;

-- Function to update camera status based on fields
CREATE OR REPLACE FUNCTION update_camera_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update status based on camera fields
    IF NEW.has_camera = false THEN
        NEW.status = 'No camera';
    ELSIF NEW.permission = 'denied' THEN
        NEW.status = 'Permission denied';
    ELSIF NEW.last_error IS NOT NULL AND NEW.last_error != '' THEN
        NEW.status = 'Error';
    ELSIF NEW.snapshot_at IS NOT NULL AND NEW.snapshot_at > now() - interval '10 minutes' THEN
        NEW.status = 'Healthy';
    ELSE
        NEW.status = 'Detected';
    END IF;
    
    -- Update last_seen
    NEW.last_seen = now();
    
    RETURN NEW;
END;
$$;

-- Create trigger to automatically update status
CREATE TRIGGER trigger_update_camera_status
    BEFORE INSERT OR UPDATE ON public.machine_cameras
    FOR EACH ROW
    EXECUTE FUNCTION update_camera_status();
