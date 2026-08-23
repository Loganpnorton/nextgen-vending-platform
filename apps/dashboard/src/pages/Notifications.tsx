import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { edgeFetch } from "@/lib/edgeApi";

type EventRow = {
  type?: string;
  event?: string;
  item_name?: string;
  item?: string;
  quantity?: number;
  total_price?: number;
  confidence?: number;
  timestamp?: string;
  message?: string;
};

export default function Notifications() {
  const [events, setEvents] = useState<EventRow[]>([]);

  useEffect(() => {
    const run = async () => {
      try {
        const ev = await edgeFetch<EventRow[]>("/events", { method: "GET" });
        setEvents(ev || []);
      } catch {
        setEvents([]);
      }
    };
    run();
    const id = window.setInterval(run, 2000);
    return () => window.clearInterval(id);
  }, []);

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Card className="bg-card border-border shadow-card">
        <CardHeader className="pb-2">
          <CardTitle>Events</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {events.length === 0 ? (
            <div className="text-sm text-muted-foreground">No events.</div>
          ) : (
            events.map((e, idx) => (
              <div key={idx} className="rounded-md border p-3 bg-muted/10">
                <div className="font-medium">
                  {e.type || e.event || "Event"}
                  {e.item_name ? `: ${e.item_name}` : e.item ? `: ${e.item}` : ""}
                </div>
                <div className="text-xs text-muted-foreground">
                  {e.timestamp || ""}
                  {typeof e.confidence === "number"
                    ? `${e.timestamp ? " • " : ""}${(e.confidence * 100).toFixed(0)}%`
                    : ""}
                  {typeof e.total_price === "number"
                    ? `${e.timestamp || e.confidence !== undefined ? " • " : ""}$${e.total_price.toFixed(2)}`
                    : ""}
                </div>
                {e.message && <div className="text-sm mt-1">{e.message}</div>}
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}



