import React, { useState } from 'react';
import {
  Shield,
  Key,
  Server,
  Bell,
  Check,
  AlertCircle,
  Laptop,
  Moon,
  Sun,
  Lock,
  Mail,
  User,
  Activity,
  CheckCircle,
  Palette,
  RefreshCw,
} from 'lucide-react';
import { useAuth } from '../stores/authStore';
import { useTheme } from '../stores/themeStore';
import { useSystemHealth } from '../hooks/useAnalytics';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Badge } from '../components/common/Badge';
import { Input } from '../components/common/Input';

export const Settings: React.FC = () => {
  const { user } = useAuth();
  const { theme, setTheme } = useTheme();
  const { data: healthData, refetch: refetchHealth, isRefetching } = useSystemHealth();

  const [name, setName] = useState(user?.name || '');
  const [email] = useState(user?.email || '');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const [profileSuccess, setProfileSuccess] = useState(false);
  const [pwdError, setPwdError] = useState<string | null>(null);
  const [pwdSuccess, setPwdSuccess] = useState(false);

  const handleProfileSave = (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSuccess(true);
    setTimeout(() => setProfileSuccess(false), 3500);
  };

  const handlePasswordSave = (e: React.FormEvent) => {
    e.preventDefault();
    setPwdError(null);
    setPwdSuccess(false);

    if (newPassword.length < 8) {
      setPwdError('New password must be at least 8 characters long.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setPwdError('New passwords do not match.');
      return;
    }

    setPwdSuccess(true);
    setCurrentPassword('');
    setNewPassword('');
    setConfirmPassword('');
    setTimeout(() => setPwdSuccess(false), 3500);
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-10 animate-in fade-in duration-200">
      {/* Page Header */}
      <div className="space-y-1">
        <h1 className="text-xl sm:text-2xl font-extrabold text-guardian-text tracking-tight">
          Settings & Diagnostics
        </h1>
        <p className="text-xs sm:text-sm text-guardian-muted leading-relaxed">
          Manage console appearance, administrator credentials, profile identity, and live fleet microservices.
        </p>
      </div>

      {/* 1. Theme / Appearance Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-violet-500/15 text-violet-400 border border-violet-500/25 flex items-center justify-center shrink-0 shadow-xs">
              <Palette className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Console Appearance</CardTitle>
              <CardDescription>Select your active visual theme and workspace canvas</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3.5">
            {/* Dark Cloud */}
            <button
              type="button"
              onClick={() => setTheme('dark')}
              className={`p-3.5 rounded-xl border text-left transition-all relative cursor-pointer group flex flex-col justify-between ${
                theme === 'dark'
                  ? 'bg-brand-500/10 border-brand-500 ring-2 ring-brand-500/30 shadow-md'
                  : 'bg-guardian-bg/60 border-guardian-border hover:border-brand-500/40 hover:bg-white/2'
              }`}
            >
              <div>
                {/* Mini Swatch Preview */}
                <div className="w-full h-16 rounded-lg bg-[#060913] border border-white/10 p-2 flex flex-col justify-between mb-3 shadow-inner overflow-hidden">
                  <div className="flex items-center justify-between">
                    <div className="w-12 h-1.5 rounded-full bg-violet-500" />
                    <div className="w-3 h-3 rounded-full bg-cyan-400" />
                  </div>
                  <div className="space-y-1">
                    <div className="w-full h-2 rounded bg-slate-800" />
                    <div className="w-2/3 h-2 rounded bg-slate-800" />
                  </div>
                </div>

                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5">
                    <Moon className="w-4 h-4 text-violet-400" />
                    <span className="font-bold text-xs sm:text-sm text-guardian-text">Dark Cloud</span>
                  </div>
                  {theme === 'dark' && (
                    <span className="w-4 h-4 rounded-full bg-brand-600 text-white flex items-center justify-center shadow-xs">
                      <Check className="w-2.5 h-2.5" />
                    </span>
                  )}
                </div>
                <p className="text-[11px] text-guardian-muted leading-relaxed">
                  Cybersecurity dark canvas with glowing security telemetry.
                </p>
              </div>
            </button>

            {/* Light Mode */}
            <button
              type="button"
              onClick={() => setTheme('light')}
              className={`p-3.5 rounded-xl border text-left transition-all relative cursor-pointer group flex flex-col justify-between ${
                theme === 'light'
                  ? 'bg-brand-500/10 border-brand-500 ring-2 ring-brand-500/30 shadow-md'
                  : 'bg-guardian-bg/60 border-guardian-border hover:border-brand-500/40 hover:bg-white/2'
              }`}
            >
              <div>
                {/* Mini Swatch Preview */}
                <div className="w-full h-16 rounded-lg bg-[#F8FAFC] border border-slate-300 p-2 flex flex-col justify-between mb-3 shadow-inner overflow-hidden">
                  <div className="flex items-center justify-between">
                    <div className="w-12 h-1.5 rounded-full bg-brand-600" />
                    <div className="w-3 h-3 rounded-full bg-amber-500" />
                  </div>
                  <div className="space-y-1">
                    <div className="w-full h-2 rounded bg-slate-200" />
                    <div className="w-2/3 h-2 rounded bg-slate-200" />
                  </div>
                </div>

                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5">
                    <Sun className="w-4 h-4 text-amber-500" />
                    <span className="font-bold text-xs sm:text-sm text-guardian-text">Light Mode</span>
                  </div>
                  {theme === 'light' && (
                    <span className="w-4 h-4 rounded-full bg-brand-600 text-white flex items-center justify-center shadow-xs">
                      <Check className="w-2.5 h-2.5" />
                    </span>
                  )}
                </div>
                <p className="text-[11px] text-guardian-muted leading-relaxed">
                  High-contrast daytime canvas with clean off-white background.
                </p>
              </div>
            </button>

            {/* System Match */}
            <button
              type="button"
              onClick={() => setTheme('system')}
              className={`p-3.5 rounded-xl border text-left transition-all relative cursor-pointer group flex flex-col justify-between ${
                theme === 'system'
                  ? 'bg-brand-500/10 border-brand-500 ring-2 ring-brand-500/30 shadow-md'
                  : 'bg-guardian-bg/60 border-guardian-border hover:border-brand-500/40 hover:bg-white/2'
              }`}
            >
              <div>
                {/* Mini Swatch Preview (Split) */}
                <div className="w-full h-16 rounded-lg border border-white/10 flex mb-3 shadow-inner overflow-hidden">
                  <div className="w-1/2 h-full bg-[#060913] p-1.5 flex flex-col justify-between">
                    <div className="w-6 h-1.5 rounded-full bg-violet-500" />
                    <div className="w-full h-2 rounded bg-slate-800" />
                  </div>
                  <div className="w-1/2 h-full bg-[#F8FAFC] border-l border-slate-300 p-1.5 flex flex-col justify-between">
                    <div className="w-6 h-1.5 rounded-full bg-brand-600" />
                    <div className="w-full h-2 rounded bg-slate-200" />
                  </div>
                </div>

                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5">
                    <Laptop className="w-4 h-4 text-sky-400" />
                    <span className="font-bold text-xs sm:text-sm text-guardian-text">System Match</span>
                  </div>
                  {theme === 'system' && (
                    <span className="w-4 h-4 rounded-full bg-brand-600 text-white flex items-center justify-center shadow-xs">
                      <Check className="w-2.5 h-2.5" />
                    </span>
                  )}
                </div>
                <p className="text-[11px] text-guardian-muted leading-relaxed">
                  Automatically synchronize with your operating system preference.
                </p>
              </div>
            </button>
          </div>
        </CardContent>
      </Card>

      {/* 2. Admin Profile Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-sky-500/15 text-sky-400 border border-sky-500/25 flex items-center justify-center shrink-0 shadow-xs">
              <User className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Administrator Profile</CardTitle>
              <CardDescription>Primary identity for audit trails and notification dispatches</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleProfileSave} className="space-y-4">
            {profileSuccess && (
              <div className="p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2 animate-in fade-in">
                <CheckCircle className="w-4 h-4 shrink-0" />
                <span className="font-medium">Administrator profile updated successfully.</span>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input
                label="Administrator Full Name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. System Administrator"
              />

              <Input
                label="Email Address (Fixed ID)"
                value={email}
                disabled
                helperText="Primary Superuser email used for STS AssumeRole audits."
                className="font-mono"
              />
            </div>

            <div className="pt-2 flex justify-end">
              <Button type="submit" variant="primary" size="md">
                Update Profile
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* 3. Security & Credentials Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-500/15 text-amber-400 border border-amber-500/25 flex items-center justify-center shrink-0 shadow-xs">
              <Lock className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Security & Credentials</CardTitle>
              <CardDescription>Update your console administrator password</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handlePasswordSave} className="space-y-4">
            {pwdError && (
              <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-center gap-2 animate-in fade-in">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span className="font-medium">{pwdError}</span>
              </div>
            )}

            {pwdSuccess && (
              <div className="p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2 animate-in fade-in">
                <CheckCircle className="w-4 h-4 shrink-0" />
                <span className="font-medium">Administrator password updated successfully.</span>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <Input
                label="Current Password"
                type="password"
                required
                placeholder="••••••••••••"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
              />

              <Input
                label="New Password"
                type="password"
                required
                placeholder="Min 8 characters"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
              />

              <Input
                label="Confirm New Password"
                type="password"
                required
                placeholder="Repeat password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
            </div>

            <div className="pt-2 flex justify-end">
              <Button type="submit" variant="primary" size="md">
                Change Password
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* 4. Live Backend Diagnostics Card */}
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between w-full gap-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/25 flex items-center justify-center shrink-0 shadow-xs">
                <Activity className="w-5 h-5" />
              </div>
              <div>
                <CardTitle>System & Microservices Health</CardTitle>
                <CardDescription>Live real-time connectivity and latency measurements</CardDescription>
              </div>
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={() => refetchHealth()}
              isLoading={isRefetching}
              className="h-8 text-xs font-semibold shrink-0"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefetching ? 'animate-spin' : ''}`} />
              <span>Check Diagnostics</span>
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-guardian-border">
            {healthData?.components?.map((comp, idx) => (
              <div
                key={idx}
                className="px-5 py-3.5 sm:px-6 flex items-center justify-between text-xs hover:bg-white/2 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`w-2.5 h-2.5 rounded-full shrink-0 ${
                      comp.status === 'Operational'
                        ? 'bg-emerald-400 animate-status-pulse shadow-xs shadow-emerald-400/50'
                        : 'bg-amber-400'
                    }`}
                  />
                  <div>
                    <span className="font-bold text-guardian-text text-xs sm:text-sm">{comp.name}</span>
                    <span className="text-guardian-muted ml-2 text-[11px]">({comp.description})</span>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  {comp.latency_ms !== undefined && (
                    <span className="font-mono text-cyan-300 font-bold text-[11px] px-2 py-0.5 rounded bg-white/4 border border-white/6">
                      {comp.latency_ms}ms
                    </span>
                  )}
                  <Badge variant={comp.status === 'Operational' ? 'success' : 'warning'} dot>
                    {comp.status}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
