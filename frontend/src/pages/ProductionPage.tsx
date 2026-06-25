import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, Search, Flame, Boxes, Cylinder, Warehouse, CheckCircle2, Container } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import BalanceCard from '@/components/ui/BalanceCard';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDate } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import ProductionModal, { Category, ProductionRecord } from '@/features/production/ProductionModal';
import KotyolToWarehouseModal from '@/features/production/KotyolToWarehouseModal';

interface DaySummary {
  production_date: string; kotyol: number; bunker: number; garelka: number; tana: number;
}
interface Summary {
  days: DaySummary[];
  total_kotyol: number; total_bunker: number; total_garelka: number; total_tana: number;
}

type Tab = 'summary' | Category;

const TAB_KEYS: Tab[] = ['summary', 'kotyol', 'bunker', 'garelka', 'tana'];

const TAB_LABELS: Record<Tab, string> = {
  summary: "Kunlik hisobot",
  kotyol: "Kotyol",
  bunker: "Bunker",
  garelka: "Garelka",
  tana: "Kotyol tanasi",
};

const ADD_LABELS: Record<Category, string> = {
  kotyol: "Kotyol qoʻshish",
  bunker: "Bunker qoʻshish",
  garelka: "Garelka qoʻshish",
  tana: "Tana qoʻshish",
};

export default function ProductionPage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const [tab, setTab] = useState<Tab>('summary');
  const [search, setSearch] = useState('');
  const [modal, setModal] = useState<{ category: Category; record: ProductionRecord | null } | null>(null);
  const [deleteRec, setDeleteRec] = useState<ProductionRecord | null>(null);
  const [xferRec, setXferRec] = useState<ProductionRecord | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['prod-summary'],
    queryFn: () => api.get('/production/summary').then((r) => r.data),
  });

  const category = tab === 'summary' ? null : tab;
  const recordsQ = useQuery<ProductionRecord[]>({
    queryKey: ['prod-records', category, search],
    queryFn: () => api.get('/production/records', {
      params: { category, search: search.trim() || undefined },
    }).then((r) => r.data),
    enabled: category !== null,
  });

  const s = summaryQ.data;
  const records = recordsQ.data ?? [];

  function refresh() {
    qc.invalidateQueries({ queryKey: ['prod-summary'] });
    qc.invalidateQueries({ queryKey: ['prod-records'] });
  }

  async function confirmDelete() {
    if (!deleteRec) return;
    try {
      await api.delete(`/production/records/${deleteRec.id}`);
      toast.success("O'chirildi");
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setDeleteRec(null);
    }
  }

  const dirLabel = (d?: string | null) =>
    d === 'right' ? "Oʻngga" : d === 'left' ? "Chapga" : '—';

  const addBtnLabel = category ? ADD_LABELS[category] : null;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Ishlab chiqarish</h1>
          <p className="text-sm text-ink-soft">Kunlik ishlab chiqarilgan kotyol, bunker va garelka jurnali</p>
        </div>
        {category && addBtnLabel && can('production:write') && (
          <button className="btn-primary" onClick={() => setModal({ category, record: null })}>
            <Plus size={16} /> {addBtnLabel}
          </button>
        )}
      </div>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <BalanceCard title="Jami kotyol" accent="primary"
          value={String(s?.total_kotyol ?? 0)} icon={<Cylinder size={18} />} />
        <BalanceCard title="Jami bunker" accent="success"
          value={String(s?.total_bunker ?? 0)} icon={<Boxes size={18} />} />
        <BalanceCard title="Jami garelka" accent="warning"
          value={String(s?.total_garelka ?? 0)} icon={<Flame size={18} />} />
        <BalanceCard title="Jami tana" accent="primary"
          value={String(s?.total_tana ?? 0)} icon={<Container size={18} />} />
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5">
        {TAB_KEYS.map((k) => (
          <button key={k} onClick={() => setTab(k)}
            className={
              'px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors ' +
              (tab === k ? 'border-primary text-primary' : 'border-transparent text-ink-soft hover:text-ink')
            }>
            {TAB_LABELS[k]}
          </button>
        ))}
      </div>

      {tab === 'summary' ? (
        <Card title="Kunlik hisobot">
          {summaryQ.isLoading ? (
            <Skeleton />
          ) : (s?.days.length ?? 0) === 0 ? (
            <EmptyState title="Hozircha yozuv yoʻq" description="Kotyol, tana, bunker yoki garelka qoʻshing" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Sana</th>
                    <th className="py-2 pr-3 text-right">Kotyol</th>
                    <th className="py-2 pr-3 text-right">Bunker</th>
                    <th className="py-2 pr-3 text-right">Garelka</th>
                    <th className="py-2 pr-3 text-right">Tana</th>
                  </tr>
                </thead>
                <tbody>
                  {s!.days.map((d) => (
                    <tr key={d.production_date} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 whitespace-nowrap font-medium">{formatDate(d.production_date)}</td>
                      <td className="py-2 pr-3 text-right">{d.kotyol || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.bunker || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.garelka || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.tana || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      ) : (
        <Card title={TAB_LABELS[tab]}>
          {tab === 'kotyol' && (
            <div className="relative mb-4 w-full max-w-xs">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input className="input pl-9 w-full" placeholder="ID raqami boʻyicha qidirish"
                     value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
          )}

          {recordsQ.isLoading ? (
            <Skeleton />
          ) : records.length === 0 ? (
            <EmptyState title="Yozuv topilmadi" description="Yangi yozuv qoʻshing" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Sana</th>
                    {tab === 'kotyol' ? (
                      <>
                        <th className="py-2 pr-3">ID raqami</th>
                        <th className="py-2 pr-3">Model</th>
                        <th className="py-2 pr-3">Oʻlcham</th>
                        <th className="py-2 pr-3">Yoʻnalish</th>
                      </>
                    ) : tab === 'tana' ? (
                      <>
                        <th className="py-2 pr-3">Oʻlcham</th>
                        <th className="py-2 pr-3">Yoʻnalish</th>
                        <th className="py-2 pr-3 text-right">Soni</th>
                      </>
                    ) : (
                      <th className="py-2 pr-3 text-right">Soni</th>
                    )}
                    <th className="py-2 pr-3">Izoh</th>
                    <th className="py-2 pr-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((r) => (
                    <tr key={r.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 whitespace-nowrap font-medium">{formatDate(r.production_date)}</td>
                      {tab === 'kotyol' ? (
                        <>
                          <td className="py-2 pr-3 font-mono font-medium">{r.unit_code ?? '—'}</td>
                          <td className="py-2 pr-3">{r.model ?? '—'}</td>
                          <td className="py-2 pr-3">{r.kvm ? `${r.kvm} kvm` : '—'}</td>
                          <td className="py-2 pr-3">{dirLabel(r.bunker_direction)}</td>
                        </>
                      ) : tab === 'tana' ? (
                        <>
                          <td className="py-2 pr-3 font-medium">{r.body_size ?? '—'}</td>
                          <td className="py-2 pr-3">{dirLabel(r.bunker_direction)}</td>
                          <td className="py-2 pr-3 text-right font-semibold">{r.quantity}</td>
                        </>
                      ) : (
                        <td className="py-2 pr-3 text-right font-semibold">{r.quantity}</td>
                      )}
                      <td className="py-2 pr-3 text-ink-soft">{r.notes ?? '—'}</td>
                      <td className="py-2 pr-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {tab === 'kotyol' && (
                            r.transferred ? (
                              <span className="p-1 inline-flex items-center text-success"
                                    title="Omborga oʻtkazilgan">
                                <CheckCircle2 size={14} />
                              </span>
                            ) : can('inventory:write') ? (
                              <button onClick={() => setXferRec(r)}
                                      className="p-1 rounded hover:bg-accent/10 text-accent" title="Omborga oʻtkazish">
                                <Warehouse size={14} />
                              </button>
                            ) : null
                          )}
                          {can('production:write') && (
                            <button onClick={() => setModal({ category: tab, record: r })}
                                    className="p-1 rounded hover:bg-primary/10 text-primary" title="Tahrirlash">
                              <Pencil size={14} />
                            </button>
                          )}
                          {can('production:delete') && (
                            <button onClick={() => setDeleteRec(r)}
                                    className="p-1 rounded hover:bg-danger/10 text-danger" title="O'chirish">
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
      )}

      {modal && (
        <ProductionModal
          category={modal.category}
          record={modal.record}
          onClose={() => setModal(null)}
          onSaved={refresh}
        />
      )}
      {xferRec && (
        <KotyolToWarehouseModal
          record={xferRec}
          onClose={() => setXferRec(null)}
          onSaved={() => {
            refresh(); // prod-records yangilanadi → qator "o'tkazilgan" holatiga o'tadi
            qc.invalidateQueries({ queryKey: ['wh-summary'] });
            qc.invalidateQueries({ queryKey: ['wh-units'] });
            qc.invalidateQueries({ queryKey: ['wh-types'] });
          }}
        />
      )}
      <ConfirmModal
        open={deleteRec !== null}
        title="Yozuvni oʻchirish"
        message="Ushbu yozuvni oʻchirishni tasdiqlaysizmi?"
        confirmText="O'chirish"
        variant="danger"
        onConfirm={confirmDelete}
        onCancel={() => setDeleteRec(null)}
      />
    </div>
  );
}

function Skeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
    </div>
  );
}
