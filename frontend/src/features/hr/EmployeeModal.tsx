import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Info, CalendarClock } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';
import SalaryOverrideModal from '@/features/hr/SalaryOverrideModal';

const SALARY_TYPES = [
  { value: 'hourly', label: 'Soatbay' },
  { value: 'daily', label: 'Kunbay' },
  { value: 'fixed', label: 'Belgilangan (oylik)' },
  { value: 'kpi', label: 'KPI' },
];

export interface EmployeeMonthSummary {
  year: number;
  month: number;
  present_days: number;
  total_hours: string;
  gross: string;
  advance: string;
  net: string;
  salary_type: string;
  bonus?: string;
  penalty?: string;
  max_gross?: string;
}

export interface EmployeeRow {
  id: string;
  full_name: string;
  phone?: string | null;
  secondary_phone?: string | null;
  birth_date?: string | null;
  hire_date?: string | null;
  address?: string | null;
  position_id?: string | null;
  position_name?: string | null;
  employment_type: string;
  department_type?: string;
  salary_type: string;
  salary_amount: string;
  currency: string;
  status: string;
  has_account: boolean;
  user_id?: string | null;
  month_summary?: EmployeeMonthSummary | null;
}

interface Position {
  id: string;
  name: string;
}

// Boshlang'ich qiymatni soddalashtirish: "0.00" -> "0", "1500.00" -> "1500"
function normalizeAmount(s: string | null | undefined): string {
  if (!s) return '';
  const str = String(s);
  if (!str.includes('.')) return str;
  return str.replace(/\.?0+$/, '');
}

// Faqat raqam va bitta nuqta qoldiradi (input uchun)
function cleanAmount(raw: string): string {
  let cleaned = raw.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  if (firstDot !== -1) {
    cleaned = cleaned.slice(0, firstDot + 1) + cleaned.slice(firstDot + 1).replace(/\./g, '');
  }
  return cleaned;
}

// Ko'rsatish uchun 3 raqamdan bo'sh joy bilan ajratadi: 1500000 -> "1 500 000"
function displayAmount(raw: string): string {
  if (!raw) return '';
  const [intPart, decPart] = raw.split('.');
  let i = (intPart || '').replace(/^0+(?=\d)/, '');
  if (i === '') i = '0';
  const grouped = i.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return decPart != null ? `${grouped}.${decPart}` : grouped;
}

export default function EmployeeModal({
  employee,
  onClose,
  onSaved,
}: {
  employee: EmployeeRow | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = employee === null;
  const isOffice = !!employee?.has_account || employee?.employment_type === 'office';

  const [fullName, setFullName] = useState(employee?.full_name ?? '');
  const [phone, setPhone] = useState(employee?.phone ?? '');
  const [secondaryPhone, setSecondaryPhone] = useState(employee?.secondary_phone ?? '');
  const [birthDate, setBirthDate] = useState(employee?.birth_date ?? '');
  const [hireDate, setHireDate] = useState(employee?.hire_date ?? '');
  const [address, setAddress] = useState(employee?.address ?? '');
  const [positionId, setPositionId] = useState(employee?.position_id ?? '');
  const [departmentType, setDepartmentType] = useState(employee?.department_type ?? 'production');
  const [salaryType, setSalaryType] = useState(employee?.salary_type ?? 'daily');
  const [salaryAmount, setSalaryAmount] = useState(normalizeAmount(employee?.salary_amount));
  const [status, setStatus] = useState(employee?.status ?? 'active');
  const [saving, setSaving] = useState(false);
  const [showOverride, setShowOverride] = useState(false);

  const positionsQ = useQuery<Position[]>({
    queryKey: ['hr', 'positions'],
    queryFn: () => api.get('/hr/positions').then((r) => r.data),
  });
  const positions = positionsQ.data ?? [];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!isOffice && !fullName.trim()) {
      toast.error('Ism-familiya majburiy');
      return;
    }
    setSaving(true);
    try {
      if (isCreate) {
        await api.post('/hr/employees', {
          full_name: fullName,
          phone: phone || null,
          secondary_phone: secondaryPhone || null,
          birth_date: birthDate || null,
          hire_date: hireDate || null,
          address: address || null,
          position_id: positionId || null,
          employment_type: 'worker',
          department_type: departmentType,
          salary_type: salaryType,
          salary_amount: salaryAmount || '0',
          status,
        });
        toast.success("Xodim qo'shildi");
      } else {
        const payload: Record<string, unknown> = {
          secondary_phone: secondaryPhone || null,
          birth_date: birthDate || null,
          hire_date: hireDate || null,
          address: address || null,
          position_id: positionId || null,
          salary_type: salaryType,
          salary_amount: salaryAmount || '0',
          status,
        };
        if (!isOffice) {
          payload.full_name = fullName;
          payload.phone = phone || null;
          payload.department_type = departmentType;
        }
        await api.patch(`/hr/employees/${employee!.id}`, payload);
        toast.success('Yangilandi');
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-2xl max-h-[92vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">
            {isCreate
              ? 'Yangi xodim (Oddiy ishchi)'
              : `Xodimni tahrirlash — ${employee?.full_name}`}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {isOffice && (
            <div className="flex items-start gap-2 text-sm bg-primary/5 text-ink/80 rounded-button px-3 py-2.5">
              <Info size={16} className="text-primary mt-0.5 shrink-0" />
              <span dangerouslySetInnerHTML={{ __html: "Bu — <strong>Ofis xodimi</strong> (tizim foydalanuvchisi). Ism-familiya, telefon va lavozim <strong>Foydalanuvchilar</strong> bo'limidan boshqariladi. Bu yerda qo'shimcha ma'lumot va oylik sozlamalarini kiritishingiz mumkin." }} />
            </div>
          )}

          {!isOffice && (
            <div>
              <label className="label">Bo'lim turi</label>
              <select
                className="input"
                value={departmentType}
                onChange={(e) => setDepartmentType(e.target.value)}
              >
                <option value="office">Ofis xodimlari</option>
                <option value="assembly">Yig'uv bo'limi</option>
                <option value="production">Ishlab chiqarish</option>
              </select>
            </div>
          )}

          <div>
            <label className="label">Ism-familiya *</label>
            <input
              className="input"
              value={fullName}
              disabled={isOffice}
              onChange={(e) => setFullName(e.target.value)}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Telefon</label>
              <PhoneInput value={phone} onChange={setPhone} disabled={isOffice} />
            </div>
            <div>
              <label className="label">Qo'shimcha telefon</label>
              <PhoneInput value={secondaryPhone} onChange={setSecondaryPhone} />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="label">Tug'ilgan sana</label>
              <input
                type="date"
                className="input"
                value={birthDate ?? ''}
                onChange={(e) => setBirthDate(e.target.value)}
              />
            </div>
            <div>
              <label className="label">Ish boshlagan sana</label>
              <input
                type="date"
                className="input"
                value={hireDate ?? ''}
                disabled={isOffice}
                onChange={(e) => setHireDate(e.target.value)}
              />
            </div>
            <div>
              <label className="label">Lavozim</label>
              <select
                className="input"
                value={positionId ?? ''}
                disabled={isOffice}
                onChange={(e) => setPositionId(e.target.value)}
              >
                <option value="">— tanlanmagan —</option>
                {positions.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="label">Manzil</label>
            <textarea
              className="input min-h-[64px]"
              value={address ?? ''}
              onChange={(e) => setAddress(e.target.value)}
            />
          </div>

          <div className="pt-3 border-t border-black/5 grid grid-cols-2 gap-3">
            <div>
              <label className="label">Oylik turi</label>
              <select
                className="input"
                value={salaryType}
                onChange={(e) => setSalaryType(e.target.value)}
              >
                {SALARY_TYPES.map((s) => (
                  <option key={s.value} value={s.value}>{s.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="label">{`Summa (${employee?.currency ?? 'UZS'})`}</label>
              <input
                type="text"
                inputMode="decimal"
                className="input"
                placeholder="0"
                value={displayAmount(salaryAmount)}
                onChange={(e) => setSalaryAmount(cleanAmount(e.target.value))}
              />
            </div>
          </div>

          {!isCreate && employee && (
            <div className="rounded-button bg-black/[0.02] border border-black/5 px-3 py-2.5 flex items-center justify-between gap-3">
              <div className="min-w-0">
                <div className="text-sm font-medium">Muayyan oy uchun boshqa oylik</div>
                <div className="text-xs text-ink-soft">
                  Yuqoridagi summa <strong>joriy oydan</strong> amal qiladi. Faqat bitta o'tgan
                  oyni to'g'rilash uchun bu yerdan foydalaning.
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowOverride(true)}
                className="btn-action shrink-0 whitespace-nowrap border border-primary/30 text-primary hover:bg-primary/5"
              >
                <CalendarClock size={15} /> Oy tanlash
              </button>
            </div>
          )}

          {!isCreate && (
            <div>
              <label className="label">Status</label>
              <select
                className="input"
                value={status}
                onChange={(e) => setStatus(e.target.value)}
              >
                <option value="active">Faol</option>
                <option value="terminated">Ishdan ketgan</option>
              </select>
            </div>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="btn-primary disabled:opacity-50"
          >
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>

    {showOverride && employee && (
      <SalaryOverrideModal
        employeeId={employee.id}
        employeeName={employee.full_name}
        currency={employee.currency}
        onClose={() => setShowOverride(false)}
      />
    )}
    </>
  );
}
