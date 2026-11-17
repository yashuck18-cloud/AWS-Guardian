import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Search,
  Layers,
  Eye,
  RefreshCw,
  Filter,
  Server,
  HardDrive,
  Database,
  Folder,
} from 'lucide-react';
import { useResources } from '../hooks/useResources';
import { Card, CardContent } from '../components/common/Card';
import { Badge, RiskBadge } from '../components/common/Badge';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState } from '../components/common/EmptyState';
import { Pagination } from '../components/tables/Pagination';
import { formatTimeAgo } from '../utils/cn';

export const Resources: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [serviceFilter, setServiceFilter] = useState(searchParams.get('service') || 'all');
  const [riskFilter, setRiskFilter] = useState(searchParams.get('risk') || 'all');
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const navigate = useNavigate();

  const { data, isLoading, refetch, isRefetching } = useResources({
    search: search.trim() || undefined,
    service: serviceFilter !== 'all' ? serviceFilter : undefined,
    risk: riskFilter !== 'all' ? riskFilter : undefined,
  });

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    setSearchParams((prev) => {
      if (search) prev.set('search', search);
      else prev.delete('search');
      return prev;
    });
  };

  const resourcesList = data?.resources || [];
  const paginatedResources = resourcesList.slice((page - 1) * pageSize, page * pageSize);

  const services = ['all', 'EC2', 'EBS', 'RDS', 'S3', 'ELB', 'EIP', 'NAT'];
  const risks = ['all', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  const ec2Count = resourcesList.filter((r) => r.service === 'EC2').length;
  const ebsCount = resourcesList.filter((r) => r.service === 'EBS').length;
  const rdsCount = resourcesList.filter((r) => r.service === 'RDS').length;
  const s3Count = resourcesList.filter((r) => r.service === 'S3').length;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-extrabold text-white tracking-tight">Cloud Resource Catalog</h1>
          <p className="text-xs text-slate-300/80 mt-0.5">
            Global inventory of detected AWS infrastructure resources and automated risk classifications.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()} isLoading={isRefetching} className="h-8 text-xs bg-white/4 hover:bg-white/10 border-white/12 text-white">
            <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </Button>
        </div>
      </div>

      {/* KPI Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className="p-3.5 rounded-xl bg-linear-to-br from-indigo-950/30 to-guardian-card border border-indigo-500/20 space-y-1">
          <span className="text-[11px] font-bold text-indigo-400 uppercase tracking-wider">Discovered Fleet</span>
          <div className="text-2xl font-extrabold text-white font-mono">{resourcesList.length}</div>
        </div>
        <div className="p-3.5 rounded-xl bg-linear-to-br from-amber-950/30 to-guardian-card border border-amber-500/20 space-y-1">
          <span className="text-[11px] font-bold text-amber-400 uppercase tracking-wider">EC2 Compute</span>
          <div className="text-2xl font-extrabold text-amber-400 font-mono">{ec2Count}</div>
        </div>
        <div className="p-3.5 rounded-xl bg-linear-to-br from-cyan-950/30 to-guardian-card border border-cyan-500/20 space-y-1">
          <span className="text-[11px] font-bold text-cyan-400 uppercase tracking-wider">EBS Block Storage</span>
          <div className="text-2xl font-extrabold text-cyan-400 font-mono">{ebsCount}</div>
        </div>
        <div className="p-3.5 rounded-xl bg-linear-to-br from-purple-950/30 to-guardian-card border border-purple-500/20 space-y-1">
          <span className="text-[11px] font-bold text-purple-400 uppercase tracking-wider">RDS & S3 Assets</span>
          <div className="text-2xl font-extrabold text-purple-400 font-mono">{rdsCount + s3Count}</div>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-3 space-y-2.5">
          <div className="flex flex-col md:flex-row items-center justify-between gap-3">
            {/* Search Input */}
            <form onSubmit={handleSearchSubmit} className="w-full md:w-80 relative flex items-center">
              <Search className="w-4 h-4 text-indigo-400 absolute left-3 pointer-events-none" />
              <input
                type="text"
                placeholder="Search resource ID, tag name, account..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-xl border border-white/8 pl-9 pr-3 py-2 focus:outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400/30 font-sans"
              />
            </form>

            {/* Risk Filters */}
            <div className="flex items-center gap-1.5 w-full md:w-auto overflow-x-auto pb-1 md:pb-0">
              <span className="text-xs text-guardian-muted flex items-center gap-1 mr-1">
                <Filter className="w-3.5 h-3.5 text-indigo-400" /> Risk:
              </span>
              {risks.map((rk) => (
                <button
                  key={rk}
                  onClick={() => {
                    setRiskFilter(rk);
                    setPage(1);
                  }}
                  className={`px-3 py-1 text-xs font-bold rounded-lg uppercase transition-all cursor-pointer ${
                    riskFilter === rk
                      ? 'bg-linear-to-r from-violet-600 to-indigo-600 text-white shadow-md shadow-violet-500/30'
                      : 'bg-white/3 hover:bg-white/8 text-guardian-muted hover:text-white border border-white/6'
                  }`}
                >
                  {rk}
                </button>
              ))}
            </div>
          </div>

          {/* Service Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto pt-2 border-t border-white/6">
            <span className="text-xs text-guardian-muted mr-1 font-semibold">Service:</span>
            {services.map((svc) => (
              <button
                key={svc}
                onClick={() => {
                  setServiceFilter(svc);
                  setPage(1);
                }}
                className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                  serviceFilter === svc
                    ? 'bg-violet-500/20 text-violet-300 border border-violet-400/40 shadow-xs'
                    : 'bg-white/4 text-slate-400 hover:text-white hover:bg-white/8 border border-transparent'
                }`}
              >
                {svc}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Resources Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-white/6 bg-white/2 text-guardian-muted font-bold text-[10px] uppercase tracking-wider">
                <th className="py-3 px-4">Service</th>
                <th className="py-3 px-3">Resource Identifier</th>
                <th className="py-3 px-3">Custom Name</th>
                <th className="py-3 px-3">AWS Account</th>
                <th className="py-3 px-3">Region</th>
                <th className="py-3 px-3">Risk Level</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-3">Last Seen</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/4 text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={9} className="p-0">
                    <TableSkeleton rows={5} cols={9} />
                  </td>
                </tr>
              ) : paginatedResources.length === 0 ? (
                <tr>
                  <td colSpan={9} className="p-0">
                    <EmptyState
                      icon={<Layers className="w-6 h-6 text-indigo-400" />}
                      title="No cloud resources found"
                      description="No infrastructure resources discovered matching your criteria. Once an AWS Account is connected, scans catalog resources automatically."
                    />
                  </td>
                </tr>
              ) : (
                paginatedResources.map((res) => (
                  <tr key={res.id} className="hover:bg-white/4 transition-colors group">
                    <td className="py-3 px-4 font-extrabold text-violet-400 font-mono text-[11px]">
                      <span className="px-2 py-0.5 rounded-md bg-violet-500/10 border border-violet-500/20">
                        {res.service}
                      </span>
                    </td>
                    <td className="py-3 px-3 font-mono font-bold text-white hover:text-cyan-300 transition-colors cursor-pointer text-[11px]" onClick={() => navigate(`/admin/resources/${res.id}`)}>
                      {res.resource_id}
                    </td>
                    <td className="py-3 px-3 text-slate-300 max-w-40 truncate">
                      {res.resource_name || '—'}
                    </td>
                    <td className="py-3 px-3">
                      <div className="font-bold text-white">{res.account_name}</div>
                      <div className="text-[10px] text-cyan-300/80 font-mono">{res.account_aws_id}</div>
                    </td>
                    <td className="py-3 px-3 font-mono text-slate-400 text-[11px]">{res.region}</td>
                    <td className="py-3 px-3"><RiskBadge risk={res.risk_level} /></td>
                    <td className="py-3 px-3"><Badge variant="muted">{res.status}</Badge></td>
                    <td className="py-3 px-3 text-guardian-muted font-mono text-[11px]">{formatTimeAgo(res.last_seen)}</td>
                    <td className="py-3 px-4 text-right">
                      <Button variant="secondary" size="sm" onClick={() => navigate(`/admin/resources/${res.id}`)} className="h-7 text-xs bg-white/4 hover:bg-white/10 border-white/10 text-white cursor-pointer">
                        <Eye className="w-3.5 h-3.5" />
                        <span>Inspect</span>
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <Pagination
          currentPage={page}
          totalItems={resourcesList.length}
          pageSize={pageSize}
          onPageChange={setPage}
        />
      </Card>
    </div>
  );
};
