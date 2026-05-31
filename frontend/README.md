# NurBunker Frontend (React + Vite)

NUR TECHNO GROUP ERP/CRM tizimining web ilovasi.

## Texnologiyalar

- React 18 + TypeScript + Vite
- Tailwind CSS (iOS-style design)
- TanStack Query (server state)
- Zustand (lokal state)
- React Router v6
- React Hook Form + Zod
- Recharts (grafiklar)
- i18next (uz/ru/en)
- Axios (interceptors + auto refresh)

## O'rnatish

```bash
npm install
cp .env.example .env
```

`.env` da `VITE_API_BASE_URL` ni backend manziliga qo'ying:

```
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

## Ishga tushirish

```bash
npm run dev
```

Manzil: <http://localhost:5173>

## Build

```bash
npm run build
npm run preview
```

`dist/` papkasidagi static fayllar har qanday static hosting (Nginx, Caddy,
Vercel, Netlify va h.k.) orqali serv qilinadi.

## Loyiha tuzilmasi

```
src/
├── app/
│   └── App.tsx              # router
├── api/
│   └── client.ts            # axios + interceptors
├── components/
│   ├── layout/              # AppLayout, Sidebar, TopBar, MobileNav
│   └── ui/                  # Card, StatusBadge, BalanceCard, EmptyState
├── features/                # feature-based modullar
├── pages/                   # router-level sahifalar
├── stores/                  # Zustand (auth, ui)
├── lib/                     # format, cn (className helper)
├── locales/                 # uz/ru/en + i18n config
├── styles/global.css
└── main.tsx
```

## Sahifalar

- `/login` — kirish
- `/` — Bosh sahifa (balanslar, KPI, eslatmalar)
- `/orders` — Buyurtmalar (Sotuv CRM)
- `/customers` — Mijozlar bazasi
- `/products` — Mahsulot katalogi
- `/service` — Servis arizalari
- `/finance` — Moliya (3 daftar, tranzaksiyalar)
- `/hr` — Xodimlar va davomat
- `/supply` — Ta'minot (4 sektor, materiallar, vendorlar)
- `/reports` — Hisobotlar va analitika
- `/settings` — Profil va sozlamalar

## Dizayn

iOS-inspired:
- Soft borders (12-16px)
- Soft shadows (`0 2px 16px rgba(0,0,0,0.08)`)
- Inter font (Google Fonts)
- Primary: `#1E3A5F`

Mobil ko'rinish: pastda 5-tab navigation (Sotuv, Servis, Moliya, HR, Ta'minot).

## Dark mode

Tailwind `dark:` variant. `Settings` sahifasi yoki TopBardan toggle qiling.
