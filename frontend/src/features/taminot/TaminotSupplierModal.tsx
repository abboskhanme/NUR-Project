import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Building2 } from 'lucide-react';

import { api } from '@/api/client';
import type { TaminotSupplier } from '@/features/taminot/types';

/**
 * Yetkazib beruvchi yaratish/tahrirlash.
 *
 * Yetkazib beruvchi — mahsulotlar olib kelinadigan joy (firma, bozor, shaxs).
 * Qarz hisobi aynan shu daraja bo'yicha yuritiladi: bitta joydan nechta
 * mahsulot olinishidan qat'i nazar hisob-kitob bitta bo'ladi.
 */
export default function TaminotSupplierModal({
  scope, supplier, onClose, onSaved,
}: {
  scope: string;
  supplier?: TaminotSupplier | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const editing = !!supplier;
  const [name, setName] = useState(supplier?.name ?? '');
  const [phone, setPhone] = useState(supplier?.phone ?? '');
  const [note, setNote] = useState(supplier?.note ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomini kiriting'); return; }
    setSaving(true);
    try {
      const payload = {
        name: name.trim(),
        phone: phone.trim() || null,
        note: note.trim() || null,
      };
      if (editing) await api.patch(`/taminot/suppliers/${supplier!.id}`, payload);
      else await api.post('/taminot/suppliers', { scope, ...payload });
      toast.success('Saqlandi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            <Building2 size={18} className="text-primary" />
            {editing ? 'Tahrirlash' : 'Yangi yetkazib beruvchi'}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" placeholder="Masalan: Metall Servis yoki Chorsu bozori"
                   value={name} onChange={(e) => setName(e.target.value)} autoFocus />
            <p className="text-[11px] text-ink-soft mt-1">
              Shu joydan olinadigan barcha mahsulotlarning qarzi bitta hisobda yuritiladi
            </p>
          </div>

          <div>
            <label className="label">Telefon</label>
            <input className="input" placeholder="+998 90 123 45 67"
                   value={phone} onChange={(e) => setPhone(e.target.value)} />
          </div>

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[60px]" placeholder="Manzil, shartlar va h.k."
                      value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
