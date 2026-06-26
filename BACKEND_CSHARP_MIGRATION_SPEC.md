# NUR-Project — Backend to'liq spetsifikatsiyasi (C#/.NET migratsiya uchun)

> **Maqsad:** Mavjud Python/FastAPI backend'ni C#/.NET (clean architecture) ga sodiq ko'chirish uchun yagona, to'liq texnik hujjat. Bu fayl orqali AI yoki dasturchi originalni ko'rmasdan ham backend'ni qayta qura oladi.
>
> **Tarkib:** har bir modul uchun — ma'lumotlar modeli (har bir ustun: tip, nullable, default, FK, index, unique), DTO sxemalari, API endpointlar (metod, yo'l, ruxsat, so'rov/javob, biznes-qoidalar), va enum/konstantalar.

## Mundarija
0. [Arxitektura va tech-stack → .NET moslik](#0-arxitektura-va-tech-stack--net-moslik)
1. [Core infratuzilma va autentifikatsiya](#1-core-infratuzilma-va-autentifikatsiya)
2. [Foydalanuvchilar / RBAC va HR](#2-foydalanuvchilar--rbac-va-hr)
3. [Mahsulotlar / Ombor / Ishlab chiqarish](#3-mahsulotlar--ombor--ishlab-chiqarish)
4. [Mijozlar / Buyurtmalar / Navbat / Yuk chiqarish](#4-mijozlar--buyurtmalar--navbat--yuk-chiqarish)
5. [Moliya va Qarzlar](#5-moliya-va-qarzlar)
6. [Servis/Kafolat va Ta'minot](#6-servis-kafolat-va-taminot)
7. [Tizim / Hisobotlar / Qidiruv / Bildirishnoma / Telegram / PDF / Excel](#7-tizim--hisobotlar--qidiruv--bildirishnoma--telegram--pdf--excel)
8. [Appendix: jadvallar, enumlar, ruxsatlar matritsasi](#8-appendix)

---

# 0. Arxitektura va tech-stack → .NET moslik

## Hozirgi tech-stack
- **Framework:** FastAPI (Python, async/await)
- **DB:** PostgreSQL (asyncpg drayveri)
- **ORM:** SQLAlchemy 2.0 (async)
- **Migratsiya:** Alembic (32 ta migratsiya; startup'da avtomatik `upgrade head`)
- **Auth:** JWT (python-jose), bcrypt (passlib) parol hash
- **Validatsiya/DTO:** Pydantic v2
- **Rate limit:** slowapi (IP bo'yicha)
- **Fayllar:** PDF — reportlab, Excel — openpyxl, rasm — PostgreSQL BYTEA
- **Telegram bot:** aiogram 3 + APScheduler (alohida konteyner/process)
- **Server:** uvicorn

## Tavsiya etilgan .NET ekvivalentlari (Clean Architecture)
| Python qatlami | .NET ekvivalenti |
|---|---|
| FastAPI router'lar | ASP.NET Core Controllers (yoki Minimal API) |
| Pydantic DTO | C# `record`/DTO sinflari + FluentValidation |
| SQLAlchemy ORM models | EF Core entity'lari (`DbContext`) |
| Alembic | EF Core Migrations |
| `get_db` dependency | Scoped `DbContext` (DI) |
| `module_guard`/`require_permission` | Authorization policy/handler (`IAuthorizationRequirement`) |
| JWT (python-jose) | `Microsoft.AspNetCore.Authentication.JwtBearer` |
| bcrypt (passlib) | `BCrypt.Net-Next` |
| reportlab PDF | QuestPDF yoki iText |
| openpyxl | ClosedXML yoki EPPlus |
| slowapi | `AspNetCoreRateLimit` |
| async/await | C# async/await (bir xil model) |
| Decimal | `decimal` (EF `[Precision(p,s)]`) |
| `uuid.UUID` | `Guid` (PostgreSQL `uuid`) |
| `dict[str,Any]` JSONB | `JsonDocument`/`jsonb` (Npgsql) |
| `DateTime(timezone=True)` | `DateTimeOffset` / `timestamptz` |
| BYTEA | `byte[]` / `bytea` |

**Tavsiya qatlamlar:** `Domain` (entity + enum), `Application` (use-case/service + DTO + validation + permission), `Infrastructure` (EF Core, JWT, PDF/Excel, CBU, Telegram), `Api` (controllers). PostgreSQL'ni saqlang (Npgsql).

## Umumiy konvensiyalar (barcha modullarga taalluqli)
- **PK:** har bir jadval `id uuid` (default `uuid4()` → `Guid.NewGuid()`), `UUIDPrimaryKeyMixin`.
- **Timestamp:** deyarli har bir jadvalda `created_at`, `updated_at` (`timestamptz`, server default `now()`, `updated_at` onupdate). `TimestampMixin`.
- **Jadval nomi:** CamelCase klass → snake_case + "s" (masalan `User`→`users`, `OrderItem`→`order_items`).
- **Pagination javob shakli:** `{ "items": [...], "total": int, "page": int, "page_size": int }` (`Page<T>`).
- **Xato javob shakli:** `{ "detail": "<xabar>" }` (HTTPException). Global 500: `{"detail":"Ichki server xatoligi","type":"<ExceptionName>"}`. Rate limit 429: `{"detail":"Juda ko'p so'rov..."}`.
- **Soft delete:** ko'p joyda — User (`is_active=false`), Finance tx / SalaryAdvance (`status="void"`), Product (`status="archived"`).
- **Pul:** asosan UZS; USD bilan ikki valyuta. `Decimal` aniqligi: narx `(10,2)`, jami/balans `(14,2)` yoki `(16,2)`, kurs `(12,2)`, miqdor `(14,3)`.
- **Telefon:** login identifikatori (email emas). Normalizatsiya: barcha raqam bo'lmagan belgilarni olib tashlash → `phone_digits`; `normalize_phone` = `"+" + digits`. Moslik tekshiruvi raqamlar bo'yicha (`regexp_replace(phone,'\\D','','g')`).

---

# 1. Core infratuzilma va autentifikatsiya

## Tech-stack & runtime
FastAPI + PostgreSQL(asyncpg) + SQLAlchemy 2.0 async + JWT(python-jose) + bcrypt(passlib) + slowapi + uvicorn.

## App bootstrap (main.py)
**Lifespan:** startup'da app nomi/muhitini log qiladi, `settings.validate_security()` ishlaydi (production'da kritik muammo bo'lsa `RuntimeError`). **Auto-migrate:** startup'da Alembic `upgrade head` (prod compose). Shutdown — log.

**Middleware tartibi:**
1. **Rate limit (slowapi):** `app.state.limiter`; 429 handler. Faqat `DEBUG=False` da yoqiladi. Default `240/min`; login `5/min`.
2. **CORS:** origin'lar `settings.ALLOWED_ORIGINS` (vergulli); `allow_credentials=True`; metodlar `GET,POST,PATCH,PUT,DELETE,OPTIONS`; header'lar `Authorization,Content-Type,Accept,Origin,X-Requested-With`.
3. **Global exception handler** (`DEBUG=False`): har qanday `Exception` → 500 `{"detail":"Ichki server xatoligi","type":"<ClassName>"}`.

**Health:** `GET /` → `{app,version:"0.1.0",env,docs:"/api/docs"}`; `GET /health` → `{"status":"ok"}`.
**Docs:** `/api/docs` (Swagger), `/api/redoc`, `/api/openapi.json`. API prefiks: `/api/v1`.

## Konfiguratsiya (config.py) — har bir sozlama
| Sozlama | Tip | Default | Maqsad |
|---|---|---|---|
| APP_NAME | str | "NUR Project" | Nom |
| APP_ENV | str | "development" | Muhit (production/prod = prod) |
| DEBUG | bool | False | Debug + SQL echo |
| API_V1_PREFIX | str | "/api/v1" | Route prefiks |
| HOST / PORT | str/int | 0.0.0.0 / 8000 | Bind |
| DATABASE_URL | str | postgresql+asyncpg://postgres:postgres@localhost:5432/nur_erp | DB |
| SECRET_KEY | str | "change-me" | JWT kalit (prod'da 32+ belgi shart) |
| ALGORITHM | str | "HS256" | JWT algoritmi |
| ACCESS_TOKEN_EXPIRE_MINUTES | int | 15 | Access token muddati |
| REFRESH_TOKEN_EXPIRE_DAYS | int | 30 | Refresh token muddati |
| ALLOWED_ORIGINS_STR | str | localhost:5173,127.0.0.1:5173 | CORS |
| REDIS_URL | str | redis://localhost:6379/0 | (ixtiyoriy) |
| TELEGRAM_BOT_TOKEN | str | "" | Bot tokeni |
| TELEGRAM_WEBHOOK_URL | str | "" | Webhook |
| TELEGRAM_ADMIN_CHAT_IDS | str | "" | Admin chat ID'lar (vergulli, manfiy = guruh) |
| TELEGRAM_REPORT_TIME | str | "20:00" | Kunlik digest vaqti |
| TELEGRAM_NOTIFY_NEW_ORDER | bool | True | Yangi buyurtma haqida xabar |
| TIMEZONE | str | "Asia/Tashkent" | Vaqt mintaqasi |
| CBU_API_URL | str | https://cbu.uz/uz/arkhiv-kursov-valyut/json/ | Valyuta kursi |
| INIT_ADMIN_PHONE/PASSWORD/NAME | str | +998901234567 / Admin@12345 / Super Admin | Seed admin |
| UPLOAD_DIR / MAX_UPLOAD_SIZE_MB | str/int | ./uploads / 20 | Yuklash |
| COMPANY_NAME/PHONE/ADDRESS/INN_LABEL/WEBSITE | str | "NUR TECHNO GROUP"/… | Hujjatlar uchun |

**`is_production`** = `APP_ENV.lower() in {"production","prod"}`. **`validate_security()`** prod'da: SECRET_KEY zaif (≥32 emas) / DEBUG=True / CORS `*` / default admin parol → kritik xato.

## Security (security.py)
**JWT access token claims:** `sub`(user id str), `exp`(now+ACCESS_MIN), `type:"access"`, `ver`(token_version), `extra`. **Refresh:** `sub,exp(now+REFRESH_DAYS),type:"refresh",ver`. Alg HS256, secret `SECRET_KEY`. `decode_token` xato bo'lsa `ValueError`.
**Parol:** bcrypt (passlib CryptContext). `hash_password`, `verify_password`.
**Telefon:** `phone_digits(raw)` = `\D`→"" ; `normalize_phone(raw)` = `"+"+digits` (masalan "+998 90 123 45 67" → "+998901234567").

## Auth dependency'lar (dependencies.py)
`OAuth2PasswordBearer(tokenUrl="{prefix}/auth/login")`. **`get_current_user`:** token decode → `sub` bor; `type=="access"` (refresh rad); `ver` olinadi → User by id → `is_active` tekshir → **`token_ver != user.token_version` bo'lsa 401** (instant logout). `CurrentUser = Annotated[User, Depends(get_current_user)]`. `require_roles(*allowed)` — rol nomlari kesishmasi.

## RBAC ruxsat tizimi (permissions.py)
**MODULES (15):** users, customers, orders, products, inventory, production, service, finance, hr, supply, reports, telegram, debts, shipping, settings.
**VERBS (5):** read, write, delete, approve, export.
**Saqlash:** `Role.permissions` JSONB = `{"permissions": ["users:read","finance:*","*:export"]}`.
**Wildcard:** `*`/`*:*` = hammasi; `module:*` = modul ichidagi barcha verb; `*:verb` = barcha modulda shu verb; `module:verb` = aniq.

**SPECIAL_PERMISSIONS** (oddiy `*` BERMAYDI — faqat haqiqiy super-admin yoki aniq berilgan / `system:*`):
| key | label | danger |
|---|---|---|
| system:roles | Rollar va ruxsatlarni boshqarish | no |
| system:grant_superadmin | Boshqaga super-admin huquqini berish | yes |
| system:user_delete | Foydalanuvchini butunlay o'chirish | yes |
| system:user_password | Parolni almashtirish | no |
| system:user_avatar | Rasmni boshqarish | no |
| system:finance_override | Oylikdan ortiq avans | yes |
| system:order_override | Buyurtma ID/sotuvchini tahrirlash | no |

**Algoritmlar (pseudokod):**
```
has_permission(user, perm):
  if user.is_superadmin or any(role.name=="super_admin"): return True
  perms = union of role.permissions["permissions"]
  if perm in perms: return True
  if "*" in perms or "*:*" in perms: return True
  module,verb = perm.split(":")
  if f"{module}:*" in perms or f"*:{verb}" in perms: return True
  return False

has_special(user, perm):
  if is_superadmin(user): return True
  perms = collect()
  return perm in perms or "system:*" in perms   # "*" YETMAYDI

ensure_can_grant_special(actor, new, old):
  if is_superadmin(actor): return
  added = specials(new) - specials(old)   # specials = SPECIAL keys + "system:*"
  if added: raise 403   # privilege escalation himoyasi
```
**`module_guard(module)`:** HTTP metod → verb (GET/HEAD/OPTIONS=read, POST/PATCH/PUT=write, DELETE=delete). read uchun modulda istalgan verb yetadi. `read_exempt`/`exempt` path bo'laklari. **`require_permission(*perms)`** = any; **`require_all_permissions`** = all; **`require_special(perm)`**.

## DB base & session
`Base` (DeclarativeBase, `dict[str,Any]→JSONB`). `UUIDPrimaryKeyMixin(id uuid default uuid4)`. `TimestampMixin(created_at, updated_at timestamptz server_default now(), updated_at onupdate)`.
Engine: `create_async_engine(DATABASE_URL, echo=DEBUG, pool_pre_ping=True, pool_size=10, max_overflow=20)`. Session: `async_sessionmaker(expire_on_commit=False, autoflush=False)`. `get_db()` — request scoped, finally close.

## Common sxemalar
`ORMBase(from_attributes=True)`; `Page[T]{items,total,page=1,page_size=20}`; `Message{detail}`.

## Auth endpointlar (auth.py) — `/api/v1/auth`
| Metod | Yo'l | So'rov | Javob | Izoh |
|---|---|---|---|---|
| POST | /login (rate 5/min) | `{phone(4-20), password(≥6)}` | `LoginResponse{access_token,refresh_token,token_type,user}` | Telefon raqamlar bo'yicha match; bcrypt; `is_active`; 401 "Telefon yoki parol noto'g'ri"; 403 "Akkount o'chirilgan" |
| POST | /refresh | `{refresh_token}` | `TokenResponse` | type=="refresh"; ver mosligi; 401 revoked/expired |
| POST | /logout | — | `{detail}` | `token_version += 1` (barcha sessiya bekor) |
| GET | /me | — | `UserOut` | Joriy foydalanuvchi |
| PATCH | /me | `UserUpdate` | `UserOut` | Telefon unikal; o'zgaruvchan maydonlar |
| PATCH | /me/password | `{old_password,new_password(≥8)}` | `{detail,access_token,refresh_token}` | Eski parol; token_version++; yangi token |
| POST | /me/avatar | multipart file | `UserOut` | png/jpeg/webp/gif, ≤2MB → BYTEA |
| DELETE | /me/avatar | — | 204 | avatar_url=NULL |

## Router registri (`__init__.py`) prefiks → tag
auth→Auth, users→Users, customers→Customers, products→Products, inventory→Warehouse/Ombor, orders→Sales/Orders, service→Service, finance→Finance, hr→HR, supply→Supply, telegram→Telegram Bot, notifications→Notifications, reports→Reports, permissions→Permissions, search→Search, debts→Debts, shipping→Shipping, production→Production.

---

# 2. Foydalanuvchilar / RBAC va HR

## Modellar

### users
| Ustun | Tip | SQL | Null | Default | FK | Idx | Uniq |
|---|---|---|---|---|---|---|---|
| id | uuid | UUID | no | uuid4 | | PK | yes |
| phone | str | VARCHAR(20) | no | | | yes | yes |
| password_hash | str | VARCHAR(255) | no | | | | |
| full_name | str | VARCHAR(255) | no | | | | |
| avatar_url | str? | VARCHAR(500) | yes | NULL | | | |
| position | str? | VARCHAR(100) | yes | NULL | | | |
| locale | str | VARCHAR(5) | no | "uz" | | | |
| theme | str | VARCHAR(10) | no | "light" | | | |
| is_active | bool | BOOLEAN | no | True | | | |
| is_superadmin | bool | BOOLEAN | no | False | | | |
| token_version | int | INTEGER | no | 0 | | | |
| telegram_chat_id | str? | VARCHAR(50) | yes | NULL | | | |
| notification_settings | dict | JSONB | no | {} | | | |
+ created_at, updated_at. **Relationships:** roles (M2M via user_roles, selectin), avatar (1:1 cascade).

### roles
id, name VARCHAR(50) **unique**, description VARCHAR(255)?, permissions JSONB `{}`. M2M users.
### user_roles (M2M)
user_id→users.id CASCADE, role_id→roles.id CASCADE, composite PK.
### user_avatars
user_id→users.id CASCADE **PK**, content_type VARCHAR(64), size_bytes int, data BYTEA.

### departments
id, name VARCHAR(100) unique.
### positions
id, name VARCHAR(100) unique, department_id→departments.id SET NULL?.
### employees
| Ustun | Tip | Null | Default | FK |
|---|---|---|---|---|
| full_name | VARCHAR(255) | no | | (indexed) |
| phone | VARCHAR(30) | yes | NULL | |
| secondary_phone | VARCHAR(30) | yes | NULL | |
| birth_date | DATE | yes | | |
| address | TEXT | yes | | |
| position_id | UUID | yes | | positions.id SET NULL |
| hire_date | DATE | yes | | |
| employment_type | VARCHAR(20) | no | "worker" | office/worker |
| department_type | VARCHAR(20) | no | "production" | office/assembly/production |
| salary_type | VARCHAR(20) | no | "hourly" | hourly/daily/fixed/kpi |
| salary_amount | NUMERIC(14,2) | no | 0 | |
| currency | VARCHAR(3) | no | "UZS" | |
| status | VARCHAR(20) | no | "active" | active/terminated/leave |
| has_account | BOOLEAN | no | False | |
| user_id | UUID | yes | NULL | users.id SET NULL |

### salary_rates (stavka tarixi)
employee_id→employees.id CASCADE, effective_from DATE (idx), salary_type, amount NUMERIC(14,2), currency, note?, created_by_id→users.id SET NULL. **Immutable tarix** — payroll work_date'dagi amaldagi stavka bo'yicha hisoblaydi.
### attendance (davomat)
employee_id→employees.id CASCADE, work_date DATE, **UNIQUE(employee_id, work_date)**, check_in/check_out TIME?, hours_worked NUMERIC(5,2), daily_pay NUMERIC(14,2), note?, entered_by_id→users.id SET NULL. `hours_worked=(check_out-check_in)/3600`; `daily_pay=hourly_rate(work_date)×hours` (faqat hourly). STANDARD_WORKDAY_HOURS=9.5 (08:30–18:00).
### salary_advances (avans)
employee_id→employees.id CASCADE, advance_date DATE, amount NUMERIC(14,2), currency, note?, status VARCHAR(10) "active"/"void", tx_id UUID? (FinanceTransaction'ga bog'lanish), created_by_id. `net = gross - advances`.
### employee_loans (bizdan qarzdor — Finance bilan AVTO bog'lanmaydi)
employee_id CASCADE, amount NUMERIC(14,2), currency "UZS", source VARCHAR(20) "firma" (director/firma/other), loan_date DATE, note?, status "active"/"closed", created_by_id. `balance = amount - sum(payments)`.
### employee_loan_payments
loan_id→employee_loans.id CASCADE, amount NUMERIC(14,2), pay_date DATE, note?, created_by_id.
### payroll_runs
period_start, period_end DATE, status "draft"/"approved"/"paid", created_by_id, approved_by_id.
### payroll_items
run_id→payroll_runs.id CASCADE, employee_id→employees.id RESTRICT, hours NUMERIC(7,2), gross/advance/net NUMERIC(14,2).

## Asosiy DTO'lar
**Auth (1-bo'limda ko'rsatilgan + ):** `UserCreate{phone(4-20),password(≥8),full_name,position?,role_names[]}`, `UserUpdate{...barchasi optional, role_names?}`, `UserOut{id,phone,full_name,avatar_url?,position?,locale,theme,is_active,is_superadmin,roles[]}`, `RoleCreate{name(2-50),description?,permissions{}}`, `AdminPasswordReset{new_password(≥8)}`, `LinkableEmployeeOut{id,full_name,phone?,position?}`, `UserFromEmployee{phone,password(≥8),full_name?,position?,role_names[]}`.
**HR:** `EmployeeBase/Create{full_name,phone?,…,employment_type="worker",department_type="production",salary_type="hourly",salary_amount=0,currency="UZS",status="active",has_account=False}`, `EmployeeUpdate{...optional}`, `EmployeeOut{...,position_name(computed),user_id?,month_summary?}`, `EmployeeMonthSummary{year,month,present_days,total_hours,gross,advance,net,salary_type,max_gross}`, `AttendanceIn{employee_id,work_date,check_in?,check_out?,note?}`, `AttendanceBatchIn{entries[]}`, `SalaryAdvanceIn{employee_id,advance_date,amount,currency,note?}`, `EmployeeLoanIn{employee_id,amount,currency,source,loan_date?,note?}`, `EmployeeLoanOut{...,paid,balance,payments[]}`, `SalaryRateCreate{effective_from,salary_type,amount,currency,note?}`, `PayrollRunIn{period_start,period_end}`, `MonthlySummary`, `MonthDebts{year,month,total,items[EmployeeDebt{employee_id,full_name,department_type,gross,paid,debt}]}`.

## Endpointlar — Users (`/api/v1/users`)
| Metod | Yo'l | Ruxsat | Izoh / side-effect |
|---|---|---|---|
| GET | / | users:read | Page[UserOut]; q (phone/full_name LIKE), is_active filtr |
| POST | / | users:write | UserCreate→UserOut(201). **Avto Employee(office) yaratadi; supplier rol→Vendor; super_admin rol→`system:grant_superadmin` kerak** |
| PATCH | /{id} | users:write | Employee+Vendor sync; super_admin grant himoyasi |
| DELETE | /{id} | users:delete | Soft: is_active=False; Employee→terminated, Vendor→inactive; o'zini emas |
| POST | /{id}/restore | users:write | is_active=True; Employee→active |
| DELETE | /{id}/permanent | system:user_delete | Hard delete (Employee ham); faqat arxivdagi |
| POST | /{id}/password | system:user_password | token_version++ |
| GET/POST/DELETE | /{id}/avatar | (get public)/system:user_avatar | BYTEA |
| GET | /linkable-employees | users:read | Akkauntsiz (user_id IS NULL, status≠terminated) xodimlar |
| POST | /from-employee/{employee_id} | users:write | **User yaratib MAVJUD xodimga bog'laydi (dublikat yo'q); office; has_account=true** |
| GET | /roles/all | auth | list[RoleOut] |
| POST | /roles | system:roles | ensure_can_grant_special |
| PATCH | /roles/{id} | system:roles | |
| DELETE | /roles/{id} | system:roles | super_admin rolini emas |
| PATCH | /roles/{id}/permissions | system:roles | ensure_can_grant_special |

## Endpointlar — HR (`/api/v1/hr`, `module_guard("hr")`)
- **Departments/Positions:** GET/POST/PATCH/DELETE (write=hr:write, delete=hr:delete; nom unikal).
- **Employees:** GET / (page,page_size≤200,status="active",employment_type?,department_type?,q?,with_summary,year,month) → Page[EmployeeOut]; POST (hire_date default today + boshlang'ich SalaryRate); GET/PATCH /{id} (salary o'zgarsa yangi SalaryRate effective_from=today); GET /{id}/summary?year&month → MonthlySummary; GET /{id}/history?months(≤36) → list.
- **Salary rates:** GET/POST /employees/{id}/salary-rates (POST Employee.salary_* ni joriy stavkaga yangilaydi).
- **Attendance:** GET /attendance (employee_id?,date_from?,date_to?, ≤1000); POST /attendance/batch — **upsert (employee_id,work_date)**: hours=(out-in)/3600, daily_pay=rate(work_date)×hours (hourly).
- **Advances:** GET /advances; POST (status=active, tx_id=NULL); DELETE /advances/{id} — soft void + linked FinanceTransaction reverse/delete.
- **Employee loans:** GET /employee-loans (active, balance>0, employee bo'yicha guruh); POST; PATCH/{id}; DELETE/{id} (cascade payments); POST /{id}/payments (balansdan oshmaydi; to'liq to'lansa status=closed); DELETE /{id}/payments/{pid} (closed bo'lsa qayta active).
- **Payroll:** POST /payroll/runs (PayrollRunIn) — har faol xodim uchun: hours=sum(attendance.hours_worked); gross=sum(daily_pay) yoki fixed bo'lsa salary_amount; advance=sum(active advances); net=gross-advance. GET /salary-debts?year → list[MonthDebts].

## Hisoblash algoritmlari (muhim)
```
daily_pay(attendance): rate = SalaryRate effective on work_date (effective_from<=date, DESC)
                       hourly ? rate.amount*hours_worked : 0
gross(month): sum(attendance.daily_pay)  OR  salary_amount if salary_type=="fixed"
advance(month): sum(salary_advances.amount where status="active" and advance_date in month)
net = gross - advance
max_gross(current month): gross_actual + remaining_workdays*(rate.amount*9.5)   # Yakshanba 6 chiqariladi
```

## Avto-sync mantiqi
**User→Employee:** create/update'da — user_id bo'yicha topadi; topilmasa telefon raqami bo'yicha bog'lanmagan xodimni topadi; bo'lmasa yangi yaratadi. office/office, has_account=true, full_name/phone/position sync, status active/terminated. Arxiv→terminated; restore→active; permanent→Employee hard delete.
**User→Vendor:** supplier rol bor → Vendor yaratadi/yangilaydi; rol olib tashlansa Vendor is_active=False (o'chmaydi).

---

# 3. Mahsulotlar / Ombor / Ishlab chiqarish

## Modellar

### products
| Ustun | Tip | Null | Default | Idx | Uniq | Izoh |
|---|---|---|---|---|---|---|
| product_type | VARCHAR(20) | no | "main" | yes | | main / additional / warehouse |
| model | VARCHAR(50) | yes | | yes | | "PREMIUM 3" va h.k. (main/warehouse uchun) |
| kvm | INTEGER | yes | | | | 150/200/300/400/500 |
| name | VARCHAR(120) | yes | | | | additional uchun (turba, defizor…) |
| unit | VARCHAR(20) | yes | | | | dona/metr/komplekt |
| sku | VARCHAR(50) | yes | | | yes | |
| bunker_direction | VARCHAR(10) | yes | | | | legacy: right/left |
| description | TEXT | yes | | | | |
| base_price_usd | NUMERIC(10,2) | no | 0 | | | |
| specs | JSONB | no | {} | | | |
| status | VARCHAR(20) | no | "active" | | | active/archived |

**display_name (computed):** additional→`name`; else→`"{model} {kvm} kvm"`. **Relationships:** inventory_items (1:N cascade), image (1:1 cascade).
**product_type semantikasi:** main = sotiladigan kotyol (model kerak); additional = aksessuar (name kerak); warehouse = ombor master (model+kvm), sotilmaydi.

### inventory (SKLAD KATYOL — har bir birlik)
product_id→products.id CASCADE (idx), unique_id VARCHAR(50) **unique** (idx), status VARCHAR(20) "available"/"reserved"/"sold" (idx), added_date DATE, bunker_direction VARCHAR(10)?, notes TEXT?. **Status Order linkage'dan hosil:** available = aktiv order yo'q; reserved = aktiv order (`unit_uid==unique_id` va status∉{delivered,rejected}); delivered bo'lsa birlik **o'chiriladi**.
### product_images
product_id→products.id CASCADE **PK**, content_type VARCHAR(64), size_bytes int, data BYTEA. (≤5MB API'da).
### production_records (Ishlab chiqarish)
category VARCHAR(20) "kotyol"/"bunker"/"garelka" (idx), production_date DATE (idx), quantity int default 1, product_id→products.id SET NULL? (kotyol, warehouse model), bunker_direction VARCHAR(10)? (kotyol), unit_code VARCHAR(50)? **unique** (kotyol ID), notes?, created_by_id→users.id SET NULL. kotyol: product_id+unit_code majburiy, quantity=1; bunker/garelka: faqat quantity.

## DTO'lar
`ProductBase/Create{product_type="main",model?,kvm?,name?,unit?,sku?,description?,base_price_usd=0,status="active"}`, `ProductUpdate{...optional}`, `ProductOut{...,bunker_direction?,has_image,created_at,display_name(computed)}`. `InventoryCreate`, `ModelSummary{product_id,model,kvm,base_price_usd,available,reserved,sold,total}`, `WarehouseSummary{rows[],total_available,total_reserved,total_sold,total_value_usd}`, `UnitOut{...,model,kvm,order_code,customer_name}`, `UnitsCreate{product_id,unique_ids[≥1],added_date?,notes?,bunker_direction?}`, `UnitUpdate`. `RecordCreate{category,production_date?,quantity≥1,product_id?,bunker_direction?,unit_code?,notes?}`, `RecordOut{...,model,kvm}`, `DaySummary{production_date,kotyol,bunker,garelka}`, `ProductionSummary{days[],total_kotyol,total_bunker,total_garelka}`.

## Endpointlar
**Products (`/api/v1/products`, module_guard("products")):**
| Metod | Yo'l | Izoh |
|---|---|---|
| GET | / | Page[ProductOut]; page,page_size≤200,product_type?,model?,search(model+name ILIKE),status="active" |
| POST | / | `_validate_product`: main/warehouse→model kerak; additional→name kerak |
| PATCH/DELETE | /{id} | DELETE: OrderItem'da bo'lsa archived, aks holda hard delete (cascade image+inventory) |
| POST/GET/DELETE | /{id}/image | png/jpeg/webp/gif ≤5MB; GET Cache-Control private max-age=300 |
| GET/POST | /inventory/list, /inventory | (sodda inventory) |

**Inventory (`/api/v1/inventory`, module_guard("inventory")):**
- GET /summary → WarehouseSummary (warehouse product'lar, model+kvm bo'yicha; total_value_usd = (available+reserved)×base_price_usd).
- GET /units → list[UnitOut]; status?,product_id?,model?,search(unique_id),limit≤2000; warehouse only; `Order.unit_uid==unique_id AND status∉{delivered,rejected}` join + customer.
- POST /units (inventory:write) — bulk; warehouse product; unique_id'lar tozalanadi/dedup; mavjud bo'lsa 400.
- PATCH /units/{id} (inventory:write) — sold tahrirlanmaydi; unique_id/product_id unikal/warehouse.
- DELETE /units/{id} (inventory:delete) — faqat available.

**Production (`/api/v1/production`, module_guard("production")):**
- GET /summary?date_from?date_to → ProductionSummary (sana+kategoriya bo'yicha sum(quantity)).
- GET /records → list[RecordOut]; category?,date_from?,date_to?,search(unit_code),limit≤2000; Product LEFT JOIN (model,kvm).
- POST /records (production:write) — kotyol: product_id(warehouse)+unit_code(unikal) majburiy, quantity=1.
- PATCH /records/{id} (production:write) — unit_code unikal qayta tekshir.
- DELETE /records/{id} (production:delete).

**Inventory linkage:** Order yaratilganda `unit_uid` berilsa birlik reserved bo'ladi; delivered→birlik o'chiriladi; rejected→available. `unit_uid` snapshot order'da qoladi.

---

# 4. Mijozlar / Buyurtmalar / Navbat / Yuk chiqarish

## Modellar

### customers
full_name VARCHAR(255)(idx), phone VARCHAR(30)(idx), phone2 VARCHAR(30)?, country VARCHAR(50)="Uzbekistan", region VARCHAR(100)?, city VARCHAR(100)?, address TEXT?, source VARCHAR(50)? (manual/telegram_bot/import), **is_dealer BOOLEAN=False** (qarz bilan ham "yetkazildi"ga ruxsat), note?, created_by_id→users.id SET NULL.

### orders
| Ustun | Tip | Null | Default | FK/Izoh |
|---|---|---|---|---|
| code | VARCHAR(30) | no | | **unique** "YYYY-NNNNN" |
| customer_id | UUID | no | | customers.id RESTRICT |
| salesperson_id | UUID | yes | | users.id SET NULL |
| source | VARCHAR(30) | no | "manual" | manual/telegram_bot/import |
| order_date | DATE | no | | (idx) |
| delivered_at | DATE | yes | | |
| status | VARCHAR(20) | no | "new" | new/ready/delivered/rejected |
| priority | INTEGER | no | 0 | navbat ustuvorligi |
| in_queue | BOOLEAN | no | False | |
| pickup_date | DATE | yes | | navbat |
| inventory_id | UUID | yes | | inventory.id SET NULL (delivered→NULL) |
| unit_uid | VARCHAR(50) | yes | | (idx) ombor birligi ID snapshot |
| area_m2 | INTEGER | yes | | kvm |
| bunker_direction | VARCHAR(10) | yes | | |
| delivery_address | TEXT | yes | | |
| exchange_rate | NUMERIC(12,2) | no | 0 | USD→UZS snapshot |
| payment_type | VARCHAR(20) | yes | | |
| has_stamp_ruc/has_stamp_avt/has_online/has_video | BOOLEAN | no | False | NUR Excel flag'lari |
| note, additional_info | TEXT | yes | | |

**Computed:** `items_total_uzs=Σ OrderItem.total_uzs`; `paid_uzs=Σ Payment.amount_uzs_equiv(yoki amount)`; `balance_uzs=items_total-paid`. **Relationships:** customer (selectin), items (1:N cascade selectin), payments (1:N cascade selectin), inventory (1:1?).

### order_items
order_id→orders.id CASCADE, product_id→products.id RESTRICT, serial_id VARCHAR(50)?, bunker_direction VARCHAR(10)?, quantity int=1, unit_price_usd NUMERIC(10,2), unit_price_uzs NUMERIC(14,2), discount_usd NUMERIC(10,2), discount NUMERIC(14,2) (=discount_usd×exchange_rate), total_uzs NUMERIC(14,2) (=unit_price_uzs×quantity-discount). Validatsiya: `0 ≤ discount_usd ≤ unit_price_usd×quantity`.
### payments
order_id→orders.id CASCADE, date DATE, amount NUMERIC(14,2), currency VARCHAR(3)="UZS", amount_uzs_equiv NUMERIC(14,2), method VARCHAR(20)? (cash/card/transfer), doc_file_id UUID?, note? (`"__import_correction__"` = override tomonidan), created_by_id. **Finance modulidan MUSTAQIL.**
### shipments (Yuk chiqarish — mustaqil)
date DATE?(idx), qty int=1, country VARCHAR(40)?(idx), region VARCHAR(60)?(idx), destination VARCHAR(255)?, kvm int?, direction VARCHAR(20)?, product_name VARCHAR(120)?, product_price NUMERIC(14,2)?, driver_name VARCHAR(120)?, driver_phone VARCHAR(40)?, freight NUMERIC(14,2)?, card_number VARCHAR(40)?, card_holder VARCHAR(120)?, reason TEXT?, order_id→orders.id SET NULL? (legacy), created_by_id. Hammasi optional (qty=1 dan tashqari) — Google Sheets uslubidagi inline tahrir.

## Buyurtma status lifecycle
Qiymatlar: **new** (Navbatda), **ready** (Tayyor), **delivered** (Yetkazildi), **rejected** (Rad etildi).
O'tishlar: new→{ready,delivered,rejected}; ready→{delivered,rejected}; delivered/rejected = terminal.
**→delivered:** `delivered_at=today`; bog'langan inventory birlik **o'chiriladi**; `balance_uzs≤0` shart (yoki `customer.is_dealer`). **→rejected:** inventory birlik **available** ga qaytadi.

## DTO'lar
`CustomerBase/Create{full_name,phone,phone2?,country="Uzbekistan",region?,city?,address?,source?="manual",note?,is_dealer=False}`, `CustomerOut`. `OrderItemIn{product_id,serial_id?,bunker_direction?,quantity≥1,unit_price_usd≥0,unit_price_uzs≥0,discount_usd≥0,discount≥0}`, `PaymentIn{date,amount,currency="UZS",amount_uzs_equiv=0,method?,note?}`, `OrderBase{customer_id,order_date,area_m2?,bunker_direction?,inventory_id?,unit_uid?,delivery_address?,exchange_rate=0,payment_type?,has_*,note?,additional_info?}`, `OrderCreate{+items[]}`, `OrderUpdate{...optional,status?,items?}`, `OrderOut{...,items[],payments[],customer,inventory,items_total_uzs,paid_uzs,balance_uzs,queue_position?,salesperson_name?}`, `UnitUidUpdate`, `SalespersonUpdate`, `OverrideAmounts{total_uzs?,paid_uzs?}`, `OrderStatusChange{status,delivered_at?,note?}`, `QueueItemOut{+position}`, `QueueAdd{pickup_date?}`, `QueueMove{action: up/down/top}`, `SalesSummary`, `ShipmentCreate/Update/Out`, `ShipmentStats`.

## Endpointlar
**Customers (`/api/v1/customers`, module_guard):** GET / (page,search,region,country); POST (created_by); GET/PATCH /{id}; DELETE /{id} (order bo'lsa 400, RESTRICT).
**Orders (`/api/v1/orders`, module_guard("orders", exempt=("/payments",))):**
| Metod | Yo'l | Izoh |
|---|---|---|
| GET | / | Page[OrderOut]; status?,salesperson_id?,customer_id?,date_from?,date_to?,search(code/customer/phone) |
| GET | /summary | SalesSummary (status sanog'i, sotuvchi sanog'i, oylik) |
| GET | /export.xlsx | ≤5000 |
| GET | /queue | list[QueueItemOut] (in_queue, status∈{new,ready}, sort: priority desc→pickup_date asc→order_date asc→created_at asc) |
| POST | /{id}/queue-move | up/down/top → priority qayta hisoblash |
| POST | /{id}/to-queue, /from-queue | in_queue toggle |
| GET | /salespeople | faol userlar |
| POST | / | OrderCreate→201; discount validatsiya; delivery_address mijozdan; code generatsiya (5 retry); _link_unit |
| GET | /{id} | OrderOut |
| GET | /{id}/invoice.pdf, /warranty.pdf, /payments/{pid}/receipt.pdf | PDF |
| PATCH | /{id} | delivered/cancelled tahrirlanmaydi; unit_uid; items almashtirish; status o'tish |
| PATCH | /{id}/unit-uid, /salesperson, /override-amounts | **`system:order_override`** (super-admin) |
| POST | /{id}/status | OrderStatusChange; transition; delivered→balance/inventory; rejected→free |
| POST/GET/DELETE | /{id}/payments[/{pid}] | orders:write/read/delete; balansdan oshmaydi; delivered to'lov o'chmaydi |
| DELETE | /{id} | orders:delete; inventory free; cascade items+payments |

**Shipping (`/api/v1/shipping`, module_guard("shipping")):** GET / (year?,month?); GET /stats?group_by(region/country/direction/driver/month/year); GET /drivers; GET /products; POST; PATCH/{id}; DELETE/{id}.

## order_service.py
- `generate_order_code(db)` → `"{year}-{maxseq+1:05d}"` (eng katta mavjud raqamdan; o'chirilganda qayta ishlatilmaydi; 5 retry IntegrityError'da).
- `is_valid_transition(current,new)` (yuqoridagi jadval).
- `_link_unit(db,order,uid)`: eski birlik free; yangi birlik topiladi (yo'q→422), boshqa aktiv order band qilgan bo'lsa 400, reserved qilinadi; `_free_unit_by_uid`; `_delete_linked_unit` (delivered'da o'chiradi, unit_uid snapshot qoladi).

**Muhim:** Sotuv to'lovlari Finance'dan mustaqil. Dealer istisnosi. delivered→inventory o'chadi. Navbat pozitsiyasi endpoint'da hisoblanadi (DB'da saqlanmaydi).

---

# 5. Moliya va Qarzlar

## Modellar

### accounts
name VARCHAR(100), currency VARCHAR(3)="UZS" (UZS/USD), ledger VARCHAR(20)="operational" (operational/gazna), **balance NUMERIC(16,2)=0 (SAQLANADI, hisoblanmaydi)**.
### finance_categories
name VARCHAR(100), parent_id→finance_categories.id SET NULL? (ierarxiya), kind VARCHAR(20)="expense" (income/expense), code VARCHAR(50)? **unique** (maxsus: `employee_salary`, `advance_to_employee`).
### finance_transactions
date DATE(idx), type VARCHAR(20)(idx) income/expense/transfer, category_id→finance_categories SET NULL?, amount NUMERIC(16,2), currency VARCHAR(3)="UZS", amount_other_curr NUMERIC(16,2)=0, account_id→accounts SET NULL?, related_order_id→orders SET NULL?(idx), doc_file_id?, note?, **status VARCHAR(10)="active"** (active/void), created_by_id.
### exchange_rates
date DATE(idx) **UNIQUE**, usd_to_uzs NUMERIC(12,2), source VARCHAR(20)="manual" (manual/cbu).
### debt_products (Bizning qarzlar)
name VARCHAR(255)(idx), debt_type VARCHAR(50)="product" (product=qty×price / credit/loan/erkin=to'g'ridan amount), unit VARCHAR(20)="dona", unit_price NUMERIC(16,2), currency VARCHAR(3)="UZS", supplier?, note?, created_by_id. Computed: total_purchased/total_paid/balance/last_purchase_at/tx_count.
### debt_transactions
product_id→debt_products.id CASCADE, kind VARCHAR(20) purchase/payment, qty NUMERIC(14,3), unit_price NUMERIC(16,2), amount NUMERIC(16,2), currency (snapshot), note?, created_by_id.

## DTO'lar
`AccountCreate/Out{name,currency,ledger,balance}`, `CategoryCreate/Out{name,kind,parent_id?,code?}`, `TransactionCreate/Out{date,type,category_id?,amount,currency,amount_other_curr,account_id?,related_order_id?,note?,status,category_name,account_name}`, `ExchangeRateBase/Out{date,usd_to_uzs,source}`, `BalanceSummary{uzs,usd,gazna,last_updated}`, `EmployeePaymentIn{employee_id,kind(advance/salary),amount?,year,month,pay_date?,affect_finance?,override=False,currency="UZS",note?}`, `FinanceSummary{year,month,income_total,expense_total,net,usd_income_total,usd_expense_total,by_category[]}`. `DebtProductCreate/Update/Out`, `PurchaseCreate{qty?,unit_price?,amount?,note?}`, `PaymentCreate{amount,note?}`, `DebtTransactionOut`, `DebtSummary{by_currency[CurrencyTotal],product_count}`.

## Endpointlar
**Finance (`/api/v1/finance`, module_guard("finance"), `/exchange-rates` read-exempt):**
| Metod | Yo'l | Izoh |
|---|---|---|
| GET/POST/DELETE | /accounts[/{id}] | DELETE: tranzaksiyada bo'lsa 400 |
| GET/POST/DELETE | /categories[/{id}] | code unikal |
| GET | /transactions | Page; type?,account_id?,date_from?,date_to?; void ham qaytadi |
| POST | /transactions | income/expense (transfer emas); amount>0; `apply_transaction` (income +, expense −) |
| DELETE | /transactions/{id} | **Soft void** + balansni teskari qiladi |
| GET | /summary?year&month | FinanceSummary (void chiqarib; transfer chiqarib; valyuta ajratilgan) |
| POST | /employee-payments | advance/salary → SalaryAdvance + Finance expense (pastda) |
| GET | /exchange-rates[?limit] | public-read |
| GET | /exchange-rates/latest | bugungi yo'q bo'lsa CBU'dan oladi |
| POST | /exchange-rates | upsert(date) |
| GET | /balance-summary | BalanceSummary |

**Debts (`/api/v1/debts`, module_guard("debts")):** GET /summary; GET /products (search,with_debt); POST /products; PATCH/DELETE /products/{id}; GET /products/{id}/transactions; POST /products/{id}/purchase (product→qty×price, boshqa→amount); POST /products/{id}/payment; DELETE /transactions/{id} (hard).

## Biznes mantiq (finance_service.py)
- `apply_transaction(db,tx,reverse=False)`: `account.balance += mult*sign*amount` (income sign +1, expense/transfer −1; reverse mult −1). account_id yo'q→no-op.
- `current_balances`: gazna=ledger=="gazna"; usd=ledger≠gazna&currency=USD; uzs=ledger≠gazna&currency=UZS.
- `ensure_today_rate`: bugungi rate yo'q→`fetch_usd_rate()` (CBU), source=cbu; xato→oxirgi rate.
- `month_summary`: oy oralig'i, status=active, income/expense (transfer emas), valyuta ajratilgan, kategoriya bo'yicha (UZS), uncategorized="Boshqa".
- **CBU (cbu.py):** GET `CBU_API_URL`, JSON `[{"Ccy":"USD","Rate":"12345.67"}]` → Decimal; timeout 10s; xato→None.

## Cross-module: Employee Payment
**advance:** limit tekshiruvi (max_gross = taxminiy oylik; current_advances). Oshsa override=false→400; override=true→`system:finance_override` kerak. SalaryAdvance yaratiladi; affect_finance(default true)→Finance expense (category `advance_to_employee`, employee.currency account), `SalaryAdvance.tx_id` bog'lanadi, balans kamayadi.
**salary:** `_month_aggregate` (attendance daily_pay yoki fixed salary_amount − active advances); net≤0→400. SalaryAdvance(amount=net) + Finance expense (category `employee_salary`). pay_date oy oralig'iga to'g'rilanadi.

---

# 6. Servis/Kafolat va Ta'minot

## Modellar

### service_tickets
code VARCHAR(30) **unique** "SRV-YYYY-NNNNN", order_id→orders SET NULL?(idx), customer_id→customers RESTRICT(idx), serial_id VARCHAR(50)?, address TEXT?, problem TEXT, category VARCHAR(50)? (ServiceCategory nomiga soft-link), parts_used JSONB=[], opened_at, closed_at?, status VARCHAR(20)="new" (new/scheduled/completed/cancelled), in_warranty BOOLEAN=False, resolution?, client_cost NUMERIC(14,2)=0, created_by_id, trip_id→service_trips SET NULL?(idx). Status→completed/cancelled: closed_at avtomatik; →new/scheduled: closed_at=NULL.
### service_visits
ticket_id→service_tickets CASCADE, planned_at/started_at/finished_at?, travel_cost NUMERIC(14,2)=0, note?.
### service_categories / service_parts
name VARCHAR(80) **unique**, is_active BOOLEAN=True (soft-delete).
### service_trips (safari)
name VARCHAR(120)?, status VARCHAR(20)="open" (open/closed), collected/spent/total_cost NUMERIC(14,2)=0 (qo'lda), note?, ticket_count int=0, opened_at, closed_at?, created_by_id. Doim 1 ta open; yopilganda barcha "scheduled" ticketlar "completed" bo'lib bog'lanadi, yangi open ochiladi.

### vendors
name VARCHAR(255)(idx), user_id→users SET NULL? **unique**(idx) (login; o'z item/receipt'ini ko'radi), phone?, address?, note?, is_active BOOLEAN=True.
### items (ta'minot materiallari — katalog products'dan ALOHIDA)
name VARCHAR(255)(idx), vendor_id→vendors SET NULL?(idx), unit VARCHAR(20)="dona" (dona/kg/gr/metr/list), unit_price NUMERIC(16,2), stock_qty NUMERIC(14,3), min_qty NUMERIC(14,3), note?. `is_low = stock_qty<min_qty AND min_qty>0`.
### goods_receipts
date DATE(idx), vendor_id→vendors RESTRICT(idx), item_id→items RESTRICT, qty NUMERIC(14,3), unit_price NUMERIC(16,2), total NUMERIC(16,2) (=qty×price), paid NUMERIC(16,2), balance NUMERIC(16,2) (=total-paid), status VARCHAR(20)="open" (open/partial/paid), note?, created_by_id. Yaratilganda: stock_qty+=qty + StockMovement(reason="receipt").
### vendor_payments
vendor_id→vendors CASCADE(idx), date DATE, amount NUMERIC(16,2), receipt_id→goods_receipts SET NULL?, note?, created_by_id. receipt_id yo'q→FIFO ochiq receipt'larga (date,created_at); bor→bitta receipt.
### stock_movements
item_id→items CASCADE(idx), qty_change NUMERIC(14,3) (+in/−out), reason VARCHAR(50) (receipt/issue/adjust), ref_id UUID?, note?, created_by_id.

## DTO'lar (asosiy)
`ServiceTicketCreate{order_id?,customer_id,serial_id?,address?,problem,category?,in_warranty=False}`, `ServiceTicketUpdate{status?,resolution?,client_cost?,closed_at?,in_warranty?,parts_used?}`, `ServiceTicketOut{...,visits[],customer,order}`, `ServiceVisitIn/Out`, `WarrantyInfo{order_id,warranty_start?,year1_end?,year3_end?,days_remaining_year1?,days_remaining_year3?,current_status}`, `ServiceCategoryIn/Out`, `ServicePartIn/Out`, `ServiceSummary`, `ServiceTripOut/Update`, `TripMoneyStat`, `PartStat`, `CustomerMini`, `OrderMini`.
`VendorCreate/Update/Out{...,open_debt,items_count,low_stock_count}`, `ItemCreate/Update/Out{...,is_low}`, `GoodsReceiptIn{date,vendor_id?,item_id,qty,unit_price?,paid=0,note?}`, `GoodsReceiptOut{...,item_name,vendor_name,unit}`, `VendorPaymentIn/Out`, `StockIssueIn{item_id,qty,note?}`, `SupplySummary`.

## Endpointlar
**Service (`/api/v1/service`, module_guard("service")):** GET /summary; GET /trips/current; GET /trips/stats; GET /trips; GET /trips/{id}/tickets; PATCH /trips/{id}; POST /trips/{id}/close (scheduled→completed); GET /tickets (page,status?,in_warranty?,customer_id?,search); GET /tickets/{id}; POST /tickets (code "SRV-YYYY-NNNNN", order_id→warranty auto in_warranty, address mijozdan); PATCH /tickets/{id} (closed_at logikasi); POST /tickets/{id}/visits; GET/POST/DELETE /categories[/{id}] (soft); GET/POST/DELETE /parts[/{id}], GET /parts/stats; GET /warranty/{order_id}; GET /orders?customer_id.
**Supply (`/api/v1/supply`, module_guard("supply"); yozish require_permission("supply:write/delete")):** GET/POST/PATCH /vendors[/{id}] + GET /vendors/{id}/balance; GET/POST/PATCH/DELETE /items[/{id}] + GET /reorder-suggestions; GET/POST /receipts (POST: total/paid/balance/status, stock+=qty, StockMovement, low-stock notif); POST /payments (FIFO/single); POST /stock/issue (qty≤stock; stock−=qty; low-stock notif); GET /summary. **Vendor-scoped userlar faqat o'z vendor ma'lumotini ko'radi.**

## Kafolat (warranty_service.py)
`calculate_warranty(order)`: start = `order.delivered_at`. Year1 = start+365 (to'liq: ehtiyot+servis bepul); Year2-3 = start+1095 (faqat servis bepul, ehtiyot pullik). Status: `not_delivered` (delivered_at yo'q) / `active_full` (today<year1_end) / `active_service_only` (year1_end≤today<year3_end) / `expired`. Ticket yaratishda order_id bo'lsa in_warranty avto.

**Status enumlar:** ticket new/scheduled/completed/cancelled; trip open/closed; receipt open/partial/paid; warranty not_delivered/active_full/active_service_only/expired; stock_movement receipt/issue/adjust.

---

# 7. Tizim / Hisobotlar / Qidiruv / Bildirishnoma / Telegram / PDF / Excel

## Modellar (system.py)
### notifications
user_id→users CASCADE(idx), channel VARCHAR(20)="in_app" (in_app/email/sms/telegram), type VARCHAR(50) (new_order, warranty_expiring, low_stock_alert…), title VARCHAR(255), body TEXT?, payload JSONB={}, read_at? (NULL=o'qilmagan).
### audit_logs
user_id→users SET NULL?(idx), entity VARCHAR(50)(idx), entity_id VARCHAR(100)?(idx), action VARCHAR(50) (create/update/delete/login/logout…), before JSONB?, after JSONB?, ip VARCHAR(45)?, user_agent VARCHAR(500)?.
### file_records
name VARCHAR(255), mime VARCHAR(100)?, size int=0, storage_key VARCHAR(500), uploaded_by_id→users SET NULL?.
### telegram_orders
telegram_chat_id VARCHAR(50)(idx), telegram_message_id VARCHAR(50)?, raw_data JSONB={}, order_id→orders SET NULL?, processed_at?.

## Hisobotlar (`/api/v1/reports`, module_guard("reports"))
Barchasi read-only agregatsiya. Asosiy endpointlar va javob shakllari:
- **GET /dashboard** → `{as_of, kpi{orders_total,orders_delivered,revenue_uzs,revenue_prev_uzs,revenue_growth_pct,income_uzs,expense_uzs,net_uzs}, alerts{warranty_expiring,service_new,service_scheduled,low_stock,vendor_debt_uzs,queue_count}, status_breakdown[], recent_orders[], revenue_sparkline[14d]}`.
- **GET /sales/kpi?date_from&date_to** → `{orders_total,orders_new/ready/delivered/rejected,total_uzs,avg_check_uzs}`.
- **GET /sales/trend?granularity(day/month)** → `{points[{date,total_uzs,orders}]}` (kunlar to'ldiriladi).
- **GET /sales/income-expense?year&month** → 5 hafta bucket (1–7,8–14,15–21,22–28,29+) income/expense (FinanceTransaction active).
- **GET /sales/by-model** (OrderItem→Order→Product, model bo'yicha), **/by-region** (Customer.region), **/by-seller** (User.full_name), **/by-customer?limit** — har biri `[{<key>,count,total_uzs}]`, revenue desc. Default 90 kun.
- **GET /sales/receivables[?limit]** → `{total_balance_uzs,count,items[{code,customer,phone,is_dealer,total_uzs,paid_uzs,balance_uzs,days}]}` (balance>0, non-rejected). **/sales/receivables.xlsx** export.
- **GET /sales/status-breakdown** → `[{status,count,total_uzs}]`.
- **GET /finance/pnl?date_from&date_to** → `{income,expense,net,margin_pct,expense_by_category[top8]}`.
- **GET /service/summary** → `{total,new,scheduled,completed,cancelled,in_warranty,out_warranty,client_revenue_uzs,by_category[top8]}`.
- **GET /supply/summary** → `{receipts_total_uzs,receipts_paid_uzs,debt_total_uzs,low_stock_count,low_stock[],top_debts[top10]}`.

## Qidiruv (`/api/v1/search`)
**GET /?q&per_type(≤20,default6)** → `{query, groups[{type, items[{id,label,sublabel,route,...}]}]}`. Entity'lar: customers (full_name ILIKE / normalized phone), orders (code/customer/phone), products (model/name/sku), service (code/problem). **Faqat ruxsati bor entity tiplari qaytadi.**

## Bildirishnoma (`/api/v1/notifications`, auth, faqat o'ziniki)
GET /?unread_only (≤100, created_at desc); POST /{id}/read → `{updated}`; POST /read-all; GET /unread-count → `{count}`.

## Permissions endpoint (`/api/v1/permissions`)
GET /catalog → `{modules[15],verbs[5],wildcard_all,special[7]}`; GET /me → `{is_superadmin,permissions[]}`; GET /check?perm → `{perm,allowed}`; PATCH /role/{id} (`system:roles`, ensure_can_grant_special).

## Telegram (`/api/v1/telegram`)
POST /webhook (public; TelegramOrder yaratadi; token yo'q→503); GET /status → `{bot_token_set,webhook_url}`.

## Telegram bot (`app/integrations/telegram/`, aiogram 3 + APScheduler, alohida process: `python -m app.integrations.telegram`)
**Mijoz oqimi (FSM OrderFSM):** /neworder yoki /start → name→phone→region→model(PREMIUM 3/PREMIUM 4/ULTRA/MAGNUM/OPTIMA)→kvm(150-500)→direction(O'NGA/CHAPGA→right/left)→price(USD)→note→confirm. Tasdiqda: Customer find/create (normalized phone, source=telegram_bot), Product find/create (main,model+kvm,active), latest USD rate, order code, Order(source=telegram_bot,status=new), OrderItem(qty=1), commit; admin'larga xabar (TELEGRAM_NOTIFY_NEW_ORDER).
**Admin:** /id (chat_id), /report (TELEGRAM_ADMIN_IDS, bugungi digest).
**Kunlik digest (digest.py, APScheduler default 20:00):** kun bo'yicha — new_orders, telegram_orders, delivered, revenue_uzs, payments_uzs, income/expense, cash (uzs/usd/gazna), queue_count, outstanding_uzs, status_breakdown. HTML format. `net_uzs=income-expense`.
**repository.py:** `_find_or_create_customer`, `_resolve_or_create_product`, `_latest_usd_rate`, `create_order_from_draft`. **common.py:** MODELS, KVMS, DIRECTIONS, tz/today, fmt_uzs/fmt_usd, to_decimal, normalize_phone.

## PDF (pdf_service.py, reportlab)
Fontlar: DejaVuSans/Vera TTF (Unicode), fallback Helvetica. Brend ranglar (#1E3A5F, #2980B9).
- **order_invoice_pdf** (FAKTURA): kompaniya/customer blok, items jadval (#, Mahsulot, Soni, Narx USD, Summa UZS), Jami/To'langan/Qoldiq, kurs, imzo blok, footer. `Order.items_total_uzs/paid_uzs/balance_uzs`.
- **payment_receipt_pdf** (TO'LOV KVITANSIYASI): customer, to'lov jadval (sana, summa, usul Naqd/Karta/O'tkazma, UZS ekv, qoldiq), izoh, imzo.
- **warranty_certificate_pdf** (KAFOLAT SERTIFIKATI): mahsulotlar (serial), kafolat jadval (yetkazilgan sana, 1-yil to'liq, 2-3 yil servis), shartlar, imzo. delivered_at yo'q→"Hali yetkazilmagan".

## Excel (excel_service.py, openpyxl)
`build_xlsx(title, columns[Col{header,getter,kind:text/money/date/int,width}], rows)`: header dark-blue/white, alternating rows, money `#,##0 "so'm"`, date DD.MM.YYYY, frozen header + autofilter.
- **orders_workbook:** Kod, Sana, Mijoz, Telefon, Viloyat, Holat (Navbatda/Tayyor bo'ldi/Yetkazildi/Rad etildi), Mahsulot(soni), Jami, To'langan, Qoldiq.
- **receivables_workbook:** Mijoz, Telefon, Buyurtma, Sana, Kun, Jami, To'langan, Qoldiq.

---

# 8. Appendix

## 8.1 Barcha jadvallar (entity'lar)
users, roles, user_roles, user_avatars · departments, positions, employees, salary_rates, attendance, salary_advances, employee_loans, employee_loan_payments, payroll_runs, payroll_items · customers, orders, order_items, payments · products, inventory, product_images, production_records · accounts, finance_categories, finance_transactions, exchange_rates · debt_products, debt_transactions · service_tickets, service_visits, service_categories, service_parts, service_trips · vendors, items, goods_receipts, vendor_payments, stock_movements · shipments · notifications, audit_logs, file_records, telegram_orders.

## 8.2 Enum / status qiymatlari (lug'at)
| Soha | Qiymatlar |
|---|---|
| user locale/theme | uz/ru/en · light/dark |
| employment_type | office, worker |
| department_type | office, assembly, production |
| salary_type | hourly, daily, fixed, kpi |
| employee status | active, terminated, leave |
| salary_advance status | active, void |
| employee_loan source/status | director,firma,other · active,closed |
| payroll_run status | draft, approved, paid |
| product_type | main, additional, warehouse |
| product/inventory status | active/archived · available/reserved/sold |
| bunker_direction | right, left |
| production category | kotyol, bunker, garelka |
| order status | new, ready, delivered, rejected |
| order/customer source | manual, telegram_bot, import |
| payment method/currency | cash,card,transfer · UZS,USD |
| account ledger | operational, gazna |
| finance tx type/status | income,expense,transfer · active,void |
| finance category kind | income, expense |
| exchange_rate source | manual, cbu |
| debt_type / debt kind | product,credit,loan,… · purchase,payment |
| service ticket status | new, scheduled, completed, cancelled |
| service trip status | open, closed |
| goods_receipt status | open, partial, paid |
| warranty status | not_delivered, active_full, active_service_only, expired |
| stock_movement reason | receipt, issue, adjust |
| notification channel | in_app, email, sms, telegram |

## 8.3 Ruxsatlar — endpoint → permission xulosa
- **module_guard(module):** GET=module:read (modulda istalgan verb), POST/PATCH/PUT=module:write, DELETE=module:delete.
- **Aniq:** inventory units POST/PATCH=inventory:write, DELETE=inventory:delete; production records POST/PATCH=production:write, DELETE=production:delete; supply receipts/payments/items write=supply:write, delete=supply:delete.
- **Maxsus (super-admin):** users permanent=`system:user_delete`; password=`system:user_password`; avatar=`system:user_avatar`; roles CRUD=`system:roles`; order override (unit-uid/salesperson/amounts)=`system:order_override`; avans override=`system:finance_override`; super_admin grant=`system:grant_superadmin`.

## 8.4 C#/.NET migratsiya bo'yicha kalit eslatmalar
1. **PK/UUID** → `Guid` (Npgsql `uuid`), default `Guid.NewGuid()`.
2. **Decimal aniqligi:** narx (10,2), jami/balans (14,2)/(16,2), kurs (12,2), miqdor (14,3), soat (5,2). EF `[Precision]`.
3. **Timestamptz** → `DateTimeOffset` / UTC.
4. **JSONB** (permissions, specs, payload, parts_used, before/after) → Npgsql `jsonb` / `JsonDocument`.
5. **Cascade:** EF `OnDelete(Cascade/SetNull/Restrict)` — modellarda ko'rsatilgan.
6. **Unique/Index:** phone(users), name(role/department/position/service_category/service_part), sku(products), unique_id(inventory), code(orders/service_tickets), unit_code(production), (employee_id,work_date)(attendance), exchange_rate.date, vendor.user_id.
7. **Token invalidation:** `token_version` claim (`ver`) — DB'dagi qiymat bilan solishtiriladi (blacklist'siz logout).
8. **RBAC:** wildcard matching (`*`, `module:*`, `*:verb`) + special permissions (oddiy `*` bermaydi). `ensure_can_grant_special` — privilege escalation himoyasi.
9. **Hisoblangan vs saqlangan balans:** account.balance SAQLANADI (apply_transaction); order/debt/vendor balanslari HISOBLANADI (so'rovda).
10. **Order↔Inventory** FK emas, `unit_uid` STRING tenglik orqali (delivered birlikni o'chiradi, snapshot qoladi).
11. **Pul/valyuta:** asosan UZS; USD bilan; `amount_uzs_equiv` (to'lov), `exchange_rate` snapshot (order). CBU'dan kunlik kurs.
12. **Salary rate tarixi:** har bir work_date uchun amaldagi stavka (`effective_from<=date`, DESC) — eski oylar o'zgarmaydi.
13. **Atomic tranzaksiyalar:** payroll, attendance batch, employee-payment (HR+Finance), user create (User+Employee+Vendor) — bitta DB transaction.
14. **Soft delete:** user(is_active), finance tx & salary_advance(status=void), product(archived). Hard delete cheklangan.
15. **Fayllar:** rasm/avatar = PostgreSQL BYTEA (alohida jadval, ro'yxat so'rovlarini yengillashtirish uchun).
16. **Telefon normalizatsiya** — login va qidiruv uchun raqamlar bo'yicha moslik.
17. **Avto-migratsiya** startup'da — .NET'da `dbContext.Database.Migrate()` ekvivalenti.
18. **Telegram bot** — alohida worker service (ASP.NET Core Hosted Service yoki alohida konsol).

---

*Ushbu hujjat 2026-06-24 holatiga ko'ra avtomatik tahlil asosida tuzilgan. Manba: `backend/app/` (models, schemas, api/v1, services, core, integrations). Har bir bo'lim originaldan to'g'ridan-to'g'ri o'qib hujjatlangan.*
