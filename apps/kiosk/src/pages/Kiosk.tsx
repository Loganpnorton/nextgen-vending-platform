import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { StatusDot } from "@/components/common/StatusDot";
import { ProductCard } from "@/components/kiosk/ProductCard";
import { CartSidebar } from "@/components/kiosk/CartSidebar";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { useMachineIdentity } from "@/hooks/useMachineIdentity";
import { useMachineProducts } from "@/hooks/useMachineProducts";
import { useMachineCheckin } from "@/hooks/useMachineCheckin";
import { useCart } from "@/hooks/useCart";
import { useSales } from "@/hooks/useSales";
import type { MachineProduct } from "@/types/api";
import { getFallbackImage } from "@/lib/utils";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { supabase } from "@/lib/supabase";
import { clearAll } from "@/lib/storage";
import { edgeUrl } from "@/lib/edgeConfig";
import { useAiEvents } from "@/hooks/useAiEvents";
import { edgeFetch } from "@/lib/edgeApi";
import { edgeConfig } from "@/lib/edgeConfig";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";

const Kiosk = () => {
  const navigate = useNavigate();
  const identity = useMachineIdentity();
  
  // Debug logging
  console.log('Kiosk identity:', identity);
  
  const { products, loading, error, refresh } = useMachineProducts(
    identity.machineId,
    identity.machineCode,
    identity.machineToken
  );
  const { online, lastSyncText, batteryPct, performCheckin } = useMachineCheckin(
    identity.machineId,
    identity.machineCode,
    identity.machineToken,
    products
  );

  const { events: aiEvents, latest: latestAiEvent, online: aiOnline } = useAiEvents({
    pollMs: 1000,
    max: 20,
  });
  const { items, total, totalItems, add, clear } = useCart();
  const { processSale, processing, error: saleError, clearError } = useSales();
  const [debugPanelOpen, setDebugPanelOpen] = useState(false);
  const longPressRef = useRef<NodeJS.Timeout | null>(null);
  const longPressStartRef = useRef<number>(0);
  
  const [showDispensing, setShowDispensing] = useState(false);
  const [saleResult, setSaleResult] = useState<any>(null);
  const [unlockAfterSaleError, setUnlockAfterSaleError] = useState<string | null>(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [password, setPassword] = useState("");
  const [verifying, setVerifying] = useState(false);
  const [verifyError, setVerifyError] = useState<string | null>(null);
  const [settingsUnlocked, setSettingsUnlocked] = useState(false);
  const [selectedCam, setSelectedCam] = useState<string>("0");
  const [camNonce, setCamNonce] = useState(() => Date.now());
  const mjpegUrl = `${edgeUrl(`/video_feed/${selectedCam}`)}?_=${camNonce}`;

  useEffect(() => {
    document.title = "Kiosk Mode - Vending Kiosk";
    const meta = document.querySelector('meta[name="description"]');
    if (meta) meta.setAttribute("content", "Browse products and preview cart in the vending kiosk UI demo.");
  }, []);

  // Handle debug panel triggers
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && e.key === 'D') {
        e.preventDefault();
        setDebugPanelOpen(true);
      }
    };

    const handleMouseDown = (e: MouseEvent) => {
      // Check if clicking on the app logo/header area
      const target = e.target as HTMLElement;
      if (target.closest('h1') || target.closest('[data-logo]')) {
        longPressStartRef.current = Date.now();
        longPressRef.current = setTimeout(() => {
          setDebugPanelOpen(true);
        }, 5000); // 5 second long press
      }
    };

    const handleMouseUp = () => {
      if (longPressRef.current) {
        clearTimeout(longPressRef.current);
        longPressRef.current = null;
      }
    };

    const handleTouchStart = (e: TouchEvent) => {
      // Check if touching the app logo/header area
      const target = e.target as HTMLElement;
      if (target.closest('h1') || target.closest('[data-logo]')) {
        longPressStartRef.current = Date.now();
        longPressRef.current = setTimeout(() => {
          setDebugPanelOpen(true);
        }, 5000); // 5 second long press
      }
    };

    const handleTouchEnd = () => {
      if (longPressRef.current) {
        clearTimeout(longPressRef.current);
        longPressRef.current = null;
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    document.addEventListener('mousedown', handleMouseDown);
    document.addEventListener('mouseup', handleMouseUp);
    document.addEventListener('touchstart', handleTouchStart);
    document.addEventListener('touchend', handleTouchEnd);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('mousedown', handleMouseDown);
      document.removeEventListener('mouseup', handleMouseUp);
      document.removeEventListener('touchstart', handleTouchStart);
      document.removeEventListener('touchend', handleTouchEnd);
    };
  }, []);

  const handleBuy = (product: any) => {
    if (!online) {
      console.error('Cannot add items while offline');
      return;
    }

    if (!product.inStock) {
      console.error('Product is out of stock');
      return;
    }

    // Check if we're trying to add more than available stock
    const existingItem = items.find(item => item.id === product.id);
    const currentQty = existingItem?.qty || 0;
    
    // Find the actual stock level from the products array
    const actualProduct = products.find(p => p.id === product.id);
    const availableStock = actualProduct?.stock_level || 0;
    
    if (currentQty >= availableStock) {
      console.error(`Cannot add more items. Available stock: ${availableStock}`);
      return;
    }

    // Convert UI product back to MachineProduct format for cart
    const machineProduct: MachineProduct = {
      id: product.id,
      product_id: product.id, // Use same ID for now
      name: product.name,
      price: product.price,
      image_url: product.image,
      slot_position: product.slot,
      stock_level: availableStock,
    };
    add(machineProduct);
  };

  const handleCheckout = async () => {
    console.log('=== CHECKOUT ATTEMPT ===');
    console.log('Online status:', online);
    console.log('Items in cart:', items);
    console.log('Machine token:', identity.machineToken);
    
    if (!online) {
      console.error('Cannot process sale while offline');
      return;
    }

    if (items.length === 0) {
      console.error('No items in cart');
      return;
    }

    try {
      console.log('Calling processSale with items:', items);
      const result = await processSale(items, identity.machineToken);
      console.log('Process sale result:', result);
      
      if (result.success) {
        // Manual flow: /sale (accounting) -> /unlock (door)
        setUnlockAfterSaleError(null);
        try {
          await edgeFetch(edgeConfig.unlockPath, { method: "POST", auth: false });
        } catch (e) {
          console.error("Unlock failed after sale:", e);
          setUnlockAfterSaleError(e instanceof Error ? e.message : "Unlock failed after sale");
        }
        setSaleResult(result.data);
        clear();
        setShowDispensing(true);
        setTimeout(() => {
          setShowDispensing(false);
          setSaleResult(null);
          setUnlockAfterSaleError(null);
        }, 3000);
        
        // Refresh products to show updated stock levels
        refresh();
      } else {
        console.error('Sale failed:', result.message);
        // Show error but don't clear cart - let user retry
      }
    } catch (error) {
      console.error('Error processing sale:', error);
    }
  };

  const handleManualSync = () => {
    performCheckin();
    refresh(); // Refresh products immediately
  };

  const handleOpenSettings = () => {
    setPassword("");
    setVerifyError(null);
    setSettingsUnlocked(false);
    setSettingsOpen(true);
  };

  const handleVerifyPassword = async () => {
    setVerifying(true);
    setVerifyError(null);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      const email = user?.email;
      if (!email) {
        setVerifyError("Not signed in.");
        return;
      }
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        setVerifyError("Incorrect password.");
        return;
      }
      setSettingsUnlocked(true);
    } catch (e) {
      setVerifyError("Verification failed.");
    } finally {
      setVerifying(false);
    }
  };

  const handleResetMachine = () => {
    clearAll();
    setSettingsOpen(false);
    navigate('/kiosk');
  };

  // Convert API products to UI format
  const uiProducts = products.map((p): any => {
    const fallbackImage = getFallbackImage(p.category, p.name);
    const finalImage = p.image_url || fallbackImage;
    
    return {
      id: p.id,
      name: p.name,
      price: p.price,
      image: finalImage, // Uses finalImage
      inStock: p.stock_level > 0,
      slot: p.slot_position || `Slot ${p.id}`,
    };
  });

  return (
    <div className="container mx-auto px-4 py-6 min-h-screen bg-background">
      <header className="mb-6 rounded-lg border bg-card p-5 shadow-[var(--shadow-elegant)]">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-2xl font-semibold" data-logo>
              Edge Kiosk: {identity.machineCode || identity.machineId || "Vending Machine"}
            </h1>
            <p className="text-sm text-muted-foreground">
              Code: {identity.machineCode || identity.machineId || "-"} • Items in cart: {totalItems}
            </p>
          </div>
          <div className="flex items-center gap-6 text-sm">
            <StatusDot status={online ? "online" : "offline"} label={online ? "Online" : "Offline"} />
            <Separator orientation="vertical" className="hidden h-6 md:block" />
            <span className="text-muted-foreground">Last sync: {lastSyncText}</span>
            <Button 
              onClick={handleManualSync}
              variant="outline"
              size="sm"
              className="text-xs"
            >
              Manual Sync
            </Button>
            <Button
              onClick={handleOpenSettings}
              variant="outline"
              size="sm"
              className="text-xs"
            >
              Settings
            </Button>
          </div>
        </div>
      </header>

      <main className="grid grid-cols-1 gap-6 lg:grid-cols-12">
        <section className="lg:col-span-8 xl:col-span-9 space-y-6">
          {/* Local MJPEG stream */}
          <div className="rounded-lg border bg-card overflow-hidden">
            <div className="flex items-center justify-between px-4 py-3 border-b">
              <div className="font-medium">Camera Stream</div>
              <StatusDot
                status={aiOnline === false ? "offline" : "online"}
                label={aiOnline === false ? "Edge API Down" : "Edge API OK"}
              />
            </div>
            <div className="px-4 py-3 border-b">
              <Tabs
                value={selectedCam}
                onValueChange={(v) => {
                  setSelectedCam(v);
                  setCamNonce(Date.now());
                }}
              >
                <TabsList>
                  <TabsTrigger value="0">Cam 1</TabsTrigger>
                  <TabsTrigger value="4">Cam 2</TabsTrigger>
                  <TabsTrigger value="8">Cam 3</TabsTrigger>
                </TabsList>
              </Tabs>
            </div>
            <div className="aspect-video bg-black">
              <img
                key={`${selectedCam}-${camNonce}`}
                src={mjpegUrl}
                alt="MJPEG stream"
                className="w-full h-full object-cover"
              />
            </div>
          </div>

          {/* AI events */}
          <div className="rounded-lg border bg-card">
            <div className="flex items-center justify-between px-4 py-3 border-b">
              <div className="font-medium">AI Events</div>
              {latestAiEvent ? (
                <span className="text-xs text-muted-foreground">
                  Latest: {latestAiEvent.event}
                  {latestAiEvent.item ? ` • ${latestAiEvent.item}` : ""}
                  {typeof latestAiEvent.confidence === "number"
                    ? ` • ${(latestAiEvent.confidence * 100).toFixed(0)}%`
                    : ""}
                </span>
              ) : (
                <span className="text-xs text-muted-foreground">No events yet</span>
              )}
            </div>
            <div className="p-4 space-y-2 max-h-64 overflow-auto">
              {aiEvents.length === 0 ? (
                <div className="text-sm text-muted-foreground">Waiting for AI events…</div>
              ) : (
                aiEvents.map((e, idx) => (
                  <div key={idx} className="text-sm rounded-md border p-2 bg-muted/10">
                    <div className="font-medium">
                      {e.event}
                      {e.item ? `: ${e.item}` : ""}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {e.timestamp ? e.timestamp : ""}
                      {typeof e.confidence === "number"
                        ? `${e.timestamp ? " • " : ""}${(e.confidence * 100).toFixed(0)}%`
                        : ""}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {loading ? (
            <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-48 animate-pulse bg-muted rounded-lg" />
              ))}
            </div>
          ) : error ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">Error loading products: {error}</p>
            </div>
          ) : uiProducts.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No products assigned to this machine</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-3">
              {uiProducts.map((p) => (
                <ProductCard 
                  key={p.id} 
                  product={p} 
                  onBuy={() => handleBuy(p)} 
                />
              ))}
            </div>
          )}
        </section>
        <aside className="lg:col-span-4 xl:col-span-3">
          <CartSidebar 
            items={items}
            onCheckout={handleCheckout}
            onClear={clear}
            processing={processing}
          />
        </aside>
      </main>

      {/* Offline overlay */}
      {!online && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-card p-6 rounded-lg text-center">
            <h3 className="text-lg font-semibold mb-2">Machine Offline</h3>
            <p className="text-muted-foreground">Please wait while we reconnect...</p>
          </div>
        </div>
      )}

      {/* Dispensing banner */}
      {showDispensing && (
        <div className="fixed top-4 left-1/2 transform -translate-x-1/2 bg-green-500 text-white px-6 py-3 rounded-lg z-50">
          {saleResult ? (
            <div className="text-center">
              <div className="font-semibold">Sale Complete!</div>
              <div className="text-sm">
                Total: ${typeof saleResult.sale_total === "number" ? saleResult.sale_total.toFixed(2) : "0.00"}
              </div>
              <div className="text-xs">Items: {saleResult.items_sold || 0}</div>
              {Array.isArray(saleResult.new_stock) && saleResult.new_stock.length > 0 && (
                <div className="text-[11px] mt-1 opacity-90">
                  Stock updated:{" "}
                  {saleResult.new_stock
                    .map((s: any) => `${s.id}:${s.stock}`)
                    .join(", ")}
                </div>
              )}
              {unlockAfterSaleError && (
                <div className="text-[11px] mt-1 opacity-90">
                  Door unlock error: {unlockAfterSaleError}
                </div>
              )}
            </div>
          ) : (
            'Dispensing...'
          )}
        </div>
      )}

      {/* Sale Error Banner */}
      {saleError && (
        <div className="fixed top-4 left-1/2 transform -translate-x-1/2 bg-red-500 text-white px-6 py-3 rounded-lg z-50">
          <div className="flex items-center gap-2">
            <span>Sale Error: {saleError}</span>
            <button 
              onClick={clearError}
              className="text-xs underline"
            >
              Dismiss
            </button>
          </div>
        </div>
      )}

      <Dialog open={settingsOpen} onOpenChange={setSettingsOpen}>
        <DialogContent>
          {!settingsUnlocked ? (
            <>
              <DialogHeader>
                <DialogTitle>Enter Password</DialogTitle>
                <DialogDescription>
                  Confirm your identity to access machine settings.
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-2">
                <Label htmlFor="settings-password">Password</Label>
                <Input
                  id="settings-password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !verifying && handleVerifyPassword()}
                />
                {verifyError && (
                  <p className="text-sm text-red-500">{verifyError}</p>
                )}
              </div>
              <DialogFooter>
                <Button onClick={handleVerifyPassword} disabled={!password || verifying}>
                  {verifying ? 'Verifying...' : 'Continue'}
                </Button>
              </DialogFooter>
            </>
          ) : (
            <>
              <DialogHeader>
                <DialogTitle>Machine Settings</DialogTitle>
                <DialogDescription>
                  Perform maintenance actions for this kiosk.
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-3">
                <div className="rounded-md border p-4">
                  <h4 className="font-medium mb-1">Reset Machine</h4>
                  <p className="text-sm text-muted-foreground mb-3">
                    Clears pairing and identity from this device and returns to the pairing screen.
                  </p>
                  <Button variant="destructive" onClick={handleResetMachine}>
                    Reset Machine
                  </Button>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>

      {/* Camera debug tooling removed (edge MJPEG is handled by Flask). */}
    </div>
  );
};

export default Kiosk;
