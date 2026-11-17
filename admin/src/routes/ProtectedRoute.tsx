import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../stores/authStore';
import { ShieldAlert, Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, isAdmin, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-guardian-bg flex flex-col items-center justify-center gap-3 text-guardian-text">
        <Loader2 className="w-8 h-8 animate-spin text-primary-light" />
        <span className="text-xs text-guardian-muted font-medium">Verifying Administrator Session...</span>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-guardian-bg flex flex-col items-center justify-center p-6 text-center space-y-4">
        <div className="w-16 h-16 rounded-2xl bg-guardian-critical/15 border border-guardian-critical/30 text-guardian-critical flex items-center justify-center shadow-lg">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <div className="space-y-1">
          <h1 className="text-xl font-bold text-guardian-text">Access Denied</h1>
          <p className="text-xs text-guardian-muted max-w-sm">
            Your account is authenticated, but does not possess platform administrator privileges (is_staff / is_superuser).
          </p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};
