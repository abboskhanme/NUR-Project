import { Fragment, useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, Search, Flame, Boxes, Cylinder, Warehouse, CheckCircle2, Container, CalendarDays, CalendarRange, ChevronLeft, ChevronRight } from 'lucide-react';

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
  tana: "Ishlab chiqarishdan olib kelish",
};

const ADD_LABELS: Record<Category, string> = {
  kotyol: "Kotyol qoʻshish",
  bunker: "Bunker qoʻshish",
  garelka: "Garelka qoʻshish",
  tana: "Ishlab chiqarishdan olib kelish",
};

// Hisobot filtri uchun oy nomlari (1..12)
const REPORT_MONTHS: Record<number, string> = {
  1: 'Yanvar', 2: 'Fevral', 3: 'Mart', 4: 'Aprel', 5: 'May', 6: 'Iyun',
  7: 'Iyul', 8: 'Avgust', 9: 'Sentabr', 10: 'Oktabr', 11: 'Noyabr', 12: 'Dekabr',
};
const rpad2 = (n: number) => String(n).padStart(2, '0');

export default function ProductionPage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const [tab, setTab] = useState<Tab>('summary');
  const [search, setSearch] = useState('');
  const [modal, setModal] = useState<{ category: Category; record: ProductionRecord | null } | null>(null);
  const [deleteRec, setDeleteRec] = useState<ProductionRecord | null>(null);
  const [xferRec, setXferRec] = useState<ProductionRecord | null>(null);

  // Davr filtri — oy / yil (month 0 = butun yil). Kun uchun alohida filtr YO'Q:
  // ichki bo'limlarda kunlar sahifalash sifatida ishlaydi (pastdagi dayPager).
  const now = new Date();
  const [repYear, setRepYear] = useState(now.getFullYear());
  const [repMonth, setRepMonth] = useState(now.getMonth() + 1);
  // Sahifalash kursori — tanlangan kun (ISO). Ro'yxatda bo'lmasa birinchisiga tushadi.
  const [dayCursor, setDayCursor] = useState<string | null>(null);
  // Ko'rinish: kun bo'yicha sahifalash yoki butun tanlangan oy birdaniga
  const [wholeMonth, setWholeMonth] = useState(false);

  const { dateFrom, dateTo } = useMemo(() => {
    if (repMonth === 0) return { dateFrom: `${repYear}-01-01`, dateTo: `${repYear}-12-31` };
    const last = new Date(repYear, repMonth, 0).getDate();
    return {
      dateFrom: `${repYear}-${rpad2(repMonth)}-01`,
      dateTo: `${repYear}-${rpad2(repMonth)}-${rpad2(last)}`,
    };
  }, [repYear, repMonth]);
  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);
  const isDefaultPeriod = repYear === now.getFullYear() && repMonth === now.getMonth() + 1;
  const periodLabel = repMonth === 0
    ? `${repYear}-yil`
    : `${REPORT_MONTHS[repMonth]} ${repYear}`;

  // KPI kartalar uchun — butun davr (filtrsiz) jami
  const summaryQ = useQuery<Summary>({
    queryKey: ['prod-summary'],
    queryFn: () => api.get('/production/summary').then((r) => r.data),
  });

  // Hisobot jadvali uchun — tanlangan davr bo'yicha
  const reportQ = useQuery<Summary>({
    queryKey: ['prod-summary', dateFrom, dateTo],
    queryFn: () => api.get('/production/summary', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
    enabled: tab === 'summary',
  });
  const rs = reportQ.data;

  // Ichki bo'limlar (kotyol/bunker/garelka/tana) ham xuddi hisobot kabi
  // tanlangan davr bo'yicha filtrlanadi — kunlik ko'rish uchun.
  const category = tab === 'summary' ? null : tab;
  const recordsQ = useQuery<ProductionRecord[]>({
    queryKey: ['prod-records', category, search, dateFrom, dateTo],
    queryFn: () => api.get('/production/records', {
      params: {
        category,
        search: search.trim() || undefined,
        date_from: dateFrom,
        date_to: dateTo,
      },
    }).then((r) => r.data),
    enabled: category !== null,
  });

  const s = summaryQ.data;
  const records = useMemo(() => recordsQ.data ?? [], [recordsQ.data]);

  // --- Kunlar bo'yicha sahifalash -----------------------------------------
  // Yozuvlar bor kunlar (yangidan eskiga). Bo'sh kunlar ro'yxatga tushmaydi —
  // shunda "keyingi/oldingi" bosganda bo'sh sahifalar orasidan o'tilmaydi.
  const dayGroups = useMemo(() => {
    const map = new Map<string, ProductionRecord[]>();
    for (const r of records) {
      const list = map.get(r.production_date);
      if (list) list.push(r);
      else map.set(r.production_date, [r]);
    }
    return [...map.entries()].sort((a, b) => b[0].localeCompare(a[0]));
  }, [records]);

  // Qidiruv paytida sahifalash o'chadi — natijalar butun oy bo'yicha ko'rsatiladi
  const searching = search.trim().length > 0;
  const dayKeys = dayGroups.map(([d]) => d);
  const activeDay = dayCursor && dayKeys.includes(dayCursor) ? dayCursor : (dayKeys[0] ?? null);
  const dayIdx = activeDay ? dayKeys.indexOf(activeDay) : -1;
  const visibleRecords = searching || wholeMonth || !activeDay
    ? records
    : (dayGroups.find(([d]) => d === activeDay)?.[1] ?? []);
  const visibleTotal = visibleRecords.reduce((sum, r) => sum + (r.quantity ?? 0), 0);

  // Jadval guruhlari: butun oy rejimida kunlar sarlavha qatori bilan ajratiladi
  const tableGroups: [string | null, ProductionRecord[]][] =
    wholeMonth && !searching ? dayGroups : [[null, visibleRecords]];
  const colCount = tab === 'kotyol' ? 6 : tab === 'tana' ? 5 : 3;

  // Davr jamlanmasi — doim ko'rinib turadi (kun almashsa ham o'zgarmaydi)
  const periodTotal = records.reduce((sum, r) => sum + (r.quantity ?? 0), 0);

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

  // Davr filtri — hisobotda ham, ichki bo'limlarda ham bir xil ishlaydi
  const periodFilter = (
    <div className="flex items-center gap-2 flex-wrap mb-4">
      <span className="text-sm text-ink-soft inline-flex items-center gap-1.5">
        <CalendarDays size={15} /> Davr:
      </span>
      <select className="input w-36" value={repMonth}
              onChange={(e) => { setRepMonth(Number(e.target.value)); setDayCursor(null); }}>
        <option value={0}>Butun yil</option>
        {Object.entries(REPORT_MONTHS).map(([n, l]) => (
          <option key={n} value={n}>{l}</option>
        ))}
      </select>
      <select className="input w-24" value={repYear}
              onChange={(e) => { setRepYear(Number(e.target.value)); setDayCursor(null); }}>
        {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
      </select>
      {!isDefaultPeriod && (
        <button
          onClick={() => {
            setRepYear(now.getFullYear()); setRepMonth(now.getMonth() + 1); setDayCursor(null);
          }}
          className="text-xs text-ink-soft hover:text-primary px-2 py-1 rounded-button hover:bg-black/5">
          Joriy oy
        </button>
      )}
    </div>
  );

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
          {periodFilter}

          {/* Tanlangan davr jamlanmasi */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-4">
            <PeriodStat label="Kotyol" value={rs?.total_kotyol ?? 0} tone="primary" />
            <PeriodStat label="Bunker" value={rs?.total_bunker ?? 0} tone="success" />
            <PeriodStat label="Garelka" value={rs?.total_garelka ?? 0} tone="warning" />
            <PeriodStat label="Tana" value={rs?.total_tana ?? 0} tone="accent" />
          </div>

          {reportQ.isLoading ? (
            <Skeleton />
          ) : (rs?.days.length ?? 0) === 0 ? (
            <EmptyState title="Bu davrda yozuv yoʻq" description="Boshqa oy yoki kunni tanlang" />
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
                  {rs!.days.map((d) => (
                    <tr key={d.production_date} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 whitespace-nowrap font-medium">{formatDate(d.production_date)}</td>
                      <td className="py-2 pr-3 text-right">{d.kotyol || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.bunker || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.garelka || '—'}</td>
                      <td className="py-2 pr-3 text-right">{d.tana || '—'}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 border-black/10 font-semibold">
                    <td className="py-2 pr-3">Jami</td>
                    <td className="py-2 pr-3 text-right">{rs!.total_kotyol || '—'}</td>
                    <td className="py-2 pr-3 text-right">{rs!.total_bunker || '—'}</td>
                    <td className="py-2 pr-3 text-right">{rs!.total_garelka || '—'}</td>
                    <td className="py-2 pr-3 text-right">{rs!.total_tana || '—'}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </Card>
      ) : (
        <Card title={TAB_LABELS[tab]}>
          {periodFilter}

          {/* Davr jamlanmasi — DOIM ko'rinadi, kun almashsa ham o'zgarmaydi */}
          <div className="mb-4 rounded-card border border-primary/20 bg-gradient-to-r from-primary/10 to-primary/[0.02] px-4 py-3.5 flex items-center justify-between gap-4 flex-wrap">
            <div className="flex items-center gap-3">
              <span className="w-11 h-11 shrink-0 rounded-button bg-primary/15 text-primary inline-flex items-center justify-center">
                <CalendarRange size={22} />
              </span>
              <div>
                <div className="text-xs font-semibold uppercase tracking-wide text-ink-soft">
                  {periodLabel} jami
                </div>
                <div className="flex items-baseline gap-1.5">
                  <span className="text-3xl font-extrabold tabular-nums text-primary leading-tight">
                    {periodTotal}
                  </span>
                  <span className="text-sm font-medium text-ink-soft">dona</span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-5 pr-1">
              <div className="text-center">
                <div className="text-xl font-bold tabular-nums leading-tight">{records.length}</div>
                <div className="text-xs text-ink-soft">ta yozuv</div>
              </div>
              <div className="w-px h-8 bg-black/10" />
              <div className="text-center">
                <div className="text-xl font-bold tabular-nums leading-tight">{dayKeys.length}</div>
                <div className="text-xs text-ink-soft">kun</div>
              </div>
            </div>
          </div>

          {/* Kunlar bo'yicha sahifalash / butun oy */}
          {!searching && activeDay && (
            <div className="mb-4 flex items-center justify-between gap-2 flex-wrap">
              {wholeMonth ? (
                <div className="px-1 py-1.5 text-sm font-medium inline-flex items-center gap-1.5">
                  <CalendarRange size={16} className="text-primary" />
                  {periodLabel} — barcha kunlar
                  <span className="ml-1 text-xs text-ink-soft tabular-nums">
                    ({dayKeys.length} kun)
                  </span>
                </div>
              ) : (
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => setDayCursor(dayKeys[dayIdx + 1])}
                    disabled={dayIdx >= dayKeys.length - 1}
                    title="Oldingi kun"
                    className="p-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    <ChevronLeft size={16} />
                  </button>
                  <div className="px-3 py-1.5 text-sm font-medium min-w-[9rem] text-center">
                    {formatDate(activeDay)}
                  </div>
                  <button
                    onClick={() => setDayCursor(dayKeys[dayIdx - 1])}
                    disabled={dayIdx <= 0}
                    title="Keyingi kun"
                    className="p-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    <ChevronRight size={16} />
                  </button>
                  <span className="ml-2 text-xs text-ink-soft tabular-nums">
                    {dayIdx + 1} / {dayKeys.length}
                  </span>
                </div>
              )}
              <div className="flex items-center gap-3 flex-wrap">
                <div className="text-sm">
                  <span className="text-ink-soft">
                    {wholeMonth ? (repMonth === 0 ? 'Butun yilda:' : 'Butun oyda:') : 'Shu kunda:'}
                  </span>{' '}
                  <b className="tabular-nums">{visibleTotal}</b> dona
                </div>
                {/* Ko'rinishni almashtirish: kun / butun oy */}
                <div className="inline-flex rounded-button border border-black/10 overflow-hidden text-xs font-medium">
                  <button
                    onClick={() => setWholeMonth(false)}
                    className={'px-2.5 py-1.5 transition-colors ' + (wholeMonth
                      ? 'text-ink-soft hover:bg-black/5'
                      : 'bg-primary text-white')}>
                    Kun boʻyicha
                  </button>
                  <button
                    onClick={() => setWholeMonth(true)}
                    className={'px-2.5 py-1.5 border-l border-black/10 transition-colors ' + (wholeMonth
                      ? 'bg-primary text-white'
                      : 'text-ink-soft hover:bg-black/5')}>
                    {repMonth === 0 ? 'Butun yil' : 'Butun oy'}
                  </button>
                </div>
              </div>
            </div>
          )}

          {tab === 'kotyol' && (
            <div className="relative mb-4 w-full max-w-xs">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input className="input pl-9 w-full" placeholder="ID raqami boʻyicha qidirish"
                     value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
          )}

          {recordsQ.isLoading ? (
            <Skeleton />
          ) : visibleRecords.length === 0 ? (
            <EmptyState title="Yozuv topilmadi" description="Boshqa oyni tanlang yoki yangi yozuv qoʻshing" />
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
                    <th className="py-2 pr-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {tableGroups.map(([day, rows]) => (
                    <Fragment key={day ?? 'all'}>
                      {day && (
                        <tr className="bg-primary/5">
                          <td colSpan={colCount} className="py-1.5 pr-3 text-xs font-semibold text-ink-soft">
                            {formatDate(day)}
                            <span className="text-ink">
                              {' · '}
                              <b className="tabular-nums">
                                {rows.reduce((sum, r) => sum + (r.quantity ?? 0), 0)}
                              </b>{' '}
                              dona
                            </span>
                          </td>
                        </tr>
                      )}
                      {rows.map((r) => (
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
                    </Fragment>
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

const PERIOD_TONES: Record<string, string> = {
  primary: 'border-primary/20 bg-primary/5 text-primary',
  success: 'border-success/25 bg-success/10 text-success',
  warning: 'border-warning/25 bg-warning/10 text-warning',
  accent: 'border-accent/25 bg-accent/10 text-accent',
};

function PeriodStat({ label, value, tone }: {
  label: string; value: number; tone: 'primary' | 'success' | 'warning' | 'accent';
}) {
  return (
    <div className={`rounded-button border p-2.5 ${PERIOD_TONES[tone]}`}>
      <div className="text-xs font-medium opacity-80">{label}</div>
      <div className="text-xl font-bold tabular-nums">{value}</div>
    </div>
  );
}
