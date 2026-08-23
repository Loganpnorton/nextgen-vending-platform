import { useState } from "react";
import type { CartItem } from "@/types/api";
import { edgeFetch } from "@/lib/edgeApi";
import { edgeConfig } from "@/lib/edgeConfig";

export interface SaleResponse {
  success: boolean;
  message: string;
  data?: {
    sale_total: number;
    items_sold: number;
    new_stock: Array<{ id: number; stock: number }>;
    backend_message?: string;
  };
  errors?: string[];
}

type SaleApiSuccess = {
  status: "success";
  message: string;
  new_stock: Array<{ id: number; stock: number }>;
};

type SaleApiError = {
  status?: "error";
  error?: string;
  message?: string;
};

export function useSales() {
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const processSale = async (
    items: CartItem[],
    machineToken: string
  ): Promise<SaleResponse> => {
    if (!items || items.length === 0) {
      return {
        success: false,
        message: 'No items to process',
        errors: ['Cart is empty']
      };
    }

    if (!machineToken) {
      return {
        success: false,
        message: 'Machine token is required',
        errors: ['Machine not authenticated']
      };
    }

    setProcessing(true);
    setError(null);

    try {
      const saleTotal = items.reduce((sum, i) => sum + i.price * i.qty, 0);
      const itemsSold = items.reduce((sum, i) => sum + i.qty, 0);

      const resp = await edgeFetch<SaleApiSuccess | SaleApiError>(edgeConfig.salePath, {
        method: "POST",
        auth: false,
        json: {
          items: items.map((i) => ({ id: Number(i.id), quantity: i.qty })),
        },
      });

      if (!resp || typeof resp !== "object") {
        return { success: false, message: "Invalid response from /sale" };
      }

      if ("status" in resp && resp.status === "success") {
        return {
          success: true,
          message: resp.message || "Transaction recorded",
          data: {
            sale_total: saleTotal,
            items_sold: itemsSold,
            new_stock: resp.new_stock || [],
            backend_message: resp.message,
          },
        };
      }

      const msg =
        ("error" in resp && resp.error) ||
        ("message" in resp && resp.message) ||
        "Sale failed";

      return { success: false, message: String(msg), errors: [String(msg)] };

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Network error";
      console.error("❌ Error processing sale:", err);
      setError(errorMessage);
      return {
        success: false,
        message: errorMessage,
        errors: [errorMessage]
      };
    } finally {
      setProcessing(false);
    }
  };

  const clearError = () => {
    setError(null);
  };

  return {
    processSale,
    processing,
    error,
    clearError
  };
}
