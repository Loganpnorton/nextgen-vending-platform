import { useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { edgeFetch } from "@/lib/edgeApi";
import { useNavigate } from "react-router-dom";

type Health = { status?: string; cameras?: string };
type InventoryRow = { id?: number | string; name?: string; price?: number; stock?: number };
type EventRow = { type?: string; event?: string; item_name?: string; timestamp?: string };

export default function Dashboard() {
  const navigate = useNavigate();
  const [health, setHealth] = useState<Health | null>(null);
  const [inventory, setInventory] = useState<InventoryRow[]>([]);
  const [events, setEvents] = useState<EventRow[]>([]);

  useEffect(() => {
    const run = async () => {
      try {
        const h = await edgeFetch<Health>("/health", { method: "GET" });
        setHealth(h);
      } catch {
        setHealth(null);
      }
      try {
        const inv = await edgeFetch<InventoryRow[]>("/inventory", { method: "GET" });
        setInventory(inv || []);
      } catch {
        setInventory([]);
      }
      try {
        const ev = await edgeFetch<EventRow[]>("/events", { method: "GET" });
        setEvents(ev || []);
      } catch {
        setEvents([]);
      }
    };

    run();
    const id = window.setInterval(run, 5000);
    return () => window.clearInterval(id);
  }, []);

  const lowStockCount = useMemo(
    () => inventory.filter((i) => typeof i.stock === "number" && i.stock <= 2).length,
    [inventory]
  );

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <div className="grid grid-cols-2 gap-4">
        <Card className="bg-card border-border shadow-card">
          <CardContent className="p-4 space-y-1">
            <div className="text-xs text-muted-foreground">Edge Status</div>
            <div className="flex items-center gap-2">
              <div className="text-lg font-semibold">
                {health?.status || "offline"}
              </div>
              <Badge variant={health?.status === "online" ? "default" : "secondary"}>
                {health?.cameras || "unknown"}
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-card border-border shadow-card">
          <CardContent className="p-4 space-y-1">
            <div className="text-xs text-muted-foreground">Low Stock Items</div>
            <div className="text-lg font-semibold">{lowStockCount}</div>
          </CardContent>
        </Card>
      </div>

      <Card className="bg-card border-border shadow-card">
        <CardHeader className="pb-2">
          <CardTitle className="flex items-center justify-between">
            <span>Quick Actions</span>
            <div className="flex gap-2">
              <Button size="sm" variant="outline" onClick={() => navigate("/machines")}>
                Machines
              </Button>
              <Button size="sm" onClick={() => navigate("/live")}>
                Live
              </Button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-muted-foreground">
          Latest events: {events.length}
        </CardContent>
      </Card>
    </div>
  );
}



