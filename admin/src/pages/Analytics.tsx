import React, { useState } from 'react';
import {
  BarChart3,
  TrendingUp,
  Layers,
  AlertTriangle,
  Cloud,
  RefreshCw,
} from 'lucide-react';
import { useAnalytics } from '../hooks/useAnalytics';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Skeleton } from '../components/common/Skeleton';
import { UserGrowthChart } from '../components/charts/UserGrowthChart';
import { ServiceDistributionChart } from '../components/charts/ServiceDistributionChart';
import { AlertSeverityChart } from '../components/charts/AlertSeverityChart';
import { AccountStatusDonut } from '../components/charts/AccountStatusDonut';

export const Analytics: React.FC = () => {
  const [timeframe, setTimeframe] = useState('30d');
  const { data, isLoading, refetch, isRefetching } = useAnalytics(timeframe);

  const timeframes = [
    { label: '7D', value: '7d' },
    { label: '30D', value: '30d' },
    { label: '90D', value: '90d' },
    { label: '1Y', value: '1y' },
  ];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-guardian-text tracking-tight">Platform Analytics</h1>
          <p className="text-xs text-guardian-muted mt-0.5">
            Fleet telemetry, resource distribution metrics, and security discovery trends.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Timeframe Switcher */}
          <div className="flex items-center gap-1 bg-guardian-card p-0.5 rounded-lg border border-guardian-border">
            {timeframes.map((tf) => (
              <button
                key={tf.value}
                onClick={() => setTimeframe(tf.value)}
                className={`px-2.5 py-1 text-xs font-bold rounded-md uppercase transition-colors ${
                  timeframe === tf.value
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-guardian-muted hover:text-guardian-text'
                }`}
              >
                {tf.label}
              </button>
            ))}
          </div>

          <Button variant="outline" size="sm" onClick={() => refetch()} isLoading={isRefetching} className="h-8 text-xs">
            <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </div>

      {/* Main Growth Area Chart */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Fleet Growth & Scan Velocity</CardTitle>
            <CardDescription>Historical trend of users onboarded and scan executions over {timeframe}</CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Skeleton className="h-64 w-full" />
          ) : (
            <UserGrowthChart
              data={data?.growth_series || []}
              timeframe={timeframe}
              onTimeframeChange={setTimeframe}
            />
          )}
        </CardContent>
      </Card>

      {/* 3 Grid Analytics Charts */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Service Breakdown */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Layers className="w-4 h-4 text-primary-light" />
              <div>
                <CardTitle>Resource Breakdown</CardTitle>
                <CardDescription>Distribution across AWS services</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <ServiceDistributionChart data={data?.service_breakdown || []} />
            )}
          </CardContent>
        </Card>

        {/* Severity Distribution */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-400" />
              <div>
                <CardTitle>Severity Distribution</CardTitle>
                <CardDescription>Risk proportion of active findings</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <AlertSeverityChart data={data?.severity_breakdown || []} />
            )}
          </CardContent>
        </Card>

        {/* Account Health */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Cloud className="w-4 h-4 text-sky-400" />
              <div>
                <CardTitle>AWS Connection Health</CardTitle>
                <CardDescription>STS AssumeRole verification</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-48 w-full" />
            ) : (
              <AccountStatusDonut data={data?.account_status || []} />
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
