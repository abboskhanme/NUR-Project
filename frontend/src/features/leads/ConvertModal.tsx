import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, UserPlus } from 'lucide-react';

import PhoneInput from '@/components/ui/PhoneInput';
import { leadsApi, type Lead } from '@/features/leads/api';

/** Leaddan mijoz yaratish modali. Telefon raqami majburiy. */
export default function ConvertModal({
  lead, onClose, onDone,
}: { lead: Lead; onClose: () => void; onDone: (updated: Lead) => void }) {
  const [fullName, setFullName] = useState(lead.name || lead.ig_username || '');
  // Lead kontakti raqamga o'xshasa — oldindan to'ldiramiz
  const [phone, setPhone] = useState(
    lead.contact && /\d/.test(lead.contact) ? lead.contact : '',
  );
  const [region, setRegion] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!phone.trim()) {
      toast.error('Telefon raqamini kiriting');
      return;
    }
    setSaving(true);
    try {
      const updated = await leadsApi.convert(lead.id, {
        full_name: fullName.trim() || undefined,
        phone: phone.trim(),
        region: region.trim() || undefined,
      });
      toast.success('Mijoz yaratildi');
      onDone(updated);
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            <UserPlus size={18} className="text-primary" />
            Mijozga aylantirish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <p className="text-xs text-ink-soft">
            Ushbu lead asosida yangi mijoz yaratiladi va lead <b>"Mijoz bo'ldi"</b> holatiga o'tadi.
          </p>
          <div>
            <label className="label">To'liq ism *</label>
            <input className="input" value={fullName} autoFocus
                   onChange={(e) => setFullName(e.target.value)} placeholder="Mijoz ismi" />
          </div>
          <div>
            <label className="label">Telefon raqami *</label>
            <PhoneInput value={phone} onChange={setPhone} />
          </div>
          <div>
            <label className="label">Viloyat (ixtiyoriy)</label>
            <input className="input" value={region}
                   onChange={(e) => setRegion(e.target.value)} placeholder="Masalan: Toshkent" />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : 'Mijoz yaratish'}
          </button>
        </div>
      </div>
    </div>
  );
}
