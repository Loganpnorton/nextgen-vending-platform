-- Create live streaming tables for WebRTC peer-to-peer video streaming
-- This enables real-time camera preview from kiosk to admin dashboard

-- Live stream offers (from dashboard to kiosk)
CREATE TABLE IF NOT EXISTS public.live_stream_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
    offer JSONB NOT NULL, -- RTCSessionDescriptionInit
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT now() + interval '5 minutes',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired'))
);

-- Live stream answers (from kiosk to dashboard)
CREATE TABLE IF NOT EXISTS public.live_stream_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES public.live_stream_offers(id) ON DELETE CASCADE,
    answer JSONB NOT NULL, -- RTCSessionDescriptionInit
    machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ICE candidates for WebRTC connection establishment
CREATE TABLE IF NOT EXISTS public.live_stream_ice_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES public.live_stream_offers(id) ON DELETE CASCADE,
    candidate JSONB NOT NULL, -- RTCIceCandidateInit
    machine_id UUID NOT NULL REFERENCES public.machines(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_machine_id ON public.live_stream_offers(machine_id);
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_status ON public.live_stream_offers(status);
CREATE INDEX IF NOT EXISTS idx_live_stream_offers_expires_at ON public.live_stream_offers(expires_at);
CREATE INDEX IF NOT EXISTS idx_live_stream_answers_offer_id ON public.live_stream_answers(offer_id);
CREATE INDEX IF NOT EXISTS idx_live_stream_ice_candidates_offer_id ON public.live_stream_ice_candidates(offer_id);

-- Enable RLS
ALTER TABLE public.live_stream_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_stream_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_stream_ice_candidates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own live stream offers" ON public.live_stream_offers;
DROP POLICY IF EXISTS "Machine token can view live stream offers" ON public.live_stream_offers;
DROP POLICY IF EXISTS "Users can view their own live stream answers" ON public.live_stream_answers;
DROP POLICY IF EXISTS "Machine token can insert live stream answers" ON public.live_stream_answers;
DROP POLICY IF EXISTS "Users can view their own live stream ICE candidates" ON public.live_stream_ice_candidates;
DROP POLICY IF EXISTS "Machine token can manage live stream ICE candidates" ON public.live_stream_ice_candidates;

-- RLS Policies for live_stream_offers
CREATE POLICY "Users can manage their own live stream offers" ON public.live_stream_offers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id = live_stream_offers.machine_id
            AND m.user_id = auth.uid()
        )
    );

CREATE POLICY "Machine token can view live stream offers" ON public.live_stream_offers
    FOR SELECT USING (
        machine_id IN (
            SELECT id FROM public.machines 
            WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::uuid
        )
    );

-- RLS Policies for live_stream_answers
CREATE POLICY "Users can view their own live stream answers" ON public.live_stream_answers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id = live_stream_answers.machine_id
            AND m.user_id = auth.uid()
        )
    );

CREATE POLICY "Machine token can insert live stream answers" ON public.live_stream_answers
    FOR INSERT WITH CHECK (
        machine_id IN (
            SELECT id FROM public.machines 
            WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::uuid
        )
    );

-- RLS Policies for live_stream_ice_candidates
CREATE POLICY "Users can view their own live stream ICE candidates" ON public.live_stream_ice_candidates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.machines m
            WHERE m.id = live_stream_ice_candidates.machine_id
            AND m.user_id = auth.uid()
        )
    );

CREATE POLICY "Machine token can manage live stream ICE candidates" ON public.live_stream_ice_candidates
    FOR ALL USING (
        machine_id IN (
            SELECT id FROM public.machines 
            WHERE machine_token = (current_setting('request.jwt.claims', true)::json ->> 'machine_token')::uuid
        )
    );

-- Function to clean up expired offers
CREATE OR REPLACE FUNCTION cleanup_expired_live_stream_offers()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.live_stream_offers 
    SET status = 'expired' 
    WHERE expires_at < now() AND status = 'pending';
END;
$$;

-- Function to create a live stream offer
CREATE OR REPLACE FUNCTION create_live_stream_offer(
    machine_id_param UUID,
    offer_param JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    offer_id UUID;
BEGIN
    -- Check if user owns the machine
    IF NOT EXISTS (
        SELECT 1 FROM public.machines m
        WHERE m.id = machine_id_param
        AND m.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;
    
    -- Create the offer
    INSERT INTO public.live_stream_offers (machine_id, offer)
    VALUES (machine_id_param, offer_param)
    RETURNING id INTO offer_id;
    
    RETURN offer_id;
END;
$$;

-- Create a scheduled job to clean up expired offers (runs every 5 minutes)
-- Note: This requires pg_cron extension to be enabled
-- SELECT cron.schedule('cleanup-expired-offers', '*/5 * * * *', 'SELECT cleanup_expired_live_stream_offers();');
