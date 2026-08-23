import { useState, useMemo } from 'react';
import type { CartItem, MachineProduct } from '@/types/api';

export function useCart() {
  const [items, setItems] = useState<CartItem[]>([]);

  const add = (product: MachineProduct) => {
    setItems(prev => {
      const existingIndex = prev.findIndex(item => item.id === product.id);
      
      if (existingIndex > -1) {
        const updated = [...prev];
        updated[existingIndex] = {
          ...updated[existingIndex],
          qty: updated[existingIndex].qty + 1,
        };
        return updated;
      }
      
      return [...prev, {
        id: product.id,
        name: product.name,
        price: product.price,
        qty: 1,
      }];
    });
  };

  const remove = (productId: string) => {
    setItems(prev => prev.filter(item => item.id !== productId));
  };

  const updateQuantity = (productId: string, qty: number) => {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    
    setItems(prev => 
      prev.map(item => 
        item.id === productId ? { ...item, qty } : item
      )
    );
  };

  const clear = () => {
    setItems([]);
  };

  const total = useMemo(() => {
    return items.reduce((sum, item) => sum + (item.price * item.qty), 0);
  }, [items]);

  const totalItems = useMemo(() => {
    return items.reduce((sum, item) => sum + item.qty, 0);
  }, [items]);

  return {
    items,
    total,
    totalItems,
    add,
    remove,
    updateQuantity,
    clear,
  };
}
