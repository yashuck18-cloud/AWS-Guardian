import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Users,
  Cloud,
  Layers,
  AlertTriangle,
  ScanLine,
  Send,
  RefreshCw,
  Server,
  CheckCircle,
} from 'lucide-react';
import { ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, XAxis, YAxis, Tooltip } from 'recharts';
import { useDashboard } from '../hooks/useDashboard';
import { useAnalytics } from '../hooks/useAnalytics';
import { useAWSAccounts } from '../hooks/useAWSAccounts';
import { useAlerts } from '../hooks/useAlerts';
import { Card, CardContent } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Skeleton } from '../components/common/Skeleton';
import { formatTimeAgo } from '../utils/cn';

export const Dashboard: React.FC = () => {
  const [timeframe, setTimeframe] = useState('7D');
  const navigate = useNavigate();

  const { data: dashboardData, isLoading: dashLoading, refetch: refetchDash, isRefetching } = useDashboard();
  const { data: analyticsData } = useAnalytics('30d');
  const { data: accountsData } = useAWSAccounts();
  const { data: alertsData } = useAlerts({ status: 'ACTIVE' });

  const stats = dashboardData?.stats;
  const accountsList = accountsData?.accounts || [];
  const activeAlertsList = alertsData?.alerts || [];

  // Strictly real chart series from Django backend API
  const growthSeries = analyticsData?.growth_series || [];
  const activityData = growthSeries.map((d) => ({
    date: d.date,
    users: d.users,
    scans: d.scans,
    alerts: d.alerts,
  }));

  // Real severity count breakdown from Django REST API backend
  const critCount = stats?.critical_alerts ?? 0;
  const highCount = stats?.high_alerts ?? 0;
  const medCount = stats?.medium_alerts ?? 0;
  const lowCount = stats?.low_alerts ?? 0;
  const totalAlertsCount = stats?.active_alerts ?? (critCount + highCount + medCount + lowCount);

  const pieData = [
    { name: 'Critical', value: critCount, color: '#EF4444', percent: `${totalAlertsCount > 0 ? Math.round((critCount / totalAlertsCount) * 100) : 0}%` },
    { name: 'High', value: highCount, color: '#F97316', percent: `${totalAlertsCount > 0 ? Math.round((highCount / totalAlertsCount) * 100) : 0}%` },
    { name: 'Medium', value: medCount, color: '#EAB308', percent: `${totalAlertsCount > 0 ? Math.round((medCount / totalAlertsCount) * 100) : 0}%` },
    { name: 'Low', value: lowCount, color: '#3B82F6', percent: `${totalAlertsCount > 0 ? Math.round((lowCount / totalAlertsCount) * 100) : 0}%` },
  ];

  return (
    <div className="space-y-5 sm:space-y-6">
      {/* 1. Header Row */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-extrabold text-guardian-text tracking-tight">Executive Dashboard</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Real-time security telemetry & AWS infrastructure monitoring
          </p>
        </div>

        <Button
          variant="outline"
          size="sm"
          onClick={() => refetchDash()}
          isLoading={isRefetching}
          className="h-9 text-xs bg-guardian-card/80 backdrop-blur-md border-guardian-border text-guardian-text hover:bg-guardian-cardElevated cursor-pointer shrink-0 self-start sm:self-auto"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
          <span>Refresh Live Data</span>
        </Button>
      </div>

      {/* 2. Top 6 Real KPI Stat Cards Grid - Fully Responsive */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-3.5">
        {/* Card 1: Total Users */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">Total Users</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-16" /> : (stats?.total_users ?? 0)}
            </div>
            <div className="text-[11px] text-purple-400 font-medium mt-1">+{stats?.new_users_30d ?? 0} new (30d)</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <Users className="w-5 h-5" />
          </div>
        </div>

        {/* Card 2: AWS Accounts */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">AWS Accounts</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-12" /> : (stats?.total_accounts ?? 0)}
            </div>
            <div className="text-[11px] text-sky-400 font-medium mt-1">+{stats?.connected_accounts ?? 0} connected</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-sky-500/10 border border-sky-500/20 text-sky-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <Cloud className="w-5 h-5" />
          </div>
        </div>

        {/* Card 3: Resources */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">Resources</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-20" /> : (stats?.total_resources ?? 0)}
            </div>
            <div className="text-[11px] text-emerald-400 font-medium mt-1">Catalog items</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <Layers className="w-5 h-5" />
          </div>
        </div>

        {/* Card 4: Active Alerts */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">Active Alerts</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-12" /> : (stats?.active_alerts ?? 0)}
            </div>
            <div className="text-[11px] text-rose-400 font-medium mt-1">{stats?.critical_alerts ?? 0} critical</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <AlertTriangle className="w-5 h-5" />
          </div>
        </div>

        {/* Card 5: Scans Today */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">Scans Today</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-12" /> : (stats?.scans_today ?? 0)}
            </div>
            <div className="text-[11px] text-amber-400 font-medium mt-1">STS AssumeRole</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <ScanLine className="w-5 h-5" />
          </div>
        </div>

        {/* Card 6: Notifications */}
        <div className="p-4 rounded-2xl admin-card flex flex-col justify-between h-32 relative overflow-hidden group">
          <div className="relative z-10">
            <span className="text-xs text-guardian-muted font-semibold">Notifications</span>
            <div className="text-2xl font-bold text-guardian-text mt-1 font-mono tracking-tight">
              {dashLoading ? <Skeleton className="h-7 w-12" /> : (stats?.notifications_sent ?? 0)}
            </div>
            <div className="text-[11px] text-cyan-400 font-medium mt-1">Dispatched</div>
          </div>
          <div className="w-9 h-9 rounded-xl bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 flex items-center justify-center absolute bottom-3.5 right-3.5 group-hover:scale-110 transition-transform">
            <Send className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* 3. Middle Row: Platform Activity & Alerts by Severity Donut */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left: Platform Activity Chart (8 cols) */}
        <Card className="lg:col-span-8">
          <div className="px-5 py-4 border-b border-guardian-border flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <h3 className="text-sm font-bold text-guardian-text">Platform Activity</h3>
            <div className="flex items-center gap-1 bg-guardian-bg/80 p-0.5 rounded-xl border border-guardian-border self-start sm:self-auto">
              {['7D', '30D', '90D', '1Y'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setTimeframe(tab)}
                  className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                    timeframe === tab
                      ? 'bg-brand-600 text-white shadow-xs'
                      : 'text-guardian-muted hover:text-guardian-text'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>
          <CardContent className="p-4 sm:p-5">
            {activityData.length === 0 ? (
              <div className="h-64 flex flex-col items-center justify-center text-guardian-muted text-xs">
                No activity data recorded yet for the selected timeframe.
              </div>
            ) : (
              <>
                <div className="flex items-center justify-center gap-4 sm:gap-6 mb-4 text-xs font-medium text-guardian-muted flex-wrap">
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-1 rounded-full bg-purple-500" />
                    <span>Users</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-1 rounded-full bg-sky-400" />
                    <span>Scans</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-1 rounded-full bg-rose-500" />
                    <span>Alerts</span>
                  </div>
                </div>

                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={activityData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <XAxis dataKey="date" stroke="#64748B" fontSize={11} tickLine={false} axisLine={false} />
                      <YAxis stroke="#64748B" fontSize={11} tickLine={false} axisLine={false} />
                      <Tooltip
                        contentStyle={{ backgroundColor: 'var(--bg-card)', borderColor: 'var(--border-color)', borderRadius: '12px', color: 'var(--text-primary)', backdropFilter: 'blur(16px)' }}
                      />
                      <Line type="monotone" dataKey="users" stroke="#A855F7" strokeWidth={2.5} dot={{ r: 3.5, fill: '#A855F7' }} />
                      <Line type="monotone" dataKey="scans" stroke="#38BDF8" strokeWidth={2.5} dot={{ r: 3.5, fill: '#38BDF8' }} />
                      <Line type="monotone" dataKey="alerts" stroke="#EF4444" strokeWidth={2.5} dot={{ r: 3.5, fill: '#EF4444' }} />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Right: Alerts by Severity Donut (4 cols) */}
        <Card className="lg:col-span-4 flex flex-col justify-between">
          <div className="px-5 py-4 border-b border-guardian-border">
            <h3 className="text-sm font-bold text-guardian-text">Alerts by Severity</h3>
          </div>
          <CardContent className="p-4 sm:p-5 flex flex-col items-center justify-center">
            <div className="relative w-44 h-44 flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={75}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} stroke="var(--bg-card)" strokeWidth={2} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute flex flex-col items-center justify-center text-center">
                <span className="text-2xl font-bold text-guardian-text font-mono">{totalAlertsCount}</span>
                <span className="text-[10px] text-guardian-muted uppercase tracking-wider font-semibold">Total</span>
              </div>
            </div>

            {/* Severity Legend List */}
            <div className="w-full space-y-2 mt-4 text-xs font-medium">
              {pieData.map((item) => (
                <div key={item.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                    <span className="text-guardian-muted">{item.name}</span>
                  </div>
                  <div className="font-mono text-guardian-muted">
                    <span className="font-bold text-guardian-text mr-1">{item.value}</span> ({item.percent})
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 4. Bottom Row: Recent Alerts & AWS Accounts Status */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left: Recent Alerts List (6 cols) */}
        <Card className="lg:col-span-6">
          <div className="px-5 py-4 border-b border-guardian-border flex items-center justify-between">
            <h3 className="text-sm font-bold text-guardian-text">Recent Alerts</h3>
            <Link to="/admin/alerts" className="text-xs font-semibold text-brand-500 hover:text-brand-600 transition-colors">
              View all
            </Link>
          </div>
          <CardContent className="p-0 divide-y divide-guardian-border">
            {activeAlertsList.length > 0 ? (
              activeAlertsList.slice(0, 4).map((alert) => (
                <div
                  key={alert.id}
                  onClick={() => navigate(`/admin/alerts/${alert.id}`)}
                  className="p-4 flex items-center justify-between hover:bg-guardian-cardElevated transition-colors cursor-pointer gap-2"
                >
                  <div className="flex items-center gap-3 truncate min-w-0">
                    <div className="w-9 h-9 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-500 flex items-center justify-center shrink-0">
                      <AlertTriangle className="w-4.5 h-4.5" />
                    </div>
                    <div className="truncate min-w-0">
                      <div className="text-xs font-bold text-guardian-text truncate">{alert.title}</div>
                      <div className="text-[11px] text-guardian-muted font-mono mt-0.5 truncate">
                        {alert.resource_identifier || 'Asset'} • Account: {alert.account_aws_id || 'AWS'}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 sm:gap-3 shrink-0">
                    <span className="px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-400 border border-rose-500/30 text-[10px] font-bold">
                      • {alert.severity}
                    </span>
                    <span className="text-[11px] text-guardian-muted font-mono hidden sm:inline">{formatTimeAgo(alert.last_detected_at)}</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-6 text-center text-xs text-guardian-muted">
                <CheckCircle className="w-6 h-6 text-emerald-500 mx-auto mb-2 opacity-80" />
                No active security alerts recorded in backend database.
              </div>
            )}
          </CardContent>
        </Card>

        {/* Right: AWS Accounts Status List (6 cols) */}
        <Card className="lg:col-span-6">
          <div className="px-5 py-4 border-b border-guardian-border flex items-center justify-between">
            <h3 className="text-sm font-bold text-guardian-text">AWS Accounts Status</h3>
            <Link to="/admin/aws-accounts" className="text-xs font-semibold text-brand-500 hover:text-brand-600 transition-colors">
              View all
            </Link>
          </div>
          <CardContent className="p-0 divide-y divide-guardian-border">
            {accountsList.length > 0 ? (
              accountsList.slice(0, 4).map((acc) => (
                <div
                  key={acc.id}
                  onClick={() => navigate(`/admin/aws-accounts/${acc.id}`)}
                  className="p-4 flex items-center justify-between hover:bg-guardian-cardElevated transition-colors cursor-pointer gap-2"
                >
                  <div className="flex items-center gap-3 truncate min-w-0">
                    <div className="w-9 h-9 rounded-xl bg-guardian-cardElevated border border-guardian-border text-guardian-text flex items-center justify-center shrink-0">
                      <Server className="w-4.5 h-4.5" />
                    </div>
                    <div className="truncate min-w-0">
                      <div className="text-xs font-bold text-guardian-text font-mono truncate">{acc.account_id}</div>
                      <div className="text-[11px] text-guardian-muted mt-0.5 truncate">{acc.name}</div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 sm:gap-3 shrink-0">
                    <span className={`text-xs font-bold flex items-center gap-1 ${acc.status === 'CONNECTED' ? 'text-emerald-500' : 'text-amber-500'}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${acc.status === 'CONNECTED' ? 'bg-emerald-500' : 'bg-amber-500'}`} /> {acc.status}
                    </span>
                    <span className="text-[11px] text-guardian-muted font-mono hidden sm:inline">{formatTimeAgo(acc.last_scan_at)}</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-6 text-center text-xs text-guardian-muted">
                No AWS accounts connected yet in backend database.
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
