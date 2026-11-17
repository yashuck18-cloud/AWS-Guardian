import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '../api/dashboard';

export const useDashboard = () => {
  return useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: dashboardApi.getStats,
    refetchInterval: 30000, // auto-refresh every 30 seconds
    staleTime: 10000,
  });
};
