import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Search, Pencil, Building2, HardHat, Briefcase, BadgeCheck, ChevronRight } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatPhone, formatDate, formatUZS } from '@/lib/format';
import EmployeeModal, { EmployeeRow } from '@/features/hr/EmployeeModal';
import PositionsSection from '@/features/hr/PositionsSection';

type Tab = 'office' | 'worker' | 'positions';

const STATUS_LABEL: Record<string, string> = {
  active: 'Faol',
  terminated: 'Ishdan ketgan',
};

export default function HRPage() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('office');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('active');
  const [editEmp, setEditEmp] = useState<EmployeeRow | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const isPositions = tab === 'positions';

  const empQ = useQuery({
    queryKey: ['employees', tab, status, search],
    queryFn: () =>
      api
        .get('/hr/employees', {
          params: {
            employment_type: tab,
            status: status || undefined,
            q: search || undefined,
            page_size: 200,
          },
        })
        .then((r) => r.data),
    enabled: !isPositions,
  });

  const items: EmployeeRow[] = empQ.data?.items ?? [];

  function refresh() {
    qc.invalidateQueries({ queryKey: ['employees'] });
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Xodimlar (HR)</h1>
          <p className="text-sm text-ink-soft">
            Ofis xodimlari, oddiy ishchilar va lavozimlar bazasi
          </p>
        </div>
        {tab === 'worker' && (
          <button onClick={() => setShowCreate(true)} className="btn-primary">
            <Plus size={16} /> Yangi ishchi
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        <TabButton active={tab === 'office'} onClick={() => setTab('office')} icon={<Building2 size={16} />}>
          Ofis xodimlari
        </TabButton>
        <TabButton active={tab === 'worker'} onClick={() => setTab('worker')} icon={<HardHat size={16} />}>
          Oddiy ishchilar
        </TabButton>
        <TabButton active={tab === 'positions'} onClick={() => setTab('positions')} icon={<Briefcase size={16} />}>
          Lavozimlar
        </TabButton>
      </div>

      {isPositions ? (
        <PositionsSection />
      ) : (
        <Card>
          <div className="flex items-center gap-2 mb-4 flex-wrap">
            <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
              <Search size={16} className="text-ink/40" />
              <input
                placeholder="Ism bo'yicha qidirish..."
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
              <option value="active">Faol</option>
              <option value="terminated">Ishdan ketgan</option>
              <option value="">Barchasi</option>
            </select>
          </div>

          {tab === 'office' && (
            <p className="text-xs text-ink-soft mb-3">
              Ofis xodimlari <span className="font-medium">Foydalanuvchilar</span> bo'limidan avtomatik qo'shiladi.
            </p>
          )}

          {empQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : items.length === 0 ? (
            <EmptyState
              title={tab === 'office' ? 'Ofis xodimlari yo\'q' : 'Ishchilar yo\'q'}
              description={
                tab === 'office'
                  ? "Foydalanuvchilar bo'limidan akkount yarating — bu yerda paydo bo'ladi."
                  : "Yuqoridagi \"Yangi ishchi\" tugmasi orqali qo'shing."
              }
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Ism familiya</th>
                    <th className="py-2 pr-3">Tug'ilgan sana</th>
                    <th className="py-2 pr-3">Telefon</th>
                    <th className="py-2 pr-3">Qo'shimcha tel.</th>
                    <th className="py-2 pr-3">Lavozim</th>
                    <th className="py-2 pr-3">Manzil</th>
                    <th className="py-2 pr-3">Status</th>
                    <th className="py-2 pr-3 text-right">Amallar</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((e) => (
                    <tr
                      key={e.id}
                      onClick={() => navigate(`/hr/${e.id}`)}
                      className="border-b border-black/5 hover:bg-primary/5 cursor-pointer"
                    >
                      <td className="py-2 pr-3 font-medium">
                        <div className="flex items-center gap-1.5">
                          {e.full_name}
                          {e.has_account && (
                            <span title="Tizim foydalanuvchisi">
                              <BadgeCheck size={14} className="text-primary" />
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="py-2 pr-3">{e.birth_date ? formatDate(e.birth_date) : '—'}</td>
                      <td className="py-2 pr-3">{formatPhone(e.phone)}</td>
                      <td className="py-2 pr-3">{formatPhone(e.secondary_phone)}</td>
                      <td className="py-2 pr-3">{e.position_name || '—'}</td>
                      <td className="py-2 pr-3 max-w-[180px] truncate" title={e.address || ''}>
                        {e.address || '—'}
                      </td>
                      <td className="py-2 pr-3">
                        {e.status === 'active' ? (
                          <span className="badge bg-success/10 text-success">Faol</span>
                        ) : (
                          <span className="badge bg-gray-100 text-gray-700">
                            {STATUS_LABEL[e.status] ?? e.status}
                          </span>
                        )}
                      </td>
                      <td className="py-2 pr-3">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            title="Tahrirlash"
                            onClick={(ev) => { ev.stopPropagation(); setEditEmp(e); }}
                            className="p-1.5 rounded hover:bg-black/10 text-ink/60"
                          >
                            <Pencil size={16} />
                          </button>
                          <ChevronRight size={16} className="text-ink/30" />
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
