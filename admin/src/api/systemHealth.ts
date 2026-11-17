import { apiClient } from './client';
import { SystemHealthResponse, GlobalSearchResponse } from '../types';

export const systemHealthApi = {
  getHealth: async (): Promise<SystemHealthResponse> => {
    const res = await apiClient.get<SystemHealthResponse>('/admin/system-health/');
    return res.data;
  },
};

export const searchApi = {
  globalSearch: async (q: string): Promise<GlobalSearchResponse> => {
    const res = await apiClient.get<GlobalSearchResponse>('/admin/search/', {
      params: { q },
    });
    return res.data;
  },
};
