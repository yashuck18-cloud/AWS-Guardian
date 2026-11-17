import React from 'react';
import { cn } from '../../utils/cn';
import { Loader2 } from 'lucide-react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg' | 'icon';
  isLoading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  className,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  disabled,
  ...props
}) => {
  const baseStyles =
    'inline-flex items-center justify-center font-semibold rounded-lg transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none select-none cursor-pointer';

  const variants = {
    primary:
      'bg-brand-600 hover:bg-brand-700 text-white shadow-sm hover:shadow-glow-brand border border-brand-500/30 active:bg-brand-800',
    secondary:
      'bg-guardian-cardElevated hover:bg-guardian-cardElevated2 text-guardian-text border border-guardian-border shadow-xs hover:border-guardian-borderHover active:bg-white/10',
    outline:
      'bg-transparent hover:bg-white/5 text-guardian-text border border-guardian-border hover:border-guardian-borderHover active:bg-white/10',
    danger:
      'bg-red-600 hover:bg-red-700 text-white shadow-sm border border-red-500/40 active:bg-red-800',
    ghost:
      'bg-transparent hover:bg-white/5 text-guardian-muted hover:text-guardian-text active:bg-white/10',
  };

  const sizes = {
    sm: 'px-3 py-1.5 text-xs gap-1.5 h-8',
    md: 'px-4 py-2 text-xs sm:text-sm gap-2 h-9.5',
    lg: 'px-5 py-2.5 text-sm sm:text-base gap-2.5 h-11',
    icon: 'w-9 h-9 p-0 rounded-lg text-guardian-muted hover:text-guardian-text',
  };

  return (
    <button
      className={cn(baseStyles, variants[variant], sizes[size], className)}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading && <Loader2 className="w-4 h-4 animate-spin text-current shrink-0" />}
      {children}
    </button>
  );
};
