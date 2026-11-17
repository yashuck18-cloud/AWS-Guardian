import { apiClient } from './client';
import { AdminAlert } from '../types';

export interface AlertsFilterParams {
  search?: string;
  severity?: string;
  status?: string;
  service?: string;
}

export const alertsApi = {
  getAlerts: async (params?: AlertsFilterParams): Promise<{ success: boolean; count: number; alerts: AdminAlert[] }> => {
    const res = await apiClient.get('/admin/alerts/', { params });
    return res.data;
  },

  getAlertDetail: async (id: string): Promise<{ success: boolean; alert: AdminAlert }> => {
    const res = await apiClient.get(`/admin/alerts/${id}/`);
    return res.data;
  },

  resolveAlert: async (id: string): Promise<{ success: boolean; message: string; alert: AdminAlert }> => {
    const res = await apiClient.post(`/admin/alerts/${id}/resolve/`);
    return res.data;
  },
};
