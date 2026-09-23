import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        },
    },
    server: {
        port: 5173,
        host: true,
        // Windows + Docker'da fayl o'zgarishlarini sezish uchun polling
        watch: {
            usePolling: true,
            interval: 1000,
            binaryInterval: 3000,
            ignored: ['**/node_modules/**', '**/dist/**', '**/.git/**'],
        },
        proxy: {
            '/api': {
                target: 'http://localhost:8000',
                changeOrigin: true,
            },
        },
    },
});
