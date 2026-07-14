import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Boxes, PackageCheck, Search, Trash2, Pencil, Wallet } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import BalanceCard from '@/components/ui/BalanceCard';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDate, formatUSD, formatUZS } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import AddUnitsModal from '@/features/warehouse/AddUnitsModal';
import EditUnitModal from '@/features/warehouse/EditUnitModal';
import ProductModal, { ProductFull } from '@/features/products/ProductModal';

interface SummaryRow {
  product_id: string; model: string | null; kvm: number | null;
  available: number; reserved: number; sold: number; total: number;
}
interface Summary {
  rows: SummaryRow[]; total_available: number; total_reserved: number; total_sold: number;
  total_value_usd: number;
}
interface Unit {
  id: string; unique_id: string; status: string; added_date: string; notes?: string | null;
  product_id: string; bunker_direction?: string | null;
  model: string | null; kvm: number | null; order_code?: string | null; customer_name?: string | null;
}
interface MainProduct extends ProductFull {
  display_name: string;
}
interface SizeRow {
  kvm: number | null; right: number; left: number; total: number;
}
interface SizeSummary {
  rows: SizeRow[]; total_right: number; total_left: number; total: number;
}

const STATUS_STYLE: Record<string, string> = {
  available: 'bg-success/10 text-success',
  reserved: 'bg-warning/10 text-warning',
  sold: 'bg-black/5 text-ink-soft',
};

type Tab = 'types' | 'list' | 'sizes';

export default function WarehousePage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const [tab, setTab] = useState<Tab>('types');
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [typeSearch, setTypeSearch] = useState('');
  const [adding, setAdding] = useState(false);
  const [editUnit, setEditUnit] = useState<Unit | null>(null);
  const [deleteUnit, setDeleteUnit] = useState<Unit | null>(null);
  // Turlari (model) CRUD holati
  const [editingType, setEditingType] = useState<MainProduct | null>(null);
  const [typeModalOpen, setTypeModalOpen] = useState(false);
  const [deleteType, setDeleteType] = useState<MainProduct | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['wh-summary'],
    queryFn: () => api.get('/inventory/summary').then((r) => r.data),
  });
  const unitsQ = useQuery<Unit[]>({
    queryKey: ['wh-units', status, search],
    queryFn: () => api.get('/inventory/units', {
      params: { status: status || undefined, search: search.trim() || undefined },
    }).then((r) => r.data),
    enabled: tab === 'list',
  });
  const typesQ = useQuery<{ items: MainProduct[] }>({
    queryKey: ['wh-types'],
    queryFn: () => api.get('/products', {
      params: { product_type: 'warehouse', page_size: 200 },
    }).then((r) => r.data),
    enabled: tab === 'types',
  });
  const sizeSummaryQ = useQuery<SizeSummary>({
    queryKey: ['wh-size-summary'],
    queryFn: () => api.get('/inventory/size-summary').then((r) => r.data),
    enabled: tab === 'sizes',
  });
  const rateQ = useQuery<number>({
    queryKey: ['usd-rate'],
    queryFn: () => api.get('/finance/exchange-rates/latest').then((r) => Number(r.data?.usd_to_uzs) || 0),
  });

  const s = summaryQ.data;
  const rate = rateQ.data ?? 0;
  const totalValueUsd = Number(s?.total_value_usd ?? 0);
  const units = unitsQ.data ?? [];
  const types = typesQ.data?.items ?? [];
  const sz = sizeSummaryQ.data;

  // Turlari qidiruvi — model / o'lcham (kvm) / nom bo'yicha (mijoz tomonida)
  const filteredTypes = useMemo(() => {
    const term = typeSearch.trim().toLowerCase();
    if (!term) return types;
    return types.filter((p) =>
      (p.model ?? '').toLowerCase().includes(term) ||
      String(p.kvm ?? '').includes(term) ||
      (p.display_name ?? '').toLowerCase().includes(term),
    );
  }, [types, typeSearch]);

  // product_id -> qoldiq sanoqlari (Turlari tab uchun)
  const countByProduct = useMemo(() => {
    const m = new Map<string, SummaryRow>();
    for (const r of s?.rows ?? []) m.set(r.product_id, r);
    return m;
  }, [s]);

  const statusLabel = useMemo(() => ({
    available: 'Boʻsh',
    reserved: 'Band',
    sold: 'Sotilgan',
  } as Record<string, string>), []);

  function refresh() {
    qc.invalidateQueries({ queryKey: ['wh-summary'] });
    qc.invalidateQueries({ queryKey: ['wh-units'] });
    qc.invalidateQueries({ queryKey: ['wh-types'] });
    qc.invalidateQueries({ queryKey: ['wh-size-summary'] });
  }

  async function confirmDelete() {
    if (!deleteUnit) return;
    try {
      await api.delete(`/inventory/units/${deleteUnit.id}`);
      toast.success("O'chirildi");
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleteUnit(null);
    }
  }

  async function confirmDeleteType() {
    if (!deleteType) return;
    try {
      await api.delete(`/products/${deleteType.id}`);
      toast.success("O'chirildi");
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleteType(null);
    }
  }

  const STATUS_FILTERS = ['', 'available', 'reserved'] as const;
  const TABS: Array<{ key: Tab; label: string }> = [
    { key: 'types', label: 'Turlari' },
    { key: 'list', label: 'Roʻyxat' },
    { key: 'sizes', label: 'Oʻlcham boʻyicha' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Ombor</h1>
          <p className="text-sm text-ink-soft">Kotyol skladi — ID raqamli birliklar</p>
        </div>
        {can('inventory:write') && (
          tab === 'list' ? (
            <button className="btn-primary" onClick={() => setAdding(true)}>
              <Plus size={16} /> Birlik qoʻshish
            </button>
          ) : (
            <button className="btn-primary" onClick={() => { setEditingType(null); setTypeModalOpen(true); }}>
              <Plus size={16} /> Model qoʻshish
            </button>
          )
        )}
      </div>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
        <BalanceCard title="Boʻsh" accent="success"
          value={String(s?.total_available ?? 0)} icon={<PackageCheck size={18} />} />
        <BalanceCard title="Band" accent="warning"
          value={String(s?.total_reserved ?? 0)} icon={<Boxes size={18} />} />
        <div className="col-span-2">
          <BalanceCard title="Ombor qiymati ($)" accent="primary"
            value={formatUSD(totalValueUsd)} icon={<Wallet size={18} />} />
        </div>
        <div className="col-span-2">
          <BalanceCard title="Ombor qiymati (soʻm)" accent="success"
            value={rate > 0 ? formatUZS(totalValueUsd * rate) : '—'} icon={<Wallet size={18} />} />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5">
        {TABS.map((tb) => (
          <button key={tb.key} onClick={() => setTab(tb.key)}
            className={
              'px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors ' +
              (tab === tb.key
                ? 'border-primary text-primary'
                : 'border-transparent text-ink-soft hover:text-ink')
            }>
            {tb.label}
          </button>
        ))}
      </div>

      {tab === 'types' ? (
        /* Turlari — kotyol modellari (qoʻshish / tahrir / oʻchirish) */
        <Card title="Turlari">
          {types.length > 0 && (
            <div className="relative mb-4 w-full max-w-xs">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input className="input pl-9 w-full" placeholder="Model yoki oʻlcham boʻyicha qidirish"
                     value={typeSearch} onChange={(e) => setTypeSearch(e.target.value)} />
            </div>
          )}
          {typesQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
            </div>
          ) : types.length === 0 ? (
            <EmptyState title="Hozircha model yoʻq" description="Kotyol modellarini shu yerda qoʻshing" />
          ) : filteredTypes.length === 0 ? (
            <EmptyState title="Model topilmadi" description="Qidiruvni oʻzgartirib koʻring" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Model</th>
                    <th className="py-2 pr-3">Oʻlcham</th>
                    <th className="py-2 pr-3 text-right">Narx</th>
                    <th className="py-2 pr-3 text-right">Boʻsh</th>
                    <th className="py-2 pr-3 text-right">Band</th>
                    <th className="py-2 pr-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {filteredTypes.map((p) => {
                    const c = countByProduct.get(p.id);
                    return (
                      <tr key={p.id} className="border-b border-black/5 hover:bg-black/5">
                        <td className="py-2 pr-3 font-medium">{p.model ?? '—'}</td>
                        <td className="py-2 pr-3">{p.kvm ? `${p.kvm} kvm` : '—'}</td>
                        <td className="py-2 pr-3 text-right">{formatUSD(p.base_price_usd)}</td>
                        <td className="py-2 pr-3 text-right font-semibold text-success">{c?.available ?? 0}</td>
                        <td className="py-2 pr-3 text-right text-warning">{c?.reserved ?? 0}</td>
                        <td className="py-2 pr-3 text-right">
                          <div className="flex items-center justify-end gap-1">
                            {can('inventory:write') && (
                              <button onClick={() => { setEditingType(p); setTypeModalOpen(true); }}
                                      className="p-1 rounded hover:bg-primary/10 text-primary" title="Tahrirlash">
                                <Pencil size={14} />
                              </button>
                            )}
                            {can('inventory:delete') && (
                              <button onClick={() => setDeleteType(p)}
                                      className="p-1 rounded hover:bg-danger/10 text-danger" title="O'chirish">
                                <Trash2 size={14} />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      ) : tab === 'list' ? (
        /* Roʻyxat — ID raqamli birliklar */
        <Card title="Birliklar">
          <div className="flex flex-wrap gap-3 mb-4 items-center justify-between">
            <div className="flex flex-wrap gap-1.5">
              {STATUS_FILTERS.map((k) => (
                <button key={k} onClick={() => setStatus(k)}
                  className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                    status === k ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
                  {k === '' ? 'Hammasi' : statusLabel[k]}
                </button>
              ))}
            </div>
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input className="input pl-9 w-64" placeholder="ID, model yoki oʻlcham boʻyicha qidirish"
                     value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
          </div>

          {unitsQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
            </div>
          ) : units.length === 0 ? (
            <EmptyState title="Birlik topilmadi" description="Ishlab chiqarilgan kotyollarni ID bilan qoʻshing" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">ID raqami</th>
                    <th className="py-2 pr-3">Model</th>
                    <th className="py-2 pr-3">Oʻlcham</th>
                    <th className="py-2 pr-3">Yoʻnalish</th>
                    <th className="py-2 pr-3">Holat</th>
                    <th className="py-2 pr-3">Qoʻshilgan</th>
                    <th className="py-2 pr-3">Buyurtma / mijoz</th>
                    <th className="py-2 pr-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {units.map((u) => (
                    <tr key={u.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 font-mono font-medium">{u.unique_id}</td>
                      <td className="py-2 pr-3">{u.model ?? '—'}</td>
                      <td className="py-2 pr-3">{u.kvm ? `${u.kvm} kvm` : '—'}</td>
                      <td className="py-2 pr-3">
                        {u.bunker_direction === 'right' ? 'Oʻngga'
                          : u.bunker_direction === 'left' ? 'Chapga'
                          : <span className="text-ink-soft">—</span>}
                      </td>
                      <td className="py-2 pr-3">
                        <span className={`badge ${STATUS_STYLE[u.status] ?? ''}`}>{statusLabel[u.status] ?? u.status}</span>
                      </td>
                      <td className="py-2 pr-3 whitespace-nowrap">{formatDate(u.added_date)}</td>
                      <td className="py-2 pr-3">
                        {u.order_code
                          ? <span>{u.order_code}{u.customer_name ? ` · ${u.customer_name}` : ''}</span>
                          : <span className="text-ink-soft">—</span>}
                      </td>
                      <td className="py-2 pr-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {u.status !== 'sold' && can('inventory:write') && (
                            <button onClick={() => setEditUnit(u)} className="p-1 rounded hover:bg-primary/10 text-primary" title="Tahrirlash">
                              <Pencil size={14} />
                            </button>
                          )}
                          {u.status === 'available' && can('inventory:delete') && (
                            <button onClick={() => setDeleteUnit(u)} className="p-1 rounded hover:bg-danger/10 text-danger" title="O'chirish">
                              <Trash2 size={14} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      ) : (
        /* Oʻlcham boʻyicha qoldiq — model farqlanmaydi, faqat oʻlcham + yoʻnalish */
        <Card title="Oʻlcham boʻyicha qoldiq">
          <p className="text-sm text-ink-soft mb-4">
            Ombordagi boʻsh birliklar — oʻlchami va yoʻnalishi boʻyicha (modeldan qatʼi nazar)
          </p>
          {sizeSummaryQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
            </div>
          ) : (sz?.rows.length ?? 0) === 0 ? (
            <EmptyState title="Ombor boʻsh" description="Hozircha boʻsh birlik yoʻq" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Oʻlcham</th>
                    <th className="py-2 pr-3 text-right">Oʻngga</th>
                    <th className="py-2 pr-3 text-right">Chapga</th>
                    <th className="py-2 pr-3 text-right">Jami</th>
                  </tr>
                </thead>
                <tbody>
                  {sz!.rows.map((r) => (
                    <tr key={r.kvm ?? 'none'} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 font-medium">{r.kvm ? `${r.kvm} kvm` : '—'}</td>
                      <td className="py-2 pr-3 text-right">{r.right || '—'}</td>
                      <td className="py-2 pr-3 text-right">{r.left || '—'}</td>
                      <td className="py-2 pr-3 text-right font-semibold text-success">{r.total}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 border-black/10 font-semibold">
                    <td className="py-2 pr-3">Jami</td>
                    <td className="py-2 pr-3 text-right">{sz!.total_right || '—'}</td>
                    <td className="py-2 pr-3 text-right">{sz!.total_left || '—'}</td>
                    <td className="py-2 pr-3 text-right text-success">{sz!.total}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </Card>
      )}

      {adding && <AddUnitsModal onClose={() => setAdding(false)} onSaved={refresh} />}
      {editUnit && (
        <EditUnitModal
          unit={editUnit}
          onClose={() => setEditUnit(null)}
          onSaved={refresh}
        />
      )}
      {typeModalOpen && (
        <ProductModal
          product={editingType}
          defaultType="warehouse"
          onClose={() => setTypeModalOpen(false)}
          onSaved={refresh}
        />
      )}
      <ConfirmModal
        open={deleteUnit !== null}
        title="Birlikni oʻchirish"
        message={`«${deleteUnit?.unique_id ?? ''}» birligini oʻchirishni tasdiqlaysizmi?`}
        confirmText="O'chirish"
        variant="danger"
        onConfirm={confirmDelete}
        onCancel={() => setDeleteUnit(null)}
      />
      <ConfirmModal
        open={deleteType !== null}
        title="Modelni oʻchirish"
        message={`«${deleteType?.display_name ?? deleteType?.model ?? ''}» modelini oʻchirishni tasdiqlaysizmi?`}
        confirmText="O'chirish"
        variant="danger"
        onConfirm={confirmDeleteType}
        onCancel={() => setDeleteType(null)}
      />
    </div>
  );
}
