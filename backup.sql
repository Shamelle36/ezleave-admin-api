--
-- PostgreSQL database dump
--

\restrict qm2U5tyDoaVGmDm0iCzRmMVvTgnYoa5801a7e7nW4j0cMzmB2HggEhcZDXtaacB

-- Dumped from database version 17.5 (aa1f746)
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: create_default_entitlements(); Type: FUNCTION; Schema: public; Owner: neondb_owner
--

CREATE FUNCTION public.create_default_entitlements() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    INSERT INTO leave_entitlements (employee_id, leave_type, year, total_days)

    SELECT NEW.id, lt.code, EXTRACT(YEAR FROM CURRENT_DATE)::INT, lt.default_days

    FROM leave_types lt;



    RETURN NEW;

END;

$$;


ALTER FUNCTION public.create_default_entitlements() OWNER TO neondb_owner;

--
-- Name: create_leave_credits_for_employee(); Type: FUNCTION; Schema: public; Owner: neondb_owner
--

CREATE FUNCTION public.create_leave_credits_for_employee() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

  INSERT INTO leave_credits (user_id, year)

  VALUES (NEW.user_id, EXTRACT(YEAR FROM CURRENT_DATE)::int);

  RETURN NEW;

END;

$$;


ALTER FUNCTION public.create_leave_credits_for_employee() OWNER TO neondb_owner;

--
-- Name: create_leave_entitlements(); Type: FUNCTION; Schema: public; Owner: neondb_owner
--

CREATE FUNCTION public.create_leave_entitlements() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    INSERT INTO leave_entitlements (user_id, leave_type, year, total_days)

    SELECT NEW.id, lt.code, EXTRACT(YEAR FROM CURRENT_DATE)::INT, lt.default_days

    FROM leave_types lt;



    RETURN NEW;

END;

$$;


ALTER FUNCTION public.create_leave_entitlements() OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_accounts; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.admin_accounts (
    id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    role character varying(50) NOT NULL,
    department character varying(150),
    password_hash text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    profile_picture text,
    CONSTRAINT admin_accounts_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'office_head'::character varying, 'mayor'::character varying])::text[])))
);


ALTER TABLE public.admin_accounts OWNER TO neondb_owner;

--
-- Name: admin_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.admin_accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_accounts_id_seq OWNER TO neondb_owner;

--
-- Name: admin_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.admin_accounts_id_seq OWNED BY public.admin_accounts.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.announcements (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    details text NOT NULL,
    priority character varying(50) DEFAULT 'Normal'::character varying,
    created_by integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    images text[]
);


ALTER TABLE public.announcements OWNER TO neondb_owner;

--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.announcements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.announcements_id_seq OWNER TO neondb_owner;

--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: attendance_logs; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.attendance_logs (
    id integer NOT NULL,
    pin character varying(50),
    name character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    attendance_date date,
    am_checkin timestamp without time zone,
    am_checkout timestamp without time zone,
    pm_checkin timestamp without time zone,
    pm_checkout timestamp without time zone,
    updated_at timestamp without time zone DEFAULT now(),
    user_id character varying(255)
);


ALTER TABLE public.attendance_logs OWNER TO neondb_owner;

--
-- Name: attendance_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.attendance_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_logs_id_seq OWNER TO neondb_owner;

--
-- Name: attendance_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.attendance_logs_id_seq OWNED BY public.attendance_logs.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    role character varying(50) NOT NULL,
    activity character varying(100) NOT NULL,
    details text,
    ip_address character varying(50),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO neondb_owner;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO neondb_owner;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: department; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.department (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.department OWNER TO neondb_owner;

--
-- Name: department_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.department_id_seq OWNER TO neondb_owner;

--
-- Name: department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.department_id_seq OWNED BY public.department.id;


--
-- Name: employee_list; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.employee_list (
    id integer NOT NULL,
    user_id character varying(255),
    id_number character varying(50),
    gender character varying(20),
    civil_status character varying(50),
    "position" character varying(255),
    department character varying(255),
    email character varying(255),
    address text,
    date_hired date,
    employment_status character varying(50) DEFAULT 'Active'::character varying,
    profile_picture text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_registered boolean DEFAULT false,
    first_name text,
    last_name text,
    contact_number character varying(50),
    status text,
    middle_name text
);


ALTER TABLE public.employee_list OWNER TO neondb_owner;

--
-- Name: employee_list_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.employee_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_list_id_seq OWNER TO neondb_owner;

--
-- Name: employee_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.employee_list_id_seq OWNED BY public.employee_list.id;


--
-- Name: leave_applications; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.leave_applications (
    id integer NOT NULL,
    user_id character varying(255),
    office_department character varying(255),
    "position" character varying(255),
    salary numeric(12,2),
    date_filing date NOT NULL,
    leave_type character varying(100) NOT NULL,
    details text,
    inclusive_dates daterange NOT NULL,
    number_of_days integer,
    commutation_requested boolean DEFAULT false,
    status character varying(50) DEFAULT 'Pending'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    first_name text,
    last_name text,
    middle_name text,
    approver_name text,
    approver_date date,
    attachment text,
    approved_by character varying(255),
    remarks text,
    subtype character varying(100),
    country character varying(100),
    office_head_id character varying(255),
    office_head_status character varying(50) DEFAULT 'Pending'::character varying,
    office_head_date timestamp without time zone,
    hr_id character varying(255),
    hr_status character varying(50) DEFAULT 'Pending'::character varying,
    hr_date timestamp without time zone,
    mayor_id character varying(255),
    mayor_status character varying(50) DEFAULT 'Pending'::character varying,
    mayor_date timestamp without time zone,
    office_head_signature text,
    hr_signature text,
    mayor_signature text
);


ALTER TABLE public.leave_applications OWNER TO neondb_owner;

--
-- Name: leave_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.leave_applications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_applications_id_seq OWNER TO neondb_owner;

--
-- Name: leave_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.leave_applications_id_seq OWNED BY public.leave_applications.id;


--
-- Name: leave_cards; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.leave_cards (
    id integer NOT NULL,
    employee_id integer,
    period text,
    particulars text,
    vl_earned numeric(8,3),
    vl_used character varying(50),
    vl_balance numeric(8,3),
    sl_earned numeric(8,3),
    sl_used character varying(50),
    sl_balance numeric(8,3),
    remarks text
);


ALTER TABLE public.leave_cards OWNER TO neondb_owner;

--
-- Name: leave_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.leave_cards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_cards_id_seq OWNER TO neondb_owner;

--
-- Name: leave_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.leave_cards_id_seq OWNED BY public.leave_cards.id;


--
-- Name: leave_credits; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.leave_credits (
    id integer NOT NULL,
    user_id text,
    year integer NOT NULL,
    vacation_earned integer DEFAULT 15,
    vacation_used integer DEFAULT 0,
    vacation_balance integer GENERATED ALWAYS AS ((vacation_earned - vacation_used)) STORED,
    sick_earned integer DEFAULT 15,
    sick_used integer DEFAULT 0,
    sick_balance integer GENERATED ALWAYS AS ((sick_earned - sick_used)) STORED,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.leave_credits OWNER TO neondb_owner;

--
-- Name: leave_credits_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.leave_credits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_credits_id_seq OWNER TO neondb_owner;

--
-- Name: leave_credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.leave_credits_id_seq OWNED BY public.leave_credits.id;


--
-- Name: leave_entitlements; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.leave_entitlements (
    id integer NOT NULL,
    user_id integer NOT NULL,
    leave_type text NOT NULL,
    year integer NOT NULL,
    total_days integer NOT NULL,
    used_days integer DEFAULT 0,
    balance_days integer GENERATED ALWAYS AS ((total_days - used_days)) STORED,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.leave_entitlements OWNER TO neondb_owner;

--
-- Name: leave_entitlements_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.leave_entitlements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_entitlements_id_seq OWNER TO neondb_owner;

--
-- Name: leave_entitlements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.leave_entitlements_id_seq OWNED BY public.leave_entitlements.id;


--
-- Name: leave_types; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.leave_types (
    id integer NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    is_accruable boolean DEFAULT false,
    default_days integer DEFAULT 0
);


ALTER TABLE public.leave_types OWNER TO neondb_owner;

--
-- Name: leave_types_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.leave_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_types_id_seq OWNER TO neondb_owner;

--
-- Name: leave_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.leave_types_id_seq OWNED BY public.leave_types.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    user_id character varying(255),
    receiver_id character varying(255),
    message text NOT NULL,
    "time" timestamp without time zone DEFAULT now(),
    pinned boolean DEFAULT false
);


ALTER TABLE public.messages OWNER TO neondb_owner;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO neondb_owner;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id character varying(255),
    message text NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO neondb_owner;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO neondb_owner;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: password_tokens; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.password_tokens (
    id integer NOT NULL,
    user_id integer,
    token character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean DEFAULT false,
    CONSTRAINT password_tokens_type_check CHECK (((type)::text = ANY ((ARRAY['setup'::character varying, 'reset'::character varying])::text[])))
);


ALTER TABLE public.password_tokens OWNER TO neondb_owner;

--
-- Name: password_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.password_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_tokens_id_seq OWNER TO neondb_owner;

--
-- Name: password_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.password_tokens_id_seq OWNED BY public.password_tokens.id;


--
-- Name: useradmin; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.useradmin (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password text NOT NULL,
    role character varying(50) DEFAULT 'admin'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    full_name text,
    profile_picture text
);


ALTER TABLE public.useradmin OWNER TO neondb_owner;

--
-- Name: useradmin_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.useradmin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.useradmin_id_seq OWNER TO neondb_owner;

--
-- Name: useradmin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.useradmin_id_seq OWNED BY public.useradmin.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.users (
    user_id character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    first_name character varying(255),
    last_name character varying(255)
);


ALTER TABLE public.users OWNER TO neondb_owner;

--
-- Name: admin_accounts id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admin_accounts ALTER COLUMN id SET DEFAULT nextval('public.admin_accounts_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: attendance_logs id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.attendance_logs ALTER COLUMN id SET DEFAULT nextval('public.attendance_logs_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: department id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.department ALTER COLUMN id SET DEFAULT nextval('public.department_id_seq'::regclass);


--
-- Name: employee_list id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.employee_list ALTER COLUMN id SET DEFAULT nextval('public.employee_list_id_seq'::regclass);


--
-- Name: leave_applications id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_applications ALTER COLUMN id SET DEFAULT nextval('public.leave_applications_id_seq'::regclass);


--
-- Name: leave_cards id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_cards ALTER COLUMN id SET DEFAULT nextval('public.leave_cards_id_seq'::regclass);


--
-- Name: leave_credits id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_credits ALTER COLUMN id SET DEFAULT nextval('public.leave_credits_id_seq'::regclass);


--
-- Name: leave_entitlements id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_entitlements ALTER COLUMN id SET DEFAULT nextval('public.leave_entitlements_id_seq'::regclass);


--
-- Name: leave_types id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_types ALTER COLUMN id SET DEFAULT nextval('public.leave_types_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: password_tokens id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.password_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_tokens_id_seq'::regclass);


--
-- Name: useradmin id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.useradmin ALTER COLUMN id SET DEFAULT nextval('public.useradmin_id_seq'::regclass);


--
-- Data for Name: admin_accounts; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.admin_accounts (id, full_name, email, role, department, password_hash, is_active, created_at, profile_picture) FROM stdin;
14	Clarence Amoyan	klarensdasekond@gmail.com	office_head	Sangguniang Bayan Office	$2b$10$qsTfsSkNkuaO4tsoOAcBguaTQUSMmwkaSbQfHmknKkSGIG6HDXi.K	t	2025-10-17 01:05:36.990345	\N
17	Shamelle Anne	shamelletadeja10@gmail.com	office_head	Office of the Municipal Mayor	$2b$10$fU/KksHJdXLcYHcRY3BEMOTChuucXwinizI7it.PODxGp9Tq9lGsi	t	2025-10-26 12:23:00.034039	https://res.cloudinary.com/dlrveckcz/image/upload/v1764042137/fdtwd7kdflownank8lsf.jpg
18	Michael Diaz	mellesha728@gmail.com	mayor	Office of the Municipal Mayor	$2b$10$oaKUuvyjm06nHYqkfJ8UI.t3IQTKSfc31I87WOgfLEWol1pX2MxGe	t	2025-11-07 01:38:07.899234	\N
\.


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.announcements (id, title, details, priority, created_by, created_at, updated_at, images) FROM stdin;
50	Baghot si gilliane	hsdahd		2	2025-11-09 00:07:58.482579	2025-11-09 00:11:00.479776	{{https://res.cloudinary.com/dlrveckcz/image/upload/v1762647059/announcements/1762647054024-2.png.png}}
51	Panget si gab	hahahaah		2	2025-11-09 00:12:12.565265	2025-11-09 00:12:12.565265	{{https://res.cloudinary.com/dlrveckcz/image/upload/v1762647131/announcements/1762647122283-IMG_20251108_161725_573.jpg.jpg}}
55	hahaha			2	2025-11-09 02:41:52.65303	2025-11-09 02:41:52.65303	{https://res.cloudinary.com/dlrveckcz/image/upload/v1762656109/announcements/1762656102509-Screenshot%202025-07-01%20091514.png.png,https://res.cloudinary.com/dlrveckcz/image/upload/v1762656109/announcements/1762656102525-Screenshot%202025-07-02%20150056.png.png,https://res.cloudinary.com/dlrveckcz/image/upload/v1762656111/announcements/1762656104836-Screenshot%202025-07-02%20170120.png.png}
56	Wala	I know		2	2025-11-09 04:38:47.998964	2025-11-09 04:38:47.998964	{https://res.cloudinary.com/dlrveckcz/image/upload/v1762663127/announcements/1762663114648-Screenshot%202025-07-20%20130347.png.png}
70				2	2025-11-09 11:04:49.253339	2025-11-09 11:04:49.253339	{https://res.cloudinary.com/dlrveckcz/image/upload/v1762686288/announcements/1762686286146-thinking-pictures-6emuk5lfn539b5zb.jpg.jpg}
71				2	2025-11-09 11:44:07.54874	2025-11-09 11:44:07.54874	{https://res.cloudinary.com/dlrveckcz/image/upload/v1762688645/announcements/1762688639409-young-woman-using-smart-phone-social-media-concept-free-photo.jpg.jpg,https://res.cloudinary.com/dlrveckcz/image/upload/v1762688645/announcements/1762688639472-30-best-side-dishes-76bad62.jpg.jpg}
\.


--
-- Data for Name: attendance_logs; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.attendance_logs (id, pin, name, created_at, attendance_date, am_checkin, am_checkout, pm_checkin, pm_checkout, updated_at, user_id) FROM stdin;
43	20210101	Reyland Tanglao	2025-10-12 03:58:40.328222	2025-10-12	2025-10-12 11:57:57	2025-10-12 12:00:14	2025-10-12 13:04:14	\N	2025-10-12 05:04:58.063186	user_32XnLpEUcAGjNDHLAkf4qz5kOE2
44	74264234	Clarence Amoyan	2025-10-12 03:59:24.793094	2025-10-12	2025-10-12 11:58:41	2025-10-12 12:00:46	2025-10-12 13:04:52	\N	2025-10-12 05:05:38.344819	\N
42	20232313	Sofia Cantos	2025-10-12 03:58:19.803553	2025-10-12	2025-10-12 11:57:36	2025-10-12 12:00:29	2025-10-12 13:05:03	\N	2025-10-12 05:05:49.361138	\N
52	74264234	Clarence Amoyan	2025-10-17 10:49:39.56597	2025-10-17	\N	\N	\N	2025-10-17 18:48:55	2025-10-17 10:49:39.56597	\N
53	20232313	Sofia Cantos	2025-10-17 10:53:41.245871	2025-10-17	\N	\N	\N	2025-10-17 18:52:57	2025-10-17 10:53:41.245871	\N
54	23984828	Angel Salgado	2025-10-17 12:33:03.57279	2025-10-17	\N	\N	\N	2025-10-17 20:32:18	2025-10-17 12:33:03.57279	\N
55	20210101	Reyland Tanglao	2025-10-18 00:34:48.600269	2025-10-18	2025-10-18 08:34:00	\N	\N	\N	2025-10-18 00:34:48.600269	user_32XnLpEUcAGjNDHLAkf4qz5kOE2
56	24747663	24747663	2025-10-18 00:35:04.620757	2025-10-18	2025-10-18 08:34:20	\N	\N	\N	2025-10-18 00:35:04.620757	\N
57	1	1	2025-10-18 02:16:29.540674	2025-10-18	2025-10-18 10:15:40	\N	\N	\N	2025-10-18 02:16:55.686974	\N
63	20210101	Reyland Tanglao	2025-10-26 12:05:27.975101	2025-10-26	\N	\N	\N	2025-10-26 20:04:43	2025-10-26 12:05:27.975101	user_32XnLpEUcAGjNDHLAkf4qz5kOE2
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.audit_logs (id, user_id, role, activity, details, ip_address, created_at) FROM stdin;
137	2	admin	Logout	User logged out	::1	2025-10-12 05:06:26.10594
138	2	admin	Login	Successful login	::1	2025-10-17 01:04:13.192401
140	2	admin	Login	Successful login	::1	2025-10-17 05:00:53.425759
141	2	admin	Logout	User logged out	::1	2025-10-17 14:38:50.497171
142	2	admin	Login	Successful login	::1	2025-10-17 23:38:54.391535
143	2	admin	Logout	User logged out	::1	2025-10-26 11:34:12.678561
145	2	admin	Logout	User logged out	::1	2025-10-26 11:35:25.479885
146	2	admin	Failed Login	Incorrect password	::1	2025-10-26 11:35:32.342749
148	2	admin	Login	Successful login	::1	2025-10-26 12:18:05.919036
149	2	admin	Logout	User logged out	::1	2025-10-26 12:29:16.553435
152	2	admin	Login	Successful login	::1	2025-10-30 10:35:11.864895
153	2	admin	Logout	User logged out	::1	2025-11-07 00:41:22.941828
154	2	admin	Failed Login	Incorrect password	::1	2025-11-07 00:41:30.548513
156	2	admin	Login	Successful login	::1	2025-11-07 01:26:52.262601
157	2	admin	Logout	User logged out	::1	2025-11-07 01:45:41.841061
158	2	admin	Failed Login	Incorrect password	::1	2025-11-07 01:45:54.94866
160	2	admin	Login	Successful login	::1	2025-11-07 02:07:46.245602
161	2	admin	Logout	User logged out	::1	2025-11-07 02:38:19.855081
162	2	admin	Failed Login	Incorrect password	::1	2025-11-07 02:38:27.511055
165	2	admin	Logout	User logged out	::1	2025-11-07 02:49:15.018199
166	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-07 02:49:22.632447
170	2	admin	Login	Successful login	::1	2025-11-07 02:52:47.295678
171	2	admin	Logout	User logged out	::1	2025-11-07 02:57:04.777056
172	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-07 02:57:14.711109
174	2	admin	Failed Login	Incorrect password	::1	2025-11-07 03:10:26.590892
177	2	admin	Logout	User logged out	::1	2025-11-07 03:21:05.397485
178	2	admin	Failed Login	Incorrect password	::1	2025-11-07 03:21:14.719236
181	2	admin	Logout	User logged out	::1	2025-11-07 03:22:49.292782
182	2	admin	Failed Login	Incorrect password	::1	2025-11-07 03:22:56.006382
184	2	admin	Failed Login	Incorrect password	::1	2025-11-07 03:27:19.852412
187	2	admin	Logout	User logged out	::1	2025-11-07 07:57:03.685952
188	2	admin	Failed Login	Incorrect password	::1	2025-11-07 07:57:10.753954
196	2	admin	Login	Successful login	::1	2025-11-07 08:09:46.703509
197	2	admin	Logout	User logged out	::1	2025-11-07 08:10:25.770245
198	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-07 08:10:33.811536
200	2	admin	Failed Login	Incorrect password	::1	2025-11-07 08:15:45.571665
203	2	admin	Logout	User logged out	::1	2025-11-07 08:16:21.531395
204	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-07 08:16:29.305198
206	2	admin	Login	Successful login	::1	2025-11-08 23:55:35.046835
208	2	admin	UPDATE ANNOUNCEMENT	Updated announcement: "Baghot si gilliane"	::1	2025-11-09 00:10:34.52571
209	2	admin	UPDATE ANNOUNCEMENT	Updated announcement: "Baghot si gilliane"	::1	2025-11-09 00:11:00.973746
210	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "Panget si gab"	::1	2025-11-09 00:12:12.74662
212	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "wala"	::1	2025-11-09 02:23:23.46727
215	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "Wala"	::1	2025-11-09 04:38:49.021653
216	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 04:42:19.051698
217	2	admin	UPDATE ANNOUNCEMENT	Updated announcement: ""	::1	2025-11-09 04:44:04.391125
218	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 04:45:24.918559
219	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 04:45:55.729085
220	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 04:49:25.955052
221	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 04:51:09.083586
222	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 05:06:37.449016
223	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 05:06:53.040934
224	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 05:14:13.433194
225	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 05:14:33.359081
226	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 05:17:23.783129
227	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 06:05:43.711814
228	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 10:18:38.079503
229	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:18:58.550502
230	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 10:23:09.711193
231	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:27:19.878534
232	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:27:20.524297
240	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 11:04:36.95277
241	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 11:04:49.39693
242	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 11:44:08.838659
243	2	admin	Logout	User logged out	::1	2025-11-13 01:19:18.507942
244	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-13 01:19:25.205348
246	2	admin	Failed Login	Incorrect password	::1	2025-11-13 03:26:42.993745
249	2	admin	Logout	User logged out	::1	2025-11-13 03:27:29.883761
250	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-13 03:27:36.27409
252	2	admin	Failed Login	Incorrect password	::1	2025-11-13 04:29:49.893078
255	2	admin	Logout	User logged out	::1	2025-11-13 04:30:28.895665
256	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-13 04:30:36.358122
258	2	admin	Failed Login	Incorrect password	::1	2025-11-15 16:26:23.811827
261	2	admin	Logout	User logged out	::1	2025-11-15 16:27:09.53708
262	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-15 16:27:20.467235
139	2	admin	Logout	User logged out	::1	2025-10-17 01:11:05.77041
144	2	admin	Login	Successful login	::1	2025-10-26 11:34:22.749141
150	2	admin	Failed Login	Incorrect password	::1	2025-10-26 12:29:37.640602
164	2	admin	Login	Successful login	::1	2025-11-07 02:44:30.254166
168	2	admin	Failed Login	Incorrect password	::1	2025-11-07 02:50:10.619017
91	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 09:34:28.149747
92	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 09:43:04.638469
93	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 09:45:03.932781
176	2	admin	Login	Successful login	::1	2025-11-07 03:12:59.303347
97	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 09:56:50.698243
180	2	admin	Login	Successful login	::1	2025-11-07 03:22:27.933426
186	2	admin	Login	Successful login	::1	2025-11-07 03:27:35.094824
101	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 10:15:01.989935
190	2	admin	Login	Successful login	::1	2025-11-07 08:04:40.715877
191	2	admin	Logout	User logged out	::1	2025-11-07 08:05:05.612956
105	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 10:15:42.802154
192	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-07 08:05:57.939151
194	2	admin	Failed Login	Incorrect password	::1	2025-11-07 08:09:20.790277
109	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 12:24:53.947073
202	2	admin	Login	Successful login	::1	2025-11-07 08:16:09.147599
207	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "hhaha"	::1	2025-11-09 00:07:58.632633
113	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 12:32:10.85247
211	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "wala"	::1	2025-11-09 02:23:23.466731
213	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "wala"	::1	2025-11-09 02:23:25.056961
214	2	admin	CREATE ANNOUNCEMENT	Posted announcement: "hahaha"	::1	2025-11-09 02:41:52.885897
117	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-11 12:46:04.7699
233	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:27:33.964056
234	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 10:37:37.073067
235	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:39:53.983368
121	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-12 00:49:37.261314
236	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 10:49:48.705595
237	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:50:37.469589
238	2	Admin	DELETE ANNOUNCEMENT	Deleted announcement: ""	::1	2025-11-09 10:53:06.800715
125	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-12 01:07:20.052015
239	2	admin	CREATE ANNOUNCEMENT	Posted announcement: ""	::1	2025-11-09 10:56:31.495778
127	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:44:01.4459
128	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:44:05.976008
129	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:44:14.022699
130	\N	unknown	Failed Login	No account found for reylandtanglao2@gmail.com	::1	2025-10-12 02:44:28.046194
132	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:44:38.940419
133	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:45:58.765677
134	\N	unknown	Failed Login	No account found for shamelletadeja10@gmail.com	::1	2025-10-12 02:46:05.488292
135	2	admin	Signup	Admin shamelletadeja10@gmail.com registered	::1	2025-10-12 02:46:59.537034
136	2	admin	Login	Successful login	::1	2025-10-12 02:47:09.356481
248	2	admin	Login	Successful login	::1	2025-11-13 03:27:15.219189
254	2	admin	Login	Successful login	::1	2025-11-13 04:30:12.219783
260	2	admin	Login	Successful login	::1	2025-11-15 16:26:56.480074
264	2	admin	Failed Login	Incorrect password	::1	2025-11-16 00:46:42.789159
266	2	admin	Login	Successful login	::1	2025-11-16 00:47:10.290305
267	2	admin	Logout	User logged out	::1	2025-11-16 00:47:23.467752
268	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-16 00:47:29.807828
270	2	admin	Failed Login	Incorrect password	::1	2025-11-16 01:52:27.103936
272	2	admin	Login	Successful login	::1	2025-11-16 01:52:47.609114
273	2	admin	Logout	User logged out	::1	2025-11-16 01:52:59.831408
274	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-16 01:53:05.58172
276	2	admin	Failed Login	Incorrect password	::1	2025-11-16 02:03:15.696097
278	2	admin	Login	Successful login	::1	2025-11-16 02:03:33.945025
279	2	admin	Logout	User logged out	::1	2025-11-16 02:03:55.114855
280	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-16 02:04:05.997201
282	2	admin	Failed Login	Incorrect password	::1	2025-11-16 02:17:25.107247
284	2	admin	Login	Successful login	::1	2025-11-16 02:17:47.406972
285	2	admin	Logout	User logged out	::1	2025-11-16 02:17:59.181958
286	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-16 02:18:07.17355
288	2	admin	Failed Login	Incorrect password	::1	2025-11-18 02:32:33.851403
290	2	admin	Login	Successful login	::1	2025-11-19 03:20:32.878012
291	2	admin	Logout	User logged out	::1	2025-11-19 03:21:24.187904
292	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-19 03:21:33.218236
294	2	admin	Login	Successful login	::1	2025-11-19 03:30:39.865801
295	2	admin	Login	Successful login	::ffff:192.168.254.102	2025-11-19 04:09:36.658598
296	2	admin	Logout	User logged out	::ffff:192.168.254.102	2025-11-19 04:15:15.287648
297	2	admin	Logout	User logged out	::1	2025-11-19 04:15:36.102601
298	2	admin	Login	Successful login	::ffff:192.168.254.102	2025-11-19 05:12:28.259124
299	2	admin	Login	Successful login	::1	2025-11-23 01:02:49.845779
300	2	admin	Login	Successful login	::ffff:10.242.224.6	2025-11-23 01:49:15.354704
301	2	admin	Logout	User logged out	::ffff:10.242.224.6	2025-11-23 01:52:55.374687
302	2	admin	Failed Login	Incorrect password	::ffff:10.242.224.6	2025-11-23 01:55:49.745471
303	2	admin	Login	Successful login	::ffff:10.242.224.6	2025-11-23 01:55:57.995272
304	2	admin	Login	Successful login	::1	2025-11-23 15:14:15.782099
305	2	admin	Login	Successful login	::ffff:10.242.224.6	2025-11-23 15:16:38.105774
306	2	admin	Login	Successful login	::ffff:10.242.224.212	2025-11-24 00:44:02.472914
307	2	admin	Logout	User logged out	::1	2025-11-25 03:41:43.591903
308	2	admin	Failed Login	Incorrect password	::1	2025-11-25 03:41:56.620712
310	2	admin	Login	Successful login	::1	2025-11-25 06:49:10.167736
311	2	admin	Logout	User logged out	::1	2025-11-25 07:29:56.566521
312	2	admin	Failed Login	Incorrect password	::1	2025-11-25 07:30:05.106821
314	2	admin	Login	Successful login	::1	2025-11-25 08:46:38.93366
315	2	admin	Logout	User logged out	::1	2025-11-25 09:08:43.080594
316	2	admin	Failed Login	Incorrect password	::1	2025-11-25 09:08:49.610997
318	2	admin	Login	Successful login	::1	2025-11-25 09:10:14.735617
319	2	admin	Logout	User logged out	::1	2025-11-25 09:23:17.866539
320	2	admin	Failed Login	Incorrect password	::1	2025-11-25 09:23:24.706493
322	2	admin	Failed Login	Incorrect password	::1	2025-11-25 09:32:35.064874
324	2	admin	Login	Successful login	::1	2025-11-25 09:33:14.681294
325	2	admin	Logout	User logged out	::1	2025-11-25 09:48:20.72154
326	2	admin	Failed Login	Incorrect password	::1	2025-11-25 09:48:27.02974
328	2	admin	Login	Successful login	::1	2025-11-25 09:49:16.576119
329	2	admin	Logout	User logged out	::1	2025-11-25 09:50:43.150942
330	2	admin	Failed Login	Incorrect password	::1	2025-11-25 09:50:53.187656
332	2	admin	Login	Successful login	::1	2025-11-25 11:24:32.750969
333	2	admin	Logout	User logged out	::1	2025-11-25 14:12:53.461931
334	2	admin	Failed Login	Incorrect password	::1	2025-11-25 14:13:01.053699
336	2	admin	Login	Successful login	::1	2025-11-25 14:29:28.246368
337	2	admin	Logout	User logged out	::1	2025-11-25 14:53:15.256706
338	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-25 14:53:25.157433
340	2	admin	Failed Login	Incorrect password	::1	2025-11-25 15:17:02.224671
342	2	admin	Login	Successful login	::1	2025-11-25 15:18:02.663641
343	2	admin	Logout	User logged out	::1	2025-11-25 15:19:03.085144
344	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-25 15:19:14.1524
346	2	admin	Failed Login	Incorrect password	::1	2025-11-26 01:52:48.165446
348	2	admin	Failed Login	Incorrect password	::1	2025-11-26 01:54:00.237162
349	2	admin	Login	Successful login	::1	2025-11-26 01:54:09.245491
350	2	admin	Logout	User logged out	::1	2025-11-26 01:55:17.287176
351	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 01:55:41.063582
353	2	admin	Failed Login	Incorrect password	::1	2025-11-26 02:10:26.584409
355	2	admin	Login	Successful login	::1	2025-11-26 02:11:11.519902
356	2	admin	Logout	User logged out	::1	2025-11-26 02:11:43.734811
357	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 02:11:53.03981
359	2	admin	Failed Login	Incorrect password	::1	2025-11-26 02:13:43.23768
361	2	admin	Login	Successful login	::1	2025-11-26 02:14:47.992896
362	2	admin	Logout	User logged out	::1	2025-11-26 02:15:47.703471
363	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 02:16:40.913208
365	2	admin	Login	Successful login	::1	2025-11-26 04:12:58.255296
366	2	admin	Logout	User logged out	::1	2025-11-26 07:26:16.573158
367	2	admin	Failed Login	Incorrect password	::1	2025-11-26 07:26:26.241451
369	2	admin	Login	Successful login	::1	2025-11-26 07:28:07.647755
370	2	admin	Logout	User logged out	::1	2025-11-26 07:28:44.880009
371	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 07:28:52.528663
372	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 07:28:58.140651
374	2	admin	Failed Login	Incorrect password	::1	2025-11-26 07:31:48.247956
376	2	admin	Login	Successful login	::1	2025-11-26 07:33:01.534432
377	2	admin	Logout	User logged out	::1	2025-11-26 07:33:47.575666
378	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 07:33:55.825315
380	2	admin	Failed Login	Incorrect password	::1	2025-11-26 10:00:34.604878
382	2	admin	Login	Successful login	::1	2025-11-26 10:34:17.582898
383	2	admin	Logout	User logged out	::1	2025-11-26 10:44:30.970578
384	2	admin	Failed Login	Incorrect password	::1	2025-11-26 10:44:40.991266
386	2	admin	Login	Successful login	::1	2025-11-26 11:33:17.268549
387	2	admin	Logout	User logged out	::1	2025-11-26 11:46:50.366533
388	2	admin	Failed Login	Incorrect password	::1	2025-11-26 11:47:04.104401
390	2	admin	Login	Successful login	::1	2025-11-26 13:07:19.062854
391	2	admin	Logout	User logged out	::1	2025-11-26 13:09:05.074042
392	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 13:09:17.088921
394	2	admin	Failed Login	Incorrect password	::1	2025-11-26 14:33:40.141303
396	2	admin	Login	Successful login	::1	2025-11-26 14:35:00.908833
397	2	admin	Logout	User logged out	::1	2025-11-26 14:35:42.147092
398	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 14:35:48.998224
399	\N	unknown	Failed Login	No account found for mellesha728@gmail.com	::1	2025-11-26 14:35:54.917633
401	2	admin	Failed Login	Incorrect password	::1	2025-11-26 14:49:20.101278
403	2	admin	Login	Successful login	::1	2025-11-26 14:55:24.377456
\.


--
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.department (id, name, description, created_at, updated_at) FROM stdin;
1	Human Resource Management	Hr	2025-08-18 10:24:01.466391	2025-08-18 10:24:01.466391
\.


--
-- Data for Name: employee_list; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.employee_list (id, user_id, id_number, gender, civil_status, "position", department, email, address, date_hired, employment_status, profile_picture, created_at, updated_at, is_registered, first_name, last_name, contact_number, status, middle_name) FROM stdin;
31	user_337kIzlBTqnt9eHoXkPXAwdXqp8	30348234	Female	Married	Staff	Municipal Social Welfare and Development Office	mellesha728@gmail.com	\N	2025-09-20	Active	\N	2025-09-20 12:12:57.184958	2025-10-18 00:27:39.939899	t	Celia	Cabagay	09374762343	active	\N
29	\N	74264234	Male	Single	Staff	Office of the Municipal Agriculturist	clarenceamoyan23@gmail.com	\N	2025-09-12	Active	\N	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569	f	Clarence	Amoyan	09934734723	active	\N
1802	\N	\N	Female	MARRIED	Engineering Support Staff	Municipal Engineering Office	louiellaenconado@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.258594	2025-11-26 05:05:48.812154	f	LOUIELLA ZEHN	ENCONADO	9158328985	active	\N
19	user_34bLHXnQoaRKUune6CfsSgzBTtp	20250905	Female		Staff	Human Resource Management Division	shamelletadeja10@gmail.com	\N	2025-09-11	Permanent	https://res.cloudinary.com/dlrveckcz/image/upload/v1761477478/arwsvdzoluyty1qk14aj.jpg	2025-09-05 07:06:36.467383	2025-10-30 10:52:14.32762	t	Shamelle 	Tadeja	09062380886	active	\N
23	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	20210101	Male	Single	Staff	Office of the Municipal Mayor	reylandtanglao2@gmail.com	\N	2025-09-11	Permanent	https://res.cloudinary.com/dlrveckcz/image/upload/v1759478243/b8mpkrq69f1kiqjdzaqr.jpg	2025-09-11 02:40:03.543155	2025-10-30 10:52:28.078124	t	REYLAND	TANGLAO	09066769097	active	Sanchez
1945	user_34oTu5GqoNrNVwxp76cVuw5EeKB	23222434	Female	Single	Staff	Office of the Municipal Mayor	sofiacantos325@gmail.com	\N	2025-10-01	Permanent	https://res.cloudinary.com/dlrveckcz/image/upload/v1763255049/rphjmxmcvtwt88suduyg.jpg	2025-10-31 02:48:12.127514	2025-11-16 01:04:10.153145	t	Sofia	Cantos	09123343444	active	\N
1912	\N	\N	Male	MARRIED	MESSENGER	Sangguniang Bayan Office	gereneterrenal@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.347585	2025-11-26 04:32:07.97355	f	GERENE	TERRENAL	9951300115	active	\N
1830	\N	19921201	Male	MARRIED	MPDC	Municipal Planning and Development Office	erwingaupo1966@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.151453	2025-11-26 04:53:34.800071	f	MANUEL ERWIN	GAUPO	9776077854	active	\N
1827	\N	\N	Male	SINGLE	Clerk	Municipal Environment and Natural Resources Office	joycebellebautista838@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:47.909447	2025-11-26 04:54:06.440876	f	JOYCEBELLE	BAUTISTA	9358381536	active	\N
1812	\N	\N	Female	SINGLE	CLERK	Municipal Public Employment Service Office	nu├▒ezmicaella1@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:46.250758	2025-11-26 04:58:01.403683	f	MICAELLA	NU├æEZ	9654893269	active	\N
28	\N	23984828	Female	Single	Staff	Municipal Environment and Natural Resources Office	angel@gmail.com	\N	2025-09-11	Active	\N	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702	f	Angel	Salgado	93822842842	active	\N
25	\N	20230678	Male	Single	Staff	Municipal General Services Office	retuya@gmail.com	\N	2025-09-12	Active	\N	2025-09-11 02:58:11.319832	2025-09-12 05:25:23.653548	f	Renz 	Retuya	09009238273	active	\N
1871	\N	\N	Male	MARRIED	IP FOCAL PERSON	Office of the Municipal Mayor	clayfordray2023@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:52.098	2025-11-26 04:36:27.881685	f	CLAY FORD RAY	TAGUMPAY	9369107634	active	\N
1869	\N	\N	Male	SINGLE	Public Relations Assistant	Office of the Municipal Mayor	jhorylgamboa02@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.89339	2025-11-26 04:36:37.272049	f	JHORYL	GAMBOA	9455625060	active	\N
1868	\N	\N	Female	SINGLE	MYDO Focal Person	Office of the Municipal Mayor	aprilvillasaguilar01@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.804983	2025-11-26 04:36:44.751825	f	APRIL	AGUILAR	9054202797	active	\N
1867	\N	\N	Female	SINGLE	MPIO Focal Person	Office of the Municipal Mayor	alfaroangelicajane25@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.724701	2025-11-26 04:36:50.591781	f	ANGELICA JANE	ALFARO	9356379064	active	\N
1866	\N	\N	Male	SINGLE	Tourism Focal Person	Office of the Municipal Mayor	gajetobonandrian@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.573863	2025-11-26 04:36:56.661562	f	BON ANDRIAN	GAJETO	9262920922	active	\N
1865	\N	\N	Female	SINGLE	Clerk	Office of the Municipal Mayor	saleslovely96@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.489778	2025-11-26 04:37:44.532115	f	LOVELY	SALES	9953587042	active	\N
1863	\N	20240910	Female	SINGLE	Administrative Aide I	Municipal General Services Office	charishmariano1998@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.332644	2025-11-26 04:38:29.152116	f	CHARISH JOY	MARIANO	9553296570	active	\N
1862	\N	20230707	Female	MARRIED	Administrative Aide IV	Municipal General Services Office	pobletejenny8@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.197983	2025-11-26 04:38:34.56176	f	JENNY	POBLETE	9537115635	active	\N
1859	\N	\N	Female	SINGLE	Clerk	Municipal General Services Office	sunshinetupas19@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.958774	2025-11-26 04:39:43.282822	f	SUNSHINE	TUPAS	9658857195	active	\N
1858	\N	\N	Female	SINGLE	Procurement Management Staff	Municipal General Services Office	janefranco0718@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.80686	2025-11-26 04:39:51.083746	f	BABY JANE	FRANCO	9755244801	active	\N
1857	\N	\N	Female	SINGLE	Property Management Encoder	Municipal General Services Office	katedelara24@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.723771	2025-11-26 04:39:57.811776	f	KATE	DE LARA	9352820221	active	\N
1856	\N	\N	Male	SINGLE	Property Management Assistant	Municipal General Services Office	johnziond@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.650177	2025-11-26 04:40:07.523255	f	JOHN ZION	DUE├æAS	9168527590	active	\N
1855	\N	\N	Female	SINGLE	Inventory Management Staff	Municipal General Services Office	idiomaaizelm@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.578293	2025-11-26 04:40:15.062122	f	AIZEL	IDIOMA	9676810006	active	\N
1854	\N	\N	Female	SINGLE	Property Management Clerk	Municipal General Services Office	amasangkay97@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.445107	2025-11-26 04:40:21.092639	f	ANGELICA	MASANGKAY	9264900078	active	\N
1853	\N	\N	Female	SINGLE	Clerk	Municipal General Services Office	Julieanneugeniovillas@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.330835	2025-11-26 04:40:39.091678	f	JULIE ANN	VILLAS	9363938443	active	\N
1860	\N	\N	Female	MARRIED	Administrative Aide III	MO - GSO	paguagansusan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167	f	SUSAN	PAGUAGAN	9663595248	active	\N
1861	\N	20230605	Female	MARRIED	Planning Officer III/Acting MGSO	MPDO - GSO	rhdelossantos@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067	f	ROSANA	FINEZA	9171782528	active	\N
1864	\N	20230604	Female	SINGLE	Administrative Officer II (HRMO I)	Office of the Municipal Mayor (OMM)	insigne.patricia@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568	f	PATRICIA MAE	INSIGNE	9154110707	active	\N
1870	\N	\N	Female	SINGLE	Clerk/Encoder	OMM - DILG	dianne.paglicawan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685	f	DIANNE CYRIL	PAGLICAWAN	9457084206	active	\N
1872	\N	20241113	Female	MARRIED	Tourism Operations Officer I	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	princesstamayo0316@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993	f	PRINCESS ROSE	PEDRAZA	9272871969	active	\N
1873	\N	20170103	Female	MARRIED	Administrative Aide I	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	delararomaris@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889	f	ROMARIS	DE LARA	9692445636	active	\N
1852	\N	\N	Female	SINGLE	Property Management Staff	Municipal General Services Office	gabreignpoblete1322@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.255999	2025-11-26 04:40:48.310921	f	LORRIENE	POBLETE	9268450568	active	\N
1851	\N	\N	Female	SINGLE	Clerk	Municipal Budget Office	jayamaepaguagan149@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:50.181888	2025-11-26 04:41:00.644275	f	JAYA MAE	PAGUAGAN	9553290344	active	\N
1850	\N	\N	Female	SINGLE	Clerk	Municipal Budget Office	angeluzalfaro07@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:50.069697	2025-11-26 04:46:15.914317	f	ANGELUZ	ALFARO	9655744716	active	\N
1849	\N	\N	Female	MARRIED	Administrative Assistant	Municipal Budget Office	krisselletadeja021217@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.987703	2025-11-26 04:46:22.103287	f	KRISSELLE	VICENTE	9167040246	active	\N
1848	\N	20161006	Female	MARRIED	Administrative Aide IV	Municipal Budget Office	reinatinaliga01@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.89894	2025-11-26 04:47:24.301382	f	REINA	TINALIGA	9660226844	active	\N
1790	\N	20230606	Male	MARRIED	Administrative Officer IV (HRMO II)	OMM - HRM Division	vicente1031jorel@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026	f	JOREL	VICENTE	9978833706	active	\N
1791	\N	20170101	Female	MARRIED	Administrative Aide I	MO - BPLO - HRM Division	cajayonm500@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234	f	MAYLIN	CAJAYON	9663595245	active	\N
1792	\N	20211005	Male	MARRIED	Administrative Assistant I (RMO I)	OMM - HRM Division	vexter888@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797	f	VEXTER	VILLAROZA	9365016583	active	\N
1793	\N	20241215	Female	SINGLE	Market Inspector I	OMM - HRM Division	evangelinepaglicawan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068	f	EVANGELINE	PAGLICAWAN	9953532904	active	\N
1794	\N	\N	Female	SINGLE	HRM Assistant	OMM - HRM Division	clarajanegdelara1997@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067	f	CLARA JANE	DE LARA	9269916080	active	\N
1795	\N	\N	Female	MARRIED	HRM Assistant	OMM -HRM Division	maptepico@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712	f	MARIE ANN	AUSTRIA	9531901700	active	\N
1796	\N	\N	Female	MARRIED	Messenger	OMM - HRM Division	jovelvhan051921@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934	f	VANISA	APARECIO	9756548185	active	\N
1804	\N	20020502	Male	MARRIED	Municipal Civil Registrar	MUNICIPAL CIVIL REGISTRAR OFFICE (MCRO)	falitfajardo67@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889	f	RONALD	FAJARDO	9664015049	active	\N
1805	\N	20241214	Female	MARRIED	Assistant Registration Officer	MCRO	gmenancio_aguilar@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162	f	GRACE MARIE	AGUILAR	9485517089	active	\N
1806	\N	20240104	Male	MARRIED	Administrative Aide I	MBO - MCRO	markdarienvillaluna@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702	f	MARK DARIEN	VILLALUNA	9614031180	active	\N
1807	\N	20161007	Female	WIDOWED	Administrative Aide I	MO - MCRO	luzmelbatagumpay@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871	f	LUZ MELBA	TAGUMPAY	9532789280	active	\N
1808	\N	\N	Female	SINGLE	CLERK	MCRO	dublinrechelle176@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837	f	RECHELLE ANN	DUBLIN	9536046450	active	\N
1809	\N	19980101	Female	MARRIED	PESO Manager	PUBLIC EMPLOYMENT SERVICE OFFICE (PESO)	jiegupilan@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646	f	JESSICA	GUPILAN	9213128418	active	\N
1815	\N	20241012	Female	MARRIED	Municipal Administrator	MO - OFFICE OF THE MUNICIPAL ADMINISTRATOR (OMAD)	omadpaluan5107@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937	f	CHARLOTTE JENNIFER	VALBUENA-PEDRAZA	9173202216	active	\N
1816	\N	\N	Female	SINGLE	Messenger	MO - OMAD	rbettymay@gmail. Com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223	f	BETTY MAY	ROBLES	9554469288	active	\N
1817	\N	\N	Female	SINGLE	Clerk	MO - OMAD	jolinamahinay43@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879	f	JOLINA	MAHINAY	9666006830	active	\N
1818	\N	\N	Female	MARRIED	Administrative Assistant	MO -OMAD	bernajoyuy12@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026	f	BERNAJOY	UY	9774454598	active	\N
1819	\N	19880701	Female	WIDOWED	Administrative Assistant III	MAO - MO	charlottevalbbuena0306@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437	f	ROSALIE	VALBUENA	9171462327	active	\N
1824	\N	19950302	Male	MARRIED	Registration Officer IV/Acting MENRO	MCR - MUNICIPAL ENVIRONMENT AND NATURAL RESOURCES OFFICE (MENRO)	acduenas02@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835	f	ARNOLD	DUE├æAS	9957444062	active	\N
1829	\N	\N	Male	SINGLE	Senior Environmental Management Specialist	Municipal Environment and Natural Resources Office	Jtmasangkay@up.edu.ph	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.063763	2025-11-26 04:53:46.567281	f	JETHRO	MASANGKAY	9171341589	active	\N
1828	\N	\N	Male	SINGLE	Environmental Management Assistant	Municipal Environment and Natural Resources Office	dennismazocajayon31@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.982717	2025-11-26 04:53:54.295763	f	DENNIS	CAJAYON	9051990098	active	\N
1826	\N	\N	Female	SINGLE	Clerk/Encoder	Municipal Environment and Natural Resources Office	madelienepaglicawan23@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.732887	2025-11-26 04:54:14.704814	f	MADELIENE	PAGLICAWAN	9056204474	active	\N
1825	\N	20170307	Female	MARRIED	Administrative Aide II	Municipal Environment and Natural Resources Office	shentalento@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.618089	2025-11-26 04:54:20.217409	f	SHERRYL ANNE	TALENTO	9262799075	active	\N
1823	\N	\N	Female	SINGLE	Encoder	Office of the Assessor	dyrithcababay2218@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.351989	2025-11-26 04:54:50.888012	f	DYRITH	CABABAY	9263160181	active	\N
1822	\N	20161004	Female	MARRIED	Administrative Aide I	Office of the Assessor	gie.estano0807@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.268995	2025-11-26 04:54:57.126281	f	GERALDINE	ESTA├æO	9675633099	active	\N
1821	\N	20150301	Male	MARRIED	LAOO I	Office of the Assessor	paul_3ya@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.178672	2025-11-26 04:55:02.937898	f	PAUL MICHAEL	TRIA	9535879472	active	\N
1820	\N	20031002	Female	MARRIED	Municipal Assessor	Office of the Assessor	melody_paglicawan@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:47.004877	2025-11-26 04:55:10.537685	f	MELODY	PAGLICAWAN	9175196429	active	\N
1814	\N	\N	Female	SINGLE	CLERK	Municipal Public Employment Service Office	quiloancriciamei@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:46.467783	2025-11-26 04:57:42.177703	f	CRICIA MEI	QUILOAN	9051988413	active	\N
1813	\N	\N	Female	SINGLE	CLERK	Municipal Public Employment Service Office	tividadjhenny@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:46.389141	2025-11-26 04:57:51.81205	f	JENNY ROSE	TIVIDAD	9773378796	active	\N
1811	\N	\N	Female	SINGLE	Labor and Employment Assistant	Municipal Public Employment Service Office	jeccabeatrix224@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:46.170192	2025-11-26 04:58:07.476262	f	ANGELICA	MORALES	9606915299	active	\N
1810	\N	20241216	Male	SINGLE	Administrative Aide IV (Clerk II)	Municipal Public Employment Service Office	ariesvillaluna6@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:46.081087	2025-11-26 04:58:13.97583	f	ARIES	VILLALUNA	9567337495	active	\N
1801	\N	20250206	Female	MARRIED	Engineering Aide	Municipal Engineering Office	jackieloutria@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.120886	2025-11-26 05:05:54.967327	f	JACKIE LOU	TRIA	9354702522	active	\N
1800	\N	20221009	Male	SINGLE	Engineering Assistant	Municipal Engineering Office	arnoldjansenmbu├▒ag@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.037561	2025-11-26 05:06:01.927775	f	ARNOLD JANSEN	BU├æAG	9178622111	active	\N
1799	\N	20091001	Male	MARRIED	DRAFTSMAN IV	Municipal Engineering Office	gabrielle.tepico041406@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.948659	2025-11-26 05:06:08.18094	f	CLIFFORD	TEPICO	9670844064	active	\N
1798	\N	20221010	Male	SINGLE	Engineer II	Municipal Engineering Office	rcajayon.plgumeo@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.877884	2025-11-26 05:06:18.284016	f	ROB MARVINZ	CAJAYON	9770333291	active	\N
1797	\N	19880903	Male	MARRIED	Municipal Engineer	Municipal Engineering Office	villabezajerry@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:44.747689	2025-11-26 05:06:28.020505	f	GERARDO	VILLABEZA	9176891264	active	\N
1803	\N	\N	Male	SINGLE	Engineering Consultant	Municipal Engineering Office	masangkayarkye@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:45.329821	2025-11-26 05:05:44.328971	f	ARKYE	MASANGKAY	9532249970	active	\N
1847	\N	20250204	Male	SINGLE	Administrative Officer II	Municipal Budget Office	bryanmasangkay1998@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.806912	2025-11-26 04:47:33.855031	f	JAMES BRYAN	MASANGKAY	9549863567	active	\N
1846	\N	19990901	Female	MARRIED	Senior Administrative Assistant III	Municipal Budget Office	eypands7599@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.688995	2025-11-26 04:48:06.692237	f	MYLENE	CABRERA	9062633234	active	\N
1845	\N	20161008	Female	MARRIED	Administrative Assistant II	Municipal Budget Office	jeselleventurero29@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.597818	2025-11-26 04:48:25.812665	f	JESELLE	VENTURERO	9268582263	active	\N
1844	\N	\N	Male	SINGLE	Clerk	Office of the Municipal Accountant	jamesbryansales11@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.527947	2025-11-26 04:48:44.442548	f	JAMES BRYAN	SALES	9558728557	active	\N
1843	\N	\N	Female	SINGLE	Clerk/Encoder	Office of the Municipal Accountant	gloenalyncadahin.23@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.429141	2025-11-26 04:49:00.413596	f	GLOENALYN	CADAHIN	9559287645	active	\N
1842	\N	\N	Male	SINGLE	Clerk/Encoder	Office of the Municipal Accountant	duenasjoshuaandrew@gamil.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.300913	2025-11-26 04:49:13.732376	f	JOSHUA ANDREW	DUE├æAS	9502650513	active	\N
1841	\N	20211106	Female	MARRIED	Administrative Aide II	Office of the Municipal Accountant	apriltagumpay49@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.222833	2025-11-26 04:49:21.723836	f	APRIL	TAGUMPAY	9458741587	active	\N
1840	\N	20191102	Female	SINGLE	Administrative Aide IV	Office of the Municipal Accountant	jzurita@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.135104	2025-11-26 04:49:29.37243	f	JAY ANNE	ZURITA	9260848779	active	\N
1839	\N	20170308	Female	MARRIED	Administrative Assistant II	Office of the Municipal Accountant	joannesuner@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:49.058052	2025-11-26 04:49:54.89209	f	JOANNE	SU├æER	9157853287	active	\N
1838	\N	20220607	Female	SINGLE	Municipal Accountant	Office of the Municipal Accountant	\N	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.92507	2025-11-26 04:50:07.837325	f	JULIE ANNE	VALLESTERO		active	\N
1837	\N	\N	Male	SINGLE	Data Encoder	Municipal Planning and Development Office	Johncelpaulnunez23@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.818124	2025-11-26 04:50:31.598163	f	JOHNCEL PAUL	NU├æEZ	9972372617	active	\N
1836	\N	\N	Female	SINGLE	Statistician	Municipal Planning and Development Office	rzdelemos@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.739855	2025-11-26 04:52:10.022708	f	ROSALIE FE	DE LEMOS	9157754429	active	\N
1835	\N	\N	Female	MARRIED	Planning Aide	Municipal Planning and Development Office	fabiennecute1@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.66897	2025-11-26 04:52:16.894914	f	FABIENNE BETSY	RICASIO	9367762980	active	\N
1834	\N	\N	Female	MARRIED	Clerk	Municipal Planning and Development Office	alfarohazel.1990@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.548508	2025-11-26 04:52:22.196116	f	HAZEL	ALFARO	9164120323	active	\N
1832	\N	20220303	Male	SINGLE	Administrative Aide I	Municipal Planning and Development Office	m.b.paglicawan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.373308	2025-11-26 04:52:36.855627	f	MELGAR	PAGLICAWAN	9062298704	active	\N
1831	\N	20240909	Female	MARRIED	Project Development Officer I	Municipal Planning and Development Office	crystle.villaflores@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.29433	2025-11-26 04:53:19.94831	f	CRYSTLE FLORENCE	JOSE	9562839806	active	\N
1833	\N	20161003	Female	MARRIED	Administrative Aide I	MO - MPDO	jovyabeleda01@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651	f	MA. JOVY	ABELEDA	9351579546	active	\N
1874	\N	\N	Male	SINGLE	Administrative Aide I	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	cristergoco@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702	f	CRISTER JOHANSON	GOCO	9066456981	active	\N
1875	\N	\N	Female	SINGLE	CLERK	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	amacadayjoyce@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853	f	JOYCE ANN	MACADAY	9974681258	active	\N
1876	\N	\N	Female	SINGLE	ENCODER	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	mariamarielsesalim10@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043	f	MA. MARIEL	SESALIM	9754388942	active	\N
1877	\N	\N	Male	SINGLE	Messenger	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	wilmerguillermo042001@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484	f	WILMER	GUILLERMMO	9531940568	active	\N
1878	\N	\N	Female	SINGLE	Clerk	OMM - TOURISM, CULTURE & THE ARTS  DIVISION	maryjoymarzan74@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894	f	MARY JOY	MARZAN	9262310676	active	\N
1879	\N	\N	Female	WIDOWED	Task Force Disiplina (TFD)	OMM - Task Force Disiplina	maylssalazar495@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014	f	MAYLIE	SALAZAR	09368193628 / 09158020664	active	\N
1880	\N	\N	Female	WIDOWED	TFD - Kalinisan	OMM - Task Force Disiplina	emmasanchez@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195	f	EMMALYN	DE LARA	09551832291 / 09150237900	active	\N
1881	\N	\N	Male	MARRIED	TFD - Focal Person	OMM - Task Force Disiplina	edwardemmanuelyambao2@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883	f	EDWAERD EMMANUEL	YAMBAO	9757937285	active	\N
1882	\N	\N	Female	SEPARATED	TFD - Kalinisan	OMM - Task Force Disiplina	ruzzlebeltran@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918	f	RUZZLE	BALAJADIA	9664750242	active	\N
1883	\N	\N	Male	SINGLE	TFD - PARKING	OMM - Task Force Disiplina	oliverdelara91@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557	f	OLIVER	DE LARA	9978802500	active	\N
1884	\N	\N	Male	MARRIED	TFD - PARKING	OMM - Task Force Disiplina	christianperezmanimtim1997@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675	f	CHRISTIAN	MANIMTIM	9269619633	active	\N
1885	\N	\N	Male	MARRIED	Task Force Disiplina (TFD)	OMM - Task Force Disiplina	bernardbasco@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776	f	BERNARD	BASCO	9757639306	active	\N
1886	\N	\N	Male	SINGLE	Task Force Disiplina (TFD)	OMM - Task Force Disiplina	lyndonarnedo@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516	f	LYNDON	ARNEDO	9161691054	active	\N
1887	\N	\N	Male	MARRIED	Task Force Disiplina (TFD)	OMM - Task Force Disiplina	glanniecabrera7@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153	f	GLANNIE	CABRERA	9679945659	active	\N
1888	\N	\N	Male	Single	Task Force Disiplina (TFD)	OMM - Task Force Disiplina	\N	\N	2025-10-17	Permanent	\N	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174	f	REYMARK	ENCONADO		active	\N
1889	\N	20130703	Female	MARRIED	Vice-Mayor	SANGGUNIANG BAYAN OFFICE	JasmintriaFernandez27@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119	f	JASMIN	FERNANDEZ		active	\N
1911	\N	\N	Male	SINGLE	DRIVER	Sangguniang Bayan Office	JoelPaglicawan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.263328	2025-11-26 04:32:14.753804	f	JOEL	PAGLICAWAN	9058460987	active	\N
1910	\N	\N	Female	MARRIED	CLERK/ENCODER	Sangguniang Bayan Office	rryanne12@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.148832	2025-11-26 04:32:31.911813	f	CHERRY ANN	TUPAS	9352804825	active	\N
1909	\N	\N	Female	MARRIED	CLERK/ENCODER	Sangguniang Bayan Office	jhieanSalon@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.068138	2025-11-26 04:32:40.552519	f	JESSELE ANN	TAMARES	9972336969	active	\N
1908	\N	\N	Male	SINGLE	LOCAL LEGISLATIVE STAFF OFFICER	Sangguniang Bayan Office	patrickandrewaguilarricasio06@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.971796	2025-11-26 04:32:47.581715	f	PATRICK ANDREW	RICASIO	9676076922	active	\N
1907	\N	20220102	Female	MARRIED	ADMINISTRATIVE AIDE I	Sangguniang Bayan Office	Jessavillaflores27@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.894569	2025-11-26 04:32:55.373462	f	JESSA	VILLAFLORES	9659104865	active	\N
1906	\N	20220101	Female	SINGLE	ADMINISTRATIVE AIDE I	Sangguniang Bayan Office	Pinkysbatacadulo20@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.763695	2025-11-26 04:33:20.812456	f	PINKY	BATACANDULO	9454405130	active	\N
1905	\N	20210201	Female	MARRIED	ADMINISTRATIVE AIDE I	Sangguniang Bayan Office	christinejadegoco@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.69001	2025-11-26 04:33:28.561832	f	CHRISTINE JADE	GLASE	9754801784	active	\N
1904	\N	20161005	Female	MARRIED	LLSE II	Sangguniang Bayan Office	applejanemasangkay@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.60094	2025-11-26 04:33:36.557086	f	APPLE JANE	MASANGKAY	9261696644	active	\N
1903	\N	20201104	Male	MARRIED	LLSA I	Sangguniang Bayan Office	ryanmalimban302@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.508084	2025-11-26 04:33:45.251863	f	RYAN	MALIMBAN	9957586388	active	\N
1902	\N	20250201	Female	MARRIED	LOCAL LEGISLATIVE STAFF OFFICER IV	Sangguniang Bayan Office	jannaeviannedayandayan@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.325097	2025-11-26 04:33:51.641642	f	JANA EVIANNE	VILLALUNA	9759169897	active	\N
1901	\N	20121102	Male	SINGLE	SECRETARY TO THE SANGGUNIANG BAYAN	Sangguniang Bayan Office	satreuh1116@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:55.230926	2025-11-26 04:33:57.722549	f	JEFFREY	HUERTAS	9178062616	active	\N
1900	\N	20250708	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	\N	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:55.137765	2025-11-26 04:34:04.392781	f	BENITO	CABABAY		active	\N
1899	\N	20250707	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	Vonjosephvvelandria1993@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.949722	2025-11-26 04:34:10.342885	f	VON JOSEPH	VELANDRIA		active	\N
1898	\N	20231111	Male	SINGLE	SKF President	Sangguniang Bayan Office	Velandriavic@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.8681	2025-11-26 04:34:16.861651	f	VIC ANTHONY	VELANDRIA	9260658770	active	\N
1897	\N	20240103	Male	MARRIED	ABC President	Sangguniang Bayan Office	kultztalento@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.765104	2025-11-26 04:35:09.951838	f	ROMELITO	TALENTO		active	\N
1896	\N	20230302	Male	MARRIED	IPMR	Sangguniang Bayan Office	ryanparisan06@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.612679	2025-11-26 04:35:27.611711	f	RYAN	PARISAN	9659432189	active	\N
1895	\N	20190701	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	marasiganelorde07@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.533041	2025-11-26 04:35:36.523541	f	ELORDE	MARASIGAN	9362946564	active	\N
1894	\N	19980702	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	Ronnie.torreliza1960@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.453049	2025-11-26 04:35:42.932817	f	RONALDO	TORRELIZA		active	\N
1893	\N	20220707	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	jonelltria@yahoo.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.374304	2025-11-26 04:35:51.93178	f	JONELL	TRIA		active	\N
1892	\N	20220705	Female	SINGLE	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	marrian.ibanez@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.223837	2025-11-26 04:35:59.432996	f	MARRIAN	IBA├æEZ	9474230331	active	\N
1891	\N	20130704	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	Rockymasangkay2024@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.147963	2025-11-26 04:36:05.432728	f	ROCKY	MASANGKAY	9452656947	active	\N
1890	\N	20130702	Male	MARRIED	SANGGUNIANG BAYAN MEMBER	Sangguniang Bayan Office	rochebautista24@gmail.com	\N	1970-01-01	Temporary	\N	2025-10-17 12:46:54.073759	2025-11-26 04:36:12.64332	f	ROCHE	BAUTISTA	9543905018	active	\N
1919	\N	20141002	Female	MARRIED	ASSESSMENT CLERK I	ASSESSOR'S OFFICE - MUNICIPAL TREASURER'S OFFICE	bernagepelgon@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007	f	BERNADETH	GEPELGON	9053351497	active	\N
1928	\N	20200903	Male	SINGLE	LDRRM ASSISTANT	MDRRMO	polthirtyuno@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687	f	POL THIRTY	MASANGKAY	9773375338	active	\N
1929	\N	20201205	Male	SINGLE	COMMUNITY AFFAIRS ASST. I	OMM - MDRRMO	mlabeleda@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436	f	MARK LOUIE	ABELEDA	9359097072	active	\N
1942	\N	20240101	Female	MARRIED	NURSE II	Municipal Health Office	she_lezada@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.460108	2025-11-26 04:19:13.830501	f	SHERYLL ANNE	LEZADA	9533755575	active	\N
1941	\N	20170104	Female	SEPARATED	NURSING ATTENDANT	Municipal Health Office	jeanettemercader@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.383837	2025-11-26 04:19:24.573909	f	JEANETTE	MERCADER	9568925329	active	\N
1940	\N	20020501	Female	WIDOWED	MIDWIFE VI	Municipal Health Office	lizamidwife1121@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.311567	2025-11-26 04:19:33.153921	f	ANNALIZA	DE VEAS	9178036148	active	\N
1939	\N	20230101	Female	MARRIED	MEDICAL TECHNOLOGIST I	Municipal Health Office	nelkievelandria@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.170754	2025-11-26 04:19:40.31383	f	NELKIE JANE	VELANDRIA	9298313340	active	\N
1938	\N	20210502	Male	MARRIED	SANITARY INSPECTOR I	Municipal Health Office	paulvincentoaguilar@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.095562	2025-11-26 04:19:46.814613	f	PAUL VINCENT	AGUILAR	9506173356	active	\N
1937	\N	20191203	Male	MARRIED	NURSE IV	Municipal Health Office	carlovsanagustin@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:59.013954	2025-11-26 04:19:53.973557	f	CARLO	SAN AGUSTIN	09610116025 / 09551564831	active	\N
1936	\N	20210803	Female	MARRIED	NUTRITION OFFICER I	Municipal Health Office	michelleritabayronbernardo@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.92481	2025-11-26 04:20:01.973806	f	MICHELLE RITA	BERNARDO	9059631874	active	\N
1935	\N	19950101	Female	MARRIED	MIDWIFE II	Municipal Health Office	prencisitabernardo@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.803803	2025-11-26 04:20:11.893873	f	PRENCISITA	BERNARDO	9363555343	active	\N
1934	\N	19880802	Female	MARRIED	MIDWIFE IV	Municipal Health Office	violetavian.velandria@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.727616	2025-11-26 04:20:18.154361	f	VIOLETA	VELANDRIA	9263935604	active	\N
1933	\N	20240102	Female	MARRIED	MIDWIFE II	Municipal Health Office	lerrymesana16@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.653282	2025-11-26 04:20:26.453366	f	LERRY	MESANA	09701320782 / 09958573036	active	\N
1932	\N	19940101	Female	MARRIED	MUNICIPAL HEALTH OFFICER	Municipal Health Office	ruthramosmd@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.557677	2025-11-26 04:20:39.453913	f	RUTH ALMA	RAMOS	9568945317	active	\N
1926	\N	\N	Female	MARRIED	CLERK	Municipal Treasurer's Office	Msmbeltran@yahoo.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:57.884694	2025-11-26 04:28:24.631416	f	MELDIE	BELTRAN	9364031211	active	\N
1931	\N	20221011	Male	SINGLE	ADMINISTRATIVE AIDE I	Municipal Disaster Risk Reduction and Management Office	\N	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.417581	2025-11-26 04:22:17.884128	f	ENGELBERT	MARI├æO	9058468589	active	\N
1930	\N	20221012	Male	SINGLE	ADMINISTRATIVE AIDE III (DRIVER)	Municipal Disaster Risk Reduction and Management Office	\N	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:58.348892	2025-11-26 04:22:29.464031	f	JOHN CARLO	VILLAFLORES	9059771714	active	\N
1927	\N	20110801	Male	MARRIED	LDRRMO III/OIC-MDRRMO	Municipal Disaster Risk Reduction and Management Office	albertdimaano@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.973863	2025-11-26 04:28:17.552972	f	ALBERT	DIMAANO	9553279511	active	\N
1925	\N	\N	Male	SINGLE	ENCODER/CLERK	Municipal Treasurer's Office	billyjamesbangcuyan@gmail.com	\N	1970-01-01	Contractual	\N	2025-10-17 12:46:57.78788	2025-11-26 04:28:33.262978	f	BILLY JAMES	BANGCUYAN	9050910182	active	\N
1924	\N	\N	Female	MARRIED	TREASURY OPERATIONS CLERK	Municipal Treasurer's Office	tinaligamaricris@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.665653	2025-11-26 04:28:40.503341	f	MARICRIS	TINALIGA	9568944299	active	\N
1923	\N	20230603	Female	MARRIED	REVENUE COLLECTION CLERK I	Municipal Treasurer's Office	licelpaguagan09@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.585055	2025-11-26 04:28:49.461878	f	LICEL	PAGUAGAN	9354180828	active	\N
1922	\N	20170309	Male	MARRIED	REVENUE COLLECTION CLERK II	Municipal Treasurer's Office	dondontalento@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.493471	2025-11-26 04:28:55.733004	f	DONDON	TALENTO	9064618042	active	\N
1921	\N	20170105	Male	MARRIED	ADMINISTRATIVE AIDE I	Municipal Treasurer's Office	panganibanjaymark@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.413955	2025-11-26 04:29:05.811592	f	JAY MARK	PANGANIBAN	9566321120	active	\N
1920	\N	20140501	Male	MARRIED	ADMINISTRATIVE AIDE I	Municipal Treasurer's Office	rudyvillasjr@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.210048	2025-11-26 04:29:38.111786	f	RUDY	VILLAS	9066761261	active	\N
1918	\N	20170102	Female	MARRIED	REVENUE COLLECTION CLERK I	Municipal Treasurer's Office	ashley_ahne@yahoo.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:57.028296	2025-11-26 04:30:57.342808	f	SHIERAN	CAJAYON	9351919716	active	\N
1917	\N	20230808	Female	MARRIED	REVENUE COLLECTION OFFICER II	Municipal Treasurer's Office	CHAKABELTRAN27@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.83032	2025-11-26 04:31:05.913061	f	CHAKA MAUREA	BELTRAN	9270846057	active	\N
1916	\N	19860701	Female	MARRIED	ADMINISTRATIVE ASSISTANT II/DISBURSING OFFICER	Municipal Treasurer's Office	villaroza64@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.728938	2025-11-26 04:31:12.502876	f	EVA	DUE├æAS	9267983910	active	\N
1915	\N	20240507	Female	SINGLE	REVENUE COLLECTION CLERK I	Municipal Treasurer's Office	shellysalazar04@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.649831	2025-11-26 04:31:20.091858	f	SHELLY ANN	SALAZAR	9539476358	active	\N
1914	\N	20170106	Male	MARRIED	Administrative Aide I	Municipal Treasurer's Office	sunervincent01@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.511693	2025-11-26 04:31:34.433146	f	VINCENT	SU├æER	9158959230	active	\N
1913	\N	19840301	Female	MARRIED	Municipal Treasurer	Municipal Treasurer's Office	arlenedeveas@gmail.com	\N	1970-01-01	Permanent	\N	2025-10-17 12:46:56.417517	2025-11-26 04:31:44.393255	f	ARLENE	DE VEAS	9276901266	active	\N
\.


--
-- Data for Name: leave_applications; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.leave_applications (id, user_id, office_department, "position", salary, date_filing, leave_type, details, inclusive_dates, number_of_days, commutation_requested, status, created_at, updated_at, first_name, last_name, middle_name, approver_name, approver_date, attachment, approved_by, remarks, subtype, country, office_head_id, office_head_status, office_head_date, hr_id, hr_status, hr_date, mayor_id, mayor_status, mayor_date, office_head_signature, hr_signature, mayor_signature) FROM stdin;
97	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Office of the Municipal Mayor	Staff	500.00	2025-11-26	Mandatory/Forced Leave	Leave application submitted	[2025-11-26,2025-11-29)	3	f	Approved	2025-11-26 14:33:18.470276	2025-11-26 14:47:04.933854	Sofia	Cantos	\N	Michael Diaz	2025-11-26	\N	\N	Approved with CS Form No. 6 - 3 days with pay	\N	\N	17	Approved	2025-11-26 14:34:27.701974	2	Approved	2025-11-26 14:35:35.850576	18	Approved	2025-11-26 14:47:04.933854	data:image/png;base64,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	data:image/png;base64,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	data:image/png;base64,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
98	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Office of the Municipal Mayor	Staff	500.00	2025-11-26	Sick Leave	Haha	[2025-11-26,2025-11-28)	2	f	Pending	2025-11-26 14:49:12.389925	2025-11-26 14:49:12.389925	Sofia	Cantos	\N	\N	\N	https://res.cloudinary.com/dlrveckcz/image/upload/v1764168538/nal3lr8fa1fqhh6y7l0s.png	\N	\N	Hospital	\N	\N	Pending	\N	\N	Pending	\N	\N	Pending	\N	\N	\N	\N
95	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Office of the Municipal Mayor	Staff	500.00	2025-11-26	Vacation Leave	Leave application submitted	[2025-12-02,2025-12-04)	2	f	Rejected	2025-11-26 11:45:39.780779	2025-11-26 11:51:25.392826	Sofia	Cantos	\N	Shamelle Anne	2025-11-26	\N	\N	Kunware ka lang	Philippines	\N	17	Rejected	2025-11-26 11:51:25.392826	\N	Rejected	\N	\N	Rejected	\N	data:image/png;base64,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	\N	\N
\.


--
-- Data for Name: leave_cards; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.leave_cards (id, employee_id, period, particulars, vl_earned, vl_used, vl_balance, sl_earned, sl_used, sl_balance, remarks) FROM stdin;
1513	1833	As of 01/1-31/21	BALANCE BROUGHT FORWARD	\N	\N	13.958	\N	\N	59.958	\N
1514	1833	2/01-29/21	\N	1.250	\N	15.208	1.250	\N	61.208	\N
1515	1833	03/01-31/21	\N	1.250	\N	16.458	1.250	\N	62.458	\N
1516	1833	(10.0.00)	\N	\N	10	6.458	\N	\N	62.458	Monetization 2021
1517	1833	04/01-30/21	\N	1.250	\N	7.708	1.250	\N	63.708	\N
1518	1833	05/01-31/21	\N	1.250	\N	8.958	1.250	\N	64.958	\N
1519	1833	06/01-30/21	\N	1.250	\N	10.208	1.250	\N	66.208	\N
1520	1833	07/01-31/21	\N	1.250	\N	11.458	1.250	\N	67.458	\N
1521	1833	08/01-31/21	\N	1.250	\N	12.708	1.250	\N	68.708	\N
1522	1833	09/01-30/21	\N	1.250	\N	13.958	1.250	\N	69.958	\N
1523	1833	10/01-31/21	\N	1.250	\N	15.208	1.250	\N	71.208	\N
1524	1833	11/01-30/21	\N	1.250	\N	16.458	1.250	\N	72.458	\N
1525	1833	(3.0.00) SPL	\N	\N	\N	16.458	\N	\N	72.458	Dec. 21-23,2021
1526	1833	(5.0.00)	\N	\N	5	11.458	\N	\N	72.458	Mandatory Leave
1527	1833	12/01-31/21	\N	1.250	\N	12.708	1.250	\N	73.708	\N
1528	1833	1/1-31/22	\N	1.250	\N	13.958	1.250	\N	74.958	\N
1529	1833	2/1-29/22	\N	1.250	\N	15.208	1.250	\N	76.208	\N
1530	1833	3/1-31/22	\N	1.250	\N	16.458	1.250	\N	77.458	\N
1531	1833	\N	\N	\N	10	6.458	\N	\N	77.458	Monetization 2022
1532	1833	4/1-30/22	\N	1.250	\N	7.708	1.250	\N	78.708	\N
1533	1833	5/1-31/22	\N	1.250	\N	8.958	1.250	\N	79.958	\N
1534	1833	6/1-30/22	\N	1.250	\N	10.208	1.250	\N	81.208	\N
1535	1833	7/1-31/22	\N	1.250	\N	11.458	1.250	\N	82.458	\N
1536	1833	(5.0.00)	\N	\N	\N	11.458	\N	5	77.458	August 15-19,2022
1537	1833	8/1-31/22	\N	1.250	\N	12.708	1.250	\N	78.708	\N
1538	1833	(2.0.00)SPL	\N	\N	2	10.708	\N	\N	78.708	Sept. 1/Oct 5, 2022
1539	1833	9/1-30/22	\N	1.250	\N	11.958	1.250	\N	79.958	\N
1540	1833	10/1-31/22	\N	1.250	\N	13.208	1.250	\N	81.208	\N
1541	1833	11/1-30/22	\N	1.250	\N	14.458	1.250	\N	82.458	\N
1542	1833	(5.0.00) ML	\N	\N	2	12.458	\N	\N	82.458	December 26-29,2022
1543	1833	12/1-31/22	\N	1.250	\N	13.708	1.250	\N	83.708	\N
1544	1833	\N	\N	\N	2 days SPL January 26-27,2023	\N	\N	\N	\N	\N
1545	1833	1/1-31/2023	\N	1.250	\N	14.958	1.250	\N	84.958	\N
1546	1833	2/1-28/2023	\N	1.250	\N	16.208	1.250	\N	86.208	\N
1547	1833	\N	\N	\N	1 day SPL February 8, 2023	\N	\N	\N	\N	\N
1548	1833	3/1-31/2023	\N	1.250	\N	17.458	1.250	\N	87.458	\N
1549	1833	(10.0.00)	\N	\N	10	7.458	\N	\N	87.458	Monetization 2023
1550	1833	\N	\N	\N	2 days SPL April 3&4,2023	\N	\N	\N	\N	\N
1551	1833	4/1-30/2023	\N	1.250	\N	8.708	1.250	\N	88.708	\N
1552	1833	5/1-31/2023	\N	1.250	\N	9.958	1.250	\N	89.958	\N
1553	1833	6/1-30/2023	\N	1.250	\N	11.208	1.250	\N	91.208	\N
1554	1833	7/1-31/2023	\N	1.250	\N	12.458	1.250	\N	92.458	\N
1555	1833	-4	\N	\N	\N	12.458	\N	4	88.458	August 22-25,2023
1556	1833	8/1-31/2023	\N	1.250	\N	13.708	1.250	\N	89.708	\N
1557	1833	9/1-30/2023	\N	1.250	\N	14.958	1.250	\N	90.958	\N
1558	1833	10/1-31/2023	\N	1.250	\N	16.208	1.250	\N	92.208	\N
1559	1833	11/1-30/2023	\N	1.250	\N	17.458	1.250	\N	93.458	\N
1560	1833	-5	\N	\N	5	12.458	\N	\N	93.458	\N
1561	1833	12/1-31/2023	\N	1.250	\N	13.708	1.250	\N	94.708	\N
1562	1833	1/1-31/2024	\N	1.250	\N	14.958	1.250	\N	95.958	\N
1563	1833	2/1-28/2024	\N	1.250	\N	16.208	1.250	\N	97.208	\N
1564	1833	(3.000) SPL	3 days	\N	\N	16.208	\N	\N	97.208	March 26-28, 2024
1565	1833	3/1-31/2024	\N	1.250	\N	17.458	1.250	\N	98.458	\N
1566	1833	4/1-30/2024	\N	1.250	\N	18.708	1.250	\N	99.708	\N
1567	1833	-10	\N	\N	10	8.708	\N	\N	99.708	Monetization 2024
1568	1833	-4	\N	\N	\N	8.708	\N	4	95.708	June 13, 18-20, 2024
1569	1833	5/1-31/2024	\N	1.250	\N	9.958	1.250	\N	96.958	\N
1570	1833	6/1-30/2024	\N	1.250	\N	11.208	1.250	\N	98.208	\N
1571	1833	7/1-31/2024	\N	1.250	\N	12.458	1.250	\N	99.458	\N
1572	1833	(3.000)SL	\N	\N	\N	12.458	\N	3	96.458	Sept.5-7,2024
1573	1833	8/1-31/2024	\N	1.250	\N	13.708	1.250	\N	97.708	\N
1574	1833	9/1-30/2024	\N	1.250	\N	14.958	1.250	\N	98.958	\N
1575	1833	10/1-31/2024	\N	1.250	\N	16.208	1.250	\N	100.208	\N
1576	1833	11/1-30/2024	\N	1.250	\N	17.458	1.250	\N	101.458	\N
1577	1833	(5.000)SL	\N	\N	\N	17.458	\N	5	96.458	Nov.18 -22,2024
1578	1833	12/1-31/2024	\N	1.250	\N	18.708	1.250	\N	97.708	\N
1579	1833	1/1-31/2025	\N	1.250	\N	19.958	1.250	\N	98.958	\N
1580	1833	2/1-28/2025	\N	1.250	\N	21.208	1.250	\N	100.208	\N
1581	1833	3/1-31/2025	\N	1.250	\N	22.458	1.250	\N	101.458	\N
1582	1833	(4.000)ML	\N	\N	4	18.458	\N	\N	101.458	April 7,8,10 & 11,2025
1583	1833	4/1-30/2025	\N	1.250	\N	19.708	1.250	\N	102.708	\N
1584	1833	(5.000)SL	\N	\N	\N	19.708	\N	5	97.708	June 2-5 & 8, 2025
1585	1833	5/1-31/2025	\N	1.250	\N	20.958	1.250	\N	98.958	\N
1586	1833	6/1-30/2025	\N	1.250	\N	22.208	1.250	\N	100.208	\N
1587	1833	7/1-30/2025	\N	1.250	\N	23.458	1.250	\N	101.458	\N
1588	1833	8/1-31/2025	\N	1.250	\N	24.708	1.250	\N	102.708	\N
1589	1833	9/1-30/2025	\N	1.250	\N	25.958	1.250	\N	103.958	\N
1590	1805	45642	\N	0.667	\N	0.667	0.667	\N	0.667	\N
1591	1805	1/1-31/2025	\N	1.250	\N	1.917	1.250	\N	1.917	\N
1592	1805	2/1-28/2025	\N	1.250	\N	3.167	1.250	\N	3.167	\N
1593	1805	3/1-31/2025	\N	1.250	\N	4.417	1.250	\N	4.417	\N
1594	1805	4/1-30/2025	\N	1.250	\N	5.667	1.250	\N	5.667	\N
1595	1805	(1.000)SPL	\N	\N	1	5.667	\N	\N	5.667	\N
1596	1805	5/1-31/2025	\N	1.250	\N	6.917	1.250	\N	6.917	\N
1597	1805	6/1-30/2025	\N	1.250	\N	8.167	1.250	\N	8.167	\N
1598	1805	7/1-31/2025	\N	1.250	\N	9.417	1.250	\N	9.417	\N
1599	1805	8/1-31/2025	\N	1.250	\N	10.667	1.250	\N	10.667	\N
1600	1805	9/1-30/2025	\N	1.250	\N	11.917	1.250	\N	11.917	\N
1601	23	As of 01/1-31/21	BALANCE BROUGHT FORWARD	\N	\N	13.958	\N	\N	59.958	\N
1602	23	2/01-29/21	\N	1.250	\N	15.208	1.250	\N	61.208	\N
1603	23	03/01-31/21	\N	1.250	\N	16.458	1.250	\N	62.458	\N
1604	23	(10.0.00)	\N	\N	10	6.458	\N	\N	62.458	Monetization 2021
1605	23	04/01-30/21	\N	1.250	\N	7.708	1.250	\N	63.708	\N
1606	23	05/01-31/21	\N	1.250	\N	8.958	1.250	\N	64.958	\N
1607	23	06/01-30/21	\N	1.250	\N	10.208	1.250	\N	66.208	\N
1608	23	07/01-31/21	\N	1.250	\N	11.458	1.250	\N	67.458	\N
1609	23	08/01-31/21	\N	1.250	\N	12.708	1.250	\N	68.708	\N
1610	23	09/01-30/21	\N	1.250	\N	13.958	1.250	\N	69.958	\N
1611	23	10/01-31/21	\N	1.250	\N	15.208	1.250	\N	71.208	\N
1612	23	11/01-30/21	\N	1.250	\N	16.458	1.250	\N	72.458	\N
1613	23	(3.0.00) SPL	\N	\N	\N	16.458	\N	\N	72.458	Dec. 21-23,2021
1614	23	(5.0.00)	\N	\N	5	11.458	\N	\N	72.458	Mandatory Leave
1615	23	12/01-31/21	\N	1.250	\N	12.708	1.250	\N	73.708	\N
1616	23	1/1-31/22	\N	1.250	\N	13.958	1.250	\N	74.958	\N
1617	23	2/1-29/22	\N	1.250	\N	15.208	1.250	\N	76.208	\N
1618	23	3/1-31/22	\N	1.250	\N	16.458	1.250	\N	77.458	\N
1619	23	\N	\N	\N	10	6.458	\N	\N	77.458	Monetization 2022
1620	23	4/1-30/22	\N	1.250	\N	7.708	1.250	\N	78.708	\N
1621	23	5/1-31/22	\N	1.250	\N	8.958	1.250	\N	79.958	\N
1622	23	6/1-30/22	\N	1.250	\N	10.208	1.250	\N	81.208	\N
1623	23	7/1-31/22	\N	1.250	\N	11.458	1.250	\N	82.458	\N
1624	23	(5.0.00)	\N	\N	\N	11.458	\N	5	77.458	August 15-19,2022
1625	23	8/1-31/22	\N	1.250	\N	12.708	1.250	\N	78.708	\N
1626	23	(2.0.00)SPL	\N	\N	2	10.708	\N	\N	78.708	Sept. 1/Oct 5, 2022
1627	23	9/1-30/22	\N	1.250	\N	11.958	1.250	\N	79.958	\N
1628	23	10/1-31/22	\N	1.250	\N	13.208	1.250	\N	81.208	\N
1629	23	11/1-30/22	\N	1.250	\N	14.458	1.250	\N	82.458	\N
1630	23	(5.0.00) ML	\N	\N	2	12.458	\N	\N	82.458	December 26-29,2022
1631	23	12/1-31/22	\N	1.250	\N	13.708	1.250	\N	83.708	\N
1632	23	\N	\N	\N	2 days SPL January 26-27,2023	\N	\N	\N	\N	\N
1633	23	1/1-31/2023	\N	1.250	\N	14.958	1.250	\N	84.958	\N
1634	23	2/1-28/2023	\N	1.250	\N	16.208	1.250	\N	86.208	\N
1635	23	\N	\N	\N	1 day SPL February 8, 2023	\N	\N	\N	\N	\N
1636	23	3/1-31/2023	\N	1.250	\N	17.458	1.250	\N	87.458	\N
1637	23	(10.0.00)	\N	\N	10	7.458	\N	\N	87.458	Monetization 2023
1638	23	\N	\N	\N	2 days SPL April 3&4,2023	\N	\N	\N	\N	\N
1639	23	4/1-30/2023	\N	1.250	\N	8.708	1.250	\N	88.708	\N
1640	23	5/1-31/2023	\N	1.250	\N	9.958	1.250	\N	89.958	\N
1641	23	6/1-30/2023	\N	1.250	\N	11.208	1.250	\N	91.208	\N
1642	23	7/1-31/2023	\N	1.250	\N	12.458	1.250	\N	92.458	\N
1643	23	-4	\N	\N	\N	12.458	\N	4	88.458	August 22-25,2023
1644	23	8/1-31/2023	\N	1.250	\N	13.708	1.250	\N	89.708	\N
1645	23	9/1-30/2023	\N	1.250	\N	14.958	1.250	\N	90.958	\N
1646	23	10/1-31/2023	\N	1.250	\N	16.208	1.250	\N	92.208	\N
1647	23	11/1-30/2023	\N	1.250	\N	17.458	1.250	\N	93.458	\N
1648	23	-5	\N	\N	5	12.458	\N	\N	93.458	\N
1649	23	12/1-31/2023	\N	1.250	\N	13.708	1.250	\N	94.708	\N
1650	23	1/1-31/2024	\N	1.250	\N	14.958	1.250	\N	95.958	\N
1651	23	2/1-28/2024	\N	1.250	\N	16.208	1.250	\N	97.208	\N
1652	23	(3.000) SPL	3 days	\N	\N	16.208	\N	\N	97.208	March 26-28, 2024
1653	23	3/1-31/2024	\N	1.250	\N	17.458	1.250	\N	98.458	\N
1654	23	4/1-30/2024	\N	1.250	\N	18.708	1.250	\N	99.708	\N
1655	23	-10	\N	\N	10	8.708	\N	\N	99.708	Monetization 2024
1656	23	-4	\N	\N	\N	8.708	\N	4	95.708	June 13, 18-20, 2024
1657	23	5/1-31/2024	\N	1.250	\N	9.958	1.250	\N	96.958	\N
1658	23	6/1-30/2024	\N	1.250	\N	11.208	1.250	\N	98.208	\N
1659	23	7/1-31/2024	\N	1.250	\N	12.458	1.250	\N	99.458	\N
1660	23	(3.000)SL	\N	\N	\N	12.458	\N	3	96.458	Sept.5-7,2024
1661	23	8/1-31/2024	\N	1.250	\N	13.708	1.250	\N	97.708	\N
1662	23	9/1-30/2024	\N	1.250	\N	14.958	1.250	\N	98.958	\N
1663	23	10/1-31/2024	\N	1.250	\N	16.208	1.250	\N	100.208	\N
1664	23	11/1-30/2024	\N	1.250	\N	17.458	1.250	\N	101.458	\N
1665	23	(5.000)SL	\N	\N	\N	17.458	\N	5	96.458	Nov.18 -22,2024
1666	23	12/1-31/2024	\N	1.250	\N	18.708	1.250	\N	97.708	\N
1667	23	1/1-31/2025	\N	1.250	\N	19.958	1.250	\N	98.958	\N
1668	23	2/1-28/2025	\N	1.250	\N	21.208	1.250	\N	100.208	\N
1669	23	3/1-31/2025	\N	1.250	\N	22.458	1.250	\N	101.458	\N
1670	23	(4.000)ML	\N	\N	4	18.458	\N	\N	101.458	April 7,8,10 & 11,2025
1671	23	4/1-30/2025	\N	1.250	\N	19.708	1.250	\N	102.708	\N
1672	23	(5.000)SL	\N	\N	\N	19.708	\N	5	97.708	June 2-5 & 8, 2025
1673	23	5/1-31/2025	\N	1.250	\N	20.958	1.250	\N	98.958	\N
1674	23	6/1-30/2025	\N	1.250	\N	22.208	1.250	\N	100.208	\N
1675	23	7/1-30/2025	\N	1.250	\N	23.458	1.250	\N	101.458	\N
1676	23	8/1-31/2025	\N	1.250	\N	24.708	1.250	\N	102.708	\N
1677	23	9/1-30/2025	\N	1.250	\N	25.958	1.250	\N	103.958	\N
1682	23	(2.000) VL	\N	1.250	2	23.958	1.250	\N	103.958	November 4 & November 5, 2025
1694	1945	45642	\N	0.667	\N	0.667	0.667	\N	0.667	\N
1695	1945	1/1-31/2025	\N	1.250	\N	1.917	1.250	\N	1.917	\N
1696	1945	2/1-28/2025	\N	1.250	\N	3.167	1.250	\N	3.167	\N
1697	1945	3/1-31/2025	\N	1.250	\N	4.417	1.250	\N	4.417	\N
1698	1945	4/1-30/2025	\N	1.250	\N	5.667	1.250	\N	5.667	\N
1699	1945	(1.000)SPL	\N	\N	1	5.667	\N	\N	5.667	\N
1700	1945	5/1-31/2025	\N	1.250	\N	6.917	1.250	\N	6.917	\N
1701	1945	6/1-30/2025	\N	1.250	\N	8.167	1.250	\N	8.167	\N
1702	1945	7/1-31/2025	\N	1.250	\N	9.417	1.250	\N	9.417	\N
1703	1945	8/1-31/2025	\N	1.250	\N	10.667	1.250	\N	10.667	\N
1704	1945	9/1-30/2025	\N	1.250	\N	11.917	1.250	\N	11.917	\N
2073	23	10/1-31/2025	\N	1.250	\N	25.208	1.250	\N	105.208	\N
2074	1945	10/1-31/2025	\N	1.250	\N	13.167	1.250	\N	13.167	\N
2075	1805	10/1-31/2025	\N	1.250	\N	13.167	1.250	\N	13.167	\N
2076	1833	10/1-31/2025	\N	1.250	\N	27.208	1.250	\N	105.208	\N
2078	1945	(3.000) ML	\N	\N	\N	13.167	\N	\N	13.167	November 26, November 27 & November 28, 2025
\.


--
-- Data for Name: leave_credits; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.leave_credits (id, user_id, year, vacation_earned, vacation_used, sick_earned, sick_used, created_at, updated_at) FROM stdin;
10	user_32DnrEP3Z0WO36aaj7wDmpdTrWB	2025	15	0	15	0	2025-09-04 05:36:47.624406	2025-09-04 05:36:47.624406
11	user_32GnDupU1GMex4n6pJHsUsnFVkY	2025	15	0	15	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
12	\N	2025	15	0	15	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
13	\N	2025	15	0	15	0	2025-09-11 02:54:53.109051	2025-09-11 02:54:53.109051
14	\N	2025	15	0	15	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
15	\N	2025	15	0	15	0	2025-09-11 06:17:40.762496	2025-09-11 06:17:40.762496
16	\N	2025	15	0	15	0	2025-09-11 07:22:32.547043	2025-09-11 07:22:32.547043
17	\N	2025	15	0	15	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
18	\N	2025	15	0	15	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
19	\N	2025	15	0	15	0	2025-09-20 12:12:04.183278	2025-09-20 12:12:04.183278
20	\N	2025	15	0	15	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
21	\N	2025	15	0	15	0	2025-09-20 12:13:43.564138	2025-09-20 12:13:43.564138
22	\N	2025	15	0	15	0	2025-09-22 14:09:33.885188	2025-09-22 14:09:33.885188
23	\N	2025	15	0	15	0	2025-09-22 14:40:36.419167	2025-09-22 14:40:36.419167
24	\N	2025	15	0	15	0	2025-10-07 04:54:59.696169	2025-10-07 04:54:59.696169
25	\N	2025	15	0	15	0	2025-10-07 04:57:01.308644	2025-10-07 04:57:01.308644
26	\N	2025	15	0	15	0	2025-10-07 05:22:36.083374	2025-10-07 05:22:36.083374
27	\N	2025	15	0	15	0	2025-10-07 05:25:36.243334	2025-10-07 05:25:36.243334
28	\N	2025	15	0	15	0	2025-10-07 07:18:10.578518	2025-10-07 07:18:10.578518
29	\N	2025	15	0	15	0	2025-10-07 07:18:11.45755	2025-10-07 07:18:11.45755
30	\N	2025	15	0	15	0	2025-10-07 07:18:12.402981	2025-10-07 07:18:12.402981
31	\N	2025	15	0	15	0	2025-10-07 07:18:12.560764	2025-10-07 07:18:12.560764
32	\N	2025	15	0	15	0	2025-10-07 07:20:18.53929	2025-10-07 07:20:18.53929
33	\N	2025	15	0	15	0	2025-10-07 07:20:18.67313	2025-10-07 07:20:18.67313
34	\N	2025	15	0	15	0	2025-10-07 07:20:18.802432	2025-10-07 07:20:18.802432
35	\N	2025	15	0	15	0	2025-10-07 07:20:18.887704	2025-10-07 07:20:18.887704
36	\N	2025	15	0	15	0	2025-10-07 07:26:03.038753	2025-10-07 07:26:03.038753
37	\N	2025	15	0	15	0	2025-10-07 07:26:04.178897	2025-10-07 07:26:04.178897
38	\N	2025	15	0	15	0	2025-10-07 07:26:05.094036	2025-10-07 07:26:05.094036
39	\N	2025	15	0	15	0	2025-10-07 07:26:05.358119	2025-10-07 07:26:05.358119
40	\N	2025	15	0	15	0	2025-10-07 07:30:49.793263	2025-10-07 07:30:49.793263
41	\N	2025	15	0	15	0	2025-10-07 07:30:49.936788	2025-10-07 07:30:49.936788
42	\N	2025	15	0	15	0	2025-10-07 07:30:50.009828	2025-10-07 07:30:50.009828
43	\N	2025	15	0	15	0	2025-10-07 07:30:50.089542	2025-10-07 07:30:50.089542
44	\N	2025	15	0	15	0	2025-10-07 07:30:50.166767	2025-10-07 07:30:50.166767
45	\N	2025	15	0	15	0	2025-10-07 07:30:50.24485	2025-10-07 07:30:50.24485
46	\N	2025	15	0	15	0	2025-10-07 07:30:50.327785	2025-10-07 07:30:50.327785
47	\N	2025	15	0	15	0	2025-10-07 07:30:50.409999	2025-10-07 07:30:50.409999
48	\N	2025	15	0	15	0	2025-10-07 07:30:50.487104	2025-10-07 07:30:50.487104
49	\N	2025	15	0	15	0	2025-10-07 07:30:50.564308	2025-10-07 07:30:50.564308
50	\N	2025	15	0	15	0	2025-10-17 11:05:34.208555	2025-10-17 11:05:34.208555
51	\N	2025	15	0	15	0	2025-10-17 11:05:34.44299	2025-10-17 11:05:34.44299
52	\N	2025	15	0	15	0	2025-10-17 11:05:34.564295	2025-10-17 11:05:34.564295
53	\N	2025	15	0	15	0	2025-10-17 11:05:34.701403	2025-10-17 11:05:34.701403
54	\N	2025	15	0	15	0	2025-10-17 11:05:34.792291	2025-10-17 11:05:34.792291
55	\N	2025	15	0	15	0	2025-10-17 11:05:35.357585	2025-10-17 11:05:35.357585
56	\N	2025	15	0	15	0	2025-10-17 11:05:35.440392	2025-10-17 11:05:35.440392
57	\N	2025	15	0	15	0	2025-10-17 11:05:35.530863	2025-10-17 11:05:35.530863
58	\N	2025	15	0	15	0	2025-10-17 11:05:35.695212	2025-10-17 11:05:35.695212
59	\N	2025	15	0	15	0	2025-10-17 11:05:35.784213	2025-10-17 11:05:35.784213
60	\N	2025	15	0	15	0	2025-10-17 11:05:36.139483	2025-10-17 11:05:36.139483
61	\N	2025	15	0	15	0	2025-10-17 11:05:36.241197	2025-10-17 11:05:36.241197
62	\N	2025	15	0	15	0	2025-10-17 11:05:36.323535	2025-10-17 11:05:36.323535
63	\N	2025	15	0	15	0	2025-10-17 11:05:36.523741	2025-10-17 11:05:36.523741
64	\N	2025	15	0	15	0	2025-10-17 11:05:36.941588	2025-10-17 11:05:36.941588
65	\N	2025	15	0	15	0	2025-10-17 11:05:37.025312	2025-10-17 11:05:37.025312
66	\N	2025	15	0	15	0	2025-10-17 11:05:37.746193	2025-10-17 11:05:37.746193
67	\N	2025	15	0	15	0	2025-10-17 11:05:38.148335	2025-10-17 11:05:38.148335
68	\N	2025	15	0	15	0	2025-10-17 11:05:38.384264	2025-10-17 11:05:38.384264
69	\N	2025	15	0	15	0	2025-10-17 11:05:38.48841	2025-10-17 11:05:38.48841
70	\N	2025	15	0	15	0	2025-10-17 11:05:38.573654	2025-10-17 11:05:38.573654
71	\N	2025	15	0	15	0	2025-10-17 11:05:38.952189	2025-10-17 11:05:38.952189
72	\N	2025	15	0	15	0	2025-10-17 11:05:39.126307	2025-10-17 11:05:39.126307
73	\N	2025	15	0	15	0	2025-10-17 11:05:39.903302	2025-10-17 11:05:39.903302
74	\N	2025	15	0	15	0	2025-10-17 11:05:39.989603	2025-10-17 11:05:39.989603
75	\N	2025	15	0	15	0	2025-10-17 11:05:40.067201	2025-10-17 11:05:40.067201
76	\N	2025	15	0	15	0	2025-10-17 11:05:40.13842	2025-10-17 11:05:40.13842
77	\N	2025	15	0	15	0	2025-10-17 11:05:41.12243	2025-10-17 11:05:41.12243
78	\N	2025	15	0	15	0	2025-10-17 11:05:41.202804	2025-10-17 11:05:41.202804
79	\N	2025	15	0	15	0	2025-10-17 11:05:41.275928	2025-10-17 11:05:41.275928
80	\N	2025	15	0	15	0	2025-10-17 11:05:41.825023	2025-10-17 11:05:41.825023
81	\N	2025	15	0	15	0	2025-10-17 11:05:41.91345	2025-10-17 11:05:41.91345
82	\N	2025	15	0	15	0	2025-10-17 11:05:42.020054	2025-10-17 11:05:42.020054
83	\N	2025	15	0	15	0	2025-10-17 11:05:42.161751	2025-10-17 11:05:42.161751
84	\N	2025	15	0	15	0	2025-10-17 11:05:46.072231	2025-10-17 11:05:46.072231
85	\N	2025	15	0	15	0	2025-10-17 11:05:46.370035	2025-10-17 11:05:46.370035
86	\N	2025	15	0	15	0	2025-10-17 11:05:46.73649	2025-10-17 11:05:46.73649
87	\N	2025	15	0	15	0	2025-10-17 11:05:47.244424	2025-10-17 11:05:47.244424
88	\N	2025	15	0	15	0	2025-10-17 11:05:49.11006	2025-10-17 11:05:49.11006
89	\N	2025	15	0	15	0	2025-10-17 11:05:49.362285	2025-10-17 11:05:49.362285
90	\N	2025	15	0	15	0	2025-10-17 11:05:52.845778	2025-10-17 11:05:52.845778
91	\N	2025	15	0	15	0	2025-10-17 11:05:52.958849	2025-10-17 11:05:52.958849
92	\N	2025	15	0	15	0	2025-10-17 11:05:53.161993	2025-10-17 11:05:53.161993
93	\N	2025	15	0	15	0	2025-10-17 11:05:53.342065	2025-10-17 11:05:53.342065
94	\N	2025	15	0	15	0	2025-10-17 11:05:53.582844	2025-10-17 11:05:53.582844
95	\N	2025	15	0	15	0	2025-10-17 11:05:53.721825	2025-10-17 11:05:53.721825
96	\N	2025	15	0	15	0	2025-10-17 11:05:53.986964	2025-10-17 11:05:53.986964
97	\N	2025	15	0	15	0	2025-10-17 11:05:54.083385	2025-10-17 11:05:54.083385
98	\N	2025	15	0	15	0	2025-10-17 11:05:54.306901	2025-10-17 11:05:54.306901
99	\N	2025	15	0	15	0	2025-10-17 11:05:54.408042	2025-10-17 11:05:54.408042
100	\N	2025	15	0	15	0	2025-10-17 11:05:54.550713	2025-10-17 11:05:54.550713
101	\N	2025	15	0	15	0	2025-10-17 11:05:54.776069	2025-10-17 11:05:54.776069
102	\N	2025	15	0	15	0	2025-10-17 11:05:54.866032	2025-10-17 11:05:54.866032
103	\N	2025	15	0	15	0	2025-10-17 11:05:55.05807	2025-10-17 11:05:55.05807
104	\N	2025	15	0	15	0	2025-10-17 11:05:55.171731	2025-10-17 11:05:55.171731
105	\N	2025	15	0	15	0	2025-10-17 11:05:55.253814	2025-10-17 11:05:55.253814
106	\N	2025	15	0	15	0	2025-10-17 11:05:55.513663	2025-10-17 11:05:55.513663
107	\N	2025	15	0	15	0	2025-10-17 11:05:56.608229	2025-10-17 11:05:56.608229
108	\N	2025	15	0	15	0	2025-10-17 11:05:56.703241	2025-10-17 11:05:56.703241
109	\N	2025	15	0	15	0	2025-10-17 11:05:56.821612	2025-10-17 11:05:56.821612
110	\N	2025	15	0	15	0	2025-10-17 11:05:57.062336	2025-10-17 11:05:57.062336
111	\N	2025	15	0	15	0	2025-10-17 11:05:57.335596	2025-10-17 11:05:57.335596
112	\N	2025	15	0	15	0	2025-10-17 11:05:57.435614	2025-10-17 11:05:57.435614
113	\N	2025	15	0	15	0	2025-10-17 11:05:57.579154	2025-10-17 11:05:57.579154
114	\N	2025	15	0	15	0	2025-10-17 11:05:57.750982	2025-10-17 11:05:57.750982
115	\N	2025	15	0	15	0	2025-10-17 11:05:57.848487	2025-10-17 11:05:57.848487
116	\N	2025	15	0	15	0	2025-10-17 11:05:57.942876	2025-10-17 11:05:57.942876
117	\N	2025	15	0	15	0	2025-10-17 11:05:58.14023	2025-10-17 11:05:58.14023
118	\N	2025	15	0	15	0	2025-10-17 11:05:58.69971	2025-10-17 11:05:58.69971
119	\N	2025	15	0	15	0	2025-10-17 11:05:58.881037	2025-10-17 11:05:58.881037
120	\N	2025	15	0	15	0	2025-10-17 11:05:59.009548	2025-10-17 11:05:59.009548
121	\N	2025	15	0	15	0	2025-10-17 11:05:59.444895	2025-10-17 11:05:59.444895
122	\N	2025	15	0	15	0	2025-10-17 11:05:59.737868	2025-10-17 11:05:59.737868
123	\N	2025	15	0	15	0	2025-10-17 11:05:59.819907	2025-10-17 11:05:59.819907
124	\N	2025	15	0	15	0	2025-10-17 11:06:00.049985	2025-10-17 11:06:00.049985
125	\N	2025	15	0	15	0	2025-10-17 11:06:00.383922	2025-10-17 11:06:00.383922
126	\N	2025	15	0	15	0	2025-10-17 11:06:00.460255	2025-10-17 11:06:00.460255
127	\N	2025	15	0	15	0	2025-10-17 11:06:00.540259	2025-10-17 11:06:00.540259
128	\N	2025	15	0	15	0	2025-10-17 11:06:00.619809	2025-10-17 11:06:00.619809
129	\N	2025	15	0	15	0	2025-10-17 11:06:00.789357	2025-10-17 11:06:00.789357
130	\N	2025	15	0	15	0	2025-10-17 11:36:04.492498	2025-10-17 11:36:04.492498
131	\N	2025	15	0	15	0	2025-10-17 11:36:04.744307	2025-10-17 11:36:04.744307
132	\N	2025	15	0	15	0	2025-10-17 11:36:04.828479	2025-10-17 11:36:04.828479
133	\N	2025	15	0	15	0	2025-10-17 11:36:04.912452	2025-10-17 11:36:04.912452
134	\N	2025	15	0	15	0	2025-10-17 11:36:04.997463	2025-10-17 11:36:04.997463
135	\N	2025	15	0	15	0	2025-10-17 11:36:05.333619	2025-10-17 11:36:05.333619
136	\N	2025	15	0	15	0	2025-10-17 11:36:05.497433	2025-10-17 11:36:05.497433
137	\N	2025	15	0	15	0	2025-10-17 11:36:05.602093	2025-10-17 11:36:05.602093
138	\N	2025	15	0	15	0	2025-10-17 11:36:05.697616	2025-10-17 11:36:05.697616
139	\N	2025	15	0	15	0	2025-10-17 11:36:05.880468	2025-10-17 11:36:05.880468
140	\N	2025	15	0	15	0	2025-10-17 11:36:06.137509	2025-10-17 11:36:06.137509
141	\N	2025	15	0	15	0	2025-10-17 11:36:06.252167	2025-10-17 11:36:06.252167
142	\N	2025	15	0	15	0	2025-10-17 11:36:06.37943	2025-10-17 11:36:06.37943
143	\N	2025	15	0	15	0	2025-10-17 11:36:06.468646	2025-10-17 11:36:06.468646
144	\N	2025	15	0	15	0	2025-10-17 11:36:06.731421	2025-10-17 11:36:06.731421
145	\N	2025	15	0	15	0	2025-10-17 11:36:06.827566	2025-10-17 11:36:06.827566
146	\N	2025	15	0	15	0	2025-10-17 11:36:07.522278	2025-10-17 11:36:07.522278
147	\N	2025	15	0	15	0	2025-10-17 11:36:07.967055	2025-10-17 11:36:07.967055
148	\N	2025	15	0	15	0	2025-10-17 11:36:08.162518	2025-10-17 11:36:08.162518
149	\N	2025	15	0	15	0	2025-10-17 11:36:08.25211	2025-10-17 11:36:08.25211
150	\N	2025	15	0	15	0	2025-10-17 11:36:08.338078	2025-10-17 11:36:08.338078
151	\N	2025	15	0	15	0	2025-10-17 11:36:08.547466	2025-10-17 11:36:08.547466
152	\N	2025	15	0	15	0	2025-10-17 11:36:08.650259	2025-10-17 11:36:08.650259
153	\N	2025	15	0	15	0	2025-10-17 11:36:09.386063	2025-10-17 11:36:09.386063
154	\N	2025	15	0	15	0	2025-10-17 11:36:09.489039	2025-10-17 11:36:09.489039
155	\N	2025	15	0	15	0	2025-10-17 11:36:09.682388	2025-10-17 11:36:09.682388
156	\N	2025	15	0	15	0	2025-10-17 11:36:09.773519	2025-10-17 11:36:09.773519
157	\N	2025	15	0	15	0	2025-10-17 11:36:10.448795	2025-10-17 11:36:10.448795
158	\N	2025	15	0	15	0	2025-10-17 11:36:10.548381	2025-10-17 11:36:10.548381
159	\N	2025	15	0	15	0	2025-10-17 11:36:10.651235	2025-10-17 11:36:10.651235
160	\N	2025	15	0	15	0	2025-10-17 11:36:10.825251	2025-10-17 11:36:10.825251
161	\N	2025	15	0	15	0	2025-10-17 11:36:11.215597	2025-10-17 11:36:11.215597
162	\N	2025	15	0	15	0	2025-10-17 11:36:11.308121	2025-10-17 11:36:11.308121
163	\N	2025	15	0	15	0	2025-10-17 11:36:11.409382	2025-10-17 11:36:11.409382
164	\N	2025	15	0	15	0	2025-10-17 11:36:11.580929	2025-10-17 11:36:11.580929
165	\N	2025	15	0	15	0	2025-10-17 11:36:15.762633	2025-10-17 11:36:15.762633
166	\N	2025	15	0	15	0	2025-10-17 11:36:15.842556	2025-10-17 11:36:15.842556
167	\N	2025	15	0	15	0	2025-10-17 11:36:16.140263	2025-10-17 11:36:16.140263
168	\N	2025	15	0	15	0	2025-10-17 11:36:16.288506	2025-10-17 11:36:16.288506
169	\N	2025	15	0	15	0	2025-10-17 11:36:17.378055	2025-10-17 11:36:17.378055
170	\N	2025	15	0	15	0	2025-10-17 11:36:17.470266	2025-10-17 11:36:17.470266
171	\N	2025	15	0	15	0	2025-10-17 11:36:23.362852	2025-10-17 11:36:23.362852
172	\N	2025	15	0	15	0	2025-10-17 11:36:23.457776	2025-10-17 11:36:23.457776
173	\N	2025	15	0	15	0	2025-10-17 11:36:23.540338	2025-10-17 11:36:23.540338
174	\N	2025	15	0	15	0	2025-10-17 11:36:23.741003	2025-10-17 11:36:23.741003
175	\N	2025	15	0	15	0	2025-10-17 11:36:23.842528	2025-10-17 11:36:23.842528
176	\N	2025	15	0	15	0	2025-10-17 11:36:23.9372	2025-10-17 11:36:23.9372
177	\N	2025	15	0	15	0	2025-10-17 11:36:24.111366	2025-10-17 11:36:24.111366
178	\N	2025	15	0	15	0	2025-10-17 11:36:24.21847	2025-10-17 11:36:24.21847
179	\N	2025	15	0	15	0	2025-10-17 11:36:24.310187	2025-10-17 11:36:24.310187
180	\N	2025	15	0	15	0	2025-10-17 11:36:24.499388	2025-10-17 11:36:24.499388
181	\N	2025	15	0	15	0	2025-10-17 11:36:24.586736	2025-10-17 11:36:24.586736
182	\N	2025	15	0	15	0	2025-10-17 11:36:24.769328	2025-10-17 11:36:24.769328
183	\N	2025	15	0	15	0	2025-10-17 11:36:24.89238	2025-10-17 11:36:24.89238
184	\N	2025	15	0	15	0	2025-10-17 11:36:24.9867	2025-10-17 11:36:24.9867
185	\N	2025	15	0	15	0	2025-10-17 11:36:25.086018	2025-10-17 11:36:25.086018
186	\N	2025	15	0	15	0	2025-10-17 11:36:25.262547	2025-10-17 11:36:25.262547
187	\N	2025	15	0	15	0	2025-10-17 11:36:25.349947	2025-10-17 11:36:25.349947
188	\N	2025	15	0	15	0	2025-10-17 11:36:25.442204	2025-10-17 11:36:25.442204
189	\N	2025	15	0	15	0	2025-10-17 11:36:26.411306	2025-10-17 11:36:26.411306
190	\N	2025	15	0	15	0	2025-10-17 11:36:26.541096	2025-10-17 11:36:26.541096
191	\N	2025	15	0	15	0	2025-10-17 11:36:26.642798	2025-10-17 11:36:26.642798
192	\N	2025	15	0	15	0	2025-10-17 11:36:26.813057	2025-10-17 11:36:26.813057
193	\N	2025	15	0	15	0	2025-10-17 11:36:26.907568	2025-10-17 11:36:26.907568
194	\N	2025	15	0	15	0	2025-10-17 11:36:27.004934	2025-10-17 11:36:27.004934
195	\N	2025	15	0	15	0	2025-10-17 11:36:27.160033	2025-10-17 11:36:27.160033
196	\N	2025	15	0	15	0	2025-10-17 11:36:27.538172	2025-10-17 11:36:27.538172
197	\N	2025	15	0	15	0	2025-10-17 11:36:27.615476	2025-10-17 11:36:27.615476
198	\N	2025	15	0	15	0	2025-10-17 11:36:27.708868	2025-10-17 11:36:27.708868
199	\N	2025	15	0	15	0	2025-10-17 11:36:27.809425	2025-10-17 11:36:27.809425
200	\N	2025	15	0	15	0	2025-10-17 11:36:28.469643	2025-10-17 11:36:28.469643
201	\N	2025	15	0	15	0	2025-10-17 11:36:28.562937	2025-10-17 11:36:28.562937
202	\N	2025	15	0	15	0	2025-10-17 11:36:28.847095	2025-10-17 11:36:28.847095
203	\N	2025	15	0	15	0	2025-10-17 11:36:29.16554	2025-10-17 11:36:29.16554
204	\N	2025	15	0	15	0	2025-10-17 11:36:29.447469	2025-10-17 11:36:29.447469
205	\N	2025	15	0	15	0	2025-10-17 11:36:29.586048	2025-10-17 11:36:29.586048
206	\N	2025	15	0	15	0	2025-10-17 11:36:29.66855	2025-10-17 11:36:29.66855
207	\N	2025	15	0	15	0	2025-10-17 11:36:29.948305	2025-10-17 11:36:29.948305
208	\N	2025	15	0	15	0	2025-10-17 11:36:30.028238	2025-10-17 11:36:30.028238
209	\N	2025	15	0	15	0	2025-10-17 11:36:30.188913	2025-10-17 11:36:30.188913
210	\N	2025	15	0	15	0	2025-10-17 11:36:30.278791	2025-10-17 11:36:30.278791
211	\N	2025	15	0	15	0	2025-10-17 11:36:30.358321	2025-10-17 11:36:30.358321
212	\N	2025	15	0	15	0	2025-10-17 11:45:28.403681	2025-10-17 11:45:28.403681
213	\N	2025	15	0	15	0	2025-10-17 11:45:35.34242	2025-10-17 11:45:35.34242
214	\N	2025	15	0	15	0	2025-10-17 11:45:38.492974	2025-10-17 11:45:38.492974
215	\N	2025	15	0	15	0	2025-10-17 11:45:40.670697	2025-10-17 11:45:40.670697
216	\N	2025	15	0	15	0	2025-10-17 11:45:41.175711	2025-10-17 11:45:41.175711
217	\N	2025	15	0	15	0	2025-10-17 11:45:46.038301	2025-10-17 11:45:46.038301
218	\N	2025	15	0	15	0	2025-10-17 11:45:47.165635	2025-10-17 11:45:47.165635
219	\N	2025	15	0	15	0	2025-10-17 11:45:48.895367	2025-10-17 11:45:48.895367
220	\N	2025	15	0	15	0	2025-10-17 11:45:50.165618	2025-10-17 11:45:50.165618
221	\N	2025	15	0	15	0	2025-10-17 11:45:50.24633	2025-10-17 11:45:50.24633
222	\N	2025	15	0	15	0	2025-10-17 11:45:50.580638	2025-10-17 11:45:50.580638
223	\N	2025	15	0	15	0	2025-10-17 11:45:50.730871	2025-10-17 11:45:50.730871
224	\N	2025	15	0	15	0	2025-10-17 11:45:50.92757	2025-10-17 11:45:50.92757
225	\N	2025	15	0	15	0	2025-10-17 11:45:51.058519	2025-10-17 11:45:51.058519
226	\N	2025	15	0	15	0	2025-10-17 11:45:51.303276	2025-10-17 11:45:51.303276
227	\N	2025	15	0	15	0	2025-10-17 11:45:51.463737	2025-10-17 11:45:51.463737
228	\N	2025	15	0	15	0	2025-10-17 11:45:53.583631	2025-10-17 11:45:53.583631
229	\N	2025	15	0	15	0	2025-10-17 11:45:53.972741	2025-10-17 11:45:53.972741
230	\N	2025	15	0	15	0	2025-10-17 11:45:54.048604	2025-10-17 11:45:54.048604
231	\N	2025	15	0	15	0	2025-10-17 11:45:54.126874	2025-10-17 11:45:54.126874
232	\N	2025	15	0	15	0	2025-10-17 11:45:54.209029	2025-10-17 11:45:54.209029
233	\N	2025	15	0	15	0	2025-10-17 11:45:54.440377	2025-10-17 11:45:54.440377
234	\N	2025	15	0	15	0	2025-10-17 11:45:54.511638	2025-10-17 11:45:54.511638
235	\N	2025	15	0	15	0	2025-10-17 11:45:54.991154	2025-10-17 11:45:54.991154
236	\N	2025	15	0	15	0	2025-10-17 11:45:55.138446	2025-10-17 11:45:55.138446
237	\N	2025	15	0	15	0	2025-10-17 11:45:55.218654	2025-10-17 11:45:55.218654
238	\N	2025	15	0	15	0	2025-10-17 11:45:55.286247	2025-10-17 11:45:55.286247
239	\N	2025	15	0	15	0	2025-10-17 11:45:55.948875	2025-10-17 11:45:55.948875
240	\N	2025	15	0	15	0	2025-10-17 11:45:56.028189	2025-10-17 11:45:56.028189
241	\N	2025	15	0	15	0	2025-10-17 11:45:56.111368	2025-10-17 11:45:56.111368
242	\N	2025	15	0	15	0	2025-10-17 11:45:56.263392	2025-10-17 11:45:56.263392
243	\N	2025	15	0	15	0	2025-10-17 11:45:58.165592	2025-10-17 11:45:58.165592
244	\N	2025	15	0	15	0	2025-10-17 11:45:58.250923	2025-10-17 11:45:58.250923
245	\N	2025	15	0	15	0	2025-10-17 11:45:58.329303	2025-10-17 11:45:58.329303
246	\N	2025	15	0	15	0	2025-10-17 11:45:58.566375	2025-10-17 11:45:58.566375
247	\N	2025	15	0	15	0	2025-10-17 11:46:18.460808	2025-10-17 11:46:18.460808
248	\N	2025	15	0	15	0	2025-10-17 11:46:22.979077	2025-10-17 11:46:22.979077
249	\N	2025	15	0	15	0	2025-10-17 11:46:27.08342	2025-10-17 11:46:27.08342
250	\N	2025	15	0	15	0	2025-10-17 11:46:27.497625	2025-10-17 11:46:27.497625
251	\N	2025	15	0	15	0	2025-10-17 11:46:44.274891	2025-10-17 11:46:44.274891
252	\N	2025	15	0	15	0	2025-10-17 11:46:44.908179	2025-10-17 11:46:44.908179
253	\N	2025	15	0	15	0	2025-10-17 11:46:56.580368	2025-10-17 11:46:56.580368
254	\N	2025	15	0	15	0	2025-10-17 11:46:56.750684	2025-10-17 11:46:56.750684
255	\N	2025	15	0	15	0	2025-10-17 11:46:56.863657	2025-10-17 11:46:56.863657
256	\N	2025	15	0	15	0	2025-10-17 11:46:56.933449	2025-10-17 11:46:56.933449
257	\N	2025	15	0	15	0	2025-10-17 11:46:57.051312	2025-10-17 11:46:57.051312
258	\N	2025	15	0	15	0	2025-10-17 11:46:57.136941	2025-10-17 11:46:57.136941
259	\N	2025	15	0	15	0	2025-10-17 11:46:57.21649	2025-10-17 11:46:57.21649
260	\N	2025	15	0	15	0	2025-10-17 11:46:57.293153	2025-10-17 11:46:57.293153
261	\N	2025	15	0	15	0	2025-10-17 11:46:57.437645	2025-10-17 11:46:57.437645
262	\N	2025	15	0	15	0	2025-10-17 11:46:57.523589	2025-10-17 11:46:57.523589
263	\N	2025	15	0	15	0	2025-10-17 11:46:57.603559	2025-10-17 11:46:57.603559
264	\N	2025	15	0	15	0	2025-10-17 11:46:57.814247	2025-10-17 11:46:57.814247
265	\N	2025	15	0	15	0	2025-10-17 11:46:57.900901	2025-10-17 11:46:57.900901
266	\N	2025	15	0	15	0	2025-10-17 11:46:57.982804	2025-10-17 11:46:57.982804
267	\N	2025	15	0	15	0	2025-10-17 11:46:58.062167	2025-10-17 11:46:58.062167
268	\N	2025	15	0	15	0	2025-10-17 11:46:58.191749	2025-10-17 11:46:58.191749
269	\N	2025	15	0	15	0	2025-10-17 11:46:58.291401	2025-10-17 11:46:58.291401
270	\N	2025	15	0	15	0	2025-10-17 11:46:58.364664	2025-10-17 11:46:58.364664
271	\N	2025	15	0	15	0	2025-10-17 11:46:58.966061	2025-10-17 11:46:58.966061
272	\N	2025	15	0	15	0	2025-10-17 11:46:59.038413	2025-10-17 11:46:59.038413
273	\N	2025	15	0	15	0	2025-10-17 11:46:59.127052	2025-10-17 11:46:59.127052
274	\N	2025	15	0	15	0	2025-10-17 11:46:59.20515	2025-10-17 11:46:59.20515
275	\N	2025	15	0	15	0	2025-10-17 11:46:59.34036	2025-10-17 11:46:59.34036
276	\N	2025	15	0	15	0	2025-10-17 11:46:59.452543	2025-10-17 11:46:59.452543
277	\N	2025	15	0	15	0	2025-10-17 11:46:59.539534	2025-10-17 11:46:59.539534
278	\N	2025	15	0	15	0	2025-10-17 11:46:59.72248	2025-10-17 11:46:59.72248
279	\N	2025	15	0	15	0	2025-10-17 11:46:59.803467	2025-10-17 11:46:59.803467
280	\N	2025	15	0	15	0	2025-10-17 11:46:59.879366	2025-10-17 11:46:59.879366
281	\N	2025	15	0	15	0	2025-10-17 11:46:59.947521	2025-10-17 11:46:59.947521
282	\N	2025	15	0	15	0	2025-10-17 11:47:00.345515	2025-10-17 11:47:00.345515
283	\N	2025	15	0	15	0	2025-10-17 11:47:00.47776	2025-10-17 11:47:00.47776
284	\N	2025	15	0	15	0	2025-10-17 11:47:00.557858	2025-10-17 11:47:00.557858
285	\N	2025	15	0	15	0	2025-10-17 11:47:00.883676	2025-10-17 11:47:00.883676
286	\N	2025	15	0	15	0	2025-10-17 11:47:01.049203	2025-10-17 11:47:01.049203
287	\N	2025	15	0	15	0	2025-10-17 11:47:01.232654	2025-10-17 11:47:01.232654
288	\N	2025	15	0	15	0	2025-10-17 11:47:01.329493	2025-10-17 11:47:01.329493
289	\N	2025	15	0	15	0	2025-10-17 11:47:01.611584	2025-10-17 11:47:01.611584
290	\N	2025	15	0	15	0	2025-10-17 11:47:01.701056	2025-10-17 11:47:01.701056
291	\N	2025	15	0	15	0	2025-10-17 11:47:01.778591	2025-10-17 11:47:01.778591
292	\N	2025	15	0	15	0	2025-10-17 11:47:01.872612	2025-10-17 11:47:01.872612
293	\N	2025	15	0	15	0	2025-10-17 11:47:01.999396	2025-10-17 11:47:01.999396
294	\N	2025	15	0	15	0	2025-10-17 11:51:10.702049	2025-10-17 11:51:10.702049
295	\N	2025	15	0	15	0	2025-10-17 11:51:10.780451	2025-10-17 11:51:10.780451
296	\N	2025	15	0	15	0	2025-10-17 11:51:10.862301	2025-10-17 11:51:10.862301
297	\N	2025	15	0	15	0	2025-10-17 11:51:11.04642	2025-10-17 11:51:11.04642
298	\N	2025	15	0	15	0	2025-10-17 11:51:11.127639	2025-10-17 11:51:11.127639
299	\N	2025	15	0	15	0	2025-10-17 11:51:11.417598	2025-10-17 11:51:11.417598
300	\N	2025	15	0	15	0	2025-10-17 11:51:11.517573	2025-10-17 11:51:11.517573
301	\N	2025	15	0	15	0	2025-10-17 11:51:11.608683	2025-10-17 11:51:11.608683
302	\N	2025	15	0	15	0	2025-10-17 11:51:11.686415	2025-10-17 11:51:11.686415
303	\N	2025	15	0	15	0	2025-10-17 11:51:11.856777	2025-10-17 11:51:11.856777
304	\N	2025	15	0	15	0	2025-10-17 11:51:12.189438	2025-10-17 11:51:12.189438
305	\N	2025	15	0	15	0	2025-10-17 11:51:12.264468	2025-10-17 11:51:12.264468
306	\N	2025	15	0	15	0	2025-10-17 11:51:12.342154	2025-10-17 11:51:12.342154
307	\N	2025	15	0	15	0	2025-10-17 11:51:12.421258	2025-10-17 11:51:12.421258
308	\N	2025	15	0	15	0	2025-10-17 11:51:12.653799	2025-10-17 11:51:12.653799
309	\N	2025	15	0	15	0	2025-10-17 11:51:12.754227	2025-10-17 11:51:12.754227
310	\N	2025	15	0	15	0	2025-10-17 11:51:13.199782	2025-10-17 11:51:13.199782
311	\N	2025	15	0	15	0	2025-10-17 11:51:13.533639	2025-10-17 11:51:13.533639
312	\N	2025	15	0	15	0	2025-10-17 11:51:13.700397	2025-10-17 11:51:13.700397
313	\N	2025	15	0	15	0	2025-10-17 11:51:13.783648	2025-10-17 11:51:13.783648
314	\N	2025	15	0	15	0	2025-10-17 11:51:13.855484	2025-10-17 11:51:13.855484
315	\N	2025	15	0	15	0	2025-10-17 11:51:14.093318	2025-10-17 11:51:14.093318
316	\N	2025	15	0	15	0	2025-10-17 11:51:14.183492	2025-10-17 11:51:14.183492
317	\N	2025	15	0	15	0	2025-10-17 11:51:14.671649	2025-10-17 11:51:14.671649
318	\N	2025	15	0	15	0	2025-10-17 11:51:14.844449	2025-10-17 11:51:14.844449
319	\N	2025	15	0	15	0	2025-10-17 11:51:15.3129	2025-10-17 11:51:15.3129
320	\N	2025	15	0	15	0	2025-10-17 11:51:15.42324	2025-10-17 11:51:15.42324
321	\N	2025	15	0	15	0	2025-10-17 11:51:15.982483	2025-10-17 11:51:15.982483
322	\N	2025	15	0	15	0	2025-10-17 11:51:16.060505	2025-10-17 11:51:16.060505
323	\N	2025	15	0	15	0	2025-10-17 11:51:16.141658	2025-10-17 11:51:16.141658
324	\N	2025	15	0	15	0	2025-10-17 11:51:16.214932	2025-10-17 11:51:16.214932
325	\N	2025	15	0	15	0	2025-10-17 11:51:16.602371	2025-10-17 11:51:16.602371
326	\N	2025	15	0	15	0	2025-10-17 11:51:16.741492	2025-10-17 11:51:16.741492
327	\N	2025	15	0	15	0	2025-10-17 11:51:16.822382	2025-10-17 11:51:16.822382
328	\N	2025	15	0	15	0	2025-10-17 11:51:16.901433	2025-10-17 11:51:16.901433
329	\N	2025	15	0	15	0	2025-10-17 11:51:18.130615	2025-10-17 11:51:18.130615
330	\N	2025	15	0	15	0	2025-10-17 11:51:18.266253	2025-10-17 11:51:18.266253
331	\N	2025	15	0	15	0	2025-10-17 11:51:18.371993	2025-10-17 11:51:18.371993
332	\N	2025	15	0	15	0	2025-10-17 11:51:18.494631	2025-10-17 11:51:18.494631
333	\N	2025	15	0	15	0	2025-10-17 11:51:19.869427	2025-10-17 11:51:19.869427
334	\N	2025	15	0	15	0	2025-10-17 11:51:19.943792	2025-10-17 11:51:19.943792
335	\N	2025	15	0	15	0	2025-10-17 11:51:22.82987	2025-10-17 11:51:22.82987
336	\N	2025	15	0	15	0	2025-10-17 11:51:23.06942	2025-10-17 11:51:23.06942
337	\N	2025	15	0	15	0	2025-10-17 11:51:23.206384	2025-10-17 11:51:23.206384
338	\N	2025	15	0	15	0	2025-10-17 11:51:23.287605	2025-10-17 11:51:23.287605
339	\N	2025	15	0	15	0	2025-10-17 11:51:23.405782	2025-10-17 11:51:23.405782
340	\N	2025	15	0	15	0	2025-10-17 11:51:23.573494	2025-10-17 11:51:23.573494
341	\N	2025	15	0	15	0	2025-10-17 11:51:23.662678	2025-10-17 11:51:23.662678
342	\N	2025	15	0	15	0	2025-10-17 11:51:23.757883	2025-10-17 11:51:23.757883
343	\N	2025	15	0	15	0	2025-10-17 11:51:23.846545	2025-10-17 11:51:23.846545
344	\N	2025	15	0	15	0	2025-10-17 11:51:23.96238	2025-10-17 11:51:23.96238
345	\N	2025	15	0	15	0	2025-10-17 11:51:24.035415	2025-10-17 11:51:24.035415
346	\N	2025	15	0	15	0	2025-10-17 11:51:24.176343	2025-10-17 11:51:24.176343
347	\N	2025	15	0	15	0	2025-10-17 11:51:24.341393	2025-10-17 11:51:24.341393
348	\N	2025	15	0	15	0	2025-10-17 11:51:24.413603	2025-10-17 11:51:24.413603
349	\N	2025	15	0	15	0	2025-10-17 11:51:24.501825	2025-10-17 11:51:24.501825
350	\N	2025	15	0	15	0	2025-10-17 11:51:24.578892	2025-10-17 11:51:24.578892
351	\N	2025	15	0	15	0	2025-10-17 11:51:24.7263	2025-10-17 11:51:24.7263
352	\N	2025	15	0	15	0	2025-10-17 11:51:24.808405	2025-10-17 11:51:24.808405
353	\N	2025	15	0	15	0	2025-10-17 11:51:25.571572	2025-10-17 11:51:25.571572
354	\N	2025	15	0	15	0	2025-10-17 11:51:25.652823	2025-10-17 11:51:25.652823
355	\N	2025	15	0	15	0	2025-10-17 11:51:25.733605	2025-10-17 11:51:25.733605
356	\N	2025	15	0	15	0	2025-10-17 11:51:25.859381	2025-10-17 11:51:25.859381
357	\N	2025	15	0	15	0	2025-10-17 11:51:25.964433	2025-10-17 11:51:25.964433
358	\N	2025	15	0	15	0	2025-10-17 11:51:26.042514	2025-10-17 11:51:26.042514
359	\N	2025	15	0	15	0	2025-10-17 11:51:26.12433	2025-10-17 11:51:26.12433
360	\N	2025	15	0	15	0	2025-10-17 11:51:26.242513	2025-10-17 11:51:26.242513
361	\N	2025	15	0	15	0	2025-10-17 11:51:26.317402	2025-10-17 11:51:26.317402
362	\N	2025	15	0	15	0	2025-10-17 11:51:26.406446	2025-10-17 11:51:26.406446
363	\N	2025	15	0	15	0	2025-10-17 11:51:26.501358	2025-10-17 11:51:26.501358
364	\N	2025	15	0	15	0	2025-10-17 11:51:27.002892	2025-10-17 11:51:27.002892
365	\N	2025	15	0	15	0	2025-10-17 11:51:27.081236	2025-10-17 11:51:27.081236
366	\N	2025	15	0	15	0	2025-10-17 11:51:27.162397	2025-10-17 11:51:27.162397
367	\N	2025	15	0	15	0	2025-10-17 11:51:27.456878	2025-10-17 11:51:27.456878
368	\N	2025	15	0	15	0	2025-10-17 11:51:27.613499	2025-10-17 11:51:27.613499
369	\N	2025	15	0	15	0	2025-10-17 11:51:27.766462	2025-10-17 11:51:27.766462
370	\N	2025	15	0	15	0	2025-10-17 11:51:27.846326	2025-10-17 11:51:27.846326
371	\N	2025	15	0	15	0	2025-10-17 11:51:28.01181	2025-10-17 11:51:28.01181
372	\N	2025	15	0	15	0	2025-10-17 11:51:28.145561	2025-10-17 11:51:28.145561
373	\N	2025	15	0	15	0	2025-10-17 11:51:28.248255	2025-10-17 11:51:28.248255
374	\N	2025	15	0	15	0	2025-10-17 11:51:28.326411	2025-10-17 11:51:28.326411
375	\N	2025	15	0	15	0	2025-10-17 11:51:28.406365	2025-10-17 11:51:28.406365
376	\N	2025	15	0	15	0	2025-10-17 11:55:28.921782	2025-10-17 11:55:28.921782
377	\N	2025	15	0	15	0	2025-10-17 11:55:29.061587	2025-10-17 11:55:29.061587
378	\N	2025	15	0	15	0	2025-10-17 11:55:29.138701	2025-10-17 11:55:29.138701
379	\N	2025	15	0	15	0	2025-10-17 11:55:29.216505	2025-10-17 11:55:29.216505
380	\N	2025	15	0	15	0	2025-10-17 11:55:29.293591	2025-10-17 11:55:29.293591
381	\N	2025	15	0	15	0	2025-10-17 11:55:29.644709	2025-10-17 11:55:29.644709
382	\N	2025	15	0	15	0	2025-10-17 11:55:29.840399	2025-10-17 11:55:29.840399
383	\N	2025	15	0	15	0	2025-10-17 11:55:29.926961	2025-10-17 11:55:29.926961
384	\N	2025	15	0	15	0	2025-10-17 11:55:29.997248	2025-10-17 11:55:29.997248
385	\N	2025	15	0	15	0	2025-10-17 11:55:30.077429	2025-10-17 11:55:30.077429
386	\N	2025	15	0	15	0	2025-10-17 11:55:30.34952	2025-10-17 11:55:30.34952
387	\N	2025	15	0	15	0	2025-10-17 11:55:30.425279	2025-10-17 11:55:30.425279
388	\N	2025	15	0	15	0	2025-10-17 11:55:30.582165	2025-10-17 11:55:30.582165
389	\N	2025	15	0	15	0	2025-10-17 11:55:30.660207	2025-10-17 11:55:30.660207
390	\N	2025	15	0	15	0	2025-10-17 11:55:30.831526	2025-10-17 11:55:30.831526
391	\N	2025	15	0	15	0	2025-10-17 11:55:30.965439	2025-10-17 11:55:30.965439
392	\N	2025	15	0	15	0	2025-10-17 11:55:31.42235	2025-10-17 11:55:31.42235
393	\N	2025	15	0	15	0	2025-10-17 11:55:31.823566	2025-10-17 11:55:31.823566
394	\N	2025	15	0	15	0	2025-10-17 11:55:31.903308	2025-10-17 11:55:31.903308
395	\N	2025	15	0	15	0	2025-10-17 11:55:31.971495	2025-10-17 11:55:31.971495
396	\N	2025	15	0	15	0	2025-10-17 11:55:32.102294	2025-10-17 11:55:32.102294
397	\N	2025	15	0	15	0	2025-10-17 11:55:32.277066	2025-10-17 11:55:32.277066
398	\N	2025	15	0	15	0	2025-10-17 11:55:32.350474	2025-10-17 11:55:32.350474
399	\N	2025	15	0	15	0	2025-10-17 11:55:32.928061	2025-10-17 11:55:32.928061
400	\N	2025	15	0	15	0	2025-10-17 11:55:33.037913	2025-10-17 11:55:33.037913
401	\N	2025	15	0	15	0	2025-10-17 11:55:33.123498	2025-10-17 11:55:33.123498
402	\N	2025	15	0	15	0	2025-10-17 11:55:33.238668	2025-10-17 11:55:33.238668
403	\N	2025	15	0	15	0	2025-10-17 11:55:33.713563	2025-10-17 11:55:33.713563
404	\N	2025	15	0	15	0	2025-10-17 11:55:33.791532	2025-10-17 11:55:33.791532
405	\N	2025	15	0	15	0	2025-10-17 11:55:33.863417	2025-10-17 11:55:33.863417
406	\N	2025	15	0	15	0	2025-10-17 11:55:34.005912	2025-10-17 11:55:34.005912
407	\N	2025	15	0	15	0	2025-10-17 11:55:34.38118	2025-10-17 11:55:34.38118
408	\N	2025	15	0	15	0	2025-10-17 11:55:34.460833	2025-10-17 11:55:34.460833
409	\N	2025	15	0	15	0	2025-10-17 11:55:34.542224	2025-10-17 11:55:34.542224
410	\N	2025	15	0	15	0	2025-10-17 11:55:34.61854	2025-10-17 11:55:34.61854
411	\N	2025	15	0	15	0	2025-10-17 11:55:35.895692	2025-10-17 11:55:35.895692
412	\N	2025	15	0	15	0	2025-10-17 11:55:35.963776	2025-10-17 11:55:35.963776
413	\N	2025	15	0	15	0	2025-10-17 11:55:36.043071	2025-10-17 11:55:36.043071
414	\N	2025	15	0	15	0	2025-10-17 11:55:36.118387	2025-10-17 11:55:36.118387
415	\N	2025	15	0	15	0	2025-10-17 11:55:37.197389	2025-10-17 11:55:37.197389
416	\N	2025	15	0	15	0	2025-10-17 11:55:37.28549	2025-10-17 11:55:37.28549
417	\N	2025	15	0	15	0	2025-10-17 11:55:38.931322	2025-10-17 11:55:38.931322
418	\N	2025	15	0	15	0	2025-10-17 11:55:39.021335	2025-10-17 11:55:39.021335
419	\N	2025	15	0	15	0	2025-10-17 11:55:39.104736	2025-10-17 11:55:39.104736
420	\N	2025	15	0	15	0	2025-10-17 11:55:39.197228	2025-10-17 11:55:39.197228
421	\N	2025	15	0	15	0	2025-10-17 11:55:39.322212	2025-10-17 11:55:39.322212
422	\N	2025	15	0	15	0	2025-10-17 11:55:39.39532	2025-10-17 11:55:39.39532
423	\N	2025	15	0	15	0	2025-10-17 11:55:39.479072	2025-10-17 11:55:39.479072
424	\N	2025	15	0	15	0	2025-10-17 11:55:39.552472	2025-10-17 11:55:39.552472
425	\N	2025	15	0	15	0	2025-10-17 11:55:39.701721	2025-10-17 11:55:39.701721
426	\N	2025	15	0	15	0	2025-10-17 11:55:39.781808	2025-10-17 11:55:39.781808
427	\N	2025	15	0	15	0	2025-10-17 11:55:39.86331	2025-10-17 11:55:39.86331
428	\N	2025	15	0	15	0	2025-10-17 11:55:40.106156	2025-10-17 11:55:40.106156
429	\N	2025	15	0	15	0	2025-10-17 11:55:40.187604	2025-10-17 11:55:40.187604
430	\N	2025	15	0	15	0	2025-10-17 11:55:40.275379	2025-10-17 11:55:40.275379
431	\N	2025	15	0	15	0	2025-10-17 11:55:40.456311	2025-10-17 11:55:40.456311
432	\N	2025	15	0	15	0	2025-10-17 11:55:40.526289	2025-10-17 11:55:40.526289
433	\N	2025	15	0	15	0	2025-10-17 11:55:40.608744	2025-10-17 11:55:40.608744
434	\N	2025	15	0	15	0	2025-10-17 11:55:40.681575	2025-10-17 11:55:40.681575
435	\N	2025	15	0	15	0	2025-10-17 11:55:41.290997	2025-10-17 11:55:41.290997
436	\N	2025	15	0	15	0	2025-10-17 11:55:41.383746	2025-10-17 11:55:41.383746
437	\N	2025	15	0	15	0	2025-10-17 11:55:41.472145	2025-10-17 11:55:41.472145
438	\N	2025	15	0	15	0	2025-10-17 11:55:41.607764	2025-10-17 11:55:41.607764
439	\N	2025	15	0	15	0	2025-10-17 11:55:41.678249	2025-10-17 11:55:41.678249
440	\N	2025	15	0	15	0	2025-10-17 11:55:41.757335	2025-10-17 11:55:41.757335
441	\N	2025	15	0	15	0	2025-10-17 11:55:41.837797	2025-10-17 11:55:41.837797
442	\N	2025	15	0	15	0	2025-10-17 11:55:42.008455	2025-10-17 11:55:42.008455
443	\N	2025	15	0	15	0	2025-10-17 11:55:42.084496	2025-10-17 11:55:42.084496
444	\N	2025	15	0	15	0	2025-10-17 11:55:42.157507	2025-10-17 11:55:42.157507
445	\N	2025	15	0	15	0	2025-10-17 11:55:42.246178	2025-10-17 11:55:42.246178
446	\N	2025	15	0	15	0	2025-10-17 11:55:42.611337	2025-10-17 11:55:42.611337
447	\N	2025	15	0	15	0	2025-10-17 11:55:42.73804	2025-10-17 11:55:42.73804
448	\N	2025	15	0	15	0	2025-10-17 11:55:42.815346	2025-10-17 11:55:42.815346
449	\N	2025	15	0	15	0	2025-10-17 11:55:43.117157	2025-10-17 11:55:43.117157
450	\N	2025	15	0	15	0	2025-10-17 11:55:43.291379	2025-10-17 11:55:43.291379
451	\N	2025	15	0	15	0	2025-10-17 11:55:43.381743	2025-10-17 11:55:43.381743
452	\N	2025	15	0	15	0	2025-10-17 11:55:43.501272	2025-10-17 11:55:43.501272
453	\N	2025	15	0	15	0	2025-10-17 11:55:43.664413	2025-10-17 11:55:43.664413
454	\N	2025	15	0	15	0	2025-10-17 11:55:43.742527	2025-10-17 11:55:43.742527
455	\N	2025	15	0	15	0	2025-10-17 11:55:43.88372	2025-10-17 11:55:43.88372
456	\N	2025	15	0	15	0	2025-10-17 11:55:43.997615	2025-10-17 11:55:43.997615
457	\N	2025	15	0	15	0	2025-10-17 11:55:44.07952	2025-10-17 11:55:44.07952
458	\N	2025	15	0	15	0	2025-10-17 12:10:24.459294	2025-10-17 12:10:24.459294
459	\N	2025	15	0	15	0	2025-10-17 12:10:24.648332	2025-10-17 12:10:24.648332
460	\N	2025	15	0	15	0	2025-10-17 12:10:24.799093	2025-10-17 12:10:24.799093
461	\N	2025	15	0	15	0	2025-10-17 12:10:24.885576	2025-10-17 12:10:24.885576
462	\N	2025	15	0	15	0	2025-10-17 12:10:26.699185	2025-10-17 12:10:26.699185
463	\N	2025	15	0	15	0	2025-10-17 12:10:26.874223	2025-10-17 12:10:26.874223
464	\N	2025	15	0	15	0	2025-10-17 12:10:27.08646	2025-10-17 12:10:27.08646
465	\N	2025	15	0	15	0	2025-10-17 12:10:27.166018	2025-10-17 12:10:27.166018
466	\N	2025	15	0	15	0	2025-10-17 12:10:27.250264	2025-10-17 12:10:27.250264
467	\N	2025	15	0	15	0	2025-10-17 12:10:27.463126	2025-10-17 12:10:27.463126
468	\N	2025	15	0	15	0	2025-10-17 12:10:27.535949	2025-10-17 12:10:27.535949
469	\N	2025	15	0	15	0	2025-10-17 12:10:27.604184	2025-10-17 12:10:27.604184
470	\N	2025	15	0	15	0	2025-10-17 12:10:27.690211	2025-10-17 12:10:27.690211
471	\N	2025	15	0	15	0	2025-10-17 12:10:27.869128	2025-10-17 12:10:27.869128
472	\N	2025	15	0	15	0	2025-10-17 12:10:27.947209	2025-10-17 12:10:27.947209
473	\N	2025	15	0	15	0	2025-10-17 12:10:28.847125	2025-10-17 12:10:28.847125
474	\N	2025	15	0	15	0	2025-10-17 12:10:29.04737	2025-10-17 12:10:29.04737
475	\N	2025	15	0	15	0	2025-10-17 12:10:29.190102	2025-10-17 12:10:29.190102
476	\N	2025	15	0	15	0	2025-10-17 12:10:29.421111	2025-10-17 12:10:29.421111
477	\N	2025	15	0	15	0	2025-10-17 12:10:29.508893	2025-10-17 12:10:29.508893
478	\N	2025	15	0	15	0	2025-10-17 12:10:29.630695	2025-10-17 12:10:29.630695
479	\N	2025	15	0	15	0	2025-10-17 12:10:29.739039	2025-10-17 12:10:29.739039
480	\N	2025	15	0	15	0	2025-10-17 12:10:29.894884	2025-10-17 12:10:29.894884
481	\N	2025	15	0	15	0	2025-10-17 12:10:30.007846	2025-10-17 12:10:30.007846
482	\N	2025	15	0	15	0	2025-10-17 12:10:30.127568	2025-10-17 12:10:30.127568
483	\N	2025	15	0	15	0	2025-10-17 12:10:30.214103	2025-10-17 12:10:30.214103
484	\N	2025	15	0	15	0	2025-10-17 12:10:31.108078	2025-10-17 12:10:31.108078
485	\N	2025	15	0	15	0	2025-10-17 12:10:31.351304	2025-10-17 12:10:31.351304
486	\N	2025	15	0	15	0	2025-10-17 12:10:31.427131	2025-10-17 12:10:31.427131
487	\N	2025	15	0	15	0	2025-10-17 12:10:31.500527	2025-10-17 12:10:31.500527
488	\N	2025	15	0	15	0	2025-10-17 12:10:31.673909	2025-10-17 12:10:31.673909
489	\N	2025	15	0	15	0	2025-10-17 12:10:31.755476	2025-10-17 12:10:31.755476
490	\N	2025	15	0	15	0	2025-10-17 12:10:31.837994	2025-10-17 12:10:31.837994
491	\N	2025	15	0	15	0	2025-10-17 12:10:32.018153	2025-10-17 12:10:32.018153
492	\N	2025	15	0	15	0	2025-10-17 12:10:33.92278	2025-10-17 12:10:33.92278
493	\N	2025	15	0	15	0	2025-10-17 12:10:34.072444	2025-10-17 12:10:34.072444
494	\N	2025	15	0	15	0	2025-10-17 12:10:34.303063	2025-10-17 12:10:34.303063
495	\N	2025	15	0	15	0	2025-10-17 12:10:34.399388	2025-10-17 12:10:34.399388
496	\N	2025	15	0	15	0	2025-10-17 12:10:34.551319	2025-10-17 12:10:34.551319
497	\N	2025	15	0	15	0	2025-10-17 12:10:34.688356	2025-10-17 12:10:34.688356
498	\N	2025	15	0	15	0	2025-10-17 12:10:36.306884	2025-10-17 12:10:36.306884
499	\N	2025	15	0	15	0	2025-10-17 12:10:36.580682	2025-10-17 12:10:36.580682
500	\N	2025	15	0	15	0	2025-10-17 12:10:36.726284	2025-10-17 12:10:36.726284
501	\N	2025	15	0	15	0	2025-10-17 12:10:36.80764	2025-10-17 12:10:36.80764
502	\N	2025	15	0	15	0	2025-10-17 12:10:36.952139	2025-10-17 12:10:36.952139
503	\N	2025	15	0	15	0	2025-10-17 12:10:37.01717	2025-10-17 12:10:37.01717
504	\N	2025	15	0	15	0	2025-10-17 12:10:37.10807	2025-10-17 12:10:37.10807
505	\N	2025	15	0	15	0	2025-10-17 12:10:37.186243	2025-10-17 12:10:37.186243
506	\N	2025	15	0	15	0	2025-10-17 12:10:37.36725	2025-10-17 12:10:37.36725
507	\N	2025	15	0	15	0	2025-10-17 12:10:37.447868	2025-10-17 12:10:37.447868
508	\N	2025	15	0	15	0	2025-10-17 12:10:37.523668	2025-10-17 12:10:37.523668
509	\N	2025	15	0	15	0	2025-10-17 12:10:37.727755	2025-10-17 12:10:37.727755
510	\N	2025	15	0	15	0	2025-10-17 12:10:37.812743	2025-10-17 12:10:37.812743
511	\N	2025	15	0	15	0	2025-10-17 12:10:37.890811	2025-10-17 12:10:37.890811
512	\N	2025	15	0	15	0	2025-10-17 12:10:37.978646	2025-10-17 12:10:37.978646
513	\N	2025	15	0	15	0	2025-10-17 12:10:38.099817	2025-10-17 12:10:38.099817
514	\N	2025	15	0	15	0	2025-10-17 12:10:38.188342	2025-10-17 12:10:38.188342
515	\N	2025	15	0	15	0	2025-10-17 12:10:38.267731	2025-10-17 12:10:38.267731
516	\N	2025	15	0	15	0	2025-10-17 12:10:38.482812	2025-10-17 12:10:38.482812
517	\N	2025	15	0	15	0	2025-10-17 12:10:38.551248	2025-10-17 12:10:38.551248
518	\N	2025	15	0	15	0	2025-10-17 12:10:38.621171	2025-10-17 12:10:38.621171
519	\N	2025	15	0	15	0	2025-10-17 12:10:38.715817	2025-10-17 12:10:38.715817
520	\N	2025	15	0	15	0	2025-10-17 12:10:38.860457	2025-10-17 12:10:38.860457
521	\N	2025	15	0	15	0	2025-10-17 12:10:38.92876	2025-10-17 12:10:38.92876
522	\N	2025	15	0	15	0	2025-10-17 12:10:39.012086	2025-10-17 12:10:39.012086
523	\N	2025	15	0	15	0	2025-10-17 12:10:39.091342	2025-10-17 12:10:39.091342
524	\N	2025	15	0	15	0	2025-10-17 12:10:39.263737	2025-10-17 12:10:39.263737
525	\N	2025	15	0	15	0	2025-10-17 12:10:39.359009	2025-10-17 12:10:39.359009
526	\N	2025	15	0	15	0	2025-10-17 12:10:39.459465	2025-10-17 12:10:39.459465
527	\N	2025	15	0	15	0	2025-10-17 12:10:39.67154	2025-10-17 12:10:39.67154
528	\N	2025	15	0	15	0	2025-10-17 12:10:39.75167	2025-10-17 12:10:39.75167
529	\N	2025	15	0	15	0	2025-10-17 12:10:39.825587	2025-10-17 12:10:39.825587
530	\N	2025	15	0	15	0	2025-10-17 12:10:40.180374	2025-10-17 12:10:40.180374
531	\N	2025	15	0	15	0	2025-10-17 12:10:40.377858	2025-10-17 12:10:40.377858
532	\N	2025	15	0	15	0	2025-10-17 12:10:40.536529	2025-10-17 12:10:40.536529
533	\N	2025	15	0	15	0	2025-10-17 12:10:40.6203	2025-10-17 12:10:40.6203
534	\N	2025	15	0	15	0	2025-10-17 12:10:40.859474	2025-10-17 12:10:40.859474
535	\N	2025	15	0	15	0	2025-10-17 12:10:40.955789	2025-10-17 12:10:40.955789
536	\N	2025	15	0	15	0	2025-10-17 12:10:41.14399	2025-10-17 12:10:41.14399
537	\N	2025	15	0	15	0	2025-10-17 12:10:41.233948	2025-10-17 12:10:41.233948
538	\N	2025	15	0	15	0	2025-10-17 12:10:41.306241	2025-10-17 12:10:41.306241
539	\N	2025	15	0	15	0	2025-10-17 12:16:05.310422	2025-10-17 12:16:05.310422
540	\N	2025	15	0	15	0	2025-10-17 12:16:05.433947	2025-10-17 12:16:05.433947
541	\N	2025	15	0	15	0	2025-10-17 12:16:05.513927	2025-10-17 12:16:05.513927
542	\N	2025	15	0	15	0	2025-10-17 12:16:05.591097	2025-10-17 12:16:05.591097
543	\N	2025	15	0	15	0	2025-10-17 12:16:05.807646	2025-10-17 12:16:05.807646
544	\N	2025	15	0	15	0	2025-10-17 12:16:05.89427	2025-10-17 12:16:05.89427
545	\N	2025	15	0	15	0	2025-10-17 12:16:05.979967	2025-10-17 12:16:05.979967
546	\N	2025	15	0	15	0	2025-10-17 12:16:06.183947	2025-10-17 12:16:06.183947
547	\N	2025	15	0	15	0	2025-10-17 12:16:06.290101	2025-10-17 12:16:06.290101
548	\N	2025	15	0	15	0	2025-10-17 12:16:06.41203	2025-10-17 12:16:06.41203
549	\N	2025	15	0	15	0	2025-10-17 12:16:06.561304	2025-10-17 12:16:06.561304
550	\N	2025	15	0	15	0	2025-10-17 12:16:06.65018	2025-10-17 12:16:06.65018
551	\N	2025	15	0	15	0	2025-10-17 12:16:06.765029	2025-10-17 12:16:06.765029
552	\N	2025	15	0	15	0	2025-10-17 12:16:06.970111	2025-10-17 12:16:06.970111
553	\N	2025	15	0	15	0	2025-10-17 12:16:07.056173	2025-10-17 12:16:07.056173
554	\N	2025	15	0	15	0	2025-10-17 12:16:07.180484	2025-10-17 12:16:07.180484
555	\N	2025	15	0	15	0	2025-10-17 12:16:07.378357	2025-10-17 12:16:07.378357
556	\N	2025	15	0	15	0	2025-10-17 12:16:07.464454	2025-10-17 12:16:07.464454
557	\N	2025	15	0	15	0	2025-10-17 12:16:07.542628	2025-10-17 12:16:07.542628
558	\N	2025	15	0	15	0	2025-10-17 12:16:07.702474	2025-10-17 12:16:07.702474
559	\N	2025	15	0	15	0	2025-10-17 12:16:07.817585	2025-10-17 12:16:07.817585
560	\N	2025	15	0	15	0	2025-10-17 12:16:07.887639	2025-10-17 12:16:07.887639
561	\N	2025	15	0	15	0	2025-10-17 12:16:08.080299	2025-10-17 12:16:08.080299
562	\N	2025	15	0	15	0	2025-10-17 12:16:08.157135	2025-10-17 12:16:08.157135
563	\N	2025	15	0	15	0	2025-10-17 12:16:08.288457	2025-10-17 12:16:08.288457
564	\N	2025	15	0	15	0	2025-10-17 12:16:08.469992	2025-10-17 12:16:08.469992
565	\N	2025	15	0	15	0	2025-10-17 12:16:08.59499	2025-10-17 12:16:08.59499
566	\N	2025	15	0	15	0	2025-10-17 12:16:08.698914	2025-10-17 12:16:08.698914
567	\N	2025	15	0	15	0	2025-10-17 12:16:08.857367	2025-10-17 12:16:08.857367
568	\N	2025	15	0	15	0	2025-10-17 12:16:08.946419	2025-10-17 12:16:08.946419
569	\N	2025	15	0	15	0	2025-10-17 12:16:09.059293	2025-10-17 12:16:09.059293
570	\N	2025	15	0	15	0	2025-10-17 12:16:09.222924	2025-10-17 12:16:09.222924
571	\N	2025	15	0	15	0	2025-10-17 12:16:09.297924	2025-10-17 12:16:09.297924
572	\N	2025	15	0	15	0	2025-10-17 12:16:09.409516	2025-10-17 12:16:09.409516
573	\N	2025	15	0	15	0	2025-10-17 12:16:10.775313	2025-10-17 12:16:10.775313
574	\N	2025	15	0	15	0	2025-10-17 12:16:10.84948	2025-10-17 12:16:10.84948
575	\N	2025	15	0	15	0	2025-10-17 12:16:10.924786	2025-10-17 12:16:10.924786
576	\N	2025	15	0	15	0	2025-10-17 12:16:11.119429	2025-10-17 12:16:11.119429
577	\N	2025	15	0	15	0	2025-10-17 12:16:11.310304	2025-10-17 12:16:11.310304
578	\N	2025	15	0	15	0	2025-10-17 12:16:11.381663	2025-10-17 12:16:11.381663
579	\N	2025	15	0	15	0	2025-10-17 12:25:36.699562	2025-10-17 12:25:36.699562
580	\N	2025	15	0	15	0	2025-10-17 12:25:36.961862	2025-10-17 12:25:36.961862
581	\N	2025	15	0	15	0	2025-10-17 12:25:37.050589	2025-10-17 12:25:37.050589
582	\N	2025	15	0	15	0	2025-10-17 12:25:37.169233	2025-10-17 12:25:37.169233
583	\N	2025	15	0	15	0	2025-10-17 12:25:37.311904	2025-10-17 12:25:37.311904
584	\N	2025	15	0	15	0	2025-10-17 12:25:37.383708	2025-10-17 12:25:37.383708
585	\N	2025	15	0	15	0	2025-10-17 12:25:37.461541	2025-10-17 12:25:37.461541
586	\N	2025	15	0	15	0	2025-10-17 12:25:37.553711	2025-10-17 12:25:37.553711
587	\N	2025	15	0	15	0	2025-10-17 12:25:37.701645	2025-10-17 12:25:37.701645
588	\N	2025	15	0	15	0	2025-10-17 12:25:37.777144	2025-10-17 12:25:37.777144
589	\N	2025	15	0	15	0	2025-10-17 12:25:37.888523	2025-10-17 12:25:37.888523
590	\N	2025	15	0	15	0	2025-10-17 12:25:38.081751	2025-10-17 12:25:38.081751
591	\N	2025	15	0	15	0	2025-10-17 12:25:38.173933	2025-10-17 12:25:38.173933
592	\N	2025	15	0	15	0	2025-10-17 12:25:38.297727	2025-10-17 12:25:38.297727
593	\N	2025	15	0	15	0	2025-10-17 12:25:38.457727	2025-10-17 12:25:38.457727
594	\N	2025	15	0	15	0	2025-10-17 12:25:38.531006	2025-10-17 12:25:38.531006
595	\N	2025	15	0	15	0	2025-10-17 12:25:38.608763	2025-10-17 12:25:38.608763
596	\N	2025	15	0	15	0	2025-10-17 12:25:38.694366	2025-10-17 12:25:38.694366
597	\N	2025	15	0	15	0	2025-10-17 12:25:38.8581	2025-10-17 12:25:38.8581
598	\N	2025	15	0	15	0	2025-10-17 12:25:38.953555	2025-10-17 12:25:38.953555
599	\N	2025	15	0	15	0	2025-10-17 12:25:39.038787	2025-10-17 12:25:39.038787
600	\N	2025	15	0	15	0	2025-10-17 12:25:39.212893	2025-10-17 12:25:39.212893
601	\N	2025	15	0	15	0	2025-10-17 12:25:39.287736	2025-10-17 12:25:39.287736
602	\N	2025	15	0	15	0	2025-10-17 12:25:39.392038	2025-10-17 12:25:39.392038
603	\N	2025	15	0	15	0	2025-10-17 12:25:39.593861	2025-10-17 12:25:39.593861
604	\N	2025	15	0	15	0	2025-10-17 12:25:39.681705	2025-10-17 12:25:39.681705
605	\N	2025	15	0	15	0	2025-10-17 12:25:39.808814	2025-10-17 12:25:39.808814
606	\N	2025	15	0	15	0	2025-10-17 12:25:39.976657	2025-10-17 12:25:39.976657
607	\N	2025	15	0	15	0	2025-10-17 12:25:40.053623	2025-10-17 12:25:40.053623
608	\N	2025	15	0	15	0	2025-10-17 12:25:40.128949	2025-10-17 12:25:40.128949
609	\N	2025	15	0	15	0	2025-10-17 12:25:40.210521	2025-10-17 12:25:40.210521
610	\N	2025	15	0	15	0	2025-10-17 12:25:40.352814	2025-10-17 12:25:40.352814
611	\N	2025	15	0	15	0	2025-10-17 12:25:40.449089	2025-10-17 12:25:40.449089
612	\N	2025	15	0	15	0	2025-10-17 12:25:40.533912	2025-10-17 12:25:40.533912
613	\N	2025	15	0	15	0	2025-10-17 12:25:40.731664	2025-10-17 12:25:40.731664
614	\N	2025	15	0	15	0	2025-10-17 12:25:40.811861	2025-10-17 12:25:40.811861
615	\N	2025	15	0	15	0	2025-10-17 12:25:40.888631	2025-10-17 12:25:40.888631
616	\N	2025	15	0	15	0	2025-10-17 12:25:40.983739	2025-10-17 12:25:40.983739
617	\N	2025	15	0	15	0	2025-10-17 12:25:41.112151	2025-10-17 12:25:41.112151
618	\N	2025	15	0	15	0	2025-10-17 12:25:41.184591	2025-10-17 12:25:41.184591
619	\N	2025	15	0	15	0	2025-10-17 12:25:41.268666	2025-10-17 12:25:41.268666
620	\N	2025	15	0	15	0	2025-10-17 12:25:41.354676	2025-10-17 12:25:41.354676
621	\N	2025	15	0	15	0	2025-10-17 12:25:41.496985	2025-10-17 12:25:41.496985
622	\N	2025	15	0	15	0	2025-10-17 12:25:41.576587	2025-10-17 12:25:41.576587
623	\N	2025	15	0	15	0	2025-10-17 12:25:41.685744	2025-10-17 12:25:41.685744
624	\N	2025	15	0	15	0	2025-10-17 12:25:41.871744	2025-10-17 12:25:41.871744
625	\N	2025	15	0	15	0	2025-10-17 12:25:41.968698	2025-10-17 12:25:41.968698
626	\N	2025	15	0	15	0	2025-10-17 12:25:42.053744	2025-10-17 12:25:42.053744
627	\N	2025	15	0	15	0	2025-10-17 12:25:42.137929	2025-10-17 12:25:42.137929
628	\N	2025	15	0	15	0	2025-10-17 12:25:42.251723	2025-10-17 12:25:42.251723
629	\N	2025	15	0	15	0	2025-10-17 12:25:42.393353	2025-10-17 12:25:42.393353
630	\N	2025	15	0	15	0	2025-10-17 12:25:42.461714	2025-10-17 12:25:42.461714
631	\N	2025	15	0	15	0	2025-10-17 12:25:42.63402	2025-10-17 12:25:42.63402
632	\N	2025	15	0	15	0	2025-10-17 12:25:42.716687	2025-10-17 12:25:42.716687
633	\N	2025	15	0	15	0	2025-10-17 12:25:42.79345	2025-10-17 12:25:42.79345
634	\N	2025	15	0	15	0	2025-10-17 12:25:42.870001	2025-10-17 12:25:42.870001
635	\N	2025	15	0	15	0	2025-10-17 12:25:43.016253	2025-10-17 12:25:43.016253
636	\N	2025	15	0	15	0	2025-10-17 12:25:43.107067	2025-10-17 12:25:43.107067
637	\N	2025	15	0	15	0	2025-10-17 12:25:43.188106	2025-10-17 12:25:43.188106
638	\N	2025	15	0	15	0	2025-10-17 12:25:43.392727	2025-10-17 12:25:43.392727
639	\N	2025	15	0	15	0	2025-10-17 12:25:43.488691	2025-10-17 12:25:43.488691
640	\N	2025	15	0	15	0	2025-10-17 12:25:43.573786	2025-10-17 12:25:43.573786
641	\N	2025	15	0	15	0	2025-10-17 12:25:43.772674	2025-10-17 12:25:43.772674
642	\N	2025	15	0	15	0	2025-10-17 12:25:43.871725	2025-10-17 12:25:43.871725
643	\N	2025	15	0	15	0	2025-10-17 12:25:43.988839	2025-10-17 12:25:43.988839
644	\N	2025	15	0	15	0	2025-10-17 12:25:44.152078	2025-10-17 12:25:44.152078
645	\N	2025	15	0	15	0	2025-10-17 12:25:44.246543	2025-10-17 12:25:44.246543
646	\N	2025	15	0	15	0	2025-10-17 12:25:44.321097	2025-10-17 12:25:44.321097
647	\N	2025	15	0	15	0	2025-10-17 12:25:44.398713	2025-10-17 12:25:44.398713
648	\N	2025	15	0	15	0	2025-10-17 12:25:44.536992	2025-10-17 12:25:44.536992
649	\N	2025	15	0	15	0	2025-10-17 12:25:44.64163	2025-10-17 12:25:44.64163
650	\N	2025	15	0	15	0	2025-10-17 12:25:44.768594	2025-10-17 12:25:44.768594
651	\N	2025	15	0	15	0	2025-10-17 12:25:44.912278	2025-10-17 12:25:44.912278
652	\N	2025	15	0	15	0	2025-10-17 12:25:44.989663	2025-10-17 12:25:44.989663
653	\N	2025	15	0	15	0	2025-10-17 12:25:45.074428	2025-10-17 12:25:45.074428
654	\N	2025	15	0	15	0	2025-10-17 12:25:45.168754	2025-10-17 12:25:45.168754
655	\N	2025	15	0	15	0	2025-10-17 12:25:45.301839	2025-10-17 12:25:45.301839
656	\N	2025	15	0	15	0	2025-10-17 12:25:45.408826	2025-10-17 12:25:45.408826
657	\N	2025	15	0	15	0	2025-10-17 12:25:45.493926	2025-10-17 12:25:45.493926
658	\N	2025	15	0	15	0	2025-10-17 12:25:45.682037	2025-10-17 12:25:45.682037
659	\N	2025	15	0	15	0	2025-10-17 12:25:45.768411	2025-10-17 12:25:45.768411
660	\N	2025	15	0	15	0	2025-10-17 12:25:45.87185	2025-10-17 12:25:45.87185
661	\N	2025	15	0	15	0	2025-10-17 12:25:46.057696	2025-10-17 12:25:46.057696
662	\N	2025	15	0	15	0	2025-10-17 12:25:46.132768	2025-10-17 12:25:46.132768
663	\N	2025	15	0	15	0	2025-10-17 12:25:46.23264	2025-10-17 12:25:46.23264
664	\N	2025	15	0	15	0	2025-10-17 12:25:46.423791	2025-10-17 12:25:46.423791
665	\N	2025	15	0	15	0	2025-10-17 12:25:46.502685	2025-10-17 12:25:46.502685
666	\N	2025	15	0	15	0	2025-10-17 12:25:46.585941	2025-10-17 12:25:46.585941
667	\N	2025	15	0	15	0	2025-10-17 12:25:46.672535	2025-10-17 12:25:46.672535
668	\N	2025	15	0	15	0	2025-10-17 12:25:47.027736	2025-10-17 12:25:47.027736
669	\N	2025	15	0	15	0	2025-10-17 12:25:47.202415	2025-10-17 12:25:47.202415
670	\N	2025	15	0	15	0	2025-10-17 12:25:47.287759	2025-10-17 12:25:47.287759
671	\N	2025	15	0	15	0	2025-10-17 12:25:47.367827	2025-10-17 12:25:47.367827
672	\N	2025	15	0	15	0	2025-10-17 12:25:47.582464	2025-10-17 12:25:47.582464
673	\N	2025	15	0	15	0	2025-10-17 12:25:47.701436	2025-10-17 12:25:47.701436
674	\N	2025	15	0	15	0	2025-10-17 12:25:47.828093	2025-10-17 12:25:47.828093
675	\N	2025	15	0	15	0	2025-10-17 12:25:48.093884	2025-10-17 12:25:48.093884
676	\N	2025	15	0	15	0	2025-10-17 12:25:48.19183	2025-10-17 12:25:48.19183
677	\N	2025	15	0	15	0	2025-10-17 12:25:48.331665	2025-10-17 12:25:48.331665
678	\N	2025	15	0	15	0	2025-10-17 12:25:48.448723	2025-10-17 12:25:48.448723
679	\N	2025	15	0	15	0	2025-10-17 12:25:48.55187	2025-10-17 12:25:48.55187
680	\N	2025	15	0	15	0	2025-10-17 12:25:48.7277	2025-10-17 12:25:48.7277
681	\N	2025	15	0	15	0	2025-10-17 12:25:48.831973	2025-10-17 12:25:48.831973
682	\N	2025	15	0	15	0	2025-10-17 12:25:48.933479	2025-10-17 12:25:48.933479
683	\N	2025	15	0	15	0	2025-10-17 12:25:49.097839	2025-10-17 12:25:49.097839
684	\N	2025	15	0	15	0	2025-10-17 12:25:49.201747	2025-10-17 12:25:49.201747
685	\N	2025	15	0	15	0	2025-10-17 12:25:49.277837	2025-10-17 12:25:49.277837
686	\N	2025	15	0	15	0	2025-10-17 12:25:49.471798	2025-10-17 12:25:49.471798
687	\N	2025	15	0	15	0	2025-10-17 12:25:49.551094	2025-10-17 12:25:49.551094
688	\N	2025	15	0	15	0	2025-10-17 12:25:49.673687	2025-10-17 12:25:49.673687
689	\N	2025	15	0	15	0	2025-10-17 12:25:49.852925	2025-10-17 12:25:49.852925
690	\N	2025	15	0	15	0	2025-10-17 12:25:49.936873	2025-10-17 12:25:49.936873
691	\N	2025	15	0	15	0	2025-10-17 12:25:50.033981	2025-10-17 12:25:50.033981
692	\N	2025	15	0	15	0	2025-10-17 12:25:50.111543	2025-10-17 12:25:50.111543
693	\N	2025	15	0	15	0	2025-10-17 12:25:50.232628	2025-10-17 12:25:50.232628
694	\N	2025	15	0	15	0	2025-10-17 12:25:50.309964	2025-10-17 12:25:50.309964
695	\N	2025	15	0	15	0	2025-10-17 12:25:50.385591	2025-10-17 12:25:50.385591
696	\N	2025	15	0	15	0	2025-10-17 12:25:50.471704	2025-10-17 12:25:50.471704
697	\N	2025	15	0	15	0	2025-10-17 12:25:50.648052	2025-10-17 12:25:50.648052
698	\N	2025	15	0	15	0	2025-10-17 12:25:50.741564	2025-10-17 12:25:50.741564
699	\N	2025	15	0	15	0	2025-10-17 12:25:50.857692	2025-10-17 12:25:50.857692
700	\N	2025	15	0	15	0	2025-10-17 12:25:50.992437	2025-10-17 12:25:50.992437
701	\N	2025	15	0	15	0	2025-10-17 12:25:51.072031	2025-10-17 12:25:51.072031
702	\N	2025	15	0	15	0	2025-10-17 12:25:51.153567	2025-10-17 12:25:51.153567
703	\N	2025	15	0	15	0	2025-10-17 12:25:51.248626	2025-10-17 12:25:51.248626
704	\N	2025	15	0	15	0	2025-10-17 12:25:51.372487	2025-10-17 12:25:51.372487
705	\N	2025	15	0	15	0	2025-10-17 12:25:51.450242	2025-10-17 12:25:51.450242
706	\N	2025	15	0	15	0	2025-10-17 12:25:51.540335	2025-10-17 12:25:51.540335
707	\N	2025	15	0	15	0	2025-10-17 12:25:51.623723	2025-10-17 12:25:51.623723
708	\N	2025	15	0	15	0	2025-10-17 12:25:51.751488	2025-10-17 12:25:51.751488
709	\N	2025	15	0	15	0	2025-10-17 12:25:51.82659	2025-10-17 12:25:51.82659
710	\N	2025	15	0	15	0	2025-10-17 12:25:51.929583	2025-10-17 12:25:51.929583
711	\N	2025	15	0	15	0	2025-10-17 12:25:52.007634	2025-10-17 12:25:52.007634
712	\N	2025	15	0	15	0	2025-10-17 12:25:52.129082	2025-10-17 12:25:52.129082
713	\N	2025	15	0	15	0	2025-10-17 12:25:52.21651	2025-10-17 12:25:52.21651
714	\N	2025	15	0	15	0	2025-10-17 12:25:52.293101	2025-10-17 12:25:52.293101
715	\N	2025	15	0	15	0	2025-10-17 12:25:52.592858	2025-10-17 12:25:52.592858
716	\N	2025	15	0	15	0	2025-10-17 12:25:52.902908	2025-10-17 12:25:52.902908
717	\N	2025	15	0	15	0	2025-10-17 12:25:52.989729	2025-10-17 12:25:52.989729
718	\N	2025	15	0	15	0	2025-10-17 12:25:53.06271	2025-10-17 12:25:53.06271
719	\N	2025	15	0	15	0	2025-10-17 12:25:53.273993	2025-10-17 12:25:53.273993
720	\N	2025	15	0	15	0	2025-10-17 12:25:53.349644	2025-10-17 12:25:53.349644
721	\N	2025	15	0	15	0	2025-10-17 12:25:53.427214	2025-10-17 12:25:53.427214
722	\N	2025	15	0	15	0	2025-10-17 12:25:53.510699	2025-10-17 12:25:53.510699
723	\N	2025	15	0	15	0	2025-10-17 12:25:53.657613	2025-10-17 12:25:53.657613
724	\N	2025	15	0	15	0	2025-10-17 12:35:24.449089	2025-10-17 12:35:24.449089
725	\N	2025	15	0	15	0	2025-10-17 12:35:24.631522	2025-10-17 12:35:24.631522
726	\N	2025	15	0	15	0	2025-10-17 12:35:24.792889	2025-10-17 12:35:24.792889
727	\N	2025	15	0	15	0	2025-10-17 12:35:24.863926	2025-10-17 12:35:24.863926
728	\N	2025	15	0	15	0	2025-10-17 12:35:24.954239	2025-10-17 12:35:24.954239
729	\N	2025	15	0	15	0	2025-10-17 12:35:25.024964	2025-10-17 12:35:25.024964
730	\N	2025	15	0	15	0	2025-10-17 12:35:25.18016	2025-10-17 12:35:25.18016
731	\N	2025	15	0	15	0	2025-10-17 12:35:25.253918	2025-10-17 12:35:25.253918
732	\N	2025	15	0	15	0	2025-10-17 12:35:25.337066	2025-10-17 12:35:25.337066
733	\N	2025	15	0	15	0	2025-10-17 12:35:25.447943	2025-10-17 12:35:25.447943
734	\N	2025	15	0	15	0	2025-10-17 12:35:25.555658	2025-10-17 12:35:25.555658
735	\N	2025	15	0	15	0	2025-10-17 12:35:25.630702	2025-10-17 12:35:25.630702
736	\N	2025	15	0	15	0	2025-10-17 12:35:25.715696	2025-10-17 12:35:25.715696
737	\N	2025	15	0	15	0	2025-10-17 12:35:25.821966	2025-10-17 12:35:25.821966
738	\N	2025	15	0	15	0	2025-10-17 12:35:25.93095	2025-10-17 12:35:25.93095
739	\N	2025	15	0	15	0	2025-10-17 12:35:26.048954	2025-10-17 12:35:26.048954
740	\N	2025	15	0	15	0	2025-10-17 12:35:26.161672	2025-10-17 12:35:26.161672
741	\N	2025	15	0	15	0	2025-10-17 12:35:26.312234	2025-10-17 12:35:26.312234
742	\N	2025	15	0	15	0	2025-10-17 12:35:26.401001	2025-10-17 12:35:26.401001
743	\N	2025	15	0	15	0	2025-10-17 12:35:26.511956	2025-10-17 12:35:26.511956
744	\N	2025	15	0	15	0	2025-10-17 12:35:26.695892	2025-10-17 12:35:26.695892
745	\N	2025	15	0	15	0	2025-10-17 12:35:26.773812	2025-10-17 12:35:26.773812
746	\N	2025	15	0	15	0	2025-10-17 12:35:26.85341	2025-10-17 12:35:26.85341
747	\N	2025	15	0	15	0	2025-10-17 12:35:26.93445	2025-10-17 12:35:26.93445
748	\N	2025	15	0	15	0	2025-10-17 12:35:27.072389	2025-10-17 12:35:27.072389
749	\N	2025	15	0	15	0	2025-10-17 12:35:27.185614	2025-10-17 12:35:27.185614
750	\N	2025	15	0	15	0	2025-10-17 12:35:27.284396	2025-10-17 12:35:27.284396
751	\N	2025	15	0	15	0	2025-10-17 12:35:27.451691	2025-10-17 12:35:27.451691
752	\N	2025	15	0	15	0	2025-10-17 12:35:27.524201	2025-10-17 12:35:27.524201
753	\N	2025	15	0	15	0	2025-10-17 12:35:27.603956	2025-10-17 12:35:27.603956
754	\N	2025	15	0	15	0	2025-10-17 12:35:27.68317	2025-10-17 12:35:27.68317
755	\N	2025	15	0	15	0	2025-10-17 12:35:27.852642	2025-10-17 12:35:27.852642
756	\N	2025	15	0	15	0	2025-10-17 12:35:27.954588	2025-10-17 12:35:27.954588
757	\N	2025	15	0	15	0	2025-10-17 12:35:28.0487	2025-10-17 12:35:28.0487
758	\N	2025	15	0	15	0	2025-10-17 12:35:28.231184	2025-10-17 12:35:28.231184
759	\N	2025	15	0	15	0	2025-10-17 12:35:28.316586	2025-10-17 12:35:28.316586
760	\N	2025	15	0	15	0	2025-10-17 12:35:28.397908	2025-10-17 12:35:28.397908
761	\N	2025	15	0	15	0	2025-10-17 12:35:28.581861	2025-10-17 12:35:28.581861
762	\N	2025	15	0	15	0	2025-10-17 12:35:28.676838	2025-10-17 12:35:28.676838
763	\N	2025	15	0	15	0	2025-10-17 12:35:28.749785	2025-10-17 12:35:28.749785
764	\N	2025	15	0	15	0	2025-10-17 12:35:28.832176	2025-10-17 12:35:28.832176
765	\N	2025	15	0	15	0	2025-10-17 12:35:28.971546	2025-10-17 12:35:28.971546
766	\N	2025	15	0	15	0	2025-10-17 12:35:29.052912	2025-10-17 12:35:29.052912
767	\N	2025	15	0	15	0	2025-10-17 12:35:29.132688	2025-10-17 12:35:29.132688
768	\N	2025	15	0	15	0	2025-10-17 12:35:29.208817	2025-10-17 12:35:29.208817
769	\N	2025	15	0	15	0	2025-10-17 12:35:29.360614	2025-10-17 12:35:29.360614
770	\N	2025	15	0	15	0	2025-10-17 12:35:29.444949	2025-10-17 12:35:29.444949
771	\N	2025	15	0	15	0	2025-10-17 12:35:29.532543	2025-10-17 12:35:29.532543
772	\N	2025	15	0	15	0	2025-10-17 12:35:29.736092	2025-10-17 12:35:29.736092
773	\N	2025	15	0	15	0	2025-10-17 12:35:29.817677	2025-10-17 12:35:29.817677
774	\N	2025	15	0	15	0	2025-10-17 12:35:29.896064	2025-10-17 12:35:29.896064
775	\N	2025	15	0	15	0	2025-10-17 12:35:29.987682	2025-10-17 12:35:29.987682
776	\N	2025	15	0	15	0	2025-10-17 12:35:30.111258	2025-10-17 12:35:30.111258
777	\N	2025	15	0	15	0	2025-10-17 12:35:30.195903	2025-10-17 12:35:30.195903
778	\N	2025	15	0	15	0	2025-10-17 12:35:30.270948	2025-10-17 12:35:30.270948
779	\N	2025	15	0	15	0	2025-10-17 12:35:30.352674	2025-10-17 12:35:30.352674
780	\N	2025	15	0	15	0	2025-10-17 12:35:30.500932	2025-10-17 12:35:30.500932
781	\N	2025	15	0	15	0	2025-10-17 12:35:30.581968	2025-10-17 12:35:30.581968
782	\N	2025	15	0	15	0	2025-10-17 12:35:30.671027	2025-10-17 12:35:30.671027
783	\N	2025	15	0	15	0	2025-10-17 12:35:30.749327	2025-10-17 12:35:30.749327
784	\N	2025	15	0	15	0	2025-10-17 12:35:30.871273	2025-10-17 12:35:30.871273
785	\N	2025	15	0	15	0	2025-10-17 12:35:30.950031	2025-10-17 12:35:30.950031
786	\N	2025	15	0	15	0	2025-10-17 12:35:31.034005	2025-10-17 12:35:31.034005
787	\N	2025	15	0	15	0	2025-10-17 12:35:31.119962	2025-10-17 12:35:31.119962
788	\N	2025	15	0	15	0	2025-10-17 12:35:31.264359	2025-10-17 12:35:31.264359
789	\N	2025	15	0	15	0	2025-10-17 12:35:31.353553	2025-10-17 12:35:31.353553
790	\N	2025	15	0	15	0	2025-10-17 12:35:31.431083	2025-10-17 12:35:31.431083
791	\N	2025	15	0	15	0	2025-10-17 12:35:31.511969	2025-10-17 12:35:31.511969
792	\N	2025	15	0	15	0	2025-10-17 12:35:31.656359	2025-10-17 12:35:31.656359
793	\N	2025	15	0	15	0	2025-10-17 12:35:31.738849	2025-10-17 12:35:31.738849
794	\N	2025	15	0	15	0	2025-10-17 12:35:31.810243	2025-10-17 12:35:31.810243
795	\N	2025	15	0	15	0	2025-10-17 12:35:31.897879	2025-10-17 12:35:31.897879
796	\N	2025	15	0	15	0	2025-10-17 12:35:32.001137	2025-10-17 12:35:32.001137
797	\N	2025	15	0	15	0	2025-10-17 12:35:32.097788	2025-10-17 12:35:32.097788
798	\N	2025	15	0	15	0	2025-10-17 12:35:32.171333	2025-10-17 12:35:32.171333
799	\N	2025	15	0	15	0	2025-10-17 12:35:32.255452	2025-10-17 12:35:32.255452
800	\N	2025	15	0	15	0	2025-10-17 12:35:32.411016	2025-10-17 12:35:32.411016
801	\N	2025	15	0	15	0	2025-10-17 12:35:32.50072	2025-10-17 12:35:32.50072
802	\N	2025	15	0	15	0	2025-10-17 12:35:32.582007	2025-10-17 12:35:32.582007
803	\N	2025	15	0	15	0	2025-10-17 12:35:32.662469	2025-10-17 12:35:32.662469
804	\N	2025	15	0	15	0	2025-10-17 12:35:32.781977	2025-10-17 12:35:32.781977
805	\N	2025	15	0	15	0	2025-10-17 12:35:32.879548	2025-10-17 12:35:32.879548
806	\N	2025	15	0	15	0	2025-10-17 12:35:32.965369	2025-10-17 12:35:32.965369
807	\N	2025	15	0	15	0	2025-10-17 12:35:33.169785	2025-10-17 12:35:33.169785
808	\N	2025	15	0	15	0	2025-10-17 12:35:33.256314	2025-10-17 12:35:33.256314
809	\N	2025	15	0	15	0	2025-10-17 12:35:33.330943	2025-10-17 12:35:33.330943
810	\N	2025	15	0	15	0	2025-10-17 12:35:33.408311	2025-10-17 12:35:33.408311
811	\N	2025	15	0	15	0	2025-10-17 12:35:33.543557	2025-10-17 12:35:33.543557
812	\N	2025	15	0	15	0	2025-10-17 12:35:33.61311	2025-10-17 12:35:33.61311
813	\N	2025	15	0	15	0	2025-10-17 12:35:33.702538	2025-10-17 12:35:33.702538
814	\N	2025	15	0	15	0	2025-10-17 12:35:33.778864	2025-10-17 12:35:33.778864
815	\N	2025	15	0	15	0	2025-10-17 12:35:33.93034	2025-10-17 12:35:33.93034
816	\N	2025	15	0	15	0	2025-10-17 12:35:34.023842	2025-10-17 12:35:34.023842
817	\N	2025	15	0	15	0	2025-10-17 12:35:34.110772	2025-10-17 12:35:34.110772
818	\N	2025	15	0	15	0	2025-10-17 12:35:34.295706	2025-10-17 12:35:34.295706
819	\N	2025	15	0	15	0	2025-10-17 12:35:34.373853	2025-10-17 12:35:34.373853
820	\N	2025	15	0	15	0	2025-10-17 12:35:34.457369	2025-10-17 12:35:34.457369
821	\N	2025	15	0	15	0	2025-10-17 12:35:34.53761	2025-10-17 12:35:34.53761
822	\N	2025	15	0	15	0	2025-10-17 12:35:34.752797	2025-10-17 12:35:34.752797
823	\N	2025	15	0	15	0	2025-10-17 12:35:34.828908	2025-10-17 12:35:34.828908
824	\N	2025	15	0	15	0	2025-10-17 12:35:34.937891	2025-10-17 12:35:34.937891
825	\N	2025	15	0	15	0	2025-10-17 12:35:35.057166	2025-10-17 12:35:35.057166
826	\N	2025	15	0	15	0	2025-10-17 12:35:35.150815	2025-10-17 12:35:35.150815
827	\N	2025	15	0	15	0	2025-10-17 12:35:35.236845	2025-10-17 12:35:35.236845
828	\N	2025	15	0	15	0	2025-10-17 12:35:35.316444	2025-10-17 12:35:35.316444
829	\N	2025	15	0	15	0	2025-10-17 12:35:35.462463	2025-10-17 12:35:35.462463
830	\N	2025	15	0	15	0	2025-10-17 12:35:35.53458	2025-10-17 12:35:35.53458
831	\N	2025	15	0	15	0	2025-10-17 12:35:35.620062	2025-10-17 12:35:35.620062
832	\N	2025	15	0	15	0	2025-10-17 12:35:35.815662	2025-10-17 12:35:35.815662
833	\N	2025	15	0	15	0	2025-10-17 12:35:35.973505	2025-10-17 12:35:35.973505
834	\N	2025	15	0	15	0	2025-10-17 12:35:36.065896	2025-10-17 12:35:36.065896
835	\N	2025	15	0	15	0	2025-10-17 12:35:36.192991	2025-10-17 12:35:36.192991
836	\N	2025	15	0	15	0	2025-10-17 12:35:36.267042	2025-10-17 12:35:36.267042
837	\N	2025	15	0	15	0	2025-10-17 12:35:36.37798	2025-10-17 12:35:36.37798
838	\N	2025	15	0	15	0	2025-10-17 12:35:36.581148	2025-10-17 12:35:36.581148
839	\N	2025	15	0	15	0	2025-10-17 12:35:36.664122	2025-10-17 12:35:36.664122
840	\N	2025	15	0	15	0	2025-10-17 12:35:36.740867	2025-10-17 12:35:36.740867
841	\N	2025	15	0	15	0	2025-10-17 12:35:36.827062	2025-10-17 12:35:36.827062
842	\N	2025	15	0	15	0	2025-10-17 12:35:36.964169	2025-10-17 12:35:36.964169
843	\N	2025	15	0	15	0	2025-10-17 12:35:37.053708	2025-10-17 12:35:37.053708
844	\N	2025	15	0	15	0	2025-10-17 12:35:37.144923	2025-10-17 12:35:37.144923
845	\N	2025	15	0	15	0	2025-10-17 12:35:37.336528	2025-10-17 12:35:37.336528
846	\N	2025	15	0	15	0	2025-10-17 12:35:37.408917	2025-10-17 12:35:37.408917
847	\N	2025	15	0	15	0	2025-10-17 12:35:37.497039	2025-10-17 12:35:37.497039
848	\N	2025	15	0	15	0	2025-10-17 12:35:37.589891	2025-10-17 12:35:37.589891
849	\N	2025	15	0	15	0	2025-10-17 12:35:37.70573	2025-10-17 12:35:37.70573
850	\N	2025	15	0	15	0	2025-10-17 12:35:37.781221	2025-10-17 12:35:37.781221
851	\N	2025	15	0	15	0	2025-10-17 12:35:37.87279	2025-10-17 12:35:37.87279
852	\N	2025	15	0	15	0	2025-10-17 12:35:37.952022	2025-10-17 12:35:37.952022
853	\N	2025	15	0	15	0	2025-10-17 12:35:38.093072	2025-10-17 12:35:38.093072
854	\N	2025	15	0	15	0	2025-10-17 12:35:38.19703	2025-10-17 12:35:38.19703
855	\N	2025	15	0	15	0	2025-10-17 12:35:38.272914	2025-10-17 12:35:38.272914
856	\N	2025	15	0	15	0	2025-10-17 12:35:38.47205	2025-10-17 12:35:38.47205
857	\N	2025	15	0	15	0	2025-10-17 12:35:38.561978	2025-10-17 12:35:38.561978
858	\N	2025	15	0	15	0	2025-10-17 12:35:38.641131	2025-10-17 12:35:38.641131
859	\N	2025	15	0	15	0	2025-10-17 12:35:38.722736	2025-10-17 12:35:38.722736
860	\N	2025	15	0	15	0	2025-10-17 12:35:38.857875	2025-10-17 12:35:38.857875
861	\N	2025	15	0	15	0	2025-10-17 12:35:38.951998	2025-10-17 12:35:38.951998
862	\N	2025	15	0	15	0	2025-10-17 12:35:39.248032	2025-10-17 12:35:39.248032
863	\N	2025	15	0	15	0	2025-10-17 12:35:39.338313	2025-10-17 12:35:39.338313
864	\N	2025	15	0	15	0	2025-10-17 12:35:39.416444	2025-10-17 12:35:39.416444
865	\N	2025	15	0	15	0	2025-10-17 12:35:39.497856	2025-10-17 12:35:39.497856
866	\N	2025	15	0	15	0	2025-10-17 12:35:39.611196	2025-10-17 12:35:39.611196
867	\N	2025	15	0	15	0	2025-10-17 12:35:39.68969	2025-10-17 12:35:39.68969
868	\N	2025	15	0	15	0	2025-10-17 12:35:39.765314	2025-10-17 12:35:39.765314
869	\N	2025	15	0	15	0	2025-10-17 12:35:39.842811	2025-10-17 12:35:39.842811
870	\N	2025	15	0	15	0	2025-10-17 12:35:39.989304	2025-10-17 12:35:39.989304
871	\N	2025	15	0	15	0	2025-10-17 12:35:40.085697	2025-10-17 12:35:40.085697
872	\N	2025	15	0	15	0	2025-10-17 12:35:40.171273	2025-10-17 12:35:40.171273
873	\N	2025	15	0	15	0	2025-10-17 12:41:44.860591	2025-10-17 12:41:44.860591
874	\N	2025	15	0	15	0	2025-10-17 12:41:45.13265	2025-10-17 12:41:45.13265
875	\N	2025	15	0	15	0	2025-10-17 12:41:45.211618	2025-10-17 12:41:45.211618
876	\N	2025	15	0	15	0	2025-10-17 12:41:45.29211	2025-10-17 12:41:45.29211
877	\N	2025	15	0	15	0	2025-10-17 12:41:45.434864	2025-10-17 12:41:45.434864
878	\N	2025	15	0	15	0	2025-10-17 12:41:45.520782	2025-10-17 12:41:45.520782
879	\N	2025	15	0	15	0	2025-10-17 12:41:45.604727	2025-10-17 12:41:45.604727
880	\N	2025	15	0	15	0	2025-10-17 12:41:45.693186	2025-10-17 12:41:45.693186
881	\N	2025	15	0	15	0	2025-10-17 12:41:45.817988	2025-10-17 12:41:45.817988
882	\N	2025	15	0	15	0	2025-10-17 12:41:45.905392	2025-10-17 12:41:45.905392
883	\N	2025	15	0	15	0	2025-10-17 12:41:45.991702	2025-10-17 12:41:45.991702
884	\N	2025	15	0	15	0	2025-10-17 12:41:46.066879	2025-10-17 12:41:46.066879
885	\N	2025	15	0	15	0	2025-10-17 12:41:46.23514	2025-10-17 12:41:46.23514
886	\N	2025	15	0	15	0	2025-10-17 12:41:46.321535	2025-10-17 12:41:46.321535
887	\N	2025	15	0	15	0	2025-10-17 12:41:46.392754	2025-10-17 12:41:46.392754
888	\N	2025	15	0	15	0	2025-10-17 12:41:46.573925	2025-10-17 12:41:46.573925
889	\N	2025	15	0	15	0	2025-10-17 12:41:46.650861	2025-10-17 12:41:46.650861
890	\N	2025	15	0	15	0	2025-10-17 12:41:46.731044	2025-10-17 12:41:46.731044
891	\N	2025	15	0	15	0	2025-10-17 12:41:46.809561	2025-10-17 12:41:46.809561
892	\N	2025	15	0	15	0	2025-10-17 12:41:55.303604	2025-10-17 12:41:55.303604
893	\N	2025	15	0	15	0	2025-10-17 12:41:55.371862	2025-10-17 12:41:55.371862
894	\N	2025	15	0	15	0	2025-10-17 12:41:55.460511	2025-10-17 12:41:55.460511
895	\N	2025	15	0	15	0	2025-10-17 12:41:55.543822	2025-10-17 12:41:55.543822
896	\N	2025	15	0	15	0	2025-10-17 12:41:55.728188	2025-10-17 12:41:55.728188
897	\N	2025	15	0	15	0	2025-10-17 12:41:55.816696	2025-10-17 12:41:55.816696
898	\N	2025	15	0	15	0	2025-10-17 12:41:55.897389	2025-10-17 12:41:55.897389
899	\N	2025	15	0	15	0	2025-10-17 12:41:56.071923	2025-10-17 12:41:56.071923
900	\N	2025	15	0	15	0	2025-10-17 12:41:56.171916	2025-10-17 12:41:56.171916
901	\N	2025	15	0	15	0	2025-10-17 12:41:56.23646	2025-10-17 12:41:56.23646
902	\N	2025	15	0	15	0	2025-10-17 12:41:56.326685	2025-10-17 12:41:56.326685
903	\N	2025	15	0	15	0	2025-10-17 12:41:56.527983	2025-10-17 12:41:56.527983
904	\N	2025	15	0	15	0	2025-10-17 12:41:56.928239	2025-10-17 12:41:56.928239
905	\N	2025	15	0	15	0	2025-10-17 12:41:57.21261	2025-10-17 12:41:57.21261
906	\N	2025	15	0	15	0	2025-10-17 12:41:57.284694	2025-10-17 12:41:57.284694
907	\N	2025	15	0	15	0	2025-10-17 12:41:57.375077	2025-10-17 12:41:57.375077
908	\N	2025	15	0	15	0	2025-10-17 12:41:57.453105	2025-10-17 12:41:57.453105
909	\N	2025	15	0	15	0	2025-10-17 12:41:57.602021	2025-10-17 12:41:57.602021
910	\N	2025	15	0	15	0	2025-10-17 12:41:57.703055	2025-10-17 12:41:57.703055
911	\N	2025	15	0	15	0	2025-10-17 12:41:57.783174	2025-10-17 12:41:57.783174
912	\N	2025	15	0	15	0	2025-10-17 12:41:57.860781	2025-10-17 12:41:57.860781
913	\N	2025	15	0	15	0	2025-10-17 12:41:57.979028	2025-10-17 12:41:57.979028
914	\N	2025	15	0	15	0	2025-10-17 12:41:58.05756	2025-10-17 12:41:58.05756
915	\N	2025	15	0	15	0	2025-10-17 12:41:58.139673	2025-10-17 12:41:58.139673
916	\N	2025	15	0	15	0	2025-10-17 12:41:58.242739	2025-10-17 12:41:58.242739
917	\N	2025	15	0	15	0	2025-10-17 12:41:58.376724	2025-10-17 12:41:58.376724
918	\N	2025	15	0	15	0	2025-10-17 12:41:58.48191	2025-10-17 12:41:58.48191
919	\N	2025	15	0	15	0	2025-10-17 12:41:58.549687	2025-10-17 12:41:58.549687
920	\N	2025	15	0	15	0	2025-10-17 12:41:58.723089	2025-10-17 12:41:58.723089
921	\N	2025	15	0	15	0	2025-10-17 12:41:58.801517	2025-10-17 12:41:58.801517
922	\N	2025	15	0	15	0	2025-10-17 12:41:58.866489	2025-10-17 12:41:58.866489
923	\N	2025	15	0	15	0	2025-10-17 12:41:58.972484	2025-10-17 12:41:58.972484
924	\N	2025	15	0	15	0	2025-10-17 12:41:59.111084	2025-10-17 12:41:59.111084
925	\N	2025	15	0	15	0	2025-10-17 12:41:59.183364	2025-10-17 12:41:59.183364
926	\N	2025	15	0	15	0	2025-10-17 12:41:59.266642	2025-10-17 12:41:59.266642
927	\N	2025	15	0	15	0	2025-10-17 12:41:59.349814	2025-10-17 12:41:59.349814
928	\N	2025	15	0	15	0	2025-10-17 12:41:59.495943	2025-10-17 12:41:59.495943
929	\N	2025	15	0	15	0	2025-10-17 12:41:59.567739	2025-10-17 12:41:59.567739
930	\N	2025	15	0	15	0	2025-10-17 12:41:59.666776	2025-10-17 12:41:59.666776
931	\N	2025	15	0	15	0	2025-10-17 12:41:59.739092	2025-10-17 12:41:59.739092
932	\N	2025	15	0	15	0	2025-10-17 12:41:59.887948	2025-10-17 12:41:59.887948
933	\N	2025	15	0	15	0	2025-10-17 12:41:59.972896	2025-10-17 12:41:59.972896
934	\N	2025	15	0	15	0	2025-10-17 12:42:00.092066	2025-10-17 12:42:00.092066
935	\N	2025	15	0	15	0	2025-10-17 12:42:00.260816	2025-10-17 12:42:00.260816
936	\N	2025	15	0	15	0	2025-10-17 12:42:00.336714	2025-10-17 12:42:00.336714
937	\N	2025	15	0	15	0	2025-10-17 12:42:00.407916	2025-10-17 12:42:00.407916
938	\N	2025	15	0	15	0	2025-10-17 12:42:00.482583	2025-10-17 12:42:00.482583
939	\N	2025	15	0	15	0	2025-10-17 12:42:00.631116	2025-10-17 12:42:00.631116
940	\N	2025	15	0	15	0	2025-10-17 12:42:00.705696	2025-10-17 12:42:00.705696
941	\N	2025	15	0	15	0	2025-10-17 12:42:00.791969	2025-10-17 12:42:00.791969
942	\N	2025	15	0	15	0	2025-10-17 12:42:00.880427	2025-10-17 12:42:00.880427
943	\N	2025	15	0	15	0	2025-10-17 12:42:01.015792	2025-10-17 12:42:01.015792
944	\N	2025	15	0	15	0	2025-10-17 12:42:01.088102	2025-10-17 12:42:01.088102
945	\N	2025	15	0	15	0	2025-10-17 12:42:01.200773	2025-10-17 12:42:01.200773
946	\N	2025	15	0	15	0	2025-10-17 12:42:01.269613	2025-10-17 12:42:01.269613
947	\N	2025	15	0	15	0	2025-10-17 12:42:01.390788	2025-10-17 12:42:01.390788
948	\N	2025	15	0	15	0	2025-10-17 12:42:01.488392	2025-10-17 12:42:01.488392
949	\N	2025	15	0	15	0	2025-10-17 12:42:01.573179	2025-10-17 12:42:01.573179
950	\N	2025	15	0	15	0	2025-10-17 12:42:01.659047	2025-10-17 12:42:01.659047
951	\N	2025	15	0	15	0	2025-10-17 12:42:01.781803	2025-10-17 12:42:01.781803
952	\N	2025	15	0	15	0	2025-10-17 12:42:01.887985	2025-10-17 12:42:01.887985
953	\N	2025	15	0	15	0	2025-10-17 12:42:01.967772	2025-10-17 12:42:01.967772
954	\N	2025	15	0	15	0	2025-10-17 12:42:02.180755	2025-10-17 12:42:02.180755
955	\N	2025	15	0	15	0	2025-10-17 12:42:02.26518	2025-10-17 12:42:02.26518
956	\N	2025	15	0	15	0	2025-10-17 12:42:02.336526	2025-10-17 12:42:02.336526
957	\N	2025	15	0	15	0	2025-10-17 12:42:02.536267	2025-10-17 12:42:02.536267
958	\N	2025	15	0	15	0	2025-10-17 12:42:02.635812	2025-10-17 12:42:02.635812
959	\N	2025	15	0	15	0	2025-10-17 12:42:02.714424	2025-10-17 12:42:02.714424
960	\N	2025	15	0	15	0	2025-10-17 12:42:02.798747	2025-10-17 12:42:02.798747
961	\N	2025	15	0	15	0	2025-10-17 12:42:02.911527	2025-10-17 12:42:02.911527
962	\N	2025	15	0	15	0	2025-10-17 12:42:02.98281	2025-10-17 12:42:02.98281
963	\N	2025	15	0	15	0	2025-10-17 12:42:03.07276	2025-10-17 12:42:03.07276
964	\N	2025	15	0	15	0	2025-10-17 12:42:03.179116	2025-10-17 12:42:03.179116
965	\N	2025	15	0	15	0	2025-10-17 12:42:03.290633	2025-10-17 12:42:03.290633
966	\N	2025	15	0	15	0	2025-10-17 12:42:03.371514	2025-10-17 12:42:03.371514
967	\N	2025	15	0	15	0	2025-10-17 12:42:03.510841	2025-10-17 12:42:03.510841
968	\N	2025	15	0	15	0	2025-10-17 12:42:03.680434	2025-10-17 12:42:03.680434
969	\N	2025	15	0	15	0	2025-10-17 12:42:03.772293	2025-10-17 12:42:03.772293
970	\N	2025	15	0	15	0	2025-10-17 12:42:03.855	2025-10-17 12:42:03.855
971	\N	2025	15	0	15	0	2025-10-17 12:42:04.090847	2025-10-17 12:42:04.090847
972	\N	2025	15	0	15	0	2025-10-17 12:42:04.16793	2025-10-17 12:42:04.16793
973	\N	2025	15	0	15	0	2025-10-17 12:42:04.244058	2025-10-17 12:42:04.244058
974	\N	2025	15	0	15	0	2025-10-17 12:42:04.430624	2025-10-17 12:42:04.430624
975	\N	2025	15	0	15	0	2025-10-17 12:42:04.498787	2025-10-17 12:42:04.498787
976	\N	2025	15	0	15	0	2025-10-17 12:42:04.586579	2025-10-17 12:42:04.586579
977	\N	2025	15	0	15	0	2025-10-17 12:42:04.670743	2025-10-17 12:42:04.670743
978	\N	2025	15	0	15	0	2025-10-17 12:42:05.017726	2025-10-17 12:42:05.017726
979	\N	2025	15	0	15	0	2025-10-17 12:42:05.191127	2025-10-17 12:42:05.191127
980	\N	2025	15	0	15	0	2025-10-17 12:42:05.26897	2025-10-17 12:42:05.26897
981	\N	2025	15	0	15	0	2025-10-17 12:42:05.409207	2025-10-17 12:42:05.409207
982	\N	2025	15	0	15	0	2025-10-17 12:42:05.691479	2025-10-17 12:42:05.691479
983	\N	2025	15	0	15	0	2025-10-17 12:42:05.952103	2025-10-17 12:42:05.952103
984	\N	2025	15	0	15	0	2025-10-17 12:42:06.080941	2025-10-17 12:42:06.080941
985	\N	2025	15	0	15	0	2025-10-17 12:42:06.160066	2025-10-17 12:42:06.160066
986	\N	2025	15	0	15	0	2025-10-17 12:42:06.332742	2025-10-17 12:42:06.332742
987	\N	2025	15	0	15	0	2025-10-17 12:42:06.413073	2025-10-17 12:42:06.413073
988	\N	2025	15	0	15	0	2025-10-17 12:42:06.527987	2025-10-17 12:42:06.527987
989	\N	2025	15	0	15	0	2025-10-17 12:42:06.711773	2025-10-17 12:42:06.711773
990	\N	2025	15	0	15	0	2025-10-17 12:42:06.787444	2025-10-17 12:42:06.787444
991	\N	2025	15	0	15	0	2025-10-17 12:42:06.871842	2025-10-17 12:42:06.871842
992	\N	2025	15	0	15	0	2025-10-17 12:42:06.96336	2025-10-17 12:42:06.96336
993	\N	2025	15	0	15	0	2025-10-17 12:42:07.095847	2025-10-17 12:42:07.095847
994	\N	2025	15	0	15	0	2025-10-17 12:42:07.185735	2025-10-17 12:42:07.185735
995	\N	2025	15	0	15	0	2025-10-17 12:42:07.344727	2025-10-17 12:42:07.344727
996	\N	2025	15	0	15	0	2025-10-17 12:42:07.470742	2025-10-17 12:42:07.470742
997	\N	2025	15	0	15	0	2025-10-17 12:42:07.540947	2025-10-17 12:42:07.540947
998	\N	2025	15	0	15	0	2025-10-17 12:42:07.612176	2025-10-17 12:42:07.612176
999	\N	2025	15	0	15	0	2025-10-17 12:42:07.692146	2025-10-17 12:42:07.692146
1000	\N	2025	15	0	15	0	2025-10-17 12:42:07.850654	2025-10-17 12:42:07.850654
1001	\N	2025	15	0	15	0	2025-10-17 12:42:07.926616	2025-10-17 12:42:07.926616
1002	\N	2025	15	0	15	0	2025-10-17 12:42:08.024562	2025-10-17 12:42:08.024562
1003	\N	2025	15	0	15	0	2025-10-17 12:42:08.096772	2025-10-17 12:42:08.096772
1004	\N	2025	15	0	15	0	2025-10-17 12:42:08.212945	2025-10-17 12:42:08.212945
1005	\N	2025	15	0	15	0	2025-10-17 12:42:08.296988	2025-10-17 12:42:08.296988
1006	\N	2025	15	0	15	0	2025-10-17 12:42:08.37144	2025-10-17 12:42:08.37144
1007	\N	2025	15	0	15	0	2025-10-17 12:42:08.452941	2025-10-17 12:42:08.452941
1008	\N	2025	15	0	15	0	2025-10-17 12:42:08.621523	2025-10-17 12:42:08.621523
1009	\N	2025	15	0	15	0	2025-10-17 12:42:08.710815	2025-10-17 12:42:08.710815
1010	\N	2025	15	0	15	0	2025-10-17 12:42:08.776489	2025-10-17 12:42:08.776489
1011	\N	2025	15	0	15	0	2025-10-17 12:42:09.061596	2025-10-17 12:42:09.061596
1012	\N	2025	15	0	15	0	2025-10-17 12:42:09.140566	2025-10-17 12:42:09.140566
1013	\N	2025	15	0	15	0	2025-10-17 12:42:09.214728	2025-10-17 12:42:09.214728
1014	\N	2025	15	0	15	0	2025-10-17 12:42:09.37077	2025-10-17 12:42:09.37077
1015	\N	2025	15	0	15	0	2025-10-17 12:42:09.456051	2025-10-17 12:42:09.456051
1016	\N	2025	15	0	15	0	2025-10-17 12:42:09.532072	2025-10-17 12:42:09.532072
1017	\N	2025	15	0	15	0	2025-10-17 12:42:09.620398	2025-10-17 12:42:09.620398
1018	\N	2025	15	0	15	0	2025-10-17 12:42:09.749557	2025-10-17 12:42:09.749557
1019	\N	2025	15	0	15	0	2025-10-17 12:42:09.854589	2025-10-17 12:42:09.854589
1020	\N	2025	15	0	15	0	2025-10-17 12:42:09.930132	2025-10-17 12:42:09.930132
1021	\N	2025	15	0	15	0	2025-10-17 12:42:10.000534	2025-10-17 12:42:10.000534
1022	\N	2025	15	0	15	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
1023	\N	2025	15	0	15	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
1024	\N	2025	15	0	15	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
1025	\N	2025	15	0	15	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
1026	\N	2025	15	0	15	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
1027	\N	2025	15	0	15	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
1028	\N	2025	15	0	15	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
1029	\N	2025	15	0	15	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
1030	\N	2025	15	0	15	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
1031	\N	2025	15	0	15	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
1032	\N	2025	15	0	15	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
1033	\N	2025	15	0	15	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
1034	\N	2025	15	0	15	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
1035	\N	2025	15	0	15	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
1036	\N	2025	15	0	15	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
1037	\N	2025	15	0	15	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
1038	\N	2025	15	0	15	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
1039	\N	2025	15	0	15	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
1040	\N	2025	15	0	15	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
1041	\N	2025	15	0	15	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
1042	\N	2025	15	0	15	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
1043	\N	2025	15	0	15	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
1044	\N	2025	15	0	15	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
1045	\N	2025	15	0	15	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
1046	\N	2025	15	0	15	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
1047	\N	2025	15	0	15	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
1048	\N	2025	15	0	15	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
1049	\N	2025	15	0	15	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
1050	\N	2025	15	0	15	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
1051	\N	2025	15	0	15	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
1052	\N	2025	15	0	15	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
1053	\N	2025	15	0	15	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
1054	\N	2025	15	0	15	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
1055	\N	2025	15	0	15	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
1056	\N	2025	15	0	15	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
1057	\N	2025	15	0	15	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
1058	\N	2025	15	0	15	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
1059	\N	2025	15	0	15	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
1060	\N	2025	15	0	15	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
1061	\N	2025	15	0	15	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
1062	\N	2025	15	0	15	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
1063	\N	2025	15	0	15	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
1064	\N	2025	15	0	15	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
1065	\N	2025	15	0	15	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
1066	\N	2025	15	0	15	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
1067	\N	2025	15	0	15	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
1068	\N	2025	15	0	15	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
1069	\N	2025	15	0	15	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
1070	\N	2025	15	0	15	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
1071	\N	2025	15	0	15	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
1072	\N	2025	15	0	15	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
1073	\N	2025	15	0	15	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
1074	\N	2025	15	0	15	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
1075	\N	2025	15	0	15	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
1076	\N	2025	15	0	15	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
1077	\N	2025	15	0	15	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
1078	\N	2025	15	0	15	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
1079	\N	2025	15	0	15	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
1080	\N	2025	15	0	15	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
1081	\N	2025	15	0	15	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
1082	\N	2025	15	0	15	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
1083	\N	2025	15	0	15	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
1084	\N	2025	15	0	15	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
1085	\N	2025	15	0	15	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
1086	\N	2025	15	0	15	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
1087	\N	2025	15	0	15	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
1088	\N	2025	15	0	15	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
1089	\N	2025	15	0	15	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
1090	\N	2025	15	0	15	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
1091	\N	2025	15	0	15	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
1092	\N	2025	15	0	15	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
1093	\N	2025	15	0	15	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
1094	\N	2025	15	0	15	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
1095	\N	2025	15	0	15	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
1096	\N	2025	15	0	15	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
1097	\N	2025	15	0	15	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
1098	\N	2025	15	0	15	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
1099	\N	2025	15	0	15	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
1100	\N	2025	15	0	15	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
1101	\N	2025	15	0	15	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
1102	\N	2025	15	0	15	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
1103	\N	2025	15	0	15	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
1104	\N	2025	15	0	15	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
1105	\N	2025	15	0	15	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
1106	\N	2025	15	0	15	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
1107	\N	2025	15	0	15	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
1108	\N	2025	15	0	15	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
1109	\N	2025	15	0	15	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
1110	\N	2025	15	0	15	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
1111	\N	2025	15	0	15	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
1112	\N	2025	15	0	15	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
1113	\N	2025	15	0	15	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
1114	\N	2025	15	0	15	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
1115	\N	2025	15	0	15	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
1116	\N	2025	15	0	15	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
1117	\N	2025	15	0	15	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
1118	\N	2025	15	0	15	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
1119	\N	2025	15	0	15	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
1120	\N	2025	15	0	15	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
1121	\N	2025	15	0	15	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
1122	\N	2025	15	0	15	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
1123	\N	2025	15	0	15	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
1124	\N	2025	15	0	15	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
1125	\N	2025	15	0	15	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
1126	\N	2025	15	0	15	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
1127	\N	2025	15	0	15	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
1128	\N	2025	15	0	15	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
1129	\N	2025	15	0	15	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
1130	\N	2025	15	0	15	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
1131	\N	2025	15	0	15	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
1132	\N	2025	15	0	15	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
1133	\N	2025	15	0	15	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
1134	\N	2025	15	0	15	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
1135	\N	2025	15	0	15	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
1136	\N	2025	15	0	15	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
1137	\N	2025	15	0	15	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
1138	\N	2025	15	0	15	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
1139	\N	2025	15	0	15	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
1140	\N	2025	15	0	15	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
1141	\N	2025	15	0	15	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
1142	\N	2025	15	0	15	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
1143	\N	2025	15	0	15	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
1144	\N	2025	15	0	15	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
1145	\N	2025	15	0	15	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
1146	\N	2025	15	0	15	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
1147	\N	2025	15	0	15	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
1148	\N	2025	15	0	15	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
1149	\N	2025	15	0	15	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
1150	\N	2025	15	0	15	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
1151	\N	2025	15	0	15	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
1152	\N	2025	15	0	15	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
1153	\N	2025	15	0	15	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
1154	\N	2025	15	0	15	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
1155	\N	2025	15	0	15	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
1156	\N	2025	15	0	15	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
1157	\N	2025	15	0	15	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
1158	\N	2025	15	0	15	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
1159	\N	2025	15	0	15	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
1160	\N	2025	15	0	15	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
1161	\N	2025	15	0	15	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
1162	\N	2025	15	0	15	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
1163	\N	2025	15	0	15	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
1164	\N	2025	15	0	15	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
1165	\N	2025	15	0	15	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
1166	\N	2025	15	0	15	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
1167	\N	2025	15	0	15	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
1168	\N	2025	15	0	15	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
1169	\N	2025	15	0	15	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
1170	\N	2025	15	0	15	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
1171	\N	2025	15	0	15	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
1172	\N	2025	15	0	15	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
1173	\N	2025	15	0	15	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
1174	\N	2025	15	0	15	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
1175	\N	2025	15	0	15	0	2025-10-17 12:55:18.365031	2025-10-17 12:55:18.365031
1176	\N	2025	15	0	15	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
\.


--
-- Data for Name: leave_entitlements; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.leave_entitlements (id, user_id, leave_type, year, total_days, used_days, created_at, updated_at) FROM stdin;
91	25	VL	2025	15	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
92	25	SL	2025	15	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
93	25	ML	2025	5	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
94	25	SPL	2025	3	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
95	25	MAT	2025	105	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
96	25	PAT	2025	7	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
97	25	SOLO	2025	7	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
98	25	VAWC	2025	10	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
99	25	RL	2025	0	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
100	25	MCW	2025	60	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
101	25	STUDY	2025	180	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
102	25	CALAMITY	2025	5	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
103	25	MOL	2025	0	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
104	25	TL	2025	0	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
105	25	AL	2025	0	0	2025-09-11 02:58:11.319832	2025-09-11 02:58:11.319832
17521	1945	VL	2025	15	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17522	1945	SL	2025	15	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17524	1945	SPL	2025	3	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17525	1945	MAT	2025	105	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17526	1945	PAT	2025	7	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17527	1945	SOLO	2025	7	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17528	1945	VAWC	2025	10	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17529	1945	RL	2025	0	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17530	1945	MCW	2025	60	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17531	1945	STUDY	2025	180	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17532	1945	CALAMITY	2025	5	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17533	1945	MOL	2025	0	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17534	1945	TL	2025	0	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
17535	1945	AL	2025	0	0	2025-10-31 02:48:12.127514	2025-10-31 02:48:12.127514
46	19	VL	2025	15	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
47	19	SL	2025	15	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
48	19	ML	2025	5	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
49	19	SPL	2025	3	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
50	19	MAT	2025	105	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
51	19	PAT	2025	7	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
52	19	SOLO	2025	7	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
53	19	VAWC	2025	10	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
54	19	RL	2025	0	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
55	19	MCW	2025	60	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
56	19	STUDY	2025	180	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
57	19	CALAMITY	2025	5	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
58	19	MOL	2025	0	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
59	19	TL	2025	0	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
60	19	AL	2025	0	0	2025-09-05 07:06:36.467383	2025-09-05 07:06:36.467383
17523	1945	ML	2025	5	3	2025-10-31 02:48:12.127514	2025-11-26 14:47:04.429969
63	23	ML	2025	5	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
64	23	SPL	2025	3	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
65	23	MAT	2025	105	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
66	23	PAT	2025	7	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
67	23	SOLO	2025	7	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
68	23	VAWC	2025	10	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
69	23	RL	2025	0	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
70	23	MCW	2025	60	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
71	23	STUDY	2025	180	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
72	23	CALAMITY	2025	5	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
73	23	MOL	2025	0	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
74	23	TL	2025	0	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
75	23	AL	2025	0	0	2025-09-11 02:40:03.543155	2025-09-11 02:40:03.543155
136	28	VL	2025	15	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
137	28	SL	2025	15	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
138	28	ML	2025	5	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
139	28	SPL	2025	3	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
140	28	MAT	2025	105	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
141	28	PAT	2025	7	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
142	28	SOLO	2025	7	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
143	28	VAWC	2025	10	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
144	28	RL	2025	0	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
145	28	MCW	2025	60	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
146	28	STUDY	2025	180	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
147	28	CALAMITY	2025	5	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
148	28	MOL	2025	0	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
149	28	TL	2025	0	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
150	28	AL	2025	0	0	2025-09-11 12:56:31.29702	2025-09-11 12:56:31.29702
151	29	VL	2025	15	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
152	29	SL	2025	15	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
153	29	ML	2025	5	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
154	29	SPL	2025	3	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
155	29	MAT	2025	105	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
156	29	PAT	2025	7	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
157	29	SOLO	2025	7	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
158	29	VAWC	2025	10	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
159	29	RL	2025	0	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
160	29	MCW	2025	60	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
161	29	STUDY	2025	180	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
162	29	CALAMITY	2025	5	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
163	29	MOL	2025	0	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
164	29	TL	2025	0	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
165	29	AL	2025	0	0	2025-09-12 05:27:36.394569	2025-09-12 05:27:36.394569
62	23	SL	2025	15	2	2025-09-11 02:40:03.543155	2025-09-22 14:04:44.126677
183	31	ML	2025	5	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
184	31	SPL	2025	3	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
185	31	MAT	2025	105	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
186	31	PAT	2025	7	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
187	31	SOLO	2025	7	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
188	31	VAWC	2025	10	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
189	31	RL	2025	0	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
190	31	MCW	2025	60	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
191	31	STUDY	2025	180	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
192	31	CALAMITY	2025	5	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
193	31	MOL	2025	0	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
194	31	TL	2025	0	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
195	31	AL	2025	0	0	2025-09-20 12:12:57.184958	2025-09-20 12:12:57.184958
181	31	VL	2025	15	2	2025-09-20 12:12:57.184958	2025-09-24 00:59:14.893607
182	31	SL	2025	15	1	2025-09-20 12:12:57.184958	2025-09-24 01:12:25.062531
61	23	VL	2025	15	3	2025-09-11 02:40:03.543155	2025-09-28 03:12:25.653861
16366	1867	VL	2025	15	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16367	1867	SL	2025	15	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16368	1867	ML	2025	5	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16369	1867	SPL	2025	3	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16370	1867	MAT	2025	105	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16371	1867	PAT	2025	7	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16372	1867	SOLO	2025	7	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16373	1867	VAWC	2025	10	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16374	1867	RL	2025	0	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16375	1867	MCW	2025	60	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16376	1867	STUDY	2025	180	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
15211	1790	VL	2025	15	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15212	1790	SL	2025	15	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15213	1790	ML	2025	5	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15214	1790	SPL	2025	3	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15215	1790	MAT	2025	105	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15216	1790	PAT	2025	7	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15217	1790	SOLO	2025	7	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15218	1790	VAWC	2025	10	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15219	1790	RL	2025	0	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15220	1790	MCW	2025	60	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15221	1790	STUDY	2025	180	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15222	1790	CALAMITY	2025	5	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15223	1790	MOL	2025	0	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15224	1790	TL	2025	0	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15225	1790	AL	2025	0	0	2025-10-17 12:46:43.965026	2025-10-17 12:46:43.965026
15226	1791	VL	2025	15	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15227	1791	SL	2025	15	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15228	1791	ML	2025	5	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15229	1791	SPL	2025	3	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15230	1791	MAT	2025	105	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15231	1791	PAT	2025	7	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15232	1791	SOLO	2025	7	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15233	1791	VAWC	2025	10	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15234	1791	RL	2025	0	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15235	1791	MCW	2025	60	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15236	1791	STUDY	2025	180	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15237	1791	CALAMITY	2025	5	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15238	1791	MOL	2025	0	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15239	1791	TL	2025	0	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15240	1791	AL	2025	0	0	2025-10-17 12:46:44.186234	2025-10-17 12:46:44.186234
15241	1792	VL	2025	15	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15242	1792	SL	2025	15	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15243	1792	ML	2025	5	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15244	1792	SPL	2025	3	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15245	1792	MAT	2025	105	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15246	1792	PAT	2025	7	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15247	1792	SOLO	2025	7	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15248	1792	VAWC	2025	10	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15249	1792	RL	2025	0	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15250	1792	MCW	2025	60	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15251	1792	STUDY	2025	180	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15252	1792	CALAMITY	2025	5	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15253	1792	MOL	2025	0	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15254	1792	TL	2025	0	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15255	1792	AL	2025	0	0	2025-10-17 12:46:44.265797	2025-10-17 12:46:44.265797
15256	1793	VL	2025	15	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15257	1793	SL	2025	15	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15258	1793	ML	2025	5	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15259	1793	SPL	2025	3	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15260	1793	MAT	2025	105	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15261	1793	PAT	2025	7	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15262	1793	SOLO	2025	7	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15263	1793	VAWC	2025	10	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15264	1793	RL	2025	0	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15265	1793	MCW	2025	60	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15266	1793	STUDY	2025	180	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15267	1793	CALAMITY	2025	5	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15268	1793	MOL	2025	0	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15269	1793	TL	2025	0	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15270	1793	AL	2025	0	0	2025-10-17 12:46:44.339068	2025-10-17 12:46:44.339068
15271	1794	VL	2025	15	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15272	1794	SL	2025	15	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15273	1794	ML	2025	5	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15274	1794	SPL	2025	3	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15275	1794	MAT	2025	105	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15276	1794	PAT	2025	7	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15277	1794	SOLO	2025	7	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15278	1794	VAWC	2025	10	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15279	1794	RL	2025	0	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15280	1794	MCW	2025	60	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15281	1794	STUDY	2025	180	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15282	1794	CALAMITY	2025	5	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15283	1794	MOL	2025	0	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15284	1794	TL	2025	0	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15285	1794	AL	2025	0	0	2025-10-17 12:46:44.488067	2025-10-17 12:46:44.488067
15286	1795	VL	2025	15	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15287	1795	SL	2025	15	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15288	1795	ML	2025	5	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15289	1795	SPL	2025	3	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15290	1795	MAT	2025	105	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15291	1795	PAT	2025	7	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15292	1795	SOLO	2025	7	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15293	1795	VAWC	2025	10	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15294	1795	RL	2025	0	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15295	1795	MCW	2025	60	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15296	1795	STUDY	2025	180	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15297	1795	CALAMITY	2025	5	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15298	1795	MOL	2025	0	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15299	1795	TL	2025	0	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15300	1795	AL	2025	0	0	2025-10-17 12:46:44.572712	2025-10-17 12:46:44.572712
15301	1796	VL	2025	15	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15302	1796	SL	2025	15	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15303	1796	ML	2025	5	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15304	1796	SPL	2025	3	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15305	1796	MAT	2025	105	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15306	1796	PAT	2025	7	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15307	1796	SOLO	2025	7	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15308	1796	VAWC	2025	10	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15309	1796	RL	2025	0	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15310	1796	MCW	2025	60	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15311	1796	STUDY	2025	180	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15312	1796	CALAMITY	2025	5	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15313	1796	MOL	2025	0	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15314	1796	TL	2025	0	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15315	1796	AL	2025	0	0	2025-10-17 12:46:44.648934	2025-10-17 12:46:44.648934
15316	1797	VL	2025	15	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15317	1797	SL	2025	15	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15318	1797	ML	2025	5	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15319	1797	SPL	2025	3	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15320	1797	MAT	2025	105	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15321	1797	PAT	2025	7	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15322	1797	SOLO	2025	7	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15323	1797	VAWC	2025	10	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15324	1797	RL	2025	0	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15325	1797	MCW	2025	60	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15326	1797	STUDY	2025	180	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15327	1797	CALAMITY	2025	5	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15328	1797	MOL	2025	0	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15329	1797	TL	2025	0	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15330	1797	AL	2025	0	0	2025-10-17 12:46:44.747689	2025-10-17 12:46:44.747689
15331	1798	VL	2025	15	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15332	1798	SL	2025	15	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15333	1798	ML	2025	5	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15334	1798	SPL	2025	3	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15335	1798	MAT	2025	105	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15336	1798	PAT	2025	7	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15337	1798	SOLO	2025	7	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15338	1798	VAWC	2025	10	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15339	1798	RL	2025	0	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15340	1798	MCW	2025	60	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15341	1798	STUDY	2025	180	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15342	1798	CALAMITY	2025	5	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15343	1798	MOL	2025	0	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15344	1798	TL	2025	0	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15345	1798	AL	2025	0	0	2025-10-17 12:46:44.877884	2025-10-17 12:46:44.877884
15346	1799	VL	2025	15	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15347	1799	SL	2025	15	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15348	1799	ML	2025	5	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15349	1799	SPL	2025	3	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15350	1799	MAT	2025	105	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15351	1799	PAT	2025	7	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15352	1799	SOLO	2025	7	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15353	1799	VAWC	2025	10	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15354	1799	RL	2025	0	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15355	1799	MCW	2025	60	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15356	1799	STUDY	2025	180	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15357	1799	CALAMITY	2025	5	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15358	1799	MOL	2025	0	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15359	1799	TL	2025	0	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15360	1799	AL	2025	0	0	2025-10-17 12:46:44.948659	2025-10-17 12:46:44.948659
15361	1800	VL	2025	15	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15362	1800	SL	2025	15	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15363	1800	ML	2025	5	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15364	1800	SPL	2025	3	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15365	1800	MAT	2025	105	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15366	1800	PAT	2025	7	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15367	1800	SOLO	2025	7	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15368	1800	VAWC	2025	10	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15369	1800	RL	2025	0	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15370	1800	MCW	2025	60	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15371	1800	STUDY	2025	180	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15372	1800	CALAMITY	2025	5	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15373	1800	MOL	2025	0	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15374	1800	TL	2025	0	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15375	1800	AL	2025	0	0	2025-10-17 12:46:45.037561	2025-10-17 12:46:45.037561
15376	1801	VL	2025	15	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15377	1801	SL	2025	15	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15378	1801	ML	2025	5	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15379	1801	SPL	2025	3	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15380	1801	MAT	2025	105	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15381	1801	PAT	2025	7	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15382	1801	SOLO	2025	7	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15383	1801	VAWC	2025	10	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15384	1801	RL	2025	0	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15385	1801	MCW	2025	60	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15386	1801	STUDY	2025	180	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15387	1801	CALAMITY	2025	5	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15388	1801	MOL	2025	0	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15389	1801	TL	2025	0	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15390	1801	AL	2025	0	0	2025-10-17 12:46:45.120886	2025-10-17 12:46:45.120886
15391	1802	VL	2025	15	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15392	1802	SL	2025	15	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15393	1802	ML	2025	5	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15394	1802	SPL	2025	3	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15395	1802	MAT	2025	105	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15396	1802	PAT	2025	7	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15397	1802	SOLO	2025	7	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15398	1802	VAWC	2025	10	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15399	1802	RL	2025	0	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15400	1802	MCW	2025	60	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15401	1802	STUDY	2025	180	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15402	1802	CALAMITY	2025	5	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15403	1802	MOL	2025	0	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15404	1802	TL	2025	0	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15405	1802	AL	2025	0	0	2025-10-17 12:46:45.258594	2025-10-17 12:46:45.258594
15406	1803	VL	2025	15	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15407	1803	SL	2025	15	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15408	1803	ML	2025	5	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15409	1803	SPL	2025	3	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15410	1803	MAT	2025	105	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15411	1803	PAT	2025	7	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15412	1803	SOLO	2025	7	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15413	1803	VAWC	2025	10	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15414	1803	RL	2025	0	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15415	1803	MCW	2025	60	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15416	1803	STUDY	2025	180	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15417	1803	CALAMITY	2025	5	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15418	1803	MOL	2025	0	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15419	1803	TL	2025	0	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15420	1803	AL	2025	0	0	2025-10-17 12:46:45.329821	2025-10-17 12:46:45.329821
15421	1804	VL	2025	15	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15422	1804	SL	2025	15	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15423	1804	ML	2025	5	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15424	1804	SPL	2025	3	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15425	1804	MAT	2025	105	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15426	1804	PAT	2025	7	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15427	1804	SOLO	2025	7	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15428	1804	VAWC	2025	10	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15429	1804	RL	2025	0	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15430	1804	MCW	2025	60	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15431	1804	STUDY	2025	180	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15432	1804	CALAMITY	2025	5	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15433	1804	MOL	2025	0	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15434	1804	TL	2025	0	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15435	1804	AL	2025	0	0	2025-10-17 12:46:45.404889	2025-10-17 12:46:45.404889
15436	1805	VL	2025	15	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15437	1805	SL	2025	15	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15438	1805	ML	2025	5	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15439	1805	SPL	2025	3	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15440	1805	MAT	2025	105	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15441	1805	PAT	2025	7	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15442	1805	SOLO	2025	7	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15443	1805	VAWC	2025	10	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15444	1805	RL	2025	0	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15445	1805	MCW	2025	60	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15446	1805	STUDY	2025	180	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15447	1805	CALAMITY	2025	5	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15448	1805	MOL	2025	0	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15449	1805	TL	2025	0	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15450	1805	AL	2025	0	0	2025-10-17 12:46:45.490162	2025-10-17 12:46:45.490162
15451	1806	VL	2025	15	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15452	1806	SL	2025	15	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15453	1806	ML	2025	5	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15454	1806	SPL	2025	3	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15455	1806	MAT	2025	105	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15456	1806	PAT	2025	7	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15457	1806	SOLO	2025	7	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15458	1806	VAWC	2025	10	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15459	1806	RL	2025	0	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15460	1806	MCW	2025	60	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15461	1806	STUDY	2025	180	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15462	1806	CALAMITY	2025	5	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15463	1806	MOL	2025	0	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15464	1806	TL	2025	0	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15465	1806	AL	2025	0	0	2025-10-17 12:46:45.645702	2025-10-17 12:46:45.645702
15466	1807	VL	2025	15	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15467	1807	SL	2025	15	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15468	1807	ML	2025	5	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15469	1807	SPL	2025	3	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15470	1807	MAT	2025	105	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15471	1807	PAT	2025	7	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15472	1807	SOLO	2025	7	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15473	1807	VAWC	2025	10	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15474	1807	RL	2025	0	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15475	1807	MCW	2025	60	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15476	1807	STUDY	2025	180	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15477	1807	CALAMITY	2025	5	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15478	1807	MOL	2025	0	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15479	1807	TL	2025	0	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15480	1807	AL	2025	0	0	2025-10-17 12:46:45.724871	2025-10-17 12:46:45.724871
15481	1808	VL	2025	15	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15482	1808	SL	2025	15	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15483	1808	ML	2025	5	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15484	1808	SPL	2025	3	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15485	1808	MAT	2025	105	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15486	1808	PAT	2025	7	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15487	1808	SOLO	2025	7	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15488	1808	VAWC	2025	10	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15489	1808	RL	2025	0	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15490	1808	MCW	2025	60	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15491	1808	STUDY	2025	180	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15492	1808	CALAMITY	2025	5	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15493	1808	MOL	2025	0	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15494	1808	TL	2025	0	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15495	1808	AL	2025	0	0	2025-10-17 12:46:45.804837	2025-10-17 12:46:45.804837
15496	1809	VL	2025	15	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15497	1809	SL	2025	15	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15498	1809	ML	2025	5	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15499	1809	SPL	2025	3	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15500	1809	MAT	2025	105	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15501	1809	PAT	2025	7	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15502	1809	SOLO	2025	7	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15503	1809	VAWC	2025	10	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15504	1809	RL	2025	0	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15505	1809	MCW	2025	60	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15506	1809	STUDY	2025	180	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15507	1809	CALAMITY	2025	5	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15508	1809	MOL	2025	0	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15509	1809	TL	2025	0	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15510	1809	AL	2025	0	0	2025-10-17 12:46:46.007646	2025-10-17 12:46:46.007646
15511	1810	VL	2025	15	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15512	1810	SL	2025	15	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15513	1810	ML	2025	5	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15514	1810	SPL	2025	3	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15515	1810	MAT	2025	105	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15516	1810	PAT	2025	7	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15517	1810	SOLO	2025	7	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15518	1810	VAWC	2025	10	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15519	1810	RL	2025	0	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15520	1810	MCW	2025	60	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15521	1810	STUDY	2025	180	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15522	1810	CALAMITY	2025	5	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15523	1810	MOL	2025	0	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15524	1810	TL	2025	0	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15525	1810	AL	2025	0	0	2025-10-17 12:46:46.081087	2025-10-17 12:46:46.081087
15526	1811	VL	2025	15	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15527	1811	SL	2025	15	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15528	1811	ML	2025	5	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15529	1811	SPL	2025	3	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15530	1811	MAT	2025	105	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15531	1811	PAT	2025	7	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15532	1811	SOLO	2025	7	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15533	1811	VAWC	2025	10	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15534	1811	RL	2025	0	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15535	1811	MCW	2025	60	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15536	1811	STUDY	2025	180	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15537	1811	CALAMITY	2025	5	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15538	1811	MOL	2025	0	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15539	1811	TL	2025	0	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15540	1811	AL	2025	0	0	2025-10-17 12:46:46.170192	2025-10-17 12:46:46.170192
15541	1812	VL	2025	15	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15542	1812	SL	2025	15	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15543	1812	ML	2025	5	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15544	1812	SPL	2025	3	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15545	1812	MAT	2025	105	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15546	1812	PAT	2025	7	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15547	1812	SOLO	2025	7	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15548	1812	VAWC	2025	10	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15549	1812	RL	2025	0	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15550	1812	MCW	2025	60	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15551	1812	STUDY	2025	180	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15552	1812	CALAMITY	2025	5	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15553	1812	MOL	2025	0	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15554	1812	TL	2025	0	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15555	1812	AL	2025	0	0	2025-10-17 12:46:46.250758	2025-10-17 12:46:46.250758
15556	1813	VL	2025	15	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15557	1813	SL	2025	15	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15558	1813	ML	2025	5	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15559	1813	SPL	2025	3	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15560	1813	MAT	2025	105	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15561	1813	PAT	2025	7	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15562	1813	SOLO	2025	7	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15563	1813	VAWC	2025	10	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15564	1813	RL	2025	0	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15565	1813	MCW	2025	60	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15566	1813	STUDY	2025	180	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15567	1813	CALAMITY	2025	5	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15568	1813	MOL	2025	0	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15569	1813	TL	2025	0	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15570	1813	AL	2025	0	0	2025-10-17 12:46:46.389141	2025-10-17 12:46:46.389141
15571	1814	VL	2025	15	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15572	1814	SL	2025	15	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15573	1814	ML	2025	5	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15574	1814	SPL	2025	3	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15575	1814	MAT	2025	105	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15576	1814	PAT	2025	7	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15577	1814	SOLO	2025	7	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15578	1814	VAWC	2025	10	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15579	1814	RL	2025	0	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15580	1814	MCW	2025	60	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15581	1814	STUDY	2025	180	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15582	1814	CALAMITY	2025	5	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15583	1814	MOL	2025	0	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15584	1814	TL	2025	0	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15585	1814	AL	2025	0	0	2025-10-17 12:46:46.467783	2025-10-17 12:46:46.467783
15586	1815	VL	2025	15	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15587	1815	SL	2025	15	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15588	1815	ML	2025	5	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15589	1815	SPL	2025	3	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15590	1815	MAT	2025	105	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15591	1815	PAT	2025	7	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15592	1815	SOLO	2025	7	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15593	1815	VAWC	2025	10	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15594	1815	RL	2025	0	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15595	1815	MCW	2025	60	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15596	1815	STUDY	2025	180	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15597	1815	CALAMITY	2025	5	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15598	1815	MOL	2025	0	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15599	1815	TL	2025	0	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15600	1815	AL	2025	0	0	2025-10-17 12:46:46.547937	2025-10-17 12:46:46.547937
15601	1816	VL	2025	15	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15602	1816	SL	2025	15	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15603	1816	ML	2025	5	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15604	1816	SPL	2025	3	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15605	1816	MAT	2025	105	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15606	1816	PAT	2025	7	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15607	1816	SOLO	2025	7	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15608	1816	VAWC	2025	10	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15609	1816	RL	2025	0	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15610	1816	MCW	2025	60	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15611	1816	STUDY	2025	180	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15612	1816	CALAMITY	2025	5	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15613	1816	MOL	2025	0	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15614	1816	TL	2025	0	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15615	1816	AL	2025	0	0	2025-10-17 12:46:46.639223	2025-10-17 12:46:46.639223
15616	1817	VL	2025	15	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15617	1817	SL	2025	15	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15618	1817	ML	2025	5	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15619	1817	SPL	2025	3	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15620	1817	MAT	2025	105	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15621	1817	PAT	2025	7	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15622	1817	SOLO	2025	7	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15623	1817	VAWC	2025	10	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15624	1817	RL	2025	0	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15625	1817	MCW	2025	60	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15626	1817	STUDY	2025	180	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15627	1817	CALAMITY	2025	5	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15628	1817	MOL	2025	0	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15629	1817	TL	2025	0	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15630	1817	AL	2025	0	0	2025-10-17 12:46:46.772879	2025-10-17 12:46:46.772879
15631	1818	VL	2025	15	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15632	1818	SL	2025	15	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15633	1818	ML	2025	5	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15634	1818	SPL	2025	3	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15635	1818	MAT	2025	105	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15636	1818	PAT	2025	7	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15637	1818	SOLO	2025	7	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15638	1818	VAWC	2025	10	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15639	1818	RL	2025	0	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15640	1818	MCW	2025	60	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15641	1818	STUDY	2025	180	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15642	1818	CALAMITY	2025	5	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15643	1818	MOL	2025	0	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15644	1818	TL	2025	0	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15645	1818	AL	2025	0	0	2025-10-17 12:46:46.854026	2025-10-17 12:46:46.854026
15646	1819	VL	2025	15	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15647	1819	SL	2025	15	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15648	1819	ML	2025	5	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15649	1819	SPL	2025	3	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15650	1819	MAT	2025	105	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15651	1819	PAT	2025	7	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15652	1819	SOLO	2025	7	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15653	1819	VAWC	2025	10	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15654	1819	RL	2025	0	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15655	1819	MCW	2025	60	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15656	1819	STUDY	2025	180	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15657	1819	CALAMITY	2025	5	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15658	1819	MOL	2025	0	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15659	1819	TL	2025	0	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15660	1819	AL	2025	0	0	2025-10-17 12:46:46.934437	2025-10-17 12:46:46.934437
15661	1820	VL	2025	15	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15662	1820	SL	2025	15	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15663	1820	ML	2025	5	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15664	1820	SPL	2025	3	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15665	1820	MAT	2025	105	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15666	1820	PAT	2025	7	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15667	1820	SOLO	2025	7	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15668	1820	VAWC	2025	10	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15669	1820	RL	2025	0	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15670	1820	MCW	2025	60	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15671	1820	STUDY	2025	180	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15672	1820	CALAMITY	2025	5	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15673	1820	MOL	2025	0	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15674	1820	TL	2025	0	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15675	1820	AL	2025	0	0	2025-10-17 12:46:47.004877	2025-10-17 12:46:47.004877
15676	1821	VL	2025	15	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15677	1821	SL	2025	15	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15678	1821	ML	2025	5	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15679	1821	SPL	2025	3	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15680	1821	MAT	2025	105	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15681	1821	PAT	2025	7	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15682	1821	SOLO	2025	7	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15683	1821	VAWC	2025	10	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15684	1821	RL	2025	0	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15685	1821	MCW	2025	60	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15686	1821	STUDY	2025	180	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15687	1821	CALAMITY	2025	5	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15688	1821	MOL	2025	0	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15689	1821	TL	2025	0	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15690	1821	AL	2025	0	0	2025-10-17 12:46:47.178672	2025-10-17 12:46:47.178672
15691	1822	VL	2025	15	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15692	1822	SL	2025	15	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15693	1822	ML	2025	5	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15694	1822	SPL	2025	3	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15695	1822	MAT	2025	105	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15696	1822	PAT	2025	7	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15697	1822	SOLO	2025	7	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15698	1822	VAWC	2025	10	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15699	1822	RL	2025	0	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15700	1822	MCW	2025	60	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15701	1822	STUDY	2025	180	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15702	1822	CALAMITY	2025	5	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15703	1822	MOL	2025	0	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15704	1822	TL	2025	0	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15705	1822	AL	2025	0	0	2025-10-17 12:46:47.268995	2025-10-17 12:46:47.268995
15706	1823	VL	2025	15	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15707	1823	SL	2025	15	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15708	1823	ML	2025	5	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15709	1823	SPL	2025	3	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15710	1823	MAT	2025	105	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15711	1823	PAT	2025	7	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15712	1823	SOLO	2025	7	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15713	1823	VAWC	2025	10	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15714	1823	RL	2025	0	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15715	1823	MCW	2025	60	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15716	1823	STUDY	2025	180	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15717	1823	CALAMITY	2025	5	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15718	1823	MOL	2025	0	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15719	1823	TL	2025	0	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15720	1823	AL	2025	0	0	2025-10-17 12:46:47.351989	2025-10-17 12:46:47.351989
15721	1824	VL	2025	15	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15722	1824	SL	2025	15	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15723	1824	ML	2025	5	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15724	1824	SPL	2025	3	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15725	1824	MAT	2025	105	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15726	1824	PAT	2025	7	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15727	1824	SOLO	2025	7	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15728	1824	VAWC	2025	10	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15729	1824	RL	2025	0	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15730	1824	MCW	2025	60	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15731	1824	STUDY	2025	180	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15732	1824	CALAMITY	2025	5	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15733	1824	MOL	2025	0	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15734	1824	TL	2025	0	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15735	1824	AL	2025	0	0	2025-10-17 12:46:47.528835	2025-10-17 12:46:47.528835
15736	1825	VL	2025	15	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15737	1825	SL	2025	15	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15738	1825	ML	2025	5	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15739	1825	SPL	2025	3	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15740	1825	MAT	2025	105	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15741	1825	PAT	2025	7	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15742	1825	SOLO	2025	7	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15743	1825	VAWC	2025	10	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15744	1825	RL	2025	0	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15745	1825	MCW	2025	60	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15746	1825	STUDY	2025	180	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15747	1825	CALAMITY	2025	5	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15748	1825	MOL	2025	0	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15749	1825	TL	2025	0	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15750	1825	AL	2025	0	0	2025-10-17 12:46:47.618089	2025-10-17 12:46:47.618089
15751	1826	VL	2025	15	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15752	1826	SL	2025	15	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15753	1826	ML	2025	5	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15754	1826	SPL	2025	3	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15755	1826	MAT	2025	105	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15756	1826	PAT	2025	7	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15757	1826	SOLO	2025	7	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15758	1826	VAWC	2025	10	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15759	1826	RL	2025	0	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15760	1826	MCW	2025	60	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15761	1826	STUDY	2025	180	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15762	1826	CALAMITY	2025	5	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15763	1826	MOL	2025	0	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15764	1826	TL	2025	0	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15765	1826	AL	2025	0	0	2025-10-17 12:46:47.732887	2025-10-17 12:46:47.732887
15766	1827	VL	2025	15	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15767	1827	SL	2025	15	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15768	1827	ML	2025	5	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15769	1827	SPL	2025	3	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15770	1827	MAT	2025	105	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15771	1827	PAT	2025	7	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15772	1827	SOLO	2025	7	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15773	1827	VAWC	2025	10	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15774	1827	RL	2025	0	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15775	1827	MCW	2025	60	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15776	1827	STUDY	2025	180	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15777	1827	CALAMITY	2025	5	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15778	1827	MOL	2025	0	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15779	1827	TL	2025	0	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15780	1827	AL	2025	0	0	2025-10-17 12:46:47.909447	2025-10-17 12:46:47.909447
15781	1828	VL	2025	15	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15782	1828	SL	2025	15	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15783	1828	ML	2025	5	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15784	1828	SPL	2025	3	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15785	1828	MAT	2025	105	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15786	1828	PAT	2025	7	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15787	1828	SOLO	2025	7	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15788	1828	VAWC	2025	10	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15789	1828	RL	2025	0	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15790	1828	MCW	2025	60	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15791	1828	STUDY	2025	180	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15792	1828	CALAMITY	2025	5	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15793	1828	MOL	2025	0	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15794	1828	TL	2025	0	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15795	1828	AL	2025	0	0	2025-10-17 12:46:47.982717	2025-10-17 12:46:47.982717
15796	1829	VL	2025	15	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15797	1829	SL	2025	15	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15798	1829	ML	2025	5	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15799	1829	SPL	2025	3	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15800	1829	MAT	2025	105	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15801	1829	PAT	2025	7	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15802	1829	SOLO	2025	7	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15803	1829	VAWC	2025	10	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15804	1829	RL	2025	0	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15805	1829	MCW	2025	60	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15806	1829	STUDY	2025	180	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15807	1829	CALAMITY	2025	5	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15808	1829	MOL	2025	0	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15809	1829	TL	2025	0	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15810	1829	AL	2025	0	0	2025-10-17 12:46:48.063763	2025-10-17 12:46:48.063763
15811	1830	VL	2025	15	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15812	1830	SL	2025	15	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15813	1830	ML	2025	5	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15814	1830	SPL	2025	3	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15815	1830	MAT	2025	105	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15816	1830	PAT	2025	7	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15817	1830	SOLO	2025	7	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15818	1830	VAWC	2025	10	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15819	1830	RL	2025	0	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15820	1830	MCW	2025	60	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15821	1830	STUDY	2025	180	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15822	1830	CALAMITY	2025	5	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15823	1830	MOL	2025	0	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15824	1830	TL	2025	0	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15825	1830	AL	2025	0	0	2025-10-17 12:46:48.151453	2025-10-17 12:46:48.151453
15826	1831	VL	2025	15	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15827	1831	SL	2025	15	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15828	1831	ML	2025	5	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15829	1831	SPL	2025	3	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15830	1831	MAT	2025	105	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15831	1831	PAT	2025	7	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15832	1831	SOLO	2025	7	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15833	1831	VAWC	2025	10	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15834	1831	RL	2025	0	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15835	1831	MCW	2025	60	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15836	1831	STUDY	2025	180	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15837	1831	CALAMITY	2025	5	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15838	1831	MOL	2025	0	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15839	1831	TL	2025	0	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15840	1831	AL	2025	0	0	2025-10-17 12:46:48.29433	2025-10-17 12:46:48.29433
15841	1832	VL	2025	15	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15842	1832	SL	2025	15	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15843	1832	ML	2025	5	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15844	1832	SPL	2025	3	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15845	1832	MAT	2025	105	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15846	1832	PAT	2025	7	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15847	1832	SOLO	2025	7	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15848	1832	VAWC	2025	10	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15849	1832	RL	2025	0	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15850	1832	MCW	2025	60	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15851	1832	STUDY	2025	180	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15852	1832	CALAMITY	2025	5	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15853	1832	MOL	2025	0	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15854	1832	TL	2025	0	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15855	1832	AL	2025	0	0	2025-10-17 12:46:48.373308	2025-10-17 12:46:48.373308
15856	1833	VL	2025	15	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15857	1833	SL	2025	15	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15858	1833	ML	2025	5	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15859	1833	SPL	2025	3	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15860	1833	MAT	2025	105	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15861	1833	PAT	2025	7	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15862	1833	SOLO	2025	7	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15863	1833	VAWC	2025	10	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15864	1833	RL	2025	0	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15865	1833	MCW	2025	60	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15866	1833	STUDY	2025	180	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15867	1833	CALAMITY	2025	5	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15868	1833	MOL	2025	0	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15869	1833	TL	2025	0	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15870	1833	AL	2025	0	0	2025-10-17 12:46:48.459651	2025-10-17 12:46:48.459651
15871	1834	VL	2025	15	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15872	1834	SL	2025	15	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15873	1834	ML	2025	5	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15874	1834	SPL	2025	3	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15875	1834	MAT	2025	105	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15876	1834	PAT	2025	7	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15877	1834	SOLO	2025	7	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15878	1834	VAWC	2025	10	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15879	1834	RL	2025	0	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15880	1834	MCW	2025	60	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15881	1834	STUDY	2025	180	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15882	1834	CALAMITY	2025	5	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15883	1834	MOL	2025	0	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15884	1834	TL	2025	0	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15885	1834	AL	2025	0	0	2025-10-17 12:46:48.548508	2025-10-17 12:46:48.548508
15886	1835	VL	2025	15	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15887	1835	SL	2025	15	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15888	1835	ML	2025	5	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15889	1835	SPL	2025	3	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15890	1835	MAT	2025	105	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15891	1835	PAT	2025	7	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15892	1835	SOLO	2025	7	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15893	1835	VAWC	2025	10	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15894	1835	RL	2025	0	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15895	1835	MCW	2025	60	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15896	1835	STUDY	2025	180	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15897	1835	CALAMITY	2025	5	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15898	1835	MOL	2025	0	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15899	1835	TL	2025	0	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15900	1835	AL	2025	0	0	2025-10-17 12:46:48.66897	2025-10-17 12:46:48.66897
15901	1836	VL	2025	15	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15902	1836	SL	2025	15	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15903	1836	ML	2025	5	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15904	1836	SPL	2025	3	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15905	1836	MAT	2025	105	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15906	1836	PAT	2025	7	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15907	1836	SOLO	2025	7	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15908	1836	VAWC	2025	10	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15909	1836	RL	2025	0	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15910	1836	MCW	2025	60	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15911	1836	STUDY	2025	180	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15912	1836	CALAMITY	2025	5	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15913	1836	MOL	2025	0	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15914	1836	TL	2025	0	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15915	1836	AL	2025	0	0	2025-10-17 12:46:48.739855	2025-10-17 12:46:48.739855
15916	1837	VL	2025	15	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15917	1837	SL	2025	15	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15918	1837	ML	2025	5	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15919	1837	SPL	2025	3	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15920	1837	MAT	2025	105	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15921	1837	PAT	2025	7	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15922	1837	SOLO	2025	7	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15923	1837	VAWC	2025	10	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15924	1837	RL	2025	0	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15925	1837	MCW	2025	60	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15926	1837	STUDY	2025	180	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15927	1837	CALAMITY	2025	5	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15928	1837	MOL	2025	0	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15929	1837	TL	2025	0	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15930	1837	AL	2025	0	0	2025-10-17 12:46:48.818124	2025-10-17 12:46:48.818124
15931	1838	VL	2025	15	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15932	1838	SL	2025	15	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15933	1838	ML	2025	5	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15934	1838	SPL	2025	3	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15935	1838	MAT	2025	105	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15936	1838	PAT	2025	7	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15937	1838	SOLO	2025	7	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15938	1838	VAWC	2025	10	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15939	1838	RL	2025	0	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15940	1838	MCW	2025	60	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15941	1838	STUDY	2025	180	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15942	1838	CALAMITY	2025	5	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15943	1838	MOL	2025	0	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15944	1838	TL	2025	0	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15945	1838	AL	2025	0	0	2025-10-17 12:46:48.92507	2025-10-17 12:46:48.92507
15946	1839	VL	2025	15	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15947	1839	SL	2025	15	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15948	1839	ML	2025	5	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15949	1839	SPL	2025	3	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15950	1839	MAT	2025	105	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15951	1839	PAT	2025	7	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15952	1839	SOLO	2025	7	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15953	1839	VAWC	2025	10	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15954	1839	RL	2025	0	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15955	1839	MCW	2025	60	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15956	1839	STUDY	2025	180	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15957	1839	CALAMITY	2025	5	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15958	1839	MOL	2025	0	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15959	1839	TL	2025	0	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15960	1839	AL	2025	0	0	2025-10-17 12:46:49.058052	2025-10-17 12:46:49.058052
15961	1840	VL	2025	15	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15962	1840	SL	2025	15	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15963	1840	ML	2025	5	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15964	1840	SPL	2025	3	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15965	1840	MAT	2025	105	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15966	1840	PAT	2025	7	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15967	1840	SOLO	2025	7	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15968	1840	VAWC	2025	10	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15969	1840	RL	2025	0	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15970	1840	MCW	2025	60	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15971	1840	STUDY	2025	180	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15972	1840	CALAMITY	2025	5	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15973	1840	MOL	2025	0	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15974	1840	TL	2025	0	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15975	1840	AL	2025	0	0	2025-10-17 12:46:49.135104	2025-10-17 12:46:49.135104
15976	1841	VL	2025	15	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15977	1841	SL	2025	15	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15978	1841	ML	2025	5	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15979	1841	SPL	2025	3	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15980	1841	MAT	2025	105	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15981	1841	PAT	2025	7	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15982	1841	SOLO	2025	7	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15983	1841	VAWC	2025	10	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15984	1841	RL	2025	0	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15985	1841	MCW	2025	60	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15986	1841	STUDY	2025	180	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15987	1841	CALAMITY	2025	5	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15988	1841	MOL	2025	0	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15989	1841	TL	2025	0	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15990	1841	AL	2025	0	0	2025-10-17 12:46:49.222833	2025-10-17 12:46:49.222833
15991	1842	VL	2025	15	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15992	1842	SL	2025	15	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15993	1842	ML	2025	5	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15994	1842	SPL	2025	3	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15995	1842	MAT	2025	105	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15996	1842	PAT	2025	7	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15997	1842	SOLO	2025	7	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15998	1842	VAWC	2025	10	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
15999	1842	RL	2025	0	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16000	1842	MCW	2025	60	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16001	1842	STUDY	2025	180	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16002	1842	CALAMITY	2025	5	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16003	1842	MOL	2025	0	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16004	1842	TL	2025	0	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16005	1842	AL	2025	0	0	2025-10-17 12:46:49.300913	2025-10-17 12:46:49.300913
16006	1843	VL	2025	15	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16007	1843	SL	2025	15	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16008	1843	ML	2025	5	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16009	1843	SPL	2025	3	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16010	1843	MAT	2025	105	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16011	1843	PAT	2025	7	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16012	1843	SOLO	2025	7	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16013	1843	VAWC	2025	10	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16014	1843	RL	2025	0	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16015	1843	MCW	2025	60	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16016	1843	STUDY	2025	180	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16017	1843	CALAMITY	2025	5	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16018	1843	MOL	2025	0	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16019	1843	TL	2025	0	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16020	1843	AL	2025	0	0	2025-10-17 12:46:49.429141	2025-10-17 12:46:49.429141
16021	1844	VL	2025	15	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16022	1844	SL	2025	15	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16023	1844	ML	2025	5	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16024	1844	SPL	2025	3	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16025	1844	MAT	2025	105	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16026	1844	PAT	2025	7	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16027	1844	SOLO	2025	7	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16028	1844	VAWC	2025	10	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16029	1844	RL	2025	0	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16030	1844	MCW	2025	60	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16031	1844	STUDY	2025	180	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16032	1844	CALAMITY	2025	5	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16033	1844	MOL	2025	0	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16034	1844	TL	2025	0	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16035	1844	AL	2025	0	0	2025-10-17 12:46:49.527947	2025-10-17 12:46:49.527947
16036	1845	VL	2025	15	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16037	1845	SL	2025	15	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16038	1845	ML	2025	5	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16039	1845	SPL	2025	3	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16040	1845	MAT	2025	105	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16041	1845	PAT	2025	7	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16042	1845	SOLO	2025	7	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16043	1845	VAWC	2025	10	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16044	1845	RL	2025	0	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16045	1845	MCW	2025	60	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16046	1845	STUDY	2025	180	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16047	1845	CALAMITY	2025	5	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16048	1845	MOL	2025	0	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16049	1845	TL	2025	0	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16050	1845	AL	2025	0	0	2025-10-17 12:46:49.597818	2025-10-17 12:46:49.597818
16051	1846	VL	2025	15	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16052	1846	SL	2025	15	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16053	1846	ML	2025	5	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16054	1846	SPL	2025	3	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16055	1846	MAT	2025	105	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16056	1846	PAT	2025	7	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16057	1846	SOLO	2025	7	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16058	1846	VAWC	2025	10	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16059	1846	RL	2025	0	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16060	1846	MCW	2025	60	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16061	1846	STUDY	2025	180	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16062	1846	CALAMITY	2025	5	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16063	1846	MOL	2025	0	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16064	1846	TL	2025	0	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16065	1846	AL	2025	0	0	2025-10-17 12:46:49.688995	2025-10-17 12:46:49.688995
16066	1847	VL	2025	15	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16067	1847	SL	2025	15	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16068	1847	ML	2025	5	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16069	1847	SPL	2025	3	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16070	1847	MAT	2025	105	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16071	1847	PAT	2025	7	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16072	1847	SOLO	2025	7	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16073	1847	VAWC	2025	10	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16074	1847	RL	2025	0	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16075	1847	MCW	2025	60	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16076	1847	STUDY	2025	180	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16077	1847	CALAMITY	2025	5	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16078	1847	MOL	2025	0	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16079	1847	TL	2025	0	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16080	1847	AL	2025	0	0	2025-10-17 12:46:49.806912	2025-10-17 12:46:49.806912
16081	1848	VL	2025	15	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16082	1848	SL	2025	15	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16083	1848	ML	2025	5	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16084	1848	SPL	2025	3	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16085	1848	MAT	2025	105	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16086	1848	PAT	2025	7	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16087	1848	SOLO	2025	7	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16088	1848	VAWC	2025	10	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16089	1848	RL	2025	0	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16090	1848	MCW	2025	60	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16091	1848	STUDY	2025	180	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16092	1848	CALAMITY	2025	5	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16093	1848	MOL	2025	0	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16094	1848	TL	2025	0	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16095	1848	AL	2025	0	0	2025-10-17 12:46:49.89894	2025-10-17 12:46:49.89894
16096	1849	VL	2025	15	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16097	1849	SL	2025	15	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16098	1849	ML	2025	5	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16099	1849	SPL	2025	3	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16100	1849	MAT	2025	105	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16101	1849	PAT	2025	7	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16102	1849	SOLO	2025	7	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16103	1849	VAWC	2025	10	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16104	1849	RL	2025	0	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16105	1849	MCW	2025	60	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16106	1849	STUDY	2025	180	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16107	1849	CALAMITY	2025	5	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16108	1849	MOL	2025	0	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16109	1849	TL	2025	0	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16110	1849	AL	2025	0	0	2025-10-17 12:46:49.987703	2025-10-17 12:46:49.987703
16111	1850	VL	2025	15	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16112	1850	SL	2025	15	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16113	1850	ML	2025	5	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16114	1850	SPL	2025	3	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16115	1850	MAT	2025	105	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16116	1850	PAT	2025	7	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16117	1850	SOLO	2025	7	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16118	1850	VAWC	2025	10	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16119	1850	RL	2025	0	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16120	1850	MCW	2025	60	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16121	1850	STUDY	2025	180	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16122	1850	CALAMITY	2025	5	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16123	1850	MOL	2025	0	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16124	1850	TL	2025	0	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16125	1850	AL	2025	0	0	2025-10-17 12:46:50.069697	2025-10-17 12:46:50.069697
16126	1851	VL	2025	15	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16127	1851	SL	2025	15	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16128	1851	ML	2025	5	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16129	1851	SPL	2025	3	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16130	1851	MAT	2025	105	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16131	1851	PAT	2025	7	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16132	1851	SOLO	2025	7	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16133	1851	VAWC	2025	10	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16134	1851	RL	2025	0	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16135	1851	MCW	2025	60	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16136	1851	STUDY	2025	180	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16137	1851	CALAMITY	2025	5	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16138	1851	MOL	2025	0	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16139	1851	TL	2025	0	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16140	1851	AL	2025	0	0	2025-10-17 12:46:50.181888	2025-10-17 12:46:50.181888
16141	1852	VL	2025	15	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16142	1852	SL	2025	15	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16143	1852	ML	2025	5	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16144	1852	SPL	2025	3	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16145	1852	MAT	2025	105	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16146	1852	PAT	2025	7	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16147	1852	SOLO	2025	7	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16148	1852	VAWC	2025	10	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16149	1852	RL	2025	0	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16150	1852	MCW	2025	60	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16151	1852	STUDY	2025	180	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16152	1852	CALAMITY	2025	5	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16153	1852	MOL	2025	0	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16154	1852	TL	2025	0	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16155	1852	AL	2025	0	0	2025-10-17 12:46:50.255999	2025-10-17 12:46:50.255999
16156	1853	VL	2025	15	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16157	1853	SL	2025	15	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16158	1853	ML	2025	5	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16159	1853	SPL	2025	3	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16160	1853	MAT	2025	105	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16161	1853	PAT	2025	7	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16162	1853	SOLO	2025	7	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16163	1853	VAWC	2025	10	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16164	1853	RL	2025	0	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16165	1853	MCW	2025	60	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16166	1853	STUDY	2025	180	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16167	1853	CALAMITY	2025	5	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16168	1853	MOL	2025	0	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16169	1853	TL	2025	0	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16170	1853	AL	2025	0	0	2025-10-17 12:46:50.330835	2025-10-17 12:46:50.330835
16171	1854	VL	2025	15	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16172	1854	SL	2025	15	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16173	1854	ML	2025	5	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16174	1854	SPL	2025	3	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16175	1854	MAT	2025	105	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16176	1854	PAT	2025	7	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16177	1854	SOLO	2025	7	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16178	1854	VAWC	2025	10	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16179	1854	RL	2025	0	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16180	1854	MCW	2025	60	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16181	1854	STUDY	2025	180	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16182	1854	CALAMITY	2025	5	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16183	1854	MOL	2025	0	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16184	1854	TL	2025	0	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16185	1854	AL	2025	0	0	2025-10-17 12:46:50.445107	2025-10-17 12:46:50.445107
16186	1855	VL	2025	15	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16187	1855	SL	2025	15	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16188	1855	ML	2025	5	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16189	1855	SPL	2025	3	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16190	1855	MAT	2025	105	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16191	1855	PAT	2025	7	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16192	1855	SOLO	2025	7	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16193	1855	VAWC	2025	10	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16194	1855	RL	2025	0	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16195	1855	MCW	2025	60	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16196	1855	STUDY	2025	180	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16197	1855	CALAMITY	2025	5	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16198	1855	MOL	2025	0	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16199	1855	TL	2025	0	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16200	1855	AL	2025	0	0	2025-10-17 12:46:50.578293	2025-10-17 12:46:50.578293
16201	1856	VL	2025	15	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16202	1856	SL	2025	15	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16203	1856	ML	2025	5	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16204	1856	SPL	2025	3	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16205	1856	MAT	2025	105	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16206	1856	PAT	2025	7	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16207	1856	SOLO	2025	7	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16208	1856	VAWC	2025	10	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16209	1856	RL	2025	0	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16210	1856	MCW	2025	60	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16211	1856	STUDY	2025	180	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16212	1856	CALAMITY	2025	5	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16213	1856	MOL	2025	0	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16214	1856	TL	2025	0	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16215	1856	AL	2025	0	0	2025-10-17 12:46:50.650177	2025-10-17 12:46:50.650177
16216	1857	VL	2025	15	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16217	1857	SL	2025	15	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16218	1857	ML	2025	5	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16219	1857	SPL	2025	3	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16220	1857	MAT	2025	105	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16221	1857	PAT	2025	7	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16222	1857	SOLO	2025	7	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16223	1857	VAWC	2025	10	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16224	1857	RL	2025	0	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16225	1857	MCW	2025	60	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16226	1857	STUDY	2025	180	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16227	1857	CALAMITY	2025	5	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16228	1857	MOL	2025	0	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16229	1857	TL	2025	0	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16230	1857	AL	2025	0	0	2025-10-17 12:46:50.723771	2025-10-17 12:46:50.723771
16231	1858	VL	2025	15	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16232	1858	SL	2025	15	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16233	1858	ML	2025	5	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16234	1858	SPL	2025	3	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16235	1858	MAT	2025	105	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16236	1858	PAT	2025	7	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16237	1858	SOLO	2025	7	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16238	1858	VAWC	2025	10	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16239	1858	RL	2025	0	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16240	1858	MCW	2025	60	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16241	1858	STUDY	2025	180	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16242	1858	CALAMITY	2025	5	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16243	1858	MOL	2025	0	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16244	1858	TL	2025	0	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16245	1858	AL	2025	0	0	2025-10-17 12:46:50.80686	2025-10-17 12:46:50.80686
16246	1859	VL	2025	15	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16247	1859	SL	2025	15	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16248	1859	ML	2025	5	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16249	1859	SPL	2025	3	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16250	1859	MAT	2025	105	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16251	1859	PAT	2025	7	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16252	1859	SOLO	2025	7	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16253	1859	VAWC	2025	10	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16254	1859	RL	2025	0	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16255	1859	MCW	2025	60	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16256	1859	STUDY	2025	180	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16257	1859	CALAMITY	2025	5	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16258	1859	MOL	2025	0	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16259	1859	TL	2025	0	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16260	1859	AL	2025	0	0	2025-10-17 12:46:50.958774	2025-10-17 12:46:50.958774
16261	1860	VL	2025	15	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16262	1860	SL	2025	15	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16263	1860	ML	2025	5	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16264	1860	SPL	2025	3	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16265	1860	MAT	2025	105	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16266	1860	PAT	2025	7	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16267	1860	SOLO	2025	7	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16268	1860	VAWC	2025	10	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16269	1860	RL	2025	0	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16270	1860	MCW	2025	60	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16271	1860	STUDY	2025	180	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16272	1860	CALAMITY	2025	5	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16273	1860	MOL	2025	0	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16274	1860	TL	2025	0	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16275	1860	AL	2025	0	0	2025-10-17 12:46:51.040167	2025-10-17 12:46:51.040167
16276	1861	VL	2025	15	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16277	1861	SL	2025	15	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16278	1861	ML	2025	5	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16279	1861	SPL	2025	3	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16280	1861	MAT	2025	105	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16281	1861	PAT	2025	7	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16282	1861	SOLO	2025	7	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16283	1861	VAWC	2025	10	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16284	1861	RL	2025	0	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16285	1861	MCW	2025	60	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16286	1861	STUDY	2025	180	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16287	1861	CALAMITY	2025	5	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16288	1861	MOL	2025	0	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16289	1861	TL	2025	0	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16290	1861	AL	2025	0	0	2025-10-17 12:46:51.120067	2025-10-17 12:46:51.120067
16291	1862	VL	2025	15	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16292	1862	SL	2025	15	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16293	1862	ML	2025	5	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16294	1862	SPL	2025	3	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16295	1862	MAT	2025	105	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16296	1862	PAT	2025	7	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16297	1862	SOLO	2025	7	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16298	1862	VAWC	2025	10	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16299	1862	RL	2025	0	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16300	1862	MCW	2025	60	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16301	1862	STUDY	2025	180	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16302	1862	CALAMITY	2025	5	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16303	1862	MOL	2025	0	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16304	1862	TL	2025	0	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16305	1862	AL	2025	0	0	2025-10-17 12:46:51.197983	2025-10-17 12:46:51.197983
16306	1863	VL	2025	15	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16307	1863	SL	2025	15	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16308	1863	ML	2025	5	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16309	1863	SPL	2025	3	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16310	1863	MAT	2025	105	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16311	1863	PAT	2025	7	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16312	1863	SOLO	2025	7	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16313	1863	VAWC	2025	10	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16314	1863	RL	2025	0	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16315	1863	MCW	2025	60	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16316	1863	STUDY	2025	180	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16317	1863	CALAMITY	2025	5	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16318	1863	MOL	2025	0	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16319	1863	TL	2025	0	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16320	1863	AL	2025	0	0	2025-10-17 12:46:51.332644	2025-10-17 12:46:51.332644
16321	1864	VL	2025	15	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16322	1864	SL	2025	15	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16323	1864	ML	2025	5	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16324	1864	SPL	2025	3	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16325	1864	MAT	2025	105	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16326	1864	PAT	2025	7	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16327	1864	SOLO	2025	7	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16328	1864	VAWC	2025	10	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16329	1864	RL	2025	0	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16330	1864	MCW	2025	60	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16331	1864	STUDY	2025	180	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16332	1864	CALAMITY	2025	5	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16333	1864	MOL	2025	0	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16334	1864	TL	2025	0	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16335	1864	AL	2025	0	0	2025-10-17 12:46:51.411568	2025-10-17 12:46:51.411568
16336	1865	VL	2025	15	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16337	1865	SL	2025	15	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16338	1865	ML	2025	5	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16339	1865	SPL	2025	3	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16340	1865	MAT	2025	105	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16341	1865	PAT	2025	7	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16342	1865	SOLO	2025	7	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16343	1865	VAWC	2025	10	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16344	1865	RL	2025	0	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16345	1865	MCW	2025	60	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16346	1865	STUDY	2025	180	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16347	1865	CALAMITY	2025	5	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16348	1865	MOL	2025	0	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16349	1865	TL	2025	0	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16350	1865	AL	2025	0	0	2025-10-17 12:46:51.489778	2025-10-17 12:46:51.489778
16351	1866	VL	2025	15	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16352	1866	SL	2025	15	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16353	1866	ML	2025	5	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16354	1866	SPL	2025	3	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16355	1866	MAT	2025	105	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16356	1866	PAT	2025	7	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16357	1866	SOLO	2025	7	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16358	1866	VAWC	2025	10	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16359	1866	RL	2025	0	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16360	1866	MCW	2025	60	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16361	1866	STUDY	2025	180	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16362	1866	CALAMITY	2025	5	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16363	1866	MOL	2025	0	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16364	1866	TL	2025	0	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16365	1866	AL	2025	0	0	2025-10-17 12:46:51.573863	2025-10-17 12:46:51.573863
16377	1867	CALAMITY	2025	5	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16378	1867	MOL	2025	0	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16379	1867	TL	2025	0	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16380	1867	AL	2025	0	0	2025-10-17 12:46:51.724701	2025-10-17 12:46:51.724701
16381	1868	VL	2025	15	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16382	1868	SL	2025	15	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16383	1868	ML	2025	5	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16384	1868	SPL	2025	3	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16385	1868	MAT	2025	105	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16386	1868	PAT	2025	7	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16387	1868	SOLO	2025	7	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16388	1868	VAWC	2025	10	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16389	1868	RL	2025	0	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16390	1868	MCW	2025	60	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16391	1868	STUDY	2025	180	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16392	1868	CALAMITY	2025	5	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16393	1868	MOL	2025	0	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16394	1868	TL	2025	0	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16395	1868	AL	2025	0	0	2025-10-17 12:46:51.804983	2025-10-17 12:46:51.804983
16396	1869	VL	2025	15	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16397	1869	SL	2025	15	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16398	1869	ML	2025	5	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16399	1869	SPL	2025	3	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16400	1869	MAT	2025	105	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16401	1869	PAT	2025	7	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16402	1869	SOLO	2025	7	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16403	1869	VAWC	2025	10	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16404	1869	RL	2025	0	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16405	1869	MCW	2025	60	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16406	1869	STUDY	2025	180	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16407	1869	CALAMITY	2025	5	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16408	1869	MOL	2025	0	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16409	1869	TL	2025	0	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16410	1869	AL	2025	0	0	2025-10-17 12:46:51.89339	2025-10-17 12:46:51.89339
16411	1870	VL	2025	15	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16412	1870	SL	2025	15	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16413	1870	ML	2025	5	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16414	1870	SPL	2025	3	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16415	1870	MAT	2025	105	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16416	1870	PAT	2025	7	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16417	1870	SOLO	2025	7	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16418	1870	VAWC	2025	10	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16419	1870	RL	2025	0	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16420	1870	MCW	2025	60	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16421	1870	STUDY	2025	180	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16422	1870	CALAMITY	2025	5	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16423	1870	MOL	2025	0	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16424	1870	TL	2025	0	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16425	1870	AL	2025	0	0	2025-10-17 12:46:51.969685	2025-10-17 12:46:51.969685
16426	1871	VL	2025	15	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16427	1871	SL	2025	15	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16428	1871	ML	2025	5	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16429	1871	SPL	2025	3	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16430	1871	MAT	2025	105	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16431	1871	PAT	2025	7	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16432	1871	SOLO	2025	7	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16433	1871	VAWC	2025	10	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16434	1871	RL	2025	0	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16435	1871	MCW	2025	60	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16436	1871	STUDY	2025	180	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16437	1871	CALAMITY	2025	5	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16438	1871	MOL	2025	0	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16439	1871	TL	2025	0	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16440	1871	AL	2025	0	0	2025-10-17 12:46:52.098	2025-10-17 12:46:52.098
16441	1872	VL	2025	15	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16442	1872	SL	2025	15	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16443	1872	ML	2025	5	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16444	1872	SPL	2025	3	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16445	1872	MAT	2025	105	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16446	1872	PAT	2025	7	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16447	1872	SOLO	2025	7	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16448	1872	VAWC	2025	10	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16449	1872	RL	2025	0	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16450	1872	MCW	2025	60	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16451	1872	STUDY	2025	180	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16452	1872	CALAMITY	2025	5	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16453	1872	MOL	2025	0	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16454	1872	TL	2025	0	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16455	1872	AL	2025	0	0	2025-10-17 12:46:52.175993	2025-10-17 12:46:52.175993
16456	1873	VL	2025	15	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16457	1873	SL	2025	15	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16458	1873	ML	2025	5	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16459	1873	SPL	2025	3	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16460	1873	MAT	2025	105	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16461	1873	PAT	2025	7	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16462	1873	SOLO	2025	7	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16463	1873	VAWC	2025	10	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16464	1873	RL	2025	0	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16465	1873	MCW	2025	60	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16466	1873	STUDY	2025	180	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16467	1873	CALAMITY	2025	5	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16468	1873	MOL	2025	0	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16469	1873	TL	2025	0	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16470	1873	AL	2025	0	0	2025-10-17 12:46:52.247889	2025-10-17 12:46:52.247889
16471	1874	VL	2025	15	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16472	1874	SL	2025	15	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16473	1874	ML	2025	5	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16474	1874	SPL	2025	3	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16475	1874	MAT	2025	105	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16476	1874	PAT	2025	7	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16477	1874	SOLO	2025	7	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16478	1874	VAWC	2025	10	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16479	1874	RL	2025	0	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16480	1874	MCW	2025	60	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16481	1874	STUDY	2025	180	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16482	1874	CALAMITY	2025	5	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16483	1874	MOL	2025	0	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16484	1874	TL	2025	0	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16485	1874	AL	2025	0	0	2025-10-17 12:46:52.317702	2025-10-17 12:46:52.317702
16486	1875	VL	2025	15	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16487	1875	SL	2025	15	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16488	1875	ML	2025	5	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16489	1875	SPL	2025	3	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16490	1875	MAT	2025	105	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16491	1875	PAT	2025	7	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16492	1875	SOLO	2025	7	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16493	1875	VAWC	2025	10	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16494	1875	RL	2025	0	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16495	1875	MCW	2025	60	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16496	1875	STUDY	2025	180	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16497	1875	CALAMITY	2025	5	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16498	1875	MOL	2025	0	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16499	1875	TL	2025	0	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16500	1875	AL	2025	0	0	2025-10-17 12:46:52.487853	2025-10-17 12:46:52.487853
16501	1876	VL	2025	15	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16502	1876	SL	2025	15	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16503	1876	ML	2025	5	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16504	1876	SPL	2025	3	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16505	1876	MAT	2025	105	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16506	1876	PAT	2025	7	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16507	1876	SOLO	2025	7	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16508	1876	VAWC	2025	10	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16509	1876	RL	2025	0	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16510	1876	MCW	2025	60	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16511	1876	STUDY	2025	180	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16512	1876	CALAMITY	2025	5	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16513	1876	MOL	2025	0	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16514	1876	TL	2025	0	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16515	1876	AL	2025	0	0	2025-10-17 12:46:52.562043	2025-10-17 12:46:52.562043
16516	1877	VL	2025	15	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16517	1877	SL	2025	15	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16518	1877	ML	2025	5	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16519	1877	SPL	2025	3	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16520	1877	MAT	2025	105	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16521	1877	PAT	2025	7	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16522	1877	SOLO	2025	7	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16523	1877	VAWC	2025	10	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16524	1877	RL	2025	0	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16525	1877	MCW	2025	60	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16526	1877	STUDY	2025	180	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16527	1877	CALAMITY	2025	5	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16528	1877	MOL	2025	0	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16529	1877	TL	2025	0	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16530	1877	AL	2025	0	0	2025-10-17 12:46:52.663484	2025-10-17 12:46:52.663484
16531	1878	VL	2025	15	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16532	1878	SL	2025	15	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16533	1878	ML	2025	5	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16534	1878	SPL	2025	3	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16535	1878	MAT	2025	105	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16536	1878	PAT	2025	7	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16537	1878	SOLO	2025	7	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16538	1878	VAWC	2025	10	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16539	1878	RL	2025	0	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16540	1878	MCW	2025	60	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16541	1878	STUDY	2025	180	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16542	1878	CALAMITY	2025	5	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16543	1878	MOL	2025	0	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16544	1878	TL	2025	0	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16545	1878	AL	2025	0	0	2025-10-17 12:46:52.857894	2025-10-17 12:46:52.857894
16546	1879	VL	2025	15	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16547	1879	SL	2025	15	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16548	1879	ML	2025	5	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16549	1879	SPL	2025	3	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16550	1879	MAT	2025	105	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16551	1879	PAT	2025	7	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16552	1879	SOLO	2025	7	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16553	1879	VAWC	2025	10	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16554	1879	RL	2025	0	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16555	1879	MCW	2025	60	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16556	1879	STUDY	2025	180	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16557	1879	CALAMITY	2025	5	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16558	1879	MOL	2025	0	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16559	1879	TL	2025	0	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16560	1879	AL	2025	0	0	2025-10-17 12:46:52.976014	2025-10-17 12:46:52.976014
16561	1880	VL	2025	15	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16562	1880	SL	2025	15	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16563	1880	ML	2025	5	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16564	1880	SPL	2025	3	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16565	1880	MAT	2025	105	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16566	1880	PAT	2025	7	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16567	1880	SOLO	2025	7	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16568	1880	VAWC	2025	10	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16569	1880	RL	2025	0	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16570	1880	MCW	2025	60	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16571	1880	STUDY	2025	180	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16572	1880	CALAMITY	2025	5	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16573	1880	MOL	2025	0	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16574	1880	TL	2025	0	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16575	1880	AL	2025	0	0	2025-10-17 12:46:53.064195	2025-10-17 12:46:53.064195
16576	1881	VL	2025	15	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16577	1881	SL	2025	15	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16578	1881	ML	2025	5	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16579	1881	SPL	2025	3	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16580	1881	MAT	2025	105	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16581	1881	PAT	2025	7	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16582	1881	SOLO	2025	7	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16583	1881	VAWC	2025	10	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16584	1881	RL	2025	0	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16585	1881	MCW	2025	60	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16586	1881	STUDY	2025	180	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16587	1881	CALAMITY	2025	5	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16588	1881	MOL	2025	0	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16589	1881	TL	2025	0	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16590	1881	AL	2025	0	0	2025-10-17 12:46:53.22883	2025-10-17 12:46:53.22883
16591	1882	VL	2025	15	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16592	1882	SL	2025	15	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16593	1882	ML	2025	5	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16594	1882	SPL	2025	3	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16595	1882	MAT	2025	105	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16596	1882	PAT	2025	7	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16597	1882	SOLO	2025	7	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16598	1882	VAWC	2025	10	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16599	1882	RL	2025	0	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16600	1882	MCW	2025	60	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16601	1882	STUDY	2025	180	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16602	1882	CALAMITY	2025	5	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16603	1882	MOL	2025	0	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16604	1882	TL	2025	0	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16605	1882	AL	2025	0	0	2025-10-17 12:46:53.301918	2025-10-17 12:46:53.301918
16606	1883	VL	2025	15	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16607	1883	SL	2025	15	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16608	1883	ML	2025	5	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16609	1883	SPL	2025	3	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16610	1883	MAT	2025	105	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16611	1883	PAT	2025	7	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16612	1883	SOLO	2025	7	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16613	1883	VAWC	2025	10	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16614	1883	RL	2025	0	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16615	1883	MCW	2025	60	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16616	1883	STUDY	2025	180	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16617	1883	CALAMITY	2025	5	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16618	1883	MOL	2025	0	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16619	1883	TL	2025	0	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16620	1883	AL	2025	0	0	2025-10-17 12:46:53.384557	2025-10-17 12:46:53.384557
16621	1884	VL	2025	15	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16622	1884	SL	2025	15	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16623	1884	ML	2025	5	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16624	1884	SPL	2025	3	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16625	1884	MAT	2025	105	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16626	1884	PAT	2025	7	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16627	1884	SOLO	2025	7	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16628	1884	VAWC	2025	10	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16629	1884	RL	2025	0	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16630	1884	MCW	2025	60	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16631	1884	STUDY	2025	180	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16632	1884	CALAMITY	2025	5	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16633	1884	MOL	2025	0	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16634	1884	TL	2025	0	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16635	1884	AL	2025	0	0	2025-10-17 12:46:53.464675	2025-10-17 12:46:53.464675
16636	1885	VL	2025	15	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16637	1885	SL	2025	15	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16638	1885	ML	2025	5	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16639	1885	SPL	2025	3	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16640	1885	MAT	2025	105	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16641	1885	PAT	2025	7	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16642	1885	SOLO	2025	7	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16643	1885	VAWC	2025	10	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16644	1885	RL	2025	0	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16645	1885	MCW	2025	60	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16646	1885	STUDY	2025	180	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16647	1885	CALAMITY	2025	5	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16648	1885	MOL	2025	0	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16649	1885	TL	2025	0	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16650	1885	AL	2025	0	0	2025-10-17 12:46:53.60776	2025-10-17 12:46:53.60776
16651	1886	VL	2025	15	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16652	1886	SL	2025	15	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16653	1886	ML	2025	5	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16654	1886	SPL	2025	3	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16655	1886	MAT	2025	105	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16656	1886	PAT	2025	7	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16657	1886	SOLO	2025	7	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16658	1886	VAWC	2025	10	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16659	1886	RL	2025	0	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16660	1886	MCW	2025	60	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16661	1886	STUDY	2025	180	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16662	1886	CALAMITY	2025	5	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16663	1886	MOL	2025	0	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16664	1886	TL	2025	0	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16665	1886	AL	2025	0	0	2025-10-17 12:46:53.684516	2025-10-17 12:46:53.684516
16666	1887	VL	2025	15	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16667	1887	SL	2025	15	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16668	1887	ML	2025	5	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16669	1887	SPL	2025	3	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16670	1887	MAT	2025	105	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16671	1887	PAT	2025	7	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16672	1887	SOLO	2025	7	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16673	1887	VAWC	2025	10	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16674	1887	RL	2025	0	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16675	1887	MCW	2025	60	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16676	1887	STUDY	2025	180	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16677	1887	CALAMITY	2025	5	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16678	1887	MOL	2025	0	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16679	1887	TL	2025	0	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16680	1887	AL	2025	0	0	2025-10-17 12:46:53.789153	2025-10-17 12:46:53.789153
16681	1888	VL	2025	15	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16682	1888	SL	2025	15	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16683	1888	ML	2025	5	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16684	1888	SPL	2025	3	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16685	1888	MAT	2025	105	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16686	1888	PAT	2025	7	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16687	1888	SOLO	2025	7	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16688	1888	VAWC	2025	10	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16689	1888	RL	2025	0	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16690	1888	MCW	2025	60	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16691	1888	STUDY	2025	180	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16692	1888	CALAMITY	2025	5	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16693	1888	MOL	2025	0	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16694	1888	TL	2025	0	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16695	1888	AL	2025	0	0	2025-10-17 12:46:53.864174	2025-10-17 12:46:53.864174
16696	1889	VL	2025	15	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16697	1889	SL	2025	15	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16698	1889	ML	2025	5	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16699	1889	SPL	2025	3	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16700	1889	MAT	2025	105	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16701	1889	PAT	2025	7	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16702	1889	SOLO	2025	7	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16703	1889	VAWC	2025	10	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16704	1889	RL	2025	0	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16705	1889	MCW	2025	60	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16706	1889	STUDY	2025	180	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16707	1889	CALAMITY	2025	5	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16708	1889	MOL	2025	0	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16709	1889	TL	2025	0	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16710	1889	AL	2025	0	0	2025-10-17 12:46:53.996119	2025-10-17 12:46:53.996119
16711	1890	VL	2025	15	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16712	1890	SL	2025	15	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16713	1890	ML	2025	5	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16714	1890	SPL	2025	3	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16715	1890	MAT	2025	105	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16716	1890	PAT	2025	7	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16717	1890	SOLO	2025	7	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16718	1890	VAWC	2025	10	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16719	1890	RL	2025	0	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16720	1890	MCW	2025	60	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16721	1890	STUDY	2025	180	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16722	1890	CALAMITY	2025	5	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16723	1890	MOL	2025	0	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16724	1890	TL	2025	0	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16725	1890	AL	2025	0	0	2025-10-17 12:46:54.073759	2025-10-17 12:46:54.073759
16726	1891	VL	2025	15	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16727	1891	SL	2025	15	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16728	1891	ML	2025	5	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16729	1891	SPL	2025	3	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16730	1891	MAT	2025	105	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16731	1891	PAT	2025	7	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16732	1891	SOLO	2025	7	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16733	1891	VAWC	2025	10	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16734	1891	RL	2025	0	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16735	1891	MCW	2025	60	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16736	1891	STUDY	2025	180	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16737	1891	CALAMITY	2025	5	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16738	1891	MOL	2025	0	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16739	1891	TL	2025	0	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16740	1891	AL	2025	0	0	2025-10-17 12:46:54.147963	2025-10-17 12:46:54.147963
16741	1892	VL	2025	15	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16742	1892	SL	2025	15	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16743	1892	ML	2025	5	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16744	1892	SPL	2025	3	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16745	1892	MAT	2025	105	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16746	1892	PAT	2025	7	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16747	1892	SOLO	2025	7	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16748	1892	VAWC	2025	10	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16749	1892	RL	2025	0	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16750	1892	MCW	2025	60	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16751	1892	STUDY	2025	180	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16752	1892	CALAMITY	2025	5	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16753	1892	MOL	2025	0	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16754	1892	TL	2025	0	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16755	1892	AL	2025	0	0	2025-10-17 12:46:54.223837	2025-10-17 12:46:54.223837
16756	1893	VL	2025	15	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16757	1893	SL	2025	15	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16758	1893	ML	2025	5	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16759	1893	SPL	2025	3	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16760	1893	MAT	2025	105	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16761	1893	PAT	2025	7	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16762	1893	SOLO	2025	7	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16763	1893	VAWC	2025	10	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16764	1893	RL	2025	0	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16765	1893	MCW	2025	60	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16766	1893	STUDY	2025	180	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16767	1893	CALAMITY	2025	5	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16768	1893	MOL	2025	0	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16769	1893	TL	2025	0	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16770	1893	AL	2025	0	0	2025-10-17 12:46:54.374304	2025-10-17 12:46:54.374304
16771	1894	VL	2025	15	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16772	1894	SL	2025	15	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16773	1894	ML	2025	5	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16774	1894	SPL	2025	3	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16775	1894	MAT	2025	105	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16776	1894	PAT	2025	7	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16777	1894	SOLO	2025	7	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16778	1894	VAWC	2025	10	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16779	1894	RL	2025	0	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16780	1894	MCW	2025	60	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16781	1894	STUDY	2025	180	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16782	1894	CALAMITY	2025	5	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16783	1894	MOL	2025	0	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16784	1894	TL	2025	0	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16785	1894	AL	2025	0	0	2025-10-17 12:46:54.453049	2025-10-17 12:46:54.453049
16786	1895	VL	2025	15	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16787	1895	SL	2025	15	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16788	1895	ML	2025	5	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16789	1895	SPL	2025	3	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16790	1895	MAT	2025	105	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16791	1895	PAT	2025	7	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16792	1895	SOLO	2025	7	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16793	1895	VAWC	2025	10	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16794	1895	RL	2025	0	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16795	1895	MCW	2025	60	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16796	1895	STUDY	2025	180	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16797	1895	CALAMITY	2025	5	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16798	1895	MOL	2025	0	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16799	1895	TL	2025	0	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16800	1895	AL	2025	0	0	2025-10-17 12:46:54.533041	2025-10-17 12:46:54.533041
16801	1896	VL	2025	15	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16802	1896	SL	2025	15	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16803	1896	ML	2025	5	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16804	1896	SPL	2025	3	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16805	1896	MAT	2025	105	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16806	1896	PAT	2025	7	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16807	1896	SOLO	2025	7	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16808	1896	VAWC	2025	10	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16809	1896	RL	2025	0	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16810	1896	MCW	2025	60	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16811	1896	STUDY	2025	180	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16812	1896	CALAMITY	2025	5	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16813	1896	MOL	2025	0	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16814	1896	TL	2025	0	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16815	1896	AL	2025	0	0	2025-10-17 12:46:54.612679	2025-10-17 12:46:54.612679
16816	1897	VL	2025	15	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16817	1897	SL	2025	15	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16818	1897	ML	2025	5	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16819	1897	SPL	2025	3	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16820	1897	MAT	2025	105	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16821	1897	PAT	2025	7	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16822	1897	SOLO	2025	7	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16823	1897	VAWC	2025	10	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16824	1897	RL	2025	0	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16825	1897	MCW	2025	60	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16826	1897	STUDY	2025	180	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16827	1897	CALAMITY	2025	5	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16828	1897	MOL	2025	0	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16829	1897	TL	2025	0	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16830	1897	AL	2025	0	0	2025-10-17 12:46:54.765104	2025-10-17 12:46:54.765104
16831	1898	VL	2025	15	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16832	1898	SL	2025	15	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16833	1898	ML	2025	5	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16834	1898	SPL	2025	3	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16835	1898	MAT	2025	105	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16836	1898	PAT	2025	7	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16837	1898	SOLO	2025	7	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16838	1898	VAWC	2025	10	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16839	1898	RL	2025	0	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16840	1898	MCW	2025	60	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16841	1898	STUDY	2025	180	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16842	1898	CALAMITY	2025	5	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16843	1898	MOL	2025	0	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16844	1898	TL	2025	0	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16845	1898	AL	2025	0	0	2025-10-17 12:46:54.8681	2025-10-17 12:46:54.8681
16846	1899	VL	2025	15	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16847	1899	SL	2025	15	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16848	1899	ML	2025	5	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16849	1899	SPL	2025	3	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16850	1899	MAT	2025	105	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16851	1899	PAT	2025	7	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16852	1899	SOLO	2025	7	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16853	1899	VAWC	2025	10	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16854	1899	RL	2025	0	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16855	1899	MCW	2025	60	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16856	1899	STUDY	2025	180	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16857	1899	CALAMITY	2025	5	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16858	1899	MOL	2025	0	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16859	1899	TL	2025	0	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16860	1899	AL	2025	0	0	2025-10-17 12:46:54.949722	2025-10-17 12:46:54.949722
16861	1900	VL	2025	15	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16862	1900	SL	2025	15	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16863	1900	ML	2025	5	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16864	1900	SPL	2025	3	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16865	1900	MAT	2025	105	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16866	1900	PAT	2025	7	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16867	1900	SOLO	2025	7	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16868	1900	VAWC	2025	10	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16869	1900	RL	2025	0	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16870	1900	MCW	2025	60	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16871	1900	STUDY	2025	180	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16872	1900	CALAMITY	2025	5	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16873	1900	MOL	2025	0	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16874	1900	TL	2025	0	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16875	1900	AL	2025	0	0	2025-10-17 12:46:55.137765	2025-10-17 12:46:55.137765
16876	1901	VL	2025	15	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16877	1901	SL	2025	15	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16878	1901	ML	2025	5	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16879	1901	SPL	2025	3	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16880	1901	MAT	2025	105	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16881	1901	PAT	2025	7	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16882	1901	SOLO	2025	7	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16883	1901	VAWC	2025	10	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16884	1901	RL	2025	0	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16885	1901	MCW	2025	60	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16886	1901	STUDY	2025	180	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16887	1901	CALAMITY	2025	5	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16888	1901	MOL	2025	0	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16889	1901	TL	2025	0	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16890	1901	AL	2025	0	0	2025-10-17 12:46:55.230926	2025-10-17 12:46:55.230926
16891	1902	VL	2025	15	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16892	1902	SL	2025	15	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16893	1902	ML	2025	5	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16894	1902	SPL	2025	3	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16895	1902	MAT	2025	105	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16896	1902	PAT	2025	7	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16897	1902	SOLO	2025	7	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16898	1902	VAWC	2025	10	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16899	1902	RL	2025	0	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16900	1902	MCW	2025	60	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16901	1902	STUDY	2025	180	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16902	1902	CALAMITY	2025	5	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16903	1902	MOL	2025	0	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16904	1902	TL	2025	0	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16905	1902	AL	2025	0	0	2025-10-17 12:46:55.325097	2025-10-17 12:46:55.325097
16906	1903	VL	2025	15	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16907	1903	SL	2025	15	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16908	1903	ML	2025	5	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16909	1903	SPL	2025	3	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16910	1903	MAT	2025	105	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16911	1903	PAT	2025	7	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16912	1903	SOLO	2025	7	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16913	1903	VAWC	2025	10	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16914	1903	RL	2025	0	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16915	1903	MCW	2025	60	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16916	1903	STUDY	2025	180	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16917	1903	CALAMITY	2025	5	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16918	1903	MOL	2025	0	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16919	1903	TL	2025	0	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16920	1903	AL	2025	0	0	2025-10-17 12:46:55.508084	2025-10-17 12:46:55.508084
16921	1904	VL	2025	15	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16922	1904	SL	2025	15	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16923	1904	ML	2025	5	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16924	1904	SPL	2025	3	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16925	1904	MAT	2025	105	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16926	1904	PAT	2025	7	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16927	1904	SOLO	2025	7	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16928	1904	VAWC	2025	10	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16929	1904	RL	2025	0	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16930	1904	MCW	2025	60	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16931	1904	STUDY	2025	180	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16932	1904	CALAMITY	2025	5	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16933	1904	MOL	2025	0	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16934	1904	TL	2025	0	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16935	1904	AL	2025	0	0	2025-10-17 12:46:55.60094	2025-10-17 12:46:55.60094
16936	1905	VL	2025	15	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16937	1905	SL	2025	15	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16938	1905	ML	2025	5	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16939	1905	SPL	2025	3	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16940	1905	MAT	2025	105	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16941	1905	PAT	2025	7	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16942	1905	SOLO	2025	7	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16943	1905	VAWC	2025	10	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16944	1905	RL	2025	0	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16945	1905	MCW	2025	60	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16946	1905	STUDY	2025	180	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16947	1905	CALAMITY	2025	5	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16948	1905	MOL	2025	0	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16949	1905	TL	2025	0	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16950	1905	AL	2025	0	0	2025-10-17 12:46:55.69001	2025-10-17 12:46:55.69001
16951	1906	VL	2025	15	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16952	1906	SL	2025	15	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16953	1906	ML	2025	5	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16954	1906	SPL	2025	3	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16955	1906	MAT	2025	105	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16956	1906	PAT	2025	7	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16957	1906	SOLO	2025	7	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16958	1906	VAWC	2025	10	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16959	1906	RL	2025	0	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16960	1906	MCW	2025	60	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16961	1906	STUDY	2025	180	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16962	1906	CALAMITY	2025	5	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16963	1906	MOL	2025	0	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16964	1906	TL	2025	0	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16965	1906	AL	2025	0	0	2025-10-17 12:46:55.763695	2025-10-17 12:46:55.763695
16966	1907	VL	2025	15	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16967	1907	SL	2025	15	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16968	1907	ML	2025	5	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16969	1907	SPL	2025	3	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16970	1907	MAT	2025	105	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16971	1907	PAT	2025	7	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16972	1907	SOLO	2025	7	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16973	1907	VAWC	2025	10	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16974	1907	RL	2025	0	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16975	1907	MCW	2025	60	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16976	1907	STUDY	2025	180	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16977	1907	CALAMITY	2025	5	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16978	1907	MOL	2025	0	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16979	1907	TL	2025	0	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16980	1907	AL	2025	0	0	2025-10-17 12:46:55.894569	2025-10-17 12:46:55.894569
16981	1908	VL	2025	15	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16982	1908	SL	2025	15	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16983	1908	ML	2025	5	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16984	1908	SPL	2025	3	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16985	1908	MAT	2025	105	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16986	1908	PAT	2025	7	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16987	1908	SOLO	2025	7	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16988	1908	VAWC	2025	10	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16989	1908	RL	2025	0	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16990	1908	MCW	2025	60	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16991	1908	STUDY	2025	180	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16992	1908	CALAMITY	2025	5	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16993	1908	MOL	2025	0	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16994	1908	TL	2025	0	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16995	1908	AL	2025	0	0	2025-10-17 12:46:55.971796	2025-10-17 12:46:55.971796
16996	1909	VL	2025	15	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
16997	1909	SL	2025	15	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
16998	1909	ML	2025	5	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
16999	1909	SPL	2025	3	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17000	1909	MAT	2025	105	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17001	1909	PAT	2025	7	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17002	1909	SOLO	2025	7	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17003	1909	VAWC	2025	10	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17004	1909	RL	2025	0	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17005	1909	MCW	2025	60	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17006	1909	STUDY	2025	180	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17007	1909	CALAMITY	2025	5	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17008	1909	MOL	2025	0	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17009	1909	TL	2025	0	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17010	1909	AL	2025	0	0	2025-10-17 12:46:56.068138	2025-10-17 12:46:56.068138
17011	1910	VL	2025	15	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17012	1910	SL	2025	15	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17013	1910	ML	2025	5	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17014	1910	SPL	2025	3	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17015	1910	MAT	2025	105	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17016	1910	PAT	2025	7	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17017	1910	SOLO	2025	7	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17018	1910	VAWC	2025	10	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17019	1910	RL	2025	0	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17020	1910	MCW	2025	60	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17021	1910	STUDY	2025	180	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17022	1910	CALAMITY	2025	5	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17023	1910	MOL	2025	0	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17024	1910	TL	2025	0	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17025	1910	AL	2025	0	0	2025-10-17 12:46:56.148832	2025-10-17 12:46:56.148832
17026	1911	VL	2025	15	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17027	1911	SL	2025	15	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17028	1911	ML	2025	5	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17029	1911	SPL	2025	3	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17030	1911	MAT	2025	105	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17031	1911	PAT	2025	7	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17032	1911	SOLO	2025	7	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17033	1911	VAWC	2025	10	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17034	1911	RL	2025	0	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17035	1911	MCW	2025	60	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17036	1911	STUDY	2025	180	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17037	1911	CALAMITY	2025	5	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17038	1911	MOL	2025	0	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17039	1911	TL	2025	0	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17040	1911	AL	2025	0	0	2025-10-17 12:46:56.263328	2025-10-17 12:46:56.263328
17041	1912	VL	2025	15	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17042	1912	SL	2025	15	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17043	1912	ML	2025	5	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17044	1912	SPL	2025	3	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17045	1912	MAT	2025	105	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17046	1912	PAT	2025	7	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17047	1912	SOLO	2025	7	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17048	1912	VAWC	2025	10	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17049	1912	RL	2025	0	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17050	1912	MCW	2025	60	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17051	1912	STUDY	2025	180	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17052	1912	CALAMITY	2025	5	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17053	1912	MOL	2025	0	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17054	1912	TL	2025	0	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17055	1912	AL	2025	0	0	2025-10-17 12:46:56.347585	2025-10-17 12:46:56.347585
17056	1913	VL	2025	15	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17057	1913	SL	2025	15	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17058	1913	ML	2025	5	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17059	1913	SPL	2025	3	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17060	1913	MAT	2025	105	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17061	1913	PAT	2025	7	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17062	1913	SOLO	2025	7	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17063	1913	VAWC	2025	10	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17064	1913	RL	2025	0	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17065	1913	MCW	2025	60	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17066	1913	STUDY	2025	180	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17067	1913	CALAMITY	2025	5	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17068	1913	MOL	2025	0	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17069	1913	TL	2025	0	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17070	1913	AL	2025	0	0	2025-10-17 12:46:56.417517	2025-10-17 12:46:56.417517
17071	1914	VL	2025	15	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17072	1914	SL	2025	15	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17073	1914	ML	2025	5	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17074	1914	SPL	2025	3	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17075	1914	MAT	2025	105	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17076	1914	PAT	2025	7	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17077	1914	SOLO	2025	7	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17078	1914	VAWC	2025	10	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17079	1914	RL	2025	0	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17080	1914	MCW	2025	60	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17081	1914	STUDY	2025	180	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17082	1914	CALAMITY	2025	5	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17083	1914	MOL	2025	0	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17084	1914	TL	2025	0	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17085	1914	AL	2025	0	0	2025-10-17 12:46:56.511693	2025-10-17 12:46:56.511693
17086	1915	VL	2025	15	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17087	1915	SL	2025	15	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17088	1915	ML	2025	5	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17089	1915	SPL	2025	3	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17090	1915	MAT	2025	105	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17091	1915	PAT	2025	7	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17092	1915	SOLO	2025	7	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17093	1915	VAWC	2025	10	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17094	1915	RL	2025	0	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17095	1915	MCW	2025	60	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17096	1915	STUDY	2025	180	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17097	1915	CALAMITY	2025	5	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17098	1915	MOL	2025	0	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17099	1915	TL	2025	0	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17100	1915	AL	2025	0	0	2025-10-17 12:46:56.649831	2025-10-17 12:46:56.649831
17101	1916	VL	2025	15	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17102	1916	SL	2025	15	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17103	1916	ML	2025	5	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17104	1916	SPL	2025	3	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17105	1916	MAT	2025	105	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17106	1916	PAT	2025	7	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17107	1916	SOLO	2025	7	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17108	1916	VAWC	2025	10	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17109	1916	RL	2025	0	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17110	1916	MCW	2025	60	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17111	1916	STUDY	2025	180	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17112	1916	CALAMITY	2025	5	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17113	1916	MOL	2025	0	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17114	1916	TL	2025	0	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17115	1916	AL	2025	0	0	2025-10-17 12:46:56.728938	2025-10-17 12:46:56.728938
17116	1917	VL	2025	15	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17117	1917	SL	2025	15	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17118	1917	ML	2025	5	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17119	1917	SPL	2025	3	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17120	1917	MAT	2025	105	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17121	1917	PAT	2025	7	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17122	1917	SOLO	2025	7	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17123	1917	VAWC	2025	10	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17124	1917	RL	2025	0	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17125	1917	MCW	2025	60	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17126	1917	STUDY	2025	180	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17127	1917	CALAMITY	2025	5	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17128	1917	MOL	2025	0	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17129	1917	TL	2025	0	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17130	1917	AL	2025	0	0	2025-10-17 12:46:56.83032	2025-10-17 12:46:56.83032
17131	1918	VL	2025	15	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17132	1918	SL	2025	15	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17133	1918	ML	2025	5	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17134	1918	SPL	2025	3	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17135	1918	MAT	2025	105	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17136	1918	PAT	2025	7	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17137	1918	SOLO	2025	7	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17138	1918	VAWC	2025	10	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17139	1918	RL	2025	0	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17140	1918	MCW	2025	60	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17141	1918	STUDY	2025	180	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17142	1918	CALAMITY	2025	5	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17143	1918	MOL	2025	0	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17144	1918	TL	2025	0	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17145	1918	AL	2025	0	0	2025-10-17 12:46:57.028296	2025-10-17 12:46:57.028296
17146	1919	VL	2025	15	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17147	1919	SL	2025	15	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17148	1919	ML	2025	5	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17149	1919	SPL	2025	3	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17150	1919	MAT	2025	105	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17151	1919	PAT	2025	7	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17152	1919	SOLO	2025	7	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17153	1919	VAWC	2025	10	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17154	1919	RL	2025	0	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17155	1919	MCW	2025	60	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17156	1919	STUDY	2025	180	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17157	1919	CALAMITY	2025	5	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17158	1919	MOL	2025	0	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17159	1919	TL	2025	0	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17160	1919	AL	2025	0	0	2025-10-17 12:46:57.109007	2025-10-17 12:46:57.109007
17161	1920	VL	2025	15	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17162	1920	SL	2025	15	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17163	1920	ML	2025	5	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17164	1920	SPL	2025	3	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17165	1920	MAT	2025	105	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17166	1920	PAT	2025	7	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17167	1920	SOLO	2025	7	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17168	1920	VAWC	2025	10	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17169	1920	RL	2025	0	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17170	1920	MCW	2025	60	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17171	1920	STUDY	2025	180	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17172	1920	CALAMITY	2025	5	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17173	1920	MOL	2025	0	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17174	1920	TL	2025	0	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17175	1920	AL	2025	0	0	2025-10-17 12:46:57.210048	2025-10-17 12:46:57.210048
17176	1921	VL	2025	15	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17177	1921	SL	2025	15	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17178	1921	ML	2025	5	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17179	1921	SPL	2025	3	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17180	1921	MAT	2025	105	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17181	1921	PAT	2025	7	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17182	1921	SOLO	2025	7	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17183	1921	VAWC	2025	10	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17184	1921	RL	2025	0	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17185	1921	MCW	2025	60	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17186	1921	STUDY	2025	180	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17187	1921	CALAMITY	2025	5	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17188	1921	MOL	2025	0	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17189	1921	TL	2025	0	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17190	1921	AL	2025	0	0	2025-10-17 12:46:57.413955	2025-10-17 12:46:57.413955
17191	1922	VL	2025	15	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17192	1922	SL	2025	15	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17193	1922	ML	2025	5	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17194	1922	SPL	2025	3	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17195	1922	MAT	2025	105	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17196	1922	PAT	2025	7	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17197	1922	SOLO	2025	7	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17198	1922	VAWC	2025	10	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17199	1922	RL	2025	0	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17200	1922	MCW	2025	60	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17201	1922	STUDY	2025	180	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17202	1922	CALAMITY	2025	5	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17203	1922	MOL	2025	0	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17204	1922	TL	2025	0	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17205	1922	AL	2025	0	0	2025-10-17 12:46:57.493471	2025-10-17 12:46:57.493471
17206	1923	VL	2025	15	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17207	1923	SL	2025	15	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17208	1923	ML	2025	5	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17209	1923	SPL	2025	3	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17210	1923	MAT	2025	105	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17211	1923	PAT	2025	7	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17212	1923	SOLO	2025	7	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17213	1923	VAWC	2025	10	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17214	1923	RL	2025	0	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17215	1923	MCW	2025	60	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17216	1923	STUDY	2025	180	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17217	1923	CALAMITY	2025	5	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17218	1923	MOL	2025	0	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17219	1923	TL	2025	0	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17220	1923	AL	2025	0	0	2025-10-17 12:46:57.585055	2025-10-17 12:46:57.585055
17221	1924	VL	2025	15	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17222	1924	SL	2025	15	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17223	1924	ML	2025	5	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17224	1924	SPL	2025	3	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17225	1924	MAT	2025	105	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17226	1924	PAT	2025	7	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17227	1924	SOLO	2025	7	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17228	1924	VAWC	2025	10	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17229	1924	RL	2025	0	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17230	1924	MCW	2025	60	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17231	1924	STUDY	2025	180	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17232	1924	CALAMITY	2025	5	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17233	1924	MOL	2025	0	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17234	1924	TL	2025	0	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17235	1924	AL	2025	0	0	2025-10-17 12:46:57.665653	2025-10-17 12:46:57.665653
17236	1925	VL	2025	15	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17237	1925	SL	2025	15	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17238	1925	ML	2025	5	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17239	1925	SPL	2025	3	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17240	1925	MAT	2025	105	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17241	1925	PAT	2025	7	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17242	1925	SOLO	2025	7	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17243	1925	VAWC	2025	10	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17244	1925	RL	2025	0	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17245	1925	MCW	2025	60	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17246	1925	STUDY	2025	180	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17247	1925	CALAMITY	2025	5	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17248	1925	MOL	2025	0	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17249	1925	TL	2025	0	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17250	1925	AL	2025	0	0	2025-10-17 12:46:57.78788	2025-10-17 12:46:57.78788
17251	1926	VL	2025	15	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17252	1926	SL	2025	15	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17253	1926	ML	2025	5	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17254	1926	SPL	2025	3	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17255	1926	MAT	2025	105	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17256	1926	PAT	2025	7	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17257	1926	SOLO	2025	7	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17258	1926	VAWC	2025	10	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17259	1926	RL	2025	0	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17260	1926	MCW	2025	60	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17261	1926	STUDY	2025	180	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17262	1926	CALAMITY	2025	5	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17263	1926	MOL	2025	0	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17264	1926	TL	2025	0	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17265	1926	AL	2025	0	0	2025-10-17 12:46:57.884694	2025-10-17 12:46:57.884694
17266	1927	VL	2025	15	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17267	1927	SL	2025	15	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17268	1927	ML	2025	5	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17269	1927	SPL	2025	3	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17270	1927	MAT	2025	105	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17271	1927	PAT	2025	7	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17272	1927	SOLO	2025	7	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17273	1927	VAWC	2025	10	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17274	1927	RL	2025	0	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17275	1927	MCW	2025	60	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17276	1927	STUDY	2025	180	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17277	1927	CALAMITY	2025	5	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17278	1927	MOL	2025	0	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17279	1927	TL	2025	0	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17280	1927	AL	2025	0	0	2025-10-17 12:46:57.973863	2025-10-17 12:46:57.973863
17281	1928	VL	2025	15	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17282	1928	SL	2025	15	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17283	1928	ML	2025	5	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17284	1928	SPL	2025	3	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17285	1928	MAT	2025	105	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17286	1928	PAT	2025	7	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17287	1928	SOLO	2025	7	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17288	1928	VAWC	2025	10	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17289	1928	RL	2025	0	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17290	1928	MCW	2025	60	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17291	1928	STUDY	2025	180	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17292	1928	CALAMITY	2025	5	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17293	1928	MOL	2025	0	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17294	1928	TL	2025	0	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17295	1928	AL	2025	0	0	2025-10-17 12:46:58.177687	2025-10-17 12:46:58.177687
17296	1929	VL	2025	15	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17297	1929	SL	2025	15	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17298	1929	ML	2025	5	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17299	1929	SPL	2025	3	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17300	1929	MAT	2025	105	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17301	1929	PAT	2025	7	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17302	1929	SOLO	2025	7	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17303	1929	VAWC	2025	10	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17304	1929	RL	2025	0	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17305	1929	MCW	2025	60	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17306	1929	STUDY	2025	180	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17307	1929	CALAMITY	2025	5	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17308	1929	MOL	2025	0	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17309	1929	TL	2025	0	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17310	1929	AL	2025	0	0	2025-10-17 12:46:58.26436	2025-10-17 12:46:58.26436
17311	1930	VL	2025	15	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17312	1930	SL	2025	15	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17313	1930	ML	2025	5	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17314	1930	SPL	2025	3	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17315	1930	MAT	2025	105	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17316	1930	PAT	2025	7	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17317	1930	SOLO	2025	7	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17318	1930	VAWC	2025	10	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17319	1930	RL	2025	0	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17320	1930	MCW	2025	60	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17321	1930	STUDY	2025	180	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17322	1930	CALAMITY	2025	5	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17323	1930	MOL	2025	0	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17324	1930	TL	2025	0	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17325	1930	AL	2025	0	0	2025-10-17 12:46:58.348892	2025-10-17 12:46:58.348892
17326	1931	VL	2025	15	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17327	1931	SL	2025	15	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17328	1931	ML	2025	5	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17329	1931	SPL	2025	3	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17330	1931	MAT	2025	105	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17331	1931	PAT	2025	7	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17332	1931	SOLO	2025	7	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17333	1931	VAWC	2025	10	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17334	1931	RL	2025	0	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17335	1931	MCW	2025	60	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17336	1931	STUDY	2025	180	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17337	1931	CALAMITY	2025	5	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17338	1931	MOL	2025	0	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17339	1931	TL	2025	0	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17340	1931	AL	2025	0	0	2025-10-17 12:46:58.417581	2025-10-17 12:46:58.417581
17341	1932	VL	2025	15	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17342	1932	SL	2025	15	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17343	1932	ML	2025	5	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17344	1932	SPL	2025	3	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17345	1932	MAT	2025	105	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17346	1932	PAT	2025	7	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17347	1932	SOLO	2025	7	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17348	1932	VAWC	2025	10	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17349	1932	RL	2025	0	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17350	1932	MCW	2025	60	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17351	1932	STUDY	2025	180	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17352	1932	CALAMITY	2025	5	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17353	1932	MOL	2025	0	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17354	1932	TL	2025	0	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17355	1932	AL	2025	0	0	2025-10-17 12:46:58.557677	2025-10-17 12:46:58.557677
17356	1933	VL	2025	15	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17357	1933	SL	2025	15	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17358	1933	ML	2025	5	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17359	1933	SPL	2025	3	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17360	1933	MAT	2025	105	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17361	1933	PAT	2025	7	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17362	1933	SOLO	2025	7	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17363	1933	VAWC	2025	10	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17364	1933	RL	2025	0	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17365	1933	MCW	2025	60	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17366	1933	STUDY	2025	180	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17367	1933	CALAMITY	2025	5	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17368	1933	MOL	2025	0	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17369	1933	TL	2025	0	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17370	1933	AL	2025	0	0	2025-10-17 12:46:58.653282	2025-10-17 12:46:58.653282
17371	1934	VL	2025	15	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17372	1934	SL	2025	15	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17373	1934	ML	2025	5	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17374	1934	SPL	2025	3	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17375	1934	MAT	2025	105	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17376	1934	PAT	2025	7	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17377	1934	SOLO	2025	7	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17378	1934	VAWC	2025	10	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17379	1934	RL	2025	0	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17380	1934	MCW	2025	60	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17381	1934	STUDY	2025	180	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17382	1934	CALAMITY	2025	5	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17383	1934	MOL	2025	0	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17384	1934	TL	2025	0	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17385	1934	AL	2025	0	0	2025-10-17 12:46:58.727616	2025-10-17 12:46:58.727616
17386	1935	VL	2025	15	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17387	1935	SL	2025	15	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17388	1935	ML	2025	5	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17389	1935	SPL	2025	3	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17390	1935	MAT	2025	105	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17391	1935	PAT	2025	7	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17392	1935	SOLO	2025	7	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17393	1935	VAWC	2025	10	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17394	1935	RL	2025	0	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17395	1935	MCW	2025	60	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17396	1935	STUDY	2025	180	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17397	1935	CALAMITY	2025	5	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17398	1935	MOL	2025	0	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17399	1935	TL	2025	0	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17400	1935	AL	2025	0	0	2025-10-17 12:46:58.803803	2025-10-17 12:46:58.803803
17401	1936	VL	2025	15	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17402	1936	SL	2025	15	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17403	1936	ML	2025	5	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17404	1936	SPL	2025	3	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17405	1936	MAT	2025	105	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17406	1936	PAT	2025	7	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17407	1936	SOLO	2025	7	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17408	1936	VAWC	2025	10	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17409	1936	RL	2025	0	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17410	1936	MCW	2025	60	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17411	1936	STUDY	2025	180	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17412	1936	CALAMITY	2025	5	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17413	1936	MOL	2025	0	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17414	1936	TL	2025	0	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17415	1936	AL	2025	0	0	2025-10-17 12:46:58.92481	2025-10-17 12:46:58.92481
17416	1937	VL	2025	15	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17417	1937	SL	2025	15	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17418	1937	ML	2025	5	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17419	1937	SPL	2025	3	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17420	1937	MAT	2025	105	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17421	1937	PAT	2025	7	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17422	1937	SOLO	2025	7	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17423	1937	VAWC	2025	10	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17424	1937	RL	2025	0	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17425	1937	MCW	2025	60	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17426	1937	STUDY	2025	180	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17427	1937	CALAMITY	2025	5	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17428	1937	MOL	2025	0	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17429	1937	TL	2025	0	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17430	1937	AL	2025	0	0	2025-10-17 12:46:59.013954	2025-10-17 12:46:59.013954
17431	1938	VL	2025	15	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17432	1938	SL	2025	15	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17433	1938	ML	2025	5	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17434	1938	SPL	2025	3	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17435	1938	MAT	2025	105	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17436	1938	PAT	2025	7	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17437	1938	SOLO	2025	7	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17438	1938	VAWC	2025	10	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17439	1938	RL	2025	0	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17440	1938	MCW	2025	60	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17441	1938	STUDY	2025	180	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17442	1938	CALAMITY	2025	5	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17443	1938	MOL	2025	0	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17444	1938	TL	2025	0	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17445	1938	AL	2025	0	0	2025-10-17 12:46:59.095562	2025-10-17 12:46:59.095562
17446	1939	VL	2025	15	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17447	1939	SL	2025	15	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17448	1939	ML	2025	5	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17449	1939	SPL	2025	3	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17450	1939	MAT	2025	105	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17451	1939	PAT	2025	7	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17452	1939	SOLO	2025	7	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17453	1939	VAWC	2025	10	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17454	1939	RL	2025	0	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17455	1939	MCW	2025	60	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17456	1939	STUDY	2025	180	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17457	1939	CALAMITY	2025	5	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17458	1939	MOL	2025	0	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17459	1939	TL	2025	0	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17460	1939	AL	2025	0	0	2025-10-17 12:46:59.170754	2025-10-17 12:46:59.170754
17461	1940	VL	2025	15	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17462	1940	SL	2025	15	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17463	1940	ML	2025	5	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17464	1940	SPL	2025	3	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17465	1940	MAT	2025	105	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17466	1940	PAT	2025	7	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17467	1940	SOLO	2025	7	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17468	1940	VAWC	2025	10	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17469	1940	RL	2025	0	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17470	1940	MCW	2025	60	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17471	1940	STUDY	2025	180	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17472	1940	CALAMITY	2025	5	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17473	1940	MOL	2025	0	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17474	1940	TL	2025	0	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17475	1940	AL	2025	0	0	2025-10-17 12:46:59.311567	2025-10-17 12:46:59.311567
17476	1941	VL	2025	15	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17477	1941	SL	2025	15	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17478	1941	ML	2025	5	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17479	1941	SPL	2025	3	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17480	1941	MAT	2025	105	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17481	1941	PAT	2025	7	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17482	1941	SOLO	2025	7	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17483	1941	VAWC	2025	10	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17484	1941	RL	2025	0	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17485	1941	MCW	2025	60	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17486	1941	STUDY	2025	180	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17487	1941	CALAMITY	2025	5	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17488	1941	MOL	2025	0	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17489	1941	TL	2025	0	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17490	1941	AL	2025	0	0	2025-10-17 12:46:59.383837	2025-10-17 12:46:59.383837
17491	1942	VL	2025	15	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17492	1942	SL	2025	15	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17493	1942	ML	2025	5	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17494	1942	SPL	2025	3	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17495	1942	MAT	2025	105	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17496	1942	PAT	2025	7	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17497	1942	SOLO	2025	7	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17498	1942	VAWC	2025	10	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17499	1942	RL	2025	0	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17500	1942	MCW	2025	60	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17501	1942	STUDY	2025	180	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17502	1942	CALAMITY	2025	5	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17503	1942	MOL	2025	0	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17504	1942	TL	2025	0	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
17505	1942	AL	2025	0	0	2025-10-17 12:46:59.460108	2025-10-17 12:46:59.460108
\.


--
-- Data for Name: leave_types; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.leave_types (id, code, name, description, is_accruable, default_days) FROM stdin;
1	VL	Vacation Leave	Earned monthly at 1.25 days per month	t	15
2	SL	Sick Leave	Earned monthly at 1.25 days per month	t	15
3	ML	Mandatory/Forced Leave	Anual 5 day vacation leave shall be forfeited if not taken during the year	f	5
4	SPL	Special Privilege Leave	3 days per year, non-cumulative	f	3
5	MAT	Maternity Leave	105 days with pay, per childbirth/miscarriage	f	105
6	PAT	Paternity Leave	7 working days with pay for first 4 deliveries of spouse	f	7
7	SOLO	Solo Parent Leave	7 working days per year under Solo Parent Act	f	7
8	VAWC	VAWC Leave	10-day leave for women victims of violence	f	10
9	RL	Rehabilitation Leave	Up to 6 months; requires accident reports and medical certificate.	f	0
10	MCW	Magna Carta for Women Leave	60-day leave for gynecological disorders	f	60
11	STUDY	Study Leave	Up to 6 months, with or without pay	f	180
12	CALAMITY	Special Emergency/Calamity Leave	Used in case of disasters, per CSC rules	f	5
13	MOL	Monetization of Leave Credits	Conversion of at least 50% accumulated leave credits into cash.	f	0
14	TL	Terminal Leave	Granted upon resignation, retirement, or separation.	t	0
15	AL	Adoption Leave	Requires Pre-Adoptive Placement Authority from DSWD.	t	0
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.messages (id, user_id, receiver_id, message, "time", pinned) FROM stdin;
1	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	Hhhh	2025-11-05 01:50:31.039042	f
2	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Hi 	2025-11-05 12:25:00.81411	f
3	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Mwaaaaa	2025-11-05 12:25:11.627099	f
4	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_34bLHXnQoaRKUune6CfsSgzBTtp	Haha	2025-11-05 12:28:40.910791	f
5	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_34bLHXnQoaRKUune6CfsSgzBTtp	Hehe	2025-11-05 12:34:56.956284	f
6	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Bahaha	2025-11-05 12:35:14.377988	f
7	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Ahahaha	2025-11-05 12:42:51.382871	f
8	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Xxxc	2025-11-05 12:53:35.224398	f
9	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Nsbsns	2025-11-05 13:01:39.113713	f
10	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	ANO NA TE	2025-11-07 03:50:35.766826	f
11	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Ano naman	2025-11-07 03:54:41.714453	f
12	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	Hahahahs	2025-11-07 04:05:10.350276	f
13	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	HAHAAHAHA	2025-11-16 01:03:09.723278	f
14	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Hahaaahahahah	2025-11-16 01:09:16.4868	f
15	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	Hoy	2025-11-16 01:09:19.371085	f
16	user_34oTu5GqoNrNVwxp76cVuw5EeKB	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	Hehehe	2025-11-16 01:10:09.495794	f
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.notifications (id, user_id, message, read, created_at) FROM stdin;
1	user_32XnLpEUcAGjNDHLAkf4qz5kOE2	Your leave request (Vacation Leave) has been approved by Admin.	f	2025-09-28 03:12:25.737907
2	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by an admin.	f	2025-11-04 03:41:10.205922
3	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 03:50:24.591092
4	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 04:18:48.009199
5	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 04:29:21.639639
6	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 04:36:42.099637
7	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 04:40:27.882697
8	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 05:00:21.982505
9	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 05:14:13.022249
10	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 05:16:35.077514
11	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 05:18:37.212879
12	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 05:55:20.014689
13	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 06:00:24.268296
14	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 06:06:02.41201
15	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 06:26:55.732261
16	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 06:31:25.58023
17	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 08:15:09.756608
18	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 08:20:50.425786
19	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 08:29:03.971442
20	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja.	f	2025-11-04 08:35:26.672981
21	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been rejected by shamelletadeja10@gmail.com. Remarks: hindi true	f	2025-11-04 14:45:13.056907
22	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-07 02:43:31.649903
23	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-07 02:56:09.993897
24	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-07 02:57:31.812094
25	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been rejected by Shamelle Anne (office head). Remarks: kunware ka lang	f	2025-11-07 03:12:38.713664
26	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been rejected by Shamelle Anne (office head). Remarks: uyyy kunware	f	2025-11-07 03:22:14.417651
27	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been rejected by Shamelle Anne (office head). Remarks: sus	f	2025-11-07 03:26:40.414764
28	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-07 08:04:23.218365
29	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-07 08:04:51.42274
30	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-07 08:06:23.989762
31	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-07 08:09:33.394403
32	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-07 08:10:09.174631
33	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-07 08:13:16.176868
34	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-07 08:15:56.214056
35	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-07 08:16:17.616681
36	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-07 08:16:38.403843
37	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-13 03:27:03.807214
38	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-13 03:27:23.879338
39	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-13 03:58:34.516511
40	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-13 04:29:59.883051
41	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-13 04:30:21.655709
42	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Mayor (mayor).	f	2025-11-15 16:13:05.586937
43	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-15 16:26:38.492383
44	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-15 16:27:04.845734
45	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Mayor (mayor).	f	2025-11-15 16:28:22.8332
46	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-16 00:46:53.805274
47	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-16 00:47:19.420412
48	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Mayor (mayor).	f	2025-11-16 01:48:20.783021
49	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-16 01:52:36.042028
50	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-16 01:52:56.205461
51	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-16 02:03:23.758504
52	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-16 02:03:42.07982
53	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Mayor (mayor).	f	2025-11-16 02:09:12.917869
54	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-16 02:17:34.634589
55	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-16 02:17:55.114474
56	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Mayor (mayor).	f	2025-11-16 02:18:38.949214
57	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-19 03:20:16.071163
58	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-19 03:21:17.447586
59	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Mayor (mayor).	f	2025-11-19 03:22:15.923907
60	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 06:48:41.731126
61	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 08:45:55.153047
62	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 09:09:57.239777
63	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 09:24:00.023385
64	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 09:33:01.521076
65	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 09:49:03.1374
66	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 09:51:38.196052
67	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 11:24:08.693288
68	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 14:28:35.813237
69	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-25 14:53:09.836515
70	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-25 15:14:26.147392
71	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-25 15:17:47.297404
72	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-25 15:18:56.604719
73	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-25 15:20:08.432665
74	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 01:53:43.063937
75	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 01:54:59.789708
76	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-26 01:56:46.238602
77	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 02:10:59.014877
78	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 02:11:38.131461
79	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Sick Leave) has been approved by Michael Diaz (mayor).	f	2025-11-26 02:12:27.814759
80	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 02:14:36.806554
81	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 02:15:20.366827
82	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-26 02:18:42.217885
83	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 07:27:50.172461
84	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 07:28:39.876677
85	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-26 07:29:26.25424
86	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 07:32:46.675285
87	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 07:33:42.755911
88	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Michael Diaz (mayor).	f	2025-11-26 07:34:28.446054
89	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 10:33:43.493409
90	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 10:46:07.262691
91	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 10:49:00.770202
92	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 10:56:43.417371
93	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 11:00:18.25217
94	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 11:12:10.320988
95	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been rejected by Shamelle Anne (office head). Remarks: Pending rejection reason...	f	2025-11-26 11:19:22.361315
96	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Vacation Leave) has been rejected by Shamelle Anne (office head). Remarks: Kunware ka lang	f	2025-11-26 11:51:25.502533
97	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Mandatory/Forced Leave) has been approved by Shamelle Anne (office head).	f	2025-11-26 13:07:00.163873
98	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Mandatory/Forced Leave) has been approved by Shamelle Anne Tadeja (admin).	f	2025-11-26 13:08:58.212634
99	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Mandatory/Forced Leave) has been approved by Michael Diaz (Mayor).	f	2025-11-26 13:47:11.448953
100	user_34oTu5GqoNrNVwxp76cVuw5EeKB	Your leave request (Mandatory/Forced Leave) has been approved by Michael Diaz (Mayor).	f	2025-11-26 14:47:05.132872
\.


--
-- Data for Name: password_tokens; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.password_tokens (id, user_id, token, type, expires_at, used) FROM stdin;
13	14	2999a579-8252-498a-8db5-5fecf9e30a3b	setup	2025-10-18 01:05:36.874	t
16	17	17a3038f-784f-4cf4-891d-d32e3bbcf61b	setup	2025-10-27 12:22:58.337	t
17	18	e65b74f6-b6d1-40b4-a9ef-1c2a1634f01f	setup	2025-11-08 01:38:07.528	t
\.


--
-- Data for Name: useradmin; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.useradmin (id, email, password, role, created_at, full_name, profile_picture) FROM stdin;
2	shamelletadeja10@gmail.com	$2b$10$UxJsE9QMrWdjMSLu3BF4IO6cYKBwk7eKPhYTkAlWmf4BpHi4YHBR.	admin	2025-10-12 02:46:59.204667	Shamelle Anne Tadeja	https://res.cloudinary.com/dlrveckcz/image/upload/v1762652361/pgpggjjyu4n9ddqpj5mk.jpg
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.users (user_id, email, first_name, last_name) FROM stdin;
user_32Xn6KrA4j3TkpI4tiGNlCNpRa7	shammyyy2@gmail.com	Sham	Tade
user_32XnLpEUcAGjNDHLAkf4qz5kOE2	reylandtanglao2@gmail.com	Reyland 	Tanglao 
user_337kIzlBTqnt9eHoXkPXAwdXqp8	mellesha728@gmail.com	Shamelle	Tadeja
user_34bLHXnQoaRKUune6CfsSgzBTtp	shamelletadeja10@gmail.com	Shamelle Anne 	Tadeja
user_34oTu5GqoNrNVwxp76cVuw5EeKB	sofiacantos325@gmail.com	Sofia	Cantos
\.


--
-- Name: admin_accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.admin_accounts_id_seq', 18, true);


--
-- Name: announcements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.announcements_id_seq', 71, true);


--
-- Name: attendance_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.attendance_logs_id_seq', 63, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 403, true);


--
-- Name: department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.department_id_seq', 1, true);


--
-- Name: employee_list_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.employee_list_id_seq', 1945, true);


--
-- Name: leave_applications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.leave_applications_id_seq', 98, true);


--
-- Name: leave_cards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.leave_cards_id_seq', 2078, true);


--
-- Name: leave_credits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.leave_credits_id_seq', 1176, true);


--
-- Name: leave_entitlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.leave_entitlements_id_seq', 17535, true);


--
-- Name: leave_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.leave_types_id_seq', 15, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.messages_id_seq', 16, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.notifications_id_seq', 100, true);


--
-- Name: password_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.password_tokens_id_seq', 17, true);


--
-- Name: useradmin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.useradmin_id_seq', 2, true);


--
-- Name: admin_accounts admin_accounts_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admin_accounts
    ADD CONSTRAINT admin_accounts_email_key UNIQUE (email);


--
-- Name: admin_accounts admin_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admin_accounts
    ADD CONSTRAINT admin_accounts_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: attendance_logs attendance_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: department department_name_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_name_key UNIQUE (name);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (id);


--
-- Name: employee_list employee_list_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.employee_list
    ADD CONSTRAINT employee_list_email_key UNIQUE (email);


--
-- Name: employee_list employee_list_id_number_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.employee_list
    ADD CONSTRAINT employee_list_id_number_key UNIQUE (id_number);


--
-- Name: employee_list employee_list_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.employee_list
    ADD CONSTRAINT employee_list_pkey PRIMARY KEY (id);


--
-- Name: employee_list employee_list_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.employee_list
    ADD CONSTRAINT employee_list_user_id_unique UNIQUE (user_id);


--
-- Name: leave_applications leave_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_applications
    ADD CONSTRAINT leave_applications_pkey PRIMARY KEY (id);


--
-- Name: leave_cards leave_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_cards
    ADD CONSTRAINT leave_cards_pkey PRIMARY KEY (id);


--
-- Name: leave_credits leave_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_credits
    ADD CONSTRAINT leave_credits_pkey PRIMARY KEY (id);


--
-- Name: leave_credits leave_credits_user_id_year_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_credits
    ADD CONSTRAINT leave_credits_user_id_year_key UNIQUE (user_id, year);


--
-- Name: leave_entitlements leave_entitlements_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_entitlements
    ADD CONSTRAINT leave_entitlements_pkey PRIMARY KEY (id);


--
-- Name: leave_types leave_types_code_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_code_key UNIQUE (code);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: password_tokens password_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.password_tokens
    ADD CONSTRAINT password_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_tokens password_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.password_tokens
    ADD CONSTRAINT password_tokens_token_key UNIQUE (token);


--
-- Name: attendance_logs unique_attendance_per_pin; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT unique_attendance_per_pin UNIQUE (pin, attendance_date);


--
-- Name: attendance_logs unique_attendance_per_user; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT unique_attendance_per_user UNIQUE (user_id, attendance_date);


--
-- Name: leave_entitlements unique_leave_per_user; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_entitlements
    ADD CONSTRAINT unique_leave_per_user UNIQUE (user_id, leave_type, year);


--
-- Name: useradmin useradmin_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.useradmin
    ADD CONSTRAINT useradmin_email_key UNIQUE (email);


--
-- Name: useradmin useradmin_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.useradmin
    ADD CONSTRAINT useradmin_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: employee_list after_employee_insert; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER after_employee_insert AFTER INSERT ON public.employee_list FOR EACH ROW EXECUTE FUNCTION public.create_leave_credits_for_employee();


--
-- Name: employee_list after_employee_insert_entitlements; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER after_employee_insert_entitlements AFTER INSERT ON public.employee_list FOR EACH ROW EXECUTE FUNCTION public.create_leave_entitlements();


--
-- Name: announcements announcements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.useradmin(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.useradmin(id) ON DELETE CASCADE;


--
-- Name: leave_entitlements fk_leave_entitlements_employee; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_entitlements
    ADD CONSTRAINT fk_leave_entitlements_employee FOREIGN KEY (user_id) REFERENCES public.employee_list(id) ON DELETE CASCADE;


--
-- Name: leave_applications leave_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_applications
    ADD CONSTRAINT leave_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.employee_list(user_id) ON DELETE CASCADE;


--
-- Name: leave_cards leave_cards_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.leave_cards
    ADD CONSTRAINT leave_cards_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_list(id) ON DELETE CASCADE;


--
-- Name: messages messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id);


--
-- Name: messages messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: password_tokens password_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.password_tokens
    ADD CONSTRAINT password_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.admin_accounts(id) ON DELETE CASCADE;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

\unrestrict qm2U5tyDoaVGmDm0iCzRmMVvTgnYoa5801a7e7nW4j0cMzmB2HggEhcZDXtaacB

