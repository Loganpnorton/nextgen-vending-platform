import { useCallback, useEffect, useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useToast } from "@/hooks/use-toast";
import { edgeFetch } from "@/lib/edgeApi";
import { getEdgeBaseUrl } from "@/lib/edgeConfig";
import { cn } from "@/lib/utils";

type InventoryItem = {
  sku?: string;
  name: string;
  quantity: number;
  slot?: string | number | null;
};

type RawInventoryItem = {
  id?: string | number;
  name?: string;
  price?: number;
  stock?: number;
  quantity?: number;
  current_stock?: number;
  slot?: string | number | null;
  slot_position?: string | number | null;
  sku?: string;
};

type InventoryResponse =
  | { items: RawInventoryItem[] }
  | { inventory: RawInventoryItem[] }
  | RawInventoryItem[];

function normalizeInventory(resp: InventoryResponse): InventoryItem[] {
  const raw: RawInventoryItem[] = Array.isArray(resp)
    ? resp
    : "items" in resp && Array.isArray(resp.items)
      ? resp.items
      : "inventory" in resp && Array.isArray(resp.inventory)
        ? resp.inventory
        : [];

  return raw.map((r) => ({
    sku: r.sku ?? (typeof r.id === "string" ? r.id : undefined),
    name: r.name || "Item",
    quantity:
      typeof r.quantity === "number"
        ? r.quantity
        : typeof r.stock === "number"
          ? r.stock
          : typeof r.current_stock === "number"
            ? r.current_stock
            : 0,
    slot: r.slot ?? r.slot_position ?? null,
  }));
}

export default function Live() {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [edgeOnline, setEdgeOnline] = useState<boolean | null>(null);
  const [unlocking, setUnlocking] = useState(false);
  const [selectedCam, setSelectedCam] = useState<string>("0");
  const [camNonce, setCamNonce] = useState(() => Date.now());

  const baseUrl = useMemo(() => getEdgeBaseUrl(), []);
  const mjpegUrl = useMemo(() => {
    if (!baseUrl) return "";
    // Use explicit cam id path so we can switch between multiple cameras.
    return `${baseUrl}/video_feed/${selectedCam}?_=${camNonce}`;
  }, [baseUrl, selectedCam, camNonce]);

  const fetchInventory = useCallback(async () => {
    setLoading(true);
    try {
      const resp = await edgeFetch<InventoryResponse>("/inventory");
      setInventory(normalizeInventory(resp));
      setEdgeOnline(true);
    } catch (e: any) {
      setEdgeOnline(false);
      setInventory([]);
      toast({
        title: "Edge offline",
        description:
          e?.message ||
          "Could not reach the kiosk edge API. Check Cloudflare tunnel + power/network.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchInventory();
    const id = window.setInterval(fetchInventory, 5000);
    return () => window.clearInterval(id);
  }, [fetchInventory]);

  const unlock = useCallback(async () => {
    setUnlocking(true);
    try {
      await edgeFetch("/unlock", { method: "POST" });
      toast({
        title: "Unlock sent",
        description: "The kiosk received the unlock request.",
      });
    } catch (e: any) {
      toast({
        title: "Unlock failed",
        description: e?.message || "Edge API call failed.",
        variant: "destructive",
      });
    } finally {
      setUnlocking(false);
    }
  }, [toast]);

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Card className="bg-card border-border shadow-card">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center justify-between">
            <span>Live</span>
            <div className="flex items-center gap-2">
              <Badge
                variant={edgeOnline ? "default" : "secondary"}
                className={cn(!edgeOnline && edgeOnline !== null && "opacity-80")}
                title={baseUrl || "Set VITE_EDGE_BASE_URL"}
              >
                {edgeOnline === null ? "Unknown" : edgeOnline ? "Edge Online" : "Edge Offline"}
              </Badge>
              <Button onClick={unlock} disabled={!edgeOnline || unlocking} size="sm">
                {unlocking ? "Unlocking..." : "Unlock"}
              </Button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <Tabs
            value={selectedCam}
            onValueChange={(v) => {
              setSelectedCam(v);
              // bump nonce so the <img> reconnects immediately
              setCamNonce(Date.now());
            }}
          >
            <TabsList>
              <TabsTrigger value="0">Cam 1</TabsTrigger>
              <TabsTrigger value="4">Cam 2</TabsTrigger>
              <TabsTrigger value="8">Cam 3</TabsTrigger>
            </TabsList>
          </Tabs>

          <div className="rounded-lg border bg-muted/20 overflow-hidden">
            {baseUrl ? (
              <img
                key={`${selectedCam}-${camNonce}`}
                src={mjpegUrl}
                alt="MJPEG stream"
                className="w-full h-64 object-cover"
              />
            ) : (
              <div className="h-64 grid place-items-center text-sm text-muted-foreground">
                Set <code className="px-1">VITE_EDGE_BASE_URL</code> to your Cloudflare tunnel URL.
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <Card className="bg-card border-border shadow-card">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center justify-between">
            <span>Inventory</span>
            <Button variant="outline" size="sm" onClick={fetchInventory} disabled={loading}>
              Refresh
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-sm text-muted-foreground">Loading inventory…</div>
          ) : inventory.length === 0 ? (
            <div className="text-sm text-muted-foreground">No inventory returned.</div>
          ) : (
            <div className="space-y-2">
              {inventory.map((item, idx) => (
                <div
                  key={`${item.sku || item.name}-${idx}`}
                  className="flex items-center justify-between rounded-md border p-3 bg-muted/10"
                >
                  <div className="min-w-0">
                    <div className="font-medium truncate">{item.name}</div>
                    <div className="text-xs text-muted-foreground">
                      {item.sku ? `SKU: ${item.sku}` : null}
                      {item.slot !== undefined && item.slot !== null
                        ? `${item.sku ? " • " : ""}Slot: ${item.slot}`
                        : null}
                    </div>
                  </div>
                  <Badge variant={item.quantity > 0 ? "default" : "destructive"}>
                    {item.quantity}
                  </Badge>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}


