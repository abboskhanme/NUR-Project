import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  ArrowDown, ArrowUp, Bot, Image as ImageIcon, Lightbulb, Pencil, Plus, Trash2,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import ConfirmModal from '@/components/ui/ConfirmModal';
import EmptyState from '@/components/ui/EmptyState';
import { cn } from '@/lib/cn';
import { usePermissions } from '@/lib/permissions';
import BotMenuItemModal from '@/features/bot-menu/BotMenuItemModal';
import BotMenuThumb from '@/features/bot-menu/BotMenuThumb';
import { botMenuApi, MAX_TEXT_LENGTH, type BotMenuItem } from '@/features/bot-menu/api';

const QUERY_KEY = ['bot-menu'];

/**
 * Telegram AI botining menyusi. Mijoz bo'limni tanlasa (tugma yoki /buyruq)
 * bot AI'siz shu matn va rasmlarni darhol yuboradi; boshqa savollarga AI
 * avvalgidek javob beradi.
 */
export default function BotMenuPage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('telegram:write');
  const canDelete = can('telegram:delete');

  const menuQ = useQuery({ queryKey: QUERY_KEY, queryFn: botMenuApi.get });
  const items = menuQ.data?.items ?? [];

  const [editing, setEditing] = useState<BotMenuItem | null | undefined>(undefined);
  const [deleting, setDeleting] = useState<BotMenuItem | null>(null);
  const [busy, setBusy] = useState(false);

  const [greeting, setGreeting] = useState('');
  const savedGreeting = menuQ.data?.greeting ?? '';
  useEffect(() => { setGreeting(savedGreeting); }, [savedGreeting]);

  const refresh = () => qc.invalidateQueries({ queryKey: QUERY_KEY });

  async function saveGreeting() {
    setBusy(true);
    try {
      qc.setQueryData(QUERY_KEY, await botMenuApi.setGreeting(greeting));
      toast.success('Salomlashish matni saqlandi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Saqlab bo‘lmadi');
    } finally {
      setBusy(false);
    }
  }

  async function move(index: number, delta: number) {
    const target = index + delta;
    if (target < 0 || target >= items.length) return;
    const ids = items.map((i) => i.id);
    [ids[index], ids[target]] = [ids[target], ids[index]];
    setBusy(true);
    try {
      qc.setQueryData(QUERY_KEY, await botMenuApi.reorder(ids));
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Tartibni o‘zgartirib bo‘lmadi');
      refresh();
    } finally {
      setBusy(false);
    }
  }

  async function toggleActive(item: BotMenuItem) {
    setBusy(true);
    try {
      await botMenuApi.update(item.id, { is_active: !item.is_active });
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'O‘zgartirib bo‘lmadi');
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleting) return;
    setBusy(true);
    try {
      await botMenuApi.remove(deleting.id);
      toast.success('Bo‘lim o‘chirildi');
      setDeleting(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'O‘chirib bo‘lmadi');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Bot size={22} className="text-primary" /> Bot menyusi
          </h1>
          <p className="text-sm text-ink-soft">
            Mijoz Telegram botda bo‘limni tanlasa, shu matn va rasmlar darhol yuboriladi.
            Boshqa savollarga AI javob beradi.
          </p>
        </div>
        {canWrite && (
          <button onClick={() => setEditing(null)} className="btn-primary">
            <Plus size={16} /> Bo‘lim qo‘shish
          </button>
        )}
      </div>

      <Card title="Salomlashish xabari">
        <p className="text-xs text-ink-soft mb-2">
          Mijoz botni ochganda (/start) tugmalar bilan birga chiqadi. Bo‘sh qoldirsangiz standart matn ishlatiladi.
        </p>
        <textarea className="input min-h-[80px]" maxLength={MAX_TEXT_LENGTH} disabled={!canWrite}
                  placeholder={'Assalomu alaykum! 👋\nQuyidagi bo‘limlardan birini tanlang yoki savolingizni yozing — darhol javob beramiz.'}
                  value={greeting} onChange={(e) => setGreeting(e.target.value)} />
        {canWrite && greeting !== savedGreeting && (
          <div className="flex justify-end gap-2 mt-2">
            <button onClick={() => setGreeting(savedGreeting)} className="btn-ghost text-sm">Bekor qilish</button>
            <button onClick={saveGreeting} disabled={busy} className="btn-primary text-sm">Saqlash</button>
          </div>
        )}
      </Card>

      {menuQ.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="h-24 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <Card>
          <EmptyState
            title="Hali bo‘lim yo‘q"
            description="Masalan «💰 Narxlar», «📍 Manzil», «🚚 Yetkazib berish» bo‘limlarini qo‘shing"
          />
        </Card>
      ) : (
        <div className="space-y-2">
          {items.map((item, index) => (
            <Card key={item.id} className={cn(!item.is_active && 'opacity-60')}>
              <div className="flex gap-3">
                {canWrite && (
                  <div className="flex flex-col gap-1 shrink-0">
                    <button aria-label="Yuqoriga" disabled={busy || index === 0} onClick={() => move(index, -1)}
                            className="p-1 rounded hover:bg-black/5 disabled:opacity-30">
                      <ArrowUp size={16} />
                    </button>
                    <button aria-label="Pastga" disabled={busy || index === items.length - 1}
                            onClick={() => move(index, 1)}
                            className="p-1 rounded hover:bg-black/5 disabled:opacity-30">
                      <ArrowDown size={16} />
                    </button>
                  </div>
                )}

                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-semibold">{item.title}</span>
                    <span className="badge bg-black/[0.05] text-ink-soft font-mono">/{item.command}</span>
                    {item.is_active ? (
                      <span className="badge bg-emerald-100 text-emerald-800">Botda ko‘rinadi</span>
                    ) : (
                      <span className="badge bg-slate-200 text-slate-700">Yashirilgan</span>
                    )}
                    {item.images.length > 0 && (
                      <span className="badge bg-sky-100 text-sky-800 gap-1">
                        <ImageIcon size={12} /> {item.images.length} ta rasm
                      </span>
                    )}
                  </div>

                  {item.text ? (
                    <p className="text-sm mt-1.5 line-clamp-3 whitespace-pre-wrap break-words">{item.text}</p>
                  ) : (
                    <p className="text-sm mt-1.5 text-ink-soft">(matnsiz — faqat rasmlar)</p>
                  )}

                  {item.images.length > 0 && (
                    <div className="flex gap-1.5 mt-2 overflow-x-auto">
                      {item.images.map((img) => <BotMenuThumb key={img.id} imageId={img.id} size={48} />)}
                    </div>
                  )}
                </div>

                {(canWrite || canDelete) && (
                  <div className="flex flex-col gap-1.5 shrink-0">
                    {canWrite && (
                      <button onClick={() => setEditing(item)}
                              className="btn-action bg-black/[0.05] text-ink-soft hover:bg-black/10 text-xs">
                        <Pencil size={14} /> Tahrirlash
                      </button>
                    )}
                    {canWrite && (
                      <button disabled={busy} onClick={() => toggleActive(item)}
                              className="btn-action bg-black/[0.05] text-ink-soft hover:bg-black/10 text-xs">
                        {item.is_active ? 'Yashirish' : 'Ko‘rsatish'}
                      </button>
                    )}
                    {canDelete && (
                      <button onClick={() => setDeleting(item)}
                              className="btn-action text-danger hover:bg-danger/5 text-xs">
                        <Trash2 size={14} /> O‘chirish
                      </button>
                    )}
                  </div>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      <div className="rounded-card border border-sky-200 bg-sky-50 text-sky-900 p-3 text-sm flex gap-2">
        <Lightbulb size={16} className="shrink-0 mt-0.5" />
        <ul className="space-y-1 text-xs">
          <li>• Botning o‘z chatida tugmalar pastda doim ko‘rinib turadi, buyruqlar esa «Menu» tugmasida.</li>
          <li>• Business ulanishida (siz nomingizdan yozishmada) tugmalar salomlashish xabari ostida chiqadi —
            mijoz «menyu» deb yozsa ham ko‘rinadi.</li>
          <li>• To‘g‘ridan-to‘g‘ri bo‘limga havola: <span className="font-mono">t.me/&lt;bot_nomi&gt;?start=buyruq</span>
            — masalan Instagram bio uchun.</li>
          <li>• O‘zgarishlar botda bir necha soniyada (ko‘pi bilan 5 daqiqada) paydo bo‘ladi.</li>
        </ul>
      </div>

      {editing !== undefined && (
        <BotMenuItemModal item={editing} canDelete={canDelete} onClose={() => setEditing(undefined)} onSaved={refresh} />
      )}

      <ConfirmModal
        open={!!deleting}
        title="Bo‘limni o‘chirish"
        message={deleting ? `«${deleting.title}» bo‘limi va uning rasmlari o‘chiriladi. Davom etasizmi?` : ''}
        confirmText="O‘chirish"
        loading={busy}
        onConfirm={confirmDelete}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
