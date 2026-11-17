import { apiClient } from './client';
import { AdminResource, AdminAlert } from '../types';

export interface ResourcesFilterParams {
  search?: string;
  service?: string;
  risk?: string;
  account?: string;
}

export const resourcesApi = {
  getResources: async (params?: ResourcesFilterParams): Promise<{ success: boolean; count: number; resources: AdminResource[] }> => {
    const res = await apiClient.get('/admin/resources/', { params });
    return res.data;
  },

  getResourceDetail: async (id: string): Promise<{
    success: boolean;
    resource: AdminResource;
    alerts: AdminAlert[];
  }> => {
    const res = await apiClient.get(`/admin/resources/${id}/`);
    return res.data;
  },
};
