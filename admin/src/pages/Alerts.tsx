import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Search,
  AlertTriangle,
  AlertOctagon,
  Download,
  ChevronLeft,
  ChevronRight,
  Send,
  Zap,
  CheckCircle,
  ShieldCheck,
} from 'lucide-react';
import { useAlerts, useResolveAlert } from '../hooks/useAlerts';
import { Card, CardContent } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState, ConfirmationDialog } from '../components/common/EmptyState';
import { AdminAlert } from '../types';
import { formatTimeAgo } from '../utils/cn';

export const Alerts: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [severityFilter, setSeverityFilter] = useState(searchParams.get('severity') || 'all');
  const [statusFilter, setStatusFilter] = useState(searchParams.get('status') || 'all');
  const [alertToResolve, setAlertToResolve] = useState<AdminAlert | null>(null);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const navigate = useNavigate();

  const { data, isLoading, refetch } = useAlerts({
    search: search.trim() || undefined,
    severity: severityFilter !== 'all' ? severityFilter : undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const resolveMutation = useResolveAlert();

  const alertsList = data?.alerts || [];
  const paginatedAlerts = alertsList.slice((page - 1) * pageSize, page * pageSize);
  const totalPages = Math.ceil(alertsList.length / pageSize) || 1;

  const handleConfirmResolve = async () => {
    if (!alertToResolve) return;
    try {
      await resolveMutation.mutateAsync(alertToResolve.id);
      setAlertToResolve(null);
      refetch();
    } catch {
      // handled
    }
  };

  const handleClearFilters = () => {
    setSearch('');
    setSeverityFilter('all');
    setStatusFilter('all');
    setSearchParams({});
  };

  const critCount = alertsList.filter((a) => a.severity === 'CRITICAL').length;
  const highCount = alertsList.filter((a) => a.severity === 'HIGH').length;
  const medCount = alertsList.filter((a) => a.severity === 'MEDIUM').length;
  const lowCount = alertsList.filter((a) => a.severity === 'LOW').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-guardian-text tracking-tight">Alerts</h1>
          <p className="text-xs text-guardian-muted mt-1">
            Monitor and respond to security alerts
          </p>
        </div>

        <Button variant="outline" size="sm" className="bg-guardian-card border-guardian-border text-guardian-text hover:bg-guardian-cardElevated text-xs h-9 px-3.5 gap-1.5 cursor-pointer">
          <Download className="w-3.5 h-3.5" />
          <span>Export</span>
        </Button>
      </div>

      {/* 4 Severity KPI Stat Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {/* Critical */}
        <div className="p-4 rounded-xl bg-guardian-card border border-guardian-border flex items-center justify-between">
          <div>
            <span className="text-xs text-guardian-muted font-medium block">Critical</span>
            <span className="text-2xl font-bold text-guardian-text font-mono mt-0.5 block">{critCount}</span>
          </div>
          <div className="w-9 h-9 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-500 flex items-center justify-center shrink-0">
            <AlertOctagon className="w-5 h-5" />
          </div>
        </div>

        {/* High */}
        <div className="p-4 rounded-xl bg-guardian-card border border-guardian-border flex items-center justify-between">
          <div>
            <span className="text-xs text-guardian-muted font-medium block">High</span>
            <span className="text-2xl font-bold text-guardian-text font-mono mt-0.5 block">{highCount}</span>
          </div>
          <div className="w-9 h-9 rounded-lg bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
            <AlertTriangle className="w-5 h-5" />
          </div>
        </div>

        {/* Medium */}
        <div className="p-4 rounded-xl bg-guardian-card border border-guardian-border flex items-center justify-between">
          <div>
            <span className="text-xs text-guardian-muted font-medium block">Medium</span>
            <span className="text-2xl font-bold text-guardian-text font-mono mt-0.5 block">{medCount}</span>
          </div>
          <div className="w-9 h-9 rounded-lg bg-yellow-500/10 border border-yellow-500/20 text-yellow-400 flex items-center justify-center shrink-0">
            <Zap className="w-5 h-5" />
          </div>
        </div>

        {/* Low */}
        <div className="p-4 rounded-xl bg-guardian-card border border-guardian-border flex items-center justify-between">
          <div>
            <span className="text-xs text-guardian-muted font-medium block">Low</span>
            <span className="text-2xl font-bold text-guardian-text font-mono mt-0.5 block">{lowCount}</span>
          </div>
          <div className="w-9 h-9 rounded-lg bg-sky-500/10 border border-sky-500/20 text-sky-400 flex items-center justify-center shrink-0">
            <Send className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filter Bar */}
      <Card className="bg-guardian-card border-guardian-border">
        <CardContent className="p-3.5 flex flex-col md:flex-row items-center justify-between gap-3">
          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto flex-1">
            {/* Search input */}
            <div className="relative flex-1 min-w-50 max-w-sm">
              <Search className="w-4 h-4 text-guardian-muted absolute left-3 top-2.5 pointer-events-none" />
              <input
                type="text"
                placeholder="Search alerts..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-lg border border-guardian-border pl-9 pr-3 py-2 focus:outline-none focus:border-brand-500"
              />
            </div>

            {/* Severity Select */}
            <select
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
              className="bg-guardian-bg text-guardian-text text-xs rounded-lg border border-guardian-border px-3 py-2 focus:outline-none cursor-pointer"
            >
              <option value="all">Severity</option>
              <option value="CRITICAL">Critical</option>
              <option value="HIGH">High</option>
              <option value="MEDIUM">Medium</option>
              <option value="LOW">Low</option>
            </select>

            {/* Status Select */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-guardian-bg text-guardian-text text-xs rounded-lg border border-guardian-border px-3 py-2 focus:outline-none cursor-pointer"
            >
              <option value="all">Status</option>
              <option value="ACTIVE">Active</option>
              <option value="RESOLVED">Resolved</option>
            </select>
          </div>

          <button
            onClick={handleClearFilters}
            className="text-xs font-semibold text-brand-500 hover:text-brand-600 cursor-pointer self-end md:self-center"
          >
            Clear
          </button>
        </CardContent>
      </Card>

      {/* Alerts Table */}
      <Card className="bg-guardian-card border-guardian-border">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border text-guardian-muted font-semibold text-[11px]">
                <th className="py-3.5 px-5">Alert</th>
                <th className="py-3.5 px-4">Severity</th>
                <th className="py-3.5 px-4">AWS Account</th>
                <th className="py-3.5 px-4">Resource</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4">Created</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <TableSkeleton rows={5} cols={7} />
                  </td>
                </tr>
              ) : paginatedAlerts.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <EmptyState
                      icon={<ShieldCheck className="w-6 h-6 text-emerald-500" />}
                      title="No security findings found"
                      description="No security or cost waste alerts detected matching your search or filters."
                    />
                  </td>
                </tr>
              ) : (
                paginatedAlerts.map((alert) => (
                  <tr key={alert.id} className="hover:bg-guardian-cardElevated transition-colors group">
                    {/* Alert Title */}
                    <td className="py-3.5 px-5">
                      <div className="font-bold text-guardian-text leading-tight cursor-pointer hover:text-brand-500 transition-colors" onClick={() => navigate(`/admin/alerts/${alert.id}`)}>
                        {alert.title}
                      </div>
                      <div className="text-[11px] text-guardian-muted font-mono mt-0.5">{alert.resource_identifier || '—'}</div>
                    </td>

                    {/* Severity Pill */}
                    <td className="py-3.5 px-4">
                      {alert.severity === 'CRITICAL' && (
                        <span className="px-2.5 py-0.5 rounded-full bg-rose-500/20 text-rose-500 border border-rose-500/30 text-[10px] font-bold">
                          • Critical
                        </span>
                      )}
                      {alert.severity === 'HIGH' && (
                        <span className="px-2.5 py-0.5 rounded-full bg-amber-500/20 text-amber-500 border border-amber-500/30 text-[10px] font-bold">
                          • High
                        </span>
                      )}
                      {alert.severity === 'MEDIUM' && (
                        <span className="px-2.5 py-0.5 rounded-full bg-yellow-500/20 text-yellow-600 border border-yellow-500/30 text-[10px] font-bold">
                          • Medium
                        </span>
                      )}
                      {alert.severity === 'LOW' && (
                        <span className="px-2.5 py-0.5 rounded-full bg-sky-500/20 text-sky-500 border border-sky-500/30 text-[10px] font-bold">
                          • Low
                        </span>
                      )}
                    </td>

                    {/* AWS Account ID */}
                    <td className="py-3.5 px-4 font-mono text-guardian-text">
                      {alert.account_aws_id || '—'}
                    </td>

                    {/* Resource Name */}
                    <td className="py-3.5 px-4 text-guardian-text">
                      {alert.resource_type || 'Cloud Asset'}
                    </td>

                    {/* Status */}
                    <td className="py-3.5 px-4">
                      <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${alert.status === 'RESOLVED' ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20' : 'bg-amber-500/10 text-amber-500 border border-amber-500/20'}`}>
                        • {alert.status}
                      </span>
                    </td>

                    {/* Created */}
                    <td className="py-3.5 px-4 text-guardian-muted font-mono text-[11px]">
                      {formatTimeAgo(alert.last_detected_at)}
                    </td>

                    {/* Actions */}
                    <td className="py-3.5 px-5 text-right">
                      <div className="flex items-center justify-end gap-1">
                        {alert.status !== 'RESOLVED' && (
                          <button
                            onClick={() => setAlertToResolve(alert)}
                            title="Resolve Alert"
                            className="p-1.5 rounded text-guardian-muted hover:text-emerald-500 transition-colors cursor-pointer"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Custom Pagination */}
        {alertsList.length > 0 && (
          <div className="px-5 py-3 border-t border-guardian-border flex items-center justify-between text-xs text-guardian-muted">
            <div>
              Showing 1 to {paginatedAlerts.length} of {alertsList.length} results
            </div>

            <div className="flex items-center gap-1 font-mono">
              <button
                disabled={page <= 1}
                onClick={() => setPage(page - 1)}
                className="p-1.5 rounded text-guardian-muted hover:text-guardian-text disabled:opacity-40 cursor-pointer"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-3 py-1 rounded font-bold bg-brand-600 text-white">
                Page {page} of {totalPages}
              </span>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage(page + 1)}
                className="p-1.5 rounded text-guardian-muted hover:text-guardian-text disabled:opacity-40 cursor-pointer"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </Card>

      {/* Resolve Dialog */}
      <ConfirmationDialog
        isOpen={!!alertToResolve}
        onClose={() => setAlertToResolve(null)}
        onConfirm={handleConfirmResolve}
        isLoading={resolveMutation.isPending}
        title="Mark Alert as Resolved?"
        message={`Are you sure you want to resolve alert "${alertToResolve?.title}"?`}
        confirmLabel="Resolve Alert"
      />
    </div>
  );
};
