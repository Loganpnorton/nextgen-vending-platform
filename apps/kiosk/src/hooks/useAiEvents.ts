import { useEffect, useMemo, useState } from "react";
import { edgeFetch } from "@/lib/edgeApi";
import { edgeConfig } from "@/lib/edgeConfig";

export type AiEvent = {
  event: string;
  timestamp?: string;
  item?: string;
  confidence?: number;
  [key: string]: unknown;
};

type EventsResponse = AiEvent[] | { events: AiEvent[] } | AiEvent;

function normalize(resp: EventsResponse): AiEvent[] {
  if (Array.isArray(resp)) return resp;
  if (resp && typeof resp === "object" && "events" in resp && Array.isArray((resp as any).events)) {
    return (resp as any).events;
  }
  if (resp && typeof resp === "object" && "event" in resp) return [resp as AiEvent];
  return [];
}

export function useAiEvents(opts?: { pollMs?: number; max?: number }) {
  const pollMs = opts?.pollMs ?? 1000;
  const max = opts?.max ?? 20;

  const [events, setEvents] = useState<AiEvent[]>([]);
  const [online, setOnline] = useState<boolean | null>(null);

  useEffect(() => {
    let cancelled = false;

    const tick = async () => {
      try {
        const resp = await edgeFetch<EventsResponse>(edgeConfig.eventsPath, { auth: false });
        if (cancelled) return;
        setOnline(true);
        const incoming = normalize(resp);
        if (incoming.length === 0) return;
        setEvents((prev) => {
          const merged = [...incoming, ...prev];
          return merged.slice(0, max);
        });
      } catch {
        if (cancelled) return;
        setOnline(false);
      }
    };

    tick();
    const id = window.setInterval(tick, pollMs);
    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, [pollMs, max]);

  const latest = useMemo(() => events[0] || null, [events]);

  return { events, latest, online };
}



