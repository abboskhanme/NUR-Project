import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Send, Clock, CheckCircle2, AlertTriangle, SkipForward, RefreshCw,
  Image as ImageIcon, Video, FileText, MessageSquare, Settings2,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { cn } from '@/lib/cn';
import { formatDateTime } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import {
  waBridgeApi, KIND_LABELS, POST_STATUS_LABELS, POST_STATUS_STYLE,
  type ChannelPost, type PostStatus,
} from '@/features/wa-bridge/api';

const POLL_MS = 20_000;

const FILTERS: { key: '' | PostStatus; label: string }[] = [
  { key: '', label: 'Hammasi' },
  { key: 'pending', label: 'Navbatda' },
  { key: 'sent', label: 'Yuborildi' },
  { key: 'posted', label: 'Kanalga qo‘yildi' },
  { key: 'failed', label: 'Xato' },
  { key: 'skipped', label: 'O‘tkazilgan' },
];

function KindIcon({ kind }: { kind: ChannelPost['kind'] }) {
  const size = 14;
  if (kind === 'photo') return <ImageIcon size={size} />;
  if (kind === 'video') return <Video size={size} />;
  if (kind === 'document') return <FileText size={size} />;
  return <MessageSquare size={size} />;
}

/**
 * Telegram kanaldagi post → belgilangan vaqtdan keyin xodimning WhatsApp
 * raqamiga yuboriladi, u forward qilib kanalga qo'yadi.
 * WhatsApp Kanallariga to'g'ridan-to'g'ri yozadigan rasmiy API yo'q.
 */
export default function WaBridgePage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('telegram:write');
  const [status, setStatus] = useState<'' | PostStatus>('');
  const [busy, setBusy] = useState<string | null>(null);

  const summaryQ = useQuery({
    queryKey: ['wa-bridge-summary'],
    queryFn: waBridgeApi.summary,
    refetchInterval: POLL_MS,
  });
  const postsQ = useQuery({
    queryKey: ['wa-bridge-posts', status],
    queryFn: () => waBridgeApi.posts({ status: status || undefined, limit: 100 }),
    refetchInterval: POLL_MS,
  });

  const s = summaryQ.data;
  const posts = postsQ.data ?? [];

  async function act(id: string, fn: () => Promise<unknown>, message: string) {
    setBusy(id);
    try {
      await fn();
      toast.success(message);
      qc.invalidateQueries({ queryKey: ['wa-bridge-posts'] });
      qc.invalidateQueries({ queryKey: ['wa-bridge-summary'] });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Amal bajarilmadi');
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Send size={22} className="text-primary" /> WhatsApp navbati
        </h1>
        <p className="text-sm text-ink-soft">
          Telegram kanaldagi post {s?.delay_minutes ?? 60} daqiqadan keyin xodim
          WhatsApp'iga yuboriladi — u forward qilib kanalga qo‘yadi.
        </p>
      </div>

      {/* Sozlama holati */}
      {s && (!s.enabled || !s.watching || !s.sending) && (
        <div className="rounded-card border border-amber-200 bg-amber-50 text-amber-900 p-3 text-sm flex gap-2">
          <Settings2 size={16} className="shrink-0 mt-0.5" />
          <div>
            <div className="font-medium">Ko‘prik hali to‘liq sozlanmagan</div>
            <ul className="mt-1 space-y-0.5 text-xs">
              {!s.enabled && <li>• «Tizim sozlamalari → Telegram → WhatsApp» da ko‘prikni yoqing</li>}
              {!s.watching && <li>• Telegram bot tokenini kiriting va botni kanalga admin qiling</li>}
              {!s.sending && <li>• WhatsApp Phone Number ID, token va qabul qiluvchi raqamlarni to‘ldiring</li>}
            </ul>
          </div>
        </div>
      )}

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi label="Navbatda" value={s?.pending ?? 0} tone="warning" icon={<Clock size={18} />} />
        <Kpi label="Yuborildi" value={s?.sent ?? 0} tone="info" icon={<Send size={18} />} />
        <Kpi label="Kanalga qo‘yildi" value={s?.posted ?? 0} tone="success" icon={<CheckCircle2 size={18} />} />
        <Kpi label="Xato" value={s?.failed ?? 0} tone="danger" icon={<AlertTriangle size={18} />} />
      </div>

      {/* Filtrlar */}
      <div className="flex flex-wrap gap-1.5">
        {FILTERS.map((f) => (
          <button key={f.key || 'all'} onClick={() => setStatus(f.key)}
            className={cn('px-3 py-1.5 rounded-button text-sm font-medium transition',
              status === f.key ? 'bg-primary text-white'
                               : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
            {f.label}
          </button>
        ))}
      </div>

      {postsQ.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-24 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : posts.length === 0 ? (
        <EmptyState
          title="Post yo‘q"
          description="Telegram kanalga post tashlansa, u shu yerda navbatga tushadi"
        />
      ) : (
        <div className="space-y-2">
          {posts.map((p) => (
            <Card key={p.id}>
              <div className="flex gap-3">
                {/* Media ko'rinishi */}
                {p.has_media && p.kind === 'photo' ? (
                  <img src={waBridgeApi.mediaUrl(p.id)} alt=""
                       className="w-20 h-20 rounded-button object-cover bg-black/5 shrink-0" />
                ) : (
                  <div className="w-20 h-20 rounded-button bg-black/[0.04] flex items-center justify-center shrink-0 text-ink-soft">
                    <KindIcon kind={p.kind} />
                  </div>
                )}

                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className={cn('badge', POST_STATUS_STYLE[p.status])}>
                      {POST_STATUS_LABELS[p.status]}
                    </span>
                    <span className="badge bg-black/[0.05] text-ink-soft inline-flex items-center gap-1">
                      <KindIcon kind={p.kind} /> {KIND_LABELS[p.kind]}
                    </span>
                    {p.media_size > 0 && (
                      <span className="text-xs text-ink-soft">
                        {(p.media_size / 1048576).toFixed(1)} MB
                      </span>
                    )}
                  </div>

                  <p className="text-sm mt-1.5 line-clamp-3 whitespace-pre-wrap break-words">
                    {p.caption || <span className="text-ink-soft">(matnsiz)</span>}
                  </p>

                  <div className="text-xs text-ink-soft mt-1.5 flex flex-wrap gap-x-3 gap-y-0.5">
                    <span>Telegram: {formatDateTime(p.posted_at)}</span>
                    <span>
                      {p.status === 'pending' ? 'Yuboriladi: ' : 'Reja: '}
                      {formatDateTime(p.planned_at)}
                    </span>
                    {p.sent_at && <span>Yuborildi: {formatDateTime(p.sent_at)}</span>}
                    {p.sent_to && <span>Kimga: {p.sent_to}</span>}
                  </div>

                  {p.error && (
                    <div className="text-xs text-danger mt-1.5">{p.error}</div>
                  )}
                </div>

                {canWrite && (
                  <div className="flex flex-col gap-1.5 shrink-0">
                    {(p.status === 'sent') && (
                      <button disabled={busy === p.id}
                        onClick={() => act(p.id, () => waBridgeApi.markPosted(p.id), 'Belgilandi')}
                        className="btn-action bg-emerald-100 text-emerald-700 hover:bg-emerald-200 text-xs">
                        <CheckCircle2 size={14} /> Qo‘ydim
                      </button>
                    )}
                    {p.status !== 'pending' && (
                      <button disabled={busy === p.id}
                        onClick={() => act(p.id, () => waBridgeApi.retry(p.id), 'Navbatga qo‘yildi')}
                        className="btn-action bg-black/[0.05] text-ink-soft hover:bg-black/10 text-xs">
                        <RefreshCw size={14} /> Qayta
                      </button>
                    )}
                    {p.status === 'pending' && (
                      <button disabled={busy === p.id}
                        onClick={() => act(p.id, () => waBridgeApi.skip(p.id), 'O‘tkazib yuborildi')}
                        className="btn-action bg-black/[0.05] text-ink-soft hover:bg-black/10 text-xs">
                        <SkipForward size={14} /> O‘tkazish
                      </button>
                    )}
                  </div>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

function Kpi({ label, value, tone, icon }: {
  label: string; value: number; tone: 'warning' | 'info' | 'success' | 'danger';
  icon: React.ReactNode;
}) {
  const styles = {
    warning: 'border-amber-200 bg-amber-50 text-amber-800',
    info: 'border-sky-200 bg-sky-50 text-sky-800',
    success: 'border-emerald-200 bg-emerald-50 text-emerald-800',
    danger: 'border-rose-200 bg-rose-50 text-rose-800',
  }[tone];
  return (
    <div className={cn('rounded-card border p-4 flex items-start justify-between', styles)}>
      <div>
        <div className="text-sm font-medium opacity-90">{label}</div>
        <div className="text-2xl font-bold mt-1.5">{value}</div>
      </div>
      <div className="opacity-70">{icon}</div>
    </div>
  );
}
