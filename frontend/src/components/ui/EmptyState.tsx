import { Inbox } from 'lucide-react';

export default function EmptyState({
  title = "Ma'lumot yo'q",
  description = "Hozircha bu yerda hech narsa yo'q",
}: { title?: string; description?: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mb-3">
        <Inbox className="text-primary" size={28} />
      </div>
      <div className="font-semibold text-ink">{title}</div>
      <div className="text-sm text-ink-soft mt-1">{description}</div>
    </div>
  );
}
