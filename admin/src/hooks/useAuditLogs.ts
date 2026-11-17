import { useQuery } from '@tanstack/react-query';
import { auditLogsApi } from '../api/auditLogs';

export const useAuditLogs = (params?: { search?: string; action?: string; status?: string }) => {
  return useQuery({
    queryKey: ['admin-audit-logs', params],
    queryFn: () => auditLogsApi.getLogs(params),
    staleTime: 10000,
  });
};
