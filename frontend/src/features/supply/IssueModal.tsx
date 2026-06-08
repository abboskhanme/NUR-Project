import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import { toNum } from './money';

export default function IssueModal({
  item, onClose, onSaved,
}: {
  item: { id: string; name: string; unit: string; stock_qty: string };
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const [qty, setQty] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    const n = toNum(qty);
    if (n <= 0) { toast.error(t('supply.issueModal.qtyRequired')); return; }
    if (n > parseFloat(item.stock_qty)) { toast.error(t('supply.issueModal.notEnoughStock')); return; }
    setSaving(true);
    try {
      await api.post('/supply/stock/issue', { item_id: item.id, qty: n, note: note || null });
      toast.success(t('supply.issueModal.saved'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('supply.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{t('supply.issueModal.title')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>
        <div className="p-5 space-y-3">
          <div className="text-sm">
            <span className="font-medium">{item.name}</span>
            <span className="text-ink-soft">
              {' — '}{t('supply.issueModal.currentStock', { qty: parseFloat(item.stock_qty), unit: item.unit })}
            </span>
          </div>
          <div>
            <label className="label">{t('supply.issueModal.labelQty', { unit: item.unit })}</label>
            <input className="input" inputMode="decimal" value={qty}
                   onChange={(e) => setQty(e.target.value.replace(/[^\d.]/g, ''))} placeholder="0" autoFocus />
          </div>
          <div>
            <label className="label">{t('supply.issueModal.labelNote')}</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                   placeholder={t('supply.issueModal.placeholderNote')} />
          </div>
        </div>
        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('supply.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('supply.issueModal.saving') : t('supply.issueModal.submit')}
          </button>
        </div>
      </div>
    </div>
  );
}
