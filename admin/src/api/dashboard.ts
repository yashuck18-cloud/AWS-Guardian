import { apiClient } from './client';
import { DashboardResponse } from '../types';

export const dashboardApi = {
  getStats: async (): Promise<DashboardResponse> => {
    const res = await apiClient.get<DashboardResponse>('/admin/dashboard/');
    return res.data;
  },
};
