import type { Config } from 'tailwindcss';

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#1E3A5F', 50: '#eaf0f7', 600: '#1E3A5F', 700: '#162a47' },
        accent:  { DEFAULT: '#2980B9', 600: '#2980B9' },
        success: { DEFAULT: '#27AE60' },
        warning: { DEFAULT: '#F39C12' },
        danger:  { DEFAULT: '#E74C3C' },
        bg:      { DEFAULT: '#F8FAFB' },
        card:    { DEFAULT: '#FFFFFF' },
        ink:     { DEFAULT: '#1A1A2E', soft: '#7F8C8D' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        cozy: '0 2px 16px rgba(0,0,0,0.08)',
      },
      borderRadius: {
        card: '16px',
        button: '10px',
      },
    },
  },
  plugins: [],
} satisfies Config;
