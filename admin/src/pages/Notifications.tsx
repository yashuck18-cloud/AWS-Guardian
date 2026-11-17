import React, { useState } from 'react';
import {
  Search,
  Bell,
  RefreshCw,
  Filter,
  Send,
  Mail,
  Smartphone,
} from 'lucide-react';
import { useNotifications } from '../hooks/useNotifications';
import { Card, CardContent } from '../components/common/Card';
import { Badge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { Pagination } from '../components/tables/Pagination';
import { formatTimeAgo } from '../utils/cn';

export const Notifications: React.FC = () => {
  const [search, setSearch] = useState('');
  const [channelFilter, setChannelFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const { data, isLoading, refetch, isRefetching } = useNotifications({
    search: search.trim() || undefined,
    channel: channelFilter !== 'all' ? channelFilter : undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const notificationsList = data?.notifications || [];
  const paginatedNotifications = notificationsList.slice((page - 1) * pageSize, page * pageSize);

  const telegramCount = notificationsList.filter((n) => n.channel === 'TELEGRAM').length;
  const emailCount = notificationsList.filter((n) => n.channel === 'EMAIL').length;
  const sentCount = notificationsList.filter((n) => n.status === 'SENT').length;

  const channels = ['all', 'TELEGRAM', 'EMAIL', 'PUSH', 'IN_APP'];
  const statuses = ['all', 'SENT', 'FAILED', 'PENDING'];

  const getChannelIcon = (ch: string) => {
    switch (ch.toUpperCase()) {
      case 'TELEGRAM':
        return <Send className="w-3.5 h-3.5 text-sky-400" />;
      case 'EMAIL':
        return <Mail className="w-3.5 h-3.5 text-amber-400" />;
      default:
        return <Smartphone className="w-3.5 h-3.5 text-primary-light" />;
    }
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-guardian-text tracking-tight">Notifications Log</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Audit history of dispatch events delivered via Telegram, Email, and Push notification channels.
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
          <span className="text-[11px] font-semibold text-guardian-muted">Total Dispatched</span>
          <div className="text-xl font-bold text-guardian-text font-mono">{notificationsList.length}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-sky-400">Telegram Bot</span>
          <div className="text-xl font-bold text-sky-400 font-mono">{telegramCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-amber-400">Email Alerts</span>
          <div className="text-xl font-bold text-amber-400 font-mono">{emailCount}</div>
        </div>
        <div className="p-3 rounded-lg bg-guardian-card border border-guardian-border space-y-0.5">
          <span className="text-[11px] font-semibold text-emerald-400">Delivered (200 OK)</span>
          <div className="text-xl font-bold text-emerald-400 font-mono">{sentCount}</div>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-3 space-y-2.5">
          <div className="flex flex-col md:flex-row items-center justify-between gap-3">
            {/* Search */}
            <div className="w-full md:w-80 relative flex items-center">
              <Search className="w-4 h-4 text-guardian-muted absolute left-3 pointer-events-none" />
              <input
                type="text"
                placeholder="Search recipient or message text..."
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-lg border border-guardian-border pl-9 pr-3 py-1.5 focus:outline-none focus:border-primary-light focus:ring-1 focus:ring-primary-light/30"
              />
            </div>

            {/* Channel Tabs */}
            <div className="flex items-center gap-1.5 w-full md:w-auto overflow-x-auto pb-1 md:pb-0">
              <span className="text-xs text-guardian-muted flex items-center gap-1 mr-1">
                <Filter className="w-3.5 h-3.5" /> Channel:
              </span>
              {channels.map((ch) => (
                <button
                  key={ch}
                  onClick={() => {
                    setChannelFilter(ch);
                    setPage(1);
                  }}
                  className={`px-2.5 py-0.5 text-xs font-semibold rounded-md uppercase transition-colors ${
                    channelFilter === ch
                      ? 'bg-primary text-white shadow-sm'
                      : 'bg-guardian-bg hover:bg-white/5 text-guardian-muted hover:text-guardian-text border border-guardian-border'
                  }`}
                >
                  {ch}
                </button>
              ))}
            </div>
          </div>

          {/* Status Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto pt-2 border-t border-guardian-border">
            <span className="text-xs text-guardian-muted mr-1">Status:</span>
            {statuses.map((st) => (
              <button
                key={st}
                onClick={() => {
                  setStatusFilter(st);
                  setPage(1);
                }}
                className={`px-2.5 py-0.5 text-xs font-semibold rounded-md uppercase transition-colors ${
                  statusFilter === st
                    ? 'bg-primary/20 text-primary-light border border-primary/40'
                    : 'bg-white/5 text-guardian-muted hover:text-guardian-text border border-transparent'
                }`}
              >
                {st}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Notifications Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border bg-guardian-bg/40 text-guardian-muted font-bold text-[10px] uppercase tracking-wider">
                <th className="py-3 px-4">Recipient User</th>
                <th className="py-3 px-3">Channel</th>
                <th className="py-3 px-3">Subject / Title</th>
                <th className="py-3 px-3">Message Content</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-4 text-right">Dispatched</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="p-0">
                    <TableSkeleton rows={5} cols={6} />
                  </td>
                </tr>
              ) : paginatedNotifications.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-0">
                    <EmptyState
                      icon={<Bell className="w-6 h-6" />}
                      title="No notification records found"
                      description="No alerts or summary digests have been dispatched through notification channels yet."
                    />
                  </td>
                </tr>
              ) : (
                paginatedNotifications.map((notif) => (
                  <tr key={notif.id} className="hover:bg-white/5 transition-colors group">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-guardian-text">{notif.user_name}</div>
                      <div className="text-[10px] text-guardian-muted font-mono">{notif.user_email}</div>
                    </td>

                    <td className="py-3 px-3">
                      <div className="flex items-center gap-1.5 font-semibold text-guardian-text">
                        {getChannelIcon(notif.channel)}
                        <span>{notif.channel}</span>
                      </div>
                    </td>

                    <td className="py-3 px-3 font-semibold text-guardian-text max-w-50 truncate">
                      {notif.title}
                    </td>

                    <td className="py-3 px-3 text-guardian-muted max-w-sm truncate" title={notif.message}>
                      {notif.message}
                    </td>

                    <td className="py-3 px-3">
                      <Badge
                        variant={
                          notif.status === 'SENT'
                            ? 'success'
                            : notif.status === 'FAILED'
                            ? 'critical'
                            : 'warning'
                        }
                        dot
                      >
                        {notif.status}
                      </Badge>
                    </td>

                    <td className="py-3 px-4 text-right text-guardian-muted font-mono text-[11px]">
                      {formatTimeAgo(notif.created_at)}
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
          totalItems={notificationsList.length}
          pageSize={pageSize}
          onPageChange={setPage}
        />
      </Card>
    </div>
  );
};
