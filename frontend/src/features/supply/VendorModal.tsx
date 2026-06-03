import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';

interface UserLite { id: string; full_name: string; email: string }
export interface VendorLite {
  id: string; name: string; user_id?: string | null;
  phone?: string | null; address?: string | null; note?: string | null; is_active: boolean;
}

export default function VendorModal({
  vendor, onClose, onSaved,
}: { vendor?: VendorLite | null; onClose: () => void; onSaved: () => void }) {
  const editing = !!vendor;
  const [name, setName] = useState(vendor?.name ?? '');
  const [phone, setPhone] = useState(vendor?.phone ?? '');
  const [address, setAddress] = useState(vendor?.address ?? '');
  const [userId, setUserId] = useState(vendor?.user_id ?? '');
  const [note, setNote] = useState(vendor?.note ?? '');
  const [isActive, setIsActive] = useState(vendor?.is_active ?? true);
  const [saving, setSaving] = useState(false);

  const usersQ = useQuery<UserLite[]>({
    queryKey: ['users-for-vendor'],
    queryFn: () => api.get('/users', { params: { page_size: 200 } })
      .then((r) => r.data.items ?? r.data ?? []),
  });

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomini kiriting'); return; }
    setSaving(true);
    try {
      const body = {
        name: name.trim(), phone: phone || null, address: address || null,
        user_id: userId || null, note: note || null, is_active: isActive,
      };
      if (editing) await api.patch(`/supply/vendors/${vendor!.id}`, body);
      else await api.post('/supply/vendors', body);
      toast.success(editing ? 'Yangilandi' : 'Taminotchi qo\'shildi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{editing ? 'Taminotchini tahrirlash' : 'Yangi taminotchi'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)}
                   placeholder="Masalan: Umid Tokir" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Telefon</label>
              <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)}
                     placeholder="+998..." />
            </div>
            <div>
              <label className="label">Login akkaunt</label>
              <select className="input" value={userId} onChange={(e) => setUserId(e.target.value)}>
                <option value="">— Bog'lanmagan —</option>
                {(usersQ.data ?? []).map((u) => (
                  <option key={u.id} value={u.id}>{u.full_name}</option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="label">Manzil</label>
            <input className="input" value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
          <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)}
                   className="w-4 h-4 accent-primary" />
            Faol
          </label>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
