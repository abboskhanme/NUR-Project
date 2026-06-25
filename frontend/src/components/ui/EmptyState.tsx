import { Inbox } from 'lucide-react';

export default function EmptyState({
  title,
  description,
}: { title?: string; description?: string }) {
  const resolvedTitle = title ?? "Ma'lumot yo'q";
  const resolvedDescription = description ?? "Hozircha bu yerda hech narsa yo'q";

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
