import axios, { AxiosError, AxiosInstance } from 'axios';
import { useAuthStore } from '@/stores/auth';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1';

export const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Refresh on 401
let refreshing = false;
let queue: Array<() => void> = [];

api.interceptors.response.use(
  (r) => r,
  async (error: AxiosError) => {
    const original: any = error.config;
    if (error.response?.status === 401 && !original?._retry) {
      original._retry = true;
      const auth = useAuthStore.getState();
      if (!auth.refreshToken) {
        auth.logout();
        return Promise.reject(error);
      }
      if (refreshing) {
        await new Promise<void>((resolve) => queue.push(resolve));
      } else {
        refreshing = true;
        try {
          const { data } = await axios.post(
            `${API_BASE_URL}/auth/refresh`,
            { refresh_token: auth.refreshToken },
          );
          auth.setTokens(data.access_token, data.refresh_token);
          queue.forEach((fn) => fn());
          queue = [];
        } catch (e) {
          auth.logout();
          return Promise.reject(e);
        } finally {
          refreshing = false;
        }
      }
      return api(original);
    }
    return Promise.reject(error);
  },
);
