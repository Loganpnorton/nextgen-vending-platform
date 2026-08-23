import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';

interface MachineDetails {
  id: string;
  name: string;
  code?: string;
  location?: string;
  status: 'active' | 'inactive';
}

export function useMachineDetails(machineId?: string, machineToken?: string) {
  const [details, setDetails] = useState<MachineDetails | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!machineId || !machineToken) return;

    const fetchMachineDetails = async () => {
      setLoading(true);
      setError(null);

      try {
        // Try to fetch machine details from Supabase
        // machineId is the UUID, we need to find by UUID, not machine_code
        const { data, error } = await supabase
          .from('machines')
          .select('id, name, machine_code, location, status')
          .eq('id', machineId)
          .single();

        if (error) {
          console.log('Failed to fetch machine details:', error);
          // Fallback to using machine ID as name
          setDetails({
            id: machineId,
            name: machineId, // Use machine ID as name if no details found
            code: machineId,
            status: 'active',
          });
        } else if (data) {
          console.log('Machine details fetched:', data);
          setDetails({
            id: data.id,
            name: data.name || machineId,
            code: data.machine_code || machineId,
            location: data.location,
            status: data.status || 'active',
          });
        }
      } catch (err) {
        console.error('Error fetching machine details:', err);
        // Fallback to using machine ID as name
        setDetails({
          id: machineId,
          name: machineId,
          code: machineId,
          status: 'active',
        });
      } finally {
        setLoading(false);
      }
    };

    fetchMachineDetails();
  }, [machineId, machineToken]);

  return {
    details,
    loading,
    error,
  };
}
