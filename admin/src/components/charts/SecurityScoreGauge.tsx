import React from 'react';
import { ShieldCheck, ShieldAlert, AlertTriangle } from 'lucide-react';
import { Badge } from '../common/Badge';

interface SecurityScoreGaugeProps {
  criticalAlerts: number;
  highAlerts: number;
  mediumAlerts: number;
  totalResources: number;
}

export const SecurityScoreGauge: React.FC<SecurityScoreGaugeProps> = ({
  criticalAlerts,
  highAlerts,
  mediumAlerts,
  totalResources,
}) => {
  let penalty = criticalAlerts * 20 + highAlerts * 8 + mediumAlerts * 3;
  let score = Math.max(15, Math.min(100, 100 - penalty));
  if (totalResources === 0 && criticalAlerts === 0) {
    score = 100;
  }

  let rating = 'Optimal';
  let badgeVariant: 'success' | 'warning' | 'critical' | 'info' = 'success';
  let gradientId = 'gaugeOptimal';

  if (score < 50 || criticalAlerts > 0) {
    rating = 'Critical Risk';
    badgeVariant = 'critical';
    gradientId = 'gaugeCritical';
  } else if (score < 75 || highAlerts > 0) {
    rating = 'Needs Attention';
    badgeVariant = 'warning';
    gradientId = 'gaugeWarning';
  } else if (score < 90) {
    rating = 'Good';
    badgeVariant = 'info';
    gradientId = 'gaugeGood';
  }

  const radius = 48;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (score / 100) * circumference;

  const healthyResourcesCount = Math.max(0, totalResources - (criticalAlerts + highAlerts + mediumAlerts));
  const healthyPercentage = totalResources > 0 ? Math.round((healthyResourcesCount / totalResources) * 100) : 100;

  return (
    <div className="flex flex-col md:flex-row items-center justify-between gap-6 p-1">
      {/* Radial Meter */}
      <div className="flex items-center gap-5 shrink-0">
        <div className="relative w-32 h-32 flex items-center justify-center">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 120 120">
            <defs>
              <linearGradient id="gaugeOptimal" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#10B981" />
                <stop offset="100%" stopColor="#06B6D4" />
              </linearGradient>
              <linearGradient id="gaugeGood" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#38BDF8" />
                <stop offset="100%" stopColor="#818CF8" />
              </linearGradient>
              <linearGradient id="gaugeWarning" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#F59E0B" />
                <stop offset="100%" stopColor="#FB923C" />
              </linearGradient>
              <linearGradient id="gaugeCritical" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#EF4444" />
                <stop offset="100%" stopColor="#F43F5E" />
              </linearGradient>
            </defs>

            {/* Track */}
            <circle
              cx="60"
              cy="60"
              r={radius}
              stroke="currentColor"
              strokeWidth="10"
              fill="transparent"
              className="text-white/6"
            />
            {/* Gradient Arc */}
            <circle
              cx="60"
              cy="60"
              r={radius}
              stroke={`url(#${gradientId})`}
              strokeWidth="10"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              fill="transparent"
              className="transition-all duration-1000 ease-out drop-shadow-md"
            />
          </svg>

          <div className="absolute flex flex-col items-center justify-center text-center">
            <span className="text-3xl font-extrabold bg-linear-to-br from-white via-slate-100 to-slate-300 bg-clip-text text-transparent font-mono tracking-tight">
              {score}
            </span>
            <span className="text-[9px] text-violet-300 uppercase tracking-widest font-bold">/ 100</span>
          </div>
        </div>

        <div className="space-y-1.5">
          <div className="text-[11px] font-bold text-guardian-muted uppercase tracking-wider">Security Posture</div>
          <div className="flex items-center gap-2">
            <Badge variant={badgeVariant} dot className="shadow-sm font-semibold">
              {rating}
            </Badge>
          </div>
          <p className="text-[11px] text-guardian-muted max-w-40 leading-relaxed">
            {criticalAlerts === 0
              ? 'Zero active critical vulnerabilities detected.'
              : `${criticalAlerts} critical finding(s) require prompt resolution.`}
          </p>
        </div>
      </div>

      {/* Progress Breakdown Bars */}
      <div className="flex-1 w-full space-y-3 text-xs">
        {/* Critical Issues */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-guardian-text font-medium flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-rose-500 shadow-xs shadow-rose-500/50" /> Critical Issues
            </span>
            <span className="font-mono font-bold text-rose-400">{criticalAlerts}</span>
          </div>
          <div className="h-2 w-full rounded-full bg-white/6 overflow-hidden p-0.5 border border-white/5">
            <div
              className="h-full bg-linear-to-r from-rose-500 to-red-600 rounded-full transition-all duration-700 shadow-sm shadow-rose-500/30"
              style={{ width: `${Math.min(100, criticalAlerts * 25)}%` }}
            />
          </div>
        </div>

        {/* High Risk */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-guardian-text font-medium flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-amber-400 shadow-xs shadow-amber-400/50" /> High Risk Resources
            </span>
            <span className="font-mono font-bold text-amber-400">{highAlerts}</span>
          </div>
          <div className="h-2 w-full rounded-full bg-white/6 overflow-hidden p-0.5 border border-white/5">
            <div
              className="h-full bg-linear-to-r from-amber-400 to-orange-500 rounded-full transition-all duration-700 shadow-sm shadow-amber-400/30"
              style={{ width: `${Math.min(100, highAlerts * 15)}%` }}
            />
          </div>
        </div>

        {/* Healthy Resources Ratio */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-guardian-text font-medium flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-400 shadow-xs shadow-emerald-400/50" /> Healthy Fleet Ratio
            </span>
            <span className="font-mono font-bold text-emerald-400">{healthyPercentage}%</span>
          </div>
          <div className="h-2 w-full rounded-full bg-white/6 overflow-hidden p-0.5 border border-white/5">
            <div
              className="h-full bg-linear-to-r from-emerald-400 via-teal-400 to-cyan-500 rounded-full transition-all duration-700 shadow-sm shadow-emerald-400/30"
              style={{ width: `${healthyPercentage}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
