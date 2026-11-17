import { apiClient } from './client';
import { AdminNotification } from '../types';

export const notificationsApi = {
  getNotifications: async (params?: { search?: string; channel?: string; status?: string }): Promise<{ success: boolean; count: number; notifications: AdminNotification[] }> => {
    const res = await apiClient.get('/admin/notifications/', { params });
    return res.data;
  },
};
