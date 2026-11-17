import { apiClient } from './client';
import { AdminAWSAccount, AdminResource, AdminAlert, AdminScan } from '../types';

export interface AWSAccountsFilterParams {
  search?: string;
  status?: string;
}

export const awsAccountsApi = {
  getAccounts: async (params?: AWSAccountsFilterParams): Promise<{ success: boolean; count: number; accounts: AdminAWSAccount[] }> => {
    const res = await apiClient.get('/admin/aws-accounts/', { params });
    return res.data;
  },

  getAccountDetail: async (id: string): Promise<{
    success: boolean;
    account: AdminAWSAccount;
    resources: AdminResource[];
    alerts: AdminAlert[];
    scans: AdminScan[];
  }> => {
    const res = await apiClient.get(`/admin/aws-accounts/${id}/`);
    return res.data;
  },
};
