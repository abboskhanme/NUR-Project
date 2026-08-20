import { api } from '@/api/client';

// Backend `core/system_settings.py` katalogi bilan mos
export interface SysSettingItem {
  key: string;
  label: string;
  type: 'text' | 'password' | 'number' | 'select' | 'textarea';
  secret: boolean;
  options: string[];
  placeholder: string;
  help: string;
  is_set: boolean;
  from_env: boolean;   // qiymat .env dan kelgan (DB'da yo'q)
  value: string;       // sir bo'lmaganlarда haqiqiy qiymat; sirda ""
  masked?: string;     // sirlar uchun maskalangan ko'rinish
}

export interface SysSettingGroup {
  id: string;
  title: string;
  items: SysSettingItem[];
}

export interface SysSettingsResponse {
  groups: SysSettingGroup[];
  /** Instagram ulanganmi — token/ID UI'da yashirin, shuning uchun alohida bayroq */
  instagram_connected: boolean;
}

export const systemSettingsApi = {
  get: () => api.get<SysSettingsResponse>('/system-settings').then((r) => r.data),
  update: (values: Record<string, string>) =>
    api.put<SysSettingsResponse>('/system-settings', { values }).then((r) => r.data),
  /** Eski Instagram suhbatlarini Leadlarga ko'chirish (fon rejimida) */
  importConversations: () =>
    api.post<{ started: boolean }>('/system-settings/agent/import-conversations')
      .then((r) => r.data),
};
