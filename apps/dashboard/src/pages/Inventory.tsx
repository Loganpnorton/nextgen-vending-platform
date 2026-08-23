import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { edgeFetch } from "@/lib/edgeApi";

type InventoryRow = { id?: number | string; name?: string; price?: number; stock?: number };

export default function Inventory() {
  const [rows, setRows] = useState<InventoryRow[]>([]);
  const [online, setOnline] = useState<boolean | null>(null);

  useEffect(() => {
    const run = async () => {
      try {
        const inv = await edgeFetch<InventoryRow[]>("/inventory", { method: "GET" });
        setRows(inv || []);
        setOnline(true);
      } catch {
        setRows([]);
        setOnline(false);
      }
    };
    run();
    const id = window.setInterval(run, 5000);
    return () => window.clearInterval(id);
  }, []);

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Card className="bg-card border-border shadow-card">
        <CardHeader className="pb-2">
          <CardTitle className="flex items-center justify-between">
            <span>Inventory</span>
            <Badge variant={online ? "default" : "secondary"}>
              {online === null ? "unknown" : online ? "edge online" : "edge offline"}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {rows.length === 0 ? (
            <div className="text-sm text-muted-foreground">No items.</div>
          ) : (
            rows.map((r, idx) => (
              <div
                key={`${r.id ?? idx}`}
                className="flex items-center justify-between rounded-md border p-3 bg-muted/10"
              >
                <div className="min-w-0">
                  <div className="font-medium truncate">{r.name || "Item"}</div>
                  <div className="text-xs text-muted-foreground">
                    {typeof r.price === "number" ? `$${r.price.toFixed(2)}` : ""}
                  </div>
                </div>
                <Badge variant={typeof r.stock === "number" && r.stock > 0 ? "default" : "destructive"}>
                  {typeof r.stock === "number" ? r.stock : 0}
                </Badge>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}



