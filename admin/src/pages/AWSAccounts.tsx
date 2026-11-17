import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Search,
  Cloud,
  Eye,
  RefreshCw,
  Filter,
  Copy,
  Check,
  ShieldCheck,
} from 'lucide-react';
import { useAWSAccounts } from '../hooks/useAWSAccounts';
import { Card, CardContent } from '../components/common/Card';
import { AccountStatusBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { Pagination } from '../components/tables/Pagination';
import { formatTimeAgo } from '../utils/cn';

export const AWSAccounts: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [statusFilter, setStatusFilter] = useState(searchParams.get('status') || 'all');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const navigate = useNavigate();

  const { data, isLoading, refetch, isRefetching } = useAWSAccounts({
    search: search.trim() || undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    setSearchParams((prev) => {
      if (search) prev.set('search', search);
      else prev.delete('search');
      return prev;
    });
  };

  const accountsList = data?.accounts || [];
  const paginatedAccounts = accountsList.slice((page - 1) * pageSize, page * pageSize);

  const connectedCount = accountsList.filter((a) => a.status === 'CONNECTED').length;
  const disconnectedCount = accountsList.filter((a) => a.status === 'DISCONNECTED').length;
  const errorCount = accountsList.filter((a) => a.status === 'ERROR' || a.status === 'VERIFICATION_FAILED').length;

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-guardian-text tracking-tight">AWS Accounts</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Connected cloud accounts, IAM AssumeRole verification status, and regional coverage.
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
          <span className="text-[11px] font-semibold text-guardian-muted">Total Accounts</span>
          <div className="text-xl font-bold text-guardian-text font-mono">{accountsList.length}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-emerald-400">Connected & Verified</span>
          <div className="text-xl font-bold text-emerald-400 font-mono">{connectedCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-guardian-muted">Disconnected</span>
          <div className="text-xl font-bold text-guardian-muted font-mono">{disconnectedCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-red-400">STS Error</span>
          <div className="text-xl font-bold text-red-400 font-mono">{errorCount}</div>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-3 flex flex-col md:flex-row items-center justify-between gap-3">
          {/* Search Form */}
          <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative flex items-center">
            <Search className="w-4 h-4 text-guardian-muted absolute left-3 pointer-events-none" />
            <input
              type="text"
              placeholder="Search account name, 12-digit ID, or user..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-lg border border-guardian-border pl-9 pr-3 py-1.5 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500/30"
            />
          </form>

          {/* Status Tabs */}
          <div className="flex items-center gap-1.5 w-full md:w-auto overflow-x-auto pb-1 md:pb-0">
            <span className="text-xs text-guardian-muted flex items-center gap-1 mr-1">
              <Filter className="w-3.5 h-3.5" /> Status:
            </span>
            {['all', 'connected', 'disconnected', 'error', 'pending'].map((st) => (
              <button
                key={st}
                onClick={() => {
                  setStatusFilter(st);
                  setPage(1);
                  setSearchParams((prev) => {
                    if (st !== 'all') prev.set('status', st);
                    else prev.delete('status');
                    return prev;
                  });
                }}
                className={`px-2.5 py-1 text-xs font-semibold rounded-md uppercase transition-colors ${
                  statusFilter === st
                    ? 'bg-brand-600 text-white shadow-sm'
                    : 'bg-guardian-bg hover:bg-white/5 text-guardian-muted hover:text-guardian-text border border-guardian-border'
                }`}
              >
                {st}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* AWS Accounts Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border bg-guardian-bg/40 text-guardian-muted font-bold text-[10px] uppercase tracking-wider">
                <th className="py-3 px-4">Account Name</th>
                <th className="py-3 px-3">AWS Account ID</th>
                <th className="py-3 px-3">Owner User</th>
                <th className="py-3 px-3">IAM Role ARN</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-3 text-center">Resources</th>
                <th className="py-3 px-3 text-center">Alerts</th>
                <th className="py-3 px-3">Last Scanned</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={9} className="p-0">
                    <TableSkeleton rows={5} cols={9} />
                  </td>
                </tr>
              ) : paginatedAccounts.length === 0 ? (
                <tr>
                  <td colSpan={9} className="p-0">
                    <EmptyState
                      icon={<Cloud className="w-6 h-6" />}
                      title="No AWS accounts found"
                      description="No cloud accounts connected yet. Users connect AWS accounts securely via IAM STS AssumeRole in the mobile application."
                    />
                  </td>
                </tr>
              ) : (
                paginatedAccounts.map((account) => (
                  <tr key={account.id} className="hover:bg-white/5 transition-colors group">
                    {/* Account Name */}
                    <td className="py-3 px-4">
                      <div className="font-semibold text-guardian-text hover:text-brand-400 transition-colors cursor-pointer" onClick={() => navigate(`/admin/aws-accounts/${account.id}`)}>
                        {account.name}
                      </div>
                      <div className="text-[10px] text-guardian-muted truncate max-w-40">{account.enabled_regions?.join(', ') || 'All Regions'}</div>
                    </td>

                    {/* AWS Account ID */}
                    <td className="py-3 px-3">
                      <div className="flex items-center gap-1.5 font-mono text-guardian-text text-[11px]">
                        <span>{account.account_id}</span>
                        <button
                          onClick={() => copyToClipboard(account.account_id, `acc-${account.id}`)}
                          className="text-guardian-muted hover:text-brand-400"
                          title="Copy ID"
                        >
                          {copiedId === `acc-${account.id}` ? (
                            <Check className="w-3 h-3 text-emerald-400" />
                          ) : (
                            <Copy className="w-3 h-3" />
                          )}
                        </button>
                      </div>
                    </td>

                    {/* Owner */}
                    <td className="py-3 px-3">
                      <div className="font-medium text-guardian-text">{account.user_name}</div>
                      <div className="text-[10px] text-guardian-muted font-mono">{account.user_email}</div>
                    </td>

                    {/* Role ARN */}
                    <td className="py-3 px-3 font-mono text-guardian-muted max-w-50 truncate text-[11px]" title={account.role_arn}>
                      {account.role_arn}
                    </td>

                    {/* Status */}
                    <td className="py-3 px-3">
                      <AccountStatusBadge status={account.status} />
                    </td>

                    {/* Resources */}
                    <td className="py-3 px-3 text-center font-semibold font-mono">
                      <span className="px-2 py-0.5 rounded bg-guardian-bg border border-guardian-border">
                        {account.resources_count}
                      </span>
                    </td>

                    {/* Alerts */}
                    <td className="py-3 px-3 text-center font-semibold font-mono">
                      {account.alerts_count > 0 ? (
                        <span className="px-2 py-0.5 rounded bg-amber-500/15 text-amber-400 border border-amber-500/30">
                          {account.alerts_count}
                        </span>
                      ) : (
                        <span className="text-guardian-dimmed">—</span>
                      )}
                    </td>

                    {/* Last Scanned */}
                    <td className="py-3 px-3 text-guardian-muted font-mono text-[11px]">
                      {account.last_scan_at ? formatTimeAgo(account.last_scan_at) : 'Never'}
                    </td>

                    {/* Actions */}
                    <td className="py-3 px-4 text-right">
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={() => navigate(`/admin/aws-accounts/${account.id}`)}
                        className="h-7 text-xs"
                      >
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
          totalItems={accountsList.length}
          pageSize={pageSize}
          onPageChange={setPage}
        />
      </Card>
    </div>
  );
};
