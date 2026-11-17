import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';
import { GlobalSearchModal } from './GlobalSearchModal';
import { useAlerts } from '../../hooks/useAlerts';

export const AdminLayout: React.FC = () => {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);

  const { data: alertsData } = useAlerts({ status: 'ACTIVE' });
  const activeAlertsCount = alertsData?.alerts?.length || 0;

  return (
    <div className="min-h-screen bg-guardian-bg text-guardian-text flex relative overflow-x-hidden">
      {/* Background Glassmorphic Glowing Orbs */}
      <div className="fixed top-[-10%] left-[15%] w-125 h-125 rounded-full bg-brand-600/10 blur-[130px] pointer-events-none z-0" />
      <div className="fixed bottom-[10%] right-[5%] w-112.5 h-112.5 rounded-full bg-cyan-500/8 blur-[120px] pointer-events-none z-0" />
      <div className="fixed top-[45%] right-[25%] w-87.5 h-87.5 rounded-full bg-purple-600/8 blur-[110px] pointer-events-none z-0" />

      {/* Sidebar with Glass Effect */}
      <Sidebar
        collapsed={collapsed}
        onToggleCollapse={() => setCollapsed(!collapsed)}
        mobileOpen={mobileOpen}
        onCloseMobile={() => setMobileOpen(false)}
        activeAlertsCount={activeAlertsCount}
      />

      {/* Main Content Area */}
      <div
        className={`flex-1 flex flex-col min-w-0 transition-all duration-300 relative z-10 ${
          collapsed ? 'lg:pl-18' : 'lg:pl-60'
        }`}
      >
        <Topbar
          onOpenMobileSidebar={() => setMobileOpen(true)}
          onOpenSearch={() => setSearchOpen(true)}
        />

        <main className="flex-1 p-3.5 sm:p-5 lg:p-6 max-w-[1600px] w-full mx-auto animate-in fade-in duration-150">
          <Outlet />
        </main>
      </div>

      {/* Global Search Modal */}
      <GlobalSearchModal isOpen={searchOpen} onClose={() => setSearchOpen(false)} />
    </div>
  );
};
