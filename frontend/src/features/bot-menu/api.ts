import { api } from '@/api/client';

export interface BotMenuImage {
  id: string;
  content_type: string;
  size_bytes: number;
  sort_order: number;
}

export interface BotMenuItem {
  id: string;
  command: string;
  title: string;
  text?: string | null;
  sort_order: number;
  is_active: boolean;
  images: BotMenuImage[];
  created_at: string;
  updated_at: string;
}

export interface BotMenu {
  greeting: string;
  items: BotMenuItem[];
}

export interface BotMenuItemInput {
  command: string;
  title: string;
  text?: string | null;
  is_active: boolean;
}

// Backend bilan bir xil chegaralar (app/models/bot_menu.py)
export const MAX_IMAGES_PER_ITEM = 10;
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_TEXT_LENGTH = 4096;
export const CAPTION_LIMIT = 1024;
export const IMAGE_ACCEPT = 'image/jpeg,image/png,image/webp';

/**
 * Tugma nomidan Telegram buyrug'ini taklif qiladi: «💰 Narxlar» -> «narxlar».
 * Telegram faqat lotin kichik harf, raqam va `_` qabul qiladi (1-32 belgi).
 */
export function suggestCommand(title: string): string {
  return title
    .toLowerCase()
    .replace(/[‘’ʻʼ'`]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 32);
}

export const botMenuApi = {
  get: () => api.get<BotMenu>('/bot-menu').then((r) => r.data),
  setGreeting: (greeting: string) =>
    api.put<BotMenu>('/bot-menu/greeting', { greeting }).then((r) => r.data),
  create: (body: BotMenuItemInput) =>
    api.post<BotMenuItem>('/bot-menu/items', body).then((r) => r.data),
  update: (id: string, body: Partial<BotMenuItemInput>) =>
    api.patch<BotMenuItem>(`/bot-menu/items/${id}`, body).then((r) => r.data),
  remove: (id: string) => api.delete(`/bot-menu/items/${id}`),
  reorder: (ids: string[]) =>
    api.post<BotMenu>('/bot-menu/reorder', { ids }).then((r) => r.data),
  uploadImage: (itemId: string, file: File) => {
    const form = new FormData();
    form.append('file', file);
    return api
      .post<BotMenuItem>(`/bot-menu/items/${itemId}/images`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      .then((r) => r.data);
  },
  removeImage: (imageId: string) => api.delete(`/bot-menu/images/${imageId}`),
  imageBlob: (imageId: string) =>
    api.get<Blob>(`/bot-menu/images/${imageId}`, { responseType: 'blob' }).then((r) => r.data),
};
