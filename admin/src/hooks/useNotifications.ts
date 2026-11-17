import { useQuery } from '@tanstack/react-query';
import { notificationsApi } from '../api/notifications';

export const useNotifications = (params?: { search?: string; channel?: string; status?: string }) => {
  return useQuery({
    queryKey: ['admin-notifications', params],
    queryFn: () => notificationsApi.getNotifications(params),
    staleTime: 15000,
  });
};
