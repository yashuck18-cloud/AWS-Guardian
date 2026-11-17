import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { alertsApi, AlertsFilterParams } from '../api/alerts';

export const useAlerts = (params?: AlertsFilterParams) => {
  return useQuery({
    queryKey: ['admin-alerts', params],
    queryFn: () => alertsApi.getAlerts(params),
    staleTime: 15000,
  });
};

export const useAlertDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-alert-detail', id],
    queryFn: () => alertsApi.getAlertDetail(id),
    enabled: !!id,
  });
};

export const useResolveAlert = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => alertsApi.resolveAlert(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: ['admin-alerts'] });
      queryClient.invalidateQueries({ queryKey: ['admin-alert-detail', id] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard'] });
    },
  });
};
