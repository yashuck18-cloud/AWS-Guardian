import React, { useState } from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { GrowthPoint } from '../../types';

interface UserGrowthChartProps {
  data: GrowthPoint[];
  timeframe: string;
  onTimeframeChange?: (tf: string) => void;
}

export const UserGrowthChart: React.FC<UserGrowthChartProps> = ({
  data,
  timeframe,
  onTimeframeChange,
}) => {
  const [metric, setMetric] = useState<'users' | 'scans' | 'alerts'>('users');
  const timeframes = ['7d', '30d', '90d', '1y'];

  const metricConfig = {
    users: { label: 'Platform Users', color: '#8B5CF6', fillId: 'gradUsers', key: 'users' },
    scans: { label: 'Automated Scans', color: '#38BDF8', fillId: 'gradScans', key: 'scans' },
    alerts: { label: 'Detected Alerts', color: '#F59E0B', fillId: 'gradAlerts', key: 'alerts' },
  };

  const activeConfig = metricConfig[metric];

  return (
    <div className="w-full space-y-3.5">
      {/* Metric & Timeframe Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
        {/* Metric Selector */}
        <div className="flex items-center gap-1 bg-guardian-bg/80 p-0.5 rounded-lg border border-guardian-border">
          {(Object.keys(metricConfig) as Array<keyof typeof metricConfig>).map((mKey) => (
            <button
              key={mKey}
              onClick={() => setMetric(mKey)}
              className={`px-2.5 py-1 text-xs font-semibold rounded-md transition-all ${
                metric === mKey
                  ? 'bg-guardian-card text-guardian-text shadow-sm border border-guardian-border'
                  : 'text-guardian-muted hover:text-guardian-text'
              }`}
            >
              {metricConfig[mKey].label}
            </button>
          ))}
        </div>

        {/* Timeframe Selector */}
        {onTimeframeChange && (
          <div className="flex items-center gap-1 bg-guardian-bg/80 p-0.5 rounded-lg border border-guardian-border self-start sm:self-auto">
            {timeframes.map((tf) => (
              <button
                key={tf}
                onClick={() => onTimeframeChange(tf)}
                className={`px-2.5 py-1 text-[11px] font-bold rounded-md uppercase transition-all ${
                  timeframe === tf
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-guardian-muted hover:text-guardian-text'
                }`}
              >
                {tf}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Chart */}
      <div className="h-56 w-full">
        {data.length === 0 ? (
          <div className="h-full flex items-center justify-center text-xs text-guardian-muted">
            No activity telemetry recorded for this timeframe.
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 8, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradUsers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#8B5CF6" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#8B5CF6" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="gradScans" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#38BDF8" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#38BDF8" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="gradAlerts" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#F59E0B" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.08)" vertical={false} />
              <XAxis
                dataKey="date"
                stroke="#64748B"
                fontSize={10}
                tickLine={false}
                axisLine={false}
                tickFormatter={(val) => {
                  const parts = val.split('-');
                  return parts.length >= 3 ? `${parts[1]}/${parts[2]}` : val;
                }}
              />
              <YAxis stroke="#64748B" fontSize={10} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#0F172A',
                  borderColor: 'rgba(148, 163, 184, 0.15)',
                  borderRadius: '8px',
                  color: '#F8FAFC',
                  fontSize: '11px',
                  boxShadow: '0 10px 25px rgba(0,0,0,0.5)',
                }}
              />
              <Area
                type="monotone"
                dataKey={activeConfig.key}
                name={activeConfig.label}
                stroke={activeConfig.color}
                strokeWidth={2}
                fillOpacity={1}
                fill={`url(#${activeConfig.fillId})`}
              />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
