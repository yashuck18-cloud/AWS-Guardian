import { apiClient } from './client';
import { AdminAuditLog } from '../types';

export const auditLogsApi = {
  getLogs: async (params?: { search?: string; action?: string; status?: string }): Promise<{ success: boolean; count: number; logs: AdminAuditLog[] }> => {
    const res = await apiClient.get('/admin/audit-logs/', { params });
    return res.data;
  },
};
