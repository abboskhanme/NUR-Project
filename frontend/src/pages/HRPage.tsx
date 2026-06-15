import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { Plus, Search, Pencil, Users, Briefcase, BadgeCheck, ChevronRight, Coins, Wallet, Scale } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS } from '@/lib/format';
import EmployeeModal, { EmployeeRow } from '@/features/hr/EmployeeModal';
import EmployeeHistoryModal, { HistoryKind } from '@/features/hr/EmployeeHistoryModal';
import PositionsSection from '@/features/hr/PositionsSection';

type Tab = 'employees' | 'positions';

export default function HRPage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('employees');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('active');
  const [editEmp, setEditEmp] = useState<EmployeeRow | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [hist, setHist] = useState<{ emp: EmployeeRow; kind: HistoryKind } | null>(null);

  const isPositions = tab === 'positions';
  const now = new Date();
  const [curYear, setCurYear] = useState(now.getFullYear());
  const [curMonth, setCurMonth] = useState(now.getMonth() + 1);
  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  const empQ = useQuery({
    queryKey: ['employees', 'all', status, search, curYear, curMonth],
    queryFn: () =>
      api
        .get('/hr/employees', {
          params: {
            status: status || undefined,
            q: search || undefined,
            with_summary: true,
            year: curYear,
            month: curMonth,
            page_size: 200,
          },
        })
        .then((r) => r.data),
    enabled: !isPositions,
  });

  const rawItems: EmployeeRow[] = empQ.data?.items ?? [];
  // Turi bo'yicha guruhlaymiz: avval ofis xodimlari (qizil), keyin ishchilar (yashil).
  // Backend allaqachon ism bo'yicha tartiblagani uchun har guruh ichida tartib saqlanadi.
  const items = [...rawItems].sort((a, b) => {
    const rank = (e: EmployeeRow) => (e.employment_type === 'office' ? 0 : 1);
    return rank(a) - rank(b);
  });

  // Joriy oy bo'yicha umumiy ko'rsatkichlar (header kartalari uchun)
  const totals = items.reduce(
    (acc, e) => {
      const s = e.month_summary;
      acc.gross += parseFloat(s?.gross ?? '0') || 0;
      acc.advance += parseFloat(s?.advance ?? '0') || 0;
      acc.net += parseFloat(s?.net ?? '0') || 0;
      return acc;
    },
    { gross: 0, advance: 0, net: 0 },
  );

  function refresh() {
    qc.invalidateQueries({ queryKey: ['employees'] });
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('hr.title')}</h1>
          <p className="text-sm text-ink-soft">{t('hr.subtitle')}</p>
        </div>
        {tab === 'employees' && (
          <button onClick={() => setShowCreate(true)} className="btn-primary">
            <Plus size={16} /> {t('hr.newWorker')}
          </button>
        )}
      </div>

      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        <TabButton active={tab === 'employees'} onClick={() => setTab('employees')} icon={<Users size={16} />}>
          {t('hr.tabs.employees')}
        </TabButton>
        <TabButton active={tab === 'positions'} onClick={() => setTab('positions')} icon={<Briefcase size={16} />}>
          {t('hr.tabs.positions')}
        </TabButton>
      </div>

      {!isPositions && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <KpiCard
            tone="primary"
            label={t('hr.totals.salary')}
            value={formatUZS(totals.gross)}
            icon={<Coins size={18} />}
          />
          <KpiCard
            tone="warning"
            label={t('hr.totals.advance')}
            value={formatUZS(totals.advance)}
            icon={<Wallet size={18} />}
          />
          <KpiCard
            tone="success"
            label={t('hr.totals.remaining')}
            value={formatUZS(totals.net)}
            icon={<Scale size={18} />}
          />
        </div>
      )}

      {isPositions ? (
        <PositionsSection />
      ) : (
        <Card>
          <div className="flex items-center gap-2 mb-4 flex-wrap">
            <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
              <Search size={16} className="text-ink/40" />
              <input
                placeholder={t('hr.searchByName')}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="bg-transparent outline-none flex-1 text-sm"
              />
            </div>
            <select
              className="input !w-auto"
              value={status}
              onChange={(e) => setStatus(e.target.value)}
            >
              <option value="active">{t('hr.status.active')}</option>
              <option value="terminated">{t('hr.status.terminated')}</option>
              <option value="">{t('common.all')}</option>
            </select>
            <select
              className="input !w-auto"
              value={curMonth}
              onChange={(e) => setCurMonth(Number(e.target.value))}
              title={t('hr.monthTooltip', { defaultValue: 'Oy' })}
            >
              {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                <option key={m} value={m}>{t(`hr.months.${m}`)}</option>
              ))}
            </select>
            <select
              className="input !w-auto"
              value={curYear}
              onChange={(e) => setCurYear(Number(e.target.value))}
              title={t('hr.yearTooltip', { defaultValue: 'Yil' })}
            >
              {yearOptions.map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>

          <div className="flex items-center justify-between gap-3 flex-wrap mb-3">
            <p className="text-xs text-ink-soft">
              {t('hr.monthHint', { month: t(`hr.months.${curMonth}`), year: curYear })}
            </p>
            <div className="flex items-center gap-4 text-xs text-ink-soft">
              <span className="flex items-center gap-1.5">
                <span className="inline-block w-2.5 h-2.5 rounded-full bg-red-500" />
                {t('hr.tabs.office')}
              </span>
              <span className="flex items-center gap-1.5">
                <span className="inline-block w-2.5 h-2.5 rounded-full bg-green-600" />
                {t('hr.tabs.worker')}
              </span>
            </div>
          </div>

          {empQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : items.length === 0 ? (
            <EmptyState
              title={t('hr.empty.allTitle')}
              description={t('hr.empty.allDesc')}
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pl-3 pr-3 border-l-4 border-l-transparent">{t('hr.table.fullName')}</th>
                    <th className="py-2 px-3 text-left">{t('hr.table.salary')}</th>
                    <th className="py-2 px-3 text-left">{t('hr.table.advance')}</th>
                    <th className="py-2 px-3 text-left">{t('hr.table.remaining')}</th>
                    <th className="py-2 px-3 text-left">{t('hr.table.hours')}</th>
                    <th className="py-2 pr-3 text-right">{t('hr.table.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((e) => {
                    const s = e.month_summary;
                    const isHourly = (s?.salary_type || e.salary_type) === 'hourly';
                    // Xodim turini keskin rang bilan ajratamiz: ofis — qizil, ishchi — yashil
                    const isOffice = e.employment_type === 'office';
                    const rowTint = isOffice
                      ? 'bg-red-100/70 hover:bg-red-200/70'
                      : 'bg-green-100/70 hover:bg-green-200/70';
                    const accentBorder = isOffice ? 'border-l-red-500' : 'border-l-green-600';
                    return (
                      <tr
                        key={e.id}
                        onClick={() => navigate(`/hr/${e.id}`)}
                        className={`border-b border-black/5 cursor-pointer ${rowTint}`}
                      >
                        <td className={`py-2 pl-3 pr-3 font-medium border-l-4 ${accentBorder}`}>
                          <div className="flex items-center gap-1.5">
                            {e.full_name}
                            {e.has_account && (
                              <span title={t('hr.tooltip.systemUser')}>
                                <BadgeCheck size={14} className="text-primary" />
                              </span>
                            )}
                          </div>
                        </td>

                        <NumCell
                          value={formatUZS(s?.gross ?? 0)}
                          onClick={() => setHist({ emp: e, kind: 'salary' })}
                          title={t('hr.histModal.title.salary')}
                        />
                        <NumCell
                          value={formatUZS(s?.advance ?? 0)}
                          className={(parseFloat(s?.advance ?? '0') > 0) ? 'text-warning' : ''}
                          onClick={() => setHist({ emp: e, kind: 'advance' })}
                          title={t('hr.histModal.title.advance')}
                        />
                        <NumCell
                          value={formatUZS(s?.net ?? 0)}
                          className="font-semibold"
                          onClick={() => setHist({ emp: e, kind: 'remaining' })}
                          title={t('hr.histModal.title.remaining')}
                        />
                        {isHourly ? (
                          <NumCell
                            value={`${(parseFloat(s?.total_hours ?? '0') || 0).toFixed(1)} ${t('hr.histModal.hoursUnit')}`}
                            onClick={() => setHist({ emp: e, kind: 'hours' })}
                            title={t('hr.histModal.title.hours')}
                          />
                        ) : (
                          <td className="py-2 px-3 text-left text-ink/30">—</td>
                        )}

                        <td className="py-2 pr-3">
                          <div className="flex items-center justify-end gap-1">
                            <button
                              title={t('hr.tooltip.edit')}
                              onClick={(ev) => { ev.stopPropagation(); setEditEmp(e); }}
                              className="p-1.5 rounded hover:bg-black/10 text-ink/60"
                            >
                              <Pencil size={16} />
                            </button>
                            <ChevronRight size={16} className="text-ink/30" />
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
      )}

      {(showCreate || editEmp) && (
        <EmployeeModal
          employee={editEmp}
          onClose={() => {
            setShowCreate(false);
            setEditEmp(null);
          }}
          onSaved={refresh}
        />
      )}

      {hist && (
        <EmployeeHistoryModal
          employee={hist.emp}
          kind={hist.kind}
          year={curYear}
          month={curMonth}
          onClose={() => setHist(null)}
        />
      )}
    </div>
  );
}

/** Bosish mumkin bo'lgan raqamli katak — tarix modalini ochadi (qatorga o'tishni to'xtatadi). */
function NumCell({
  value, onClick, title, className = '',
}: {
  value: string;
  onClick: () => void;
  title?: string;
  className?: string;
}) {
  return (
    <td className="py-1.5 px-3 text-left">
      <button
        title={title}
        onClick={(ev) => { ev.stopPropagation(); onClick(); }}
        className={
          'tabular-nums whitespace-nowrap rounded px-2 py-1 -my-1 hover:bg-primary/10 hover:text-primary transition-colors ' +
          className
        }
      >
        {value}
      </button>
    </td>
  );
}

const KPI_TONES = {
  primary: { card: 'border-primary/20 bg-primary/5', text: 'text-primary', icon: 'bg-primary/15 text-primary' },
  warning: { card: 'border-warning/25 bg-warning/10', text: 'text-warning', icon: 'bg-warning/20 text-warning' },
  success: { card: 'border-success/25 bg-success/10', text: 'text-success', icon: 'bg-success/20 text-success' },
} as const;

function KpiCard({ tone, label, value, icon }: {
  tone: keyof typeof KPI_TONES;
  label: string;
  value: string;
  icon: React.ReactNode;
}) {
  const tn = KPI_TONES[tone];
  return (
    <div className={`rounded-card border p-4 flex items-start justify-between ${tn.card}`}>
      <div className="min-w-0">
        <div className={`text-sm font-medium ${tn.text}`}>{label}</div>
        <div className={`text-2xl font-bold mt-2 ${tn.text}`}>{value}</div>
      </div>
      <div className={`w-10 h-10 rounded-button flex items-center justify-center shrink-0 ${tn.icon}`}>
        {icon}
      </div>
    </div>
  );
}

function TabButton({
  active, onClick, icon, children,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={
        'flex items-center gap-2 px-4 py-2 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ' +
        (active
          ? 'border-primary text-primary'
          : 'border-transparent text-ink/60 hover:text-ink')
      }
    >
      {icon}
      {children}
    </button>
  );
}
