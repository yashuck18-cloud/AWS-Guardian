import React from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import {
  Layers,
  AlertTriangle,
  ExternalLink,
  Server,
  HardDrive,
  Database,
  Cloud,
  User,
  MapPin,
  Clock,
  Info,
  DollarSign,
  Cpu,
  Shield,
  Tag,
  Key,
} from 'lucide-react';
import { useResourceDetail } from '../hooks/useResources';
import { Breadcrumbs } from '../components/common/Breadcrumbs';
import { Card, CardHeader, CardTitle, CardContent } from '../components/common/Card';
import { Badge, SeverityBadge, RiskBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { Skeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { formatDateTime, formatTimeAgo } from '../utils/cn';

export const ResourceDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data, isLoading } = useResourceDetail(id || '');

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-36 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  const resource = data?.resource;
  if (!resource) {
    return (
      <div className="py-12">
        <EmptyState
          title="Resource not found"
          description="The requested cloud resource does not exist."
          action={{ label: 'Back to Resources', onClick: () => navigate('/admin/resources') }}
        />
      </div>
    );
  }

  const alerts = data?.alerts || [];
  const meta = (resource.metadata as Record<string, any>) || {};
  const cost = (resource as any).cost_info || {};

  const getServiceIcon = (svc: string) => {
    switch (svc.toUpperCase()) {
      case 'EC2':
        return <Server className="w-6 h-6 text-amber-400" />;
      case 'EBS':
        return <HardDrive className="w-6 h-6 text-sky-400" />;
      case 'RDS':
        return <Database className="w-6 h-6 text-purple-400" />;
      default:
        return <Layers className="w-6 h-6 text-primary-light" />;
    }
  };

  const getCostStatusVariant = (status: string) => {
    switch ((status || '').toUpperCase()) {
      case 'ACTUAL':
        return 'success';
      case 'ESTIMATED':
        return 'warning';
      default:
        return 'muted';
    }
  };

  return (
    <div className="space-y-6">
      <Breadcrumbs
        items={[
          { label: 'Resources', href: '/admin/resources' },
          { label: `${resource.service}: ${resource.resource_name || resource.resource_id}` },
        ]}
      />

      {/* 1. Resource Main Summary */}
      <Card>
        <CardContent className="p-6 space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-14 h-14 rounded-2xl bg-white/5 border border-guardian-border flex items-center justify-center shadow-lg shrink-0">
                {getServiceIcon(resource.service)}
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-3 flex-wrap">
                  <h1 className="text-xl font-bold text-guardian-text font-mono">{resource.resource_id}</h1>
                  <RiskBadge risk={resource.risk_level} />
                  <Badge variant={resource.status?.toLowerCase() === 'running' ? 'success' : 'muted'}>
                    {resource.status}
                  </Badge>
                </div>
                <div className="text-sm font-semibold text-guardian-muted">
                  {resource.resource_name ? `Tag Name: ${resource.resource_name}` : 'No Name Tag Configured'}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2.5 self-start md:self-center">
              <Button
                variant="secondary"
                size="sm"
                onClick={() => {
                  window.open(
                    `https://${resource.region}.console.aws.amazon.com`,
                    '_blank',
                    'noopener,noreferrer'
                  );
                }}
              >
                <span>AWS Console</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </Button>
            </div>
          </div>

          {/* Details Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 p-4 rounded-xl bg-guardian-bg/60 border border-guardian-border text-xs">
            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-primary-light" /> AWS Region
              </span>
              <div className="font-mono font-semibold text-guardian-text">{resource.region}</div>
            </div>

            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <Cloud className="w-3.5 h-3.5 text-primary-light" /> AWS Account
              </span>
              <Link to={`/admin/aws-accounts/${resource.account}`} className="font-semibold text-primary-light hover:underline block truncate">
                {resource.account_name} ({resource.account_aws_id})
              </Link>
            </div>

            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <User className="w-3.5 h-3.5 text-primary-light" /> Owner User
              </span>
              <Link to={`/admin/users/${resource.user_id}`} className="font-semibold text-primary-light hover:underline block truncate">
                {resource.user_name}
              </Link>
            </div>

            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 text-primary-light" /> Last Inspected
              </span>
              <div className="font-semibold text-guardian-text">{formatTimeAgo(resource.last_seen)}</div>
            </div>
          </div>

          {/* Detection Reason Banner */}
          {resource.detection_reason && (
            <div className="p-4 rounded-xl bg-primary/10 border border-primary/20 space-y-1">
              <div className="text-xs font-semibold text-primary-light flex items-center gap-1.5">
                <Info className="w-4 h-4" />
                <span>Detection & Audit Rationale</span>
              </div>
              <p className="text-xs text-guardian-text/90 leading-relaxed pl-5">
                {resource.detection_reason}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* 2. Authoritative AWS Cost & Billing Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-3">
          <CardTitle className="flex items-center gap-2 text-sm font-bold">
            <DollarSign className="w-4 h-4 text-emerald-400" />
            <span>AWS Cost & Billing Attribution</span>
          </CardTitle>
          <div className="flex items-center gap-2">
            <Badge variant={getCostStatusVariant(cost.billing_status)}>
              {cost.billing_status_display || cost.billing_status || 'PRICING ESTIMATE'}
            </Badge>
            <Badge variant="muted">{cost.cost_source_display || cost.cost_source || 'AWS Pricing'}</Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 p-4 rounded-xl bg-guardian-bg/60 border border-guardian-border">
            <div>
              <div className="text-xs text-guardian-muted font-medium">Estimated Current Cost</div>
              <div className="text-xl font-bold font-mono text-emerald-400 mt-1">
                ${cost.actual_cost && parseFloat(cost.actual_cost) > 0 ? cost.actual_cost : cost.estimated_cost || '0.00'} USD
              </div>
              {cost.approx_inr ? (
                <div className="text-[11px] text-guardian-muted mt-0.5">Approx. ₹{cost.approx_inr} INR (Conversion)</div>
              ) : null}
            </div>

            <div>
              <div className="text-xs text-guardian-muted font-medium">Authoritative Pricing Rate</div>
              <div className="text-lg font-bold font-mono text-guardian-text mt-1">
                ${cost.pricing_rate || resource.estimated_hourly_cost || '0.0000'} / {cost.pricing_unit || 'hr'}
              </div>
              <div className="text-[11px] text-guardian-muted mt-0.5">AWS On-Demand Rate</div>
            </div>

            <div>
              <div className="text-xs text-guardian-muted font-medium">Attribution Status</div>
              <div className="text-xs font-semibold text-guardian-text mt-2">
                {cost.cost_source_display || 'AWS On-Demand Pricing'}
              </div>
              <div className="text-[10px] text-guardian-muted mt-0.5 italic">Final AWS billing may differ.</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 3. Deep Resource Configuration Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Hardware & Placement Info */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm flex items-center gap-2">
              <Cpu className="w-4 h-4 text-primary-light" /> Configuration & Architecture
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="divide-y divide-guardian-border text-xs">
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Resource Type</dt>
                <dd className="font-semibold text-guardian-text">{meta.instance_type || meta.volume_type || meta.db_instance_class || resource.service}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Availability Zone</dt>
                <dd className="font-semibold text-guardian-text">{meta.availability_zone || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Platform / OS</dt>
                <dd className="font-semibold text-guardian-text">{meta.platform || meta.engine || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Architecture</dt>
                <dd className="font-semibold text-guardian-text">{meta.architecture || 'x86_64'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Tenancy</dt>
                <dd className="font-semibold text-guardian-text">{meta.tenancy || 'default'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">IAM Role Profile</dt>
                <dd className="font-mono text-guardian-text text-[11px] truncate max-w-50">{meta.iam_instance_profile || 'N/A'}</dd>
              </div>
            </dl>
          </CardContent>
        </Card>

        {/* Network & VPC Info */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm flex items-center gap-2">
              <Shield className="w-4 h-4 text-amber-400" /> Network & VPC
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="divide-y divide-guardian-border text-xs">
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Public IPv4</dt>
                <dd className="font-mono text-guardian-text">{meta.public_ip || meta.primary_public_ip || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Private IPv4</dt>
                <dd className="font-mono text-guardian-text">{meta.private_ip || meta.primary_private_ip || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">VPC ID</dt>
                <dd className="font-mono text-guardian-text">{meta.vpc_id || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Subnet ID</dt>
                <dd className="font-mono text-guardian-text">{meta.subnet_id || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">Key Pair</dt>
                <dd className="font-mono text-guardian-text">{meta.key_pair_name || 'N/A'}</dd>
              </div>
              <div className="py-2.5 flex justify-between">
                <dt className="text-guardian-muted font-medium">AMI ID</dt>
                <dd className="font-mono text-guardian-text">{meta.ami_id || 'N/A'}</dd>
              </div>
            </dl>
          </CardContent>
        </Card>
      </div>

      {/* 4. Associated Security Alerts */}
      <Card>
        <CardHeader>
          <CardTitle>Associated Security Findings ({alerts.length})</CardTitle>
        </CardHeader>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-guardian-border bg-guardian-bg/60 text-guardian-muted uppercase tracking-wider font-bold">
                <th className="py-3.5 px-5">Severity</th>
                <th className="py-3.5 px-4">Alert Title</th>
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
                    <EmptyState title="No findings for this resource" description="This cloud component has no active or historical alerts." />
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

      {/* 5. Raw AWS Metadata JSON */}
      <Card>
        <CardHeader>
          <CardTitle>Discovered AWS Metadata</CardTitle>
        </CardHeader>
        <CardContent>
          <pre className="p-4 rounded-xl bg-guardian-bg border border-guardian-border text-[11px] font-mono text-guardian-text overflow-x-auto max-h-72">
            {JSON.stringify(resource.metadata || {}, null, 2)}
          </pre>
        </CardContent>
      </Card>
    </div>
  );
};
