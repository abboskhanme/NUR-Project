import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Search, X, User, FileText, Package, Wrench, Loader2 } from 'lucide-react';

import { api } from '@/api/client';
import { orderStatusLabel } from '@/lib/status';

interface SearchItem {
  id: string;
  label: string;
  sublabel?: string | null;
  status?: string | null;
  route: string;
}
interface SearchGroup { type: string; items: SearchItem[] }
interface SearchResponse { query: string; groups: SearchGroup[] }

const GROUP_META: Record<string, { icon: typeof User; title: string }> = {
  customers: { icon: User, title: 'Mijozlar' },
  orders: { icon: FileText, title: 'Buyurtmalar' },
  products: { icon: Package, title: 'Mahsulotlar' },
  service: { icon: Wrench, title: 'Servis' },
};

export default function GlobalSearch({ open, onClose }: { open: boolean; onClose: () => void }) {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [debounced, setDebounced] = useState('');
  const [active, setActive] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  // Ochilganda inputga fokus va holatni tozalash
  useEffect(() => {
    if (open) {
      setQuery('');
      setDebounced('');
      setActive(0);
      setTimeout(() => inputRef.current?.focus(), 30);
    }
  }, [open]);

  // Debounce — 250ms
  useEffect(() => {
    const id = setTimeout(() => setDebounced(query.trim()), 250);
    return () => clearTimeout(id);
  }, [query]);

  const { data, isFetching } = useQuery<SearchResponse>({
    queryKey: ['global-search', debounced],
    queryFn: () => api.get('/search', { params: { q: debounced } }).then((r) => r.data),
    enabled: open && debounced.length >= 2,
  });

  // Klaviatura navigatsiyasi uchun yassi ro'yxat
  const flat = useMemo(() => {
    const out: SearchItem[] = [];
    (data?.groups ?? []).forEach((g) => g.items.forEach((it) => out.push(it)));
    return out;
  }, [data]);

  useEffect(() => { setActive(0); }, [data]);

  function select(item?: SearchItem) {
    const target = item ?? flat[active];
    if (!target) return;
    navigate(target.route);
    onClose();
  }

  function onKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Escape') { onClose(); return; }
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((a) => Math.min(a + 1, flat.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)); }
    else if (e.key === 'Enter') { e.preventDefault(); select(); }
  }

  if (!open) return null;

  const hasResults = (data?.groups?.length ?? 0) > 0;
  let runningIndex = -1;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-start justify-center bg-black/40 p-4 pt-[12vh]"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-xl overflow-hidden"
        onClick={(e) => e.stopPropagation()}
        onKeyDown={onKeyDown}
      >
        {/* Qidiruv maydoni */}
        <div className="flex items-center gap-3 px-4 py-3 border-b border-black/5">
          <Search size={18} className="text-ink/40 shrink-0" />
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buyurtma, mijoz, mahsulot yoki servis qidiring…"
            className="flex-1 bg-transparent outline-none text-sm text-ink placeholder:text-ink-soft"
          />
          {isFetching && <Loader2 size={16} className="text-ink/40 animate-spin shrink-0" />}
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50 shrink-0">
            <X size={16} />
          </button>
        </div>

        {/* Natijalar */}
        <div className="max-h-[55vh] overflow-y-auto">
          {debounced.length < 2 ? (
            <div className="px-4 py-8 text-center text-sm text-ink-soft">Qidirish uchun kamida 2 ta belgi kiriting</div>
          ) : !hasResults && !isFetching ? (
            <div className="px-4 py-8 text-center text-sm text-ink-soft">{`«${debounced}» bo'yicha hech narsa topilmadi`}</div>
          ) : (
            (data?.groups ?? []).map((g) => {
              const meta = GROUP_META[g.type];
              const Icon = meta?.icon ?? FileText;
              return (
                <div key={g.type} className="py-1">
                  <div className="px-4 pt-2 pb-1 text-[11px] font-semibold uppercase tracking-wide text-ink-soft">
                    {meta ? meta.title : g.type}
                  </div>
                  {g.items.map((item) => {
                    runningIndex += 1;
                    const idx = runningIndex;
                    return (
                      <button
                        key={`${g.type}-${item.id}`}
                        onMouseEnter={() => setActive(idx)}
                        onClick={() => select(item)}
                        className={`w-full flex items-center gap-3 px-4 py-2 text-left ${
                          active === idx ? 'bg-primary/10' : 'hover:bg-black/5'
                        }`}
                      >
                        <Icon size={16} className="text-ink/40 shrink-0" />
                        <div className="min-w-0 flex-1">
                          <div className="text-sm text-ink truncate">{item.label}</div>
                          {item.sublabel && (
                            <div className="text-xs text-ink-soft truncate">{item.sublabel}</div>
                          )}
                        </div>
                        {item.status && (
                          <span className="text-[11px] text-ink-soft shrink-0">{orderStatusLabel(item.status)}</span>
                        )}
                      </button>
                    );
                  })}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
