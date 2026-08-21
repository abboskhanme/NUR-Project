import { api } from '@/api/client';

export type PostStatus = 'pending' | 'sent' | 'posted' | 'failed' | 'skipped';

export interface ChannelPost {
  id: string;
  tg_chat_id: string;
  tg_message_id: string;
  kind: 'text' | 'photo' | 'video' | 'document';
  caption?: string | null;
  media_mime?: string | null;
  media_size: number;
  has_media: boolean;
  posted_at: string;
  planned_at: string;
  status: PostStatus;
  attempts: number;
  error?: string | null;
  sent_at?: string | null;
  sent_to?: string | null;
}

export interface BridgeSummary {
  pending: number;
  sent: number;
  posted: number;
  failed: number;
  skipped: number;
  enabled: boolean;
  watching: boolean;
  sending: boolean;
  targets: number;
  delay_minutes: number;
}

export const POST_STATUS_LABELS: Record<PostStatus, string> = {
  pending: 'Navbatda',
  sent: 'Yuborildi',
  posted: 'Kanalga qo‘yildi',
  failed: 'Xato',
  skipped: 'O‘tkazib yuborildi',
};

export const POST_STATUS_STYLE: Record<PostStatus, string> = {
  pending: 'bg-amber-100 text-amber-800',
  sent: 'bg-sky-100 text-sky-800',
  posted: 'bg-emerald-100 text-emerald-800',
  failed: 'bg-rose-100 text-rose-800',
  skipped: 'bg-slate-200 text-slate-700',
};

export const KIND_LABELS: Record<ChannelPost['kind'], string> = {
  text: 'Matn',
  photo: 'Rasm',
  video: 'Video',
  document: 'Fayl',
};

export const waBridgeApi = {
  summary: () => api.get<BridgeSummary>('/wa-bridge/summary').then((r) => r.data),
  posts: (params: { status?: string; limit?: number } = {}) =>
    api.get<ChannelPost[]>('/wa-bridge/posts', { params }).then((r) => r.data),
  retry: (id: string) =>
    api.post<ChannelPost>(`/wa-bridge/posts/${id}/retry`).then((r) => r.data),
  skip: (id: string) =>
    api.post<ChannelPost>(`/wa-bridge/posts/${id}/skip`).then((r) => r.data),
  markPosted: (id: string) =>
    api.post<ChannelPost>(`/wa-bridge/posts/${id}/posted`).then((r) => r.data),
  mediaUrl: (id: string) => `${api.defaults.baseURL}/wa-bridge/posts/${id}/media`,
};
