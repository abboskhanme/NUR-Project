import { useState } from 'react';
import toast from 'react-hot-toast';
import { Send, Check } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { useAuthStore } from '@/stores/auth';

/**
 * "Telegram" kartasi — xodim o'z Telegram akkauntini profiliga bog'laydi.
 *
 * Nima uchun kerak: servis arizasiga lokatsiya biriktirish. Bot faqat shu
 * yerda ko'rsatilgan chat'dan kelgan lokatsiyani qabul qiladi va kim
 * biriktirganini yozib boradi.
 */
export default function TelegramLinkCard() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);
  const linked = (user?.telegram_chat_id ?? '').trim();

  const [value, setValue] = useState(linked);
  const [saving, setSaving] = useState(false);

  const changed = value.trim() !== linked;

  async function save(next: string) {
    setSaving(true);
    try {
      const { data } = await api.patch('/auth/me', { telegram_chat_id: next });
      setUser(data);
      setValue((data.telegram_chat_id ?? '') as string);
      toast.success(next ? 'Telegram bog\'landi' : 'Telegram uzildi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card title="Telegram">
      <div className="space-y-3">
        <div className="text-sm text-ink-soft">
          Servis arizasiga lokatsiya biriktirish uchun Telegram akkauntingizni
          profilingizga bog'lang:
        </div>
        <ol className="text-sm text-ink-soft list-decimal list-inside space-y-0.5">
          <li>Kompaniya botiga <b>/id</b> deb yozing</li>
          <li>Bot bergan raqamni quyiga qo'ying va saqlang</li>
        </ol>

        {linked && (
          <div className="inline-flex items-center gap-1.5 text-sm text-success">
            <Check size={15} /> Bog'langan — chat ID: <b>{linked}</b>
          </div>
        )}

        <div>
          <label className="label">Telegram chat ID</label>
          <div className="flex flex-wrap gap-2">
            <input
              className="input max-w-[16rem]"
              placeholder="123456789"
              value={value}
              onChange={(e) => setValue(e.target.value.replace(/[^\d-]/g, ''))}
            />
            <button
              className="btn-primary disabled:opacity-40"
              onClick={() => save(value.trim())}
              disabled={!changed || saving}
            >
              <Send size={16} /> {saving ? 'Saqlanmoqda…' : 'Saqlash'}
            </button>
            {linked && (
              <button
                className="btn-ghost disabled:opacity-40"
                onClick={() => { setValue(''); save(''); }}
                disabled={saving}
              >
                Uzish
              </button>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
}
