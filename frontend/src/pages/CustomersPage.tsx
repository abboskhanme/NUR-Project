import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Search, Pencil, Trash2, Users } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatPhone } from '@/lib/format';
import CustomerModal, { CustomerFull } from '@/features/customers/CustomerModal';

export default function CustomersPage() {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [region, setRegion] = useState('');
  const [edit, setEdit] = useState<CustomerFull | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['customers', search, region],
    queryFn: () => api.get('/customers', {
      params: { search: search || undefined, region: region || undefined, page_size: 100 },
    }).then((r) => r.data),
  });
  const items: CustomerFull[] = data?.items ?? [];
  const total: number = data?.total ?? 0;

  function refresh() {
    qc.invalidateQueries({ queryKey: ['customers'] });
  }

  async function handleDelete(c: CustomerFull, e: React.MouseEvent) {
    e.stopPropagation();
    if (!window.confirm(`"${c.full_name}" o'chirilsinmi?`)) return;
    try {
      await api.delete(`/customers/${c.id}`);
      toast.success("O'chirildi");
      refresh();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || "Xatolik");
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Mijozlar</h1>
          <p className="text-sm text-ink-soft">Barcha mijozlar bazasi</p>
        </div>
        <button className="btn-primary" onClick={() => setShowCreate(true)}>
          <Plus size={16} /> Yangi mijoz
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="card !p-4">
          <div className="flex items-center gap-2 text-ink-soft text-xs">
            <span className="text-primary"><Users size={18} /></span> Jami mijozlar
          </div>
          <div className="text-xl font-bold mt-1">{total}</div>
        </div>
      </div>

      <Card>
        <div className="flex flex-wrap gap-3 mb-4">
          <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={16} className="text-ink/40" />
            <input
              placeholder="Ism yoki telefon bo'yicha qidirish..."
              value={search} onChange={(e) => setSearch(e.target.value)}
              className="bg-transparent outline-none flex-1 text-sm"
            />
          </div>
          <input className="input max-w-[200px]" placeholder="Viloyat bo'yicha"
                 value={region} onChange={(e) => setRegion(e.target.value)} />
        </div>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : items.length === 0 ? (
          <EmptyState title="Mijozlar yo'q" description="'Yangi mijoz' tugmasi orqali qo'shing" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Ism familiya</th>
                  <th className="py-2 pr-3">Telefon</th>
                  <th className="py-2 pr-3">Davlat</th>
                  <th className="py-2 pr-3">Viloyat</th>
                  <th className="py-2 pr-3">Shahar</th>
                  <th className="py-2 pr-3"></th>
                </tr>
              </thead>
              <tbody>
                {items.map((c) => (
                  <tr key={c.id} onClick={() => navigate(`/customers/${c.id}`)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                    <td className="py-2 pr-3 font-medium">{c.full_name}</td>
                    <td className="py-2 pr-3">{formatPhone(c.phone)}</td>
                    <td className="py-2 pr-3">{c.country || '—'}</td>
                    <td className="py-2 pr-3">{c.region || '—'}</td>
                    <td className="py-2 pr-3">{c.city || '—'}</td>
                    <td className="py-2 pr-3">
                      <div className="flex items-center gap-1 justify-end">
                        <button onClick={(e) => { e.stopPropagation(); setEdit(c); }}
                                className="p-1.5 rounded hover:bg-black/5 text-ink/60"
                                title="Tahrirlash">
                          <Pencil size={15} />
                        </button>
                        <button onClick={(e) => handleDelete(c, e)}
                                className="p-1.5 rounded hover:bg-danger/10 text-danger"
                                title="O'chirish">
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {showCreate && <CustomerModal customer={null} onClose={() => setShowCreate(false)} onSaved={refresh} />}
      {edit && <CustomerModal customer={edit} onClose={() => setEdit(null)} onSaved={refresh} />}
    </div>
  );
}
