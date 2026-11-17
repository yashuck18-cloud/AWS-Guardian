import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Users,
  Cloud,
  Layers,
  AlertTriangle,
  ScanLine,
  FileText,
  UserCheck,
  UserX,
  Trash2,
  Mail,
  Calendar,
  Clock,
  Send,
  ArrowLeft,
} from 'lucide-react';
import { useUserDetail, useToggleUserStatus, useDeleteUser } from '../hooks/useUsers';
import { Breadcrumbs } from '../components/common/Breadcrumbs';
import { Card, CardHeader, CardTitle, CardContent } from '../components/common/Card';
import { Badge, SeverityBadge, AccountStatusBadge, RiskBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { Skeleton, TableSkeleton } from '../components/common/Skeleton';
import { EmptyState, ConfirmationDialog } from '../components/common/EmptyState';
import { formatDate, formatDateTime, formatTimeAgo } from '../utils/cn';

export const UserDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [activeTab, setActiveTab] = useState<'overview' | 'accounts' | 'resources' | 'alerts' | 'scans' | 'audit'>('overview');
  const [toggleOpen, setToggleOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const navigate = useNavigate();
  const { data, isLoading, refetch } = useUserDetail(id || '');
  const toggleMutation = useToggleUserStatus();
  const deleteMutation = useDeleteUser();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-36 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  const user = data?.user;
  if (!user) {
    return (
      <div className="py-12">
        <EmptyState
          title="User not found"
          description="The requested user does not exist or has been deleted."
          action={{ label: 'Back to Users', onClick: () => navigate('/admin/users') }}
        />
      </div>
    );
  }

  const accounts = data?.user?.aws_accounts || [];
  const resources = data?.resources || [];
  const alerts = data?.alerts || [];
  const scans = data?.scans || [];
  const auditLogs = data?.audit_logs || [];
  const stats = user.stats;

  const handleToggle = async () => {
    try {
      await toggleMutation.mutateAsync(user.id);
      setToggleOpen(false);
      refetch();
    } catch {
      // ignore
    }
  };

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(user.id);
      setDeleteOpen(false);
      navigate('/admin/users');
    } catch {
      // ignore
    }
  };

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Users },
    { id: 'accounts', label: `AWS Accounts (${accounts.length})`, icon: Cloud },
    { id: 'resources', label: `Resources (${resources.length})`, icon: Layers },
    { id: 'alerts', label: `Alerts (${alerts.length})`, icon: AlertTriangle },
    { id: 'scans', label: `Scans (${scans.length})`, icon: ScanLine },
    { id: 'audit', label: `Audit Trail (${auditLogs.length})`, icon: FileText },
  ];

  return (
    <div className="space-y-6">
      {/* Breadcrumbs */}
      <Breadcrumbs
        items={[
          { label: 'Users', href: '/admin/users' },
          { label: user.name || user.email },
        ]}
      />

      {/* Header Profile Card */}
      <Card>
        <CardContent className="p-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div className="flex items-start gap-4">
              <div className="w-14 h-14 rounded-2xl bg-linear-to-tr from-primary to-primary-light flex items-center justify-center text-white font-extrabold text-xl shadow-lg shadow-primary/25 shrink-0">
                {user.name?.[0]?.toUpperCase() || 'U'}
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-2.5 flex-wrap">
                  <h1 className="text-xl font-bold text-guardian-text">{user.name}</h1>
                  {user.is_staff && <Badge variant="purple">Admin</Badge>}
                  {user.is_active ? (
                    <Badge variant="success" dot>Active</Badge>
                  ) : (
                    <Badge variant="critical" dot>Suspended</Badge>
                  )}
                </div>
                <div className="flex items-center gap-4 text-xs text-guardian-muted flex-wrap">
                  <span className="flex items-center gap-1 font-mono text-guardian-text">
                    <Mail className="w-3.5 h-3.5 text-primary-light" /> {user.email}
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" /> Joined {formatDate(user.created_at)}
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" /> Last login {user.last_login ? formatTimeAgo(user.last_login) : 'Never'}
                  </span>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2.5 self-start md:self-center">
              <Button
                variant={user.is_active ? 'secondary' : 'primary'}
                size="sm"
                onClick={() => setToggleOpen(true)}
              >
                {user.is_active ? <UserX className="w-3.5 h-3.5" /> : <UserCheck className="w-3.5 h-3.5" />}
                <span>{user.is_active ? 'Suspend User' : 'Activate User'}</span>
              </Button>

              <Button variant="danger" size="sm" onClick={() => setDeleteOpen(true)}>
                <Trash2 className="w-3.5 h-3.5" />
                <span>Delete</span>
              </Button>
            </div>
          </div>

          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mt-6 pt-6 border-t border-guardian-border">
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">AWS Accounts</span>
              <div className="text-lg font-bold text-guardian-text">{stats?.accounts_count ?? 0}</div>
            </div>
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">Resources Monitored</span>
              <div className="text-lg font-bold text-guardian-text">{stats?.resources_count ?? 0}</div>
            </div>
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">Active Alerts</span>
              <div className="text-lg font-bold text-guardian-warning">{stats?.active_alerts_count ?? 0}</div>
            </div>
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">Resolved Alerts</span>
              <div className="text-lg font-bold text-guardian-success">{stats?.resolved_alerts_count ?? 0}</div>
            </div>
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">Total Scans</span>
              <div className="text-lg font-bold text-guardian-text">{stats?.total_scans_count ?? 0}</div>
            </div>
            <div className="bg-guardian-bg p-3 rounded-lg border border-guardian-border space-y-1">
              <span className="text-[11px] text-guardian-muted font-medium">Notifications</span>
              <div className="text-lg font-bold text-guardian-text">{stats?.notifications_count ?? 0}</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs Navigation */}
      <div className="flex items-center gap-2 border-b border-guardian-border pb-px overflow-x-auto">
        {tabs.map((t) => {
          const Icon = t.icon;
          const isActive = activeTab === t.id;
          return (
            <button
              key={t.id}
              onClick={() => setActiveTab(t.id as any)}
              className={`flex items-center gap-2 px-4 py-2.5 text-xs font-semibold border-b-2 transition-all whitespace-nowrap ${
                isActive
                  ? 'border-primary-light text-primary-light bg-primary/5 rounded-t-lg'
                  : 'border-transparent text-guardian-muted hover:text-guardian-text'
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{t.label}</span>
            </button>
          );
        })}
      </div>

      {/* Tab 1: Overview */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Scanning Threshold Preferences</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3.5 text-xs">
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">Automated Scan Frequency</span>
                <span className="font-semibold text-guardian-text">Every {user.scan_interval_hours} hours</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">EC2 Idle Threshold</span>
                <span className="font-semibold text-guardian-text">{user.ec2_threshold_hours} hours</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">EBS Unattached Threshold</span>
                <span className="font-semibold text-guardian-text">{user.ebs_threshold_hours} hours</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-guardian-muted">App Theme Mode</span>
                <span className="font-semibold text-guardian-text capitalize">{user.theme_preference}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Notification Channels</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3.5 text-xs">
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">Morning Fleet Summary (09:00)</span>
                <Badge variant={user.notification_settings?.morning_summary_enabled ? 'success' : 'muted'}>
                  {user.notification_settings?.morning_summary_enabled ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">Evening Summary (19:00)</span>
                <Badge variant={user.notification_settings?.evening_summary_enabled ? 'success' : 'muted'}>
                  {user.notification_settings?.evening_summary_enabled ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>
              <div className="flex justify-between py-1.5 border-b border-guardian-border">
                <span className="text-guardian-muted">Critical Alert Dispatch</span>
                <Badge variant={user.notification_settings?.urgent_alerts_enabled ? 'success' : 'muted'}>
                  {user.notification_settings?.urgent_alerts_enabled ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-guardian-muted">Telegram Delivery</span>
                <Badge variant={user.notification_settings?.telegram_enabled ? 'info' : 'muted'}>
                  {user.notification_settings?.telegram_enabled ? `Active (ID: ${user.notification_settings.telegram_chat_id})` : 'Not Configured'}
                </Badge>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Tab 2: AWS Accounts */}
      {activeTab === 'accounts' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">Account Name</th>
                  <th className="py-3.5 px-4">AWS Account ID</th>
                  <th className="py-3.5 px-4">Role ARN</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4">Last Scanned</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {accounts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-0">
                      <EmptyState title="No AWS accounts connected" description="This user has not connected any AWS accounts yet." />
                    </td>
                  </tr>
                ) : (
                  accounts.map((acc) => (
                    <tr key={acc.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5 font-semibold">{acc.name}</td>
                      <td className="py-3.5 px-4 font-mono">{acc.account_id}</td>
                      <td className="py-3.5 px-4 font-mono text-guardian-muted max-w-50 truncate">{acc.role_arn}</td>
                      <td className="py-3.5 px-4"><AccountStatusBadge status={acc.status} /></td>
                      <td className="py-3.5 px-4 text-guardian-muted">{acc.last_scan_at ? formatTimeAgo(acc.last_scan_at) : 'Never'}</td>
                      <td className="py-3.5 px-5 text-right">
                        <Button variant="secondary" size="sm" onClick={() => navigate(`/admin/aws-accounts/${acc.id}`)}>
                          Inspect
                        </Button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Tab 3: Resources */}
      {activeTab === 'resources' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">Service</th>
                  <th className="py-3.5 px-4">Resource ID</th>
                  <th className="py-3.5 px-4">Name</th>
                  <th className="py-3.5 px-4">Region</th>
                  <th className="py-3.5 px-4">Risk Level</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {resources.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-0">
                      <EmptyState title="No resources detected" description="No cloud resources cataloged under this user's accounts." />
                    </td>
                  </tr>
                ) : (
                  resources.map((res) => (
                    <tr key={res.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5 font-semibold text-primary-light">{res.service}</td>
                      <td className="py-3.5 px-4 font-mono">{res.resource_id}</td>
                      <td className="py-3.5 px-4 text-guardian-muted">{res.resource_name || '—'}</td>
                      <td className="py-3.5 px-4 font-mono">{res.region}</td>
                      <td className="py-3.5 px-4"><RiskBadge risk={res.risk_level} /></td>
                      <td className="py-3.5 px-4"><Badge variant="muted">{res.status}</Badge></td>
                      <td className="py-3.5 px-5 text-right">
                        <Button variant="secondary" size="sm" onClick={() => navigate(`/admin/resources/${res.id}`)}>
                          Inspect
                        </Button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Tab 4: Alerts */}
      {activeTab === 'alerts' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">Severity</th>
                  <th className="py-3.5 px-4">Finding Title</th>
                  <th className="py-3.5 px-4">Rule Code</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4">Detected</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {alerts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-0">
                      <EmptyState title="No alerts found" description="Zero active security or idle resource alerts." />
                    </td>
                  </tr>
                ) : (
                  alerts.map((al) => (
                    <tr key={al.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5"><SeverityBadge severity={al.severity} /></td>
                      <td className="py-3.5 px-4 font-semibold">{al.title}</td>
                      <td className="py-3.5 px-4 font-mono text-guardian-muted">{al.rule_code}</td>
                      <td className="py-3.5 px-4">
                        <Badge variant={al.status === 'RESOLVED' ? 'success' : 'warning'}>{al.status}</Badge>
                      </td>
                      <td className="py-3.5 px-4 text-guardian-muted">{formatTimeAgo(al.last_detected_at)}</td>
                      <td className="py-3.5 px-5 text-right">
                        <Button variant="secondary" size="sm" onClick={() => navigate(`/admin/alerts/${al.id}`)}>
                          Inspect
                        </Button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Tab 5: Scans */}
      {activeTab === 'scans' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">AWS Account</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4 text-center">Resources Found</th>
                  <th className="py-3.5 px-4 text-center">Alerts Generated</th>
                  <th className="py-3.5 px-4">Started</th>
                  <th className="py-3.5 px-5 text-right">Duration</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {scans.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-0">
                      <EmptyState title="No scan runs recorded" description="No STS AssumeRole scans executed for this user yet." />
                    </td>
                  </tr>
                ) : (
                  scans.map((sc) => (
                    <tr key={sc.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5 font-semibold">{sc.account_name}</td>
                      <td className="py-3.5 px-4">
                        <Badge variant={sc.status === 'COMPLETED' ? 'success' : sc.status === 'FAILED' ? 'critical' : 'warning'}>
                          {sc.status}
                        </Badge>
                      </td>
                      <td className="py-3.5 px-4 text-center font-mono">{sc.resources_found}</td>
                      <td className="py-3.5 px-4 text-center font-mono">{sc.alerts_generated}</td>
                      <td className="py-3.5 px-4 text-guardian-muted">{formatDateTime(sc.started_at)}</td>
                      <td className="py-3.5 px-5 text-right text-guardian-muted">
                        {sc.completed_at ? formatTimeAgo(sc.completed_at) : 'In Progress'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Tab 6: Audit Logs */}
      {activeTab === 'audit' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">Timestamp</th>
                  <th className="py-3.5 px-4">Action</th>
                  <th className="py-3.5 px-4">IP Address</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-5">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {auditLogs.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-0">
                      <EmptyState title="No audit events" description="No activity logged for this user." />
                    </td>
                  </tr>
                ) : (
                  auditLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5 text-guardian-muted font-mono">{formatDateTime(log.timestamp)}</td>
                      <td className="py-3.5 px-4 font-mono font-semibold text-primary-light">{log.action}</td>
                      <td className="py-3.5 px-4 font-mono text-guardian-muted">{log.ip_address}</td>
                      <td className="py-3.5 px-4">
                        <Badge variant={log.status === 'SUCCESS' ? 'success' : 'critical'}>{log.status}</Badge>
                      </td>
                      <td className="py-3.5 px-5 font-mono text-[11px] text-guardian-muted max-w-xs truncate">
                        {JSON.stringify(log.details)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Confirm Suspend Modal */}
      <ConfirmationDialog
        isOpen={toggleOpen}
        onClose={() => setToggleOpen(false)}
        onConfirm={handleToggle}
        isLoading={toggleMutation.isPending}
        title={user.is_active ? 'Suspend User?' : 'Reactivate User?'}
        message={
          user.is_active
            ? `Suspending "${user.email}" will immediately block their access to the AWS Guardian mobile and web services.`
            : `Reactivating "${user.email}" will restore normal login privileges.`
        }
        confirmLabel={user.is_active ? 'Suspend User' : 'Reactivate'}
        isDanger={user.is_active}
      />

      {/* Confirm Delete Modal */}
      <ConfirmationDialog
        isOpen={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
        isLoading={deleteMutation.isPending}
        title="Permanently Delete User?"
        message={`Are you sure you want to permanently delete "${user.email}"? All associated AWS accounts and data will be destroyed.`}
        confirmLabel="Delete User"
        isDanger
      />
    </div>
  );
};
