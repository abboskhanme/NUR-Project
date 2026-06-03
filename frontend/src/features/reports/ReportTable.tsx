import { ReactNode, useMemo, useState } from 'react';
import { ArrowUpDown, ArrowUp, ArrowDown, Download } from 'lucide-react';

import { exportCSV } from '@/lib/export';

export interface Column<T> {
  key: string;
  label: string;
  align?: 'left' | 'right' | 'center';
  /** Jadvalda ko'rsatish uchun render funksiyasi. */
  render?: (row: T) => ReactNode;
  /** Saralash va CSV uchun xom qiymat. */
  value?: (row: T) => string | number;
  sortable?: boolean;
}

interface Props<T> {
  rows: T[] | undefined;
  columns: Column<T>[];
  filename?: string;
  emptyText?: string;
  /** Jami qatori ko'rsatish uchun: ustun kaliti -> yig'indi render. */
  footer?: ReactNode;
}

export default function ReportTable<T extends object>({
  rows, columns, filename, emptyText = "Ma'lumot yo'q", footer,
}: Props<T>) {
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');

  const valueOf = (row: T, col: Column<T>): string | number =>
    col.value ? col.value(row) : ((row as Record<string, unknown>)[col.key] as string | number);

  const sorted = useMemo(() => {
    if (!rows) return undefined;
    if (!sortKey) return rows;
    const col = columns.find((c) => c.key === sortKey);
    if (!col) return rows;
    const copy = [...rows];
    copy.sort((a, b) => {
      const av = valueOf(a, col);
      const bv = valueOf(b, col);
      if (typeof av === 'number' && typeof bv === 'number') {
        return sortDir === 'asc' ? av - bv : bv - av;
      }
      const cmp = String(av).localeCompare(String(bv));
      return sortDir === 'asc' ? cmp : -cmp;
    });
    return copy;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rows, sortKey, sortDir, columns]);

  function toggleSort(col: Column<T>) {
    if (col.sortable === false) return;
    if (sortKey === col.key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortKey(col.key);
      setSortDir('desc');
    }
  }

  function handleExport() {
    const data = (sorted ?? []).map((row) => {
      const obj: Record<string, unknown> = {};
      columns.forEach((c) => { obj[c.key] = valueOf(row, c); });
      return obj;
    });
    exportCSV(data, columns.map((c) => ({ key: c.key, label: c.label })), filename ?? 'hisobot');
  }

  const align = (a?: string) =>
    a === 'right' ? 'text-right' : a === 'center' ? 'text-center' : 'text-left';

  return (
    <div>
      {filename && (
        <div className="flex justify-end mb-2">
          <button
            onClick={handleExport}
            disabled={!sorted || sorted.length === 0}
            className="inline-flex items-center gap-1.5 text-sm text-primary hover:text-primary-700 disabled:opacity-40"
          >
            <Download size={15} /> CSV
          </button>
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-ink-soft border-b border-black/10">
              {columns.map((c) => (
                <th
                  key={c.key}
                  className={`py-2 px-2 font-medium ${align(c.align)} ${c.sortable === false ? '' : 'cursor-pointer select-none'}`}
                  onClick={() => toggleSort(c)}
                >
                  <span className="inline-flex items-center gap-1">
                    {c.label}
                    {c.sortable !== false && (
                      sortKey === c.key
                        ? (sortDir === 'asc' ? <ArrowUp size={12} /> : <ArrowDown size={12} />)
                        : <ArrowUpDown size={12} className="opacity-30" />
                    )}
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {!sorted && (
              <tr><td colSpan={columns.length} className="py-8 text-center text-ink-soft">Yuklanmoqda…</td></tr>
            )}
            {sorted && sorted.length === 0 && (
              <tr><td colSpan={columns.length} className="py-8 text-center text-ink-soft">{emptyText}</td></tr>
            )}
            {sorted?.map((row, i) => (
              <tr key={i} className="border-b border-black/5 hover:bg-primary/5">
                {columns.map((c) => (
                  <td key={c.key} className={`py-2 px-2 ${align(c.align)}`}>
                    {c.render ? c.render(row) : String(row[c.key] ?? '')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
          {footer && sorted && sorted.length > 0 && (
            <tfoot>
              <tr className="border-t-2 border-black/10 font-semibold">{footer}</tr>
            </tfoot>
          )}
        </table>
      </div>
    </div>
  );
}
