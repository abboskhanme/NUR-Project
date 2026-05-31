import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Plus, AlertTriangle } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { cn } from '@/lib/cn';

interface Sector { id: string; name: string; code: string; }
interface Item {
  id: string; name: string; sector_id?: string | null; unit: string;
  stock_qty: string; min_qty: string;
}

export default function SupplyPage() {
  const [sectorId, setSectorId] = useState<string | undefined>();

  const sectors = useQuery({
    queryKey: ['supply-sectors'],
    queryFn: () => api.get('/supply/sectors').then((r) => r.data as Sector[]),
  });

  const items = useQuery({
    queryKey: ['supply-items', sectorId],
    queryFn: () => api.get('/supply/items', {
      params: { sector_id: sectorId, page_size: 100 },
    }).then((r) => r.data),
  });

  const list: Item[] = items.data?.items ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Ta'minot</h1>
          <p className="text-sm text-ink-soft">Materiallar, vendorlar va ombor</p>
        </div>
        <button className="btn-primary"><Plus size={16} /> Yangi kirim</button>
      </div>

      {/* Sector tabs */}
      <div className="flex gap-2 flex-wrap">
        <button
          onClick={() => setSectorId(undefined)}
          className={cn('btn-ghost', !sectorId && 'bg-primary/10 text-primary')}
        >
          Barchasi
        </button>
        {(sectors.data ?? []).map((s) => (
          <button
            key={s.id}
            onClick={() => setSectorId(s.id)}
            className={cn('btn-ghost', sectorId === s.id && 'bg-primary/10 text-primary')}
          >
            {s.name}
          </button>
        ))}
      </div>

      <Card>
        {list.length === 0 ? (
          <EmptyState title="Materiallar yo'q" />
        ) : (
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Nomi</th>
                <th className="py-2 pr-3">Birlik</th>
                <th className="py-2 pr-3">Joriy zaxira</th>
                <th className="py-2 pr-3">Minimum</th>
                <th className="py-2 pr-3">Holat</th>
              </tr>
            </thead>
            <tbody>
              {list.map((it) => {
                const low = parseFloat(it.stock_qty) < parseFloat(it.min_qty);
                return (
                  <tr key={it.id} className="border-b border-black/5 hover:bg-black/5">
                    <td className="py-2 pr-3 font-medium">{it.name}</td>
                    <td className="py-2 pr-3">{it.unit}</td>
                    <td className="py-2 pr-3">{it.stock_qty}</td>
                    <td className="py-2 pr-3">{it.min_qty}</td>
                    <td className="py-2 pr-3">
                      {low
                        ? <span className="badge bg-danger/10 text-danger"><AlertTriangle size={12} /> Kam</span>
                        : <span className="badge bg-success/10 text-success">OK</span>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  );
}
