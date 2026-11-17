import React, { useState } from 'react';
import {
  Search,
  FileText,
  RefreshCw,
  Filter,
  Eye,
  ShieldCheck,
  X,
  Lock,
} from 'lucide-react';
import { useAuditLogs } from '../hooks/useAuditLogs';
import { Card, CardContent } from '../components/common/Card';
import { Badge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { Pagination } from '../components/tables/Pagination';
import { formatDateTime, formatTimeAgo } from '../utils/cn';
import { AdminAuditLog } from '../types';

export const AuditLogs: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedLog, setSelectedLog] = useState<AdminAuditLog | null>(null);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const { data, isLoading, refetch, isRefetching } = useAuditLogs({
    search: search.trim() || undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const logsList = data?.logs || [];
  const paginatedLogs = logsList.slice((page - 1) * pageSize, page * pageSize);

  const successCount = logsList.filter((l) => l.status === 'SUCCESS').length;
  const failureCount = logsList.filter((l) => l.status === 'FAILURE').length;
  const uniqueIPs = new Set(logsList.map((l) => l.ip_address).filter(Boolean)).size;

  const statuses = ['all', 'SUCCESS', 'FAILURE'];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-guardian-text tracking-tight">Security Audit Logs</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Immutable tamper-evident security audit trail of administrative authentication and resource operations.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()} isLoading={isRefetching} className="h-8 text-xs">
            <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </Button>
        </div>
      </div>

      {/* KPI Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-guardian-muted">Total Events</span>
          <div className="text-xl font-bold text-guardian-text font-mono">{logsList.length}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-emerald-400">Success Operations</span>
          <div className="text-xl font-bold text-emerald-400 font-mono">{successCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-red-400">Failed Attempts</span>
          <div className="text-xl font-bold text-red-400 font-mono">{failureCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-purple-300">Unique Origin IPs</span>
          <div className="text-xl font-bold text-purple-300 font-mono">{uniqueIPs}</div>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-3 flex flex-col md:flex-row items-center justify-between gap-3">
          {/* Search */}
          <div className="w-full md:w-80 relative flex items-center">
            <Search className="w-4 h-4 text-guardian-muted absolute left-3 pointer-events-none" />
            <input
              type="text"
              placeholder="Search action code, IP, or user..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-lg border border-guardian-border pl-9 pr-3 py-1.5 focus:outline-none focus:border-primary-light focus:ring-1 focus:ring-primary-light/30"
            />
          </div>

          {/* Status Tabs */}
          <div className="flex items-center gap-1.5 w-full md:w-auto overflow-x-auto pb-1 md:pb-0">
            <span className="text-xs text-guardian-muted flex items-center gap-1 mr-1">
              <Filter className="w-3.5 h-3.5" /> Result:
            </span>
            {statuses.map((st) => (
              <button
                key={st}
                onClick={() => {
                  setStatusFilter(st);
                  setPage(1);
                }}
                className={`px-2.5 py-0.5 text-xs font-semibold rounded-md uppercase transition-colors ${
                  statusFilter === st
                    ? 'bg-primary text-white shadow-sm'
                    : 'bg-guardian-bg hover:bg-white/5 text-guardian-muted hover:text-guardian-text border border-guardian-border'
                }`}
              >
                {st}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Audit Logs Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border bg-guardian-bg/40 text-guardian-muted font-bold text-[10px] uppercase tracking-wider">
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-3">Action Code</th>
                <th className="py-3 px-3">Actor User</th>
                <th className="py-3 px-3">IP Address</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-3">Payload Summary</th>
                <th className="py-3 px-4 text-right">Inspect</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <TableSkeleton rows={5} cols={7} />
                  </td>
                </tr>
              ) : paginatedLogs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <EmptyState
                      icon={<ShieldCheck className="w-6 h-6 text-emerald-400" />}
                      title="No audit events found"
                      description="No security audit operations match the active filter criteria."
                    />
                  </td>
                </tr>
              ) : (
                paginatedLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-white/5 transition-colors group">
                    <td className="py-3 px-4 text-guardian-muted font-mono text-[11px] whitespace-nowrap">
                      {formatDateTime(log.timestamp)}
                    </td>

                    <td className="py-3 px-3 font-mono font-semibold text-primary-light text-[11px]">
                      {log.action}
                    </td>

                    <td className="py-3 px-3">
                      {log.user_name ? (
                        <div>
                          <div className="font-semibold text-guardian-text">{log.user_name}</div>
                          <div className="text-[10px] text-guardian-muted font-mono">{log.user_email}</div>
                        </div>
                      ) : (
                        <span className="text-guardian-dimmed font-mono text-[11px]">System / Core</span>
                      )}
                    </td>

                    <td className="py-3 px-3 font-mono text-guardian-muted text-[11px]">
                      {log.ip_address}
                    </td>

                    <td className="py-3 px-3">
                      <Badge variant={log.status === 'SUCCESS' ? 'success' : 'critical'} dot>
                        {log.status}
                      </Badge>
                    </td>

                    <td className="py-3 px-3 font-mono text-[10px] text-guardian-muted max-w-xs truncate" title={JSON.stringify(log.details)}>
                      {JSON.stringify(log.details)}
                    </td>

                    <td className="py-3 px-4 text-right">
                      <Button variant="secondary" size="sm" onClick={() => setSelectedLog(log)} className="h-7 text-xs">
                        <Eye className="w-3 h-3" />
                        <span>Inspect</span>
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <Pagination
          currentPage={page}
          totalItems={logsList.length}
          pageSize={pageSize}
          onPageChange={setPage}
        />
      </Card>

      {/* Inspect Log Event Modal */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in">
          <div
            className="w-full max-w-lg bg-guardian-card border border-guardian-border rounded-xl shadow-2xl overflow-hidden p-5 space-y-3.5"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-guardian-border pb-2.5">
              <div className="flex items-center gap-2">
                <FileText className="w-4 h-4 text-primary-light" />
                <h3 className="text-sm font-bold text-guardian-text">Audit Event Details</h3>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-guardian-muted hover:text-guardian-text p-1 rounded-md"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-1.5 text-xs">
              <div className="flex justify-between py-1 border-b border-guardian-border">
                <span className="text-guardian-muted">Action Code</span>
                <span className="font-mono font-bold text-primary-light">{selectedLog.action}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-guardian-border">
                <span className="text-guardian-muted">Status</span>
                <Badge variant={selectedLog.status === 'SUCCESS' ? 'success' : 'critical'}>{selectedLog.status}</Badge>
              </div>
              <div className="flex justify-between py-1 border-b border-guardian-border">
                <span className="text-guardian-muted">Timestamp</span>
                <span className="font-mono text-guardian-text">{formatDateTime(selectedLog.timestamp)}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-guardian-border">
                <span className="text-guardian-muted">Originating IP</span>
                <span className="font-mono text-guardian-text">{selectedLog.ip_address}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-guardian-border">
                <span className="text-guardian-muted">Actor User</span>
                <span className="text-guardian-text">{selectedLog.user_name || 'System Core'} ({selectedLog.user_email || '—'})</span>
              </div>
            </div>

            <div className="space-y-1 pt-1">
              <label className="block text-[11px] font-semibold text-guardian-muted">Sanitized Audit Payload:</label>
              <pre className="p-3 rounded-lg bg-guardian-bg border border-guardian-border text-[11px] font-mono text-guardian-text overflow-x-auto max-h-44">
                {JSON.stringify(selectedLog.details, null, 2)}
              </pre>
            </div>

            <div className="pt-1 flex justify-end">
              <Button variant="secondary" size="sm" onClick={() => setSelectedLog(null)}>
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
