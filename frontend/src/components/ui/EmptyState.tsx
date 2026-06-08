import { Inbox } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export default function EmptyState({
  title,
  description,
}: { title?: string; description?: string }) {
  const { t } = useTranslation();
  const resolvedTitle = title ?? t('ui.emptyState.title');
  const resolvedDescription = description ?? t('ui.emptyState.description');

  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mb-3">
        <Inbox className="text-primary" size={28} />
      </div>
      <div className="font-semibold text-ink">{resolvedTitle}</div>
      <div className="text-sm text-ink-soft mt-1">{resolvedDescription}</div>
    </div>
  );
}
