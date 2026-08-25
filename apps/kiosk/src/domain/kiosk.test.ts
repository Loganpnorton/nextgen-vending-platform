import { describe, expect, it } from 'vitest';

import {
  acknowledgeSale,
  addCartItem,
  applyInventorySale,
  authDestination,
  enqueueOfflineSale,
  recordRetry,
  setCartQuantity,
  transitionKiosk,
  type OfflineSale,
} from './kiosk';

const sale: OfflineSale = { id: 'sale-1', createdAt: '2026-09-01T00:00:00Z', attempts: 0, items: [{ id: '1', name: 'Water', price: 2, qty: 1 }] };

describe('inventory and cart transitions', () => {
  it('adds, increments, updates, and removes cart products immutably', () => {
    const product = { id: '1', name: 'Water', price: 2, stock: 4 } as never;
    const one = addCartItem([], product);
    const two = addCartItem(one, product);
    expect(two[0].qty).toBe(2);
    expect(one[0].qty).toBe(1);
    expect(setCartQuantity(two, '1', 0)).toEqual([]);
  });

  it('applies stock changes without allowing oversell', () => {
    expect(applyInventorySale([{ id: 1, stock: 4 }, { id: 2, stock: 2 }], [{ id: '1', qty: 3 }])).toEqual([{ id: 1, stock: 1 }, { id: 2, stock: 2 }]);
    expect(() => applyInventorySale([{ id: 1, stock: 1 }], [{ id: 1, qty: 2 }])).toThrow(/Insufficient stock/);
  });
});

describe('offline recovery', () => {
  it('deduplicates queued sales and records retry attempts', () => {
    expect(enqueueOfflineSale([sale], sale)).toHaveLength(1);
    expect(recordRetry([sale], sale.id)[0].attempts).toBe(1);
  });

  it('acknowledges a recovered sale', () => {
    expect(acknowledgeSale([sale], sale.id)).toEqual([]);
  });
});

describe('authorization and kiosk state', () => {
  it('routes sessions according to the page authorization contract', () => {
    expect(authDestination(true, false)).toBe('/login');
    expect(authDestination(false, true)).toBe('/kiosk');
    expect(authDestination(true, true)).toBeNull();
  });

  it('models checkout and network recovery', () => {
    expect(transitionKiosk('booting', 'IDENTITY_READY')).toBe('ready');
    expect(transitionKiosk('ready', 'CHECKOUT_STARTED')).toBe('processing');
    expect(transitionKiosk('processing', 'NETWORK_LOST')).toBe('offline');
    expect(transitionKiosk('offline', 'NETWORK_RESTORED')).toBe('booting');
    expect(() => transitionKiosk('pairing', 'CHECKOUT_STARTED')).toThrow(/Invalid kiosk transition/);
  });
});

