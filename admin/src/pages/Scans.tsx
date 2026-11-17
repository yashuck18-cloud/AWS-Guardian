import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  ScanLine,
  RefreshCw,
  Filter,
  CheckCircle,
  AlertOctagon,
  Clock,
} from 'lucide-react';
import { useScans } from '../hooks/useScans';
import { Card, CardContent } from '../components/common/Card';
import { Badge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { Pagination } from '../components/tables/Pagination';
import { formatDateTime, formatTimeAgo } from '../utils/cn';

export const Scans: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const navigate = useNavigate();

  const { data, isLoading, refetch, isRefetching } = useScans({
    search: search.trim() || undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const scansList = data?.scans || [];
  const paginatedScans = scansList.slice((page - 1) * pageSize, page * pageSize);

  const completedCount = scansList.filter((s) => s.status === 'COMPLETED').length;
  const runningCount = scansList.filter((s) => s.status === 'RUNNING').length;
  const failedCount = scansList.filter((s) => s.status === 'FAILED').length;

  const statuses = ['all', 'COMPLETED', 'RUNNING', 'FAILED', 'PENDING'];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-guardian-text tracking-tight">STS AssumeRole Scans</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Automated multi-region discovery runs across AWS EC2, EBS, RDS, S3, ELB, and VPC services.
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
          <span className="text-[11px] font-semibold text-guardian-muted">Total Scans</span>
          <div className="text-xl font-bold text-guardian-text font-mono">{scansList.length}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-emerald-400">Completed Clean</span>
          <div className="text-xl font-bold text-emerald-400 font-mono">{completedCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-sky-400">In Progress</span>
          <div className="text-xl font-bold text-sky-400 font-mono">{runningCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-red-400">Failed Runs</span>
          <div className="text-xl font-bold text-red-400 font-mono">{failedCount}</div>
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
              placeholder="Search by AWS account name or ID..."
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
              <Filter className="w-3.5 h-3.5" /> Status:
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

      {/* Scans Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border bg-guardian-bg/40 text-guardian-muted font-bold text-[10px] uppercase tracking-wider">
                <th className="py-3 px-4">AWS Account</th>
                <th className="py-3 px-3">Owner User</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-3 text-center">Resources Found</th>
                <th className="py-3 px-3 text-center">Alerts Created</th>
                <th className="py-3 px-3">Started</th>
                <th className="py-3 px-3">Duration</th>
                <th className="py-3 px-4">Details / Logs</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="p-0">
                    <TableSkeleton rows={5} cols={8} />
                  </td>
                </tr>
              ) : paginatedScans.length === 0 ? (
                <tr>
                  <td colSpan={8} className="p-0">
                    <EmptyState
                      icon={<ScanLine className="w-6 h-6" />}
                      title="No scan runs recorded"
                      description="No automated discovery runs matching the filter criteria."
                    />
                  </td>
                </tr>
              ) : (
                paginatedScans.map((scan) => (
                  <tr key={scan.id} className="hover:bg-white/5 transition-colors group">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-guardian-text hover:text-primary-light transition-colors cursor-pointer" onClick={() => navigate(`/admin/aws-accounts/${scan.account}`)}>
                        {scan.account_name}
                      </div>
                      <div className="text-[10px] text-guardian-muted font-mono">{scan.account_aws_id}</div>
                    </td>

                    <td className="py-3 px-3">
                      <div className="font-medium text-guardian-text">{scan.user_name}</div>
                      <div className="text-[10px] text-guardian-muted font-mono">{scan.user_email}</div>
                    </td>

                    <td className="py-3 px-3">
                      <Badge
                        variant={
                          scan.status === 'COMPLETED'
                            ? 'success'
                            : scan.status === 'FAILED'
                            ? 'critical'
                            : scan.status === 'RUNNING'
                            ? 'info'
                            : 'warning'
                        }
                        dot
                      >
                        {scan.status}
                      </Badge>
                    </td>

                    <td className="py-3 px-3 text-center font-mono font-semibold">
                      <span className="px-2 py-0.5 rounded bg-guardian-bg border border-guardian-border">
                        {scan.resources_found}
                      </span>
                    </td>

                    <td className="py-3 px-3 text-center font-mono font-semibold">
                      {scan.alerts_generated > 0 ? (
                        <span className="px-2 py-0.5 rounded bg-amber-500/15 text-amber-400 border border-amber-500/30">
                          {scan.alerts_generated}
                        </span>
                      ) : (
                        <span className="text-guardian-dimmed">0</span>
                      )}
                    </td>

                    <td className="py-3 px-3 text-guardian-muted font-mono text-[11px]">
                      {formatDateTime(scan.started_at)}
                    </td>

                    <td className="py-3 px-3 text-guardian-muted font-mono text-[11px]">
                      {scan.completed_at ? formatTimeAgo(scan.completed_at) : 'Running...'}
                    </td>

                    <td className="py-3 px-4">
                      {scan.error_message ? (
                        <span className="text-[10px] text-guardian-critical font-mono max-w-xs truncate block" title={scan.error_message}>
                          {scan.error_message}
                        </span>
                      ) : (
                        <span className="text-[11px] text-guardian-dimmed font-mono">Clean run</span>
                      )}
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
          totalItems={scansList.length}
          pageSize={pageSize}
          onPageChange={setPage}
        />
      </Card>
    </div>
  );
};
