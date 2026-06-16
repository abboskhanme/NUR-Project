import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Info } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';

export interface EmployeeMonthSummary {
  year: number;
  month: number;
  present_days: number;
  total_hours: string;
  gross: string;
  advance: string;
  net: string;
  salary_type: string;
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
  const { t } = useTranslation();
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

  const SALARY_TYPES = [
    { value: 'hourly', label: t('hr.salaryType.hourly') },
    { value: 'daily', label: t('hr.salaryType.daily') },
    { value: 'fixed', label: t('hr.salaryType.fixedFull') },
    { value: 'kpi', label: t('hr.salaryType.kpi') },
  ];

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
      toast.error(t('hr.modal.errorRequired'));
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
        toast.success(t('hr.modal.created'));
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
        toast.success(t('hr.modal.updated'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('hr.modal.errorGeneric'));
    } finally {
      setSaving(false);
    }
  }

  return (
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
              ? t('hr.modal.createTitle')
              : t('hr.modal.editTitle', { name: employee?.full_name })}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {isOffice && (
            <div className="flex items-start gap-2 text-sm bg-primary/5 text-ink/80 rounded-button px-3 py-2.5">
              <Info size={16} className="text-primary mt-0.5 shrink-0" />
              <span dangerouslySetInnerHTML={{ __html: t('hr.modal.officeInfo') }} />
            </div>
          )}

          {!isOffice && (
            <div>
              <label className="label">{t('hr.modal.departmentTypeLabel')}</label>
              <select
                className="input"
                value={departmentType}
                onChange={(e) => setDepartmentType(e.target.value)}
              >
                <option value="office">{t('hr.tabs.office')}</option>
                <option value="assembly">{t('hr.tabs.assembly')}</option>
                <option value="production">{t('hr.tabs.production')}</option>
              </select>
            </div>
          )}

          <div>
            <label className="label">{t('hr.modal.fullNameLabel')}</label>
            <input
              className="input"
              value={fullName}
              disabled={isOffice}
              onChange={(e) => setFullName(e.target.value)}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">{t('hr.modal.phoneLabel')}</label>
              <PhoneInput value={phone} onChange={setPhone} disabled={isOffice} />
            </div>
            <div>
              <label className="label">{t('hr.modal.secondaryPhoneLabel')}</label>
              <PhoneInput value={secondaryPhone} onChange={setSecondaryPhone} />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="label">{t('hr.modal.birthDateLabel')}</label>
              <input
                type="date"
                className="input"
                value={birthDate ?? ''}
                onChange={(e) => setBirthDate(e.target.value)}
              />
            </div>
            <div>
              <label className="label">{t('hr.modal.hireDateLabel')}</label>
              <input
                type="date"
                className="input"
                value={hireDate ?? ''}
                disabled={isOffice}
                onChange={(e) => setHireDate(e.target.value)}
              />
            </div>
            <div>
              <label className="label">{t('hr.modal.positionLabel')}</label>
              <select
                className="input"
                value={positionId ?? ''}
                disabled={isOffice}
                onChange={(e) => setPositionId(e.target.value)}
              >
                <option value="">{t('hr.modal.positionNone')}</option>
                {positions.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="label">{t('hr.modal.addressLabel')}</label>
            <textarea
              className="input min-h-[64px]"
              value={address ?? ''}
              onChange={(e) => setAddress(e.target.value)}
            />
          </div>

          <div className="pt-3 border-t border-black/5 grid grid-cols-2 gap-3">
            <div>
              <label className="label">{t('hr.modal.salaryTypeLabel')}</label>
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
              <label className="label">{t('hr.modal.salaryAmountLabel', { currency: employee?.currency ?? 'UZS' })}</label>
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

          {!isCreate && (
            <div>
              <label className="label">{t('hr.modal.statusLabel')}</label>
              <select
                className="input"
                value={status}
                onChange={(e) => setStatus(e.target.value)}
              >
                <option value="active">{t('hr.status.active')}</option>
                <option value="terminated">{t('hr.status.terminated')}</option>
              </select>
            </div>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="btn-primary disabled:opacity-50"
          >
            {saving ? t('hr.modal.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
