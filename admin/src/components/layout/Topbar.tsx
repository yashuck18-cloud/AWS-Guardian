import React, { useState } from 'react';
import { useLocation } from 'react-router-dom';
import {
  Menu,
  Search,
  Bell,
  Sun,
  Moon,
  Laptop,
} from 'lucide-react';
import { useAuth } from '../../stores/authStore';
import { useTheme } from '../../stores/themeStore';
import { NotificationDropdown } from './NotificationDropdown';
import { useAlerts } from '../../hooks/useAlerts';
import { useSystemHealth } from '../../hooks/useAnalytics';

interface TopbarProps {
  onOpenMobileSidebar: () => void;
  onOpenSearch: () => void;
}

export const Topbar: React.FC<TopbarProps> = ({ onOpenMobileSidebar, onOpenSearch }) => {
  const { user } = useAuth();
  const { theme, setTheme } = useTheme();
  const [notifOpen, setNotifOpen] = useState(false);
  const location = useLocation();

  const { data: alertsData } = useAlerts({ status: 'ACTIVE' });
  const { data: healthData } = useSystemHealth();

  const activeAlerts = alertsData?.alerts || [];
  const criticalCount = activeAlerts.filter((a) => a.severity === 'CRITICAL').length;
  const isHealthy = healthData?.components?.every((c) => c.status === 'Operational') ?? true;

  const cycleTheme = () => {
    if (theme === 'dark') setTheme('light');
    else if (theme === 'light') setTheme('system');
    else setTheme('dark');
  };

  const getBreadcrumbTitle = () => {
    const p = location.pathname;
    if (p === '/admin' || p === '/admin/') return 'Executive Overview';
    if (p.startsWith('/admin/users')) return 'User Directory';
    if (p.startsWith('/admin/aws-accounts')) return 'AWS Accounts';
    if (p.startsWith('/admin/resources')) return 'Cloud Resources';
    if (p.startsWith('/admin/alerts')) return 'Security Findings';
    if (p.startsWith('/admin/scans')) return 'STS AssumeRole Scans';
    if (p.startsWith('/admin/notifications')) return 'Notification Logs';
    if (p.startsWith('/admin/audit-logs')) return 'Security Audit Trail';
    if (p.startsWith('/admin/analytics')) return 'Platform Telemetry';
    if (p.startsWith('/admin/settings')) return 'Settings & Diagnostics';
    return 'Console';
  };

  return (
    <header className="h-16 bg-guardian-sidebar/80 backdrop-blur-xl border-b border-guardian-border px-3 sm:px-6 flex items-center justify-between sticky top-0 z-30 transition-all">
      {/* Left: Mobile Toggle & Breadcrumb Title */}
      <div className="flex items-center gap-2 sm:gap-3 min-w-0">
        <button
          onClick={onOpenMobileSidebar}
          aria-label="Open sidebar"
          className="lg:hidden p-2 rounded-lg text-guardian-muted hover:text-guardian-text hover:bg-guardian-cardElevated transition-colors cursor-pointer shrink-0"
        >
          <Menu className="w-4 h-4" />
        </button>

        <div className="flex items-center gap-1.5 sm:gap-2 text-xs font-semibold truncate">
          <span className="text-guardian-muted hidden md:inline shrink-0">AWS Guardian</span>
          <span className="text-guardian-dimmed hidden md:inline shrink-0">/</span>
          <span className="text-guardian-text font-bold truncate">{getBreadcrumbTitle()}</span>
        </div>
      </div>

      {/* Center/Right: Search, Health, Theme, Notifications */}
      <div className="flex items-center gap-1.5 sm:gap-3 shrink-0">
        {/* Global Search Trigger button */}
        <button
          onClick={onOpenSearch}
          className="flex items-center gap-2 px-2.5 sm:px-3 py-1.5 rounded-xl bg-guardian-card/90 backdrop-blur-md border border-guardian-border text-guardian-muted hover:text-guardian-text hover:border-guardian-borderHover transition-all text-xs w-auto sm:w-60 md:w-64 justify-between cursor-pointer group shadow-xs"
        >
          <div className="flex items-center gap-2 truncate">
            <Search className="w-3.5 h-3.5 text-guardian-muted group-hover:text-brand-500 transition-colors shrink-0" />
            <span className="hidden sm:inline truncate">Search users, accounts...</span>
          </div>
          <kbd className="hidden sm:inline-block px-1.5 py-0.5 text-[9px] font-mono rounded bg-guardian-cardElevated text-guardian-muted border border-guardian-border">
            ⌘K
          </kbd>
        </button>

        {/* System Health Indicator */}
        <div className="hidden lg:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-guardian-card/90 backdrop-blur-md border border-guardian-border text-xs">
          <span
            className={`w-2 h-2 rounded-full shrink-0 ${
              isHealthy ? 'bg-emerald-500 shadow-xs shadow-emerald-500/50' : 'bg-amber-500'
            }`}
          />
          <span className="text-[11px] font-bold text-guardian-text">
            {isHealthy ? 'Operational' : 'Degraded'}
          </span>
        </div>

        {/* Theme Toggle */}
        <button
          onClick={cycleTheme}
          title={`Active Theme: ${theme}`}
          className="p-2 rounded-xl text-guardian-muted hover:text-guardian-text hover:bg-guardian-cardElevated transition-colors cursor-pointer border border-transparent hover:border-guardian-border"
        >
          {theme === 'dark' && <Moon className="w-4 h-4 text-brand-400" />}
          {theme === 'light' && <Sun className="w-4 h-4 text-amber-500" />}
          {theme === 'system' && <Laptop className="w-4 h-4 text-sky-400" />}
        </button>

        {/* Notification Bell */}
        <div className="relative">
          <button
            onClick={() => setNotifOpen(!notifOpen)}
            className="p-2 rounded-xl text-guardian-muted hover:text-guardian-text hover:bg-guardian-cardElevated transition-colors cursor-pointer relative border border-transparent hover:border-guardian-border"
          >
            <Bell className="w-4 h-4" />
            {activeAlerts.length > 0 && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-rose-500 ring-2 ring-guardian-bg" />
            )}
          </button>

          <NotificationDropdown
            isOpen={notifOpen}
            onClose={() => setNotifOpen(false)}
            recentAlerts={activeAlerts}
            unreadCount={criticalCount > 0 ? criticalCount : activeAlerts.length}
          />
        </div>
      </div>
    </header>
  );
};
