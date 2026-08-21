import { useEffect, useMemo, useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Search, Send, Instagram, Phone, Bot, BotOff, Lock, Clock, ExternalLink, Loader2,
  MessageCircle,
} from 'lucide-react';

import { cn } from '@/lib/cn';
import { formatDateTime, formatPhone } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import {
  leadsApi, LEAD_STATUS_LABELS, WINDOW_LABELS,
  type InboxItem, type InboxWindow, type LeadChannel, type LeadEvent,
} from '@/features/leads/api';
import { ScoreBadge } from '@/features/leads/LeadBadges';

const POLL_MS = 10_000;   // yangi xabarlar shuncha vaqtda o'zi chiqadi

type Role = 'user' | 'assistant' | 'operator';

function roleOf(ev: LeadEvent): Role {
  if (ev.message_text) return 'user';
  return ev.actor === 'operator' ? 'operator' : 'assistant';
}

/** Suhbat hodisalarini bitta oqimga yoyamiz (bitta yozuvda ikkala tomon bo'lishi mumkin). */
function toMessages(events: LeadEvent[]) {
  const out: { id: string; role: Role; text: string; at: string; kind: string }[] = [];
  for (const ev of events) {
    if (ev.kind === 'status' || ev.kind === 'note') continue;
    if (ev.message_text) {
      out.push({ id: `${ev.id}-u`, role: 'user', text: ev.message_text, at: ev.created_at, kind: ev.kind });
    }
    if (ev.agent_reply) {
      out.push({
        id: `${ev.id}-a`, role: roleOf({ ...ev, message_text: null }),
        text: ev.agent_reply, at: ev.created_at, kind: ev.kind,
      });
    }
  }
  return out;
}

/** Kanal ikonkasi — Instagram (kamera) yoki Telegram (xabar) */
function ChannelIcon({ channel, size = 13 }: { channel: LeadChannel; size?: number }) {
  return channel === 'telegram'
    ? <MessageCircle size={size} className="text-sky-500" />
    : <Instagram size={size} className="text-pink-500" />;
}

function profileUrl(item: InboxItem): string | null {
  if (!item.username) return null;
  return item.channel === 'telegram'
    ? `https://t.me/${item.username}`
    : `https://instagram.com/${item.username}`;
}

const CHANNEL_FILTERS: { key: '' | LeadChannel; label: string }[] = [
  { key: '', label: 'Hammasi' },
  { key: 'instagram', label: 'Instagram' },
  { key: 'telegram', label: 'Telegram' },
];

const WINDOW_STYLE: Record<InboxWindow, string> = {
  open: 'bg-success/10 text-success',
  human_agent: 'bg-warning/10 text-warning',
  closed: 'bg-black/[0.06] text-ink-soft',
};

/**
 * Instagram yozishmalari — ERP ichidan jonli javob berish.
 * Kelayotgan xabarlar webhook orqali tushadi, javob agent orqali yuboriladi.
 */
export default function LeadsInbox() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('leads:write');

  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [onlyUnread, setOnlyUnread] = useState(false);
  const [channel, setChannel] = useState<'' | LeadChannel>('');
  const [activeId, setActiveId] = useState<string | null>(null);

  useEffect(() => {
    const t = setTimeout(() => setDebounced(search.trim()), 300);
    return () => clearTimeout(t);
  }, [search]);

  const inboxQ = useQuery({
    queryKey: ['leads-inbox', debounced, onlyUnread, channel],
    queryFn: () => leadsApi.inbox({
      search: debounced || undefined,
      only_unread: onlyUnread || undefined,
      channel: channel || undefined,
    }),
    refetchInterval: POLL_MS,
  });
  const items = inboxQ.data ?? [];

  // Birinchi suhbatni avtomatik ochamiz
  useEffect(() => {
    if (!activeId && items.length) setActiveId(items[0].lead_id);
  }, [items, activeId]);

  const active = useMemo(
    () => items.find((i) => i.lead_id === activeId) ?? null,
    [items, activeId],
  );

  return (
    <div className="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-3 h-[70vh] min-h-[440px]">
      {/* --- Suhbatlar ro'yxati --- */}
      <div className="rounded-card border border-black/5 bg-card flex flex-col overflow-hidden">
        <div className="p-2.5 border-b border-black/5 space-y-2">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 h-9" placeholder="Ism, username, telefon…"
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
          <div className="flex gap-1">
            {CHANNEL_FILTERS.map((f) => (
              <button key={f.key || 'all'} type="button" onClick={() => setChannel(f.key)}
                className={cn('px-2 py-1 rounded-button text-xs font-medium transition',
                  channel === f.key ? 'bg-primary text-white'
                                    : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
                {f.label}
              </button>
            ))}
          </div>
          <label className="flex items-center gap-2 text-xs text-ink-soft cursor-pointer select-none">
            <input type="checkbox" className="h-3.5 w-3.5 accent-primary"
                   checked={onlyUnread} onChange={(e) => setOnlyUnread(e.target.checked)} />
            Faqat o'qilmaganlar
          </label>
        </div>

        <div className="flex-1 overflow-y-auto divide-y divide-black/5">
          {inboxQ.isLoading ? (
            Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-16 bg-black/[0.03] animate-pulse" />
            ))
          ) : items.length === 0 ? (
            <div className="p-6 text-center text-sm text-ink-soft">
              {debounced || onlyUnread || channel ? 'Suhbat topilmadi' : "Hozircha yozishma yo'q"}
            </div>
          ) : (
            items.map((it) => (
              <ConversationRow key={it.lead_id} item={it} active={it.lead_id === activeId}
                               onClick={() => setActiveId(it.lead_id)} />
            ))
          )}
        </div>
      </div>

      {/* --- Suhbat --- */}
      <div className="rounded-card border border-black/5 bg-card overflow-hidden">
        {active ? (
          <ChatPanel
            key={active.lead_id}
            item={active}
            canWrite={canWrite}
            onChanged={() => {
              qc.invalidateQueries({ queryKey: ['leads-inbox'] });
              qc.invalidateQueries({ queryKey: ['leads'] });
            }}
          />
        ) : (
          <div className="h-full flex items-center justify-center text-sm text-ink-soft">
            Suhbatni tanlang
          </div>
        )}
      </div>
    </div>
  );
}

// --------------------------------------------------------------------------- //
function ConversationRow({ item, active, onClick }: {
  item: InboxItem; active: boolean; onClick: () => void;
}) {
  const title = item.name || item.username || item.ig_username || "Noma'lum";
  const preview = item.last_message || '';
  const prefix = item.last_message_role === 'user' ? '' : 'Siz: ';
  return (
    <button type="button" onClick={onClick}
      className={cn('w-full text-left px-3 py-2.5 transition flex gap-2.5',
                    active ? 'bg-primary/10' : 'hover:bg-black/[0.03]')}>
      <div className="w-8 h-8 rounded-full bg-black/[0.05] flex items-center justify-center shrink-0">
        <ChannelIcon channel={item.channel} size={15} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <span className="font-medium text-sm truncate">{title}</span>
          {item.unread > 0 && (
            <span className="shrink-0 text-[10px] font-bold bg-danger text-white rounded-full px-1.5 py-0.5 min-w-[18px] text-center">
              {item.unread}
            </span>
          )}
        </div>
        <div className="text-xs text-ink-soft truncate">
          {prefix}{preview || '—'}
        </div>
        <div className="text-[10px] text-ink-soft/70 mt-0.5 flex items-center gap-1.5">
          {item.last_message_at && formatDateTime(item.last_message_at)}
          {item.window === 'closed' && <Lock size={10} />}
        </div>
      </div>
    </button>
  );
}

// --------------------------------------------------------------------------- //
function ChatPanel({ item, canWrite, onChanged }: {
  item: InboxItem; canWrite: boolean; onChanged: () => void;
}) {
  const qc = useQueryClient();
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const detailQ = useQuery({
    queryKey: ['lead', item.lead_id],
    queryFn: () => leadsApi.get(item.lead_id),
    refetchInterval: POLL_MS,
  });
  const messages = useMemo(() => toMessages(detailQ.data?.events ?? []), [detailQ.data]);

  const botQ = useQuery({
    queryKey: ['lead-bot', item.lead_id],
    queryFn: () => leadsApi.botState(item.lead_id),
    retry: false,
  });
  const botPaused = botQ.data?.paused ?? false;

  // Ochilganda o'qilgan deb belgilaymiz
  useEffect(() => {
    if (item.unread > 0) {
      leadsApi.markRead(item.lead_id).then(onChanged).catch(() => {});
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [item.lead_id]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ block: 'end' });
  }, [messages.length]);

  const locked = item.window === 'closed' || !canWrite;

  async function send() {
    const body = text.trim();
    if (!body || sending) return;
    setSending(true);
    try {
      const res = await leadsApi.reply(item.lead_id, body);
      if (!res.sent) {
        toast.error(res.error || 'Yuborilmadi');
        return;
      }
      setText('');
      toast.success(res.tag ? 'Yuborildi (operator sifatida)' : 'Yuborildi');
      qc.invalidateQueries({ queryKey: ['lead', item.lead_id] });
      qc.invalidateQueries({ queryKey: ['lead-bot', item.lead_id] });
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Yuborishda xatolik');
    } finally {
      setSending(false);
    }
  }

  async function toggleBot() {
    try {
      const res = await leadsApi.setBot(item.lead_id, botPaused);
      toast.success(res.paused ? 'AI bu suhbatda jim turadi' : 'AI javob beradi');
      qc.invalidateQueries({ queryKey: ['lead-bot', item.lead_id] });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "AI holatini o'zgartirib bo'lmadi");
    }
  }

  return (
    <div className="h-full flex flex-col">
      {/* Sarlavha */}
      <div className="px-4 py-2.5 border-b border-black/5 flex items-center justify-between gap-3 flex-wrap">
        <div className="min-w-0">
          <div className="font-semibold text-sm flex items-center gap-2">
            <span className="truncate">{item.name || item.username || "Noma'lum"}</span>
            <ScoreBadge score={item.lead_score} />
            <span className="badge bg-black/[0.05] text-ink-soft">{LEAD_STATUS_LABELS[item.status]}</span>
          </div>
          <div className="text-xs text-ink-soft flex items-center gap-2.5 mt-0.5">
            <span className="inline-flex items-center gap-1">
              <ChannelIcon channel={item.channel} size={12} />
              {item.channel === 'telegram' ? 'Telegram' : 'Instagram'}
            </span>
            {item.username && profileUrl(item) && (
              <a href={profileUrl(item)!} target="_blank" rel="noreferrer"
                 className="inline-flex items-center gap-1 hover:text-primary">
                @{item.username} <ExternalLink size={11} />
              </a>
            )}
            {item.contact && (
              <span className="inline-flex items-center gap-1">
                <Phone size={11} /> {formatPhone(item.contact)}
              </span>
            )}
          </div>
        </div>

        {canWrite && (
          <button onClick={toggleBot} disabled={botQ.isLoading}
            title={botPaused ? "AI javobini yoqish" : "AI javobini o'chirish"}
            className={cn('btn-action text-xs',
              botPaused ? 'bg-black/[0.06] text-ink-soft hover:bg-black/10'
                        : 'bg-primary/10 text-primary hover:bg-primary/20')}>
            {botPaused ? <BotOff size={14} /> : <Bot size={14} />}
            {botPaused ? 'AI o\'chiq' : 'AI yoniq'}
          </button>
        )}
      </div>

      {/* Javob oynasi holati */}
      <div className={cn('px-4 py-1.5 text-xs flex items-center gap-1.5', WINDOW_STYLE[item.window])}>
        {item.window === 'closed' ? <Lock size={12} /> : <Clock size={12} />}
        {WINDOW_LABELS[item.window]}
      </div>

      {/* Xabarlar */}
      <div className="flex-1 overflow-y-auto p-4 space-y-2.5 bg-black/[0.015]">
        {detailQ.isLoading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-12 rounded-2xl bg-black/5 animate-pulse" />
          ))
        ) : messages.length === 0 ? (
          <div className="text-center text-sm text-ink-soft py-10">Xabarlar yo'q</div>
        ) : (
          messages.map((m) => <MessageBubble key={m.id} {...m} />)
        )}
        <div ref={bottomRef} />
      </div>

      {/* Yozish maydoni */}
      <div className="border-t border-black/5 p-2.5">
        {locked ? (
          <div className="text-xs text-ink-soft text-center py-2">
            {!canWrite
              ? "Yozish uchun ruxsat yo'q"
              : "Instagram bu suhbatga javob yozishga ruxsat bermaydi — ilovadan yoki telefon orqali bog'laning"}
          </div>
        ) : (
          <div className="flex items-end gap-2">
            <textarea
              className="input min-h-[42px] max-h-32 resize-y flex-1"
              placeholder="Xabar yozing…"
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
              }}
            />
            <button onClick={send} disabled={sending || !text.trim()}
                    className="btn-primary h-[42px] disabled:opacity-50">
              {sending ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// --------------------------------------------------------------------------- //
function MessageBubble({ role, text, at, kind }: {
  role: Role; text: string; at: string; kind: string;
}) {
  const mine = role !== 'user';
  const label = role === 'user' ? 'Mijoz' : role === 'operator' ? 'Operator' : 'AI agent';
  return (
    <div className={cn('flex', mine ? 'justify-end' : 'justify-start')}>
      <div className={cn(
        'max-w-[78%] rounded-2xl px-3.5 py-2 shadow-sm',
        role === 'user' ? 'bg-card border border-black/5 rounded-bl-sm'
          : role === 'operator' ? 'bg-primary text-white rounded-br-sm'
          : 'bg-primary/15 text-ink rounded-br-sm',
      )}>
        <div className={cn('text-[10px] font-medium mb-0.5 flex items-center gap-1.5',
                           role === 'operator' ? 'text-white/80' : 'text-ink-soft')}>
          {label}
          {kind === 'comment' && (
            <span className={cn('rounded px-1',
                                role === 'operator' ? 'bg-white/20' : 'bg-black/[0.06]')}>Izoh</span>
          )}
        </div>
        <p className="text-sm whitespace-pre-wrap break-words">{text}</p>
        <div className={cn('text-[10px] mt-1 text-right',
                           role === 'operator' ? 'text-white/70' : 'text-ink-soft')}>
          {formatDateTime(at)}
        </div>
      </div>
    </div>
  );
}
