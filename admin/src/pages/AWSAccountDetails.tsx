import React, { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import {
  Cloud,
  Layers,
  AlertTriangle,
  ScanLine,
  Copy,
  Check,
  User,
  Shield,
  Clock,
  Calendar,
  Globe,
} from 'lucide-react';
import { useAWSAccountDetail } from '../hooks/useAWSAccounts';
import { Breadcrumbs } from '../components/common/Breadcrumbs';
import { Card, CardHeader, CardTitle, CardContent } from '../components/common/Card';
import { Badge, SeverityBadge, AccountStatusBadge, RiskBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { Skeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { formatDate, formatDateTime, formatTimeAgo } from '../utils/cn';

export const AWSAccountDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [activeTab, setActiveTab] = useState<'resources' | 'alerts' | 'scans'>('resources');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const navigate = useNavigate();
  const { data, isLoading } = useAWSAccountDetail(id || '');

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-36 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  const account = data?.account;
  if (!account) {
    return (
      <div className="py-12">
        <EmptyState
          title="AWS Account not found"
          description="The requested AWS account could not be found."
          action={{ label: 'Back to AWS Accounts', onClick: () => navigate('/admin/aws-accounts') }}
        />
      </div>
    );
  }

  const resources = data?.resources || [];
  const alerts = data?.alerts || [];
  const scans = data?.scans || [];

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(label);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const tabs = [
    { id: 'resources', label: `Discovered Resources (${resources.length})`, icon: Layers },
    { id: 'alerts', label: `Active Alerts (${alerts.length})`, icon: AlertTriangle },
    { id: 'scans', label: `Scan Runs (${scans.length})`, icon: ScanLine },
  ];

  return (
    <div className="space-y-6">
      <Breadcrumbs
        items={[
          { label: 'AWS Accounts', href: '/admin/aws-accounts' },
          { label: account.name },
        ]}
      />

      {/* Account Info Card */}
      <Card>
        <CardContent className="p-6 space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-14 h-14 rounded-2xl bg-guardian-info/15 border border-guardian-info/30 text-guardian-info flex items-center justify-center font-extrabold text-xl shadow-lg shrink-0">
                <Cloud className="w-7 h-7" />
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-3 flex-wrap">
                  <h1 className="text-xl font-bold text-guardian-text">{account.name}</h1>
                  <AccountStatusBadge status={account.status} />
                </div>
                <div className="flex items-center gap-4 text-xs text-guardian-muted flex-wrap">
                  <span className="font-mono text-guardian-text">AWS ID: {account.account_id}</span>
                  <span className="flex items-center gap-1">
                    <User className="w-3.5 h-3.5 text-primary-light" />
                    Owner:{' '}
                    <Link to={`/admin/users/${account.user}`} className="text-primary-light hover:underline font-semibold">
                      {account.user_name} ({account.user_email})
                    </Link>
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" /> Connected {formatDate(account.created_at)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Configuration Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 rounded-xl bg-guardian-bg/60 border border-guardian-border text-xs">
            <div className="space-y-2">
              <span className="text-guardian-muted font-medium block">IAM Role ARN:</span>
              <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-guardian-card border border-guardian-border font-mono">
                <span className="text-guardian-text truncate">{account.role_arn}</span>
                <button onClick={() => copyToClipboard(account.role_arn, 'role')} className="text-guardian-muted hover:text-primary-light">
                  {copiedId === 'role' ? <Check className="w-3.5 h-3.5 text-guardian-success" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <div className="space-y-2">
              <span className="text-guardian-muted font-medium block">STS External ID:</span>
              <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-guardian-card border border-guardian-border font-mono">
                <span className="text-guardian-text truncate">{account.external_id}</span>
                <button onClick={() => copyToClipboard(account.external_id, 'ext')} className="text-guardian-muted hover:text-primary-light">
                  {copiedId === 'ext' ? <Check className="w-3.5 h-3.5 text-guardian-success" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <div className="md:col-span-2 space-y-1.5 pt-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <Globe className="w-3.5 h-3.5 text-primary-light" /> Configured Regions:
              </span>
              <div className="flex items-center gap-1.5 flex-wrap">
                {account.enabled_regions?.map((reg) => (
                  <span key={reg} className="px-2.5 py-1 rounded-md bg-white/5 border border-guardian-border font-mono text-[11px] text-guardian-text">
                    {reg}
                  </span>
                ))}
              </div>
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

      {/* Tab: Resources */}
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
                  <th className="py-3.5 px-4">Risk</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {resources.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-0">
                      <EmptyState title="No resources found" description="No active cloud resources found in this AWS account." />
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

      {/* Tab: Alerts */}
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
                      <EmptyState title="No active alerts" description="All resources in this account are healthy." />
                    </td>
                  </tr>
                ) : (
                  alerts.map((al) => (
                    <tr key={al.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5"><SeverityBadge severity={al.severity} /></td>
                      <td className="py-3.5 px-4 font-semibold">{al.title}</td>
                      <td className="py-3.5 px-4 font-mono text-guardian-muted">{al.rule_code}</td>
                      <td className="py-3.5 px-4"><Badge variant={al.status === 'RESOLVED' ? 'success' : 'warning'}>{al.status}</Badge></td>
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

      {/* Tab: Scans */}
      {activeTab === 'scans' && (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                  <th className="py-3.5 px-5">Status</th>
                  <th className="py-3.5 px-4 text-center">Resources Scanned</th>
                  <th className="py-3.5 px-4 text-center">Alerts Created</th>
                  <th className="py-3.5 px-4">Started</th>
                  <th className="py-3.5 px-5 text-right">Completed</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-guardian-border text-guardian-text">
                {scans.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-0">
                      <EmptyState title="No scan runs recorded" description="No automated scans have executed yet." />
                    </td>
                  </tr>
                ) : (
                  scans.map((sc) => (
                    <tr key={sc.id} className="hover:bg-white/5 transition-colors">
                      <td className="py-3.5 px-5">
                        <Badge variant={sc.status === 'COMPLETED' ? 'success' : sc.status === 'FAILED' ? 'critical' : 'warning'}>
                          {sc.status}
                        </Badge>
                      </td>
                      <td className="py-3.5 px-4 text-center font-mono">{sc.resources_found}</td>
                      <td className="py-3.5 px-4 text-center font-mono">{sc.alerts_generated}</td>
                      <td className="py-3.5 px-4 text-guardian-muted font-mono">{formatDateTime(sc.started_at)}</td>
                      <td className="py-3.5 px-5 text-right text-guardian-muted font-mono">
                        {sc.completed_at ? formatDateTime(sc.completed_at) : 'In Progress'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
};
