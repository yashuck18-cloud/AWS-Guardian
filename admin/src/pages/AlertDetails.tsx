import React, { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  Layers,
  Cloud,
  DollarSign,
  ShieldAlert,
  ArrowRight,
  Info,
} from 'lucide-react';
import { useAlertDetail, useResolveAlert } from '../hooks/useAlerts';
import { Breadcrumbs } from '../components/common/Breadcrumbs';
import { Card, CardHeader, CardTitle, CardContent } from '../components/common/Card';
import { Badge, SeverityBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { Skeleton } from '../components/common/Skeleton';
import { EmptyState, ConfirmationDialog } from '../components/common/EmptyState';
import { formatDateTime, formatTimeAgo } from '../utils/cn';

export const AlertDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [resolveOpen, setResolveOpen] = useState(false);
  const navigate = useNavigate();

  const { data, isLoading, refetch } = useAlertDetail(id || '');
  const resolveMutation = useResolveAlert();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-36 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  const alert = data?.alert;
  if (!alert) {
    return (
      <div className="py-12">
        <EmptyState
          title="Alert not found"
          description="The requested security or cost alert does not exist."
          action={{ label: 'Back to Alerts', onClick: () => navigate('/admin/alerts') }}
        />
      </div>
    );
  }

  const handleResolve = async () => {
    try {
      await resolveMutation.mutateAsync(alert.id);
      setResolveOpen(false);
      refetch();
    } catch {
      // ignore
    }
  };

  return (
    <div className="space-y-6">
      <Breadcrumbs
        items={[
          { label: 'Alerts', href: '/admin/alerts' },
          { label: alert.title },
        ]}
      />

      {/* Main Alert Card */}
      <Card>
        <CardContent className="p-6 space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-14 h-14 rounded-2xl bg-guardian-critical/15 border border-guardian-critical/30 text-guardian-critical flex items-center justify-center font-extrabold text-xl shadow-lg shrink-0">
                <AlertTriangle className="w-7 h-7" />
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-3 flex-wrap">
                  <h1 className="text-xl font-bold text-guardian-text">{alert.title}</h1>
                  <SeverityBadge severity={alert.severity} />
                  <Badge variant={alert.status === 'RESOLVED' ? 'success' : 'warning'}>
                    {alert.status}
                  </Badge>
                </div>
                <div className="text-xs font-mono text-guardian-muted">
                  Rule Code: <span className="text-primary-light font-semibold">{alert.rule_code}</span>
                </div>
              </div>
            </div>

            {alert.status !== 'RESOLVED' && (
              <Button
                variant="primary"
                size="sm"
                onClick={() => setResolveOpen(true)}
                className="self-start md:self-center"
              >
                <CheckCircle className="w-4 h-4" />
                <span>Mark as Resolved</span>
              </Button>
            )}
          </div>

          {/* Key Metrics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 p-4 rounded-xl bg-guardian-bg/60 border border-guardian-border text-xs">
            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <DollarSign className="w-3.5 h-3.5 text-guardian-warning" /> Estimated Monthly Cost
              </span>
              <div className="text-base font-bold text-guardian-warning font-mono">
                ${Number(alert.estimated_cost_impact || 0).toFixed(2)} / month
              </div>
            </div>

            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 text-primary-light" /> First Detected
              </span>
              <div className="font-semibold text-guardian-text font-mono">
                {formatDateTime(alert.first_detected_at)}
              </div>
            </div>

            <div className="space-y-1">
              <span className="text-guardian-muted font-medium flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 text-primary-light" /> Last Verified
              </span>
              <div className="font-semibold text-guardian-text font-mono">
                {formatDateTime(alert.last_detected_at)}
              </div>
            </div>
          </div>

          {/* Description Section */}
          <div className="space-y-2">
            <h4 className="text-xs font-bold text-guardian-text uppercase tracking-wider">
              Finding Details & Rationale
            </h4>
            <p className="text-xs text-guardian-text/90 leading-relaxed bg-guardian-bg p-4 rounded-xl border border-guardian-border">
              {alert.description}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Target Infrastructure Links */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Resource Link */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Layers className="w-4 h-4 text-primary-light" />
              <CardTitle>Flagged Cloud Resource</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-3 text-xs">
            <div className="flex justify-between py-1.5 border-b border-guardian-border">
              <span className="text-guardian-muted">Service Type</span>
              <span className="font-semibold text-primary-light">{alert.resource_type || 'AWS Core'}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-guardian-border">
              <span className="text-guardian-muted">Resource Identifier</span>
              <span className="font-mono font-semibold text-guardian-text">{alert.resource_identifier || 'Fleet Global'}</span>
            </div>
            {alert.resource && (
              <div className="pt-2">
                <Link
                  to={`/admin/resources/${alert.resource}`}
                  className="w-full flex items-center justify-center gap-1.5 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-xs font-semibold text-guardian-text border border-guardian-border transition-colors"
                >
                  <span>Inspect Full Resource Profile</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            )}
          </CardContent>
        </Card>

        {/* AWS Account Link */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Cloud className="w-4 h-4 text-guardian-info" />
              <CardTitle>Parent AWS Account</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-3 text-xs">
            <div className="flex justify-between py-1.5 border-b border-guardian-border">
              <span className="text-guardian-muted">Account Name</span>
              <span className="font-semibold text-guardian-text">{alert.account_name}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-guardian-border">
              <span className="text-guardian-muted">AWS 12-Digit ID</span>
              <span className="font-mono text-guardian-text">{alert.account_aws_id}</span>
            </div>
            <div className="pt-2">
              <Link
                to={`/admin/aws-accounts/${alert.account}`}
                className="w-full flex items-center justify-center gap-1.5 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-xs font-semibold text-guardian-text border border-guardian-border transition-colors"
              >
                <span>View AWS Account & Credentials</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Resolve Confirmation Modal */}
      <ConfirmationDialog
        isOpen={resolveOpen}
        onClose={() => setResolveOpen(false)}
        onConfirm={handleResolve}
        isLoading={resolveMutation.isPending}
        title="Resolve Security Finding?"
        message={`Mark finding "${alert.title}" as resolved? This action records an administrative resolution in the immutable security audit log.`}
        confirmLabel="Mark as Resolved"
      />
    </div>
  );
};
