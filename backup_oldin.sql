--
-- PostgreSQL database dump
--

\restrict AKxU8qamdggh0iqJvzmlqjSmaPFnK1RhEgNPciJBzPmbZwivbYxxaVPZYnHkML3

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts (
    name character varying(100) NOT NULL,
    currency character varying(3) NOT NULL,
    ledger character varying(20) NOT NULL,
    balance numeric(16,2) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance (
    employee_id uuid NOT NULL,
    work_date date NOT NULL,
    check_in time without time zone,
    check_out time without time zone,
    hours_worked numeric(5,2) NOT NULL,
    daily_pay numeric(14,2) NOT NULL,
    note text,
    entered_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    user_id uuid,
    entity character varying(50) NOT NULL,
    entity_id character varying(100),
    action character varying(50) NOT NULL,
    before jsonb,
    after jsonb,
    ip character varying(45),
    user_agent character varying(500),
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    full_name character varying(255) NOT NULL,
    phone character varying(30) NOT NULL,
    phone2 character varying(30),
    country character varying(50) NOT NULL,
    region character varying(100),
    city character varying(100),
    address text,
    source character varying(50),
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    name character varying(100) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    full_name character varying(255) NOT NULL,
    phone character varying(30),
    secondary_phone character varying(30),
    birth_date date,
    address text,
    position_id uuid,
    hire_date date,
    employment_type character varying(20) NOT NULL,
    salary_type character varying(20) NOT NULL,
    salary_amount numeric(14,2) NOT NULL,
    currency character varying(3) NOT NULL,
    status character varying(20) NOT NULL,
    has_account boolean NOT NULL,
    user_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exchange_rates (
    date date NOT NULL,
    usd_to_uzs numeric(12,2) NOT NULL,
    source character varying(20) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.exchange_rates OWNER TO postgres;

--
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.files (
    name character varying(255) NOT NULL,
    mime character varying(100),
    size integer NOT NULL,
    storage_key character varying(500) NOT NULL,
    uploaded_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.files OWNER TO postgres;

--
-- Name: finance_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finance_categories (
    name character varying(100) NOT NULL,
    parent_id uuid,
    kind character varying(20) NOT NULL,
    code character varying(50),
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.finance_categories OWNER TO postgres;

--
-- Name: finance_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finance_transactions (
    date date NOT NULL,
    type character varying(20) NOT NULL,
    category_id uuid,
    amount numeric(16,2) NOT NULL,
    currency character varying(3) NOT NULL,
    amount_other_curr numeric(16,2) NOT NULL,
    account_id uuid,
    related_order_id uuid,
    doc_file_id uuid,
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.finance_transactions OWNER TO postgres;

--
-- Name: goods_receipts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.goods_receipts (
    date date NOT NULL,
    vendor_id uuid NOT NULL,
    item_id uuid NOT NULL,
    qty numeric(14,3) NOT NULL,
    unit_price numeric(14,2) NOT NULL,
    total numeric(16,2) NOT NULL,
    paid numeric(16,2) NOT NULL,
    balance numeric(16,2) NOT NULL,
    status character varying(20) NOT NULL,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


ALTER TABLE public.goods_receipts OWNER TO postgres;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory (
    product_id uuid NOT NULL,
    unique_id character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    added_date date NOT NULL,
    notes text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.inventory OWNER TO postgres;

--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items (
    name character varying(255) NOT NULL,
    unit character varying(20) NOT NULL,
    stock_qty numeric(14,3) NOT NULL,
    min_qty numeric(14,3) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    vendor_id uuid,
    unit_price numeric(16,2) DEFAULT 0 NOT NULL,
    note text
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    user_id uuid NOT NULL,
    channel character varying(20) NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    body text,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    read_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    serial_id character varying(50),
    bunker_direction character varying(10),
    quantity integer NOT NULL,
    unit_price_usd numeric(10,2) NOT NULL,
    unit_price_uzs numeric(14,2) NOT NULL,
    discount numeric(10,2) NOT NULL,
    total_uzs numeric(14,2) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    code character varying(30) NOT NULL,
    customer_id uuid NOT NULL,
    salesperson_id uuid,
    source character varying(30) NOT NULL,
    order_date date NOT NULL,
    delivered_at date,
    status character varying(20) NOT NULL,
    priority integer NOT NULL,
    inventory_id uuid,
    area_m2 integer,
    bunker_direction character varying(10),
    delivery_address text,
    exchange_rate numeric(12,2) NOT NULL,
    payment_type character varying(20),
    has_stamp_ruc boolean NOT NULL,
    has_stamp_avt boolean NOT NULL,
    has_online boolean NOT NULL,
    has_video boolean NOT NULL,
    note text,
    additional_info text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    order_id uuid NOT NULL,
    date date NOT NULL,
    amount numeric(14,2) NOT NULL,
    currency character varying(3) NOT NULL,
    amount_uzs_equiv numeric(14,2) NOT NULL,
    method character varying(20),
    doc_file_id uuid,
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: payroll_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payroll_items (
    run_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    hours numeric(7,2) NOT NULL,
    gross numeric(14,2) NOT NULL,
    advance numeric(14,2) NOT NULL,
    net numeric(14,2) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.payroll_items OWNER TO postgres;

--
-- Name: payroll_runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payroll_runs (
    period_start date NOT NULL,
    period_end date NOT NULL,
    status character varying(20) NOT NULL,
    created_by_id uuid,
    approved_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.payroll_runs OWNER TO postgres;

--
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    name character varying(100) NOT NULL,
    department_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_type character varying(20) DEFAULT 'main'::character varying NOT NULL,
    model character varying(50),
    kvm integer,
    name character varying(120),
    unit character varying(20),
    sku character varying(50),
    bunker_direction character varying(10),
    description text,
    base_price_usd numeric(10,2) NOT NULL,
    specs jsonb DEFAULT '{}'::jsonb NOT NULL,
    status character varying(20) NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    name character varying(50) NOT NULL,
    description character varying(255),
    permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: salary_advances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salary_advances (
    employee_id uuid NOT NULL,
    advance_date date NOT NULL,
    amount numeric(14,2) NOT NULL,
    currency character varying(3) NOT NULL,
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.salary_advances OWNER TO postgres;

--
-- Name: salary_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salary_rates (
    employee_id uuid NOT NULL,
    effective_from date NOT NULL,
    salary_type character varying(20) NOT NULL,
    amount numeric(14,2) NOT NULL,
    currency character varying(3) NOT NULL,
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.salary_rates OWNER TO postgres;

--
-- Name: service_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_categories (
    name character varying(80) NOT NULL,
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.service_categories OWNER TO postgres;

--
-- Name: service_tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_tickets (
    code character varying(30) NOT NULL,
    order_id uuid,
    customer_id uuid NOT NULL,
    serial_id character varying(50),
    address text,
    problem text NOT NULL,
    category character varying(50),
    opened_at timestamp with time zone NOT NULL,
    scheduled_at timestamp with time zone,
    closed_at timestamp with time zone,
    status character varying(20) NOT NULL,
    in_warranty boolean NOT NULL,
    resolution text,
    client_cost numeric(14,2) NOT NULL,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.service_tickets OWNER TO postgres;

--
-- Name: service_visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_visits (
    ticket_id uuid NOT NULL,
    planned_at timestamp with time zone,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    travel_cost numeric(14,2) NOT NULL,
    note text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.service_visits OWNER TO postgres;

--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stock_movements (
    item_id uuid NOT NULL,
    qty_change numeric(14,3) NOT NULL,
    reason character varying(50) NOT NULL,
    ref_id uuid,
    note text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_id uuid
);


ALTER TABLE public.stock_movements OWNER TO postgres;

--
-- Name: telegram_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telegram_orders (
    telegram_chat_id character varying(50) NOT NULL,
    telegram_message_id character varying(50),
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    order_id uuid,
    processed_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.telegram_orders OWNER TO postgres;

--
-- Name: user_avatars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_avatars (
    user_id uuid NOT NULL,
    content_type character varying(64) NOT NULL,
    size_bytes integer NOT NULL,
    data bytea NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_avatars OWNER TO postgres;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    password_hash character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    phone character varying(20) NOT NULL,
    avatar_url character varying(500),
    "position" character varying(100),
    locale character varying(5) NOT NULL,
    theme character varying(10) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_superadmin boolean DEFAULT false NOT NULL,
    telegram_chat_id character varying(50),
    notification_settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    token_version integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: vendor_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor_payments (
    vendor_id uuid NOT NULL,
    date date NOT NULL,
    amount numeric(16,2) NOT NULL,
    note text,
    created_by_id uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    receipt_id uuid
);


ALTER TABLE public.vendor_payments OWNER TO postgres;

--
-- Name: vendors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendors (
    name character varying(255) NOT NULL,
    phone character varying(30),
    address text,
    note text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.vendors OWNER TO postgres;

--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts (name, currency, ledger, balance, id, created_at, updated_at) FROM stdin;
G'azna (naqd dollar)	USD	gazna	0.00	ad29ab9c-b1f8-461c-82a5-af2f48816234	2026-05-29 11:14:47.009126+00	2026-06-01 10:42:41.016248+00
Bank Asaka - UZS	UZS	operational	3600000.00	2abb3f1f-6dac-419c-b1cd-fb0cd69dcd57	2026-05-29 11:14:47.009126+00	2026-06-08 05:22:08.032782+00
Karta Uzcard - UZS	UZS	operational	-1000000.00	d77f1018-2d92-4745-adcd-b31d972ae101	2026-05-29 11:14:47.009126+00	2026-06-08 05:22:14.164145+00
Naqd - UZS	UZS	operational	-1250000.00	16eb7215-a042-4308-b60d-d15799042b61	2026-05-29 11:14:47.009126+00	2026-06-08 05:22:15.96268+00
Naqd - USD	USD	operational	5000.00	5ac75181-983c-4ab5-ae52-3a0c9571bc66	2026-05-29 11:14:47.009126+00	2026-06-08 05:22:18.58752+00
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance (employee_id, work_date, check_in, check_out, hours_worked, daily_pay, note, entered_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (user_id, entity, entity_id, action, before, after, ip, user_agent, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (full_name, phone, phone2, country, region, city, address, source, note, created_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (name, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (full_name, phone, secondary_phone, birth_date, address, position_id, hire_date, employment_type, salary_type, salary_amount, currency, status, has_account, user_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: exchange_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exchange_rates (date, usd_to_uzs, source, id, created_at, updated_at) FROM stdin;
2026-05-31	11997.83	cbu	728f92a4-0943-4345-a492-043f9fd15724	2026-05-31 17:44:54.250407+00	2026-05-31 17:44:54.250407+00
2026-06-01	12001.94	cbu	82a1e40b-3cdb-4f19-9ea6-62c50b4fdfc4	2026-06-01 04:30:22.071425+00	2026-06-01 04:30:22.071425+00
2026-06-02	11949.03	cbu	817bba60-0171-4ff0-8858-77e9da5dd32f	2026-06-02 11:05:09.324597+00	2026-06-02 11:05:09.324597+00
2026-06-04	11997.21	cbu	616f5743-a177-4a3c-a512-494edcb1d5f9	2026-06-04 19:14:52.557583+00	2026-06-04 19:14:52.557583+00
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.files (name, mime, size, storage_key, uploaded_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: finance_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finance_categories (name, parent_id, kind, code, id, created_at, updated_at) FROM stdin;
Mahsulot sotuvi	\N	income	sales_payment	00a9ed76-16b0-46a9-9251-85f6acc32afd	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Avans to'lovi	\N	income	advance_payment	f898742c-ee18-4ce7-bb8c-01c16cc0e872	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Qoldiq to'lov	\N	income	remaining_payment	2dba9700-7f3f-4d7d-a016-9c562c20ee45	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Qayta kirim	\N	income	returned_funds	94da8d84-c07d-450c-8528-06ab10718bf1	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Boshqa kirimlar	\N	income	other_income	6b260e1a-07d5-4cfb-bda5-1b18eeb36b8d	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Xodimlar oyligi	\N	expense	employee_salary	05efc116-eba1-4254-9186-047c9a513c44	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Ta'minotga o'tkazma	\N	expense	supply_payment	f8992c85-fcef-4993-a37d-20ecae2dbd7d	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Transport	\N	expense	transport	c93b46ce-945e-4de5-9e59-90d7b7ee0d46	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Oziq-ovqat	\N	expense	food	15831ecc-f26c-40e8-9bae-6cd9bb3fefc5	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Kommunal xizmatlar	\N	expense	utilities	292238a8-32c3-496a-8411-101f35ab0547	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Reklama	\N	expense	advertising	f6687ea0-465b-47c7-b2ca-27ccbb96e5c9	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Ehtiyot qismlar	\N	expense	spare_parts	4643555a-df50-4b9a-a6cf-f3b467a9c8ca	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Xodimga avans	\N	expense	advance_to_employee	acf4defb-271d-4f9e-8dab-e6973f08cc2e	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Boshqa xarajatlar	\N	expense	other_expense	e7df157e-d7af-473f-ae68-3f16aace42ed	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Buyurtma to'lovi	\N	income	order_payment	5cb3d4bd-3921-4d80-becd-21820ace4445	2026-06-04 12:40:10.900542+00	2026-06-04 12:40:10.900542+00
\.


--
-- Data for Name: finance_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finance_transactions (date, type, category_id, amount, currency, amount_other_curr, account_id, related_order_id, doc_file_id, note, created_by_id, id, created_at, updated_at) FROM stdin;
2026-06-01	income	00a9ed76-16b0-46a9-9251-85f6acc32afd	1200000.00	UZS	0.00	2abb3f1f-6dac-419c-b1cd-fb0cd69dcd57	\N	\N	\N	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	59e9de51-c6ee-4e2f-8585-b514d6c52ba7	2026-06-01 10:02:29.681978+00	2026-06-01 10:02:29.681978+00
2026-06-01	expense	4643555a-df50-4b9a-a6cf-f3b467a9c8ca	100000.00	UZS	0.00	2abb3f1f-6dac-419c-b1cd-fb0cd69dcd57	\N	\N	\N	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	47b7c724-6c94-4488-b465-fb5de2701d1f	2026-06-01 10:06:15.765356+00	2026-06-01 10:06:15.765356+00
2026-06-01	income	00a9ed76-16b0-46a9-9251-85f6acc32afd	5000.00	USD	0.00	5ac75181-983c-4ab5-ae52-3a0c9571bc66	\N	\N	\N	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	3792a6b4-3ee2-42ed-a7fa-020ceeb23a3d	2026-06-01 10:07:51.008175+00	2026-06-01 10:07:51.008175+00
2026-05-31	expense	acf4defb-271d-4f9e-8dab-e6973f08cc2e	1250000.00	UZS	0.00	16eb7215-a042-4308-b60d-d15799042b61	\N	\N	oldindan	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	328d1582-2a56-47be-b21d-75a9dcb7f2ce	2026-06-01 10:27:31.732074+00	2026-06-01 10:27:31.732074+00
2026-06-01	expense	acf4defb-271d-4f9e-8dab-e6973f08cc2e	1000000.00	UZS	0.00	d77f1018-2d92-4745-adcd-b31d972ae101	\N	\N	Avans — Karimov Jasur	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	40557f3d-ce62-40a7-a52b-0fc8e2d2c5e4	2026-06-01 10:28:22.234887+00	2026-06-01 10:28:22.234887+00
2026-06-01	income	00a9ed76-16b0-46a9-9251-85f6acc32afd	2500000.00	UZS	0.00	2abb3f1f-6dac-419c-b1cd-fb0cd69dcd57	\N	\N	\N	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	50af5a0f-ff0e-4a3c-ab6b-86fd732cae26	2026-06-01 10:40:48.714699+00	2026-06-01 10:40:48.714699+00
\.


--
-- Data for Name: goods_receipts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.goods_receipts (date, vendor_id, item_id, qty, unit_price, total, paid, balance, status, created_by_id, id, created_at, updated_at, note) FROM stdin;
\.


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory (product_id, unique_id, status, added_date, notes, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (name, unit, stock_qty, min_qty, id, created_at, updated_at, vendor_id, unit_price, note) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (user_id, channel, type, title, body, payload, read_at, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (order_id, product_id, serial_id, bunker_direction, quantity, unit_price_usd, unit_price_uzs, discount, total_uzs, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (code, customer_id, salesperson_id, source, order_date, delivered_at, status, priority, inventory_id, area_m2, bunker_direction, delivery_address, exchange_rate, payment_type, has_stamp_ruc, has_stamp_avt, has_online, has_video, note, additional_info, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (order_id, date, amount, currency, amount_uzs_equiv, method, doc_file_id, note, created_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payroll_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payroll_items (run_id, employee_id, hours, gross, advance, net, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payroll_runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payroll_runs (period_start, period_end, status, created_by_id, approved_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (name, department_id, id, created_at, updated_at) FROM stdin;
Usta	\N	fe228d84-8daa-45ec-94ac-8f4d81ea29f1	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Yordamchi ishchi	\N	6b34a21c-acbd-4fdc-95f2-7feb85d6e49b	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Payvandchi	\N	dab3d794-663b-4133-a389-94830f7dc9c6	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Montajchi	\N	df7121b5-0d0d-48df-8ea9-3b3deeef86c9	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Operator	\N	9b98ed54-22e5-4fb3-9a79-e9271f1aead7	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Omborchi	\N	169f7db1-8ba9-4f8b-848a-71d7e72896e1	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Haydovchi	\N	2b31357b-604b-44fd-9a65-02f681758807	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Tozalovchi	\N	158ed4fd-9ca6-442c-8d47-16e45af61b24	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
Bosh direktor	\N	462e4b06-ec97-4ea6-b8e7-49f23f229ac8	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
Buxgalter	\N	cabb0f27-c2a1-417d-8138-b4fe79b80b51	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
HR menejeri	\N	f5aaef76-a0a0-429f-a7b8-3da01171a440	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
Moliya menejeri	\N	d066f08f-1874-483b-9f10-49e1b5745a39	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
Ofis menejeri	\N	da340ea5-6bbf-4f21-8e91-0e100c986502	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
Servis menejeri	\N	bdaf5eb5-8e0e-4e19-8683-002458f0682f	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
Sotuv menejeri	\N	fdb25bf5-a9e1-40b3-aeff-c106919b9390	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (product_type, model, kvm, name, unit, sku, bunker_direction, description, base_price_usd, specs, status, id, created_at, updated_at) FROM stdin;
main	PREMIUM 3	150	\N	\N	\N	\N	\N	1200.00	{}	active	6bd9ac73-8d06-47c2-a227-1495f529685e	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	PREMIUM 3	200	\N	\N	\N	\N	\N	1400.00	{}	active	61c5ce59-f09f-4444-9d6c-be77ce787e16	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	PREMIUM 4	200	\N	\N	\N	\N	\N	1500.00	{}	active	2065e82c-6de8-4342-ba18-011272757703	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	PREMIUM 4	300	\N	\N	\N	\N	\N	1700.00	{}	active	baee405f-865e-4b22-b8be-de2d2580f165	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	ULTRA	300	\N	\N	\N	\N	\N	1900.00	{}	active	d40334eb-41e2-4f6e-b4d4-f0f59d2762a3	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	ULTRA	400	\N	\N	\N	\N	\N	2100.00	{}	active	8363d105-e4f2-4e91-97eb-e07e60015976	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	MAGNUM	400	\N	\N	\N	\N	\N	2200.00	{}	active	772d116f-bac0-4342-80be-ae6361c1b305	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	MAGNUM	500	\N	\N	\N	\N	\N	2500.00	{}	active	65853518-6c60-45af-b267-6a3db9dbfc22	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	OPTIMA	200	\N	\N	\N	\N	\N	1300.00	{}	active	805354a2-61ae-481b-8c08-f8c095433d4e	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	OPTIMA	300	\N	\N	\N	\N	\N	1500.00	{}	active	ed278f8f-94fa-4d9a-b411-004c7d093221	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Turba (issiqlik quvuri)	metr	\N	\N	\N	3.00	{}	active	76d22710-9832-4a54-b9c2-454c203c2aa4	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Defizor (radiator)	dona	\N	\N	\N	25.00	{}	active	d77315aa-2e2a-41e2-aaa8-63b12361c0c2	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Aylanma nasos	dona	\N	\N	\N	60.00	{}	active	f0ae3187-c275-48c3-9495-3cf8142e0320	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Termostat	dona	\N	\N	\N	15.00	{}	active	31ebb36d-202c-4274-9243-a5e68b04469a	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Montaj komplekti	komplekt	\N	\N	\N	40.00	{}	active	85dfb37d-3303-405c-965c-3d457aa346c6	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
additional	\N	\N	Kengaytma baki	dona	\N	\N	\N	35.00	{}	active	54381348-dc04-4aec-b1af-49e0d25af9d2	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
main	PREMIUM 3	300	\N	\N	\N	\N	\N	1600.00	{}	active	b25b5902-81f4-4c4b-b7f3-f877a1bc4ed0	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
main	MAGNUM	600	\N	\N	\N	\N	\N	2800.00	{}	active	905e9eeb-45b4-4838-ab5d-32a309ec7a1d	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
additional	\N	\N	Filtr (suv tozalagich)	dona	\N	\N	\N	18.00	{}	active	06d2a875-43d3-4938-bda9-e7a17a7e7b07	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
additional	\N	\N	Manometr	dona	\N	\N	\N	8.00	{}	active	c7fe5b43-e04e-43a4-b0c1-ebaba3772106	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
additional	\N	\N	Ventil (kran)	dona	\N	\N	\N	5.00	{}	active	67052bb6-d419-4dd5-ab4f-2dcce3bf90ea	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
additional	\N	\N	Dudburon truba	metr	\N	\N	\N	12.00	{}	active	7944a9c6-d31f-4f09-8ad6-f03418a1455d	2026-05-31 16:58:36.757632+00	2026-05-31 16:58:36.757632+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (name, description, permissions, id, created_at, updated_at) FROM stdin;
super_admin	Super Admin (barcha modul)	{"permissions": ["*:*"]}	ba1ae45e-7211-418e-91dd-2b28101edce7	2026-05-29 11:14:47.009126+00	2026-05-29 11:14:47.009126+00
supplier	Ta'minotchi	{"permissions": ["supply:read", "supply:write"]}	be48aa60-38ea-4be3-92df-bb3ac7827615	2026-05-29 11:14:47.009126+00	2026-06-02 08:30:41.492062+00
hr_manager	HR menejeri	{"permissions": ["hr:*"]}	32d507f4-5409-47ad-bd57-a190019d22f0	2026-05-29 11:14:47.009126+00	2026-06-04 18:38:59.70738+00
finance_manager	Moliya menejeri	{"permissions": ["customers:*", "orders:*", "finance:*", "reports:*"]}	9f735276-2fc7-4b28-a2f9-a045573d826c	2026-05-29 11:14:47.009126+00	2026-06-04 19:15:49.123423+00
sales_manager	Sotuv menejeri	{"permissions": ["customers:*", "orders:*", "reports:read"]}	4df72f7a-08b8-4d8b-bcdd-fbe6a670d328	2026-05-29 11:14:47.009126+00	2026-06-04 19:16:16.121068+00
director	Bosh direktor	{"permissions": ["users:*", "customers:*", "orders:*", "products:*", "service:read", "finance:read", "hr:read", "supply:read", "reports:*"]}	5d21070a-06dc-49d9-bf83-6b6d100d5cf1	2026-05-29 11:14:47.009126+00	2026-06-04 19:18:13.568121+00
service_manager	Servis menejeri	{"permissions": ["service:*", "reports:read"]}	1fa3d26a-8ee9-4882-8472-09fb89b222e3	2026-05-29 11:14:47.009126+00	2026-06-04 19:19:13.72696+00
viewer	Ko'rish (read-only)	{"permissions": ["users:read", "customers:read", "orders:read", "products:read", "service:read", "finance:read", "hr:read", "supply:read", "reports:read", "telegram:read", "settings:read"]}	15dadb2a-5cea-43a5-9f35-01f1181a588c	2026-05-29 11:14:47.009126+00	2026-06-04 19:19:38.756084+00
salesperson	Sotuvchi	{"permissions": []}	21970341-7e2a-4d22-a8ab-01586e51df97	2026-06-05 04:15:38.103745+00	2026-06-05 04:15:38.103745+00
service_technician	Servis ustasi	{"permissions": []}	87b2d455-f3d9-42d4-ace4-b4cf0db25de4	2026-06-05 04:15:38.103745+00	2026-06-05 04:15:38.103745+00
supply_manager	Ta'minot menejeri (barcha taminotchilar)	{"permissions": ["supply:read", "supply:write", "supply:delete", "supply:export"]}	af5e2795-42a0-416d-8797-1254b3ade845	2026-06-05 04:15:38.103745+00	2026-06-06 05:10:02.933448+00
\.


--
-- Data for Name: salary_advances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salary_advances (employee_id, advance_date, amount, currency, note, created_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: salary_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salary_rates (employee_id, effective_from, salary_type, amount, currency, note, created_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: service_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_categories (name, is_active, id, created_at, updated_at) FROM stdin;
Ta'mirlash	t	a1e2c0b3-0338-4f76-bbc9-81e33a07979a	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
Profilaktika	t	be9036da-6568-47a8-a64f-32dd5f3d000f	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
Ehtiyot qism almashtirish	t	6499a619-1f0d-4634-806c-f7070b6ce5fa	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
Sozlash / kalibrovka	t	fe403bf3-b73b-4953-92f5-41368652a250	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
O'rnatish	t	184d3eaa-60b9-44f1-b437-974d36655d52	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
Konsultatsiya	t	e4d2ed15-de97-42cc-a9dc-3ac95615a58b	2026-06-01 17:40:16.589914+00	2026-06-01 17:40:16.589914+00
\.


--
-- Data for Name: service_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_tickets (code, order_id, customer_id, serial_id, address, problem, category, opened_at, scheduled_at, closed_at, status, in_warranty, resolution, client_cost, created_by_id, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: service_visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_visits (ticket_id, planned_at, started_at, finished_at, travel_cost, note, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stock_movements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stock_movements (item_id, qty_change, reason, ref_id, note, id, created_at, updated_at, created_by_id) FROM stdin;
\.


--
-- Data for Name: telegram_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telegram_orders (telegram_chat_id, telegram_message_id, raw_data, order_id, processed_at, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_avatars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_avatars (user_id, content_type, size_bytes, data, created_at, updated_at) FROM stdin;
6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	image/jpeg	120331	\\xffd8ffe000104a46494600010101004800480000ffdb0043000302020302020303030304030304050805050404050a070706080c0a0c0c0b0a0b0b0d0e12100d0e110e0b0b1016101113141515150c0f171816141812141514ffdb00430103040405040509050509140d0b0d1414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414ffc0001108036602e003012200021101031101ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffc4001f0100030101010101010101010000000000000102030405060708090a0bffc400b51100020102040403040705040400010277000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738393a434445464748494a535455565758595a636465666768696a737475767778797a82838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae2e3e4e5e6e7e8e9eaf2f3f4f5f6f7f8f9faffda000c03010002110311003f00ed68a7b77a17b57947b61b29db685a7f341045b28d952f347340116ca3654bcd36801946ca7d2ad058d55a76da5e68a08136d1b6968a005db494fa280194fa28a0028a7d1400ca29f4500328a7d1400ca3653e9dcd0045b29db69db6979a006d3b9a39a39a800e69b4ea2ac066da76da5a280136d2f3452eda006eda36d3b6d3a8023db4bcd3e8a006eda36d48ab46da008f6d1e554db69cab4011aad3b6d3b6d3b654011eda36d49b29db68021db47975636d3bcaa082155a9161a9162a9962a008562a72c556162a916de802bac5532c356a3b7ab11daffb3500538e2ab51dbd5c86c1ab4ad74b66fe1a5cc066c366cd5a16fa5b4adf76ba0b1f0fb36df96ba4d3fc38abb59969ea4f31cbd8e82cdfc35d369be1ff00baccbb6b7adec238bf86ae2a54815ed6ce3b75e16ad2ad0b4ea0029f4ca7d05051451400c93eed79bf8dbfd5cd5e9127ddaf37f1a2feee4a00f3d65a6eda91bbd35aab50128e68a28d40bfa57fc7d47fef57b47877fe3cd6bc6747ff008fc8ebd93c3bff001e6b5249b34ee69b4ee6ab500a5db49cd146a4051451cd480514734556a0145145480fa29945002b5251473400514734da00f8d9a96976d0a95d0740bcd14fa28019453e8a00651cd3e8d9400ce68a5db4ea00653f65145001453b6d2d0026da5a5db4bcd00336d2d3b9a2801b4bb69db69d4011eda5e69f4500328a7d1400ca5db4ea76da8023db46da76ca76dab023db4ea76da6d4006ca3653e936d5811eda753b6d3b6d0047b28a936d1b6801bb68db4fa5db4011eda72a53b6d3b65400ddb4ed94edb4e54a008f653b6d48ab4ed941047b68db536da76da00876d3956a655a9162a0085529cb155858aa458a8021586a68edead476b56a3b7a9e6029c76b5623b5ad0b7b066fe1ad4b5d19a5fe1a9e6031edec377f0d6a5ae8cd2ff000d749a7f865bf896ba4b1d0e3897e65a449cad8f8719bf86ba0b1f0e2afde5ae823b558ba2d4db6802adbd8476ebf2ad5854a928a0a1bb69d4e5a5a00653e8a2800a773473473400734da773473401149f76bce7c65fea64af4693eed79cf8cbfd4c9401e7fb69b523252f340115376d4db69bb6802e693ff1f51d7b2786ff00e3cd6bc7f49ff8fa4af60f0dff00c79ad01236f9a28e68aad490a28a28d4028a28a352028a28a3500a28a5db46a02514fa28d4065145146a0235253a91a8d40f8e29f46ca76dad8e80db46da76da36d002514bb68db4011d1526da4a0028a2976d00376d2d3b9a2800e68e68a5db4009452eda75001b28a7d1400cd94fa77349b6801bb68db4edb4b500336d1b6a4db46da004e6936d3b6d1b680139a4db4edb4ed94011eda36d49b28d94011eda76da76ca76da008f6d3b653b6d3b6d0047b28d9526da76da008f6d1b6a6d94edb41043b69db6a654a76da008556a454a9162a9161a0085569db2a658aa65b7a00abe5548b155c8ed6ac2dad4019ab6f53476f5a4b65fecd5a874d66fe1a7cc064c76bfecd5c86cd9bf86b72df4666fe1adcd3fc3dbb6fcb53cc49cddbe92cdfc35b167e1c66fe1aec2c7c3f1aafccb5ad0d84712fcab480e56cfc33f77e5adeb3d0e3897eed6a2c4ab522ad0510c76eb154cab4ed9450014edb4b450014514ee6801b453b9a39a0039a39a39a2800a28a282428e68a39a008a4fbaf5e77e305fdcc95e8927ddaf3ff182fee64a0a3cfdbbd329edde8a006514fa2802de97ff001f51d7b0f877fe3cd6bc7f4bff008fa8ff00deaf60f0effc7aad012366956928aad490a7d1451a9014ca7d146a0328a7d146a01451451a805329f451a805329f451a80ca39a56a4e68d40f8ff9a45a5a2b63a05db46da751400ddb494fa28019453e8a006514f55a36500329f46ca76da006d1b29db69db6801bb69db69db69db2a0067349b6a4a36500328a976d1b6801b46ca76da7f340116ca2a4db46da006eda36d49b68db4011eda76da76da72ad0047b68db536da36d0047b69cab526da76da0821d94edb536ca3650043b69db6a655a76da00876d3b654cab4ef2a802155a9162a9961ab11dbd4015562ab0b6f56a3b7ab11dab37f0d3e6028adbd588ed6b423b066fe1ad2b5d2646fe1a9e603261b366fe1ad0b7d2d9bf86ba2b1f0fb7f12d6e5ae82abfc3480e4edf4366fe1ad6b5f0ff00f796baa874b55ab91daaaff0d0498f67a0c6bf796b5a1b55897e55ab0ab4ea0a2354a76da753e801946ca29f400514ee68e6800e68e68e68e6800e68a28a0039a39a28a090a28a282829f451412328a7d32801927dd15e7fe30ff53257a049f745707e325fdcc941479e514ea39a82c6d31bbd4bcd36802de9bff1f51ffbd5ebde1dff008f55af21d37fe3ea3ff7abd7bc3bff001eeb4112366956929ebdab5d490a28a282028a28a3500a28a7d1a80ca29f451a80ca7d1451a80ca29f4ca3500a8daa4a6b51a81f20eca29db6855ad8e8055a76da5e68a8019b68db526da36d0047b68db526da36d00376d3b6d253e8023db4edb4ea2801bb69cbda9f48b4006da5a5db4edb400ddb4bcd3f651b28206eda36d4b450033651b29f4bb68023d94edb4edb4e55a008d568db536ca3650043b69db6a4d946ca006eda76ca76da9156802355a76da936539568023db46da9952a458a802baad48b0d585b7ab11dbd401556dea45b7abd1dad5a86cf77f0d2e6033e3b5ab51d9d6a43a6b37f0d6a5ae8ccdfc353cc062dbe9acdfc35b167a334bfc35d058e83fde5adcb5d2d62fe1a6073f67e1ffef2d6d5ae8cb17f0d6b471aaff0d49b6802bc76aabfc3532a5494500376d3a9f4500329f451400514ab4bcd001cd1cd145001cd145140051451400514fa2800a28a282428a28a0a0a28a2824286ef4514011c9f76b83f187fa992bbc93ee9ae1fc609fb99a828f3b65a6eda99aa3a82c6eda6eda93650dde8026d37fe3e23ff007abd7bc3bff1eab5e47a7ffc7c2ffbd5ebbe1bff008f55a0891b14fa28ad752428a7d146a405329f451a80514ab4bcd1a80da28a28d4028a28a3500a28a28d406377a653dbbd328d40f9236d1b69d4559d0376d3a9db6968019453e8a00653b6d2d2eda006eda5a773450036976d3b6d3a8206eda36d49b6968019b29f452eda004a7734bb68db4009cd26da76da76ca006eda76ca3653ea0066ca72ad3b6d3b6d00376d1b6a455a76dab023db4ed9526da72ad0046ab4e54a9156a4586a008d569cb155858aa68e0a7cc05758aa68edeae476bbaaf5be9bbaa7980cf86d6af4361bbf86b5ad74b6feed6c59e8dfecd20306df4b66fe1ad6b5d0d9ff0086ba2b5d2557f86b5a1b3555fbb50061d9e82abf796b5adf4b8e2fe1abca952500471c5b6a4d9453b6d00368a7d1560329f451400514ee68e6801b4ee68e68a0039a28a2800a29f4500329f4514005145140051453e800a653e8a006514fa282428a28a002994fa2802293ee9ae1bc69ff001ef25772d5c4f8d13fd1e4a0a89e79cd1cd3d969950587351377ab1b2a36a00934ff00f8f85af5af0cff00c7bad793e9ff00f1f0b5eb1e19ff008f55a0891bd451456ba923e8a28a352029dcd1cd1cd1a807347347347346a01cd369dcd368d4028a28a3500a28a28d4046a8daa46a6b77a3503e4aa455a936d1b6ace81bb69db69d45040ddb49cd3e8d9400ddb46da76ca7d0033653b6d3f9a4db400ddb4edb4b4bb6801bb69db69db29db68023db4ed94edb4edb4011eca76da76da76da8023db4edb4edb4ed94011eda76da936d3b6d0046ab4edb522ad3956802354a76da9961a9162a00afb2a4586ac2c35623b7a5cc0575b7a9a3b7ab90d9b35695ae96cdfc353cc065c76ad5a16fa6b37f0d6e59e8dfecd6e59e86bfc4b4c0e76cf4766fe1adcb5d0ffd9ae82df4d55fe1ab8b6eabfc350064dbe92ab5a11d9aad5a55a750046a9526ca28a0029f45156014514ee6801b4ee68e68a0039a39a28a0028a28a0028a7d140051451400514fa2800a653e8a0028a28a0028a29dcd00368a28a0028a2976d0489453b9a6d001451450031bbd717e34ff8f792bb66ae2bc69ff1ef250544f3c65a36d48d49589b09b6a1916a7a8a4ab024d3ff00e3e56bd63c33ff001eab5e4f63ff001f095eade17f9ad68898c8dea72d2d15aea4853b9a39a39a352039a39a39a39a3500e68e68e68a3500e69b4ee68e68d4039a6d3b9a4db46a02514ee69b46a014ca735368d40f9476d369f4ee6acd466da5a5db46da004a773452ad00376d3b6d3a8a006eda76ca7d2eda008f653b6d3b6d3b6d0027349b6a4d946ca00652eda936d0ab400dd94edb4edb4edb400ddb46da93653b6d4011eda72ad48a9522ad0046a9522c5522a54cab46a591ac556238aa4862dd5a96760d27f0d47301461b5dd5a56ba5b37f0d6e58e87f7772d6f59e92abfc35247318363a1b36ddcb5b56ba4edfe1ada86cd57f86ad2c356067dbd82aff000d5e8e255a936d3aa006aad3a9f45001451450014514558053b9a39a39a0039a39a28a0039a2976d25001453e8a0028a28a0028a7d1400ca7d1450014514ee6801b4ee68e68e6800e68e68e68e682439a39a28e6800e68e68a2800a39a28a0039a39a28a0039a39a39a39a00635717e32ff8f792bb46ae37c65ff1ef250544f3fa2a5e69b589b0c65a864ab35048b400eb3ff5cb5ea5e17ff8f715e5f67feb96bd43c2bff1ef5713191d1d14515aea4853b9a45a5a352028a28a3500a28a28d4028e68a28d4039a39a28a3500e6936d2d1cd1a80c6a6d48d51d481f2a734734bb69db2b5351bb68db4ea7d00328d94e55a72a500376d3f9a5db46da006ad49b29cab4edb4011eca7d3f6d0ab400ddb46da9b6d3961a8021db4ed956162a162a0085569cb0d58586a45b7a00abe5549b6ad7d9bda8f2e8d40afb69cab526da76da352c6aad4d1aee6a6aad58b75f9aa40d2d36c3cd65aec34dd255557e5acbd06dd5f6d7696b16d8d6a080b7b355fe1ab8b12d0a95250035569db29f4500329f451400514515601453b9a39a0039a6d3b9a39a0039a39a39a39a090a7d32956ab501d4514548051451bbdeab500a29bba9d5203e8a62f6a7d0014ee69b45003b9a39a39a39a0039a28e68a0028a28a0028a28a0028a28a0028a28a0028a28a0028e68a28018d5c7f8cbfe3de4aec1ab91f187fc7bc94a4544e039a4db526ca2b23623db51b2d58d951c9400db5ff5cb5e99e15ff52b5e6b6ffeb96bd2bc2ffea56ae26323a5a28a55ad75245e68a39a28d480a28a28d4028a7d35a8d404a28a28d4028a28a3500a28a28d4046a8ea46a6b5481f2beda36d3b6d2d6a6a31569db6968a00555a7514e5a0036d39529cab4e55a006aad3b654cab4e55a802354a72c5532c35616de9f3015562a9962ab51dbd5a86cd9aa7980cf5b7a923b566adab7d2d9bf86b52d741ff66a7980e6e3d359bf86b42d746666fbb5d45be86bfddad2874d58bf86981c8c9a2ed8feed62dd5af94d5e8d796abe5d717ab45b666a0b30f6d1b6ac32d47b68021ab56bf7aa1db562dd7e6a803b2f0ea7cab5d85bfdd5ae3fc3bf756bb3b7fbab4104ebda8a29f400514515601453b9a39a801b453b9a39ab00e68e68e68e682439a28e68aad4028e68e69375002d15134aabfc558fe28f18e8de0bd1e4d5b5fd62c743d2e3fbd7ba95d476f0ff00df4cd46a06f6ea6b4b5f2d78dbfe0a21f0cf434923f0e43ab78eae17e55934db7fb2d9337fd7d5c6d56ff80ab57cf5e3cff82837c49f1379d0e80ba1f80ad5be5596da16d5af7fefe4db615ff80c6d5b46854911cc7e9547ba5fb8ad2ffbabba9b712fd97fd7fee3febab6dffd0abf1abc49f183c61e2f99a5d77c6fe2fd7b77fcb2bbd726b783fe030dbf96ab5c36a53e92f342b7962b7d71336d8e097cebc9a4ff007559999ab5faacbed48398fdc06d7b4d56dadaa69eadfdd6bc87ff008aab96b70b79ff001ef24773ff005c24593ff41afc365d22dbe50de08451fed5a5aab7fdf3bb755ab05d32dae5cdb699169b7b0eddcb1c325acf1ff77fd5b2ff00df4b47d53fbc5f31fb8ff32b6d2acadfed51bbdebf1df45f8d9f11bc3fb5748f88de32d3615fbb047ad49344bfeeadc7995df7873f6d2f8d7a0c9ff23e5aebd0ff00cf0f10e876b37fe4487cb6a8961661cc7ea56ef7a7d7c39e0bff00828a6b4be5c7e30f87505f47ff002d2f7c23a8fcdfef7d96eb6b7fc0564afa23e1cfed4bf0bfe285c4363a4f8aa0d3f5a93fe609aec6da6deeefeeac736df33fed9b35632a72888f5ba55a195a26daeacadfed52f3597317ca1451cd14c90a28a2800a29f4ca0029f451400ca29f4556a0328a28a3500a28a28d4046ae3fc61ff1ef25760d5c8f8c3fe3de4a89151384a28a773591b0da8a4a9f9a8a4a008edffd72d7a5785ffd4ad79cdbff00ac5af46f0bff00ab5ab898c8e96956929dcd6ba921451451a901453e8a3500a28a28d4028a29946a03dbbd328a56a350128a28a35011a9ad4e6a8dbbd1a81f2fd1453eacd466ca76da76da76da801bb69cab4ed9522a5003556a655a156a68d6801aa9532c55247155c86d7752e602bc76f57adecd9bf86ae5ae96ccd5bd67a4ff007969018f6ba5eedbf2d6c5ae8dfde5ad8b7b055fe1abd1dad0067dbe9aabfc35a10d9aad5a8e3db532ad0042b6eab4ef2ea7a6377a80337505fddb570babff00c7c35779a97fab6ae1758ff5cd417131e4a86ac377a85a82c6ecab10afcd50ad4d6ff7a803b0f0efdd5aec2dfeed71fe1ffbab5d95bffab5a0c49a9f4c5ed4fa0028a29dcd001cd1cd1cd1cd001cd1cd1cd1cd5921cd1cd1cd1cd56a01cd26ea6eea8da5feeffbd5203a46db5c6fc4cf8b5e13f847a0ff006c78c35eb5d06c5be587cf6dd35c37f761857f79237fbab5f327ed1bff000506d23c1b25df87fe198b3f12eb91b3433ebf73fbcd32cdbf896155ff008fa917fd9fddaff79beed7e78f8cbc7dacf8f3c4375aef88f56bcf11eb771f2c9a86a526e936ff007557eec71ffd335dab5db4b0b2a9ef48c255394fb0fe317fc14ab56d6669b4bf86da5ff60dbfddfed9d52dd6f2fe4ff6a3b5ff00530ffdb4691bfd9af923c53e2ed73c75ad36b1e219affc41ac37fcc43c437de748bfeeab7cb1affb2aab5cc2ea522aed56f2a3feeafcab42dc3357a51a54e9fc261cdcc6c35c5f5c36e964b5ddfed49249ff00b2d397ed5ff3d2d5bfe032563c379e6b32dbc6d7322fdef2feeaff00bcdf756af4705c48bfe9170d12ff00cf0b46dbff007d49f7bfef9db57735d492e2fe4b06559e6b6591beec6b236e6ff80eddd59c9e31b8f0feb1f6c7d26f2686687ecf27eed95b6eeddb95bff656ad7b78a1b3565b78638377dedabf337fbcdfc54dbebcfb058cd71f7a4fbb1aff0079beeaaffdf5521a976cbe215aea0adf63d2b58b8dbf7952cd7e5ff79b76da648da86a9a92de5c69b756d6f1c3e4c70c1346d336e6dccccaadbbfe02bfed549a6daff65e9f0daeedccbf348dfde91be666ab1bf6d1ca591dbdbe8b792346b676b2dc2fde8ee6366917fde593e6ab4ba4e96bff00307d3bff0001569b235bdfc6b1de46b3aafddf3d7cc55ff75bef2ffc0685b792d555ade6f363ff009e77326e56ff00766fbcbfeeb6eff80d41658fecbd2f6ffc81f4ff00f80dbedffd069d3693a3de5afd9e7b16fb3ffcf38eea655ffbe7732ffe3b50dbde47713343b6482e957735b48bb6455fef7fb4bfed2fcb562803d27e18fc72f889f08d61b7f08fc43d620d363ff983ebbb754b2dbfdd58e4dad1ff00c0596beb1f85ff00f0510b7b858ed7e23f85db4ffef6bbe14f32f2d3fde92d5bfd2235ff0077ccaf80daa486fe6b5915919b72fddaca5423507ee9fb53e0ff001b787be21f87edf5df0beb563e20d1a6ff005779a6ccb347bbfbadfdd6ff0065b6b56d57e347817e276b5e03f117f6ef86f58bcf0d6bcdfeb2fb4fdbfe94bfddb885bf7770bfecc8bbbfbad5f7a7ecfbfb71693e3eb8b1f0f78fe2b3f0b7892e1961b3d5ad99974ad4a4fe18f749f35accdff3c64f95bf859beed79f5284a9fc23e63ea3a7d0cad1332b2ed65fe1a2b9c61451450014514500145145001451450014ca7d14011b5723e30ff8f792bae6ae47c61ff1ef2529151386e68a55a75646c3298d536ca8da801b6ffeb16bd13c2ffead6bcf61ff0058b5e85e19ff0056b5713191d2d3b9a39a2b5d490a28a28d4029f4ca7d1a9014514ca3501f4ca28a3500a28e693751a80b47348cd51b351a80e6a6b354725c2aaee66db546e3568e2fbbf35007cebb69cab4ea72ad0740dd94e55a76da72ad0406da72ad3956a455a350055ab51c54d8e2abd6f6fb9aa2522c7436fbab734dd2f77ccd4ed3ecd7bd745676aaaabb6a481b6ba6aaff000d6a436f4e862ab0ab400d58aa655a72ad395680055a72d2f3473400734c6a7f34c6a0b32f52ff0056d5c2ea9feb9abbad4bfd5b570baa7fae6a02265b77a8daa66a8d9682c6aa54d0f5a8d56ac43f7a803acf0fff00ab5aec2dbeead725a0fdd5aebe1fbab4189253e994fa0029dcd1cd1cd001cd1cd1cd1cd001cd1cd1cd22d6ba922f34c66a733563f88bc41a7f86b45d4356d5efa2d3749d3eddaeaf2eee5b6c70c2abb999aa408fc51e2ad27c1be1fd435cd7b52b6d2345d3e3f3aeafaee4db1c2bfe7eeafde6fe1afcc2fdab3f6d8d5fe344d75e1df0e7dabc3ff0f7fd5b5b37eeef758ff6aeb6ff00ab87fbb0afdeff00969fdd5e67f6a9fda9f54f8fde25529e7e9fe0dd3e4dda2e8f27cacdff004f970bfc5337f0affcb356fef6e6af9dae2e9a566666f9abd8c361797de99c752aff002935c5e34bb57eeaaaed555f95557fbb55777bd42d2d10c4d78bbb73456ffde5fbd27fbbff00c557a0737c448b70d2c9e5c11b4b27f12afdd5ff0079bf86ae5bd8ab2ffa449e6ffd335f963ffeca8876c51ac68ab146bfc2b56165ace46b12f42db55557e555fbaabf756ac2b566c6d56a36a9352e6eaaea9f6fd7ace0ff009676ead7927fbdf763ff00c7b737fc06a48da9be1ff9a1bebefe2ba9b6c7ff005ce3f957ff00666a91c4d66969bbaa1dd4e56a0a27e69159a26dc8db7ff66a8f77bd3b75051619a1bf8e386e235fddb6e8fe6dbb5bfbd1b7de8da9df6892c15bed0cd3dbafdeb9dbb6487febb2aff0ff00d345ff00812afdeaa6ddea6b7bc92d597ef32afdddbf797fdda5288f98bcdff8efdea6b553685ac17ceb28fcfb36f99ad235fbbfde6857ff00428ffef9feed5886e23ba8639a091658645dcacbfc4b531281aad5aea1b239219e359ed645f2e48e45dcacbfdd65fe25aaf4cab03ecdfd967f6d2b8f02ad9f84fe20df49a8f83576c363e249a4692e7465fbab1dd37de92d7f8566fbd1ff0016e5f997f4115959559595a365565656dcacadf7595bf896bf0d6cefa4b0996446ff00797fbd5f5e7ec71fb5837c37b9d3bc11e2cbcdfe02bc996d74bd4266f9b409a46f961919bfe5d19be556ff00962cdb7eefddf3ebd0fb510f84fd10a29d22b44ccacbf32d36bcf2c28a28aad4028a28a900a28a2ab500a28a2a406b7ddae3fc5dfea64aeb9ab92f177fab92948a89c32fdea996a35fbd52d646c23543254fcd452500361ff58b5e85e175fdcad79fc3f7d6bd03c33fead6ae26323a5e68a39a2b5d490a28a28d4029f4ca28d480a28a4dd400b48d4d66aaf35e4717de6a4058dd4d6976d63dd6b8abf73e5ac7bcd6777593754f30729d15c6a90c5fc5b9bfd9acbbad79bf859625ff00c7ab9b9b5466fbbf2d5192e99bf8aa798d794dcb8d67e6fbcccdfed566dc6a9237f1567b4b51b3549670fb69ca9526ca156b7201569cab4e54a72ad1a960ab56235a8d56ac46b5204d0c55a9676f54e15ad8b35fbb5006b69f16ddb5bd6e959766b5b16eb4105a8d6a655a6c7522d000b4fe68a2800e68a39a39a0b0e698d4fe6a26ef40197a97fab6ae1752ff008f86aee354ff00575c3ea1feb9a808945a9295a9282c45a9e1fbd50d4f0f5a803acd057e55aeba1fbb5c9e83fead2bac87eed598922f6a7d317b53e801dcd1cd1cd1cd001cd1cd1cd1cd5921cd319a96a291aab501b24bfddfbdfddafcd8fdbfbf698ff84dbc4575f0d7c3f74afe17d12ebfe275731b7cba96a11ffcbbff00b50c2df7bfbd27fbb5f50feda1fb4149f02be16f97a35d2c5e34f11349a7e8bfdeb55dbfbebcdbff004cd5be5ffa68cb5f917a85c2aaac31337971ff001336e66ff69bfdafe2af4b07479bf792396acfec90de5e35c48cccdf3551925a6c8dbaa38d56e1bcc93e6b756f957fe7a37ff135eac8e1f8892de25ba5f327ff008f7fe15ff9e9ff00d8d5ef37736e6fff0066aab4accdb9a856a9d4a2e2b55856aa71b5588ea4da25a8eac4755636ab51d41a86a174d67a7dc4cbfeb163f97fdefe1ffc7ab5adedd6c2c6decd7eec31ac758f72be74da7db8e164b8566ff763fde7fecab5ad236e6a0711dbbde9cad51eea3754944dba8dd50eea37503e62c6ea4a8b77bd3b750226b7b86b56fef46df797ff00665ff6a9b70dfd973497d17cd6727ef2e9557eeffd3c2aff00e8c5ff00815329f6f71e548aacdb1777fdf3414687fbbb597ef2b2ff001527359967ff0012bba5b2fbb6b36e6b5ffa66cbf7a1ff0080fde5ff0067fddad1a002a7b3bd5b5919648d67b3995a3b8864f99648dbef2b555ddef4ddd417cc7e96fec23f1e27f17f86dfe1cf882fdaf35cd06d16e348beba7dd2ea3a67dd5dcdfc535bb6d8dbfbcad1b57d5b5f89ff000f7c65ac784b5cd2f52d06f3fb3fc41a3dc7dbb49b96fbab27dd68e4fef4722ee8d97fbadfecd7ebe7c1bf8a9a5fc6af86fa2f8c74a8dada2d42365b8b176fdeda5cc6db6681bfda8e4565ff00776b7f157915e9f2cb98a89da514fa2b0d461451451a80ca29f4ca3500a28a2a408dab91f167fab92bae6fbb5c7f8abfd5c94a4544e3569f48b4b591b0ad50c9533543250016ff00eb16bd0bc36bfbb5af3fb7ff0058b5e85e1dff00562ae26323a05a5a45a5ad752428a4dd4d6976d1a903f9a4dd5466d4a38ab36eb5cfeeed5a8e6037249557ef35519b568d7eefcd5cbde6b9bbf8b7566cdab48df76a798be53a6bcd73e5fbdb6b16eb59feeb6eac592e99bef3546cd525729726bf925fe2aaad2d47ba929162b3535a968a006535aa5a4db5259c852eda5e6956bab52072f6a72ad0b4e54a901cb56a15a8556ae5bad005a856b62c52b36dd6b62c56a00d8b35fbb5ad0ad66daafddad4b7a082d2f6a9169ab4fa0028a7d1400ca29f4500339a89bbd4b4c928031f54fbb5c4df7fae6aed354fbad5c76a1feb9a82e267352734f6ef4ca82c39a9e1fbd5054f6ff7a803aed0feead7551fddae5743fbab5d443f76acc4997b53e98bdaa5e6800e68e68e68e6ac039a39a291a8246b55591bfbccb12fde666fbaabfde6ab1257cd7fb7b7c559be19fecf7aa5a69d71e4eb9e2c997c3f6722fde8e39159ae24ff0080c2acbbbfe9a2d694e3cd2e52252e589f9eff00b537c706f8e1f16f59f1441237f6242bfd95a146dfc3631b37ef7fde9a4dd27fbbb6bc2e6977d5cd4a555db1a2ed8e355555feeaafddacb9a55895a46fbab5f4918f2c794f3652e62391bcd93c956dbbbe666feead48d2fdddabb557e5555fe1a857744bb5bfd637cd27fbdfddff0080d359a81136ea9165aabbbde9b26e68f6ad2d40bd0ea50b4de5f98bbbeeff00c0ab4a36ae7edd667b786dcc3e5c71b2ee6ddfddfeed6c472d497134236ab11b5518daad46d506a4d0beed617fe98dbffe3d237ff12b57bcdf9ab374f6dd71a849ff004d9635ff0080afff0014cd56b75059695a9dbaabab53b7548132b567c7a94d710b5c456bbad7e6656f33f78cabfc4ab57376dacf5d2ee228da1b7bc5821fbabba1dcd1affb2dbbff0042a00d68655b886391195a391559597f89696a2b5823b5b78618976c71aac6bfeead4b415a8f5ed4377a65140c9e489752b3685a4f2a4f976c9ff3ce45ff005727fecb4eb3bc6bab7dcf1f9570acd1cd1ffcf3917ef2ff009fe16a8636f2a4ddfc3fc5feed36ebfd0f528e6ff96375b6de4ffae8bfeadbfe04bb97fef9a00b8cd4dddef4d66a6eea0a268e568a45917ef2d7dadff04f4f8a5fd8df12355f06dc4db74df165bb6a566acdf2c7a95bafef957febb5bfcdfef435f12735d8fc35f1a5d780f5cd37c4967bbed9e1bd42df5a8557f89616fdf2ff00c0a16917fe0559558f3479468fdb25ed4faad67796f7f6f0dd59c8b3d9dc46b716f22ff146cbb95bfef965ab35e2c4d428a28a7a805329f4ca900a28a650023571fe2afbb35760d5c7f8abeecd4a4544e3d6a4a6ad3ab0361ad50b77a99aa36aa00b7ff58b5e81e1bff56b5e7f1fcad5d768fa97d9e15ab898c8ecf72d4525e46bf79ab9bb8d7be5fbd58f75ae337dd6aae62794eb2e35c8e2fbb58f79af6efe2ae664d4a497f8aabb5c3354f315ca6c5c6b3bbeed66cd78d2fde6aa6cd4b505728ad2d3775369cb41a0b45145001452eda72c5410329552a68edf755c86c19a8028ac5baa68ecd9bf86b6ad749ddfc35ad6ba37f7968e52398f16a95696956b62c16a455a6aad4ca940046b57a15aaf1ad5e856a0b2e5ba56c59afcb5976eb5b166b4106a5aad6a5bd67daad6943410588e9f4c8ea6a0028a29f4009b68db4b450031bbd43254cddea1928031f54fbad5c66a1feb9abb3d53eeb57177dfeb9a82e2516ef4ddb523536a0b19566dbef543535b7dea00ebb45fbab5d343f76b9bd17fd5ad7490fddab312c2d3f9a62d3f9a0039a39a46a5e6800a46fbb4b4c6ab24864fbb5f997ff052af1d37883e3768be178a457b3f0be8be748aadf76f2f5b737fe418e3ff00beabf4d193ed122c6bf7a46db5f8a3fb4278cbfe13cf8d1f123c481b7477de20ba8eddbfbd6f6ffe8f0ffe3b1d77e0e3cd5398c2bcbdd3c86f26f36691bfdaaa7f7a4dcdf763ff00d0aac5d32c4accdf757e6aabf3450aab7defbcdfef57b279c3646f9aa3dd43525050bba9cb4ca456a5a816a36ab11cb5455a9cb2d481b10cb572ddb732d61c73d5e8eeb6aeefeeaeea0d6322f6932ffa0eeff9e924927fdf4cd5715ab274d976e9f6abff004cd6af472d417191715a9cad55d5aa456a92cb0ad522b55756a916802c2b53f9a897b53b75056a3f9a4dd494cddef406a4bcd2cd6bfda9a5dc5aab6d91976c6dfdd6fbd1b7fdf551eea92d5b6cdb7fbdf2d02891e9f79f6fb1b7b8fbbe62ee65feeb7f12ff00df5566a958ff00a3de6a56ff007556e3ce8ffdd91777fe85baaed050ab5a5a0dc2dbea90f9bf34326e8e45fef2b566eea72b6d91597f85a828fd70fd8a7c61378c3f669f07fdaa4f36fb4559bc3f70cdf799ace468d5bfefdf975eeb5f167fc1367c4df68d17e22787da4ff537d63ad431ff00b3716fe4c9ff00912d7ff1eafb496bc3ab1e5a92358fc22d145153a8c6514fa6549414d6a75328011ab8df157dd9abb26fbb5c6f8a7eec9512089c951451591b052352d2355011ff00155a8ee1957ef555a7d004b25c33546cd49450026ea6d1450014514fa00653968db522c4cd400d54a9162dd56adecd9ab52df4bff6682398c986cd9ab421d37fd9adcb5d19bfbb5a96fa4aafdeaae52398e7ed749ddfc35b16ba32afdead68edd557e55a936d5f2925786ce3897e55a9b6549b692981f3c6da72ad3b6539568351ca9532ad11ad4cab505846b572dd2abaa55cb7a00d0b75fbb5a96f59b6ff00c35a96f4106a5bd6943f76b36d6b4a1fbb410585a929b1d397b5003e8a29dcd001cd1cd1cd1cd0031aabc9561aa1928031752fba2b8dbe5fdf35765a9571f7dfeb9aa0b8945aa36ef523546dde82c2ac5bfdeaaf535b7de5a00ec345ff0056b5d243f76b9bd17fd5ad7490fddab312c2d3f9a62d3b75000d42d0d4bcd580531a866a8d9a824e77c7de288fc11e09f12788a5ff0057a3e9775a87fdf985a4ff00d96bf0a9999742d35656679a48566919bef3349fbc6ffd0abf5fff006def11ff00c239fb28fc4cb81feb2e34b5d3e3ff007ae268e1ff00d0646afc85f116d5baf2d7eec6bb57fe03f2d7ad818fbb291c75e473b79f36d8ff00bccabffb3557b86dd235586ff8f85ff6559aa9c9f7857a4718ca6539a9682865145140053b75368a5a80e56a924b8db6f37fbadffa0d434cb8ff008f79bfdd6a90366de5db0c6bfdd555ab90dc563acbf2ad4d1cb417cc6e4371baad2b562c37157a1b8a8358c8d056a915aa9c6d5615aa4b2d2b53b755756a93750049ba9299ba8dd400fa5ddb5b77f76a3dd46ea0092e3f75af46dfc335aedffbf727ff0013255addef546e9b75d69727fd34923ffbea3ffed756e82b51f4edd4d5ed45033ec4ff008274eb9f60f8e9369fbbe5d5bc2b751edfef35add4722ffe3b3495fa48bdabf28ff61fd49acff698f86ff37cb70bab59b7fc0acf77fed3afd5c8ebc6c47f10d624bcd369dcd31ab02c6d14547ba8285a298d2edaaf35fc71fde6a092c48df2d717e2a955bccad6bed71555b6d71faa5fb5d48d59ca4544a145369dcd49b051cd1450031a9691a96800a28a5db4011d1532c5534766cdfc340b98aea953476ecf5a16fa4b356c5ae8dfecd04f31836fa6b37f0d6b59e8cccdf76ba4b3d25625f996b4a3b555fe1aae52398c7b3d0d57ef2d6a47a7c71745ab4ab4ed95a1242b16da76da928aad40651453e8d40652352d235481f3faa548ab4e55a9156a0e8055a99529aab522d000b572deabaad5a856a00d0b7ad2b7acfb7ad2b7ab20d4b7ad086b3edeb421fbb4105a5a96a25a96801dcd1cd1cd1cd001473451400da826ab0d5566a00c5d46b91d43fd73575da8d7237dff001f0d505c4a2d51b77a91aa36ef4161535b7dea86a487ef500761a3ff00ab5ae9a1fbb5cbe8bf756ba587eed59896d68dd4d5ed4d66a0076ef7a377bd42cdb6abcd74abf79aac0b4d2aad579af2355dccdb6b9dd53c4d1dbee556dcd5c7eade2892e376e6dabfdda00f26ff0082877886193f66bd42d636dcb75ade976edff811e67fed3afcbad71b75d48d5f7d7ede1abb4df036c61ff9e9e26d3fff001d599abe01d53e699abdbc0fc079f5fe2315bfd65c37f776aff9ff00beaaab558ff97799bfbd337ff1355dabb4e512994fa6505051453296a03e9ad49451a80734c9be6864ff0075a9cd4d6fbad5205856a915aa15fbab4e5a00b91cb572196b355aac46d4166d432d5a8dab1ede5ad08daa0d6322f2b548ad5555aa656a92c93753b77bd47ba979a007eef7a6b5273473400b337ee6cffd9b88ff00f665ff00d9aaf2d66c8dfe8ffeecd1b7fe3cb5a0b5456a3e9f51eea76ea919ee5fb22dd7d9ff00686f84edbbfe660921ff00bf96770b5fae90fdd5afc79fd95e6dbf1fbe13ff00d8d56fff008f4370b5fb011caaab5e562bf886b12e6ea6b35539b528e2fbcd59379af2ff000572166c4d74b17de6acdb8d6557eed73b79ae6efbcd58b75a934bf75aa398ae53a4baf107fb559375ae337ddac56b86a85a5a82b94b926a0d2ff155566dcd4ca55a0d07548b4d5a7d0014514bb680139a555a36eeab56b6ad2b7cb4010c716eab90d8337f0d6a59e92cdfc3f356f59e83fc4ff2d063cc73f6fa5eefe1ad8b5d07fbcbb6b7a1b38e25f956ac2ad5729266dbe971c557a3b755fbab53515a00d55a7514556a014fa65146a01453e9946a405145146a03291a9691aa4b3c1f6d48ab4edb42d41d0396a45ed4d5a96a0055ab50d555ab90d00685bd685bd67c35a56f5641a56f5a50f4acdb7ad283eed041697b548b51af6a979a0028a28a0028a28a0046aab37dd6ab4d55e6fbb40187a8d7237dfeb9ff00deaebb52ae46fbfd735417128b546ddea46a8dbbd058ca9edfef542b535bfde5a00ec345fbab5d147f74573ba2fdd5ae8a3fba2acc49b754324bb68925db587aa6acb6f1b7cd40126a5acc76bfc5f3571fac789a46dcbe67cb59fad6b3b99be6ae4efaff0076ef9aac0d0bed659b77cd58775a9337f1551b8baff6ab3e6baab8c4be53c37f6dcbaf37e15f87e3fef789ad5bfef9b7b8af8a6fbe699bfdeafb1bf6ce6697e1bf86ff00babe2287ff0049ee2be37b8fbdbabdac1ff0cf2f11fc430f77fa2aff00b4ccdff8f3545cd3d7fe3ca3ff0076a36aeb3984a653e994005329f4ca5a941451454805237dd6a5e691beeb556a03a3ff0056bfeed48b51c7fead7fdda72f6a90245a9a36a8b9a7ab50597236ad0b79772d64c6d56a1976b5006c46d522b5538daac2b541a96377bd3b7542b4e5a92c9691a9b4377a006ccdfe8b37fb3b5bff001eabdbab366ff8f5b8ff00757ff42abdbbe6aa02c2b53b7542ad4edd5256a7ad7ecc2ccffb407c2bc7f0f8aad64ffbe63b866afd609b5ef97ef57e56fec9712cbfb407c3ff009776dbabcbcff77c9b19b6ff00e3cd5fa3df6a66af1f152fde1d34e3cd13a0b8d7377f1567dc6a4cdfc559be751bab8798d3949a4959aa366a6eea5a93413752d26da7f34008b522f6a654ab540396969569d40051453e801235f9abaef0fe96b2aee6ae66d57f78b5dd78757f73444c646b436ab12fc8aab536ca72d2d6c489b69b4fa2ab5019453e8a3500a28a28d480a28a28d40291a968a35019453e9946a03291a9691a8d4b3c439a55a36d397b5739d00bdaa5e698ab522d000b572deaaaf6ab90d005eb7ad2b7acfb7ad0b7a0834adeb461fbb542deb4a1fbb564132f6a979a62d3f9a0028a28a0028a7d14011b5579aac35579a8030f52fbb5c8de7fac6aec352fba2b91beff0058d5122e267c950b54d2542d41aea0b5343f796a0a960fbcb406a761a3b7cab5d12b6d8eb95d1e5f956b6aeaf16de1dccd567395f58d516d636f9be6ae0756d59a4ddf355af106ade6b37cd5c7df5d6edd56595f50bfdccdf3562dc5c6ea75d5c6e6acf91aae312b948e696aac8d5248d55646aa2cf18fdae61fb47c25b39bfe7df5eb193fefaf323ffd9abe30bcf97757dc7fb49d8b6a1f04fc49b577b59fd96fbfe030dc46cdff008eeeaf88b545db7532ff00b4d5ec60ff008723cbc547de39b5ff008f387feb9ad46d5347ff001ef0ff00bab51b2d759c632994fa65048535a9d45050ca28a296a01cd27f0d0b4b46a02c7fead7fdda75363ff56b4ea3501dba9cad51d146a05a8daac46d54e36ab11b54966942df2d5c8dab3616ab91b505c4b8ad4e5a855aa456a8351f4ad494ad4011c9ff001eb71feeaffe8556bf8aa949ff001ef37fc07ff42ab2adf350058ddef446ad7570b6e9bb737dedbfc2b55fcd676f2d17749fdda6ea5aa7f60d9f93037fc4c2ebeec9ff003cd7fe7a7ff13ffd8d495a9f45fec7ba71b8f8f1a05ea0dd05be9bac797b47f7163859bfefa936ff00c07fdaafbfe16f96be3dfd8dff0065fbbbcf87ba778c359d7b5ff0d5d5e43247a1c7e1fbbfb2cf1d9bc9e634d236d6dde632ab2ab7cbb557fbd5f51783ef354b3d4b54f0cf882f23d4f58d2e386ea1d4961587fb4ac66dcb1ccd1afcab22c91c91c9b7e5dcaacbb776daf9faf5633a92e53d48d29469c652fb4754ab4edb4e55a4ae72039a6d3da9aaacd40094f55a9a3b566fe1ab90e96cdfc34014562a936d6a7f65b7f76aadd5bb45542e62baf6a72d376548b40c4a55a5e68e68027b5ff58b5dd787ff00d4d7076bfeb96bbcf0ff00fa9ab898c8dc5a5a28ab2428a28aad4028a28a3500a29dcd1cd1a90368a28a3500a291a968d406514fa651a9635a939a7b77a65481e254e5a36d396b13a016a4a653e801cb5721aaab56a1a00bd0d685bd67dbd695bad590695bd694359f6b5a10d0416169fcd22d2d0014fa28a0028a28a006b5579aac35579a8030f52fba2b91bbff0058d5d76a9f76b8fbcff58d5122e25392a16ef533546d41637650bf7a8a8f7fcd415a9bda6dc795557c41ae7cbb55aa8fdb3ecf1eeae7752bc69646ab89911de5e337f1562de5c549717159b712d6d18965799b755591a9d34b55d9aa8ad46c8d55646a9246aab23500723f10352b5bad36f3c36d6375abdd6ad63342d6969e5af970c8be5f992348caaabb9be5fef32fcbf75abe05d412689956e2368aea3fdcdc46dfc3247f2c8bff007d2b57d95ab78d2c744f137892eb54f322b7bad5bfb3d6eff86de1b78638d59bfe99f9d24dfeeee66af97fe33e92349f8a5e2bb31f2afdbbed03fdd9a38e4ffd099abb70757f7b28118ea1cb42357ed1e6b6ebfe8f1ffbbb6865a734525bb36d556566ddf7b6d46d249ff3efff009116bd63c2236a6b50cd37f0c71aff00bcd51b79cdfc512ffc07752d40751b2a3f2a4fe2b893fe02aab4dfb2aff134adfef48d46a04ccbfdea8da58d7ac91ffdf54dfb2c3ff3c57fe05f3548b146bf7638d7fe0346a047f6a87fe7a2d2fdaa1fef7fe3ad52fcd451a810add42aabfbcffc75a8fb65bffcf4ff00c75aacd152056fb55bff00cf68e9cb710ffcf68ffefaab1b6a68ecda5fe1aad40af1b47ff3d23ffbe96ad43f37dd656ff81558874687f8a356ff0080d5e5d1ecdbef5ac0dfef46b51cc6b1895ede391beead5c8ede4feeb51fd83a7b7fcb9c1ff015db4a9a059aff00ab5962ff00ae73c8bffb354f317ca4aaad532ab542ba32afdcbebe5ffb6dbbff00425a77f65dc2fddd52ebfe051c6dff00b2d0593d2b557fb1de2ffcc5246ff7ade3a77d96fbfe820bff0080abff00c55003a45668d957f8b6d48b17de67936aff0016df97ff001ea8fecb74df7afbfefddbaaff00f1559fae59c36fa2cd237993cd232c6ad3b6efbcdfc3ff008f500497de26b7b38fcbb28d6766fbadff002cf77fecd577e15f81ee3e287c50d03409e4925fed4bc55ba93f8bc95fbdfeefcbf2ff00c0ab9686dd776e6fbcd5f4b7ec29636e3e36aead77b62b3d2eddae269dfeec30c6b24d349ff01586b93153953a52944e8c1c2356bc54be13ee0f8f5e268fc3f67a4f80f439bec77135bac975f666dad6fa7c3fbb58d597eef98cbe5aff00b2b2565f84fc4d752eadf0ff0056bc91a599ae2fbc2b75237de9239a1fb55aeeff006964b5dbff0002ff006ab9dd1fc3f79e3ab893e205ec724579ac5d335c40dff2c6d59556d63ffb62ab1ffc0a492af5d2c9a0e82caabfbcb1f1468374bff02be8e16ffc7646af9084bf7d147d9d7a71faa4bf98f768fe6fbb5623819ab4a1d2596665dbf75b6d6c59e87bbf86bd23e5a523061d359bf86b42df49ff0066ba8b7d0d57ef56843611c5fc355ca4f31cddae87bbf86b62df438d7fd656a2aaad3f9a394833ae2ce358fe55ae475e8b6d77532fcad5c6f8897ff42a722e273bb69cab4e6ef42f6a82c6eda4a7d140125aafef96bbcf0fff00a9ae1ecffd62d775a1ff00a9ab898c8d9a28a2b5d490a28a77346a0368a77347346a01cd369dcd1cd1a80734da7734da352028a28a3500a653e9946a585329f4ca903c59a979a2956b13a072f6a7d22d3f9a0045ab90d555ab90d005cb7ad2b7fe1ace87eed68dbd041a96f5a10d67dbd6943564132d3969ab5250014514505851451400d6aaf35586aaf374a0830f54fe2ae46ebfd63575daa7dd6ae46ebfd635417129c950b54cddea16a0d75236a8646db523553ba9762d04956faebe5ac3b896ad5d4bb9ab2ee1ab7890579a5aa33354d3355399ab435d4af23542cd4e91aa166ab02399aabc8df37cd52355793ee8a0b3c27c5d6b1dfade472fcdb756d42393ff0002a4ff00d9596be6af181bd1e25d52d6fe432c96021b24671f37931c6be5eefef6d5655ff7556bea5f1259b45ae78b2d597eeeb0b791ff00d73b8b7864ff00d0964af9bfe2c4622f891e27c7fcfc42adfef7d9e3aac0ff001e513a332f7b054e5e879fdc5556ab537de6aaed5ef1f2846ddea36a91bbd46d4b5012994fa4db46a0368a76da36d1a80da7d14f55a3501bb6a68e2666f956a6b7b5ddf7beed684712aaed55a92cab6f61fdfad08e2d9f76855a9952a0be5054a99569abdaa45a92872d48b4d55a7d058ab4b48b4b400514514008cdb6b0fc552eefb0daaffb5337fe82bffa1356c37ccdb6b99bcb85bcd52e26fe1dde5c7feeafff0065baa8521d6ebfbcff006557757d31fb32e97f67f01cd0aaff00c4cbc6da84962abfc51e930b47f6a93fdd91956dd7fde93fbb5f31de37d96ce4dbfeb24dab5f58fc0ff0aea9e18d0ec6fa70f6f74d6f1adbaf99ff001ef0afccaaadfc3f33348dfed48d5e566353969729ed6514bda5591f7af86f4958f495b778f6accbf32edae07e225afd96d6ea375f9a6bad1d7fe04bac59edab1f0afc7dab6a975f65d5265b95dabb6465559377f75b6fdeaeb3c65a1c3acf8b3c1f62ebbbedde24d3d76ffd33b766be93ff001db55ffbeabe729479a513dcc64a54e9ce323df3fb2e18ae26f97fe5a37fe8556a3b755fbab4e8fe6fbdf79aa655af5627cbc88f6d254ad4da6111ab494fa6b50591cdf76b8df117fecd5d94df76b8ff00117f1544888981453b9a6d41b0514ee69b4013d9ff00ac5aee343ff535c3d9ff00ae5aef345ff535713191ab4514ee6b5d491b4ee68e68e68d4039a39a39a39a3500e68e68e68e68d4039a6d3b9a6d1a805145146a405145146a032994fa6549678bd3e8a72d627402d3f9a39a45a00917b55a86aaaf6ab90d005b87eed68dbd5186b42de820d4b5ad28eb36d6b4a3ab209969d4d5a750014514505851451400d6aaf374ab0d504df768030b54fe2ae46ebfd63575da9756ae46ebef35415128c950b77a9a4aaf23505ea43337cb58f7d715a1752fcb58774db9ab589255b896b36e1aad4cd54666ad2205591aaaccd5624aa7256a56a432355791aa692abb50046ddea16a924a85bbd059e7fe32d3557c696337fcb3d5b4f92cff00ede2d59a68ff00efa8e49bfefdd7c8bf1526f37e2278b1bfea2922ff00df2aabff00b2d7da1f10acee2ebc337171651b4ba9697347ab59aaff001496edbbcbff008147e647ff0002af8a7e235e5aea5e38f125d5948b3d9dc6a57134322ff146d26e5ffc76baf071fdeca4638cabfecf18799c5c9f7aabb5589bef5576af54f088dbbd35a9d4377a008da929dcd26da004a2976d4d1dbee6a5a811c6bbaaf436ff00dea921b755ab0ab5258d8d6a65a6aad4cab4163956a45a6ad48bdaa0a245a72d356a45ed5258e5a7f348b4b4005145140052352d4537f757ef37cb400d5b79aeb6c76fff001f57122dbc3fef37f17fc07e66ff0080d49e3af07b7872d74fbe82364b166f255b6fdedadb7757a67c07f86975e3ef187976f0c92c7671b471ed5fbd332ee6ff00be63dabff6d2bd43f6cdf86f0f81fe1fe87a7c11aedd3f4bb78e693fbd7125e348cdff007d37fdf35e64f15cb5e34e27ad4f0bcd8695497f563e7df81bf0caf3e2c7c44874db787cf86c616d42ea3fef2ab2aed5ff0069b757db5ac787e4d19b6ed55dadb76d711ff04f0f06ff0065f863c53e30b95d9fda170b630337fcf1857737fe446ffc76bd27c69aa4dab78db56d2ec216bcb85ba86d61817fe5a5c347f347ff00016fbdfddf9bfbb5e3e6153da55e5fe53dcca63ec697f8b53a8f82fa5b5feacb37fcb18e4f99bfddaf66d06cff00b67e35683f2ee8743d16f35691bfbb35dc8b6b0ffe4386ebfefaac9f03f856d7c1be1db7d37ed117990c3bafb506f95557ef48dfeeeedcdffecd75ff00046cdf52d2f58f19dc42f049e2aba8eeace193e56874d863f26cd76ff0ee8f74dff6f15861e3f68c331aded3dd3d3d6a45a856a65af48f06439aa3a73536800a6b53a9ad4164727dd15c6f883f8abb29beed717e20fbcd51222262ad2f3451cd646c14734734735404b6bfeb96bbcd1ffe3dd6b83b3ff5cb5df68ffea56ae263235169691696ac90e68e68a39aad4039a39a39a39a3500e68e68e68e68d406d145146a01451451a901451451a80ca653e9ad5259e3948b4da916b13a05a28a7d00396ad435556ad434017a3ad0b7aa31d685b76a0c4d4b5fbd5a11d51b5ad08eac09169d4d5a750014514fab019453e8a82c89aa192a66a8e4a00c1d4ff8ab91bcfbcd5d86a9fc55c6ddff00ac6a8089466aa7335589ab3ee1be5a0b28de4b59370d572e9ab3e6ade2414ee2a8c956ae2a8cd5a165799aaac956246aab25595a90c955daa692abb350035aa16ef5233542d416471ffc7d43fef2d7e766a96b1dadd5f428bb638ef2e9557fbaab71257e88eedb346dfdd6dd5f00f8eacffb37c69e26b3ff009f7d62f23ffc8ccdff00b357760fe291c38cf86271f375aaed56ae3ef5556af48f286d37753a9ad400ea3653a35697eeab354df67655dcf24712ff00b54808d52ac46b54e4d4f4eb7e1ae1a53ff4ce9bfdbd66bf76d6e9aa398b3616a45ac3ff00849ad57fe5ceebfefaa9a3f1358b7de8eea2ff00c7a8e603696a45acb875cd365fbb7db7feba2edad08655957f753452ff00c0a996585a916a1db22ffcb366ff0077e6a91655fe2f95bfdaa828996a45a855aa456a0b245a5a66ea7f3520145148cdb68006a6c2adb9a448da565f95635fbd248df2aaaffdf5ff008f547233336d4fbdff00a0ff00b55ecffb35fc28baf881e32b39a38dbec76736d8d9beeb5c7f149feec6adbbfeba32ff0076b9ebd58e1e9f3c8e8c3d09622a46113eb5fd8efe14af823c12ba85d46ad7d22b43e67f7a466dd337fdf5f2ff00bb1d731fb7f69525c7c28bcbd891a4996eb4f8638d57e666699b6ad7d4ba4e936fa1e976ba7daaedb5b78d638d7fd9acbf13783f4ff16ff66c7a8c2b3c3677d0ea0b1b2ee56921dde5ff00df2cdbbfe035f2caa494a35247d4cf95c654e3b5ac780f84ecee3e0ef83fc23e07b3b75b9d434fb186f2e20ddb56eaf2491961b7ff00764b8f32491bf861b793fbd5ea1f0cfe1cc3e0fb5fb64ecd7dab32b2c9a84ff7a491bfd649fecee6dd5d66a5e15b3bad72cf5468d5af2ce368e3936fdd5f9bff008a6ffbe9ab23e29fc4dd37e11f80b59f13dfaac91e976ed2436dfc57137dd861ff008148cb53cb2ab32f9e34e0790fed1bfb48689e03d7349f06b69d75aee8ff00da10ff00c25cb65279734d0b2f99f638d9be56665f2da45665fddb2c6adba46dbf63fc3bf883e1ff008abe13b5f12785f508f53d26e19a3dcabe5c90c8bf7a19236f9a3917f8a36ffd06bf386d344b9f8c9fb3a410da4d0c9abeb10adf4d24edf2c97cd70d25c4dbbf8599bcc5ff0067eed7ad7ec9ba36a5e15f87f75e38f0ade36a1ae69f78d63af787606ff9082dbfcb35ab2b7fcb655fde5bcdf7bef46df2b7cbecfb08c69f29f3752aca52e691f762d48bdab3741d7b4ff1368ba7eb1a4dd477da5ea16f1dd5adcc7f7648d9772b7ff635a0b589048d5153e8a006514fa280219beed71baf7de6aeca4fba2b8fd797ef544866151cd1473591b07347347348b5422c58ff00c7c475df693fea56b81b1ff8fa4aefb4bff5295713191a7cd148b4b564851cd1473400734734514007347347347355a807347347347346a0368a28a3500a28a2a40650dde8a6b50078cd48b494ab589d048bda8a17b51400e8eae4354e3ab90d005c8eb42d6b3d6b42d6acc4d8b5ad08eb3ed6b423a00997b514d5a750014fa653eac028a29375400da8e4a92a199be5a00c3d5beeb57177cdfbc6aec3586f95ab8bbc6fde35417133e66acbba96b42e1ab16f25ab8965599aa8cd56246aab356ba9051b86aa7255a9aa9c956594e4aaf25589aaac956510c955daa692abb50591b77a653dbbd328022916be2dfda1b416d07e2d7889b6fee7526875485bfbcb247b5bff002246d5f6a49f74578dfc7ef0e683e2ab5b5b1bad522b1f145bc6d369f1ac335d4cd1b7de5921855a4f2db6fdedbf7be65ad6854f6750c6bd3f694cf8e6ebef5536ae824f08f889a6f2dfc37ad4137fcf3934d9bff1df96bb6f03feccdf11be20de2c3a7f87dace3ddb5a6d5ae23b355ff80b7ef1bfe02b5ea4abd38c79a523cb8d0a953dd8c4f29dbf2ee6f9557ef353f45b1bff00126a91e9da069577adea5236d486ca1699bfef955dd5fa09f0a7fe09aba459ac379f117509f5d9fef7f6758eeb5b35ff0079bfd649ff008ed7d85e07f867e18f87fa68b0f0ee8961a25a05e61b0b758d5bfdedbf337fc0b7579357338fc34a3cc7a34f2c97c552563f2ffc07fb01fc60f1b79536adf60f0759b7fcff0049e65cedff00ae71ee6ffbe996be90f87bff0004c4f0469324775e2dd6354f165c2fde8d9becb0ff00df2bba46ff00beabedd58a1857e555a866ba8d56bcda98cad53791e853c351a7b44f1ed37f64df84da3db982d7c01a02a95dacd2d8c73337fc0a4dcd5e4bf143fe09d1f0e7c611cd71e1bfb4f82b526f995acbf7d68cdfed5bc8dffa0b2d7d3775af2c5332eedb5343acc2dfc55cb1ad38cb9a323b25878d48eb13f243e2f7ec6ff117e1089ee6f7485d73438fe6fed8d095ae2155ff00a691ff00ac8ffe04bb7fdaaf109b469163591a3dd1b7dd65f997fefaafde88ee21976b2b7cdfdeaf33f885fb2efc31f8a0d34dabf85ed62d424f99b52d2dbec772cdfde668fe56ff00812b57a54b3097fcbc3caa99747ec1f8aed6eabf7977547258c7feb117fef9f96bf42be207fc1325a169aebc1be325957ef2d8f882cfff001dfb443ffb3475f2bf88be07eb1e05f155f683e20b1fecfbeb7b7599a3591648e4566f9648d97ef2b6daf4e38ca5238bea35bf94f2585eea0ff53792aedfe166dcbff8f55aff00848f52b05fdf471dcc7fde5f96b5b54f0fdd78575056961925b36fbadf7be5feeffbd572fbc2527971dd697b6e6de65dcb16efbcbfecb56fed6265ec2a7c263daf8d2ca63b6585a03ebb7ff89ffe26b66d356b2beff533ee6feeab2b7fe3bf7ab4bc07a7d8de6a6fa35fc08de736e863bb85564864ff009e6cadfc2dfc2cb5dccdf04743befbda708dbfbd0c8c9584f151a72e591d74b0352b479a2703bbfe9a2b37f75be56ffc7a9de6edfbeb245fef2d75cdf006788634ed76f6d17f863b88d661ff00b2d363f82de34b37db0dd6917a9fed349037fe83b688e328ff00304b01898fd9393fb42ff796a45b59ae3f87ca5fef37ff00135ddd9fc15f1c5d30dcfa3da0fef3dcc8ff00f8eac75dcf85ff0067387ce5935cd4a5d5dbfe7da05fb3dbff00c0bf89bfefaa8a98ea14fed1ad2cb313525f0f29e6bf0f7e1dde78f3525b7b0668ac63936dd6a5b772c7fecc7ff3d24ff67eeafde6afd22fd9ff00e17d9f817c370b5bdaadb2b46b0c31ff00cf3857ff006666f999ab89f847f0b6396e2de18ade382c6dd576c71c7b638d7fd95afa523b78ed6158d176c6abb556be7ebe2258a95dfc27bf1c3d3c153e48fc44325519afe3b56669645555fe26ab9336d566af89ff006ebfda1b55f869e20f08685e1db881750559b55bd4b98fcc8da36dd0c31b2ffb5fbc6ff80ad4d3a72ad2f67139e7523463cf23ea8bef1be9f6f1c8cf751aaaab3337f757fbd5f137ed05f1a34ff8b9e2e4d1f46be86f3c2ba037da2eaed5bf777178cacabb7fbcb1aee6ddfde6ff0066be63f17fed09e37f1cf990ea77d0b59fde5d3eda3f26df77f79957fd67fc09996b0747f1c5d69ba0df69e91afdab509b74d76dfc2adfdd5fe26af670f819539734cf2b118e8548f2533d03c2bf127c47e18f0a5be9fa7ccba7e9f7573717d6bb60fde430b49feafcc6fe1f9776d5afabff00611f8f13693e38bef08ea9f655b7f136a0da92ea0ccd1c8b79b76ed5daadbb77cbb776ddadfc5f35789f8b3c2b1dc7c15fed896d567bc864b78d5a0ddb6cd5b76e5ffe2bfdaacffd9cfc39e26d7be2d785edfc2b711e9fac2dd79d0df5cc6d2436eb1aee69245fe2555fe1fe2f96bbaa46328c8f3fde8c8fd34f83fe3ad3f41f8c5e33f853ba3b62b0c7e2ad16d377ddb7baff008fcb75feef9771ba455feedc7fb35ee4b5f99bfb475d6adf017f69ef0dfc44b2d4a7d4ee96dedefa49268d6359161ff47b8876afcab1b43fc3fc3babf4badeea1bc8e3b8b76f36de6559216fef46cbb95bfef9af36a47e191ac7f94b14e6a6d3eb30194535a9d4144727ddae3f5efbcdfef576127ddae375efbcd5122e26151cd145416369dcd1cd14012d8ffc7c2d7a1693ff001eeb5e7b63ff001f4b5e85a4ff00c7bad5c4c6468f3451cd15648514514005145140051cd147355a807347347347346a01cd1cd1cd368d4028a28a90194d6a7377a6b50078e52ad252ad6274122f6a28a2801cb5721aaab56a3a00b4bf7ab4ad6b255be6ad2b5ab20dab5ef5a11d66dad5e8da820b4b4ea855a9dba8024a2a1f3a9ad74ab4016377bd46d2edaa335faad539b52ff6a803524ba55aa3757f59371ab6dfe2ac9b8d5b75005cd5af3e56ae56ea5f9aac5d5e34b59734b506b12bdd3563dd37cd5a170d59770d5ac465566aab355892aaccd5a44829cd54e6ab5255399aa8d752acd55646ab12355392ac08daa16a74951b5058d6ef51b5399aa1925a0b33efbfb4b54d52cf43d13cb5d4af15a492ee45dd1e9f6eadb5ae197f89b736d8e3fe26ff00655abde3e1ff00c3ed3fc25a5b5be9167f63fb437997577236eb8bc93fe7a4d27de91bfdeff80ed5af2ff8376ffda5a8789b567fbb36a9f6185bfbd0dac6b1ff00e8e6b8af669bc471e9b25bdbc51b4f7537dd8d7fbbfc4ccdfc2b5e457a9cd2e53d0a14fdde6ea6f43a0b3ffcb466ff0081536ebe1ee97a947b6fb4db1bcffaf9b78e4ffd096af69b757d710ee5862ffbe9a8b8d6756b56657f0fde5caff7ac6e2193ff001d6656ac342b9a661afc23d26ddb75836a5a2b7fd42754b8b55ffbe55b6ffe3b43780fc496adbac3c7dac2affcf3d52cecef97fefaf2e393ff001eabd27c4ed26c1b6ea90eb1a1b7f7b54d1ee238ff00efe2ab47ff008f56a697e3af0feb3ff20ed7b4abe6feedb5f42cdff7ceedd564cb98e6e4d27e245bff00a8d5bc27a9affd3de97756adff0090e6917ff1daa7259fc4e6ff005ba4f83a55ff00a61ab5e47ffa15bb57a44371f68ff54be6ff00d73f9aa669597efc6cbfef2d3e633e63c2f52f0afc4e96e2e264d1741956493cc58e3f1049f2aed5f95775affb3ff8f567affc2c8b0655bcf87b753aff00cf4d3758b3b8ff00c75a48d9abe826ba8eaadc4b1b2d67c91ec6f1ab53f98f09f08fc4cb6f125ab5c69976b76b1c8d1cd12fcb35bc8adb5a39236f9a36565656565aec2c7c791afcaed5f21fed41e085f06fc72d52e92dda0875e8575ab5bb819a36593fd5dc2ab2fcdfeb155bfedb5737e1df8a1e2ef0cb46aba87f6d59affcba6b2cd237fc06e17f78bff02dcbfecd12a5fcb23d0a7cb523cd289f7d5af88e1bc5f91abccfe3c7c13b3f8c9a1c335af9367e28d3d59b4fbb93e58db77deb79bfe99c9ff8eb6d6ae17e1afc5eb1f1448cb6ed3d9ea50af9971a5ddb2f9d1aff00cf48d97e59a3ff00697fe04ab5ed1a4ebd1dd2acc922b2b7de5aca339465ef135297bbee9f9f33782d9a6bcd36ff004f6b6bcb799ad6f34fb95fde5bccbf7a36ff003b5959597e5a8f41f8411e9779bade4916c6466692c5be68f77f797fbad5f6e7c5cf8376bf1124ff00848344f22dbc550c2b0b798db61d4235fbb0ccdfc2cbff002ce4fe1ddb5be5fbbe1ba1daade5bb49e4c90491c8d6f3413aed9219a36db24722ff000b2b7cb5d92af28c7ddf84aa34e9d6f8be289e71a8fc26d2b5d8563bfd3d2755ff0056df7648ff00dd65f996ba5d2fc1ff0065b586169259fcb5dbe64edb99bfde6fe2af40874b5feed5e8f4d5feed734aa4a476c69d38cb98e261f0aaff0076b42dfc32abfc35d74761fecd5cb7d3777f0d625f31cdd9f8717fbb5d67867c1ada95e470c11ee66ffc76b6345f0cc97932aac7bb757ae786fc3f0e836bb6355699bfd637fecb4e31e630a95f949b41d0e1d0ec63b7817eefde6fef3569352d319ab789e44a5cc67ea8cde4b2afde6f956bf1b3f697f886bf133e3778b7598a6f32c56ebec362dfc3f6783f76acbfef6d66ff008157e9efed5bf121fe18fc13f136ad6d22c5a9cd6ed6362dfdd9a4565ddff015dcdff01afc6d8d7cb455ff0066bdacba9eb2a878b98d4f7634c72cab12cdbaac68363a8ea9a84474fb679da36f337796cd1a2afcccccdfdd5acf936b332b7caad5f437c1ff000f5c7c55d166d0746864b1d3d615b7bc9d9be66665fdddbc7fed48cabb99be555af7252e589e1d38f348e8a4f8e763a4f826fbc2ba4dac9a9cd7567f659b56693cb8f732aee68e3dbf32fdefbdb6bec6fd84fc47e11d53e1adbe93a269f1d9f89b4db555d624fb3fcd70cd23379db97f85be55f9b6ff00abfbbf2d7e6dc9a4dd683ab5e69b79e5ade58dc496b70b048b22ac91b6d6dacbf2b7ccb5efdfb24eb3ac693f1a3c330e93792c0d75751c335b2ab32dc43ff2d1597eefcb1f98db9beeedae3ab08f29d9194a52f78fa7bf6f2f0443af7857c23788d12de36adfd93e5b7de996ea3ffe2a35ff00beabe9cfd9d7c46de2af813f0ff5497fe3e26d0ed639bfd99215f264ff00c7a36af917f6e6f8d30add69be05d3648a568648752d4ae56456fb3c91c8de5c3b7fe59c8bb7cc6fe2fbabfc4d5ee9fb08eb936a9f0364b3b85d8da5eb97d6eabff4ce465ba8ff00f4a2b8e7197b33589f492f6a7d44b4eae601ad494fa6b53286c9f74d71baf7de6aec24fbad5c7eb9fc55122e261514fa6b5416273451cd1cd004b63ff1f5157a2693fea56bcf6c7fe3e23af40d27fd4ad5c4c6468d145156485145140051451400514514007347347347355a80734da28a3500a28a2a406377a6b539bbd35a803c72956929dcd62740f5ed4fa653e80156ac4755d6a65a00b0bf7ab4ad5ab2d7b55eb76fbb56448dcb76abd1b563c371563ed5b2820d46956a192e956b266d4b6d67cdaa7fb5401b936a5fed5519b52ff6ab0e6d49aa9c978cdfc5415ca6c5c6a9fed567cda933567b5c542d2d01ca589ae99aaac92d359aa166a8341b24b55666a9a4aab3355815666acf9aae5c5519ab48905592aadc55a92a8dc5544b2ac9546e1aae4959f3356a56a5792abc9534955e4a0712192abc8db2a691ab1f58d52db49b1babdbdba8ad2cad6369a6b999b6ac6abfc4d41a935d5e476f0c924b2471431ab49249236d5555fbcccdfc2b5e0ff123f69e93c3f6fe67867475bc87ef47aa6a9b961936ff001430fde917fda6daadfed543e28f897a3f8d23b392f35483fb36eae163d3f4456fde4cdbbe59ae97ff001e58dbe555fbdb9beef0ba86a5a7fc46f17683e09d376df36a57d0c77172abf2aaac9fbcf9bf89563593e6ae9852e55cd339273e67cb03ed4f8336f37873e1af87edeee4dda87d8d6e2e9b6eddd7136e9a46ff00bea46af4af08d9fdab526ba97e6924dbbb77f77fbb5c4d9aadc5d2aa2ed8f76e55feeaff000d775a6dfae976ad22aee93f8557f89abe62a7bcf9a47d328f2c79627ae59cb0ac31fddad0568dbfbb5caf86ece468d66b893cd9997e66fe1ff757fd9ae996d777dd6db5517cc71548f2c8b11b6dfb8ccbfeeb6dacdd53c2fa3eb3f36a3a4e9da8337f15dd9c7237fdf4cb556f349f1044cd269dac5b37fd3b6a567e62ff00dfc8d9597ff1eacd93c45e24d259bfb53c2b733c2bff002f7a04cb7cbff0285bcb997fe02ad4731118f6905c7c23f05dc7cc7c2ba42b7f7a0b5585bfefa8f6d431fc2ad0ecff00e3cbfb4f4cff00af1d62f23ffc77ccdb535bfc4ef0fdc5d2dabead6d6778df76d350dd6737fdfb9955ab624d5d625567f955beeb37f154f344d796660b7816eadffe3cfc5daf40dfddbe686f97ff002247bbff001eac7d4aff005af07dd69edacc963a9e9779791d8ff6858c325bc96f349f2c3e642cccbb59b6c7b95be5665f96bac6d7adda65856e23f31bf8777cd5ccfc5a56baf863e2468be69ad6d7fb423ff7ade45b85ff00d17551e5907bd13c97f6c8f0aaeb1f0c6cfc4491ff00a6786efa3b891bf8becb37ee66ff00d0a193fed9d7c8b6ebb7e56fbcadb6bf49bc49a1d8f8cb45d5349bc5dda5eb16b25acdff005c665dbbbff1edd5f9beba6dd6937171a7ea3ff212d3ee26b1baff00aed0c8d1c9ff007d32eeff008155c65ee9e8e1a5aca25ab7b0f366866824920bab76f3219e06f2e4864fef2b7f0b57ad7847e24789ad5556f2c62d5da3f97ed362cb6b332ffb51b7eed9bfdd65af35d2d3f791edafa2be11f80d754ff48ba8ff00d1d7ff001e6ac6a1dd2e5e5e6910afc70bab78fcbb2f0bf882f2fbeeac6b67e4c7ff0002919bcb55ff00813564e93a1ea17136a5ab6aeb07f6c6ad78d7d78b69fea636dab1ac6adfc5b56355ddfc4db9abdd9bc076abb9625555ff0076a8dc782e489be58f77fb4b59fbc72c674e32e63cae3d37fd9ab4ba6b7f76bd097c17337fcbbb7fdf3572dfc1136ef9a3db417ed6279edae86d2b2fcb5d768be0ff00376b32fcb5d759f8563b7f99955ab6a1b558976aad1189854abfca51d3749874d5fddaaeefef568d3f6d1b6b5e538e52139aad336da9a46dab5c9f8fbc6567e03f09eade20bf6ff45d3edda665fe291bf8635ff699b6affc0a803e2eff00829078f1aea1d3fc3f6d27fa2d9b6db8dadff2f132eedbfef2c2adff007f2be0291be66afa4ff6b0bbd41bc39e15fed4225d6354bcbad5b506ff00a6d22afcbfeeaab2aaff00bb5f3537cd5f5197c7f727ce665fc7e52355666fddab348cdb5557f89abf447f643f874da659e8fa4c3febade45b8ba655ddfbeddb999bfd9fe1ff0080d7e7e687335aea96f74abf35bc8b22ff00bdfc35f5e68bfb477fc233f0474fd0fc39e5b789b5ab3923d62758f77d86df748bb55bfe7a3336eff6576ff7aba2bc6528fba71d0718f31d77c72fd9cf58f137ed65a6e8b616f6ba7e9be3468ef2c6e608f6c70dbc6bb6e1a45fe2917cb666fef6e5afb6be08fecd7e0bf813670b68d66da9f88235fde6b7a87fc7cc8dfecafdd85597e5f97fefa6afcc9f06fc48d6343f889a2f8d2f1bfe121d5b4bb886e15754999966f2d76aab32fdd5dbb6bf58bc03e3cd2fe20f8274bf1369170b3d8df43b976b7fab65f95a36fe2dcacadf7abcfaaa518c626f1fe63f2bfc7da6dd5bfc60d52c752923bcd43fb71a1bc68f72ac9335c7ef36eef9b6ee665f9abf42bf653ba8f4bf177c4cf0cb32add5bc9a5ea5340abb7c991addad645ffbeacd5bfe055f1cfc4ef87dac6b9fb5b78b34bf0f59c77da847ad49aa4305ddc2c6b22aac770db9bfbbf357b07c19f1a5d683fb7378db50bc65b1b3d6af3fb1752b4924dde4c936dfb3c8adfc4ab711ac7bbfe9e16ae7ef47e41cc7df11d4950c7f2d585ae189ac85a653e994c08e6fbad5c6ebbfc5fef576527ddae3fc41dea2459874d6a96a26a82c4e68e68a46a009ac7fe3ea2af42d27fd4ad79ed8ff00c7c2d7a1693ff1eeb5713191a34514559214514500145145001473451cd001cd1cd1cd1cd56a01cd369dcd368d4028a28a9018dde9ad523546d401e3dcd22d2f348b589d03969d451400e5a995aa15a76ea00995aac472edaa3ba8f3280353edbb6a39b526fef566b4b50c92d02e52d4978cdfc555dae1aa16ef4ca064ad2d46cd4948d40033546cd4e6a6d00377535a9db69de4b5056a576ef54e6ad2922f96b3ee16ac933ee2a9c95726aa7256ba905392a9dc55c9ab3ee1a9c4b29cd5464ab9355392b52b52bc955e4ab1255399a8195e4dccdb57e666f956be41fda6be2ab78a24b7d074d93fe29f5999bcf56ff908491b6df33feb8ab6e55fef32b37f76bdc3e3578aae2d74fb7f0ce9734b16a9ad2b79d341feb2d6c57fd748bfdd66ff0056bfef37f76bc66c7e0de9faa4cfa86b92334922c70dad95a4db61b1b55f9563ddff002d1b6fcdbbeeeeaeca11fb5230af294bdc89e5be07f01df788e39af936d9d9aac8ab7327f17cbf36dfef57b17ec63e03697c45ae78baf21655d3e3fecdb3ddff003da4f9a46ff80c7b57fe055b122d9f8574991ace3f2adecedd9a1b68dbe6db1fdd55ff0069bff426af74f84fe0bff8423c13a5e932aafdbb6b5c5f32ff0015c49fbc93fef966dbff0001a8c655e5872ff31ae070ff00bce6fe53d1bc3f16d69266ae93495fb45f2b37f0b7cb58fa5c5b235dbfc55d5786ecd9a65936ff00157cc4cfa3e63d23438b6dbae5ab723b8dad5cfdadc35baad5a87528ff00bd55cdca70ca3cc6f2dc2b549ba36ac19af9628f72b566cde2858bf8b6d1cc4c69ca47597d6f6faa5ab5bdec30df5bb7cbe4dcc6b347ff007cb57157df087c39b64fecb4bcf0d48df36ed0ae9ade3ddfed42dba16ffbf752af8c235fbd256959eb91dd7dd6f968e68c8d234ea436385b8fed2f046b1a3e9f7f7106a763a94d25bc3a9416ff0067916658da458e68d7e56dcab26d65dbf32fddf9abaa9ad5756d3eeacdbe75bcb792ddbfeda46cbffb3562fc665ff8b7f7da945febb459adf588f6ff00d3bc8acdff0090fcc5ff008156b7876f2392ea1d8db97cc5dadfeceeaca3eec8e897bf039ff85fae36b9f0e7c33792ff00ae934db7f33fde58d55bff001e56af8ffe3e696ba5fc76f1a4712ed8ef24b5d5157fda9add7ccffc890b7fdf55f467c23d7a3b5f87f636ebff002c6e2f235ff756f2655ffc76bc5ff680b5fb67c5efb42aff00aef0fd9b37fc06e2e157ff001dab8cbe236a31fde46479ef825ad57c59a3c77f22c16335c2c3248df763ddf2ab7fdf5b7fefaafb63c37f65d3ede38625dab1fcbb6be23bcd2d5a368dd7746cbb595bf8abbcf09fc66d6341b58ed756b7bed4ede35daba858af9d26dffa6d1fde66ff0069776efeed12fee9d9561291f632de42bfc4bff7d54d0dfc32c9e5ab7cd5e27e1ff16de78821b7934e9165fb42ab42d26e55f9bfbdfc55eb1e13d0db4bb3f32e2e1afaf24ff5d72cbb7cc6ff00657f857fbab5119731c3529f2fc46ed23252d15b1cc44dde8a7353681053646a19aa9dd5c6d5a82f948eeae36afcd5f2ff00c6cf157fc2c6f1d43e13b293cdd0fc3f32dd6a8cbf766bcff9670ffdb3fbcdfed37fb35db7ed01f189bc03a0c763a4c8ade28d5b743a7c7f7bc95fbad70cbfdd5fe1fef36dff006abcd7c1be158fc25e1986d5b735c36e9ae2466dcd248df7b737f1351fde3a69439a47cabfb684acde22f0bdb9f9e45b7b893fefa655ff00d96be7992cd957eed7b3fed2de208fc55f1a2eed6ddbcdb7d1a15b2665f997cefbd37fdf2cdb7fe035e65a96db3b59246feed7d660e3cb42313e3b319fb4c4ce5132ecd7cab78f6afcd23349ff0001fbabff00b357dedf067e07dad87c1bb8d36eac659750d4a18ee3565b1ddf69bedade647671b7f0ee6f2e3f97fbcd5f2efc27f855a878a3c71e1db57b7df6f1c30dc5c47b7eefcdf2ab7fb4cdfc3fecb57e93693e2df08fc13b7d2ef3c51ab416322eef2599773332ee692458d7e6fe1f2d5bfbccaabf3354d7a9f66267463cbef48fcefd5348bcf0cead79a5dec2b15f59ccd6f7112c8b22c722b6d65dcbf2b6d6f97e5afb33f669fda33c17f0dff6719b49d4758b3b3f135add6a125ad8ac324924cd22f991b49b576fccdf2fdefbbb6b2ff67bfd92749f156ad378d3c43359ebde0d9ae2e9b47b182e1bfd336dc32c734db7fe59edddfbbddbbfbd5adfb76783edf46f0cf85f50d2ecf48d2b4d8e66b59a0b6b58e19a69b6fee76ed5f99563f33e5fe1ff00be6b2728d4f74d077ec77f142fbe20f8ebc70de239209f5abe861d416e7c98e3daaabe5c91c7fc4bf2f97f2aff000afcd5c6fed29aa693e05fda8ae24f325d3ed75ed0e18f54b98fe66b7924f963ba55fef472436f37fbd1d79cfecb3ae3683f1ebc2b37daa0b359a492ce492e5576b2c8bb76ee6fbacdf2fcd5db7c5ef86927c76fda2bc610d96bd6da7cd67a7dbb2c776ad2332c6b246cb1aafdedbe5ab37fd74a39631985b9a27e84fc1df88cbf157e1be8de2591638b50b88dadf52b68db77d9efa16f2ee23ffbf8accbfecb2b576ead5f0afc03d72e3f653f8bda6f82f5cd52fafbc03f119564d3756d49557ec7ad43fb9685997e5db32ac7ff007d47fed57dccbb95b6b7cacb5c5523cb22a3ef13d31bbd0bda86ef5232393eed723aff00f17fbd5d749f76b91f107de6a891ac4c2fe1a46ef4fa654163291a9cd4d6a009acbfe3e17fdeaf40d1ff00e3debcfecffe3e16bd0347ff00535713191a7451455921451450014514500145145001cd1cd1cd1cd00368a28a0028a28a006377a6b53a9ad401e3d4514ab589d0397b5145140051bbde8a1bbd00359aa3dd4e6a8e801dba9bbbde8a65001452eda76ca006526dab0b0d4d1d9b35005358b7548b6acd5a96fa5b37f0d695be93fde5ab2398c18ec59bf86ae2e97f2fddae816c157f869cd6bb5680e638fbcb5dab58374b5d96ad6fb56b91bffbd41663dc5519aaf5c567cd5aea41566aa3355e9ab3e6ab896539aa8cd572e1ab3ee25ab28af33573be28f1358f85f45bed5b529bc8d3ece3f32693fd9feeaff7999be555fef356c5c4bf7b6ffbd5f25fc5ef175e7c72f1647e17f0e5c6ef0be9732c975a82b7eeee26ff009e9fed2afccb1aff00136e6ad610e790a753d9c4e07c71f17f5af185beb17d159b69f1ea970b0cd7cbb999618f77976b1b7f0aaafccdfc4cccdfdeac1f0bfc4bd63c2f346df6892f2ce38fcb5b1b96668ffd9ffc7be6af42f8b9e0d66d274db5d1b4b6fb2e9abe4dbc102c9249b5bf8557eeaaff0013337cccd5c4afc2fd5ac34dbe92f61db235aab790bb5995bccfbbfeced55f9bfef9af563cbca7955235398ee3f6715d63e237c50916f66fb4e976f247ab6a0ccbf79a36fdcc3fecaf98cadb7fe99d7dcd676ffc4df7abc27f63bf043683f0d64d5a785629b5cb8fb546db7e6fb3afcb1eeff7bf78dff02afa4349b06964fbbf2d7cde32a7b4aacfa8c1c3d9d28f37da35349b3696355dbb19abbcd16c16de35acbd26c3ca556db5d35bafcb5e71d9cc4d24b5937d71245b9a25ddfeceedbbaae4ccdf35737af788ec74b864fb45c794cbfc3e5b37fe82b5cf391a538997a978aa4b593cb5f3199bef5a4ffbb93fe02df75abe6dd4bf693d42cfc45a847a259c5e23d0e391a38f509e6fb2f98cbf7963dbb96455fbbe66d5ddff008f357f8b9f142f3c5ba86a5e1dd3967b3d2e193ecfa84f3ee8e4b8f955bc98d7f863f9977337ccdf77fbd5e6ed6eb146b1aaaa2aaed555fe1aba74fed48ee8c7f94f46d6bf6afd52d6de3f2bc37158c6d3471dc5f5cde7da16d636655693c9555f336eeddb772d7d25e075fec39a492e750bcd56fa6f964bebb917732ff7638d76c71aff00b2abff007d57c27a9696ba959dc5acbfeaee23685bfdd65db5f517c0bf1849e23f07e8b25d36ebc8edd6d6e3fd99a1fddc8adff7ceeff75aaaac6318f344cb97de9731f486a512ebde1bd4ac5be65bcb1b8b765ffae91b2ffecd5e67f047c54b7fe09f0dea93c9b57fb36dee2666fe1db1ab37fe82d5e89e1fbf8e28e367fbaacacd5f2b5ef88a4f86bf073e205a091564f0fd9eada6ab7fb4ad2471ff00e3b24753f1729cf18fc5e875ff0005e56baf07e8ecff002b490fda197feba3349ffb52b8df8a174ba97c56d7191bf77676363a7ffc0956499bff004a16b1fe10fc75f0ccb6fa6c37975268dfe8f0c7241771b7de58d55bcb655dacbf2fcbb7fef9ac7d2f54935c5bad6278e48ae356ba9b509164fbcbe648db55bfdd8fcb5ff80d28d39479b98ec8b8ca71e49171ac165adaf09f836eb59be58e28fe5fbccd5cddd78ab4fd2e6f267925f397f862b79246ff00c755abb4f02fc5af0fe9727fa45d4b62dff4f767710ab7fc09a3db44a323694f97e13e84f87fe098f43b35697f7b70dfc5fddaef3eeaed5af31d0fe2d68b796fe626a962d1aafdefb547ff00c556937c5ff0dc5f7f56b6ff00b66de67fe834e328c4f32a42a4a4778b4b5c337c5cf0adbffadf1059c1ff005d1997ff00425ae9347f1369faf42b2585c7da6365dcb246ade5b2ff00795beeb557344ca50944d292a36a733555b8b8555a0cc2e2e36d799fc5ef8aba5fc31f0ccdab6a2cd2b6ef2ed6c636fde5e4dfc31c7ffb337f0afcd57be247c48d1fc03e1fbcd6357bcf22cedd7f87e692466fbb1c6bfc5237f0ad7c737579af7c66f1c47ac6af1f95336e8ec74dddba3d3edffbbfed37f1337f137fbab5518f37bd2f84e9a74e52972a363e1ce9baa78ebc55a878e3c50cb3ea1236d8d7fe59c3b7eec71aff000aaaff009dccd5abf1abe2545f0d7c0d7bab0656bf6ff47d3e16ff0096974df77fe02bfeb1bfddff006aba99a5b1f0be93f674912daced636692791b6aaaafccd2337fdf4d5f127c52f88d2fc5af197f69a9913c3ba7ee874c824f9772ff0014ccbfde93ff0041dab5d586a3f59a9afc24632bc70946cbe2e9fe67116362d042d34f23497533349248cdf33337ccccd549a4b6b8d7edd2f5fcbd3ed76dc5c37f7be6f957fe04d5aba95e2dbc2d237f0d70f1b19d66b87fbb248cccdfeed7d61f0d23ed8f82be3ad1f4d86d6e2c24fb76ad7523476b691aed6924dadb777f7557e6666fe155666af23f1c78d352f1d78bb50d6354befb74d248d1c6caccd1c70ab36d8e3ddf763feeff00bd5efdfb28fc31b5f09784ed6e351b74bcd4b5458fed11cfb5b6c6cbfea57f8b6b2fde5af09f89de1f87c2bf1035cd2d356b6d6a6b7bc996e27b487cb86393cc6dd1affbbf2afcbf2eef957eed71c651f6923b65cdcb1e63ec4fd85fe245f6b3a5dbf83eebc4d04b0e976f71259e84ba4ac72471b37facfb56efde2ee666f2f6ee5ddf336daefbf6d0d2e3d5be05de6db7f3efadf52b16b7db1ee656926585b6ff00bde66daf8eff00655f88d6bf0dfe3069fa96a2d041a4cd6b35aea17325bc93490dbb2eedd1ac6accadb9557fe05f35769f1a3f6bcd7bc61ac5c59e8770b63e15b5ba86e21f2edf6c975e4c91c8acdbbf87747b957e5ff6ab09425cfee87d93a0f87bfb2eff00c23ff0cfc69e2ef1e697baf21d0eea4d3f4b919964b7936b7ef1b6ff00cb4feeff0076be6ff06f8f352f05f8a2cf5eb59a46bab565f317ccdbe747b76b42cdfdd65f96bf523e294b7575f09fc59259dbff00685e4da1dd491c11c7bbce66b76f976aff00bdf76bf28743d1ae35ed534dd374e559eeafa686d6df736d569246555dcdfc2bf355529737373127dedf18bfb2fe39fec53fdb82de3dd1c76faa5bc71cdbbecf751c9e5c8accbfef491ff7b76d6af4bfd897e3f5c7c66f86d2697aedd1b9f177867cbb7bb9e5ff00597d6adff1ef74dfed36d68e4ffa691ffb55e15f13be1beb1fb34fecdbe20d061f1447ace8fab5c476fe44d67b648ee2e17f7cb1b6edab1af96adfde6dbfc3b9ab81f03f8c23f833a7f86fe33785fcdb98f479a1d2fc55a5c0dba3bc86eb6b346adff3d176ab7f75645ff6ab0e5e68f295fde3f5095a92b3bc3faf69be2ad074dd6b46bc4d4347d4ade3bcb3bb8feecd0c8bb95ab46b88d4493eed723af7de6ff7abb06ae47c44bf7bfdea245c4c2a653e91ab235d46b77a8da9cd51b551258b1ff8f88ebbed1ffd49af3fd3ff00e3e16bd0347ff52b444c646af34522d2d6c01451450485145140051451cd001cd369dcd1cd00368a7734da0028a28a006377a6b539bbd32803c8a85ed4377a17b562740fa6377a7d1400ca28a6500235376d3e976d0047b69ca9532c55621b366a00aab155a86cd9bf86b42df4ddcd5ad0d82aff000d04731936fa5eefbcb5a16fa6aaff000d69476eb56a38aac82ac366abfc3563eceab532ad3f9a0b2b34350c89f2d5a6ef50c9401ccebdf76b89bcfbcd5dc7883eed70f7df79a82cc7baacf9ab42eab3666ad2241566acdb86ab9752d717f10be20e83f0e7416d5b5fbe5b1b566f2e18d57cc9aea4ff009e70c7f7a46ffc757f8996ae257c2695f5e476b0cd34f3470430ab49249236d58d57ef33337dd5af1ff137c75b78b4f9af343d3d6fac555b6eada94df65b293feb9aed69a65ff695557fdaaf2cf1cfc6097c63e171e2bd6ecfcbf0fb5c6dd17c2eb2ee8ee995be5b8bc65ff5cdf2b32c7fead76ff1578278abc5bad78eb56fb66a37124f70dfbb8e38fe558ffd955af42961f9be239e75f97e13d27c79f11bc55e2fd12ee6f176bffd9ba1dd334763a168f1fd9d752dbf7999be66f257f8999bfe035bbf0a75cd174df09cd6f6b344ab6ecd717122c7e5aaeeddb77337de6daad5e0fab586a5147e65ec33aadbaadbab48adb576ff00cb35ff00656b35964dbbb6c9e5eefbdf36ddd5dd184631e5393daca32e63db3c59f1c2dec265b5d0563b99377ef2ee45fddff0fddfef574da2affc2cb6d0f47b7f3205f125d7d8d5b77cd1daab335c49ff007ee36ff8132d7cd31b7cd5f68fec3fe0b9758d366f16dd2325bd95bb689a6237f16e6f32ea6ffbebcb8ffe02d5862a71a34f98eac2f357adcb23e99d27498ed638e38215821dbb63822fbb1c6bf2aaaffbab5d968fa6aaedf96aad8d9f9b36efe1fbb5d669b6bb57757c9ea7d4b2e5adbec5ad08d76ad470ad4d52490cd5c4f8cb54fb3dab47e637cdfed57617d2f951b35788fc62f11ff63787756beddf35bdbb32aff7a4fbaabff7d32d72cbde3b297f78f9bffe42579aa6a0df37dbb50b8b8ddfecb48cabff008eaad47716b5b167a4ff0066e9f6b6bf79a18d6366fef32fdea73586eae9e63d08c7dd39792d7f89b6aaafccccdf7557fbd5ed9f00fc2ad6fe198f587f36dae3546fb6791bb6ed8dbfd4ee5ff9e9e5edf9bfdadbfc35e6f67e195f106bda6e832aeeb7bcf32e2f17fbd6b0eddd1ffdb469238ffdd66afa6b4d68746d25aeae1a38955773337caab533f7bdd3094b959d247a947a5e9f34d79711c16f0c6d34d3c9f2ac31aaee666ff65577357c39fb4c78e187c35119536d79e3ad6a4d42481fe568ecd76c8aadff006cd6dd5bfde6ad0f899fb517863e22788351d0d7c44b6fe12d2d97ce8c3b471eaf26edcdf77e69218f6afeeff89be66dcbb6be65fda03e3143f10fe205b5ce95335c68fa5dbf916f23ab2f9ccdf34926d6fbbb9be5ff0080ad7a385c34bda479a27878ac4d38d294a32f8b4ff33d07e15ebd0cb22e9f3c9e55c47f343f37fac5feeffbcbff00a0d7bc69b2ed55af8d745d523bf8e39a091a2656dcad136d68dbfbcbfed57bc7c35f897fdad22e93a932aea8abba3917e55ba55fbdb7fbacbfc4bff025ae9c550fb512b038a8fc123e84d365596155fe1aecbc36d1c522afddaf31d06ff72aad761a7f9970caa9b999bfbb5e1d489eff00c47b8787ff00b2fc95dd0c5bbfbdb577575d6ad6bb7e493fef96af19f0ef85754ba65655dabfed357a4697e1fbcb555dcdbbfe0558c4e3ab1fef1d74771f2fcacdff007d536496aadadbb44bf3353a46db5d07211dd5e2c4bb8b579dfc44f8a1a5f82f41bcd5352bc5b3b1b75fde49f7999bf85557f899beeaad37e287c44d37c1fa2de6a5a95e4763a7daaee92793ff00415fef337f0aff00157c2fe2cf1e6a9f193c451eada8acb69a1dab37f66e96cdf77fe9b49fde91bff1dfbabfed553a7ed3fc254626e7893c61ab7c5cf1343ad6ab1c9058dbb32e97a4eedcb6fbbf89bfbd337f137f0fdd5f97ef7b1785f435f0968ff3aab6a570bfbcff00657fbb5e77e038a1b0b8fed2b958fcbb55665dcdb557e5fbcdfdd55fef578ffc6bf8f173e3d6b8f0e786ae248b436fdddfea6bf2b5effd338ffbb17fb5fc5feefdeeaa74658897244daae229e0e9f33ff8713e3dfc62ff008581753785f419f7787e17ff004fd4636f96f5d7fe5947ff004cd5bf8bf89bfd95af289a58ed61f97e5555a3f73676eb1a6d8a355f9556b9fd42fdae1bfbb1d7d2d0a51a31e589f1588af2c454e799475cbc92ebf769f79be555af42f0dfc258f5cf1b7853c396f348b25f46d35c48d1ee58618d7e66ff008132b7fdf4b5c0f87563bcf134324bb7ecf6aad712337ddf97eeeeff008157b37c11f888adf15e33716f1b5aead1dbe97e6c8db7ecb0f98acccbff00c4ff0017cb55539bec9cd4f97ed1f757c3dd0d97ecbb7cc6dbb7cc917fbdf77fe03fc55e4fe36fd9ff0052f8e1fb4778ba4d2e68ec743b3b8d3edf50d42e5be5591ade3692385557e6658db77f77e6f99be6ab9f1a3e3c49f09ffb374df0f369b7da85e7da96fa0917ccfb3c7e5b47fc3f764591b77fdb365aecbf625f88371e2ad07c451ea57df6cd71b549afaebf72b1b32c91c2aacbb76ffcf3dbfecfcabf2ff179fef463cc75ce5cd23d82e3e09f85fc1bf037c59e15f0bdbda687f6ed164b3bad6e487ccb89155774924ccbf349f2f98db7eeeefeed7e62fdaa1691993735bb7ddf33ef32ff00b5ff0001afd7a9b56b1b3b3b8b8d49a35d36de1924ba691772f96aacd26e5ff77757c2bfb3efec8ade36fecff1678a24fb37856e1bed963a5ab7fa4de43bb747e637fcb15dbb772fdedbfdda294b979b98967bc7c33f8e7a7f87ff0065fd37c517fa847aacda1d8c36f78b032b4de6798aab0b6ef97ccf2d97fe035e57fb13f80fc0fe37d435af135d59acbe22d1f589a6b3b1693f736f6f27cd0c9e5fdd6656f3157fddff0076bcf7f6d4f0ce9fe17f8951c3a26931e87a3df5badd35a5b6d8e192e37379922c6bfef2affdf55ccfecc7f11aebe1a7c52d1ef12ea5b6d2ef2e23b5d4a3556916685be5fbabf3332b36e5dbfc554a1fbbe688753eb2fdbdbcbff8527a7efbc8a09175cb768e091955ae3f7722b2c7fdedbbb7357cd7f05f59d4bc41f067e2b7c3dd3bc1bac78aa6d5ad56fa39f49556fb0cd1b2b46ccbfdddcadfed7cbb557e6af74fdb6be31786ee3c3b67e0383c8d42eaf1adefaf2f9635996c6df6ee5921656dad237fb3fc3bbfbd5f427c09f877a0fc31f867a3e9fe1cdcf0dc431df497d3c2b1dcdd4922ab79926dfe2556daabfc359f372c0ae53e4bfd857f6c0d37e1a2ff00c2b1f1edd7f66787e4b869345d6ee5b6c7a7c9236e92d66ff9e70b49b995beeab332b7cadf2fe912fdd565dacacbb9597e6565fef57e3dfed6df0bedfc11f1e3c45a7dadbadb58ea4cba85bc7b5563db36efbbf37ddddbabb3fd90ff006baf19fc24f10693e04be87fe12cf095d3fd9ed34bbabb586e2ca4fe15b59a4f97e66f956191963ddb76b474ead2f69efc498cb97dd91fa9ed5caf883f8bfdeaabf0f7e2ff0085be2ac57cba06a0cda969edb752d135085ad751d3dbfbb716b27ef23ff7beeb7f0b3558f103fccdfef579b2f77dd91d313139a6352d31bbd06da8377a85aa4dd51b501a9369ff00f1f0b5e81a4ffa95af3fb1ff005cb5e81a4ffaba2273c8d45a5a45a5e6b62428a28a0028a28a0028e68e68e6800e68e68e68e6800e69b45140051451400c6ef4ca7d32828f25a29dcd1cd626c1cd26da5a28018cb4dd952f34bb6802355ab10dbb35490dbd695bdbd0411dad85695bd9ad4d0c557a35f96ac8218ed552ac2c34e55a72f6a001569f4ca7d003b9a6d26ea5a0b18ddea393eed39aa391be5a0839bf1037cb5c2df37ccd5d978925f96b83bc95a591951599bfbaab41a99b74d597333336d456666fe15ae47c4df1734bb5bcbcd37438dbc55ac5affc7d41a7dc46b6963ff5f578dfb987fddf99bfd9af8dfe2d7ed37ae78b66bad3e2d496e74f6668e4834b692d74e65ff67eecd70bfed48caadff3ceba6952954f84ca552313e8cf8b5fb44e83f0f21bab5d3957c4fe2187e56b1b493fd1ed5bfe9eae17e58ffeb9afef3fddfbd5f2759c5e26f8c9f12a4bef1337f6bddf92b249e7868ecace16ff00571ed5fbb1b7f0c2bb5a4fbccdb77357110cdab78aeea386d2d7cd8616dd1da5a42ab6f0affbabf2affc0abd32ddbc49670b786fc2acdf6eba5fed2d4b569e45592491bfe9a37fdf3ff01f97fbd5ea4287b3ff0011cdcfed24759e2ef863278a2e2cff00b5b5a68343d3d5561d3eda1585777f13349f757e55fe1ff80d4da3f83fc2ba1dc34d656f62acd1b2eefb42c9f2ff00c09bff001eaf2fd4be0ef8b2eacee2eaff0050b69e69245924824ba69377f7a466fbbf2d799eb9a6cda348b0de2c714cd1f99e46ef9955beeee5fe1ddf7b6ffbb5bc63fde094f97dee53e8af1a788fc276ab6f6baa5f5acab70cb1fcdf37971ff1336dfbabfe56bccfc51f163c2f7563369b67a0dddce9edf2c7f32daaafcbb772afccd5e5f6b179b2798ebf2ff0ad53d5a5f2ae9bf87e5a7632756523b2f08f86ee3e2878db4ff0df87b4d6b6bad4ae3cb85a5b8f316de155f9a493e5fbaaaad23357ea67c3df05e9fe05f09e93e1fd263f2b4fd3edd6de1ddf79bfbd237fb4cdb99bfdeaf9cbf625f82ede12f0ac9e2fd5602359d72155b75917e6b7b3fbcbff000293e566ff006556bebfd26c3eeb357cd63311edaa72c7e189f4b81c37b1a7ed25f148bda6d9fddae8a18b6ad55b58bca5abd1d79e77922fcb4e66a65452354019bad4bb6ddabe71f8cd79f6c5d36c57e65b8d4a1f317fbcb1ee99bff45ad7b978c3545b7b765ddf357ce3e34bafb678bb4f855b7476f6f35c37fbcccb1aff00ed4aca3f11dd463ee99bf67dd522d9ed5ab11d4925d5bd9dbcd71753476d6b0ab4934f236d58d57e6666ff0066b5e5675ca5ca73ba878823f87fab5bf8b6e3ecaba759d9dc59de35dc9e5aac7234722c8bfde6dd1eddbf79b77cb5f2a7ed01fb5df8a3e3333e996bff0014ff008617e51a7db3b6e9d7b79cdfc5feefddfad637c7af8d92fc57f11ada58b490785ac1ff00d1a17f97cf6e9e73aff79bf857f857fe055e51ad46b0dd285fbbb6be8f0d838c63ed27f11f118fc7fb694a14be133973baae2aedaa556d7e68d5857a713c234349d5e6d1ae3ce8be68dbef47fdeaf40d27c416fab471cb6b70d05d42cb22ed6db242cbf7596bccd6a68df6b2b2332c8bf7597e565a894798de9d59533ec8f847f1563d7268f49d49a3b6d6bfe59ff0c775fed47fed7f7a3ffbe6be9af86f790cba842d2fddafcbbb2f1415da97db86d6565b883e56565fbadfef7fb4b5f54fc0bfda774d8a782c7c577ab6f22fcb1eb0bfeae6ff00aedb7fd5b7fb5f75bfd9af071583947dea67d560f318d48fb3a923f4674bbc855576c6ab5b51de46d5e4be1df1d69ba969f0dc5ade473c2cbb96481bcc56ff007596b617c75a7dbaff00c7d2cadfdd8959abc8b33d295367a14974b5c27c4ff89da37c3bf0d5e6afad5f4763616ff2b49f7999bf8638d7fe5a48dfc2ab5e3ff183f6c0f0bfc39866b38ae1757d6f6feef49d3e4569377fd3693eec2bfef7cdfecd7c43f113e2fea7f1075e1adf8cf548fcd8f77d8f4d87779368adfc30c7f7b77f7a46f99abaa8e1a557de7f09e7d5ad1a5eefda3b8f1f7c46d63e39f899754d5e36d3f41b593769fa26edcb1ffd349bfbd237fe3bf757fdaaf7be24d2bc2766b79abdd2db5bff00cb38d5774937fb31aff17fe835e4d75f12af668fc9d12cbc95ff009fabc5dcdff014ff00e2ab9e1a735d5e35f6a9732ea57adf7a499b757b31c2ca5eecbdd89c32cc2347f87ef48eafc5ff0012b59f88718b4c3691e1d56dcb631b7cd3ff00b52b7f17fbbf76b15658ed61da8aaaab50cd70aab5977579e6fcabf76bd2a74e34e3cb13c3ab5ea5697354906a1a835c37fb3597712f930b3354df7be66aa7e47f6b6a56f68bf7646f9b6ff77f8ab53987a46d6ba5da0ddf35e6eb893fdd56db1aff00e84dff0002afa27f669fd9fd7c75f65f106bd717963a4fda97ecb1d8c8d1cd3796dba46ddf7a35feeb2d794f81fc02de36f89d1e8acad158c6cd7132aff0dbaed6dbff0002dcab5fa0de19b35d361b78d55628d76aaaaff7576aaaad72d5a9cbeec4eba14b9bde91f1bfc5cf0aea1e0bf1b5c69f7b63069ebe5ac96b1c171e76eb7666f2d999be6dcdb7e6ddf357d25fb0cfc2af1245a87fc2c29563b6f0fcd0c9a7c6b249b5ae1772b349ff005cd7cbff008137fb3f3570fe3ef01ea1f1bbf694d4b49b0bc5974b856de3b8bb5f9a1b5f2e1566b78e4fbad26dff00d0b737ddafa817f678bad17e10f89bc33e17f135d69edad46bf6892e63699ae1638f6edddff2cf72aaab796bf32aed5ac6753dde51c63ef1f30fed01fb4c6bdf11af354f0ddac9069fe17b7bcb887cbb19377dba3593f76d337dd6fbbbbe5f97e6afa43f64df1d2f8a3e15e9fa7a35cb368bfe8b7124ebf2b48dba4daadfc5b5596bf3ef54896dee248e2691a1566556923f2db6ab6dfbbfc3f77eed7d19f017c55e3ef83bf0cf5ef112f84567f08c9750dc4973a849f679266923558da1ddf7a35f9599bf8b72aeea538c797dd2a2759fb4f7c34d43e2e7ed05e1fd0fc2eb14fab378763b8baf3265558e35b891777fc055b732ad7bd7c23fd92fc03e01d2d7edba7af8875a9a3559354beddba16dbb59add5597cb5ff00c7bfdaaf887c0ff17f52b5f8e1e1ff001f789750b9bcb8b7bc85afa78235591add57cb6558d76aff00abfe1fe2afd2ed37c5ba3eade19b7f115bea56dfd8735afdb16f9a4558d61dbf33337f0edfe2ff0075ab39f347dd089f953e3ad26e3c3fe36d7b49bc695ae2c7509acdbccfbcde5c8cabff008eaad7d55fb1efed31a2e836727847c6baf4966aab1c3a4ddddb2ad95ac31ab2fd9d9bfe59b333336e6fbdfc4df76af58fc02f0ffc7afda53c71e22bad720d5fc231fd8750923d3ee1bccb892e2dd5961f317eeaaf96db9776ef9957e5aeebf6bef05e9ba5fecd3a85ae81a2d8e9f63a6dd58ccd058dbc71aadbac8cbfddddb55a4ddff02ff7aa9ca32f74a8937ed096fe07f0bfc62f04eb9adc769f6ed734fbcd16e16e76b4735bed56b79a4fe1dbe67990eeff00a6cabfeefc2bf18bc1763f0e7e2f59e8fa23795a7c73437d6726edd246b35c6e58db77fcf365655ddf7976d62aea5717fab59b5fdc4b7de5c8aaab7370cdf2eefbabbbeeaffbb5da6a9137c5cfda92cedd7735acdac5bd9afeef6b7d9edfef36dfe1ff0057237fc0aaa2bd9848f66fdaeb55d57c2fe2df03f8b34cd4eef4af13e9ed756b6fac5a32add46aad1b2ab37fcb45f99bf76db9595b6d7d15f003f68cb3f8f5e16922bbf22c7c69a5c6bfda9a7c3f2c732b7cab756ebff3c5bfbbff002cdbe56fe166f977f6ded656e3c45e15d353ef476f717922ff0077cc91557ff45b5780f82fc65ab7c3df1569be24d16f3fb3f56d2d9a486665dd1b2ffcb48e45fe28645f9597fef9f9956b1f65ed2995cdcb23f5b286ef5cafc35f88d63f13bc3b1df416b2e91aa431c2da968972dfbeb16917747ff5d21917e68e65f9645ff695957a7af3be13a439a63539aa36ef40162c7fd72d77da4ffabae06c7fe3e05779a4ff00abab891235e9dcd368ab207514734734121451cd140073473473473400734734da2800a28a2800a28a650014ca7d35a828f29a28a7d626c43453f651b28005ed5246b4d55a9a35a00b16eb5a56eb54e15abd0ad041721abd1fdd154e1ab51d590494fa650cd5603e994ddd4335003a9acd51c92d63f8a3c5da3f83743bad6b5ed52d745d26d57f7d7d7d27971aff00757fda66fe155f99bf86a00d692555ae67c79f113c37f0df43fed6f146b56ba1d8b36d8daedbe6b86ff9e70c6bfbc91bfd98d5abe51f1d7eda1e30f1f5f5f697f077c2b74ba7dab6db8f116a56aad337f7961864fddc6dfed4db9bfe99d7c77f142eb50ff84ba69bc53ae5df8b3c58df2ea524f74d22daab7fcbaadc7f136dff0059e5ed55fbab5d74f0b2a9f1194aa729f726b7fb52eabf106c6f2ebe1c782bed7631c8d0c7acf8b6fbfb3e19997ef7976f1ee92455ff006997fbb5f323ea1f15fe3b7882fadfc4baddcdbf85ed6ea4b5b8834b56b1b069236f9a18e3fbd349ff005d376dfbccbfc358179fb4f5f47e158749d2b41b5d2245b5fb2ab43237936f1eddbb618ff876ff000fcd5e6363f13bc59a35adadad8788b52b3b5b3565860826daabbbef36dfe266ddf33357753c3f2fd93395489f477c48f87775e23f0bd9f86f4bd6a0f0d785ede35dba6db5bf98b349bb73349b7ef2aaff000ff137ccd5e476fe17f867e03d72e1754d6a4d6aeadd9635b6b98772ab7f1348b1aedddfecee6ae1752f8a1e2ad4ade486eb5ebe9fcc93cc6669995beeeddbf2ff000fcabf2d72334ad33333333b7de666ae98d3e5f8889d58fc5189ec9f173c69a7dbf867c3f1f85ee16ce3691aea1b6823f2d7cb55655dcbfddddfc3fc5b6bd02f3c61a3f8674fb3bad5afada06bc85596766f9a65fef2aafcdb777f15790fc19f01daf8c2eae352d515a5d3ece48e38e0ddb7ce93ef6dff00757ff66ae67e20687f63f8897d62b74b79249247b64feef99f32ab7fbbbbeed3e58fc2573ca31e73d23c4dfb406976f7525be97672ea70aaff00af66f2e391bfd9fe2dbfed5792fc40f1bffc2697d0ecb38ac618d776d8d773337f799bf8aa6f1c7816e3c25e5ccf32cf6b249e4ab7dd666ff77fefaff76b938d7f8bfbcdbab48f298cea4a5eec89215dbb6ba9f865e11d27c61f15bc23a66b52345a4df6a10dbdd6df9772b37cabff00026dabff0002ae616ad5beef976b344cadb9595b6b2b7f0b2d65523cd1e50a72e59731faf9a3e9abf2aac6b16dfe15fe1ff66bb2b7b75b78ebc1ff0064ff00da02d7e34f867ec3aa489078db4b8d7edd07ddfb647f756ea3ff007bf897f85bfd965afa01be68fe5af8d953953972c8fb58d48d68f3c49a3a997b567fda3cafbd4efed28ffbd597317ca5c925aa77575e5c6cdbaaadc6a91aab7cd5c9f883c4cab6eca926dff6bfbb51291ad3a7cc73be32d7bcd9ae24ddfbb8fe55ff007bf8abc36eaf3ed1ae6a578df75996dd7fdd8f76effc799bfef9ae9fc7de31b6d3ed27964b98ad2dad9774b34d26d8e15fef337f7abe43f88bfb53c5672358783edd2e555be6d4aee33b5bfeb9c7ff00b337fdf35d187c3d4adb1b56c4d1c2abce47d2775af5ae936335e5fdd4569670aee9a69db6ac6b5e05f13fc7179f16b4db9d3ac259f4af0d6dfdcab2ed9efe4fe1926feec3bbeec7f79bef37f0d793697f112fbe20eb8bff000925eb5ca420cb6f6adf2dbc6dfde58ff89bfda6af425f31576ff77e666ff6abe970b818d3f7a47cae33339623dca7eec4f9a2e2de4b3ba92293e49626656ff796ac6a974b78b130ad4f1f582e9fe2cbe8d3eec8de72ff00c0be6ac7beb096cd2dda45da9347e6475dc78253a9edfe5a856ac5bafcd4440b0d42fcb525376d500efbd42c5b5b70668dbfbcbf2d329ead401afa4ebdaa688dbec2fa5b66ff00a612490b7fe4365ad5baf889e2abeb76b7b8d7b519e16fbd14ba95d32b7fc077572f1b7cd57ade2dcdf2d65ece26b1a928fbaa44d6ef792feed26f217fbb6cbe5d6859e970dbb6e65df237de6a75aaac51d4ff00681fdead394cf98b2acaabf2d4735e6daa725d7f76abb3eea62249ae1a56f9aa1fbd45359f6aeea008ee25dabb56ae783e25592fb549fe5861db6eacdfde66ac1bebaf959ab467ba9ad6ce3d1e36ff00478d55ae17fbd37de6ff00be776da0227d0ffb2cdd59eafe28d7ae0ffc852f248e38e0feec2abfc3ff0002fbdff01fef56b7c70f8e136b3349e1bf0fde47fd8fb76de4f1ab798d34770db9564fe15fddafddfbd5c3fecf7f0abc51e2d9aeafb4bbc9f43b59ad66861bb8d9636999bf77b7cc6fbabfc4cdf7b6afcb5c3d8dbf9526df95b6b32ee5fbadb5b6d72f2c798ebe79469c627df9fb0bf8aa1d5bc130f87e59a25bed3e6ba9bc88fe666b566566924feeb79926d5fe2655feead7d5d7d796fa5d9cd797b751d8d8dbc6d25c4f3c8b1aaaff007999beed7c37fb30ff006d7ecfede24f1178abc27e20fecfb8b1b78e15b4b3f3246924915bfde5fddfcdff007cafde65ae17f684f8e7e2cf891e26d6b4dbf6d4341f0fadc471ff00c2333c9f2c2d0eedad22edff0059b9999bff00b1ae6e4e6a9ee9a7d93d8be13fc1bf0afc73f895e3ef1e6af27f6f786ec7c40d67a6e9ebb63b6b855556dd22afde8f6b2ed8fe5ddfc55eedfb43787e4d7be06f8a2ced2deda46b5d3e49a18e5b769b6ac6bff2ce3565db22aafcadf7576eefe1af90ff00649f8c57de03f152f85d56cffb27c49a85bfda27b956668645dcabe5fcdb7736edbf37f7b77f0edafae3e337c48d2fc07e07f1036a57de45c7f66c8b0da4137977324926e863555ff69b77cdfecb7f76a65cd190cfcf9f87bf0ff5cf89de205d1fc3966b7d7de5f9d26e91638e38d7ef48ccdf756bda3e2b7c56f1d7c3bf00c7f06f56b1d0ec6ded74d86ce69f4ddd34925bb7ccabe67dd5665fbdf2ff0017fb55f417ec832e9bff000a07c2b269d6b6d67751c325adf340aab24d711c8cad248db773337cad5e7bfb7a585aff0062f84750fb1b4ba84d7135afdb9a66db1c6b1eef2fcbfbbb99997e6fbdfbb55ad39b9a5ef1079dfec6ff00186f3c03f11a3f0db2acba2f89a68ede48bcbf9a3bafbb1c9f2fcdfc4cacbfed57db1f15b54f09dafc3dd62dfc6b711c5e1fbeb79ade65926dad71b57ccf2e36fbde67cabf76be11fd96fe0b78d3e2278db4ff001078796db4eb1d16ea3bafed4d52393ecd248adf2c71edff0058dfeefddfbd5c9fc6af88de22f883e36d41b5ed4adef9ac6e24b3863d3d9bec50f96db5bc956f9b6fcbf79be66a99479a5ee967d69e07d2fc0ff067f67bb5f1d693a7c77971fd870ead25dddaee9a6ba68fe5fbdfeaff0078db76ad787fec5be08bad7bc69af78d2fff007ada7c2d6f1c927fcb4bcb8f9a46ff0080c7bbfefe560f8fbe2e36a9fb38f837c16b71bae9a691af955557cbb5b76fdcc7ff00026dadff006cdabd73546ff867dfd926d6c76fd9bc4daf2b2edfe25b8ba5dd237fdb3b75dbfef567ef4572ff003167ceff001d3c691fc41f8a1ad6a96b279ba7c6cb6766dfde861f9777fc09b737fc0ab83b7d366d52f2dec6d57cdb8bc916d635ff006a46dabffa1549e52aaaaaaed555dab5eb1fb2ef82dbc5bf17b4fb878fcdb3d0e36d5266ff00697e5857fefe32ff00df35d72f76241ea9fb4e78f358f837e32f86bac784af16db5ed36d6e2cd9645dd0de59af92bf67997ef346ccadf2ff000b7ccbb5abe9bf873f1534ef88cf7fa735acde1ef17e92abfdb1e17d4195ae2cff00e9a46df766b76fe1997e565dbbb6b57c51f1caea1f8a9fb4a693e174d523d32cec6487476d4276dcb0c9bbcc9a45fef36e6daabfc4cbb6addc5a6a1a1f8cdbc13e36d7350f09fc47b1d49b52f087c41b36dd1c6d72cccd0cdf75becd349bbe56f963669176afccade7ce973463fcc5c65ca7df6cd51b357cfde13fda98f87f548fc29f1a74d4f87de2b50ab1eb2aadfd89aa7fd348e6ff00962cdb7eeb7cabfecfddaf7b565961866468e58665f3239236dd1c8bfde565f9596b939651f88dbe2f84d2d3ff00d72d775a4ffabae074f6fdf2d771a3b7cab5513336a9f512d4b5648ee68e69b45050ee68e69b45003b9a6d3b9a6d0014514ca091f45329f414328a28a001bbd3295a92803cb68a773473589b0da29dcd1cd0022d588d7e6aaeb56a1a00b90ad5e8ea9c35723a082c4756a3aab1d585ed56412d2350b51b35580e66a8e4976d57925f9b6afcecdf7556be3efda63f6de8fc1f7579e17f87f34379ab5bb35bdf7889956686ce45fbd0daafdd9a65fe291bf771b7fcf46f955d3a72a92e5884a5189ee7f1dbf68ef09fc03d0e3b8d72e16f35abc56fecdf0fdb48bf6bbc6fef7fd3387fbd237cbfdddcdf2d7c53e22fda83c37e37d6ad756f15aea5af6a8bf347fb958ecb4dddf7a3b387ccf97e5f97ce6fde49fc4cbf757cc6cff691d734dbeb8bc4d0f41b9beba6dd75a95f5bc9717f74dfde9ae9a4f31bff00415fe155aeb347fda33c2fe2665b5f16f8660b3fe1fb4adbadd42bff000165dcbff8f57a74f0fecbe289cdcfcd2f88f4cb5f8a1e096d16e1b46bcb57b3d3e16916c60b7f2d976aee66587ef37ffb5f35782f8a34db1f8a5f1735093c356f7da8d9de2b5d32f96b0c9248abf332ee6f9559b6fcdff8efddaf40f117c0fd07c51670eb9e06be834f9a4f9a1f226692ca6ff77f8a1ff80fcbfecd733f0cfc79a4fc34f1649a7f8ebc3eda7ea56ecd1b6a91ab7990ab7fcf48d7e5923fe2f317ff001ead6328c7de894ff96464fc5af81f75e12b78754b38e3fb1c76b2497db64dcb1b2c8aaacadff4d1645dabfecb578bdd2f95232b57e8d78b346d37c4be11beb3dd14f63a85ab2acf1b2c8acacbf2c8ad5f9f7e32d264f0ff0089352d2e55656b5b868d7fddfbcbff008eb2d694aa731955a7cbef44e6e46af78f86fe1fd26ebc0f6fa83e9b1c4d35bb473337cccdf36dff0081570bf09fc1f0f88f549aeafecfcfd3e1fddfccdb55a4fbdff02af52f89132f87fe18ea16f65b608f6c71c71c7f2fcad27ccbff0002dcd5529737ba5d28f2c79a4749e13d36c6c34585ace18e08e493ce68d5b72eedbb5be6ff0080d7ccff001125bcd07e296a575710f9527db16ea1feec91ff000b2ffdf35ebdf07fc4d25d7827ececde6c96b71247f37f12fde5af31f8e1e37d27c51a8436ba746b737567ba19350fbd1ffbb1ff007bfda6a23eec8aab28ca9c4a3f17bc4126b3af58dbfccb6f6b6aacabfc2d249f3337fdf3b57fe02d5c5afdda8ee2fe6bf9966b891a591638e3566feeaaed55ff00be69cbf76b638e52e697312f352c6db2a0a7ab5412761e07f186a9e0df1169fae68778da7eb1a7c9e75bcebff8f2b2ff0012b2fcacbfc4b5fa85f027e38693f1afc231ea96aab67a95bb2c3a969bbb7359cdff00b346df795bf897fda56afc9586e3ca6dd5e89f0a7e2c6b1f0abc5967e24d0595ae215f26ead246fdddf5bff14327fecadfc2df357998cc2fb68f347e23d5c1e2bd8cb965f09fadd7d6ab711fcadb5ab8fd596e2d59bf78cd1ffb35cff827e32693f123c1f6be24f0f4d2de58cdfbb9a065fdf59cdfc50ccbfc2cbff7cb2fccb593e26f890d6bba158d5ae9beec7fc5ff0002af959464a5cb23ec68c79fde89a1aa6b9f675fbdbbfde6af25f88df14ac7c3b04c6e2e37cf1c6d2344adfead7fbccdf7557fda6a87c41e20ba6b791ae2e9bcc6fbb1c1f7bfefaaf88be3d7c4c3af6a92e81a5c9ff12eb67cdccaae3fd2265cff0017f12aff00e3cdcff76bab0d86f6d21633111c253bb2cf8fbc79aafc6dbc9b74ff0065d12dda4fb2d9c6cdb5a4ff009e8dfde6ff0069abc4f0d1b3a15f9beed74be0af1147a3c972936ef2d97cc5dbfde5ff00ec735574f5b3d63c5f6c972acb697773b5c4676f0cd8afada74e34e318c4f80ab5a55a5cf3dcced2e7934dd4ed2ecaff00a99964f997fbbf357b8eb1e2bb1d374bb7bb59566826917e656f9bcb66dad27fc06afdf78374dbed266b1fb3afefa35566fe25655daadfef7cb5e01a9c37560eda7ddc6d14d6b232b237de5adbe133f84d9d5bc451ebde28b69e5862f2d5840dcfcacbbbef5751e35d07cef0fb32c7f35afcd1ff00b2abf797fcff0076bcc1636666daa5b6f35eb7a5f88e1d4bc371dd3b279cb1b2cd1337de655ffd9a88fbc49e46aadbaae5bc5b6a9c6db5bfd9ad4862568f72d4c408da92a564db4daa01bb69d4514013436ecdf76b52dd5a25a86cff00d5d48cdf35004de6d1baa1a9168024a2994fddef400facebeb8f9b6ad589a566fddc5f33550be8fec96eceedf37f0ad004be1fb0fed6d7ad6ddbfd5ab79927fbab5df687e036f177c4a7d35176dac8df6a99beefeedbf87fde6fbb5c8785f51b7d0ade49e7fdedd5c2ee58d4e3e55fbbff007d57b8fecc3a94daf6b5e2292e238bed0b6b67b59576eddacd1edfef7f17fe3b594a5cb1e637a518ca5ca7d55f0c7c330d87d86c6ced56d6d6155dd1c7f32aaafcbe5ffbdb76fcdfed5796fc05f819a1f8a3e3e78ca38162d43c23e17bc92dd6292e99a6691bfd4fddff0058bf2c8bb99ab8df8f5f172e975093c17a1dd34567a7f971ea1776cde5b4d70bf7a15ffa66adf7bfbcdfecad77dfb04f8ca6d37c697de0f5b58e5b5d615af1a7ddb7c968636ddfc3f36e5dabfc2bf7ab8f96518f31d3527194b9627dc56be72ab35bb4914db76c6b036ddbb7eeed6ffd06bf327e225adbdffc40d6a1d1acf57585aea458edb548d9afd997fd6798abf36eddbbe5fbcb5fa0df193e2e69ff0006fc0f7dac3b5adceadf2c763a6cb32ab5c48cdb776dfbde5afde6ff0076b95fd8de5b1f1378375ef195c69abff0955f6b575fda1acb2b34971bb6c8ab1b33332aaab6ddbfecd671972fbc41e0bf0eff0063ff00884ba4e9fe2c7d4b4cf09dc5ac9fda11c7aa798d35bc71af98b248aaadb5be56fddb7cdf2fcdfddaf1df891f10f5cf8a5e2a935ef10dc473df35bc36ead1c3e5af971afcbf2ff0eef99bfe055faad796bfda367756aad179970ad1b7da61f3a3f9976fcd1b7fac5ff67f8abf2cf56d1b54f889f12b56b7d074dd4353d42f350936db2c7ba6dcd26ddd26d5558fe6ff0065557fd9db5a427cd2e69167d19fb02eb97d7179e2cd167bcb9974bb7b58ef2dec7e6686191a6db249fdd566555fbdff00c555cfda9bf68cd2756b7d43e1de936be7dbc3a82daeb577731fcbfb9b88d9a385b77cdf346db9aa6b1fd97f5ef86ff076fbfb3a6b9bcf1c6b12476b78b6d78cb61676ecccb26e55ff005cab1fcdb9bfe02bf2fcdf1ec32acbb597e656f9bfdedd52a3194b980fd968d6dededede3b28e3b6b158d7ecb0c0be5c71c7fc2aaabf2aad7e73fed69f0d26d1be394db6e2d96df5c5fb747e45aadbdb59dbafcbe5aedfbde5ac6cccdfed57d2dfb23f8a2d65fd9f74f92e356f364d364ba5ba59ee3cc6b58d59997e5fbcabb5777fdf55f34fed7df16345f1f78a2d6ebc357df6eb7874f9b499aeff00e59b7efb73797fef2ab6e6fe25916b38734640707f02fc24bf157e3169363f6766d16ddbedd711b7fcb3b387eeab7fb4cde5affc09abb4fdb03c79ff00096fc56fec382456b1f0ec3f676dbf75af24dad37fdf3fbb8ffe02d5de7c07b0b5fd9ffe02eb1f11b5987fe26dab471dc5adb37de68ffe5d21ff00b6923798dfecff00bb5f2ab5d5c5fcd35d5e4cd3de5c48d35c4edff2d2466dccdff7d35691f7aa73164327fc06bec2f827a6c7f01ff67fd63c75aa46b16a1a843fda0ab2afcde5eddb650ffc099b76dffa695f37fc27f00c9f12fe2168be1f5566b7bab8dd78dff3ced63f9a66ff00be576ffc096bd7bf6daf890b7fae58f81ec36c5a7e96b1df5e471ffcf665fdcc3feec71fcdb7fbd22ff76aa7ef4b900f31f857f067c41f15747f136bd05c59c5343fbb8e7d426f256e2e24915ae195bef7cb1b6eddfed2d778de28d07c51636be13f8fba1ea1a2f88b4fb79a1d3fc4d730c8b7325beedbb772eef336b6ef9bf791b7f16d6f99a8f8b3e1f7c4ef837e0bf01ea905f48da7e97336a51c7a6dbb2b6937d37ef24f39957f78bb5555a4ddb7ef47f2ff001761a1fc6ef87bf1e343fecbf8ab1dae9579a7dc49a9433b334364dba4f9ade1923dd247f7bfd5b7dedadf7b6eda99734bde00f0fe8bf15aebc37671f83fe227873e27f83668e46934ff0015471c9e62b36dfb3dc4722c922fdd5dbb9976b37cb591e13f88fa97c158d9ae341bef8477524ccd269325add6a5e10d4999b6eedbb9a6b1919b72f990ee5ff65beed6cc7f06fe10eb3ae6a1a97817e2d3784e6b8864b55b1b1d4a36691a465558d7ccf2e6f2777de8d99b77f0b2fdead6d0fc4de24f82de2693e1efc5df1669fe2ff00ebd633430ea5aa349e5dab46bfeae6f315a48d5be556ddbb6b6d915be5acda5220f7ef84bf16b4df88d0d8c66ddb46d72e2ddaea3d3e4996e21bc8d7e569acee17e5ba8d7f8b6ed923ff9691ad7ba68bf76bf327c29f0dd745f8b5e28f83b77af6ab6d6324cbaa785eeeda655b8b7d4963592d6ea19b72ac72490b346cdf764f9776df9597dff00f67bfdb46eb4ebd6f057c6fb697c35e24b19bec6de28b9b7fb3d94d22b6ddb79fc36f27ddfde7fa96ddf797f8b0952e5f84be6fe63ed15a92a38feeab7cacacbb9597eeb2d4959464572853e994edb4c9168a28a0a0a651450014514504851451414145145048d6a6b539a9ad41479851cd2b532b1361dcd2352f34734008b56adeaaad5a87ef558a45e86ae475461abd1b7cb412588ea65aaaad4efb42ad5905a66aa77578b12b6e6acdd535e8ed636556f9abc17f690f8e771f0b7e1dde6a1a7379be24be6fb0e8f1aaf98de732fcd36dfe258d7749fef6dfef528c652972c48e6e53cbff6d0fdacae3466d43e1cf82ef1a0d436f93ae6b36cdb5ad5597fe3ce16fe19197fd649fc2bf2afcdbb6fc16d70aaaaaaaaaaabb5557f856b4ae346d62ea491974dd4ef2466669246b5919a466f99999b6fcccdf7ab2f52d2752d2555aff4dbcb18dbf8ae6de48d7fefa65afa2a508d18f2a38a4e52f7a437cddcd4eddbaabc7f3549bab424eabc03f1235af869aa7dab4b9965b791bfd234f9ff00d4dc7fbdfdd6ff00697e6afa6a6b7f05fed41e0b692ce66d3f5eb15f95a4f9ae6c59bf85bfe7a42cdff01ff75abe396a9b41f136a9e0fd72df56d1af24b1d42ddb74722ff17f79597f895bf896b9ea53e6f7a26919f2fbb23db3c13f1235ef80fad5d781fc5f0ffc49f76e8e45fde2dbeeff0096d0ff007a16fe25fe1ffbe96b91fda12d636f1643ad5bc91cf6ba842bba48db72f98bfed7fb4acb5e8de28d6749fda3bc070dc234563e22d3feeffd3bc8df795bfbd0b6dfbdff00b32d785f87fc4dfd8335e7867c4d6aab63e66d9239e3dcd6b27f795bfbbfeeff007b75443e2e6359e91e5fb2765f0275293ced5a16665b5558e456fe1593ff00d9a8fe3678d21fb0c7a4c1337db23b856923feeaaaee56ff00816eaef3c3fa4d9e8da3d9dbd9f972c2aabb648d964f33fbadb97ef7cb5e2ff1bafecef358b38ed5b66a0aacb75b7f85777cbff026ad63ef4825eed3e53cefed570cd34715c4b042df2cde5b32f99fecd47332aaaaafcabf77e5a91b6c51aaa2ed55aaedb99be5ad8e32c47562aadbcbf2ff00bb536ea009285ed51ad396a00b0b534370d149b96abad3b75007a0fc33f89daf7c2dd75f5af0f4bbd6e17cbbed3646db0de47fdd6feeb2ff000b7f0d7d25e1df8a7a478f34b92fb4ab891641cdcda49f2dc5b37f7645ff00d9beeb57c610dd35bb6e5ab121fb4dc477965712e9ba8c3feaee216dacbff7cd79d88c1c6b7bdf68f670798d4c2fbbf144f70f8fdf14dbc2ba07d8ac66f2f53d4559610adf3450fdd69bfde6fbabff0002feed7c88fb99b26ba8f175d6b3ac6ad2ea1adcaf7b72f80d72ff00776afcabf77eed60347e95ad0a1ec63ca73633152c554e6fb2568dda291597e565abba24a90eb16734a76c71ccaccdff0002aaff0067dd56a1b3dd1ffb55d5ca79e7d310de2f99b97e6f33eeaff157837c4478b54f15c97968fe7c7791c732b6ddbb9b6ed6ff00c796aeea5f11afdb47d36188aade5beddd37f12c91b7cadff025ae4edf549ed6f56f30b248accdb645dcbf3554a454a477ff000dfc1f7567e20371776ecb1c71edf99772c8b246df32d54f8b3e1d4d16ea1b9b28bc9b2bef99a355daab2aff0077eaad5ec5a0b47796b6b71032cb6f246acacabf7b72d72df1a34b375e0d59846ca6dee639997fd96dcb415cbee9f3fd59b5b86b7ff76b775ef09cba378774dbe951924ba666ff00795beeff00e82d5856bf32ed35266692dc4770bf2b539625aa2d6ffddf969d1de496edb5fe65aa02f7d9ff00bb4dfb3b54d6f710dc7dd6f9aad7d97fbb4015e359156a45dd5235bc8bf7577537ca9ffe79b500253f77bd396d666feead4d1d9aff001333500575dccdb57e6ab11dab37df6dabfecd4cbb57e5155ee3528ed7ef36e6feead00493343676ecdf7556b9b51378835586dd3ef48de5c6be946a97b25e7dff00957f8556ba0f85ba4ff697891642bbe3857ff1e6ff002d5320898f344bfda122a7ccb1b796ad5f4c7ecb3e01f175fc336a160b69a2e877d716f24dab5ec6cd34d1c2cdfbbb755fe166fbcdf2ff00777579ae8ff096e7c5df15b53d12394c3616f279935d4717ddb7f976f97fed37dd5ff76bef2f06e896ba4e9b6b63a7dba416f0aac36f0afcab1aff000ab7fb35855a9eef29d74a96bcc7c1fe22d1ae346f156a5a6dd5d417d7d6f70cb713db49e646d37de936b7f17cd5f467ece7e12f895e0bd175ef1d786bc1bfda6ada7fd9ed67be91635dadb649268d5995a45555ff003f3569f827f679d2bc51fb5378badafecbcef0a68661b992d8fcb1cd34f1ab2c6dfef3349237ff00655f70cd6b1dc68775636f6be6ab5ab5bc768b37d9d5a3dbb76f98bfead76fcbb97eed73ceafd91c627e59f8ebc79aa7c48f135c788359b8fb4de5c6d55feec71afdd8d57f8556be82fd825afaebe236b51fdaa45d361d26491a0691bcb691a48d772c7bb6eedbfc5b7fd9fe2af9ad6dee3c47ae343a6e9be6dd5f5c37d9f4dd36166f9999b6c30aafcdb57eeaff00b2b5f547c3bfd943c79f0fb4987c7979e2cd33c21369b6b36a9716325bc9753471c31f9caacaacb1b49f2ffab6f957fbdbaaa7cbcbca113e98f8c5f1c34bf81f67a3df6a9a7dcea7f6e9a48e3b4b4915645f2d777cdbbf87eead723fb19ea563e23f02f88b5efb2c116b17de20be9ae9976b4db6665923566fbdb555b6fcdfed57c27f103c79ae7c44f176a1e22f10b7fc4daf195a483cbf2d6dd557e58557f85557e5db5f467ec0775aa4be28f174305d4ffd931e9f1c925a2b7eedae1a45556dbfdedaadf35632a7cb4c67d6df11afecf4df873e2ebcd42e25b6d3e1d1ef249a7b66559157c96fbbbbf8bff8aaf82fe0ff00ec9be36f8a56f1dd3c71f8574bf2d5beddaa5ac8bbbe5ff9671ff17fe83fed57aa7ed31fb4758eb32788be1de9d0c179a4de431e9b7daa2cdb7cb93ed11b49e5ff00795555a36fef337f757e6fad23f1069f71a7c371a7dc472d9ccab3472472798acacabb76b7f75976fdda8f7a312cf8e7f6a8f85f67fb3ef85f4587c17f6cb1d3f5a8e4b1d62edae374979247b5955bf8b6b2ee6dabf2fcb5e03f067c0737c5ff00881a3f86d976e8b6ecd79a948bfc36fb97ccff008136d58d6bddbf6fef1c69b7ebe1bd1d9636d52d5a69a3915bfd4dbb6d5919bfde68f6affbb253be13dbdbfeccff00046f3c59acdaabf89358f2e48ec64fbccccbfe8f6edfdd555dd249571972c3fbc5fc461fed99f105756f14697e0db0655b1d1d56eaea38feeadc48bb638ffed9c3ff00a32bc0634f968babfbcd6752bad42fee1af350bc99ae2e2e5bef492336e66aeb3e19f8164f88de38d0fc371332adf5c6d9a45ff9670afcd237fdf2ad5b457b3887c47d29fb38e83a7fc20f83fac7c48d723559af2ddae1777defb1c7feae35ff006a6936ff00e3b5f2fdc36bde266d6be205edbc972b1ea90c97973b7746b7533348abfeeaf97b7fef9fef57bd7ed99e3c8ed5747f877a46d82ced638ef2f208ff00876aedb587fe02bfbcff00be6ac7c1bf8a5f0ee2f84b7de09f12cdfd950f9735af97e4b37db166f2d7ccdcabfeb99999be6fbbb57fbb58c6528c79bf98087c3bfb6bdc5fc7751f8af4389e45b7b89167d266687cc93733471ac7f763dcaccbbb77fb55621f11fecebf122f34bd1ee343ff00847a4863b7b7b59e485ac55b77fcb169a1feeb7cbba4ff00beabd826f84ff04e2d0f56d0dacfc3ed1e8ab269f793c9a82f9d62ccabe63798cdb9646f95bccfef7dddb5ccf877e07fc09d7b58d63c3fa5d9c1a9df431c77932c7a94d3346bbb6ac70c8adf7777dedbfde5a9e65f640f3bd53f66ef867e28f00f8dbc41e10d4afaf2e2cdaea4b38fed5fbbb59218f735ab2c8bb995b6b36e66ddb5976b7f7ba0d074693f698fd9874fd3e2681bc49a4c71d9acf72bf76f2dff00d4ee6ffa6d6ede5eefbbbbfddab1fb3de87a4f85fe367c50f8577eb1cba0df36db5b4b9dcad711fdd655ddf337ee66ff00c777560fec83e37d27c07278e3c2facdd5ae9f0dbccda82df5dc9b5645b7dd0c8adff01dadfdef99aab9a441cce87a0f827e29fc29f04c3acf8fb4ef0078dbc3b249a5b5cea1b9a4b88d66dd0ab6ddadf2ab2f9726edabb595abd1f4cf873f1074db7934dd13e37787b5f68f4bfdde9fe24d3a3d5239a36f95bcb93748cb6adf32fcdbb6ff0012d6bea1fb2ffc1bf16ea17d79657df638f72dc490693ae42b1c31ccbfbb5f2d95bcb56dcadff8eff1579ef8f3f637d53e13e9b7de32f01f88b538b50d0ec56fad57cb55bb9a48e46fb432c91ed55558fe6555ddb955bfdda9d25ee81d27c23fda43c5ff0003f4f966d5bc2c979e02b1d4a3d17c41e1ed166924b9f09df37cab25bc3336e5b59bef2c6acd0fcdfbb68ffd5d7ddbe15f1668fe38d0e2d6341d422d4f4d999a3592356568e45f95a39236f9a3915be568d95597f8abf3d358f1d6a9a4eabe0bf8fb6fa5db5f7847c41a2c3e1ff1f58d8c6d35bb6d91a193ce85bf876b2ed6fef2aaff0012ee758f8f3c71fb26eb57d71037fc255a1ac70de693e208e6ff0046f10696ccb1c30de7f0c8caacb1c774bfbe859555bcc85956a254b9839a513f48e8ae03e0bfc6df0b7c7af088f10785ef0b985961bed36e36add69f37fcf3997ff4165f9597e65aefeb9a5cd1f7645fc43b9a6d3b9a6d30194514500145329f4005145328287d14ca2800a46a73532803cc1a9295a92b1361dcd368a2801eb5347f7aabab54d1b55817a3ab51b7cb5455aa3babe8ed63dccd4189a1717ab6ebb99ab9bd53c43f7951ab2f54d71a566f9be5ae76eaf19aaa31024d73c411d9d9dc5d5d5d476d6b0c6d34d3cedb5638d57733337f7556be4bf1d6a1f143c75e3c9bc49a0d9d8e9fa2fd8fecba5c7aa4d1acd1dbb36e691a36ff0057248db5997f857cb56fbb5eb1f10b54ff0084b75a6f0dc4dbb47d3648e6d61bf86e26f96486cffdd5f96693fed9aff13557f9b77ccdf79be6ff006abba94797de27e23c464d2fe365ab7989fd99a87fd338daddbfe03fc3556d7e335e68379fd93e3cf0edce9570df36e587e565fef792df797fdd66afa22c6d7737ddf956ae6bde0fd27c61a4ff0067eb3a7db6a766adb963b95ddb5bfbcbb7e65ff80d6ee5fcc1ef47e191f36de7c0ff0003fc4eb39b52f096a5158dc7de6fecf6f321566ff9e90b7cd1ff00c076d783f8e3e1feb9f0e7545b3d6ecda059377d9eee3f9a1b85ff00a66dff00b2fde5af76f889fb3df893e16ea4de28f00dd5e5cd9dbee91a38db75edaaff00edc47ff8f7f795bef56d7827e2c7867e38686de13f16d9c106a174bf2c7f761ba65ff9690b7fcb39bfd9ff00be777ddaa8d4947def8a26528c65e523e4d65f96b36e1b6b57a77c60f847a87c2ad4236f324bed0ee9b6dadeedf995bfe79c9fdd6ffc75bff1daf2db86dd5d719737bc724a3cbee97bc33e2dbef06eb90ea564db997e59a066f9668ff8a36ff3f2b57a678c347d2fe2be931eada7491db5e32ffa3dccbf795bf8ade6ff003f2fde5f96bc5e66abde19f155c785750f39646fb1c8cbf688ff008597fbdfef2d3947ed1519fd991d9f827e27378274ed4b45d6ad6637b62acb696edf79a4ff009e2cdfddfe256feeff00c06bcf2f2ea6bfbcb8bcba93cdbab891a69a4fef3355ad735a9bc4dad49aa5c2ac4ccab0c2bb7eec2bf7777fb554dbeed546244a5cdee95e4a8e1f95aa46a8d6992170ad1379c9f37f796a48e5565565f9969d1b6cf95beed57922fb2c9bbfe58b54016969cb51af6a916802456a7d44b522d003f9a66edbf769fcd4134bb56802e43aa32fcaebb96aadc683a6ea5f340cd6d27fd33fbbff007cd536968f35968e52f98ab75e19bcb56f93cbb95ff65b6b55786de68a4daf1b44dfed2d6c2ea932aed6f9aa39b54f97fd5b3337caaabfc5410666bba70b58ec2e57e56bab7f3244feeb2b6dff00c7be56ff008156647134b22c6abf3357a17c46f07df787fc33e189ef822cfe5cd0cd1afde85b7798b1b7f7be56a7782be15de6b17fe55f7dab4a76b55bdb39963124727f77e6ff00be5aa798ae4f78ea3e07ebd22d8ea1a2dd6efb469ead796f1c8bf3796bb9a45ffbeb6b5798788bc4d77e2092401e48acd9a4f2e366dcde5b49e62c6dfdedbfc35ecff1ab4992c74dd33c4fa74925b6a56a56cee2e63f95a48e44dbf37fe83feeb5784c31505cfddf74f77f125ac3e36fd9de6d6ad955ae2cfc9699557fd5c8acab22ff00e3dbbfe055f392398d8357b3fc1fd5a49b4ff13783e5ff008f7d7f4f99addf77cab710c3237fe3cbff00a0ad78a377aca212d63191ad1bf9b1d433454db36daab5a4d6fb9772d6e6465c6acb57a1bc9a2fe26a8da3656a16803521d51a5fe1a9bed8dff3ceb1fe6fe1ab96f2b37cad40173ed4dfdda8e4bcdbf7e4ff0080afdea6531b6c4bf2ad00437171712afcbfb88ffbdfc5545b6aafcbff007d355891f755592802adc35777e07f10af847471a8240b73753dced8e3ddb7e555f9bfcffb55c2c7135d5d2449f7a46555ad9681a0bc9a16568fc96f2d55976b7cb5211f74fa13f66ff145c7883c7d369ba8b2cba86b4de635dfdddab0c7f2aaaafcaaaabe657d19f173e2fd8fc27d36de1b0fb35e788a69236b7d3e45dd1c30ee5666997fbacbb9557f8b757cff00fb25f85f58b5d5afbc5965a5c1a9aadbcda6d8c73ccb1f9974db7e5ff6576b6d693ff896ae07c61ab6a1acf8cb5abed5265b9d424bc916692393cc5dcadb76ab7f12aeddabfecad73ca319543af9e51a67d51fb1df8f95bc41a959cff6bd4fc51e22d6bed1232c7b9561f2d7cc9a46feeaed655feeeef96be9af8a9f163c3ff097c330dd7885a491752fb45ac36d6d1b335c3796df2eddcbf2fdddcdb96be13fd996ff00c41e1cf185d789b4ab1bc974fd374bbebaba915556ddbc987e559a46f95635924859957e66f9557ef567fc60f8b9ac7c5af115bde6a53335ad8dbadad8c0caabe5c7f2ee66dbf2f99237ccdff7cafcab58ca1cd507197ba7d0dff04fff0005e9b2c7e22f155d5ac12ea967710e9b673b7deb756859a4dbfddddb95777f76bec0f115ade5e786756b7d2efbfb2b529ad648edef96dfed0d6edb7e5658ff008997f857fbdb6be11fd89759f147fc2c2b8d1f4b924fec19236bed422f2e3f2fce55f2e1dccdf32afcdf763f99b6ff00bd5f5b7c56f8f1e1ff00837a7b35f5e47fdb0d0b5c58e9bf334971f332ab7fb2bb97e66ac27cded0a89f9ebe0bf877e24f8b5e2ab8d3746b79f53d41b75c5d4f7726d655f336b492337cdbb737ddfbdbb757d91a4fecaba0fc21f877e26d62cbc41ac378b21d16eb76ad04de5c31b792db9a3b7565ddf2eedbb9b72eedd50fec57a35abf8375af155c5bc8de20d635099af2f9be5591564dcab1aff0aee66ff817fbb5ef1e2eb868bc1be2093ecf15cc90e9b71711c13c7ba36658da45dcbfc5f32ad54ea737ba23f27559b72fcbb57fbbfddafb03f66df8b51c5f0c6e34dd4b548a25d166f2d64dbe5f936ed1eef9bfbdb7f79f35799fc07fd9af54f8916ade22f134779a6e8325bc7716f3c9f2c9a8349f36e5ddf36ddbbbe6fe2dd5adfb5a5d683f0efc3ba6f85fc35a7c563ac6b51c7f6c5b15f2d9ad63f97eeafcbba6917fe05b5ab49cb9bdd2ce57e1ee9b37ed29fb426a5e26bab566f0ed8cd1dc34127ccbe4afcb6b6edfef6ddcdff02aa3fb427c50ff008591e3a6b7b0b8f3f41d1f75bdac8adf2dc4dff2dae3fe04df2aff00b2bfed577de268bfe19cff00679b3f0cdac8b178b3c49248b79731b7ccaccabf6865ff00ae71ed857fdedd5f38d9dbac4aaa1762ad14e3cd2e60fee96a15afb03f669f07e9ff0009fe19eadf143c4cbe4497566d25aab7de8ecd7fbbfed4cdb557fd9dbfdeaf9c7e14f80e6f897f10345f0da7cb0dd4dbaea4ff009e76ebf34cdff7cfcbfef32d7b67ed8df11bfb4b5ad37e1be86bfe8ba7b4325e5b5b7f14ccaab6f6abfeeab2b6dfef32ff0076a67ef4b90b3cf7e12b5bfc5dfda2aceebc550c572baf5d5d4935b49f347b9a193cb87fda55daab5ed9e30fd87b4dbafed093c33ae4ba64925d2cd6f6da86e9a186d76fcd1fcbfbc6656f9959bf87e5ff006abc67e237ecfbe3af85fe22b75d3b43d5752874fb3b1ba6d5b4bb569156ea4f9995597e6dd1cdf2ff00c056ba29356fda22e2e358dd378956eb499bfb5af157cb592392487f857f8b6c7f3796bbb6ff00755aa65ef6b1901bd75fb08f8896c669ac3c49a65e5f798cb0c725bc90c7247fed49f795bfd9dacbfed543e01f02eb1fb3ff00ed31e15d1dd74fd73fb597ecf6f7ad1b2c7e4cdf2c9246bf79648d9597ff00daaf2bd7b59f899a6b787db59d53c4b04d70b0ea5a3fdaee24691b6b6d8668d59bef6e6ff7be6afa33e3b451d9fed19f06758b8f3e25b89ade1b8927fdcfef23b85ddf2fdd5f9a4f9bfdea52e6f864053d7b41bcf0a7edb9e1fd73598d7ec3ad48d2697731cdb7f78b6be5af99fed2b7fdf5b96ba0d7bf632f06f8cb5ebad52cb5ad62cdafa49ae24b4b192dee1564f33f78cbb9776d5666dcbfc2df2d58fdab3e016b9f141749d73c3de55cea1a4dab59b69723796d711f9ccdba366f9772eefbadf7bfbd5e2f6ffb1cfc50d36cdb508aeb48d3f526db1c36906b5e5dcc8b27facfde2fcabb7f89777cdb7f8aa54bddf880ed2fbf611d162b8be64f1a5e59dafee61b7f3ece191a1b866f9bcedacbf2b2f97b5576b6e6ff00beba0f827a36b9f01fe314df0d756bc9357f0cf892ce6bad16e6e5996359155b72f97f7559b6b2c8abfecb2fdeaf2bbaf873f1d343f08f8d2c6e2e352ff847ece169352592f9645bc8d76b3496ecdf349b5557e65f9aba2f891f112e7e227c11f00fc49d2eea7b3f1bf84f52fec7d42ee0ddfbb9a48774737cdf2fef3cb56ddfed32d1ef7f3017bc1b7fa0fecbbe24f891e01f1e69f3de78375e8d6fb49916d5a65bcb7f9a36876fdd5fddc9b5bfda87fddaf1bf8d5af68fa0f846d7c03e0ff1b4fe2cf87b6baa49ab58db5cc6de669ade5ed685646ff591fef1995b6afcdbbf8abed4f1169bf09fe39f86749f147892dedb53dda1c9750b2dd343730dbafcd71b6356f9595a365ddb7e5af877e03fc3987e327c68b1b14b1fb3787639a4d52fa0dcccb0d9c6db961dcdfdefddc7ff0002ab84bed48394f7092d6fbf65df81fe07f18690d1d8f8f2d6485774bf2c7791dd334d358dd2affae87cbff8146cbb976b7defb27e037c78f0e7ed0be093af6825acefad9961d53459e4dd71a74cdfc2dfde8dbef4722fcacbfed6e55f84bf6def1f2f88fe2058f866de45687438da6badbf77ed537f0ffc063dbff7d5727fb25e9be2e6f8bcda97823568b48d634dd366b891aed59acaf23dcbb6cee957fe59c8cdf7bef46df32fdda9e4e6a7cd214bddf84fd61a6571df0b7e28e9bf15745bc9edade5d2b5bd2ee9b4fd6b41bb915ae74bbc5fbd1b32fcacadf7a3917e5917e6fef2af635c7f0fbb22e3ef0514514c919451450505145141214514fa0a194c6a7d31a803cc5a929ed51b35626c2d26ea8d9a9acd56049bbdea456aabbaa39ae96dd7735041726bc5823dccd5cdea9ab79adf7be5aafa86a8d70df7be5ac5b8b8ad231024b8baae67c69e2a93c2be1f9af2de15bcd526916cf4db46ff00978bc93fd5affbabb5a46feec71b351e2af1469fe12d264d4b56bafb35aab2c71aaaee92e246fbb0c31fde9246fe155af37f106b971a5daffc24de2892cf4cb8fb3c8b676d7336e8f4985bef46aabf34d7522afef245f957fd5c7b977336b4e3cc4486d8dd697e15b1b5d2e7d6209eebe69249e76dad793336e926666fe2924666ae8ac6d64ba863996393c993eecedf2c6dfeeb2fcad5e3f1fc5ef87b7fa87f66af892cfcc99957f7f1c8b048cdfc2acdfbbaf5cf0cf8657cc58d2e9bc39a95e5c2c31dde8d2496b73b9beeb48abfbb9beeb37ef15be55aeb97347e20f77ec9d358e9bb6356fb95b90dab6d5f97fe04b58be19f135c5d5bf9379358eaacb3491ac96cbf65bd91559a3f9adf6f93249b97fe59b47bbe5f956bacd2ee2d756b3fb5594cb736fe6342dfbb68e48e45fbd0c91b2ee8645ff9e6dff8f567cc4f29556dd53eefcbfdd6af9bff0068afd992dfc470dd789bc216eb67e2056f3ae34d8fe55be6fbdba3ff009e771fc5fed7fbdf357d45244bb7e56dd5ceeb570ab0b465be5a23eecb9a24fc5a1f0cf847e2aaf8fb499bc1fe2f6fb4dd491f92b24ff2b5c6dfe16feeccbb7ef7fb3fdefbde23e3af0add78235c6b19d9a7b793f796b73b76f9d1ff00f14bfc55f4c7ed21f066dfc51a85c788b415fb0f88376eb883fd5adf32ff00cb45feecdfed7f17f17cdf3578ee97ad5afc52d064f0ef883741af5aee686e76ed91997f8b6ff797f897f8abb29cbed448a9194bdd91e43235578d7ed571b7fe58c6df37fb4dfddab5af68f7da0eab2e99751f9776bfc6bf75a3ff009e8bfecd11aadbc6b1a7dd5aec3847377a8e66f96a4aab74df32d0046cd4dddf3514e87e6916a00b1b6856f976b2ee5a735250056915acfe6fbd0ffe835346cacabb5b72d491ff00e3b50c966d6ffbcb7f997f8a3ffe26802c2d48b556195655dcb536ea00919aa8ccdb9aa699be5db555bbd00145145580377ad8f87faf5868be223aa5fdab5dc36b1ee8b6fcde5b6edbe76dfe2dbffb357397524b26cb78959a595b646abf7ab4b5cf07ea9e0d8ede4bb08b1dc7996e1a39377f0aee56feefdea82a3fcc6f78f7e23dc78b23bad356de0feccf315a1664dd32edfe2ddfe7e56db5eadf06f568f5ef0759a2aac571a77fa1ccabfecafcadff00025ffc795abe745f9abb3f85be359bc11e298665556b1bc65b7ba8dbfbbbbe565feeb2d44a25d39fbdef1f4eb782d7c65a6de6972c6cd69710b2cccb0f99b7e5f976aff7beeedaf95342f0edbea57fa745717329b66d523b1be6821f9a18646555997f87e6fde7cbfde5ff006abdf3e2efc48bef0569f6369a35c6dfed6b3bc8666dcdbbcb668fcb9a365fbb22b799b5bfdeae23f671d7841f17b4eb5bddb259eb937d8ee176aedf399bcc864ff80ccabff7d567ef72dcde7cb29451effe2cf80d6f0fc05b8d362b58cf8b7c2f6ada85adfd8c6ab334d0eef317e5f9996455fbbff02afcfb3f78d7ec7f87eddb4bb7924fb3f9ad1ff0b2ff00b5bb6b7f77f896bf2c3e39781e2f877f163c45a05bb996dade7dd0bb281fbb755917eeff00bd8ac68cb9bdd1568f547156ab5b562dba1ff696b2615db572de5f2a456fe16fbd5da721a0d02b2fccb55e4b3feed5e5a750065adbb6efbb5721b5f97e6ab1f2d3b750042d12afddaa378db7e5ab57571e52ff00b5547ca695be6a00aebb99b6afccd525e5bfd96dfcc95be6feed685bdbac5f76b1f5cb82d3797fc2b401a7e01d3cdf78a2db77dc873337fc07a7fe3db6bacd6bc3775af7c44974cb050f757114727cbfc3f2fcccdfeefdeae73c077d068ebaa6a13866f2e158a345fbceccdf77ff001daf53f80fadd9ea5e3cd4a4d42391b54d5123b4b65b68f76c8f6b349b7fd9db1ad652972c4d6118cbdd3eadf843a4c7a4d8d8d9d946d05bdaed86df6afcdb57f899bfbccdb9abc457e0cde7c57f8ede30d17c3eb6d67a3e9fab491dc5dc7f2c76b6fe76ddcabfc4dffa137cd5eade2cf89da7fc27f0cb48de636a5716b37d863dbb95a45dbf7be6fbbba455abdfb14f8cbfb7adfc596f7ed0cdad4da87f6a5e5ced5569164ddf37cbfc2b22aaaaff00b5fed571fbd1f78edabcbcd1a67d2da4fc3bf0ee9bf0af50f04dbe93241e1b9ac6485ac6d19566995bef6d66fbd3332afef1bf8abf35756d06fb4df115d69371a7cb67a94775f676d3ff00d6491c9bb6f93f2fde6fbab5fa98dab5af87f4fb8d6351996ced6ce392eae279feeac71fccccdff8efcbfed5786fec7bf0af41974bff0085817b1c7a9f8ab569a6be8e4bbfde7f67c6d337cd0ffd346666dd237cdfc2bb7f8b3a7539798cd9c9fece3fb377c42f097da3c5d2ea96de09be8e39ad574dd66c649a4923dbf349246acbb57fbaacdf36dfe1af99fc59e2dd6bc69af5c6adae6a53ea77d333334923332aab3336d8d7f863f9be555afd58d7bc3f0f8ab4bbed16e1ae56d6f23fb3c8d6d279726d6fbcaadfed7ddff8157e58af8375af1478caf343d0743b9bcd53ed5710c7a6db2ee68fcb91959777fb3fdead29cb9a5294847d45fb07f8c3cd6d73c23f658d5955b566be92e199a4f9a3856158f6fdd5f9999b77f12d76dfb4e7ed0fa2f82f41f107846c965d435cd42cee34f9becd70b0c962d35afeee46dcbf32fef36b2fdeaf27baf82df11bf661f09df788b4bd7a06d72fa68ed5a3d12c64ba923b58d5ae2491a46ff56bf2fcdf2fcdb57e6dad5f2fcd7525d4cd34b3493c9236e69246dccccdfc4cdfc4d531a7194b98b3f433c1ff0012349b5f817e1fd72eae3c8d2f4dd1635b893cb68d7f731ac6de5eefbcbba3dabfde6af967e12daea1fb427ed01a978db56b7ff45b19a3ba5819b72c727ddb5b7ff80eddcdfeed79eeb5e3ed52e3e1be93e03b3ba9ef2d66befed0b8b655f99a66f961b55fef2afdeffae927fb35ec9e3c5ff8678f82ba5f836ca455f147881649350b98dbe6556555b865ff00c7615ff81354f2f2fbbfcc0799fc6cf1e2fc48f891a85f5accd2e8f63ff12fd35bfbd0c6df349ff6d24dcdfeeedae4e1f96a9dbaed5550bb7fddaf50f80bf0c7fe16afc42b3d2ee377f63daafdb35265ff009e2adfeaff00de91b6affdf55d3eed3881ed5fb3fe930fc11f83fe24f8adadc2bf6cbcb5f2f4bb693ef347bbf76bff006da6dbff00015af0ff0006de5e69adaa7c4ad4a45bed52cf508fec2d72bba3bcd5a46693732ff12c6aad232ffd735fe2af4afdaf3e2449e2df1759f817418d5b4dd0dbf79041f2ac979b76f97feec31fcbff00026feed7b959fecf1e17f16fc03f05f84e0d4a58ace19adf5a9354b48d7cc9a4997f7cdf37ddf315b6ab37dd555ae3e6e5f7a5f68d4aba0feda1e07d5ae36eaf0eb5a437ee76c9043e72b3343ba6ddb5b72aac9b957fbcacbfed56f6a9fb557c3db3bad26de2d51af2ceeade6b8f3e085bfd1595599564fe2f32465dbb7f87e566f95aa8eb9fb1a7c3fd52de66b2b7d4b469bec3f678e482eb72c732ff00cbc32b7de6fef2ee55f97f86bcbfe367eccfe1bf85ff000ff5cf12586a53de32fd861d363b9ba556f319b6dc337f0c9bbef2aafddf9bfbb531e4033ff6b0f15cde3af02fc3df155869f241a1dd437127dae465f321b8936ffa3b7f17cbe5b36efbadb6b4bf6c8d2f54d3743f00aa4725ce83a6dbf97fdb6d26e9a4bc9238ff00d77f7599615656fe26ddfdda87e2878574fb3fd8cfc1b713eb126b974b7d0b5adcdb7fa98566593ccb7fef7eed772fcdfc4b5ebdf0b7e24782fe287c2dd0749f10eada3dcea0ba5c6da8697aa6d6dad6ede5ee6593e5fe156ff8155fc3cb224f059bf6cdf880ad67241fd951476f6fe5ccb7367e779d36ddad3337f0b6ef9b6afcbfef56f69ffb7478920b3d2e3b8f0de95793431c8b7d2798d1ade49b76ac9b57fd5ff7995776eff66bdbac7c07f0affe134b1f1c5c49a65ceb1e24996fb4b9752bc5f264658ffd6430b6d5ddf2fcdbb77cdfed56a6b9f05be1afc41f104d717ba0e957da92df6ebc9f4d93cb916665ff0096caadf37cbb5b6b7defbdfdea5cd0fe528e5ff667f8ed7df16ad75eb7f11c36316a167346d1b5a42d0ac96f26e56dcbb9be65fbb5e2bf01fc1771e2db7f8a1f096fe4b9d2219a38efa3f3a1fde59de5bcdb63665feeb2b2ab2d751fb1cb43a5b78f34bdbbaf2dee2df6c8d1ed9a48d5a487e65ff7955b6ff79ab8df1a7c5af147c25f8edf13354d3749b7692f26db32ea10b6d585595619976edf9776dff65a8e5f7a51892798fc70f85b79f03fc551e8f3ea56ba9fdbad7ed10dddb7eedbc96f95b72fde8d999645ff0076be8cf82b6f63fb34feccf7de3cd5add5fc41e20db716f6d22ed6917eed95bffbadf34cdfecb7fb35e0fe135d43f6a0fda1a19b59556b59245babe58d5bcb86ce1dbfbb5ff7be55ff007a46adefdafbe28378dfe247fc23f6722ff62f86f75aaac6dfbb6baff96cdff01f9635ff0075aadfbdcb0901e2ba86a379acea179a85fccd737d79335c5c4edf7a4919b73357d61fb2cdadbfc27f82be2af88dab47b63badd342adf7a4b7b7f96355ff00ae93332d7cd3e03f04df7c41f17697e1dd3be5b8be9bcb693f8618fef49237fbabb9abe8cfdb23c51a7f837c03e17f86fa36d821658e69205fbd1d9dbfcb1eeffae927cdff006ceaa7ef4bd981e1bf097f682f127c20f8bdff0009e5bb49a9b5f48cbae69be66d5d4ade491a4923ff00ae8acccd1b7f0b7cbf759abf5afc1fe31d23e20784f49f1268176b7fa36a96eb756b70bf2ee56fe165fe1656dcacbfc2cacb5f888df3357d6dff0004fbf8f127837c74df0e356b8ff890f89266934bf31be5b5d4b6ff00ab5ff66655ff00bf8abfdea2bd1e68f3448f8647e8cd14ab495e7c4d6414514532428a28a0a0a28a28015aa36a7f34c6a00f3191aabb353a46aaecd5058e66a8da5a86496a1927a009a6b8f2977561ea17ed2b6dfe1a75f5d564cd2d6918811cd715caf8c3c5b1f85f4d8e6f27ed97d7532dad8d96edad7570df757fdd5556666fe1556ade919a591557ef37cab5e53a5dfaf8c35ab8f1734cab671fda2cf4591beedad9c2dfe917dfef48d1b32ffb2b0aff001356b18810ebd158e9b7cd7daccd6b73e22b3b19b52bcf115f32f97a4c3b5963b7b75fbb0eedadbb6fcdb57e66919abe19f89df163c45f11b58926d6ee36c70fddb38ff76b1b6dfe25fef6ddbfeefddaf7efda1bc4cb6be1f86de58dbfd217fb72f2091bfe58c6cb1d95ac9fdedd3346cdfeeb57c8334accaccf234accdb999bf899bf8abd5c2d3e5f78e3c44b97dd89634fd2752f16eb56ba3e976f3df6a17d22c36f6d02ee691bfcff00df35fa49637fa97c19f05c97daf7f66c1ab59e8725f43636cdfb9d3e15b8861dbe637de91b77ccccbb9b6b7fb2b5e0bff04f1f02c775e20f1078cae9951e1ff894d8ee5ff67ceba93fe031f96bff006d2bd3bf6b4bc8f56f06f8a19a491d9b49924f2b77dd8f72c91b7fbde62b7fdf35857a9ed2a7295423cb1e62f7c31fda03c17f12269ac60be8adb5092e36c3a5ea16fe5b5c46bf75959b72fccaaccdf36e56fef57b45bc17cba8477da4ee96e1a158dbcc656dd0ee6db1dc47bbf7d0ff00e448fef46dfc2df8ff0063acdd69b751dd59dd4b6d70adb9648246565ff812d7dcbfb297c60f1a78dbc1bac2ebd7905f58dadc47a7daea1731fefe69197748accbf7bcb8d5bf79f7b748b455a5cb1e68842afb4f759f57c9ae47716f232c725b4cdfebad2499649216dbbb6ee5f9645dadb95bf8976b7fb35c3ebdaf336e6f3176b337cbf76af5e34367fda0b611d9cf6722c379fd9faa4d243242b346be62add2ab6dfdf47232b32b2ee665fddfdeaf37f167882166b864fb4d8de42abf6cd3f528d63bb87737eee46dbba39236fe19a36dad5cd03728f882f16e37337fc076fdeff76be74fda0bc05058d9bf8cf4d9fec5a8da491b5cc4ade5f9cdbb6ac8bff4d97e5ff797fddf9bd6eeb566b893cc46fbabfc35f35fc78f1d37883c411e8b6d22b58e96dfbe656dcb25c7ff006b5f97fdedd5db4e32e6f749af28f2fbc707a96b5a87883506d43549967be92358d9955555557eeafcb55aa287e6a996bb3e13cc1cbdaa9dd7faeabbfc359d37fae6a9019566cd7e666aad57ed576c3400352f34ad49cd0026dab11b54145003ee2cd656f311bca9bfbcbfc5fef553fb535bb79770be537f0b7f0b55cdcd51c9b655db22ee56fe1a00864a86a392c26b7ff8f59b747ff3ce4a85ae268befc34016a9b232aab337dd5aabfda0dff3cea1b8b8fb42eddbf2ff00150077bf07f4fd3f59bfd4ae6ea3696e21f2d6156fbaabbb76eff7be5af49f18692de20f09df59a47e65c347ba15ff00a68adf2b2ff9fe2af20f867aa7f65f89961e3cbba85a36ff0080fccbff00a0b57a5f8a3c790f86a19ede2924fb637990c32aaee559976fcadff01656a93787c278bd8d9cd7f796f6f6d1b4b717122c71c4bf7999bf86bd623f843fdadf0ded6ea2b5fb0ebba7adc7daa365ff005db59bf76dfed7f75bfdaa87e12a687e22d42786fec608f5a8ee9b50b7995597e5f95be5ff0075bf86be98d074d65dac8adb95b72ad6539729a52a5cc7c5725edd6a4b1f9f3493aab332ee6ddb777dedb57a1b3996d5ae15665856458fed2aacab1c9f795777f0b7cadb7fddaf4cd7be09ea575f1aafbc1ba4c31c5797927dab4f8e7dcb1f9722eef9a45f95555b72ee6f9576fcd5f657ecbbf06ed741f86eda4f897c3ebbb588e4b5d6b46d4a359956fade6923dcdf7bfd646cbf77fe79ab2fdea89d58c6267184b9bde38bf07fed31a6f8c3e11dd497f7cba478c976e9f37f75ae2456586e959bfe59b491c6ccbfc3f37f0d7c25f12b5a97c55e256d5de1fb3fda376d8376e68d776e58f77f16dddb55bfbaab5e9bfb417c3e5f863f193c51a0a5bac1631dc7daac5557e5fb2cdfbc8f6ffbbf77fe035e53af2eeb7593fe79b55538463ef442a4a52f74c155a995772d32a58eba0c0bd672fcbb5bf86ad355187e56dd5797e65a006d0cdf2d39aa193fbb40157caf366dcd56238f6d3a35a928021b897cb8d9ab99ba66693756c6a571f3797fddfbd58f37dd66a99017b4ddbfd9acbbbe66b856dbfeeab7ff00155e9df04e1d434df1349e26b7d2fedd63a2c2d25d4d237971dbac9fbbddbbf89be66daabfc55c6f847c237be22d7f4ed16052935c2ac8ecbf37931fde691bfe03ff00b2d7db5e11f0cc9a37826fb4df0d5aac574b6acb671c7b559a665dabf7bf89bfbcd594e5cb13a6853e69731f30f8e3c6f7df10756b7bcbc87c85b78da1860ddbb6ab36ef9bfdafbbff007cd7a07ece3e3e87e17fc42d375ad47cf6d1e3f31aea083ef37ee648e36ff6995a4f97fdeaf3dd37c17aa5c78c17c2f6f0ade6adf6a6b1558dbe56915b6b36e6fe1ff69abed6b8fd9cfc37f0eff667f1635edbe9979e2886c64be9b56bbdd32c72471b6d58d7e5fbbe632c7f2ffac6566fe1db13945479498f34a5cd23c9fe3a7ed297df1763b7d2f4db7bad0fc3f0eef32d9ae374978cde5ffae55f97e565f976d7b17fc13ff5c925bcf19696f347b61b586e238f6ee91b749b59b77f7576afcbfed57c5b0b6dfbff002d7d75f027c2ff00123e0cfc33f1d78da0d363d33ed5a5f996f1ea51c71ccbe5b6efb448b27ccaaaacccb1ff00137de5fbb59d58c631e589bc65cc7d01f1cbf691d27e07cd636e238b57f1035c43349a3798d1c9f65dcdba4f336ed8fe65f9777fb5f2d64fec73e209bc55f0d75ad4a7b58ed9ae3c51a95c2aab6eff008f865999777f16d69197fe035f9fbae788352f136a926a5abea575aadf48aaad777d3349332aaed5dccdfecd7db1fb06dc5c4ff0e75a5656fb2daea8d1c2ccbf2f9922ac926d6ff80c7584e1ece223dfbe275ac9a97c35f1658dbdc7d9a4b8d26f23f336ab7fcb16fe16f96bf3a7c2bf0fb49d1be13df78ebc4aad2ee8ff00e25b62b26df319be58f77f7b736e6ff757757d8de3cfda5bc3b6be329be1fe97e7df7892491ad666f27fd1a16dbf347bb77ccdb7e5dabfc5f2d7c8ff0016b5993e2878e341f86be1258bec36371f655920ff0056d71b76c927fd73863565ff0080b514f98b89a5fb28fc355d5b50b8f1f6b3b574fd2e468ec649fe556b855dd25c37fb31affe3cdfecd79cfc50f1f37c4ef1e6a1ae7ef16c7e5b5d3e36ff009676b1fddff8137cd237fbd5ed1fb4778a2c7e1a7c3dd1fe17f871bca59ad556e36fde5b356fe2ff006a6937337fb3bbfbd5f36daad6d0f7bdf097f29723f957737caab5f627c3f897f669fd9ff50f136a30aaf89b58db3436d27def39976dac2dfeeaee91bfe055e3bfb30fc2a6f889e3a5d42f2dd65d0f43923b899645dcb7137fcb187ff1ddcdfecaff00b54dfda63e2e37c4bf1b358d95c79be1fd164921b7656f96ea6fbb24dffb2aff00b2bfed529fef25ca598ff0f7e17f8a3e25d9df6a9a659cfaadd4d7d1d8acecdb7cc9a6dd24d23337f0aafde6ff00a695d049ff000b73c076b7de24b75d734ab7d3e65f0ccd7d6cbf77c955558fcbdbbbcbf9576c9b76ff00b5f35769fb3afed29e1ff87be0f87c2faf69f2d9dbd9b49711ea168ad334cd248ccdba3ff8146abb7fbaccd5ea571fb687835a199ace3d57ed8be72c2b247e5c2de5ff00ab666f999564ff00655997f896b294a5cdf0947cc37561f12b41b59358bf8fc41a65bc70c9ba7bb9248d7cbbcf9a4daacdf32c9bb7357b66b5a6dbdafec3ba2c2f32dcaee86ead599bfd5c8d74dfbb5ff755a45ffbeabb4f8a9f13b4ff0089dfb35eb9af69cb269f6f750f92abaa46be6348b347ba38ff00e05b9772d71366b36b9fb10aadc787649db4dbc65b39e2fbde5adc6efb67fbabba456a5cdcc49dc7877e18afc52fd90fc23a0d9dd368ad22fdb9676b76659a659a4dde62ff0012b37f17fb2b5e6ebfb146bd2dbdab278ab476f32e9a39a46b79bcb8d76feeda3fe266fef2fcbb7fbcd59be0ff00dad3c41e0bf00f877c3367a4e9978ba3b792b7777b99a4b5ddb961555fbadf7be6f9bf87e5aa7a5fed65e2ad17e205c7899ad6da586e156de4d256668edbecaaadb615fbdb5b736ef33ef37f17cb53cb38946a6a9fb1af8c963d16decb54d3755bcbab5b892f23f9a3b6b3656dcb1ac8df7bccddfdd5f9b77fbd5d87ec3fa935add78cb49baba582ea1921ba6d35addbccdd1b346d2799f77e56dabb7fe055e89e01fda117e326a1e2cd37c3fa3dcc171a7e9ff68d36e64dbba69a48f6aab2b7dd93cef957ef2b6daf07fd91756d4a2f8d97d0dc4de44d7d6375fda1048bb59a65915beeff000b2c9bbff1ea3de9297301adfb36d9d8e9bf1abc6127882f228b58b1f321b796fa458da4b892ebcb93ef7f137cbf2ffb5597fb7378c343fed8d3f43b5b1b76f1046ab75a96a0bbbcc8e3556586ddbfefa6936ff0fcbfdeab1fb507c27baf0cf8b2fbe214b7905b687a96b10af970337dae393cbdcd22ff00bcd1b6dfeeeedd5e7ff04fc1127c66f8a97de24d5edfcdd26cee96eae2366dcb35c37fa9b7ddfc5f77737fb2bfed5547f9c93d0be15e9327ecd7f0675ef186a51a41e2ad4add5a1824fbd1c8dff1eb0ffbcbb9a465ff00e26be618da49646696469e491b7492b7de666fbccdff0002af4afda2be2837c49f1f4d6b6770d2e83a4c8d0dbed6f96e26ff0096d71ff026f957fd95ff006ab0fe0ffc3e9be297c42d1fc37133456f70de65e4ebff002c6d63f9a46ffbe7e55ff6996b55eec79a407d21fb31f856c7e16fc37d6be287897f711dc5ab35bff7a3b356f9997fda9a4daabff01fef57cabf10bc75a97c48f196a9e24d53e5babe9372c0adf2dbc6bf2c70affb2abffb357d29fb6b7c46b3b3b1d1fe1ce91e5c10c3e5de5f411fdd8618d76dac3ffb53fe02b5f24b77a2947ed80cae97e18f83ef3c7df113c33e1fd3f509348bebed4218edf528d77359c8ade62ccbff005cf6eeff0080d736bf357d31fb12fc3e9352f196a5e30963ff0045d1e36b3b5f97ef5d4cbf36dff763ddff007f16b59cb96241fa05f07be20cdf12bc0b6baa5fc31da7882d669b4bd72c63fbb6ba85bb79770abfecb37ef17fe99c8b5db2d7c67f083e3a69ba5fed7de24f0ddbc8a9a1f8a161d3e49777cadad5ac6cab22ff00d748d5adff00da6863afb296bcaa91e59151f84929ad4ea1bbd3d46328a291aa4a179a28e68e68011a9ad4e6a6b500792c8d55e46a9246aa733541b11cd2d53b8b8f9689a5acbbab8aa89036e2e37567c92d3a696a9c92d581c8fc54d52ead7c2eba7e9d335b6a5af5e43a2dadcafdeb7f3b779937fdb385666ff7956b0e6b7b768ed741b2b78edb47b58618e6b6fe2f2d76fd9ecd7fd9fbb248dff5cd7fbd5d078d3c2b63e34b1b3b7bcb8beb19ac6e96facefb4db8f266b799559772b7ddfbaccbb59597e6af9f7e2d6b1aff00c09b0d725bcf11ea9e23b2d634b6b6d0aeee955a68f5369bf78b36d555dde5c9e62b7f761dbf2d74d38f37ba2f87de91f3bfc70f89abe34f1178816dd99a19b566ff0049ddf2c96f6ebe5c2abfecf98d337fdf35e66cbe558c6ccadba4fde6dfe2ff006685b356f26cd1bf72abf337fb3fc4d5ea7fb3af8664f1d7c79f095a246ad6f6b75fda970ad1ee5586d95a66ddbbe5fe155f9bfbd5ecfbb4699e5734aa48fb83f67ff06cbf07bf67cb3d264b7f2b5f921592ebfbdf6ebf9176c2bff5ce3f2777fbb5e35fb6b78aacfc25a3eada6c52336a1ac430dac6bf7bf770affe3bfeb2bea26fb1f89b49d16682f12f34f699b56fb4da49ba3936aac76edbbf8976f98cadfc5f2b57e737ed71e2eff84bfe2434aa7f716ff688e3ff007566f2ff00f4285bfef9af228fef2a7bc7a153f774fdd3c319b6d7dc7fb325bc7e1ff847e1ddfb7ccb8924d4997f89bccb855ffd171d7c2d27dd6afb57e14de7d9fc1de0e5ddfb98f49b55f97fda9959bff42ffc76bbab7bd139b0ff0011d57c4df8ecbf0f7c6a34ebdf2dacee649adad6ee75dcb6edb966dadff4cd96e15bfd965aced635cbad734db78ed648229ace4926b1566f961693fd647fed5bc8bf2b2ff0fcadf796bc87f6a365bdd2d2e99774d0cda7b7fdf56f343237fdf56b1d73df0abe2d5bd9f86eeac757b968a4d2e169216ff9ed0ff0c7fef2fcaabfecb7fb359469fba6fed3dee591d8f8f3e282e83e1366b2692db58ba924b586da76fdf59b2ffacf33fddf976b7f16e56af9dd7e55db5a5e26f10dc78b7c4179abde22412dd6dfdc47f7638d576aaffc056b2dabba9c796270d49fb4916ad7f8aad47556cd7e566abca94c906fbb59737df6ad26acf9bad4011569afcaab59f0aee916b42800a653e9940051cd147340052352f34500452542cd534cdb56abd003be56fe1aaf3451aaeedb4faaf708d7135bdaa6e692e2458f6afdefbd401b1a5f82f549bc333789e26852d61dd2afef3f78db5b6eddb59ed7b717ac3cf99e5fbabf337f7576eeff007b6aaaff00c06be8df0bf84e1b5f0bc3a049b2785addade4655f95b76ef9b6ff00c0b757ce3359cd617935adc2edb8b791a1915bfbcadb5aa626b38f29a9e17d6dbc2fe24d2f564556fb1dc2c8cadfc51fdd65ff00be7757ddd1f89bc3be0fd3edf56d5eebc8d27cef2639e38f7799fbbf3157e5fe265ddb7fe035f18fc3ff008737de36fb54c2ceeffb36156f3350b68fccf2e455dcd1aaff00cb46dacadb7ef6d5aea350f891ac789bc1ba6f876f1a35d3ec56358d563fe155555ffd07ef7fb5594e3cc6f4a5ece27a3f877f686d6e1f8d9e1af11aae9f2ff67c9268ff0069d925bade59cd37deb8ff0077e593eeaed65afd1bd36eac75cd3e1d434db882facee3f7d0dcc0cad1c8bf7772b7f17dd65afc7f86dd9beeab36d5ddff0001fe2afb9bf60bf1e35d78675ef04decd235c68f70b7d6b048dfeaece4ff0058aaadf37cb27cdb7fe9a572d6a7d6210919ff00f0506f86f1ea9e0bd07c716f0c6b79a4dd7f66dd48bf79ad66f997fdedb37fe8caf8e7c1ff0008f56f89b6bac47a726d6b1b392f19997e59238f6ac8abfde917cc8db6ff00b55f477ed49fb52dc78aadf56f03e9b6b1d9dbdbdd4d67793db5d477d65a95ab2aed915b6fcb22b2ab2b2fdddccbf7abb2fd97ef345f11fc23b5b8b5d262b3d5b495b8d2ef1a0ff9786fddb2ccdfed346abff7cd38ca54e98a318ca67e71c2de646adfde5a916ba3f1f787bfe117f1d788f47d9b16c752b8857fddf33e5ffc7596b036d76c7de39251e5268ead4754e3ab90d5812d47fc552526da006d46cdb57e6a91bbd53d425db0ed5fe2a00cb9a5f36466fef5259dbfdb2fadeddbeec922ab7fbb48d45aeefb62b2fde5ddff00a0d481f537c19d0e1bcd6b5ad522db75636f1c3a7c33ac7f2b6d8d64936b7fbcdf77fd95afa02dfc4da1f807478f54f106a5069f1ee5dab27ccd348abe66d55fe266dbb7fde6f9abe5cfd94ae21835fd7bed575e443f6356df249b638ff78accdfddf9bff65ac4f89df126e3e2478aaf2f36ff00c4b6391a3d3e268f6b430eeffd9b6ee6ff0080ff0076b9650e69729e846afb3a7cc7d49fb26dbe8bae2ea5e208a4b66f126a5a85d5c5e44bf34d670c937eee1ff75b6eeff6be6feed7d1de30b0b1d67e1df89b4fd4618e7b5934db8924591b6c727971f98bbbf8b6ee8f737fb35f31fec2f6f6f61e15f1a6a975246b1fdaa3dcdbb6f92b1c3b999bfdeddf2d737f19bf696d4bc6f75ad687e1fbe54f07dd476f1c6cb0b4334d1aaee6dcdf7977336d65feec6bfed6ec25094a7ee93cdeec4ec3f62dfd9fe3f195d5afc42f12c32ae9f63751dc68f06e558ef268dbf78d246cbf346adb76eddbf32d7d71f1e22fed2f847e2885b4b835cf3ad5bce82fa49161dabfbc692468ff0078db76fdd5f999b6ad796fec6be3eb5f11fc2db3d0e2db15f787e3fb1c96d1ab6d5877334726e6fbccdf36edbf76bd4be2a78dedfe1f7c35f12788aea3fb4c7636326db656ff005d248be5c71ffc09a45ff80d6739734823ee9f9a7e07f02ebdf13bc410e8fe1cd3dafb509bf78cabf2c70c7bbfd648dfc31aeeff00f6abe97f127817c49fb26e87ac5cf8684dabdab696ada97887599963b58e49176fd9ec6dd5b76ef336c8d232eef955777cad5ebffb3cf87343f877f07f4bbad3638e792f2d63b8b8bbf97ccb89b6fcdbbfbaaadf2aaff0edfef5799fed51a97fc241f0e6f2faf6e22896ce4dd0b4edba15665dbbbcbff96927f0c6bfc2cdbbfdda73e697295189f19e87e21b8f0e5e7dbad6668b508636586e777cd1b32ed693fdedacdf37f7abe92fd9efc1f63f077e19eadf15bc510b44d35af97a6db37facfb3b7dddbff4d2e1b6aaff00b3f37f15792fecd7f081be2ff8f235bdb7925f0de96d1dc6a1ff004f0dff002ced57feba37deff00655abacfda7be302fc44f1547a0e9370b2f877439197743feaeeaebeeb48bff4ce3ff56bff00026fe2ad27fbc972130f763cc794f88bc41a878cbc49a86bdab49e6ea1a84de749b7eeaff7635ff65576aaff00bb57bc2be1cbef166bda7e8ba6c7e7ea1a84cb6f0aff000ee6fe26ff00657ef37fbb5871ad7d5dfb26f82ec7c25e17d6be28788996cece3b7923b3924ff9676ebfeba65ff699bf76bff02fef56b397b38d8a89b9f1ab5cd3ff0067bf837a7f807c332795ac6ad1b2c976bf2c8d1fddb8ba6feeb49fead7fbabfeed713fb2afc09d3fe27693e30d4356dab0ad9b68fa6aed56f26e268f77da36ff00d33555dbfef37f76b8fd0746f117ed51f183509837d99a68e4ba91a4f9a3b1b38ffd5c7fef7dd5dbfc4cccd4ed37e11fc62f0cdd59cda77867c47a7de490c9a92ad8fcad1f97ba3666dadf2c9f332aab7cccadf2fdeac3979636e6f78b3e9af05fec47e07f0fcd7527886e355f15798bb638e756b18e1f97e66db1b6e66ff79be5feeff1561fc5efd99fc03e17f04f8b3c49a5c72e9522e9b1c76304970d25b43751c9b9a45ddf36e915561dadbbef6eaf03b8f847f16b41b392497c3be268adee24b7f33c892493cc924f9a3dcaadf337ddfbdf75be56dad5e89e01b8bcf12fecdbf19975cd42e65bc87505baf32ee466f2ee36ac8df2ff000b348bb7fde6a97cdf17301bda878216e3f61dd2e4b59b6cd6edfdbd26df9b7335c32b46dfeeee5ffbe6bdcbe0adc7877c61f087c27a6d9c3e569b75a7b69f358ddfeefed0d1c7e5dd6ddadf32ee6f99bf8b7570be07f0e5bf8b7f6375d17c3cb24f7979a5ccbe5b37ccd7de76e917fd95f317fdddb5e2737c11f8c0d636f629a3dd7f66e8725c5c58cab32ac7e6348bb9adff008999995597fdda8f880fad35ef819e0bd72d6e2ddbc336b05d369bfd92b22aed92dedff87cb5fef2fcbf337cdb7fd9aa7e1bf819e11f06e86d0e9ba0dabdd476f35aaea17cbe65cb7991b799ba46f97e6ddff015af9266b7f8c9e17b3d6ad5ee35e8a192cd7c45a82b5c3332aab2fef199be6f3176aee55f9b6aff0076bdabf67bf8b179acfc35f881e2ed7965d6af34fbc9afa6ddfeae656b556f2e35fbaabf2ed6dbfc2d5328ca310317f621d356def3c69b6ea09da15b5b75863ff5926d924fdf2ff1797ffc5570bf077e34e8be01f885e2ad7b59d25ae64d6af99a3b955dd359c6d348d36dff0080b2fcbfc5b6bd2bf61df0bcd6fa6f8abc5cf6f1db2dd4d1e9f67b7eeaf96de649b7fd95668d7fe035c3fed39f09fc23f0b7499350b7bed427f106b9791fd8e09e45db1aaaeeba99b6ff0079997fd9566dab54bde94a25183fb467c46b8fda03e24787fc33e1066d434db75586cd7e6559aea45dd34cdbbf8635f9777f0aab5741f1435eb1f805f0d6c7c0be1cb8ddad5f5bb79976bf2b2c6df2cd74dfed48db957fbabfeed5cf807e15b1f847f08f5ef8b5e23b7f36eaeacd974db66f95bececdb5557fdab8936aff00d735ff006abe69f11788f50f17f882fb5cd5a6f3f50bc93cc9197eeaff007557fbaaabf2aaff00b35ac63cd2e5fb3124c95db6f1ff000aaad7d69f04ededff00673f817af7c48d66d55b5ed5a18e3d3ed24f959a36ff008f78ff00eda37ef1bfd955af0bf807f0fa3f897f14b4fb1bc85a7d16c7fd3b505fe19235fbb1ff00db4936affbbbaba2fdaa3e2c4de3cf88136836b32b683a0ccd0aac7f766badbb6493fe03fead7fdd6fef55cff792e403c8f56d5afbc41ab5f6adaa5d497da95f4cd71717327de9246fbcd555bbd142f6ad809aced66bcb886dede169eea691618638fef492336d555afb8bc5178bfb2ffecef67a3d9ccabe22995ade3923fe2be99774d37fbb1aff00e831d799fec67f08db5cd7a4f1d6a36fbb4fd2e46b7d2d5bfe5b5e7f149feec6adff007d37fb359ff14b59befda53e3a58f86f41997fb26cda4b3b5b9fbd1ac6bf35c5e37fb3f2fcbfeeaff7ab9a52e697f840d0fd957e03afc41d3f5cd7b539a5d3ed5636b3d16f97fd6437cacacb78bff5c6458ffde6dd5fa11f0c7c69378f3c0fa6eb1790ada6acde65aea968bf76defa1668ee23ff0077cc56dbfecb2d79af827c39a7f84b45b1d0f4b87c8d374f856dedd5bef6d5fe26ff00699b7337fb4d5b5f0fee1bc3ff0014bc41a4b337d8fc496b1ebd6bfdd5ba876dbde2ff00bcd1fd964ffbeab9a72f69ef11f68f5a5a7377a8d6a4acf52c651cd148d525445e68e69b45003b9a8a9f4c6ef401e3733551b896a49a5acdba96a0d886eae2b2e696a4b897e6aa3235691206ccd54e496a699aa8ccd4cb2399abe22fdacbe220f1978d8e89692ac9a5e80d25a8656f966bc6dbf686ff0080aed87fefe57d5df14bc711fc38f87de20f129dbe669b6ad25bab7fcb4b86fddc2bff007f196bf35754d4a68e2513c8d3cebf799dbef48cdba46ff81333357a585a7ef7348e3c454e58f29149e5dbab2ab6e924fbcdff00b2d67fda2685a4f226922dd1b46de5c8cbb95bef2b6dfe1ff66abc974ccdb99a9ab71fdeaf4a479c7b6f857f6b4f88fe1ff04ea1e195bfb3bbb3b8866861beb9b5ff004db3593ef79332b2ff00c0776edbfc35e47ab5dcfa92c2677de63b75b75ff757737fdf5b999bfe055146cbb7e5a93fd6c759c6318fc269294a5f11cec8bb59abea3f84bacc6de00f0e6d93779366aadfef2dc4df2ffe835f326a116d666ad2f0dfc44d6bc2ba7dc58d84e8b148cacad247b9a1dadbbe5feeeedbf35448aa73e591ecbfb466a8b6368a86332aea90c96bb4fcad1c90dc2cd1c9ff007ccd22ff00c0abc1b4bb1dbfe912ff00c056b7f56f116afe3cbf8f52d76e7cf10af97042a163455f4555ff002d54ae1a8a71e526acf9a447bb7350d447fdea92dd774cb5b1917a15daaab53d3169fcd41631beed67cdd6b4246f96a8ff0015003add7e6ab550c7522d0039bbd46d4e6a6b5002f345369eb400948cdb69ccdb56a9c92ee6a006c8db9a99452355803355df00dd43ff0009ae992cd1f9b1c970b02a6dfef7cabff8f35635e4acdb614fbcdf7bfd95aee3c23f0fefb5cd121d4349536fa959cf98e39cedf39947991b2ffc07ff001e55fef7cb948b89ed5ae6bb6fe1dd26e1da481a75b19ae21859b6b48b1edf957fefa5ff00be6bcf3c152e87e3af899747578dfcbd69648d6de665dab27cbe5aee5fe2daadff00025ff6ab94f1978caebc6f796b25fd9c5697167e747e5c6bf77749bb6fcdf37cbf76b3f4dbab8d36f2deead66682eade45921917ef2b2fdd6a8e5f74d1d5f78fb4be19f81adfc25e1f8745b39a49e3591a4f3e4558e46dcdbb6b6dfbdfef5791fed09f0e63f0478e96ea08da2b5d6a36be58f6ed58e4ddb648d7ff001d6ff8157d05fb3cde7fc2c8d174dd6955976fee6e976fcbf6a5fbcbff0002ddbbfdd6ae47f6aaf8b9e19d66cfc3fa1f87ecf4dd6a685a1d61759593cc5b7f9997eceb1fdd6f3157f78adfdd5f96b9a3297b43aeaf2f29e3ff0002fc1bab78c3e2568f0e93a6ff006ab69f716fa85e5a2b2ee6b3f3a3591b6b7de5dadf32ff0077757b57ed91f00d7e1f48de38f0cdc5d41a7c8d0e9fa85a2c9ff1eeab1ac70ccb27de656f2d55b77f16dfef57b57ec67e34d1fe20f81ed7cdd3748b6f15786d64d359ada358e66b399bcc5917f8bcb66f976fccaad1fcbb6bdb3c55e0bd2fc79e1dbed07568da7d36fa3fb2ccaadb5bcb6fbdb5bf87f86b295597b431e5f74fc6f6555f955552bd73f665f8970fc3bf888b6fa8dc2db68bad47f63ba924f996193ef43237fc0be5ff00764ae37c41e0bbed1bc79aa785d2196e750b5d526d3638157749348b3796aaabfde6f97fefaaf6afd9afe0cf867e29786fc71a4f8ab4b9d6f3ecb1ff0066df6d68e487f7ccb2491ff79a391555bfde656fbd5d3394797de223f11e05fb47e932e8ff001d3c5f6b39fde0ba8e46f976eedd0c6dbabcd992bd03e3b5adf69bf1635ab1d5265b9d42c5974d9a755dab37d9d5615936ff000ee8d636ff0081570aab5bd3f862613f8a45755dad5721a8596a4b7ab24b3cd369dcd368011ab1ef1b7495a970db636ac79a802bb53ac7735d2aafde91b6d364af4af801e11b7f1578c1a6ba4592dec2169cc25777cc777cdb7fd9dbff00a0d44bdd2a31e69729ebdf0eff0067db5b3f04c9ac6af6b26abaf5c5bb4d6fa5ab7eee3665fddc6cbff2d19bef37fbbb6bc4f4bb0babcb886de085ae6f24658e38e3fbd249f776ff00df55f735aa43169f757577bbecf6f0c9e7796db76aac2ccdf37f0fcabb6bceff00641f84b6ed63078c758b15fb45c6d9347819bfd4affcf4dbff00a0eefe15ae68cfe2948ee9d28fbb189d07fc32ab782fe0ef8924d5b58d4fc43a9797e75ae85a2332db4978de4aaab2ff00cb66ddb55bfd95f96be6568becf3491fcbf2b6df95b757e986a16b35d785fc410d9dd3699349a3de431df798abf67dd0c9f36e6fbbfef7fbd5f1dfecbbfb3ac9f1af585bcd53cfd3fc2ba7f9325c48b1b7fa76e6ff008f785bfdd56dd22fddff007ab2a753e2e62651fe5343f65df8b967f08e6f195f5eac4cb75a4edb55dbba692e95bf76abb7fe59fccdb99b6aafcbfc5f2d70ff0014be25ea1f11bc59ab6ad7135cc1677971e747a7b5c3491dbffb2bfeceedccbfef57db5fb497c23f09c5f06750fecdd3745f0adbe92b1dd5c5f5a69abe77d8edfcc6fb2c3b7f89a49157737f79b757e78cd6f24b3470a2b49337caaaabbb7355439652e611f517ecc7e3792e3e19ea1a1fd9e45b5d2f50926924f976dc34cbb9635ff776fcdffed5794fed1de3a93c7de2ad37c23a27997df61b8db22c6df2dc5f49f2ac6bfdef2d7e5ff799bfbb55749f1ccdf0dfe11de436f712c5ad6ad7524766bb557ecebb555a6ff7957ff1edb5d17eccbe08d3fc3fa2ea9f143c47fbad374b8e4fecf56f999997fd64dfef7fcb35ff00699aa65eefbc6df6794f40f881a959fecd3f02ec7c1ba1dc2af8a35a8e4592ee3f964f9b6fda2ebff69c7ffd8d7ca76f12c4aaaabb557e55adef1e78e350f891e2ebef106a4be54971b6386d95be5b5857fd5c2bfeeff17f79999ab1599615666ad69c79626529731da7c27f86f79f157c7163a0dbb3456adfbebebb55ff008f7b55ff0058dfef7f0aff00b4cb5ec5fb537c4eb5b89ad7e19f86a358345d25a18ef2383eeb4d1ffa9b55fef797f2b37f7a4ff76ba0d06dff00e197ff0067dbad6a58d7fe136d79a355593ef43348ade4c7feec31ee91bfdaae1ff645f85ade3ef888daf6a8b2cfa3e86df6a9a46fbd7178dfead777f7b76e91bfe03fdeac39b9a5cffca5137ece3f1db49f82d36a56fa968b3cf1ea11c925e5f40dba6f323ff8f7b7556f95577799b9bfbcdfecd7af5c7edd1a3fda34d5b5f08ea72dbb6e6d43ed37d1ac8bf2fcab0edf95be6fbccdfc35dd7883f657f05f8c9b5a927d264b1bed5a6b765bbd35563fb1ac2aaaab6f1eddabe66d6dcbb7e6ddfecd3b41fd9afe18e9b335d59787ec7536915a15fb5de49751ee8ff7726d5ddb772b7de6fe16feed6729425ef166b7c15fda0b45f8b5a92d8dbd9c9a7eb50d8c37935b6edcacdbb6ccb0b7de6f2fe5ff007b77fb35e0bf0d6e341d1b43fda2b4bbab58ee74d8fce996da0fbad6eb24d1c7b76ff76468fe6fe1ad0fd9e7c1fa7f827f69ef1368f6baa2dcc7a2dbdc4366d247ba49b7796acbfef47bbe6fef6d6ab5fb29f866dd75af8b1e1fbc8e3d41a3dba7cd7d1af990cd1f99346cbb5bef2b37cdff0001a5f0f300df827fb477867c0df0efc27e1dbdb796da4b59ae21d42758fccdaacad22dd2ff007b748db597f86ba0d6bf6d2f0fd9df6a0ba5e8775aaac2b0fd86e6791adfceff009ecb27f12edfe16f9b77f154da1fec5be17b2bcd2eeaeb5cd4b57b7b78f75d58cb1ac71de49fef2fccb1ff00b3f7bfdaa9350fd8c7c1ed0ea0b6b7daad9cd74d1b4324ccb37d8f6b6e6555f9776efbbf353f700efbe1dfc5cd0fe2e2ea12690accb671c2d756976cad36d9376efddff12afdd66fbad5e5bfb2faea5a97c21f166936775a6de6e6d43fb2f4b655558d5976b34cdfc31c9232ed5ff65bfe03cffc01d2343f0afed01f10b47b3ba68a6b359acf498ee5be69238e65691777f132aaaffbcbbaba2fd9f7c4de0df0bdbf8b24bdd42cf43b8d43c55756b1da5dc9b59557fd4ab2ff000aaee6f9beed44a20785fc39f8f5e2cf863e0fd63c33a4dc45f67b88dbcb69d7749a6cdf7649a3ff006be5fbadf2eef9aac58de788bf6aff008b9a2c7aa46bf67b5b7861bc6b65db1dbd9c6dfbc93fd9691b77fc09bfd9aed3f6bef1bf837fb2741d27c33a7e9979aa6a11b6a171ab58dbaab7d9646ddb772fde69a45fbdfdd5ff006abb6d26dedff64bfd9edb54b88627f1a6a9b599597e66bc917f770ffd73857e66ff0075bfbd5a5fac7e2901e77fb637c508756d6ac7c0ba4346ba5e8bb64bc8e0fbbf68dbb6387fed8c7ff8f37fb35f38aee6db1c51b4b248cb1c71c6bb9999beeaad47717135d4d25c5c4cd3dc4ccd2493c9f7a4919b73337fbcd5ee5fb28fc3e5d73c5171e2ed41635d2f43dde4cb3fdd6badbbb77fbb1afcdfef6dae8f769530f88eaa38bfe197fe0bde5c3c91af8db5c6f263dadbbcbb865fe1ff0066de3666ff00ae8dfed57cb30aedfe2666fef37de6aed3e327c4c6f8a5e3cbcd52266fec7b7ff45d2e36fe1b756ff59fef48df337fc07fbb5c5ab55538f2fc412913f35bfe09f096a1e3cf16693e1dd2d775f6a570b6f1b7f0c7fde91bfd955dcdff0001ae7e3f9abed0fd947e1f69ff000bfe1dea9f153c4dfb892eace492dd997e6b7d3d7f897fe9a4cdf77fd9dbfdea99cb9621136bf684f1a58fc09f85ba5f80fc2adf66bebab5fb2dbb2ffacb7b55f964b86ffa69236e556fef3337f0d43fb21fc2d6f0a781ee3c617f6eb16a1ae46ab66adf7a1b15fbbff7f1be6ff7556bc8fe1df87352fdaa3e375f6a5af2c8ba4c7fe99a92ab7cb0daab6d86cd5bfdafbbff007f1abee2bef2e2b5f2e28e38a38d5638e38d76aaaafdd55ff66b965eec794034b6ff00486ff76a9fc40bcff84734dd17c58bf7bc33ab5bdf4df36dff004399becb74bfeef933337fdb35a9b496fdf56c6a5e1987c61a4c9a0decde5e9baa46d6b78cb37972792cdb5957fdeddb7fd9f9ab3e6e52651e63d4b67952346dfc2db6a45ae2fe13f8826f147c3bd06faf1bfe260b6ed6779f36edb716f235bcdff91236aed16b1287546d52377a6556a0368a46a6d4943b7535bbd14500782cd2d66dd4b535c4b597752d28964334b55646a2696abc92d6912c6c8d54e66a9246aa7335515a9f3d7eda7ab345f0f7c3da5249b3fb435a59245fef476f0b49ff00a132d7c41a83334cdbabeb1fdb53510daf783ac37f10d95f5e63fda69238d7ff00416af933507db237fb55ec61a3fbb3c9c44bf7867c8d51f9b4efbcd51c95d0729621badbfeed684370bfc35cfb5c345525bea4bbb9f96973166a6a1179b1b551d2347fb4379f3f106ef957fbff00fd8d5eb7dda936d5dcb6ff00c4dfdeff00656b4a4db146aabf2edf95568e501acdfc22a9dc2d5c8ffbcd55ee2981556ae59afcccd54d7ef5695aaed8568027a7734da2a008a6e954bf8aadcdf76aaafdea00b51d494d5a4a00291a9691a80129776ca6b36daab24bba801d34bbaa2a291a800dd51cd2aaab33539a91b45babed26e35358f75a5bc8b1b7feccdfeeafcbff007d5005cbbf096a16577a6abc7be5d496368f6fdd566fbabbabe8ff00877a4de68fe19d36c6fe3582f2d55a1655656dd1ee6f2dbe5ff7ab8ff84fadaf8a34365b968daface458e6f957e65fe16ff3fc4b5ea9a4dafdbe6555f95bfbd584a47652a7f68f9d7e2b68eda378fb50f957ecf7dfe990edfeeb7deff816e56a8fc0ba4d9ebde2ad274bbfba6b38750b85b359d76b797249f2c6ccadf797732eeff6775697c48f1569fe37bed16e2cd76c8b63fe90bb5bf7733336e8777f12aedddbbfdaafb13f62bf86ba0dbfc33ff849aeac59b50beba92d6469ff00791ccb0ccad0c8aadf764566dbb976b5129f2d332e5e6a9ee9e677de0ff899fb21c30eb1a5ead66b63aa5c5bc6d7368de62fdaa38da4dad1b7f0fcd22ab7f12aff000d78cebdabff00c243e22d5354fb1dbe9eda85d4978d6d68bb618da46dccaabfdddcd5fa1dfb487c2d6f88df06f52b3b3b7f375ad257fb4b4d5593cbfde47bbcc5dbf777347b97fef9afce1b7fdeaab7f0b5654a5cdef172fe53d13e05f8f24f86bf15bc3bae3491ad8c774b6f7cb236d8dad646db26eff77e593fde8d6bf5035cf15697a3c31c377a84105c5e798b66ad22ab5d48b0c936d8ff00bcdb6366af827c3ff00b4df8b1f03750f885a5ea4da56b1a2dacd6fa9696b67badeea4b5556f39597e68da487e665dacbe62eefe26af29d73e2d78abc47e19d2743d47546b9b1d26e23bad3db6ed9ad5961f276c722fcdb76aafcbfdef9bfbd5328fb497ba57c27a469ff123c03f113f6965f17788349bcb1f0cebcd1f9de7ccab269f78d1c7e5dc2c91ff007648d5b77fb4d5fa09ad7ef5a6dfe5ab348ccdf757e666f9bfefa6afc8555565dacbf2eddbb6bf43bf65df8b0bf123e18d9d8dec8d2eb5a2c6ba7de799f334caabfb993fe051aedff795ab2ab0e52a323e39fdbc3c1ffd87f15b4dd6a38f6c7ac5ab2cdb7eefda216dadff0090fcbaf9cd6beb8fdb8fc79a078aad6df49d3eea2bcbed26f956e193e568e68e4b88668dbfe02b0b2b2fcb5f24c75d943f87ef1cd57e21ac94e8d7e6a76ca72ad6e643f9a39a291be55a00a37cff0036daa322d5a9be66aaf27cab401564af6dfd95a599fc49a95a2c52490496ab236ddabf36e555dcdff7d6d5ff007abc426fbbfef57b27807c3fe26f0cf81f56d62ceea2d321beb55924db1eeb8f27e6f995bfe59fcbbbfefa5aca66b4be2e6363e307c549bc65e229b4bd2ef245f0de9f23470ac6be5fdaa4dbb6491bfbdf32b2aab7f0ff00bd5f507ecb37f71a5fc138f56d72fa5fb2c97174cb3dcb6d8eded6de358d76ff00757f76df357c1b672c76f1ee6f95556be8af107fc26df0e7e04d9f86ef7455b1d3f56999af2fbcc566f26655923b5dbfc2db95b77fc057ef6eaca71f763135a7525294a523d3be337ed40b751ea9e1bf06cd04ba7de5adc59de6a8abbbcc59163dad6edfddf2f77fdf55f617c1d96c66f84fe0f934dd3e0d174d934d864b7d3ed9b7476f1b2eedaadff8f37fb4cd5f93762df2ad7df1fb26fc41b1d37e0beb175aa6b524aba3cdbae16e64fdddac6b0ee8e1b75fbccbe5c6cdf2afdedd5cd569f2c7dd348cb98f50fda42f3ecbf037c64bff002d2eac7ec30c6abb9a692691638e35ff008135780fc3ff00847a4fc35d26cf52d5a38e5f11490c8d717d236e5b78db733796adf2ff00abfe2ae67e287ed4575e3cf88da5d8daf953f816c75cb5bcb783c96866badbb76f9dfecac8ccdb7ff42acbfda83e2afd8fc3b36836f74d2ea9ac7ef2e197fe58d9ff00f1527ddff755aa63197c26b1f77de3c97c3ba4df7ed0ff0016becf6ebf61d3e6669a465fbb6762adf7bfde6dcbfef3357a77ed2de30b1d26c74df86ba0aac167a7ac725f2c6df2c7b57f736ffef7fcb46ff80d751f0ef41b7fd99fe0aea5e28d5ede36f146a51ac8d6d27def31bfe3ded7fe03f79bfe05fddaf9766babad4af2e2f2f6e1ae6faea469ae266fbd248cdb99bfefaade3ef4aff66244bdd8ff008872d7b67ecbff00097fe13ef192eb9a8c3bbc3fa1c8b248adf76e2ebef471ff00babf79bfe03fdeaf29f09f85f50f1a78934dd074987cfd43509bc98777dd5fef337fb2abb99bfddafa93e386bd63f00be0fe9be03f0d5c6dd4b528da16b9fbb2793ff2f170dfed48df2aff00bdfecd1525f662113cefe2e78b752fda33e2f69be19f0cafdbacede692d74f566dab71337faeb866fe15f976ab7f757fdaae67c2bf193c5df0bede1d3f48d51b43b7d3649966b4dabe5c93337ef1a656f959976ed5feeaad7a57ec73a9782fc256fe22d5b5bd72d74cd79a1db1c777fbb586c57e6668dbf89b77de5fbdb557ef57ac43e3ef80ba4f8da6f154ba9699a878935691ae9b5292de6b8fb3fcb1ed5dbb76c3f7576fcbbbef7cd597372fbbca07cffa1c5f16bc61a92eb5a75c788d6f2eafa1d15aed6e26b7dd3342db55beefcbe5eedcdf75777fb55b9f0e7c2be2af02fc7af877e1df10fdaace4b59bccb5b65baf3161b793ccf33cbdadb55599599bfbdfc55f4e683fb467807c4dac6976367e22b9b9bed52fa4b18636b5917748bb76b37f12c6dbbe566fbdb5beeedaf3dd797ed5fb69786daf2e2568ffb257fb3e38db76d93c99be56ff6772c8dfc5f796a39e5f0f29657f0cd9fdabf6daf117da5a78a686d6492dfe656ddfe8f0aeeddfddf2d9abc6756f891e22f86ff0013bc71269134fa0de5f6a4d24d048bf32c6b334d1ab2b7f0b2b2ff00c05bfdaaf4ab5f19785f43fdabbc5de22d5f586b1b1d2e1fb3dbc8bf32b49e5c70c8bf2fcccabba46dabfddff66be8ad535cf8777f6f7926a5aa7866e5b50b592cee24f323f32e2dfc9599a366fbcdfbb915b6ff00b54f9b94227cab71fb4c7c4cd6756bed43435bab6d2f545fb1dae9f6d66d756d6f26ddbfb96dbfeb377cdff02ff66b73f679f8abe30f147c5cf0ee83e21f136a12d9c31dd32da5cfcad349e5b32c7236ddcdfde5ddf776d7d05e03f8c9e09f106a51f85fc1fac3335be9eb750c105afd9ed9635dabe5affb4aadb996bc5e1f107f64fedcda848da1cf136acdfd9ebe636d66692dd7fd31777f0b796dff00016a8e6e6e65ca05cf8576fa3ea9fb5e7c52926b589af2d7ce92c7737cb1b6e8e399b6ff007995bfe03b9ab07e307ecd7a5f87f5ad43c5d2ea91691e0d8d64bed52066692e57749feaedfe5dacd26e555ddf759ab8bf8a9f1435af01fed15e30d7b49863d3eea68e4d3636bcb5ff005d0ed58fcedadf79b72ee56ff656bcf7e2a7c54f1478a341b5f0fea9752de5c5c5d7f695d2b36e69246ff531edfe1fbccdb7fddaa8c65f1440f42fd9bfc2b27c62f8b979e30d5ece35d1f4368e68ed17fd4c732aedb5b55ff6618d777fc057fbd5ccfed1df169be2b78e99ad6e3cdd0749dd6b63ff004d9b77ef2e3fe04cbf2ffb2ab5eb5f11b52b7fd9cff67fd17c0fa76d8bc49ac5ab2dc491b7ccad22afdb6e1bfdaf9bc95ffec6be515fbbb57eed5d3f7a5ce04da5e8d79e21d52cf4bd3a169efaf265b7b78d7f899abe86f8f9af58fc1bf84fa4fc35d0a6ff004ed42d7cbba917ef7d9f77efa46ff6a69372ff00bbbaa4fd9cfc0b63e0ff000aea5f13bc46cb6d6b1dbc9f636917fd5dbaff00ae997fda6ff56bff0002fef57cdfe38f185f7c41f186a9e22bf5db717d26e583fe7de15f963857fdd5ff00d9aaff00892ff087c313263fba2a45fbd50ad5887e66ae82227a57c09f85b71f16bc796ba3ed65d2e1ff0048d4ae7fe79dbab7ccbfef37dd5ff7bfd9af7cfdb2be282b5c58fc39d1176dadaf9336a11db7fcf4dbfe8f6aabfecaed6dbfde68ebaaf867a4d9fecc3fb3fde788b57857fb7af156f2e206fbd25c37cb6f6bff0001fe2ffb695c2fec93f0d2ebc7de38bcf889e23dd796f6374d34324fff002f9a937ccd27fbb1eeddfef6dfeed7173734b9cb3e86f803f0abfe1507c35b5d36e2354d7af9beddaa37fd3665f961ff007635f97fdedd5d76b12edb766ad6ba9bef35737ae4bbadf6aff13561fde00d0e569750b78576af98df37fb2bfc4cdfeed685aeb91b6876bad4bba28754923687737ddb7dade5affbccacd35726d71a7de5bea5a5dd5c4b6d6fbad6cef27817fd735c3337f67ac9fc3248b1aee6fe18e455fbd22d4df163c5b6f6abe05b345dbfda9e2cd2ec5638d7eec7fbc665dbfc3b557fe0351f115f09e81f06f548e2d73e21683e72b496bae7f6c5bc1f75becb7b0c732c8abfddf3bed0bbbfbcacb5ea51d781f8ba292ebc1b1f8b34387fe2acf09dac7ab69b247f7ae2d5557ed162db7ef4722c7246cbf777796df796bdbb43d72c7c47a3e9fab69b379fa6ea16b1de5ac9fde86455915bfef965a997f313fdd34a994fa6b53d408da9b5235475250514532803e6cb8b8aa334b524cd54e66aa362199aaac8d5248d55646ab2b51b23551919a5936a7cccdf756a49a5af9b7f6a4f8dd3787e19bc13e1fba68356b887fe2697b1b7cd6b0b7fcb15feec922fdefeeaff00bd5ad38caa4b9626729469c79a4793fed41e34b1f197c5646d2ee92f34fd274f5d35a78fe68e4b8f39a4936b7f12aee55ddfde5af1f929cdb628d55576aaaed555fe1aa3757b1c5f79abda8c7d9c794f1a52f692e624936d5592d6dd9be68d6a9cdaa337dd5dab55db526fe2a605a9b49b597eeb48bfeeb5525d0964be8e3593727de93e5fbab4f6d4b6afdd6adad2edda2b7f31ff00d649f337fb3fdd5a80268e3589785555feeaff000d576fdecd56266a8635ab026dbb56b3e66f9aaf337cb59b27de6a801aabb9ab59576aaad65dbaee996b56800a28a46a00864a8557e6a99a9280156979a39a6d003b9a6336da19aaacd2ee6a002497753291696801f51b52d140105d4be542cdfc5f757fdeaf41f84fa947776371a05d2ac816369155bfe5a46dfeb17ff1eaf3699bcdbadbfc31ff00e8557b4dbfb8d2efadefad5b6dd5bb7991b7fecbfeed05465cb23b4f0d4aff00097e244715eb48ba4dd2f96d3e3ef42cdf2c9ff016fbdff02af52f8bd7f79a0f85ed750d36ea7b3ba8efa368eeece4dacabb5bf897fdeff81563ea9a3dafc57f04c37160abf6cdbbadd5bfe58ccbf7a16ff7beeffdf2d543e1a7899bc49e0fd53c0ba8ab7f6a476f22e9be77fcb4daadbadd97fbcbf36dff0067fdd5ac247547ddf74f3ad1ed5ae2e97737cccdff008f357d45fb24fc4e5f877e30baf0ceaf34ab63ac5d430aee916386deea3668d99b77dd66f957fe02bbabcaff0067ff0007dc6b9f153c270cfa6cb7da6aea4ab74cd6ed243fbbf999646dbb7f87f8abea0fdac3e04e8b6bf0cffe12cd074bfb1de69b74d26a11c6df2b5bdc49ba46f9bf85666ddb7f87cc93f87eec4e5197ba6508f2fbc7bb7c52f8cde13f85f74da6f89e49229af2cda68e092d7cc5b85dcd1b46cbff0001dadfdddd5f23fecfbf0b7e1cfc64f895e2ad0eea6d4f4fb3b88e4baf0fd8ac8b0ccb0ee6668d9be6dd246acbf2ff0012aeeff66bc87c4de3ad6bc68da6b6b3a85cdf4d636ff6559679376e5f95777fbccaaaacdfc5b55bef6eaafe1dd7b50f0beb5a7eb1a4dd4963aa58ccb716b731b7cd1c8bfe7fef9ace34b9626bcc7ea87c35f869a1fc34d0e6d3f49b75db78b1c979232fcb7522c2b0b48d1fdd56658d776dfbcdbabf3bff006a4f86f67f0b7e346b1a4e9763fd9fa1dc470ea1a7c0bbbcb58645f995777f0ac8b22d7e837c21f89d63f173c03a7f89ac5562926dd0de5b7f15add2ff00ac8fff001edcadfdd65af977f6f0d7b45d5aeb4bd2e75583c4da4cd1c96ede5b32de69f711b3332c9bb6aed923dacadfc5f77ef5654a5fbc091f22b37951b48dbb6aaee6db5f4978b3e16f8ebf664f06dbf8e3c2be265b9d3f50f263bab9861f2e4863668e6b5668db77f16e56fbdf7b6fdd92ba2fd91fe017867c65e199bc55ab35bebd0ccd7da3de68d776fba387e58f6b2b7def336b37fc05be5dacb5f5378d3c11a7f8c3e1ceb1e139636fb0dd69ad671aaaee68f6c7fbbdbfed2b2c7b7fddab9d5f7b942313f237c597f71ab36a17d75279b7575335d4d27f7a466dccdff7d357331d6f6a1e65c69b2332fef3c9f997fdaae7eddb72ad76c4e6913f34ab49cd3d7b559032a2b86f96a66aab75f7a802bb2557b8fbb566ab5e7dedb40167c2fa645ad78a34bb1b8566b79ae17cc55fe25fbcd5f50c3676b79e0bf125bbdbc6d0ff0064dc32af93bbe6f2d9a3dabfef2aed5ff67fd9af9bbe1aaeff001ce9bbb77cbe637cbfeed7aef8d3e2bcde14b8fec5d16444be8da48efa7963565fde43b576ff00b4bb9bff001daca474d2718c79a474dfb2afc2c5b8921f196b36b67736ecbb74b82f15665dde67cd332ff7976b6dfe2fe2feed7ba7ed21a0c3acfc23d4ae3ecbf69bad3645ba8dbcef2d6dd5595646dbfc5f2b7ddfef3562fc11d4a1ff00855be19486e21f32c6c618e458a45dd0ee5665ddb7eeb32ed6fef7cdf3565fc7ef8ab1e83e03bcd06ce48ffb63588da368d9599a3b36fbccbfc3f36ddbf37cdf79ab8f9a52a87572c634cf39fd9efe102fc5af197d8ef2ea4b3d0ec5566be6b665fb4c8acdb638e1ddf2ee66fe2fe1556af6cf8e1fb3ef87fc17a2d8ea1e17d2eea2b1d274db8bad6afaeef36f991aed8e18d9b6ed69a69a6fbabfc31fdd5af56f823e01d2fc1fe0dd1db4ab78d56f956e1a768ff7926e8f77cccdf37f7aa8fed41e1fbcf187c21b5b1b09a559a4d52c7cb58ffd5ccd23347f32ff0075559a4f9bfbabfdea9954e691318f29f07c974d6ecb3798cb247f36e56dadbbfd9af4afd9b7c02df12fe2349e20d5d5ae74bd0da39195be659ae3fe5de1ff007576eeff0080aff7ab07e2b787ed749f165af827c390c9a86a4b75e5c8bff2d1ae24dab1c3fef2afccdfed49fecd7b778e352b7fd99fe0ee97e13d2268e5f146a91c8cd731fde566f96e2ebfefafddc7feeffb35aca5cd1e58f51457bdef1e5ffb487c466f1e7c40934fb59bcdd1f4366b7876b7cb35c7fcb69bfefaf957fd95ff006abcbd56a3855625555fe1aeebe0efc31baf8b1e38b5d1d19a0d3e3ff48d42ed7fe58dbab7cdff00026fbabfef7fb35a7bb4e267f148f7efd977c2fa6fc34f877ad7c4ef12fee3ed16f27d9d9bef4366bf7997fda9a4f957fd955fef5796f82f49d6bf6a8f8e8b36a6b24567232dc5f796df2d8e9f1b7cb0ab7f7bf857fbccccd5d37ed65f1121d4b5ab1f87ba1aac1a4e8fe5adc4107dd69b6ed86dfe5ff9e6bb7e5fef37fb3583f05ff68aff0085330b5bd968f05e5ab2cd25d47b96392fae3f76b0f9927de58d55646dabfdedbfde6ae68f372f37da669fdd3d5b52fd85d7fb62186d3c60b6da5b5ac9234f736fe64cd75b999638e3ddfeafcbdaccdb99bef56c687fb10e82b710cda8f89b539edfec7e5b5b2c31c2cd75b7fd66ef9b6c3bbfe59edddfed5789c3fb4a78f354b8d156def1ae752b1d2ee34bddb7ce92e9ae24dcd332ff00cf65fddaab7fd335fef576df0dfc65f14bc2ff0017bc1be0df156a1ac5a2eb1a959de4d05ded9ae64b7dacaabb9b76d8dbcbfde2ff00b3f3512f69fcc1ee9cdffc2b4bcf873fb42786fc2b6f7cba85c34d63247a87cd0accd246be632ff757cc59957fddaf56d534bbcb3fdb83c3723ac178b79e5dd5bc0b236eb7856de455693fbacbe5b36dff00768f8d5a7de7fc3647c37d9e434734766d0aedf9555669bccddff8f3562fc66d7a4f869fb57697e2cb88649ed56ded6f163ddb7cc87cb6b7655ffbe5a97c5f701bdf1a3f65ad73c4de3ed4b5ef0aff0067ad9ea4d0cd716d7375e5b2dc37fc7c48bbbe5dbf75b6ff0016e6ae06ebf641f888b35f2c56ba6cb1dbdf476b0c8d74abf6a8d9bfe3e957fe79afde6ddf37dedaadb6bb8befdb724dda7b59f83e0585ace65bcb69ef3fe5e19bf76d1c8abfead557e65dbf36efe1db527c29fda8bc49e3af891e1fd0f52d3f4c9ed6f2fa6693cb8f6b2c7e5b346b1ee6dbba365fbdfc5bbe6a9fde44b39bf04fc2fbaf863fb557877c332dc4ba842bbaeadefa3fddf9d0fd9db736dfe15dcacbb6bb4f8912e87e05fdb03c2be20d46f9a0b3b8d364bebafb64dba3b591639a38f6ff00757e55dabfdeff007aac6b92de5d7edbd67f67d49963d3f47f3a48f6edf2615b56692dfeefccaccdbbfe05fecd687c76fd9c758f8c5e38d3f58d375eb1d3e16d3e1b1db771c8ccacacdf37cbfc3fbcff00c76a79bdef780d0fda4be28786fc2bf0f63d53ec7a66b5a96b566b6fa5acf6eb23490c8be6799f32ee58d776eff7b6d7cebfb2bfc345f11f882e3c75adb6ed3747b8db6be7fddb8bcdbb9a466feec2bf337fb5b7fbb5c0f8fa393c79f14a1f0ef869a4b9b7b768f41d2fce66dab1c2bb5a4f999b6c7b96493fe055ebdf1cbc5ba7fc2df873a4fc35f0d49b7ceb3f2e69ff008bececdfbe99bfe9a5c49bbfe03baaf979572c7ed044f25f8c1f111be287c46d535e566fecff0096d74f56fe1b58feeffc09be691bfdea77c23f87371f14bc75a7e83179915ab7efafa75ff9636ebf79bfde6fbabfed3570b1b6d5dcdf756bec0f0edac7fb29fecff7de22d46358bc71e20555b781bef2cccbfb987fdd8d774d27fb5f2ff76b49be58f2c42279cfed61f14adf54d4a1f87be1ef2edbc3fa1b2c774b07dd9268d76ac2bfecc3ff008f49feed7ceed5233333333c8d2c8cdb999bef337f13535ab78c7963ca6521abf3357d09fb1ffc205f883e3a935cd46dfcfd174168d96365f96e2f1bfd5c7feeaffac6ff0080d785e87a35e788358b1d2f4e85aeb50be996dede05fe291beed7da1f11b59b3fd9a7e06e9fe0bd06e17fe120d523923fb62fcadf37fc7d5d7fc0bfd5c7ff00d8d63565f662544e1fe3b78c350f8fbf1834bf04f8666fb4e9b6774d676acbf34735c7fcbc5d37fd338d55957fd956fef57d85e0df0ce9fe05f0fe97e1fd2576e9fa7dbac31ff7a4fef48dfed336e66ff7abc3ff00635f841ff08bf86e4f1a6a56fe56a5ab43e4e9b1b2fcd6f67fdeff007a46ff00c7557fbd5ef5a7cbe6de4cd5cb3fe58965cbe6db1d71fe24bfb8b7b5dd6f0fda6e99961b781bfe5a4ccdb557fddfe26ff655abb0d417f72d5c9fd9da5d41af26668adedd64b3b5f9bfd649f2b5c49ff01555857fda924ac42243f112e345f07fc05f1835d335ce9fa6e9725f348cacb24d751c9bbcef97eec8d71e5b6eff00696be1bf167ed4b7df16be36782f52fb3cba4787f47bcff47b4926dcde648be5c9348cbfc5f36d5dbf7557fdaafbdbe16dc5af882d7c4de1dd6d7ed9e4c9369b3348be647710ed58e65dbfdedacbb97fda5afc99f88de0fbcf855f113c49e19b85916eb43beb8b55ddfc4aadba36ff00812f96dff02aeac3c632e68c89abee9fae5f0def26d374dd25a5f9a4b3692c6e95be6f95a6917e6ffbea3ff80d741f045d7c2927883e1cb7cb1f87645bad1d5bef369374cd242bff006c6459adff00ed9c75c1fc31d717c476f25e22eeb3d6b45b5d5a3f9bf89add777fe3dffb2d6e5d6a5245e36f03f8badf6eeb5bcbad0752dbff002d2c6e159bff0021cd0c322ffbcdfdeae52e5bf31eecad4b512fcb52f3522908d4d6a7f34da02232994fa6b5051f2eccd59f70d562696b3e66ab89b0d91aa8cd2d4d33567c8ccccaabf79aa8ad4e03e377c545f853e0b7beb710cdaddec9f65d2ede5fbad36ddcd237fd338d7e66ff0080aff157c11aa6a124d717175777525ddd4d235c5c5dccdf34d237de91bfdeaf48f8f5f117fe1607c46bfb9824dda4e97bb4cd3be6f95955bf7d37fdb493ff001d55af15d52f1aea6dabfead7ff1eaf6a853f671e63c9af3f69223bed524b86658bf751ffe3cd596cdf37cd524955d9b736d5dccdfdd5ad647283354324b530b1ba95b6aaed6ff00d06af5be8f1dbeddcde6c9fdefe15a8e5901168f62d7574924cbfbb5fde6dae9f7555d3d7f72d27fcf46f97fddfe1a9a46dab4cb2166dd2353ff0086991ad2f34009237eedaa855bb86fddd54e68027b35dd355faa5a7afcd2355c6a005a6377a29ad400d6a5e691a92800a46a5a826976ff00bd400d9a5a8b9a4fe2a5a0039a28a56a004a82f2e3ecb6ecdfc5f756a7e6a3d3e1b5d53c4967677723456ecdb5997fbd4480a56e9b635ab0b5b3e30f0bc9e13d516df734b6932eeb791bef7fb4adfed2d622d11091defc27f1e7fc219af2c574dff127be655baffa62df75665ff77f8bfd9aefbe377c3fbcd0752b4f1c68ecd6f1bcd1fda26b76f9adeebfe59dc7fc0be5f9bfbcbfed578743fed57d79fb33f89b4ff88de0bbcf01ebd1adccd1c2d1ed91bfe3eac7ff008a8dbff69b7f0d6157ddf7a274d2fde479247b57eca375a2f8a3c3379e26d2ede3b1d43549238f56b48feec7791ffacdabfc2b26e5917fd9655fe1afa3aced6df52b592d6f618ef2d6e23686e209fe65997eec8adfef2b57e7bfc37d7afbf64df8d575a2ebd3493f85752f2d6e2e76ff00acb5dcde4de2aff7a3f99597feba2ff76beacf8ddf1ce4f827a5f85efac21b5d5db56bc99648e493e56863b7dcad1b2ff133490b2b7ddf97fdaae1947def74def78fbc7c3ff17be1cc9f09fe286bde17f9a5b5b59bccb191be6f32d64f9a16ff00be7e5ff795aad7c23f86edf15bc716fe1783528f4cbebcb5ba92ce49e3dd1b4d1c2d22c727f755b6b2eefe1af40f177c6cd0fe387c44f87f79e30d25345d274f8d6cf529e06f33e6924dcd27f79add7fe79b7ccaad26d6dd5f647c27f80fe1df86f67a7ecb7b6d4efb4bd52eaf34bd499774d1c336e555f33f8bf7726dfeeb7cad5b4aa4a31f78ce313e41f04fc52f187ec8de3ad53c3b3aadcd9b5d59dd5e69f3afde5fddc8cd1aeedab2342cd1b37ff12b5e1bad5f47a96b1a85d416eb676f717534d1db2b6e5855a46658d7fdddd5f727edddf0fa1d6be1ce9be2cb7876ea1a0dc470ccd1aeedd6737cbf37fd7393cbf9bf877357c1ea9baae972cbde097f29ee9fb24fc5f5f869e3efecbbd5dda4f88a6b7b59a4f9bfd1e6dccb1c9b7feda6d6ff007abee0f1e7c46d2fe1a693717da8de4515e476b71756762d32c725e7d9d7cc68e366fe2ff66bf2d638ae2ce15bc4f36058e4dd1dcaab6d8e45f9bef7f797e56af5efda23e3743f19bc33f0fe668628b58b1b5ba6d5a38f77eeee1a455f97fd9658d64ff67732ff000d4ce9f348232f74ecbe05e8fe05f883e3cf1779567b6f349f137f6f687aa43fbb93ec37137ef219236f9648f77cacacbb97cc6db5f125dd99d3f52bcb41b76dbdc4d0aedff66465ff00d96bdc7e07f8f1be1cfc58f0fead2b37f67cd32d8ea0aabbb75bcccaadff007cb6d6ff0080d793fc4ad37fb07e2778cb4ddaabf63d6af21555fbbb7ce6db5a538f2ce4653f84c95a996abc6db96a65ed5d4600ddeb3e6f9a46ad06fbb59ffc540047fdeacdb86dccd5a927cb6ecd58b237cd401d2f816e2e34b3ab6b16b0acf359dbed8f72ee5566fe2ff80aad508da6bc924b89a4696699bcc9246fe26ae93c19a5f9be03d72e1ee3ecb0c8b234926dddf2aedf957fdefbb5a9f087e1cdc7c44d723876b45a6c3b64bc9f6fdd5feeff00bcd51cc6bcb2972c4f48f81bf13a4f85fe0bbabab8d0750bcd3daf269adefada355b669bcb55f2da46ff006963fbbf35798c77f7979711dc5d5d4b7370bf3799236edbf36eff00be773336dafa83f68ab0b5b5f84b0dbacdfd99636b7cad1d8c16bf2cd26d6558d76fcb1ed6f9999bfbbfdeaf997c37a35e78975cb1d1f4bb59750d52fa4586ded20f9a491bfcff0017dd5ac2128cbde34ab19479627e8a7ece7e28d53c75f06f4bd4356b8b9d4f5292eae23b8b99e6dd249b646dab237fbadff7cd787fc64fdabd752d52d6d7c331f9b0e93a94922ddcebf2cde4edf2645feeab49e67cbfdd55fef7cbc8ebd6bf123e107c31bcd1757b8b5d2b47fb679367040d1c925d4ccde6348acbf332ff00d346ff009e6aab5e3fe11f0bea1e3af1269be1fd25775d5e49e5ab37dd863fe291bfd955f9ab18c23f148d6f23dd3f657f07dbc575ad7c50f12dc32d9e9bf68f26e67f99bccdbbae2ebfde5ddb57fda66af25f885e3abcf897e34d4bc457aad17da9b6dbdb7fcfbdbaff00ab8ffe02bff8f3357b37ed19af58f807c17e1ff857e1e6db6f1dac771a837f1343bb746adfed4926e91bfe03fdeaf9e56aa1ef7be13f77dd26556f95555999be5555fbccdfddafb1ad62b7fd94be05c974f1c72f8c350dbe66eff9697d22feee3ffae70aee6ff80b7f7abccff64df855ff00094789a4f186a51ffc49f45936daac9f76e2f3ef6eff007635f9bfdedb597f133c41ab7ed1df162e2c7c3b1cd7da3e8f0ccd66abf32b431ffaeb8dbfde91b6aaff007bf76b513f7a5ca11f762769fb1afc39b7d67c517df103c477917fc4ae4f3ac7ed732ab4d70cdfbeba6ddfc2bbb6ab7fcf46ff0066bdaa1d1be0ce837da2d9ea5278565d4af249350b56921555b86bcf33f78adf77cb65f95777cabb7e5dacd5f25f87fe12fc48d719b49b5d0f5582ce6924b199ae55a3b78fcb6691a3919beeaeef9bfbacd5d0784ff657f1f7882fac5757d2e4d174fdcd1cdf6bb88da68e156f9b6c7bbf8be6dabff02a971f7b99c8a89f4d785fc4df0cf43d63c23e1ff0cff63fdaaf2de4b5d35ac63591963859bfd64df7be66f336eef999b73579af8eaf3ed5fb687827ecbaa41049631dafda1a46dab0ed59a468ff00de68d97fefe570be11f035bfc31fdac343d0ef6195b4f6bcf334f669166936c91b7d9e4936ff0016efbd5e99f1cad6cf5cfda63e18e92ba3c17cd1ac735c34ff00bb5ba56999955997e6db1ac6cdf37f7b6d4fda02e7c66d36fadff6b6f8537d6f71279d79e4ed5655db0ac7349e62ff00c0959abd6be247c01f0bfc4ef115beb5acaea13dd4362da6c305b5d2c70b7de68ff877798ad2337deff80d79bfed21f067c55ae6b8bf103c35a95e6a1ac69f2431dae9b6cab1cd6f1aee6f3216ddb9a4f31b732ffb5fecd793d9fecebf15b56be8da5920b39aeaf3edd335ceb4aad1dc32fcd332ab7facfe1dcbf37cd53f663ef01f4769bf00be11d843aa686da6e9f7322fd96d7506bbbedd731c8dfea7f79bb742d232fdd5dbbbff001dae4fe28786749d27f6acf83eb6fa3c105afd85a368e35dabb6dda458f6affd335dbff8ed781de7c27f12780fc7df0f5bc5b6f1ea775e24d49649b4d5baf3a491a3b855fde49f764ddb96456f9abdcbe385c5e6b3fb4e7c1dd25ec7ed31c2cd74b247332c926e99bcc6665fbaaab0ab7fb5f352e5e597c40737fb4a78b2ebe17fed0de19f16693671b5e43a4aeef3d5961bc5dd247e5b32fde5f2d955b6fcdf76aaf8d3f6c2d5356f0bea92691a2c7a1dab58b58c33c927993497d32aee6565ff009671aaccdfdef9a3ddfddafa0be2c7c37f0af8f3c33bbc690ac563a6c335c7f682dd35bb59ee55f32656fbbf7557ef2b2d7c2fa969ba5fc5ff008adfd93e10d3e4d0fc27e749f65819999ad6cd7fd64cdbbfe5a37deff79a35ab872ca3ef01d47c03f0f59f80fc27ac7c48d71596de3b7921b156fbde4afcb248bfed48db635ff817f7abc4fc4de26bef19788b50d73516ff004cbc93cc655fbb1afdd58d7fd955dab5eadfb4a78deddae2c7c13a42adb69ba6ac6d71047f763dabfb987fe02bf337fb4cb5e33a6d9dc6a9a85ad8d9c2d73797522c30c0bf7a4919b6aad6d0fe7904bf94f7efd927e12afc41f1e47ab6a36eb2e83a0b2dc4de67fab9ae3ef431b7fb3f2f98dfecaffb55cdfed29f17dbe2ff00c48b8b8b3b8697c3ba5eeb3d2ffbb22eefde5c7fdb465ffbe556bd93e336b967fb3c7c01d37e1ce8970bff000906b90b2de5cc6db5bcb6ff008fa9bfe04dfb95ff006777f76be415f9576afcab530f7a5ce12fe5169157e6a72d759f0d7c0375f12fc65a6f87ed59a25b86dd713ffcfbdbaffac93fef9ffc7996b794b940fa23f645f86963e19f0ddf7c4ef10b2db2f9337d8649d7e5b5b58ffd75c7fbcdb5957fd95ff6ab9df03e9379fb547ed0525f6a51c916830edbaba81bfe58e9f1b6d86dff00de91be56ff007a46ae8bf6aef89167a0e8fa7fc31f0faf916b6f0c2da82c7ff2ce155ff47b5ff79be591bfe03fdeaf7afd99fe1049f097e1faff006846abe24d6196eb50fef43f2feeedff00e02adf37fb4cd5c5cdeef3772cf569995576aaac4aabb5557eeaaff76b1f436dd24cdfed5686a12f956f249fdd5dd597e176ff00476fe26dcbf2d7301a5aa3dc37976b6724715f5d49e4dbc927dd8db6ee699bfd98e35691bfdd55fe2af23f8b1f16349f857e05d43c51796f2cba5e9f0c767a4e9b236d92e15bfd4ab7fb5237ef1bfd966feed7a0437ffdada86b9a9348bfd9b1f9da1d8b2fcab22c6d1fdb6456fe2f326db0affb36f27f7abf37ff006e0f8f16ff0013bc78be1dd0e6597c3ba0cd22b5cc6df2de5e7dd9245fef2aaaf96bff00026fe2ad2953f6950a94bd9d3e63ebff00d887c5571ac7c3fd3f54d42ebed7a96ad26a1ab5e48df37993497532c9feeffc7bafcb5e31ff000528f877fd8df11bc3be36821ff47d6acdb4dbc917eefdaad7fd5eeff69a165ffbf75a3ff04f8d7e63e08811e7db6f65a9de5971ff002cd66fb1ccadfeefcd71ff008f57d3ff001dbe17dbfc7df843fd832f9715e6a50afd8e4917fe3cf548559ade4ff75b6c90b7fb2d557f63589947da53b9f3ff00ec5ff1db4bbaf877269baf5e4162de11b585649ee66dabf6169963691bfd95fdcaff00c0bfdaafa2be03c76ff17be14d8eada46a4ada6c9791ab4cd1b6d99ad97c96daadf32ffab8777fb5babf206cf4dbeb7bebab59d65b19a366b7ba8376d65656f9a36fef7ccbff008ed7e9e7fc132f5c593e16f8c341566ff895eb8b711ab37dd8ee2dd5bff428dab5af42318f3448a73e63eca8d7ca8d557f8576d4b4c5ed4fae22c28a28a0a88ca653e9ad5007c9770d54e66a9266aa7335741d1a90c8d5c27c63f181f037c32f12eb91bec9ed6c645b77ff00a6d27eee3ffc7996bb791abc1bf6bebe6b6f8451c65be5b8d66d236ff6977337fecb5b538f34a22a92e58ca47c6d79b6c2d56dd5bfd4c7e5ff009ff815733336dad8d62e3fe04ccdf2aafde6aaf6ba5ecfde5c6df33f863fe15af76478267c3a6b5c7cd3b3247fddfef558dd1daaed855635a9afae962f957ef7f0d64cd71f2fcd53f088b8d74df7517e66fbabfdea936b5c5c476eadf7bef37fe8551c36ed670ee6ff008f893e5ffae6b57347b7dbe64cdfc5fbb5a7a81a1f77e55f916abdd36d555fef5586acf9a5f36e3fd9fbb5916588feed0d4e5fbb49cd0056ba6fbab50734f9befb546b4017ac7e58dbfda6ab0d50dafcb0ad49400535a9d450046d494ea635004724bb56ab53e46dcd4ca0028a28a007d46d433537755811dc49e546cd593b5b77cdf2b7f7bfdaaeabc33a5c7adeb5b655f36ded7f7922aff137f0ff00c06bb4b8f86ba5de5bdc2c3bace491b74726edde5b7f776ff76a245463cc5d568fe287809b663fb4edfe6dbfddb855ff00d0597fcfcb5e4cbfeeb2b7f12b7f0d741a15e5ff00c38f17017a922c6bfbb9d17fe5a43fde5ff77ef56ffc54f0aae9d790eb965b5b4fd41bf78d1fdd591be6ddfeeb2fcdfef54f3172f7a27156a9e6c8aabf79abd13c1fae5f782f5cd3758d264f2afac64f323ddf75bfbcadfecb2ee56ff7ab8bf0fdaee99a46fbab5d542b448989f607c4cf0cd9fed2df0774ff0013786a3dfae69b1c935bda7fcb4dcbff001f166dfed7dd65fef32aff007ab81f837ab43f1cfe16dd7c27d52ea38b5ed355b52f09df4ffde5fbd6bbbef7cabbbe5ff9e6cdff003cd6b9dfd9cfe2aafc34f187d9f5199a2f0eeacd1c378dbbfe3d64ff0096771ff01fbadfecb7fb35d27ed31f0d350f847f102cfc7de1c66d3ed6faf9666683fe5c7525f9b72ffd339be66feeff00ac5ae0b72cb90ebe6e6f78f33d27c07e20d72df529ad749b99574df316f36c6cde4b2b7cd1b37f0b7fb2df7b6b57dc1fb1cfc50bcf11f84f50f01eb9e62f88bc2adf678e39fe5924b556daaacbfde8dbf76dfecf9757bf679f187867e27785756f1269da7db59eb1ad3476fe24b18feeb5c471b2ab32ff007595be56fe25ff00696b07e287c2fb8f873f113fe176785da5964b3b86baf1168dbbe5b8b36558ee2487fe03b9995bf8be65fbb5329737bb211f446b9169f75a4ea16fab2c6da5c96f32de2cff0077ececade66eff0080eeafcd1f08fecf1e28f1d6ade30d2fc39f63be9bc3b3496ff35d2edb8db26d8f6c9f77e65f9959be56dadf36eaf7af8f5fb5569be2af84b1af82ef36dc6a534da6ead63a82edb986de4864f2e45ff812ee5656ff0065bef5781fecebf1557e107c50d2f5ab89258b45915acf548e05fbd6adfc5b7f8bcb6db22ffbb5508ca31e614be23f42be13fc3ed07c11e0f8e3d2749974cb7d5a186f2f349bedd2471dc792b1ccbe5b6edbbb6b6e5afcebfda13e18b7c25f8adac68317cda5c8df6ed35be5ff008f599999576ff0edf9a3ff0080d7ea447751dd59dbcd04de7c3242b24722fdd68f6ee5ff00c76be61fdb93e1cdbf8a3c0fa3f892c2de4935ad2efa1b391a08da466b7b86dbb76afccdb64f2d97fde6ace954e591523e23f0ee83e20d4bfb4b56f0ec72b5e787edd75669e0ff00596eb1c8bb64dbfecb32ff00e3d5e75f103c552f8d3c7bafeb772b12cda8ddb5cbac11f96bb995776d5fe1afd0bfd977e01789be15788b5ad6b5bb76d3ef16de6d35a0dcb35b5f472797247246cbfc4ad1c8b22b7f797fdaaf877f696f87d6ff000bfe34788347b0568b4b93cbbcb1566dde5c322eedbff016dcbff01ae9a75232a86138cb94e1ed5b755a5fbb58f6336d936d6c5761811cdf75aa9af6ab573f76abc6bf350036f3e4b7db58b37f156b6a0df756b26e3fd5b5007a1497d0e93f0de0d38baacf7d6f1ed8cff75a4dcd27fc06beaef853a3e9fe1fd25adf4985a2b35936ab45ff002d3f87cc66fe266dbf7abe1fb8b892ea45f36467f2e18e15feeaaaaed55afabb4df889ff000aefe0fe87a841245fda5269f0b5adb4db59a491b6fef197fe03ff007cfcb584e275d097bdcc76df18bc45a7dd58c9f0de45925d7b5c8ed7c9feedbeeb8f959bfdadb1b32ff7b72d7ba7817c11a0fc2ad2574dd0ec60d3e18559a6bb93f79349bbef34927f16edaabffd8d7e76d8f8d354b7f192f8a25b8925d596f3ed924ff32b337fc07f87f876aff0fcb5f7e78a3c4cd2c31dbc122c0cd1ac934927cbe5af96adb9bfbbb7f8bfbbf35734e9f2fba6b097b59731e17fb616bd0ea567e1957dcb78b7570de5fdd558fcb8ff0087fdedab5b1f03fc39a6fc1bf84f79f1135c8f75f5f5afda1636f9596df77ee615ff006a66dadff7cff76bca595bf689f8dd6b636fe6b7876dfe56936eddb631b7ef24ff0065a46ffd18b5d47ed4df10575cf135af8474e658b49d176b5c471fdd6b8dbf2c7feec71fcbfef3352e5f8601cdf14cf21d635cbef156b97dad6a9379fa96a1335c4cdfc3b9bf857fd955daabfecad49a3e877de23d62c749d361fb4ea57d32dbdbc7fde91aa9c6bf2d7d25fb33f85f4ff06f84f5cf8b1e21fdc59d9c334362dfc5b57e59245ff699bf76bff02ad672e5899457348e93e3d6ad67f04fe0ae8ff0ff0041badb797d1fd9649e3f964687ef5c4dff006d19b6ff00c0bfd9a8ff00659d67c13f0dfe1febdaa5fea502f8824b55bebef9b6f936ff0037936f1b7fcf4f97732aff00148bff0001f25f06d96b1fb4c7c6cfb66af1c8d62aad797d0c0df2dbd8c3f32dbc6dfde6f9635ff6999abd32cff639d4b59d3e1bc975c83c3d7171a82cd79a5ac6d3436b6acaadb636fe29159997e6f95ab0b4631e591b7c5a9d86a5fb687866d745d366b5d2750d4f54b8b569a6d3f72c71d8dc7f0c7248dfeb1777f757eefcdf7be5a93c23fb575af8d3e2068be1db7d06dac6cefae961fed2bbba585a35f27737cbb7fd6799f2aaeef9be5fe26ab0dfb1bf8162d37588cdd6b2d25e6dfb1ddc932f9963f2ff000aeddb26e6f9be6fe16db5c5fc52f8471f867e387c23b1d0ec74fb3d36ea4b7b58606f95a46b79bcc9269bfbdb95bef7de665dbfdda9fddfd917bc741f172d6d74dfda93e14dc35af9134cd1acd77bbfe3e248e668e3ddff005cf72aff00bacbfddacffda635e5f00fc70f05f89aca692eb5ab5b38eea6824936c7b639196355dbf75597ccdd56bf686964b3fdaa3e1ac8b7904766df63b88609f749f65692e996466556fe2655fe2fe1af7cd7be0cf877c55e34b7f126a5a6b5f5e4366d62b6d3b7990c91b49bbeeff7bef7ddfef517e5e503c3f4ff00db8597ec6ba8f84d6e556d7fd21adaebcb6fb46e6ff57b95bf77b76fdef9bef5585fdb42c65875864f0bb4134925ac7a7c1e67cb22b36db869a4fef7f75556bd1b4ffd97fe1cd9dade59b786dafade4bc8ee3f7f71279d6bb7fe59f98adbbcbf97eeb7def9bfe03e0ffb59780fc2ff000fa4f0cdbd9c2d04dac5e5e6a9a85dc0aaccb6ecd1aed87f87cb55666555a1724a5cbca0749fb5f6b371e15f899f0e758b3bc91750b356921b1923dd1dbf97347fbcff00816edacbfecd49fb4f784bc5575f1a341f12783e3bc9752b8f2f4db382c57f7d0cd1c723798bfc2b1b2b36e66dbb7f8bef5687eda5676edf0cfc27ab59c91dcdbd8ea10ad9c9b9a46b8864b7dd1b2c9fed2c2bbb77f1574cbfb5cf82e5d435c559248a3b3859ad64656dba832c7e66d56dbf2fcdfbbdadf79aa63cd68ca207cb3e30f8c9e36bdf06de780fc417972d0c7a87da2fbfb415bed7ba3ff963248cdbb6ee556dbfecad7a2780f4b87e08fc21bef176ad0ffc4db568d668e093ef793ff2ef0ffdb46fde37fb2abfddae77e06f816f3e3efc5ad4bc45e256fb4d9dbccbaa6a9f2fcb753337eeedff00ddf97fef98eb37f6b0f897ff000997c429b47b2995b47d164687747f766bafbb237fbabfead7fdd6ad9c79a5c85a972fbc78adf5fdc5fdd5c5e5e4cd3dd5c48d34d237fcb4919b73357d11fb24f80ecece3bef891af32c16362b32d8c93fdd8d635ff48b8ff80ffab5ff008157cffe19f0cdf78dfc4da6e83a77fc7d5f4de4acbfc31aff00148dfecaaee6af7cfda33c656be17d0749f867e1efdc69f6f6b0b5f2afdef257fd4c2dfef7fae6ff00796ae7ef7eee2650fe63c8fe2478f2ebe2778eb56f125d2b44b7526db581bfe5dedd7e58e3ff00be7ff1e66ae756a35ed5346b5b00efbaaccdf756bec8f83fe0db3fd9ff00e13df78d3c430ffc4daeacd6fae236fbd1c3ff002ef6bfef3332eeff006997fbb5e2ff00b34fc206f8b1e3c8e4bc8dbfe11bd1da3bad41bf8666ddba3b7ff79997e6ff00655abd0bf6a4f1e5f7c50f885a6fc33f0cedb9916f956e997eec978df7636ff6615dccdfed7fbb5c9565cd2e535f846fec97f0e6ebe2e7c4ad4be2078a156f2cf4dbcfb53799f76eb506f9957fdd8d76b7fdfb5afba246dcdb9bef570ff0afc03a7fc2ff0002e97e1bd359a486d5774d72cbf35c4cdf349237fbcdff008eedaed23ae694b9a4064f881b6e9f37fb5f2d64e8ad34da4dd436f79169974d0fda23bb91777930f98b1b4cabfc4df7b6ff000ee5ad2f12343fd9b279fe7b43ff003ced9774d336edab1c6bff003d1999557fdeacb5d264d26d66fb47d9ff00b62e1964bc915b7431b47f2c76f1ff00d3bdbaeef9bf899a493f8ab2915189bde1fb7d07c4da4cd636fa7c496762cb6f6fa7c9f2f970aaee876ff12ee566f9bfbccd5f8cff001dbc00df09fe2d78abc23e6493c3a4df3436b24bf7a4b765592166ff006bcb65afd2ff00d9dfc6d0fc4e835ed72337575a5cda8dc5be9f38dbe5ad9c170de5b2fddddb99a491b76edabe5aedaf847f6e2d02eb4bfda1bc437b2b492d9df3471412347b76b5bc71dbc91b7fb4ad1ab7fbb246dfc55d785f76a4a265888f34798eebfe09ebaefda3c59e24f08160a754863b98771fbbb639ade46ff7556e2391bfeb957d83af7ed41e0ff847790e8be35b8bed22fa6923d62de08ec6499a48649b7491fcbfc51c8d751edffa66b5f923a4ea179a6dc79d65753d9dc346d1f996d2346db5976b2ee5fe165665ae9a196fb5468e4bdbcb9bc68d76ac9733348db7fbbf35744f0f19d4e691942af2c794dcbcba6d4b5cd4af1aea5be6babcb8b8fb5cebb64b8dd233798cbfc2cdbb757dadff0004cdd7becbf13bc65a3b37fc8434386e957fdab7b8dbff00a0dc57c4b6ebb1abe90fd8475efec3fda73c1ead26d8f528ef34b6ff006bccb76655ff00bea15ad2ac79a9c854cfd5e5a96a28fee8a96bc689d6c2994fa65300a653e99cd007c7d3355391aa491aaac8d5d07410dc4b5f33feda9ae42be0ff000ee8eb22b6a171ab2de2c1bbe6f2638e45ddfeeee65af65f8adf1274ff0085be11bad6ef505c49bbc9b3b20fb1aeae1beec6bfecff001337f0ad7c0be25f136ade32f105e6b7ae5d7daf53ba6fde32fdd8d7f8638d7f8635fe15aecc352e69731cb88ab18c794c88edf6c9e74bfbd99bf8bfbbfecad477974b6f0b48df77ff0042a75c5c2aad73f7974d7536eff966bf756bd4948f1c6c92b33348ff0079aa4d3e2fb44de73ffab8feeffb4d54f6b5d4cb127de6fe2feed6b7cb1c6aa9f2c6bf76a0a1b3379b27fe835b50afd9e158d7f856b1ec57cdbc5feeafcd5b0df7682c8eea5db1b7f7ab3a9f34be6b532a00bf1fdda5e6990ffab5a73500519bef353569d27de14e8d7735005c8fee8a92994fa002994fa6b3500254133548cd55dbe66a006d14edb4d6ef400ca46a5a2802266a86697c8859bfef9a919aa9dd36e93fd95a009b498ef17ceb8b5f37cc857749240df32ab56de9fe38d6b469add9a4f3e358ff00d4dcab6d915bf8bff1dfbd5e91f0d34d6d3740b10d2473adc47f6a5dabb5a356fe1ff6aba39b4bd2f58bcb75b88629ee34f916687fbcadf7bfe05feed49bc607986a9e21b3f1b784ede1bb658fc456bbbc9655f964ff0067fe04bff8f2d74df0b2e22f1af866f3c277abe7b46bfe8ffde68d9bff0069b7fecb5b5a87c15d1f595692c249f4bb859bcc668ff78bb59b76ddbfc3fecb5665c780f5ef847ab68fe2eb49a2bcb35d4996de75dcade62fcde4ccbff4d1777ddfbdf3544a4572c94af231f5af07df780f5cbcd07528d56f2cdbe665fbb32b7ccb22ff00b2cb4d8d6bea0f89de19d3fe3efc37d3fc65e19b766d6ace16db6dff002d2455ff005d6adfde656f997ffb2af98e165655656f96b2854e609c397e12655565656fbb5f5d7c09f16e9bf1b3e15df7807c55bafaeb4fb7fb3b6e6fde4d67bbf7732b7fcf485b6aeeff00663fef57c8eb5b9e0df16ea1e03f1469faf696dfe996726ef2dbeeccbf75a36ff6597e5a271e688465ca7a57c2ff0011ea1fb2afc7a9b4bf104ccda2c8cb6ba84f1afcb35ab7cd0de2affb3f7bfefe2d7dfde32d2e4f157807c49a5d94d1b4da869b716f0b2ed68dbcc8595597fbcadffb357ccff1cbc0363f1ebe13e9be30f0cc7e7ead676ad7d62bff002d2e2ddbfd75ab7fb4acadb7fda565fe2a87f62ff8f4baa68f1f80f57b8dd7d630b49a4cf237cd716abf3793fef47f797fe99ffbb5c8fde5cc6bf0fba7c7bbb746bbbfbb525bab34d1c29f349236d8d57ef3357a77c68f877756bf1dbc45a0e87a3dd6dbeb86d434db15fde34d0c8ad27eeffbcbb964f97fd9db5ec9fb1afc3bd73c3fe266d5b5bf0dc773e1fd7b455bad3f5068e3b88639a1b856556ddf34337dedaadb5be5aeb73f76e67ca43f06ff006a0b3f06fc0bd43c3f7fab4b6be24d3e3ba5d1fcf85a4565923dd6ebf37cbb55b77cbfdddb5e3be3efda13c5de3ad6a6d493509745692cfec6d058dc48aad1f99e7796dfde559b732eef9955b6ee6db5ea9fb767806df41d73c2be24d36d60b3d3ef2d5b499a0b68d638e3921f9a3f957fbd1c8dff007eebe57dff00354c23197bc54a47ea77837c6f6bf163c03a5f89ac9957fb5ad775c47ff3c6e97fd62ffbcb26effc76bf3ebf6fcb1f2be27787eea44db349a5b5bb855dbbbcb99b6ffbdf2c95e8bfb20fc6487c25ad5e78475cbe5b6d075266bab79e466db6b74abf32ff00b2b22edff8146bfdeaf9cff68ad6a6d4bc7fa95bbc9235bd9ea9a82c3e67de5f32e3cc65fe2fe2ddb7fd9db59d3a7cb50aa92e6a6795c6db596b6a36dd1ab56356ae9edbadf6d7a0708e9be65a8e35a9a4aabbb6b350053be97748d59f3fdd6ab1336e91aaacdfc3f2b37ccbf76803b0f01f8424f1b78b2cf4c4deb6ed26eba9a35ff530ff00137fbdfddff6abd03e31781ecfc17a969afa72cab63750f970f9f234927ee7fd633337ddf99976affbd5e99f05fc12be13f0cc6b7202ea575ba4b8655f99646ff967ff0001ff00d0b7567fc74b0b8f136a9e0df0fe9d1f9baa5d5c4de4b49b57f76caabf337fbcbb9ab97da7348ecf65cb4ffbc78ef87f4bd4356d421b7d2ecee6fafbfd7471da46d237cbf36eaf48f889e2df14697a1ea9a6f88fcdb1d6b56d4a6babedcdb5bc9daacd1fcbfc2d237fbbf2b7fb55f437c3ff0005e8bf08fc1b3476ecbf6a685ae352d41bef48b1afdeff0065557736dfbb5e0bf0df41b8fda13e345c6b1a94727f61dbc8b7d78b27cdb615ff00536ffef36df9bfeda54f3f37bc57b2953f77ed48f52f87b6f6bfb3dfc07b8f145dc2bff0946b51acd1c72afccd249bbecf0ffbaabfbc6ff8157cd71b4971234d3c8d3dc48cd249237de919be666ffbeabd4bf692f1d378cbc7cba6dbc9bb4dd0d5a1555fbad70dfeb1bfe03f2c7ff016af2f5dab4423eef34ba93397d989b9e0df0adf78ebc51a6f87f4d5ff004cbe9bcbf33f8615fe291bfd955dcd5ee5fb5578cac743d2743f85fa03795a5e930c325e2aff00b2bfb98dbfdafbd237fb4cb57be05e8d6bf05be19eb5f1435e87fd32ead563d3ed9bef792cdf2aff00bd336dff0080ad71ff00b39fc31b8f8f1f1235cd5bc43e65ce9f6eb25d6a122b6df32ea65658557fddff0059feec6bfdeaca52e69737d9895cbeef2f73aafd9f7e2ff84fe0b7c33f117daad6597c5d7134732c71ff00cbd2b2ed8e3ddf763f27e666ddff003d2a9dd7ed79af697e2af146a1a6dadb4ba6ea0d0fd863d497e6b5f27e5566556f9b72eedcbfde6ddfc3f3759e0bfd8b57ecba2c9e28d7165b8db7136a1069727cacbf2adbc6b232fcadfeb1a46ff7556bd4ac7f67bf877e1785ade5d16cda1d42d61d266fed29bcc6b86f3372b2eefbb248db7732fdedbfecd672953e6e62bde3e7bf857fb4578db4bf18697a6eb9a95f6b3a6df5c2d9b5a4f1ee9a1f3a6dde647fc5b959bf8bf87e55aebbf6d4ba8ecfe29784fecad7367ab470f98ba947232aac7f68db0f97fed2b798db97fbcb537ed00dac697fb49780f508ad62b3b58e6b3b7d36e648d7cb91a3995645ff00757cc55ffd06ba8fdb52ea18bc0fe1557877dd5af881648d5976ab2fd9d99955bfe02b55f6a3217d939bfdb2bc2be24baf89de1fd4ac34dbcbeb15b18ed6d67b1b5691a3b85999b6b32ff13332b2d70b67e26f8d9acd8f8a34f826f144f1ade2ff006c47e5b4724770db6358f77de5fe16f2e3fe1f9bfdaafa2adff6c0f03dd68faa6a92c97967710c9e5c7a4f93fe9379b9576c8adf7557ef2fcdfddacbbcfdb2bc1f67ac5d5bc167abde59c778d1c7771aaaac90f96bfbe556dadb99be5dadfc3f37fb353194be1e519e2fe22f0bfc62d37c3b7df1035cbcd56cfecfff0012db869ef9a3bdfb3ee68f7346bf7a1dcccbbbfdaddf77e6ad2f8a5143af7eca7f0bf54b5859a3d266934b9ae59b735bb7ccbb7fdd6655ff00c76bdabc6de32b8f8c5fb3cf892e3488e5d324bad266baf2f525dbe65bc7336edadf77e6585955bfbcd5e4be15f1559f89bf629f1768b15bc6b7da6cd0d9b41b777da24b8ba8e486455ff9e8db997fde5aabfda03d8ac7c1163f17ff0067bf0fe826ea5d2ade6b1d3f73347ba4b792df6fdd56ff00764ffbeabe5bf8f5e0bf0efc27d6b4ff000ce91a85ceabaa5bd9b4dad5dcfb76f98cdba38e355ff57b63f99be6fe25ae9bc37fb4c78ebc06b6fa2deccb78da3ccd0b47771ab48be5c7e5adac8dfdd8d957fdaf976eeac9f803f0c6f3e34fc4a9b54d57ccbcd2ec6e3eddaa5cc9ff002f570cdb961ff799be66ff0065688f343de7f081ea5637edfb34feccb0dc7cb078cbc4cde742adf7a39245f95bfed8c3b5bfde6af8def1b6ab7ccccdfde6fe2af6efda93e242fc41f899711daccb3e97a2ab69f6f22fdd924ddba6917fde6f97fdd8d6bcafc1be0db8f889e30b1d0e26682de4fde5e5caff00cb1b75ff0058dfef7f0aff00b4cb5ac23cb1e690e5ef7ba7ac7ecefa4d9f817c1baf7c4cd6e3fdcc70c91d9aff001342adf36dff006a4936c6bfeeb578beadae5e789758bed5b5093cdd42fa66b8b86ff69bf857fd95fbbfeead7ab7ed11e3cb5dd67e01d0e35b6d2749f2fed51c7f77cc55fddc3ff6cd7e66ff0069bfd9af1b8e8a71fb7214fddf74b51d68697a5dd6ada85ad8d85bc9797d7532dbdbc11afcd248cdb5556b3e3afac3f61ff85eb79aa6a1e3ed4a355b7d3d9ac74b693eef9db7f7d37fdb35f9777fb4dfddaa9cf923cc113d1bc492dafec97fb3edbe93613452f89ae99a359d7fe5e350917f7937fd73857eeffbb1ff007abcc7f63df873236a971e38bf8da56f31acf4d693e6692466ff00489bff0065ddfed3573fe36d5350fda97e3a2d8e91248ba2c3baded64fe1b7b38dbf7971fef48df37fc0a35afacbc3ba4d9e83fd97a4e9d6eb67a6e9f1adbdbc0bfc2abffb37f1337f7ab8e5eec6df68b3d0adff00d5ad5c56555dccdb557e6dcdfc359f1b6d5a6eb1acae8da5dc5e7d9fed9247b561b45ff97ab891b6c30ffdb4936aff00bbb9ab9c0934f692eb5c667876dbe8f0c775b9bef35d5c2b797f2ff76387737fb4d27fb35f1afedc5fb4a7fc21fa4df7c39f0fccebae6a10aff6b5dab6d6b3b7917fd4affd36915be6feeab7f79be5fb4bc2fa4ae9be1fb5b79e46d4ef2de1f326b96dcab71348acd34cbfde5666936ffb3b6bf21ff6c4f0ac3e0afda33c65a7d9b48da6cd751ea163b999bfd1ee2359157e6f9be5dccbff0001adb0d15297bc455972c7dd3ebfff00827e6b8fa87c13b8b53f2ae9b79aa5aaed6fe16fb3dc37cbff00026f9ab8dff829cf8296e0f863c6569b51e3916c7548d57fe5a5c43ba199bfdefb2cd1ff00db25abbff04dfbf8dbc27a95abaaaffc4d3508f77fcf4f32c61655ff00c82d5eabfb62f8526f147c37f11e9813ccfb5786ee2f2d5d57732dd69934779b7fde6b79af17fe02d55f0e203e2a47e5a69fff001f51eefef57656bf2c6b5c5d8b2b5c42cbf7772d76d6abfbb5af58e4897a1aef3e0ef89bfe10ff008ade07d7376d5d3fc41a7dc337fb3f6858dbff001d91ab818fef55a9b77f67dd327fac585997fde55dcbff008f2d41ac4fde465f2a6923feeb32d3ab17c23ae2f8a3c2ba1eb48db9752d3ed6fbfefe42b27fecd5b55e0c4eb1f4ca28a64c46b535a9cd4d6a0a3e3391aaac9ba591557ef336da748df2d66ea5a92e9767757cff0076d6192e1bfed9ab37fecb5d0741f0e7ed07f111fe237c43bd91246fec8d1e4934fd363fe1f95b6cd37fbd232ffdf2ab5e59336da9ade5696cede476dd2491f98cdfed37ccdffa1551d4a5f2a166fe2af7a31e58f29e04a5cd2e633f50b8f35bcb5fbbfc559b336d5a9375471a7daaea38dbeefde6ff0076a6422dda47e543b8fdf93ef7fb2bfdda7c8d5248dfc55559b7530353494fddb49fdeabd70db616a8ece2f2a155feead36f9bf76abfdea82ca54ab4d6a16802f43fead69cdf769b0ffab5a24a00a6df7aa6b74a8ff8aad46b400fa7d329f400ca6335399aa191a801acd494514008d51b539bbd32800a64d37f0ad134be52d575fef5000cdb56aa09562b88e4923f3638d95a48dbf8bfd9a7de4bb63da3ef37ddaf49f0cfc39b1d634fb1be79ae2169a38e68e35dbb576fdeff007b7354c8a8c798e9e6d1ece3f0cdd5bdac9f64b78e168e19fef793b9b72ee6feefcdb7fe04b5e63a1d86ad751b4da6dadd4bf67659a4fb37fcb36fe16ffc76bd53c7ba84d6fe1cd425548e68e692386e15beeed9372b7fdf2db6b27e0be9ab7135f3799feba486dfe6ff00beaa0d5c79a5ca51d07c6fe22d06ce186769fc9bab8f3a396f95b749fc2caacdfc3feeff007abddadfe31784fc69e07d4bc13a969f7562b7562b243aa36d655d4372fcd22ff0c6adb7f78bf36dddf2d7b5780fc39a6adacd63a8d9d8df47a82eefb0df46b22cd6f1edfbd1b7f0ee65ff0077e5adab7fd92fe1dcb6ba3dbcfa5c93c7a7c774bf2ed8e4b88e6f9b6c8cbf349e5b37eedbef2fcaadf2d724ea46474f24a07ccbfb3dfc4693e18f8da6d175cdd69a5ea132dbdd2c9f2fd86e97e559bff656ff00676b7f0d697ed49f0bdbc1fe2aff00848aca158b4bd5a465b858d7e586f3f8bfe0327deff7b75771fb497ece31e93e19b7d7bc39f6cd43fb363686f20bbf9ae64b155dd0b6efbd2342bba3666f99a355ff009e756be0ef8cb4bf8e7f0def3c0be27669754b5b558da656fde5c5baff00a9ba8ffe9a47f2ab7fc05bf89a9737db88edeef248f94d5aa456ad2f187856fbc07e2ad4341d4b6b5d59c9b7cf55dab346df34722ffb2cbf3566af6ae9398f7cfd957e3137837c44be15d52ebcad0f549b75ac9237cb6b78df77fdd593e556ff006b6b7f7aa3fda33e17ea5f083c7d6fe3cf0ceeb1d36e2f96e15a05ff00906df7dedbb7fe79c8db997fe04bfddaf0b55565656fbb5f627c0df88da7fc70f02ea5e03f187fa66a50d9f932337facbeb5fe1997fe9b46db7737fb2adfdeac671e595cd23ef47949356d6ffe16c7837c27f163c2b1edd7bc237124da868d6d1ac971b76eeb8863fe2f957f7d1aeefde2ee5fbd5f447c3df1969fe34f08e8bad69d74b736b7d671dc2cbb76ee56ddb5995bf8be5656ff006abe13f08f8835efd91be354da7ea52493e92cd1fda9a35f96f2cf77ee6ea35fef2ff77feba475f547c2fbad1fe1f6b10f85ed6fadbfb27c497d75ab784e08b779335bcd1ac935ac6db76fcb26e9235feeb2d6138d8a88dfdaf3416f137c01d71a285679b49923d51be6f9a1f264db332ffc059bfefaff0076be05f04f83f52f1f789ad7c3fa37913ead79e62dbc13ccb0acd22ab3796acdf2ee655f9776dafa53f69ef8f5a92f88b54f09e97752e9971a2eb1346d776326d5bcb792de3fddc8bfde56f9597e656a77ec5ba9683e20f115e697ab697a6ffc241a5dbc37da2ea51c2b1ddc91c2d22c90b37fcb45559b77f7b6fcadb95576eb172a74f9899479a458f187ec9b6fff000cfb1eb56ba5dd69ff0011acf4bb7bcbab4f33ef342ade743b7eeee68fe6ff007a3ff6abe17f1437da2dede656dcbe67deff00796bf6826956d59645dacabb5bfd965afc8df8e9e118fc17e3cf1a68306dfb2e97ac48b0edfe18fccdcbff008ec8b5542a734b96445589e69cd5bd35be665aa2b562cdb6dd2ffb5f2d771cc694954666dbbaaf4959f73de8033daa259152ea062aacab22b6d6fe2a9e4aaadfeba3a9901f5c691e376b2f863a5eb5aa3379cb6ab75337dddcccdf2aaffc076edaf25d37e24ead6be32d3fc49e67da6e2c669a4b5827fbaab27f0b6dff0080ff00df3583ad6a5aa5c687a0e9f7578cf66b670c91da2fcab1eddcabbbfdaf96b5be1edd58e9be26b7d53518d67b3d2e36be6836ff00ae65ff00571ffc0a465acb9796274caa734a313dbbf68cf889269ba1c3e11b5dcdaa6a51c371aa797f79616dbb61ff007a465ddfeeedfef5740ccbfb35fc138ed6265ff84cb5a6daccbfc370cbf337fbb0afcbfef7fbd5e6ff00027c2f75f113e215f78c35c6f3edf4fb8fb64d249f766bc6f9a35ff7635f9bfe02b587f13bc74df113c6536a0b23369b6bbad6c57fe98eeff59fef337cdff7cd61cbef729bf37bbce7331a6d5fbccdfed37de6aefbe09fc39ff859de3eb3d36756fec9b7ff004ad4997fe78aff00cb3ddff4d1b6affdf55c1b36d5dcd5f5d7c39b5b1fd9c7e09dd78935bb7ff89d6a0ab7135b37de691bfe3ded7ff666ff0079bfbb55525cb1f74ce0b9b5385fdabbc74daf78aac7c13a5c7fb9d3da36b858db6ab5c32feee1dbfecab2ff00df5fecd62fc19f8e7ff0a8f5486c5adfed3e1b5baf32e9a0f96691b6b2b48bf36dddfecb7f0aaafcb5adfb2df8226f889e3ed5bc75e2355beb5d3e669a4f33eedd5f4df36dff007555bff1e5afa2ac7e12f807c11a6ff6c5c78774cb3b3d3ecda15bbbe559bf72bba469a4ddf2eeddfc5b777fe83584a518fb869ef4bde3e75d6bf6aff1b6b9a832e8d345a65bc7aa7db2c63821592658555963b593f8645f9b737cbf79a9bf0b7c5be26b7f8c5e09d07c54ba95e5bc9af2eb1fd9f731fef96e2e216559bfbcabfbcf336ff77e6db5f4e78774df01e9baf69b7de1fb7f0f5b6b1a942d6ba7dcda7971b490c6b1b346acbf2fdd6566fe2af9ff00f69af11eb1e0ff008f1a0f88ac2ce2d3f56b3b1b7b8b5bb55ddf6c9164917f79fc2db7fd5ffbb5519465eea8932e68fbc76dfb745ac76ba0f82f525859a6b7bebc8f72cdb576ed593cbfef6e6dbbb77f0d7b07c58f87d37c69f873a7e9ad791f87966b8b5d42469e1fb5347b636fddafddf997ccfbdfc5b6bc67f6e2bc92e349f01c32fcad2497934d6cbf755bcb87ff0041ddb6bcc6c7f6a0f19687a2e9f636175e52dbe83fd8b24f79334d2349e648df6c56ddf2c8aacb1afdef956a634e528c6511fda3d8341fd8d6d7fe11db8b3d535a8e7d5a4bcb799afac6ddbf736ebf2c90aab7fcf466ff0059fc3b56aafc50fd9efc2be08f01f8c35e82c6f27b886de15b1b6b69246fb1fefbfd73337cd27dedb27f0aaafcbb6bc67c5df193e2278c96df50bfd4b52b3b7b3b75b7f3f4f864b38f6c9b7e691976ee66dabffb2d7bd69be26b1d4bf643bebabff115cde5c49a4cd1dd5ceefde4774d32af93ff007d796bfed2b337f1512e68fc522bdd3aaf81ba1e8f71fb36dbd9ea3752df693aa6977125d79927cb6aade679cabfdddbb777fe3d5c8fec436fa6cbf09f5af3d606b89b5a863ba6bb8d5964db1c6d6ff7bfdadccbfed54df096c24f1f7ecb379a4e90d258ea8ba6dd6971b336d8fed0b26e66f33f856459155bfe055f33f8b3e1df8bbe16ea16edade8f2d8edf2ee23b98d966b66db22edfde2fcbf7957e56f9aa62b9b9a223df3f6c8ff00845f4d9345d274dd06cd7c6d7d26e692ca3f2e4f2599bef2afcacd248db5599777deaea3c6d790fecb5fb3ad9f87ec2455f156a8ad6fe7c7f7bed522eeb8b8ff00b66bf2affdb3af3bfd9cf47d53e377c6ad43e22788d9678f4d996e376ddb1b5e37fa98d57f85635f9b6ff0fcb5e73fb407c4b6f8a1f11b50be8a666d1ec7758e9abbbe5f255be693feda36e6ff00776d118f34b97f94b3cb6e255b78ff00baaab5ed9e0fb75f827f08ef3c51791aff00c241ac2c725bc122fccbbbfe3de3ff00d0a66ae57e0bfc316f891e28692f2166f0fe93b6e3506ff9ecdbbf776ebfed48df7bfd956acff8f5f119bc79e349aded6656d1f4b91a187cbfbb34df76493fddf976affb2bfed56f2fde4b9088fbb1e63cef7492c924d2c8d3cd23349248df7999be6666a9a35aaebdaad46d5b18ea749e03f06ea5f107c5da5f877495ff004cbe93cb595beec2bf79a46ff65577357d8dfb43788f4df81ff05749f87be1e6f226d42ddad55b77ef16cd7fe3e266ff006a466dbff026feed73bfb13f816dfc3fe15d73e226b3b6d61ba8daded6793fe58d9c3f34d37fc09976ff00db3ae5fc03a5de7ed45fb415c6b9a8c327fc23b6b32dd5c2c9f761b38dbfd1edff00de93ff008e35724a5cd2feec4da27b87ecd7f0957e1a7c3d5d4afe1f2bc41ae471dc5c6efbd6f0fde861ff00be5b737fb4dfecd779a4b79bab2b7f75ab7bc457bb61b86fe26feed73fe1dff8fa562bf357373737bc59db42ad2b2aa2b348cdb5557f89ab95dd7dabdc36a9e6359ac8cd67e1f8ff008be65659b5265fef32ee8e156ff967f37fcb4ade91a1bfb88f49977347716ed35e796ccacb6bbbcbdbb97eeb4cdfbb5ff65646fe1af9abf6d6fda23fe150f848f87b44687fe130d7ade45f323f9574db3dbe5ab46abf77e55f2e35ff00659bf86a231f692e5895cdcb1e691eebf0b7c796fe30b3861d26191b416bcbab7b7d43ce56593f79246cb1ff0012ab4d1c8cbfecff0017dd5afcf4ff00828978675ad13e39dbea1a9431b697a968f6aba5de471f97e7470af9722b2fdd59164fbcabfc3b5bf8abeb8fd8a2e233fb3df86246fdec763a5accd1aff0b477d336effd096aafedfdf0dd7e227eccf16bf0459d53c30ebaac2db3e792ddb6c374bfeeed6866ff00b66d5ad297b3ac4548f3533c2ffe09b978b713788eda361f6cb5d634fba8e3ff009e91c96b790b7fbdf7abe8ff00da3be24687f0f3c3b67ac5f4d66971a6eb56f32e9b7337cd716f74b25bdc2ed5dcccbf67ba9b72afcdf2d7e4de9b75359dd2c904d2c127f7a091a36ffbe96ad5c6e91999d99d99b733336ef9abb2587f69539b98e68d7e58f291d9c4b15f471a49e6c6b26d56dbb772eef95abbab5ff52bfeed70d63ff1fd0ffbd5dddaff00a98ffddaec3389347f7ab52cd55a4556fbadf2d65af6abd6adb596a0d227ebe7ec87acb6bdfb30fc31ba76dd247a2c76b237fb50b343ff00b4ebd916be63ff008279eb3fda9fb34d9d9b7ded275ad4ac7fe03e779cbffa3abe9a5af0ea7bb52513a63f092514d5a4a430a46a5a46a0a3e23925ae67e203337817c50a9f79b49bcdbff7e64ae8246acfd4ad7fb4ac6eacdbfe5e2de4b7ff00bea365ff00d9aba0ea7b1f9a964dbac6d87fd318ff00f41aced71be58d7fbdf355dd30347630abaed923dd1b2ffb4adb6a878817e685bfdeaf7bec9f36f731e46d8b5a1a7dafd9edfce7ff005937fe3ab55ec6cfed526e7ff52bf7bfda6feed695c4bb99aa62519f792ed56a2d5775c47fef556bb93ccc7fb5255fd3d7fd2169966e47f2ad55be6fdf2aff00756ae2d516b79af2e2458219676ffa671b354015da9ab535c5acd672797710c9049fdd9176b546b4017a3ff56b435363fbb4377a008d57e6ab0b51af6a9168016919aac436171750dc4904324b1dbaf99332afcb1aff00b554e46a00246a85a866a5a0062f6a1bbd14500151b36deb4e66dab546697cd6ff0066801b34de6c9522fdda8d57e6a8f50b8f2a1da3ef350068c7e1bbcbed1ceaf0c6d346b3792238d7736ddbf7ab4343f12ea9e1bfecd9964956d55bceb78666658e45566ffc777577ff000be368bc336be6b2ed99b747b7f87f87ff0065aea238f47d621b393cbb1bb8e3dcd6ebb57e5dbf2b6dff003b6a4de303cc75cf1f5d6b9a6c966f6f1411c8dba4dbfef2b2edff00be7ff1eaf4ef81fa335fd8d9daf92d14935d49f685656565556ddbbfdddbff00b35535f85ba0c967e4ff0067cbb559b6cd1cdb646af56f07b69df0ff004fbcd4a691adadec6d5995b6eedd237cb1c7fef332fcbbbf8be5acaa4bdd35853f7b9a4717af6b5e24f157c6edbe10bed4355d421d4197438eda4dde4ff13470eef97cbdcb27def976ff00b35734df8a5f16bc3f36a5241a87882292fafa4fb448d66d2335d46aab27fcb3f95956355655fe15aedbf627f0fc97fe3ad73c45711af936362d1c8cdff3dae24fe1ff00695559abec2d4bc51a7f8561d1edf57d7a2d16f356b8fb2daacf3347f6891beeed6ff75bef7fbb5cb2972fba0bdef78f94f49fdb5ef65f0dea11ea3a2c13eb11dbc3f619e293cc86699597cc5995be658e45ddf32fccbbbfddaf23f15793e03f18787fc6de05692c747d4a3fed0d360924dcd6732b6dbab193fd9566dbfed4722d7dadae7c0ff873f156eaf3c453e9363aac9796ed62daa69f70d1b7f17ef36afcab347b76ee65ddfde5af1bf127ec7375a6f84f52d3fc3fae47aac771e5de59db6acab1dc5bdf46bb595668ff0076d1cd1b32b6e55f99636fe1a98ca055a447f13bc23a7fed01f0cec7c61e1c8d7fb6ad6dda48e05f99a455ff005d6adfed2b6edbff00d957ca30caacaacbf75be65af5cfd9f7e274df0bfc71368bacf9963a5df5c7d96f239d76b69f74adb56465fe1f9be593fd9f9bf86ad7ed31f08a4f00f8aa4d72c2d7caf0fead33332c7f76d6ebef491ffb2adf332ffc097f86b587bb2b04bdef78f2156ad2d075ed43c2fad58eb1a4dd359ea56322cd6f3aff000b7feccbfc2cbfc4ad596b4fad8ca27d97e30d1b4dfdad3e0ad9eada24315b78b34d66fb3c1bbfe3deeb6fef2d59bfe79c9f2b2b7fbadfdeaf2ffd9efc4767e3ef0ddc7c1ff135d4fa2ea56b74d7de17d49b747369b7d1eedd0ff79595b736dfe2fde2ff0076b81f833f156f3e11f8b9752459aeb49badb0ea5631b7fae87fbcbff4d17ef2ff00c097f8abd7bf6a2f85b1eb56b63f18bc0b70d2b3470de6a13e9ff2b32aedf27508ff00bacbb5564ff7777f0b57272f2e86bfde3c0fe2345e20b5f1c6b91f8a9a497c45f6a66be924fbd249ff003d3fda565dacadfdda8fe1ff008dee3e1df8d345f13411f9f269374b70d06edbe747f7648ffe04accb5eedad4567fb597c299bc45650c717c52f0adbaff685a5b7cbfda16ebfc4abfdd6fbcbfdd93747f7596b8dfd96fc07e1ff008a1e26d53c3faf5adc4b6ba958c91d9ddc126d586e23fdf6d66fe16655dcbfeeb2d6fcfeefbc4f2fbc7df575ae59dc68bfdad69235ce96d6ab7d1c8bb5b742d1f98adff7cd7c25f1b9bc1fe3cbef8cfab692ab2ea8de1eb3bcdccbf34724375e4dc7fb3b9bcbb79372ff000b57a7ea5f1824fd9ae3f117c33d516e67934b8fed5e17bb923f3164b19bf78b6b337f12ab34d1eefeeeeaf90742d523d2f53d5a08bf7767aa693a8697b5dbeeac90b347ff007cb471ff00df358d3a72f88ae689e4aadf35395b6c8ad51c2fb955bfd9a7377af48e1369beed67dd7de7ab4b2fee55bfd9aa323eea00af2574bf0b74a8b56f17a1982b436d0b4c55beeeefbabffa1573125779f06ffe429aa3ff0012c71aff00e85448b8fc476df11b436bcd161d420b7ff8f56fde4ebb55561f957e6fe26f9bff0066ae06cd64b8f2eced6dfcfbeba99638d57ef337dd58d7fde66af68d72fed743f03ea1a85d4314ead1b5bdbc73aee592693eeaedfe2fef7fc06ab7ecebe0db7856f3c6daab2adad8ee86c6493eeee55fdf5c7fc057e55ff815612972c4e8e4e699d3fc44963f841f0af49f06e9d36ed4b528e45bab98ff008beefda24ff8137eed7fd9af138576ad6b78dbc61378f3c5575ab3ab456fb561b381bfe59c2bf757fde6f999bfda6acb66db1f0accdfdd5fe2a8847963ef0e72e695a27aa7ece3f0edbe20fc4286e2e2166d1743db7975fdd924ddfb987fe04cbbbfdd56ab9fb4c7c4693c79e3cfec5b39bcdd2f4591a15dadb966baff0096927fc07eeffc05abd4354ba5fd9aff0067b8ec60db178a354ff58dfc5f6c997e66ff00b631fcbff01ff6ab97fd8cfe1cc3abf882f3c4d79e54ed6b1c96ba7da49fbc92666dab35c6dfeeaf98b1eefef4958737db34e5fb071bf0f7e337883c03a7e97a0f87ade09636924fb45b490f9df6e9a49964f957ef7fab558fe5fe1dd53693f0fbe237c44b88f6e9fa92d9eb1f68bc59ef9a486c997ccf31bef7cabb9beeaff157d35ab78c3e1cfc2fd52c7c44d0e9905f788ae163fed2d3e3591996356db337fcf38d76edf95776e65dd5e67ac7ed6cd7f1c367e1cd163b69a45dbf6ef105c7eeede4693ef7cadfeaf6eef999be5ddfecd0a52f894439797791e67e3af84fac7c2db7f04cd3dc79faa6a57127ee23f9a0b3b85923f2e356fe26656566ff00d9abd5bf6dab7d4157c33a9232ad9d9b5c5bed56ff005774cab27fbdb76c6dff007cd64fed892ea570be03d5a2db0697716ad34363f32b4374de5c8dbbfd9dbe5aaff776d761fb5e44d71e01d3e69ed5a5b8fedc8d5675f9bcb6fb3b799ff7d332affc068e6f8644ff0031eb9e34f863a3fc52d0fc3f36b96f26a0d63e4df43240ccb1c8d2471b49b97f8a36dbf77fdaac387e157c37f0e5c5ae745f0fe9cba96eb3b78ef99648ee1a3669b6af98df348bb7fe03b76ffb35f20e9f67f10b41d0ee23b293c41a669b6ba9792d6904d347e5de470f98db6156ddb9636dcccabb5772eefbcb593e20f07f8bac347b56d6f47d622d2ede369a1fb74323436eb249f337cdf2c7ba4dbfdddcd53c9fde2ae7d65fb546a56b79f05eea46bafb742da95badbc907ccab22c9fc5b7fd9f316a9f80eeb41b7fd8bf529a2b58b506b7d26f9af2da7fe2ba693e6ddfeeee8d97fdd5ae47e1cb36a5fb21f8921ba8635b5861d42de1f2fef36d6593e6ff006b737fdf35d97c01f07c7e2afd9c64d0ef2fbfd1f5a5bc5dd1eddd6f1b4db5957fdafddeeff81547c31f987da3ce7e01fed23a2fc25f05b787f56d1eea766d4bed125dda7ccd24722aab332ff132ed5daabf797ff1e6fed0de3ad4be367c4ed2fc03e17dd3e9f6770b0c6bf756e2e997f79349fecc6bb97e6fbbfbcacbf8a5fb39afc2af0ec9e20bdf11457d6cb6fe4c3146be5cd26a4d37eee358dbef43e5ee666ddb97cbff00696baefd98fc3fa7f80fc17ab7c4af1037911cd0c9f679a4fbd1daab7cccbfed4d27cabfeeff00b5572e5f8e211fe53aaf8ade23d37f675f82fa7f817c3937fc4e35286487ed3f764dadff001f174dfdd66fbabffd8d7c8327cb1ac68acdfc2b1aafccdfdd55ad8f1a78d350f881e28bef106a8dfe9174df2c7fc30c6bfeae35ff006557ff0066af58fd947c036bae78a350f196b2b1ae87e1b8da68e49ffd4fdab6eef31bfd9863dd27fbccb5ac7f751e690fe23a0f88974bfb3afc01d2fc2b032c5e30d715a6b865fbd1c922fefa4ffb66bb615ff6abe4d555895557eead771f18be2349f157e206a5af3798b62dfe8fa7c127de8ed57eeffc09be666ff69ab876aba71e55ef194e5cc0ad5d57c39f045f7c4bf1a697e19d39bca9afa4fde4ff00c36f0afcd24cdfeeaffe3db6b93dd5f5d7ecd3a0e9bf0abe15ea1f1135cfdd4da95bf9dbbf8a3b356fddc71ffb5349f37fdfba5565cb10a71e63a6fda83c6f63e08f01e8ff000cfc391b44b716f1c73411fde8ec63f9638ffde9197ff1d6fef57bb7c07f854bf08fe19d8e97711aaeb979fe9daa37fd3665ff0057feec6bb57fefaaf9d7f65ff05df7c69f8b5aa7c4cf12c2ada7e9b75e7431b7cd1c979b7f731aff00b30aed6ff7b6d7d9d74fbb7570cbddf74dce1fc5975b6668d9be555dd58f67ab5be876779a95e337d96d6dda693c85dd237ccaab1c6bfc523332aaaff7996a4f1b5c6dbc997fbccbff007cad47e13d52dec2eaeafaead629ecf49685b6c8bfeb2e1596691bfed8c6d1edff00a6927fd33ace5f09ac4d2f1078a2cfe10782f5cf1178abca5d42d6d7fb53568216ff0096ccbb61b58dbf89635f2edd7fdaf31bf89abf217e2578eb54f891e30d53c45ad4de7ea5a95c34d36dfbabfdd8d7fd955daabfecad7e92fedc3e1dbef147c17f1369f6d0cd2c9a2c90eb96b25aff00cbe5bc7237991b2fde658e19bceff65959abf2bae25f35b72d76e1631e5e638f112fb27e9ffec0175249f012c20f95ee19af21b78f77deddb648d5bfeda2b2ff00c0abdcfc61a759ebbf08db48b999534ad5b4bfecd5959bef2dc473431aff00bccb710ffdf35f2c7fc13e7c41e6fc29686250d75a3ea971b9557e6daad6f751eeff00797ed4bff01af73fda3b56ff00842ff659d52fad66db71a2cd67756abfde5b5d5a36dbff007ef6d72ce3fbc3a632fdd9f91366bfb9858fdedab5619abaef8a5e105f06fc4af1668b10ff0047b1d52e23b76fef42d26e8dbfefdb2d722cbb6bda89e50963ff001fd0ff00bd5dcdaffa98ff00ddae26c7fe3f21ff007abb4b7ff52bfeed291ac4b0ad56addaa9eeab16adf3541aea7e8b7fc131f59fb47c3df885a4b37cd67af5bdd2affb335aaffecd0b57da11d7e79ffc1317595b7f881f11b4966ff8fcd1ec6f957fda8669236ffd1cb5fa151d78f5e3fbc3a29fc24cb4350b49590c291a968e6828f85a46aaed2f9522c9fdd6dd53495566ae83acfcfef887e1ff00f845fe2378bb49fe1b5d52668ffeb9c9fbc8ff00f1d6ae4b52b3fb642abbb6ed6ddbabde3f6aed07ec1f12b4fd5115563d6b4b5566fef4d6edb5bff21b475e2727dd6af7294b9a9c4f9fab1e5a928996db638d55176aafcaab59b752fcdb56ae5f5c6d6f97ef565ff155488895e6ff008fa856b7b43b59b50be58608da4999955557f8ab9f5fdede335778b17fc23367fd9a9f26a570bbafa4ff009e6adb76c2bffa137fdf359c4b2c48b6ba5fcbfbbbeb85fbdff3c63ffe39ff00a0ff00bd58736b37971f2b5e4be5ff000ac726d55ff80ad75da7c5a3e9fa0c7792dd5acfa849bb7473ab32dbaffd735ff58dfef7cb547587d3756d1f4fb86d495668da48e45915564f2ff876c71aff0017fb4d4014db54b8bff09dc437b234eb6f711fd96491b732b36edcaadfdddbf3560afdeabcbe76b3347676b1ac56f0ab32ab37cb1aff00149237fecd5b7ac6b9a5d8d9d8e9fa62adf2daaf98d73347fbb699bef49b5bef7fb3bbe55feed006046df2d4d6f6b35e49e5dbc324f27f7635666adeb8bfd37c43269771a96a524522c2b6f74b1dafef3e566f9b77ddfbb56af3c55676b750c3a6acb158c322b2aafeed55777dedbbb748dfed337fc06803955ad0b1d0f50d4a3692cec6e6e635fe28e3665adc6bff000db788aeafae3cfb98e4dd2471c76be5c0adfc2ad1eedcdff8ed36dfc69f67d621995ae56df76d9a666569997fd95fbaaabfdd5a00a7ac5c359c31f87ec99a5db27fa5347f37da2e3fbbfed2afdd5ff813560ad9dd5d5f7d8e2b7965badccbe42aee6dd5b9a7eb3a3e87a979d02df5e6d8d956e59961915997ef2afcdff7d3547a75c49ac5e6cb78ff00b3f47b7ff48baf29999bcb5fe2924fbccd40187359dc5ade35acb0c915d2b796d032fcdbbfbb57aebc39a8585ab5c4f6fe52c6db645f317cc8ff00de5fbcb5b16fe34b3b59b52ba5d3e56d42ea4665bef3b6c8aadf797fd9ff0080fcdfed551b1f152dbdbea16f716edf65ba8d63f2ed24f276fcdbbfbadbb77f16ef9a803069acd525e5d2cb26e4863b68ff008638ff00f8afe2acf9ae19be55a00269777cab5151cd22d003b77f137dda768ba25c78a2f258edfef22ee1bbeed51ba93cc93c94ff008156ef83f578fc3bac4334bbbec927eee7dbfdd6fe2ff80d4844e9be1aebd24765a9686d234175e5c9359b37f0c8abf32ffecdff007d564f85edf5bd5e68ed74b924fb469ead751c7e66d68dbeeb6dff00699ab43e236872e8faac3ac5afcb1dc37ccd1ff0cdfdeff812d6a7c1ff002eebc5d2dd37fc7c5d5ac91b7cdf7665db27fe3cabff00a1541ac7e2e533347f1d6b96b6ad6f0ea12aac9279db99bf78adbb77cbbbf87e5fbbfef57a769ff1a7549fc27ab787e7d2f4fb98f54856192e595b747fed2afdd6fef7cdf75be6aec24f06dbeb7b5af745b7b95f2fcb59e4dabb55997fe04b5ee9f0cff65ff04f87ede39b59f0ec7abdd47feb1afae2668da46ff966aaacaaaaabf2eef99b77cd594e71fb474c69ce3f683f637f0fae93f0bf56d59ece482e356d41956e7cc6fdf5bc6abe5b6dfbbf2b79cbbb6eeaf35fdaeaf345d53e2758c3a75f49fda16b6b1d8ea504ed27936f26e5dacbbbe55fddb2eef2fe5f9777f157d55e19d074df02f83749d074ef365d17498f6b79ff0034de4ab348db997ef7de6ffbe6be3f91adfc5bfb506df10e8f67ace9375ab2c735a696ad35b359ed558e65f2dbe65f2fcb919b77f7b7573425cd2948251f7794a7e26f827f13be13f88b5a6b2b7d49adf4165d4975bd1a465b69a3dbb7ed51ff007995772b2eddcabbb77cb5bde0bfda5bc51e05f1c5adc78d2d6e7fb1756d3ed7ceb4687c96f2fcbf2e1be8564f95a4f97e6fe193fd9f96beb0f157c4af09f80750d0ec7c43ac59d8b6a4d3431f9fb9a385635f99a4fe2f27e555ddfeed1e05f14784fe3668ab79653699a9dc6e92c64827b78e49961dcdba3f2dbe668d955597e5ff006bfbd53cfcd1f7a2572f2fc323e21f88d7567f18b4fb8f175859adb789b4fb55ff008492c635f96f215db1aea50aff00df2b347f797e56f9977357b47ecfbe3eb3f8c5e03d43c0fe2b8d6fafaced56193ccfbd7d63f7564ffae91b6df9bfeb9b7f7abdb23f807e0df07ebd0eb5a27856db4ad42d61b8b5db6de63595c4770ad1c9e646ccdb9555997f87ef57c87f13be1feadfb34fc46d1fc41e199245d1e691ae3499e7fde797fc3258dc7f7b6aee5ff6a36ddf795aab9a33d03e1d4f39f1d782350f873e2cd43c3fa92b79d6adba19ff0086e216ff005732ff00bcbff8f6e5ac4e6bed3f12683e1dfda8be19c37da5c9159ea90ab358cf3ffacd3eebfe5a5acdff004cdbfbdfeec8bfc55f19df585d693a85d69f7f6f259df59ccd6f716d27de8e456dacad5bd39f31328f291af6afa2bf64df8b9fd83ab7fc20fabcd1ff0064ea9237f66b4ff76dee9bef42dff4ce6ffd0bfde6af9d57b549f4665ff697f86aa51e68f2844f68f8b9e0dd6bf65af8b5a6f8bbc1acd67a3de492358eedcd1c2dff002dac66fef47b7eeffb3fed475f417c09d2f41d4b5cd4be25785638adbc3fe2a8e3b8bad1bef3697a946ccb711aff00757f79bbfe05bbeeb7cb8ff09fc65a2fed3df0bf50f06f8c1bcdd72de155bcdbf2c932affabbe87fe9a2b7deff006bfd992bc5fe13f8c352fd96be346a9e15f135c6dd0e6b85b7d424dbfbb5ff009f7d4157fbbb5be6ff00659bfbb5cd28f37bbf68bf84f4afdbfbc1ff006ff0df84fc608abe769f71268f70db7e66866fde47b9bfd9656ffbf95f0ede44db5b6fcbb7e6afd36fda13436d67f67df1f69eacdfe8fa7fdaa1ff00969bbecf22dc6df97fd9565fff006abe1df87bf06756f16ccb7175632db68f796333437322fcb26efdcfcbfed472490ee5fbdb595ab5a553969fbc6538f348f9cedffd5aff00bb52d56b5ff571ff00bb56f9aee38c7ab37d9556a36a5e698d4010c95d2fc33d462d33c452dcdc4de4dac30c923b7f0fdddbff00b3573170d5d07876ce397c37752154dcd78bf34bf776aaeef9aa4b89e91e3a92ebc6fe20f09f84f4b5db70d0ab796dff002ce6b86ddfbcff006a3b7f2f77f77e6aedbe336b96be19d274df01e88ccb636f6f1fda3fbde4ff00cb356ff6a46fde37fc07fbd5cdfc0f821d36dfc41e3dd6999bcb8e658db6fccdbbe69997fdef9635ff0079ab89d4354bad7b54bcd52fdb75e5e4cd349feceefe15ff0065576aff00c06b0e5e697a1d3cdcb1f524b55af6afd997e1a378ebc78baa5d43bb47d0596e1b72fcb35d7fcb18ff00f6a37fbabfdeaf1dd36cee2fee2ded6d6369eeae2458618d7f8a466daabff7d57d4df12b54b7fd9e3e0bd9f84f48b856f106a8b242d731fdedcdff001f575ffb4d7fe03fdda8ab2fb311538fda91e53f18bc55a87c6ef8c10e8fa36eb9b786ebfb2f4d8d5be592466fde4cdfef32fdefeeaad51b1f0478e3596b893c3da1eb9f63d3636b78dadbcc87f771c9f32ab7cbb99a4dccdb7f8aad7ecf7e20d1fe1df8d21d5b5c56b5866d3e65b5b9f2fccf2776edadb57fbdb76d7b4788bf6bcd36286fadf4bd2efb52996165b7b9be917c9693f87747f7bcbdbf37fb4d51ef47dd8c4bf765ef391c5f86ff00643f115d43aa2eb1a859e9174ab1adab5b48b70be637fac6936ff757e5dbfc4cdfddfbd47e3a7c19b7f869e26d363d264965d3752b88e38e39fe6fb3b2eddd1b7f149bbef6eff797fbb562fbf6b9f157d8f508ecec74ab6692e164b79258da6fb3dbedf9a1dbff002d377def31be6fbdff0001ec3f6babc66f0efc3fd5ac2e248ad649a69adeee35f9977470b4722ffe3ccbfeed4fef39bde1cbd9f2e8745fb6868d6b71e03d1f567595aeacf505b5b7923fbbb648dbccf33fbbbbcb5db5dd7c2dd5ad743f877e0bb5d7b5e8e7d4afb495bc8e3d4997ce91b6f9926d66fbcabb976ffbbfc4d54fe30782eebe317c31d2ec743d62d5616bab5be5bbbbddb6e23585b6b7cbf759bcc56f9abc3f4ffd97fc7de206b38757d534f8acedec596dda4bcfb5792abb9a38557f8559bfe02bbbfe0359c79651e59487ef465cc7bf6adfb43fc3fd2758fb1dd7893cfbcb76ddf69b485a485772ab7cb22fcbf32ed5ff00d0beed6f78fac21f107c37f127d9750b78ac6fb4bb865b99d9a6863fddeef9bfd9dbff007cff00c06be555fd977c55a5e83ab6a5acdc59d8ad9e9ad7d0c16d279cd24caaccd0b7f776aab7cdfeed7a97ec8baa6a5e20f00f8821bd996fb4f8ef21b7b7fb5ccd2796ad0aab47e5ff000c7b76ff00e3d438c631e6894a52f86472bfb32cb75e28f85be34f0dc16b05cee9bcc8d6ee4f2e3dd716ecbb777ddfbcbbab85f84bf1c35ef84b6f7da5a4697da6ccb22b58dcb7cb1dc7ddf31597e6dbb97e6dbf7b6d75dfb2af89ad7c1179e32d3756d4b4db3b38e68d6d567ba58f75d2b491ee8ffbcbb576ff00df3547f688f1a785dadf4ff07f85ed6c65b5d2fcc69b50836c8b0ee6dcd6f0c9fc5f37cd237f7bfe055a7594495f0c6463f8cbc61ac7ed31f11b43d26de3934fd3d57cb8e0ddbbc95dbbae2e1bfdafeeff00b3b56bacfdab3c556fa4d8f87fe1ee90bf66d3ecede3bab8817fbabf2dbc6dff007cb49ff7cd745f01fc1b63f0abe1edf78ebc4abe44d796ff006a6dcbf34366bf346abfed48db7fefa8ebe67f1778a2f3c69e28d535ebff0096eb50b8699a3fe18d7eeac6bfecaaed5ff80d11f7a5eefc2825eec7fc447a0e8f7de28d734fd174b8fcfd4b50b85b5b75fe1dcdfc4dfecafde6ff0076be84fda5b57d37e16fc39f0efc27f0e4cdb5a3fb46a522fcad347bb76e93fda9a6dcdb7fbb1ad43fb29f836d7c3fa6eb5f143c41b6db4db1b79a1b191bfbaabfe9132ffe8b5ff79abc07c6de32bcf881e2ed5bc457ff002dc6a13798b1ff00cf18feec71ff00c055556abf893f427e1898725576a9a4aaf232aaee6adccf53a6f86be0593e2378d34fd1577259b379d7d22ffcb3b75fbdff00026fbabfef57d01f1db59bef1d78cbc33f0b7c2f0ab491b42ad6d1ff00abfb432fee636ff66187e66ff7bfd9aabf0bed6d7e08fc19bef186a36eb2eb1a92c7247049f2b36eff008f7b7ffda8dff02feed7a37ec3ff000fee2fff00b73e286b9bae752d4a69ad6c6793ef36e6ff004ab85ff79bf76bfecab57254a9cd2e6fe53a631e58f29f4b7c35f02e9ff0c7c13a5f8674df9adec63dad3eddad71337cd24cdfed337fecb5bf37dd6a58daa1b897e56ae303cd7c592c8bab5e4d142b73246cb1c36ccdb56699995618ff00e0527defeeaab37f0d79cf8c3c5d6be01f877aa7891ef16e6df4b87cbb7b99db6ff684d349ff001f0cbfdd9ae246936ff0c6ab5e85e305f37509196dfcdb5b79ae2de36ff9f8baf2fcbb8917fd98564fb3aff7a49ae3fbab5f9f1fb5f7c6eb9f186bf73e0ed3ae54f87f499f75c347d2f2f155959b77758f732aff00b5b9ab5a54fda4ac54e7ece3cc7e8bfc1bbcff0084d3e1bf87d6592fa2bebed3e3b88649e6dad1c2d27eee455fbbe62ac90eeddf7a39155b76d6afc92f8bb6f630fc58f1a45a6694da169f1eb5791c3a6eddbf65559997cbdbfc3b7fbbfc3f76bf5c7e1efd9f4d8616568f6e97368f6b246bff002ce39b4f861997fefa9a16ff0080d7e797fc1413c2b1f85ff6a1d7e6895635d6ad6d7566555dbfbc917cb91bfe04d1b37fc0ab5c2cbf79232c447dd30bf653fda2acff00677d7bc417da8e9f79aad9ea16b1ac7696922aafda1599559b77f0f972495df7ed49fb5968bf16bc0f0f827c2b6fa9ae9b67ab35d7f695ded8d6fad7cbdb1c6d1fdefbccdf7bfbaadf7abe5355dd57a38b72ad777b284a5ed0e38d59463ca5af366b8dd24b2492c8df79a46dcd5426fbd5a6cbe54359337de6adccc9b4dff8fe87fe055d943fead6b8ed37fe3fa3ff0081575f1fdd153235893d4f6bf7aaad58b5fbd506ba9f507fc13e759fecbfda734db7ddb5754d0f52b36ff699563b85ff00d12d5fa8d1d7e3efecabae7fc23ffb4b7c2fbcddb55b5c5b193fddb886487ff6a2d7ec043fed57958afe21bd32d2d25315a9fcd739423535a9691aa0a3e1766aab354cd55e4aeb3acf11fdabb41fed2f8776bad22ee9b41be59a4f97fe5de6fddc9ffb4ebe4db8f9772d7e8378934187c55e1fd5345b8e2df52b592cdbfd9f3176ab7fdf5b5abf3e8c52c5118675d93c7fb9954ffcf45f95bff1e5af4f072f76513cbc647de8c8e72f3fd6553916b42f22db235519aba6470069ad1dbdf4333aee8e3915997fbcbbabb8d534bbabed6af350b58dafad6f2669a39ed97ccdcacdf75b6fdd6ff66b858d6ba0d3d9addbf76cc8caabf32b6da98966d49e17d5a5859974f9e28ffe7a4ffb95ff00be9b6d63c9616761ff001f5791de49ff003c2c5b77fdf527ddff00be7751a84cd2c6dbd999bfda6dd59b40162e2fe4b88fc945582dfef7911fddff00817f7bfe0555e8a65005a87eed4d4c87eed3e800a648d4e66a859a802d693a5dc6b9a95bd8daaee9a66dabfecffb55b5e24bc874bb76d0ec1bf771b7fa449fc5232ff0b7fecdff00015fe1ac3d3756bcd1a6926b299a09248da16917ef6d6feeff0076aaad002d2b7cb49cd56b89ff008568023b897736d5a85568db522ad00376d36693ca8d9aa466aa771fbd65feead0016a9f2ee6fbcd5736fcb55e1f9a455abdb6803d0bc13790f8b3c3373e1fbef9a6b78f08dfc4d0ff000b7fbd1b6dff0080edac1f046a4de07f186cd477470ee6b6b975f9bcb56fbb22ff00bbf7bfdd66ac4d23549f43d52df50b6dbe75bb6edadf7645fe256ff6597e5aeefe2068d69ac6936de28d2f74b6f247fe90bff4cffbdfef2b7cad532358ff0031dc7c68fed0d2750d16383509e2b5d434f5926b48246fb3ccd1b2aac8abfc5bbe5ffbe569cbf10be207836deebc3f79aa6b1a54963aa43a84cb3348b3dbdd2c7b63dccdfc2cabbb6fdd6dbbab9bf86b6771f13b5cf0ee83a8c97d736f6f1b69fbad3e692d6166fddccaadf7963665dcbfdd55afd0cd5349d3f5cd3f50b3d5e1b1b9d25a38fed8d7d1ab473797f36e666fbbb77332eefbbb9ab9653e4f74e98c7da7bc7cd7a3fed87e30b05b86bcb1d3ee7525f2648e7fb3b42abb64dd27991ffb4adb7e5dbb776ea8ff006518e1d5be375f6a967e5e996f6f6f7579fd9f6df32f97348abe4aff00b31f98adff0001afa7adfc11e17b8bcd526b8b1d3dff00e124d36df49b8565fdddf2c7e66d8e3fe1dbb7fbbf37eed7fbb447f0ef45f0cead36a9a0f876d6cf56fecf5d3d5ac5563dd0ac9bbcb655fbd22fdefef37cabbab9b9e3cbee95691f3dfed8970dae7c40f09f866c34f925d4ad6d772cfb557ed0d7522f971c7fecfcbff7d335737a5fecc9e32bcf05f87fc45a4dbde41ac4d79259de69b7d0b59cd63fbcdb1ccb26edcd1edfbdf7597e6f9596b43f698d3756d7be3e5be8eb7d17fa55bdaae92d27ee7eceb26e658d9bfbde72b6dddfde5afaf1bc556b670c7a87886ea2d2ad6de3856ea7b99b6c70c9b5776e6ff7be5ad39b9631e527979a47c43e26f0afc62f877e1f6d5b57ff0084834ed366d623f319750f3375f6efddcccaaccdf337dd93eeb36dff0066ad6b1f1a35ed735ad5b41f8a56b2db68774bfd8f7907d8daddb49ba56f3a3ba8d7fe7b46cdb997f8a3665feed7d650fc78f01c57d6f1cbe26b1b169964568246f96368dbe6593f85595beefcdf37de5dd547fe12df863f13aeac6c5ef347d62f35cb78ee1ac7505593cc6b7dde5ac8bf75665dcdb7f8b6eefbcb53cdfcd10b1f1dfc3bf186adf00be285c47ab4722c76f37d875ab181b72cd0ff00cf48ff00bdb772c91b7f12b7fb55ea1fb5b7c37692e2cfe2168db6f34dbc8618f509e0f997eeaf9371feeb2b2aeeff0077fbd5d67ed2df032dfc51a2e9faf785e1b66d634bd357ccb4b193ccfb769f1fcaad1ff79a1dcabfed2fcbfc2b5cff00eca7f142df5ed3e6f86be21f2aface6b793fb2d67f996685b734d66dfdef977347ff00025feed5735fdf8956fb323e63a72d7a17c72f83775f077c50b0c5e65cf87750666d36f9be66ff006a193fe9a2ff00e3cbf37f7abced7b56f19737bc646f7837c5da9780fc51a6f88349936df58c9e62ab7dd917f8a36ff6597e56afa6bf69af06d8fc69f853a4fc4ef0cc2d3dc69f67e64d1eddd24d63ff002d236ffa690c9bbfe03e657c96b5f477ec77f157fb07c4171e09d46456d3f56669b4ff0037eec775b7e68ffdd917ff001e5ff6aa6ac7ed44bfee9adfb3efc48d43e287c15f1078056e127f1368b67b6ce3b95f31752d3d95a358dbe656dd1eef2f77fd71feed745fb2df89aeb54f853aa7856ea68e59341b85b391a487e66ddb563593f8b72f96aaadf7beeff76bc37c7da1df7ecb5fb405aeada44327f63f98d7da7c7fc3716327cb35affc07e65ffbf6d5f42787f4bb7d27e2f6b1ad68d1ade7837c79a3c7a979f1ed58d66859595bfde65919bfd965ae69c63ca69096a7e61dcaaadd5c63eef9d27fe84d42f6abfe24812d7c4dac431bbc90c37b711ab48db9995646fbd5496bd289e6c87f348d4b4adf76ac0cf9be691aba2d27cebaf0cd9e9364be6df5f6a0cab1affbaaabff008f37fe3b5cdc8df357a5fc15b3b78a7baf105eb6db5d2ede465ffae8dbb737fc057ff425a991515cd23aff00891a843e1cf0de8be07b06dd1dbc71cd7527f7b6ee655ff8149ba4ff00be6b89856abdd6a571ae6a575a85d7faeba93cc65feeff00757fe02bb56b6bc2be1fbcf16f8834fd174e556bcbe99618d9beeaff00799bfd955dcdff0001a8f8625b97b491ee1fb2bf807fb5b5e9bc5d7aaaba6e93b96d5a4f9564badbf337fbb1ab7fdf4cbfddae76fa2bcfda5be3c496f67248ba5b3796b3afddb5d361fbd27fbcdf7bfde916bbaf8e9e2ab1f863f0fecfe1ee82db66b8b55864656f9a3b5fe291bfe9a48dbbff001eaf3ff85fe28d53e12fc3df1178aaca1896eb5e91745b19e78d5a38d61fde4d332b7de5dcd1c6abf7776efeeedae68f34bdf3a5f2c7dc3e80f127ecc9a2f89bc41af5f7db24b386ead6decf4bb6b4855574df27cb5ddf7bf79fbb8d97fe04cdf7aad787ff0067ff0008f85756d4bfd160d5d6fae3ced3ec75965924b7863db26d5fef6d6dcccdfdddbfed57ce6df1a7e2578f21b8d0e0d72fb5392ea193ceb6d3e1559a48f7798dfead772eddbf7976fcbf2d1e3cb0f8857fa6c7e24f182df2c30c8ba7c33df3796ccccbfc2abfde55f99bf8be6ff6aa3925b3915cf1de313d53f6a8d1b43f0ff817c0ff00d97676766b6f7d70cb636dfea645655924fbbfed2aff00df55a9fb5178997c43f09fc2b70b0b59ff006b5e4379f6693e6658fececcaaadfecf99587f149a3b8fd977c1735c5bc72dc37d855646fbd0feee4f9bfe04bf2d7ac7c23f0ce8bf107e0af8261d7960f11c30ac726dbbff009ecacdfbbff6b6aaf97b7f8956a7e18c587c52944f25f0dfed73a9683e1dd2f47ff8466c6e6dececed6d7cc9266dccd1fcb2337f795957e5feeb7f7ab4352fdb2b56b89af96cbc37a7d9dbb2b2dab49234932b6eff005927dd566dbfc3f77757a0eaff00b3bf80db4392ced34df2a1b1b89a5f3daed924f3197732cd27def2d576b6d6fbaaabb6a5d0fe107c3555d26cd349d33579a3b7fed08dbed4ccd78adfbb6919777cd1eeff0080ad1787f28ed32af807e39dc7c64d53c45a4d968ed676b0d8c3e5cf3b7cbba68da368e4feeaee66dbfecad717fb20cb71ff00082f8cb4fb3f29758b5997cbdcdff2d1add963ff0080f991d57fd9aef3c33e15f8bde36d0ed758f3e1b8921b7d2fcf568fed8b0c92348bfef2ff00e3caad5c7fc23f8aba6fc19f1578fbedf6375a85e5e5d7d961fb348bb5563b8919b76eff0080ed6a397e28c45cdf0c8a3ad7ece3e2af0ae83fdadacdc695069f6f6735c5e4f1dd2c9f67655f963ff69a46f9576eef99be6ac1f83fe056f891f11347d0d97fd0777da2fb6ff0dbc7f349ff007d7cabff0002aeebf68af8e16be3ad3749d0f4491a2d25638efb50dcdf7a6fbd1c3ff6cfef37fb4dfecd771f0eed63fd9cfe06df78c351857fe12ad7163fb1db49f79777fc7bc2dffa39bfef9aa6e5cbef7c44da3cc733fb597c4b6d73c4dff087d849b74dd2595af163fbb25d6df963ff007635ff00c79bfd9af17f08f856fbc75e28d2fc3fa6ff00c7e6a13797e67f0c2bf7a491bfd955dcd59f717125d4d35c5c4cd3dc4ccd249249f7a4666dcccdff0002afa3be07e97a7fc1bf863aa7c4ed7a1f36f2f2df6d8db37cacd0b37eee35ff006a691777fd735ab97b91e5887f12455fda93c656fe17d0f47f85fe1f6f234fb7b585af955be65857fd4c2dfef7fac6ff0080d7cd7b76d696b5acdf788f58bed5b529bed3a85f4cd717127f799bff0065fe15ff00656a8b5694e3ece3ca4ca5cd22bc8d5e8df02fe18c7e3cf1049a96a51eed074d917747ff003f537de58ffddfe26ff80aff001579dfd9e6ba9a3b7b78da5ba9a458618ffbcccdb556bea0f125d5bfc07f84f0d9d848bfda5e5fd8ed5bfe7a5d32ee926ff80fccdff7cd4d497d98954a3cdef4bec9c5fc54d5af3e2ffc4ed37c17a34cbf63d3e491649d7fd5ac9b7f7d37fbb1afcabfed6efef57dede03d0ecfc2be0dd0f47d3a1f22c6c6ce18618ffd955fe2ff006bf8bfe055f19fecd3e05fec6f09cde24b88ff00d3b58dd1dbb49f796d57f8bfeda49f37fc056bedcd3576dadbaff76355ff00c76b867fcb137fb3cd2fb46b2b563eb9aa5e5869fbb4dd8dad5e5c47a7e96b27dd6bc9be5566ff00663559266ff6636ad293ccdbb625f3666f9635fef33572ba0ead6f75ae7f6f798d73636f67750f87dbf86e36aafdab50ff00b69feae3ff00a671b7fcf46ac2520e53c67f6acf88567f0a3e18cb7ba1493b4d0aff00c233a4ddb7ef15a45924692e19bf85be59a46fef49b6bf2eef9fcc5655fe2f97e6afd49fdbe1c5e7ecc1ae3490ac4d6be2181563c6cdb34779711eeff8146cadbbfdaafcb066658d9bfbbf357a587fe19c95be23f60be1cea4d79e36f1b58ee5f26fae245863ff00a691d9fcbffa42dff7eebe47ff00829a46b71f1bbc27a82fdebcf0bc3237fe055c7ff155f567d8d7c25af4de2059196de3f1569fb5997e565b89ae235ff80edd497fef9af993fe0a5d146be32f86cca7fd217c3f243227fb2b71f2ff00e3ccdff7cd7350fe31d15be13e38857e6ad8862dbb6a9d8dbee6ddfddad25af60f3486ebee563c95ad7cdb61ac96a902c692bbaf97fddaeba1fbb5cbe86bfe94cdfdd5aea23a0d624d52dbff00aca8aa487ef5416751e13d73fe117f1678775aff00a05ead637dff00018ee2366ffc77757ee25c6d5ba9b6fddf31b6d7e0fea1b9b49bedbf7becf26dff007b6d7ee2783f565f10783fc3fab236e5bed2ecee95bfbde6431b7fecd5e76323f0c8e9a66e2f6a979a897b54bcd7144a0e69b4531bbd4947c2b255592a691aabb35759d6579be5fbbf7abe28f8ebe1cff8467e2cebf0aa6cb7be91754b7ff766fbdff91164afb5e6fbb5f3e7ed5be1a12e91a1789117e6b199b4fb96ff00a6337cd1b7fc0645ff00c7aba70f2e5a87362a9f3533e5ed4adff896b1e65aea2e23dcacad5cedd45b6465af56478b121b55dd32ad6dc3feb1ab334d8bfd2377f76b421ff5cd48b1b79f76a9d5ebdfbb546a006514fa17b500585ed4edd51ab50cd40033547ba9adde8a007d3b9a837535a5a0074d2edaa7f79a9ccdba92801d4f55f96a35fbd44d2ed5a008d9b73353597e5ff7a9d6eb4494005aafef246fe15dab5796ba2f86fa6da6bb6fade9733edba9e3531b7f776fdd6ff80b6dae7e4b79ad6692de78fcab8859a3917fbacb4443948dabb4f867e225b1befec7bb917fb3ef9b6af99f76399be5f9bfd96fbadff01ae339a9618bcdf95beed1208cb94f6cd1747d53e007c46f0febd1c5e75aac8d7567f37fc7c5bee68e685bfda556dbff000256afadbe3b788f4fd5bf671d635cd0e496f2cf565b58e3b98fe5fddb5c2b6e6ff812b2b2b7f17cb5e3bf0ee25fda17e05dc7876e9a36f1878776b59ccdf7a46dbfb966ff006645568dbfdadad5c7fc2dd6575cd36ebe1beb97d75a469baa5d79d6adff003eba947b9638e45ff9e7249f2b7f75955bfbd5e7cbdef7a5d0ee8fbbeec7e191a5e07f02fc50d4bc13bb41b7d4a3f0dc927f6a5ac7e72ac734d0b2b2b43fdd9377ccbf7776dfe26f969b75a4fc5ab8bad52f2eb4df12cb37882d7fb42fa46b79374d1c722ed91bfe79b46cabb7eeb2afcabf2b57d1dfb2faea167f066cecef66956ea1d42e1638e45dbf678772b2afcdfc3f3337fc0ab526f8f1e1dd064d4975cd61a0bab1be8e3917485fb643f6791bf7775b97fe59afdd93f895b6ff0079772e77cc3e5f74f916f2f3c69f11bc45a0dcbaea1ac6b7359ab6973eddb24d0dbb7fac593e5ddb595b749fdefbd5f5f7ed0cbfda9fb3feb979f368b70d6b6b7cd04932fcd234cad35bb37f137fbb5df58ea9a0eb935c4765a959eb171a7ed9b6da6d93eceb32ab2c8bfdd5656fbcbfdeaf23fda7ae1b59f843ac47611c93c7a7eb56f25f2cff00f2c76fcbb97fbdf3491ffc05b754f3734a23e5f74f1df84bfb3ec7f173e1adc6a5a4eb5069fe22b3d61adeea0be56f256d5a1568feeff17de6ff00be96bb8d5bf61b9adfc33a95d5878c16fb5886156b5b16b158619a6f97f76d2349f2eefe16ff00bebf8abacfd93d74fb5f852b2585aafdb9b5493fb5a7566565dbbbc9ff00be6365ff0080d3bc75fb555bf817e23789341baf0cc8f1e976ed0dbc9feae6b8bcfbdf37f761656f95bef7fdf555cd294b9622e589e530f83fe397c0fd53c1eba74373a9c30f9d79636369fe996d6f2797bae2d64feeee55f9955b6b36d65f9956b8df8b8ba4ea9aa59fc4af03472e95a3ead74ad35a46db64d0f565fde490ff00b3bbfd746df759777f7596be9ed07f6c0f06dfdc68f6f710ea7a64da843bae1a38da65b3baddb561daabb9b77de5917eeaedf9776edbbda85e7c31f889f0cf5cdbab6950785f54b8921bc9e355b765ba69957cedadb5964f3196456dbf37fbad53cd28cbde88f94e47c23af693fb547c1bbcd275968adb5a876c37db57e6b5ba55fdcde46bfdd6feeffd745af8c75cd0f50f0beb5a868faa43e46a5a7ccd6f711ff7597fbbfecb7de5ff0065abb2d2f54f137eccff00172ead6ea1dda869b27d9efad3eec7a85ab7ccacbfecc8bb648dbf85bfe055ed1fb467806c7e2878374ff89de105fb648b66b25e471afef2eacffe7a6dff009e90fccadfeceefeed5c7f772feec89f88f96d6a4b7b89acee21b8b599a0ba86459a1917ef4722b6e56ffbeaabacbb9772b7cb4e56ae820fb3bc6da5d9fed55f01e1d4b498e36f1359afda2de0fbad0df46bfbeb7ff7645fbbfef46d5c6fec77f1123d5fc2b7de11bc9375e68ecd75671c8bf37d9666f997e6ff009e726e56ff00ae8b5e6bfb3dfc5a6f855e388d6f2665f0eea8d1dbea0bff003c5bfe59dc2ffb51b37cdfecb35745f1e34d5f805fb43687e3cb38fcad075a9a492f2383eeab37eeef63ff00812b2ccb5c928fd835bf2fbc7c89e3db7367f10bc536ff00f3c756ba8fff002335632d763f1de18ed7e34f8cd22759636d4a499645fba564f9b77fe3d5c6475e853f84e19fc52265a8ee1b6ad3ea0b86ab24aad5e8d05d2e97f0c345d362ff005da94925d5c7fd735936affdf4cabff7eebce5be55ae92dda4fb2dbabb6ef2e158d7fd95ff002cd525465ca69435f477ecc3e1cb5d0749d73e206aeab159dadbc91dbc8dfc31aaee9a4ffd0635ff008157cf7e19d1ee3c51af69fa3dafcb717932c7bbfe79aff137fc0577357bc7ed01e2db7f0cf86745f873a1ee8ade386392f963fbde5aff00a987fdadcdfbc6ff00756b9eafbdee1bd2f77df307e19e8375f1c3e2f5c6a5ab2f9b6ed27f695f45bbfe59ab2ac76ebff90d7fdd56afab354d5bc0fe19d1ed6d6feebc3d63a7ac6d0dadb3796d1b2ab2c6db55b77caadf2b7fb5ff0002af98e3f84bf133e1a6a566da4432ff00685c58c97571fd9f22b792b1fccd0ccadf2b37f757e6ddf36dfbb597a1fc02f1a78821f0fea1fd9ad158eb8cd335cc922ab5ac7bb779d32b7dddcadb97fbdff02ac1c632fb47446525f67de3de354f8e1f0e7c24dab49a22d9cba969b6fe4c7069b62b0add6e915596199576b6d5dcdfddf96aafed21a958ebdf08749d52cedfedd6375716f35bced232f92b22fcb26dfe2ddf32ff00c0abc7fc49f01ef3c1bf0c750f136a374cd711dd431c36d1aed5fb3b6e5919b77cccccde5eddbfed57ab7c48fb2de7ecc3a6dd5d4905cdf2e9fa7b4722aed8e393e58fe555f9772ab37fe3d4f9631946511f34b965191b1e03fed4f147ecdb1dbdb59daea77d269771671c6ccbf36ddd1c6adbbe5f33eeff00c0b6d783e8b79e3cf26cfc3f64baaac7e19b8935686d3c965fb1cd1af98d237cbf7bf8955bfbcdb7ef57a87ecd3f123c2be0af05ea163adeb5169f7936a8d71e5c8adfeafcb555dbfdefbadfe5abd0a6fda7bc0f671c6cd75737cd750adc32c10ed6ddb9976c9fdd91557fef9dbf352f7a3297ba4fbb28c7de3c6fc2ff000d3e2978df4dd5b58b7b8bbb3b5f103349a87daeea4b7fb72eedde6491edf99777ddff0077e5f968f827a0de7857e3c49a0ea3631cba95bdbdc5bcd24737fc79b796acd22b7f17f77fe055f457c37f8ede1bf896d1d8db4d3c5ad4d6ff00689ac6e57fdadbe5eefe26fbbf77f8596bc3fc5974d2fed8d0ae8d25d2b35d5ac370b07cacbfe8abe72fcdf797e5fbdff7ceea39a52e68c87eec79646a786ecec74dfdacbc4d1dac36ba7d9c3a7cd34cbe5eddade4c2d232eefbacd2336e65f976b36daeabe317c37f0aff00c22ba96bd7f1dcab69eb7d7df2cdf379970abb557fbabe62ee55fef335794fc78b7d6adfe27789bc45a35aea1159c7e5e97797d1c7b95649adfe68ff00e050edff003b6bccf58f107899e1d4345bdbad4259350b8b792eacae59bcc9a68d76c3bb77cdfc5f2aff00bbfecd118f372c839b97dde53bafd9f7e1ff00fc2cef1f36a1aa5bc72e87a4b2dc5d44abb639a6ff009630edfeefcbb9bfd95ff6aa6fda43e25b78fbc79259dacde6e8fa2b35bc2cbf7669bfe5b49ff7d2ed5ff657fdaaf50d69a3fd9d7e02ad8dbc912f882f17cb5923fbd35e48bfbc93fdaf2d7ff415fef57ca31edb787ef7caabf79aae1ef4b98897bb1e53b2f85be039be2478e34fd1555bec3bbed17d22ff00cb3b75fbdff7d7caabfef5779fb547c418f5ef1559f84f4e655d27c3ff00eb963fbad74cbb76ff00db38f6affbccd5d9782628ff0067bf81fa978a2f6355f136acb1b430c9f7bcc65ff4787fe03f348d5f2ef9b24ad24d3c8d3cd23349248df7a466f9999bfe05447f792e6097bb1e51dba979a6d59b3b0b8d4aeadecece16b9bcba9161b7817ef492336d55ff00beab633d4f4efd9dfc1726b9e2a6f104f0ff00a0e92db6166ff96974cbf2ff00df2bf37fdf34df195d49f1c3e3158f87ec266fec7b566b559d7f8635f9ae26ff00816ddabfeead7a87c62fb3fc07f843a3f8574b915752b88dad7ed2bf7a499be6bab8ff00d957fde5feed57fd987c02be1ff0cc9e20b88f6df6acabe4ab2ffabb55fbbff7d7deff00be6b92ff006ceb8c7e181ec10dac36b1dadadbc2b05ac2ab0c31afdd58d555556bde2cfeeaad789dbaeeb887fda655ff00c7abdbacfe6655fef37f157348d6a9475eff004fdda3a492c125e59dc35c4f0fdeb5b555db348bfed36ef2e3ff006a4ddfc35e1ff18fe2749a2fc62f83fe03d056dedb50bfd496f2f2d9577470e971c7243f65ff00ae7247e62ffbb1eeaf70b1956f34d9350ddb7fb6bcb917fe99d8c6cdf675ff00b68cd24cdfef2d7e71787fe267fc2cafdbb3fe129b691a4b08eeaf16c3fd9b5b7b39963dbff015ddff0002a29c7da7348e794b9794fb3ff6bff09c7f10ff00667f1059c0d24b259dbaead6376cdba4baf2635997cc65fbcde5f9d1ff00b5b55abf21fef2b2ff000b2d7ede5bac3ff088d8d8deaacf63f67fb3c8bb7e5dab7925bb7fe41997fef9afc5cf1a78724f06f8c75cf0fcade64da4ea17161237f79a191a3ffd96bab0b2fb263888fda3e8dd63f6e6d4755f87da6f8761f0fc363771dce9f36a1a84970d74d71f67685b742bf2f93cdac2db7e6fe2ae17f699f8f03f686f89569e21834f7d2acad74ab6d3eded64ff00967b77349fc4df7a491bfe03b6bc5d56b42c63fbad5d71a518cb9a273caaca5eec8d6b7f956ad6eaab1d4dbab7332aea0df2aad67b55abe6dccb555a8034b435f9a46ff80d7490fddae7f435ff0047ddfde66ade8feed49ac4b14e8dbe6a8a9ebf7aa0b35adff7bf29fbadf2d7ebc7ec8bae7fc241fb30fc2fba66dd22e870dac8dfed42cd0ffed3afc85b56fbb5fa7dff0004f5d67fb4bf667d3ecd9b73697ad6a563feeaf9de72ff00e8eae3c57c06d4fe23e9e5ed4fa815aa456af2e26e3e98dde8a6b5007c2325576ef523546ddebaceb2193ee8ae67c6de1787c69e13d63419f6ac7a85bb42adfdd93ef46dff00016556ae924aab355947e7caacc8ad1dc46d15d46cd0cd1b7f0c8adb597fefaacbd4ad7e6dcab5ed1fb45783ff00e11df1f7f6ac11edb0d795ae3e5fbab731fcb32ffc0976c9f8b5794c95edd397b48f31f3d521ece5ca66d8dbf951fcdf79a86f9665ab9b2a9dcf7a7a99935d2ee86b35bbd682cbbadea8b7deac8b1b4514ca009775368a6b5003aa3dd46ea8d9a80091a99cd319a85a005a46a9162dd522c4b4011c2b50dc7deab9f2aad559bf7adc50010aed8e9b27cb1b3354df756bb6f86fe073e20d416fafa265b0b7459a38645ff8f8f9b6a9ff007772d0118f309ff08c5ef8174bf0e789214679d9b37917fbff00757fe04bf2ff00bd5a5f1334386eadedbc4fa7fef2cae96359997fdaff005727fecadfed2d7abea5a4dbeb9a6dc58dd2ff00a3dc47e5b6dfbcbfed2d79e7827758de6a9e05d6fe68e4f31616ff00797732affbcbfbc5ff006ab23a651fb2795d69e936fe6cdfecd43ac68d71e1fd5aeb4dbaff005d6edb777fcf45fe165ff7ab5b478b6c2adfdead798e6e53d0be15f8faebe17f8c2c75ab75696dd7f737d6cbff002f16edf797fdef95597fda55af6cfda2be16daea5a6b7c46f0cb2dcd9dd46b71a92c0bf2c91b7ddbc8ff00f1df317fe05fdeaf9a57b57d29fb27fc4e559a4f87fabed9eceebcc934df3fe65dccbba6b5ff0075be6655fef6efef571d58f2fbf13ae9fbdeec8f50f807f123fe1687c3fbcd16558ef3c5da7d9c91cd6d3b2c6b7d1b2b2acdbbfdadcab27fb5f37f1578cfecfbf01ec7e2869fab4da96b0da7c7a7eeb36b4b45ff00498e665568e6feeb47b9645dbfc5b7ef537c59e1cd43f669f8b9a4f8834487ed3a2fda1ae34f591be5923ff96d67237fbadb7fdd656fe1af50fd9ef49d2fc2fe2ef1a5c585afdbb49beb1b5d4349d497f8ac649a45f276ff00cf48e4f95bfbad1b7fb3587c3ef44d7e2f76479fcdfb3c7c44f094da5df785eebfb566ba69a192e744b86b56b5dacdfeb19997f76caaadbbeeeef97fdec9f165c7c50b5fed2f08f882cf579e6beba8ef2ea3687ed0d70d26ef2ff791eef31599772ed6fbd1d7d31e30f8d9e13f876cb63aa35cdcea127ccb6d68bf32c7fde66fbab5d0687f173c137f63a95c59789ad60b3d3e4861b8f324dab0f98db636f9b6ff0017f12ee55ff668e797f28729cefecbfaf437ff0003f4f9a4b182ce1d366bab599ad21f9a6f27ef4d22fde6936b7cdfc4db7fe035f39e8be67c76fda1ad5aeb505bc8756d51bcb9f50857e6b58f73471f97ff005c635555ff006abedcd3752b1d26eaceddf50b1821babcfb0c2aacbb66ba6dcde4ee5f9599be66fef357c9bfb32f85ed7fe173788349d5347b3d7adf4d5b8db76df2ad9dc4371fb9995bfda65dbffecd1197c52092f8627ae6b1fb227807529a39adff00b5b48b7691a4f220baddfbb6dbb63fde6edbb7fbdfed37fb35e4ff0012bf643d4bc3fa4de6ade19bc97c43b6e9563d27ecfbaefecedf2fde5ff58cadf7be55f97e6fef2d7b27c66f8e6df0be6924b7999b56b8d3e1934dd2eee1dd0c8cd70cb7124922ff0012c6bb5555bf8ab83d0ff6d2859564d6fc2edf686be556fecfba658e3b3fef7cdf3348bff01dd446553e224e4754f813f103c65e01d5acf5ed2e7ff8493c16b0c7a3cad22c8da859c9b9a4b38e4ff968b1ff00ac8ff89599a3fe2f9737f653f8c9ff00085f8817c2babdd2c5a0ea937fa2cf3fcab6378df2fcdfdd8e4fbadfdd6dadfdeafa6b47fda3be19ebccdff13e82ce46bc6b387fb4bcc859be6f966ff6636fef36dff6b6d782fed81f05a1d0f5293c6da4471fd8ef3cb6d62c63656fb3c927cb1dd6d5ff0096727dd66fef7fbd4465cdee48af87de479cfed25f0c57e18fc4ab85b3b56b3d1756dd79671eddab0c9bb6cd0ffc05bf87fbacb5e5ab5f567c3fbcb5fda5be0bdf78475eba5ff84ab43dad6ba94ff348bf2edb7b86fef7fcf193fbcbb5bef57cbfae683a9785f5abcd1f57b3934fd52ce4f2ee2da4fe16ff00d995bef2b7f12d6f4e5f6646722ab6d963656f995be56afa2b56b8ff0085f1fb28dd5bbb7da7c45e19556dbf799a4b78fe56ff00b696eccbfef2d7ce7babd2bf679f1a3785fe207f67cadfe83ae43f63656fbbe72fcd0b7fe851ff00db4a271fb4547e2e591f2f788b519b54d724b8964f35da1863f33fbcab1aaaff00e3aab50435bff143c363c29f11f5fd25176c56774d1c2bff004cfef47ff8eb2d60435d31f84e397c5ef12d5499be66abcdf76b3e4fbd56491b2ee5dbfdef96ba466db5830aefb8857fe9a2d6d2ac9753470c0bba6999638d7fbccd401ed5fb3ee976ba5daebde34d524f234fd3edda356fe2dbf2f99b7fda6f9635ff0069aa0f861aee97aafc565f1978cae960b586f16f16db6799e75c6e558615ff00a671fcacccdf7563accf88975ff08e786743f06d836e558d6f2e157fe5b37fcb156ff79b737fdf35d95e7ecf1aedd5e496f6d716367a6d8d9c31dbcd3c8dfe953796ad22ed5fbade6348acdf77e5ae397f348eee596d1e87bb7893f691f08e8325bffa749a9dc48cadfe831fda1563666f9b77ddfe1ddb7ef7ccb5ccebdfb5468eba84d0d958dcea76f1dbb6dbb919a3f326f976fcadf36dfbdbb7573fe0ff00d976cdafadee359d6a5beb58fcb69ad2dad5a3f324fe28f76eddb7fef96aa7f1abe02e8be01f0ade788b4bbabef96fa38d6c5b6c90c31c8dfdefbdb57e55ff00be6b28c61cd63494ab72f31d87c68f1843e2dfd9ded75a4b5920875692cf6f99ff003dbcc6dcbbbfed9b5765e05f0fd8f8cbe01e9fa6a359cb6f75a3fd8d59636dab32c7b59b6ff0b2c9f7bfdadd5c0f84597fe18ff549278e39d96d6f996395b72aed936c6df37dd6566ddb7fbcb58fe0dfda1f41f02f8274fd174bf0add34d6f0fef9a4d436ac971f7a46ddb776d66f9bf87f87fbb53cb297bb11f37bdcd2ec65d9fecb5e32974d92479b4f82f16f16dd6d249be668776d6b8ddf757fbdb7ef6dff6be5aef2cff00637b56b8be5b8f184d2c3e62ad9c96d66aadb76fcde62b37deddfdd6fbb5c7f8d3f6aad7b56866b5d074fb6f0e5bc8b1aadceefb45cc6cadb9b6b37cbf37cbfc3fdefef55af877f1bbc49e2ff8a1a2aea97d1adacdfb9fb0db2f976d248b1b7cdb7f85999b737f0fddfe1ad25ed0ca3c9cdca6a787fc2fa1fc2afda6bc27a0e97f69d5fccd3fcb9a7be65668ee268e4659a355fbbb6355ff00be9abaef8dcbe1bd0ff686f01eb9a94d259ac962cd71770337cd247ba38777f7577332b32ffecb5cff00c5adadf1fbe10dc69774da46ad70b0f9d7d1aaee5ff4a65f9b77de6dbe62fcdfdeaeabf692f831ad78e2493c49a47daa76b18e1b5874258f76ef32e36c8d1fcdf2edddb9bfbdb7fd9acff9798afe68c4d8bafda2bc07a4e9faa2daea4d3df69b1b32c1f67655b8923f957cb93eeb7f755bfbbf76bc3fe03f872fbe24fc50bcf186b3fbf8ece66bc9a46fbb25e49fead57fd95fbdff00015af33d5bc3f756fe26fec1836de6a4b71f61f2e165656baf33cb65565fbcbbbf8abde3e2b5e5afc0ff0084b63e0bd226ff0089c6a4ad0dc5cc7f7997fe5e26ff00817fab5ff67fddab94797dd8fda2a32e6f7a5f64f29f8e5f119be2378f269209bcdd174d56b3b1feeb2eefde4dff00026ffc7556ac7c01f873ff000b1bc791fdaa3f3745d2f6de5e7f7646ddfbb87fe04dff008eab5799b6d8a3feeaaad7d39a6de37ecf7fb3bfda136c1e2ad724568f77de8e6917e5ff00bf30fcdfef3554fdd8f2c4ce3ef4b9a4703fb4c7c445f1978e1747b393cdd2f436923dcbf766ba6ff58dff0001dbe5affbad5e474d8d76aff13ffb4dfc5522ad6f18f2c794ca52e69730e54afa53f633f85adadf8aa6f1a5fc3ff12dd2775be9fe67dd92e997e66ff76356ff00be9bfd9af09f04f83750f1f78b34bf0ee96bfe99a84de5ac8df7615fbd248dfecaaee6afae3f680f1469ff00033e14e9be07f0d335b5c5f59b59dbb7f1436bff002dae1bfe9a48cccbfef337f76b0ab2ff00977135847ed1e27e2ebaff00868ef8fd711c1233785f4d5686365ff9f58dbe665ff6a693ff001dff0076be92d3e25b78563895628d576ac6abf2aaff0076bcafe07f819bc15e0f8ee2e21f2b52d6163bc917f8a3876fee63ff00be7e6ff8157ac58fccb5cb297d989dd4e3cb1e63434d8b75f5affd768fff0042af50925b3bcff897dec92adbea11ccb22c1f2b7d9e3dbf68f9bf8777991dbaff00b5337f76bcef498b7ea56aab24703799bbcc93eec6abf33337fb2aaacd5e99e1fd2d6feeadef9a358a68e186fa3b4666fdcdbc6b23595bc8dff3d2491a4ba93fdaf2d7f86b09c8247cf5fb6b7c7093e1a7c3b5d1f4e668bc49e28864b759155a1fb1daafcb348abfc3f7bc98ff00babf357c3ffb29bc4bf1ff00c2eb27ca9325f5aa2ffb5258dc46bff8f32d7d0dff00053af099b0f13780fc4314976d05f584da6b2cd3798be642d1c9b957eeaee59be6dbf7996be4ef855e255f04fc4af08f882538874bd62d6ea4ff00ae6b32eeff00c77757a3463fb93ccab2fde1fae5ac6a4d1784f41936fcb7925c59b7f77f796b7927fe8c863afcaefdac2cdac7f690f8851b007ced564b95dbfdd9956456ff00be5abf4cfe336ad6be05f85b7d793b79ff00f08cea9a7ea0cbbbe66b75badb27fc07c96917fe055f9a7fb596a1a6ea7fb4578ce6d26fe0d4b4f86682d63beb693cc8e6686de38d995bf8be65fbd58e17e237aff09e4f0aeead8b55fddd65c2b5b16bfeaebd43cf2c2ad399a8dd4d91be5a00a374dfbcaaacd524cdb99aa3fbdf2ff7be5a903a2d2576dac3feed6b2f6aa3669b56add06b1275a917b542ad522d4166a5ab57e867fc133756f37e1bf8ff004b2df359f88a3b855ff66e2ce3ff00d9a16afcefb56afb83fe0993a8edf107c52d359bfd65ae977cabfeeb5c47ff00c4d73623e09170f88fbe236f96a65aab0b5585af20ea26a6b525235007c1ad50b35492542d5da7710c8d50c9534955da80387f8b1e081f103c177da5a6d5bf8f6dd69f237fcb3b85fbbff016f997fe055f1b4a8c170f1b4722b32b46df2b46cbf2b2b7fb4ad5f7bcd5f397ed19f0f5b4f9a4f18e9b09fb2cacabaac31aff00ab93eeadc7fc0beeb7fc05abb30d5397dd91e7e2a97347da44f0e6aa375579aa9de2d7a723c7895e36a864fbc6a45a6c9599a90b5252b542cd5004b48cd50f9b4ddcde9401233542cd4e66a4a0045a9235a72ad48b400bcd2335254135d4717defbdfddab2093ef546ccabf76a1dcd2fccdfba8ffbb55e697cf6f2d3fd5d473163e69c4ec147cb1776afa5f4d896c2fac591516d64b78f4f9157fe58b6edd0ee5fe1ddf77fdeff007abe67daaa8c3f876d7d2bf0e74dbaf156861af996ca3bcd3fc9dbbbfbdb7cb91bfbbfbcdacbff00a1565237a475f0c5f76b81f8bde1c9becb6be24b0dd15e69ecab332ff0c7bbf7727fc05bff001d6af40d06ea4d4b4db59a78f6dc7cd1dc2ff76656db22ff00df4bbbfe055b50e9b1dc46d0cf1acb0c8bb648dbe65656fbcb51cc74f2f31e3de28f0da7c50f0759ebba4c3bb56855b75b46bf336dff005d0ffbcbf797ff00b2ae034fdbe4c7b7eeedf96bd73c1fff00163fe2b2d8de332f8675265686793fe58aeedab27fbd1b7cadfeced6ad0fda1be0effc20dab2f88b4bb7dba0ea526db88e25f96cee9bf87feb9c9f797fdadcbfdda51a9ef7299ca9f34798f278d6af58dc4da7dc43756b3496d750c8b3433c7f2b4722b6e565aa70d5a8eb4333ed2d3ee34ffda6fe0db432c915b6b0bb5666dbff001e77d1afcb27fd736fbdfeeb32ff000d799fecf7f12ee3e13f8c350f04f8b635b6d26eae1ad6e16e7e6fecfbaf97f78adff3ce4dabbbf87eeb5798fc29f891a87c2df1643ab5aab4f6727ee6fac55b6fdaa1feeffbcbf795bfbdfef357d31f19be14e97f19bc276fe30f0bc8b79ab7d8fceb59235f9752857fe58c8bff003d17e655feeb7cad5c728f2fbafe13a39b9bdefb471ffb664bff00158783f438ade55b88ec6493eefcb234d71b576aff00bd1ffe8359fac7ec83e20d374ff10359ea56dabead66d6f258db471f93f6a8d95bce8dbccfbb32b6ddabbb6b7cd587e1df105c7c55d0fc236f7bf69d5fc4de09bc8e48eda493f79a9692d346d246bbbe6f3add9777fb51b37fcf3afae3c4de26b3f05e93aa788b54be91b4fd35649bf7bf2b5c36efddaaff00b4cdb56a79a54fdd0e5e6f78f91efbf67df89da4f817c41717566d0687a4b7f68369eb7db96e9963f9a68635f959955bef7cbf7597f86bd33f679f84fe30f85ff122f17528d62d0ef3418e6ba920f9a3f31a4f961ffaed1b2c9bbfdeff006aba2b1fdaf3c26dfdb51cf0cf67676eb67359b40acd25d332ff00a447b76eddd1b332ff0075b6d7a47867e29781fc6166d79a7789ad7c9f99645bb99619155595599a393e65ddb97e66fef512954eb108c627cebfb656b31dff0089bc3b636f27eeec6ce46997cbdab1cd336e5f9bfbcd1c6adb7ff8aaeeacff00675f00f8fbe14f83eeb4efb7787aeae2de3ba6d4208fce9999b6b4d1ccadf2b2eeddb7fbbfeed790fed21e26b1f157c4885744d4af2fade18e38fec9a847e5c76775bb6b42aadfc3bb6ee56fbbf32eedb5f637f6e6a5a3787e4bad5ecda2d6acf476bebcd3f4dfdf47e72c7f3470ff007be65daab44bdd8c43ed1f3cf8abf62b5fb3df4de19f142cf334cad6763ab46b1af93b7e68e4997e5f3377dd6dbb76d7071fc17f8ade0ff13786669fc3b3ebd25e42da7ada7da3ce87ecfb64592cee1b76d8e368f76df9b6fccacadbabd3ae3f6d4d262b8d0e6b5d16ea7b39349f32fa35655921be6ff966bbbe5921ff006bfda5feeedaf40f877fb55782fc61a7dac77b70be1ed7248e1b7b8b4bb6f2e1f32493cb558e4fe25ddfecfcabf7a8bd488fdd91f26dd587893f667f895a4ea96f0dcfd9e687ed566b7d1f96d7d66cdb64b7997f8645fbadfdd65565f976d7ae7ed3de15d37e25fc3dd1fe28786bfd263b7b75fb449b7f79258b37fcb4ff006a19372b7f7559bfbb5f417c5af02f877e35f81f54f0ede5c5b5b6a56b79f6786f9b6ac9a7ea5b5563f336ff00799a38dbfbcb22ff00b3b7e53fd987e2249e0df136a5f0e7c516eaba6ea97125afd92e7eedbdf7fab9216ff666dbe5b7fb4abfdea719737bdf6a22fee9f3eb551bcdde5fc8cd148bf32c8bf795bf85abd0be317c349be1578d2e34b5f325d266dd71a6dcb7fcb4b7feeb7fd348feeb7fc05bf8abcf6e2bae32e631919df1c3575f1378c2c3c4180b36ada55adc5c22ff000dc46ad0c9ff008f42cdff0002ae0a1ad6f154b24b7d0ab48cd1c70ed8d7fbbf3337fe855936f5ac23cb139e72e691349f2ad67b55c99be56aa554492daffc7d47ff00026ffc76bd03e1bdadbc379a86bd7ebfe87a5c6ccbfed49b7ff42fe1ff0081579edbb6db856feeab57a078899b41f07e93e1f8577de5e37daae235fbccdbbe55ff00be9bff001da92a3fcc74bf0afc49a3cdf1222f1278c1b7426e1645dcacd1c326df9646555f9963daaaabfde65feed7b3dd7ed51a3c5a7b5c59e8b733eadf6cf2ff00d266db0b5aac9f795bef2b347f2edfe166fe25ae5edff67bd2ee2d747b7975296c6eade1861bc68155bed126e6691be6fe2fde2aaffbb5e89e1bf805e0fd1db5e69ac6eb5a5b89163b7b6917cc6b78f6aee8e36fe2666ddb9bfbb5c75250f88f429c2ac7489e5bab7ed31e34d5a19a3b2d422d2acfcef317ec30af98abfc31b49ff01af5af115d49e37fd9ae6bcd67509ffb4becadab5c49a6b798b23798d22c2cbff3cfe655dbfc3b7fd9ab1f1bbc376edf0e7c557567a4d9c57571e4dc5e4ecd1c2db63dbe5c91ed5f9a455f976fcbf7bf8ab7be1dea8be20f82ba7dc6ad6b1e99a7c9a2dc4770b02fcab6f1ab46b32aafddddb5b6ad64e5a7344b8c65194a3291c3fc17f869a7fc41f80aba7cf75a958adc6b535d5d340cbb66923daabb777cacbb7ff1e5aecbc3bfb2ef82ecefa392ea1d4f57558555adaeee36c6d22b7cd26e8f6b7cdfddfbab5f37f857e2778b3c2fe0bb7d1f4dba9f4eb18750f3bed3046cacb332ff00a966fbbfc3bbcbaeaa3f147c4af1543e26b35b7d5755995566ba8a385a392c5b72fcd1eddbe5b36d55dbfc4bbbe5ad5c65fcc63194797e13e9ed27e18f83746b3bc583c33a2c11ea50fd9666685a48ee2356dde5afdefeeeef97f896bc77e25787347ff869ef03e8f6f6b6ba0d8b4763249f618d615dcb248cbb7f87fe59ac75e7379a0f8a3c17f12bc37e1bbcd62e62ba5bab5beb56b6b869238dae997cc6556fe2ddb95bfbdb7fbb5ea1fb5a45aa69be2cf04de5932ab477132daddc1fc370b346cabffa0d656e590dbe6891fed556f75a36bde05d7a058bec76fe62c2acdb5bce59966fbbfdddbb7fe05bab63c5dfb5e59f883e1eeb91e9ba3de683e28ba8d61b7916459238fcc66f31964fe1dabf77e5f999bfd9af52f899f07749f8b12693fdb336a107f67c9249b74f9963f33ccfbcacacbfecff00bd5f28fc44f06e9b79f16a3f05f822ddb6c7247a6ac924cd334d71f7a49a46ff006777cdb7e5fddd10e5969207cd19731d87ecbbe0b8d6f2fbc657b1aadbd8ab5be9ed27dd593fe5b4dff015f9777fb4d5e57f153c6edf113c75a96b4acdf6166f26c55bf86dd7eeff00df5f7bfe055ee1fb436b363f0d3c07a3fc3dd05bca92e2dd56e197ef2daafde66ff6a69377fc07757ccf26d55ddfddad21ef7ef099fbb1f66779f037c07ff09d78f2dfed10f99a5e9bb6f2e95beec8dbbf771ffc09bff1d56a6fc76f882de3ef1e5c2c1379ba4e96cd6b6bb7eeb37fcb493fe04cbff7caad779ae4b27c09f81f6fa7c0de478abc44cde748bf7a1665f9b6ff00d738d957fde6af9f61558e3555f9557eed5c3de97383f763eccb0bdaa45a856bbaf833f0e64f8abf11349f0fed9174f66fb46a122ffcb3b58ffd67fdf5f757fda6ad252e5f78cf53e90fd917c0767e08f02ea9f11bc40cb67f6e864fb3cf27fcbbe9f1fcd249ff006d197fef955fef579ff866c2f3f6a8f8fcd7da8c3245a0c7b6e2e20ff9f7d3e16fddc3fef48df2ff00bcd27f76bb8fdafbe25dbe97a6d8fc3fd236db5bac31dc6a11c1f2ac36ebff001ef6ff00f8eeeff7556bd7bf66ff00862df0b7e18dbb5fc3e5ebdab7fc4c35056fbd1fcbfb987fe02bff008f33571737bbcffcc74dbec9cef8a2e3ed5e2ad4195555564daaabf7576fcbb56ac69bfc5593b9ae269a66fbd233495bda7dbaad9c934f37d8ede18da6b8b9dbbbecf0c6bba493fdadabfc3fc4db56b23ba5f09ada1dbfdaae36bb6d86e95a391bfe79d9c7b5aea4ff00b68de5dbaff79a46feed6ff8c7e2f41f0ffc4be186d41995bc4bac7f653d96df9a459177348adfc2b0fcbf37f12b32ff007699e1bb592c236925b7fb35e4cb1c925a336e6b5555ff0047b5ff0080ab6e6fef492495f1a7c40f8b52fc4afdb2b47b3d2eebfe25be1c5bad2ed24fbcb24de4c8b7137fc0a46dbfeec6b4e31e638e523d97fe0a2d1d9dd7ecff00a3b3aaf9d67e26b75b365dacaaad6b32c91ab7f12feed7ff001dafce18e2ddb959772b7cb5faa5fb527c358fc75f0bfc41e15768d6eb4db56d434968d76ac735bf98d1c6abfed46ad1ff00c0abf2ce1db2c6acbf75977576e165eef29c75e3ef1a5e3af1cf88bc70d0cdafeb57dac490aac71fdae6ddb555638d7ff1d8e35ff80d732abf2d5cd43fd5ff00c0aabc7f76ba7e13989a15f96b4ad7eed538fe58ead59b7cb5605aa8666f969ccd556e1be5a00aacd5258af9b751affc0aabb55ed1d775c48dfddf96a40e92d57f76b53d451fdda9968351cbdaa45a8e9f505976cdbe6afad3fe09cbac7d87e3f6b9605bf75aa785e6ff00beadeea16ffd0646af916d5be6afa2bf61fd5174bfda9bc17b9b6fdbad752d3ffdedd6ad22ff00e3d1d6557f8722e3f11faa10b55c8dab3e36ab90b578913a89e919a9bbbdea366a00f8459aa166a91aa16aed3b8864a864a99bbd5792802392a8de5bc7710cd0cf0c73dbccad1c91c8bb96456fbcad571aabc95607c77f15be1ac9f0d3c42b0c0649741bedcd61337cdb3fbd0337f797f87fbcb5c4dc45b97fdaafb73c55e1ad3fc5fa1dce93aa43e7d9dc7f77e568dbf86456fe165af92bc77e03d4be1feadf62d4079d6f36e6b3bf55db1dd2ff00ecb22ff12ffecb5e952abcd1e591e2e2287b397347e138ba8a4ab17516c6dcbf76abb56c731564aabbbe6ab93555db500253b9a5db4e55a008f6d3956a4db4ddfb6ac81f4c9255897733555b8bedbf2a2ee6aafb6497e67a5cc04925d4970db53e55a7436eb17ccdf7a8856a1bc97fe59aff00c0aa4b0b8b86b86f2d3eed1b7ca5db4431ed5a24a901f6b0b5edddbdb8f95a69163ffbe9abeafd3f54b5b3f0ede4cbb62b7bc68ed6ddbfbccd32aaaaff00bab1aaff00df55f33781746935df186916317de92e159bfd955f99bff1d56afa7f50d2618fc1fac2a47ba3b3b392e2dd76edfdf47fbcf317fda6dadf356323a6944d4d26ddbedde66e5f2f526fbbff004f91afccbff6d23f9bfde85abb4d26cfcd5566ae57c1b358f8b2ce1c5d2dad8ea91c724777ff003eb37de866ff00b6727deff67757aa7856d5759d05752487ecd346ad1de5b6eddf67b856db247bbfd96f997fd9ac652e53ba2737e3ef85bff0b07c1335adac2adac59b7da2c777f149f75a36ff006645f97fdedb4df813e23d3fe2c7c35d4bc03e25dd2dd5adafd9ff0079feb24b3ff96722ff00d3485b6aff00c056bd8bc3fa6f94b1ee55dccdbbe5af07f8fde08d43e17f8dac7e227867759c77571ba6655fdddbde37dedcbff3ce65ddb97fbdbbfbcb597c5a133f76573c0fc55e12d43c07e26d4341d517fd32ce4dbe62fdd9a3fe1917fd965f9aa8ad7d6de3ef0469ff00b49fc37d37c51e1f58e0f12430b2c31b37de65ff005967237fbdf75bfdafeeb57c8eab244cd1cb1c91491b32b4722ed6565fbcadfed574d39f31cd38f29617b57b97ecc3f157fe112f113786f53baf2b45d5a4fdcb4adf2dade7f0b7fb2b27dd6ff6b6b5785ad3bef2b2b7ddab9479a3ca4c65ca7d15f1e3e1f6adf0bfe2047f10bc38ad058cd78b75232aff00c79de7f12b2ffcf393e6ff00be996baef8e1e3cb5f1a7ecefa6ebda45c2c56ba86a11d8ea1a6b6d6db2796ccd1b7f12b4722ab2edfbcacadf76b53f67bf8a16ff173c2379e13f132c7a86ad676be5cd1cdff00310b3fbbbbfde5f955bfe02d5e07f123c1771f08fc5d7de19bd925b9f0edf32de59cecdb59a3f99639bfbbe647b9a36fef2eefef2d71c7e2e597c5136ff09d87c1df80fa0fc5cf863ac5e41ae5cd9f8c21ba92d6de1665fb246db55a3f3976eedacbbbe65ffbe7e5f9a6ff008639f157daae23fedcd0da35f9619e45997ce6fe25dbb5997ff66af78f83b2df5afc3bd26df52d2d6db52d2e46d1750b68edd577490afeeee3e5f95b742d1b799fc4b58faf7ed19e0fd0fc65aa787efe6bbb692de4bab7b8be6b793cb8668d76aee55f99b73337ccbfdda3da4a5f0872c4f21d3ff63ff186a56b236a5aa691a6335c2c2cbe735c7ee7f8a6dcabf7bfbb1fde6ff66be98d72cf5c8be1edc59cfaa2d8eb5ff08fdd4326a1a7b37fae8e3fdddc47fc4bbbcbddb7fbccd5c5df7ed19f0f6c3fb4215d59750b8d3ed636dd6d0b79374df2ab2c2dfc4dfc5fc3fecfdd6ad0d4bc61e15f1e7fc249e119f54822b7d43c3ab710ea11dc46d0b46db95995bf86485955995bf86a5f34be203e6bfd96fc25e17f1d78da4d27c55a3cf7d6ba869b2476322b48b1c370abb9be65fe2f2f76dddfc4b5e9dad7ec4b6b67a7daff0065f88af350bc5d523fb52c90c6acda7b32ab796bf75a68d7e6f99b6b7f757e5a8ff62bbfd72cecfc596ead04fa1f971ccd1c6dfbc5bafbbb957ef2c6d1ab7cdfde55af46f8b1fb43c3f09fc61a0e9775a5aea10dd2b5c6a0d02b2b436acdb55a166f95a4dcadf2b7f0aff0eead2529737ba4c63ee9e2fe20fd95fe22693e3cbad0f43925bcd06f9a468f5b92f3c985a1dcbf2dc32fdd93e55fe16ddb5597eefcbc9fc60f0cf8a359b1b5f88dabe8b75a46ad35e3693ae48d1f97bb50b76f2d6f23ff00666dbf797e5f3a36fef2d7d4567fb597c3d6bcd521bcbe96da1b7be586deee3b79248eea16dbb6655dbb9557e6dcadf776ff0015769e30d1bc3ff13bc2b7da2dd5d45a869f7d6b1b3496922b6d8e4f9a1b88ff00e04bb95bfbcbb6a79e51f88ae53c0d9ac7f6a2f83b342ad02f8c34f5dcd1b36d686fb6fcb22ffd3199777fbadb97f86be37bc592de49a19e3920b8859a39239176b46cadb595bfe055eb1a5dd6b5fb38fc62687525666b193c9be583eede58c9ff002d17fde5db22ff0075976d687ed6de058743f1743e2ed2da39f47f112ac8d247f756e3cbddbbfdd9176c9fef6ead69fbb2b132f7a3cc7cbbe26ff8fe8ffeb9ff00ecd5970d697889b75f47ff005cff00f66aa10ff157744e11970d555aac49f78542dde802ff0084ec7fb53c51a65b11959255dcbfecafcdff00b2d7616be21b36f88926b57b1bdcdad9c8df678e36dbb9a35db1ff00c0777cd5c77877506d2f588eea2ff591c726dff659976eeffc7abd1bc0bf0e6c756d3ed6fb52ba962b59159a48e3f976c7f37cccdff0166a9358ff0074da9be3378a3c41ac5ac3a45c496d348cb0c305a2ac924d237cbf7b6fccdfddacfd43c55e2ebc8f6deeadaab342acdba4b86fddeddd0fcdfdd6f99a3f9bfbd5ee9e1dd4bc37a1df5c6a378ba569973a7e8f1b348bb5668e1dbb618f77f7b6fdddbf37fe3b5b1f1722b5d7be0ff881b4afb3c51c96f1dd2dcc7b76c9b64dccaccbfc5f2fdeae5e7f7be13b3d9ca51f888fc4175ff0997ecd37578f6776b0ff0065ee85a7ff005922dbc9fbb9bf8bef797f7bf8ab73e12fc4df0df873e1af836df57d422d16e1ac64f2d9a4665658e465dccdfde6ddf77fdefeed3747ba8fe237c27b3b3d2593438f50d27ec36ab76bf2c2db5a1f9957ef2b32b7cdff0002af29f0efeccfe2ad5b49b1ba7b8d3f4d9a66ff0048b4bb66f3ad555bef36d5dacdfecaff007ab28f2fc32349734651944fa121f1afc3dd1f47f102dade68ff0065b5bc6d52f20b465999ae99b77991ab7de9372fcacbfc554e3f8c9e0dbaf1259dadadd2df6a1ad35bb2cf6ccdb7e6f957ccfeeb2edfbad5e4b6bfb2aeb575e15be66bcb35f124771fe8abe76eb4f257ef6e6dbbb77fe3abf76b95f157c3993e1cfc54f0fe8bf6e9163b89ace48efa787e556691564dbfde556a39612fb44ca738fd93d43f680b3b8bff001f7c378dee16c74fbabef27ed2abba686669a3dcdfed2eddbb7fdadd51fed7975af4b75a1dc343e4786639bccb7bb5917cc5be6ddb95bf8be558d76ffb5baaafed71a1ad843a1eb9079b15d2dc4d6bba06fddeef9a4dcbfdd6dcb5efd6b716b2dae836ba95f59ebdae59d9daea1bae5a3f3a49b6ed5b88ff00e9a33349f37fc0ab3e6e58c6426b9a5289f2ce93fb48f8f2d747bc99b568ee665be5ba5d4ae63f32659b6ed5857f8557f8beefcbf37f7abb4fd9bfc3d6fe12f0cebdf153c472336d8665b5924f999a3ddfbe9bfde924fddaff00c0bfbd5ccf8c2de1f8f1f1aadfc33e1986d6c749b76916e2fac6dd638db6b7fa45d36dfbdf37caadfc5ff02aeb3f6a8f1469fa368ba1fc3fd1156dad6d638e6b8823fe18635db0c6dff8f49ff7cff7ab47ef7bb1ea4c7ddf78f01f1878aafbc69e26d4b5ed47fe3eaf24dde5ff00cf35fe18d7fd955f96bb0f803e08ff0084cbc750dd5d46ada5e92cb7536efbb249ff002ce3ff00be9777fbab5e72cad2c91c7146d2cd232c71c4bf333337dd55af7cf143c7f01fe08ae8ab22af8a35c565936b7ccb248bfbe6ff007638ff0077fef356b37eef2c498479a5cd23c97e3178fbfe16378eaeafa2666d2ecf759d8ffb51ab7cd27fc09be6ff00776d722b5563558955557e55ab11d6b18f2c794ca52e6973137dd5dcd5f697ece3e19b3f833f06754f1c78823f22eb52b75be997fe5a2daaff00a9857fda919b77fc097fbb5f39fecfff000c5be2c7c46b3d3ee2366d0ec7fd33546fe1f255be58ff00de91be5ff77757b47ed55f1064f11f882c7e1ee82bf69686e23fb6416dff002d2ebeec36ebfeeeeffbe997fbb5cb57de97b33587bbef19bfb3bf822f3e39fc5ed4bc65e238d67d374fbafed0bc56ff005735d37fa9b75ff6576ab7fbb1aff7abeccd72ebfd06f2466f9bc991b77fc06b9ff857f0fadfe13fc3dd2fc3b1796d750af9d7d3affcb6ba6ff58dfeeff0affb2ab56bc512edd0f506ff00a62d5cd297348d6278ec3f2ac75d62dc43671e93673c7e6add349a85c46cbbbfd16d5976affdb6ba92dd7fe035cadaf972dd7ef668e0b58d5a69a793fd5c31afccd237fb2aab5e9de1fd36df52874fbcbdd3d60bc9a3593cb6dd1cd1c2ad2496f1b7fb4aade632ff007a4ff656a2475ccf13fda93e3c37c1bf06b69b6537fc569ad472792cbf37d9d599964ba66ff7b72c7fde6f9bf86be48fd9074b8f52f8e165bd377976574df337f132ac7bbff2256e7eddda6dd693fb446a6b3c8f2dbdc5859c96be67f0c6aad1b2aff77f791c959dfb19ac92fc6d8da26dbe5e9b713337f7555a36ff00d96bbe31e5a479b2973553efefda435c9b46f86fe20d7ad64fdf5be8b35d798abbb6eeb8655ffd0abf27ece2fdcc71ff0075556bf51fe375edbdd7ecfbe3b82665dd1f856fa158ff0089bcbb8f95bff41afcc4b5b7dabf354e0fe190623ec997aa45b61ff812d558eaf6b5f2c3ff00025aa36f5e81c65afe1ab167fc555dbeed496adf335005891aa9dd37cdb6ac3355191b7b3500359ab6b478b6c31b7f137cd587b7cd658d7f89b6d7516abb16a4b2f2f6a916a15a9168289a8a6ad1ba802685b6c95eb9fb3beb3ff08ffed05f0af5066dab1f89ad6166ff00666dd0b7fe8caf1f8daba2b1d524d0eeb4dd5a26db269b7d677cadfddf2e68dbff0065aca51e689ac4fdbcfbb232ff0077e5ab11b557ba9565ba9a45fbb23798bfeeb50ad5f3e8eb2d34b4d66a8777bd359aa80f86daa192a66a864aed3b885aa16ef533542ddeaca2192abc95624aaf250490c8bbab0fc4be1bd3fc55a45c699aadbadcd8dc7de5fbacadfc2cadfc2cbfdeadc6a864ab0944f8ebe257c31d57e1adc335c16d434391b6dbea6a9f77fd9997f85bff0042ae21a2565dc9f32d7de17d6b0de5acd6f3c31cf6f32f9724122ee5917fbacb5f3e78f7f6719ad679af7c1f203137ccda45c49b76ff00d7291bff00416ffbeabae9d5fe63caab87e5f7a078448b51f9757b5049b48be92d354b59f4dbb8fef41731b46d4ddaacbf2b2b7fbb5d479e53db4bcd4ad1542c94086c8db56a8cd2b37cab56268599a9ab6adbbe6a5202ac76fb6a65566fbab57ac74f9352ba5b5b2b796f6e1beec36d1f98d57756f0bea3a3ea1258dfc6b653471c723421b737ccbb9559aa7fba5f2fda3026b8dbfbb4fbdfc4d50c716df9aaf5c5aac526ddb55e46dab4729027f0d31aa69976ed5feed474167a3fc05d2fed5e2ebcbadbff001eb62ccadfdd691963ff00d059abe91d4ad55743b8f9be555656ff00bf326eaf17fd98f4ff00b54be259bfbbf6387fefa691bff69d7b6f8824f2fe1eebb7feba7df5c2ff00c07ce55dbff7cd734e47a1463ee9e23fb3578d0dbea4de1bb99957ccdd359ee6fbcdfc51ff00c0bef2ff00c0bfbd5f6ff80f46fecbf1059ea9f68b59745f1343fd9f78accdff001fcabfbb5ff664923dcbb7f89a35db5f973a7bcb677114f0c9243708cb22491b6d6465fbacad5fa2dfb2cfc5cd2fe30f80f54d0fc41e7ff695bc3ff1328ece16926dabf3477d6f1aaeedd1b2ac9fecb2b7f7956b2ad1e5f78546a69ca7af6876ecab0c6ffc3f7b756a6b1e1fd3fc51a1df68fab5badce9b7d0b5bdc47f7772b7f75bf8597ef2b7f7b6d57f0fc978de5ff6cb5b36b11b7d96f9ad976c6d70bf3798abfdd92368e65ff664ff0080aee4916dfbb5c713a247c83e09d66fbf66bf8a17de15f10ccd2f87ef995beddb7e565fbb0de2ff00e8322ff0edff0066aafed5df0d1b46f1147e32b0b75fecdd51963be68beec775fc327fbb22ff0017f797fdaafa0be387c278fe2d784fecf079717882c774da6dccbf2aeefe285bfe99c9ff008eb6d6fef5793fc01f1e43e28d1efbe16f8cad5a79238e4b5b782efe569235ff005966dff4d23dbb97fddff656b7e6fb6656fb27cb7baa45ae93e277c3ebcf85be34bcd0ee99a7b7dbf68b1bb65ff8f8b76fbadfef7f0b7fb4ad5cc5767c4729d1f81fc617de01f16697e20d3be6bab193ccf2f77cb347f7648dbfd965dcb5f647c56f05e9ff001ebe18d8ea1e1f9967bcf2ff00b43479dbf8b72fef2ddbfbbbb6ed6feec8ab5f0bab57b87ecd7f19dbc11ae47e1bd5ee157c37a94dfbb9246f96c6e1be5ddff5cdbe556ff80b7f7ab0a9197c5134a72fb323d03f665f8d9717f7567e03f12b33490afd9f4b927fddc9f2fcad67237dedcbf3796df7be5dbfddae166f86f71f113f6a2f10786fc41a94fa5497da85e5d7da7c9569268f6b491f96bf777347b5bfbbf2d749fb567c2f6d26f3fe13cd2636b6669a38f568e3f95a39b77eeee17fbadbb6ab7fb5b5bf8ab6be12f8b61f8c5e28f09f89af7cab6f1d78566f2752917e55d5b4d923923f336ffcf4566ffc79bfbcb597f7a26b2fe5336e3f635bc6d3f49fb3f892dadb52f3268ef96e6369219a3593f77343b7e65fddb2ee8dbf8bf8ab9193f64bf889135d79563a64eb1dc2c6acb7cabf6856ff0096cbbbf87fd96f9bfd9afa3be2d7c6ed3fe0ee9ba6dc5fd8cfabdf6a523797696d22c2aaaabf33337fdf3fef36efeed727a5fed7de0bbcd624b796d6fb4fd2fecad27dba78f7379cbb5bcb58d7ef6ef9b6b7f797fbb4465505cb10fd9f7e17f88be1a4de34b5d7b4b8156e218d6d6fa09159a68d59b76dfe258feeb7cdfc55e43fb596a5a86a5f17268eea18e25874db55b3f237379d1c8ad22b6dfef6e91976ff00b35ef5e1bfda7bc2be30f12786f47d3a3bc59b56b8f2646be8fcb6b593fe59eefbcadb9be5f96bc17c70be1df89df15bc2eda1eb52e991ead247a7dd473ab34da5cd1c9b576ff0c8adf2f96cadfecfcb4479b9b9a412f84f42b5fd8cacf52b5d2665f165ce9fe7496f25e417767fbcb7864857cc55fef4cb26ef97fbbfed2d70375f0b7e317c1bd63c33a869cb75737934335ad8c9a349f6c8e358da491add97eeed65569b6eddbf37f7b757d51f15be225bfc2dd174dd5b51b3bcd5ecee2fa3b3b8920857e5f97e6919beeab7cadf2ff137cb54fc13fb4a78175ed2e6d49752fec5687ed135c69f72bb6686387fe5b32afcbb5b72eddbfc5f2eda98ce41ca7cb7aa7f687c62f85362babe9b78de34d174fbad5345d6645ff90f6931cccd716adff3d2687f7922b7f755969df0e6f23f8c5f027c41e07bc9165d4b478d66d3656f99963fbd6edff0193747feeb2d7db4da6e97a968fa4b5bc36b79636b22ea5a7c906df2d595999648597fbdb9b77f7b732b57c3fe32f0e2fecd3fb425add40b25b78375c593ecedb7e586d666db247ff6c64dadfeeedaa8cb9bdd0f87e23e45d625f36ea36dbb7f77f77fbbf35535fbb5da7c70d05bc2ff0015fc49a6b46b12c774d347b7eef9727ef176ff00df55c4ab57a317cd1e638651e59728d6a85aa46a8daa892c69bff1f136efe18fff0066aef345d6bc41aee9f3683a7acd7d1b46ccd1c11fef3eceabb7cbff00ae7fecd739e00b18af354b996e157c8b78d642cdf757e6f97757af687e24d07c273ce81a389acad635916dc664daadf2affb4db9b76daca46b4e2626a1f0e7c456fe19baf106a51aadbc3e4c6cb24cad36d6db1afcabf776fcbf7abe8ab3b3b5f147c15b56d52e2558754d3d6eaf24b15f2fcbf95999957fed9ab37f7956b91f1937dbfe12eb1716aad1432476b74ad3b7cd347e72b37fecbff7cd761fb39dd6a1af7806ced6fda29ede1bc934db19f72b3430b5bccadbbfeb9b7dd56fe16ae69cb9a277535184b94e67e1cfc5fd17c39f0af495bfb8fb66b9a5dadc470d8f97b7732b7ee57fbadf7b76eff65aae7fc3507d824d51acf4b6b9b7fb742da7c173f2ff00a3aaaac8d27fb4db59b6fcdf349f7be5ae76cff65fd7a0b3b7fb56b5a645e5b42b36ddcdfbbdbfbcdbfed2ff000aff00157a3687fb2ff866ced750fb7df6a5aafdaadfc98e79235b76b365ff0058cbe5b37ef3e65dbbbe55f9bef544bd987ef7e138bd17f68cd6354d5341b1bffb1e956bfdade65d5dc1f2c7f6566f96365fe1dbbb7799feeff76b4bf6985d42d7c61e11d72f3cafec18e48f6ac6cbfbb91645924ddfc5f346aadbbfd96ae6fe3f78734ff855e36f09df684b1b797670ccba7dcc2ad1ff00a3b2aab37f7bccf9b76ef9b76eaf40fdabace4bff06e977912ac50c378accb236d65f3a1655ffd068f779a3ca4fbd69464769f17bc1179f17345874bd0ee2d6068f585b86b9b966f2fcb6565ddf2ff00b4dbabe7dd4be1f6bdf0674f935ef10476d63a95c43269fa2c0b70b34cb232ed9266dbf75638d9b6fcdf7a45af64f84ff1a7c2f79aa69be19b5b5d42269aebc9b5b9bb55dab0ac2acb248cadf2ed65656ff6555abccef2e2f3f6a2f8d90c3134abe1db55daadff003c6c636f9a4ffae9337fe84bfdda95cd1f765f08a7cb2f7a27a57ecffa469ff077e0dea9e36d5e168ae35287ed1b7fe5a7d957e58615ff00ae8df37fc096be6bf106bd79e28d7350d63516dd7d7d335c4db7fbcdfc2bfecafcabff0001af62fda7be25dbeadaa5bf83748daba6e8f22fda9a36f95a655dab0aff00b31aff00e3dfeed78ce83a1de78a35ed3f47b05dd797d32c31eefbabbbf89bfd955f9bfe035a538fda9133fe589eadfb37f80e3d4b5ab8f176a5b62d2f49665b7693eeb5c6df9a4ff7635f9bfde65feed797fc52f1e49f123c6d7dac6e65b15ff47b18ff00e79dbafddff8137de6ff007abdbbf680f1058fc34f877a4fc3bd05b649756fb6e1bf896d777cccdfed4d26eff80eeaf9ab9ab87bdef84fdd8f20da566dabf7599bf8557f8a92bd57f66df01ffc265f10a1d42e21f374bd0d96ea4ddf764b8ff9631ffdf5f37fc06b594b963cc6518f34b94fa03c0f15bfecc9f0466d42ea38dbc4174ab348adff002dafa45fdcc3feec7fc5feeb7f7ab1ff0063bf86f71e26f165f78fb57f32e61d36665b5924f9bed17d27cd249ff6cd5bfefa917fbb5c6fc5ad7afbe317c56d37c23a1c9e7c36b71f61b7feec974dfeba6ff757eeff00baadfdeafb63c23e17d3fc0be17d3741d2d76d8e9f0ac31b6df9a46fe291bfda66dcdff02ae197bb1fef48ea36266ae4fe205d2d9f85754999b6aac2d5d435733e32ff0048d2ee16585ae6de1f26692055f9ae1bccdb1dbaff00b5249b57fdd566ae72a3f11e67a6e9b6ed34d6b750adcc70c96f71796ccdf2dc4ccdbad6cdbfe99feee4b8917fbb1aaff15769e19d6e6d63e322e83672497d258d8cd75ab4edf2edb8ba8d56de3ffae9e5f9926dfe1565fef5713e23d62c7e1d699a86a7ad5c24b65a6dbc9a85f4df756e2693e6665ffae8cb1c31ff00d3355ff8166fec912cde25d0fc3fe28bb7ceb1e25bad4351ba6566f9a696e248d7fe02b1c31aaffbb4e5f0f31a4be23e6cff00828d35d7fc2ffb38ee2dda2861d06de3b793fe7b2f9933337fc059997fde5af3bfd967e20683f0dfe23ddea9e21ba6b3b49b4d6b38e6f2d9b6c92491fccdb57eeedddf357d05ff000524d163d526d03c46abfbf86f1aca66fef43736b0de43ff00913ed55f1142bfbcaf4697ef28f29e6ce5ecea731f4c7c7efda2aebe226a52687e1cba96dbc3767f6cb392e609bfe4290cd3799f37cbf77e55f96bc4592a3d2d7fd156a692b68c634e3cb1227294a5cd23075ef96dd7feba2d51b75abbe22ff8f78ffeba2d54b5fbb5a999679a587e492939a66edad40125d4bb56a9eea92e1f732d435205cd362f36eb77fcf35ffc7aba0b75d8b597a3dbecb756fe26f9ab5a3a0b265a996a15a917b505122d2d22d39682c16b42f95ae3c3b7d18fbcd6b26dff00be6a8d6c696be6c2b1b7dd6dcb50289fb3df0f75eff849be1ef84758ddbbfb4345b1baddfef5bc6d5d12b57907eca3ab0d67f665f859741b71fec2b7b72dfed43ba3ff00da75eb2ad5f3f2f764771619aa366a6eea6b35007c4ed55e4a99bbd4325769dc46d51b53e98d56510b55792ac4955e4a00aed50b54d2543255810b77a8644dd53377a85aa893275cd074fd7ad7ecfa958dbea16ffc31ddc2b26dff007777ddaf3cd4bf679f056a1233269f3e9ecdff003e974cbff8eb6eaf5392a16aa8994a3197c47865dfecbfa5fcdf64d7f53b7ffaef1c727ff135932fecbf76bfea7c568e3fe9a58b7ff155f41b77a8dab4e69187b0a7fca7cf90fecc97ecff00e91e278547fd30b4666ffc7996ba8d0ff67bf0ce92cb25fb5d6b732fcdb6e5bcb8ff00efdaff00f155eaeddea1928e6907b2a71fb261d9e8f67a4c3e4d859c1630ff00cf3b68d635ff00c76be7ff008a0dbbe226b8bff3cfecf1ff00e415afa426af9b3e2336ef883e226ffa7955ff00be628eb5a5f11cd88fe19c16acbfbeacf8e2f36e218ff8775696b1feb8551d3fe6b8924feeaedae991e711dd7faf6a86a69bfd63546d59967ac7ecebe3cd3bc23e22beb2d5eed2cb4fd41636fb44df76392366dbbbfbbf2b357a06b5f13b4cd67e07f88ad74fbb492ead5668248d55976c735e36dff7be592be65d952dbdd4b6f0dc42923ac336df3155be56dbf32eeac250e691bc6aca31e5258fef0afba7fe09b9e17b7bc7f17eb0b32c77d0dc59d9c7fdef995b6fcdfef3336dfe268d7fbad5f0c46db5598fdd55dd5fa9ff00b36fc22d3fe13fc29d39a5b053ae9d324bfd42e376d6f3a7f2d648fe5feec6cb6ebfdddb237f1356588972c394aa11e6a877fe345b5d27c4979a9348d169726db7baf2db77936ebfbeb7b855fbdfe8fe67cdb7e658646fbcb1ab5692c52343e5caabe746db6455fe16ff00d997ff0065af20f047c54be6f8b9f11fe1f5c5f2df6b1a45e36a5a5ddddc6acb756b2797242b27fbab2793feecabfddaf45d1f6e83750e93179b2e9ed0b49a3c9236e93ecf1fcd258c9ff4dad777cbbbfd65bedff9e6d5e7c7dd3b0d468b6b7cbf76be71fda8be16dc5ac91fc48f0f7996da958b4726a5e47defddedf2ef17fda8fe556ff676b7f0b57d34cab2aee5f995be6aa7716f1f96d1baacb1b2ed92365dcacbfc4ad5a7372ea4fc47cdfac5ad8fed5ff08d66b38e0b3f1b68edb963fbaab70cbf347ff5c6655dcbfdd65ff65abe496592de69219e3920b8859a39239176b46cbf2b2b2ff7abe82d6ac2e3f65df8d16f756b1cd3f84f528db6c6bff2d2cd9bf790ff00d7485b6b2ffc07fbcd47ed5df0de18aead7e22686d1dce97ab796ba84907ddf3197f7374bfecc8bb55bfda5ff6abaa9cb97ddfb2652f7b53c0569db55976b7ccad50ab548ad5d2627d75fb3efc4e87e23783ee3c1fe22f2f50d52ced5a168ee7e6fed0b1dbb7fe04d1fdd6ff00676b5791f89346d63f66bf8a563a8690cd3e9b26e9b4f9276dcb756fff002d2d64ff00697eeffdf2d5e5fa3eb37de1fd5acf54d36e1acf50b391668675fe16ff003fc35f5b35e68ffb4c7c279a1568b4fd5a1656656f9bfb3ef157e56ffae727cdff000166fe25ae3947925fdd3a232f691b7da391fda7b5ed27e237807c0fe22d22ce46b591ae196ed97e6b7fbab259b6dfbd22b7ef197fbabb97ef5775e1bfd987c27e30f0cf80f5cbab5934a923d26dff00b4ad2c5959750dd0ed56dcbf764dccade62ffbad5f37f87edef2c358bcf02eb978de1c924be8d964b9f9a3b3d415596391b6ff00cb3915bcb665fe1656f9b6d7dbdf0cf4193c1fe0ff000fe8f710cb049a6d8c2d7502b79924726ddd711fcbf797ccdccaabfecffb34a5ee46d108fbc796de7ec57a3b683a1d9e9be2492db56b79a492fb52bb859bedd0b37caab1ab6d8d976fcadfed354de19fd8cad74bf1435f5ef88ae67d2ecf528ee34f8e085566b88636dde5cdff003ce4ddb7eeff000ab37f17cbc9e8bfb6e6b56f25e7dbf43b6beb76fb435ab2b34722c9e6335bf98bfc4aabb55b6ed6f97757a6783ff6b8f05f88f4fb15d5965f0e6a975751d9dd5b4ffbe86156ddfbe5936ffa956dbf7be65ddf37f7a94bda4471e533ff006cef1a6a567e0fd1f45b758a5d3f5e92692fa468d99b742d1b2aab6ef97e6fbdfeed79dafeccf71e32f0cf83f54d0ee20f3b54f0dfda26923f96d96fa36f97ccddf37efa36dbb97eec91b332ed6f95bfb44789b47f883a1c37d61ac5b417da2ead75a5dc697f79a46ddb56e2ddbeeb46cb1eeddfed7f7bef7d09f05db4db8f857e17fb2e9eba643369ab34968b70cb1c6cdb99996466f9559959bfd9dd53cdece22f8a47c9bad785fe2e7c1d9b4fd0e08f535b3fb42eb566ba36ebcb469a356dccacabf2b2aeef3236dbff0002fbd5c3eade34d5be27781fc5da7ebfa84fabdc43ff0015369f2cedbbcbdacb0dec71ff007636864ddb57e5ff0047afaebc3bfb60782eeadf439256d4b45bebe93ecf791b36e8ec64ff009e9249f2ab42dfc322aff79b6aedadcf135af847c796371a6a47a6de369b25d5ab797b5bec31dd5bed6dbe5ffcb392391597f85bfde5aaf6928ef10e5e63f32be2a78997c59abe877cd2f9b7cba2dadade7fd7687743ff008f2ac6dff02ae416b4bc59a35d78735ebad2efd765f58cd259cdff005d236dad5995e844e194b9a423546d523546d5649634b5926591523697cc916358d7fe5a37f0ad75571e17bad374bbcbeb8db1fd9eea3b5f2f6fde9197737fdf3f77fefaa83c0fadda683666e2656791af576aaaab32aaafccdff8f576be32d461d6bc2363763cfdb3490c91eefbcbf2b6edd591ac631e53d62e3c336fe20f8130c8f712c50e93a4ade43b57e6f3218fe68e456fe1f99b77ff0063583e03f8b56fe0df86f7da3d9dacf16b524d25c4373b97c9dcdf2ab7f7976aff00df5b6bd1be18c375e20f85b1c2f750417daa697e5f98d1ac8ab232c8ad2347f2afdd65fe2fe15abfa17ecc5e138600659f53b9f2ed64b3dd337fad99beedc6d5dbb5957eeafddfbacdfed727347e191dbc92f76503cf26fda135896f2fa1b7d36d9aceea3686ded999a492192487c9ddb97ef36ef99576fdedb573e09fc4bf126a9f10345d0ee350975587508574956b99199a18d5bccdcbfde6fddeddcdfc2d5efde19f02e8fe12856df4cb3b655b75b7559248556e64687e65666fe26ddf36efe16af07f116b3e1ff047ed3d6faa2c72687a4d9ccb71792410b7fac9216dd22c7fdd66917eefdef9a9465197baa2294651e594a46b7ed6da94d15af85614f2d636fb66a0acabf32b2b2aaffdf2b5ed5e3af87da6fc4bf0dc3a6def98ad332cd0df4327cd1ccb1fcb22ff000b2fccdf7abc9ff6acb06b8f0af8575069167fb3de4d6eb27f7a39a359176ffb3fbbae2fc2ff00b416bde12d2f4fb1b28638acec6ce3b568e7fde79932b3334df37dddcbb576ff00768e594a31e52b9b9672e6307e257872dfe1578b24d1748d5a7d4ef9ac561bc93c95568da68f6c90affbcadfef6d936d7b469b6ebfb35fc0fbaba6f2e2f1a6b5fbb5fef4770cbf2aff00bb0c7b9bfdeae57f677f87d75e34f125f78fb5e6f3e386ea46b7926ff978bcfbd24dfeec7ffa17fbb5c3fc6cf891ff000b23c6924d6b23368ba7ab5ad8ff00d345ddfbc9bfeda37fe3aab4ff00892e523e18f31c1fdd5fbcccdfde6fbcd5ef5f007c3963e07f0bea5f133c42cd15bc70c8b66bb7e6f27eeb48bfed48dfbb5ff817f7abcbfe18fc3eb8f891e2a874d5f322d361fdf6a172bff2ce1feeff00bcdf757ffb1aef3f69cf1d5adc5c69fe09d21a38b4fd2f6b5e4707fab591576c30ff00db35f9bfde65feed54fde97b3261eec7da1e3fe2cf145f78dfc4da86bda8ff00c7d5e49bbcb5fbb0afdd58d7fd955dab595cd2eda4ae9312291b6c6ccd5f5469b71ff0a17e05c2bfea3c4578ad232ff17db265ff00da71edff00be6bcd7f675f869ff0987891b5ebf8d5b47d1e45f2d64fbb7175f7957fdd5fbcdff01a778cb5cbcf8f1f16ac745d22466d3dae3ec76727f0edddfbeba6ff00be777fbaab5cd39734b94e9a7eec6e7b77ec4ff0e7ca8750f1d5ec7f7b769fa5b4bfddff009789bff69eeffae95f562b6eac1f0fe9767e1cd0ec749d3615834fb1856dede35fe155ad885be5ae394b9a572be11d34bb76ed5dccdf2aaff79beead73fab343b64be793cf587ccb5b1dbf75a6ff00577175ff0001ff008f78ff00edb355ad42fef16f2c61d37ca5d4aea465b79275fdddbed5dd25d4dff4ce18fe6dbfc52346b4ed7343b3d27c030ff60ac9731e9ba4b5e69bf695db25c2c30b7fac5fef49233337fb527fb559b2a27e787ed9bf1624f1078d27f04e9cfb74bd2665935068dbfe3eaf36fddff763fbaabfdedd5f537ec6f2c7ff000acfe174d6edfb8b1b68da66feeb497975bbff001e55afccebcbe9f56bc9efae24696e2ea46b89246fbccccdb99bfefa6afbf3f60df16dbeadf0c6e3438a4912eb435db70adfed4d7122b7fe445ffbe6bb6b53e5a6614a7cd5246ffedcde1d1a87c0ff00106a836bad9be8b37ddf997ecb717967237fe4c46b5f9c11ff00acafd3bfdb72fadb41f85de3c86ee6f2e4b8864b4b38437cb71e7df4726dff00795a356ffbeabf352decf736eabc2fc26588f88d4d3fe5b58ea6929b0fcb1aad125761cc73fe22ff00531ffd74aaf67feaea6f107fa98ffeba555b36aa02ef351337cd4e66a864a006c8d51afef2458d7f8a9acd573498bccb8ddfdda9037add76c6bb6ac2d471d3e82c9d69cb50af6a91680265a916a35a916828756a68edb597fd96acd5abda7b6d92a0d227e9d7ec1ba8fdb3f65df0cdbeededa6df6a563ff7cde48cbff8ec95f422b57ca3ff0004ebd47ed1f05fc4d63ff3e3e2abaffbe66b7b793ff8aafaa96bc2abfc491d31f849b77bd0cd4ca466a82cf8adbbd42d53377a864aed3b885a9ad4e6a8dbbd59446d50c953354325005592a16a9a4aaed56046ddea192a6a8daa892bc955daac3546ddeab52085aa16a99aa36a6410b77a8d92a66a8d968029ccb5f2ff008e25dde36f1337fd44a65ffbe76ad7d4922fcd5f28f8aa5f37c51af49fded4aebff46357451f88e0c57c272baa36e92a3b5565b3566fe2f9a9d78bf689a38ffbcdff008ed4d75f2c75d5a9e719b2542d534950b56522c5a48fef0a6d490ad481d87c2ff0bc7e34f891e11f0ecbbbc9d6358b3b1936ff007649955bff001d66afd7286ea3bcf0ddc5d799bbed11e9f1b6dfbbfe9178d70cbff7cdd47ff7cd7e5efecb31237ed11f0fa693fd5d9ea8b7cdfeec31b4cdff00a2ebf4aa355b0f01dac3bb6fda3c4963631eeffa632470ff00edbb57062373bb0fb1f15fed21e39baf84bfb5fd978cac89db2d859bdd2467e5923f2dade65ff6bfd4b7fc096beccfb5697e23d16df52b0d42382d6e3ecfa958eacbf76de48fe6b7baff006a3dad24727fd339197f86bf3b3f6bcf175af8a3e2ddd5bc114915c68ad75a5dc336ddb27977d71246cbff00019957fe035d87ec4ff1035cbef1e699f0efed5752f86f54f3a6ba822936b5bc71c6d249e4b7fcb3f3163f2dbfdeddf7a9ca97eee3208cfde944fd03d2750fb647f35bb69fe6349fe88ccb27d9e68e4659adf72fdedacbf2ff0079596ac5c2d732ab716b67e17d4372db6a5ae5bc7e641046cb6cd791ac9e4c91aeef97cc8616b765ff00ae2df796ba2fb543750acd049e6c3246b346db7ef2b2ee5ffc75ab9626ece07e307c2f87e2c782ee349668e0d5216fb469b78df761b85fe16ff65beeb7fdf5fc35e1bfb3df8aa1d4b4fd63e13f8c2cdbc9916686deda7f9597ef79d6bfef2b6e917fdd6ff66beac6f99b6fcbf37fe855f38fed3df0c6e2d6ea1f895e1c6920d42cda39352f23ef2f97b7cbba5ff697e5593fd9dadfc2d5ac7f9499773e6bf88de01bef863e30bcd0ef59a755fdf5addedf96eaddbeec9ffb2b7f7595ab9d5afacb5eb0b5fda83e0fade5943141e32d1d9bcb817e5fdf6dfde43ff5ce655dcbfdd6ff0075abe4b5dcb232bab4522b6d6565dacadfc4ad5d94e5cd1f78c271e525aeb7e19fc44bef863e288f56b35fb4dbb2f937d63bb6add43fddff00797ef2b7f7bfe055c97349baab97989d4fa9bf680f00dafc48f07e9be3af0cc6d7d2436ead2796bfbcb8b165ddbb6ff7a3f9be5feeeefeed765fb33fc64ff84f3478fc3fa8dc6ef1269f1ab5bddc8dff001f10fdd56ff797e5ddff007d7f7abc87f65df8b5ff0008feb0be11d52e36e9ba849bb4f9d9bfe3d6e9bfe59ffbb27fe85fef54df183c17a87c11f88da5f8d3c34bf66d2ee2f3ed16fb7e55b5baff009696edff004ce45ddb7fd9665fe1ae4b7d891b5fac4c9f817f0c6c7e23789b56d3f5e86f995a1b85b7b9d3ff00d5fdb15959959beefdd6665ddf2b57b26adfb1af866ff54d5ae2cf5ad474a86e17758db470acd0d9b6df9b76e666923ddbbf8be556fe2dbbaaf7c13b5d3e5d435af16786af9adbc3fe22b3559b496fbd63a94723332fcbfecb36d6fe256a6fc74f8fbe20f855e24b3d3f4bd2edbecba868f24cb773fcdb6eb7796acbfde58d57eeff0016e5a5cd294bdd1f2c6313cfe4fd8efc4da7c7a5f9bae691146d1c9f6eb991a4f2ede4f33f76b1aeddd22b2f97f37f0b6efe1af66b7fb57c0af80f6f25e5ac7a86a1a3e92cb756cdba68dae199be56ff00a62ad26d6ff66b8bf0cfed7da3df4d671eb76b2e991ae92d25c4f1c2d27fc4c964ff00571ed6ff0052d1aff17f136d6fef57a72f8ebc2ff11bc0baa5be8dae5ab4dab58c96b1ab6d5923b8b8b7936c7246dfc4db5be5ff0065aa5f37da14797ec9f1bfc2bf8691fc62f176b5a1d9df268ba8369b797da5da471fee64b88d9596dffbcb1ed66ff776ad73b6f178dbe104327889747bad22d6ea15b192e67b7dd0c8b347e62c7fef7cbff0168d96bdbbf63d692593566b8d165b9b1b368750b3d53cbfddd8df2c6cacbe67de5692193fe05b7e6af54f8b179a7ea90ea5a6c7756ba84762cb63711b48b279322dbb6e5917fbdf3337f96ad1cf965ca118731f9b9f12b583e21d76d7559583dddcd9c2d74fff003d268d7c9693fde6f2d59bfda6ae5ebd13e3c7866d7c39e28d3bec11f95637162be5aafdd565fddb2ffe3aadff0002af38aeea7f09c338f2cbde1cd51b539bbd46d5649774cb1924d2eeae5597cbb79155bfdadcdb6bd6362cff0009ed1a01e722dbc3e73cadf32fef36b6dff75b6aff00bb5e77a1c711f03eb61f7f9cb3c3b76ff7b72edffd9abd97e15f8574ff0016fc3db7b3ba69e0b3dccb234727972348b26edcadf776ad6529729bd38f37ba49e19f8d9ac787e1d163b7b7b368ec6cdace48278f74770bf755bfbcbb5557eeb7deff007ab72ebe2afc42f1e6d8f4e5bc665d41648ffb26dd99a391bfd5c3bb6fdd5f99b6b7f79b7576da2fc16f0adadd5f5e5d69fe569ecd1de2acf27cb6ecbf7635ddfc3bbfbdf7b77fb35eada1cba0e87aa2e87a4de5b58df4d6bf6c5b1b69be66fbbfbcf2ff00899bfefadbfecd724a71fb313ae30a9d647cd7f0c759d5349f8c5e1d8756bebeb165bc6b79239e465ff59bbe5ff75a4dbfecb5765fb51783ee2e21d1fc5497514abb574792c5bef6edd248acadfc4bf795bfbb5cefc6ef16ad87c6ab1d51ace56bad1e1b192e236f97ce68dbccfddffb3b5957fde5af46fda934bb5baf00e8b756f6725cac77d1b46d1ee668619a166dacabfdedbb7fd965ff006a9fda8c85cba4a27ac6a967a1f8aad752d2f5186c753d3ec665fb55b4ecacb6b22aac8bbbfbbb57e6ff0076be51d69bfe1737c52b5d1fc350c763a4b37d96cf6c7b563b78ff00d65c32ff00babb957f8576ad72f7daa6ada5b6ad0dd4d7316a1a82edbc5b9dcb2346caacccdbbf89976ffc059abdcbe06e8767f0b7e1cea9f10b5c8d964ba87fd1e35ff59f67ddfbb55ff6a6936ffc076d2e5e48dc7cded3dd343f680f1559fc39f01e97f0ff00c39235b35c5bed9155be686cff008b77fb5336effc7abe655566658e28da5919b6c71aafccccdf7556b4bc45e20bef16ebd7dad6a5279b7d79279927f757fbaabfecaafcb5ec1fb2ef805756d726f166a31c6b63a7b34766d3fddfb47f149ff6cd7ff1e6ff0066abf85133fe2c8ebb50b8b5fd993e0ec30a7953f8bb546f9bfdab8dbf337fd73857ff001eff007abe5791a4b89249a59249e6919a492491b7348cdf799abb0f8b9e3e6f895e3cbed512466d2e16fb2e9eadfc36eadf7bfde91be6ff00812d7215505cbf11339737bb1195258e9b75acea16ba7d842d3df5e4cb6f6f1aff00148cdb56a3afa1bf655f86ff00bcbcf1f6acab6da7d9c7247a7c93fddfbade75c7fbaabb9777fbdfddaa9cb963cc4463cd2e52f7c4ebfb3f827f0b6c7c13a44dbb56be8648e6b95f95b6b7fae9bfe04db957fd9ff76ad7eca7e0b8f4b8f4fd6a78596f3549bf72ccbf76d5776ddbfef36e6ff80ad794df4b37c7df8c52345e645a7dd49f7bfe7df4f87f8bfde65ffc7a4afab3c1f147178ab49b7821582de16558e35fbaaaabf2affdf35cd2f76363ba1ef3e6fe53da214f956ad7da2389774b247042aad249248db5638d5773337fb2abf35578ea9dd44ba96a4d0cf0acfa6e9fb649a066f96f2f3e56b7b56fef46bfeba45ffae6adfddae5919997a86b31e9da1ea9aa6a8d1e9fa5c9a6b5c6a5777cd22b58d9edf323b78e3fe16dbb64919be6692455dbf2d6ff00837c40be36f07699e2111cf05adf58cd7d25b5c27efa3b7ba8d597747f7bef4327fdf5f2d7cb3fb6578a2fbc49e22f027c19d36fa696ff00c4f7f6f26ad227de7592e36c4adfef3ef936ff00b2b5f5ef8662b58a3d3752b28e3823b8926d2d5a3fe1856469ac9bfe03f32aff00bd4a51e58c6469197d93f1161ff531edfbbb6bdabf661f8fb6ff0001fc4dac5c5fe9f2ea1a5ea96be4ccb036d923655915597fefe354bfb5f7c3ad3fe1bfc70d52d74987ecba7ea90aead0db7f0dbb48d22c91affb3e62b6dfeeab6daf14db5ecfbb5a279bef5391f457ed71fb4b58fc7cf1269b6fe1cb7d42d341b38556692f55639350997eec8d1ab36d55dcdb773337ef1abc4e18b6ad64d9ff00ae5ad85a718c69c796244a5297bd2265a6c94b5149544987e20ff530ff00d74aa36bfeb2ad6bdf76dd7fe9a55185bf795406833543235399aa19280195b7a4daf951ff00b5f7ab1ed62f36e157f87f8aba4b75dab52059a753169fcd003d7b548b5053d7b5059617b5588eaac75623a0a265ab567f7aab7353dab7cd5059f767fc136f52dda4fc50d3777fabd434fbc55ffae96f246dff00a2ebed08ebe09ff8271ea9f67f883f1034dddff1f5a1d9dd2aff00d71ba923ff00dacb5f7a475e3623f8923aa9fc24fcd44dde8a1bbd6059f16b54325145769dc46d51b77a28ab0236a864a28a0a2ac955da8a2ac08dbbd46d45154490b542dde8a2ac8236a85a8a280236a6b77a28a082bffcb48ffdeaf91b596f3356d51ffbd7d70dff00919a8a2baa87c47062be146342bbae277ee9c2d437cdf2d145749e619f2547b68a2b1351adf2d490d145007ba7ec89042df15ae6fe55256c3c3bab5d050391fe8ad1e47ab6d91bad7df9a5df0f19fc23d135c8d4db472eac35cb789cee233772dc857f56f9c8a28af3711f11dd40fcc1f8d5219be3278edcff0016bd7dff00a39abd27f627d626d1ff00683f0fc16db7ed1ab5b5ee97048ea088e4960711b1ff0064328ce390a4e334515d73fe19847f887dede30f1949a2fc68f097c38b3478ee6cbc1a7576bf91fccf9be6f27048cef47cbef1b73c01804d6a68f7f1fdb2eb4e8108863b08f5cd3f7000ad8cf238fb3be3a3c722c8aac320c4ca0e0af2515e423d136a68d7cb3b78c74a6c710b88ca48892c728086395772babfcacadfecd1456e41f1cea371ff000cd5f1ea7b1d3de4bad06ee38646b4ce49b495be5439fe389b3b4f4da07a9ab7fb5efc2db3f0eea169e34d3cac1fda776b657f6ea31bee591dd275ff0079632241dd82b0ef4515b47e230fb27ceead4fa28aec31147cbd5987fbb5f6c7c21d7a1f8fff0006eff4cf1342d7135bca9a55f5c0c0695ca8686e13d1c6549cf52bee68a2b9eafc26d03c37e18f8e2fbe04fc54d4b44be63a9e97f6d5d33538adce3cd39023b98f38c4ab9079ec593a735dbfed45a7ccbf16fc2d06a77326a3a2cf676c21b4de6368a3790acc030fe262376efa0e80514566fe22fec9dd78e3f642f0d5af84b5a6f0dbdd5b6acb789258bdfde33c2a8ec8ad0c802e4ae096dc3e6dd5f3d4df0b35ab2bcf1ac42e6c43f84159ef9d6493f7aa391e57cbc9c7386da01e071cd145429323951ea3fb2a7f68e9be36d67c3af3a8b0d5fc349aab471b708e5f644d9c0f982b4991d0eeaf0efda52c65d07e3478acdbcf244f70b0ea334b1b90e1a7b5492403d7e695c0cf634515749b7395c753689e57f14bc631f8aacfc32cd1489756f6ccb732b11fbc7242ee5fc509fc6b85a28aef89c536dcb506ef4ce68a2824eb3c2732ff00c223e235d9b9923dcbbba0dcbb7fa9ad5d07c75ad693a51b1b2bf7b6b3109b7daa8bb955cb3b6d6fe1e5da8a283589ab1eadacf8b2f2edee6fe5b99ee6e208e6f3a5215c86458f803185c8c71c63815e91f0d7c3327847e3f697a46a2e971369f7934664b66215dd6375070c3383919e7b5145725d9a5dad8ecff6a2f07dcc1a8785b5a4bfdd1bc1168a913af29220de24f71fbce9ec7d4d7d1d670b7862cee27b8b892fa7b28bf7d3e0234cd1c6cc49038c36d6ce31d451456524b94eb8b7cf23e38f075b5c7c76f8b9136b737fc7fefbfbb55e9f678a3dcb027f74045541ff00023d6bbcfda97c5327f69695e13817c8b3b48a3bd902fdd766052151ec814ffdf5ec28a2abed911fe1f3753c2e1b57bebab7b58d82cb713476eacdd159db686fc0f35f45fc7ed617e17fc3dd13c0ba2235bc37f6ef6ef703a9b78d97ce07fda919b9ff0064b7f7a8a29d4fe24429fc323e695f956968a2ba8e6353c29e1d7f1778af43d022956de4d5aee3b65b86ff00966189258fa9001c7d16be95fda7bc4b1fc3ff0087da478334580da58df4261dc9ff002ced21003463fda738cffc0bfbd4515cb53f8915d0de9fc1222f82fe0883c1fe08b7d4642b36a9ae46972f347d2388f11c43d86371f56c7a0af52f02a993c5b62c4ff137fe82d451584be23b63a53d0f5b92e9ad6da6b84552f0c618238dca58b22ae7d81707fe0354bc47ac5a7c38d1f57b8b98e5bdb6f0fe9f2dedcba63ceb99195a699f9382cfb3a9f5c7400514563bc8e7e87e77fc06f1cea7f153f6ccf0df8af59757bfbbbf9b50da39588456af2451affb31aa22affbb5fa61e0d253c21a441804858995bd25880746fd08fc68a2b5c48a8ec7c27ff0526d1e0b3f8ade15be886d6b8d2ae2061ed1ddca57f4907e55f23d14576d0fe1c4e1a9fc425b55fde569474515d4644d51c945152073fae7fac83fe055463ff59451401699be5a859a8a2a80d1d2e11b777f7ab6d68a2a409169fcd145001cd2ad14505934756968a282a24b52dbb7ef28a2a0b3ea1fd812f0dafed0d2400656ebc357f13fbec96d9c7f23f9d7e8dc74515e462bf887553f84928a28ae62cfffd9	2026-05-29 11:21:10.602965+00	2026-05-29 11:21:10.602965+00
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (user_id, role_id) FROM stdin;
6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	ba1ae45e-7211-418e-91dd-2b28101edce7
b8182d83-750f-4a53-bb6b-2b49e37581b4	ba1ae45e-7211-418e-91dd-2b28101edce7
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (password_hash, full_name, phone, avatar_url, "position", locale, theme, is_active, is_superadmin, telegram_chat_id, notification_settings, id, created_at, updated_at, token_version) FROM stdin;
$2b$12$YHxEUGJzHgdaIYJyWmjetOehDd2hXCMERgC1xb/3lmpI6nLdoVNmO	Super Admin	+998901234567	\N	\N	uz	light	f	t	\N	{}	b8182d83-750f-4a53-bb6b-2b49e37581b4	2026-06-05 04:15:38.103745+00	2026-06-08 03:48:48.833351+00	1
$2b$12$awf/kOiyYeCRhre1zbZYNOsddQx2ypM.ZuFM2Ivv6Lb8kBQeJVFjm	Boss	+998 97 666 26 75	/api/v1/users/6bde8e45-7f53-495b-bb94-c18b8fb1bc6e/avatar	\N	uz	light	t	t	\N	{}	6bde8e45-7f53-495b-bb94-c18b8fb1bc6e	2026-05-29 11:14:47.009126+00	2026-06-08 03:49:00.290611+00	1
\.


--
-- Data for Name: vendor_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor_payments (vendor_id, date, amount, note, created_by_id, id, created_at, updated_at, receipt_id) FROM stdin;
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendors (name, phone, address, note, id, created_at, updated_at, user_id, is_active) FROM stdin;
\.


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: finance_categories finance_categories_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_categories
    ADD CONSTRAINT finance_categories_code_key UNIQUE (code);


--
-- Name: finance_categories finance_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_categories
    ADD CONSTRAINT finance_categories_pkey PRIMARY KEY (id);


--
-- Name: finance_transactions finance_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_pkey PRIMARY KEY (id);


--
-- Name: goods_receipts goods_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods_receipts
    ADD CONSTRAINT goods_receipts_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: payroll_items payroll_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_items
    ADD CONSTRAINT payroll_items_pkey PRIMARY KEY (id);


--
-- Name: payroll_runs payroll_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_runs
    ADD CONSTRAINT payroll_runs_pkey PRIMARY KEY (id);


--
-- Name: positions positions_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_name_key UNIQUE (name);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: salary_advances salary_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_advances
    ADD CONSTRAINT salary_advances_pkey PRIMARY KEY (id);


--
-- Name: salary_rates salary_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_rates
    ADD CONSTRAINT salary_rates_pkey PRIMARY KEY (id);


--
-- Name: service_categories service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_categories
    ADD CONSTRAINT service_categories_pkey PRIMARY KEY (id);


--
-- Name: service_tickets service_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_tickets
    ADD CONSTRAINT service_tickets_pkey PRIMARY KEY (id);


--
-- Name: service_visits service_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_visits
    ADD CONSTRAINT service_visits_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: telegram_orders telegram_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telegram_orders
    ADD CONSTRAINT telegram_orders_pkey PRIMARY KEY (id);


--
-- Name: attendance uq_employee_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT uq_employee_date UNIQUE (employee_id, work_date);


--
-- Name: exchange_rates uq_exchange_rate_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT uq_exchange_rate_date UNIQUE (date);


--
-- Name: user_avatars user_avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_avatars
    ADD CONSTRAINT user_avatars_pkey PRIMARY KEY (user_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendor_payments vendor_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_payments
    ADD CONSTRAINT vendor_payments_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: ix_attendance_employee_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attendance_employee_id ON public.attendance USING btree (employee_id);


--
-- Name: ix_attendance_work_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attendance_work_date ON public.attendance USING btree (work_date);


--
-- Name: ix_audit_logs_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_entity ON public.audit_logs USING btree (entity);


--
-- Name: ix_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: ix_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: ix_customers_full_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_customers_full_name ON public.customers USING btree (full_name);


--
-- Name: ix_customers_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_customers_phone ON public.customers USING btree (phone);


--
-- Name: ix_employees_full_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_employees_full_name ON public.employees USING btree (full_name);


--
-- Name: ix_exchange_rates_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_exchange_rates_date ON public.exchange_rates USING btree (date);


--
-- Name: ix_finance_transactions_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_finance_transactions_date ON public.finance_transactions USING btree (date);


--
-- Name: ix_finance_transactions_related_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_finance_transactions_related_order_id ON public.finance_transactions USING btree (related_order_id);


--
-- Name: ix_finance_transactions_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_finance_transactions_type ON public.finance_transactions USING btree (type);


--
-- Name: ix_goods_receipts_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_goods_receipts_date ON public.goods_receipts USING btree (date);


--
-- Name: ix_inventory_product_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_inventory_product_id ON public.inventory USING btree (product_id);


--
-- Name: ix_inventory_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_inventory_status ON public.inventory USING btree (status);


--
-- Name: ix_inventory_unique_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_inventory_unique_id ON public.inventory USING btree (unique_id);


--
-- Name: ix_items_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_items_name ON public.items USING btree (name);


--
-- Name: ix_items_vendor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_items_vendor_id ON public.items USING btree (vendor_id);


--
-- Name: ix_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: ix_order_items_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_order_items_order_id ON public.order_items USING btree (order_id);


--
-- Name: ix_orders_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_orders_code ON public.orders USING btree (code);


--
-- Name: ix_orders_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_customer_id ON public.orders USING btree (customer_id);


--
-- Name: ix_orders_delivered_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_delivered_at ON public.orders USING btree (delivered_at);


--
-- Name: ix_orders_order_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_order_date ON public.orders USING btree (order_date);


--
-- Name: ix_orders_priority; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_priority ON public.orders USING btree (priority);


--
-- Name: ix_orders_salesperson_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_salesperson_id ON public.orders USING btree (salesperson_id);


--
-- Name: ix_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_orders_status ON public.orders USING btree (status);


--
-- Name: ix_payments_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_payments_order_id ON public.payments USING btree (order_id);


--
-- Name: ix_payroll_items_run_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_payroll_items_run_id ON public.payroll_items USING btree (run_id);


--
-- Name: ix_products_model; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_products_model ON public.products USING btree (model);


--
-- Name: ix_products_product_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_products_product_type ON public.products USING btree (product_type);


--
-- Name: ix_salary_advances_advance_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_salary_advances_advance_date ON public.salary_advances USING btree (advance_date);


--
-- Name: ix_salary_advances_employee_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_salary_advances_employee_id ON public.salary_advances USING btree (employee_id);


--
-- Name: ix_salary_rates_effective_from; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_salary_rates_effective_from ON public.salary_rates USING btree (effective_from);


--
-- Name: ix_salary_rates_employee_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_salary_rates_employee_id ON public.salary_rates USING btree (employee_id);


--
-- Name: ix_service_categories_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_service_categories_name ON public.service_categories USING btree (name);


--
-- Name: ix_service_tickets_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_service_tickets_code ON public.service_tickets USING btree (code);


--
-- Name: ix_service_tickets_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_tickets_customer_id ON public.service_tickets USING btree (customer_id);


--
-- Name: ix_service_tickets_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_tickets_order_id ON public.service_tickets USING btree (order_id);


--
-- Name: ix_service_tickets_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_tickets_status ON public.service_tickets USING btree (status);


--
-- Name: ix_service_visits_ticket_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_service_visits_ticket_id ON public.service_visits USING btree (ticket_id);


--
-- Name: ix_stock_movements_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_stock_movements_item_id ON public.stock_movements USING btree (item_id);


--
-- Name: ix_telegram_orders_telegram_chat_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_telegram_orders_telegram_chat_id ON public.telegram_orders USING btree (telegram_chat_id);


--
-- Name: ix_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_phone ON public.users USING btree (phone);


--
-- Name: ix_vendor_payments_vendor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vendor_payments_vendor_id ON public.vendor_payments USING btree (vendor_id);


--
-- Name: ix_vendors_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vendors_name ON public.vendors USING btree (name);


--
-- Name: ix_vendors_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_vendors_user_id ON public.vendors USING btree (user_id);


--
-- Name: attendance attendance_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_entered_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_entered_by_id_fkey FOREIGN KEY (entered_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: customers customers_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: employees employees_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id) ON DELETE SET NULL;


--
-- Name: employees employees_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: files files_uploaded_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_uploaded_by_id_fkey FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: finance_categories finance_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_categories
    ADD CONSTRAINT finance_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.finance_categories(id) ON DELETE SET NULL;


--
-- Name: finance_transactions finance_transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: finance_transactions finance_transactions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.finance_categories(id) ON DELETE SET NULL;


--
-- Name: finance_transactions finance_transactions_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: finance_transactions finance_transactions_related_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_related_order_id_fkey FOREIGN KEY (related_order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: goods_receipts goods_receipts_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods_receipts
    ADD CONSTRAINT goods_receipts_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: goods_receipts goods_receipts_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods_receipts
    ADD CONSTRAINT goods_receipts_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE RESTRICT;


--
-- Name: goods_receipts goods_receipts_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods_receipts
    ADD CONSTRAINT goods_receipts_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE RESTRICT;


--
-- Name: inventory inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE RESTRICT;


--
-- Name: orders orders_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(id) ON DELETE SET NULL;


--
-- Name: orders orders_salesperson_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_salesperson_id_fkey FOREIGN KEY (salesperson_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: payroll_items payroll_items_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_items
    ADD CONSTRAINT payroll_items_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE RESTRICT;


--
-- Name: payroll_items payroll_items_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_items
    ADD CONSTRAINT payroll_items_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.payroll_runs(id) ON DELETE CASCADE;


--
-- Name: payroll_runs payroll_runs_approved_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_runs
    ADD CONSTRAINT payroll_runs_approved_by_id_fkey FOREIGN KEY (approved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payroll_runs payroll_runs_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payroll_runs
    ADD CONSTRAINT payroll_runs_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: positions positions_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: salary_advances salary_advances_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_advances
    ADD CONSTRAINT salary_advances_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: salary_advances salary_advances_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_advances
    ADD CONSTRAINT salary_advances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: salary_rates salary_rates_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_rates
    ADD CONSTRAINT salary_rates_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: salary_rates salary_rates_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_rates
    ADD CONSTRAINT salary_rates_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: service_tickets service_tickets_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_tickets
    ADD CONSTRAINT service_tickets_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: service_tickets service_tickets_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_tickets
    ADD CONSTRAINT service_tickets_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE RESTRICT;


--
-- Name: service_tickets service_tickets_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_tickets
    ADD CONSTRAINT service_tickets_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: service_visits service_visits_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_visits
    ADD CONSTRAINT service_visits_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.service_tickets(id) ON DELETE CASCADE;


--
-- Name: stock_movements stock_movements_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: telegram_orders telegram_orders_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telegram_orders
    ADD CONSTRAINT telegram_orders_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: user_avatars user_avatars_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_avatars
    ADD CONSTRAINT user_avatars_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vendor_payments vendor_payments_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_payments
    ADD CONSTRAINT vendor_payments_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: vendor_payments vendor_payments_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_payments
    ADD CONSTRAINT vendor_payments_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict AKxU8qamdggh0iqJvzmlqjSmaPFnK1RhEgNPciJBzPmbZwivbYxxaVPZYnHkML3

