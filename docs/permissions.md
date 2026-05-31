# Permission tizimi (RBAC)

Ushbu hujjat ruxsatlarni qanday qo'shish, ishlatish va kengaytirish haqida.

## Tushuncha

Ruxsat — `module:verb` formatidagi string. Masalan:

- `users:read` — foydalanuvchilarni ko'rish
- `finance:write` — moliyaviy operatsiya yaratish/o'zgartirish
- `orders:approve` — buyurtmani tasdiqlash

### Wildcard'lar

- `*` yoki `*:*` — barchasi (super-admin uchun)
- `module:*` — modul ichidagi barcha verb'lar (masalan `finance:*`)
- `*:verb` — barcha modullarning shu verb'i (masalan `*:export`)

### Saqlash formati (DB)

`Role.permissions` ustuni JSONB:

```json
{ "permissions": ["users:read", "finance:read", "*:export"] }
```

Super-admin role:

```json
{ "permissions": ["*:*"] }
```

## Hozirgi modul va verb'lar

**Modullar:** `users`, `customers`, `orders`, `products`, `service`, `finance`, `hr`, `supply`, `reports`, `telegram`, `settings`

**Verb'lar:** `read`, `write`, `delete`, `approve`, `export`

Ro'yxat: `backend/app/core/permissions.py` (MODULES, VERBS) va `frontend/src/lib/permissions.ts` (MODULES, VERBS) — har ikkalasini sinxron tutish kerak.

## Yangi modul qo'shish

1. **Backend** (`backend/app/core/permissions.py`):

   ```python
   MODULES = [..., "warehouse"]
   ```

2. **Frontend** (`frontend/src/lib/permissions.ts`):

   ```ts
   export const MODULES = [..., 'warehouse'] as const;
   ```

3. **Endpoint'larda** ishlatish:

   ```python
   from app.core.permissions import require_permission

   @router.get("/items", dependencies=[Depends(require_permission("warehouse:read"))])
   async def list_items(...):
       ...
   ```

4. **Frontend komponentda** ishlatish:

   ```tsx
   import { usePermissions } from '@/lib/permissions';
   import Can from '@/components/Can';

   const { can } = usePermissions();
   {can('warehouse:write') && <button>Yangi mahsulot</button>}

   // yoki wrapper bilan:
   <Can perm="warehouse:write">
     <button>Yangi mahsulot</button>
   </Can>
   ```

Bu yetadi — migration yoki boshqa narsa kerak emas. Super-admin avtomatik kira oladi. Boshqa rollar uchun ruxsat — Permission Matrix UI orqali keyinroq beriladi.

## Yangi verb qo'shish

Xuddi shu tarzda VERBS ro'yxatiga qo'shish kifoya.

## API endpoint'lar

- `GET /api/v1/permissions/catalog` — `{ modules, verbs, wildcard_all }`
- `GET /api/v1/permissions/me` — joriy foydalanuvchining ruxsatlar ro'yxati
- `GET /api/v1/permissions/check?perm=users:read` — bitta ruxsatni tekshirish (debug)
- `PATCH /api/v1/permissions/role/{role_id}` — rolga ruxsatlar ro'yxatini qo'yish

## Kelajakda qilinadigan ishlar

- [ ] **Permission Matrix UI** — har bir rol uchun checkbox matritsasi (modul × verb)
- [ ] **Role presetlar** — `sales_manager`, `finance_manager` va h.k. uchun tavsiya etilgan ruxsatlar to'plami
- [ ] **Audit log** — ruxsat o'zgartirishlarini yozish
- [ ] **Sidebar va router'da automatik yashirish** — foydalanuvchida sahifa uchun ruxsat yo'q bo'lsa menyu va route'ni o'chirish

## Qoidalar

1. **Har bir yangi endpoint** kamida bitta `Depends(require_permission(...))` ga ega bo'lishi kerak (super-admin bypass o'tib ketadi).
2. **Frontend tugmalari** ham `Can` yoki `can()` bilan o'ralsin — UI darajasida ham himoya.
3. `module:verb` nomlanish konvensiyasini buzmaslik. Maxsus verb kerak bo'lsa avval VERBS'ga qo'shing.
4. **Hech qachon** `is_superadmin=True` ni qo'lda tekshirmang — `require_permission` o'zi to'g'ri ishlaydi.
