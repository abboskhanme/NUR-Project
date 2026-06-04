import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Search, UserPlus, Check, X } from 'lucide-react';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';
import { formatPhone } from '@/lib/format';
import Select from '@/components/ui/Select';
import { regionsOf } from '@/lib/centralAsia';

export interface CustomerLite {
  id: string;
  full_name: string;
  phone: string;
  region?: string | null;
  city?: string | null;
  country?: string;
}

export default function CustomerPicker({
  value,
  onChange,
}: {
  value: CustomerLite | null;
  onChange: (c: CustomerLite | null) => void;
}) {
  const [search, setSearch] = useState('');
  const [open, setOpen] = useState(false);
  const [creating, setCreating] = useState(false);

  // inline create form
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [region, setRegion] = useState('');
  const [saving, setSaving] = useState(false);

  const { data } = useQuery({
    queryKey: ['customers', 'picker', search],
    queryFn: () =>
      api.get('/customers', { params: { search: search || undefined, page_size: 20 } })
        .then((r) => r.data),
    enabled: open && !creating,
  });
  const results: CustomerLite[] = data?.items ?? [];

  async function handleCreate() {
    if (!name.trim() || !phone.trim()) {
      toast.error('Ism va telefon majburiy');
      return;
    }
    setSaving(true);
    try {
      const r = await api.post('/customers', {
        full_name: name.trim(),
        phone: phone.trim(),
        region: region.trim() || null,
      });
      onChange(r.data);
      toast.success('Mijoz qo\'shildi');
      setCreating(false);
      setOpen(false);
      setName(''); setPhone(''); setRegion('');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  if (value) {
    return (
      <div className="flex items-center justify-between gap-2 rounded-button border border-black/10 px-3 py-2 bg-white">
        <div className="min-w-0">
          <div className="font-medium truncate">{value.full_name}</div>
          <div className="text-xs text-ink-soft truncate">
            {formatPhone(value.phone)}{value.region ? ` • ${value.region}` : ''}
          </div>
        </div>
        <button
          type="button"
          onClick={() => onChange(null)}
          className="p-1 rounded hover:bg-black/5 text-ink/50 shrink-0"
          title="Boshqa mijoz tanlash"
        >
          <X size={16} />
        </button>
      </div>
    );
  }

  return (
    <div className="rounded-button border border-black/10 bg-white">
      {!creating ? (
        <>
          <div className="flex items-center gap-2 px-3 py-2">
            <Search size={16} className="text-ink/40" />
            <input
              autoFocus
              placeholder="Mijoz ismi yoki telefoni..."
              value={search}
              onFocus={() => setOpen(true)}
              onChange={(e) => { setSearch(e.target.value); setOpen(true); }}
              className="bg-transparent outline-none flex-1 text-sm"
            />
            <button
              type="button"
              onClick={() => setCreating(true)}
              className="text-xs text-primary font-medium flex items-center gap-1 shrink-0"
            >
              <UserPlus size={14} /> Yangi
            </button>
          </div>
          {open && (
            <div className="max-h-52 overflow-y-auto border-t border-black/5">
              {results.length === 0 ? (
                <div className="px-3 py-3 text-sm text-ink-soft">
                  Topilmadi. <button type="button" className="text-primary" onClick={() => setCreating(true)}>Yangi mijoz qo'shish</button>
                </div>
              ) : (
                results.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => { onChange(c); setOpen(false); }}
                    className="w-full text-left px-3 py-2 hover:bg-black/5 flex items-center justify-between"
                  >
                    <span className="min-w-0">
                      <span className="font-medium block truncate">{c.full_name}</span>
                      <span className="text-xs text-ink-soft">{formatPhone(c.phone)}{c.region ? ` • ${c.region}` : ''}</span>
                    </span>
                  </button>
                ))
              )}
            </div>
          )}
        </>
      ) : (
        <div className="p-3 space-y-2">
          <div className="text-sm font-medium flex items-center gap-1.5"><UserPlus size={15} className="text-primary" /> Yangi mijoz</div>
          <input className="input" placeholder="Ism familiya *" value={name} onChange={(e) => setName(e.target.value)} />
          <PhoneInput value={phone} onChange={setPhone} />
          <Select
            value={region}
            onChange={setRegion}
            allowEmpty
            emptyLabel="Viloyat —"
            placeholder="Viloyat"
            options={regionsOf('Uzbekistan').map((r) => ({ value: r, label: r }))}
          />
          <div className="flex justify-end gap-2 pt-1">
            <button type="button" onClick={() => setCreating(false)} className="btn-ghost text-sm py-1.5">Bekor</button>
            <button type="button" onClick={handleCreate} disabled={saving} className="btn-primary text-sm py-1.5">
              <Check size={15} /> {saving ? 'Saqlanmoqda...' : 'Qo\'shish'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
