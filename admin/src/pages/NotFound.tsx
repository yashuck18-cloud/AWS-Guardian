import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldAlert } from 'lucide-react';
import { Button } from '../components/common/Button';

export const NotFound: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-[70vh] flex flex-col items-center justify-center text-center p-6 space-y-4">
      <div className="w-16 h-16 rounded-2xl bg-white/5 border border-guardian-border flex items-center justify-center text-guardian-critical shadow-lg">
        <ShieldAlert className="w-8 h-8" />
      </div>
      <div className="space-y-1">
        <h1 className="text-4xl font-extrabold text-guardian-text tracking-tight">404</h1>
        <h2 className="text-lg font-semibold text-guardian-text">Page Not Found</h2>
        <p className="text-xs text-guardian-muted max-w-sm mx-auto">
          The requested administrative console URL does not exist or has been relocated.
        </p>
      </div>

      <div className="pt-2">
        <Button onClick={() => navigate('/admin')}>
          Return to Dashboard
        </Button>
      </div>
    </div>
  );
};
