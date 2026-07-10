import type { Target } from '@/features/targets/TargetModal';

export type TargetTone = 'success' | 'danger' | 'primary';

/** Sana o'tib ketganini tekshirish (mahalliy vaqt bo'yicha, kun aniqligida). */
export function isOverdue(target: Target): boolean {
  if (!target.deadline || target.is_completed) return false;
  return daysLeft(target)! < 0;
}

/** Muddatgacha qolgan kunlar. Muddat yo'q bo'lsa — null. */
export function daysLeft(target: Target): number | null {
  if (!target.deadline) return null;
  const [y, m, d] = target.deadline.split('-').map(Number);
  const end = new Date(y, m - 1, d);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((end.getTime() - today.getTime()) / 86_400_000);
}

/** Maqsad holatiga mos rang: bajarilgan — yashil, muddati o'tgan — qizil. */
export function targetTone(target: Target): TargetTone {
  if (target.is_completed) return 'success';
  if (isOverdue(target)) return 'danger';
  return 'primary';
}

const BAR_TONES: Record<TargetTone, string> = {
  success: 'bg-success',
  danger: 'bg-danger',
  primary: 'bg-primary',
};

/** Maqsadga qancha yig'ilganini ko'rsatuvchi progress chizig'i. */
export default function TargetProgress({
  progress, tone, size = 'md',
}: { progress: number; tone: TargetTone; size?: 'sm' | 'md' }) {
  const pct = Math.max(0, Math.min(100, progress));
  return (
    <div className={`w-full rounded-full bg-black/[0.07] overflow-hidden ${size === 'sm' ? 'h-1.5' : 'h-2.5'}`}>
      <div
        className={`h-full rounded-full transition-[width] duration-500 ease-out ${BAR_TONES[tone]}`}
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}
