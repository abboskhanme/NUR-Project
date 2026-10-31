import { Boxes } from 'lucide-react';

export interface ModelCount {
  name: string;
  count: number;
  right: number;
  left: number;
}

/**
 * Qaysi modeldan nechta dona hali yetkazilmagan — Navbat va Sotuv
 * sahifalarining tepasidagi umumiy card. Qo'shimcha mahsulotlar kirmaydi.
 */
export default function ModelCountsCard({ title, rows }: { title: string; rows: ModelCount[] }) {
  if (rows.length === 0) return null;
  const total = rows.reduce((s, r) => s + r.count, 0);
  return (
    <div className="card !p-3 sm:!p-4">
      <div className="flex items-center justify-between gap-2 flex-wrap mb-3">
        <div className="flex items-center gap-1.5 text-sm font-medium">
          <Boxes size={18} className="text-primary shrink-0" />
          {title}
        </div>
        <div className="text-xs text-ink-soft">
          Jami: <span className="font-semibold text-ink">{total} ta</span>
        </div>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2">
        {rows.map((r) => {
          const other = r.count - r.right - r.left;
          const dirs = [
            r.right ? `O'NG ${r.right}` : '',
            r.left ? `CHAP ${r.left}` : '',
            (r.right || r.left) && other > 0 ? `— ${other}` : '',
          ].filter(Boolean).join(' · ');
          return (
            <div key={r.name} className="rounded-button border border-primary/20 bg-primary/5 px-3 py-2 min-w-0">
              <div className="text-xs font-medium text-ink-soft truncate" title={r.name}>{r.name}</div>
              <div className="text-xl font-bold text-primary">{r.count} ta</div>
              {dirs && <div className="text-[11px] text-ink-soft truncate" title={dirs}>{dirs}</div>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
