import { apiClient } from './client';
import { AdminUser, UserDetailData } from '../types';

export interface UsersFilterParams {
  search?: string;
  status?: string;
  ordering?: string;
}

export const usersApi = {
  getUsers: async (params?: UsersFilterParams): Promise<{ success: boolean; count: number; users: AdminUser[] }> => {
    const res = await apiClient.get('/admin/users/', { params });
    return res.data;
  },

  getUserDetail: async (id: string): Promise<{
    success: boolean;
    user: UserDetailData;
    resources: any[];
    alerts: any[];
    scans: any[];
    audit_logs: any[];
  }> => {
    const res = await apiClient.get(`/admin/users/${id}/`);
    return res.data;
  },

  toggleUserStatus: async (id: string): Promise<{ success: boolean; message: string; is_active: boolean }> => {
    const res = await apiClient.post(`/admin/users/${id}/toggle-status/`);
    return res.data;
  },

  deleteUser: async (id: string): Promise<{ success: boolean; message: string }> => {
    const res = await apiClient.delete(`/admin/users/${id}/delete/`);
    return res.data;
  },
};
