import React from 'react';
import { Link } from 'react-router-dom';
import { ChevronRight, Home } from 'lucide-react';
import { cn } from '../../utils/cn';

export interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface BreadcrumbsProps {
  items: BreadcrumbItem[];
  className?: string;
}

export const Breadcrumbs: React.FC<BreadcrumbsProps> = ({ items, className }) => {
  return (
    <nav className={cn('flex items-center gap-1.5 text-xs text-guardian-muted mb-4', className)}>
      <Link
        to="/admin"
        className="flex items-center gap-1 hover:text-guardian-text transition-colors"
      >
        <Home className="w-3.5 h-3.5" />
        <span>Admin</span>
      </Link>

      {items.map((item, index) => {
        const isLast = index === items.length - 1;
        return (
          <React.Fragment key={index}>
            <ChevronRight className="w-3.5 h-3.5 text-guardian-dimmed" />
            {item.href && !isLast ? (
              <Link
                to={item.href}
                className="hover:text-guardian-text transition-colors font-medium"
              >
                {item.label}
              </Link>
            ) : (
              <span className="text-guardian-text font-semibold">{item.label}</span>
            )}
          </React.Fragment>
        );
      })}
    </nav>
  );
};
