import { apiClient } from './client';
import { AnalyticsResponse } from '../types';

export const analyticsApi = {
  getAnalytics: async (timeframe: string = '30d'): Promise<AnalyticsResponse> => {
    const res = await apiClient.get<AnalyticsResponse>('/admin/analytics/', {
      params: { timeframe },
    });
    return res.data;
  },
};
