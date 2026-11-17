import React from 'react';
import { cn } from '../../utils/cn';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, leftIcon, rightIcon, className, id, ...props }, ref) => {
    const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);

    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label htmlFor={inputId} className="block text-xs font-bold text-guardian-text tracking-wide">
            {label}
          </label>
        )}
        <div className="relative flex items-center">
          {leftIcon && (
            <div className="absolute left-3 text-guardian-muted flex items-center pointer-events-none">
              {leftIcon}
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            className={cn(
              'w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs sm:text-sm rounded-lg border border-guardian-border transition-all duration-150',
              'focus:outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-500/25',
              leftIcon ? 'pl-9' : 'pl-3.5',
              rightIcon ? 'pr-9' : 'pr-3.5',
              'py-2.5 h-10',
              error && 'border-red-500 focus:border-red-500 focus:ring-red-500/25',
              props.disabled && 'opacity-60 cursor-not-allowed bg-guardian-cardElevated',
              className
            )}
            {...props}
          />
          {rightIcon && (
            <div className="absolute right-3 text-guardian-muted flex items-center">
              {rightIcon}
            </div>
          )}
        </div>
        {error && <p className="text-[11px] font-medium text-red-400 mt-1">{error}</p>}
        {helperText && !error && <p className="text-[11px] text-guardian-muted mt-1">{helperText}</p>}
      </div>
    );
  }
);
Input.displayName = 'Input';

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  options: { label: string; value: string }[];
}

export const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, options, className, id, ...props }, ref) => {
    const selectId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);

    return (
      <div className="w-full space-y-1.5">
        {label && (
          <label htmlFor={selectId} className="block text-xs font-bold text-guardian-text tracking-wide">
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={cn(
            'w-full bg-guardian-bg text-guardian-text text-xs sm:text-sm rounded-lg border border-guardian-border px-3 py-2.5 h-10 transition-all duration-150',
            'focus:outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-500/25 cursor-pointer',
            error && 'border-red-500 focus:border-red-500 focus:ring-red-500/25',
            className
          )}
          {...props}
        >
          {options.map((opt) => (
            <option key={opt.value} value={opt.value} className="bg-guardian-card text-guardian-text">
              {opt.label}
            </option>
          ))}
        </select>
        {error && <p className="text-[11px] font-medium text-red-400 mt-1">{error}</p>}
      </div>
    );
  }
);
Select.displayName = 'Select';
