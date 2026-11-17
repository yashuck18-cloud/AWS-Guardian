import React, { useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, AlertTriangle, CheckCircle, ArrowRight, Clock } from 'lucide-react';
import { formatTimeAgo } from '../../utils/cn';
import { AdminAlert } from '../../types';

interface NotificationDropdownProps {
  isOpen: boolean;
  onClose: () => void;
  recentAlerts: AdminAlert[];
  unreadCount: number;
}

export const NotificationDropdown: React.FC<NotificationDropdownProps> = ({
  isOpen,
  onClose,
  recentAlerts,
  unreadCount,
}) => {
  const dropdownRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        onClose();
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      ref={dropdownRef}
      className="absolute right-0 top-12 w-80 sm:w-96 bg-guardian-card border border-guardian-border rounded-xl shadow-2xl overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-150"
    >
      <div className="px-4 py-3 border-b border-guardian-border flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Bell className="w-4 h-4 text-primary-light" />
          <span className="text-xs font-semibold text-guardian-text">Notification Center</span>
        </div>
        {unreadCount > 0 && (
          <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-guardian-critical text-white">
            {unreadCount} Active
          </span>
        )}
      </div>

      <div className="max-h-80 overflow-y-auto divide-y divide-guardian-border">
        {recentAlerts.length === 0 ? (
          <div className="py-8 px-4 text-center">
            <CheckCircle className="w-8 h-8 text-guardian-success mx-auto mb-2 opacity-80" />
            <p className="text-xs font-medium text-guardian-text">All systems quiet</p>
            <p className="text-[11px] text-guardian-muted mt-0.5">No critical alerts detected.</p>
          </div>
        ) : (
          recentAlerts.slice(0, 5).map((alert) => (
            <div
              key={alert.id}
              onClick={() => {
                onClose();
                navigate(`/admin/alerts/${alert.id}`);
              }}
              className="p-3.5 hover:bg-white/5 cursor-pointer transition-colors space-y-1"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-1.5">
                  <AlertTriangle className="w-3.5 h-3.5 text-guardian-critical shrink-0" />
                  <span className="text-xs font-semibold text-guardian-text truncate max-w-50">
                    {alert.title}
                  </span>
                </div>
                <span className="text-[10px] text-guardian-dimmed flex items-center gap-1 shrink-0">
                  <Clock className="w-3 h-3" />
                  {formatTimeAgo(alert.last_detected_at)}
                </span>
              </div>
              <p className="text-[11px] text-guardian-muted line-clamp-2 pl-5">
                {alert.description}
              </p>
              <div className="pl-5 text-[10px] font-mono text-primary-light">
                AWS Account: {alert.account_name} ({alert.account_aws_id})
              </div>
            </div>
          ))
        )}
      </div>

      <div className="p-2.5 bg-guardian-bg/60 border-t border-guardian-border flex items-center justify-between">
        <button
          onClick={() => {
            onClose();
            navigate('/admin/alerts');
          }}
          className="text-xs text-primary-light hover:text-primary-hover font-semibold flex items-center gap-1 mx-auto transition-colors"
        >
          <span>View All Security Alerts</span>
          <ArrowRight className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
};
