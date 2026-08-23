import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import { edgeFetch } from "@/lib/edgeApi";

type Health = { status?: string; cameras?: string };

export default function Machines() {
  const navigate = useNavigate();
  const [health, setHealth] = useState<Health | null>(null);

  useEffect(() => {
    const run = async () => {
      try {
        const h = await edgeFetch<Health>("/health", { method: "GET" });
        setHealth(h);
      } catch {
        setHealth(null);
      }
    };
    run();
    const id = window.setInterval(run, 5000);
    return () => window.clearInterval(id);
  }, []);

  const online = health?.status === "online";

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Card
        className="bg-card border-border shadow-card cursor-pointer hover:shadow-elevated transition-all"
        onClick={() => navigate("/machines/edge")}
      >
        <CardContent className="p-4 flex items-center justify-between">
          <div className="space-y-1">
            <div className="font-semibold">Edge Kiosk</div>
            <div className="text-xs text-muted-foreground">
              Cameras: {health?.cameras || "unknown"}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant={online ? "default" : "secondary"}>
              {online ? "online" : "offline"}
            </Badge>
            <Button size="sm" variant="outline" onClick={(e) => { e.stopPropagation(); navigate("/live"); }}>
              Live
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}



