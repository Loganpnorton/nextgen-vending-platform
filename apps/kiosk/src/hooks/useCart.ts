import { useState, useMemo } from 'react';
import type { CartItem, MachineProduct } from '@/types/api';
import { addCartItem, setCartQuantity } from '@/domain/kiosk';

export function useCart() {
  const [items, setItems] = useState<CartItem[]>([]);

  const add = (product: MachineProduct) => {
    setItems(prev => addCartItem(prev, product));
  };

  const remove = (productId: string) => {
    setItems(prev => prev.filter(item => item.id !== productId));
  };

  const updateQuantity = (productId: string, qty: number) => {
    setItems(prev => setCartQuantity(prev, productId, qty));
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
