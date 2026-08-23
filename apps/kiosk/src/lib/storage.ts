import type { MachineIdentity } from '@/types/api';

const KEYS = {
  machineId: "nv_machine_id",
  machineCode: "nv_machine_code", 
  machineToken: "nv_machine_token",
  pairingCode: "nv_pairing_code",
  pairingExpiresAt: "nv_pairing_expires_at",
} as const;

export function setIdentity(identity: Partial<MachineIdentity>): void {
  if (identity.machineId) {
    localStorage.setItem(KEYS.machineId, identity.machineId);
  }
  if (identity.machineCode) {
    localStorage.setItem(KEYS.machineCode, identity.machineCode);
  }
  if (identity.machineToken) {
    localStorage.setItem(KEYS.machineToken, identity.machineToken);
  }
}

export function setPairingCode(code: string, expiresAt: string): void {
  localStorage.setItem(KEYS.pairingCode, code);
  localStorage.setItem(KEYS.pairingExpiresAt, expiresAt);
}

export function getPairingCode(): { code: string; expiresAt: string } | null {
  const code = localStorage.getItem(KEYS.pairingCode);
  const expiresAt = localStorage.getItem(KEYS.pairingExpiresAt);
  
  if (!code || !expiresAt) {
    return null;
  }
  
  return { code, expiresAt };
}

export function clearPairingCode(): void {
  localStorage.removeItem(KEYS.pairingCode);
  localStorage.removeItem(KEYS.pairingExpiresAt);
}

export function getIdentity(): MachineIdentity {
  const machineId = localStorage.getItem(KEYS.machineId) || undefined;
  const machineCode = localStorage.getItem(KEYS.machineCode) || undefined;
  const machineToken = localStorage.getItem(KEYS.machineToken) || '';
  
  // Only consider it a valid identity if we have a non-empty machine token
  const hasValidIdentity = machineToken && machineToken.trim() !== '';
  
  return {
    machineId,
    machineCode,
    machineToken,
    hasIdentity: hasValidIdentity,
  };
}

export function clearIdentity(): void {
  localStorage.removeItem(KEYS.machineId);
  localStorage.removeItem(KEYS.machineCode);
  localStorage.removeItem(KEYS.machineToken);
}

export function clearAll(): void {
  clearIdentity();
  clearPairingCode();
}

export function clearInvalidIdentity(): void {
  const machineToken = localStorage.getItem(KEYS.machineToken);
  // If we have an empty or invalid machine token, clear the identity
  if (!machineToken || machineToken.trim() === '') {
    clearIdentity();
  }
}
