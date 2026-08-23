import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { getIdentity } from '@/lib/storage';
import type { MachineIdentity } from '@/types/api';

export function useMachineIdentity() {
  const [searchParams] = useSearchParams();
  const [identity, setIdentity] = useState<MachineIdentity>({
    machineId: undefined,
    machineCode: undefined,
    machineToken: '',
    hasIdentity: false,
  });

  useEffect(() => {
    // Priority: URL params > localStorage
    const urlToken = searchParams.get('machine_token');
    const storedIdentity = getIdentity();

    // In the edge-first architecture, the kiosk is a single local node; a token is optional.
    // We keep a token field for compatibility with older flows (ex: /sale payloads).
    const machineToken = urlToken || storedIdentity.machineToken || 'local-kiosk';
    const machineId = storedIdentity.machineId;
    const machineCode = storedIdentity.machineCode;

    const newIdentity: MachineIdentity = {
      machineId,
      machineCode,
      machineToken,
      hasIdentity: !!machineToken,
    };

    setIdentity(newIdentity);
  }, [searchParams]);

  return identity;
}
