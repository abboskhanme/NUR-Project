import { Flame, Instagram, MessageCircle, MessageSquare } from 'lucide-react';
import { cn } from '@/lib/cn';
import { LEAD_STATUS_LABELS, type LeadChannel, type LeadStatus } from '@/features/leads/api';

/** Kanal ikonkasi — Instagram / Telegram / WhatsApp (barcha ekranlarda bir xil) */
export function ChannelIcon({ channel, size = 13, className }: {
  channel: LeadChannel; size?: number; className?: string;
}) {
  if (channel === 'telegram') {
    return <MessageCircle size={size} className={cn('text-sky-500', className)} />;
  }
  if (channel === 'whatsapp') {
    return <MessageSquare size={size} className={cn('text-emerald-500', className)} />;
  }
  return <Instagram size={size} className={cn('text-pink-500', className)} />;
}

const STATUS_STYLES: Record<LeadStatus, string> = {
  new: 'bg-blue-100 text-blue-700',
  contacted: 'bg-amber-100 text-amber-700',
  qualified: 'bg-violet-100 text-violet-700',
  won: 'bg-emerald-100 text-emerald-700',
  lost: 'bg-gray-200 text-gray-600',
};

export function LeadStatusBadge({ status, className }: { status: string; className?: string }) {
  const style = STATUS_STYLES[status as LeadStatus] || 'bg-gray-100 text-gray-700';
  const label = LEAD_STATUS_LABELS[status as LeadStatus] ?? status;
  return <span className={cn('badge', style, className)}>{label}</span>;
}

/** Qiziqish balli (0..100) — issiq (≥70), iliq (40..69), sovuq (<40). */
export function ScoreBadge({ score, className }: { score: number; className?: string }) {
  const hot = score >= 70;
  const warm = score >= 40 && score < 70;
  const style = hot
    ? 'bg-red-100 text-red-700'
    : warm
      ? 'bg-amber-100 text-amber-700'
      : 'bg-gray-100 text-gray-600';
  return (
    <span className={cn('badge inline-flex items-center gap-1', style, className)}>
      {hot && <Flame size={12} />}
      {score}
    </span>
  );
}
