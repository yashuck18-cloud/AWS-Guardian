import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Shield, Lock, Mail, AlertCircle, Loader2, KeyRound, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../stores/authStore';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('admin@awsguardian.com');
  const [password, setPassword] = useState('Admin@123456');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      await login({ email: email.trim(), password });
      navigate('/admin');
    } catch (err: any) {
      setError(
        err.message ||
        err.response?.data?.detail ||
        err.response?.data?.message ||
        'Authentication failed. Please verify your administrator credentials.'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleFillDemo = () => {
    setEmail('admin@awsguardian.com');
    setPassword('Admin@123456');
    setError(null);
  };

  return (
    <div className="min-h-screen bg-guardian-bg text-guardian-text flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background Decorative Mesh Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-brand-600/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-10 right-10 w-72 h-72 bg-sky-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-guardian-card border border-guardian-border rounded-2xl shadow-2xl p-7 space-y-6 relative z-10">
        {/* Header */}
        <div className="text-center space-y-2">
          <div className="relative inline-block mx-auto">
            <img
              src="/logo_icon.png"
              alt="AWS Guardian Logo"
              className="w-16 h-16 rounded-2xl mx-auto shadow-xl shadow-cyan-500/25 border border-cyan-500/30 object-cover"
            />
          </div>
          <div>
            <h1 className="text-xl font-extrabold text-guardian-text tracking-tight">AWS GUARDIAN</h1>
            <p className="text-[10px] font-bold text-brand-500 uppercase tracking-widest mt-0.5">Admin Security Console</p>
          </div>
          <p className="text-xs text-guardian-muted">
            Platform administration, IAM STS AssumeRole monitoring & fleet security
          </p>
        </div>

        {/* Error Banner */}
        {error && (
          <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/25 text-red-400 text-xs flex items-start gap-2.5 animate-in fade-in">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span className="leading-relaxed">{error}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label className="block text-xs font-semibold text-guardian-text">Administrator Email</label>
            <div className="relative flex items-center">
              <Mail className="w-4 h-4 text-guardian-muted absolute left-3.5 pointer-events-none" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@awsguardian.com"
                className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-xl border border-guardian-border pl-10 pr-3 py-2.5 focus:outline-none focus:border-brand-500"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="block text-xs font-semibold text-guardian-text">Password</label>
            <div className="relative flex items-center">
              <Lock className="w-4 h-4 text-guardian-muted absolute left-3.5 pointer-events-none" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-xl border border-guardian-border pl-10 pr-10 py-2.5 focus:outline-none focus:border-brand-500"
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                className="absolute right-3 text-guardian-muted hover:text-guardian-text transition-colors p-1 rounded focus:outline-none cursor-pointer"
                title={showPassword ? 'Hide password' : 'Show password'}
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? (
                  <EyeOff className="w-4 h-4" />
                ) : (
                  <Eye className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full h-10 rounded-xl bg-brand-600 hover:bg-brand-700 active:scale-[0.99] text-white font-semibold text-xs transition-all shadow-md shadow-brand-600/20 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
          >
            {isLoading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Signing in...</span>
              </>
            ) : (
              <span>Sign In to Console</span>
            )}
          </button>
        </form>

        {/* Quick Credentials Info Box */}
        <div className="p-3 rounded-xl bg-guardian-bg border border-guardian-border flex items-center justify-between text-xs">
          <div>
            <div className="text-[11px] font-bold text-guardian-text">Default Admin Account</div>
            <div className="text-[10px] text-guardian-muted font-mono">admin@awsguardian.com / Admin@123456</div>
          </div>
          <button
            type="button"
            onClick={handleFillDemo}
            className="px-2 py-1 rounded bg-brand-600/20 text-brand-500 hover:bg-brand-600/30 text-[10px] font-bold transition-colors cursor-pointer flex items-center gap-1"
          >
            <KeyRound className="w-3 h-3" />
            <span>Fill</span>
          </button>
        </div>

        {/* Security badge footer */}
        <div className="pt-2 border-t border-guardian-border text-center">
          <p className="text-[11px] text-guardian-muted flex items-center justify-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block" />
            End-to-end encrypted session with RBAC security
          </p>
        </div>
      </div>
    </div>
  );
};
