import { useCallback, useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Pencil, Trash2, Plus } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS, formatUSD, formatDate } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';

// Payment method options
const METHOD_OPTIONS = [
  { value: 'cash', label: 'Naqd' },
  { value: 'card', label: 'Karta' },
  { value: 'transfer', label: "O'tkazma" },
];
const METHOD_LABEL: Record<string, string> = {
  cash: 'Naqd', card: 'Karta', transfer: "O'tkazma",
};

// Eski bazadan import qilingan (avtomatik) summa — Payment.note shu belgi bilan
// (backend bilan bir xil). Bunday yozuv ro'yxatda "Eski baza" deb ko'rsatiladi.
const IMPORT_CORRECTION_NOTE = '__import_correction__';

const today = () => new Date().toISOString().slice(0, 10);

interface PaymentRow {
  id: string; date: string; amount: string; currency: string;
  amount_uzs_equiv: string; method?: string | null; note?: string | null;
}

function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  let intPart = (firstDot === -1 ? cleaned : cleaned.slice(0, firstDot)).replace(/^0+(?=\d)/, '');
  const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  if (firstDot === -1) return intFmt;
  const decPart = cleaned.slice(firstDot + 1).replace(/\./g, '').slice(0, 2);
  return `${intFmt || '0'}.${decPart}`;
}

export default function PaymentModal({
  orderId,
  onClose,
  onSaved,
}: {
  orderId: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { can, canSpecial } = usePermissions();
  const canOverride = canSpecial('system:order_override');
  const [date, setDate] = useState(today());
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('UZS');
  const [method, setMethod] = useState('cash');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [order, setOrder] = useState<{ status?: string; balance_uzs: string; exchange_rate: string; payments?: PaymentRow[] } | null>(null);
  const [isFull, setIsFull] = useState(false);
  // null = yangi to'lov qo'shish rejimi; aks holda — shu id'li to'lovni tahrirlash
  const [editingId, setEditingId] = useState<string | null>(null);

  const refresh = useCallback(() => {
    return api.get(`/orders/${orderId}`).then((r) => setOrder(r.data)).catch(() => {});
  }, [orderId]);

  useEffect(() => { refresh(); }, [refresh]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  // Barcha to'lovlar — real zaklad VA eski import summalar (hammasi ko'rinadi/tahrirlanadi)
  const payments: PaymentRow[] = order?.payments ?? [];
  const delivered = order?.status === 'delivered';
  const isCorrection = (p: PaymentRow) => (p.note || '') === IMPORT_CORRECTION_NOTE;

  // Ruxsatlar: import yozuvini faqat override egasi; yetkazilgan buyurtmani ham faqat override.
  const canEditRow = (p: PaymentRow) =>
    (isCorrection(p) ? canOverride : can('orders:write')) && (!delivered || canOverride);
  const canDeleteRow = (p: PaymentRow) =>
    (isCorrection(p) ? canOverride : can('orders:delete')) && (!delivered || canOverride);

  const rate = order ? parseFloat(order.exchange_rate) || 0 : 0;
  const rawBalance = order ? Math.max(0, parseFloat(order.balance_uzs) || 0) : null;
  // Tahrirlashda: ushbu to'lov o'rnini bo'shatadi — ruxsat etilgan maksimum
  // qoldiq + shu to'lovning so'mdagi qiymati.
  const editingEquiv = editingId
    ? parseFloat(payments.find((p) => p.id === editingId)?.amount_uzs_equiv || '0') || 0
    : 0;
  const balance = rawBalance == null ? null : rawBalance + editingEquiv;

  const amtNum = parseFloat(amount.replace(/[^\d.]/g, '')) || 0;
  const amtUzs = currency === 'USD' ? amtNum * rate : amtNum;
  const exceeds = balance != null && !isFull && amtUzs > balance + 0.01;
  // Yangi to'lov qo'shib bo'lmaydi — buyurtma to'liq to'langan (faqat tahrirlash qoladi)
  const addBlocked = !editingId && rawBalance != null && rawBalance <= 0;

  function resetForm() {
    setEditingId(null);
    setDate(today());
    setAmount('');
    setCurrency('UZS');
    setMethod('cash');
    setNote('');
    setIsFull(false);
  }

  function startEdit(p: PaymentRow) {
    setEditingId(p.id);
    setDate(p.date.slice(0, 10));
    setAmount(formatAmount(String(p.amount)));
    setCurrency(p.currency || 'UZS');
    setMethod(p.method || 'cash');
    setNote(isCorrection(p) ? '' : (p.note || ''));
    setIsFull(false);
  }

  async function removePayment(p: PaymentRow) {
    if (!window.confirm("Ushbu to'lov o'chirilsinmi?")) return;
    setSaving(true);
    try {
      await api.delete(`/orders/${orderId}/payments/${p.id}`);
      if (editingId === p.id) resetForm();
      await refresh();
      onSaved();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  function payFull() {
    if (balance == null) return;
    const v = currency === 'USD' && rate > 0
      ? Math.round((balance / rate) * 100) / 100
      : balance;
    setAmount(formatAmount(String(v)));
    setIsFull(true);
  }

  async function handleSave() {
    const amt = parseFloat(amount.replace(/[^\d.]/g, ''));
    if (!amt || amt <= 0) { toast.error("To'g'ri summa kiriting"); return; }
    if (exceeds) {
      toast.error(`To'lov qoldiqdan oshib ketdi — qoldiq: ${formatUZS(balance!)}`);
      return;
    }
    setSaving(true);
    try {
      const editingRow = editingId ? payments.find((p) => p.id === editingId) : null;
      const body: Record<string, unknown> = {
        date, amount: amt, currency, method,
        ...(isFull && balance != null ? { amount_uzs_equiv: balance } : {}),
      };
      // Eski import yozuvini tahrirlashda note'ni jo'natmaymiz — backend belgini saqlaydi.
      if (!(editingRow && isCorrection(editingRow))) body.note = note || null;
      if (editingId) {
        await api.patch(`/orders/${orderId}/payments/${editingId}`, body);
        toast.success("To'lov yangilandi");
      } else {
        await api.post(`/orders/${orderId}/payments`, body);
        toast.success("To'lov qo'shildi");
      }
      resetForm();
      await refresh();
      onSaved();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  const methodLabel = (m?: string | null) =>
    m ? (METHOD_LABEL[m] || m) : '—';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md overflow-hidden flex flex-col max-h-[90vh]"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">To'lov qo'shish</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4 overflow-y-auto">
          {/* Barcha to'lovlar (real zaklad + eski import) — tahrirlash uchun */}
          <div>
            <div className="text-xs font-medium text-ink-soft mb-1.5">Berilgan to'lovlar (zakladlar)</div>
            {payments.length === 0 ? (
              <div className="text-sm text-ink-soft py-1">Hozircha to'lov yo'q</div>
            ) : (
              <div className="rounded-lg border border-black/5 divide-y divide-black/5">
                {payments.map((p) => {
                  const corr = isCorrection(p);
                  return (
                    <div key={p.id}
                         className={'flex items-center gap-2 px-3 py-2 text-sm ' +
                           (editingId === p.id ? 'bg-primary/5' : '')}>
                      <div className="w-20 shrink-0 text-ink-soft">{formatDate(p.date)}</div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium">
                          {p.currency === 'USD' ? formatUSD(p.amount) : formatUZS(p.amount)}
                          {corr ? (
                            <span className="ml-1 text-[11px] font-normal text-amber-600">· Eski baza (import)</span>
                          ) : (
                            <span className="text-ink-soft font-normal"> · {methodLabel(p.method)}</span>
                          )}
                        </div>
                        {!corr && p.note && (
                          <div className="text-xs text-ink-soft truncate">{p.note}</div>
                        )}
                      </div>
                      {canEditRow(p) && (
                        <button onClick={() => startEdit(p)} disabled={saving}
                                className="shrink-0 p-1 rounded hover:bg-primary/10 text-primary disabled:opacity-50"
                                title="Tahrirlash">
                          <Pencil size={14} />
                        </button>
                      )}
                      {canDeleteRow(p) && (
                        <button onClick={() => removePayment(p)} disabled={saving}
                                className="shrink-0 p-1 rounded hover:bg-danger/10 text-danger disabled:opacity-50"
                                title="To'lovni o'chirish">
                          <Trash2 size={14} />
                        </button>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Qo'shish / tahrirlash formasi */}
          {(editingId || !addBlocked) ? (
            <div className="pt-1">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-medium text-ink-soft">
                  {editingId ? "To'lovni tahrirlash" : "Yangi to'lov qo'shish"}
                </span>
                {editingId && (
                  <button onClick={resetForm} className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline">
                    <Plus size={13} /> Yangi qo'shish
                  </button>
                )}
              </div>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="label">Sana</label>
                    <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
                  </div>
                  <div>
                    <label className="label">Valyuta</label>
                    <select className="input" value={currency}
                            onChange={(e) => { setCurrency(e.target.value); setIsFull(false); }}>
                      <option value="UZS">UZS</option>
                      <option value="USD">USD</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label className="label">Summa *</label>
                  <input type="text" inputMode="decimal"
                         className={'input ' + (exceeds ? '!border-danger' : '')} placeholder="0"
                         value={amount}
                         onChange={(e) => { setAmount(formatAmount(e.target.value)); setIsFull(false); }} />
                  <div className="flex items-center justify-between mt-1">
                    <span className="text-xs text-ink-soft">
                      {balance != null ? <>Qoldiq: <b>{formatUZS(balance)}</b></> : ' '}
                    </span>
                    {balance != null && balance > 0 && (
                      <button type="button" onClick={payFull}
                              className="text-xs font-medium text-primary hover:underline">
                        To'liq to'lash
                      </button>
                    )}
                  </div>
                  {exceeds && (
                    <p className="text-xs text-danger mt-0.5">
                      {`Summa qoldiqdan oshib ketdi — maksimal ${formatUZS(balance!)}`}
                    </p>
                  )}
                </div>
                <div>
                  <label className="label">To'lov usuli</label>
                  <select className="input" value={method} onChange={(e) => setMethod(e.target.value)}>
                    {METHOD_OPTIONS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Izoh</label>
                  <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
                </div>
              </div>
            </div>
          ) : (
            <div className="text-xs text-success font-medium pt-1">To'liq to'langan</div>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor</button>
          {(editingId || !addBlocked) && (
            <button onClick={handleSave} disabled={saving || exceeds} className="btn-primary disabled:opacity-50">
              {saving ? "Saqlanmoqda..." : editingId ? "Yangilash" : "Saqlash"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
