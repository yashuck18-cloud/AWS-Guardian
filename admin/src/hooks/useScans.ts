import { useQuery } from '@tanstack/react-query';
import { scansApi } from '../api/scans';

export const useScans = (params?: { search?: string; status?: string }) => {
  return useQuery({
    queryKey: ['admin-scans', params],
    queryFn: () => scansApi.getScans(params),
    refetchInterval: 20000,
    staleTime: 10000,
  });
};
