import { api } from '@/api/client';

// ---------------------------------------------------------------------------
// Turlar (backend LeadOut/LeadDetailOut bilan mos)
// ---------------------------------------------------------------------------
export interface Lead {
  id: string;
  source: string;
  ig_user_id?: string | null;
  ig_username?: string | null;
  media_id?: string | null;
  comment_id?: string | null;
  name?: string | null;
  contact?: string | null;
  product_interest?: string | null;
  language?: string | null;
  intent?: string | null;
  lead_score: number;
  summary?: string | null;
  status: LeadStatus;
  assigned_to_id?: string | null;
  assigned_to_name?: string | null;
  note?: string | null;
  customer_id?: string | null;
  order_id?: string | null;
  created_at: string;
  updated_at: string;
  event_count: number;
}

export interface LeadEvent {
  id: string;
  kind: string;
  message_text?: string | null;
  agent_reply?: string | null;
  actor: string;
  created_at: string;
}

export interface LeadDetail extends Lead {
  events: LeadEvent[];
}

export interface LeadAnalytics {
  total: number;
  new_today: number;
  hot_leads: number;
  by_status: { status: string; count: number }[];
  conversion_rate: number;
  avg_score: number;
  top_products: { name: string; count: number }[];
  by_language: { name: string; count: number }[];
}

export type LeadStatus = 'new' | 'contacted' | 'qualified' | 'won' | 'lost';

export const LEAD_STATUS_ORDER: LeadStatus[] = [
  'new', 'contacted', 'qualified', 'won', 'lost',
];

export const LEAD_STATUS_LABELS: Record<LeadStatus, string> = {
  new: 'Yangi',
  contacted: "Bog'lanildi",
  qualified: 'Qiziqqan',
  won: 'Mijoz bo\'ldi',
  lost: 'Yo\'qotildi',
};

// Til kodlari → o'qiladigan nom
export const LANG_LABELS: Record<string, string> = {
  'uz-Cyrl': "O'zbek (kirill)",
  'uz-Latn': "O'zbek (lotin)",
  ru: 'Rus',
  en: 'Ingliz',
};

export const INTENT_LABELS: Record<string, string> = {
  greeting: 'Salomlashish',
  product_info: "Mahsulot ma'lumoti",
  price_inquiry: 'Narx so\'rovi',
  buying_intent: 'Sotib olish niyati',
  complaint: 'Shikoyat',
  spam: 'Spam',
  other: 'Boshqa',
};

// ---------------------------------------------------------------------------
// API chaqiruvlari
// ---------------------------------------------------------------------------
export interface LeadListParams {
  search?: string;
  status?: string;
  source?: string;
  assigned_to_id?: string;
}

export const leadsApi = {
  list: (params: LeadListParams) =>
    api.get<Lead[]>('/leads', { params }).then((r) => r.data),
  get: (id: string) => api.get<LeadDetail>(`/leads/${id}`).then((r) => r.data),
  analytics: () => api.get<LeadAnalytics>('/leads/analytics').then((r) => r.data),
  assignees: () =>
    api.get<{ id: string; full_name: string }[]>('/leads/assignees').then((r) => r.data),
  update: (id: string, body: Partial<Pick<Lead, 'status' | 'assigned_to_id' | 'note' | 'lead_score'>>) =>
    api.patch<Lead>(`/leads/${id}`, body).then((r) => r.data),
  remove: (id: string) => api.delete(`/leads/${id}`),
  convert: (id: string, body: { full_name?: string; phone?: string; region?: string; note?: string }) =>
    api.post<Lead>(`/leads/${id}/convert`, body).then((r) => r.data),
};
