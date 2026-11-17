import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Cloud,
  Layers,
  AlertTriangle,
  ScanLine,
  Bell,
  FileText,
  BarChart3,
  Settings,
  LogOut,
  Shield,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { cn } from '../../utils/cn';
import { useAuth } from '../../stores/authStore';

interface SidebarProps {
  collapsed: boolean;
  onToggleCollapse: () => void;
  mobileOpen: boolean;
  onCloseMobile: () => void;
  activeAlertsCount?: number;
}

interface NavItem {
  label: string;
  path: string;
  icon: any;
  exact?: boolean;
  badge?: number;
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

export const Sidebar: React.FC<SidebarProps> = ({
  collapsed,
  onToggleCollapse,
  mobileOpen,
  onCloseMobile,
  activeAlertsCount,
}) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const navGroups: NavGroup[] = [
    {
      label: 'OVERVIEW',
      items: [
        { label: 'Dashboard', path: '/admin', icon: LayoutDashboard, exact: true },
      ],
    },
    {
      label: 'MANAGEMENT',
      items: [
        { label: 'Users', path: '/admin/users', icon: Users },
        { label: 'AWS Accounts', path: '/admin/aws-accounts', icon: Cloud },
        { label: 'Resources', path: '/admin/resources', icon: Layers },
      ],
    },
    {
      label: 'MONITORING',
      items: [
        { label: 'Alerts', path: '/admin/alerts', icon: AlertTriangle, badge: activeAlertsCount },
        { label: 'Scans', path: '/admin/scans', icon: ScanLine },
        { label: 'Notifications', path: '/admin/notifications', icon: Bell },
      ],
    },
    {
      label: 'SYSTEM',
      items: [
        { label: 'Audit Logs', path: '/admin/audit-logs', icon: FileText },
        { label: 'Analytics', path: '/admin/analytics', icon: BarChart3 },
        { label: 'Settings', path: '/admin/settings', icon: Settings },
      ],
    },
  ];

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden transition-opacity"
          onClick={onCloseMobile}
        />
      )}

      <aside
        className={cn(
          'fixed top-0 left-0 bottom-0 z-50 flex flex-col bg-guardian-sidebar/85 backdrop-blur-xl border-r border-guardian-border transition-all duration-300 shadow-2xl',
          collapsed ? 'w-18' : 'w-60',
          mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        )}
      >
        {/* Brand Header */}
        <div className="h-16 flex items-center justify-between px-4 border-b border-guardian-border shrink-0">
          <div className="flex items-center gap-3 overflow-hidden">
            <img
              src="/logo_icon.png"
              alt="AWS Guardian Logo"
              className="w-8 h-8 rounded-xl object-cover shrink-0 shadow-md shadow-cyan-500/20"
            />
            {!collapsed && (
              <div className="flex flex-col truncate">
                <span className="font-extrabold text-sm text-guardian-text tracking-tight leading-tight">AWS Guardian</span>
                <span className="text-[10px] text-guardian-muted font-semibold uppercase tracking-wider">Admin Console</span>
              </div>
            )}
          </div>

          <button
            onClick={onToggleCollapse}
            aria-label="Toggle sidebar collapse"
            className="hidden lg:flex items-center justify-center w-6 h-6 rounded-lg text-guardian-muted hover:text-guardian-text hover:bg-guardian-cardElevated transition-colors cursor-pointer"
          >
            {collapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
          </button>
        </div>

        {/* Grouped Navigation */}
        <div className="flex-1 overflow-y-auto px-3 py-4 space-y-5">
          {navGroups.map((group, gIdx) => (
            <div key={gIdx} className="space-y-1">
              {!collapsed && (
                <div className="text-[10px] font-bold text-guardian-dimmed uppercase tracking-widest px-3 mb-1.5">
                  {group.label}
                </div>
              )}
              {group.items.map((item) => {
                const Icon = item.icon;
                return (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    end={item.exact}
                    onClick={onCloseMobile}
                    className={({ isActive }) =>
                      cn(
                        'flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all group relative',
                        isActive
                          ? 'bg-brand-600 text-white! shadow-md shadow-brand-600/30'
                          : 'text-guardian-muted hover:text-guardian-text hover:bg-guardian-cardElevated'
                      )
                    }
                  >
                    <Icon className="w-4 h-4 shrink-0" />
                    {!collapsed && <span className="truncate">{item.label}</span>}
                    {item.badge !== undefined && item.badge > 0 && (
                      <span
                        className={cn(
                          'ml-auto px-1.5 py-0.2 text-[10px] font-bold rounded-full bg-rose-500 text-white shrink-0 font-mono',
                          collapsed && 'absolute top-1 right-1 px-1 py-0 text-[8px]'
                        )}
                      >
                        {item.badge}
                      </span>
                    )}
                  </NavLink>
                );
              })}
            </div>
          ))}
        </div>

        {/* Bottom User Profile Section */}
        <div className="p-3.5 border-t border-guardian-border bg-guardian-bg/60 backdrop-blur-md shrink-0">
          {!collapsed ? (
            <div className="space-y-2.5">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-brand-600/20 border border-brand-500/30 flex items-center justify-center text-brand-500 font-bold text-xs shrink-0">
                  {user?.name?.[0]?.toUpperCase() || 'A'}
                </div>
                <div className="flex flex-col truncate">
                  <span className="text-xs font-bold text-guardian-text truncate leading-tight">
                    {user?.name || 'Admin User'}
                  </span>
                  <span className="text-[11px] text-guardian-muted truncate font-mono">
                    {user?.email || 'admin@awsguardian.com'}
                  </span>
                </div>
              </div>

              <button
                onClick={handleLogout}
                className="w-full flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-xs font-semibold text-guardian-muted hover:text-rose-500 hover:bg-rose-500/10 transition-colors cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-brand-600/20 border border-brand-500/30 flex items-center justify-center text-brand-500 font-bold text-xs shrink-0">
                {user?.name?.[0]?.toUpperCase() || 'A'}
              </div>
              <button
                onClick={handleLogout}
                title="Sign Out"
                className="p-1.5 rounded-lg text-guardian-muted hover:text-rose-500 hover:bg-rose-500/10 transition-colors cursor-pointer"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>
      </aside>
    </>
  );
};
