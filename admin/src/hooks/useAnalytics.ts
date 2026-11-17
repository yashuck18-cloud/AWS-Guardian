import { useQuery } from '@tanstack/react-query';
import { analyticsApi } from '../api/analytics';
import { systemHealthApi } from '../api/systemHealth';

export const useAnalytics = (timeframe: string = '30d') => {
  return useQuery({
    queryKey: ['admin-analytics', timeframe],
    queryFn: () => analyticsApi.getAnalytics(timeframe),
    staleTime: 30000,
  });
};

export const useSystemHealth = () => {
  return useQuery({
    queryKey: ['admin-system-health'],
    queryFn: systemHealthApi.getHealth,
    refetchInterval: 15000,
    staleTime: 10000,
  });
};
