import { apiClient } from './client';
import { AdminScan } from '../types';

export const scansApi = {
  getScans: async (params?: { search?: string; status?: string }): Promise<{ success: boolean; count: number; scans: AdminScan[] }> => {
    const res = await apiClient.get('/admin/scans/', { params });
    return res.data;
  },
};
