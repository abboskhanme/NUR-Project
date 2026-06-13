import { cn } from '@/lib/cn';
import { ReactNode } from 'react';

export default function Card({
  children, className, title, action,
}: {
  children: ReactNode;
  className?: string;
  title?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className={cn('card', className)}>
      {(title || action) && (
        <div className="flex items-center justify-between mb-4">
          {title && <h3 className="font-semibold text-base">{title}</h3>}
          {action}
        </div>
      )}
      {children}
    </div>
  );
}
