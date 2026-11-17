import React from 'react';
import { cn } from '../../utils/cn';
import { AlertSeverity, AWSAccountStatus, RiskLevel } from '../../types';

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'critical' | 'info' | 'purple' | 'muted';
  dot?: boolean;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  className,
  variant = 'default',
  dot = false,
  ...props
}) => {
  const variantStyles = {
    default: 'bg-white/5 text-guardian-text border-white/10',
    success: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/25',
    warning: 'bg-amber-500/10 text-amber-400 border-amber-500/25',
    critical: 'bg-red-500/10 text-red-400 border-red-500/25',
    info: 'bg-sky-500/10 text-sky-400 border-sky-500/25',
    purple: 'bg-purple-500/10 text-purple-300 border-purple-500/25',
    muted: 'bg-slate-500/10 text-slate-400 border-slate-500/20',
  };

  const dotColors = {
    default: 'bg-guardian-text',
    success: 'bg-emerald-400',
    warning: 'bg-amber-400',
    critical: 'bg-red-400',
    info: 'bg-sky-400',
    purple: 'bg-purple-300',
    muted: 'bg-slate-400',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-[11px] font-medium border tracking-wide transition-colors whitespace-nowrap',
        variantStyles[variant],
        className
      )}
      {...props}
    >
      {dot && <span className={cn('w-1.5 h-1.5 rounded-full shrink-0', dotColors[variant])} />}
      {children}
    </span>
  );
};

export const SeverityBadge: React.FC<{ severity: AlertSeverity; className?: string }> = ({
  severity,
  className,
}) => {
  const map: Record<AlertSeverity, { variant: 'critical' | 'warning' | 'info' | 'purple'; label: string }> = {
    CRITICAL: { variant: 'critical', label: 'CRITICAL' },
    HIGH: { variant: 'warning', label: 'HIGH' },
    MEDIUM: { variant: 'info', label: 'MEDIUM' },
    LOW: { variant: 'purple', label: 'LOW' },
  };

  const item = map[severity] || { variant: 'info', label: severity };

  return (
    <Badge variant={item.variant} dot className={cn('font-mono font-bold text-[10px]', className)}>
      {item.label}
    </Badge>
  );
};

export const RiskBadge: React.FC<{ risk: RiskLevel; className?: string }> = ({
  risk,
  className,
}) => {
  const map: Record<RiskLevel, { variant: 'critical' | 'warning' | 'info' | 'purple'; label: string }> = {
    CRITICAL: { variant: 'critical', label: 'Critical Risk' },
    HIGH: { variant: 'warning', label: 'High Risk' },
    MEDIUM: { variant: 'info', label: 'Medium Risk' },
    LOW: { variant: 'purple', label: 'Low Risk' },
  };

  const item = map[risk] || { variant: 'info', label: risk };

  return (
    <Badge variant={item.variant} dot className={className}>
      {item.label}
    </Badge>
  );
};

export const AccountStatusBadge: React.FC<{ status: AWSAccountStatus; className?: string }> = ({
  status,
  className,
}) => {
  const map: Record<AWSAccountStatus, { variant: 'success' | 'muted' | 'critical' | 'warning'; label: string }> = {
    CONNECTED: { variant: 'success', label: 'Connected' },
    DISCONNECTED: { variant: 'muted', label: 'Disconnected' },
    ERROR: { variant: 'critical', label: 'Error' },
    VERIFICATION_FAILED: { variant: 'critical', label: 'Verification Failed' },
    PENDING: { variant: 'warning', label: 'Pending' },
  };

  const item = map[status] || { variant: 'muted', label: status };

  return (
    <Badge variant={item.variant} dot className={className}>
      {item.label}
    </Badge>
  );
};
