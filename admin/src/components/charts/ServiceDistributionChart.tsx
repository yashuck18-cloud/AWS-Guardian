import React from 'react';
import { ServiceBreakdownItem } from '../../types';
import { Server, HardDrive, Database, Folder, Network, Globe, Activity } from 'lucide-react';

interface ServiceDistributionChartProps {
  data: ServiceBreakdownItem[];
}

const SERVICE_META: Record<string, { label: string; color: string; bgGradient: string; icon: any }> = {
  EC2: { label: 'EC2 Compute Instances', color: 'text-amber-400', bgGradient: 'from-amber-500 to-orange-500', icon: Server },
  EBS: { label: 'EBS Block Storage Volumes', color: 'text-cyan-400', bgGradient: 'from-cyan-400 to-blue-500', icon: HardDrive },
  RDS: { label: 'RDS Relational Databases', color: 'text-purple-400', bgGradient: 'from-violet-400 to-fuchsia-600', icon: Database },
  S3: { label: 'S3 Storage Buckets', color: 'text-emerald-400', bgGradient: 'from-emerald-400 to-teal-500', icon: Folder },
  ELB: { label: 'Elastic Load Balancers', color: 'text-pink-400', bgGradient: 'from-pink-400 to-rose-500', icon: Network },
  EIP: { label: 'Elastic IP Addresses', color: 'text-sky-400', bgGradient: 'from-sky-400 to-indigo-500', icon: Globe },
  NAT: { label: 'VPC NAT Gateways', color: 'text-indigo-400', bgGradient: 'from-indigo-400 to-violet-500', icon: Activity },
};

export const ServiceDistributionChart: React.FC<ServiceDistributionChartProps> = ({ data }) => {
  const total = data.reduce((acc, curr) => acc + curr.count, 0);

  if (data.length === 0 || total === 0) {
    return (
      <div className="py-8 text-center text-xs text-guardian-muted">
        No cloud resources discovered yet.
      </div>
    );
  }

  return (
    <div className="space-y-3.5">
      {data.map((item) => {
        const meta = SERVICE_META[item.service] || {
          label: item.service,
          color: 'text-violet-400',
          bgGradient: 'from-violet-500 to-indigo-500',
          icon: Server,
        };
        const Icon = meta.icon;
        const percentage = total > 0 ? Math.round((item.count / total) * 100) : 0;

        return (
          <div key={item.service} className="space-y-1.5 group">
            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <div className={`p-1 rounded-md bg-white/5 border border-white/10 ${meta.color} group-hover:scale-110 transition-transform`}>
                  <Icon className="w-3.5 h-3.5" />
                </div>
                <span className="font-semibold text-guardian-text group-hover:text-white transition-colors">{meta.label}</span>
              </div>
              <div className="flex items-center gap-2 font-mono">
                <span className="font-bold text-guardian-text">{item.count}</span>
                <span className="text-[10px] text-guardian-muted">({percentage}%)</span>
              </div>
            </div>
            <div className="h-2 w-full rounded-full bg-white/6 overflow-hidden p-0.5 border border-white/5">
              <div
                className={`h-full bg-linear-to-r ${meta.bgGradient} rounded-full transition-all duration-700 shadow-sm`}
                style={{ width: `${Math.max(4, percentage)}%` }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
};
