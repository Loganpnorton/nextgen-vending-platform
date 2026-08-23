import { useCallback, useEffect, useState } from "react";
import type { MachineProduct } from "@/types/api";
import { edgeFetch } from "@/lib/edgeApi";
import { edgeConfig } from "@/lib/edgeConfig";

type InventoryItem = Partial<MachineProduct> & {
  id?: string;
  name?: string;
  price?: number;
  stock_level?: number;
  stock?: number;
  image_url?: string | null;
  slot_position?: string | null;
};

type InventoryResponse = InventoryItem[] | { items: InventoryItem[] } | { inventory: InventoryItem[] };

function normalizeInventory(resp: InventoryResponse): InventoryItem[] {
  if (Array.isArray(resp)) return resp;
  if (resp && typeof resp === "object" && "items" in resp && Array.isArray((resp as any).items)) {
    return (resp as any).items;
  }
  if (resp && typeof resp === "object" && "inventory" in resp && Array.isArray((resp as any).inventory)) {
    return (resp as any).inventory;
  }
  return [];
}

export function useMachineProducts(machineId?: string, machineCode?: string, machineToken?: string) {
  const [products, setProducts] = useState<MachineProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    try {
      setError(null);

      const resp = await edgeFetch<InventoryResponse>(edgeConfig.inventoryPath, { auth: false });
      const items = normalizeInventory(resp);

      const mapped: MachineProduct[] = items
        .map((it, idx) => ({
          id: it.id || `${idx}`,
          product_id: it.product_id || it.id || `${idx}`,
          name: it.name || "Item",
          price: typeof it.price === "number" ? it.price : 0,
          image_url: it.image_url ?? null,
          category: it.category ?? null,
          slot_position: it.slot_position ?? null,
          stock_level:
            typeof it.stock_level === "number"
              ? it.stock_level
              : typeof it.stock === "number"
                ? it.stock
                : 0,
        }))
        .filter(Boolean);

      setProducts(mapped);
    } catch (err: any) {
      setProducts([]);
      setError(err?.message || "Failed to load local inventory");
    } finally {
      setLoading(false);
    }
  }, []);

  // Initial fetch
  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  // Polling every 5 seconds (local edge)
  useEffect(() => {
    const interval = setInterval(() => {
      fetchProducts();
    }, 5000);

    return () => clearInterval(interval);
  }, [fetchProducts]);

  const refresh = useCallback(() => {
    setLoading(true);
    fetchProducts();
  }, [fetchProducts]);

  return {
    products,
    loading,
    error,
    refresh,
  };
}
