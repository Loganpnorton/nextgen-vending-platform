import type { CartItem, MachineProduct } from '@/types/api';

export function addCartItem(items: CartItem[], product: MachineProduct): CartItem[] {
  const existing = items.find((item) => item.id === product.id);
  if (!existing) return [...items, { id: product.id, name: product.name, price: product.price, qty: 1 }];
  return items.map((item) => item.id === product.id ? { ...item, qty: item.qty + 1 } : item);
}

export function setCartQuantity(items: CartItem[], productId: string, quantity: number): CartItem[] {
  if (!Number.isInteger(quantity) || quantity < 0) throw new Error('Quantity must be a non-negative integer.');
  if (quantity === 0) return items.filter((item) => item.id !== productId);
  return items.map((item) => item.id === productId ? { ...item, qty: quantity } : item);
}

export function applyInventorySale(
  inventory: Array<{ id: number; stock: number }>,
  items: Array<{ id: string | number; qty: number }>,
): Array<{ id: number; stock: number }> {
  const requested = new Map(items.map((item) => [Number(item.id), item.qty]));
  for (const [id, quantity] of requested) {
    if (!Number.isInteger(id) || !Number.isInteger(quantity) || quantity <= 0) throw new Error('Sale lines must use positive integer identifiers and quantities.');
    const item = inventory.find((candidate) => candidate.id === id);
    if (!item) throw new Error(`Inventory item ${id} does not exist.`);
    if (item.stock < quantity) throw new Error(`Insufficient stock for item ${id}.`);
  }
  return inventory.map((item) => ({ ...item, stock: item.stock - (requested.get(item.id) ?? 0) }));
}

export interface OfflineSale {
  id: string;
  items: CartItem[];
  createdAt: string;
  attempts: number;
}

export function enqueueOfflineSale(queue: OfflineSale[], sale: OfflineSale): OfflineSale[] {
  return queue.some((item) => item.id === sale.id) ? queue : [...queue, sale];
}

export function recordRetry(queue: OfflineSale[], saleId: string): OfflineSale[] {
  return queue.map((sale) => sale.id === saleId ? { ...sale, attempts: sale.attempts + 1 } : sale);
}

export function acknowledgeSale(queue: OfflineSale[], saleId: string): OfflineSale[] {
  return queue.filter((sale) => sale.id !== saleId);
}

export function authDestination(requireAuth: boolean, authenticated: boolean): string | null {
  if (requireAuth && !authenticated) return '/login';
  if (!requireAuth && authenticated) return '/kiosk';
  return null;
}

export type KioskStatus = 'booting' | 'pairing' | 'ready' | 'processing' | 'offline' | 'error';
export type KioskEvent = 'IDENTITY_MISSING' | 'IDENTITY_READY' | 'CHECKOUT_STARTED' | 'CHECKOUT_FINISHED' | 'NETWORK_LOST' | 'NETWORK_RESTORED' | 'FAILED';

export function transitionKiosk(status: KioskStatus, event: KioskEvent): KioskStatus {
  const transitions: Partial<Record<KioskStatus, Partial<Record<KioskEvent, KioskStatus>>>> = {
    booting: { IDENTITY_MISSING: 'pairing', IDENTITY_READY: 'ready', NETWORK_LOST: 'offline', FAILED: 'error' },
    pairing: { IDENTITY_READY: 'ready', NETWORK_LOST: 'offline', FAILED: 'error' },
    ready: { CHECKOUT_STARTED: 'processing', NETWORK_LOST: 'offline', FAILED: 'error' },
    processing: { CHECKOUT_FINISHED: 'ready', NETWORK_LOST: 'offline', FAILED: 'error' },
    offline: { NETWORK_RESTORED: 'booting', FAILED: 'error' },
    error: { NETWORK_RESTORED: 'booting' },
  };
  const next = transitions[status]?.[event];
  if (!next) throw new Error(`Invalid kiosk transition: ${status} -> ${event}`);
  return next;
}

