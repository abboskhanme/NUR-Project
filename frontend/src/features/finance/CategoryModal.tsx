import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';

export default function CategoryModal({
  defaultKind = 'expense', onClose, onSaved,
}: { defaultKind?: 'income' | 'expense'; onClose: () => void; onSaved: () => void }) {
  const [name, setName] = useState('');
  const [kind, setKind] = useState<'income' | 'expense'>(defaultKind);
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
      await api.post('/finance/categories', { name: name.trim(), kind });
      toast.success('Kategoriya qo\'shildi');
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
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">Yangi kategoriya</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>
        <div className="p-5 space-y-3">
          <div>
            <label className="label">Turi</label>
            <div className="grid grid-cols-2 gap-2">
              <button type="button" onClick={() => setKind('income')}
                className={`py-2 rounded-button border text-sm font-medium ${
                  kind === 'income' ? 'border-success bg-success/10 text-success' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                Kirim
              </button>
              <button type="button" onClick={() => setKind('expense')}
                className={`py-2 rounded-button border text-sm font-medium ${
                  kind === 'expense' ? 'border-danger bg-danger/10 text-danger' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                Chiqim
              </button>
            </div>
          </div>
          <div>
            <label className="label">Nomi *</label>
            <input className="input" placeholder="Masalan: Transport" value={name}
                   onChange={(e) => setName(e.target.value)}
                   onKeyDown={(e) => e.key === 'Enter' && handleSave()} />
          </div>
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
