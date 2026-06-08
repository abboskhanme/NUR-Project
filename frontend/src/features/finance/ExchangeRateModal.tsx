import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';

import { api } from '@/api/client';

const today = () => new Date().toISOString().slice(0, 10);

export default function ExchangeRateModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  const { t } = useTranslation();
  const [date, setDate] = useState(today());
  const [rate, setRate] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    const val = parseFloat(rate.replace(/[^\d.]/g, ''));
    if (!val || val <= 0) { toast.error(t('finance.rates.rateRequired')); return; }
    setSaving(true);
    try {
      await api.post('/finance/exchange-rates', { date, usd_to_uzs: val, source: 'manual' });
      toast.success(t('finance.rates.savedSuccess'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('finance.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{t('finance.rates.modalTitle')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>
        <div className="p-5 space-y-3">
          <div>
            <label className="label">{t('finance.rates.dateLabel')}</label>
            <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
          </div>
          <div>
            <label className="label">{t('finance.rates.rateLabel')}</label>
            <input type="text" inputMode="decimal" className="input" placeholder={t('finance.rates.ratePlaceholder')}
                   value={rate} onChange={(e) => setRate(e.target.value.replace(/[^\d.]/g, ''))}
                   onKeyDown={(e) => e.key === 'Enter' && handleSave()} />
          </div>
        </div>
        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">{t('actions.cancel')}</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('finance.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
