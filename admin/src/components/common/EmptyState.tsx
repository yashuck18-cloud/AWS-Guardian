import React from 'react';
import { cn } from '../../utils/cn';
import { FolderSearch, AlertTriangle, X } from 'lucide-react';
import { Button } from './Button';

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  className?: string;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon,
  title,
  description,
  action,
  className,
}) => {
  return (
    <div className={cn('py-8 px-6 flex flex-col items-center justify-center text-center', className)}>
      <div className="w-10 h-10 rounded-xl bg-white/5 border border-guardian-border flex items-center justify-center text-guardian-muted mb-3">
        {icon || <FolderSearch className="w-5 h-5 text-guardian-dimmed" />}
      </div>
      <h4 className="text-sm font-semibold text-guardian-text">{title}</h4>
      {description && <p className="text-xs text-guardian-muted max-w-sm mt-1 mb-3.5 leading-relaxed">{description}</p>}
      {action && (
        <Button variant="outline" size="sm" onClick={action.onClick}>
          {action.label}
        </Button>
      )}
    </div>
  );
};

interface ConfirmationDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  isDanger?: boolean;
  isLoading?: boolean;
}

export const ConfirmationDialog: React.FC<ConfirmationDialogProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  isDanger = false,
  isLoading = false,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
      <div
        className="w-full max-w-md bg-guardian-card border border-guardian-border rounded-xl shadow-2xl overflow-hidden p-6 space-y-4 animate-in zoom-in-95 duration-150"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            <div
              className={cn(
                'w-9 h-9 rounded-xl flex items-center justify-center',
                isDanger
                  ? 'bg-guardian-critical/15 text-guardian-critical border border-guardian-critical/30'
                  : 'bg-primary/15 text-primary-light border border-primary/30'
              )}
            >
              <AlertTriangle className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-guardian-text">{title}</h3>
              <p className="text-[11px] text-guardian-muted">Administrative Confirmation</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-guardian-muted hover:text-guardian-text p-1 rounded-md transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <p className="text-xs text-guardian-text/90 leading-relaxed bg-guardian-bg/60 p-3.5 rounded-lg border border-guardian-border">
          {message}
        </p>

        <div className="flex items-center justify-end gap-2.5 pt-2">
          <Button variant="secondary" size="sm" onClick={onClose} disabled={isLoading}>
            {cancelLabel}
          </Button>
          <Button
            variant={isDanger ? 'danger' : 'primary'}
            size="sm"
            onClick={onConfirm}
            isLoading={isLoading}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>
  );
};
