--
-- PostgreSQL database dump
--

\restrict dsxIodPy6USXZGi0UBOLR6nl8u9YaR3SKeY7RsHj3AAcp97h34yrlJCMUdz8bUl

-- Dumped from database version 17.11 (fcae950)
-- Dumped by pg_dump version 18.6

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
-- Name: neon_auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA neon_auth;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "accountId" text NOT NULL,
    "providerId" text NOT NULL,
    "userId" uuid NOT NULL,
    "accessToken" text,
    "refreshToken" text,
    "idToken" text,
    "accessTokenExpiresAt" timestamp with time zone,
    "refreshTokenExpiresAt" timestamp with time zone,
    scope text,
    password text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: invitation; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.invitation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "organizationId" uuid NOT NULL,
    email text NOT NULL,
    role text,
    status text NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "inviterId" uuid NOT NULL
);


--
-- Name: jwks; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.jwks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "publicKey" text NOT NULL,
    "privateKey" text NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "expiresAt" timestamp with time zone
);


--
-- Name: member; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.member (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "organizationId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    role text NOT NULL,
    "createdAt" timestamp with time zone NOT NULL
);


--
-- Name: organization; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.organization (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    logo text,
    "createdAt" timestamp with time zone NOT NULL,
    metadata text
);


--
-- Name: project_config; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.project_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    endpoint_id text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    trusted_origins jsonb NOT NULL,
    social_providers jsonb NOT NULL,
    email_provider jsonb,
    email_and_password jsonb,
    allow_localhost boolean NOT NULL,
    plugin_configs jsonb,
    webhook_config jsonb
);


--
-- Name: session; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL,
    token text NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "ipAddress" text,
    "userAgent" text,
    "userId" uuid NOT NULL,
    "impersonatedBy" text,
    "activeOrganizationId" text
);


--
-- Name: user; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    "emailVerified" boolean NOT NULL,
    image text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    role text,
    banned boolean,
    "banReason" text,
    "banExpires" timestamp with time zone
);


--
-- Name: verification; Type: TABLE; Schema: neon_auth; Owner: -
--

CREATE TABLE neon_auth.verification (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identifier text NOT NULL,
    value text NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: accounts_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_user (
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    id uuid NOT NULL,
    name character varying(150) NOT NULL,
    email character varying(254),
    phone character varying(20),
    role character varying(10) NOT NULL,
    is_active boolean NOT NULL,
    is_staff boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    created_by_id uuid,
    CONSTRAINT user_requires_email_or_phone CHECK (((email IS NOT NULL) OR (phone IS NOT NULL)))
);


--
-- Name: accounts_user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_user_groups (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    group_id integer NOT NULL
);


--
-- Name: accounts_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.accounts_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.accounts_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounts_user_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_user_user_permissions (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: accounts_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.accounts_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.accounts_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: assets_asset; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets_asset (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(150) NOT NULL,
    purchase_price numeric(10,2) NOT NULL,
    purchase_date date NOT NULL,
    has_warranty boolean NOT NULL,
    warranty_note text NOT NULL,
    created_by_id uuid,
    supplier_id bigint,
    description text NOT NULL
);


--
-- Name: assets_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.assets_asset ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.assets_asset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: assets_assetincident; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets_assetincident (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    type character varying(10) NOT NULL,
    cost numeric(10,2) NOT NULL,
    date date NOT NULL,
    note text NOT NULL,
    asset_id bigint NOT NULL,
    created_by_id uuid
);


--
-- Name: assets_assetincident_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.assets_assetincident ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.assets_assetincident_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_auditlog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_auditlog (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    object_id character varying(64) NOT NULL,
    object_repr character varying(255) NOT NULL,
    action character varying(10) NOT NULL,
    changed_fields jsonb NOT NULL,
    content_type_id integer NOT NULL,
    created_by_id uuid
);


--
-- Name: audit_auditlog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_auditlog ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.audit_auditlog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_auditlogentry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_auditlogentry (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    object_id bigint NOT NULL,
    action character varying(100) NOT NULL,
    description text NOT NULL,
    content_type_id integer NOT NULL,
    created_by_id uuid,
    CONSTRAINT audit_auditlogentry_object_id_check CHECK ((object_id >= 0))
);


--
-- Name: audit_auditlogentry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_auditlogentry ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.audit_auditlogentry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customers_customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers_customer (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    address text NOT NULL,
    email character varying(254),
    is_red_listed boolean NOT NULL,
    created_by_id uuid,
    description text NOT NULL
);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.customers_customer ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.customers_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id uuid NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


--
-- Name: ecommerce_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ecommerce_order (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    order_no character varying(30) NOT NULL,
    tracking_token character varying(16) NOT NULL,
    customer_name character varying(150) NOT NULL,
    customer_phone character varying(20) NOT NULL,
    customer_address text NOT NULL,
    status character varying(10) NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    created_by_id uuid
);


--
-- Name: ecommerce_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.ecommerce_order ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ecommerce_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ecommerce_orderitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ecommerce_orderitem (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    quantity integer NOT NULL,
    price_charged numeric(10,2) NOT NULL,
    created_by_id uuid,
    order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    CONSTRAINT ecommerce_orderitem_quantity_check CHECK ((quantity >= 0))
);


--
-- Name: ecommerce_orderitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.ecommerce_orderitem ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ecommerce_orderitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: expenses_expense; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses_expense (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    category character varying(20) NOT NULL,
    amount numeric(10,2) NOT NULL,
    date date NOT NULL,
    note text NOT NULL,
    created_by_id uuid
);


--
-- Name: expenses_expense_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.expenses_expense ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.expenses_expense_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices_invoice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices_invoice (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    invoice_no character varying(30) NOT NULL,
    status character varying(10) NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    paid_amount numeric(12,2) NOT NULL,
    created_date date NOT NULL,
    public_share_token character varying(16) NOT NULL,
    created_by_id uuid,
    customer_id bigint NOT NULL,
    had_shortfall boolean NOT NULL,
    discount_amount numeric(10,2) NOT NULL,
    discount_note text NOT NULL,
    waived_amount numeric(10,2) NOT NULL,
    waived_note text NOT NULL
);


--
-- Name: invoices_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invoices_invoice ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.invoices_invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices_invoicemeterentry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices_invoicemeterentry (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    serial_number character varying(100),
    previous_km integer,
    current_km integer,
    service_date timestamp with time zone NOT NULL,
    paid_share numeric(10,2) NOT NULL,
    created_by_id uuid,
    invoice_id bigint NOT NULL,
    meter_id bigint NOT NULL,
    mileage_correction_device_id bigint,
    condition_note jsonb NOT NULL,
    CONSTRAINT invoices_invoicemeterentry_current_km_check CHECK ((current_km >= 0)),
    CONSTRAINT invoices_invoicemeterentry_previous_km_check CHECK ((previous_km >= 0))
);


--
-- Name: invoices_invoicemeterentry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invoices_invoicemeterentry ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.invoices_invoicemeterentry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices_invoicepayment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices_invoicepayment (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(20) NOT NULL,
    payment_date timestamp with time zone NOT NULL,
    note text NOT NULL,
    created_by_id uuid,
    invoice_id bigint NOT NULL
);


--
-- Name: invoices_invoicepayment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invoices_invoicepayment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.invoices_invoicepayment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices_invoiceproductline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices_invoiceproductline (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    quantity integer NOT NULL,
    price_charged numeric(10,2) NOT NULL,
    created_by_id uuid,
    invoice_id bigint NOT NULL,
    product_id bigint NOT NULL,
    added_date date NOT NULL,
    CONSTRAINT invoices_invoiceproductline_quantity_check CHECK ((quantity >= 0))
);


--
-- Name: invoices_invoiceproductline_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invoices_invoiceproductline ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.invoices_invoiceproductline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices_invoiceserviceline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices_invoiceserviceline (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    price_charged numeric(10,2) NOT NULL,
    created_by_id uuid,
    invoice_id bigint NOT NULL,
    meter_entry_id bigint,
    service_id bigint NOT NULL,
    asset_used_id bigint,
    added_date date NOT NULL,
    product_price numeric(10,2) NOT NULL,
    product_used_id bigint
);


--
-- Name: invoices_invoiceserviceline_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invoices_invoiceserviceline ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.invoices_invoiceserviceline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: loans_loan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans_loan (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    lender_name character varying(150) NOT NULL,
    lender_type character varying(10) NOT NULL,
    loan_amount numeric(12,2) NOT NULL,
    deposit_amount numeric(12,2) NOT NULL,
    interest_amount numeric(12,2) NOT NULL,
    total_installments integer NOT NULL,
    installment_amount numeric(10,2) NOT NULL,
    installment_frequency character varying(10) NOT NULL,
    start_date date NOT NULL,
    created_by_id uuid,
    CONSTRAINT loans_loan_total_installments_check CHECK ((total_installments >= 0))
);


--
-- Name: loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.loans_loan ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.loans_loan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: loans_loaninstallmentpayment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans_loaninstallmentpayment (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    amount_paid numeric(10,2) NOT NULL,
    payment_date date NOT NULL,
    installment_number integer NOT NULL,
    created_by_id uuid,
    loan_id bigint NOT NULL,
    attachment character varying(100),
    CONSTRAINT loans_loaninstallmentpayment_installment_number_check CHECK ((installment_number >= 0))
);


--
-- Name: loans_loaninstallmentpayment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.loans_loaninstallmentpayment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.loans_loaninstallmentpayment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: meters_meter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meters_meter (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    brand character varying(100) NOT NULL,
    model character varying(100) NOT NULL,
    cc integer NOT NULL,
    memory_type character varying(10) NOT NULL,
    ic_mcu_model character varying(100) NOT NULL,
    sales_price numeric(10,2) NOT NULL,
    image character varying(100),
    created_by_id uuid,
    description text NOT NULL,
    CONSTRAINT meters_meter_cc_check CHECK ((cc >= 0))
);


--
-- Name: meters_meter_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.meters_meter ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.meters_meter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: meters_mileagecorrectiondevice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meters_mileagecorrectiondevice (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(100) NOT NULL,
    purchase_price numeric(10,2) NOT NULL,
    purchase_date date NOT NULL,
    memory_type_support character varying(10) NOT NULL,
    created_by_id uuid
);


--
-- Name: meters_mileagecorrectiondevice_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.meters_mileagecorrectiondevice ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.meters_mileagecorrectiondevice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notifications_notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications_notification (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    type character varying(30) NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    due_date date,
    is_read boolean NOT NULL,
    object_id character varying(64),
    content_type_id integer,
    created_by_id uuid
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notifications_notification ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products_product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_product (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(150) NOT NULL,
    sku character varying(50) NOT NULL,
    buy_price numeric(10,2) NOT NULL,
    sale_price numeric(10,2) NOT NULL,
    image character varying(100),
    current_stock_quantity integer NOT NULL,
    created_by_id uuid,
    supplier_id bigint NOT NULL,
    description text NOT NULL,
    CONSTRAINT products_product_current_stock_quantity_check CHECK ((current_stock_quantity >= 0))
);


--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.products_product ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.products_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products_productrestockevent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_productrestockevent (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    extra_costs numeric(10,2) NOT NULL,
    landed_unit_cost numeric(10,2) NOT NULL,
    total_cost numeric(12,2) NOT NULL,
    restocked_at timestamp with time zone NOT NULL,
    created_by_id uuid,
    product_id bigint NOT NULL,
    CONSTRAINT products_productrestockevent_quantity_check CHECK ((quantity >= 0))
);


--
-- Name: products_productrestockevent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.products_productrestockevent ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.products_productrestockevent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products_purchase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_purchase (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    purchase_date date NOT NULL,
    shared_extra_costs numeric(10,2) NOT NULL,
    note text NOT NULL,
    processed_at timestamp with time zone,
    created_by_id uuid,
    supplier_id bigint NOT NULL
);


--
-- Name: products_purchase_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.products_purchase ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.products_purchase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products_purchaselineitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_purchaselineitem (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    created_by_id uuid,
    product_id bigint NOT NULL,
    purchase_id bigint NOT NULL,
    CONSTRAINT products_purchaselineitem_quantity_check CHECK ((quantity >= 0))
);


--
-- Name: products_purchaselineitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.products_purchaselineitem ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.products_purchaselineitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: services_service; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services_service (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(150) NOT NULL,
    service_price numeric(10,2) NOT NULL,
    image character varying(100),
    description text NOT NULL,
    created_by_id uuid,
    category_id bigint NOT NULL
);


--
-- Name: services_service_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.services_service ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.services_service_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: services_servicecategory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services_servicecategory (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(30) NOT NULL,
    created_by_id uuid
);


--
-- Name: services_servicecategory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.services_servicecategory ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.services_servicecategory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shop_profile_shopprofile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_profile_shopprofile (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    shop_name character varying(150) NOT NULL,
    address text NOT NULL,
    phone character varying(20) NOT NULL,
    invoice_footer_text character varying(255) NOT NULL,
    created_by_id uuid
);


--
-- Name: shop_profile_shopprofile_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.shop_profile_shopprofile ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.shop_profile_shopprofile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suppliers_supplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers_supplier (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    address text NOT NULL,
    note text NOT NULL,
    created_by_id uuid
);


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.suppliers_supplier ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.suppliers_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: token_blacklist_blacklistedtoken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_blacklist_blacklistedtoken (
    id bigint NOT NULL,
    blacklisted_at timestamp with time zone NOT NULL,
    token_id bigint NOT NULL
);


--
-- Name: token_blacklist_blacklistedtoken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.token_blacklist_blacklistedtoken ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.token_blacklist_blacklistedtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: token_blacklist_outstandingtoken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_blacklist_outstandingtoken (
    id bigint NOT NULL,
    token text NOT NULL,
    created_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    user_id uuid,
    jti character varying(255) NOT NULL
);


--
-- Name: token_blacklist_outstandingtoken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.token_blacklist_outstandingtoken ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.token_blacklist_outstandingtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: account; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.account (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: invitation; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.invitation (id, "organizationId", email, role, status, "expiresAt", "createdAt", "inviterId") FROM stdin;
\.


--
-- Data for Name: jwks; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.jwks (id, "publicKey", "privateKey", "createdAt", "expiresAt") FROM stdin;
\.


--
-- Data for Name: member; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.member (id, "organizationId", "userId", role, "createdAt") FROM stdin;
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.organization (id, name, slug, logo, "createdAt", metadata) FROM stdin;
\.


--
-- Data for Name: project_config; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.project_config (id, name, endpoint_id, created_at, updated_at, trusted_origins, social_providers, email_provider, email_and_password, allow_localhost, plugin_configs, webhook_config) FROM stdin;
28eb0a30-b06d-461a-846f-66f368d96c60	bike_erp_db	ep-patient-dust-azbzcrni	2026-07-28 13:35:23.223+00	2026-07-28 13:35:23.223+00	[]	[{"id": "google", "isShared": true}]	{"type": "shared"}	{"enabled": true, "disableSignUp": false, "emailVerificationMethod": "otp", "requireEmailVerification": false, "autoSignInAfterVerification": true, "sendVerificationEmailOnSignIn": false, "sendVerificationEmailOnSignUp": false}	t	{"magicLink": {"config": {"expiresIn": 5, "disableSignUp": false}, "enabled": false}, "phoneNumber": {"config": {"otp_expires_in": 300}, "enabled": false}, "organization": {"config": {"creatorRole": "owner", "membershipLimit": 100, "organizationLimit": 10, "sendInvitationEmail": false}, "enabled": true}}	{"enabled": false, "enabledEvents": [], "timeoutSeconds": 5}
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.session (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId", "impersonatedBy", "activeOrganizationId") FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth."user" (id, name, email, "emailVerified", image, "createdAt", "updatedAt", role, banned, "banReason", "banExpires") FROM stdin;
\.


--
-- Data for Name: verification; Type: TABLE DATA; Schema: neon_auth; Owner: -
--

COPY neon_auth.verification (id, identifier, value, "expiresAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: accounts_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.accounts_user (password, last_login, is_superuser, id, name, email, phone, role, is_active, is_staff, created_at, updated_at, is_deleted, deleted_at, created_by_id) FROM stdin;
pbkdf2_sha256$1200000$zQN1BDLYm5APCyL6fdHt7E$nAdGbKLFFuv8ttyiPHy/Dh/6LCHDi9xtmqMHjwd/Vj8=	\N	t	3043b9d3-e73d-40b5-8a84-ec4fc263398a	QA Verify	qa_verify@test.local	\N	staff	f	t	2026-07-27 16:11:00.289727+00	2026-07-27 16:11:01.108518+00	t	2026-07-27 16:17:43.731095+00	\N
pbkdf2_sha256$1200000$9O2sCxFZ8luBzvMDx1IqRn$KsGvbFHZ+cKKTD7FKE+2mLHpp8CtW4lXrx4yCtXCEk8=	\N	t	c9af5589-7d4d-4a4b-b306-82621f9858f3	QA Verify 2	qa_verify2@test.local	\N	staff	f	t	2026-07-27 17:07:03.304663+00	2026-07-27 17:07:04.055513+00	t	2026-07-27 17:15:45.068056+00	\N
pbkdf2_sha256$1200000$lQKFDIhpWifrBzdoTEUuXM$VgYs2tu+LlFgVP8he7fcmTjiqHE94c6A06QOI9HpVGQ=	2026-07-31 14:29:06.809435+00	t	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	wahednur@gmail.com	01917839303	admin	t	t	2026-07-23 09:26:56.534829+00	2026-07-23 12:52:36.220204+00	f	\N	\N
pbkdf2_sha256$1200000$pgIlWND8mIc4PflGd4LBl1$mlo8V7QqA7Odv3BKNjnsJzl59Zu4tGc3tM3gs7/SU6Y=	\N	f	f403c6e3-a6ab-46db-b10a-f7f87b941fce	Sadika Sabrin	\N	01306788267	staff	t	f	2026-07-31 14:30:21.689845+00	2026-07-31 14:30:21.689854+00	f	\N	\N
\.


--
-- Data for Name: accounts_user_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.accounts_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: accounts_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.accounts_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: assets_asset; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assets_asset (id, created_at, updated_at, is_deleted, deleted_at, name, purchase_price, purchase_date, has_warranty, warranty_note, created_by_id, supplier_id, description) FROM stdin;
1	2026-07-26 09:27:13.493495+00	2026-07-26 09:27:13.493521+00	f	\N	Display	3200.00	2026-07-26	f		9a259d21-6303-464d-97fe-23a835dfdc29	1	ডিসকভার      6*220=1320\nFz v2.            2*220=440\nFz v3.             2*320=640\nMonoton.        2*320=640\nDelivery charge 200
2	2026-08-09 15:33:46.506176+00	2026-08-09 15:35:23.394733+00	f	\N	Display	2130.00	2026-08-09	f		9a259d21-6303-464d-97fe-23a835dfdc29	1	Monoton 2pcs, Glamor 2pcs, Glamore rabur 3pcs, Pulsar ug5 display 2pcs
3	2026-08-09 15:36:13.824138+00	2026-08-09 15:36:13.82415+00	f	\N	SF FI ABS Meter Half Meter	2590.00	2026-08-09	f		9a259d21-6303-464d-97fe-23a835dfdc29	1	SF FI ABS Meter Half Meter
\.


--
-- Data for Name: assets_assetincident; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assets_assetincident (id, created_at, updated_at, is_deleted, deleted_at, type, cost, date, note, asset_id, created_by_id) FROM stdin;
\.


--
-- Data for Name: audit_auditlog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_auditlog (id, created_at, updated_at, is_deleted, deleted_at, object_id, object_repr, action, changed_fields, content_type_id, created_by_id) FROM stdin;
1	2026-07-23 09:26:08.5616+00	2026-07-23 09:26:08.561612+00	f	\N	1	MileageCorrectionDevice object (1)	CREATE	[]	1	\N
2	2026-07-23 09:26:08.567751+00	2026-07-23 09:26:08.567762+00	f	\N	2	MileageCorrectionDevice object (2)	CREATE	[]	1	\N
3	2026-07-23 09:26:08.571194+00	2026-07-23 09:26:08.571209+00	f	\N	3	MileageCorrectionDevice object (3)	CREATE	[]	1	\N
4	2026-07-23 09:26:08.574186+00	2026-07-23 09:26:08.574197+00	f	\N	4	MileageCorrectionDevice object (4)	CREATE	[]	1	\N
5	2026-07-23 09:26:56.54402+00	2026-07-23 09:26:56.544031+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	CREATE	[]	9	\N
6	2026-07-23 09:29:18.274241+00	2026-07-23 09:29:18.274257+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	UPDATE	["last_login"]	9	9a259d21-6303-464d-97fe-23a835dfdc29
7	2026-07-23 09:29:52.281985+00	2026-07-23 09:29:52.282009+00	f	\N	1	Ali Akbar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
8	2026-07-23 09:29:52.28777+00	2026-07-23 09:29:52.287785+00	f	\N	2	Arun Sarkar Nagla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
9	2026-07-23 09:29:52.292064+00	2026-07-23 09:29:52.292083+00	f	\N	3	Mym Ashadul	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
10	2026-07-23 09:29:52.299426+00	2026-07-23 09:29:52.299448+00	f	\N	4	Taju islam	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
11	2026-07-23 09:29:52.304082+00	2026-07-23 09:29:52.304094+00	f	\N	5	Shuhag Mymensing	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
12	2026-07-23 09:29:52.308484+00	2026-07-23 09:29:52.308504+00	f	\N	6	Helal Jograrchar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
13	2026-07-23 09:29:52.314284+00	2026-07-23 09:29:52.314305+00	f	\N	7	Akram Hossain Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
14	2026-07-23 09:29:52.319307+00	2026-07-23 09:29:52.319348+00	f	\N	8	Liton khurshed	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
15	2026-07-23 09:29:52.323846+00	2026-07-23 09:29:52.323864+00	f	\N	9	Sudip Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
16	2026-07-23 09:29:52.327941+00	2026-07-23 09:29:52.327967+00	f	\N	10	Shipon - Bottola	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
17	2026-07-23 09:29:52.333264+00	2026-07-23 09:29:52.333285+00	f	\N	11	Kamrul Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
18	2026-07-23 09:29:52.337515+00	2026-07-23 09:29:52.337534+00	f	\N	12	Akash Jinaighati	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
19	2026-07-23 09:29:52.341706+00	2026-07-23 09:29:52.341729+00	f	\N	13	Azad Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
20	2026-07-23 09:29:52.346522+00	2026-07-23 09:29:52.346533+00	f	\N	14	Ikbal Maker- modhupur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
21	2026-07-23 09:29:52.351849+00	2026-07-23 09:29:52.351869+00	f	\N	15	Shuhag Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
22	2026-07-23 09:29:52.356125+00	2026-07-23 09:29:52.356149+00	f	\N	16	Komol Mia Kalitola	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
23	2026-07-23 09:29:52.360135+00	2026-07-23 09:29:52.360156+00	f	\N	17	Babul Dhubaura	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
24	2026-07-23 09:29:52.36423+00	2026-07-23 09:29:52.364246+00	f	\N	18	Kamruzzaman Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
25	2026-07-23 09:29:52.368204+00	2026-07-23 09:29:52.368227+00	f	\N	19	DB Zafor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
26	2026-07-23 09:29:52.371736+00	2026-07-23 09:29:52.371755+00	f	\N	20	Zafor bottola	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
27	2026-07-23 09:29:52.375154+00	2026-07-23 09:29:52.375175+00	f	\N	21	Aminul kamarerchar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
28	2026-07-23 09:29:52.379223+00	2026-07-23 09:29:52.379242+00	f	\N	22	Marfot Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
29	2026-07-23 09:29:52.382606+00	2026-07-23 09:29:52.38262+00	f	\N	23	Razzk Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
30	2026-07-23 09:29:52.386329+00	2026-07-23 09:29:52.386349+00	f	\N	24	Rafique khusumhati	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
31	2026-07-23 09:29:52.39023+00	2026-07-23 09:29:52.390248+00	f	\N	25	Ujjal 2 buira Jograrchar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
32	2026-07-23 09:29:52.394293+00	2026-07-23 09:29:52.394312+00	f	\N	26	Sha Ali Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
33	2026-07-23 09:29:52.397602+00	2026-07-23 09:29:52.397615+00	f	\N	27	Shohag Nanni	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
34	2026-07-23 09:29:52.401165+00	2026-07-23 09:29:52.401187+00	f	\N	28	Manik Khuarpar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
35	2026-07-23 09:29:52.404376+00	2026-07-23 09:29:52.404388+00	f	\N	29	Khaled Mahmud Nagpara	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
36	2026-07-23 09:29:52.4093+00	2026-07-23 09:29:52.409334+00	f	\N	30	Rafiqul Islam Sreeboddi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
37	2026-07-23 09:29:52.412517+00	2026-07-23 09:29:52.412531+00	f	\N	31	Unknown	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
38	2026-07-23 09:29:52.415908+00	2026-07-23 09:29:52.415927+00	f	\N	32	Delwar haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
39	2026-07-23 09:29:52.419393+00	2026-07-23 09:29:52.419406+00	f	\N	33	Mofizul Nagla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
40	2026-07-23 09:29:52.422815+00	2026-07-23 09:29:52.422834+00	f	\N	34	Mazharul Modina Nagla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
41	2026-07-23 09:29:52.426021+00	2026-07-23 09:29:52.426031+00	f	\N	35	Ershad - Fulpur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
42	2026-07-23 09:29:52.42927+00	2026-07-23 09:29:52.429293+00	f	\N	36	Khursher - Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
43	2026-07-23 09:29:52.432879+00	2026-07-23 09:29:52.432894+00	f	\N	37	Abul Khayer - Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
44	2026-07-23 09:29:52.436202+00	2026-07-23 09:29:52.436216+00	f	\N	38	Mizan Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
45	2026-07-23 09:29:52.439572+00	2026-07-23 09:29:52.439594+00	f	\N	39	Mustafiz	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
46	2026-07-23 09:29:52.442867+00	2026-07-23 09:29:52.442882+00	f	\N	40	Haider- Kamarchar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
47	2026-07-23 09:29:52.446189+00	2026-07-23 09:29:52.446203+00	f	\N	41	Jibon Batta	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
48	2026-07-23 09:29:52.449729+00	2026-07-23 09:29:52.449743+00	f	\N	42	Hanif Mymensingh	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
49	2026-07-23 09:29:52.453062+00	2026-07-23 09:29:52.453076+00	f	\N	43	Akij- Panir tank	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
50	2026-07-23 09:29:52.456429+00	2026-07-23 09:29:52.456442+00	f	\N	44	Tutul Kamarerchol	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
51	2026-07-23 09:29:52.461136+00	2026-07-23 09:29:52.46115+00	f	\N	45	Rabbi Haque	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
52	2026-07-23 09:29:52.464358+00	2026-07-23 09:29:52.464385+00	f	\N	46	Babul Nakla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
53	2026-07-23 09:29:52.467685+00	2026-07-23 09:29:52.467698+00	f	\N	47	Pappu - Mirgong	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
54	2026-07-23 09:29:52.47094+00	2026-07-23 09:29:52.470958+00	f	\N	48	Likhon Nakla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
55	2026-07-23 09:29:52.474266+00	2026-07-23 09:29:52.474287+00	f	\N	49	Sabbir Shamvuganj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
56	2026-07-23 09:29:52.477816+00	2026-07-23 09:29:52.477835+00	f	\N	50	Shamim Fulpur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
57	2026-07-23 09:29:52.481095+00	2026-07-23 09:29:52.481123+00	f	\N	51	Shohag Fulpur Baliamore	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
58	2026-07-23 09:29:52.484336+00	2026-07-23 09:29:52.484351+00	f	\N	52	Raju Palli biddot	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
59	2026-07-23 09:29:52.48848+00	2026-07-23 09:29:52.488493+00	f	\N	53	Farukh khuyarpar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
60	2026-07-23 09:29:52.492648+00	2026-07-23 09:29:52.492666+00	f	\N	54	Azizul Nakla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
61	2026-07-23 09:29:52.496078+00	2026-07-23 09:29:52.4961+00	f	\N	55	Hannan Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
62	2026-07-23 09:29:52.500449+00	2026-07-23 09:29:52.500471+00	f	\N	56	Hasem Bolayerchor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
63	2026-07-23 09:29:52.505018+00	2026-07-23 09:29:52.505032+00	f	\N	57	Mym Shofiqul	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
64	2026-07-23 09:29:52.508457+00	2026-07-23 09:29:52.508473+00	f	\N	58	Sapan Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
65	2026-07-23 09:29:52.512267+00	2026-07-23 09:29:52.512286+00	f	\N	59	Rubel Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
66	2026-07-23 09:29:52.517077+00	2026-07-23 09:29:52.51709+00	f	\N	60	Naim hasan Bakshiganj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
67	2026-07-23 09:29:52.520416+00	2026-07-23 09:29:52.520441+00	f	\N	61	Ornob Nakla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
68	2026-07-23 09:29:52.523761+00	2026-07-23 09:29:52.523779+00	f	\N	62	Selim Shreboddi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
69	2026-07-23 09:29:52.52735+00	2026-07-23 09:29:52.527363+00	f	\N	63	Shimul Taratia	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
70	2026-07-23 09:29:52.530539+00	2026-07-23 09:29:52.530561+00	f	\N	64	Kawsar Suzuki Service center	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
71	2026-07-23 09:29:52.535541+00	2026-07-23 09:29:52.535555+00	f	\N	65	Babu Khuarpar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
72	2026-07-23 09:29:52.539059+00	2026-07-23 09:29:52.539084+00	f	\N	66	Kajol - Sribordi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
73	2026-07-23 09:29:52.542958+00	2026-07-23 09:29:52.542978+00	f	\N	67	Lokmkman vimgonj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
74	2026-07-23 09:29:52.546581+00	2026-07-23 09:29:52.546602+00	f	\N	68	Shohidul Shreepoddi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
75	2026-07-23 09:29:52.550066+00	2026-07-23 09:29:52.550085+00	f	\N	69	Hannan Haluagat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
76	2026-07-23 09:29:52.55379+00	2026-07-23 09:29:52.553811+00	f	\N	70	Al Amin Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
77	2026-07-23 09:29:52.557271+00	2026-07-23 09:29:52.557285+00	f	\N	71	Shohag Fulpur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
78	2026-07-23 09:29:52.561531+00	2026-07-23 09:29:52.561556+00	f	\N	72	Suman Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
79	2026-07-23 09:29:52.566171+00	2026-07-23 09:29:52.566183+00	f	\N	73	Ibrahim master Jinaigati	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
80	2026-07-23 09:29:52.570537+00	2026-07-23 09:29:52.570557+00	f	\N	74	Rezaul karim Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
81	2026-07-23 09:29:52.575089+00	2026-07-23 09:29:52.575109+00	f	\N	75	Atik Jograrchor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
82	2026-07-23 09:29:52.578527+00	2026-07-23 09:29:52.578548+00	f	\N	76	Hasan Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
83	2026-07-23 09:29:52.582811+00	2026-07-23 09:29:52.582836+00	f	\N	77	Shohel Jangaldi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
84	2026-07-23 09:29:52.586545+00	2026-07-23 09:29:52.586579+00	f	\N	78	Minal Ostimtola	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
85	2026-07-23 09:29:52.589742+00	2026-07-23 09:29:52.589758+00	f	\N	79	Suman Nalitabari	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
86	2026-07-23 09:29:52.593251+00	2026-07-23 09:29:52.593271+00	f	\N	80	Rafiq vai	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
87	2026-07-23 09:29:52.596711+00	2026-07-23 09:29:52.596728+00	f	\N	81	Arif Thanar gate	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
88	2026-07-23 09:29:52.60005+00	2026-07-23 09:29:52.600071+00	f	\N	82	#N/A	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
89	2026-07-23 09:29:52.603354+00	2026-07-23 09:29:52.603367+00	f	\N	83	Azad Jhenaigati	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
90	2026-07-23 09:29:52.607578+00	2026-07-23 09:29:52.607589+00	f	\N	84	Ujjal Jograrchor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
91	2026-07-23 09:29:52.610828+00	2026-07-23 09:29:52.610846+00	f	\N	85	Imran bhai Bottola	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
92	2026-07-23 09:29:52.614719+00	2026-07-23 09:29:52.614736+00	f	\N	86	Monu Kamarer Char	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
93	2026-07-23 09:29:52.618176+00	2026-07-23 09:29:52.6182+00	f	\N	87	Emon Pinter	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
94	2026-07-23 09:29:52.621983+00	2026-07-23 09:29:52.621999+00	f	\N	88	Anwar-Nagla	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
95	2026-07-23 09:29:52.62535+00	2026-07-23 09:29:52.625368+00	f	\N	89	Gulap Hossain Islampur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
96	2026-07-23 09:29:52.628546+00	2026-07-23 09:29:52.628577+00	f	\N	90	Manik	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
97	2026-07-23 09:29:52.632622+00	2026-07-23 09:29:52.632636+00	f	\N	91	Shahadat Bajitkhila	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
98	2026-07-23 09:29:52.636029+00	2026-07-23 09:29:52.636051+00	f	\N	92	Sapan Motors	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
99	2026-07-23 09:29:52.640224+00	2026-07-23 09:29:52.640245+00	f	\N	93	Atik Bakshigonj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
100	2026-07-23 09:29:52.644708+00	2026-07-23 09:29:52.644721+00	f	\N	94	Alkas Ali	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
101	2026-07-23 09:29:52.648064+00	2026-07-23 09:29:52.648078+00	f	\N	95	Sadu	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
102	2026-07-23 09:29:52.65138+00	2026-07-23 09:29:52.651393+00	f	\N	96	Piyas Bajaj Kharompur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
103	2026-07-23 09:29:52.656076+00	2026-07-23 09:29:52.656099+00	f	\N	97	Babu Chaudhuri	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
104	2026-07-23 09:29:52.659442+00	2026-07-23 09:29:52.659459+00	f	\N	98	Jewel Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
105	2026-07-23 09:29:52.663901+00	2026-07-23 09:29:52.663916+00	f	\N	99	Rocky	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
106	2026-07-23 09:29:52.667167+00	2026-07-23 09:29:52.667185+00	f	\N	100	Billal Taratia	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
107	2026-07-23 09:29:52.670963+00	2026-07-23 09:29:52.670975+00	f	\N	101	Goutom Haluaghat	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
108	2026-07-23 09:29:52.674792+00	2026-07-23 09:29:52.674807+00	f	\N	102	Based Bokshigonj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
109	2026-07-23 09:29:52.679568+00	2026-07-23 09:29:52.679592+00	f	\N	103	Liton Thana	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
110	2026-07-23 09:29:52.683316+00	2026-07-23 09:29:52.683338+00	f	\N	104	Shohidul Joghrarchor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
111	2026-07-23 09:29:52.686643+00	2026-07-23 09:29:52.686661+00	f	\N	105	Labu Thanar	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
112	2026-07-23 09:29:52.689945+00	2026-07-23 09:29:52.68996+00	f	\N	106	Lockman Vai	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
113	2026-07-23 09:29:52.693131+00	2026-07-23 09:29:52.693148+00	f	\N	107	Sobuj Joghrarchor	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
114	2026-07-23 09:29:52.696562+00	2026-07-23 09:29:52.696578+00	f	\N	108	Hasan Khrompur	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
115	2026-07-23 09:31:41.178746+00	2026-07-23 09:31:41.178757+00	f	\N	1	Bajaj Discover 5Gear 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
116	2026-07-23 09:32:16.685116+00	2026-07-23 09:32:16.685133+00	f	\N	2	Bajaj Discover 4Gear 110cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
117	2026-07-23 09:32:58.814341+00	2026-07-23 09:32:58.814353+00	f	\N	3	Bajaj Discover CBS 110cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
118	2026-07-23 09:33:47.648447+00	2026-07-23 09:33:47.648467+00	f	\N	4	Bajaj Discover V18 110cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
119	2026-07-23 09:34:00.414038+00	2026-07-23 09:34:00.414063+00	f	\N	2	Bajaj Discover 4Gear 110cc	UPDATE	["memory_type"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
120	2026-07-23 09:34:18.656355+00	2026-07-23 09:34:18.656374+00	f	\N	4	Bajaj Discover V18 110cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
121	2026-07-23 09:42:00.890829+00	2026-07-23 09:42:00.890841+00	f	\N	5	Bajaj Pulsar 8F(UG3-UG5) 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
122	2026-07-23 09:42:51.230056+00	2026-07-23 09:42:51.230076+00	f	\N	6	Bajaj Pulsar 4F 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
123	2026-07-23 09:52:21.288312+00	2026-07-23 09:52:21.288346+00	f	\N	7	Bajaj Pulsar ABS 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
124	2026-07-23 09:58:28.338934+00	2026-07-23 09:58:28.338946+00	f	\N	8	Bajaj Pulsar Double ABS 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
125	2026-07-23 10:00:23.003174+00	2026-07-23 10:00:23.003201+00	f	\N	1	Mileage Correction	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
126	2026-07-23 10:00:37.270986+00	2026-07-23 10:00:37.271005+00	f	\N	2	Meter Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
127	2026-07-23 10:00:44.003948+00	2026-07-23 10:00:44.00396+00	f	\N	3	Display Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
128	2026-07-23 10:00:52.533224+00	2026-07-23 10:00:52.533249+00	f	\N	4	Main Board Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
129	2026-07-23 10:00:57.985747+00	2026-07-23 10:00:57.985772+00	f	\N	5	Light Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
130	2026-07-23 10:01:02.009415+00	2026-07-23 10:01:02.00944+00	f	\N	6	Kilometer Freeze Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
131	2026-07-23 10:01:06.601725+00	2026-07-23 10:01:06.601755+00	f	\N	7	Power Problem Repair	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
132	2026-07-23 10:01:12.710587+00	2026-07-23 10:01:12.710599+00	f	\N	8	Others	CREATE	[]	14	9a259d21-6303-464d-97fe-23a835dfdc29
133	2026-07-23 10:04:02.678229+00	2026-07-23 10:04:02.67825+00	f	\N	1	Pridim Foundation (NGO)	CREATE	[]	26	9a259d21-6303-464d-97fe-23a835dfdc29
134	2026-07-23 10:04:27.985278+00	2026-07-23 10:04:27.985299+00	f	\N	1	Installment #1 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
135	2026-07-23 10:04:54.466048+00	2026-07-23 10:04:54.46607+00	f	\N	2	Installment #2 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
136	2026-07-23 10:05:18.649204+00	2026-07-23 10:05:18.649225+00	f	\N	3	Installment #3 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
137	2026-07-23 10:11:44.481259+00	2026-07-23 10:11:44.481278+00	f	\N	9	Bajaj Pulsar Single Disk Double ABS 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
138	2026-07-23 10:12:09.547802+00	2026-07-23 10:12:09.547824+00	f	\N	9	Bajaj Pulsar Single Disk Double ABS 150cc	UPDATE	["ic_mcu_model", "image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
139	2026-07-23 10:12:25.146004+00	2026-07-23 10:12:25.146039+00	f	\N	8	Bajaj Pulsar Double ABS 150cc	UPDATE	["ic_mcu_model"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
140	2026-07-23 10:13:01.869288+00	2026-07-23 10:13:01.869302+00	f	\N	4	Bajaj Discover V18 110cc	UPDATE	["ic_mcu_model"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
141	2026-07-23 10:14:27.993505+00	2026-07-23 10:14:27.993564+00	f	\N	10	Gixxer Monotone 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
142	2026-07-23 10:17:22.987335+00	2026-07-23 10:17:22.987366+00	f	\N	11	Gixxer SF A1 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
143	2026-07-23 10:18:23.889676+00	2026-07-23 10:18:23.889698+00	f	\N	12	Gixxer SF A2 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
144	2026-07-23 10:19:46.866899+00	2026-07-23 10:19:46.866918+00	f	\N	13	Gixxer SF A3 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
145	2026-07-23 10:20:29.293586+00	2026-07-23 10:20:29.293642+00	f	\N	14	Gixxer SF A5 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
146	2026-07-23 10:20:59.489944+00	2026-07-23 10:20:59.489983+00	f	\N	15	Gixxer SF A6 155cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
147	2026-07-23 10:26:17.986369+00	2026-07-23 10:26:17.986383+00	f	\N	16	Yamaha FZ V1 153cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
148	2026-07-23 10:29:55.619237+00	2026-07-23 10:29:55.619278+00	f	\N	17	Yamaha FZ V2 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
149	2026-07-23 10:33:33.696125+00	2026-07-23 10:33:33.696177+00	f	\N	18	Yamaha FZ V3 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
150	2026-07-23 10:34:34.973163+00	2026-07-23 10:34:34.973174+00	f	\N	19	Yamaha FZS 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
151	2026-07-23 10:36:50.526654+00	2026-07-23 10:36:50.526676+00	f	\N	20	Yamaha FZX 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
152	2026-07-23 12:52:36.222036+00	2026-07-23 12:52:36.222061+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	UPDATE	["phone"]	9	9a259d21-6303-464d-97fe-23a835dfdc29
153	2026-07-23 12:55:09.831636+00	2026-07-23 12:55:09.831678+00	f	\N	109	Usman Bakshiganj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
154	2026-07-23 12:55:27.230443+00	2026-07-23 12:55:27.230478+00	f	\N	1	INV-2026-00001	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
155	2026-07-23 12:57:29.050153+00	2026-07-23 12:57:29.050169+00	f	\N	1	Mileage Correction	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
156	2026-07-23 12:58:50.023507+00	2026-07-23 12:58:50.023521+00	f	\N	1	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00001	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
157	2026-07-23 12:58:50.038328+00	2026-07-23 12:58:50.038344+00	f	\N	1	Mileage Correction on INV-2026-00001	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
158	2026-07-23 12:58:50.057616+00	2026-07-23 12:58:50.057632+00	f	\N	1	INV-2026-00001	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
159	2026-07-23 12:58:59.757195+00	2026-07-23 12:58:59.757214+00	f	\N	1	400.00 on INV-2026-00001	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
160	2026-07-23 12:58:59.780576+00	2026-07-23 12:58:59.780591+00	f	\N	1	INV-2026-00001	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
161	2026-07-23 12:58:59.805269+00	2026-07-23 12:58:59.80528+00	f	\N	1	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00001	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
162	2026-07-23 13:00:22.719826+00	2026-07-23 13:00:22.719842+00	f	\N	110	Nur Islam	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
163	2026-07-23 13:00:34.76205+00	2026-07-23 13:00:34.762075+00	f	\N	2	INV-2026-00002	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
164	2026-07-23 13:01:16.261001+00	2026-07-23 13:01:16.261025+00	f	\N	2	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00002	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
165	2026-07-23 13:01:16.269768+00	2026-07-23 13:01:16.269795+00	f	\N	2	Mileage Correction on INV-2026-00002	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
166	2026-07-23 13:01:16.291033+00	2026-07-23 13:01:16.291052+00	f	\N	2	INV-2026-00002	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
167	2026-07-23 13:01:34.191328+00	2026-07-23 13:01:34.191348+00	f	\N	2	Mileage Correction on INV-2026-00002	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
168	2026-07-23 13:01:34.220492+00	2026-07-23 13:01:34.220516+00	f	\N	2	INV-2026-00002	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
169	2026-07-23 13:01:54.723573+00	2026-07-23 13:01:54.723584+00	f	\N	2	500.00 on INV-2026-00002	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
170	2026-07-23 13:01:54.749982+00	2026-07-23 13:01:54.750002+00	f	\N	2	INV-2026-00002	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
171	2026-07-23 13:01:54.769694+00	2026-07-23 13:01:54.769709+00	f	\N	2	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00002	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
172	2026-07-23 13:07:15.44089+00	2026-07-23 13:07:15.440909+00	f	\N	111	Bijoy	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
173	2026-07-23 13:07:30.609645+00	2026-07-23 13:07:30.609657+00	f	\N	3	INV-2026-00003	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
174	2026-07-23 13:07:40.863104+00	2026-07-23 13:07:40.863117+00	f	\N	3	INV-2026-00003	UPDATE	["created_date"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
175	2026-07-23 13:08:23.323969+00	2026-07-23 13:08:23.32401+00	f	\N	3	Gixxer Monotone 155cc (serial None) on INV-2026-00003	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
176	2026-07-23 13:08:23.332346+00	2026-07-23 13:08:23.332414+00	f	\N	3	Mileage Correction on INV-2026-00003	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
177	2026-07-23 13:08:23.362274+00	2026-07-23 13:08:23.362305+00	f	\N	3	INV-2026-00003	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
178	2026-07-24 05:47:13.384176+00	2026-07-24 05:47:13.384195+00	f	\N	4	INV-2026-00004	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
179	2026-07-24 05:49:04.230783+00	2026-07-24 05:49:04.230836+00	f	\N	4	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00004	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
180	2026-07-24 05:49:04.256063+00	2026-07-24 05:49:04.256086+00	f	\N	4	Mileage Correction on INV-2026-00004	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
181	2026-07-24 05:49:04.305608+00	2026-07-24 05:49:04.305631+00	f	\N	4	INV-2026-00004	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
182	2026-07-24 05:49:12.160722+00	2026-07-24 05:49:12.160783+00	f	\N	3	400.00 on INV-2026-00004	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
183	2026-07-24 05:49:12.220864+00	2026-07-24 05:49:12.220924+00	f	\N	4	INV-2026-00004	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
184	2026-07-24 05:49:12.311786+00	2026-07-24 05:49:12.311936+00	f	\N	4	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00004	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
185	2026-07-24 06:32:49.407944+00	2026-07-24 06:32:49.407985+00	f	\N	2	Pulsar Polarize Paper Replace	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
186	2026-07-24 06:35:04.178466+00	2026-07-24 06:35:04.178494+00	f	\N	1	Meter Expert BD	CREATE	[]	11	9a259d21-6303-464d-97fe-23a835dfdc29
187	2026-07-24 06:35:26.845499+00	2026-07-24 06:35:26.845538+00	f	\N	2	Local	CREATE	[]	11	9a259d21-6303-464d-97fe-23a835dfdc29
188	2026-07-24 06:37:36.22968+00	2026-07-24 06:37:36.229703+00	f	\N	1	Pulsar Polarized Paper (PP-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
189	2026-07-24 06:38:32.952673+00	2026-07-24 06:38:32.952695+00	f	\N	1	Pulsar Polarized Paper (PP-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
190	2026-07-24 06:38:32.972508+00	2026-07-24 06:38:32.972534+00	f	\N	1	10 x Pulsar Polarized Paper on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
191	2026-07-24 06:43:29.811609+00	2026-07-24 06:43:29.811645+00	f	\N	3	Display Replace	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
192	2026-07-24 06:44:12.904894+00	2026-07-24 06:44:12.904997+00	f	\N	4	Display Repair	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
193	2026-07-24 06:45:57.569186+00	2026-07-24 06:45:57.569211+00	f	\N	5	Light Replace	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
194	2026-07-24 06:47:28.323712+00	2026-07-24 06:47:28.323736+00	f	\N	6	Kilometer Freeze Repair	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
195	2026-07-24 07:37:11.867063+00	2026-07-24 07:37:11.867074+00	f	\N	0effd36d-e464-49f7-a774-09cd58002dbb	Temp Preview	CREATE	[]	9	\N
196	2026-07-24 07:37:12.507503+00	2026-07-24 07:37:12.507516+00	f	\N	0effd36d-e464-49f7-a774-09cd58002dbb	Temp Preview	UPDATE	["password", "is_superuser", "is_staff"]	9	\N
197	2026-07-24 07:38:35.544296+00	2026-07-24 07:38:35.544313+00	f	\N	0effd36d-e464-49f7-a774-09cd58002dbb	Temp Preview	DELETE	[]	9	\N
198	2026-07-24 07:56:18.187113+00	2026-07-24 07:56:18.187138+00	f	\N	6843735a-3ad2-466d-ad60-81a2d4643362	Temp Preview	CREATE	[]	9	\N
199	2026-07-24 07:56:19.193008+00	2026-07-24 07:56:19.193032+00	f	\N	6843735a-3ad2-466d-ad60-81a2d4643362	Temp Preview	UPDATE	["password", "is_superuser", "is_staff"]	9	\N
200	2026-07-24 07:57:51.38527+00	2026-07-24 07:57:51.385291+00	f	\N	2	Pulsar Display UG4 (LPDUG4-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
201	2026-07-24 07:58:28.933271+00	2026-07-24 07:58:28.933286+00	f	\N	6843735a-3ad2-466d-ad60-81a2d4643362	Temp Preview	DELETE	[]	9	\N
202	2026-07-24 07:58:28.958649+00	2026-07-24 07:58:28.95867+00	f	\N	2	Pulsar Display UG4 (LPDUG4-01)	DELETE	[]	15	\N
203	2026-07-24 08:19:02.321087+00	2026-07-24 08:19:02.321114+00	f	\N	bf528851-cdf8-49a4-84eb-17180b614df1	Temp Preview	CREATE	[]	9	\N
204	2026-07-24 08:19:03.21238+00	2026-07-24 08:19:03.212391+00	f	\N	bf528851-cdf8-49a4-84eb-17180b614df1	Temp Preview	UPDATE	["password", "is_superuser", "is_staff"]	9	\N
205	2026-07-24 08:21:25.850136+00	2026-07-24 08:21:25.850155+00	f	\N	bf528851-cdf8-49a4-84eb-17180b614df1	Temp Preview	DELETE	[]	9	\N
206	2026-07-24 08:48:27.636145+00	2026-07-24 08:48:27.636161+00	f	\N	3	RTR Display All V (MERDAV-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
207	2026-07-24 08:48:56.313868+00	2026-07-24 08:48:56.31388+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
208	2026-07-24 08:48:56.324986+00	2026-07-24 08:48:56.324997+00	f	\N	2	4 x RTR Display All V on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
209	2026-07-24 08:55:07.068429+00	2026-07-24 08:55:07.068447+00	f	\N	4	Gixxer SF Display (MEGSFDi01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
210	2026-07-24 08:55:47.039418+00	2026-07-24 08:55:47.039443+00	f	\N	4	Gixxer SF Display (MEGSFDi01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
211	2026-07-24 08:55:47.057756+00	2026-07-24 08:55:47.057767+00	f	\N	3	4 x Gixxer SF Display on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
212	2026-07-24 09:19:38.362321+00	2026-07-24 09:19:38.362333+00	f	\N	5	White LED 3228 (MEWL3228-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
213	2026-07-24 09:20:15.313107+00	2026-07-24 09:20:15.313122+00	f	\N	5	White LED 3228 (MEWL3228-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
214	2026-07-24 09:20:15.326743+00	2026-07-24 09:20:15.326764+00	f	\N	4	90 x White LED 3228 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
215	2026-07-24 09:21:23.152277+00	2026-07-24 09:21:23.152288+00	f	\N	5	White LED 3528 (MEWL3528-01)	UPDATE	["name", "sku"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
216	2026-07-24 09:22:52.151919+00	2026-07-24 09:22:52.151931+00	f	\N	6	Green LED 3528 (MEGL3528-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
217	2026-07-24 09:23:27.781737+00	2026-07-24 09:23:27.781754+00	f	\N	6	Green LED 3528 (MEGL3528-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
218	2026-07-24 09:23:27.789649+00	2026-07-24 09:23:27.78967+00	f	\N	5	45 x Green LED 3528 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
219	2026-07-24 09:24:44.903948+00	2026-07-24 09:24:44.903966+00	f	\N	7	Blue LED 3528 (MEBL3528-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
220	2026-07-24 09:25:03.224087+00	2026-07-24 09:25:03.224128+00	f	\N	7	Blue LED 3528 (MEBL3528-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
221	2026-07-24 09:25:03.237458+00	2026-07-24 09:25:03.23748+00	f	\N	6	45 x Blue LED 3528 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
222	2026-07-24 09:26:34.197387+00	2026-07-24 09:26:34.197404+00	f	\N	8	Orange LED 3528 (MEOL3528-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
223	2026-07-24 09:26:55.05359+00	2026-07-24 09:26:55.053601+00	f	\N	8	Orange LED 3528 (MEOL3528-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
224	2026-07-24 09:26:55.060808+00	2026-07-24 09:26:55.060819+00	f	\N	7	45 x Orange LED 3528 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
225	2026-07-24 09:30:45.50521+00	2026-07-24 09:30:45.505221+00	f	\N	9	RED LED 3528 (MERL3528-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
226	2026-07-24 09:32:07.882833+00	2026-07-24 09:32:07.882844+00	f	\N	9	RED LED 3528 (MERL3528-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
227	2026-07-24 09:32:07.889659+00	2026-07-24 09:32:07.889669+00	f	\N	8	45 x RED LED 3528 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
228	2026-07-24 09:33:19.047301+00	2026-07-24 09:33:19.047313+00	f	\N	10	Yellow LED 3528 (MEYL3528-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
229	2026-07-24 09:33:36.5737+00	2026-07-24 09:33:36.573711+00	f	\N	10	Yellow LED 3528 (MEYL3528-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
230	2026-07-24 09:33:36.580849+00	2026-07-24 09:33:36.580879+00	f	\N	9	45 x Yellow LED 3528 on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
231	2026-07-24 09:36:28.163548+00	2026-07-24 09:36:28.163564+00	f	\N	11	Pulsar LED (MEPLED-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
232	2026-07-24 09:36:52.434434+00	2026-07-24 09:36:52.434444+00	f	\N	11	Pulsar LED (MEPLED-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
233	2026-07-24 09:36:52.440302+00	2026-07-24 09:36:52.440315+00	f	\N	10	45 x Pulsar LED on 2026-07-24	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
234	2026-07-24 12:42:18.418853+00	2026-07-24 12:42:18.418868+00	f	\N	82	#N/A	DELETE	["is_deleted", "deleted_at"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
235	2026-07-24 13:57:32.358212+00	2026-07-24 13:57:32.358223+00	f	\N	21	TVS Apache RTR 150 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
236	2026-07-24 13:57:57.213244+00	2026-07-24 13:57:57.21326+00	f	\N	21	TVS Apache RTR 150cc	UPDATE	["model"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
237	2026-07-24 13:58:24.214282+00	2026-07-24 13:58:24.214293+00	f	\N	22	TVS Apache RTR 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
238	2026-07-24 13:59:05.703253+00	2026-07-24 13:59:05.703264+00	f	\N	23	TVS Apache RTR Horse 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
239	2026-07-24 13:59:28.47448+00	2026-07-24 13:59:28.474495+00	f	\N	23	TVS Apache RTR Horse 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
240	2026-07-24 14:02:46.526783+00	2026-07-24 14:02:46.526796+00	f	\N	24	TVS Apache 4V X Connect 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
241	2026-07-24 14:03:39.177645+00	2026-07-24 14:03:39.177659+00	f	\N	25	TVS Apache 4V 1st 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
242	2026-07-24 14:03:57.644295+00	2026-07-24 14:03:57.644325+00	f	\N	24	TVS Apache 4V X Connect 160cc	UPDATE	["memory_type"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
243	2026-07-24 14:05:08.991282+00	2026-07-24 14:05:08.991293+00	f	\N	26	TVS Apache 4V 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
244	2026-07-24 14:08:34.316064+00	2026-07-24 14:08:34.316085+00	f	\N	27	Honda SP shine 100cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
245	2026-07-24 14:09:49.368347+00	2026-07-24 14:09:49.368371+00	f	\N	28	Honda Livo 110cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
246	2026-07-24 14:12:41.352907+00	2026-07-24 14:12:41.35294+00	f	\N	29	Hero Hunk 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
247	2026-07-24 14:15:28.737533+00	2026-07-24 14:15:28.737544+00	f	\N	30	Bajaj Pulsar 135cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
248	2026-07-24 14:17:40.905727+00	2026-07-24 14:17:40.905739+00	f	\N	31	Hero Ignitor 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
249	2026-07-24 14:21:13.158382+00	2026-07-24 14:21:13.158394+00	f	\N	32	Honda X-Blade 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
250	2026-07-24 14:23:40.575036+00	2026-07-24 14:23:40.575054+00	f	\N	33	Bajaj Platina 100cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
251	2026-07-24 14:26:33.959171+00	2026-07-24 14:26:33.959199+00	f	\N	34	TVS Rider 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
252	2026-07-24 14:34:20.561433+00	2026-07-24 14:34:20.561444+00	f	\N	35	Hero Hunk 150R 2025 150cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
253	2026-07-24 14:43:05.731428+00	2026-07-24 14:43:05.731444+00	f	\N	2	Grameen Bank (NGO)	CREATE	[]	26	9a259d21-6303-464d-97fe-23a835dfdc29
254	2026-07-24 14:44:11.997859+00	2026-07-24 14:44:11.997879+00	f	\N	4	Installment #1 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
255	2026-07-25 03:59:44.418111+00	2026-07-25 03:59:44.418144+00	f	\N	110	Noor Islam	UPDATE	["name"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
256	2026-07-25 04:01:49.640652+00	2026-07-25 04:01:49.640675+00	f	\N	112	Khurshed Painter	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
257	2026-07-25 08:40:28.639951+00	2026-07-25 08:40:28.639964+00	f	\N	5	INV-2026-00005	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
258	2026-07-25 08:42:20.70961+00	2026-07-25 08:42:20.709627+00	f	\N	5	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191066) on INV-2026-00005	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
259	2026-07-25 08:42:20.725919+00	2026-07-25 08:42:20.725952+00	f	\N	5	Mileage Correction on INV-2026-00005	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
260	2026-07-25 08:42:20.753416+00	2026-07-25 08:42:20.753427+00	f	\N	5	INV-2026-00005	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
261	2026-07-25 08:46:26.66775+00	2026-07-25 08:46:26.667759+00	f	\N	6	INV-2026-00006	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
262	2026-07-25 08:47:05.159288+00	2026-07-25 08:47:05.159301+00	f	\N	6	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00006	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
263	2026-07-25 08:47:05.168904+00	2026-07-25 08:47:05.16892+00	f	\N	6	Mileage Correction on INV-2026-00006	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
264	2026-07-25 08:47:05.189793+00	2026-07-25 08:47:05.189806+00	f	\N	6	INV-2026-00006	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
265	2026-07-25 08:47:16.871966+00	2026-07-25 08:47:16.871977+00	f	\N	6	INV-2026-00006	UPDATE	["created_date"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
266	2026-07-25 08:47:21.558569+00	2026-07-25 08:47:21.558581+00	f	\N	6	Mileage Correction on INV-2026-00006	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
267	2026-07-25 13:38:54.299909+00	2026-07-25 13:38:54.29993+00	f	\N	36	Honda SP 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
268	2026-07-25 15:08:48.898622+00	2026-07-25 15:08:48.898643+00	f	\N	4	400.00 on INV-2026-00005	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
269	2026-07-25 15:08:48.938864+00	2026-07-25 15:08:48.938876+00	f	\N	5	INV-2026-00005	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
270	2026-07-25 15:08:48.960568+00	2026-07-25 15:08:48.960579+00	f	\N	5	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191066) on INV-2026-00005	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
271	2026-07-25 15:19:05.34656+00	2026-07-25 15:19:05.346593+00	f	\N	5	Installment #2 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
272	2026-07-25 15:19:41.906089+00	2026-07-25 15:19:41.9061+00	f	\N	6	Installment #3 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
273	2026-07-25 15:20:29.617967+00	2026-07-25 15:20:29.617994+00	f	\N	7	Installment #4 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
274	2026-07-25 15:20:59.865459+00	2026-07-25 15:20:59.86547+00	f	\N	8	Installment #5 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
275	2026-07-25 15:21:40.595908+00	2026-07-25 15:21:40.595934+00	f	\N	9	Installment #6 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
276	2026-07-25 15:23:17.722727+00	2026-07-25 15:23:17.722738+00	f	\N	10	Installment #7 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
277	2026-07-25 15:24:49.720819+00	2026-07-25 15:24:49.72083+00	f	\N	11	Installment #8 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
278	2026-07-25 15:25:23.469458+00	2026-07-25 15:25:23.469469+00	f	\N	12	Installment #9 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
279	2026-07-25 15:25:50.859396+00	2026-07-25 15:25:50.859408+00	f	\N	13	Installment #10 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
280	2026-07-25 15:26:14.850658+00	2026-07-25 15:26:14.850675+00	f	\N	14	Installment #11 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
281	2026-07-25 15:26:33.888407+00	2026-07-25 15:26:33.88842+00	f	\N	15	Installment #12 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
282	2026-07-25 15:26:49.899107+00	2026-07-25 15:26:49.899126+00	f	\N	16	Installment #13 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
283	2026-07-25 15:28:20.695043+00	2026-07-25 15:28:20.695054+00	f	\N	17	Installment #14 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
284	2026-07-25 15:28:38.858604+00	2026-07-25 15:28:38.858614+00	f	\N	18	Installment #15 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
285	2026-07-25 15:29:45.38008+00	2026-07-25 15:29:45.380099+00	f	\N	19	Installment #16 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
286	2026-07-25 15:30:20.212262+00	2026-07-25 15:30:20.212272+00	f	\N	20	Installment #17 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
287	2026-07-25 15:32:47.941505+00	2026-07-25 15:32:47.941516+00	f	\N	21	Installment #18 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
288	2026-07-25 15:33:20.59538+00	2026-07-25 15:33:20.595392+00	f	\N	22	Installment #19 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
289	2026-07-25 15:34:13.451568+00	2026-07-25 15:34:13.451581+00	f	\N	23	Installment #20 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
290	2026-07-25 15:34:33.255033+00	2026-07-25 15:34:33.255091+00	f	\N	24	Installment #21 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
291	2026-07-25 15:34:57.841882+00	2026-07-25 15:34:57.841893+00	f	\N	25	Installment #22 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
292	2026-07-25 15:35:40.423016+00	2026-07-25 15:35:40.423035+00	f	\N	26	Installment #23 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
293	2026-07-25 15:36:06.075177+00	2026-07-25 15:36:06.075191+00	f	\N	27	Installment #24 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
294	2026-07-25 15:36:43.4557+00	2026-07-25 15:36:43.455712+00	f	\N	28	Installment #25 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
295	2026-07-25 15:41:00.987194+00	2026-07-25 15:41:00.987206+00	f	\N	29	Installment #26 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
296	2026-07-25 15:41:27.009471+00	2026-07-25 15:41:27.009483+00	f	\N	30	Installment #27 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
297	2026-07-25 15:41:49.275425+00	2026-07-25 15:41:49.275436+00	f	\N	31	Installment #28 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
298	2026-07-25 15:42:47.079261+00	2026-07-25 15:42:47.079297+00	f	\N	32	Installment #29 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
299	2026-07-25 15:42:53.520906+00	2026-07-25 15:42:53.520918+00	f	\N	33	Installment #30 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
300	2026-07-25 15:43:09.527961+00	2026-07-25 15:43:09.527973+00	f	\N	34	Installment #31 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
301	2026-07-25 15:43:29.785484+00	2026-07-25 15:43:29.785495+00	f	\N	35	Installment #32 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
302	2026-07-25 15:43:36.376303+00	2026-07-25 15:43:36.376315+00	f	\N	36	Installment #33 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
303	2026-07-25 15:43:42.05872+00	2026-07-25 15:43:42.058733+00	f	\N	37	Installment #34 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
304	2026-07-25 15:43:48.683586+00	2026-07-25 15:43:48.683598+00	f	\N	38	Installment #35 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
305	2026-07-25 15:43:54.075897+00	2026-07-25 15:43:54.075918+00	f	\N	39	Installment #36 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
306	2026-07-25 15:44:01.377812+00	2026-07-25 15:44:01.377831+00	f	\N	40	Installment #37 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
307	2026-07-25 15:44:07.173531+00	2026-07-25 15:44:07.173542+00	f	\N	41	Installment #38 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
308	2026-07-25 15:44:12.682385+00	2026-07-25 15:44:12.682406+00	f	\N	42	Installment #39 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
309	2026-07-25 15:44:19.268716+00	2026-07-25 15:44:19.268726+00	f	\N	43	Installment #40 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
310	2026-07-25 15:46:09.524481+00	2026-07-25 15:46:09.524492+00	f	\N	44	Installment #41 for Grameen Bank	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
311	2026-07-26 07:34:30.105256+00	2026-07-26 07:34:30.105299+00	f	\N	7	INV-2026-00007	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
312	2026-07-26 07:40:39.833569+00	2026-07-26 07:40:39.833585+00	f	\N	7	Bajaj Discover 5Gear 125cc (serial JZ 402422 0024) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
313	2026-07-26 07:40:39.846661+00	2026-07-26 07:40:39.846682+00	f	\N	7	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
314	2026-07-26 07:40:39.870982+00	2026-07-26 07:40:39.870997+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
315	2026-07-26 08:22:58.30033+00	2026-07-26 08:22:58.300352+00	f	\N	12	Discover 110 & 125 display 2018v (MED11D2018v-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
316	2026-07-26 08:24:03.114949+00	2026-07-26 08:24:03.114985+00	f	\N	12	Discover 110 & 125 display 2018v (MED11D2018v-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
317	2026-07-26 08:24:03.128664+00	2026-07-26 08:24:03.128677+00	f	\N	11	2 x Discover 110 & 125 display 2018v on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
318	2026-07-26 08:26:36.545963+00	2026-07-26 08:26:36.545975+00	f	\N	13	Discover CBS Non gear display (MEDCNGdisplay-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
319	2026-07-26 08:30:38.682436+00	2026-07-26 08:30:38.682454+00	f	\N	13	Discover CBS Non gear display (MEDCNGdisplay-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
320	2026-07-26 08:30:38.700141+00	2026-07-26 08:30:38.700159+00	f	\N	12	2 x Discover CBS Non gear display on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
321	2026-07-26 08:36:13.757589+00	2026-07-26 08:36:13.757611+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
322	2026-07-26 08:36:32.850225+00	2026-07-26 08:36:32.850247+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
323	2026-07-26 08:36:32.858326+00	2026-07-26 08:36:32.858348+00	f	\N	13	4 x Discover Display Grear on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
324	2026-07-26 09:06:09.622886+00	2026-07-26 09:06:09.622907+00	f	\N	15	FZ V3 Display (MEFVD-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
325	2026-07-26 09:07:00.061813+00	2026-07-26 09:07:00.061831+00	f	\N	15	FZ V3 Display (MEFVD-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
326	2026-07-26 09:07:00.06988+00	2026-07-26 09:07:00.0699+00	f	\N	14	2 x FZ V3 Display on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
327	2026-07-26 09:08:02.563603+00	2026-07-26 09:08:02.563673+00	f	\N	16	FZ V2 Display (LFVD-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
328	2026-07-26 09:08:25.625123+00	2026-07-26 09:08:25.625139+00	f	\N	16	FZ V2 Display (LFVD-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
329	2026-07-26 09:08:25.635664+00	2026-07-26 09:08:25.635687+00	f	\N	15	2 x FZ V2 Display on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
330	2026-07-26 09:18:17.402779+00	2026-07-26 09:18:17.402813+00	f	\N	17	Gexxer Monotone Display (MEGMD-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
331	2026-07-26 09:18:43.617122+00	2026-07-26 09:18:43.617137+00	f	\N	17	Gexxer Monotone Display (MEGMD-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
332	2026-07-26 09:18:43.626695+00	2026-07-26 09:18:43.626709+00	f	\N	16	2 x Gexxer Monotone Display on 2026-07-26	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
333	2026-07-26 09:21:35.305395+00	2026-07-26 09:21:35.30541+00	f	\N	113	Bipul	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
334	2026-07-26 09:23:41.293175+00	2026-07-26 09:23:41.29319+00	f	\N	7	Gixxer SF Main board repaire	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
335	2026-07-26 09:24:00.22963+00	2026-07-26 09:24:00.229644+00	f	\N	8	INV-2026-00008	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
336	2026-07-26 09:24:26.581278+00	2026-07-26 09:24:26.581311+00	f	\N	8	Gixxer SF Main board repaire on INV-2026-00008	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
337	2026-07-26 09:24:26.617365+00	2026-07-26 09:24:26.617401+00	f	\N	8	INV-2026-00008	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
338	2026-07-26 09:24:38.919846+00	2026-07-26 09:24:38.919858+00	f	\N	8	Gixxer SF Main board repaire on INV-2026-00008	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
339	2026-07-26 09:24:38.953149+00	2026-07-26 09:24:38.953178+00	f	\N	8	INV-2026-00008	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
340	2026-07-26 09:24:56.379937+00	2026-07-26 09:24:56.37998+00	f	\N	7	Gixxer SF Main board repaire	UPDATE	["service_price"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
341	2026-07-26 09:27:13.510083+00	2026-07-26 09:27:13.51011+00	f	\N	1	Display	CREATE	[]	24	9a259d21-6303-464d-97fe-23a835dfdc29
342	2026-07-26 14:10:58.649457+00	2026-07-26 14:10:58.649472+00	f	\N	5	400.00 on INV-2026-00006	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
343	2026-07-26 14:10:58.688929+00	2026-07-26 14:10:58.688949+00	f	\N	6	INV-2026-00006	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
344	2026-07-26 14:10:58.718895+00	2026-07-26 14:10:58.71892+00	f	\N	6	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00006	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
345	2026-07-27 07:36:10.374125+00	2026-07-27 07:36:10.374152+00	f	\N	9	INV-2026-00009	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
346	2026-07-27 07:37:35.60231+00	2026-07-27 07:37:35.60233+00	f	\N	8	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191071) on INV-2026-00009	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
347	2026-07-27 07:37:35.615711+00	2026-07-27 07:37:35.615723+00	f	\N	9	Mileage Correction on INV-2026-00009	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
348	2026-07-27 07:37:35.645669+00	2026-07-27 07:37:35.64568+00	f	\N	9	INV-2026-00009	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
349	2026-07-27 09:38:21.434579+00	2026-07-27 09:38:21.434591+00	f	\N	9	Bajaj Discover 5Gear 125cc (serial JZ402422) on INV-2026-00003	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
350	2026-07-27 09:38:21.474731+00	2026-07-27 09:38:21.474748+00	f	\N	10	Mileage Correction on INV-2026-00003	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
351	2026-07-27 09:38:21.501885+00	2026-07-27 09:38:21.501897+00	f	\N	3	INV-2026-00003	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
352	2026-07-27 11:18:44.182082+00	2026-07-27 11:18:44.182112+00	f	\N	6	400.00 on INV-2026-00003	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
353	2026-07-27 11:18:44.209749+00	2026-07-27 11:18:44.209766+00	f	\N	3	INV-2026-00003	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
354	2026-07-27 11:18:44.242134+00	2026-07-27 11:18:44.242151+00	f	\N	3	Gixxer Monotone 155cc (serial None) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
355	2026-07-27 11:18:44.25801+00	2026-07-27 11:18:44.258029+00	f	\N	9	Bajaj Discover 5Gear 125cc (serial JZ402422) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
356	2026-07-27 11:19:28.703964+00	2026-07-27 11:19:28.703991+00	f	\N	11	Display Replace on INV-2026-00003	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
357	2026-07-27 11:19:28.722057+00	2026-07-27 11:19:28.722077+00	f	\N	17	Gexxer Monotone Display (MEGMD-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
358	2026-07-27 11:19:28.748161+00	2026-07-27 11:19:28.748178+00	f	\N	3	INV-2026-00003	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
359	2026-07-27 13:31:11.843757+00	2026-07-27 13:31:11.843767+00	f	\N	10	INV-2026-00010	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
360	2026-07-27 13:33:03.466484+00	2026-07-27 13:33:03.466502+00	f	\N	5	EasyPro	CREATE	[]	1	9a259d21-6303-464d-97fe-23a835dfdc29
361	2026-07-27 13:33:13.37789+00	2026-07-27 13:33:13.377913+00	f	\N	5	EasyPro	UPDATE	["memory_type_support"]	1	9a259d21-6303-464d-97fe-23a835dfdc29
362	2026-07-27 13:35:24.180887+00	2026-07-27 13:35:24.180899+00	f	\N	10	Bajaj Discover V18 110cc (serial None) on INV-2026-00010	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
363	2026-07-27 13:35:24.190783+00	2026-07-27 13:35:24.190803+00	f	\N	12	Mileage Correction on INV-2026-00010	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
364	2026-07-27 13:35:24.216941+00	2026-07-27 13:35:24.216956+00	f	\N	10	INV-2026-00010	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
365	2026-07-27 13:44:59.286566+00	2026-07-27 13:44:59.286593+00	f	\N	11	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00010	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
366	2026-07-27 13:44:59.298014+00	2026-07-27 13:44:59.29803+00	f	\N	13	Mileage Correction on INV-2026-00010	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
367	2026-07-27 13:44:59.324986+00	2026-07-27 13:44:59.324996+00	f	\N	10	INV-2026-00010	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
368	2026-07-27 13:46:23.32134+00	2026-07-27 13:46:23.321355+00	f	\N	11	INV-2026-00011	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
369	2026-07-27 13:47:13.57533+00	2026-07-27 13:47:13.575347+00	f	\N	12	Bajaj Discover V18 110cc (serial None) on INV-2026-00011	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
370	2026-07-27 13:47:13.584563+00	2026-07-27 13:47:13.584596+00	f	\N	14	Mileage Correction on INV-2026-00011	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
371	2026-07-27 13:47:13.611576+00	2026-07-27 13:47:13.611592+00	f	\N	11	INV-2026-00011	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
372	2026-07-27 13:49:13.880064+00	2026-07-27 13:49:13.88013+00	f	\N	7	600.00 on INV-2026-00008	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
373	2026-07-27 13:49:13.922277+00	2026-07-27 13:49:13.922299+00	f	\N	8	INV-2026-00008	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
374	2026-07-27 13:49:56.202246+00	2026-07-27 13:49:56.202258+00	f	\N	12	INV-2026-00012	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
375	2026-07-27 13:51:26.696097+00	2026-07-27 13:51:26.696128+00	f	\N	15	Light Replace on INV-2026-00012	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
376	2026-07-27 13:51:26.713069+00	2026-07-27 13:51:26.713087+00	f	\N	5	White LED 3528 (MEWL3528-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
377	2026-07-27 13:51:26.740668+00	2026-07-27 13:51:26.740684+00	f	\N	12	INV-2026-00012	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
378	2026-07-27 13:52:17.979809+00	2026-07-27 13:52:17.979831+00	f	\N	15	Light Replace on INV-2026-00012	UPDATE	["product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
379	2026-07-27 13:52:18.015335+00	2026-07-27 13:52:18.015353+00	f	\N	12	INV-2026-00012	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
380	2026-07-27 13:52:32.161366+00	2026-07-27 13:52:32.161386+00	f	\N	15	Light Replace on INV-2026-00012	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
381	2026-07-27 13:52:32.193041+00	2026-07-27 13:52:32.193063+00	f	\N	12	INV-2026-00012	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
382	2026-07-27 13:52:41.668224+00	2026-07-27 13:52:41.668241+00	f	\N	8	1800.00 on INV-2026-00012	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
383	2026-07-27 13:52:41.700968+00	2026-07-27 13:52:41.70098+00	f	\N	12	INV-2026-00012	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
384	2026-07-27 13:55:02.810081+00	2026-07-27 13:55:02.8101+00	f	\N	114	Babu	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
385	2026-07-27 13:55:18.207431+00	2026-07-27 13:55:18.207445+00	f	\N	13	INV-2026-00013	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
386	2026-07-27 13:57:05.206053+00	2026-07-27 13:57:05.206077+00	f	\N	8	Mainboard Repair	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
387	2026-07-27 13:57:39.941294+00	2026-07-27 13:57:39.941323+00	f	\N	16	Mainboard Repair on INV-2026-00013	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
388	2026-07-27 13:57:39.96993+00	2026-07-27 13:57:39.969976+00	f	\N	13	INV-2026-00013	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
389	2026-07-27 13:57:47.401804+00	2026-07-27 13:57:47.401823+00	f	\N	16	Mainboard Repair on INV-2026-00013	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
390	2026-07-27 13:57:47.432917+00	2026-07-27 13:57:47.432934+00	f	\N	13	INV-2026-00013	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
391	2026-07-27 13:57:55.683978+00	2026-07-27 13:57:55.684021+00	f	\N	9	1000.00 on INV-2026-00013	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
392	2026-07-27 13:57:55.713618+00	2026-07-27 13:57:55.71365+00	f	\N	13	INV-2026-00013	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
393	2026-07-27 14:59:50.646485+00	2026-07-27 14:59:50.646496+00	f	\N	14	INV-2026-00014	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
394	2026-07-27 15:00:25.014936+00	2026-07-27 15:00:25.014959+00	f	\N	17	Pulsar Polarize Paper Replace on INV-2026-00014	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
395	2026-07-27 15:00:25.028327+00	2026-07-27 15:00:25.028348+00	f	\N	1	Pulsar Polarized Paper (PP-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
396	2026-07-27 15:00:25.052763+00	2026-07-27 15:00:25.052784+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
397	2026-07-27 15:04:41.86775+00	2026-07-27 15:04:41.867776+00	f	\N	12	Mileage Correction on INV-2026-00010	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
398	2026-07-27 15:04:41.892945+00	2026-07-27 15:04:41.892965+00	f	\N	10	Bajaj Discover V18 110cc (serial None) on INV-2026-00010	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
399	2026-07-27 15:04:41.918539+00	2026-07-27 15:04:41.918563+00	f	\N	10	INV-2026-00010	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
400	2026-07-27 15:04:52.134264+00	2026-07-27 15:04:52.13429+00	f	\N	10	400.00 on INV-2026-00010	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
401	2026-07-27 15:04:52.164861+00	2026-07-27 15:04:52.164876+00	f	\N	10	INV-2026-00010	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
402	2026-07-27 15:04:52.195649+00	2026-07-27 15:04:52.19566+00	f	\N	11	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00010	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
403	2026-07-27 15:05:05.738884+00	2026-07-27 15:05:05.738907+00	f	\N	15	INV-2026-00015	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
404	2026-07-27 15:06:22.187873+00	2026-07-27 15:06:22.1879+00	f	\N	13	Bajaj Discover V18 110cc (serial None) on INV-2026-00015	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
405	2026-07-27 15:06:22.196673+00	2026-07-27 15:06:22.196691+00	f	\N	18	Mileage Correction on INV-2026-00015	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
406	2026-07-27 15:06:22.221201+00	2026-07-27 15:06:22.221216+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
407	2026-07-27 15:51:06.5192+00	2026-07-27 15:51:06.519211+00	f	\N	115	Demo Customer	CREATE	[]	10	\N
408	2026-07-27 15:51:06.534136+00	2026-07-27 15:51:06.534149+00	f	\N	37	Bajaj Discover 125 125cc	CREATE	[]	12	\N
409	2026-07-27 15:51:06.549757+00	2026-07-27 15:51:06.54978+00	f	\N	16	INV-2026-00016	CREATE	[]	19	\N
410	2026-07-27 15:51:06.568951+00	2026-07-27 15:51:06.568968+00	f	\N	14	Bajaj Discover 125 125cc (serial MCU-DEMO) on INV-2026-00016	CREATE	[]	20	\N
411	2026-07-27 15:52:16.009242+00	2026-07-27 15:52:16.009275+00	f	\N	14	Bajaj Discover 125 125cc (serial MCU-DEMO) on INV-2026-00016	DELETE	[]	20	\N
412	2026-07-27 15:52:16.035658+00	2026-07-27 15:52:16.03568+00	f	\N	16	INV-2026-00016	DELETE	[]	19	\N
413	2026-07-27 15:52:16.044167+00	2026-07-27 15:52:16.044179+00	f	\N	37	Bajaj Discover 125 125cc	DELETE	[]	12	\N
414	2026-07-27 15:52:16.053368+00	2026-07-27 15:52:16.05338+00	f	\N	115	Demo Customer	DELETE	[]	10	\N
419	2026-07-27 16:11:00.294039+00	2026-07-27 16:11:00.294051+00	f	\N	3043b9d3-e73d-40b5-8a84-ec4fc263398a	QA Verify	CREATE	[]	9	\N
420	2026-07-27 16:11:01.110623+00	2026-07-27 16:11:01.110634+00	f	\N	3043b9d3-e73d-40b5-8a84-ec4fc263398a	QA Verify	UPDATE	["password"]	9	\N
421	2026-07-27 16:12:33.437938+00	2026-07-27 16:12:33.437973+00	f	\N	118	ZZZ QA TEST DELETE ME	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
422	2026-07-27 16:12:58.90806+00	2026-07-27 16:12:58.908086+00	f	\N	18	INV-2026-00016	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
423	2026-07-27 16:14:08.517728+00	2026-07-27 16:14:08.517748+00	f	\N	16	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00016	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
424	2026-07-27 16:14:08.528972+00	2026-07-27 16:14:08.528999+00	f	\N	19	Mileage Correction on INV-2026-00016	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
425	2026-07-27 16:14:08.560917+00	2026-07-27 16:14:08.56095+00	f	\N	18	INV-2026-00016	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
426	2026-07-27 16:16:36.3839+00	2026-07-27 16:16:36.383926+00	f	\N	1	InvoiceMeterEntry object (1)	UPDATE	["condition_note_tags"]	20	\N
427	2026-07-27 16:16:36.394173+00	2026-07-27 16:16:36.394203+00	f	\N	2	InvoiceMeterEntry object (2)	UPDATE	["condition_note_tags"]	20	\N
428	2026-07-27 16:16:36.405776+00	2026-07-27 16:16:36.405799+00	f	\N	3	InvoiceMeterEntry object (3)	UPDATE	["condition_note_tags"]	20	\N
429	2026-07-27 16:16:36.417639+00	2026-07-27 16:16:36.417666+00	f	\N	4	InvoiceMeterEntry object (4)	UPDATE	["condition_note_tags"]	20	\N
430	2026-07-27 16:16:36.429129+00	2026-07-27 16:16:36.429141+00	f	\N	5	InvoiceMeterEntry object (5)	UPDATE	["condition_note_tags"]	20	\N
431	2026-07-27 16:16:36.443191+00	2026-07-27 16:16:36.443203+00	f	\N	6	InvoiceMeterEntry object (6)	UPDATE	["condition_note_tags"]	20	\N
432	2026-07-27 16:16:36.456824+00	2026-07-27 16:16:36.456842+00	f	\N	7	InvoiceMeterEntry object (7)	UPDATE	["condition_note_tags"]	20	\N
433	2026-07-27 16:16:36.467882+00	2026-07-27 16:16:36.467894+00	f	\N	8	InvoiceMeterEntry object (8)	UPDATE	["condition_note_tags"]	20	\N
434	2026-07-27 16:16:36.483063+00	2026-07-27 16:16:36.483075+00	f	\N	9	InvoiceMeterEntry object (9)	UPDATE	["condition_note_tags"]	20	\N
435	2026-07-27 16:16:36.497143+00	2026-07-27 16:16:36.497156+00	f	\N	10	InvoiceMeterEntry object (10)	UPDATE	["condition_note_tags"]	20	\N
436	2026-07-27 16:16:36.512561+00	2026-07-27 16:16:36.512577+00	f	\N	11	InvoiceMeterEntry object (11)	UPDATE	["condition_note_tags"]	20	\N
437	2026-07-27 16:16:36.525067+00	2026-07-27 16:16:36.525088+00	f	\N	12	InvoiceMeterEntry object (12)	UPDATE	["condition_note_tags"]	20	\N
438	2026-07-27 16:16:36.536849+00	2026-07-27 16:16:36.536872+00	f	\N	13	InvoiceMeterEntry object (13)	UPDATE	["condition_note_tags"]	20	\N
439	2026-07-27 16:16:36.548481+00	2026-07-27 16:16:36.548495+00	f	\N	16	InvoiceMeterEntry object (16)	UPDATE	["condition_note_tags"]	20	\N
440	2026-07-27 16:17:43.652188+00	2026-07-27 16:17:43.652236+00	f	\N	19	Mileage Correction on INV-2026-00016	DELETE	[]	23	\N
441	2026-07-27 16:17:43.695067+00	2026-07-27 16:17:43.695089+00	f	\N	16	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00016	DELETE	[]	20	\N
442	2026-07-27 16:17:43.718+00	2026-07-27 16:17:43.718015+00	f	\N	18	INV-2026-00016	DELETE	[]	19	\N
443	2026-07-27 16:17:43.724856+00	2026-07-27 16:17:43.724872+00	f	\N	118	ZZZ QA TEST DELETE ME	DELETE	[]	10	\N
444	2026-07-27 16:17:43.734422+00	2026-07-27 16:17:43.734436+00	f	\N	3043b9d3-e73d-40b5-8a84-ec4fc263398a	QA Verify	DELETE	["is_active", "is_deleted", "deleted_at"]	9	\N
445	2026-07-27 16:21:17.676462+00	2026-07-27 16:21:17.676475+00	f	\N	3	Gixxer Monotone 155cc (serial None) on INV-2026-00003	UPDATE	["condition_note"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
446	2026-07-27 17:07:03.308244+00	2026-07-27 17:07:03.308255+00	f	\N	c9af5589-7d4d-4a4b-b306-82621f9858f3	QA Verify 2	CREATE	[]	9	\N
447	2026-07-27 17:07:04.060549+00	2026-07-27 17:07:04.06056+00	f	\N	c9af5589-7d4d-4a4b-b306-82621f9858f3	QA Verify 2	UPDATE	["password"]	9	\N
448	2026-07-27 17:14:23.609252+00	2026-07-27 17:14:23.609285+00	f	\N	3	ZZZ QA Pridim Foundation (NGO)	CREATE	[]	26	\N
449	2026-07-27 17:14:23.640917+00	2026-07-27 17:14:23.640935+00	f	\N	45	Installment #1 for ZZZ QA Pridim Foundation	CREATE	[]	27	\N
450	2026-07-27 17:14:23.647917+00	2026-07-27 17:14:23.647932+00	f	\N	46	Installment #2 for ZZZ QA Pridim Foundation	CREATE	[]	27	\N
451	2026-07-27 17:14:23.65971+00	2026-07-27 17:14:23.659732+00	f	\N	47	Installment #3 for ZZZ QA Pridim Foundation	CREATE	[]	27	\N
452	2026-07-27 17:14:23.663917+00	2026-07-27 17:14:23.66395+00	f	\N	4	ZZZ QA Overdue Test (NGO)	CREATE	[]	26	\N
453	2026-07-27 17:15:45.036899+00	2026-07-27 17:15:45.036928+00	f	\N	45	Installment #1 for ZZZ QA Pridim Foundation	DELETE	[]	27	\N
454	2026-07-27 17:15:45.045204+00	2026-07-27 17:15:45.045215+00	f	\N	46	Installment #2 for ZZZ QA Pridim Foundation	DELETE	[]	27	\N
455	2026-07-27 17:15:45.048104+00	2026-07-27 17:15:45.048115+00	f	\N	47	Installment #3 for ZZZ QA Pridim Foundation	DELETE	[]	27	\N
456	2026-07-27 17:15:45.054841+00	2026-07-27 17:15:45.054866+00	f	\N	3	ZZZ QA Pridim Foundation (NGO)	DELETE	[]	26	\N
457	2026-07-27 17:15:45.060568+00	2026-07-27 17:15:45.06058+00	f	\N	4	ZZZ QA Overdue Test (NGO)	DELETE	[]	26	\N
458	2026-07-27 17:15:45.074376+00	2026-07-27 17:15:45.074391+00	f	\N	c9af5589-7d4d-4a4b-b306-82621f9858f3	QA Verify 2	DELETE	["is_active", "is_deleted", "deleted_at"]	9	\N
459	2026-07-27 17:21:38.046554+00	2026-07-27 17:21:38.046569+00	f	\N	39	TVS Metro Plus 110cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
460	2026-07-27 17:24:57.466825+00	2026-07-27 17:24:57.466842+00	f	\N	17	TVS Metro Plus 110cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
461	2026-07-27 17:24:57.493622+00	2026-07-27 17:24:57.493635+00	f	\N	20	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
462	2026-07-27 17:24:57.526726+00	2026-07-27 17:24:57.526742+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
463	2026-07-27 17:35:17.412525+00	2026-07-27 17:35:17.412567+00	f	\N	18	Gixxer SF A2 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
464	2026-07-27 17:35:17.431616+00	2026-07-27 17:35:17.431702+00	f	\N	21	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
465	2026-07-27 17:35:17.499199+00	2026-07-27 17:35:17.499238+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
466	2026-07-27 17:35:36.496135+00	2026-07-27 17:35:36.496162+00	f	\N	21	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
467	2026-07-27 17:36:07.539887+00	2026-07-27 17:36:07.539945+00	f	\N	19	Gixxer Monotone 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
468	2026-07-27 17:36:07.554648+00	2026-07-27 17:36:07.554674+00	f	\N	22	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
469	2026-07-27 17:36:07.607956+00	2026-07-27 17:36:07.607982+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
470	2026-07-27 17:36:17.46489+00	2026-07-27 17:36:17.464995+00	f	\N	22	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
471	2026-07-27 17:37:04.451027+00	2026-07-27 17:37:04.451043+00	f	\N	20	Gixxer SF A5 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
472	2026-07-27 17:37:04.463342+00	2026-07-27 17:37:04.463411+00	f	\N	23	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
473	2026-07-27 17:37:04.513931+00	2026-07-27 17:37:04.513989+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
474	2026-07-27 17:37:21.96228+00	2026-07-27 17:37:21.962313+00	f	\N	23	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
475	2026-07-27 17:37:56.170963+00	2026-07-27 17:37:56.171053+00	f	\N	21	Honda SP shine 100cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
476	2026-07-27 17:37:56.193228+00	2026-07-27 17:37:56.193274+00	f	\N	24	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
477	2026-07-27 17:37:56.257643+00	2026-07-27 17:37:56.257708+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
478	2026-07-27 17:38:14.925202+00	2026-07-27 17:38:14.92523+00	f	\N	24	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
479	2026-07-27 17:46:29.850099+00	2026-07-27 17:46:29.850137+00	f	\N	40	Honda Hornet 160cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
480	2026-07-27 17:47:24.048141+00	2026-07-27 17:47:24.04817+00	f	\N	22	Honda Hornet 160cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
481	2026-07-27 17:47:24.062842+00	2026-07-27 17:47:24.062861+00	f	\N	25	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
482	2026-07-27 17:47:24.103742+00	2026-07-27 17:47:24.103775+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
483	2026-07-27 17:48:07.543565+00	2026-07-27 17:48:07.543597+00	f	\N	23	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
484	2026-07-27 17:48:07.555603+00	2026-07-27 17:48:07.555631+00	f	\N	26	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
485	2026-07-27 17:48:07.600133+00	2026-07-27 17:48:07.600179+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
486	2026-07-27 17:49:34.081908+00	2026-07-27 17:49:34.081931+00	f	\N	26	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
487	2026-07-27 17:49:41.718073+00	2026-07-27 17:49:41.718105+00	f	\N	25	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
488	2026-07-27 17:50:35.127889+00	2026-07-27 17:50:35.127913+00	f	\N	24	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
489	2026-07-27 17:50:35.142168+00	2026-07-27 17:50:35.142202+00	f	\N	27	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
490	2026-07-27 17:50:35.213399+00	2026-07-27 17:50:35.213448+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
491	2026-07-27 17:50:49.543802+00	2026-07-27 17:50:49.543837+00	f	\N	27	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
492	2026-07-27 17:51:28.731604+00	2026-07-27 17:51:28.731635+00	f	\N	25	Gixxer Monotone 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
493	2026-07-27 17:51:28.747537+00	2026-07-27 17:51:28.747584+00	f	\N	28	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
494	2026-07-27 17:51:28.797881+00	2026-07-27 17:51:28.797916+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
495	2026-07-27 17:52:00.547105+00	2026-07-27 17:52:00.54714+00	f	\N	28	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
496	2026-07-27 17:52:08.426588+00	2026-07-27 17:52:08.426609+00	f	\N	28	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
497	2026-07-27 17:52:24.042761+00	2026-07-27 17:52:24.042789+00	f	\N	28	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
498	2026-07-27 17:56:15.193615+00	2026-07-27 17:56:15.19366+00	f	\N	41	TVS Stryker 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
499	2026-07-27 17:58:10.20658+00	2026-07-27 17:58:10.206603+00	f	\N	26	TVS Stryker 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
500	2026-07-27 17:58:10.231632+00	2026-07-27 17:58:10.231714+00	f	\N	29	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
501	2026-07-27 17:58:10.282617+00	2026-07-27 17:58:10.282655+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
502	2026-07-27 17:58:51.438957+00	2026-07-27 17:58:51.439002+00	f	\N	29	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
503	2026-07-27 17:59:11.234981+00	2026-07-27 17:59:11.235009+00	f	\N	29	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
504	2026-07-27 17:59:26.531924+00	2026-07-27 17:59:26.531947+00	f	\N	29	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
505	2026-07-27 18:00:10.801858+00	2026-07-27 18:00:10.801894+00	f	\N	27	Gixxer SF A5 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
506	2026-07-27 18:00:10.818247+00	2026-07-27 18:00:10.818287+00	f	\N	30	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
507	2026-07-27 18:00:10.870475+00	2026-07-27 18:00:10.870501+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
508	2026-07-27 18:00:24.873141+00	2026-07-27 18:00:24.873168+00	f	\N	30	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
509	2026-07-27 18:42:23.430942+00	2026-07-27 18:42:23.430966+00	f	\N	1	Pridim Foundation (NGO)	UPDATE	["start_date"]	26	\N
510	2026-07-27 18:56:35.36038+00	2026-07-27 18:56:35.360414+00	f	\N	17	TVS Metro Plus 110cc (serial A2C1297290101) on INV-2026-00007	UPDATE	["serial_number", "mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
511	2026-07-28 07:39:36.212722+00	2026-07-28 07:39:36.212765+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	UPDATE	["last_login"]	9	9a259d21-6303-464d-97fe-23a835dfdc29
512	2026-07-28 13:44:55.244409+00	2026-07-28 13:44:55.244444+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	UPDATE	["last_login"]	9	9a259d21-6303-464d-97fe-23a835dfdc29
513	2026-07-28 13:48:59.520202+00	2026-07-28 13:48:59.520216+00	f	\N	4	Display Repair	UPDATE	["image"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
514	2026-07-28 13:50:13.444469+00	2026-07-28 13:50:13.444486+00	f	\N	2	Bajaj Discover 4Gear 110cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
515	2026-07-28 13:51:13.939353+00	2026-07-28 13:51:13.939367+00	f	\N	4	Bajaj Discover V18 110cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
516	2026-07-28 13:53:22.438589+00	2026-07-28 13:53:22.438603+00	f	\N	6	Bajaj Pulsar 4F 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
517	2026-07-28 13:53:46.906463+00	2026-07-28 13:53:46.906475+00	f	\N	7	Bajaj Pulsar ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
518	2026-07-28 13:54:40.716939+00	2026-07-28 13:54:40.716956+00	f	\N	9	Bajaj Pulsar Single Disk Double ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
519	2026-07-28 13:55:33.240861+00	2026-07-28 13:55:33.240874+00	f	\N	11	Gixxer SF A1 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
520	2026-07-28 13:55:45.02046+00	2026-07-28 13:55:45.020472+00	f	\N	12	Gixxer SF A2 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
521	2026-07-28 13:55:55.832296+00	2026-07-28 13:55:55.832323+00	f	\N	13	Gixxer SF A3 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
522	2026-07-28 13:56:14.113685+00	2026-07-28 13:56:14.113696+00	f	\N	14	Gixxer SF A5 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
523	2026-07-28 13:56:28.534557+00	2026-07-28 13:56:28.534568+00	f	\N	15	Gixxer SF A6 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
524	2026-07-28 14:00:36.962203+00	2026-07-28 14:00:36.962215+00	f	\N	34	TVS Rider 125cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
525	2026-07-28 14:01:27.001524+00	2026-07-28 14:01:27.001542+00	f	\N	26	TVS Apache 4V 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
526	2026-07-28 14:02:22.955563+00	2026-07-28 14:02:22.955579+00	f	\N	25	TVS Apache 4V 1st 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
527	2026-07-28 14:02:44.936253+00	2026-07-28 14:02:44.936265+00	f	\N	24	TVS Apache 4V X Connect 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
528	2026-07-28 14:04:08.509012+00	2026-07-28 14:04:08.509023+00	f	\N	23	TVS Apache RTR Horse 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
529	2026-07-28 14:05:33.142482+00	2026-07-28 14:05:33.142491+00	f	\N	19	Yamaha FZS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
530	2026-07-28 14:09:15.811194+00	2026-07-28 14:09:15.811205+00	f	\N	8	Mainboard Repair	UPDATE	["category", "image"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
531	2026-07-28 14:10:31.608864+00	2026-07-28 14:10:31.608874+00	f	\N	6	Kilometer Freeze Repair	UPDATE	["image"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
532	2026-07-28 14:10:48.176346+00	2026-07-28 14:10:48.176359+00	f	\N	5	Light Replace	UPDATE	["image"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
533	2026-07-28 14:11:04.124471+00	2026-07-28 14:11:04.124484+00	f	\N	7	Gixxer SF Main board repaire	UPDATE	["image"]	13	9a259d21-6303-464d-97fe-23a835dfdc29
534	2026-07-28 14:30:44.486819+00	2026-07-28 14:30:44.486833+00	f	\N	119	Unknown Customer	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
535	2026-07-28 14:30:53.331825+00	2026-07-28 14:30:53.331845+00	f	\N	19	INV-2026-00016	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
536	2026-07-28 14:31:55.075558+00	2026-07-28 14:31:55.075569+00	f	\N	31	Pulsar Polarize Paper Replace on INV-2026-00016	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
537	2026-07-28 14:31:55.100823+00	2026-07-28 14:31:55.100836+00	f	\N	1	Pulsar Polarized Paper (PP-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
538	2026-07-28 14:31:55.162435+00	2026-07-28 14:31:55.162449+00	f	\N	19	INV-2026-00016	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
539	2026-07-28 14:32:55.103607+00	2026-07-28 14:32:55.103618+00	f	\N	28	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00016	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
540	2026-07-28 14:32:55.112427+00	2026-07-28 14:32:55.112443+00	f	\N	32	Mileage Correction on INV-2026-00016	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
541	2026-07-28 14:32:55.156962+00	2026-07-28 14:32:55.15698+00	f	\N	19	INV-2026-00016	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
542	2026-07-28 14:34:12.421844+00	2026-07-28 14:34:12.421855+00	f	\N	31	Pulsar Polarize Paper Replace on INV-2026-00016	UPDATE	["price_charged", "product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
543	2026-07-28 14:34:12.4566+00	2026-07-28 14:34:12.456609+00	f	\N	19	INV-2026-00016	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
544	2026-07-28 14:37:53.154866+00	2026-07-28 14:37:53.154882+00	f	\N	28	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00016	UPDATE	["condition_note"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
545	2026-07-28 14:40:14.850546+00	2026-07-28 14:40:14.850558+00	f	\N	17	Pulsar Polarize Paper Replace on INV-2026-00014	UPDATE	["price_charged", "product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
546	2026-07-28 14:40:14.869363+00	2026-07-28 14:40:14.869373+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
547	2026-07-28 14:48:03.793333+00	2026-07-28 14:48:03.793345+00	f	\N	29	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00014	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
548	2026-07-28 14:48:03.820521+00	2026-07-28 14:48:03.820531+00	f	\N	33	Mileage Correction on INV-2026-00014	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
549	2026-07-28 14:48:03.849113+00	2026-07-28 14:48:03.849126+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
550	2026-07-28 14:48:50.340365+00	2026-07-28 14:48:50.340376+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount", "discount_amount", "discount_note"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
551	2026-07-28 14:50:15.233893+00	2026-07-28 14:50:15.233905+00	f	\N	70	Al Amin Nalitabari	UPDATE	["phone", "address"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
552	2026-07-28 14:54:55.859775+00	2026-07-28 14:54:55.859786+00	f	\N	87	Emon Pinter	UPDATE	["phone", "address"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
553	2026-07-28 15:24:13.816689+00	2026-07-28 15:24:13.816707+00	f	\N	119	Kajal Al madina	UPDATE	["name", "address"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
554	2026-07-28 15:25:14.350448+00	2026-07-28 15:25:14.350479+00	f	\N	28	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191065) on INV-2026-00016	UPDATE	["serial_number"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
555	2026-07-28 15:28:03.332051+00	2026-07-28 15:28:03.332064+00	f	\N	19	INV-2026-00016	UPDATE	["total_amount", "discount_amount", "discount_note"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
556	2026-07-28 15:28:14.707213+00	2026-07-28 15:28:14.707226+00	f	\N	11	1500.00 on INV-2026-00016	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
557	2026-07-28 15:28:14.734595+00	2026-07-28 15:28:14.734608+00	f	\N	19	INV-2026-00016	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
558	2026-07-28 15:28:14.765158+00	2026-07-28 15:28:14.765175+00	f	\N	28	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191065) on INV-2026-00016	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
559	2026-07-28 15:34:00.949056+00	2026-07-28 15:34:00.949069+00	f	\N	30	Gixxer Monotone 155cc (serial 34134J0) on INV-2026-00003	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
560	2026-07-28 15:34:00.983232+00	2026-07-28 15:34:00.983246+00	f	\N	3	Gixxer Monotone 155cc (serial None) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
561	2026-07-28 15:34:01.01207+00	2026-07-28 15:34:01.012104+00	f	\N	9	Bajaj Discover 5Gear 125cc (serial JZ402422) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
562	2026-07-28 15:34:01.066032+00	2026-07-28 15:34:01.066044+00	f	\N	30	Gixxer Monotone 155cc (serial 34134J0) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
563	2026-07-28 15:34:01.078776+00	2026-07-28 15:34:01.078789+00	f	\N	34	Mileage Correction on INV-2026-00003	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
564	2026-07-28 15:34:01.108001+00	2026-07-28 15:34:01.108015+00	f	\N	3	INV-2026-00003	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
565	2026-07-28 15:37:28.780244+00	2026-07-28 15:37:28.780256+00	f	\N	11	Display Replace on INV-2026-00003	UPDATE	["price_charged", "product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
566	2026-07-28 15:54:31.329791+00	2026-07-28 15:54:31.329807+00	f	\N	36	Khursher - Nalitabari	UPDATE	["phone", "address"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
567	2026-07-28 16:01:27.423171+00	2026-07-28 16:01:27.423184+00	f	\N	108	Hasan Khrompur	UPDATE	["address"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
568	2026-07-30 06:17:07.61022+00	2026-07-30 06:17:07.610234+00	f	\N	48	Installment #4 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
569	2026-07-30 07:04:38.029921+00	2026-07-30 07:04:38.02993+00	f	\N	120	Unknown Jinaigati 01	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
570	2026-07-30 07:04:49.792035+00	2026-07-30 07:04:49.79205+00	f	\N	20	INV-2026-00017	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
571	2026-07-30 07:05:52.454324+00	2026-07-30 07:05:52.454336+00	f	\N	31	TVS Stryker 125cc (serial None) on INV-2026-00017	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
572	2026-07-30 07:05:52.473161+00	2026-07-30 07:05:52.473172+00	f	\N	35	Mileage Correction on INV-2026-00017	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
573	2026-07-30 07:05:52.510726+00	2026-07-30 07:05:52.51074+00	f	\N	20	INV-2026-00017	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
574	2026-07-30 07:06:01.005578+00	2026-07-30 07:06:01.00559+00	f	\N	12	400.00 on INV-2026-00017	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
575	2026-07-30 07:06:01.031152+00	2026-07-30 07:06:01.031162+00	f	\N	20	INV-2026-00017	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
576	2026-07-30 07:06:01.062285+00	2026-07-30 07:06:01.062298+00	f	\N	31	TVS Stryker 125cc (serial None) on INV-2026-00017	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
577	2026-07-30 09:33:53.995663+00	2026-07-30 09:33:53.995674+00	f	\N	121	Ashik Wash	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
578	2026-07-30 09:34:13.990559+00	2026-07-30 09:34:13.990575+00	f	\N	21	INV-2026-00018	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
579	2026-07-30 09:35:37.767122+00	2026-07-30 09:35:37.767131+00	f	\N	32	Yamaha FZ V2 150cc (serial 2GSH3500-00) on INV-2026-00018	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
580	2026-07-30 09:35:37.784172+00	2026-07-30 09:35:37.78418+00	f	\N	36	Mileage Correction on INV-2026-00018	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
581	2026-07-30 09:35:37.807971+00	2026-07-30 09:35:37.807978+00	f	\N	21	INV-2026-00018	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
582	2026-07-30 10:16:34.809697+00	2026-07-30 10:16:34.809709+00	f	\N	13	400.00 on INV-2026-00018	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
583	2026-07-30 10:16:34.849269+00	2026-07-30 10:16:34.849281+00	f	\N	21	INV-2026-00018	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
584	2026-07-30 10:16:34.881249+00	2026-07-30 10:16:34.881265+00	f	\N	32	Yamaha FZ V2 150cc (serial 2GSH3500-00) on INV-2026-00018	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
585	2026-07-30 18:27:06.781957+00	2026-07-30 18:27:06.781973+00	f	\N	122	Sujan Bastand, fruite	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
586	2026-07-30 18:27:14.839276+00	2026-07-30 18:27:14.839289+00	f	\N	22	INV-2026-00019	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
587	2026-07-30 18:27:56.788638+00	2026-07-30 18:27:56.788651+00	f	\N	37	Pulsar Polarize Paper Replace on INV-2026-00019	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
588	2026-07-30 18:27:56.808206+00	2026-07-30 18:27:56.808219+00	f	\N	1	Pulsar Polarized Paper (PP-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
589	2026-07-30 18:27:56.843921+00	2026-07-30 18:27:56.84393+00	f	\N	22	INV-2026-00019	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
590	2026-07-30 18:28:45.858948+00	2026-07-30 18:28:45.858964+00	f	\N	33	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00019	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
591	2026-07-30 18:28:45.867182+00	2026-07-30 18:28:45.867196+00	f	\N	38	Mileage Correction on INV-2026-00019	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
592	2026-07-30 18:28:45.909807+00	2026-07-30 18:28:45.909817+00	f	\N	22	INV-2026-00019	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
593	2026-07-31 08:34:55.898491+00	2026-07-31 08:34:55.898503+00	f	\N	14	1500.00 on INV-2026-00019	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
594	2026-07-31 08:34:55.929965+00	2026-07-31 08:34:55.929975+00	f	\N	22	INV-2026-00019	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
595	2026-07-31 08:34:55.987449+00	2026-07-31 08:34:55.987465+00	f	\N	33	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00019	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
596	2026-07-31 14:29:06.829446+00	2026-07-31 14:29:06.82946+00	f	\N	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	UPDATE	["last_login"]	9	9a259d21-6303-464d-97fe-23a835dfdc29
597	2026-07-31 14:30:21.696095+00	2026-07-31 14:30:21.696104+00	f	\N	f403c6e3-a6ab-46db-b10a-f7f87b941fce	Sadika Sabrin	CREATE	[]	9	9a259d21-6303-464d-97fe-23a835dfdc29
598	2026-07-31 14:31:10.729051+00	2026-07-31 14:31:10.72906+00	f	\N	15	400.00 on INV-2026-00011	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
599	2026-07-31 14:31:10.751533+00	2026-07-31 14:31:10.751544+00	f	\N	11	INV-2026-00011	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
600	2026-07-31 14:31:10.785258+00	2026-07-31 14:31:10.785271+00	f	\N	12	Bajaj Discover V18 110cc (serial None) on INV-2026-00011	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
601	2026-08-02 11:52:53.55575+00	2026-08-02 11:52:53.555759+00	f	\N	34	TVS Metro Plus 110cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
602	2026-08-02 11:52:53.583703+00	2026-08-02 11:52:53.583712+00	f	\N	39	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
603	2026-08-02 11:52:53.629427+00	2026-08-02 11:52:53.629441+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
604	2026-08-02 11:55:12.100807+00	2026-08-02 11:55:12.100814+00	f	\N	35	TVS Stryker 125cc (serial P10-39-10-00) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
605	2026-08-02 11:55:12.108564+00	2026-08-02 11:55:12.108572+00	f	\N	40	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
606	2026-08-02 11:55:12.136065+00	2026-08-02 11:55:12.136075+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
607	2026-08-02 12:49:49.781165+00	2026-08-02 12:49:49.781176+00	f	\N	123	Sharif Thana	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
608	2026-08-02 12:50:01.137656+00	2026-08-02 12:50:01.137668+00	f	\N	23	INV-2026-00020	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
609	2026-08-02 12:51:38.700174+00	2026-08-02 12:51:38.700187+00	f	\N	36	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00020	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
610	2026-08-02 12:51:38.716202+00	2026-08-02 12:51:38.716211+00	f	\N	41	Mileage Correction on INV-2026-00020	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
611	2026-08-02 12:51:38.745945+00	2026-08-02 12:51:38.745954+00	f	\N	23	INV-2026-00020	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
612	2026-08-02 12:53:07.709916+00	2026-08-02 12:53:07.709927+00	f	\N	37	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00020	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
613	2026-08-02 12:53:07.717824+00	2026-08-02 12:53:07.717835+00	f	\N	42	Mileage Correction on INV-2026-00020	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
614	2026-08-02 12:53:07.744821+00	2026-08-02 12:53:07.744834+00	f	\N	23	INV-2026-00020	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
615	2026-08-02 16:15:01.401918+00	2026-08-02 16:15:01.401932+00	f	\N	43	Display Replace on INV-2026-00009	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
616	2026-08-02 16:15:01.431806+00	2026-08-02 16:15:01.431822+00	f	\N	17	Gexxer Monotone Display (MEGMD-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
617	2026-08-02 16:15:01.47464+00	2026-08-02 16:15:01.474652+00	f	\N	9	INV-2026-00009	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
618	2026-08-02 16:16:03.412729+00	2026-08-02 16:16:03.41274+00	f	\N	17	Gexxer Monotone Display (MEGMD-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
619	2026-08-02 16:16:03.437683+00	2026-08-02 16:16:03.437699+00	f	\N	11	Display Replace on INV-2026-00003	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
620	2026-08-02 16:16:03.47654+00	2026-08-02 16:16:03.476556+00	f	\N	3	INV-2026-00003	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
621	2026-08-02 16:16:15.64393+00	2026-08-02 16:16:15.643943+00	f	\N	43	Display Replace on INV-2026-00009	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
622	2026-08-02 16:16:41.87117+00	2026-08-02 16:16:41.87118+00	f	\N	43	Display Replace on INV-2026-00009	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
623	2026-08-02 16:16:41.897585+00	2026-08-02 16:16:41.897599+00	f	\N	9	INV-2026-00009	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
624	2026-08-02 16:17:01.534587+00	2026-08-02 16:17:01.534597+00	f	\N	43	Display Replace on INV-2026-00009	UPDATE	["asset_used"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
625	2026-08-02 16:17:24.007211+00	2026-08-02 16:17:24.007223+00	f	\N	43	Display Replace on INV-2026-00009	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
626	2026-08-02 16:17:24.075715+00	2026-08-02 16:17:24.075727+00	f	\N	9	INV-2026-00009	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
627	2026-08-02 16:17:34.595936+00	2026-08-02 16:17:34.595944+00	f	\N	9	INV-2026-00009	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
628	2026-08-02 16:17:42.427951+00	2026-08-02 16:17:42.427964+00	f	\N	16	2100.00 on INV-2026-00009	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
629	2026-08-02 16:17:42.453308+00	2026-08-02 16:17:42.45332+00	f	\N	9	INV-2026-00009	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
630	2026-08-02 16:17:42.477639+00	2026-08-02 16:17:42.477651+00	f	\N	8	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191071) on INV-2026-00009	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
631	2026-08-02 16:18:12.990337+00	2026-08-02 16:18:12.99035+00	f	\N	17	800.00 on INV-2026-00020	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
632	2026-08-02 16:18:13.014276+00	2026-08-02 16:18:13.014286+00	f	\N	23	INV-2026-00020	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
633	2026-08-02 16:18:13.063361+00	2026-08-02 16:18:13.063374+00	f	\N	36	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00020	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
634	2026-08-02 16:18:13.08838+00	2026-08-02 16:18:13.088397+00	f	\N	37	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00020	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
635	2026-08-03 10:35:02.225622+00	2026-08-03 10:35:02.225638+00	f	\N	24	INV-2026-00021	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
636	2026-08-03 10:37:23.149333+00	2026-08-03 10:37:23.149344+00	f	\N	38	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00021	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
637	2026-08-03 10:37:23.161949+00	2026-08-03 10:37:23.16196+00	f	\N	44	Mileage Correction on INV-2026-00021	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
638	2026-08-03 10:37:23.183977+00	2026-08-03 10:37:23.183985+00	f	\N	24	INV-2026-00021	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
639	2026-08-03 10:38:41.263287+00	2026-08-03 10:38:41.263298+00	f	\N	38	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00021	UPDATE	["previous_km", "current_km"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
640	2026-08-03 10:40:03.56939+00	2026-08-03 10:40:03.569397+00	f	\N	39	Honda SP shine 100cc (serial None) on INV-2026-00021	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
641	2026-08-03 10:40:03.574168+00	2026-08-03 10:40:03.574176+00	f	\N	45	Mileage Correction on INV-2026-00021	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
642	2026-08-03 10:40:03.592099+00	2026-08-03 10:40:03.592108+00	f	\N	24	INV-2026-00021	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
643	2026-08-03 10:40:11.899211+00	2026-08-03 10:40:11.899225+00	f	\N	24	INV-2026-00021	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
644	2026-08-03 10:40:19.181597+00	2026-08-03 10:40:19.181607+00	f	\N	18	700.00 on INV-2026-00021	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
645	2026-08-03 10:40:19.201721+00	2026-08-03 10:40:19.201729+00	f	\N	24	INV-2026-00021	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
646	2026-08-03 10:40:19.22177+00	2026-08-03 10:40:19.221779+00	f	\N	38	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00021	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
647	2026-08-03 10:40:19.25353+00	2026-08-03 10:40:19.253542+00	f	\N	39	Honda SP shine 100cc (serial None) on INV-2026-00021	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
648	2026-08-03 14:24:53.206611+00	2026-08-03 14:24:53.206621+00	f	\N	25	INV-2026-00022	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
649	2026-08-03 14:27:15.75126+00	2026-08-03 14:27:15.751276+00	f	\N	40	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00022	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
650	2026-08-03 14:27:15.762809+00	2026-08-03 14:27:15.762817+00	f	\N	46	Mileage Correction on INV-2026-00022	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
651	2026-08-03 14:27:15.797218+00	2026-08-03 14:27:15.79724+00	f	\N	25	INV-2026-00022	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
652	2026-08-03 14:27:24.977325+00	2026-08-03 14:27:24.977338+00	f	\N	19	400.00 on INV-2026-00022	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
653	2026-08-03 14:27:24.997381+00	2026-08-03 14:27:24.997397+00	f	\N	25	INV-2026-00022	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
654	2026-08-03 14:27:25.02069+00	2026-08-03 14:27:25.020704+00	f	\N	40	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00022	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
655	2026-08-03 14:28:51.868236+00	2026-08-03 14:28:51.868246+00	f	\N	124	Nirab Sriboddi	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
656	2026-08-03 14:29:03.150185+00	2026-08-03 14:29:03.150192+00	f	\N	26	INV-2026-00023	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
657	2026-08-03 14:29:43.27606+00	2026-08-03 14:29:43.276074+00	f	\N	41	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00023	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
658	2026-08-03 14:29:43.280764+00	2026-08-03 14:29:43.280774+00	f	\N	47	Mileage Correction on INV-2026-00023	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
659	2026-08-03 14:29:43.296233+00	2026-08-03 14:29:43.296242+00	f	\N	26	INV-2026-00023	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
660	2026-08-03 16:14:18.62593+00	2026-08-03 16:14:18.625941+00	f	\N	13	INV-2026-00013	UPDATE	["status", "total_amount", "waived_amount", "waived_note"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
661	2026-08-04 07:33:59.508226+00	2026-08-04 07:33:59.508236+00	f	\N	27	INV-2026-00024	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
662	2026-08-04 07:35:13.323196+00	2026-08-04 07:35:13.32321+00	f	\N	42	Yamaha FZ V2 150cc (serial 2GS-H3500) on INV-2026-00024	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
663	2026-08-04 07:35:13.339363+00	2026-08-04 07:35:13.339378+00	f	\N	48	Mileage Correction on INV-2026-00024	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
664	2026-08-04 07:35:13.373608+00	2026-08-04 07:35:13.373622+00	f	\N	27	INV-2026-00024	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
665	2026-08-04 07:49:06.491826+00	2026-08-04 07:49:06.491836+00	f	\N	20	400.00 on INV-2026-00024	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
666	2026-08-04 07:49:06.544417+00	2026-08-04 07:49:06.544427+00	f	\N	27	INV-2026-00024	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
667	2026-08-04 07:49:06.590036+00	2026-08-04 07:49:06.590047+00	f	\N	42	Yamaha FZ V2 150cc (serial 2GS-H3500) on INV-2026-00024	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
668	2026-08-04 14:54:22.933466+00	2026-08-04 14:54:22.933475+00	f	\N	43	Yamaha FZ V3 150cc (serial None) on INV-2026-00015	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
669	2026-08-04 14:54:22.956822+00	2026-08-04 14:54:22.95683+00	f	\N	49	Mileage Correction on INV-2026-00015	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
670	2026-08-04 14:54:22.977777+00	2026-08-04 14:54:22.977785+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
671	2026-08-05 06:32:01.970288+00	2026-08-05 06:32:01.9703+00	f	\N	50	Display Repair on INV-2026-00015	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
672	2026-08-05 06:32:02.005146+00	2026-08-05 06:32:02.005157+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
673	2026-08-05 06:32:02.038951+00	2026-08-05 06:32:02.038961+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
674	2026-08-05 06:34:37.315417+00	2026-08-05 06:34:37.315431+00	f	\N	44	TVS Apache RTR 150cc (serial None) on INV-2026-00015	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
675	2026-08-05 06:34:37.323315+00	2026-08-05 06:34:37.323327+00	f	\N	51	Mileage Correction on INV-2026-00015	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
676	2026-08-05 06:34:37.349597+00	2026-08-05 06:34:37.349612+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
677	2026-08-05 06:35:31.967758+00	2026-08-05 06:35:31.967767+00	f	\N	45	TVS Apache RTR 150cc (serial None) on INV-2026-00015	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
678	2026-08-05 06:35:31.975355+00	2026-08-05 06:35:31.975364+00	f	\N	52	Mileage Correction on INV-2026-00015	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
679	2026-08-05 06:35:32.001424+00	2026-08-05 06:35:32.001439+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
680	2026-08-05 06:37:09.466126+00	2026-08-05 06:37:09.466134+00	f	\N	46	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00023	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
681	2026-08-05 06:37:09.473869+00	2026-08-05 06:37:09.473886+00	f	\N	53	Mileage Correction on INV-2026-00023	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
682	2026-08-05 06:37:09.497358+00	2026-08-05 06:37:09.497368+00	f	\N	26	INV-2026-00023	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
683	2026-08-05 06:37:20.078076+00	2026-08-05 06:37:20.078088+00	f	\N	53	Mileage Correction on INV-2026-00023	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
684	2026-08-05 06:37:29.451016+00	2026-08-05 06:37:29.451024+00	f	\N	21	800.00 on INV-2026-00023	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
685	2026-08-05 06:37:29.473821+00	2026-08-05 06:37:29.473828+00	f	\N	26	INV-2026-00023	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
686	2026-08-05 06:37:29.500423+00	2026-08-05 06:37:29.500434+00	f	\N	41	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00023	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
687	2026-08-05 06:37:29.524077+00	2026-08-05 06:37:29.524086+00	f	\N	46	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00023	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
688	2026-08-05 06:43:57.859394+00	2026-08-05 06:43:57.859407+00	f	\N	47	Gixxer Monotone 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
689	2026-08-05 06:43:57.864392+00	2026-08-05 06:43:57.864404+00	f	\N	54	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
690	2026-08-05 06:43:57.9116+00	2026-08-05 06:43:57.911623+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
691	2026-08-05 06:44:10.203391+00	2026-08-05 06:44:10.203401+00	f	\N	54	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
692	2026-08-05 15:49:59.643479+00	2026-08-05 15:49:59.643491+00	f	\N	28	INV-2026-00025	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
693	2026-08-05 15:50:45.977476+00	2026-08-05 15:50:45.977491+00	f	\N	48	Yamaha FZ V2 150cc (serial None) on INV-2026-00025	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
694	2026-08-05 15:50:45.994672+00	2026-08-05 15:50:45.994681+00	f	\N	55	Mileage Correction on INV-2026-00025	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
695	2026-08-05 15:50:46.029242+00	2026-08-05 15:50:46.029254+00	f	\N	28	INV-2026-00025	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
696	2026-08-05 15:51:34.950591+00	2026-08-05 15:51:34.950599+00	f	\N	29	INV-2026-00026	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
697	2026-08-05 15:52:26.33238+00	2026-08-05 15:52:26.332388+00	f	\N	49	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00026	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
698	2026-08-05 15:52:26.341066+00	2026-08-05 15:52:26.341074+00	f	\N	56	Mileage Correction on INV-2026-00026	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
699	2026-08-05 15:52:26.398982+00	2026-08-05 15:52:26.398997+00	f	\N	29	INV-2026-00026	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
700	2026-08-05 15:52:33.350232+00	2026-08-05 15:52:33.350248+00	f	\N	22	400.00 on INV-2026-00026	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
701	2026-08-05 15:52:33.376903+00	2026-08-05 15:52:33.376959+00	f	\N	29	INV-2026-00026	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
702	2026-08-05 15:52:33.420505+00	2026-08-05 15:52:33.42052+00	f	\N	49	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00026	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
703	2026-08-05 15:56:04.724672+00	2026-08-05 15:56:04.724683+00	f	\N	45	TVS Apache RTR 150cc (serial None) on INV-2026-00015	UPDATE	["mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
704	2026-08-05 16:41:43.824878+00	2026-08-05 16:41:43.82489+00	f	\N	23	400.00 on INV-2026-00025	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
705	2026-08-05 16:41:43.871444+00	2026-08-05 16:41:43.871458+00	f	\N	28	INV-2026-00025	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
706	2026-08-05 16:41:43.907911+00	2026-08-05 16:41:43.907952+00	f	\N	48	Yamaha FZ V2 150cc (serial None) on INV-2026-00025	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
707	2026-08-06 05:04:19.467189+00	2026-08-06 05:04:19.4672+00	f	\N	30	INV-2026-00027	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
708	2026-08-06 06:42:07.933842+00	2026-08-06 06:42:07.933855+00	f	\N	49	Installment #5 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
709	2026-08-06 07:28:48.182154+00	2026-08-06 07:28:48.182168+00	f	\N	50	Yamaha FZ V3 150cc (serial None) on INV-2026-00027	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
710	2026-08-06 07:28:48.21082+00	2026-08-06 07:28:48.210832+00	f	\N	57	Mileage Correction on INV-2026-00027	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
711	2026-08-06 07:28:48.240364+00	2026-08-06 07:28:48.240378+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
712	2026-08-06 07:29:33.726736+00	2026-08-06 07:29:33.726745+00	f	\N	58	Display Repair on INV-2026-00027	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
713	2026-08-06 07:29:33.744471+00	2026-08-06 07:29:33.744483+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
714	2026-08-06 07:29:33.813572+00	2026-08-06 07:29:33.813584+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
715	2026-08-06 07:30:32.419967+00	2026-08-06 07:30:32.419975+00	f	\N	51	TVS Apache RTR 150cc (serial None) on INV-2026-00027	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
716	2026-08-06 07:30:32.426217+00	2026-08-06 07:30:32.426224+00	f	\N	59	Mileage Correction on INV-2026-00027	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
717	2026-08-06 07:30:32.447533+00	2026-08-06 07:30:32.447543+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
718	2026-08-06 07:30:47.88149+00	2026-08-06 07:30:47.881506+00	f	\N	58	Display Repair on INV-2026-00027	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
719	2026-08-06 07:30:51.773225+00	2026-08-06 07:30:51.773241+00	f	\N	57	Mileage Correction on INV-2026-00027	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
720	2026-08-06 07:31:04.152241+00	2026-08-06 07:31:04.152254+00	f	\N	58	Display Repair on INV-2026-00027	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
721	2026-08-06 07:31:06.60573+00	2026-08-06 07:31:06.60574+00	f	\N	59	Mileage Correction on INV-2026-00027	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
722	2026-08-06 07:31:20.061049+00	2026-08-06 07:31:20.061068+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
723	2026-08-06 07:31:20.107691+00	2026-08-06 07:31:20.107707+00	f	\N	58	Display Repair on INV-2026-00027	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
724	2026-08-06 07:31:20.136883+00	2026-08-06 07:31:20.136895+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
725	2026-08-06 07:31:52.935322+00	2026-08-06 07:31:52.935329+00	f	\N	60	Display Replace on INV-2026-00027	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
726	2026-08-06 07:31:52.951774+00	2026-08-06 07:31:52.951784+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
727	2026-08-06 07:31:52.97826+00	2026-08-06 07:31:52.978272+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
728	2026-08-06 07:32:04.766945+00	2026-08-06 07:32:04.766959+00	f	\N	60	Display Replace on INV-2026-00027	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
729	2026-08-06 07:32:14.417143+00	2026-08-06 07:32:14.417156+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
730	2026-08-06 07:32:14.444098+00	2026-08-06 07:32:14.444112+00	f	\N	50	Display Repair on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
731	2026-08-06 07:32:14.470169+00	2026-08-06 07:32:14.470179+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
732	2026-08-06 07:32:20.29974+00	2026-08-06 07:32:20.299755+00	f	\N	51	Mileage Correction on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
733	2026-08-06 07:32:20.331909+00	2026-08-06 07:32:20.331921+00	f	\N	44	TVS Apache RTR 150cc (serial None) on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
734	2026-08-06 07:32:20.359744+00	2026-08-06 07:32:20.359755+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
735	2026-08-06 07:32:25.591287+00	2026-08-06 07:32:25.591301+00	f	\N	49	Mileage Correction on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
736	2026-08-06 07:32:25.629893+00	2026-08-06 07:32:25.629906+00	f	\N	43	Yamaha FZ V3 150cc (serial None) on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
737	2026-08-06 07:32:25.658038+00	2026-08-06 07:32:25.658051+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
738	2026-08-06 07:32:32.78979+00	2026-08-06 07:32:32.7898+00	f	\N	52	Mileage Correction on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
739	2026-08-06 07:32:32.821254+00	2026-08-06 07:32:32.821272+00	f	\N	45	TVS Apache RTR 150cc (serial None) on INV-2026-00015	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
740	2026-08-06 07:32:32.850609+00	2026-08-06 07:32:32.850624+00	f	\N	15	INV-2026-00015	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
741	2026-08-06 11:03:51.092967+00	2026-08-06 11:03:51.092981+00	f	\N	31	INV-2026-00028	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
742	2026-08-06 11:07:01.62939+00	2026-08-06 11:07:01.62941+00	f	\N	52	Yamaha FZ V2 150cc (serial None) on INV-2026-00028	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
743	2026-08-06 11:07:01.640346+00	2026-08-06 11:07:01.640355+00	f	\N	61	Mileage Correction on INV-2026-00028	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
744	2026-08-06 11:07:01.661003+00	2026-08-06 11:07:01.661038+00	f	\N	31	INV-2026-00028	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
745	2026-08-06 11:07:07.526417+00	2026-08-06 11:07:07.526429+00	f	\N	24	400.00 on INV-2026-00028	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
746	2026-08-06 11:07:07.543159+00	2026-08-06 11:07:07.543173+00	f	\N	31	INV-2026-00028	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
747	2026-08-06 11:07:07.561842+00	2026-08-06 11:07:07.561854+00	f	\N	52	Yamaha FZ V2 150cc (serial None) on INV-2026-00028	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
748	2026-08-06 11:07:35.012632+00	2026-08-06 11:07:35.012645+00	f	\N	32	INV-2026-00029	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
749	2026-08-06 11:08:13.929875+00	2026-08-06 11:08:13.929887+00	f	\N	53	Gixxer Monotone 155cc (serial None) on INV-2026-00029	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
750	2026-08-06 11:08:13.935589+00	2026-08-06 11:08:13.935607+00	f	\N	62	Mileage Correction on INV-2026-00029	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
751	2026-08-06 11:08:13.952225+00	2026-08-06 11:08:13.952241+00	f	\N	32	INV-2026-00029	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
752	2026-08-06 11:08:20.305863+00	2026-08-06 11:08:20.305873+00	f	\N	25	400.00 on INV-2026-00029	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
753	2026-08-06 11:08:20.321423+00	2026-08-06 11:08:20.321438+00	f	\N	32	INV-2026-00029	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
754	2026-08-06 11:08:20.34092+00	2026-08-06 11:08:20.340931+00	f	\N	53	Gixxer Monotone 155cc (serial None) on INV-2026-00029	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
755	2026-08-06 17:38:37.073965+00	2026-08-06 17:38:37.073982+00	f	\N	33	INV-2026-00030	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
756	2026-08-06 17:40:41.024536+00	2026-08-06 17:40:41.024546+00	f	\N	54	Gixxer Monotone 155cc (serial None) on INV-2026-00030	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
757	2026-08-06 17:40:41.040937+00	2026-08-06 17:40:41.040947+00	f	\N	63	Mileage Correction on INV-2026-00030	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
758	2026-08-06 17:40:41.077658+00	2026-08-06 17:40:41.077668+00	f	\N	33	INV-2026-00030	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
759	2026-08-06 17:40:46.440244+00	2026-08-06 17:40:46.44026+00	f	\N	26	400.00 on INV-2026-00030	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
760	2026-08-06 17:40:46.473061+00	2026-08-06 17:40:46.473075+00	f	\N	33	INV-2026-00030	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
761	2026-08-06 17:40:46.495655+00	2026-08-06 17:40:46.495666+00	f	\N	54	Gixxer Monotone 155cc (serial None) on INV-2026-00030	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
762	2026-08-06 17:42:24.834+00	2026-08-06 17:42:24.834033+00	f	\N	125	Faisal Mirgonj	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
763	2026-08-06 17:42:36.210507+00	2026-08-06 17:42:36.210516+00	f	\N	34	INV-2026-00031	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
764	2026-08-06 17:43:23.4+00	2026-08-06 17:43:23.400039+00	f	\N	55	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00031	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
765	2026-08-06 17:43:23.407488+00	2026-08-06 17:43:23.407502+00	f	\N	64	Mileage Correction on INV-2026-00031	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
766	2026-08-06 17:43:23.478167+00	2026-08-06 17:43:23.478181+00	f	\N	34	INV-2026-00031	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
767	2026-08-06 17:43:44.621376+00	2026-08-06 17:43:44.621406+00	f	\N	55	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00031	UPDATE	["mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
768	2026-08-06 17:43:44.645678+00	2026-08-06 17:43:44.645693+00	f	\N	64	Mileage Correction on INV-2026-00031	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
769	2026-08-06 17:43:44.706151+00	2026-08-06 17:43:44.706167+00	f	\N	34	INV-2026-00031	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
770	2026-08-06 17:43:50.573659+00	2026-08-06 17:43:50.57367+00	f	\N	27	500.00 on INV-2026-00031	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
771	2026-08-06 17:43:50.596824+00	2026-08-06 17:43:50.596834+00	f	\N	34	INV-2026-00031	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
772	2026-08-06 17:43:50.623294+00	2026-08-06 17:43:50.623307+00	f	\N	55	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00031	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
773	2026-08-06 17:48:45.51153+00	2026-08-06 17:48:45.511539+00	f	\N	126	Glamore	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
774	2026-08-06 17:49:03.387316+00	2026-08-06 17:49:03.387324+00	f	\N	35	INV-2026-00032	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
775	2026-08-06 17:50:17.359641+00	2026-08-06 17:50:17.359657+00	f	\N	56	TVS Metro Plus 110cc (serial None) on INV-2026-00032	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
776	2026-08-06 17:50:17.364784+00	2026-08-06 17:50:17.36479+00	f	\N	65	Mileage Correction on INV-2026-00032	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
777	2026-08-06 17:50:17.380937+00	2026-08-06 17:50:17.380945+00	f	\N	35	INV-2026-00032	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
778	2026-08-06 17:52:23.202788+00	2026-08-06 17:52:23.202801+00	f	\N	42	Hero DH647542AG 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
779	2026-08-06 17:53:38.766915+00	2026-08-06 17:53:38.766934+00	f	\N	42	Hero Glamour 125cc	UPDATE	["model"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
780	2026-08-06 17:54:20.260359+00	2026-08-06 17:54:20.26037+00	f	\N	56	TVS Metro Plus 110cc (serial None) on INV-2026-00032	UPDATE	["current_km"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
781	2026-08-06 17:54:58.393368+00	2026-08-06 17:54:58.393385+00	f	\N	57	Hero Glamour 125cc (serial None) on INV-2026-00032	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
782	2026-08-06 17:54:58.397962+00	2026-08-06 17:54:58.39797+00	f	\N	66	Mileage Correction on INV-2026-00032	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
783	2026-08-06 17:54:58.411911+00	2026-08-06 17:54:58.41192+00	f	\N	35	INV-2026-00032	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
899	2026-08-13 10:57:55.117054+00	2026-08-13 10:57:55.117065+00	f	\N	46	INV-2026-00043	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
784	2026-08-06 17:55:05.922399+00	2026-08-06 17:55:05.922411+00	f	\N	56	TVS Metro Plus 110cc (serial None) on INV-2026-00032	UPDATE	["mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
785	2026-08-06 17:55:27.181058+00	2026-08-06 17:55:27.181079+00	f	\N	28	1000.00 on INV-2026-00032	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
786	2026-08-06 17:55:27.198441+00	2026-08-06 17:55:27.198449+00	f	\N	35	INV-2026-00032	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
787	2026-08-06 17:55:27.217643+00	2026-08-06 17:55:27.217653+00	f	\N	56	TVS Metro Plus 110cc (serial None) on INV-2026-00032	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
788	2026-08-06 17:55:27.291808+00	2026-08-06 17:55:27.29182+00	f	\N	57	Hero Glamour 125cc (serial None) on INV-2026-00032	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
789	2026-08-08 04:58:13.714688+00	2026-08-08 04:58:13.7147+00	f	\N	30	INV-2026-00027	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
790	2026-08-08 04:58:25.752818+00	2026-08-08 04:58:25.752829+00	f	\N	29	2800.00 on INV-2026-00027	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
791	2026-08-08 04:58:25.77784+00	2026-08-08 04:58:25.777893+00	f	\N	30	INV-2026-00027	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
792	2026-08-08 04:58:25.81193+00	2026-08-08 04:58:25.811944+00	f	\N	50	Yamaha FZ V3 150cc (serial None) on INV-2026-00027	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
793	2026-08-08 04:58:25.845057+00	2026-08-08 04:58:25.845073+00	f	\N	51	TVS Apache RTR 150cc (serial None) on INV-2026-00027	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
794	2026-08-08 05:26:58.267463+00	2026-08-08 05:26:58.267472+00	f	\N	30	300.00 on INV-2026-00015	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
795	2026-08-08 05:26:58.305192+00	2026-08-08 05:26:58.305212+00	f	\N	15	INV-2026-00015	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
796	2026-08-08 05:26:58.340689+00	2026-08-08 05:26:58.340702+00	f	\N	13	Bajaj Discover V18 110cc (serial None) on INV-2026-00015	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
797	2026-08-08 05:27:17.129974+00	2026-08-08 05:27:17.129988+00	f	\N	15	INV-2026-00015	UPDATE	["status", "total_amount", "waived_amount", "waived_note"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
798	2026-08-08 11:41:15.717716+00	2026-08-08 11:41:15.717746+00	f	\N	43	Honda SP 125 FI ABS(2025) 125cc	CREATE	[]	12	9a259d21-6303-464d-97fe-23a835dfdc29
799	2026-08-08 11:41:41.692196+00	2026-08-08 11:41:41.692205+00	f	\N	36	INV-2026-00033	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
800	2026-08-08 11:42:41.1994+00	2026-08-08 11:42:41.199408+00	f	\N	58	Honda SP 125 FI ABS(2025) 125cc (serial None) on INV-2026-00033	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
801	2026-08-08 11:42:41.215281+00	2026-08-08 11:42:41.215297+00	f	\N	67	Mileage Correction on INV-2026-00033	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
802	2026-08-08 11:42:41.279575+00	2026-08-08 11:42:41.279591+00	f	\N	36	INV-2026-00033	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
803	2026-08-08 11:42:51.222788+00	2026-08-08 11:42:51.222806+00	f	\N	31	900.00 on INV-2026-00033	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
804	2026-08-08 11:42:51.24906+00	2026-08-08 11:42:51.249071+00	f	\N	36	INV-2026-00033	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
805	2026-08-08 11:42:51.273834+00	2026-08-08 11:42:51.273861+00	f	\N	58	Honda SP 125 FI ABS(2025) 125cc (serial None) on INV-2026-00033	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
806	2026-08-08 13:45:24.130479+00	2026-08-08 13:45:24.130497+00	f	\N	29	Khaled Mahmud Nagpara	UPDATE	["phone"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
807	2026-08-08 13:45:35.276153+00	2026-08-08 13:45:35.276167+00	f	\N	37	Abul Khayer - Haluaghat	UPDATE	["phone"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
808	2026-08-08 13:45:48.936948+00	2026-08-08 13:45:48.936961+00	f	\N	12	Akash Jinaighati	UPDATE	["phone"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
809	2026-08-08 13:46:06.342348+00	2026-08-08 13:46:06.342361+00	f	\N	43	Akij- Panir tank	UPDATE	["phone"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
810	2026-08-08 13:56:51.891406+00	2026-08-08 13:56:51.891422+00	f	\N	127	Customer 01	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
811	2026-08-08 13:57:05.303737+00	2026-08-08 13:57:05.303748+00	f	\N	37	INV-2026-00034	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
812	2026-08-08 13:58:20.94964+00	2026-08-08 13:58:20.949653+00	f	\N	59	Gixxer SF A5 155cc (serial None) on INV-2026-00034	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
813	2026-08-08 13:58:20.960488+00	2026-08-08 13:58:20.960498+00	f	\N	68	Mileage Correction on INV-2026-00034	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
814	2026-08-08 13:58:20.978645+00	2026-08-08 13:58:20.978655+00	f	\N	37	INV-2026-00034	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
815	2026-08-08 14:03:49.88674+00	2026-08-08 14:03:49.88675+00	f	\N	4	Bajaj Discover V18 110cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
816	2026-08-08 14:05:21.289838+00	2026-08-08 14:05:21.289853+00	f	\N	6	Bajaj Pulsar 4F 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
817	2026-08-08 14:05:57.650311+00	2026-08-08 14:05:57.650326+00	f	\N	5	Bajaj Pulsar 8F(UG3-UG5) 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
818	2026-08-08 14:06:25.168614+00	2026-08-08 14:06:25.168635+00	f	\N	7	Bajaj Pulsar ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
819	2026-08-08 14:32:13.720707+00	2026-08-08 14:32:13.720723+00	f	\N	8	Bajaj Pulsar Double ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
820	2026-08-08 14:32:54.167644+00	2026-08-08 14:32:54.167661+00	f	\N	9	Bajaj Pulsar Single Disk Double ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
821	2026-08-08 15:43:58.411574+00	2026-08-08 15:43:58.411589+00	f	\N	32	400.00 on INV-2026-00034	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
822	2026-08-08 15:43:58.446845+00	2026-08-08 15:43:58.446858+00	f	\N	37	INV-2026-00034	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
823	2026-08-08 15:43:58.472802+00	2026-08-08 15:43:58.472816+00	f	\N	59	Gixxer SF A5 155cc (serial None) on INV-2026-00034	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
824	2026-08-09 15:29:20.480218+00	2026-08-09 15:29:20.480227+00	f	\N	33	Mileage Correction on INV-2026-00014	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
825	2026-08-09 15:29:20.527695+00	2026-08-09 15:29:20.527704+00	f	\N	29	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00014	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
826	2026-08-09 15:29:20.566372+00	2026-08-09 15:29:20.566382+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
827	2026-08-09 15:29:33.353542+00	2026-08-09 15:29:33.353553+00	f	\N	14	INV-2026-00014	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
828	2026-08-09 15:29:42.445001+00	2026-08-09 15:29:42.445012+00	f	\N	33	1500.00 on INV-2026-00014	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
829	2026-08-09 15:29:42.469863+00	2026-08-09 15:29:42.469874+00	f	\N	14	INV-2026-00014	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
830	2026-08-09 15:30:12.623306+00	2026-08-09 15:30:12.623314+00	f	\N	38	INV-2026-00035	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
831	2026-08-09 15:30:25.778027+00	2026-08-09 15:30:25.778039+00	f	\N	60	TVS Metro Plus 110cc (serial None) on INV-2026-00035	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
832	2026-08-09 15:30:25.78751+00	2026-08-09 15:30:25.787523+00	f	\N	69	Mileage Correction on INV-2026-00035	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
833	2026-08-09 15:30:25.814978+00	2026-08-09 15:30:25.814992+00	f	\N	38	INV-2026-00035	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
834	2026-08-09 15:30:31.596453+00	2026-08-09 15:30:31.596461+00	f	\N	34	400.00 on INV-2026-00035	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
835	2026-08-09 15:30:31.623335+00	2026-08-09 15:30:31.623343+00	f	\N	38	INV-2026-00035	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
836	2026-08-09 15:30:31.647609+00	2026-08-09 15:30:31.647618+00	f	\N	60	TVS Metro Plus 110cc (serial None) on INV-2026-00035	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
837	2026-08-09 15:33:46.519549+00	2026-08-09 15:33:46.519564+00	f	\N	2	Display	CREATE	[]	24	9a259d21-6303-464d-97fe-23a835dfdc29
838	2026-08-09 15:35:23.40195+00	2026-08-09 15:35:23.401962+00	f	\N	2	Display	UPDATE	["description"]	24	9a259d21-6303-464d-97fe-23a835dfdc29
839	2026-08-09 15:36:13.827425+00	2026-08-09 15:36:13.827433+00	f	\N	3	SF FI ABS Meter Half Meter	CREATE	[]	24	9a259d21-6303-464d-97fe-23a835dfdc29
840	2026-08-09 15:37:56.490843+00	2026-08-09 15:37:56.490864+00	f	\N	18	SF FI ABS (MESFABS-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
900	2026-08-13 10:58:15.213191+00	2026-08-13 10:58:15.213249+00	f	\N	39	1800.00 on INV-2026-00043	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
841	2026-08-09 15:38:34.29924+00	2026-08-09 15:38:34.299248+00	f	\N	18	SF FI ABS (MESFABS-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
842	2026-08-09 15:38:34.315974+00	2026-08-09 15:38:34.315982+00	f	\N	17	1 x SF FI ABS on 2026-08-09	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
843	2026-08-10 08:56:46.009053+00	2026-08-10 08:56:46.009064+00	f	\N	39	INV-2026-00036	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
844	2026-08-10 08:58:02.644459+00	2026-08-10 08:58:02.64451+00	f	\N	61	Bajaj Discover CBS 110cc (serial None) on INV-2026-00036	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
845	2026-08-10 08:58:02.658971+00	2026-08-10 08:58:02.658983+00	f	\N	70	Mileage Correction on INV-2026-00036	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
846	2026-08-10 08:58:02.689122+00	2026-08-10 08:58:02.68913+00	f	\N	39	INV-2026-00036	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
847	2026-08-10 08:58:12.045972+00	2026-08-10 08:58:12.045985+00	f	\N	70	Mileage Correction on INV-2026-00036	UPDATE	["price_charged"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
848	2026-08-10 08:58:12.075791+00	2026-08-10 08:58:12.075803+00	f	\N	39	INV-2026-00036	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
849	2026-08-10 08:58:24.417812+00	2026-08-10 08:58:24.417826+00	f	\N	39	INV-2026-00036	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
850	2026-08-10 08:58:31.28461+00	2026-08-10 08:58:31.284626+00	f	\N	35	440.00 on INV-2026-00036	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
851	2026-08-10 08:58:31.309761+00	2026-08-10 08:58:31.309773+00	f	\N	39	INV-2026-00036	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
852	2026-08-10 08:58:31.33526+00	2026-08-10 08:58:31.335274+00	f	\N	61	Bajaj Discover CBS 110cc (serial None) on INV-2026-00036	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
853	2026-08-10 08:58:41.855981+00	2026-08-10 08:58:41.855989+00	f	\N	40	INV-2026-00037	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
854	2026-08-10 08:59:23.611724+00	2026-08-10 08:59:23.611735+00	f	\N	62	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00037	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
855	2026-08-10 08:59:23.619803+00	2026-08-10 08:59:23.619816+00	f	\N	71	Mileage Correction on INV-2026-00037	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
856	2026-08-10 08:59:23.647354+00	2026-08-10 08:59:23.647364+00	f	\N	40	INV-2026-00037	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
857	2026-08-10 08:59:31.70084+00	2026-08-10 08:59:31.700851+00	f	\N	40	INV-2026-00037	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
858	2026-08-10 08:59:40.606872+00	2026-08-10 08:59:40.606883+00	f	\N	36	470.00 on INV-2026-00037	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
859	2026-08-10 08:59:40.632363+00	2026-08-10 08:59:40.632372+00	f	\N	40	INV-2026-00037	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
860	2026-08-10 08:59:40.661573+00	2026-08-10 08:59:40.661587+00	f	\N	62	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00037	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
861	2026-08-11 18:33:24.412364+00	2026-08-11 18:33:24.412375+00	f	\N	41	INV-2026-00038	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
862	2026-08-11 18:34:59.528402+00	2026-08-11 18:34:59.528414+00	f	\N	128	Customer Kh 01	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
863	2026-08-11 18:35:11.584245+00	2026-08-11 18:35:11.584256+00	f	\N	41	INV-2026-00038	DELETE	["is_deleted", "deleted_at"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
864	2026-08-11 18:35:23.18511+00	2026-08-11 18:35:23.185123+00	f	\N	42	INV-2026-00039	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
865	2026-08-11 18:36:11.035453+00	2026-08-11 18:36:11.035465+00	f	\N	72	Pulsar Polarize Paper Replace on INV-2026-00039	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
866	2026-08-11 18:36:11.055325+00	2026-08-11 18:36:11.055341+00	f	\N	1	Pulsar Polarized Paper (PP-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
867	2026-08-11 18:36:11.078425+00	2026-08-11 18:36:11.078436+00	f	\N	42	INV-2026-00039	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
868	2026-08-11 18:39:29.895763+00	2026-08-11 18:39:29.895775+00	f	\N	63	TVS Stryker 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
869	2026-08-11 18:39:29.903162+00	2026-08-11 18:39:29.90317+00	f	\N	73	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
870	2026-08-11 18:39:29.926457+00	2026-08-11 18:39:29.926465+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
871	2026-08-11 18:40:37.146868+00	2026-08-11 18:40:37.146877+00	f	\N	64	Bajaj Discover V18 110cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
872	2026-08-11 18:40:37.153036+00	2026-08-11 18:40:37.153044+00	f	\N	74	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
873	2026-08-11 18:40:37.17471+00	2026-08-11 18:40:37.17472+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
874	2026-08-11 18:41:12.740836+00	2026-08-11 18:41:12.740845+00	f	\N	43	INV-2026-00040	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
875	2026-08-11 18:42:11.048961+00	2026-08-11 18:42:11.048975+00	f	\N	65	TVS Stryker 125cc (serial None) on INV-2026-00040	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
876	2026-08-11 18:42:11.055439+00	2026-08-11 18:42:11.055446+00	f	\N	75	Mileage Correction on INV-2026-00040	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
877	2026-08-11 18:42:11.077346+00	2026-08-11 18:42:11.077359+00	f	\N	43	INV-2026-00040	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
878	2026-08-12 07:07:21.801884+00	2026-08-12 07:07:21.8019+00	f	\N	66	Gixxer SF A5 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
879	2026-08-12 07:07:21.835446+00	2026-08-12 07:07:21.835457+00	f	\N	76	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
880	2026-08-12 07:07:21.867404+00	2026-08-12 07:07:21.867415+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
881	2026-08-12 15:06:09.209841+00	2026-08-12 15:06:09.209853+00	f	\N	37	1800.00 on INV-2026-00039	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
882	2026-08-12 15:06:09.24531+00	2026-08-12 15:06:09.245318+00	f	\N	42	INV-2026-00039	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
883	2026-08-12 15:10:09.94826+00	2026-08-12 15:10:09.948278+00	f	\N	44	INV-2026-00041	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
884	2026-08-12 15:11:22.929848+00	2026-08-12 15:11:22.929858+00	f	\N	67	TVS Apache RTR 150cc (serial None) on INV-2026-00041	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
885	2026-08-12 15:11:22.943416+00	2026-08-12 15:11:22.943424+00	f	\N	77	Mileage Correction on INV-2026-00041	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
886	2026-08-12 15:11:22.966401+00	2026-08-12 15:11:22.966413+00	f	\N	44	INV-2026-00041	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
887	2026-08-12 15:11:34.357875+00	2026-08-12 15:11:34.357884+00	f	\N	38	400.00 on INV-2026-00041	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
888	2026-08-12 15:11:34.378009+00	2026-08-12 15:11:34.378018+00	f	\N	44	INV-2026-00041	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
889	2026-08-12 15:11:34.404307+00	2026-08-12 15:11:34.404318+00	f	\N	67	TVS Apache RTR 150cc (serial None) on INV-2026-00041	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
890	2026-08-12 15:13:52.39199+00	2026-08-12 15:13:52.392004+00	f	\N	65	TVS Stryker 125cc (serial None) on INV-2026-00040	UPDATE	["mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
891	2026-08-12 15:14:28.937658+00	2026-08-12 15:14:28.937666+00	f	\N	45	INV-2026-00042	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
892	2026-08-12 15:15:24.73962+00	2026-08-12 15:15:24.739635+00	f	\N	68	TVS Apache RTR Horse 160cc (serial None) on INV-2026-00042	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
893	2026-08-12 15:15:24.751197+00	2026-08-12 15:15:24.751209+00	f	\N	78	Mileage Correction on INV-2026-00042	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
894	2026-08-12 15:15:24.824369+00	2026-08-12 15:15:24.824384+00	f	\N	45	INV-2026-00042	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
895	2026-08-13 03:44:36.761451+00	2026-08-13 03:44:36.761465+00	f	\N	50	Installment #6 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
896	2026-08-13 10:56:59.901566+00	2026-08-13 10:56:59.901578+00	f	\N	46	INV-2026-00043	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
897	2026-08-13 10:57:55.027668+00	2026-08-13 10:57:55.027683+00	f	\N	79	Display Replace on INV-2026-00043	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
898	2026-08-13 10:57:55.059666+00	2026-08-13 10:57:55.059677+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
901	2026-08-13 10:58:15.239121+00	2026-08-13 10:58:15.239131+00	f	\N	46	INV-2026-00043	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
902	2026-08-13 10:58:51.455538+00	2026-08-13 10:58:51.45555+00	f	\N	40	300.00 on INV-2026-00042	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
903	2026-08-13 10:58:51.480288+00	2026-08-13 10:58:51.4803+00	f	\N	45	INV-2026-00042	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
904	2026-08-13 10:58:51.512896+00	2026-08-13 10:58:51.512909+00	f	\N	68	TVS Apache RTR Horse 160cc (serial None) on INV-2026-00042	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
905	2026-08-13 10:59:03.591889+00	2026-08-13 10:59:03.591897+00	f	\N	47	INV-2026-00044	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
906	2026-08-13 11:00:26.284297+00	2026-08-13 11:00:26.284312+00	f	\N	69	Yamaha FZ V2 150cc (serial None) on INV-2026-00044	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
907	2026-08-13 11:00:26.291978+00	2026-08-13 11:00:26.291986+00	f	\N	80	Mileage Correction on INV-2026-00044	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
908	2026-08-13 11:00:26.317871+00	2026-08-13 11:00:26.31788+00	f	\N	47	INV-2026-00044	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
909	2026-08-13 12:23:24.008491+00	2026-08-13 12:23:24.008507+00	f	\N	41	400.00 on INV-2026-00040	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
910	2026-08-13 12:23:24.052303+00	2026-08-13 12:23:24.052315+00	f	\N	43	INV-2026-00040	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
911	2026-08-13 12:23:24.086558+00	2026-08-13 12:23:24.086576+00	f	\N	65	TVS Stryker 125cc (serial None) on INV-2026-00040	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
912	2026-08-13 12:23:41.263789+00	2026-08-13 12:23:41.263803+00	f	\N	42	400.00 on INV-2026-00044	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
913	2026-08-13 12:23:41.288847+00	2026-08-13 12:23:41.288856+00	f	\N	47	INV-2026-00044	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
914	2026-08-13 12:23:41.31745+00	2026-08-13 12:23:41.317462+00	f	\N	69	Yamaha FZ V2 150cc (serial None) on INV-2026-00044	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
915	2026-08-15 13:44:24.111844+00	2026-08-15 13:44:24.111861+00	f	\N	110	Noor Islam	UPDATE	["phone"]	10	9a259d21-6303-464d-97fe-23a835dfdc29
916	2026-08-15 13:44:36.007457+00	2026-08-15 13:44:36.007472+00	f	\N	48	INV-2026-00045	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
917	2026-08-15 13:45:43.35777+00	2026-08-15 13:45:43.357779+00	f	\N	70	Yamaha FZ V2 150cc (serial 2GSH3500-00) on INV-2026-00045	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
918	2026-08-15 13:45:43.368328+00	2026-08-15 13:45:43.368337+00	f	\N	81	Mileage Correction on INV-2026-00045	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
919	2026-08-15 13:45:43.386634+00	2026-08-15 13:45:43.386646+00	f	\N	48	INV-2026-00045	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
920	2026-08-15 13:46:28.630583+00	2026-08-15 13:46:28.630594+00	f	\N	71	Yamaha FZ V3 150cc (serial None) on INV-2026-00045	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
921	2026-08-15 13:46:28.634804+00	2026-08-15 13:46:28.634815+00	f	\N	82	Mileage Correction on INV-2026-00045	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
922	2026-08-15 13:46:28.65077+00	2026-08-15 13:46:28.650778+00	f	\N	48	INV-2026-00045	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
923	2026-08-15 13:46:41.589368+00	2026-08-15 13:46:41.589378+00	f	\N	70	Yamaha FZ V2 150cc (serial 2GSH3500-00) on INV-2026-00045	UPDATE	["mileage_correction_device"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
924	2026-08-17 11:30:23.280339+00	2026-08-17 11:30:23.280361+00	f	\N	72	Yamaha FZ V2 150cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
925	2026-08-17 11:30:23.333573+00	2026-08-17 11:30:23.333588+00	f	\N	83	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
926	2026-08-17 11:30:23.366172+00	2026-08-17 11:30:23.366181+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
927	2026-08-17 11:30:28.464035+00	2026-08-17 11:30:28.464046+00	f	\N	83	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
928	2026-08-17 11:30:55.587409+00	2026-08-17 11:30:55.587418+00	f	\N	73	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
929	2026-08-17 11:30:55.59531+00	2026-08-17 11:30:55.595324+00	f	\N	84	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
930	2026-08-17 11:30:55.622766+00	2026-08-17 11:30:55.622779+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
931	2026-08-17 11:31:02.881324+00	2026-08-17 11:31:02.881333+00	f	\N	84	Mileage Correction on INV-2026-00007	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
932	2026-08-17 11:31:21.570547+00	2026-08-17 11:31:21.570555+00	f	\N	49	INV-2026-00046	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
933	2026-08-17 11:31:55.518365+00	2026-08-17 11:31:55.518377+00	f	\N	74	TVS Apache 4V 1st 160cc (serial None) on INV-2026-00046	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
934	2026-08-17 11:31:55.525679+00	2026-08-17 11:31:55.525687+00	f	\N	85	Mileage Correction on INV-2026-00046	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
935	2026-08-17 11:31:55.551484+00	2026-08-17 11:31:55.551491+00	f	\N	49	INV-2026-00046	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
936	2026-08-17 11:32:02.8891+00	2026-08-17 11:32:02.889108+00	f	\N	43	400.00 on INV-2026-00046	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
937	2026-08-17 11:32:02.915696+00	2026-08-17 11:32:02.915709+00	f	\N	49	INV-2026-00046	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
938	2026-08-17 11:32:02.947962+00	2026-08-17 11:32:02.947977+00	f	\N	74	TVS Apache 4V 1st 160cc (serial None) on INV-2026-00046	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
939	2026-08-17 21:10:48.504828+00	2026-08-17 21:10:48.504837+00	f	\N	44	1400.00 on INV-2026-00045	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
940	2026-08-17 21:10:48.543987+00	2026-08-17 21:10:48.543998+00	f	\N	48	INV-2026-00045	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
941	2026-08-17 21:10:48.578594+00	2026-08-17 21:10:48.578602+00	f	\N	70	Yamaha FZ V2 150cc (serial 2GSH3500-00) on INV-2026-00045	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
942	2026-08-17 21:10:48.604763+00	2026-08-17 21:10:48.604776+00	f	\N	71	Yamaha FZ V3 150cc (serial None) on INV-2026-00045	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
943	2026-08-18 11:17:18.173572+00	2026-08-18 11:17:18.173594+00	f	\N	75	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
944	2026-08-18 11:17:18.201689+00	2026-08-18 11:17:18.201701+00	f	\N	86	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
945	2026-08-18 11:17:18.230299+00	2026-08-18 11:17:18.230309+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
946	2026-08-18 11:35:45.335121+00	2026-08-18 11:35:45.335141+00	f	\N	50	INV-2026-00047	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
947	2026-08-18 11:37:01.743244+00	2026-08-18 11:37:01.743255+00	f	\N	76	TVS Apache 4V 160cc (serial None) on INV-2026-00047	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
948	2026-08-18 11:37:01.759937+00	2026-08-18 11:37:01.759947+00	f	\N	87	Mileage Correction on INV-2026-00047	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
949	2026-08-18 11:37:01.793939+00	2026-08-18 11:37:01.793949+00	f	\N	50	INV-2026-00047	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
950	2026-08-18 11:37:10.206671+00	2026-08-18 11:37:10.206678+00	f	\N	45	400.00 on INV-2026-00047	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
951	2026-08-18 11:37:10.231705+00	2026-08-18 11:37:10.231713+00	f	\N	50	INV-2026-00047	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
952	2026-08-18 11:37:10.261596+00	2026-08-18 11:37:10.261604+00	f	\N	76	TVS Apache 4V 160cc (serial None) on INV-2026-00047	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
953	2026-08-18 11:37:29.09172+00	2026-08-18 11:37:29.091728+00	f	\N	51	INV-2026-00048	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
954	2026-08-18 11:38:22.157102+00	2026-08-18 11:38:22.157111+00	f	\N	77	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00048	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
955	2026-08-18 11:38:22.164708+00	2026-08-18 11:38:22.164716+00	f	\N	88	Mileage Correction on INV-2026-00048	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
956	2026-08-18 11:38:22.187638+00	2026-08-18 11:38:22.187648+00	f	\N	51	INV-2026-00048	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
957	2026-08-18 11:38:29.836151+00	2026-08-18 11:38:29.83616+00	f	\N	46	400.00 on INV-2026-00048	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
958	2026-08-18 11:38:29.860982+00	2026-08-18 11:38:29.860992+00	f	\N	51	INV-2026-00048	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
959	2026-08-18 11:38:29.891043+00	2026-08-18 11:38:29.891055+00	f	\N	77	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00048	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
960	2026-08-18 11:39:01.438936+00	2026-08-18 11:39:01.438948+00	f	\N	52	INV-2026-00049	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
961	2026-08-18 11:41:37.476761+00	2026-08-18 11:41:37.476775+00	f	\N	19	Polarize Paper replace (LPPreplace-01)	CREATE	[]	15	9a259d21-6303-464d-97fe-23a835dfdc29
962	2026-08-18 11:42:29.641362+00	2026-08-18 11:42:29.641377+00	f	\N	19	Polarize Paper replace (LPPreplace-01)	UPDATE	["buy_price", "current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
963	2026-08-18 11:42:29.659276+00	2026-08-18 11:42:29.659295+00	f	\N	18	5 x Polarize Paper replace on 2026-08-18	CREATE	[]	16	9a259d21-6303-464d-97fe-23a835dfdc29
964	2026-08-18 11:44:58.786319+00	2026-08-18 11:44:58.786332+00	f	\N	9	Discover Polarized paper replace	CREATE	[]	13	9a259d21-6303-464d-97fe-23a835dfdc29
965	2026-08-18 11:47:13.436078+00	2026-08-18 11:47:13.436087+00	f	\N	89	Discover Polarized paper replace on INV-2026-00049	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
966	2026-08-18 11:47:13.453089+00	2026-08-18 11:47:13.453099+00	f	\N	19	Polarize Paper replace (LPPreplace-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
967	2026-08-18 11:47:13.479033+00	2026-08-18 11:47:13.479043+00	f	\N	52	INV-2026-00049	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
968	2026-08-18 11:47:24.24898+00	2026-08-18 11:47:24.248992+00	f	\N	47	1000.00 on INV-2026-00049	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
969	2026-08-18 11:47:24.275158+00	2026-08-18 11:47:24.27517+00	f	\N	52	INV-2026-00049	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
970	2026-08-18 14:18:55.615899+00	2026-08-18 14:18:55.615913+00	f	\N	78	Bajaj Discover CBS 110cc (serial None) on INV-2026-00049	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
971	2026-08-18 14:18:55.655823+00	2026-08-18 14:18:55.655835+00	f	\N	78	Bajaj Discover CBS 110cc (serial None) on INV-2026-00049	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
972	2026-08-18 14:18:55.668465+00	2026-08-18 14:18:55.668474+00	f	\N	90	Mileage Correction on INV-2026-00049	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
973	2026-08-18 14:18:55.69963+00	2026-08-18 14:18:55.699641+00	f	\N	52	INV-2026-00049	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
974	2026-08-18 14:19:16.329331+00	2026-08-18 14:19:16.329346+00	f	\N	52	INV-2026-00049	UPDATE	["total_amount", "discount_amount", "discount_note"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
975	2026-08-18 17:06:04.411006+00	2026-08-18 17:06:04.411016+00	f	\N	79	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00042	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
976	2026-08-18 17:06:04.447839+00	2026-08-18 17:06:04.447852+00	f	\N	68	TVS Apache RTR Horse 160cc (serial None) on INV-2026-00042	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
977	2026-08-18 17:06:04.466176+00	2026-08-18 17:06:04.466187+00	f	\N	79	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00042	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
978	2026-08-18 17:06:04.477332+00	2026-08-18 17:06:04.477342+00	f	\N	91	Mileage Correction on INV-2026-00042	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
979	2026-08-18 17:06:04.498227+00	2026-08-18 17:06:04.498235+00	f	\N	45	INV-2026-00042	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
980	2026-08-19 11:40:04.412074+00	2026-08-19 11:40:04.412092+00	f	\N	53	INV-2026-00050	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
981	2026-08-19 11:41:02.389921+00	2026-08-19 11:41:02.389929+00	f	\N	80	TVS Metro Plus 110cc (serial None) on INV-2026-00050	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
982	2026-08-19 11:41:02.405245+00	2026-08-19 11:41:02.405252+00	f	\N	92	Mileage Correction on INV-2026-00050	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
983	2026-08-19 11:41:02.433952+00	2026-08-19 11:41:02.433961+00	f	\N	53	INV-2026-00050	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
984	2026-08-19 11:41:23.217998+00	2026-08-19 11:41:23.218012+00	f	\N	48	400.00 on INV-2026-00050	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
985	2026-08-19 11:41:23.243676+00	2026-08-19 11:41:23.243687+00	f	\N	53	INV-2026-00050	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
986	2026-08-19 11:41:23.273295+00	2026-08-19 11:41:23.273311+00	f	\N	80	TVS Metro Plus 110cc (serial None) on INV-2026-00050	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
987	2026-08-20 06:45:38.539012+00	2026-08-20 06:45:38.539027+00	f	\N	51	Installment #7 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
988	2026-08-20 14:55:18.686389+00	2026-08-20 14:55:18.686399+00	f	\N	54	INV-2026-00051	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
989	2026-08-20 14:56:12.832612+00	2026-08-20 14:56:12.832621+00	f	\N	81	TVS Metro Plus 110cc (serial None) on INV-2026-00051	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
990	2026-08-20 14:56:12.845831+00	2026-08-20 14:56:12.845838+00	f	\N	93	Mileage Correction on INV-2026-00051	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
991	2026-08-20 14:56:12.876273+00	2026-08-20 14:56:12.876282+00	f	\N	54	INV-2026-00051	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
992	2026-08-20 14:56:20.728512+00	2026-08-20 14:56:20.728529+00	f	\N	49	400.00 on INV-2026-00051	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
993	2026-08-20 14:56:20.756819+00	2026-08-20 14:56:20.756833+00	f	\N	54	INV-2026-00051	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
994	2026-08-20 14:56:20.792886+00	2026-08-20 14:56:20.792902+00	f	\N	81	TVS Metro Plus 110cc (serial None) on INV-2026-00051	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
995	2026-08-20 14:56:46.876681+00	2026-08-20 14:56:46.876693+00	f	\N	55	INV-2026-00052	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
996	2026-08-20 14:57:03.180875+00	2026-08-20 14:57:03.18089+00	f	\N	82	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00052	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
997	2026-08-20 14:57:03.190819+00	2026-08-20 14:57:03.190832+00	f	\N	94	Mileage Correction on INV-2026-00052	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
998	2026-08-20 14:57:03.260643+00	2026-08-20 14:57:03.260655+00	f	\N	55	INV-2026-00052	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
999	2026-08-20 14:57:09.019817+00	2026-08-20 14:57:09.019827+00	f	\N	50	400.00 on INV-2026-00052	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1000	2026-08-20 14:57:09.045089+00	2026-08-20 14:57:09.045101+00	f	\N	55	INV-2026-00052	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1001	2026-08-20 14:57:09.070927+00	2026-08-20 14:57:09.070939+00	f	\N	82	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00052	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1002	2026-08-20 14:57:31.197321+00	2026-08-20 14:57:31.197334+00	f	\N	56	INV-2026-00053	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1003	2026-08-20 14:58:45.207844+00	2026-08-20 14:58:45.207856+00	f	\N	95	Display Replace on INV-2026-00053	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1004	2026-08-20 14:58:45.231044+00	2026-08-20 14:58:45.231056+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
1005	2026-08-20 14:58:45.271763+00	2026-08-20 14:58:45.271776+00	f	\N	56	INV-2026-00053	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1006	2026-08-20 14:59:20.910338+00	2026-08-20 14:59:20.910351+00	f	\N	83	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00053	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1007	2026-08-20 14:59:20.919271+00	2026-08-20 14:59:20.919285+00	f	\N	96	Mileage Correction on INV-2026-00053	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1008	2026-08-20 14:59:20.970551+00	2026-08-20 14:59:20.970569+00	f	\N	56	INV-2026-00053	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1009	2026-08-20 18:13:14.332312+00	2026-08-20 18:13:14.332326+00	f	\N	57	INV-2026-00054	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1010	2026-08-20 18:13:59.309307+00	2026-08-20 18:13:59.309321+00	f	\N	84	Gixxer SF A5 155cc (serial None) on INV-2026-00054	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1011	2026-08-20 18:13:59.326772+00	2026-08-20 18:13:59.326783+00	f	\N	97	Mileage Correction on INV-2026-00054	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1012	2026-08-20 18:13:59.360577+00	2026-08-20 18:13:59.360591+00	f	\N	57	INV-2026-00054	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1013	2026-08-20 18:14:16.527201+00	2026-08-20 18:14:16.527214+00	f	\N	51	400.00 on INV-2026-00054	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1014	2026-08-20 18:14:16.556604+00	2026-08-20 18:14:16.556616+00	f	\N	57	INV-2026-00054	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1015	2026-08-20 18:14:16.625718+00	2026-08-20 18:14:16.625731+00	f	\N	84	Gixxer SF A5 155cc (serial None) on INV-2026-00054	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1016	2026-08-23 09:03:14.832448+00	2026-08-23 09:03:14.832461+00	f	\N	58	INV-2026-00055	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1017	2026-08-23 09:04:11.370168+00	2026-08-23 09:04:11.370178+00	f	\N	85	TVS Apache RTR 160cc (serial None) on INV-2026-00055	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1018	2026-08-23 09:04:11.383486+00	2026-08-23 09:04:11.383497+00	f	\N	98	Mileage Correction on INV-2026-00055	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1019	2026-08-23 09:04:11.409273+00	2026-08-23 09:04:11.409286+00	f	\N	58	INV-2026-00055	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1020	2026-08-23 09:04:18.227017+00	2026-08-23 09:04:18.227028+00	f	\N	52	400.00 on INV-2026-00055	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1021	2026-08-23 09:04:18.251213+00	2026-08-23 09:04:18.251225+00	f	\N	58	INV-2026-00055	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1022	2026-08-23 09:04:18.279818+00	2026-08-23 09:04:18.279831+00	f	\N	85	TVS Apache RTR 160cc (serial None) on INV-2026-00055	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1023	2026-08-23 09:04:26.672512+00	2026-08-23 09:04:26.672519+00	f	\N	59	INV-2026-00056	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1024	2026-08-23 09:05:08.020482+00	2026-08-23 09:05:08.020494+00	f	\N	86	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00056	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1025	2026-08-23 09:05:08.0277+00	2026-08-23 09:05:08.027707+00	f	\N	99	Mileage Correction on INV-2026-00056	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1026	2026-08-23 09:05:08.050804+00	2026-08-23 09:05:08.050811+00	f	\N	59	INV-2026-00056	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1027	2026-08-23 13:02:04.881626+00	2026-08-23 13:02:04.881639+00	f	\N	60	INV-2026-00057	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1028	2026-08-23 13:04:40.137295+00	2026-08-23 13:04:40.137306+00	f	\N	87	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00057	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1029	2026-08-23 13:04:40.151593+00	2026-08-23 13:04:40.151605+00	f	\N	100	Mileage Correction on INV-2026-00057	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1030	2026-08-23 13:04:40.193236+00	2026-08-23 13:04:40.193261+00	f	\N	60	INV-2026-00057	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1031	2026-08-23 13:04:46.117265+00	2026-08-23 13:04:46.117275+00	f	\N	53	400.00 on INV-2026-00057	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1032	2026-08-23 13:04:46.139733+00	2026-08-23 13:04:46.139744+00	f	\N	60	INV-2026-00057	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1033	2026-08-23 13:04:46.196845+00	2026-08-23 13:04:46.19686+00	f	\N	87	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00057	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1034	2026-08-23 13:05:49.916361+00	2026-08-23 13:05:49.916371+00	f	\N	54	1400.00 on INV-2026-00053	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1035	2026-08-23 13:05:50.180441+00	2026-08-23 13:05:50.18045+00	f	\N	56	INV-2026-00053	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1036	2026-08-23 13:05:50.201459+00	2026-08-23 13:05:50.201471+00	f	\N	83	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00053	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1037	2026-08-23 13:06:22.93112+00	2026-08-23 13:06:22.931129+00	f	\N	55	300.00 on INV-2026-00056	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1038	2026-08-23 13:06:22.952352+00	2026-08-23 13:06:22.952359+00	f	\N	59	INV-2026-00056	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1039	2026-08-23 13:06:22.978854+00	2026-08-23 13:06:22.978869+00	f	\N	86	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00056	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1040	2026-08-23 17:14:26.900175+00	2026-08-23 17:14:26.9002+00	f	\N	d22d666c-5236-4abd-a8c4-6b3f8e03fa48	verify_curl_temp@test.local	CREATE	[]	9	\N
1041	2026-08-23 17:17:33.033584+00	2026-08-23 17:17:33.033621+00	f	\N	d22d666c-5236-4abd-a8c4-6b3f8e03fa48	verify_curl_temp@test.local	DELETE	[]	9	\N
1042	2026-08-23 17:27:59.864506+00	2026-08-23 17:27:59.864536+00	f	\N	c28a846d-0e23-4df3-933d-2f01a564587c	verify_flip_temp@test.local	CREATE	[]	9	\N
1043	2026-08-23 17:31:18.713191+00	2026-08-23 17:31:18.713208+00	f	\N	c28a846d-0e23-4df3-933d-2f01a564587c	verify_flip_temp@test.local	DELETE	[]	9	\N
1044	2026-08-23 17:46:12.61423+00	2026-08-23 17:46:12.614249+00	f	\N	333bf690-640e-4a1a-9358-bcd55e0db31b	verify_prod_temp@test.local	CREATE	[]	9	\N
1045	2026-08-23 17:48:12.124375+00	2026-08-23 17:48:12.124391+00	f	\N	333bf690-640e-4a1a-9358-bcd55e0db31b	verify_prod_temp@test.local	DELETE	[]	9	\N
1046	2026-08-24 12:21:37.372982+00	2026-08-24 12:21:37.37299+00	f	\N	88	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00049	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1047	2026-08-24 12:21:37.407303+00	2026-08-24 12:21:37.407312+00	f	\N	78	Bajaj Discover CBS 110cc (serial None) on INV-2026-00049	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1048	2026-08-24 12:21:37.44831+00	2026-08-24 12:21:37.44832+00	f	\N	88	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00049	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1049	2026-08-24 12:21:37.461225+00	2026-08-24 12:21:37.461235+00	f	\N	101	Mileage Correction on INV-2026-00049	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1050	2026-08-24 12:21:37.486828+00	2026-08-24 12:21:37.486839+00	f	\N	52	INV-2026-00049	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1051	2026-08-24 12:21:49.556347+00	2026-08-24 12:21:49.556359+00	f	\N	56	600.00 on INV-2026-00049	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1052	2026-08-24 12:21:49.575944+00	2026-08-24 12:21:49.575957+00	f	\N	52	INV-2026-00049	UPDATE	["paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1053	2026-08-24 12:21:49.594459+00	2026-08-24 12:21:49.594469+00	f	\N	78	Bajaj Discover CBS 110cc (serial None) on INV-2026-00049	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1054	2026-08-24 12:21:49.652818+00	2026-08-24 12:21:49.652831+00	f	\N	88	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00049	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1055	2026-08-24 12:25:25.25428+00	2026-08-24 12:25:25.254288+00	f	\N	129	Unknown Customer Discover	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
1056	2026-08-24 12:25:35.868926+00	2026-08-24 12:25:35.868935+00	f	\N	61	INV-2026-00058	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1057	2026-08-24 12:26:15.959734+00	2026-08-24 12:26:15.959742+00	f	\N	102	Display Repair on INV-2026-00058	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1058	2026-08-24 12:26:15.975733+00	2026-08-24 12:26:15.975743+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
1059	2026-08-24 12:26:15.99599+00	2026-08-24 12:26:15.995998+00	f	\N	61	INV-2026-00058	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1060	2026-08-24 12:26:24.113775+00	2026-08-24 12:26:24.113786+00	f	\N	57	1200.00 on INV-2026-00058	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1061	2026-08-24 12:26:24.13505+00	2026-08-24 12:26:24.135069+00	f	\N	61	INV-2026-00058	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1062	2026-08-25 07:07:06.851163+00	2026-08-25 07:07:06.851173+00	f	\N	89	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1063	2026-08-25 07:07:06.879532+00	2026-08-25 07:07:06.879541+00	f	\N	103	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1064	2026-08-25 07:07:06.907819+00	2026-08-25 07:07:06.907831+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1065	2026-08-26 15:08:40.538743+00	2026-08-26 15:08:40.538761+00	f	\N	104	Display Repair on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1066	2026-08-26 15:08:40.568313+00	2026-08-26 15:08:40.568324+00	f	\N	12	Discover 110 & 125 display 2018v (MED11D2018v-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
1067	2026-08-26 15:08:40.597862+00	2026-08-26 15:08:40.597874+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1068	2026-08-26 15:09:38.433064+00	2026-08-26 15:09:38.433076+00	f	\N	90	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1069	2026-08-26 15:09:38.439743+00	2026-08-26 15:09:38.439751+00	f	\N	105	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1070	2026-08-26 15:09:38.461455+00	2026-08-26 15:09:38.461463+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1071	2026-08-26 15:10:22.110957+00	2026-08-26 15:10:22.110969+00	f	\N	58	1500.00 on INV-2026-00007	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1072	2026-08-26 15:10:22.136868+00	2026-08-26 15:10:22.136882+00	f	\N	7	INV-2026-00007	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1073	2026-08-26 15:10:22.166125+00	2026-08-26 15:10:22.16614+00	f	\N	7	Bajaj Discover 5Gear 125cc (serial JZ 402422 0024) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1074	2026-08-26 15:10:22.186744+00	2026-08-26 15:10:22.186763+00	f	\N	17	TVS Metro Plus 110cc (serial A2C1297290101) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1075	2026-08-26 15:10:22.23796+00	2026-08-26 15:10:22.237978+00	f	\N	18	Gixxer SF A2 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1076	2026-08-26 15:10:22.259811+00	2026-08-26 15:10:22.259825+00	f	\N	19	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1077	2026-08-26 15:10:22.279537+00	2026-08-26 15:10:22.279552+00	f	\N	20	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1078	2026-08-26 15:10:22.300256+00	2026-08-26 15:10:22.300273+00	f	\N	21	Honda SP shine 100cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1079	2026-08-26 15:10:22.359734+00	2026-08-26 15:10:22.35975+00	f	\N	22	Honda Hornet 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1080	2026-08-26 15:10:22.382438+00	2026-08-26 15:10:22.382453+00	f	\N	23	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1081	2026-08-26 15:10:22.448554+00	2026-08-26 15:10:22.448569+00	f	\N	24	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1082	2026-08-26 15:10:22.469365+00	2026-08-26 15:10:22.469379+00	f	\N	25	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1083	2026-08-26 15:10:22.490028+00	2026-08-26 15:10:22.490042+00	f	\N	26	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1084	2026-08-26 15:10:22.549646+00	2026-08-26 15:10:22.549661+00	f	\N	27	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1085	2026-08-26 15:10:22.574301+00	2026-08-26 15:10:22.574314+00	f	\N	34	TVS Metro Plus 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1086	2026-08-26 15:10:22.644175+00	2026-08-26 15:10:22.644188+00	f	\N	35	TVS Stryker 125cc (serial P10-39-10-00) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1087	2026-08-26 15:10:22.665568+00	2026-08-26 15:10:22.665583+00	f	\N	47	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1088	2026-08-26 15:10:22.69003+00	2026-08-26 15:10:22.690044+00	f	\N	63	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1089	2026-08-26 15:10:22.756844+00	2026-08-26 15:10:22.756857+00	f	\N	64	Bajaj Discover V18 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1090	2026-08-26 15:10:22.78101+00	2026-08-26 15:10:22.781022+00	f	\N	66	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1091	2026-08-26 15:10:22.838132+00	2026-08-26 15:10:22.83815+00	f	\N	72	Yamaha FZ V2 150cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1092	2026-08-26 15:10:22.860579+00	2026-08-26 15:10:22.860598+00	f	\N	73	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1093	2026-08-26 15:10:22.889727+00	2026-08-26 15:10:22.889743+00	f	\N	75	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1094	2026-08-26 15:10:22.945203+00	2026-08-26 15:10:22.945217+00	f	\N	89	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1095	2026-08-26 15:10:22.967115+00	2026-08-26 15:10:22.967129+00	f	\N	90	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1096	2026-08-26 15:14:40.136733+00	2026-08-26 15:14:40.136751+00	f	\N	4	Bajaj Discover V18 110cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1097	2026-08-26 15:16:00.010835+00	2026-08-26 15:16:00.010845+00	f	\N	6	Bajaj Pulsar 4F 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1098	2026-08-26 15:16:26.59434+00	2026-08-26 15:16:26.594359+00	f	\N	5	Bajaj Pulsar 8F(UG3-UG5) 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1099	2026-08-26 15:16:46.327317+00	2026-08-26 15:16:46.327328+00	f	\N	7	Bajaj Pulsar ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1100	2026-08-26 15:17:05.470748+00	2026-08-26 15:17:05.470759+00	f	\N	8	Bajaj Pulsar Double ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1101	2026-08-26 15:17:25.850814+00	2026-08-26 15:17:25.850823+00	f	\N	9	Bajaj Pulsar Single Disk Double ABS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1102	2026-08-26 15:18:37.516224+00	2026-08-26 15:18:37.516235+00	f	\N	12	Gixxer SF A2 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1103	2026-08-26 15:18:51.11623+00	2026-08-26 15:18:51.116239+00	f	\N	13	Gixxer SF A3 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1104	2026-08-26 15:19:16.911454+00	2026-08-26 15:19:16.911465+00	f	\N	14	Gixxer SF A5 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1105	2026-08-26 15:19:57.493948+00	2026-08-26 15:19:57.493957+00	f	\N	15	Gixxer SF A6 155cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1106	2026-08-26 15:21:37.627846+00	2026-08-26 15:21:37.627858+00	f	\N	40	Honda Hornet 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1107	2026-08-26 15:22:13.935909+00	2026-08-26 15:22:13.935922+00	f	\N	36	Honda SP 125cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1108	2026-08-26 15:23:53.387912+00	2026-08-26 15:23:53.387927+00	f	\N	26	TVS Apache 4V 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1109	2026-08-26 15:24:14.286933+00	2026-08-26 15:24:14.286948+00	f	\N	24	TVS Apache 4V X Connect 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1110	2026-08-26 15:24:43.640436+00	2026-08-26 15:24:43.640451+00	f	\N	43	Honda SP 125 FI ABS(2025) 125cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1111	2026-08-26 15:25:15.835712+00	2026-08-26 15:25:15.835725+00	f	\N	22	TVS Apache RTR 160cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1112	2026-08-26 15:26:45.90425+00	2026-08-26 15:26:45.904262+00	f	\N	19	Yamaha FZS 150cc	UPDATE	["image"]	12	9a259d21-6303-464d-97fe-23a835dfdc29
1113	2026-08-27 04:54:39.202407+00	2026-08-27 04:54:39.20242+00	f	\N	52	Installment #8 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1114	2026-08-27 04:55:35.916154+00	2026-08-27 04:55:35.916164+00	f	\N	51	Installment #7 for Pridim Foundation	UPDATE	["attachment"]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1115	2026-08-27 04:56:08.214105+00	2026-08-27 04:56:08.214114+00	f	\N	50	Installment #6 for Pridim Foundation	UPDATE	["attachment"]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1116	2026-08-27 04:56:37.116196+00	2026-08-27 04:56:37.116206+00	f	\N	49	Installment #5 for Pridim Foundation	UPDATE	["attachment"]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1117	2026-08-27 04:56:50.820298+00	2026-08-27 04:56:50.820307+00	f	\N	48	Installment #4 for Pridim Foundation	UPDATE	["attachment"]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1118	2026-08-27 04:57:09.824639+00	2026-08-27 04:57:09.824648+00	f	\N	3	Installment #3 for Pridim Foundation	UPDATE	["attachment"]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1119	2026-08-27 07:42:28.928903+00	2026-08-27 07:42:28.928915+00	f	\N	104	Display Repair on INV-2026-00007	UPDATE	["price_charged", "product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1120	2026-08-27 09:49:55.296774+00	2026-08-27 09:49:55.296783+00	f	\N	91	Gixxer Monotone 155cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1121	2026-08-27 09:49:55.362292+00	2026-08-27 09:49:55.362305+00	f	\N	7	Bajaj Discover 5Gear 125cc (serial JZ 402422 0024) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1122	2026-08-27 09:49:55.382722+00	2026-08-27 09:49:55.382731+00	f	\N	17	TVS Metro Plus 110cc (serial A2C1297290101) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1123	2026-08-27 09:49:55.404882+00	2026-08-27 09:49:55.404892+00	f	\N	18	Gixxer SF A2 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1124	2026-08-27 09:49:55.462898+00	2026-08-27 09:49:55.46291+00	f	\N	19	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1125	2026-08-27 09:49:55.484821+00	2026-08-27 09:49:55.484832+00	f	\N	20	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1126	2026-08-27 09:49:55.50628+00	2026-08-27 09:49:55.506291+00	f	\N	21	Honda SP shine 100cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1127	2026-08-27 09:49:55.527716+00	2026-08-27 09:49:55.527731+00	f	\N	22	Honda Hornet 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1128	2026-08-27 09:49:55.575764+00	2026-08-27 09:49:55.575775+00	f	\N	23	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1129	2026-08-27 09:49:55.595827+00	2026-08-27 09:49:55.595837+00	f	\N	24	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1130	2026-08-27 09:49:55.616937+00	2026-08-27 09:49:55.616949+00	f	\N	25	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1131	2026-08-27 09:49:55.667503+00	2026-08-27 09:49:55.667514+00	f	\N	26	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1132	2026-08-27 09:49:55.688373+00	2026-08-27 09:49:55.688384+00	f	\N	27	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1133	2026-08-27 09:49:55.71527+00	2026-08-27 09:49:55.715283+00	f	\N	34	TVS Metro Plus 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1134	2026-08-27 09:49:55.777891+00	2026-08-27 09:49:55.777903+00	f	\N	35	TVS Stryker 125cc (serial P10-39-10-00) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1135	2026-08-27 09:49:55.799705+00	2026-08-27 09:49:55.799719+00	f	\N	47	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1136	2026-08-27 09:49:55.824458+00	2026-08-27 09:49:55.82447+00	f	\N	63	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1137	2026-08-27 09:49:55.878371+00	2026-08-27 09:49:55.878388+00	f	\N	64	Bajaj Discover V18 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1138	2026-08-27 09:49:55.906703+00	2026-08-27 09:49:55.906717+00	f	\N	66	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1139	2026-08-27 09:49:55.959799+00	2026-08-27 09:49:55.959817+00	f	\N	72	Yamaha FZ V2 150cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1140	2026-08-27 09:49:55.983378+00	2026-08-27 09:49:55.983387+00	f	\N	73	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1141	2026-08-27 09:49:56.012248+00	2026-08-27 09:49:56.012279+00	f	\N	75	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1142	2026-08-27 09:49:56.071935+00	2026-08-27 09:49:56.071948+00	f	\N	89	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1143	2026-08-27 09:49:56.095685+00	2026-08-27 09:49:56.095702+00	f	\N	90	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1144	2026-08-27 09:49:56.12482+00	2026-08-27 09:49:56.124831+00	f	\N	91	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1145	2026-08-27 09:49:56.159426+00	2026-08-27 09:49:56.159437+00	f	\N	106	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1146	2026-08-27 09:49:56.190644+00	2026-08-27 09:49:56.190653+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1147	2026-08-27 10:01:36.728358+00	2026-08-27 10:01:36.728381+00	f	\N	130	test cust	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
1148	2026-08-27 10:01:43.346818+00	2026-08-27 10:01:43.346835+00	f	\N	62	INV-2026-00059	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1149	2026-08-27 10:02:34.659796+00	2026-08-27 10:02:34.659813+00	f	\N	92	Bajaj Discover 4Gear 110cc (serial None) on INV-2026-00059	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1150	2026-08-27 10:02:34.895774+00	2026-08-27 10:02:34.895802+00	f	\N	107	Mileage Correction on INV-2026-00059	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1151	2026-08-27 10:02:35.468153+00	2026-08-27 10:02:35.468187+00	f	\N	62	INV-2026-00059	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1152	2026-08-27 10:02:52.300474+00	2026-08-27 10:02:52.300502+00	f	\N	107	Mileage Correction on INV-2026-00059	DELETE	["is_deleted", "deleted_at"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1153	2026-08-27 10:02:52.873976+00	2026-08-27 10:02:52.874+00	f	\N	92	Bajaj Discover 4Gear 110cc (serial None) on INV-2026-00059	DELETE	["is_deleted", "deleted_at"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1154	2026-08-27 10:02:53.453812+00	2026-08-27 10:02:53.453824+00	f	\N	62	INV-2026-00059	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1155	2026-08-27 10:12:52.87318+00	2026-08-27 10:12:52.873198+00	f	\N	59	400.00 on INV-2026-00003	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1156	2026-08-27 10:12:53.410366+00	2026-08-27 10:12:53.410398+00	f	\N	3	INV-2026-00003	UPDATE	["paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1157	2026-08-27 10:12:54.133472+00	2026-08-27 10:12:54.133494+00	f	\N	3	Gixxer Monotone 155cc (serial None) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1158	2026-08-27 10:12:54.758189+00	2026-08-27 10:12:54.758213+00	f	\N	9	Bajaj Discover 5Gear 125cc (serial JZ402422) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1159	2026-08-27 10:12:55.35935+00	2026-08-27 10:12:55.359389+00	f	\N	30	Gixxer Monotone 155cc (serial 34134J0) on INV-2026-00003	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1160	2026-08-29 17:13:29.165135+00	2026-08-29 17:13:29.16515+00	f	\N	63	INV-2026-00060	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1161	2026-08-29 17:14:28.523638+00	2026-08-29 17:14:28.523648+00	f	\N	108	Discover Polarized paper replace on INV-2026-00060	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1162	2026-08-29 17:14:28.551273+00	2026-08-29 17:14:28.55128+00	f	\N	63	INV-2026-00060	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1163	2026-08-29 17:14:36.031774+00	2026-08-29 17:14:36.031791+00	f	\N	60	1200.00 on INV-2026-00060	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1164	2026-08-29 17:14:36.054926+00	2026-08-29 17:14:36.05494+00	f	\N	63	INV-2026-00060	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1165	2026-08-30 10:17:54.217713+00	2026-08-30 10:17:54.217728+00	f	\N	45	INV-2026-00042	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1166	2026-08-30 10:18:00.945363+00	2026-08-30 10:18:00.945373+00	f	\N	61	400.00 on INV-2026-00042	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1167	2026-08-30 10:18:00.96991+00	2026-08-30 10:18:00.96992+00	f	\N	45	INV-2026-00042	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1168	2026-08-30 10:18:01.011928+00	2026-08-30 10:18:01.011945+00	f	\N	68	TVS Apache RTR Horse 160cc (serial None) on INV-2026-00042	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1169	2026-08-30 10:18:01.036773+00	2026-08-30 10:18:01.036785+00	f	\N	79	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00042	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1170	2026-09-01 16:58:34.437178+00	2026-09-01 16:58:34.43719+00	f	\N	64	INV-2026-00061	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1171	2026-09-01 16:59:32.901979+00	2026-09-01 16:59:32.90199+00	f	\N	93	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00061	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1172	2026-09-01 16:59:32.919316+00	2026-09-01 16:59:32.919327+00	f	\N	109	Mileage Correction on INV-2026-00061	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1173	2026-09-01 16:59:32.950604+00	2026-09-01 16:59:32.950614+00	f	\N	64	INV-2026-00061	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1174	2026-09-01 16:59:41.060875+00	2026-09-01 16:59:41.060887+00	f	\N	62	400.00 on INV-2026-00061	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1175	2026-09-01 16:59:41.088252+00	2026-09-01 16:59:41.088264+00	f	\N	64	INV-2026-00061	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1176	2026-09-01 16:59:41.124086+00	2026-09-01 16:59:41.124104+00	f	\N	93	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00061	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1177	2026-09-01 17:00:10.703455+00	2026-09-01 17:00:10.703473+00	f	\N	65	INV-2026-00062	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1178	2026-09-01 17:00:50.548742+00	2026-09-01 17:00:50.548752+00	f	\N	94	Yamaha FZ V2 150cc (serial None) on INV-2026-00062	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1179	2026-09-01 17:00:50.557517+00	2026-09-01 17:00:50.557525+00	f	\N	110	Mileage Correction on INV-2026-00062	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1180	2026-09-01 17:00:50.584373+00	2026-09-01 17:00:50.58438+00	f	\N	65	INV-2026-00062	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1181	2026-09-01 17:00:58.60427+00	2026-09-01 17:00:58.604281+00	f	\N	63	500.00 on INV-2026-00062	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1182	2026-09-01 17:00:58.631077+00	2026-09-01 17:00:58.631088+00	f	\N	65	INV-2026-00062	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1183	2026-09-01 17:00:58.669285+00	2026-09-01 17:00:58.6693+00	f	\N	94	Yamaha FZ V2 150cc (serial None) on INV-2026-00062	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1184	2026-09-01 17:01:15.178493+00	2026-09-01 17:01:15.178503+00	f	\N	66	INV-2026-00063	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1185	2026-09-01 17:03:22.11646+00	2026-09-01 17:03:22.116476+00	f	\N	95	Yamaha FZ V2 150cc (serial None) on INV-2026-00063	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1186	2026-09-01 17:03:22.136589+00	2026-09-01 17:03:22.136603+00	f	\N	111	Mileage Correction on INV-2026-00063	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1187	2026-09-01 17:03:22.167394+00	2026-09-01 17:03:22.167406+00	f	\N	66	INV-2026-00063	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1188	2026-09-01 17:03:27.832751+00	2026-09-01 17:03:27.83276+00	f	\N	111	Mileage Correction on INV-2026-00063	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1189	2026-09-01 17:03:57.139566+00	2026-09-01 17:03:57.139576+00	f	\N	67	INV-2026-00064	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1190	2026-09-01 17:04:40.443962+00	2026-09-01 17:04:40.44397+00	f	\N	96	Bajaj Discover V18 110cc (serial None) on INV-2026-00064	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1191	2026-09-01 17:04:40.451556+00	2026-09-01 17:04:40.451564+00	f	\N	112	Mileage Correction on INV-2026-00064	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1192	2026-09-01 17:04:40.479215+00	2026-09-01 17:04:40.479224+00	f	\N	67	INV-2026-00064	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1193	2026-09-01 17:04:43.89621+00	2026-09-01 17:04:43.896225+00	f	\N	112	Mileage Correction on INV-2026-00064	UPDATE	["added_date"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1194	2026-09-01 17:04:56.463424+00	2026-09-01 17:04:56.463432+00	f	\N	64	300.00 on INV-2026-00064	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1195	2026-09-01 17:04:56.49857+00	2026-09-01 17:04:56.49858+00	f	\N	67	INV-2026-00064	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1196	2026-09-01 17:04:56.528518+00	2026-09-01 17:04:56.528535+00	f	\N	96	Bajaj Discover V18 110cc (serial None) on INV-2026-00064	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1197	2026-09-03 08:30:51.173659+00	2026-09-03 08:30:51.17367+00	f	\N	113	Display Replace on INV-2026-00063	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1198	2026-09-03 08:30:51.206576+00	2026-09-03 08:30:51.206592+00	f	\N	3	RTR Display All V (MERDAV-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
1199	2026-09-03 08:30:51.246811+00	2026-09-03 08:30:51.246825+00	f	\N	66	INV-2026-00063	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1200	2026-09-03 08:31:49.740512+00	2026-09-03 08:31:49.740524+00	f	\N	114	Display Repair on INV-2026-00064	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1201	2026-09-03 08:31:49.762604+00	2026-09-03 08:31:49.762615+00	f	\N	67	INV-2026-00064	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1202	2026-09-03 08:32:05.391415+00	2026-09-03 08:32:05.391427+00	f	\N	68	INV-2026-00065	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1203	2026-09-03 08:32:39.446549+00	2026-09-03 08:32:39.446559+00	f	\N	115	Display Repair on INV-2026-00065	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1204	2026-09-03 08:32:39.460505+00	2026-09-03 08:32:39.460513+00	f	\N	14	Discover Display Grear (MEDDGrear-01)	UPDATE	["current_stock_quantity"]	15	9a259d21-6303-464d-97fe-23a835dfdc29
1205	2026-09-03 08:32:39.487131+00	2026-09-03 08:32:39.487141+00	f	\N	68	INV-2026-00065	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1206	2026-09-03 08:33:58.46133+00	2026-09-03 08:33:58.461343+00	f	\N	97	Bajaj Discover V18 110cc (serial None) on INV-2026-00056	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1207	2026-09-03 08:33:58.500517+00	2026-09-03 08:33:58.500533+00	f	\N	86	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00056	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1208	2026-09-03 08:33:58.524495+00	2026-09-03 08:33:58.52451+00	f	\N	97	Bajaj Discover V18 110cc (serial None) on INV-2026-00056	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1209	2026-09-03 08:33:58.529125+00	2026-09-03 08:33:58.529137+00	f	\N	116	Mileage Correction on INV-2026-00056	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1210	2026-09-03 08:33:58.600743+00	2026-09-03 08:33:58.600754+00	f	\N	59	INV-2026-00056	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1211	2026-09-03 08:34:04.449082+00	2026-09-03 08:34:04.449094+00	f	\N	59	INV-2026-00056	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1212	2026-09-03 08:34:09.749419+00	2026-09-03 08:34:09.74943+00	f	\N	65	400.00 on INV-2026-00056	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1213	2026-09-03 08:34:09.770227+00	2026-09-03 08:34:09.770236+00	f	\N	59	INV-2026-00056	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1214	2026-09-03 08:34:09.7926+00	2026-09-03 08:34:09.792611+00	f	\N	86	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00056	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1215	2026-09-03 08:34:09.813431+00	2026-09-03 08:34:09.813442+00	f	\N	97	Bajaj Discover V18 110cc (serial None) on INV-2026-00056	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1216	2026-09-03 15:37:06.623257+00	2026-09-03 15:37:06.623269+00	f	\N	66	500.00 on INV-2026-00065	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1217	2026-09-03 15:37:06.658142+00	2026-09-03 15:37:06.658177+00	f	\N	68	INV-2026-00065	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1218	2026-09-03 15:37:59.613524+00	2026-09-03 15:37:59.613534+00	f	\N	53	Installment #9 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1219	2026-09-03 17:00:56.804394+00	2026-09-03 17:00:56.804419+00	f	\N	69	INV-2026-00066	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1220	2026-09-03 17:01:20.745996+00	2026-09-03 17:01:20.746007+00	f	\N	98	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00066	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1221	2026-09-03 17:01:20.761606+00	2026-09-03 17:01:20.76162+00	f	\N	117	Mileage Correction on INV-2026-00066	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1222	2026-09-03 17:01:20.787962+00	2026-09-03 17:01:20.787978+00	f	\N	69	INV-2026-00066	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1223	2026-09-03 17:02:38.526741+00	2026-09-03 17:02:38.52675+00	f	\N	99	Gixxer SF A2 155cc (serial None) on INV-2026-00066	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1224	2026-09-03 17:02:38.534586+00	2026-09-03 17:02:38.534598+00	f	\N	118	Mileage Correction on INV-2026-00066	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1225	2026-09-03 17:02:38.563262+00	2026-09-03 17:02:38.56328+00	f	\N	69	INV-2026-00066	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1226	2026-09-03 17:03:36.030612+00	2026-09-03 17:03:36.03062+00	f	\N	100	Gixxer SF A5 155cc (serial None) on INV-2026-00066	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1227	2026-09-03 17:03:36.038311+00	2026-09-03 17:03:36.038323+00	f	\N	119	Mileage Correction on INV-2026-00066	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1228	2026-09-03 17:03:36.058961+00	2026-09-03 17:03:36.058974+00	f	\N	69	INV-2026-00066	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1229	2026-09-03 17:03:48.683257+00	2026-09-03 17:03:48.683274+00	f	\N	67	1000.00 on INV-2026-00066	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1230	2026-09-03 17:03:48.709479+00	2026-09-03 17:03:48.709493+00	f	\N	69	INV-2026-00066	UPDATE	["status", "paid_amount", "had_shortfall"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1231	2026-09-03 17:03:48.770845+00	2026-09-03 17:03:48.770857+00	f	\N	98	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00066	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1232	2026-09-03 17:03:48.792182+00	2026-09-03 17:03:48.792193+00	f	\N	99	Gixxer SF A2 155cc (serial None) on INV-2026-00066	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1233	2026-09-03 17:03:48.813945+00	2026-09-03 17:03:48.813961+00	f	\N	100	Gixxer SF A5 155cc (serial None) on INV-2026-00066	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1234	2026-09-03 17:04:04.452056+00	2026-09-03 17:04:04.452065+00	f	\N	69	INV-2026-00066	UPDATE	["status", "total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1235	2026-09-03 17:04:36.396633+00	2026-09-03 17:04:36.396641+00	f	\N	70	INV-2026-00067	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1236	2026-09-03 17:05:28.705683+00	2026-09-03 17:05:28.705709+00	f	\N	101	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00067	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1237	2026-09-03 17:05:28.714258+00	2026-09-03 17:05:28.714269+00	f	\N	120	Mileage Correction on INV-2026-00067	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1238	2026-09-03 17:05:28.773759+00	2026-09-03 17:05:28.773773+00	f	\N	70	INV-2026-00067	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1239	2026-09-03 17:05:38.112106+00	2026-09-03 17:05:38.112117+00	f	\N	68	400.00 on INV-2026-00067	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1240	2026-09-03 17:05:38.135696+00	2026-09-03 17:05:38.13571+00	f	\N	70	INV-2026-00067	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1241	2026-09-03 17:05:38.162875+00	2026-09-03 17:05:38.162886+00	f	\N	101	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00067	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1242	2026-09-03 17:06:29.865838+00	2026-09-03 17:06:29.865845+00	f	\N	102	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00007	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1243	2026-09-03 17:06:29.892358+00	2026-09-03 17:06:29.892367+00	f	\N	7	Bajaj Discover 5Gear 125cc (serial JZ 402422 0024) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1244	2026-09-03 17:06:29.908299+00	2026-09-03 17:06:29.908308+00	f	\N	17	TVS Metro Plus 110cc (serial A2C1297290101) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1245	2026-09-03 17:06:29.964541+00	2026-09-03 17:06:29.964554+00	f	\N	18	Gixxer SF A2 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1246	2026-09-03 17:06:29.983591+00	2026-09-03 17:06:29.983604+00	f	\N	19	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1247	2026-09-03 17:06:30.005173+00	2026-09-03 17:06:30.005188+00	f	\N	20	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1248	2026-09-03 17:06:30.061542+00	2026-09-03 17:06:30.061553+00	f	\N	21	Honda SP shine 100cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1249	2026-09-03 17:06:30.088052+00	2026-09-03 17:06:30.088063+00	f	\N	22	Honda Hornet 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1250	2026-09-03 17:06:30.12571+00	2026-09-03 17:06:30.125721+00	f	\N	23	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1251	2026-09-03 17:06:30.176071+00	2026-09-03 17:06:30.176082+00	f	\N	24	TVS Apache 4V X Connect 160cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1252	2026-09-03 17:06:30.207251+00	2026-09-03 17:06:30.207262+00	f	\N	25	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1253	2026-09-03 17:06:30.255516+00	2026-09-03 17:06:30.25553+00	f	\N	26	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1254	2026-09-03 17:06:30.296951+00	2026-09-03 17:06:30.296962+00	f	\N	27	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1255	2026-09-03 17:06:30.375739+00	2026-09-03 17:06:30.375755+00	f	\N	34	TVS Metro Plus 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1256	2026-09-03 17:06:30.467236+00	2026-09-03 17:06:30.467254+00	f	\N	35	TVS Stryker 125cc (serial P10-39-10-00) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1257	2026-09-03 17:06:30.487431+00	2026-09-03 17:06:30.487445+00	f	\N	47	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1258	2026-09-03 17:06:30.508996+00	2026-09-03 17:06:30.509007+00	f	\N	63	TVS Stryker 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1259	2026-09-03 17:06:30.560923+00	2026-09-03 17:06:30.560935+00	f	\N	64	Bajaj Discover V18 110cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1260	2026-09-03 17:06:30.582905+00	2026-09-03 17:06:30.582916+00	f	\N	66	Gixxer SF A5 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1261	2026-09-03 17:06:30.601036+00	2026-09-03 17:06:30.601049+00	f	\N	72	Yamaha FZ V2 150cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1262	2026-09-03 17:06:30.655649+00	2026-09-03 17:06:30.655663+00	f	\N	73	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1263	2026-09-03 17:06:30.68042+00	2026-09-03 17:06:30.680431+00	f	\N	75	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1264	2026-09-03 17:06:30.701554+00	2026-09-03 17:06:30.701564+00	f	\N	89	Gixxer Monotone 155cc (serial 341-34J0) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1265	2026-09-03 17:06:30.755531+00	2026-09-03 17:06:30.755545+00	f	\N	90	Bajaj Discover 5Gear 125cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1266	2026-09-03 17:06:30.780058+00	2026-09-03 17:06:30.780073+00	f	\N	91	Gixxer Monotone 155cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1267	2026-09-03 17:06:30.802669+00	2026-09-03 17:06:30.802681+00	f	\N	102	Bajaj Pulsar 8F(UG3-UG5) 150cc (serial None) on INV-2026-00007	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1268	2026-09-03 17:06:30.807653+00	2026-09-03 17:06:30.807662+00	f	\N	121	Mileage Correction on INV-2026-00007	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1269	2026-09-03 17:06:30.868792+00	2026-09-03 17:06:30.868802+00	f	\N	7	INV-2026-00007	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1270	2026-09-04 16:54:53.053629+00	2026-09-04 16:54:53.053639+00	f	\N	115	Display Repair on INV-2026-00065	UPDATE	["product_price"]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1271	2026-09-04 16:54:53.099419+00	2026-09-04 16:54:53.099428+00	f	\N	68	INV-2026-00065	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1272	2026-09-04 16:55:03.431662+00	2026-09-04 16:55:03.431675+00	f	\N	69	900.00 on INV-2026-00065	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1273	2026-09-04 16:55:03.458122+00	2026-09-04 16:55:03.45813+00	f	\N	68	INV-2026-00065	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1274	2026-09-05 11:06:49.700986+00	2026-09-05 11:06:49.701001+00	f	\N	71	INV-2026-00068	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1275	2026-09-05 11:07:51.606235+00	2026-09-05 11:07:51.606251+00	f	\N	122	Display Replace on INV-2026-00068	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1276	2026-09-05 11:07:51.637504+00	2026-09-05 11:07:51.637519+00	f	\N	71	INV-2026-00068	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1277	2026-09-06 12:08:01.654863+00	2026-09-06 12:08:01.654871+00	f	\N	70	1500.00 on INV-2026-00068	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1278	2026-09-06 12:08:01.694825+00	2026-09-06 12:08:01.694834+00	f	\N	71	INV-2026-00068	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1279	2026-09-06 12:08:20.39811+00	2026-09-06 12:08:20.39812+00	f	\N	66	INV-2026-00063	UPDATE	["total_amount", "discount_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1280	2026-09-06 12:08:28.02129+00	2026-09-06 12:08:28.021302+00	f	\N	71	1500.00 on INV-2026-00063	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1281	2026-09-06 12:08:28.048171+00	2026-09-06 12:08:28.048184+00	f	\N	66	INV-2026-00063	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1282	2026-09-06 12:08:28.08124+00	2026-09-06 12:08:28.081256+00	f	\N	95	Yamaha FZ V2 150cc (serial None) on INV-2026-00063	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1283	2026-09-06 12:10:07.460367+00	2026-09-06 12:10:07.46038+00	f	\N	131	CID	CREATE	[]	10	9a259d21-6303-464d-97fe-23a835dfdc29
1284	2026-09-06 12:10:22.132595+00	2026-09-06 12:10:22.13261+00	f	\N	72	INV-2026-00069	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1285	2026-09-06 12:10:42.892169+00	2026-09-06 12:10:42.892179+00	f	\N	123	Mainboard Repair on INV-2026-00069	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1286	2026-09-06 12:10:42.921057+00	2026-09-06 12:10:42.921065+00	f	\N	72	INV-2026-00069	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1287	2026-09-06 12:10:53.071577+00	2026-09-06 12:10:53.071586+00	f	\N	72	3500.00 on INV-2026-00069	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1288	2026-09-06 12:10:53.100666+00	2026-09-06 12:10:53.100674+00	f	\N	72	INV-2026-00069	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1289	2026-09-06 12:11:08.162632+00	2026-09-06 12:11:08.16264+00	f	\N	73	INV-2026-00070	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1290	2026-09-06 12:11:27.196555+00	2026-09-06 12:11:27.196565+00	f	\N	103	TVS Metro Plus 110cc (serial None) on INV-2026-00070	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1291	2026-09-06 12:11:27.207272+00	2026-09-06 12:11:27.207279+00	f	\N	124	Mileage Correction on INV-2026-00070	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1292	2026-09-06 12:11:27.26136+00	2026-09-06 12:11:27.261374+00	f	\N	73	INV-2026-00070	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1293	2026-09-06 12:11:32.738263+00	2026-09-06 12:11:32.738276+00	f	\N	73	400.00 on INV-2026-00070	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1294	2026-09-06 12:11:32.773361+00	2026-09-06 12:11:32.773377+00	f	\N	73	INV-2026-00070	UPDATE	["status", "paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1295	2026-09-06 12:11:32.809566+00	2026-09-06 12:11:32.809582+00	f	\N	103	TVS Metro Plus 110cc (serial None) on INV-2026-00070	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1296	2026-09-08 06:03:16.130237+00	2026-09-08 06:03:16.130254+00	f	\N	74	INV-2026-00071	CREATE	[]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1297	2026-09-08 06:03:46.465474+00	2026-09-08 06:03:46.465489+00	f	\N	104	Bajaj Discover V18 110cc (serial None) on INV-2026-00071	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1298	2026-09-08 06:03:46.478582+00	2026-09-08 06:03:46.478595+00	f	\N	125	Mileage Correction on INV-2026-00071	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1299	2026-09-08 06:03:46.499702+00	2026-09-08 06:03:46.499716+00	f	\N	74	INV-2026-00071	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1300	2026-09-11 15:08:52.007395+00	2026-09-11 15:08:52.007412+00	f	\N	54	Installment #10 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1301	2026-09-11 15:22:09.185239+00	2026-09-11 15:22:09.185255+00	f	\N	74	1000.00 on INV-2026-00064	CREATE	[]	21	9a259d21-6303-464d-97fe-23a835dfdc29
1302	2026-09-11 15:22:09.230426+00	2026-09-11 15:22:09.230438+00	f	\N	67	INV-2026-00064	UPDATE	["paid_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1303	2026-09-11 15:22:09.290615+00	2026-09-11 15:22:09.290631+00	f	\N	96	Bajaj Discover V18 110cc (serial None) on INV-2026-00064	UPDATE	["paid_share"]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1304	2026-09-15 10:52:00.061909+00	2026-09-15 10:52:00.061922+00	f	\N	105	Bajaj Discover CBS 110cc (serial None) on INV-2026-00071	CREATE	[]	20	9a259d21-6303-464d-97fe-23a835dfdc29
1305	2026-09-15 10:52:00.089155+00	2026-09-15 10:52:00.089164+00	f	\N	126	Mileage Correction on INV-2026-00071	CREATE	[]	23	9a259d21-6303-464d-97fe-23a835dfdc29
1306	2026-09-15 10:52:00.115212+00	2026-09-15 10:52:00.115222+00	f	\N	74	INV-2026-00071	UPDATE	["total_amount"]	19	9a259d21-6303-464d-97fe-23a835dfdc29
1307	2026-09-24 13:04:59.329722+00	2026-09-24 13:04:59.329743+00	f	\N	55	Installment #11 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
1308	2026-09-24 13:05:04.62634+00	2026-09-24 13:05:04.628423+00	f	\N	56	Installment #12 for Pridim Foundation	CREATE	[]	27	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: audit_auditlogentry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_auditlogentry (id, created_at, updated_at, is_deleted, deleted_at, object_id, action, description, content_type_id, created_by_id) FROM stdin;
1	2026-07-23 12:55:27.235478+00	2026-07-23 12:55:27.235502+00	f	\N	1	invoice_created	Invoice INV-2026-00001 created for Usman Bakshiganj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
2	2026-07-23 12:58:50.026419+00	2026-07-23 12:58:50.026442+00	f	\N	1	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
3	2026-07-23 12:58:50.03942+00	2026-07-23 12:58:50.039435+00	f	\N	1	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
4	2026-07-23 12:58:59.806502+00	2026-07-23 12:58:59.806513+00	f	\N	1	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
5	2026-07-23 13:00:34.770021+00	2026-07-23 13:00:34.770048+00	f	\N	2	invoice_created	Invoice INV-2026-00002 created for Nur Islam.	19	9a259d21-6303-464d-97fe-23a835dfdc29
6	2026-07-23 13:01:16.264039+00	2026-07-23 13:01:16.264061+00	f	\N	2	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
7	2026-07-23 13:01:16.271272+00	2026-07-23 13:01:16.271284+00	f	\N	2	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
8	2026-07-23 13:01:34.19808+00	2026-07-23 13:01:34.198096+00	f	\N	2	service_line_updated	Updated service line: price_charged changed from 400.00 to 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
9	2026-07-23 13:01:54.771454+00	2026-07-23 13:01:54.771466+00	f	\N	2	payment_added	Payment of 500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
10	2026-07-23 13:07:30.621575+00	2026-07-23 13:07:30.621597+00	f	\N	3	invoice_created	Invoice INV-2026-00003 created for Bijoy.	19	9a259d21-6303-464d-97fe-23a835dfdc29
11	2026-07-23 13:07:40.867664+00	2026-07-23 13:07:40.867708+00	f	\N	3	invoice_date_updated	created_date changed from 2026-07-23 to 2026-07-22.	19	9a259d21-6303-464d-97fe-23a835dfdc29
12	2026-07-23 13:08:23.32746+00	2026-07-23 13:08:23.327489+00	f	\N	3	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
13	2026-07-23 13:08:23.334605+00	2026-07-23 13:08:23.334636+00	f	\N	3	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
14	2026-07-24 05:47:13.416149+00	2026-07-24 05:47:13.416171+00	f	\N	4	invoice_created	Invoice INV-2026-00004 created for Hasan Khrompur.	19	9a259d21-6303-464d-97fe-23a835dfdc29
15	2026-07-24 05:49:04.240194+00	2026-07-24 05:49:04.240234+00	f	\N	4	meter_entry_added	Added meter Gixxer Monotone 155cc (serial 341-34J0).	19	9a259d21-6303-464d-97fe-23a835dfdc29
16	2026-07-24 05:49:04.258308+00	2026-07-24 05:49:04.258332+00	f	\N	4	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
17	2026-07-24 05:49:12.320466+00	2026-07-24 05:49:12.320642+00	f	\N	4	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
18	2026-07-25 08:40:28.6625+00	2026-07-25 08:40:28.662513+00	f	\N	5	invoice_created	Invoice INV-2026-00005 created for Hasan Khrompur.	19	9a259d21-6303-464d-97fe-23a835dfdc29
19	2026-07-25 08:42:20.712492+00	2026-07-25 08:42:20.712503+00	f	\N	5	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191066).	19	9a259d21-6303-464d-97fe-23a835dfdc29
20	2026-07-25 08:42:20.727992+00	2026-07-25 08:42:20.728003+00	f	\N	5	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
21	2026-07-25 08:46:26.682351+00	2026-07-25 08:46:26.682362+00	f	\N	6	invoice_created	Invoice INV-2026-00006 created for Khurshed Painter.	19	9a259d21-6303-464d-97fe-23a835dfdc29
22	2026-07-25 08:47:05.162634+00	2026-07-25 08:47:05.162647+00	f	\N	6	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
23	2026-07-25 08:47:05.169845+00	2026-07-25 08:47:05.169856+00	f	\N	6	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
24	2026-07-25 08:47:16.875937+00	2026-07-25 08:47:16.87595+00	f	\N	6	invoice_date_updated	created_date changed from 2026-07-25 to 2026-07-20.	19	9a259d21-6303-464d-97fe-23a835dfdc29
25	2026-07-25 08:47:21.562755+00	2026-07-25 08:47:21.562766+00	f	\N	6	service_line_updated	Updated service line: added_date changed from 2026-07-25 to 2026-07-20.	19	9a259d21-6303-464d-97fe-23a835dfdc29
26	2026-07-25 15:08:48.964299+00	2026-07-25 15:08:48.964311+00	f	\N	5	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
27	2026-07-26 07:34:30.12762+00	2026-07-26 07:34:30.127651+00	f	\N	7	invoice_created	Invoice INV-2026-00007 created for Alkas Ali.	19	9a259d21-6303-464d-97fe-23a835dfdc29
28	2026-07-26 07:40:39.835913+00	2026-07-26 07:40:39.835942+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial JZ 402422 0024).	19	9a259d21-6303-464d-97fe-23a835dfdc29
29	2026-07-26 07:40:39.847969+00	2026-07-26 07:40:39.847984+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
30	2026-07-26 09:24:00.241003+00	2026-07-26 09:24:00.24103+00	f	\N	8	invoice_created	Invoice INV-2026-00008 created for Bipul.	19	9a259d21-6303-464d-97fe-23a835dfdc29
31	2026-07-26 09:24:26.584979+00	2026-07-26 09:24:26.585018+00	f	\N	8	service_line_added	Added service 'Gixxer SF Main board repaire' for 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
32	2026-07-26 09:24:38.924572+00	2026-07-26 09:24:38.924606+00	f	\N	8	service_line_updated	Updated service line: price_charged changed from 100.00 to 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
33	2026-07-26 14:10:58.721301+00	2026-07-26 14:10:58.721325+00	f	\N	6	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
34	2026-07-27 07:36:10.400807+00	2026-07-27 07:36:10.400823+00	f	\N	9	invoice_created	Invoice INV-2026-00009 created for Babul Nakla.	19	9a259d21-6303-464d-97fe-23a835dfdc29
35	2026-07-27 07:37:35.605614+00	2026-07-27 07:37:35.60564+00	f	\N	9	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial DH191071).	19	9a259d21-6303-464d-97fe-23a835dfdc29
36	2026-07-27 07:37:35.61707+00	2026-07-27 07:37:35.61709+00	f	\N	9	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
37	2026-07-27 09:38:21.469066+00	2026-07-27 09:38:21.469079+00	f	\N	3	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial JZ402422).	19	9a259d21-6303-464d-97fe-23a835dfdc29
38	2026-07-27 09:38:21.476282+00	2026-07-27 09:38:21.476302+00	f	\N	3	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
39	2026-07-27 11:18:44.260375+00	2026-07-27 11:18:44.260388+00	f	\N	3	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
40	2026-07-27 11:19:28.723419+00	2026-07-27 11:19:28.723432+00	f	\N	3	service_line_added	Added service 'Display Replace' for 500.00 + product 'Gexxer Monotone Display' for 1500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
41	2026-07-27 13:31:11.857547+00	2026-07-27 13:31:11.857564+00	f	\N	10	invoice_created	Invoice INV-2026-00010 created for Khurshed Painter.	19	9a259d21-6303-464d-97fe-23a835dfdc29
42	2026-07-27 13:35:24.183821+00	2026-07-27 13:35:24.183841+00	f	\N	10	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
43	2026-07-27 13:35:24.192132+00	2026-07-27 13:35:24.192145+00	f	\N	10	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
44	2026-07-27 13:44:59.290481+00	2026-07-27 13:44:59.290498+00	f	\N	10	meter_entry_added	Added meter TVS Apache 4V X Connect 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
45	2026-07-27 13:44:59.299609+00	2026-07-27 13:44:59.299623+00	f	\N	10	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
46	2026-07-27 13:46:23.327823+00	2026-07-27 13:46:23.327843+00	f	\N	11	invoice_created	Invoice INV-2026-00011 created for Azad Jhenaigati.	19	9a259d21-6303-464d-97fe-23a835dfdc29
47	2026-07-27 13:47:13.577909+00	2026-07-27 13:47:13.577928+00	f	\N	11	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
48	2026-07-27 13:47:13.585949+00	2026-07-27 13:47:13.585964+00	f	\N	11	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
49	2026-07-27 13:49:13.933885+00	2026-07-27 13:49:13.933909+00	f	\N	8	payment_added	Payment of 600.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
50	2026-07-27 13:49:56.215814+00	2026-07-27 13:49:56.215831+00	f	\N	12	invoice_created	Invoice INV-2026-00012 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
51	2026-07-27 13:51:26.714545+00	2026-07-27 13:51:26.714558+00	f	\N	12	service_line_added	Added service 'Light Replace' for 300.00 + product 'White LED 3528' for 300.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
52	2026-07-27 13:52:17.987707+00	2026-07-27 13:52:17.987736+00	f	\N	12	service_line_updated	Updated service line: product_price changed from 300.00 to 1300.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
53	2026-07-27 13:52:32.170639+00	2026-07-27 13:52:32.170664+00	f	\N	12	service_line_updated	Updated service line: price_charged changed from 300.00 to 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
54	2026-07-27 13:52:41.709635+00	2026-07-27 13:52:41.70965+00	f	\N	12	payment_added	Payment of 1800.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
55	2026-07-27 13:55:18.219296+00	2026-07-27 13:55:18.219311+00	f	\N	13	invoice_created	Invoice INV-2026-00013 created for Babu.	19	9a259d21-6303-464d-97fe-23a835dfdc29
56	2026-07-27 13:57:39.944819+00	2026-07-27 13:57:39.944837+00	f	\N	13	service_line_added	Added service 'Mainboard Repair' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
57	2026-07-27 13:57:47.406965+00	2026-07-27 13:57:47.406992+00	f	\N	13	service_line_updated	Updated service line: price_charged changed from 500.00 to 1500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
58	2026-07-27 13:57:55.720998+00	2026-07-27 13:57:55.721009+00	f	\N	13	payment_added	Payment of 1000.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
59	2026-07-27 14:59:50.660301+00	2026-07-27 14:59:50.660313+00	f	\N	14	invoice_created	Invoice INV-2026-00014 created for Khursher - Nalitabari.	19	9a259d21-6303-464d-97fe-23a835dfdc29
60	2026-07-27 15:00:25.030004+00	2026-07-27 15:00:25.030022+00	f	\N	14	service_line_added	Added service 'Pulsar Polarize Paper Replace' for 500.00 + product 'Pulsar Polarized Paper' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
61	2026-07-27 15:04:41.895659+00	2026-07-27 15:04:41.895673+00	f	\N	10	service_line_deleted	Removed service 'Mileage Correction' (400.00). Also removed linked meter entry for Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
62	2026-07-27 15:04:52.197714+00	2026-07-27 15:04:52.197737+00	f	\N	10	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
63	2026-07-27 15:05:05.74528+00	2026-07-27 15:05:05.745304+00	f	\N	15	invoice_created	Invoice INV-2026-00015 created for Hasan Khrompur.	19	9a259d21-6303-464d-97fe-23a835dfdc29
64	2026-07-27 15:06:22.190499+00	2026-07-27 15:06:22.190525+00	f	\N	15	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
65	2026-07-27 15:06:22.198102+00	2026-07-27 15:06:22.198118+00	f	\N	15	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
73	2026-07-27 16:21:17.71059+00	2026-07-27 16:21:17.710626+00	f	\N	3	service_line_updated	Updated service line: condition_note changed from ['good'] to ['Good'].	19	9a259d21-6303-464d-97fe-23a835dfdc29
74	2026-07-27 17:24:57.470417+00	2026-07-27 17:24:57.47044+00	f	\N	7	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
75	2026-07-27 17:24:57.495803+00	2026-07-27 17:24:57.495817+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
76	2026-07-27 17:35:17.41792+00	2026-07-27 17:35:17.41798+00	f	\N	7	meter_entry_added	Added meter Gixxer SF A2 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
77	2026-07-27 17:35:17.435566+00	2026-07-27 17:35:17.435615+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
78	2026-07-27 17:35:36.508062+00	2026-07-27 17:35:36.508091+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-05-17.	19	9a259d21-6303-464d-97fe-23a835dfdc29
79	2026-07-27 17:36:07.544372+00	2026-07-27 17:36:07.544392+00	f	\N	7	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
80	2026-07-27 17:36:07.55774+00	2026-07-27 17:36:07.557762+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
81	2026-07-27 17:36:17.475629+00	2026-07-27 17:36:17.475739+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-05-17.	19	9a259d21-6303-464d-97fe-23a835dfdc29
82	2026-07-27 17:37:04.45418+00	2026-07-27 17:37:04.454197+00	f	\N	7	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
83	2026-07-27 17:37:04.466338+00	2026-07-27 17:37:04.466361+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
84	2026-07-27 17:37:21.97335+00	2026-07-27 17:37:21.973376+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-24.	19	9a259d21-6303-464d-97fe-23a835dfdc29
85	2026-07-27 17:37:56.177938+00	2026-07-27 17:37:56.177968+00	f	\N	7	meter_entry_added	Added meter Honda SP shine 100cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
86	2026-07-27 17:37:56.196832+00	2026-07-27 17:37:56.196857+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
87	2026-07-27 17:38:14.937608+00	2026-07-27 17:38:14.93768+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-23.	19	9a259d21-6303-464d-97fe-23a835dfdc29
88	2026-07-27 17:47:24.052835+00	2026-07-27 17:47:24.052862+00	f	\N	7	meter_entry_added	Added meter Honda Hornet 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
89	2026-07-27 17:47:24.064551+00	2026-07-27 17:47:24.064568+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
90	2026-07-27 17:48:07.54759+00	2026-07-27 17:48:07.547629+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
91	2026-07-27 17:48:07.558703+00	2026-07-27 17:48:07.558737+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
92	2026-07-27 17:49:34.08933+00	2026-07-27 17:49:34.089361+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-12.	19	9a259d21-6303-464d-97fe-23a835dfdc29
93	2026-07-27 17:49:41.726392+00	2026-07-27 17:49:41.726442+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-12.	19	9a259d21-6303-464d-97fe-23a835dfdc29
94	2026-07-27 17:50:35.132851+00	2026-07-27 17:50:35.132877+00	f	\N	7	meter_entry_added	Added meter TVS Apache 4V X Connect 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
95	2026-07-27 17:50:35.145404+00	2026-07-27 17:50:35.145441+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
96	2026-07-27 17:50:49.554273+00	2026-07-27 17:50:49.554297+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
97	2026-07-27 17:51:28.735752+00	2026-07-27 17:51:28.735812+00	f	\N	7	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
98	2026-07-27 17:51:28.750192+00	2026-07-27 17:51:28.750224+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
99	2026-07-27 17:52:00.557657+00	2026-07-27 17:52:00.557695+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-04.	19	9a259d21-6303-464d-97fe-23a835dfdc29
100	2026-07-27 17:52:08.433956+00	2026-07-27 17:52:08.433992+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-04-04 to 2026-07-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
101	2026-07-27 17:52:24.050526+00	2026-07-27 17:52:24.050559+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-05 to 2026-04-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
102	2026-07-27 17:58:10.212039+00	2026-07-27 17:58:10.212072+00	f	\N	7	meter_entry_added	Added meter TVS Stryker 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
103	2026-07-27 17:58:10.235269+00	2026-07-27 17:58:10.235304+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
104	2026-07-27 17:58:51.450195+00	2026-07-27 17:58:51.450265+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-27 to 2026-04-14.	19	9a259d21-6303-464d-97fe-23a835dfdc29
105	2026-07-27 17:59:11.243821+00	2026-07-27 17:59:11.243862+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-04-14 to 2026-04-28.	19	9a259d21-6303-464d-97fe-23a835dfdc29
106	2026-07-27 17:59:26.541856+00	2026-07-27 17:59:26.541881+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-04-28 to 2026-03-28.	19	9a259d21-6303-464d-97fe-23a835dfdc29
107	2026-07-27 18:00:10.80649+00	2026-07-27 18:00:10.806525+00	f	\N	7	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
108	2026-07-27 18:00:10.821597+00	2026-07-27 18:00:10.821632+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
109	2026-07-27 18:00:24.886969+00	2026-07-27 18:00:24.887007+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-07-28 to 2026-03-26.	19	9a259d21-6303-464d-97fe-23a835dfdc29
110	2026-07-27 18:56:35.377717+00	2026-07-27 18:56:35.377764+00	f	\N	7	service_line_updated	Updated service line: serial_number changed from None to 'A2C1297290101'; mileage_correction_device changed from <MileageCorrectionDevice: VVDI Prog> to None.	19	9a259d21-6303-464d-97fe-23a835dfdc29
111	2026-07-28 14:30:53.338774+00	2026-07-28 14:30:53.338795+00	f	\N	19	invoice_created	Invoice INV-2026-00016 created for Unknown Customer.	19	9a259d21-6303-464d-97fe-23a835dfdc29
112	2026-07-28 14:31:55.10354+00	2026-07-28 14:31:55.103551+00	f	\N	19	service_line_added	Added service 'Pulsar Polarize Paper Replace' for 500.00 + product 'Pulsar Polarized Paper' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
113	2026-07-28 14:32:55.106556+00	2026-07-28 14:32:55.106567+00	f	\N	19	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
114	2026-07-28 14:32:55.115276+00	2026-07-28 14:32:55.115286+00	f	\N	19	service_line_added	Added service 'Mileage Correction' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
115	2026-07-28 14:34:12.425644+00	2026-07-28 14:34:12.425655+00	f	\N	19	service_line_updated	Updated service line: price_charged changed from 500.00 to 0.00; product_price changed from 1000.00 to 1700.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
116	2026-07-28 14:37:53.182401+00	2026-07-28 14:37:53.182414+00	f	\N	19	service_line_updated	Updated service line: condition_note changed from ['Good'] to ['Display Problem'].	19	9a259d21-6303-464d-97fe-23a835dfdc29
117	2026-07-28 14:40:14.852886+00	2026-07-28 14:40:14.852897+00	f	\N	14	service_line_updated	Updated service line: price_charged changed from 500.00 to 0.00; product_price changed from 1000.00 to 1700.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
118	2026-07-28 14:48:03.805439+00	2026-07-28 14:48:03.805449+00	f	\N	14	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
119	2026-07-28 14:48:03.823484+00	2026-07-28 14:48:03.823496+00	f	\N	14	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
120	2026-07-28 14:48:50.34371+00	2026-07-28 14:48:50.34372+00	f	\N	14	discount_applied	Discount changed from 0.00 to 400.00. Reason: Discount for display pchange	19	9a259d21-6303-464d-97fe-23a835dfdc29
121	2026-07-28 15:25:14.381221+00	2026-07-28 15:25:14.381235+00	f	\N	19	service_line_updated	Updated service line: serial_number changed from None to 'DH191065'.	19	9a259d21-6303-464d-97fe-23a835dfdc29
122	2026-07-28 15:28:03.337721+00	2026-07-28 15:28:03.337735+00	f	\N	19	discount_applied	Discount changed from 0.00 to 700.00. Reason: Rembmer	19	9a259d21-6303-464d-97fe-23a835dfdc29
123	2026-07-28 15:28:14.769174+00	2026-07-28 15:28:14.769191+00	f	\N	19	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
124	2026-07-28 15:34:00.952233+00	2026-07-28 15:34:00.952243+00	f	\N	3	meter_entry_added	Added meter Gixxer Monotone 155cc (serial 34134J0).	19	9a259d21-6303-464d-97fe-23a835dfdc29
125	2026-07-28 15:34:01.082839+00	2026-07-28 15:34:01.082848+00	f	\N	3	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
126	2026-07-28 15:37:28.783442+00	2026-07-28 15:37:28.783452+00	f	\N	3	service_line_updated	Updated service line: price_charged changed from 500.00 to 0.00; product_price changed from 1500.00 to 2000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
127	2026-07-30 07:04:49.798028+00	2026-07-30 07:04:49.798039+00	f	\N	20	invoice_created	Invoice INV-2026-00017 created for Unknown Jinaigati 01.	19	9a259d21-6303-464d-97fe-23a835dfdc29
128	2026-07-30 07:05:52.4568+00	2026-07-30 07:05:52.45681+00	f	\N	20	meter_entry_added	Added meter TVS Stryker 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
129	2026-07-30 07:05:52.476378+00	2026-07-30 07:05:52.476387+00	f	\N	20	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
130	2026-07-30 07:06:01.065747+00	2026-07-30 07:06:01.065755+00	f	\N	20	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
131	2026-07-30 09:34:13.996091+00	2026-07-30 09:34:13.996104+00	f	\N	21	invoice_created	Invoice INV-2026-00018 created for Ashik Wash.	19	9a259d21-6303-464d-97fe-23a835dfdc29
132	2026-07-30 09:35:37.771445+00	2026-07-30 09:35:37.771455+00	f	\N	21	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial 2GSH3500-00).	19	9a259d21-6303-464d-97fe-23a835dfdc29
133	2026-07-30 09:35:37.786493+00	2026-07-30 09:35:37.786541+00	f	\N	21	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
134	2026-07-30 10:16:34.885018+00	2026-07-30 10:16:34.88503+00	f	\N	21	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
135	2026-07-30 18:27:14.845501+00	2026-07-30 18:27:14.845516+00	f	\N	22	invoice_created	Invoice INV-2026-00019 created for Sujan Bastand, fruite.	19	9a259d21-6303-464d-97fe-23a835dfdc29
136	2026-07-30 18:27:56.81036+00	2026-07-30 18:27:56.81037+00	f	\N	22	service_line_added	Added service 'Pulsar Polarize Paper Replace' for 500.00 + product 'Pulsar Polarized Paper' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
137	2026-07-30 18:28:45.861665+00	2026-07-30 18:28:45.861678+00	f	\N	22	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
138	2026-07-30 18:28:45.869442+00	2026-07-30 18:28:45.869452+00	f	\N	22	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
139	2026-07-31 08:34:55.990785+00	2026-07-31 08:34:55.990796+00	f	\N	22	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
140	2026-07-31 14:31:10.78831+00	2026-07-31 14:31:10.788318+00	f	\N	11	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
141	2026-08-02 11:52:53.566941+00	2026-08-02 11:52:53.566953+00	f	\N	7	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
142	2026-08-02 11:52:53.586827+00	2026-08-02 11:52:53.586835+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
143	2026-08-02 11:55:12.103444+00	2026-08-02 11:55:12.103453+00	f	\N	7	meter_entry_added	Added meter TVS Stryker 125cc (serial P10-39-10-00).	19	9a259d21-6303-464d-97fe-23a835dfdc29
144	2026-08-02 11:55:12.110916+00	2026-08-02 11:55:12.110955+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
145	2026-08-02 12:50:01.144526+00	2026-08-02 12:50:01.144535+00	f	\N	23	invoice_created	Invoice INV-2026-00020 created for Sharif Thana.	19	9a259d21-6303-464d-97fe-23a835dfdc29
146	2026-08-02 12:51:38.702701+00	2026-08-02 12:51:38.702708+00	f	\N	23	meter_entry_added	Added meter Gixxer Monotone 155cc (serial 341-34J0).	19	9a259d21-6303-464d-97fe-23a835dfdc29
147	2026-08-02 12:51:38.719519+00	2026-08-02 12:51:38.71953+00	f	\N	23	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
148	2026-08-02 12:53:07.712457+00	2026-08-02 12:53:07.712468+00	f	\N	23	meter_entry_added	Added meter Gixxer Monotone 155cc (serial 341-34J0).	19	9a259d21-6303-464d-97fe-23a835dfdc29
149	2026-08-02 12:53:07.720332+00	2026-08-02 12:53:07.720341+00	f	\N	23	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
150	2026-08-02 16:15:01.435195+00	2026-08-02 16:15:01.435207+00	f	\N	9	service_line_added	Added service 'Display Replace' for 0.00 + product 'Gexxer Monotone Display' for 1500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
151	2026-08-02 16:16:03.440541+00	2026-08-02 16:16:03.440549+00	f	\N	3	service_line_deleted	Removed service 'Display Replace' (0.00). Restored 1 x 'Gexxer Monotone Display' to stock.	19	9a259d21-6303-464d-97fe-23a835dfdc29
152	2026-08-02 16:16:15.647231+00	2026-08-02 16:16:15.647242+00	f	\N	9	service_line_updated	Updated service line: added_date changed from 2026-08-02 to 2026-07-27.	19	9a259d21-6303-464d-97fe-23a835dfdc29
153	2026-08-02 16:16:41.874938+00	2026-08-02 16:16:41.87495+00	f	\N	9	service_line_updated	Updated service line: price_charged changed from 0.00 to 200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
154	2026-08-02 16:17:01.537886+00	2026-08-02 16:17:01.537894+00	f	\N	9	service_line_updated	Updated service line: asset_used changed from none to Display.	19	9a259d21-6303-464d-97fe-23a835dfdc29
155	2026-08-02 16:17:24.010729+00	2026-08-02 16:17:24.010746+00	f	\N	9	service_line_updated	Updated service line: price_charged changed from 200.00 to 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
156	2026-08-02 16:17:34.598721+00	2026-08-02 16:17:34.598732+00	f	\N	9	discount_applied	Discount changed from 0.00 to 300.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
157	2026-08-02 16:17:42.480815+00	2026-08-02 16:17:42.480824+00	f	\N	9	payment_added	Payment of 2100.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
158	2026-08-02 16:18:13.091559+00	2026-08-02 16:18:13.091572+00	f	\N	23	payment_added	Payment of 800.00 recorded via BKASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
159	2026-08-03 10:35:02.240673+00	2026-08-03 10:35:02.240684+00	f	\N	24	invoice_created	Invoice INV-2026-00021 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
160	2026-08-03 10:37:23.150966+00	2026-08-03 10:37:23.150974+00	f	\N	24	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
161	2026-08-03 10:37:23.164174+00	2026-08-03 10:37:23.164182+00	f	\N	24	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
162	2026-08-03 10:38:41.280286+00	2026-08-03 10:38:41.280297+00	f	\N	24	service_line_updated	Updated service line: previous_km changed from 37975 to 51565; current_km changed from 15119 to 14138.	19	9a259d21-6303-464d-97fe-23a835dfdc29
163	2026-08-03 10:40:03.571014+00	2026-08-03 10:40:03.571021+00	f	\N	24	meter_entry_added	Added meter Honda SP shine 100cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
164	2026-08-03 10:40:03.575751+00	2026-08-03 10:40:03.575762+00	f	\N	24	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
165	2026-08-03 10:40:11.901824+00	2026-08-03 10:40:11.901833+00	f	\N	24	discount_applied	Discount changed from 0.00 to 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
166	2026-08-03 10:40:19.256167+00	2026-08-03 10:40:19.256177+00	f	\N	24	payment_added	Payment of 700.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
167	2026-08-03 14:24:53.219086+00	2026-08-03 14:24:53.219098+00	f	\N	25	invoice_created	Invoice INV-2026-00022 created for Atik Jograrchor.	19	9a259d21-6303-464d-97fe-23a835dfdc29
168	2026-08-03 14:27:15.752917+00	2026-08-03 14:27:15.752929+00	f	\N	25	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
169	2026-08-03 14:27:15.764769+00	2026-08-03 14:27:15.764777+00	f	\N	25	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
170	2026-08-03 14:27:25.02344+00	2026-08-03 14:27:25.02345+00	f	\N	25	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
171	2026-08-03 14:29:03.153777+00	2026-08-03 14:29:03.153784+00	f	\N	26	invoice_created	Invoice INV-2026-00023 created for Nirab Sriboddi.	19	9a259d21-6303-464d-97fe-23a835dfdc29
172	2026-08-03 14:29:43.277772+00	2026-08-03 14:29:43.27778+00	f	\N	26	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
173	2026-08-03 14:29:43.282014+00	2026-08-03 14:29:43.282021+00	f	\N	26	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
174	2026-08-03 16:14:18.647107+00	2026-08-03 16:14:18.64712+00	f	\N	13	invoice_force_closed	Force-closed as Paid, waiving 500.00 of the remaining balance. Reason: Give me a v3 meter	19	9a259d21-6303-464d-97fe-23a835dfdc29
175	2026-08-04 07:33:59.523194+00	2026-08-04 07:33:59.523203+00	f	\N	27	invoice_created	Invoice INV-2026-00024 created for Liton Thana.	19	9a259d21-6303-464d-97fe-23a835dfdc29
176	2026-08-04 07:35:13.325487+00	2026-08-04 07:35:13.325498+00	f	\N	27	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial 2GS-H3500).	19	9a259d21-6303-464d-97fe-23a835dfdc29
177	2026-08-04 07:35:13.342948+00	2026-08-04 07:35:13.342961+00	f	\N	27	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
178	2026-08-04 07:49:06.592954+00	2026-08-04 07:49:06.593002+00	f	\N	27	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
179	2026-08-04 14:54:22.943367+00	2026-08-04 14:54:22.94339+00	f	\N	15	meter_entry_added	Added meter Yamaha FZ V3 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
180	2026-08-04 14:54:22.959058+00	2026-08-04 14:54:22.959065+00	f	\N	15	service_line_added	Added service 'Mileage Correction' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
181	2026-08-05 06:32:02.008599+00	2026-08-05 06:32:02.008608+00	f	\N	15	service_line_added	Added service 'Display Repair' for 300.00 + product 'RTR Display All V' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
182	2026-08-05 06:34:37.318191+00	2026-08-05 06:34:37.318204+00	f	\N	15	meter_entry_added	Added meter TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
183	2026-08-05 06:34:37.325728+00	2026-08-05 06:34:37.32574+00	f	\N	15	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
184	2026-08-05 06:35:31.970327+00	2026-08-05 06:35:31.970339+00	f	\N	15	meter_entry_added	Added meter TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
185	2026-08-05 06:35:31.977915+00	2026-08-05 06:35:31.977923+00	f	\N	15	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
186	2026-08-05 06:37:09.468817+00	2026-08-05 06:37:09.468826+00	f	\N	26	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
187	2026-08-05 06:37:09.476373+00	2026-08-05 06:37:09.47638+00	f	\N	26	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
188	2026-08-05 06:37:20.081697+00	2026-08-05 06:37:20.081708+00	f	\N	26	service_line_updated	Updated service line: added_date changed from 2026-08-05 to 2026-08-04.	19	9a259d21-6303-464d-97fe-23a835dfdc29
189	2026-08-05 06:37:29.527584+00	2026-08-05 06:37:29.527598+00	f	\N	26	payment_added	Payment of 800.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
190	2026-08-05 06:43:57.860942+00	2026-08-05 06:43:57.860955+00	f	\N	7	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
191	2026-08-05 06:43:57.865969+00	2026-08-05 06:43:57.86598+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
192	2026-08-05 06:44:10.205892+00	2026-08-05 06:44:10.205902+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-08-05 to 2026-08-04.	19	9a259d21-6303-464d-97fe-23a835dfdc29
193	2026-08-05 15:49:59.658155+00	2026-08-05 15:49:59.658165+00	f	\N	28	invoice_created	Invoice INV-2026-00025 created for Kajol - Sribordi.	19	9a259d21-6303-464d-97fe-23a835dfdc29
194	2026-08-05 15:50:45.980541+00	2026-08-05 15:50:45.980554+00	f	\N	28	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
195	2026-08-05 15:50:45.998676+00	2026-08-05 15:50:45.998684+00	f	\N	28	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
196	2026-08-05 15:51:34.956081+00	2026-08-05 15:51:34.956093+00	f	\N	29	invoice_created	Invoice INV-2026-00026 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
197	2026-08-05 15:52:26.334862+00	2026-08-05 15:52:26.334871+00	f	\N	29	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
198	2026-08-05 15:52:26.34365+00	2026-08-05 15:52:26.343658+00	f	\N	29	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
199	2026-08-05 15:52:33.424324+00	2026-08-05 15:52:33.424339+00	f	\N	29	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
200	2026-08-05 15:56:04.750822+00	2026-08-05 15:56:04.750832+00	f	\N	15	service_line_updated	Updated service line: mileage_correction_device changed from <MileageCorrectionDevice: RT809F> to <MileageCorrectionDevice: TOP2013>.	19	9a259d21-6303-464d-97fe-23a835dfdc29
201	2026-08-05 16:41:43.911614+00	2026-08-05 16:41:43.911625+00	f	\N	28	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
202	2026-08-06 05:04:19.47988+00	2026-08-06 05:04:19.47989+00	f	\N	30	invoice_created	Invoice INV-2026-00027 created for Akij- Panir tank.	19	9a259d21-6303-464d-97fe-23a835dfdc29
203	2026-08-06 07:28:48.193941+00	2026-08-06 07:28:48.193955+00	f	\N	30	meter_entry_added	Added meter Yamaha FZ V3 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
204	2026-08-06 07:28:48.21408+00	2026-08-06 07:28:48.214095+00	f	\N	30	service_line_added	Added service 'Mileage Correction' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
205	2026-08-06 07:29:33.74667+00	2026-08-06 07:29:33.746683+00	f	\N	30	service_line_added	Added service 'Display Repair' for 300.00 + product 'RTR Display All V' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
206	2026-08-06 07:30:32.422132+00	2026-08-06 07:30:32.422139+00	f	\N	30	meter_entry_added	Added meter TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
207	2026-08-06 07:30:32.428214+00	2026-08-06 07:30:32.428221+00	f	\N	30	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
208	2026-08-06 07:30:47.885218+00	2026-08-06 07:30:47.885233+00	f	\N	30	service_line_updated	Updated service line: added_date changed from 2026-08-06 to 2026-08-04.	19	9a259d21-6303-464d-97fe-23a835dfdc29
209	2026-08-06 07:30:51.776805+00	2026-08-06 07:30:51.776816+00	f	\N	30	service_line_updated	Updated service line: added_date changed from 2026-08-06 to 2026-08-04.	19	9a259d21-6303-464d-97fe-23a835dfdc29
210	2026-08-06 07:31:04.155507+00	2026-08-06 07:31:04.155517+00	f	\N	30	service_line_updated	Updated service line: added_date changed from 2026-08-04 to 2026-08-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
211	2026-08-06 07:31:06.609118+00	2026-08-06 07:31:06.609127+00	f	\N	30	service_line_updated	Updated service line: added_date changed from 2026-08-06 to 2026-08-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
212	2026-08-06 07:31:20.111677+00	2026-08-06 07:31:20.11169+00	f	\N	30	service_line_deleted	Removed service 'Display Repair' (300.00). Restored 1 x 'RTR Display All V' to stock.	19	9a259d21-6303-464d-97fe-23a835dfdc29
213	2026-08-06 07:31:52.954088+00	2026-08-06 07:31:52.954097+00	f	\N	30	service_line_added	Added service 'Display Replace' for 300.00 + product 'RTR Display All V' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
214	2026-08-06 07:32:04.772209+00	2026-08-06 07:32:04.772222+00	f	\N	30	service_line_updated	Updated service line: added_date changed from 2026-08-06 to 2026-08-05.	19	9a259d21-6303-464d-97fe-23a835dfdc29
215	2026-08-06 07:32:14.447477+00	2026-08-06 07:32:14.447486+00	f	\N	15	service_line_deleted	Removed service 'Display Repair' (300.00). Restored 1 x 'RTR Display All V' to stock.	19	9a259d21-6303-464d-97fe-23a835dfdc29
216	2026-08-06 07:32:20.335273+00	2026-08-06 07:32:20.335283+00	f	\N	15	service_line_deleted	Removed service 'Mileage Correction' (400.00). Also removed linked meter entry for TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
217	2026-08-06 07:32:25.633355+00	2026-08-06 07:32:25.63337+00	f	\N	15	service_line_deleted	Removed service 'Mileage Correction' (1000.00). Also removed linked meter entry for Yamaha FZ V3 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
218	2026-08-06 07:32:32.824739+00	2026-08-06 07:32:32.824749+00	f	\N	15	service_line_deleted	Removed service 'Mileage Correction' (400.00). Also removed linked meter entry for TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
219	2026-08-06 11:03:51.104864+00	2026-08-06 11:03:51.104874+00	f	\N	31	invoice_created	Invoice INV-2026-00028 created for Usman Bakshiganj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
220	2026-08-06 11:07:01.63113+00	2026-08-06 11:07:01.631138+00	f	\N	31	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
221	2026-08-06 11:07:01.642411+00	2026-08-06 11:07:01.642419+00	f	\N	31	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
222	2026-08-06 11:07:07.564568+00	2026-08-06 11:07:07.564582+00	f	\N	31	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
223	2026-08-06 11:07:35.016757+00	2026-08-06 11:07:35.016769+00	f	\N	32	invoice_created	Invoice INV-2026-00029 created for Komol Mia Kalitola.	19	9a259d21-6303-464d-97fe-23a835dfdc29
224	2026-08-06 11:08:13.931859+00	2026-08-06 11:08:13.931871+00	f	\N	32	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
225	2026-08-06 11:08:13.937259+00	2026-08-06 11:08:13.937268+00	f	\N	32	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
226	2026-08-06 11:08:20.34352+00	2026-08-06 11:08:20.343531+00	f	\N	32	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
227	2026-08-06 17:38:37.089837+00	2026-08-06 17:38:37.089847+00	f	\N	33	invoice_created	Invoice INV-2026-00030 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
228	2026-08-06 17:40:41.027097+00	2026-08-06 17:40:41.02711+00	f	\N	33	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
229	2026-08-06 17:40:41.048089+00	2026-08-06 17:40:41.048099+00	f	\N	33	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
230	2026-08-06 17:40:46.498818+00	2026-08-06 17:40:46.498827+00	f	\N	33	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
231	2026-08-06 17:42:36.215521+00	2026-08-06 17:42:36.215529+00	f	\N	34	invoice_created	Invoice INV-2026-00031 created for Faisal Mirgonj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
232	2026-08-06 17:43:23.402602+00	2026-08-06 17:43:23.402613+00	f	\N	34	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
233	2026-08-06 17:43:23.410033+00	2026-08-06 17:43:23.410042+00	f	\N	34	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
234	2026-08-06 17:43:44.648929+00	2026-08-06 17:43:44.64894+00	f	\N	34	service_line_updated	Updated service line: mileage_correction_device changed from None to <MileageCorrectionDevice: RT809F>; price_charged changed from 400.00 to 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
235	2026-08-06 17:43:50.626442+00	2026-08-06 17:43:50.626452+00	f	\N	34	payment_added	Payment of 500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
236	2026-08-06 17:49:03.390779+00	2026-08-06 17:49:03.390786+00	f	\N	35	invoice_created	Invoice INV-2026-00032 created for Glamore.	19	9a259d21-6303-464d-97fe-23a835dfdc29
237	2026-08-06 17:50:17.361363+00	2026-08-06 17:50:17.361372+00	f	\N	35	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
238	2026-08-06 17:50:17.366675+00	2026-08-06 17:50:17.366682+00	f	\N	35	service_line_added	Added service 'Mileage Correction' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
239	2026-08-06 17:54:20.277311+00	2026-08-06 17:54:20.277325+00	f	\N	35	service_line_updated	Updated service line: current_km changed from 22229 to 20296.	19	9a259d21-6303-464d-97fe-23a835dfdc29
240	2026-08-06 17:54:58.395111+00	2026-08-06 17:54:58.395121+00	f	\N	35	meter_entry_added	Added meter Hero Glamour 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
241	2026-08-06 17:54:58.399297+00	2026-08-06 17:54:58.399304+00	f	\N	35	service_line_added	Added service 'Mileage Correction' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
242	2026-08-06 17:55:05.979663+00	2026-08-06 17:55:05.979676+00	f	\N	35	service_line_updated	Updated service line: mileage_correction_device changed from None to <MileageCorrectionDevice: VVDI Prog>.	19	9a259d21-6303-464d-97fe-23a835dfdc29
243	2026-08-06 17:55:27.294033+00	2026-08-06 17:55:27.294041+00	f	\N	35	payment_added	Payment of 1000.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
244	2026-08-08 04:58:13.729625+00	2026-08-08 04:58:13.729637+00	f	\N	30	discount_applied	Discount changed from 0.00 to 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
245	2026-08-08 04:58:25.848754+00	2026-08-08 04:58:25.848766+00	f	\N	30	payment_added	Payment of 2800.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
246	2026-08-08 05:26:58.344471+00	2026-08-08 05:26:58.344485+00	f	\N	15	payment_added	Payment of 300.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
247	2026-08-08 05:27:17.143745+00	2026-08-08 05:27:17.143753+00	f	\N	15	invoice_force_closed	Force-closed as Paid, waiving 100.00 of the remaining balance. Reason: kom dise 100 tk	19	9a259d21-6303-464d-97fe-23a835dfdc29
248	2026-08-08 11:41:41.698623+00	2026-08-08 11:41:41.698632+00	f	\N	36	invoice_created	Invoice INV-2026-00033 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
249	2026-08-08 11:42:41.20209+00	2026-08-08 11:42:41.202099+00	f	\N	36	meter_entry_added	Added meter Honda SP 125 FI ABS(2025) 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
250	2026-08-08 11:42:41.21886+00	2026-08-08 11:42:41.218875+00	f	\N	36	service_line_added	Added service 'Mileage Correction' for 900.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
251	2026-08-08 11:42:51.277483+00	2026-08-08 11:42:51.277493+00	f	\N	36	payment_added	Payment of 900.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
252	2026-08-08 13:57:05.308516+00	2026-08-08 13:57:05.308528+00	f	\N	37	invoice_created	Invoice INV-2026-00034 created for Customer 01.	19	9a259d21-6303-464d-97fe-23a835dfdc29
253	2026-08-08 13:58:20.951205+00	2026-08-08 13:58:20.951213+00	f	\N	37	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
254	2026-08-08 13:58:20.96308+00	2026-08-08 13:58:20.963088+00	f	\N	37	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
255	2026-08-08 15:43:58.520661+00	2026-08-08 15:43:58.520683+00	f	\N	37	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
256	2026-08-09 15:29:20.532171+00	2026-08-09 15:29:20.532186+00	f	\N	14	service_line_deleted	Removed service 'Mileage Correction' (400.00). Also removed linked meter entry for Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
257	2026-08-09 15:29:33.356796+00	2026-08-09 15:29:33.356804+00	f	\N	14	discount_applied	Discount changed from 400.00 to 200.00. Reason: Discount for display pchange	19	9a259d21-6303-464d-97fe-23a835dfdc29
258	2026-08-09 15:29:42.475887+00	2026-08-09 15:29:42.475894+00	f	\N	14	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
259	2026-08-09 15:30:12.629384+00	2026-08-09 15:30:12.629392+00	f	\N	38	invoice_created	Invoice INV-2026-00035 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
260	2026-08-09 15:30:25.78074+00	2026-08-09 15:30:25.780751+00	f	\N	38	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
261	2026-08-09 15:30:25.790246+00	2026-08-09 15:30:25.790256+00	f	\N	38	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
262	2026-08-09 15:30:31.650983+00	2026-08-09 15:30:31.650992+00	f	\N	38	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
263	2026-08-10 08:56:46.026764+00	2026-08-10 08:56:46.026776+00	f	\N	39	invoice_created	Invoice INV-2026-00036 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
264	2026-08-10 08:58:02.646877+00	2026-08-10 08:58:02.646886+00	f	\N	39	meter_entry_added	Added meter Bajaj Discover CBS 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
265	2026-08-10 08:58:02.662502+00	2026-08-10 08:58:02.662514+00	f	\N	39	service_line_added	Added service 'Mileage Correction' for 460.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
266	2026-08-10 08:58:12.049438+00	2026-08-10 08:58:12.049448+00	f	\N	39	service_line_updated	Updated service line: price_charged changed from 460.00 to 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
267	2026-08-10 08:58:24.421177+00	2026-08-10 08:58:24.421189+00	f	\N	39	discount_applied	Discount changed from 0.00 to 60.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
268	2026-08-10 08:58:31.338819+00	2026-08-10 08:58:31.33883+00	f	\N	39	payment_added	Payment of 440.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
269	2026-08-10 08:58:41.861256+00	2026-08-10 08:58:41.861269+00	f	\N	40	invoice_created	Invoice INV-2026-00037 created for Labu Thanar.	19	9a259d21-6303-464d-97fe-23a835dfdc29
270	2026-08-10 08:59:23.614296+00	2026-08-10 08:59:23.614304+00	f	\N	40	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
271	2026-08-10 08:59:23.62239+00	2026-08-10 08:59:23.622397+00	f	\N	40	service_line_added	Added service 'Mileage Correction' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
272	2026-08-10 08:59:31.704265+00	2026-08-10 08:59:31.704277+00	f	\N	40	discount_applied	Discount changed from 0.00 to 30.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
273	2026-08-10 08:59:40.665072+00	2026-08-10 08:59:40.665079+00	f	\N	40	payment_added	Payment of 470.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
274	2026-08-11 18:33:24.428378+00	2026-08-11 18:33:24.42839+00	f	\N	41	invoice_created	Invoice INV-2026-00038 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
275	2026-08-11 18:35:11.587421+00	2026-08-11 18:35:11.587432+00	f	\N	41	invoice_deleted	Invoice deleted.	19	9a259d21-6303-464d-97fe-23a835dfdc29
276	2026-08-11 18:35:23.189716+00	2026-08-11 18:35:23.189729+00	f	\N	42	invoice_created	Invoice INV-2026-00039 created for Customer Kh 01.	19	9a259d21-6303-464d-97fe-23a835dfdc29
277	2026-08-11 18:36:11.057604+00	2026-08-11 18:36:11.057616+00	f	\N	42	service_line_added	Added service 'Pulsar Polarize Paper Replace' for 500.00 + product 'Pulsar Polarized Paper' for 1300.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
278	2026-08-11 18:39:29.89818+00	2026-08-11 18:39:29.89819+00	f	\N	7	meter_entry_added	Added meter TVS Stryker 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
279	2026-08-11 18:39:29.905845+00	2026-08-11 18:39:29.905852+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
280	2026-08-11 18:40:37.148812+00	2026-08-11 18:40:37.14882+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
281	2026-08-11 18:40:37.155051+00	2026-08-11 18:40:37.155059+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
282	2026-08-11 18:41:12.745766+00	2026-08-11 18:41:12.745777+00	f	\N	43	invoice_created	Invoice INV-2026-00040 created for Khurshed Painter.	19	9a259d21-6303-464d-97fe-23a835dfdc29
283	2026-08-11 18:42:11.051398+00	2026-08-11 18:42:11.051407+00	f	\N	43	meter_entry_added	Added meter TVS Stryker 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
284	2026-08-11 18:42:11.057422+00	2026-08-11 18:42:11.057431+00	f	\N	43	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
285	2026-08-12 07:07:21.817462+00	2026-08-12 07:07:21.817474+00	f	\N	7	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
286	2026-08-12 07:07:21.838645+00	2026-08-12 07:07:21.838655+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
287	2026-08-12 15:06:09.253048+00	2026-08-12 15:06:09.253057+00	f	\N	42	payment_added	Payment of 1800.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
288	2026-08-12 15:10:09.953888+00	2026-08-12 15:10:09.953895+00	f	\N	44	invoice_created	Invoice INV-2026-00041 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
289	2026-08-12 15:11:22.931878+00	2026-08-12 15:11:22.931886+00	f	\N	44	meter_entry_added	Added meter TVS Apache RTR 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
290	2026-08-12 15:11:22.946147+00	2026-08-12 15:11:22.946154+00	f	\N	44	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
291	2026-08-12 15:11:34.407145+00	2026-08-12 15:11:34.407154+00	f	\N	44	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
292	2026-08-12 15:13:52.423873+00	2026-08-12 15:13:52.423888+00	f	\N	43	service_line_updated	Updated service line: mileage_correction_device changed from None to <MileageCorrectionDevice: EasyPro2025>.	19	9a259d21-6303-464d-97fe-23a835dfdc29
293	2026-08-12 15:14:28.942671+00	2026-08-12 15:14:28.942682+00	f	\N	45	invoice_created	Invoice INV-2026-00042 created for Sharif Thana.	19	9a259d21-6303-464d-97fe-23a835dfdc29
294	2026-08-12 15:15:24.74604+00	2026-08-12 15:15:24.746056+00	f	\N	45	meter_entry_added	Added meter TVS Apache RTR Horse 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
295	2026-08-12 15:15:24.753436+00	2026-08-12 15:15:24.753448+00	f	\N	45	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
296	2026-08-13 10:56:59.916874+00	2026-08-13 10:56:59.916883+00	f	\N	46	invoice_created	Invoice INV-2026-00043 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
297	2026-08-13 10:57:55.062545+00	2026-08-13 10:57:55.062556+00	f	\N	46	service_line_added	Added service 'Display Replace' for 500.00 + product 'Discover Display Grear' for 1300.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
298	2026-08-13 10:58:15.248135+00	2026-08-13 10:58:15.248144+00	f	\N	46	payment_added	Payment of 1800.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
299	2026-08-13 10:58:51.516231+00	2026-08-13 10:58:51.516245+00	f	\N	45	payment_added	Payment of 300.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
300	2026-08-13 10:59:03.597186+00	2026-08-13 10:59:03.597194+00	f	\N	47	invoice_created	Invoice INV-2026-00044 created for Rafique khusumhati.	19	9a259d21-6303-464d-97fe-23a835dfdc29
301	2026-08-13 11:00:26.286863+00	2026-08-13 11:00:26.286872+00	f	\N	47	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
302	2026-08-13 11:00:26.29448+00	2026-08-13 11:00:26.294493+00	f	\N	47	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
303	2026-08-13 12:23:24.090314+00	2026-08-13 12:23:24.090326+00	f	\N	43	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
304	2026-08-13 12:23:41.322443+00	2026-08-13 12:23:41.322454+00	f	\N	47	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
305	2026-08-15 13:44:36.011988+00	2026-08-15 13:44:36.012004+00	f	\N	48	invoice_created	Invoice INV-2026-00045 created for Noor Islam.	19	9a259d21-6303-464d-97fe-23a835dfdc29
306	2026-08-15 13:45:43.359618+00	2026-08-15 13:45:43.359627+00	f	\N	48	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial 2GSH3500-00).	19	9a259d21-6303-464d-97fe-23a835dfdc29
307	2026-08-15 13:45:43.370818+00	2026-08-15 13:45:43.370826+00	f	\N	48	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
308	2026-08-15 13:46:28.631933+00	2026-08-15 13:46:28.631942+00	f	\N	48	meter_entry_added	Added meter Yamaha FZ V3 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
309	2026-08-15 13:46:28.636547+00	2026-08-15 13:46:28.636556+00	f	\N	48	service_line_added	Added service 'Mileage Correction' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
310	2026-08-15 13:46:41.603298+00	2026-08-15 13:46:41.603308+00	f	\N	48	service_line_updated	Updated service line: mileage_correction_device changed from None to <MileageCorrectionDevice: EasyPro2025>.	19	9a259d21-6303-464d-97fe-23a835dfdc29
311	2026-08-17 11:30:23.292677+00	2026-08-17 11:30:23.292693+00	f	\N	7	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
312	2026-08-17 11:30:23.337543+00	2026-08-17 11:30:23.337554+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
313	2026-08-17 11:30:28.467494+00	2026-08-17 11:30:28.467502+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-08-17 to 2026-08-16.	19	9a259d21-6303-464d-97fe-23a835dfdc29
314	2026-08-17 11:30:55.589936+00	2026-08-17 11:30:55.589945+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
315	2026-08-17 11:30:55.59829+00	2026-08-17 11:30:55.598301+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
316	2026-08-17 11:31:02.884695+00	2026-08-17 11:31:02.884704+00	f	\N	7	service_line_updated	Updated service line: added_date changed from 2026-08-17 to 2026-08-15.	19	9a259d21-6303-464d-97fe-23a835dfdc29
317	2026-08-17 11:31:21.577114+00	2026-08-17 11:31:21.577132+00	f	\N	49	invoice_created	Invoice INV-2026-00046 created for Usman Bakshiganj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
318	2026-08-17 11:31:55.520921+00	2026-08-17 11:31:55.520929+00	f	\N	49	meter_entry_added	Added meter TVS Apache 4V 1st 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
319	2026-08-17 11:31:55.528189+00	2026-08-17 11:31:55.528197+00	f	\N	49	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
320	2026-08-17 11:32:02.951718+00	2026-08-17 11:32:02.951727+00	f	\N	49	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
321	2026-08-17 21:10:48.608238+00	2026-08-17 21:10:48.608248+00	f	\N	48	payment_added	Payment of 1400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
322	2026-08-18 11:17:18.184931+00	2026-08-18 11:17:18.184941+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
323	2026-08-18 11:17:18.204836+00	2026-08-18 11:17:18.204846+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
324	2026-08-18 11:35:45.354218+00	2026-08-18 11:35:45.354232+00	f	\N	50	invoice_created	Invoice INV-2026-00047 created for Manik Khuarpar.	19	9a259d21-6303-464d-97fe-23a835dfdc29
325	2026-08-18 11:37:01.746128+00	2026-08-18 11:37:01.746139+00	f	\N	50	meter_entry_added	Added meter TVS Apache 4V 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
326	2026-08-18 11:37:01.763665+00	2026-08-18 11:37:01.763673+00	f	\N	50	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
327	2026-08-18 11:37:10.265034+00	2026-08-18 11:37:10.265043+00	f	\N	50	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
328	2026-08-18 11:37:29.097418+00	2026-08-18 11:37:29.097425+00	f	\N	51	invoice_created	Invoice INV-2026-00048 created for Nirab Sriboddi.	19	9a259d21-6303-464d-97fe-23a835dfdc29
329	2026-08-18 11:38:22.159298+00	2026-08-18 11:38:22.159306+00	f	\N	51	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
330	2026-08-18 11:38:22.166967+00	2026-08-18 11:38:22.166975+00	f	\N	51	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
331	2026-08-18 11:38:29.894692+00	2026-08-18 11:38:29.894702+00	f	\N	51	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
332	2026-08-18 11:39:01.44498+00	2026-08-18 11:39:01.444988+00	f	\N	52	invoice_created	Invoice INV-2026-00049 created for Hasan Khrompur.	19	9a259d21-6303-464d-97fe-23a835dfdc29
333	2026-08-18 11:47:13.455574+00	2026-08-18 11:47:13.455586+00	f	\N	52	service_line_added	Added service 'Discover Polarized paper replace' for 500.00 + product 'Polarize Paper replace' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
334	2026-08-18 11:47:24.281616+00	2026-08-18 11:47:24.281625+00	f	\N	52	payment_added	Payment of 1000.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
335	2026-08-18 14:18:55.627298+00	2026-08-18 14:18:55.627306+00	f	\N	52	meter_entry_added	Added meter Bajaj Discover CBS 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
336	2026-08-18 14:18:55.672139+00	2026-08-18 14:18:55.672152+00	f	\N	52	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
337	2026-08-18 14:19:16.332724+00	2026-08-18 14:19:16.332738+00	f	\N	52	discount_applied	Discount changed from 0.00 to 400.00. Reason: For Display paper change	19	9a259d21-6303-464d-97fe-23a835dfdc29
338	2026-08-18 17:06:04.42097+00	2026-08-18 17:06:04.420978+00	f	\N	45	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
339	2026-08-18 17:06:04.479846+00	2026-08-18 17:06:04.479856+00	f	\N	45	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
340	2026-08-19 11:40:04.431635+00	2026-08-19 11:40:04.431651+00	f	\N	53	invoice_created	Invoice INV-2026-00050 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
341	2026-08-19 11:41:02.392333+00	2026-08-19 11:41:02.39234+00	f	\N	53	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
342	2026-08-19 11:41:02.408256+00	2026-08-19 11:41:02.408264+00	f	\N	53	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
343	2026-08-19 11:41:23.276583+00	2026-08-19 11:41:23.276594+00	f	\N	53	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
344	2026-08-20 14:55:18.698076+00	2026-08-20 14:55:18.698088+00	f	\N	54	invoice_created	Invoice INV-2026-00051 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
345	2026-08-20 14:56:12.83483+00	2026-08-20 14:56:12.834837+00	f	\N	54	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
346	2026-08-20 14:56:12.848995+00	2026-08-20 14:56:12.849004+00	f	\N	54	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
347	2026-08-20 14:56:20.797277+00	2026-08-20 14:56:20.797292+00	f	\N	54	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
348	2026-08-20 14:56:46.883215+00	2026-08-20 14:56:46.88329+00	f	\N	55	invoice_created	Invoice INV-2026-00052 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
349	2026-08-20 14:57:03.184174+00	2026-08-20 14:57:03.184186+00	f	\N	55	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
350	2026-08-20 14:57:03.193984+00	2026-08-20 14:57:03.193996+00	f	\N	55	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
351	2026-08-20 14:57:09.074568+00	2026-08-20 14:57:09.074582+00	f	\N	55	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
352	2026-08-20 14:57:31.203279+00	2026-08-20 14:57:31.203294+00	f	\N	56	invoice_created	Invoice INV-2026-00053 created for Rafique khusumhati.	19	9a259d21-6303-464d-97fe-23a835dfdc29
353	2026-08-20 14:58:45.233931+00	2026-08-20 14:58:45.233943+00	f	\N	56	service_line_added	Added service 'Display Replace' for 0.00 + product 'Discover Display Grear' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
354	2026-08-20 14:59:20.913543+00	2026-08-20 14:59:20.913555+00	f	\N	56	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
355	2026-08-20 14:59:20.922298+00	2026-08-20 14:59:20.922315+00	f	\N	56	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
356	2026-08-20 18:13:14.347878+00	2026-08-20 18:13:14.347889+00	f	\N	57	invoice_created	Invoice INV-2026-00054 created for Lokmkman vimgonj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
357	2026-08-20 18:13:59.313031+00	2026-08-20 18:13:59.31304+00	f	\N	57	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
358	2026-08-20 18:13:59.330468+00	2026-08-20 18:13:59.330481+00	f	\N	57	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
359	2026-08-20 18:14:16.630569+00	2026-08-20 18:14:16.630585+00	f	\N	57	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
360	2026-08-23 09:03:14.846309+00	2026-08-23 09:03:14.846321+00	f	\N	58	invoice_created	Invoice INV-2026-00055 created for Arif Thanar gate.	19	9a259d21-6303-464d-97fe-23a835dfdc29
361	2026-08-23 09:04:11.372676+00	2026-08-23 09:04:11.372684+00	f	\N	58	meter_entry_added	Added meter TVS Apache RTR 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
362	2026-08-23 09:04:11.386447+00	2026-08-23 09:04:11.386455+00	f	\N	58	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
363	2026-08-23 09:04:18.283125+00	2026-08-23 09:04:18.283135+00	f	\N	58	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
364	2026-08-23 09:04:26.677942+00	2026-08-23 09:04:26.677952+00	f	\N	59	invoice_created	Invoice INV-2026-00056 created for Akij- Panir tank.	19	9a259d21-6303-464d-97fe-23a835dfdc29
365	2026-08-23 09:05:08.022858+00	2026-08-23 09:05:08.022865+00	f	\N	59	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
366	2026-08-23 09:05:08.029933+00	2026-08-23 09:05:08.029941+00	f	\N	59	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
367	2026-08-23 13:02:04.89466+00	2026-08-23 13:02:04.894673+00	f	\N	60	invoice_created	Invoice INV-2026-00057 created for Monu Kamarer Char.	19	9a259d21-6303-464d-97fe-23a835dfdc29
368	2026-08-23 13:04:40.140314+00	2026-08-23 13:04:40.140324+00	f	\N	60	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
369	2026-08-23 13:04:40.153583+00	2026-08-23 13:04:40.153591+00	f	\N	60	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
370	2026-08-23 13:04:46.200035+00	2026-08-23 13:04:46.200044+00	f	\N	60	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
371	2026-08-23 13:05:50.204404+00	2026-08-23 13:05:50.204415+00	f	\N	56	payment_added	Payment of 1400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
372	2026-08-23 13:06:22.996465+00	2026-08-23 13:06:22.996476+00	f	\N	59	payment_added	Payment of 300.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
373	2026-08-24 12:21:37.383893+00	2026-08-24 12:21:37.383901+00	f	\N	52	meter_entry_added	Added meter TVS Apache 4V X Connect 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
374	2026-08-24 12:21:37.463628+00	2026-08-24 12:21:37.463636+00	f	\N	52	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
375	2026-08-24 12:21:49.655741+00	2026-08-24 12:21:49.655755+00	f	\N	52	payment_added	Payment of 600.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
376	2026-08-24 12:25:35.873867+00	2026-08-24 12:25:35.873875+00	f	\N	61	invoice_created	Invoice INV-2026-00058 created for Unknown Customer Discover.	19	9a259d21-6303-464d-97fe-23a835dfdc29
377	2026-08-24 12:26:15.977584+00	2026-08-24 12:26:15.977594+00	f	\N	61	service_line_added	Added service 'Display Repair' for 500.00 + product 'Discover Display Grear' for 700.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
378	2026-08-24 12:26:24.140557+00	2026-08-24 12:26:24.140566+00	f	\N	61	payment_added	Payment of 1200.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
379	2026-08-25 07:07:06.862395+00	2026-08-25 07:07:06.862405+00	f	\N	7	meter_entry_added	Added meter Gixxer Monotone 155cc (serial 341-34J0).	19	9a259d21-6303-464d-97fe-23a835dfdc29
380	2026-08-25 07:07:06.881769+00	2026-08-25 07:07:06.881777+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
381	2026-08-26 15:08:40.571434+00	2026-08-26 15:08:40.571444+00	f	\N	7	service_line_added	Added service 'Display Repair' for 500.00 + product 'Discover 110 & 125 display 2018v' for 1000.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
382	2026-08-26 15:09:38.435578+00	2026-08-26 15:09:38.435587+00	f	\N	7	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
383	2026-08-26 15:09:38.441704+00	2026-08-26 15:09:38.441713+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
384	2026-08-26 15:10:22.970811+00	2026-08-26 15:10:22.970822+00	f	\N	7	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
385	2026-08-27 07:42:28.945449+00	2026-08-27 07:42:28.945461+00	f	\N	7	service_line_updated	Updated service line: price_charged changed from 500.00 to 0.00; product_price changed from 1000.00 to 1500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
386	2026-08-27 09:49:55.312623+00	2026-08-27 09:49:55.312633+00	f	\N	7	meter_entry_added	Added meter Gixxer Monotone 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
387	2026-08-27 09:49:56.162392+00	2026-08-27 09:49:56.162401+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
388	2026-08-27 10:01:43.459786+00	2026-08-27 10:01:43.459805+00	f	\N	62	invoice_created	Invoice INV-2026-00059 created for test cust.	19	9a259d21-6303-464d-97fe-23a835dfdc29
389	2026-08-27 10:02:34.717157+00	2026-08-27 10:02:34.717192+00	f	\N	62	meter_entry_added	Added meter Bajaj Discover 4Gear 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
390	2026-08-27 10:02:34.952202+00	2026-08-27 10:02:34.952225+00	f	\N	62	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
391	2026-08-27 10:02:52.932681+00	2026-08-27 10:02:52.932724+00	f	\N	62	service_line_deleted	Removed service 'Mileage Correction' (400.00). Also removed linked meter entry for Bajaj Discover 4Gear 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
392	2026-08-27 10:12:55.419611+00	2026-08-27 10:12:55.419624+00	f	\N	3	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
393	2026-08-29 17:13:29.182647+00	2026-08-29 17:13:29.182666+00	f	\N	63	invoice_created	Invoice INV-2026-00060 created for Usman Bakshiganj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
394	2026-08-29 17:14:28.526498+00	2026-08-29 17:14:28.526508+00	f	\N	63	service_line_added	Added service 'Discover Polarized paper replace' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
395	2026-08-29 17:14:36.074787+00	2026-08-29 17:14:36.074802+00	f	\N	63	payment_added	Payment of 1200.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
396	2026-08-30 10:17:54.230919+00	2026-08-30 10:17:54.230934+00	f	\N	45	discount_applied	Discount changed from 0.00 to 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
397	2026-08-30 10:18:01.040398+00	2026-08-30 10:18:01.040408+00	f	\N	45	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
398	2026-09-01 16:58:34.455685+00	2026-09-01 16:58:34.455696+00	f	\N	64	invoice_created	Invoice INV-2026-00061 created for Usman Bakshiganj.	19	9a259d21-6303-464d-97fe-23a835dfdc29
399	2026-09-01 16:59:32.905808+00	2026-09-01 16:59:32.90582+00	f	\N	64	meter_entry_added	Added meter TVS Apache 4V X Connect 160cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
400	2026-09-01 16:59:32.922039+00	2026-09-01 16:59:32.922049+00	f	\N	64	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
401	2026-09-01 16:59:41.127723+00	2026-09-01 16:59:41.127735+00	f	\N	64	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
402	2026-09-01 17:00:10.721334+00	2026-09-01 17:00:10.721351+00	f	\N	65	invoice_created	Invoice INV-2026-00062 created for Babul Nakla.	19	9a259d21-6303-464d-97fe-23a835dfdc29
403	2026-09-01 17:00:50.551395+00	2026-09-01 17:00:50.551402+00	f	\N	65	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
404	2026-09-01 17:00:50.560014+00	2026-09-01 17:00:50.560022+00	f	\N	65	service_line_added	Added service 'Mileage Correction' for 500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
405	2026-09-01 17:00:58.673407+00	2026-09-01 17:00:58.67342+00	f	\N	65	payment_added	Payment of 500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
406	2026-09-01 17:01:15.184699+00	2026-09-01 17:01:15.184708+00	f	\N	66	invoice_created	Invoice INV-2026-00063 created for Sharif Thana.	19	9a259d21-6303-464d-97fe-23a835dfdc29
407	2026-09-01 17:03:22.12646+00	2026-09-01 17:03:22.126474+00	f	\N	66	meter_entry_added	Added meter Yamaha FZ V2 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
408	2026-09-01 17:03:22.139948+00	2026-09-01 17:03:22.139961+00	f	\N	66	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
409	2026-09-01 17:03:27.836092+00	2026-09-01 17:03:27.836102+00	f	\N	66	service_line_updated	Updated service line: added_date changed from 2026-09-01 to 2026-08-31.	19	9a259d21-6303-464d-97fe-23a835dfdc29
410	2026-09-01 17:03:57.145291+00	2026-09-01 17:03:57.145302+00	f	\N	67	invoice_created	Invoice INV-2026-00064 created for Kajol - Sribordi.	19	9a259d21-6303-464d-97fe-23a835dfdc29
411	2026-09-01 17:04:40.44673+00	2026-09-01 17:04:40.446737+00	f	\N	67	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
412	2026-09-01 17:04:40.453884+00	2026-09-01 17:04:40.453891+00	f	\N	67	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
413	2026-09-01 17:04:43.900095+00	2026-09-01 17:04:43.900115+00	f	\N	67	service_line_updated	Updated service line: added_date changed from 2026-09-01 to 2026-08-31.	19	9a259d21-6303-464d-97fe-23a835dfdc29
414	2026-09-01 17:04:56.531872+00	2026-09-01 17:04:56.531884+00	f	\N	67	payment_added	Payment of 300.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
415	2026-09-03 08:30:51.210816+00	2026-09-03 08:30:51.210827+00	f	\N	66	service_line_added	Added service 'Display Replace' for 0.00 + product 'RTR Display All V' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
416	2026-09-03 08:31:49.74262+00	2026-09-03 08:31:49.742628+00	f	\N	67	service_line_added	Added service 'Display Repair' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
417	2026-09-03 08:32:05.396119+00	2026-09-03 08:32:05.39613+00	f	\N	68	invoice_created	Invoice INV-2026-00065 created for Nirab Sriboddi.	19	9a259d21-6303-464d-97fe-23a835dfdc29
418	2026-09-03 08:32:39.462606+00	2026-09-03 08:32:39.462617+00	f	\N	68	service_line_added	Added service 'Display Repair' for 0.00 + product 'Discover Display Grear' for 1200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
419	2026-09-03 08:33:58.464316+00	2026-09-03 08:33:58.464328+00	f	\N	59	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
420	2026-09-03 08:33:58.534825+00	2026-09-03 08:33:58.534838+00	f	\N	59	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
421	2026-09-03 08:34:04.45202+00	2026-09-03 08:34:04.45203+00	f	\N	59	discount_applied	Discount changed from 0.00 to 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
422	2026-09-03 08:34:09.81619+00	2026-09-03 08:34:09.816201+00	f	\N	59	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
423	2026-09-03 15:37:06.665595+00	2026-09-03 15:37:06.665606+00	f	\N	68	payment_added	Payment of 500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
424	2026-09-03 17:00:56.819147+00	2026-09-03 17:00:56.819186+00	f	\N	69	invoice_created	Invoice INV-2026-00066 created for Babul Nakla.	19	9a259d21-6303-464d-97fe-23a835dfdc29
425	2026-09-03 17:01:20.749105+00	2026-09-03 17:01:20.749114+00	f	\N	69	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
426	2026-09-03 17:01:20.763751+00	2026-09-03 17:01:20.763759+00	f	\N	69	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
427	2026-09-03 17:02:38.529489+00	2026-09-03 17:02:38.529501+00	f	\N	69	meter_entry_added	Added meter Gixxer SF A2 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
428	2026-09-03 17:02:38.536809+00	2026-09-03 17:02:38.53682+00	f	\N	69	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
429	2026-09-03 17:03:36.033211+00	2026-09-03 17:03:36.033223+00	f	\N	69	meter_entry_added	Added meter Gixxer SF A5 155cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
430	2026-09-03 17:03:36.040762+00	2026-09-03 17:03:36.040771+00	f	\N	69	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
431	2026-09-03 17:03:48.858069+00	2026-09-03 17:03:48.858081+00	f	\N	69	payment_added	Payment of 1000.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
432	2026-09-03 17:04:04.455904+00	2026-09-03 17:04:04.455913+00	f	\N	69	discount_applied	Discount changed from 0.00 to 200.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
433	2026-09-03 17:04:36.401578+00	2026-09-03 17:04:36.401589+00	f	\N	70	invoice_created	Invoice INV-2026-00067 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
434	2026-09-03 17:05:28.707814+00	2026-09-03 17:05:28.707825+00	f	\N	70	meter_entry_added	Added meter Bajaj Discover 5Gear 125cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
435	2026-09-03 17:05:28.716738+00	2026-09-03 17:05:28.716749+00	f	\N	70	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
436	2026-09-03 17:05:38.166304+00	2026-09-03 17:05:38.166313+00	f	\N	70	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
437	2026-09-03 17:06:29.867779+00	2026-09-03 17:06:29.867787+00	f	\N	7	meter_entry_added	Added meter Bajaj Pulsar 8F(UG3-UG5) 150cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
438	2026-09-03 17:06:30.809877+00	2026-09-03 17:06:30.809884+00	f	\N	7	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
439	2026-09-04 16:54:53.06625+00	2026-09-04 16:54:53.066261+00	f	\N	68	service_line_updated	Updated service line: product_price changed from 1200.00 to 1400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
440	2026-09-04 16:55:03.464502+00	2026-09-04 16:55:03.46451+00	f	\N	68	payment_added	Payment of 900.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
441	2026-09-05 11:06:49.715116+00	2026-09-05 11:06:49.715128+00	f	\N	71	invoice_created	Invoice INV-2026-00068 created for Labu Thanar.	19	9a259d21-6303-464d-97fe-23a835dfdc29
442	2026-09-05 11:07:51.60948+00	2026-09-05 11:07:51.609494+00	f	\N	71	service_line_added	Added service 'Display Replace' for 1500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
443	2026-09-06 12:08:01.703873+00	2026-09-06 12:08:01.703882+00	f	\N	71	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
444	2026-09-06 12:08:20.402347+00	2026-09-06 12:08:20.402354+00	f	\N	66	discount_applied	Discount changed from 0.00 to 100.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
445	2026-09-06 12:08:28.084776+00	2026-09-06 12:08:28.084791+00	f	\N	66	payment_added	Payment of 1500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
446	2026-09-06 12:10:22.138757+00	2026-09-06 12:10:22.138773+00	f	\N	72	invoice_created	Invoice INV-2026-00069 created for CID.	19	9a259d21-6303-464d-97fe-23a835dfdc29
447	2026-09-06 12:10:42.894616+00	2026-09-06 12:10:42.894623+00	f	\N	72	service_line_added	Added service 'Mainboard Repair' for 3500.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
448	2026-09-06 12:10:53.108468+00	2026-09-06 12:10:53.108477+00	f	\N	72	payment_added	Payment of 3500.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
449	2026-09-06 12:11:08.168445+00	2026-09-06 12:11:08.168456+00	f	\N	73	invoice_created	Invoice INV-2026-00070 created for Unknown.	19	9a259d21-6303-464d-97fe-23a835dfdc29
450	2026-09-06 12:11:27.201365+00	2026-09-06 12:11:27.201372+00	f	\N	73	meter_entry_added	Added meter TVS Metro Plus 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
451	2026-09-06 12:11:27.210005+00	2026-09-06 12:11:27.210012+00	f	\N	73	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
452	2026-09-06 12:11:32.813549+00	2026-09-06 12:11:32.813563+00	f	\N	73	payment_added	Payment of 400.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
453	2026-09-08 06:03:16.144745+00	2026-09-08 06:03:16.144762+00	f	\N	74	invoice_created	Invoice INV-2026-00071 created for Sharif Thana.	19	9a259d21-6303-464d-97fe-23a835dfdc29
454	2026-09-08 06:03:46.468352+00	2026-09-08 06:03:46.468365+00	f	\N	74	meter_entry_added	Added meter Bajaj Discover V18 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
455	2026-09-08 06:03:46.480181+00	2026-09-08 06:03:46.480192+00	f	\N	74	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
456	2026-09-11 15:22:09.294703+00	2026-09-11 15:22:09.294716+00	f	\N	67	payment_added	Payment of 1000.00 recorded via CASH.	19	9a259d21-6303-464d-97fe-23a835dfdc29
457	2026-09-15 10:52:00.074068+00	2026-09-15 10:52:00.07408+00	f	\N	74	meter_entry_added	Added meter Bajaj Discover CBS 110cc (serial —).	19	9a259d21-6303-464d-97fe-23a835dfdc29
458	2026-09-15 10:52:00.091489+00	2026-09-15 10:52:00.091503+00	f	\N	74	service_line_added	Added service 'Mileage Correction' for 400.00.	19	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	2	add_logentry
2	Can change log entry	2	change_logentry
3	Can delete log entry	2	delete_logentry
4	Can view log entry	2	view_logentry
5	Can add permission	4	add_permission
6	Can change permission	4	change_permission
7	Can delete permission	4	delete_permission
8	Can view permission	4	view_permission
9	Can add group	3	add_group
10	Can change group	3	change_group
11	Can delete group	3	delete_group
12	Can view group	3	view_group
13	Can add content type	5	add_contenttype
14	Can change content type	5	change_contenttype
15	Can delete content type	5	delete_contenttype
16	Can view content type	5	view_contenttype
17	Can add session	6	add_session
18	Can change session	6	change_session
19	Can delete session	6	delete_session
20	Can view session	6	view_session
21	Can add Blacklisted Token	7	add_blacklistedtoken
22	Can change Blacklisted Token	7	change_blacklistedtoken
23	Can delete Blacklisted Token	7	delete_blacklistedtoken
24	Can view Blacklisted Token	7	view_blacklistedtoken
25	Can add Outstanding Token	8	add_outstandingtoken
26	Can change Outstanding Token	8	change_outstandingtoken
27	Can delete Outstanding Token	8	delete_outstandingtoken
28	Can view Outstanding Token	8	view_outstandingtoken
29	Can add user	9	add_user
30	Can change user	9	change_user
31	Can delete user	9	delete_user
32	Can view user	9	view_user
33	Can add customer	10	add_customer
34	Can change customer	10	change_customer
35	Can delete customer	10	delete_customer
36	Can view customer	10	view_customer
37	Can add supplier	11	add_supplier
38	Can change supplier	11	change_supplier
39	Can delete supplier	11	delete_supplier
40	Can view supplier	11	view_supplier
41	Can add meter	12	add_meter
42	Can change meter	12	change_meter
43	Can delete meter	12	delete_meter
44	Can view meter	12	view_meter
45	Can add mileage correction device	1	add_mileagecorrectiondevice
46	Can change mileage correction device	1	change_mileagecorrectiondevice
47	Can delete mileage correction device	1	delete_mileagecorrectiondevice
48	Can view mileage correction device	1	view_mileagecorrectiondevice
49	Can add service category	14	add_servicecategory
50	Can change service category	14	change_servicecategory
51	Can delete service category	14	delete_servicecategory
52	Can view service category	14	view_servicecategory
53	Can add service	13	add_service
54	Can change service	13	change_service
55	Can delete service	13	delete_service
56	Can view service	13	view_service
57	Can add product	15	add_product
58	Can change product	15	change_product
59	Can delete product	15	delete_product
60	Can view product	15	view_product
61	Can add product restock event	16	add_productrestockevent
62	Can change product restock event	16	change_productrestockevent
63	Can delete product restock event	16	delete_productrestockevent
64	Can view product restock event	16	view_productrestockevent
65	Can add purchase	17	add_purchase
66	Can change purchase	17	change_purchase
67	Can delete purchase	17	delete_purchase
68	Can view purchase	17	view_purchase
69	Can add purchase line item	18	add_purchaselineitem
70	Can change purchase line item	18	change_purchaselineitem
71	Can delete purchase line item	18	delete_purchaselineitem
72	Can view purchase line item	18	view_purchaselineitem
73	Can add invoice	19	add_invoice
74	Can change invoice	19	change_invoice
75	Can delete invoice	19	delete_invoice
76	Can view invoice	19	view_invoice
77	Can add invoice meter entry	20	add_invoicemeterentry
78	Can change invoice meter entry	20	change_invoicemeterentry
79	Can delete invoice meter entry	20	delete_invoicemeterentry
80	Can view invoice meter entry	20	view_invoicemeterentry
81	Can add invoice payment	21	add_invoicepayment
82	Can change invoice payment	21	change_invoicepayment
83	Can delete invoice payment	21	delete_invoicepayment
84	Can view invoice payment	21	view_invoicepayment
85	Can add invoice product line	22	add_invoiceproductline
86	Can change invoice product line	22	change_invoiceproductline
87	Can delete invoice product line	22	delete_invoiceproductline
88	Can view invoice product line	22	view_invoiceproductline
89	Can add invoice service line	23	add_invoiceserviceline
90	Can change invoice service line	23	change_invoiceserviceline
91	Can delete invoice service line	23	delete_invoiceserviceline
92	Can view invoice service line	23	view_invoiceserviceline
93	Can add asset	24	add_asset
94	Can change asset	24	change_asset
95	Can delete asset	24	delete_asset
96	Can view asset	24	view_asset
97	Can add asset incident	25	add_assetincident
98	Can change asset incident	25	change_assetincident
99	Can delete asset incident	25	delete_assetincident
100	Can view asset incident	25	view_assetincident
101	Can add loan	26	add_loan
102	Can change loan	26	change_loan
103	Can delete loan	26	delete_loan
104	Can view loan	26	view_loan
105	Can add loan installment payment	27	add_loaninstallmentpayment
106	Can change loan installment payment	27	change_loaninstallmentpayment
107	Can delete loan installment payment	27	delete_loaninstallmentpayment
108	Can view loan installment payment	27	view_loaninstallmentpayment
109	Can add order	28	add_order
110	Can change order	28	change_order
111	Can delete order	28	delete_order
112	Can view order	28	view_order
113	Can add order item	29	add_orderitem
114	Can change order item	29	change_orderitem
115	Can delete order item	29	delete_orderitem
116	Can view order item	29	view_orderitem
117	Can add audit log entry	31	add_auditlogentry
118	Can change audit log entry	31	change_auditlogentry
119	Can delete audit log entry	31	delete_auditlogentry
120	Can view audit log entry	31	view_auditlogentry
121	Can add audit log	30	add_auditlog
122	Can change audit log	30	change_auditlog
123	Can delete audit log	30	delete_auditlog
124	Can view audit log	30	view_auditlog
125	Can add notification	32	add_notification
126	Can change notification	32	change_notification
127	Can delete notification	32	delete_notification
128	Can view notification	32	view_notification
129	Can add expense	33	add_expense
130	Can change expense	33	change_expense
131	Can delete expense	33	delete_expense
132	Can view expense	33	view_expense
133	Can add Shop Profile	34	add_shopprofile
134	Can change Shop Profile	34	change_shopprofile
135	Can delete Shop Profile	34	delete_shopprofile
136	Can view Shop Profile	34	view_shopprofile
\.


--
-- Data for Name: customers_customer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customers_customer (id, created_at, updated_at, is_deleted, deleted_at, name, phone, address, email, is_red_listed, created_by_id, description) FROM stdin;
127	2026-08-08 13:56:51.856534+00	2026-08-08 13:56:51.856546+00	f	\N	Customer 01	01618149026		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
1	2026-07-23 09:29:52.268947+00	2026-07-23 09:29:52.268965+00	f	\N	Ali Akbar	01737317170		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
31	2026-07-23 09:29:52.411287+00	2026-07-23 09:29:52.411302+00	f	\N	Unknown	0		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
36	2026-07-23 09:29:52.42804+00	2026-07-28 15:54:31.318468+00	f	\N	Khursher - Nalitabari	01713482606	Nalitabari	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
29	2026-07-23 09:29:52.403185+00	2026-08-08 13:45:24.11211+00	f	\N	Khaled Mahmud Nagpara	01761616277		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
37	2026-07-23 09:29:52.431542+00	2026-08-08 13:45:35.270347+00	f	\N	Abul Khayer - Haluaghat	0162094070		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
12	2026-07-23 09:29:52.335905+00	2026-08-08 13:45:48.930801+00	f	\N	Akash Jinaighati	01932572520		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
43	2026-07-23 09:29:52.451805+00	2026-08-08 13:46:06.335824+00	f	\N	Akij- Panir tank	01757085272		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
128	2026-08-11 18:34:59.510231+00	2026-08-11 18:34:59.510247+00	f	\N	Customer Kh 01	01327384255		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
110	2026-07-23 13:00:22.715977+00	2026-08-15 13:44:24.098454+00	f	\N	Noor Islam	013135016156	Nalitabari	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
129	2026-08-24 12:25:25.243995+00	2026-08-24 12:25:25.244014+00	f	\N	Unknown Customer Discover	01863067555		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
130	2026-08-27 10:01:36.603482+00	2026-08-27 10:01:36.6035+00	f	\N	test cust	01		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
131	2026-09-06 12:10:07.447572+00	2026-09-06 12:10:07.447584+00	f	\N	CID	01684237128	Sherpur CID office	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
2	2026-07-23 09:29:52.285886+00	2026-07-23 09:29:52.285912+00	f	\N	Arun Sarkar Nagla	01758658160		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
90	2026-07-23 09:29:52.627496+00	2026-07-23 09:29:52.627506+00	f	\N	Manik	1316619878		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
109	2026-07-23 12:55:09.827398+00	2026-07-23 12:55:09.827418+00	f	\N	Usman Bakshiganj	01728486598	Bakshiganj, Sherpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
111	2026-07-23 13:07:15.437319+00	2026-07-23 13:07:15.437358+00	f	\N	Bijoy	01817803549	Khuarpar	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
112	2026-07-25 04:01:49.606182+00	2026-07-25 04:01:49.606212+00	f	\N	Khurshed Painter	01316619878	Chalkpathak	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
113	2026-07-26 09:21:35.284839+00	2026-07-26 09:21:35.284855+00	f	\N	Bipul	018881591230	Kusumhati	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
114	2026-07-27 13:55:02.802816+00	2026-07-27 13:55:02.802827+00	f	\N	Babu	01391147042	Bou Bazar	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
70	2026-07-23 09:29:52.552337+00	2026-07-28 14:50:15.221804+00	f	\N	Al Amin Nalitabari	01930398679	Nalitabari	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
87	2026-07-23 09:29:52.617018+00	2026-07-28 14:54:55.853939+00	f	\N	Emon Pinter	01780998090	Chalkathak	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
119	2026-07-28 14:30:44.460867+00	2026-07-28 15:24:13.807335+00	f	\N	Kajal Al madina	01761895679	Narayanpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
120	2026-07-30 07:04:38.012035+00	2026-07-30 07:04:38.012048+00	f	\N	Unknown Jinaigati 01	01925313195	Jinaigati, Sherpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
121	2026-07-30 09:33:53.978144+00	2026-07-30 09:33:53.978155+00	f	\N	Ashik Wash	01979103059	Stadium, Chalkpathak	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
122	2026-07-30 18:27:06.76191+00	2026-07-30 18:27:06.761925+00	f	\N	Sujan Bastand, fruite	01714636404	Bas Stand	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
123	2026-08-02 12:49:49.758459+00	2026-08-02 12:49:49.758481+00	f	\N	Sharif Thana	01770104231	Thanar Gate, Sherpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
124	2026-08-03 14:28:51.859614+00	2026-08-03 14:28:51.859628+00	f	\N	Nirab Sriboddi	01963562947	Sriboddi	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
125	2026-08-06 17:42:24.823726+00	2026-08-06 17:42:24.823738+00	f	\N	Faisal Mirgonj	01326608695	Mirgonj, Sherpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
126	2026-08-06 17:48:45.509294+00	2026-08-06 17:48:45.509314+00	f	\N	Glamore	01913913985		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
3	2026-07-23 09:29:52.290373+00	2026-07-23 09:29:52.290388+00	f	\N	Mym Ashadul	01953469177		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
4	2026-07-23 09:29:52.296696+00	2026-07-23 09:29:52.296723+00	f	\N	Taju islam	01925100125		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
5	2026-07-23 09:29:52.302309+00	2026-07-23 09:29:52.302323+00	f	\N	Shuhag Mymensing	01863755824		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
6	2026-07-23 09:29:52.306789+00	2026-07-23 09:29:52.306808+00	f	\N	Helal Jograrchar	01921560170		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
7	2026-07-23 09:29:52.312128+00	2026-07-23 09:29:52.312156+00	f	\N	Akram Hossain Nalitabari	01713522204		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
8	2026-07-23 09:29:52.31707+00	2026-07-23 09:29:52.31712+00	f	\N	Liton khurshed	01758820092		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
9	2026-07-23 09:29:52.322502+00	2026-07-23 09:29:52.322528+00	f	\N	Sudip Nalitabari	01722004483		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
10	2026-07-23 09:29:52.326057+00	2026-07-23 09:29:52.326074+00	f	\N	Shipon - Bottola	01710650486		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
11	2026-07-23 09:29:52.331576+00	2026-07-23 09:29:52.331592+00	f	\N	Kamrul Nalitabari	01712674742		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
13	2026-07-23 09:29:52.340159+00	2026-07-23 09:29:52.34018+00	f	\N	Azad Haluaghat	01913016327		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
14	2026-07-23 09:29:52.344538+00	2026-07-23 09:29:52.344563+00	f	\N	Ikbal Maker- modhupur	01713538428		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
15	2026-07-23 09:29:52.350443+00	2026-07-23 09:29:52.350459+00	f	\N	Shuhag Haluaghat	01716870076		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
16	2026-07-23 09:29:52.354404+00	2026-07-23 09:29:52.354421+00	f	\N	Komol Mia Kalitola	01872005888		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
17	2026-07-23 09:29:52.358557+00	2026-07-23 09:29:52.358573+00	f	\N	Babul Dhubaura	01842519726		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
18	2026-07-23 09:29:52.362964+00	2026-07-23 09:29:52.362982+00	f	\N	Kamruzzaman Nalitabari	01712674747		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
19	2026-07-23 09:29:52.366611+00	2026-07-23 09:29:52.366624+00	f	\N	DB Zafor	01711661419		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
20	2026-07-23 09:29:52.370434+00	2026-07-23 09:29:52.370447+00	f	\N	Zafor bottola	01777046305		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
21	2026-07-23 09:29:52.373845+00	2026-07-23 09:29:52.373864+00	f	\N	Aminul kamarerchar	0192260049		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
22	2026-07-23 09:29:52.377604+00	2026-07-23 09:29:52.377619+00	f	\N	Marfot Nalitabari	01716798978		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
23	2026-07-23 09:29:52.38133+00	2026-07-23 09:29:52.381344+00	f	\N	Razzk Haluaghat	01731419838		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
24	2026-07-23 09:29:52.384852+00	2026-07-23 09:29:52.384871+00	f	\N	Rafique khusumhati	01911736816		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
25	2026-07-23 09:29:52.38867+00	2026-07-23 09:29:52.388685+00	f	\N	Ujjal 2 buira Jograrchar	01719807127		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
26	2026-07-23 09:29:52.392641+00	2026-07-23 09:29:52.392659+00	f	\N	Sha Ali Nalitabari	01940485148		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
27	2026-07-23 09:29:52.396488+00	2026-07-23 09:29:52.396498+00	f	\N	Shohag Nanni	01878947578		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
28	2026-07-23 09:29:52.399917+00	2026-07-23 09:29:52.399934+00	f	\N	Manik Khuarpar	01712400016		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
30	2026-07-23 09:29:52.406311+00	2026-07-23 09:29:52.406321+00	f	\N	Rafiqul Islam Sreeboddi	01613536875		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
32	2026-07-23 09:29:52.414557+00	2026-07-23 09:29:52.414575+00	f	\N	Delwar haluaghat	01925585497		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
33	2026-07-23 09:29:52.4181+00	2026-07-23 09:29:52.418113+00	f	\N	Mofizul Nagla	01734876758		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
34	2026-07-23 09:29:52.421493+00	2026-07-23 09:29:52.421516+00	f	\N	Mazharul Modina Nagla	01729704098		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
35	2026-07-23 09:29:52.42496+00	2026-07-23 09:29:52.424974+00	f	\N	Ershad - Fulpur	01722178869		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
38	2026-07-23 09:29:52.434941+00	2026-07-23 09:29:52.434955+00	f	\N	Mizan Haluaghat	01713150235		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
39	2026-07-23 09:29:52.438288+00	2026-07-23 09:29:52.438303+00	f	\N	Mustafiz	01988800169		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
40	2026-07-23 09:29:52.441618+00	2026-07-23 09:29:52.441641+00	f	\N	Haider- Kamarchar	01936496979		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
41	2026-07-23 09:29:52.444935+00	2026-07-23 09:29:52.444949+00	f	\N	Jibon Batta	01745470714		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
42	2026-07-23 09:29:52.448402+00	2026-07-23 09:29:52.448421+00	f	\N	Hanif Mymensingh	01912728355		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
44	2026-07-23 09:29:52.45513+00	2026-07-23 09:29:52.455144+00	f	\N	Tutul Kamarerchol	01734240576		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
45	2026-07-23 09:29:52.458478+00	2026-07-23 09:29:52.458496+00	f	\N	Rabbi Haque	01797044086		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
46	2026-07-23 09:29:52.463192+00	2026-07-23 09:29:52.463202+00	f	\N	Babul Nakla	01910396757		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
47	2026-07-23 09:29:52.466554+00	2026-07-23 09:29:52.466564+00	f	\N	Pappu - Mirgong	01933867066		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
48	2026-07-23 09:29:52.469822+00	2026-07-23 09:29:52.469836+00	f	\N	Likhon Nakla	01618659200		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
49	2026-07-23 09:29:52.473181+00	2026-07-23 09:29:52.473191+00	f	\N	Sabbir Shamvuganj	01681270923		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
50	2026-07-23 09:29:52.476622+00	2026-07-23 09:29:52.476637+00	f	\N	Shamim Fulpur	01611621960		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
51	2026-07-23 09:29:52.479972+00	2026-07-23 09:29:52.479983+00	f	\N	Shohag Fulpur Baliamore	01626236063		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
52	2026-07-23 09:29:52.483108+00	2026-07-23 09:29:52.48313+00	f	\N	Raju Palli biddot	01714622225		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
53	2026-07-23 09:29:52.487169+00	2026-07-23 09:29:52.487183+00	f	\N	Farukh khuyarpar	01786205222		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
54	2026-07-23 09:29:52.49113+00	2026-07-23 09:29:52.491144+00	f	\N	Azizul Nakla	01720134427		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
55	2026-07-23 09:29:52.494747+00	2026-07-23 09:29:52.494765+00	f	\N	Hannan Nalitabari	01921706988		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
56	2026-07-23 09:29:52.499151+00	2026-07-23 09:29:52.499165+00	f	\N	Hasem Bolayerchor	01986594207		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
57	2026-07-23 09:29:52.503511+00	2026-07-23 09:29:52.503525+00	f	\N	Mym Shofiqul	01947802357		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
58	2026-07-23 09:29:52.507235+00	2026-07-23 09:29:52.507246+00	f	\N	Sapan Nalitabari	01735483248		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
59	2026-07-23 09:29:52.510662+00	2026-07-23 09:29:52.510681+00	f	\N	Rubel Haluaghat	01710831976		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
60	2026-07-23 09:29:52.51428+00	2026-07-23 09:29:52.51429+00	f	\N	Naim hasan Bakshiganj	01409676426		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
61	2026-07-23 09:29:52.519275+00	2026-07-23 09:29:52.519285+00	f	\N	Ornob Nakla	01611439690		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
62	2026-07-23 09:29:52.522557+00	2026-07-23 09:29:52.522568+00	f	\N	Selim Shreboddi	01913170609		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
63	2026-07-23 09:29:52.526056+00	2026-07-23 09:29:52.526066+00	f	\N	Shimul Taratia	01994992225		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
64	2026-07-23 09:29:52.529378+00	2026-07-23 09:29:52.529388+00	f	\N	Kawsar Suzuki Service center	01771595181		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
65	2026-07-23 09:29:52.534407+00	2026-07-23 09:29:52.534418+00	f	\N	Babu Khuarpar	01402007276		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
66	2026-07-23 09:29:52.537813+00	2026-07-23 09:29:52.537823+00	f	\N	Kajol - Sribordi	01401008757		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
67	2026-07-23 09:29:52.541353+00	2026-07-23 09:29:52.541363+00	f	\N	Lokmkman vimgonj	01993973308		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
68	2026-07-23 09:29:52.545393+00	2026-07-23 09:29:52.545405+00	f	\N	Shohidul Shreepoddi	01960106323		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
69	2026-07-23 09:29:52.54884+00	2026-07-23 09:29:52.54885+00	f	\N	Hannan Haluagat	01997451185		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
71	2026-07-23 09:29:52.55608+00	2026-07-23 09:29:52.556091+00	f	\N	Shohag Fulpur	01713592070		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
72	2026-07-23 09:29:52.560323+00	2026-07-23 09:29:52.560334+00	f	\N	Suman Nalitabari	01734858636		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
73	2026-07-23 09:29:52.564659+00	2026-07-23 09:29:52.564692+00	f	\N	Ibrahim master Jinaigati	01917820776		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
74	2026-07-23 09:29:52.568324+00	2026-07-23 09:29:52.568334+00	f	\N	Rezaul karim Nalitabari	01716080627		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
75	2026-07-23 09:29:52.573752+00	2026-07-23 09:29:52.573767+00	f	\N	Atik Jograrchor	01936496276		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
76	2026-07-23 09:29:52.577355+00	2026-07-23 09:29:52.577366+00	f	\N	Hasan Nalitabari	01985065502		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
77	2026-07-23 09:29:52.58142+00	2026-07-23 09:29:52.581434+00	f	\N	Shohel Jangaldi	01929352577		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
78	2026-07-23 09:29:52.585113+00	2026-07-23 09:29:52.585125+00	f	\N	Minal Ostimtola	01861220879		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
79	2026-07-23 09:29:52.588604+00	2026-07-23 09:29:52.588615+00	f	\N	Suman Nalitabari	01995343536		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
80	2026-07-23 09:29:52.591857+00	2026-07-23 09:29:52.591872+00	f	\N	Rafiq vai	01712004177		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
81	2026-07-23 09:29:52.59548+00	2026-07-23 09:29:52.595495+00	f	\N	Arif Thanar gate	01753541820		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
83	2026-07-23 09:29:52.602075+00	2026-07-23 09:29:52.602094+00	f	\N	Azad Jhenaigati	01913518079		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
84	2026-07-23 09:29:52.60633+00	2026-07-23 09:29:52.606345+00	f	\N	Ujjal Jograrchor	01915504944		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
85	2026-07-23 09:29:52.609607+00	2026-07-23 09:29:52.609635+00	f	\N	Imran bhai Bottola	0। 01718567032		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
86	2026-07-23 09:29:52.613257+00	2026-07-23 09:29:52.613269+00	f	\N	Monu Kamarer Char	01951568804		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
88	2026-07-23 09:29:52.620553+00	2026-07-23 09:29:52.620575+00	f	\N	Anwar-Nagla	01722203265		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
89	2026-07-23 09:29:52.62423+00	2026-07-23 09:29:52.624241+00	f	\N	Gulap Hossain Islampur	01920955914		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
91	2026-07-23 09:29:52.631544+00	2026-07-23 09:29:52.631554+00	f	\N	Shahadat Bajitkhila	01924753509		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
92	2026-07-23 09:29:52.63479+00	2026-07-23 09:29:52.634803+00	f	\N	Sapan Motors	01913152920		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
93	2026-07-23 09:29:52.638445+00	2026-07-23 09:29:52.638457+00	f	\N	Atik Bakshigonj	01921442771		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
94	2026-07-23 09:29:52.643172+00	2026-07-23 09:29:52.643187+00	f	\N	Alkas Ali	01712446393		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
95	2026-07-23 09:29:52.646903+00	2026-07-23 09:29:52.646913+00	f	\N	Sadu	01709012918		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
96	2026-07-23 09:29:52.650223+00	2026-07-23 09:29:52.650233+00	f	\N	Piyas Bajaj Kharompur	01795970456		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
97	2026-07-23 09:29:52.654461+00	2026-07-23 09:29:52.654477+00	f	\N	Babu Chaudhuri	01932816962		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
98	2026-07-23 09:29:52.658304+00	2026-07-23 09:29:52.658314+00	f	\N	Jewel Haluaghat	01789042027		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
99	2026-07-23 09:29:52.66248+00	2026-07-23 09:29:52.662497+00	f	\N	Rocky	0185414883		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
100	2026-07-23 09:29:52.666063+00	2026-07-23 09:29:52.666073+00	f	\N	Billal Taratia	01846625848		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
101	2026-07-23 09:29:52.669615+00	2026-07-23 09:29:52.669633+00	f	\N	Goutom Haluaghat	01719174039		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
102	2026-07-23 09:29:52.673185+00	2026-07-23 09:29:52.673208+00	f	\N	Based Bokshigonj	01912518886		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
103	2026-07-23 09:29:52.678053+00	2026-07-23 09:29:52.678074+00	f	\N	Liton Thana	01752154168		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
104	2026-07-23 09:29:52.681849+00	2026-07-23 09:29:52.681862+00	f	\N	Shohidul Joghrarchor	01710722457		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
105	2026-07-23 09:29:52.685518+00	2026-07-23 09:29:52.685529+00	f	\N	Labu Thanar	01724656504		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
106	2026-07-23 09:29:52.688735+00	2026-07-23 09:29:52.688748+00	f	\N	Lockman Vai	01828164748		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
107	2026-07-23 09:29:52.691891+00	2026-07-23 09:29:52.691912+00	f	\N	Sobuj Joghrarchor	01934839654		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
82	2026-07-23 09:29:52.598749+00	2026-07-23 09:29:52.598765+00	t	2026-07-24 12:42:18.399329+00	#N/A	01930131894		\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
108	2026-07-23 09:29:52.695126+00	2026-07-28 16:01:27.416721+00	f	\N	Hasan Khrompur	01722486905	Kharampur, Sherpur	\N	f	9a259d21-6303-464d-97fe-23a835dfdc29	
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
1	2026-07-23 12:52:36.241064+00	9a259d21-6303-464d-97fe-23a835dfdc29	Abdul Wahed Nur	2	[{"changed": {"fields": ["Phone"]}}]	9	9a259d21-6303-464d-97fe-23a835dfdc29
2	2026-07-31 14:30:21.698592+00	f403c6e3-a6ab-46db-b10a-f7f87b941fce	Sadika Sabrin	1	[{"added": {}}]	9	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	meters	mileagecorrectiondevice
2	admin	logentry
3	auth	group
4	auth	permission
5	contenttypes	contenttype
6	sessions	session
7	token_blacklist	blacklistedtoken
8	token_blacklist	outstandingtoken
9	accounts	user
10	customers	customer
11	suppliers	supplier
12	meters	meter
13	services	service
14	services	servicecategory
15	products	product
16	products	productrestockevent
17	products	purchase
18	products	purchaselineitem
19	invoices	invoice
20	invoices	invoicemeterentry
21	invoices	invoicepayment
22	invoices	invoiceproductline
23	invoices	invoiceserviceline
24	assets	asset
25	assets	assetincident
26	loans	loan
27	loans	loaninstallmentpayment
28	ecommerce	order
29	ecommerce	orderitem
30	audit	auditlog
31	audit	auditlogentry
32	notifications	notification
33	expenses	expense
34	shop_profile	shopprofile
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2026-07-23 09:26:07.577246+00
2	contenttypes	0002_remove_content_type_name	2026-07-23 09:26:07.589463+00
3	auth	0001_initial	2026-07-23 09:26:07.653762+00
4	auth	0002_alter_permission_name_max_length	2026-07-23 09:26:07.666591+00
5	auth	0003_alter_user_email_max_length	2026-07-23 09:26:07.675127+00
6	auth	0004_alter_user_username_opts	2026-07-23 09:26:07.711994+00
7	auth	0005_alter_user_last_login_null	2026-07-23 09:26:07.723583+00
8	auth	0006_require_contenttypes_0002	2026-07-23 09:26:07.725436+00
9	auth	0007_alter_validators_add_error_messages	2026-07-23 09:26:07.734502+00
10	auth	0008_alter_user_username_max_length	2026-07-23 09:26:07.744206+00
11	auth	0009_alter_user_last_name_max_length	2026-07-23 09:26:07.755127+00
12	auth	0010_alter_group_name_max_length	2026-07-23 09:26:07.765547+00
13	auth	0011_update_proxy_permissions	2026-07-23 09:26:07.772381+00
14	auth	0012_alter_user_first_name_max_length	2026-07-23 09:26:07.783776+00
15	accounts	0001_initial	2026-07-23 09:26:07.85445+00
16	admin	0001_initial	2026-07-23 09:26:07.880716+00
17	admin	0002_logentry_remove_auto_add	2026-07-23 09:26:07.890861+00
18	admin	0003_logentry_add_action_flag_choices	2026-07-23 09:26:07.899207+00
19	suppliers	0001_initial	2026-07-23 09:26:07.924071+00
20	assets	0001_initial	2026-07-23 09:26:07.976386+00
21	assets	0002_asset_description	2026-07-23 09:26:07.990567+00
22	audit	0001_initial	2026-07-23 09:26:08.023193+00
23	audit	0002_auditlog	2026-07-23 09:26:08.051718+00
24	customers	0001_initial	2026-07-23 09:26:08.081944+00
25	customers	0002_customer_description	2026-07-23 09:26:08.102365+00
26	products	0001_initial	2026-07-23 09:26:08.136541+00
27	products	0002_productrestockevent	2026-07-23 09:26:08.169531+00
28	ecommerce	0001_initial	2026-07-23 09:26:08.235505+00
29	expenses	0001_initial	2026-07-23 09:26:08.263803+00
30	products	0003_purchase_purchaselineitem	2026-07-23 09:26:08.334824+00
31	products	0004_product_description	2026-07-23 09:26:08.358321+00
32	services	0001_initial	2026-07-23 09:26:08.443771+00
33	meters	0001_initial	2026-07-23 09:26:08.479239+00
34	meters	0002_mileagecorrectiondevice	2026-07-23 09:26:08.521123+00
35	meters	0003_seed_mileage_correction_devices	2026-07-23 09:26:08.575117+00
36	invoices	0001_initial	2026-07-23 09:26:08.833654+00
37	invoices	0002_invoice_had_shortfall	2026-07-23 09:26:08.87491+00
38	invoices	0003_invoice_discount_amount_invoice_discount_note	2026-07-23 09:26:08.939924+00
39	invoices	0004_invoiceserviceline_asset_used	2026-07-23 09:26:08.983757+00
40	invoices	0005_invoice_waived_amount_invoice_waived_note_and_more	2026-07-23 09:26:09.293119+00
41	loans	0001_initial	2026-07-23 09:26:09.384109+00
42	meters	0004_meter_description	2026-07-23 09:26:09.424758+00
43	notifications	0001_initial	2026-07-23 09:26:09.484395+00
44	sessions	0001_initial	2026-07-23 09:26:09.49493+00
45	shop_profile	0001_initial	2026-07-23 09:26:09.549734+00
46	token_blacklist	0001_initial	2026-07-23 09:26:09.648835+00
47	token_blacklist	0002_outstandingtoken_jti_hex	2026-07-23 09:26:09.686485+00
48	token_blacklist	0003_auto_20171017_2007	2026-07-23 09:26:09.726803+00
49	token_blacklist	0004_auto_20171017_2013	2026-07-23 09:26:09.771654+00
50	token_blacklist	0005_remove_outstandingtoken_jti	2026-07-23 09:26:09.820372+00
51	token_blacklist	0006_auto_20171017_2113	2026-07-23 09:26:09.861954+00
52	token_blacklist	0007_auto_20171017_2214	2026-07-23 09:26:09.94858+00
53	token_blacklist	0008_migrate_to_bigautofield	2026-07-23 09:26:10.028268+00
54	token_blacklist	0010_fix_migrate_to_bigautofield	2026-07-23 09:26:10.082701+00
55	token_blacklist	0011_linearizes_history	2026-07-23 09:26:10.084508+00
56	token_blacklist	0012_alter_outstandingtoken_user	2026-07-23 09:26:10.121399+00
57	token_blacklist	0013_alter_blacklistedtoken_options_and_more	2026-07-23 09:26:10.164881+00
58	invoices	0006_condition_note_tag_list	2026-07-27 16:16:36.644694+00
59	loans	0002_loaninstallmentpayment_attachment	2026-07-30 06:06:48.491343+00
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
orr7t6x2rid5rzjdi9d6tbb3i10h1xk5	.eJxVjMsKwjAQAP8lZ1vi5u1R8Kx_ULa7G1LUtjTtSfx3EXrQ6zAzL9XhtpZuq7J0A6uTSgguMRwbb7RprLfcpJClAYPROM5MkNThN-uR7jJ-W5zn2iLRtI1rbXde28sTh8d1uZVplPMu_x0K1qJOCnKyGKxFrzNqSsQI3oB2UQQ1R-e5l8Corc4mOE-GkClEkITR9lG9PxYFQc4:1wmpjy:DdI0ba0Eq2EWLMIOaKHONvbR7PcAXMnCvu69KQOE9dE	2026-08-06 09:29:18.277456+00
1q81t7yy74ubc6p8c3kbvxwqwvsmcko3	.eJxVjMsKwjAQAP8lZ1vi5u1R8Kx_ULa7G1LUtjTtSfx3EXrQ6zAzL9XhtpZuq7J0A6uTSgguMRwbb7RprLfcpJClAYPROM5MkNThN-uR7jJ-W5zn2iLRtI1rbXde28sTh8d1uZVplPMu_x0K1qJOCnKyGKxFrzNqSsQI3oB2UQQ1R-e5l8Corc4mOE-GkClEkITR9lG9PxYFQc4:1wocPY:z8lBIGdfNtFOAaZS_6Cr9qSz6uukNCGUPirt63yzq9w	2026-08-11 07:39:36.224319+00
ddafll1w91ssamiq0vcips8lh4vw22bz	.eJxVjMsKwjAQAP8lZ1vi5u1R8Kx_ULa7G1LUtjTtSfx3EXrQ6zAzL9XhtpZuq7J0A6uTSgguMRwbb7RprLfcpJClAYPROM5MkNThN-uR7jJ-W5zn2iLRtI1rbXde28sTh8d1uZVplPMu_x0K1qJOCnKyGKxFrzNqSsQI3oB2UQQ1R-e5l8Corc4mOE-GkClEkITR9lG9PxYFQc4:1woi75:cdrg9ov15L3L1FAuGcal-jYbEhDZYqv3CTsmO3sfIsk	2026-08-11 13:44:55.319604+00
wt4mgldst0j91pdyuu4r9fyhsv0jqh4m	.eJxVzDsOwjAQRdG9uCaRGf8pkahhB9FkZiwjIInipELsHZBSQPt0z3uqDteldGuVubuyOqiE4BLDvvFGm8Z6y00KWRowGI3jzARJ7X5Zj3ST4WtxmmqLROM6LLXd9tqeHni9n-dLGQc5bvHfQ8FaPhxyshisRa8zakrECN6AdlEENUfnuZfAqK3OJjhPhpApRJCE0fZRvd4WBUHO:1wpoEU:Zw6AZJubSaOynFHmlt6aQO5KTq-SJc4fZxNMDZNlDVs	2026-08-14 14:29:06.845315+00
\.


--
-- Data for Name: ecommerce_order; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ecommerce_order (id, created_at, updated_at, is_deleted, deleted_at, order_no, tracking_token, customer_name, customer_phone, customer_address, status, total_amount, created_by_id) FROM stdin;
\.


--
-- Data for Name: ecommerce_orderitem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ecommerce_orderitem (id, created_at, updated_at, is_deleted, deleted_at, quantity, price_charged, created_by_id, order_id, product_id) FROM stdin;
\.


--
-- Data for Name: expenses_expense; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.expenses_expense (id, created_at, updated_at, is_deleted, deleted_at, category, amount, date, note, created_by_id) FROM stdin;
1	2026-07-24 05:53:40.735438+00	2026-07-24 05:53:40.735477+00	f	\N	MISC	510.00	2026-07-24	Sherpur to Mymensingh to Sherpur	9a259d21-6303-464d-97fe-23a835dfdc29
4	2026-07-24 15:56:52.4327+00	2026-07-24 15:56:52.432713+00	f	\N	MISC	320.00	2026-07-24	Chal	9a259d21-6303-464d-97fe-23a835dfdc29
5	2026-07-25 08:44:32.143072+00	2026-07-25 08:44:32.1431+00	f	\N	MISC	130.00	2026-07-25	Sigarate	9a259d21-6303-464d-97fe-23a835dfdc29
6	2026-07-25 08:44:48.723412+00	2026-07-25 08:44:48.723436+00	f	\N	MISC	50.00	2026-07-25	Amra	9a259d21-6303-464d-97fe-23a835dfdc29
7	2026-07-26 09:28:22.657966+00	2026-07-26 09:28:22.657983+00	f	\N	MISC	3200.00	2026-07-26	ডিসকভার      6*220=1320\nFz v2.            2*220=440\nFz v3.             2*320=640\nMonoton.        2*320=640\nDelivery charge 200	9a259d21-6303-464d-97fe-23a835dfdc29
8	2026-07-27 15:01:57.028958+00	2026-07-27 15:01:57.028979+00	f	\N	MISC	500.00	2026-07-27	Cigarate, Parts	9a259d21-6303-464d-97fe-23a835dfdc29
9	2026-07-28 15:00:24.663561+00	2026-07-28 15:00:24.663576+00	f	\N	MISC	500.00	2026-07-28	Cigarate, customer, faire	9a259d21-6303-464d-97fe-23a835dfdc29
10	2026-07-28 15:01:02.96118+00	2026-07-28 15:01:02.961193+00	f	\N	MISC	120.00	2026-07-28	Kalomegh	9a259d21-6303-464d-97fe-23a835dfdc29
11	2026-07-31 14:34:43.707692+00	2026-07-31 14:34:43.707709+00	f	\N	MISC	1615.00	2026-07-31	Mona 600, Daruchini 50, Cream+Facewash 250+275, Cigarate 130,  Food 20. Others 100, Rice 160, Dhonegura 30	9a259d21-6303-464d-97fe-23a835dfdc29
12	2026-08-02 16:19:53.108902+00	2026-08-02 16:19:53.108915+00	f	\N	MISC	1300.00	2026-08-02	bKash loan payment	9a259d21-6303-464d-97fe-23a835dfdc29
13	2026-08-02 16:20:23.016722+00	2026-08-02 16:20:52.048492+00	f	\N	MISC	520.00	2026-08-02	Cigarate	9a259d21-6303-464d-97fe-23a835dfdc29
14	2026-08-03 10:41:18.801276+00	2026-08-03 10:41:18.80129+00	f	\N	MISC	400.00	2026-08-03	Sigarate	9a259d21-6303-464d-97fe-23a835dfdc29
15	2026-08-05 16:43:12.841863+00	2026-08-05 16:43:59.57128+00	f	\N	MISC	800.00	2026-08-05	Gigarate pamparse, bazar	9a259d21-6303-464d-97fe-23a835dfdc29
16	2026-08-06 17:56:37.745874+00	2026-08-06 17:56:37.745892+00	f	\N	MISC	390.00	2026-08-06	Cigarate	9a259d21-6303-464d-97fe-23a835dfdc29
17	2026-08-06 17:57:05.94435+00	2026-08-06 17:57:05.944362+00	f	\N	MISC	2500.00	2026-08-06	Loan	9a259d21-6303-464d-97fe-23a835dfdc29
18	2026-08-06 17:57:20.359769+00	2026-08-06 17:57:20.359781+00	f	\N	MISC	1000.00	2026-08-06	Mona	9a259d21-6303-464d-97fe-23a835dfdc29
19	2026-08-06 18:13:01.074084+00	2026-08-06 18:13:01.074097+00	f	\N	MISC	200.00	2026-08-06	kacha bazar	9a259d21-6303-464d-97fe-23a835dfdc29
20	2026-08-08 16:51:37.573071+00	2026-08-08 16:51:37.573084+00	f	\N	MISC	600.00	2026-08-08		9a259d21-6303-464d-97fe-23a835dfdc29
21	2026-08-09 15:36:40.790199+00	2026-08-09 15:36:40.790216+00	f	\N	MISC	4720.00	2026-08-09	Display	9a259d21-6303-464d-97fe-23a835dfdc29
22	2026-08-12 15:09:32.567435+00	2026-08-12 15:09:32.567448+00	f	\N	MISC	390.00	2026-08-12	Sigarate	9a259d21-6303-464d-97fe-23a835dfdc29
23	2026-08-13 17:13:10.72807+00	2026-08-13 17:13:10.728085+00	f	\N	MISC	2500.00	2026-08-13	Pidim EMI 2500	9a259d21-6303-464d-97fe-23a835dfdc29
24	2026-08-13 17:13:49.205447+00	2026-08-13 17:13:49.205462+00	f	\N	MISC	390.00	2026-08-13	Cigarate	9a259d21-6303-464d-97fe-23a835dfdc29
25	2026-08-13 17:15:03.48338+00	2026-08-13 17:15:03.483394+00	f	\N	MISC	30.00	2026-08-13	Salt + Chilli	9a259d21-6303-464d-97fe-23a835dfdc29
26	2026-08-18 14:25:08.235914+00	2026-08-18 14:25:08.235928+00	f	\N	MISC	500.00	2026-08-18	Cigarate,	9a259d21-6303-464d-97fe-23a835dfdc29
27	2026-08-18 14:25:43.025973+00	2026-08-18 14:25:43.025991+00	f	\N	MISC	10000.00	2026-08-16	Mona	9a259d21-6303-464d-97fe-23a835dfdc29
28	2026-08-20 18:16:21.775292+00	2026-08-20 18:16:21.775312+00	f	\N	MISC	1200.00	2026-08-20	Gigarate390, electricity 500, Osud 325	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: invoices_invoice; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices_invoice (id, created_at, updated_at, is_deleted, deleted_at, invoice_no, status, total_amount, paid_amount, created_date, public_share_token, created_by_id, customer_id, had_shortfall, discount_amount, discount_note, waived_amount, waived_note) FROM stdin;
1	2026-07-23 12:55:27.223401+00	2026-07-23 12:58:59.776341+00	f	\N	INV-2026-00001	PAID	400.00	400.00	2026-07-23	FVosTpZnf1	9a259d21-6303-464d-97fe-23a835dfdc29	109	f	0.00		0.00	
2	2026-07-23 13:00:34.760178+00	2026-07-23 13:01:54.745572+00	f	\N	INV-2026-00002	PAID	500.00	500.00	2026-07-23	Kv50t7aNXK	9a259d21-6303-464d-97fe-23a835dfdc29	110	f	0.00		0.00	
4	2026-07-24 05:47:13.375686+00	2026-07-24 05:49:12.209513+00	f	\N	INV-2026-00004	PAID	400.00	400.00	2026-07-24	RngVGmVySE	9a259d21-6303-464d-97fe-23a835dfdc29	108	f	0.00		0.00	
5	2026-07-25 08:40:28.626294+00	2026-07-25 15:08:48.923963+00	f	\N	INV-2026-00005	PAID	400.00	400.00	2026-07-25	PjaF8Kw2Ow	9a259d21-6303-464d-97fe-23a835dfdc29	108	f	0.00		0.00	
6	2026-07-25 08:46:26.666285+00	2026-07-26 14:10:58.681519+00	f	\N	INV-2026-00006	PAID	400.00	400.00	2026-07-20	bh1eIkGmj0	9a259d21-6303-464d-97fe-23a835dfdc29	112	f	0.00		0.00	
8	2026-07-26 09:24:00.226945+00	2026-07-27 13:49:13.914826+00	f	\N	INV-2026-00008	PARTIAL	1000.00	600.00	2026-07-26	48NPAA74ap	9a259d21-6303-464d-97fe-23a835dfdc29	113	t	0.00		0.00	
12	2026-07-27 13:49:56.200131+00	2026-07-27 13:52:41.697606+00	f	\N	INV-2026-00012	PAID	1800.00	1800.00	2026-07-27	yADU-sN5sE	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
10	2026-07-27 13:31:11.841459+00	2026-07-27 15:04:52.161204+00	f	\N	INV-2026-00010	PAID	400.00	400.00	2026-07-27	NWaxL7rGwg	9a259d21-6303-464d-97fe-23a835dfdc29	112	f	0.00		0.00	
13	2026-07-27 13:55:18.205732+00	2026-08-03 16:14:18.643668+00	f	\N	INV-2026-00013	PAID	1000.00	1000.00	2026-07-27	qGzX45gCde	9a259d21-6303-464d-97fe-23a835dfdc29	114	t	0.00		500.00	Give me a v3 meter
22	2026-07-30 18:27:14.826757+00	2026-07-31 08:34:55.92343+00	f	\N	INV-2026-00019	PARTIAL	1900.00	1500.00	2026-07-30	GDrSiNQxCh	9a259d21-6303-464d-97fe-23a835dfdc29	122	t	0.00		0.00	
11	2026-07-27 13:46:23.319675+00	2026-07-31 14:31:10.746587+00	f	\N	INV-2026-00011	PAID	400.00	400.00	2026-07-27	fHatLS7ba7	9a259d21-6303-464d-97fe-23a835dfdc29	83	f	0.00		0.00	
42	2026-08-11 18:35:23.182513+00	2026-08-12 15:06:09.23819+00	f	\N	INV-2026-00039	PAID	1800.00	1800.00	2026-08-11	Pq9SV4HQGM	9a259d21-6303-464d-97fe-23a835dfdc29	128	f	0.00		0.00	
19	2026-07-28 14:30:53.317255+00	2026-07-28 15:28:14.727889+00	f	\N	INV-2026-00016	PAID	1500.00	1500.00	2026-07-28	HU3JYoMgWg	9a259d21-6303-464d-97fe-23a835dfdc29	119	f	700.00	Rembmer	0.00	
34	2026-08-06 17:42:36.207746+00	2026-08-06 17:43:50.591262+00	f	\N	INV-2026-00031	PAID	500.00	500.00	2026-08-06	IgsLtDFrDV	9a259d21-6303-464d-97fe-23a835dfdc29	125	f	0.00		0.00	
27	2026-08-04 07:33:59.491685+00	2026-08-04 07:49:06.537702+00	f	\N	INV-2026-00024	PAID	400.00	400.00	2026-08-04	Cw6jhsTJT-	9a259d21-6303-464d-97fe-23a835dfdc29	103	f	0.00		0.00	
20	2026-07-30 07:04:49.778307+00	2026-07-30 07:06:01.024564+00	f	\N	INV-2026-00017	PAID	400.00	400.00	2026-07-30	OJatoXvdTw	9a259d21-6303-464d-97fe-23a835dfdc29	120	f	0.00		0.00	
37	2026-08-08 13:57:05.2957+00	2026-08-08 15:43:58.439789+00	f	\N	INV-2026-00034	PAID	400.00	400.00	2026-08-08	R3NLZXM_dH	9a259d21-6303-464d-97fe-23a835dfdc29	127	f	0.00		0.00	
21	2026-07-30 09:34:13.976488+00	2026-07-30 10:16:34.841483+00	f	\N	INV-2026-00018	PAID	400.00	400.00	2026-07-30	4O9E5cjjrk	9a259d21-6303-464d-97fe-23a835dfdc29	121	f	0.00		0.00	
40	2026-08-10 08:58:41.853045+00	2026-08-10 08:59:40.626247+00	f	\N	INV-2026-00037	PAID	470.00	470.00	2026-08-10	X53bynltsW	9a259d21-6303-464d-97fe-23a835dfdc29	105	f	30.00		0.00	
7	2026-07-26 07:34:30.097928+00	2026-09-03 17:06:30.864441+00	f	\N	INV-2026-00007	PARTIAL	11500.00	1500.00	2026-07-26	Lw40zQIDq6	9a259d21-6303-464d-97fe-23a835dfdc29	94	t	0.00		0.00	
14	2026-07-27 14:59:50.644192+00	2026-08-09 15:29:42.463315+00	f	\N	INV-2026-00014	PAID	1500.00	1500.00	2026-07-27	125Hy9fW2r	9a259d21-6303-464d-97fe-23a835dfdc29	36	f	200.00	Discount for display pchange	0.00	
26	2026-08-03 14:29:03.148312+00	2026-08-05 06:37:29.468487+00	f	\N	INV-2026-00023	PAID	800.00	800.00	2026-08-03	1OOlN5wkaE	9a259d21-6303-464d-97fe-23a835dfdc29	124	f	0.00		0.00	
35	2026-08-06 17:49:03.385272+00	2026-08-06 17:55:27.19458+00	f	\N	INV-2026-00032	PAID	1000.00	1000.00	2026-08-06	zvFiYN1ATF	9a259d21-6303-464d-97fe-23a835dfdc29	126	f	0.00		0.00	
9	2026-07-27 07:36:10.358946+00	2026-08-02 16:17:42.447347+00	f	\N	INV-2026-00009	PAID	2100.00	2100.00	2026-07-27	P370ER4-Ai	9a259d21-6303-464d-97fe-23a835dfdc29	46	f	300.00		0.00	
23	2026-08-02 12:50:01.121044+00	2026-08-02 16:18:13.008713+00	f	\N	INV-2026-00020	PAID	800.00	800.00	2026-08-02	0rNrcPCr-4	9a259d21-6303-464d-97fe-23a835dfdc29	123	f	0.00		0.00	
41	2026-08-11 18:33:24.393675+00	2026-08-11 18:33:24.393691+00	t	2026-08-11 18:35:11.568779+00	INV-2026-00038	UNPAID	0.00	0.00	2026-08-11	hfjw7Bazdp	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
24	2026-08-03 10:35:02.204045+00	2026-08-03 10:40:19.196993+00	f	\N	INV-2026-00021	PAID	700.00	700.00	2026-08-03	QpfQBIYuNK	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	100.00		0.00	
25	2026-08-03 14:24:53.191136+00	2026-08-03 14:27:24.992276+00	f	\N	INV-2026-00022	PAID	400.00	400.00	2026-08-03	glNnvo3yEJ	9a259d21-6303-464d-97fe-23a835dfdc29	75	f	0.00		0.00	
38	2026-08-09 15:30:12.614448+00	2026-08-09 15:30:31.617315+00	f	\N	INV-2026-00035	PAID	400.00	400.00	2026-08-09	k6rqGM3C_a	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
29	2026-08-05 15:51:34.948129+00	2026-08-05 15:52:33.370524+00	f	\N	INV-2026-00026	PAID	400.00	400.00	2026-08-05	wAXIgR1AGr	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
30	2026-08-06 05:04:19.456378+00	2026-08-08 04:58:25.771483+00	f	\N	INV-2026-00027	PAID	2800.00	2800.00	2026-08-06	BIuexbkqTa	9a259d21-6303-464d-97fe-23a835dfdc29	43	f	100.00		0.00	
28	2026-08-05 15:49:59.625416+00	2026-08-05 16:41:43.862309+00	f	\N	INV-2026-00025	PAID	400.00	400.00	2026-08-05	if7nxy7DDo	9a259d21-6303-464d-97fe-23a835dfdc29	66	f	0.00		0.00	
31	2026-08-06 11:03:51.077692+00	2026-08-06 11:07:07.539352+00	f	\N	INV-2026-00028	PAID	400.00	400.00	2026-08-06	V8NWsXaeny	9a259d21-6303-464d-97fe-23a835dfdc29	109	f	0.00		0.00	
15	2026-07-27 15:05:05.736894+00	2026-08-08 05:27:17.140553+00	f	\N	INV-2026-00015	PAID	300.00	300.00	2026-07-27	YLmPXX-Xai	9a259d21-6303-464d-97fe-23a835dfdc29	108	t	0.00		100.00	kom dise 100 tk
32	2026-08-06 11:07:35.010763+00	2026-08-06 11:08:20.317311+00	f	\N	INV-2026-00029	PAID	400.00	400.00	2026-08-06	v2Fqk6NGmC	9a259d21-6303-464d-97fe-23a835dfdc29	16	f	0.00		0.00	
33	2026-08-06 17:38:37.05546+00	2026-08-06 17:40:46.46736+00	f	\N	INV-2026-00030	PAID	400.00	400.00	2026-08-06	mafOlncEqS	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
36	2026-08-08 11:41:41.681214+00	2026-08-08 11:42:51.242897+00	f	\N	INV-2026-00033	PAID	900.00	900.00	2026-08-08	IrX8RD6n47	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
39	2026-08-10 08:56:45.988178+00	2026-08-10 08:58:31.303446+00	f	\N	INV-2026-00036	PAID	440.00	440.00	2026-08-10	12NNsdKOdg	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	60.00		0.00	
43	2026-08-11 18:41:12.738445+00	2026-08-13 12:23:24.042616+00	f	\N	INV-2026-00040	PAID	400.00	400.00	2026-08-11	wvNQKwnKSC	9a259d21-6303-464d-97fe-23a835dfdc29	112	f	0.00		0.00	
46	2026-08-13 10:56:59.883689+00	2026-08-13 10:58:15.233352+00	f	\N	INV-2026-00043	PAID	1800.00	1800.00	2026-08-13	8RLfzI30A-	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
44	2026-08-12 15:10:09.939549+00	2026-08-12 15:11:34.373099+00	f	\N	INV-2026-00041	PAID	400.00	400.00	2026-08-12	3bemkm7j3a	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
48	2026-08-15 13:44:35.989247+00	2026-08-17 21:10:48.535729+00	f	\N	INV-2026-00045	PAID	1400.00	1400.00	2026-08-15	JpOosXFEw6	9a259d21-6303-464d-97fe-23a835dfdc29	110	f	0.00		0.00	
47	2026-08-13 10:59:03.589181+00	2026-08-13 12:23:41.283109+00	f	\N	INV-2026-00044	PAID	400.00	400.00	2026-08-13	y528Ly1pAR	9a259d21-6303-464d-97fe-23a835dfdc29	24	f	0.00		0.00	
49	2026-08-17 11:31:21.561535+00	2026-08-17 11:32:02.909033+00	f	\N	INV-2026-00046	PAID	400.00	400.00	2026-08-17	Y1nu56SNi5	9a259d21-6303-464d-97fe-23a835dfdc29	109	f	0.00		0.00	
50	2026-08-18 11:35:45.321101+00	2026-08-18 11:37:10.225539+00	f	\N	INV-2026-00047	PAID	400.00	400.00	2026-08-18	vIvkWKjOHv	9a259d21-6303-464d-97fe-23a835dfdc29	28	f	0.00		0.00	
51	2026-08-18 11:37:29.088892+00	2026-08-18 11:38:29.854774+00	f	\N	INV-2026-00048	PAID	400.00	400.00	2026-08-18	g4Bx8gc0tL	9a259d21-6303-464d-97fe-23a835dfdc29	124	f	0.00		0.00	
45	2026-08-12 15:14:28.935313+00	2026-08-30 10:18:00.964182+00	f	\N	INV-2026-00042	PAID	700.00	700.00	2026-08-12	9mG9GcsMKM	9a259d21-6303-464d-97fe-23a835dfdc29	123	t	100.00		0.00	
52	2026-08-18 11:39:01.436447+00	2026-08-24 12:21:49.571322+00	f	\N	INV-2026-00049	PARTIAL	1900.00	1600.00	2026-08-18	KOFdDm1ARz	9a259d21-6303-464d-97fe-23a835dfdc29	108	t	400.00	For Display paper change	0.00	
53	2026-08-19 11:40:04.390372+00	2026-08-19 11:41:23.237794+00	f	\N	INV-2026-00050	PAID	400.00	400.00	2026-08-19	EzipI9QLT5	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
54	2026-08-20 14:55:18.675058+00	2026-08-20 14:56:20.74989+00	f	\N	INV-2026-00051	PAID	400.00	400.00	2026-08-20	50a_bxVkc5	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
3	2026-07-23 13:07:30.607423+00	2026-08-27 10:12:53.288691+00	f	\N	INV-2026-00003	PARTIAL	1200.00	800.00	2026-07-22	hgAuNOJ9Fs	9a259d21-6303-464d-97fe-23a835dfdc29	111	t	0.00		0.00	
55	2026-08-20 14:56:46.873618+00	2026-08-20 14:57:09.038418+00	f	\N	INV-2026-00052	PAID	400.00	400.00	2026-08-20	BMydGiLvzW	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
57	2026-08-20 18:13:14.313561+00	2026-08-20 18:14:16.549419+00	f	\N	INV-2026-00054	PAID	400.00	400.00	2026-08-20	CrK5CeZQR1	9a259d21-6303-464d-97fe-23a835dfdc29	67	f	0.00		0.00	
69	2026-09-03 17:00:56.78768+00	2026-09-03 17:04:04.446306+00	f	\N	INV-2026-00066	PAID	1000.00	1000.00	2026-09-03	f19I1UYQre	9a259d21-6303-464d-97fe-23a835dfdc29	46	t	200.00		0.00	
58	2026-08-23 09:03:14.815375+00	2026-08-23 09:04:18.245175+00	f	\N	INV-2026-00055	PAID	400.00	400.00	2026-08-23	4Xu3pwwCVs	9a259d21-6303-464d-97fe-23a835dfdc29	81	f	0.00		0.00	
60	2026-08-23 13:02:04.86518+00	2026-08-23 13:04:46.134004+00	f	\N	INV-2026-00057	PAID	400.00	400.00	2026-08-23	n37xFXV_bK	9a259d21-6303-464d-97fe-23a835dfdc29	86	f	0.00		0.00	
56	2026-08-20 14:57:31.194637+00	2026-08-23 13:05:50.175049+00	f	\N	INV-2026-00053	PAID	1400.00	1400.00	2026-08-20	EueFE4gt6n	9a259d21-6303-464d-97fe-23a835dfdc29	24	f	0.00		0.00	
70	2026-09-03 17:04:36.394622+00	2026-09-03 17:05:38.129787+00	f	\N	INV-2026-00067	PAID	400.00	400.00	2026-09-03	SRt00l1Cll	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
61	2026-08-24 12:25:35.861869+00	2026-08-24 12:26:24.129548+00	f	\N	INV-2026-00058	PAID	1200.00	1200.00	2026-08-24	XRgeKT_Ecg	9a259d21-6303-464d-97fe-23a835dfdc29	129	f	0.00		0.00	
68	2026-09-03 08:32:05.383137+00	2026-09-04 16:55:03.45172+00	f	\N	INV-2026-00065	PAID	1400.00	1400.00	2026-09-03	bdxXAVOBoL	9a259d21-6303-464d-97fe-23a835dfdc29	124	t	0.00		0.00	
62	2026-08-27 10:01:43.228733+00	2026-08-27 10:02:53.337617+00	f	\N	INV-2026-00059	UNPAID	0.00	0.00	2026-08-27	1WQsJlsGOl	9a259d21-6303-464d-97fe-23a835dfdc29	130	f	0.00		0.00	
63	2026-08-29 17:13:29.144537+00	2026-08-29 17:14:36.049121+00	f	\N	INV-2026-00060	PAID	1200.00	1200.00	2026-08-29	HzspX5Ugk2	9a259d21-6303-464d-97fe-23a835dfdc29	109	f	0.00		0.00	
64	2026-09-01 16:58:34.421081+00	2026-09-01 16:59:41.08139+00	f	\N	INV-2026-00061	PAID	400.00	400.00	2026-09-01	QryFnkzPfk	9a259d21-6303-464d-97fe-23a835dfdc29	109	f	0.00		0.00	
71	2026-09-05 11:06:49.691289+00	2026-09-06 12:08:01.68621+00	f	\N	INV-2026-00068	PAID	1500.00	1500.00	2026-09-05	X3_CI4utin	9a259d21-6303-464d-97fe-23a835dfdc29	105	f	0.00		0.00	
65	2026-09-01 17:00:10.699361+00	2026-09-01 17:00:58.624664+00	f	\N	INV-2026-00062	PAID	500.00	500.00	2026-09-01	WPmxidVJe7	9a259d21-6303-464d-97fe-23a835dfdc29	46	f	0.00		0.00	
66	2026-09-01 17:01:15.17573+00	2026-09-06 12:08:28.042177+00	f	\N	INV-2026-00063	PAID	1500.00	1500.00	2026-09-01	-iQO_c-IwB	9a259d21-6303-464d-97fe-23a835dfdc29	123	f	100.00		0.00	
72	2026-09-06 12:10:22.124143+00	2026-09-06 12:10:53.094122+00	f	\N	INV-2026-00069	PAID	3500.00	3500.00	2026-09-06	tSvPJQGOEM	9a259d21-6303-464d-97fe-23a835dfdc29	131	f	0.00		0.00	
73	2026-09-06 12:11:08.160094+00	2026-09-06 12:11:32.76435+00	f	\N	INV-2026-00070	PAID	400.00	400.00	2026-09-06	xQZXgNPE5-	9a259d21-6303-464d-97fe-23a835dfdc29	31	f	0.00		0.00	
59	2026-08-23 09:04:26.669675+00	2026-09-03 08:34:09.765145+00	f	\N	INV-2026-00056	PAID	700.00	700.00	2026-08-23	g1oYotRHo3	9a259d21-6303-464d-97fe-23a835dfdc29	43	t	100.00		0.00	
67	2026-09-01 17:03:57.136291+00	2026-09-11 15:22:09.221498+00	f	\N	INV-2026-00064	PARTIAL	1600.00	1300.00	2026-09-01	glcjZktGLV	9a259d21-6303-464d-97fe-23a835dfdc29	66	t	0.00		0.00	
74	2026-09-08 06:03:16.113433+00	2026-09-15 10:52:00.107801+00	f	\N	INV-2026-00071	UNPAID	800.00	0.00	2026-09-08	PWok2akX78	9a259d21-6303-464d-97fe-23a835dfdc29	123	f	0.00		0.00	
\.


--
-- Data for Name: invoices_invoicemeterentry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices_invoicemeterentry (id, created_at, updated_at, is_deleted, deleted_at, serial_number, previous_km, current_km, service_date, paid_share, created_by_id, invoice_id, meter_id, mileage_correction_device_id, condition_note) FROM stdin;
1	2026-07-23 12:58:50.013361+00	2026-07-23 12:58:50.013378+00	f	\N	\N	0	0	2026-07-23 12:58:50.013455+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	1	5	2	["good"]
2	2026-07-23 13:01:16.257024+00	2026-07-23 13:01:16.257146+00	f	\N	\N	35835	17178	2026-07-23 13:01:16.257391+00	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	2	5	\N	["good"]
4	2026-07-24 05:49:04.209317+00	2026-07-24 05:49:04.209356+00	f	\N	341-34J0	6328	1570	2026-07-24 05:49:04.209655+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	4	10	2	["good"]
5	2026-07-25 08:42:20.698693+00	2026-07-25 08:42:20.698741+00	f	\N	DH191066	54689	22319	2026-07-25 08:42:20.698811+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	5	5	2	["good"]
6	2026-07-25 08:47:05.156673+00	2026-07-25 08:47:05.156686+00	f	\N	\N	\N	\N	2026-07-25 08:47:05.156736+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	6	1	1	["good"]
10	2026-07-27 13:35:24.177942+00	2026-07-27 13:35:24.177979+00	t	2026-07-27 15:04:41.881553+00	\N	67705	25219	2026-07-27 13:35:24.178076+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	10	4	\N	["good"]
11	2026-07-27 13:44:59.279315+00	2026-07-27 13:44:59.279336+00	f	\N	\N	40490	18681	2026-07-27 13:44:59.279406+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	10	24	1	["good"]
103	2026-09-06 12:11:27.187818+00	2026-09-06 12:11:27.187831+00	f	\N	\N	\N	\N	2026-09-06 12:11:27.187881+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	73	39	1	["Good"]
104	2026-09-08 06:03:46.455201+00	2026-09-08 06:03:46.455215+00	f	\N	\N	\N	\N	2026-09-08 06:03:46.455272+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	74	4	4	["Good"]
105	2026-09-15 10:52:00.043645+00	2026-09-15 10:52:00.043658+00	f	\N	\N	36106	24128	2026-09-15 10:52:00.043719+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	74	3	1	["Good"]
40	2026-08-03 14:27:15.74358+00	2026-08-03 14:27:15.743592+00	f	\N	\N	16550	6123	2026-08-03 14:27:15.743644+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	25	1	1	["Good"]
28	2026-07-28 14:32:55.093243+00	2026-07-28 15:25:14.315398+00	f	\N	DH191065	\N	20462	2026-07-28 14:32:55.093308+00	1500.00	9a259d21-6303-464d-97fe-23a835dfdc29	19	5	2	["Display Problem"]
8	2026-07-27 07:37:35.592882+00	2026-07-27 07:37:35.592939+00	f	\N	DH191071	101095	20302	2026-07-27 07:37:35.593023+00	2100.00	9a259d21-6303-464d-97fe-23a835dfdc29	9	5	\N	["good"]
36	2026-08-02 12:51:38.688964+00	2026-08-02 12:51:38.688978+00	f	\N	341-34J0	25796	18140	2026-08-02 12:51:38.689028+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	23	10	2	["Good"]
42	2026-08-04 07:35:13.311289+00	2026-08-04 07:35:13.311303+00	f	\N	2GS-H3500	22204	11552	2026-08-04 07:35:13.311367+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	27	17	4	["Good"]
31	2026-07-30 07:05:52.444107+00	2026-07-30 07:05:52.444125+00	f	\N	\N	102284	27639	2026-07-30 07:05:52.444183+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	20	41	4	["Good"]
32	2026-07-30 09:35:37.757607+00	2026-07-30 09:35:37.757625+00	f	\N	2GSH3500-00	110471	49228	2026-07-30 09:35:37.757695+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	21	17	4	["Good"]
33	2026-07-30 18:28:45.848965+00	2026-07-30 18:28:45.848979+00	f	\N	\N	164000	55186	2026-07-30 18:28:45.849024+00	1500.00	9a259d21-6303-464d-97fe-23a835dfdc29	22	5	2	["Display Problem"]
12	2026-07-27 13:47:13.57196+00	2026-07-27 13:47:13.571972+00	f	\N	\N	68858	25219	2026-07-27 13:47:13.572018+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	11	4	\N	["good"]
37	2026-08-02 12:53:07.707127+00	2026-08-02 12:53:07.707142+00	f	\N	341-34J0	19225	9456	2026-08-02 12:53:07.707206+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	23	10	2	["Good"]
38	2026-08-03 10:37:23.139977+00	2026-08-03 10:38:41.257156+00	f	\N	\N	51565	14138	2026-08-03 10:37:23.140033+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	24	5	2	["Good"]
39	2026-08-03 10:40:03.567336+00	2026-08-03 10:40:03.567351+00	f	\N	\N	37975	15119	2026-08-03 10:40:03.567403+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	24	27	2	["Good"]
3	2026-07-23 13:08:23.320149+00	2026-07-27 16:21:17.66934+00	f	\N	\N	0	0	2026-07-23 13:08:23.320385+00	266.66	9a259d21-6303-464d-97fe-23a835dfdc29	3	10	2	["Good"]
41	2026-08-03 14:29:43.27417+00	2026-08-03 14:29:43.274182+00	f	\N	\N	45483	21251	2026-08-03 14:29:43.274228+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	26	1	1	["Good"]
46	2026-08-05 06:37:09.463553+00	2026-08-05 06:37:09.463566+00	f	\N	\N	\N	\N	2026-08-05 06:37:09.463608+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	26	5	\N	["Good"]
9	2026-07-27 09:38:21.427367+00	2026-07-27 09:38:21.427491+00	f	\N	JZ402422	35643	13919	2026-07-27 09:38:21.427625+00	266.67	9a259d21-6303-464d-97fe-23a835dfdc29	3	1	1	["Display will go soon"]
30	2026-07-28 15:34:00.940922+00	2026-07-28 15:34:00.940938+00	f	\N	34134J0	29522	18140	2026-07-28 15:34:00.940999+00	266.67	9a259d21-6303-464d-97fe-23a835dfdc29	3	10	2	["Display Problem"]
17	2026-07-27 17:24:57.458137+00	2026-07-27 18:56:35.345023+00	f	\N	A2C1297290101	36001	16012	2026-07-27 17:24:57.458364+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	39	\N	["Good"]
18	2026-07-27 17:35:17.403146+00	2026-07-27 17:35:17.403206+00	f	\N	\N	34519	14327	2026-07-27 17:35:17.403686+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	12	\N	["Good"]
49	2026-08-05 15:52:26.329843+00	2026-08-05 15:52:26.329857+00	f	\N	\N	29615	11725	2026-08-05 15:52:26.329942+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	29	1	1	["Good"]
45	2026-08-05 06:35:31.965028+00	2026-08-05 15:56:04.715424+00	t	2026-08-06 07:32:32.797901+00	\N	119665	24501	2026-08-05 06:35:31.965102+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	21	4	["Light Problem"]
29	2026-07-28 14:48:03.783382+00	2026-07-28 14:48:03.783398+00	t	2026-08-09 15:29:20.503596+00	\N	\N	16044	2026-07-28 14:48:03.783453+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	14	5	\N	["Display Problem"]
43	2026-08-04 14:54:22.919305+00	2026-08-04 14:54:22.919326+00	t	2026-08-06 07:32:25.605063+00	\N	55000	25441	2026-08-04 14:54:22.919384+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	18	2	["Good"]
44	2026-08-05 06:34:37.304681+00	2026-08-05 06:34:37.304695+00	t	2026-08-06 07:32:20.308082+00	\N	51840	23401	2026-08-05 06:34:37.30474+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	21	4	["Display Repair kora hoyese"]
48	2026-08-05 15:50:45.966582+00	2026-08-05 15:50:45.966597+00	f	\N	\N	432	12071	2026-08-05 15:50:45.966657+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	28	17	4	["Good"]
51	2026-08-06 07:30:32.417732+00	2026-08-06 07:30:32.417744+00	f	\N	\N	119665	24501	2026-08-06 07:30:32.417784+00	1400.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	21	4	["Good"]
13	2026-07-27 15:06:22.185131+00	2026-07-27 15:06:22.185162+00	f	\N	\N	67705	25219	2026-07-27 15:06:22.185277+00	300.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	4	5	["good"]
52	2026-08-06 11:07:01.590374+00	2026-08-06 11:07:01.590389+00	f	\N	\N	11761	5510	2026-08-06 11:07:01.590472+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	31	17	4	["Good"]
53	2026-08-06 11:08:13.927951+00	2026-08-06 11:08:13.927967+00	f	\N	\N	54018	21178	2026-08-06 11:08:13.928059+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	32	10	2	["Good"]
54	2026-08-06 17:40:41.013562+00	2026-08-06 17:40:41.013576+00	f	\N	\N	15020	8038	2026-08-06 17:40:41.013626+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	33	10	\N	["Good"]
55	2026-08-06 17:43:23.397068+00	2026-08-06 17:43:44.613307+00	f	\N	\N	70826	26233	2026-08-06 17:43:23.397141+00	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	34	5	2	["Good"]
50	2026-08-06 07:28:48.164152+00	2026-08-06 07:28:48.164184+00	f	\N	\N	55000	25441	2026-08-06 07:28:48.164284+00	1400.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	18	2	["Good"]
74	2026-08-17 11:31:55.515382+00	2026-08-17 11:31:55.515398+00	f	\N	\N	\N	13205	2026-08-17 11:31:55.515445+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	49	25	1	["Good"]
70	2026-08-15 13:45:43.349302+00	2026-08-15 13:46:41.584272+00	f	\N	2GSH3500-00	51617	30219	2026-08-15 13:45:43.349356+00	700.00	9a259d21-6303-464d-97fe-23a835dfdc29	48	17	5	["Good"]
71	2026-08-15 13:46:28.628939+00	2026-08-15 13:46:28.628954+00	f	\N	\N	69282	27174	2026-08-15 13:46:28.629009+00	700.00	9a259d21-6303-464d-97fe-23a835dfdc29	48	18	2	["Good"]
56	2026-08-06 17:50:17.357906+00	2026-08-06 17:55:05.916872+00	f	\N	\N	49000	20296	2026-08-06 17:50:17.357959+00	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	35	39	1	["Good"]
57	2026-08-06 17:54:58.39192+00	2026-08-06 17:54:58.391932+00	f	\N	\N	52356	22229	2026-08-06 17:54:58.391972+00	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	35	42	2	["Good"]
58	2026-08-08 11:42:41.189881+00	2026-08-08 11:42:41.1899+00	f	\N	\N	24866	1342	2026-08-08 11:42:41.190004+00	900.00	9a259d21-6303-464d-97fe-23a835dfdc29	36	43	\N	["Good"]
59	2026-08-08 13:58:20.941882+00	2026-08-08 13:58:20.941897+00	f	\N	\N	49183	25043	2026-08-08 13:58:20.941966+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	37	14	2	["Good"]
60	2026-08-09 15:30:25.771022+00	2026-08-09 15:30:25.771037+00	f	\N	\N	\N	\N	2026-08-09 15:30:25.771094+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	38	39	\N	["Good"]
61	2026-08-10 08:58:02.635101+00	2026-08-10 08:58:02.635114+00	f	\N	\N	51178	34150	2026-08-10 08:58:02.635163+00	440.00	9a259d21-6303-464d-97fe-23a835dfdc29	39	3	\N	["Good"]
62	2026-08-10 08:59:23.608719+00	2026-08-10 08:59:23.608731+00	f	\N	\N	42202	12017	2026-08-10 08:59:23.608776+00	470.00	9a259d21-6303-464d-97fe-23a835dfdc29	40	1	1	["Good"]
67	2026-08-12 15:11:22.919729+00	2026-08-12 15:11:22.919741+00	f	\N	\N	38286	15286	2026-08-12 15:11:22.919786+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	44	21	5	["Good"]
68	2026-08-12 15:15:24.735376+00	2026-08-12 15:15:24.735393+00	f	\N	\N	49261	25261	2026-08-12 15:15:24.735488+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	45	23	2	["Good"]
65	2026-08-11 18:42:11.046511+00	2026-08-12 15:13:52.382914+00	f	\N	\N	60970	19373	2026-08-11 18:42:11.046583+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	43	41	5	["Good"]
69	2026-08-13 11:00:26.276741+00	2026-08-13 11:00:26.276758+00	f	\N	\N	\N	20111	2026-08-13 11:00:26.276823+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	47	17	5	["Good"]
78	2026-08-18 14:18:55.602006+00	2026-08-18 14:18:55.602019+00	f	\N	\N	46653	22384	2026-08-18 14:18:55.602078+00	800.00	9a259d21-6303-464d-97fe-23a835dfdc29	52	3	\N	["Good"]
88	2026-08-24 12:21:37.362958+00	2026-08-24 12:21:37.362969+00	f	\N	\N	\N	17294	2026-08-24 12:21:37.363025+00	800.00	9a259d21-6303-464d-97fe-23a835dfdc29	52	24	1	["Good"]
76	2026-08-18 11:37:01.735028+00	2026-08-18 11:37:01.735046+00	f	\N	\N	106986	23536	2026-08-18 11:37:01.735108+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	50	26	1	["Good"]
77	2026-08-18 11:38:22.154093+00	2026-08-18 11:38:22.154105+00	f	\N	\N	38069	20505	2026-08-18 11:38:22.154152+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	51	1	1	["Good"]
79	2026-08-18 17:06:04.399137+00	2026-08-18 17:06:04.399153+00	f	\N	\N	37827	18512	2026-08-18 17:06:04.399234+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	45	1	1	["Good"]
19	2026-07-27 17:36:07.53278+00	2026-07-27 17:36:07.532803+00	f	\N	\N	39857	25566	2026-07-27 17:36:07.53303+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	10	\N	["Good"]
86	2026-08-23 09:05:08.01804+00	2026-08-23 09:05:08.018054+00	f	\N	\N	31839	18106	2026-08-23 09:05:08.018098+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	59	5	2	["Good"]
7	2026-07-26 07:40:39.82724+00	2026-07-26 07:40:39.827261+00	f	\N	JZ 402422 0024	39906	12294	2026-07-26 07:40:39.827361+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	1	1	["good"]
20	2026-07-27 17:37:04.446745+00	2026-07-27 17:37:04.446768+00	f	\N	\N	27133	7111	2026-07-27 17:37:04.446879+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	14	\N	["Good"]
21	2026-07-27 17:37:56.161983+00	2026-07-27 17:37:56.162011+00	f	\N	\N	13442	4717	2026-07-27 17:37:56.162135+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	27	\N	["Good"]
22	2026-07-27 17:47:24.036348+00	2026-07-27 17:47:24.036372+00	f	\N	\N	42821	20122	2026-07-27 17:47:24.03649+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	40	\N	["Good"]
23	2026-07-27 17:48:07.538536+00	2026-07-27 17:48:07.538668+00	f	\N	\N	71162	17116	2026-07-27 17:48:07.538811+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	1	\N	["Good"]
24	2026-07-27 17:50:35.122639+00	2026-07-27 17:50:35.122665+00	f	\N	\N	106199	15227	2026-07-27 17:50:35.122775+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	24	\N	["Good"]
80	2026-08-19 11:41:02.380884+00	2026-08-19 11:41:02.380899+00	f	\N	\N	\N	26320	2026-08-19 11:41:02.380949+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	53	39	1	["Good"]
81	2026-08-20 14:56:12.821125+00	2026-08-20 14:56:12.821137+00	f	\N	\N	\N	\N	2026-08-20 14:56:12.821184+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	54	39	1	["Good"]
82	2026-08-20 14:57:03.177514+00	2026-08-20 14:57:03.177533+00	f	\N	\N	\N	\N	2026-08-20 14:57:03.177594+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	55	1	\N	["Good"]
84	2026-08-20 18:13:59.299143+00	2026-08-20 18:13:59.299159+00	f	\N	\N	\N	\N	2026-08-20 18:13:59.299216+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	57	14	2	["Good"]
85	2026-08-23 09:04:11.3612+00	2026-08-23 09:04:11.361218+00	f	\N	\N	\N	22232	2026-08-23 09:04:11.361292+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	58	22	5	["Good"]
87	2026-08-23 13:04:40.128429+00	2026-08-23 13:04:40.128446+00	f	\N	\N	71305	21223	2026-08-23 13:04:40.128499+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	60	5	2	["Display Sun burning, 30% display health"]
83	2026-08-20 14:59:20.905642+00	2026-08-20 14:59:20.905661+00	f	\N	\N	122945	17721	2026-08-20 14:59:20.905727+00	1400.00	9a259d21-6303-464d-97fe-23a835dfdc29	56	1	\N	["Good"]
25	2026-07-27 17:51:28.726412+00	2026-07-27 17:51:28.726449+00	f	\N	\N	12324	1702	2026-07-27 17:51:28.726647+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	10	\N	["Good"]
26	2026-07-27 17:58:10.193191+00	2026-07-27 17:58:10.19326+00	f	\N	\N	79082	20112	2026-07-27 17:58:10.193568+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	41	\N	["Good"]
27	2026-07-27 18:00:10.796484+00	2026-07-27 18:00:10.796508+00	f	\N	\N	\N	\N	2026-07-27 18:00:10.79658+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	14	\N	["Good"]
72	2026-08-17 11:30:23.265772+00	2026-08-17 11:30:23.265791+00	f	\N	\N	\N	\N	2026-08-17 11:30:23.265916+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	17	\N	["Good"]
92	2026-08-27 10:02:34.53973+00	2026-08-27 10:02:34.539775+00	t	2026-08-27 10:02:52.471987+00	\N	12	0	2026-08-27 10:02:34.539971+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	62	2	\N	["Good"]
93	2026-09-01 16:59:32.891857+00	2026-09-01 16:59:32.891869+00	f	\N	\N	22312	12105	2026-09-01 16:59:32.891917+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	64	24	1	["Good"]
94	2026-09-01 17:00:50.54544+00	2026-09-01 17:00:50.545456+00	f	\N	\N	\N	\N	2026-09-01 17:00:50.545518+00	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	65	17	2	["Good"]
95	2026-09-01 17:03:22.104735+00	2026-09-01 17:03:22.104751+00	f	\N	\N	\N	\N	2026-09-01 17:03:22.104815+00	1500.00	9a259d21-6303-464d-97fe-23a835dfdc29	66	17	4	["Good"]
96	2026-09-01 17:04:40.441224+00	2026-09-01 17:04:40.441235+00	f	\N	\N	\N	\N	2026-09-01 17:04:40.441276+00	1300.00	9a259d21-6303-464d-97fe-23a835dfdc29	67	4	5	["Good"]
97	2026-09-03 08:33:58.451346+00	2026-09-03 08:33:58.451363+00	f	\N	\N	50500	2400	2026-09-03 08:33:58.451427+00	350.00	9a259d21-6303-464d-97fe-23a835dfdc29	59	4	4	["Good"]
98	2026-09-03 17:01:20.736593+00	2026-09-03 17:01:20.736606+00	f	\N	\N	\N	\N	2026-09-03 17:01:20.736651+00	333.34	9a259d21-6303-464d-97fe-23a835dfdc29	69	5	\N	["Good"]
99	2026-09-03 17:02:38.524082+00	2026-09-03 17:02:38.524096+00	f	\N	\N	44768	14153	2026-09-03 17:02:38.524187+00	333.33	9a259d21-6303-464d-97fe-23a835dfdc29	69	12	2	["Good"]
100	2026-09-03 17:03:36.027542+00	2026-09-03 17:03:36.027554+00	f	\N	\N	31316	18050	2026-09-03 17:03:36.027595+00	333.33	9a259d21-6303-464d-97fe-23a835dfdc29	69	14	2	["Good"]
101	2026-09-03 17:05:28.701895+00	2026-09-03 17:05:28.701911+00	f	\N	\N	50949	26784	2026-09-03 17:05:28.70197+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	70	1	1	["Good"]
34	2026-08-02 11:52:53.542643+00	2026-08-02 11:52:53.542655+00	f	\N	\N	49720	16383	2026-08-02 11:52:53.542732+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	39	1	["Good"]
35	2026-08-02 11:55:12.097985+00	2026-08-02 11:55:12.097997+00	f	\N	P10-39-10-00	46840	16397	2026-08-02 11:55:12.098039+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	41	4	["Good"]
47	2026-08-05 06:43:57.857405+00	2026-08-05 06:43:57.857425+00	f	\N	\N	36800	16666	2026-08-05 06:43:57.857481+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	10	\N	["Good"]
63	2026-08-11 18:39:29.85388+00	2026-08-11 18:39:29.853893+00	f	\N	\N	\N	19373	2026-08-11 18:39:29.853936+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	41	5	["Good"]
64	2026-08-11 18:40:37.14471+00	2026-08-11 18:40:37.144721+00	f	\N	\N	38493	152010	2026-08-11 18:40:37.144765+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	4	5	["Good"]
66	2026-08-12 07:07:21.783232+00	2026-08-12 07:07:21.783256+00	f	\N	\N	44166	13120	2026-08-12 07:07:21.783317+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	14	2	["Good"]
73	2026-08-17 11:30:55.584681+00	2026-08-17 11:30:55.584693+00	f	\N	\N	\N	\N	2026-08-17 11:30:55.584735+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	1	\N	["Good"]
75	2026-08-18 11:17:18.160294+00	2026-08-18 11:17:18.160306+00	f	\N	\N	32223	17116	2026-08-18 11:17:18.160361+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	1	1	["Good"]
89	2026-08-25 07:07:06.838529+00	2026-08-25 07:07:06.838543+00	f	\N	341-34J0	71964	19305	2026-08-25 07:07:06.838606+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	10	2	["Good"]
90	2026-08-26 15:09:38.424268+00	2026-08-26 15:09:38.424282+00	f	\N	\N	17247	8221	2026-08-26 15:09:38.424331+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	1	\N	["Good"]
91	2026-08-27 09:49:55.282414+00	2026-08-27 09:49:55.282434+00	f	\N	\N	32285	15293	2026-08-27 09:49:55.28253+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	10	2	["Good"]
102	2026-09-03 17:06:29.863556+00	2026-09-03 17:06:29.86358+00	f	\N	\N	39452	18137	2026-09-03 17:06:29.863672+00	60.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	5	2	["Good"]
\.


--
-- Data for Name: invoices_invoicepayment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices_invoicepayment (id, created_at, updated_at, is_deleted, deleted_at, amount, payment_method, payment_date, note, created_by_id, invoice_id) FROM stdin;
1	2026-07-23 12:58:59.744976+00	2026-07-23 12:58:59.745001+00	f	\N	400.00	CASH	2026-07-23 12:58:59.744024+00		9a259d21-6303-464d-97fe-23a835dfdc29	1
2	2026-07-23 13:01:54.715916+00	2026-07-23 13:01:54.715928+00	f	\N	500.00	CASH	2026-07-23 13:01:54.715459+00		9a259d21-6303-464d-97fe-23a835dfdc29	2
3	2026-07-24 05:49:12.145509+00	2026-07-24 05:49:12.145531+00	f	\N	400.00	CASH	2026-07-24 05:49:12.144415+00		9a259d21-6303-464d-97fe-23a835dfdc29	4
4	2026-07-25 15:08:48.887359+00	2026-07-25 15:08:48.887372+00	f	\N	400.00	CASH	2026-07-25 15:08:48.886386+00		9a259d21-6303-464d-97fe-23a835dfdc29	5
5	2026-07-26 14:10:58.633982+00	2026-07-26 14:10:58.634004+00	f	\N	400.00	CASH	2026-07-26 14:10:58.633142+00		9a259d21-6303-464d-97fe-23a835dfdc29	6
6	2026-07-27 11:18:44.172951+00	2026-07-27 11:18:44.172964+00	f	\N	400.00	CASH	2026-07-27 11:18:44.172429+00		9a259d21-6303-464d-97fe-23a835dfdc29	3
7	2026-07-27 13:49:13.868059+00	2026-07-27 13:49:13.868091+00	f	\N	600.00	CASH	2026-07-27 13:49:13.866945+00	Due 400tk, Display change + meter repair for picker problem	9a259d21-6303-464d-97fe-23a835dfdc29	8
8	2026-07-27 13:52:41.66419+00	2026-07-27 13:52:41.66421+00	f	\N	1800.00	CASH	2026-07-27 13:52:41.663618+00		9a259d21-6303-464d-97fe-23a835dfdc29	12
9	2026-07-27 13:57:55.680151+00	2026-07-27 13:57:55.680194+00	f	\N	1000.00	CASH	2026-07-27 13:57:55.679437+00		9a259d21-6303-464d-97fe-23a835dfdc29	13
10	2026-07-27 15:04:52.13033+00	2026-07-27 15:04:52.130372+00	f	\N	400.00	CASH	2026-07-27 15:04:52.129612+00		9a259d21-6303-464d-97fe-23a835dfdc29	10
11	2026-07-28 15:28:14.697049+00	2026-07-28 15:28:14.697061+00	f	\N	1500.00	CASH	2026-07-28 15:28:14.696697+00		9a259d21-6303-464d-97fe-23a835dfdc29	19
12	2026-07-30 07:06:00.995672+00	2026-07-30 07:06:00.995686+00	f	\N	400.00	CASH	2026-07-30 07:06:00.99524+00		9a259d21-6303-464d-97fe-23a835dfdc29	20
13	2026-07-30 10:16:34.791825+00	2026-07-30 10:16:34.791852+00	f	\N	400.00	CASH	2026-07-30 10:16:34.791222+00		9a259d21-6303-464d-97fe-23a835dfdc29	21
14	2026-07-31 08:34:55.887034+00	2026-07-31 08:34:55.887047+00	f	\N	1500.00	CASH	2026-07-31 08:34:55.88658+00		9a259d21-6303-464d-97fe-23a835dfdc29	22
15	2026-07-31 14:31:10.719715+00	2026-07-31 14:31:10.719728+00	f	\N	400.00	CASH	2026-07-31 14:31:10.719359+00		9a259d21-6303-464d-97fe-23a835dfdc29	11
16	2026-08-02 16:17:42.418601+00	2026-08-02 16:17:42.418613+00	f	\N	2100.00	CASH	2026-08-02 16:17:42.418245+00		9a259d21-6303-464d-97fe-23a835dfdc29	9
17	2026-08-02 16:18:12.98641+00	2026-08-02 16:18:12.98644+00	f	\N	800.00	BKASH	2026-08-02 16:18:12.986119+00		9a259d21-6303-464d-97fe-23a835dfdc29	23
18	2026-08-03 10:40:19.172025+00	2026-08-03 10:40:19.172038+00	f	\N	700.00	CASH	2026-08-03 10:40:19.171652+00		9a259d21-6303-464d-97fe-23a835dfdc29	24
19	2026-08-03 14:27:24.966635+00	2026-08-03 14:27:24.966649+00	f	\N	400.00	CASH	2026-08-03 14:27:24.966079+00		9a259d21-6303-464d-97fe-23a835dfdc29	25
20	2026-08-04 07:49:06.461874+00	2026-08-04 07:49:06.461887+00	f	\N	400.00	CASH	2026-08-04 07:49:06.461431+00		9a259d21-6303-464d-97fe-23a835dfdc29	27
21	2026-08-05 06:37:29.441177+00	2026-08-05 06:37:29.441189+00	f	\N	800.00	CASH	2026-08-05 06:37:29.440829+00		9a259d21-6303-464d-97fe-23a835dfdc29	26
22	2026-08-05 15:52:33.340543+00	2026-08-05 15:52:33.34056+00	f	\N	400.00	CASH	2026-08-05 15:52:33.340067+00		9a259d21-6303-464d-97fe-23a835dfdc29	29
23	2026-08-05 16:41:43.803241+00	2026-08-05 16:41:43.803257+00	f	\N	400.00	CASH	2026-08-05 16:41:43.802756+00		9a259d21-6303-464d-97fe-23a835dfdc29	28
24	2026-08-06 11:07:07.518331+00	2026-08-06 11:07:07.518342+00	f	\N	400.00	CASH	2026-08-06 11:07:07.517921+00		9a259d21-6303-464d-97fe-23a835dfdc29	31
25	2026-08-06 11:08:20.302935+00	2026-08-06 11:08:20.302947+00	f	\N	400.00	CASH	2026-08-06 11:08:20.302634+00		9a259d21-6303-464d-97fe-23a835dfdc29	32
26	2026-08-06 17:40:46.429381+00	2026-08-06 17:40:46.429394+00	f	\N	400.00	CASH	2026-08-06 17:40:46.428962+00		9a259d21-6303-464d-97fe-23a835dfdc29	33
27	2026-08-06 17:43:50.570272+00	2026-08-06 17:43:50.570283+00	f	\N	500.00	CASH	2026-08-06 17:43:50.569886+00		9a259d21-6303-464d-97fe-23a835dfdc29	34
28	2026-08-06 17:55:27.178489+00	2026-08-06 17:55:27.178502+00	f	\N	1000.00	CASH	2026-08-06 17:55:27.178163+00		9a259d21-6303-464d-97fe-23a835dfdc29	35
29	2026-08-08 04:58:25.742207+00	2026-08-08 04:58:25.74222+00	f	\N	2800.00	CASH	2026-08-08 04:58:25.741784+00		9a259d21-6303-464d-97fe-23a835dfdc29	30
30	2026-08-08 05:26:58.250171+00	2026-08-08 05:26:58.250188+00	f	\N	300.00	CASH	2026-08-08 05:26:58.249751+00		9a259d21-6303-464d-97fe-23a835dfdc29	15
31	2026-08-08 11:42:51.212994+00	2026-08-08 11:42:51.213008+00	f	\N	900.00	CASH	2026-08-08 11:42:51.212569+00		9a259d21-6303-464d-97fe-23a835dfdc29	36
32	2026-08-08 15:43:58.398543+00	2026-08-08 15:43:58.398564+00	f	\N	400.00	CASH	2026-08-08 15:43:58.397888+00		9a259d21-6303-464d-97fe-23a835dfdc29	37
33	2026-08-09 15:29:42.434904+00	2026-08-09 15:29:42.434917+00	f	\N	1500.00	CASH	2026-08-09 15:29:42.434453+00		9a259d21-6303-464d-97fe-23a835dfdc29	14
34	2026-08-09 15:30:31.592944+00	2026-08-09 15:30:31.592956+00	f	\N	400.00	CASH	2026-08-09 15:30:31.592679+00		9a259d21-6303-464d-97fe-23a835dfdc29	38
35	2026-08-10 08:58:31.274762+00	2026-08-10 08:58:31.274777+00	f	\N	440.00	CASH	2026-08-10 08:58:31.274241+00		9a259d21-6303-464d-97fe-23a835dfdc29	39
36	2026-08-10 08:59:40.603306+00	2026-08-10 08:59:40.603317+00	f	\N	470.00	CASH	2026-08-10 08:59:40.603004+00		9a259d21-6303-464d-97fe-23a835dfdc29	40
37	2026-08-12 15:06:09.196309+00	2026-08-12 15:06:09.196326+00	f	\N	1800.00	CASH	2026-08-12 15:06:09.1958+00		9a259d21-6303-464d-97fe-23a835dfdc29	42
38	2026-08-12 15:11:34.354235+00	2026-08-12 15:11:34.354247+00	f	\N	400.00	CASH	2026-08-12 15:11:34.353888+00		9a259d21-6303-464d-97fe-23a835dfdc29	44
39	2026-08-13 10:58:15.202269+00	2026-08-13 10:58:15.202287+00	f	\N	1800.00	CASH	2026-08-13 10:58:15.20174+00	WS5G-001	9a259d21-6303-464d-97fe-23a835dfdc29	46
40	2026-08-13 10:58:51.452061+00	2026-08-13 10:58:51.452075+00	f	\N	300.00	CASH	2026-08-13 10:58:51.451756+00		9a259d21-6303-464d-97fe-23a835dfdc29	45
41	2026-08-13 12:23:23.994847+00	2026-08-13 12:23:23.994863+00	f	\N	400.00	CASH	2026-08-13 12:23:23.994325+00		9a259d21-6303-464d-97fe-23a835dfdc29	43
42	2026-08-13 12:23:41.260319+00	2026-08-13 12:23:41.260333+00	f	\N	400.00	CASH	2026-08-13 12:23:41.259963+00		9a259d21-6303-464d-97fe-23a835dfdc29	47
43	2026-08-17 11:32:02.879546+00	2026-08-17 11:32:02.879561+00	f	\N	400.00	CASH	2026-08-17 11:32:02.879137+00		9a259d21-6303-464d-97fe-23a835dfdc29	49
44	2026-08-17 21:10:48.490246+00	2026-08-17 21:10:48.490258+00	f	\N	1400.00	CASH	2026-08-17 21:10:48.489881+00		9a259d21-6303-464d-97fe-23a835dfdc29	48
45	2026-08-18 11:37:10.196118+00	2026-08-18 11:37:10.196131+00	f	\N	400.00	CASH	2026-08-18 11:37:10.19569+00		9a259d21-6303-464d-97fe-23a835dfdc29	50
46	2026-08-18 11:38:29.832645+00	2026-08-18 11:38:29.832657+00	f	\N	400.00	CASH	2026-08-18 11:38:29.832363+00		9a259d21-6303-464d-97fe-23a835dfdc29	51
47	2026-08-18 11:47:24.244857+00	2026-08-18 11:47:24.244911+00	f	\N	1000.00	CASH	2026-08-18 11:47:24.244436+00		9a259d21-6303-464d-97fe-23a835dfdc29	52
48	2026-08-19 11:41:23.207772+00	2026-08-19 11:41:23.207787+00	f	\N	400.00	CASH	2026-08-19 11:41:23.207278+00		9a259d21-6303-464d-97fe-23a835dfdc29	53
49	2026-08-20 14:56:20.717147+00	2026-08-20 14:56:20.717169+00	f	\N	400.00	CASH	2026-08-20 14:56:20.716598+00		9a259d21-6303-464d-97fe-23a835dfdc29	54
50	2026-08-20 14:57:09.016109+00	2026-08-20 14:57:09.016124+00	f	\N	400.00	CASH	2026-08-20 14:57:09.015753+00		9a259d21-6303-464d-97fe-23a835dfdc29	55
51	2026-08-20 18:14:16.51701+00	2026-08-20 18:14:16.517024+00	f	\N	400.00	CASH	2026-08-20 18:14:16.516575+00		9a259d21-6303-464d-97fe-23a835dfdc29	57
52	2026-08-23 09:04:18.217511+00	2026-08-23 09:04:18.217524+00	f	\N	400.00	CASH	2026-08-23 09:04:18.217083+00		9a259d21-6303-464d-97fe-23a835dfdc29	58
53	2026-08-23 13:04:46.107526+00	2026-08-23 13:04:46.107537+00	f	\N	400.00	CASH	2026-08-23 13:04:46.107165+00		9a259d21-6303-464d-97fe-23a835dfdc29	60
54	2026-08-23 13:05:49.909542+00	2026-08-23 13:05:49.909555+00	f	\N	1400.00	CASH	2026-08-23 13:05:49.909233+00		9a259d21-6303-464d-97fe-23a835dfdc29	56
55	2026-08-23 13:06:22.927702+00	2026-08-23 13:06:22.927713+00	f	\N	300.00	CASH	2026-08-23 13:06:22.927445+00		9a259d21-6303-464d-97fe-23a835dfdc29	59
56	2026-08-24 12:21:49.547349+00	2026-08-24 12:21:49.54736+00	f	\N	600.00	CASH	2026-08-24 12:21:49.546981+00		9a259d21-6303-464d-97fe-23a835dfdc29	52
57	2026-08-24 12:26:24.110974+00	2026-08-24 12:26:24.110986+00	f	\N	1200.00	CASH	2026-08-24 12:26:24.110669+00		9a259d21-6303-464d-97fe-23a835dfdc29	61
58	2026-08-26 15:10:22.101788+00	2026-08-26 15:10:22.101801+00	f	\N	1500.00	CASH	2026-08-26 15:10:22.101356+00	Discover 18V Display replace price	9a259d21-6303-464d-97fe-23a835dfdc29	7
59	2026-08-27 10:12:52.750686+00	2026-08-27 10:12:52.750704+00	f	\N	400.00	CASH	2026-08-27 10:12:52.750165+00	Emaoin painter paid	9a259d21-6303-464d-97fe-23a835dfdc29	3
60	2026-08-29 17:14:36.018716+00	2026-08-29 17:14:36.018731+00	f	\N	1200.00	CASH	2026-08-29 17:14:36.018182+00		9a259d21-6303-464d-97fe-23a835dfdc29	63
61	2026-08-30 10:18:00.934941+00	2026-08-30 10:18:00.934954+00	f	\N	400.00	CASH	2026-08-30 10:18:00.934611+00		9a259d21-6303-464d-97fe-23a835dfdc29	45
62	2026-09-01 16:59:41.050588+00	2026-09-01 16:59:41.050603+00	f	\N	400.00	CASH	2026-09-01 16:59:41.050154+00		9a259d21-6303-464d-97fe-23a835dfdc29	64
63	2026-09-01 17:00:58.593833+00	2026-09-01 17:00:58.593847+00	f	\N	500.00	CASH	2026-09-01 17:00:58.593438+00		9a259d21-6303-464d-97fe-23a835dfdc29	65
64	2026-09-01 17:04:56.459504+00	2026-09-01 17:04:56.459518+00	f	\N	300.00	CASH	2026-09-01 17:04:56.459178+00		9a259d21-6303-464d-97fe-23a835dfdc29	67
65	2026-09-03 08:34:09.738567+00	2026-09-03 08:34:09.738579+00	f	\N	400.00	CASH	2026-09-03 08:34:09.738091+00		9a259d21-6303-464d-97fe-23a835dfdc29	59
66	2026-09-03 15:37:06.611593+00	2026-09-03 15:37:06.611605+00	f	\N	500.00	CASH	2026-09-03 15:37:06.611221+00		9a259d21-6303-464d-97fe-23a835dfdc29	68
67	2026-09-03 17:03:48.673047+00	2026-09-03 17:03:48.673065+00	f	\N	1000.00	CASH	2026-09-03 17:03:48.672567+00		9a259d21-6303-464d-97fe-23a835dfdc29	69
68	2026-09-03 17:05:38.108455+00	2026-09-03 17:05:38.108468+00	f	\N	400.00	CASH	2026-09-03 17:05:38.108138+00		9a259d21-6303-464d-97fe-23a835dfdc29	70
69	2026-09-04 16:55:03.419848+00	2026-09-04 16:55:03.419859+00	f	\N	900.00	CASH	2026-09-04 16:55:03.419486+00		9a259d21-6303-464d-97fe-23a835dfdc29	68
70	2026-09-06 12:08:01.64189+00	2026-09-06 12:08:01.641906+00	f	\N	1500.00	CASH	2026-09-06 12:08:01.641513+00		9a259d21-6303-464d-97fe-23a835dfdc29	71
71	2026-09-06 12:08:28.01729+00	2026-09-06 12:08:28.017307+00	f	\N	1500.00	CASH	2026-09-06 12:08:28.016912+00		9a259d21-6303-464d-97fe-23a835dfdc29	66
72	2026-09-06 12:10:53.067572+00	2026-09-06 12:10:53.067584+00	f	\N	3500.00	CASH	2026-09-06 12:10:53.067304+00		9a259d21-6303-464d-97fe-23a835dfdc29	72
73	2026-09-06 12:11:32.733907+00	2026-09-06 12:11:32.733925+00	f	\N	400.00	CASH	2026-09-06 12:11:32.733453+00		9a259d21-6303-464d-97fe-23a835dfdc29	73
74	2026-09-11 15:22:09.167057+00	2026-09-11 15:22:09.167069+00	f	\N	1000.00	CASH	2026-09-11 15:22:09.166618+00		9a259d21-6303-464d-97fe-23a835dfdc29	67
\.


--
-- Data for Name: invoices_invoiceproductline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices_invoiceproductline (id, created_at, updated_at, is_deleted, deleted_at, quantity, price_charged, created_by_id, invoice_id, product_id, added_date) FROM stdin;
\.


--
-- Data for Name: invoices_invoiceserviceline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices_invoiceserviceline (id, created_at, updated_at, is_deleted, deleted_at, price_charged, created_by_id, invoice_id, meter_entry_id, service_id, asset_used_id, added_date, product_price, product_used_id) FROM stdin;
1	2026-07-23 12:58:50.029615+00	2026-07-23 12:58:50.029635+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	1	1	1	\N	2026-07-23	0.00	\N
2	2026-07-23 13:01:16.266996+00	2026-07-23 13:01:34.183532+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	2	2	1	\N	2026-07-23	0.00	\N
4	2026-07-24 05:49:04.245663+00	2026-07-24 05:49:04.245687+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	4	4	1	\N	2026-07-24	0.00	\N
5	2026-07-25 08:42:20.715186+00	2026-07-25 08:42:20.715206+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	5	5	1	\N	2026-07-25	0.00	\N
6	2026-07-25 08:47:05.166145+00	2026-07-25 08:47:21.549556+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	6	6	1	\N	2026-07-20	0.00	\N
7	2026-07-26 07:40:39.838251+00	2026-07-26 07:40:39.83828+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	7	1	\N	2026-07-26	0.00	\N
8	2026-07-26 09:24:26.578271+00	2026-07-26 09:24:38.907722+00	f	\N	1000.00	9a259d21-6303-464d-97fe-23a835dfdc29	8	\N	7	\N	2026-07-26	0.00	\N
9	2026-07-27 07:37:35.609272+00	2026-07-27 07:37:35.609283+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	9	8	1	\N	2026-07-27	0.00	\N
10	2026-07-27 09:38:21.471118+00	2026-07-27 09:38:21.471132+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	3	9	1	\N	2026-07-27	0.00	\N
13	2026-07-27 13:44:59.293296+00	2026-07-27 13:44:59.293311+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	10	11	1	\N	2026-07-27	0.00	\N
14	2026-07-27 13:47:13.581437+00	2026-07-27 13:47:13.581457+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	11	12	1	\N	2026-07-27	0.00	\N
15	2026-07-27 13:51:26.692965+00	2026-07-27 13:52:32.153025+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	12	\N	5	\N	2026-07-27	1300.00	5
16	2026-07-27 13:57:39.937935+00	2026-07-27 13:57:47.395159+00	f	\N	1500.00	9a259d21-6303-464d-97fe-23a835dfdc29	13	\N	8	\N	2026-07-27	0.00	\N
12	2026-07-27 13:35:24.186997+00	2026-07-27 13:35:24.187016+00	t	2026-07-27 15:04:41.853302+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	10	10	1	\N	2026-07-27	0.00	\N
18	2026-07-27 15:06:22.192984+00	2026-07-27 15:06:22.193004+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	13	1	\N	2026-07-27	0.00	\N
3	2026-07-23 13:08:23.329663+00	2026-07-27 16:21:17.7041+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	3	3	1	\N	2026-07-23	0.00	\N
21	2026-07-27 17:35:17.424977+00	2026-07-27 17:35:36.477976+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	18	1	\N	2026-05-17	0.00	\N
22	2026-07-27 17:36:07.548592+00	2026-07-27 17:36:17.448358+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	19	1	\N	2026-05-17	0.00	\N
23	2026-07-27 17:37:04.458316+00	2026-07-27 17:37:21.94815+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	20	1	\N	2026-04-24	0.00	\N
24	2026-07-27 17:37:56.185106+00	2026-07-27 17:38:14.906445+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	21	1	\N	2026-04-23	0.00	\N
26	2026-07-27 17:48:07.550692+00	2026-07-27 17:49:34.064789+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	23	1	\N	2026-04-12	0.00	\N
25	2026-07-27 17:47:24.057418+00	2026-07-27 17:49:41.709399+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	22	1	\N	2026-04-12	0.00	\N
27	2026-07-27 17:50:35.137024+00	2026-07-27 17:50:49.529776+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	24	1	\N	2026-04-05	0.00	\N
28	2026-07-27 17:51:28.742112+00	2026-07-27 17:52:24.017927+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	25	1	\N	2026-04-05	0.00	\N
29	2026-07-27 17:58:10.217426+00	2026-07-27 17:59:26.522293+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	26	1	\N	2026-03-28	0.00	\N
30	2026-07-27 18:00:10.811999+00	2026-07-27 18:00:24.857746+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	27	1	\N	2026-03-26	0.00	\N
20	2026-07-27 17:24:57.488729+00	2026-07-27 18:56:35.371379+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	17	1	\N	2026-07-27	0.00	\N
31	2026-07-28 14:31:55.064004+00	2026-07-28 14:34:12.413303+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	19	\N	2	\N	2026-07-28	1700.00	1
17	2026-07-27 15:00:25.012296+00	2026-07-28 14:40:14.845054+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	14	\N	2	\N	2026-07-27	1700.00	1
32	2026-07-28 14:32:55.10946+00	2026-07-28 15:25:14.370708+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	19	28	1	\N	2026-07-28	0.00	\N
34	2026-07-28 15:34:01.06922+00	2026-07-28 15:34:01.069229+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	3	30	1	\N	2026-07-28	0.00	\N
54	2026-08-05 06:43:57.862573+00	2026-08-05 06:44:10.198623+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	47	1	\N	2026-08-04	0.00	\N
35	2026-07-30 07:05:52.459363+00	2026-07-30 07:05:52.459373+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	20	31	1	\N	2026-07-30	0.00	\N
36	2026-07-30 09:35:37.774126+00	2026-07-30 09:35:37.774133+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	21	32	1	\N	2026-07-30	0.00	\N
37	2026-07-30 18:27:56.779191+00	2026-07-30 18:27:56.779207+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	22	\N	2	\N	2026-07-30	1000.00	1
38	2026-07-30 18:28:45.864312+00	2026-07-30 18:28:45.864324+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	22	33	1	\N	2026-07-30	0.00	\N
39	2026-08-02 11:52:53.574166+00	2026-08-02 11:52:53.574175+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	34	1	\N	2026-08-02	0.00	\N
40	2026-08-02 11:55:12.106113+00	2026-08-02 11:55:12.106122+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	35	1	\N	2026-08-02	0.00	\N
41	2026-08-02 12:51:38.705343+00	2026-08-02 12:51:38.705353+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	23	36	1	\N	2026-08-02	0.00	\N
42	2026-08-02 12:53:07.71506+00	2026-08-02 12:53:07.715071+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	23	37	1	\N	2026-08-02	0.00	\N
11	2026-07-27 11:19:28.699963+00	2026-07-28 15:37:28.771222+00	t	2026-08-02 16:16:03.415496+00	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	3	\N	3	1	2026-07-27	2000.00	17
55	2026-08-05 15:50:45.984115+00	2026-08-05 15:50:45.984124+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	28	48	1	\N	2026-08-05	0.00	\N
56	2026-08-05 15:52:26.337893+00	2026-08-05 15:52:26.337979+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	29	49	1	\N	2026-08-05	0.00	\N
43	2026-08-02 16:15:01.389424+00	2026-08-02 16:17:23.99896+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	9	\N	3	1	2026-07-27	1500.00	17
44	2026-08-03 10:37:23.1527+00	2026-08-03 10:38:41.274452+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	24	38	1	\N	2026-08-03	0.00	\N
45	2026-08-03 10:40:03.572607+00	2026-08-03 10:40:03.572615+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	24	39	1	\N	2026-08-03	0.00	\N
46	2026-08-03 14:27:15.75469+00	2026-08-03 14:27:15.754702+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	25	40	1	\N	2026-08-03	0.00	\N
47	2026-08-03 14:29:43.279354+00	2026-08-03 14:29:43.279362+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	26	41	1	\N	2026-08-03	0.00	\N
48	2026-08-04 07:35:13.327872+00	2026-08-04 07:35:13.327881+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	27	42	1	\N	2026-08-04	0.00	\N
53	2026-08-05 06:37:09.471202+00	2026-08-05 06:37:20.068735+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	26	46	1	\N	2026-08-04	0.00	\N
61	2026-08-06 11:07:01.63276+00	2026-08-06 11:07:01.632768+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	31	52	1	\N	2026-08-06	0.00	\N
58	2026-08-06 07:29:33.724483+00	2026-08-06 07:31:04.14038+00	t	2026-08-06 07:31:20.064768+00	300.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	\N	4	1	2026-08-05	1200.00	3
57	2026-08-06 07:28:48.200482+00	2026-08-06 07:30:51.764749+00	f	\N	1000.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	50	1	\N	2026-08-04	0.00	\N
50	2026-08-05 06:32:01.95806+00	2026-08-05 06:32:01.958072+00	t	2026-08-06 07:32:14.420282+00	300.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	\N	4	1	2026-08-05	1200.00	3
59	2026-08-06 07:30:32.424156+00	2026-08-06 07:31:06.596689+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	51	1	\N	2026-08-05	0.00	\N
60	2026-08-06 07:31:52.932809+00	2026-08-06 07:32:04.75293+00	f	\N	300.00	9a259d21-6303-464d-97fe-23a835dfdc29	30	\N	3	1	2026-08-05	1200.00	3
51	2026-08-05 06:34:37.320725+00	2026-08-05 06:34:37.320737+00	t	2026-08-06 07:32:20.278414+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	44	1	\N	2026-08-05	0.00	\N
49	2026-08-04 14:54:22.948848+00	2026-08-04 14:54:22.948855+00	t	2026-08-06 07:32:25.557209+00	1000.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	43	1	\N	2026-08-04	0.00	\N
52	2026-08-05 06:35:31.972886+00	2026-08-05 15:56:04.741208+00	t	2026-08-06 07:32:32.770436+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	15	45	1	\N	2026-08-05	0.00	\N
62	2026-08-06 11:08:13.93382+00	2026-08-06 11:08:13.933831+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	32	53	1	\N	2026-08-06	0.00	\N
63	2026-08-06 17:40:41.02978+00	2026-08-06 17:40:41.029793+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	33	54	1	\N	2026-08-06	0.00	\N
64	2026-08-06 17:43:23.405056+00	2026-08-06 17:43:44.636741+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	34	55	1	\N	2026-08-06	0.00	\N
67	2026-08-08 11:42:41.204608+00	2026-08-08 11:42:41.204616+00	f	\N	900.00	9a259d21-6303-464d-97fe-23a835dfdc29	36	58	1	\N	2026-08-08	0.00	\N
66	2026-08-06 17:54:58.396624+00	2026-08-06 17:54:58.396632+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	35	57	1	\N	2026-08-06	0.00	\N
65	2026-08-06 17:50:17.363116+00	2026-08-06 17:55:05.934331+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	35	56	1	\N	2026-08-06	0.00	\N
68	2026-08-08 13:58:20.952703+00	2026-08-08 13:58:20.952711+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	37	59	1	\N	2026-08-08	0.00	\N
33	2026-07-28 14:48:03.812514+00	2026-07-28 14:48:03.812524+00	t	2026-08-09 15:29:20.450653+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	14	29	1	\N	2026-07-28	0.00	\N
69	2026-08-09 15:30:25.783256+00	2026-08-09 15:30:25.783266+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	38	60	1	\N	2026-08-09	0.00	\N
70	2026-08-10 08:58:02.649609+00	2026-08-10 08:58:12.037121+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	39	61	1	\N	2026-08-10	0.00	\N
71	2026-08-10 08:59:23.617002+00	2026-08-10 08:59:23.617013+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	40	62	1	\N	2026-08-10	0.00	\N
72	2026-08-11 18:36:11.0252+00	2026-08-11 18:36:11.025212+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	42	\N	2	\N	2026-08-11	1300.00	1
73	2026-08-11 18:39:29.900681+00	2026-08-11 18:39:29.900689+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	63	1	\N	2026-08-11	0.00	\N
74	2026-08-11 18:40:37.150816+00	2026-08-11 18:40:37.150822+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	64	1	\N	2026-08-11	0.00	\N
76	2026-08-12 07:07:21.824857+00	2026-08-12 07:07:21.824869+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	66	1	\N	2026-08-12	0.00	\N
77	2026-08-12 15:11:22.933841+00	2026-08-12 15:11:22.933847+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	44	67	1	\N	2026-08-12	0.00	\N
75	2026-08-11 18:42:11.053467+00	2026-08-12 15:13:52.415113+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	43	65	1	\N	2026-08-11	0.00	\N
78	2026-08-12 15:15:24.748651+00	2026-08-12 15:15:24.748663+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	45	68	1	\N	2026-08-12	0.00	\N
79	2026-08-13 10:57:55.016621+00	2026-08-13 10:57:55.016635+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	46	\N	3	2	2026-08-13	1300.00	14
80	2026-08-13 11:00:26.289317+00	2026-08-13 11:00:26.289326+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	47	69	1	\N	2026-08-13	0.00	\N
82	2026-08-15 13:46:28.633309+00	2026-08-15 13:46:28.633318+00	f	\N	1000.00	9a259d21-6303-464d-97fe-23a835dfdc29	48	71	1	\N	2026-08-15	0.00	\N
81	2026-08-15 13:45:43.360981+00	2026-08-15 13:46:41.598557+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	48	70	1	\N	2026-08-15	0.00	\N
83	2026-08-17 11:30:23.300682+00	2026-08-17 11:30:28.455438+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	72	1	\N	2026-08-16	0.00	\N
84	2026-08-17 11:30:55.592464+00	2026-08-17 11:31:02.872381+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	73	1	\N	2026-08-15	0.00	\N
85	2026-08-17 11:31:55.523326+00	2026-08-17 11:31:55.523334+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	49	74	1	\N	2026-08-17	0.00	\N
86	2026-08-18 11:17:18.192103+00	2026-08-18 11:17:18.192113+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	75	1	\N	2026-08-18	0.00	\N
87	2026-08-18 11:37:01.748551+00	2026-08-18 11:37:01.74856+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	50	76	1	\N	2026-08-18	0.00	\N
88	2026-08-18 11:38:22.162052+00	2026-08-18 11:38:22.162063+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	51	77	1	\N	2026-08-18	0.00	\N
89	2026-08-18 11:47:13.433253+00	2026-08-18 11:47:13.433265+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	52	\N	9	\N	2026-08-18	1000.00	19
90	2026-08-18 14:18:55.658387+00	2026-08-18 14:18:55.658394+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	52	78	1	\N	2026-08-18	0.00	\N
91	2026-08-18 17:06:04.468127+00	2026-08-18 17:06:04.468137+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	45	79	1	\N	2026-08-18	0.00	\N
92	2026-08-19 11:41:02.395361+00	2026-08-19 11:41:02.395368+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	53	80	1	\N	2026-08-19	0.00	\N
93	2026-08-20 14:56:12.837138+00	2026-08-20 14:56:12.837145+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	54	81	1	\N	2026-08-20	0.00	\N
94	2026-08-20 14:57:03.187427+00	2026-08-20 14:57:03.187442+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	55	82	1	\N	2026-08-20	0.00	\N
95	2026-08-20 14:58:45.204387+00	2026-08-20 14:58:45.204407+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	56	\N	3	1	2026-08-20	1000.00	14
96	2026-08-20 14:59:20.916365+00	2026-08-20 14:59:20.916377+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	56	83	1	\N	2026-08-20	0.00	\N
97	2026-08-20 18:13:59.316308+00	2026-08-20 18:13:59.316317+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	57	84	1	\N	2026-08-20	0.00	\N
98	2026-08-23 09:04:11.374661+00	2026-08-23 09:04:11.374669+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	58	85	1	\N	2026-08-23	0.00	\N
99	2026-08-23 09:05:08.02516+00	2026-08-23 09:05:08.025168+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	59	86	1	\N	2026-08-23	0.00	\N
100	2026-08-23 13:04:40.142439+00	2026-08-23 13:04:40.142448+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	60	87	1	\N	2026-08-23	0.00	\N
101	2026-08-24 12:21:37.451242+00	2026-08-24 12:21:37.451261+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	52	88	1	\N	2026-08-24	0.00	\N
102	2026-08-24 12:26:15.957206+00	2026-08-24 12:26:15.957226+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	61	\N	4	\N	2026-08-24	700.00	14
103	2026-08-25 07:07:06.869555+00	2026-08-25 07:07:06.869564+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	89	1	\N	2026-08-25	0.00	\N
105	2026-08-26 15:09:38.437667+00	2026-08-26 15:09:38.437677+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	90	1	\N	2026-08-26	0.00	\N
104	2026-08-26 15:08:40.527978+00	2026-08-27 07:42:28.900989+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	\N	4	2	2026-08-26	1500.00	12
106	2026-08-27 09:49:56.129839+00	2026-08-27 09:49:56.129849+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	91	1	\N	2026-08-27	0.00	\N
107	2026-08-27 10:02:34.777573+00	2026-08-27 10:02:34.777586+00	t	2026-08-27 10:02:51.835629+00	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	62	92	1	\N	2026-08-27	0.00	\N
108	2026-08-29 17:14:28.512785+00	2026-08-29 17:14:28.512798+00	f	\N	1200.00	9a259d21-6303-464d-97fe-23a835dfdc29	63	\N	9	2	2026-08-29	0.00	\N
109	2026-09-01 16:59:32.909146+00	2026-09-01 16:59:32.909154+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	64	93	1	\N	2026-09-01	0.00	\N
110	2026-09-01 17:00:50.554693+00	2026-09-01 17:00:50.554709+00	f	\N	500.00	9a259d21-6303-464d-97fe-23a835dfdc29	65	94	1	\N	2026-09-01	0.00	\N
111	2026-09-01 17:03:22.133118+00	2026-09-01 17:03:27.824518+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	66	95	1	\N	2026-08-31	0.00	\N
112	2026-09-01 17:04:40.449226+00	2026-09-01 17:04:43.886732+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	67	96	1	\N	2026-08-31	0.00	\N
113	2026-09-03 08:30:51.158759+00	2026-09-03 08:30:51.158772+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	66	\N	3	2	2026-09-03	1200.00	3
114	2026-09-03 08:31:49.738368+00	2026-09-03 08:31:49.73838+00	f	\N	1200.00	9a259d21-6303-464d-97fe-23a835dfdc29	67	\N	4	\N	2026-09-03	0.00	\N
116	2026-09-03 08:33:58.526556+00	2026-09-03 08:33:58.526566+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	59	97	1	\N	2026-09-03	0.00	\N
117	2026-09-03 17:01:20.75159+00	2026-09-03 17:01:20.751599+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	69	98	1	\N	2026-09-03	0.00	\N
118	2026-09-03 17:02:38.532207+00	2026-09-03 17:02:38.532217+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	69	99	1	\N	2026-09-03	0.00	\N
119	2026-09-03 17:03:36.035699+00	2026-09-03 17:03:36.035706+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	69	100	1	\N	2026-09-03	0.00	\N
120	2026-09-03 17:05:28.711502+00	2026-09-03 17:05:28.711514+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	70	101	1	\N	2026-09-03	0.00	\N
121	2026-09-03 17:06:30.805535+00	2026-09-03 17:06:30.80555+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	7	102	1	\N	2026-09-03	0.00	\N
115	2026-09-03 08:32:39.444268+00	2026-09-04 16:54:53.038426+00	f	\N	0.00	9a259d21-6303-464d-97fe-23a835dfdc29	68	\N	4	\N	2026-09-03	1400.00	14
122	2026-09-05 11:07:51.595931+00	2026-09-05 11:07:51.595948+00	f	\N	1500.00	9a259d21-6303-464d-97fe-23a835dfdc29	71	\N	3	\N	2026-09-05	0.00	\N
123	2026-09-06 12:10:42.881362+00	2026-09-06 12:10:42.881375+00	f	\N	3500.00	9a259d21-6303-464d-97fe-23a835dfdc29	72	\N	8	\N	2026-09-06	0.00	\N
124	2026-09-06 12:11:27.204373+00	2026-09-06 12:11:27.204381+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	73	103	1	\N	2026-09-06	0.00	\N
125	2026-09-08 06:03:46.470214+00	2026-09-08 06:03:46.470226+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	74	104	1	\N	2026-09-08	0.00	\N
126	2026-09-15 10:52:00.079976+00	2026-09-15 10:52:00.079986+00	f	\N	400.00	9a259d21-6303-464d-97fe-23a835dfdc29	74	105	1	\N	2026-09-15	0.00	\N
\.


--
-- Data for Name: loans_loan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loans_loan (id, created_at, updated_at, is_deleted, deleted_at, lender_name, lender_type, loan_amount, deposit_amount, interest_amount, total_installments, installment_amount, installment_frequency, start_date, created_by_id) FROM stdin;
2	2026-07-24 14:43:05.721412+00	2026-07-24 14:43:05.721425+00	f	\N	Grameen Bank	NGO	70000.00	4400.00	7000.00	44	1850.00	WEEKLY	2023-12-17	9a259d21-6303-464d-97fe-23a835dfdc29
1	2026-07-23 10:04:02.666942+00	2026-07-27 18:42:23.42363+00	f	\N	Pridim Foundation	NGO	100000.00	0.00	12500.00	45	2500.00	WEEKLY	2026-07-02	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: loans_loaninstallmentpayment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loans_loaninstallmentpayment (id, created_at, updated_at, is_deleted, deleted_at, amount_paid, payment_date, installment_number, created_by_id, loan_id, attachment) FROM stdin;
1	2026-07-23 10:04:27.973736+00	2026-07-23 10:04:27.973763+00	f	\N	2500.00	2026-07-09	1	9a259d21-6303-464d-97fe-23a835dfdc29	1	\N
2	2026-07-23 10:05:18.642775+00	2026-07-23 10:05:18.642787+00	f	\N	2500.00	2026-07-16	2	9a259d21-6303-464d-97fe-23a835dfdc29	1	\N
4	2026-07-24 14:44:11.980585+00	2026-07-24 14:44:11.980621+00	f	\N	1850.00	2023-12-17	1	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
5	2026-07-25 15:19:05.33727+00	2026-07-25 15:19:05.337282+00	f	\N	1850.00	2023-12-24	2	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
6	2026-07-25 15:19:41.89795+00	2026-07-25 15:19:41.897963+00	f	\N	1850.00	2023-07-31	3	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
7	2026-07-25 15:20:29.608475+00	2026-07-25 15:20:29.608499+00	f	\N	1850.00	2024-01-14	4	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
9	2026-07-25 15:21:40.59303+00	2026-07-25 15:21:40.593041+00	f	\N	1850.00	2024-01-28	6	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
8	2026-07-25 15:20:59.86228+00	2026-07-25 15:20:59.86231+00	f	\N	1850.00	2024-01-21	5	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
10	2026-07-25 15:23:17.720322+00	2026-07-25 15:23:17.720334+00	f	\N	1850.00	2024-02-04	7	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
11	2026-07-25 15:24:49.713776+00	2026-07-25 15:24:49.713788+00	f	\N	1850.00	2024-02-11	8	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
12	2026-07-25 15:25:23.465733+00	2026-07-25 15:25:23.465748+00	f	\N	1850.00	2024-02-18	9	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
13	2026-07-25 15:25:50.852726+00	2026-07-25 15:25:50.852741+00	f	\N	1850.00	2024-02-25	10	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
14	2026-07-25 15:26:14.841476+00	2026-07-25 15:26:14.841526+00	f	\N	1850.00	2024-03-03	11	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
15	2026-07-25 15:26:33.881659+00	2026-07-25 15:26:33.881671+00	f	\N	1850.00	2024-03-10	12	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
16	2026-07-25 15:26:49.892646+00	2026-07-25 15:26:49.892667+00	f	\N	1850.00	2024-03-17	13	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
17	2026-07-25 15:28:20.686014+00	2026-07-25 15:28:20.686057+00	f	\N	1850.00	2024-03-24	14	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
18	2026-07-25 15:28:38.852384+00	2026-07-25 15:28:38.852397+00	f	\N	1850.00	2024-03-31	15	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
19	2026-07-25 15:29:45.377337+00	2026-07-25 15:29:45.377349+00	f	\N	1850.00	2024-04-07	16	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
20	2026-07-25 15:30:20.206219+00	2026-07-25 15:30:20.206231+00	f	\N	1850.00	2024-04-14	17	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
21	2026-07-25 15:32:47.934922+00	2026-07-25 15:32:47.934936+00	f	\N	1850.00	2024-04-21	18	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
22	2026-07-25 15:33:20.589146+00	2026-07-25 15:33:20.589159+00	f	\N	1850.00	2024-04-28	19	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
23	2026-07-25 15:34:13.444974+00	2026-07-25 15:34:13.444985+00	f	\N	1850.00	2024-05-05	20	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
24	2026-07-25 15:34:33.247759+00	2026-07-25 15:34:33.247775+00	f	\N	1850.00	2024-05-12	21	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
25	2026-07-25 15:34:57.839521+00	2026-07-25 15:34:57.839533+00	f	\N	1850.00	2024-05-19	22	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
26	2026-07-25 15:35:40.414692+00	2026-07-25 15:35:40.414704+00	f	\N	1850.00	2024-05-26	23	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
27	2026-07-25 15:36:06.072465+00	2026-07-25 15:36:06.072476+00	f	\N	1850.00	2024-06-02	24	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
28	2026-07-25 15:36:43.448555+00	2026-07-25 15:36:43.448567+00	f	\N	1850.00	2024-06-09	25	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
29	2026-07-25 15:41:00.980248+00	2026-07-25 15:41:00.980261+00	f	\N	1850.00	2026-07-02	26	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
30	2026-07-25 15:41:27.002909+00	2026-07-25 15:41:27.002927+00	f	\N	1850.00	2026-07-02	27	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
31	2026-07-25 15:41:49.269196+00	2026-07-25 15:41:49.269207+00	f	\N	1850.00	2026-07-02	28	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
32	2026-07-25 15:42:47.076504+00	2026-07-25 15:42:47.076517+00	f	\N	1850.00	2026-07-02	29	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
33	2026-07-25 15:42:53.517447+00	2026-07-25 15:42:53.517459+00	f	\N	1850.00	2026-07-02	30	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
34	2026-07-25 15:43:09.520952+00	2026-07-25 15:43:09.520971+00	f	\N	1850.00	2026-07-02	31	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
35	2026-07-25 15:43:29.781782+00	2026-07-25 15:43:29.781794+00	f	\N	1850.00	2026-07-02	32	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
36	2026-07-25 15:43:36.368899+00	2026-07-25 15:43:36.368919+00	f	\N	1850.00	2026-07-02	33	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
37	2026-07-25 15:43:42.052464+00	2026-07-25 15:43:42.052476+00	f	\N	1850.00	2026-07-02	34	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
38	2026-07-25 15:43:48.681191+00	2026-07-25 15:43:48.681203+00	f	\N	1850.00	2026-07-02	35	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
39	2026-07-25 15:43:54.069589+00	2026-07-25 15:43:54.069609+00	f	\N	1850.00	2026-07-02	36	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
40	2026-07-25 15:44:01.370109+00	2026-07-25 15:44:01.370137+00	f	\N	1850.00	2026-07-02	37	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
41	2026-07-25 15:44:07.171158+00	2026-07-25 15:44:07.171171+00	f	\N	1850.00	2026-07-02	38	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
42	2026-07-25 15:44:12.674196+00	2026-07-25 15:44:12.674222+00	f	\N	1850.00	2026-07-02	39	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
43	2026-07-25 15:44:19.262065+00	2026-07-25 15:44:19.262077+00	f	\N	1850.00	2026-07-02	40	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
44	2026-07-25 15:46:09.522108+00	2026-07-25 15:46:09.522123+00	f	\N	1050.00	2026-07-02	41	9a259d21-6303-464d-97fe-23a835dfdc29	2	\N
3	2026-07-23 10:04:54.459544+00	2026-08-29 16:20:34.955508+00	f	\N	2500.00	2026-07-23	3	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/23-7-26.jpg
53	2026-09-03 15:37:59.602439+00	2026-09-03 15:37:59.602459+00	f	\N	2500.00	2026-09-03	9	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/3-9-26.jpg
54	2026-09-11 15:08:51.992099+00	2026-09-11 15:08:51.992112+00	f	\N	2500.00	2026-09-10	10	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/10-09-26.jpg
55	2026-09-24 13:04:59.313752+00	2026-09-24 13:04:59.313764+00	f	\N	2500.00	2026-09-17	11	9a259d21-6303-464d-97fe-23a835dfdc29	1	
56	2026-09-24 13:05:04.622237+00	2026-09-24 13:05:04.622258+00	f	\N	2500.00	2026-09-24	12	9a259d21-6303-464d-97fe-23a835dfdc29	1	
48	2026-07-30 06:17:07.590047+00	2026-08-29 16:21:15.953956+00	f	\N	2500.00	2026-07-30	4	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/30-7-26.jpg
49	2026-08-06 06:42:07.917962+00	2026-08-29 16:21:34.747391+00	f	\N	2500.00	2026-08-06	5	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/06-8-26.jpg
50	2026-08-13 03:44:36.742683+00	2026-08-29 16:21:59.54945+00	f	\N	2500.00	2026-08-13	6	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/13-8-26.jpg
51	2026-08-20 06:45:38.523557+00	2026-08-29 16:22:17.552925+00	f	\N	2500.00	2026-08-20	7	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/20-8-2026.jpg
52	2026-08-27 04:54:39.111843+00	2026-08-29 16:22:36.7546+00	f	\N	2500.00	2026-08-27	8	9a259d21-6303-464d-97fe-23a835dfdc29	1	loan-installment-payments/27-8-26.jpg
\.


--
-- Data for Name: meters_meter; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.meters_meter (id, created_at, updated_at, is_deleted, deleted_at, brand, model, cc, memory_type, ic_mcu_model, sales_price, image, created_by_id, description) FROM stdin;
1	2026-07-23 09:31:41.171137+00	2026-07-23 09:31:41.171153+00	f	\N	Bajaj	Discover 5Gear	125	MCU	R5F10CMEL	400.00	meters/discoverg.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
3	2026-07-23 09:32:58.809555+00	2026-08-26 15:14:11.369365+00	f	\N	Bajaj	Discover CBS	110	MCU	R5F10CMEL	400.00	meters/discover18.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
39	2026-07-27 17:21:38.035876+00	2026-08-26 15:23:02.80259+00	f	\N	TVS	Metro Plus	110	MCU	10DGDJ	400.00	meters/metro.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
4	2026-07-23 09:33:47.643584+00	2026-08-26 15:14:40.128431+00	f	\N	Bajaj	Discover V18	110	EEPROM	93C46	400.00	meters/discover18_CHoaQan.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
33	2026-07-24 14:23:40.568105+00	2026-08-26 15:15:05.79553+00	f	\N	Bajaj	Platina	100	EEPROM	93C46	400.00	meters/pladina.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
30	2026-07-24 14:15:28.7326+00	2026-08-26 15:15:28.889781+00	f	\N	Bajaj	Pulsar	135	EEPROM	93C46	400.00	meters/pulsar135.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
6	2026-07-23 09:42:51.225612+00	2026-08-26 15:16:00.004263+00	f	\N	Bajaj	Pulsar 4F	150	EEPROM	24LC01	400.00	meters/pulsar.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
5	2026-07-23 09:42:00.877887+00	2026-08-26 15:16:26.584463+00	f	\N	Bajaj	Pulsar 8F(UG3-UG5)	150	EEPROM	24LC01	400.00	meters/pulsar_NlxRirm.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
7	2026-07-23 09:52:21.283754+00	2026-08-26 15:16:46.320784+00	f	\N	Bajaj	Pulsar ABS	150	EEPROM	24LC01	400.00	meters/pulsar-abs.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
8	2026-07-23 09:58:28.33245+00	2026-08-26 15:17:05.464373+00	f	\N	Bajaj	Pulsar Double ABS	150	EEPROM	93C46X16	400.00	meters/pulsar-abs_pkLNA9o.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
9	2026-07-23 10:11:44.47641+00	2026-08-26 15:17:25.843954+00	f	\N	Bajaj	Pulsar Single Disk Double ABS	150	EEPROM	93C46X16	400.00	meters/pulsar-abs_QrKTGzV.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
10	2026-07-23 10:14:27.989225+00	2026-08-26 15:17:44.903982+00	f	\N	Gixxer	Monotone	155	EEPROM	93C66x16	400.00	meters/monoton.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
34	2026-07-24 14:26:33.954081+00	2026-08-26 15:23:15.199787+00	f	\N	TVS	Rider	125	EEPROM	93C56	400.00	meters/rider.webp	9a259d21-6303-464d-97fe-23a835dfdc29	
41	2026-07-27 17:56:15.184899+00	2026-08-26 15:23:30.671865+00	f	\N	TVS	Stryker	125	EEPROM	93C46	400.00	meters/styker.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
26	2026-07-24 14:05:08.988028+00	2026-08-26 15:23:53.380329+00	f	\N	TVS Apache	4V	160	MCU	R5F10DPJ	400.00	meters/4vs.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
20	2026-07-23 10:36:50.521237+00	2026-08-26 15:27:10.223073+00	f	\N	Yamaha	FZX	150	EEPROM	93C66x16	1500.00	meters/fzx.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
25	2026-07-24 14:03:39.173411+00	2026-08-26 15:24:02.76711+00	f	\N	TVS Apache	4V 1st	160	MCU	R5F10DJJ	400.00	meters/4vs.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
24	2026-07-24 14:02:46.519278+00	2026-08-26 15:24:14.278736+00	f	\N	TVS Apache	4V X Connect	160	MCU	R5F10DPJ	400.00	meters/4v-x.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
21	2026-07-24 13:57:32.343716+00	2026-08-26 15:25:03.970059+00	f	\N	TVS Apache	RTR	150	EEPROM	93C46	400.00	meters/rtr150.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
22	2026-07-24 13:58:24.210326+00	2026-08-26 15:25:15.828921+00	f	\N	TVS Apache	RTR	160	EEPROM	93C46	400.00	meters/rtr160.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
16	2026-07-23 10:26:17.979234+00	2026-08-26 15:25:33.258694+00	f	\N	Yamaha	FZ V1	153	EEPROM	93C46	400.00	meters/fz-v1.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
17	2026-07-23 10:29:55.615161+00	2026-08-26 15:25:51.294809+00	f	\N	Yamaha	FZ V2	150	EEPROM	93C46	400.00	meters/fz-2.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
12	2026-07-23 10:18:23.884558+00	2026-08-26 15:18:37.508097+00	f	\N	Gixxer	SF A2	155	EEPROM	93C66x16	400.00	meters/sfs_A9jc6jj.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
23	2026-07-24 13:59:05.699367+00	2026-07-28 14:04:08.501946+00	f	\N	TVS Apache	RTR Horse	160	EEPROM	93C46	400.00	meters/rte160h_OMmEsTO.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
18	2026-07-23 10:33:33.691584+00	2026-08-26 15:26:23.559228+00	f	\N	Yamaha	FZ V3	150	EEPROM	93C46	1000.00	meters/fzv3.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
13	2026-07-23 10:19:46.862965+00	2026-08-26 15:18:51.109367+00	f	\N	Gixxer	SF A3	155	EEPROM	93C66x16	400.00	meters/sfs_LrdwssD.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
14	2026-07-23 10:20:29.289676+00	2026-08-26 15:19:16.904365+00	f	\N	Gixxer	SF A5	155	EEPROM	93C66x16	400.00	meters/sfs_ZM61ozg.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
15	2026-07-23 10:20:59.486007+00	2026-08-26 15:19:57.4862+00	f	\N	Gixxer	SF A6	155	EEPROM	93C66x16	400.00	meters/sfs_Kc7yHKO.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
29	2026-07-24 14:12:41.347943+00	2026-08-26 15:20:25.236338+00	f	\N	Hero	Hunk	150	EEPROM	24C04	400.00	meters/hunk.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
35	2026-07-24 14:34:20.557162+00	2026-08-26 15:20:55.948397+00	f	\N	Hero	Hunk 150R 2025	150	EEPROM	93C56 X 16	500.00	meters/Hero-Hunk-150R.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
31	2026-07-24 14:17:40.900379+00	2026-08-26 15:21:20.853797+00	f	\N	Hero	Ignitor	125	EEPROM	24C02	400.00	meters/ignator125.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
40	2026-07-27 17:46:29.814863+00	2026-08-26 15:21:37.620664+00	f	\N	Honda	Hornet	160	EEPROM	24C08	400.00	meters/hornet.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
28	2026-07-24 14:09:49.363733+00	2026-08-26 15:21:52.333616+00	f	\N	Honda	Livo	110	EEPROM	24LC01	400.00	meters/livo.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
36	2026-07-25 13:38:54.277425+00	2026-08-26 15:22:13.925175+00	f	\N	Honda	SP	125	MCU	R5F10DMFL	800.00	meters/sp-125fiabs.png	9a259d21-6303-464d-97fe-23a835dfdc29	Honda SP-125- XPULSE 2022 R5F10DMFL
27	2026-07-24 14:08:34.311487+00	2026-08-26 15:22:35.09486+00	f	\N	Honda	SP shine	100	EEPROM	93C66x16	400.00	meters/hpshahin.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
11	2026-07-23 10:17:22.980811+00	2026-08-26 15:18:12.224153+00	f	\N	Gixxer	SF A1	155	EEPROM	93C66x16	400.00	meters/sfs.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
32	2026-07-24 14:21:13.15345+00	2026-08-26 15:22:49.772982+00	f	\N	Honda	X-Blade	160	EEPROM	24C04	400.00	meters/xblade.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
19	2026-07-23 10:34:34.969396+00	2026-08-26 15:26:45.89678+00	f	\N	Yamaha	FZS	150	EEPROM	93C66x16	1000.00	meters/fzv3_KmxPNpC.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
2	2026-07-23 09:32:16.68033+00	2026-08-26 15:13:38.063026+00	f	\N	Bajaj	Discover 4Gear	110	MCU	R5F10CMEL	400.00	meters/discoverg.jpg	9a259d21-6303-464d-97fe-23a835dfdc29	
42	2026-08-06 17:52:23.193542+00	2026-08-26 15:20:11.086597+00	f	\N	Hero	Glamour	125	EEPROM	93C56x16	400.00	meters/glamor.png	9a259d21-6303-464d-97fe-23a835dfdc29	
43	2026-08-08 11:41:15.694078+00	2026-08-26 15:24:43.633061+00	f	\N	Honda	SP 125 FI ABS(2025)	125	EEPROM	93C66x16	1000.00	meters/sp-125fiabs_OKNCYTU.png	9a259d21-6303-464d-97fe-23a835dfdc29	
\.


--
-- Data for Name: meters_mileagecorrectiondevice; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.meters_mileagecorrectiondevice (id, created_at, updated_at, is_deleted, deleted_at, name, purchase_price, purchase_date, memory_type_support, created_by_id) FROM stdin;
1	2026-07-23 09:26:08.555171+00	2026-07-23 09:26:08.555214+00	f	\N	VVDI Prog	70000.00	2026-07-23	MCU	\N
2	2026-07-23 09:26:08.566823+00	2026-07-23 09:26:08.566834+00	f	\N	RT809F	7500.00	2026-07-23	EEPROM	\N
3	2026-07-23 09:26:08.569797+00	2026-07-23 09:26:08.569821+00	f	\N	UPA USB 1.3	7000.00	2026-07-23	EEPROM	\N
4	2026-07-23 09:26:08.573355+00	2026-07-23 09:26:08.573367+00	f	\N	TOP2013	15000.00	2026-07-23	EEPROM	\N
5	2026-07-27 13:33:03.452111+00	2026-07-27 13:33:13.369933+00	f	\N	EasyPro2025	3500.00	2025-07-29	EEPROM	\N
\.


--
-- Data for Name: notifications_notification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications_notification (id, created_at, updated_at, is_deleted, deleted_at, type, title, message, due_date, is_read, object_id, content_type_id, created_by_id) FROM stdin;
\.


--
-- Data for Name: products_product; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products_product (id, created_at, updated_at, is_deleted, deleted_at, name, sku, buy_price, sale_price, image, current_stock_quantity, created_by_id, supplier_id, description) FROM stdin;
4	2026-07-24 08:55:06.999326+00	2026-07-24 08:55:47.026045+00	f	\N	Gixxer SF Display	MEGSFDi01	412.50	1500.00	products/sfs.jpg	4	9a259d21-6303-464d-97fe-23a835dfdc29	1	
6	2026-07-24 09:22:52.148875+00	2026-07-24 09:23:27.765981+00	f	\N	Green LED 3528	MEGL3528-01	11.56	300.00	products/green.webp	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
7	2026-07-24 09:24:44.900042+00	2026-07-24 09:25:03.214525+00	f	\N	Blue LED 3528	MEBL3528-01	11.56	300.00	products/3528-4Pin-blue-1.webp	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
8	2026-07-24 09:26:34.191825+00	2026-07-24 09:26:54.981121+00	f	\N	Orange LED 3528	MEOL3528-01	11.56	300.00	products/orange.jpg	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
9	2026-07-24 09:30:45.50225+00	2026-07-24 09:32:07.874643+00	f	\N	RED LED 3528	MERL3528-01	11.56	300.00	products/red.jpg	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
10	2026-07-24 09:33:19.043611+00	2026-07-24 09:33:36.56666+00	f	\N	Yellow LED 3528	MEYL3528-01	50.56	300.00	products/yellow.avif	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
11	2026-07-24 09:36:28.160418+00	2026-07-24 09:36:52.426939+00	f	\N	Pulsar LED	MEPLED-01	11.56	300.00	products/orange_4FC4aLx.jpg	45	9a259d21-6303-464d-97fe-23a835dfdc29	1	
13	2026-07-26 08:26:36.542473+00	2026-07-26 08:30:38.672307+00	f	\N	Discover CBS Non gear display	MEDCNGdisplay-01	345.00	1000.00	products/110_wrNCxrQ.jpg	2	9a259d21-6303-464d-97fe-23a835dfdc29	1	
15	2026-07-26 09:06:09.616289+00	2026-07-26 09:07:00.052021+00	f	\N	FZ V3 Display	MEFVD-01	395.00	1500.00	products/fz-v3d.jpg	2	9a259d21-6303-464d-97fe-23a835dfdc29	1	
16	2026-07-26 09:08:02.559915+00	2026-07-26 09:08:25.616503+00	f	\N	FZ V2 Display	LFVD-01	295.00	1200.00	products/fz-2-display_3.jpg	2	9a259d21-6303-464d-97fe-23a835dfdc29	1	
5	2026-07-24 09:19:38.359009+00	2026-07-27 13:51:26.704677+00	f	\N	White LED 3528	MEWL3528-01	6.78	300.00	products/smd-3528-white.jpg	89	9a259d21-6303-464d-97fe-23a835dfdc29	1	
19	2026-08-18 11:41:37.464716+00	2026-08-18 11:47:13.445712+00	f	\N	Polarize Paper replace	LPPreplace-01	54.00	1000.00	products/polar.jpg	4	9a259d21-6303-464d-97fe-23a835dfdc29	2	
17	2026-07-26 09:18:17.398735+00	2026-08-02 16:16:03.405856+00	f	\N	Gexxer Monotone Display	MEGMD-01	395.00	1500.00	products/monoton.jpg	1	9a259d21-6303-464d-97fe-23a835dfdc29	1	
12	2026-07-26 08:22:58.293435+00	2026-08-26 15:08:40.557752+00	f	\N	Discover 110 & 125 display 2018v	MED11D2018v-01	345.00	1000.00	products/110.jpg	1	9a259d21-6303-464d-97fe-23a835dfdc29	1	
3	2026-07-24 08:48:27.615675+00	2026-09-03 08:30:51.191198+00	f	\N	RTR Display All V	MERDAV-01	312.50	1200.00	products/rtr-d.jpg	2	9a259d21-6303-464d-97fe-23a835dfdc29	1	
14	2026-07-26 08:36:13.754276+00	2026-09-03 08:32:39.454525+00	f	\N	Discover Display Grear	MEDDGrear-01	282.50	1200.00	products/gear.jpg	0	9a259d21-6303-464d-97fe-23a835dfdc29	1	
18	2026-08-09 15:37:56.478842+00	2026-08-09 15:38:34.292307+00	f	\N	SF FI ABS	MESFABS-01	2590.00	4500.00		1	9a259d21-6303-464d-97fe-23a835dfdc29	1	
1	2026-07-24 06:37:36.211011+00	2026-08-11 18:36:11.045535+00	f	\N	Pulsar Polarized Paper	PP-01	115.00	1000.00	products/pulsarug3.jpg	6	9a259d21-6303-464d-97fe-23a835dfdc29	2	
\.


--
-- Data for Name: products_productrestockevent; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products_productrestockevent (id, created_at, updated_at, is_deleted, deleted_at, quantity, unit_price, extra_costs, landed_unit_cost, total_cost, restocked_at, created_by_id, product_id) FROM stdin;
1	2026-07-24 06:38:32.960009+00	2026-07-24 06:38:32.960034+00	f	\N	10	100.00	150.00	115.00	1150.00	2026-07-24 06:38:32.960122+00	\N	1
2	2026-07-24 08:48:56.320499+00	2026-07-24 08:48:56.32051+00	f	\N	4	250.00	250.00	312.50	1250.00	2026-07-24 08:48:56.320555+00	\N	3
3	2026-07-24 08:55:47.053749+00	2026-07-24 08:55:47.053766+00	f	\N	4	350.00	250.00	412.50	1650.00	2026-07-24 08:55:47.053832+00	\N	4
4	2026-07-24 09:20:15.32176+00	2026-07-24 09:20:15.32178+00	f	\N	90	4.00	250.00	6.78	610.20	2026-07-24 09:20:15.321864+00	\N	5
5	2026-07-24 09:23:27.787178+00	2026-07-24 09:23:27.78719+00	f	\N	45	6.00	250.00	11.56	520.20	2026-07-24 09:23:27.78725+00	\N	6
6	2026-07-24 09:25:03.233254+00	2026-07-24 09:25:03.233282+00	f	\N	45	6.00	250.00	11.56	520.20	2026-07-24 09:25:03.233392+00	\N	7
7	2026-07-24 09:26:55.058899+00	2026-07-24 09:26:55.05891+00	f	\N	45	6.00	250.00	11.56	520.20	2026-07-24 09:26:55.058962+00	\N	8
8	2026-07-24 09:32:07.887516+00	2026-07-24 09:32:07.887526+00	f	\N	45	6.00	250.00	11.56	520.20	2026-07-24 09:32:07.88757+00	\N	9
9	2026-07-24 09:33:36.578181+00	2026-07-24 09:33:36.578192+00	f	\N	45	45.00	250.00	50.56	2275.20	2026-07-24 09:33:36.578235+00	\N	10
10	2026-07-24 09:36:52.438261+00	2026-07-24 09:36:52.438273+00	f	\N	45	6.00	250.00	11.56	520.20	2026-07-24 09:36:52.438325+00	\N	11
11	2026-07-26 08:24:03.121541+00	2026-07-26 08:24:03.121557+00	f	\N	2	220.00	250.00	345.00	690.00	2026-07-26 08:24:03.121671+00	\N	12
12	2026-07-26 08:30:38.695156+00	2026-07-26 08:30:38.695177+00	f	\N	2	220.00	250.00	345.00	690.00	2026-07-26 08:30:38.695461+00	\N	13
13	2026-07-26 08:36:32.855198+00	2026-07-26 08:36:32.85523+00	f	\N	4	220.00	250.00	282.50	1130.00	2026-07-26 08:36:32.8554+00	\N	14
14	2026-07-26 09:07:00.067054+00	2026-07-26 09:07:00.067072+00	f	\N	2	320.00	150.00	395.00	790.00	2026-07-26 09:07:00.067178+00	\N	15
15	2026-07-26 09:08:25.632372+00	2026-07-26 09:08:25.632392+00	f	\N	2	220.00	150.00	295.00	590.00	2026-07-26 09:08:25.632506+00	\N	16
16	2026-07-26 09:18:43.623476+00	2026-07-26 09:18:43.623492+00	f	\N	2	320.00	150.00	395.00	790.00	2026-07-26 09:18:43.623593+00	\N	17
17	2026-08-09 15:38:34.30366+00	2026-08-09 15:38:34.303672+00	f	\N	1	2500.00	90.00	2590.00	2590.00	2026-08-09 15:38:34.303717+00	\N	18
18	2026-08-18 11:42:29.645203+00	2026-08-18 11:42:29.645218+00	f	\N	5	50.00	20.00	54.00	270.00	2026-08-18 11:42:29.645268+00	\N	19
\.


--
-- Data for Name: products_purchase; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products_purchase (id, created_at, updated_at, is_deleted, deleted_at, purchase_date, shared_extra_costs, note, processed_at, created_by_id, supplier_id) FROM stdin;
\.


--
-- Data for Name: products_purchaselineitem; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products_purchaselineitem (id, created_at, updated_at, is_deleted, deleted_at, quantity, unit_price, created_by_id, product_id, purchase_id) FROM stdin;
\.


--
-- Data for Name: services_service; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.services_service (id, created_at, updated_at, is_deleted, deleted_at, name, service_price, image, description, created_by_id, category_id) FROM stdin;
4	2026-07-24 06:44:12.89272+00	2026-07-28 13:48:59.510631+00	f	\N	Display Repair	500.00	services/rtr-d.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	3
3	2026-07-24 06:43:29.803361+00	2026-07-28 14:07:03.437355+00	f	\N	Display Replace	500.00	services/110.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	3
8	2026-07-27 13:57:05.19502+00	2026-07-28 14:09:15.804568+00	f	\N	Mainboard Repair	500.00	services/mb.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	4
2	2026-07-24 06:32:49.340049+00	2026-07-28 14:09:46.056258+00	f	\N	Pulsar Polarize Paper Replace	500.00	services/polar.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	3
6	2026-07-24 06:47:28.313556+00	2026-07-28 14:10:31.602305+00	f	\N	Kilometer Freeze Repair	500.00	services/rtr4vx.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	6
5	2026-07-24 06:45:57.556612+00	2026-07-28 14:10:48.169721+00	f	\N	Light Replace	300.00	services/yellow.avif		9a259d21-6303-464d-97fe-23a835dfdc29	5
7	2026-07-26 09:23:41.28447+00	2026-07-28 14:11:04.117383+00	f	\N	Gixxer SF Main board repaire	1000.00	services/mb_czN4rIg.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	4
1	2026-07-23 12:57:29.037316+00	2026-07-28 14:11:26.117532+00	f	\N	Mileage Correction	400.00	services/code.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	1
9	2026-08-18 11:44:58.756173+00	2026-08-18 11:44:58.75619+00	f	\N	Discover Polarized paper replace	1000.00	services/polar.jpg		9a259d21-6303-464d-97fe-23a835dfdc29	3
\.


--
-- Data for Name: services_servicecategory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.services_servicecategory (id, created_at, updated_at, is_deleted, deleted_at, name, created_by_id) FROM stdin;
1	2026-07-23 10:00:22.993667+00	2026-07-23 10:00:22.993694+00	f	\N	MILEAGE_CORRECTION	9a259d21-6303-464d-97fe-23a835dfdc29
2	2026-07-23 10:00:37.263597+00	2026-07-23 10:00:37.263619+00	f	\N	METER_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
3	2026-07-23 10:00:43.997562+00	2026-07-23 10:00:43.997588+00	f	\N	DISPLAY_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
4	2026-07-23 10:00:52.514009+00	2026-07-23 10:00:52.514034+00	f	\N	MAIN_BOARD_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
5	2026-07-23 10:00:57.978912+00	2026-07-23 10:00:57.978938+00	f	\N	LIGHT_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
6	2026-07-23 10:01:02.001471+00	2026-07-23 10:01:02.001492+00	f	\N	KILOMETER_FREEZE_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
7	2026-07-23 10:01:06.592883+00	2026-07-23 10:01:06.592898+00	f	\N	POWER_PROBLEM_REPAIR	9a259d21-6303-464d-97fe-23a835dfdc29
8	2026-07-23 10:01:12.704519+00	2026-07-23 10:01:12.704541+00	f	\N	OTHERS	9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: shop_profile_shopprofile; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shop_profile_shopprofile (id, created_at, updated_at, is_deleted, deleted_at, shop_name, address, phone, invoice_footer_text, created_by_id) FROM stdin;
1	2026-07-23 09:29:23.028878+00	2026-07-25 15:56:06.253371+00	f	\N	Nurain Motorcycle Meter Service Center	228/1 Nayani Samaj, Chalkpathak, Sherpur	01581334959	Development by Wahed Nur	\N
\.


--
-- Data for Name: suppliers_supplier; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suppliers_supplier (id, created_at, updated_at, is_deleted, deleted_at, name, phone, address, note, created_by_id) FROM stdin;
1	2026-07-24 06:35:04.156578+00	2026-07-24 06:35:04.156612+00	f	\N	Meter Expert BD	01917207231	Gangni Upazila, Meherpur		9a259d21-6303-464d-97fe-23a835dfdc29
2	2026-07-24 06:35:26.840144+00	2026-07-24 06:35:26.840168+00	f	\N	Local	N/A			9a259d21-6303-464d-97fe-23a835dfdc29
\.


--
-- Data for Name: token_blacklist_blacklistedtoken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.token_blacklist_blacklistedtoken (id, blacklisted_at, token_id) FROM stdin;
1	2026-07-23 10:29:55.507754+00	1
2	2026-07-24 05:46:31.652032+00	3
4	2026-07-24 06:47:28.034939+00	6
5	2026-07-24 09:03:26.807675+00	8
6	2026-07-24 13:56:19.786388+00	10
8	2026-07-24 15:42:40.275124+00	12
9	2026-07-25 03:43:51.77331+00	15
10	2026-07-25 11:59:44.652214+00	17
13	2026-07-25 13:33:26.149799+00	19
14	2026-07-25 15:55:18.998537+00	23
15	2026-07-26 07:34:13.302971+00	25
16	2026-07-26 09:37:55.901235+00	27
17	2026-07-27 04:07:02.10108+00	32
18	2026-07-27 07:35:46.360672+00	34
19	2026-07-27 09:35:34.093101+00	36
20	2026-07-27 11:18:14.113851+00	38
23	2026-07-27 13:31:00.1042+00	40
24	2026-07-27 14:58:55.658297+00	44
25	2026-07-27 16:01:44.383899+00	46
26	2026-07-27 16:24:26.978902+00	49
27	2026-07-27 17:24:57.304517+00	50
28	2026-07-28 13:48:01.332191+00	54
29	2026-07-28 15:51:20.019658+00	57
30	2026-07-28 19:35:50.733739+00	64
31	2026-07-28 23:50:40.214775+00	66
32	2026-07-29 04:50:38.905369+00	55
33	2026-07-29 08:09:03.204803+00	68
34	2026-07-30 05:50:23.294592+00	72
35	2026-07-30 06:02:16.479646+00	70
36	2026-07-30 07:02:52.214022+00	74
37	2026-07-30 07:12:12.668411+00	76
38	2026-07-30 08:20:28.823847+00	79
39	2026-07-30 09:31:37.622789+00	82
40	2026-07-30 10:38:25.268848+00	81
41	2026-07-30 10:38:25.329839+00	84
42	2026-07-30 18:24:51.466103+00	87
43	2026-07-31 05:36:10.322495+00	90
44	2026-07-31 14:30:33.028387+00	92
45	2026-08-02 09:49:02.222637+00	94
46	2026-08-02 12:51:38.524889+00	96
47	2026-08-03 07:56:45.43818+00	98
48	2026-08-03 10:25:28.007003+00	100
49	2026-08-03 14:24:38.794584+00	102
50	2026-08-03 16:12:05.329962+00	104
51	2026-08-03 18:00:39.021686+00	106
52	2026-08-04 13:38:51.597527+00	108
53	2026-08-05 06:30:29.541113+00	110
54	2026-08-05 15:49:36.86829+00	112
55	2026-08-05 16:49:52.400449+00	114
56	2026-08-06 05:03:00.887372+00	116
57	2026-08-06 06:41:31.962598+00	118
58	2026-08-06 09:58:01.209251+00	120
59	2026-08-06 17:37:49.182898+00	122
60	2026-08-08 04:46:30.2404+00	124
61	2026-08-08 07:35:53.223615+00	126
62	2026-08-08 11:30:50.898058+00	128
63	2026-08-08 13:43:04.246277+00	130
64	2026-08-08 14:52:33.337635+00	132
65	2026-08-08 16:50:39.479703+00	135
66	2026-08-09 11:38:01.491497+00	137
67	2026-08-09 18:15:46.251746+00	139
68	2026-08-10 08:51:51.71894+00	141
69	2026-08-11 18:26:39.339409+00	143
70	2026-08-12 05:47:20.289751+00	145
71	2026-08-12 07:10:09.526169+00	147
72	2026-08-13 03:20:02.216561+00	149
73	2026-08-13 07:17:53.548275+00	151
74	2026-08-13 12:21:53.46108+00	153
75	2026-08-13 17:12:05.856576+00	155
76	2026-08-14 09:13:15.710147+00	157
77	2026-08-14 18:12:59.394743+00	159
78	2026-08-17 11:28:35.464597+00	161
79	2026-08-17 21:09:10.308784+00	163
80	2026-08-18 11:16:00.307074+00	165
81	2026-08-18 14:16:48.791215+00	167
82	2026-08-18 17:04:49.429153+00	170
83	2026-08-19 11:21:13.385832+00	172
84	2026-08-20 06:44:04.247089+00	174
85	2026-08-20 14:52:23.08258+00	176
86	2026-08-20 18:10:38.806361+00	178
87	2026-08-23 09:02:40.732544+00	180
88	2026-08-23 13:01:30.352617+00	183
89	2026-08-23 15:13:51.08463+00	185
90	2026-08-23 15:37:41.667215+00	168
91	2026-08-23 17:05:49.549146+00	187
92	2026-08-23 17:23:07.356301+00	190
93	2026-08-23 18:03:55.342791+00	197
94	2026-08-23 19:18:40.485294+00	201
95	2026-08-24 12:19:52.503079+00	203
96	2026-08-25 07:04:38.452972+00	205
97	2026-08-26 15:07:29.215291+00	207
98	2026-08-27 04:21:11.624806+00	209
99	2026-08-27 06:51:48.225537+00	211
100	2026-08-27 07:04:43.27491+00	200
103	2026-08-27 09:48:22.200423+00	213
104	2026-08-28 10:08:13.126453+00	218
105	2026-08-30 10:16:56.225234+00	221
106	2026-08-30 17:58:23.385387+00	222
107	2026-09-01 08:45:33.492135+00	224
108	2026-09-01 10:12:49.490649+00	228
109	2026-09-01 16:58:18.494953+00	230
110	2026-09-03 15:30:23.150839+00	232
111	2026-09-03 16:59:22.104746+00	234
112	2026-09-04 16:53:04.753071+00	236
113	2026-09-04 19:25:25.375573+00	238
114	2026-09-06 12:07:15.590441+00	240
115	2026-09-06 19:49:48.210168+00	242
116	2026-09-08 06:02:54.068845+00	244
117	2026-09-08 07:36:58.443663+00	246
118	2026-09-13 07:40:32.057987+00	248
119	2026-09-14 19:54:32.372871+00	250
120	2026-09-15 06:23:40.672878+00	252
121	2026-09-19 10:03:29.024832+00	254
122	2026-09-21 07:08:46.923065+00	257
123	2026-09-22 08:59:49.385388+00	258
124	2026-09-24 13:03:35.655907+00	261
125	2026-10-01 03:42:24.12805+00	263
\.


--
-- Data for Name: token_blacklist_outstandingtoken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.token_blacklist_outstandingtoken (id, token, created_at, expires_at, user_id, jti) FROM stdin;
1	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQwMzc2MiwiaWF0IjoxNzg0Nzk4OTYyLCJqdGkiOiI2NjE2NWI0YzBiN2M0ZDM0YTc2MTA3NWM3MzM3ZjNhYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.NCdLSli0hpC7ljAXz9MCCduTAWLoSRFuapTNkRpiDp4	2026-07-23 09:29:22.919321+00	2026-07-30 09:29:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	66165b4c0b7c4d34a761075c7337f3aa
2	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQwNzM5NSwiaWF0IjoxNzg0ODAyNTk1LCJqdGkiOiI3ZDFkODlhMzA0YWI0ZjYyYThjOTE0YzUyNmM1ZGRlMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.y7ORPOn-C49GsY8IIQJXXhYNxwLcuqXLl6rGLWCJUwQ	2026-07-23 10:29:55.395682+00	2026-07-30 10:29:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	7d1d89a304ab4f62a8c914c526c5dde0
3	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQxNTkzMiwiaWF0IjoxNzg0ODExMTMyLCJqdGkiOiJjNWIxMTVhMjE2M2E0ZDVhYWE4OTI2ODQ1OTZjODQ0ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.rEJsJ2UAYy7lJYq4h93dPHExwgLLjjogf9KhqMo3FPc	2026-07-23 12:52:12.610149+00	2026-07-30 12:52:12+00	9a259d21-6303-464d-97fe-23a835dfdc29	c5b115a2163a4d5aaa892684596c844d
4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ3Njc5MSwiaWF0IjoxNzg0ODcxOTkxLCJqdGkiOiI3MjEwMDQ3MDEyNDQ0YWE4YmJiOWRhMWE3ZjBlNmQ4OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.eObCxKKmaC5mkcSzFNkXoiQKSomCOdCQ3Ei8dBrLn2U	2026-07-24 05:46:31.355079+00	2026-07-31 05:46:31+00	9a259d21-6303-464d-97fe-23a835dfdc29	7210047012444aa8bbb9da1a7f0e6d89
5	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ3Njc5MSwiaWF0IjoxNzg0ODcxOTkxLCJqdGkiOiJlNmQ0YzA1OWQ4ZWY0NjU1YjRjODIyMDRiYmJkMmM1NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.tluu_nHeJ31KAJMMIb1FAFokzws24MSBZHMh4GqKgek	2026-07-24 05:46:31.410225+00	2026-07-31 05:46:31+00	9a259d21-6303-464d-97fe-23a835dfdc29	e6d4c059d8ef4655b4c82204bbbd2c54
6	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ3NjgwMiwiaWF0IjoxNzg0ODcyMDAyLCJqdGkiOiJjZWM1NWI5NTAwOTQ0NGVkYWMwMmY2ZjYzMGI4YjAwNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.BsTsyENC48XKj1HLXVw7KyFTu9QVz6hxDFt_aZu4jQs	2026-07-24 05:46:42.900548+00	2026-07-31 05:46:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	cec55b95009444edac02f6f630b8b007
7	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ4MDQ0NywiaWF0IjoxNzg0ODc1NjQ3LCJqdGkiOiJlM2VmMDMxNDM5NmY0YTc3ODE0MTRkODg0YWVmZWIwNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.tyK82Ll3TMLlP2To9iZyELSllueuPG_caXDMP3IdeXU	2026-07-24 06:47:27.846767+00	2026-07-31 06:47:27+00	9a259d21-6303-464d-97fe-23a835dfdc29	e3ef0314396f4a7781414d884aefeb07
8	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ4NDU3NSwiaWF0IjoxNzg0ODc5Nzc1LCJqdGkiOiJlZmY2ZTNiODBmYmU0ZTVhOWI0YzI1NGVkY2VlY2I3MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.S6XgxJhil-1kU1wMm1PvOPsureX6PGVEmEi-srKBiD4	2026-07-24 07:56:15.855329+00	2026-07-31 07:56:15+00	9a259d21-6303-464d-97fe-23a835dfdc29	eff6e3b80fbe4e5a9b4c254edceecb72
9	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ4ODYwNiwiaWF0IjoxNzg0ODgzODA2LCJqdGkiOiJhYWVkYzM3ZTEyOWU0MDQ1YjM2MmQwMmM0Y2EwYjgxNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.sbbuu1Gdh-Sw1FRMxqdiDZfsu-1YcZfG7gw-8y9bd8c	2026-07-24 09:03:26.719005+00	2026-07-31 09:03:26+00	9a259d21-6303-464d-97fe-23a835dfdc29	aaedc37e129e4045b362d02c4ca0b817
10	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTQ5ODYxOSwiaWF0IjoxNzg0ODkzODE5LCJqdGkiOiI4ZmRlN2M2MWM0NmY0NjZmODkzMTZhYTAyMjgyMWIzOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.15iWMKl5x_cgxBYErDrRdkj9zy2wHYoIz9MmFlfcpVY	2026-07-24 11:50:19.146143+00	2026-07-31 11:50:19+00	9a259d21-6303-464d-97fe-23a835dfdc29	8fde7c61c46f466f89316aa022821b38
11	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTUwNjE3OSwiaWF0IjoxNzg0OTAxMzc5LCJqdGkiOiJmMjNjYjBhZDMxODQ0YTk4ODNkNjllMTdhMTE3MmUxNSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ayXYwNim1NFBkSP5x69IOG5etAVeDYIWNUOobvfHcWw	2026-07-24 13:56:19.30248+00	2026-07-31 13:56:19+00	9a259d21-6303-464d-97fe-23a835dfdc29	f23cb0ad31844a9883d69e17a1172e15
12	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTUwNjE4MywiaWF0IjoxNzg0OTAxMzgzLCJqdGkiOiJmNDNkZjNkNTI0MWU0ZDg5OTE0MmMyOGY5MmYwYTAyNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.IAbR5egsqve2HGH54qv5ekFGb7tqDKf6zyJuh5b4wpk	2026-07-24 13:56:23.620867+00	2026-07-31 13:56:23+00	9a259d21-6303-464d-97fe-23a835dfdc29	f43df3d5241e4d899142c28f92f0a026
13	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTUxMjU2MCwiaWF0IjoxNzg0OTA3NzYwLCJqdGkiOiI4MmQ0MjNmMTdiYmQ0ZTI3YmY5OWY3NzhiMDc2ZDRkYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.XOx75P7DBNWOIqS3iux3MQie0zdZ-i4Mx4-OkHVD3Rw	2026-07-24 15:42:40.071279+00	2026-07-31 15:42:40+00	9a259d21-6303-464d-97fe-23a835dfdc29	82d423f17bbd4e27bf99f778b076d4dc
14	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTUxMjU2MCwiaWF0IjoxNzg0OTA3NzYwLCJqdGkiOiJjOWYwMzY5ZDkwMjY0MTI3YWM2NjI5YTVjZjYwYWJlZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.AT_TTaGcdlPr4ecn9yFcOremkpZoDWehXD76uZdL3lI	2026-07-24 15:42:40.134705+00	2026-07-31 15:42:40+00	9a259d21-6303-464d-97fe-23a835dfdc29	c9f0369d90264127ac6629a5cf60abed
15	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTUxMjU2NSwiaWF0IjoxNzg0OTA3NzY1LCJqdGkiOiIxYWJhZTgxZmJmMzk0NWY3OTU1ZWM5Nzk0MmJkYjdlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.zYt9xpssVcOCqUuN_gjOvdk5qtwaUjElfRkmWmQ1wnA	2026-07-24 15:42:45.72656+00	2026-07-31 15:42:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	1abae81fbf3945f7955ec97942bdb7ec
16	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU1NTgzMSwiaWF0IjoxNzg0OTUxMDMxLCJqdGkiOiIyNDhjYTQ4OTQ0OGI0OGZmYTQ2YmFiOTUzMTczYTkyYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.aFOUxogRky38PYFcZUa9VZQtfKtG3CqqhUHO3H_WU0g	2026-07-25 03:43:51.558985+00	2026-08-01 03:43:51+00	9a259d21-6303-464d-97fe-23a835dfdc29	248ca489448b48ffa46bab953173a92a
17	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU3MzYxMCwiaWF0IjoxNzg0OTY4ODEwLCJqdGkiOiI2NmY2ZTU0MzI3MzQ0NjhlYmQ4ODg0Zjk2ZmJkYjQ5OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.wFwriSZaM662Sroz0WK0S73gZqE5XDFbFhajk_4fxOE	2026-07-25 08:40:10.286726+00	2026-08-01 08:40:10+00	9a259d21-6303-464d-97fe-23a835dfdc29	66f6e5432734468ebd8884f96fbdb499
18	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU4NTU4NCwiaWF0IjoxNzg0OTgwNzg0LCJqdGkiOiIxN2NmYjgyMDU1MWM0NWQ2OGQyYzhiZTNhZjkzOWNhYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.hFxqmLUueOBj218BRFUdqmnZYA54EqZVhSYCfslARR0	2026-07-25 11:59:44.441003+00	2026-08-01 11:59:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	17cfb820551c45d68d2c8be3af939cab
19	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU4NTYwMywiaWF0IjoxNzg0OTgwODAzLCJqdGkiOiJiNTE1ZjE4NjdkZWQ0NWFmYTNhOGJkYWY4OGNjY2E5ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.uYBVBVDwgLh0rOLwYYe9oHpSuccPOS_YkxOA22iC47E	2026-07-25 12:00:03.024891+00	2026-08-01 12:00:03+00	9a259d21-6303-464d-97fe-23a835dfdc29	b515f1867ded45afa3a8bdaf88ccca9d
20	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5MTIwNSwiaWF0IjoxNzg0OTg2NDA1LCJqdGkiOiJhODhjODZlMDEzMmM0MjU3OGM2YTE0YmVmMTg3ZGI3NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Zp7CeyGZWhSIxRwDnUqBRM5_bMl7Z9dd28NNmhbz7iE	2026-07-25 13:33:25.885601+00	2026-08-01 13:33:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	a88c86e0132c42578c6a14bef187db74
22	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5MTIwNSwiaWF0IjoxNzg0OTg2NDA1LCJqdGkiOiI0ZmUwYTFlNjcwMjQ0YjkwYmNmYzY5YjJjYjg2YjY4ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Gkl82-0YIwHYcW7OLfkIVTt8Yrim7LPtnqQyk8ygUaE	2026-07-25 13:33:25.952363+00	2026-08-01 13:33:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	4fe0a1e670244b90bcfc69b2cb86b68f
21	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5MTIwNSwiaWF0IjoxNzg0OTg2NDA1LCJqdGkiOiJjN2IzMmU1MmU2OWQ0Mjc4YThiNzIyM2M1YTIzMTAzYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.omcjTC2LmnrJ2X-xZcLN_lHugPvS_mQFhzJ8P86Odak	2026-07-25 13:33:25.850986+00	2026-08-01 13:33:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	c7b32e52e69d4278a8b7223c5a23103b
23	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5NjAyMiwiaWF0IjoxNzg0OTkxMjIyLCJqdGkiOiI0YTgwNDUxY2RkZTg0OGIxOTIwYWIxM2M1YTcyY2NjOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.YnMcjylLTMSIjqFNAjMvv8YOREiMNJS2SbYWENoeN_Q	2026-07-25 14:53:42.042726+00	2026-08-01 14:53:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	4a80451cdde848b1920ab13c5a72ccc8
24	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5OTcxOCwiaWF0IjoxNzg0OTk0OTE4LCJqdGkiOiI5MTNkOTQ1MTU1NmE0N2Y5YjQ1MTZjYWQzOWFjMTdlMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.68vWU-di48Prsj-X9lwdtBrnQhBRC1W_1KH8iNyVOCk	2026-07-25 15:55:18.898258+00	2026-08-01 15:55:18+00	9a259d21-6303-464d-97fe-23a835dfdc29	913d9451556a47f9b4516cad39ac17e1
25	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTU5OTcyNSwiaWF0IjoxNzg0OTk0OTI1LCJqdGkiOiIwYjI3YmQwODViMzY0YmNiOTg1YmQ3MDhkZGQ2ZjM3YyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.W-UlvlkqW23dhvrBVbISVYY-rS19Isa10X4mea5MWnY	2026-07-25 15:55:25.156688+00	2026-08-01 15:55:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	0b27bd085b364bcb985bd708ddd6f37c
26	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY1NjA1MywiaWF0IjoxNzg1MDUxMjUzLCJqdGkiOiI2ZWEyMzMyNTVhYzk0OTFlOGVhYjQ0NTdlNTdkNzUyYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.m0AAxC0i09l2ByYtCismADUDePDN0m_p4WTiGMgNBmc	2026-07-26 07:34:13.190937+00	2026-08-02 07:34:13+00	9a259d21-6303-464d-97fe-23a835dfdc29	6ea233255ac9491e8eab4457e57d752b
27	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY1OTczMywiaWF0IjoxNzg1MDU0OTMzLCJqdGkiOiJiYTI3NTAxNjFjZTY0MGJhOTY2MzUxNjAxMmZkZDExYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.lQx_qncWbttqsWNuTPsQFD6ToBKordHNG6qvj5D7QKc	2026-07-26 08:35:33.357995+00	2026-08-02 08:35:33+00	9a259d21-6303-464d-97fe-23a835dfdc29	ba2750161ce640ba9663516012fdd11b
28	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY2MzQ3NSwiaWF0IjoxNzg1MDU4Njc1LCJqdGkiOiI5MmM0OWNkNmUxNGI0YmZkYjdjOWIwYjliYmQ0N2RhZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.PSCCxfBS95Q8ARprRfzhLQTmNyVeCYKeDqUfYl_Fmqw	2026-07-26 09:37:55.793679+00	2026-08-02 09:37:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	92c49cd6e14b4bfdb7c9b0b9bbd47dae
29	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY2MzQ3NSwiaWF0IjoxNzg1MDU4Njc1LCJqdGkiOiIwMGE5NzE1ZTlmMDk0YzBmYTYwY2M3M2U3ODRhNTU5MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.c89-94nNwbQWPM3BJkz97cmEVprP1JDBbRDirKmT8NM	2026-07-26 09:37:55.796482+00	2026-08-02 09:37:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	00a9715e9f094c0fa60cc73e784a5590
30	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY2MzQ3NSwiaWF0IjoxNzg1MDU4Njc1LCJqdGkiOiJhNmMzMjU0MzA0ZDY0ZmYyOWRkYjZmYjY3ZmZlNjVhNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.-kpgsReO5FwtSO_h6tx51F9OuLYTmEGWDI-jxAucPG4	2026-07-26 09:37:55.798716+00	2026-08-02 09:37:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	a6c3254304d64ff29ddb6fb67ffe65a6
31	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY2MzQ3NSwiaWF0IjoxNzg1MDU4Njc1LCJqdGkiOiJhYTk5NDU3YTMzODQ0MDAyYWZkMmQyZGU5NzI0N2FiMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.PRrKEB3xJkTK81q-f4QhZGAAjJxnI4SWjTh7wSy4rnk	2026-07-26 09:37:55.802041+00	2026-08-02 09:37:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	aa99457a33844002afd2d2de97247ab1
32	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTY3OTgzMSwiaWF0IjoxNzg1MDc1MDMxLCJqdGkiOiI5ZWU1MjczOTAxMzc0YTdhYmY0NzdhYzlkY2I1ZmMwOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ixWQdgWbsd4AUjD_kiwVr0LgJiTgyXWht3uqFozHp8g	2026-07-26 14:10:31.911097+00	2026-08-02 14:10:31+00	9a259d21-6303-464d-97fe-23a835dfdc29	9ee5273901374a7abf477ac9dcb5fc08
33	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTczMDAyMSwiaWF0IjoxNzg1MTI1MjIxLCJqdGkiOiJjMjk2NDFlMzFlYzQ0ODk5OGZiZWY5MWNjZTlhZjIyMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.KTzeq2KqzqephrtOC6MPBUvnafugq3WgMA7qAG60RqI	2026-07-27 04:07:01.986722+00	2026-08-03 04:07:01+00	9a259d21-6303-464d-97fe-23a835dfdc29	c29641e31ec448998fbef91cce9af221
34	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTczMDAyOCwiaWF0IjoxNzg1MTI1MjI4LCJqdGkiOiIzNWRmYmE2NGU4N2M0MTc1OGJhYzk2ZGVjY2UxYjkxNSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Cim8J8G-W1MdsoNymHW_aZp-XO79ZUO-dNzsoZhYYWo	2026-07-27 04:07:08.321193+00	2026-08-03 04:07:08+00	9a259d21-6303-464d-97fe-23a835dfdc29	35dfba64e87c41758bac96decce1b915
35	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc0MjU0NiwiaWF0IjoxNzg1MTM3NzQ2LCJqdGkiOiI2YTVjZjhhYjk3OWQ0MTkyOGJjYjNlMGRhMmFiZDEwMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.YO3PK5BDIXe1FxKxggk6VHLDm5-TLiZUSrSZriPMWz8	2026-07-27 07:35:46.184881+00	2026-08-03 07:35:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	6a5cf8ab979d41928bcb3e0da2abd103
36	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc0MjU1MiwiaWF0IjoxNzg1MTM3NzUyLCJqdGkiOiJhNTUwZjc0NjRiNTI0MTdiODJkODU0YmI4MzNiZmU0YyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.oksmodhFLCg1eNWdHv1YFpwdxWc5_0f9XTyKRc2onYM	2026-07-27 07:35:52.370883+00	2026-08-03 07:35:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	a550f7464b52417b82d854bb833bfe4c
37	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc0OTczMywiaWF0IjoxNzg1MTQ0OTMzLCJqdGkiOiIwNTg5YmQzOGM3NmU0ZjdiODYyMTFmMTcwY2NkOGVhOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.m4id_tiBIMZFLsxKuWf4-Zqj3aYtSpmomxRsb3dBXbA	2026-07-27 09:35:33.878615+00	2026-08-03 09:35:33+00	9a259d21-6303-464d-97fe-23a835dfdc29	0589bd38c76e4f7b86211f170ccd8ea9
38	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc0OTc0MSwiaWF0IjoxNzg1MTQ0OTQxLCJqdGkiOiIyN2ViNGIxZGFlYTM0NjcxOWJjNTI1YzQzNzE2MzAzMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.8zHmFps99DPlqau7awYvxCM4ANM9pQ4J7Wpf-6qNFvg	2026-07-27 09:35:41.688182+00	2026-08-03 09:35:41+00	9a259d21-6303-464d-97fe-23a835dfdc29	27eb4b1daea346719bc525c437163032
39	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc1NTg5MywiaWF0IjoxNzg1MTUxMDkzLCJqdGkiOiJlNGY4M2VjZWVlMTk0NmNiODJjMTRiMjU0NWJkODJjYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.iYIWJxNEhipvhvH18--uEU1nkHuicabcVQ_nswIvCW4	2026-07-27 11:18:13.948674+00	2026-08-03 11:18:13+00	9a259d21-6303-464d-97fe-23a835dfdc29	e4f83eceee1946cb82c14b2545bd82cc
40	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc1NTkwMCwiaWF0IjoxNzg1MTUxMTAwLCJqdGkiOiJhY2NmZDAwNGY3Y2Q0NTBmYTI3Y2Y2MDAxZWY0YzIyMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.cA_2SP4WYYZFevKZKPSKc8k9RcmSI8Sgj6LNvvIwAFE	2026-07-27 11:18:20.903529+00	2026-08-03 11:18:20+00	9a259d21-6303-464d-97fe-23a835dfdc29	accfd004f7cd450fa27cf6001ef4c223
42	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2Mzg1OSwiaWF0IjoxNzg1MTU5MDU5LCJqdGkiOiIwNTFiODZmYTU3YjA0Nzc4OWMxOGFmM2FiOTViZWEzNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.7YWlSWJVRiQsxUbHGiH8izfvsIKNfvQRUJ7yXXPKXeM	2026-07-27 13:30:59.924696+00	2026-08-03 13:30:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	051b86fa57b047789c18af3ab95bea36
41	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2Mzg1OSwiaWF0IjoxNzg1MTU5MDU5LCJqdGkiOiIyM2NmMjQ5M2E5NzE0NDQzODRjYzI4NTdmYzY3YjhkYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.yqoLCUu1R3N8ovE3qOlwUUVYrA18JnRROQiHt-MyQZE	2026-07-27 13:30:59.915019+00	2026-08-03 13:30:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	23cf2493a971444384cc2857fc67b8db
43	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2Mzg1OSwiaWF0IjoxNzg1MTU5MDU5LCJqdGkiOiIxMGIyY2FhMWY1MWI0MDM4YTJlNzA5YTg1ODhjMzk1MSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.hTqHgJlXxE0xcRVXz-zikI_tPG9PKjfZ4Kc2wtCDDow	2026-07-27 13:30:59.928587+00	2026-08-03 13:30:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	10b2caa1f51b4038a2e709a8588c3951
44	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2NDM5NCwiaWF0IjoxNzg1MTU5NTk0LCJqdGkiOiI2Y2E3ZTI5YjE2NjA0ZjE3OGZkZGVlYzVkNWE3NzVmMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.5E26OTAQdZRDjwqqqBXY7UB-emyFMQ70xeCOuiD1Ufo	2026-07-27 13:39:54.704883+00	2026-08-03 13:39:54+00	9a259d21-6303-464d-97fe-23a835dfdc29	6ca7e29b16604f178fddeec5d5a775f1
45	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2OTEzNSwiaWF0IjoxNzg1MTY0MzM1LCJqdGkiOiI2M2NhZjVlMGFlNWI0NzY0YTczZjlhNDViNzlkMDdmMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.3C8tynK0eDrPLFqE5ilBgGLa7wB6-VrDl-hzVpGlM2I	2026-07-27 14:58:55.543448+00	2026-08-03 14:58:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	63caf5e0ae5b4764a73f9a45b79d07f1
46	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc2OTE0MiwiaWF0IjoxNzg1MTY0MzQyLCJqdGkiOiI4NWZhNjIyZTBlMzg0ZDVlYmRkYTI5ZmQzN2MwZGMzOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Wmoj8ORrLRMnLVMVdPEPgfLwCzBoy8uC4xiwmcAmflo	2026-07-27 14:59:02.095728+00	2026-08-03 14:59:02+00	9a259d21-6303-464d-97fe-23a835dfdc29	85fa622e0e384d5ebdda29fd37c0dc39
48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc3MjkwNCwiaWF0IjoxNzg1MTY4MTA0LCJqdGkiOiI2ZGFiMTFhMGM4MTk0YWU4OWRmZDYwZDJmZDZkMmQ4ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.H1NhZin9p1ixfHYqHS4-sT2fHkPJMlhuOH9JRuBEoVA	2026-07-27 16:01:44.258909+00	2026-08-03 16:01:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	6dab11a0c8194ae89dfd60d2fd6d2d8e
47	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc3MjkwNCwiaWF0IjoxNzg1MTY4MTA0LCJqdGkiOiJjMzRiNTRmMmRmOGI0MjZhOTAyZmNmMWQyNzkwYjJjMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.1PnlZa_TubDWgHa6NmQu2ehgdNs6ACNB1NbKMOwky1U	2026-07-27 16:01:44.13243+00	2026-08-03 16:01:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	c34b54f2df8b426a902fcf1d2790b2c2
49	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc3MzI1OSwiaWF0IjoxNzg1MTY4NDU5LCJqdGkiOiI5NmZiNzU5NTk3ZTI0ZWY5OWNiODJiM2E5MDEzZDRiNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.v25yjMEQymFe0Pb6ivWpyd7gCLYo43rNDQLdJ6xpZrw	2026-07-27 16:07:39.985119+00	2026-08-03 16:07:39+00	9a259d21-6303-464d-97fe-23a835dfdc29	96fb759597e24ef99cb82b3a9013d4b7
50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc3NDI3NCwiaWF0IjoxNzg1MTY5NDc0LCJqdGkiOiJiZGZmMTMxZWI1ZDE0ZjQ5OTEyNDZlYWM1YWMwN2NmZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Zshl-BV8_pyTbmyJzLpwIneuDTihAZsn6r0UkF-Ouxw	2026-07-27 16:24:34.485823+00	2026-08-03 16:24:34+00	9a259d21-6303-464d-97fe-23a835dfdc29	bdff131eb5d14f4991246eac5ac07cff
51	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc3Nzg5NywiaWF0IjoxNzg1MTczMDk3LCJqdGkiOiJmOTAwZWI3NjY0MDU0NmJmYWI4YmM4Y2NjOTRjMzBlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.bRk95_5graqxNMd9cIf6O_vyhDHfY6J8vwJv4VQ1cTw	2026-07-27 17:24:57.081602+00	2026-08-03 17:24:57+00	9a259d21-6303-464d-97fe-23a835dfdc29	f900eb76640546bfab8bc8ccc94c30ec
52	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTc4MTUzOCwiaWF0IjoxNzg1MTc2NzM4LCJqdGkiOiIwYTMzYmM4YjJhMDA0ZjE3ODRiNDkyMWE5Yzc1ZjBhYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.5D01f7932VCBBOYx1Qp0ZL0h5eeRccjiws4M-bV-qbA	2026-07-27 18:25:38.241815+00	2026-08-03 18:25:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	0a33bc8b2a004f1784b4921a9c75f0ab
53	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1MTEwNiwiaWF0IjoxNzg1MjQ2MzA2LCJqdGkiOiIwNGUyYmQ3YTc0ZDc0OWM3OWEwY2JmYTE1ODIxZTllZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.igsTp1JXO0B4uSPBc4A2P2xJWzC4TxiefbqnBxOHxW8	2026-07-28 13:45:06.897801+00	2026-08-04 13:45:06+00	9a259d21-6303-464d-97fe-23a835dfdc29	04e2bd7a74d749c79a0cbfa15821e9ee
54	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1MTIxOSwiaWF0IjoxNzg1MjQ2NDE5LCJqdGkiOiJjMDQ3M2VjN2VjYmU0ZmNiOGI3ZDdiMjY4NGRhNGYyYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.bMeZtXXufMivHoYiGOPsJqeejHTogmwwCo2ouA9aTtw	2026-07-28 13:46:59.88755+00	2026-08-04 13:46:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	c0473ec7ecbe4fcb8b7d7b2684da4f2c
55	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1MTI4NSwiaWF0IjoxNzg1MjQ2NDg1LCJqdGkiOiIzOTRhMmYxYjJjMjU0YzEzODljNGJlNjM1ZTdiMDI0NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.yka9DMjO6oxPVDW10CQmkEmYCJzh9qH6beCtd4VWfMM	2026-07-28 13:48:05.491391+00	2026-08-04 13:48:05+00	9a259d21-6303-464d-97fe-23a835dfdc29	394a2f1b2c254c1389c4be635e7b0244
56	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1NDI0MiwiaWF0IjoxNzg1MjQ5NDQyLCJqdGkiOiIwNDExZmM4NGUyNmU0NzNlOGI1NDQxM2VjZTNkNDYzMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.-Z38QBP3YGWfUhJspTX8hoTvCun3IPP0dVQlIiuMrEM	2026-07-28 14:37:22.957711+00	2026-08-04 14:37:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	0411fc84e26e473e8b54413ece3d4632
57	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1NDgxNiwiaWF0IjoxNzg1MjUwMDE2LCJqdGkiOiI5YTY3M2I0ZjQ5YmM0M2M1YWZkY2ZhNTFkMzBkMDRlMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.5HJzi1aPr0bRd-K-dBflJGk5853CycNN0CFC0Q9v5eQ	2026-07-28 14:46:56.962562+00	2026-08-04 14:46:56+00	9a259d21-6303-464d-97fe-23a835dfdc29	9a673b4f49bc43c5afdcfa51d30d04e2
58	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODY3OSwiaWF0IjoxNzg1MjUzODc5LCJqdGkiOiJkMjQ2YjY5OWI1YTM0MmM4YWU0NzI1NWU3Y2U4YzQxOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.LxFzvMqkpeZWToZaoR1cX42c6736AJazaMc7tITvTNk	2026-07-28 15:51:19.362927+00	2026-08-04 15:51:19+00	9a259d21-6303-464d-97fe-23a835dfdc29	d246b699b5a342c8ae47255e7ce8c419
59	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODY4NiwiaWF0IjoxNzg1MjUzODg2LCJqdGkiOiIyOGJmNmM3MjVhNDQ0ZmZkODg3N2E1NzgzY2FjYTg0NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.gdxFFq4fMEPyQbohwTjH0xuebBiVtWjV2DZLER4EFrU	2026-07-28 15:51:26.460724+00	2026-08-04 15:51:26+00	9a259d21-6303-464d-97fe-23a835dfdc29	28bf6c725a444ffd8877a5783caca844
60	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODY5MywiaWF0IjoxNzg1MjUzODkzLCJqdGkiOiJkYWY0ZmNiOTk2Y2E0N2VlYjUzNjc1Zjc1NTIxZGViNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.6Mnya-ld9c4hyGo3JotFiMDtTBfUcM2XvrpEghm_X2g	2026-07-28 15:51:33.853788+00	2026-08-04 15:51:33+00	9a259d21-6303-464d-97fe-23a835dfdc29	daf4fcb996ca47eeb53675f75521deb7
61	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODcwNCwiaWF0IjoxNzg1MjUzOTA0LCJqdGkiOiIyMjZlM2RjNGMyMjA0MDViODNhM2Y2OTQ3Mzg1N2RhZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.g6UzXomBPRlK7cZDS3CYaLHix9BnUWL417SNKCNSioA	2026-07-28 15:51:44.551273+00	2026-08-04 15:51:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	226e3dc4c220405b83a3f69473857dad
62	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODcwNiwiaWF0IjoxNzg1MjUzOTA2LCJqdGkiOiIyYjAyM2NhM2E4MDg0Mjc0OTgzZDQ3NDMxNGE2OGE0MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.zBkskVSygcT46LJiA1euGA92KA9cSiVon-XOf6hl1r0	2026-07-28 15:51:46.858834+00	2026-08-04 15:51:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	2b023ca3a8084274983d474314a68a40
63	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODcwOSwiaWF0IjoxNzg1MjUzOTA5LCJqdGkiOiI3NzBlN2JjODk5MTI0NDUzYjYwYjg5Yjk5OWJhMzQ0MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.91qmimKt2eiLDpnDNK0ZTXGbb7rnswdzzx9kDTw7joc	2026-07-28 15:51:49.258408+00	2026-08-04 15:51:49+00	9a259d21-6303-464d-97fe-23a835dfdc29	770e7bc899124453b60b89b999ba3442
64	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg1ODcxNSwiaWF0IjoxNzg1MjUzOTE1LCJqdGkiOiJmMDJjZjE2N2ZjMzc0ZTQ4OGRiMjkyOWJiNjQ5ZmM4OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.j6qG0URUglYj9kPH8QJ-fnwvIzhKYQ5c6x3UUYVmcK0	2026-07-28 15:51:55.356074+00	2026-08-04 15:51:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	f02cf167fc374e488db2929bb649fc89
65	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg3MjE0OSwiaWF0IjoxNzg1MjY3MzQ5LCJqdGkiOiI5MzA0ZWIzZjFhMzY0NmYxYWEzODRjZTI4MzlhMDUzOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.sLLcNuZJiWn-hg0ixQo4ypEKPC1DMkyCpK0o3fYB4as	2026-07-28 19:35:49.586938+00	2026-08-04 19:35:49+00	9a259d21-6303-464d-97fe-23a835dfdc29	9304eb3f1a3646f1aa384ce2839a0539
66	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg3MjE1NSwiaWF0IjoxNzg1MjY3MzU1LCJqdGkiOiJmYTk5MjI5NTA0YTQ0ZDYxYTI3MTFkZjJlNjg4MzQ4YSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.FuNk_HxOqXwV33bWyQMG21ZkYotKewYaSXwtyYSU2GY	2026-07-28 19:35:55.671169+00	2026-08-04 19:35:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	fa99229504a44d61a2711df2e688348a
67	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg4NzQzOSwiaWF0IjoxNzg1MjgyNjM5LCJqdGkiOiIxZDRkYzhhYWViYmQ0YTMzYTRkZTVhYWRlZDBhMDY5YSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.z7vDya2GCEQb9-hyP8geEfb-yGPilIRE5z1fcd-KmZo	2026-07-28 23:50:39.411566+00	2026-08-04 23:50:39+00	9a259d21-6303-464d-97fe-23a835dfdc29	1d4dc8aaebbd4a33a4de5aaded0a069a
68	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTg4NzQ0NywiaWF0IjoxNzg1MjgyNjQ3LCJqdGkiOiIwNWJhNDFkNzQyYWU0YzhkYTU4NGE0MWU2NzgzOWI2MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.PpZ5zrluJYgGJlFRTOWHoNmMuMgzT8129hzSZORa9Ok	2026-07-28 23:50:47.765089+00	2026-08-04 23:50:47+00	9a259d21-6303-464d-97fe-23a835dfdc29	05ba41d742ae4c8da584a41e67839b62
69	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTkwNTQzOCwiaWF0IjoxNzg1MzAwNjM4LCJqdGkiOiIyNDc4MWNmMjFlZWE0ZjU3YWVmOWUxNDFkMmI3YjkxOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.J0_wk9y64IB8NhmO3mXTY046ELdA4l2VlzQgbJAJIPg	2026-07-29 04:50:38.859918+00	2026-08-05 04:50:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	24781cf21eea4f57aef9e141d2b7b918
70	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTkwNTQ0NSwiaWF0IjoxNzg1MzAwNjQ1LCJqdGkiOiJhMzFlZjFjMDBmNTk0NjRmOTBlZGM2NDFiYzkzZjg5MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.QA96KhsiFgvcUAqUPf7kC_bz1e6FSuTy39G-TCzt8Ac	2026-07-29 04:50:45.218832+00	2026-08-05 04:50:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	a31ef1c00f59464f90edc641bc93f892
71	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTkxNzM0MiwiaWF0IjoxNzg1MzEyNTQyLCJqdGkiOiIwODE1ZmQ3Y2Q5ZWQ0OGFhOGI3N2ZlOTljNGM3YWFhZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.eX1493z3sfsMjX0XZ-AuYpjvnIdk_9vP0moakejEFY4	2026-07-29 08:09:02.47461+00	2026-08-05 08:09:02+00	9a259d21-6303-464d-97fe-23a835dfdc29	0815fd7cd9ed48aa8b77fe99c4c7aaaf
72	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTkxNzM0OCwiaWF0IjoxNzg1MzEyNTQ4LCJqdGkiOiJiNmYzMDlkZjEwNDc0YTliODRiODkwNTk2M2EyMjIxNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.UrZIBR_VELhTermZOKgLJ_BkshgyHZ5cVKNmq-L1fwk	2026-07-29 08:09:08.328259+00	2026-08-05 08:09:08+00	9a259d21-6303-464d-97fe-23a835dfdc29	b6f309df10474a9b84b8905963a22216
73	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTk5NTQyMiwiaWF0IjoxNzg1MzkwNjIyLCJqdGkiOiIxZjQ2MjJlMGQ0YjI0YjU5ODU4NjMxZjMyNTk3MWU1OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.QELLKSXvzMXiezAeHsNHuPQX2y_dFjetP7SxKy0kygo	2026-07-30 05:50:22.634328+00	2026-08-06 05:50:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	1f4622e0d4b24b59858631f325971e59
74	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTk5NTQyOCwiaWF0IjoxNzg1MzkwNjI4LCJqdGkiOiI4OWJlNzY2MWM1OGU0OTM3YWY2ZTNiNDlkZWI0Y2YxYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Xr7kS6D7oFE-IxcEJRWotI8cZcGb1tdu5NvgddWjEgA	2026-07-30 05:50:28.090975+00	2026-08-06 05:50:28+00	9a259d21-6303-464d-97fe-23a835dfdc29	89be7661c58e4937af6e3b49deb4cf1a
75	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTk5NjEzNSwiaWF0IjoxNzg1MzkxMzM1LCJqdGkiOiI3M2M2MThmODAxNDE0NTZhOTMwNmFiYzZiNTJiYmUzNSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.q7T8BlQU4U976qfpGSrrL3_zbLuEHPconWL1mQU8YmE	2026-07-30 06:02:15.717294+00	2026-08-06 06:02:15+00	9a259d21-6303-464d-97fe-23a835dfdc29	73c618f80141456a9306abc6b52bbe35
76	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTk5NjE0MiwiaWF0IjoxNzg1MzkxMzQyLCJqdGkiOiJhZmQwOWJjMTg4ZTM0MTg5OTU2NWFmZGNiNzc3NzQ1MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.fykqIipJ9VKiY7AQZ-Rewl4m_6fKXBGqHfVjbddUzmU	2026-07-30 06:02:22.79744+00	2026-08-06 06:02:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	afd09bc188e341899565afdcb7777450
77	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NTk5OTc3MSwiaWF0IjoxNzg1Mzk0OTcxLCJqdGkiOiIxNGU3OTFlYTk5NjQ0M2E3YTM5YjQ4MWIxYTI0NDFkZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.GBikKFRlTXKWMrErzCu0Om1lge753lNul4_wvNAYlow	2026-07-30 07:02:51.003877+00	2026-08-06 07:02:51+00	9a259d21-6303-464d-97fe-23a835dfdc29	14e791ea996443a7a39b481b1a2441dd
78	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwMDMzMiwiaWF0IjoxNzg1Mzk1NTMyLCJqdGkiOiI4ZTgwNGJhNDI2ZjE0OWM3YmZjMzc3ZjIzZDI4ODY4ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.F0F9ZYHjG3EL72-pnCanx0Z39oqZqCWNdo4YyCjLTnw	2026-07-30 07:12:12.655118+00	2026-08-06 07:12:12+00	9a259d21-6303-464d-97fe-23a835dfdc29	8e804ba426f149c7bfc377f23d28868d
79	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwMDM0MCwiaWF0IjoxNzg1Mzk1NTQwLCJqdGkiOiJjNjQ3OWM5NjU1NWU0ZWVhYjk2Mzc4NTZkMWI0ZjdmYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.O4eR6hR0WsLwpS42IF3QRyEQnWidzlBcYA_kKpPgRcI	2026-07-30 07:12:20.904043+00	2026-08-06 07:12:20+00	9a259d21-6303-464d-97fe-23a835dfdc29	c6479c96555e4eeab9637856d1b4f7fb
80	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwNDQyOCwiaWF0IjoxNzg1Mzk5NjI4LCJqdGkiOiJjYWZkMGU5YjYxMTA0ZjAyYTMwNjU5YjMwYWM2ZTFiYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Uhbpo1R80Boa_h7Ujz3VkEhAdn9sPY4o5ihS2iO2-9A	2026-07-30 08:20:28.74277+00	2026-08-06 08:20:28+00	9a259d21-6303-464d-97fe-23a835dfdc29	cafd0e9b61104f02a30659b30ac6e1ba
81	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwNDQzMywiaWF0IjoxNzg1Mzk5NjMzLCJqdGkiOiI0ODc4ODcyNzZjOTE0NGNkYWU3ZjU1M2JhNDJiZTFlMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.E4_uu8xacTRvZkLT0QZR0DVv-gJyGo1bFAU5lzUntls	2026-07-30 08:20:33.885413+00	2026-08-06 08:20:33+00	9a259d21-6303-464d-97fe-23a835dfdc29	487887276c9144cdae7f553ba42be1e1
82	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwNDQ2NCwiaWF0IjoxNzg1Mzk5NjY0LCJqdGkiOiI0NWIxNmE1OWY0ZDA0YjY0ODY5Njk0ZjM3M2NmZmQ3OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.PPLZTWRVu9OJbwyyDEtm8HuuA_j6x02aIWU_bXO44hM	2026-07-30 08:21:04.28639+00	2026-08-06 08:21:04+00	9a259d21-6303-464d-97fe-23a835dfdc29	45b16a59f4d04b64869694f373cffd79
83	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwODY5NywiaWF0IjoxNzg1NDAzODk3LCJqdGkiOiI5ZDhhN2RkNDdjZTQ0MTU1OGQwNDQyNTY4YjU1YjJmMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.50I0_QO4UQhoIIOGIXKPP0yYcuYyvdnv7RXM7JkvH3I	2026-07-30 09:31:37.430367+00	2026-08-06 09:31:37+00	9a259d21-6303-464d-97fe-23a835dfdc29	9d8a7dd47ce441558d0442568b55b2f3
84	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAwODcwOCwiaWF0IjoxNzg1NDAzOTA4LCJqdGkiOiJkYjViMmE0MGZjMTI0NTRlOTdiYTFmODkxYzQxZDhlMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.AzE-rFaUXpLUWN77-vG9SSL6_qCWL9IW-VRytrHbU7c	2026-07-30 09:31:48.258961+00	2026-08-06 09:31:48+00	9a259d21-6303-464d-97fe-23a835dfdc29	db5b2a40fc12454e97ba1f891c41d8e0
85	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAxMjcwNCwiaWF0IjoxNzg1NDA3OTA0LCJqdGkiOiIyMmEwOGM4ZTUxOGM0ZWM4OGE4MTI0MzJmYmVmOGViYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.i0oxzCyFdZoodP4WJ5Y2yfOM1iMPggNcki1B3Tjh150	2026-07-30 10:38:24.528202+00	2026-08-06 10:38:24+00	9a259d21-6303-464d-97fe-23a835dfdc29	22a08c8e518c4ec88a812432fbef8ebc
86	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAxMjcwNSwiaWF0IjoxNzg1NDA3OTA1LCJqdGkiOiI2YzY1YzUyNmMzMDc0YzdhOGQ0ZWE0MjA4NWZlODY5OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.nc7auh5hzua3uc5rKumWBbdBGrwJCegb29qhtdoNrjs	2026-07-30 10:38:25.317261+00	2026-08-06 10:38:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	6c65c526c3074c7a8d4ea42085fe8699
87	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAxMjcxMCwiaWF0IjoxNzg1NDA3OTEwLCJqdGkiOiJlOTIyZTlkMzBkMzg0YTI3YjYxMmNiZjg0MjBjMTc5MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.n5ocQ1DCZgDAXuCWPW-v5dh3qcdKR1J0cYi8xfw55SY	2026-07-30 10:38:30.164046+00	2026-08-06 10:38:30+00	9a259d21-6303-464d-97fe-23a835dfdc29	e922e9d30d384a27b612cbf8420c1793
88	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjAxMzM4OSwiaWF0IjoxNzg1NDA4NTg5LCJqdGkiOiIxOTBkNDc0MjgxMGI0MmM1OGNhMzdiNmY0NTc5MzI3NSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.7H9wTL0_N5iIBXtR6CXHZsv5kTPPV1uNjFjLVH__tcQ	2026-07-30 10:49:49.768841+00	2026-08-06 10:49:49+00	9a259d21-6303-464d-97fe-23a835dfdc29	190d4742810b42c58ca37b6f45793275
89	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjA0MDY5MCwiaWF0IjoxNzg1NDM1ODkwLCJqdGkiOiJhZDdmYWE4N2IyODM0MjExYjdmZWI5Yjc5OTA1MDNlOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.AXkhajy3hUbXByUyjQDVEHQMTUG06lD5bjkbqZuMet4	2026-07-30 18:24:50.653158+00	2026-08-06 18:24:50+00	9a259d21-6303-464d-97fe-23a835dfdc29	ad7faa87b2834211b7feb9b7990503e9
90	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjA0MDY5NiwiaWF0IjoxNzg1NDM1ODk2LCJqdGkiOiI3NjBlNzAzYWU0MmY0MzlhYTEwMTEyOTEzMjJhYmM3OCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.MFLs64acqxyK0HQmx9Rqoi52KLJHTt8y0GCLg6pe_3k	2026-07-30 18:24:56.102982+00	2026-08-06 18:24:56+00	9a259d21-6303-464d-97fe-23a835dfdc29	760e703ae42f439aa1011291322abc78
91	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjA4MDk2OSwiaWF0IjoxNzg1NDc2MTY5LCJqdGkiOiIwNTAxNDAyNzIzNmM0MjJhOWRhODRiOTBlMDViMjdkMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.-p8F6Pi9F6LNQTOPDQ99VAWhQGm3AhygQ1C2MeW4dt4	2026-07-31 05:36:09.532542+00	2026-08-07 05:36:09+00	9a259d21-6303-464d-97fe-23a835dfdc29	05014027236c422a9da84b90e05b27d1
92	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjA5MTY1NSwiaWF0IjoxNzg1NDg2ODU1LCJqdGkiOiIyZWQ3M2RhNGI1NWU0ODY4ODllOTgwMmU1OGYzY2I2YiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.uDABFn2lMU1YB2ruXCHJFT4TVKMJPbjZb6vmK26U91c	2026-07-31 08:34:15.197495+00	2026-08-07 08:34:15+00	9a259d21-6303-464d-97fe-23a835dfdc29	2ed73da4b55e486889e9802e58f3cb6b
93	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjExMzAzMywiaWF0IjoxNzg1NTA4MjMzLCJqdGkiOiI2YzBjOWVkODc2OWU0NGQ2ODQ3MWM4ZTQyMjQ2Y2FmZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.GhqvbmxL8R2-ZrHSbiwQaMIXwleRat4SB_NfegVSrT0	2026-07-31 14:30:33.002147+00	2026-08-07 14:30:33+00	9a259d21-6303-464d-97fe-23a835dfdc29	6c0c9ed8769e44d68471c8e42246caff
94	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjEyNDUzMSwiaWF0IjoxNzg1NTE5NzMxLCJqdGkiOiIwYjk0NTA4Yzc5YTY0NWMyOGM2ZTFkYjZlY2FlZGMxMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.JA4UcZZr1i--tlPylLPC_c_Z4Yfxth23uCNfkgbB948	2026-07-31 17:42:11.434819+00	2026-08-07 17:42:11+00	9a259d21-6303-464d-97fe-23a835dfdc29	0b94508c79a645c28c6e1db6ecaedc13
95	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjI2ODk0MSwiaWF0IjoxNzg1NjY0MTQxLCJqdGkiOiIxZjU0NDE5ZWRiYTU0NzM2OWJhMDhiY2M3MTBhZWY2NSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.mYtPb7qbr4SLFnpdPQQIOVr49C1thPHYx0JvgM0BzjM	2026-08-02 09:49:01.53416+00	2026-08-09 09:49:01+00	9a259d21-6303-464d-97fe-23a835dfdc29	1f54419edba547369ba08bcc710aef65
96	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjI3NjI3MywiaWF0IjoxNzg1NjcxNDczLCJqdGkiOiI5OWFhMTY3YzRhYWM0MTgxYjhiMzQzMDhhZDVlMzVlYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.LWwUYHUUCPjo4PocI5X8OcwSz2rsCA7q0azga1gMkY0	2026-08-02 11:51:13.617457+00	2026-08-09 11:51:13+00	9a259d21-6303-464d-97fe-23a835dfdc29	99aa167c4aac4181b8b34308ad5e35eb
97	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjI3OTg5OCwiaWF0IjoxNzg1Njc1MDk4LCJqdGkiOiJiNDg5NGNhMWNkNmM0OWI0OWU4MjUwNjRhMDJiMDY0MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.MIX3C7XXbGh4RrXWQLTOu9Q3p7lzFLf96zilioyaTFo	2026-08-02 12:51:38.493446+00	2026-08-09 12:51:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	b4894ca1cd6c49b49e825064a02b0642
98	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjI5MjA0MCwiaWF0IjoxNzg1Njg3MjQwLCJqdGkiOiI0NWIyYjY2MDE4NTM0NDgyYmNkNDJlZDIzMTkxMWMwOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.SaN1XyVguCnuKrNxXqWK_Iz2KsosTZqYfyjJN3DqSDY	2026-08-02 16:14:00.567101+00	2026-08-09 16:14:00+00	9a259d21-6303-464d-97fe-23a835dfdc29	45b2b66018534482bcd42ed231911c08
99	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM0ODYwNCwiaWF0IjoxNzg1NzQzODA0LCJqdGkiOiI2MTMyMTE4MmI5Yzc0OTgwODZjOTJiZDdmMGU3NjNlZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ycpcvWHeP_2Q2gQJia0wPRpMM0nGsuiGTsOxu9AnT04	2026-08-03 07:56:44.658722+00	2026-08-10 07:56:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	61321182b9c7498086c92bd7f0e763ed
100	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM0ODYzNiwiaWF0IjoxNzg1NzQzODM2LCJqdGkiOiJiOGUwM2I5ZTIzNTU0ZmRjOGNjNjg4ZTg4N2ExODIxZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.PYg6qI8asoBHytULdS_p3dInRWKkP-dIE28NfQtE75w	2026-08-03 07:57:16.690134+00	2026-08-10 07:57:16+00	9a259d21-6303-464d-97fe-23a835dfdc29	b8e03b9e23554fdc8cc688e887a1821f
101	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM1NzUyNywiaWF0IjoxNzg1NzUyNzI3LCJqdGkiOiJiMGVmZDliY2MwYWM0ZDYzODI3ODJlM2I0OTJkZjUxZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Z2_nEJrp7CZXNzroOoaUwRom5FkQJo8rJnB5FSz_fY4	2026-08-03 10:25:27.304437+00	2026-08-10 10:25:27+00	9a259d21-6303-464d-97fe-23a835dfdc29	b0efd9bcc0ac4d6382782e3b492df51d
102	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM1NzUzNSwiaWF0IjoxNzg1NzUyNzM1LCJqdGkiOiJhM2ExMGM2Y2RjZGM0ZDg4YmFkYTc5NGJjNTA2MWRkOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.fdquYaLQEtqW-AIc508MR7DPRs0PdUYi_74QWlXWkFI	2026-08-03 10:25:35.849845+00	2026-08-10 10:25:35+00	9a259d21-6303-464d-97fe-23a835dfdc29	a3a10c6cdcdc4d88bada794bc5061dd9
103	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM3MTg3OCwiaWF0IjoxNzg1NzY3MDc4LCJqdGkiOiIwZDI3ZThlOTA3YzU0OTU2ODhjMDU1N2EwNjE3NDU4NyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.-SExBHL-3o72jgUC6r2ghQ5AOgZlV8FqMbueABEkR-o	2026-08-03 14:24:38.081579+00	2026-08-10 14:24:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	0d27e8e907c5495688c0557a06174587
104	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM3MTg4MiwiaWF0IjoxNzg1NzY3MDgyLCJqdGkiOiIxNzViMTBiYThmMmM0MzMyOTUxNmM3NTlkZGJmNDY5MSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.FJ_rBj8HsPTlgV_dE0duWR8f952M_PBJ_wSnPaPymTA	2026-08-03 14:24:42.90512+00	2026-08-10 14:24:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	175b10ba8f2c43329516c759ddbf4691
105	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM3ODMyNCwiaWF0IjoxNzg1NzczNTI0LCJqdGkiOiJlNDJkM2VkNTE3Y2I0YjUwYmIxMjczY2U5ZjlkMGQyZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.WrAzw_EJwo9VMtCwcAaBZMPFSwVTsEvSR0gHW3vTbPk	2026-08-03 16:12:04.59832+00	2026-08-10 16:12:04+00	9a259d21-6303-464d-97fe-23a835dfdc29	e42d3ed517cb4b50bb1273ce9f9d0d2d
106	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM3ODMyOSwiaWF0IjoxNzg1NzczNTI5LCJqdGkiOiJhYWM5MmQ5OGY4ZmY0MTllOGMxNTI2MmMzMGNlNjYyNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.f5nRKB_W1CQ4l_EWSIpq9ruT0E2kD0rKFhtmKdH_VBM	2026-08-03 16:12:09.795513+00	2026-08-10 16:12:09+00	9a259d21-6303-464d-97fe-23a835dfdc29	aac92d98f8ff419e8c15262c30ce6627
107	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjM4NDgzOCwiaWF0IjoxNzg1NzgwMDM4LCJqdGkiOiIxNzFiYTE4MWVkNzY0MzczODU5ZDA5OTE4ZGQ1MmE1ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.EbtuUgh_5RLTQQRUczSLU88nFoM9aLrP0sKa2Fnw-gM	2026-08-03 18:00:38.112386+00	2026-08-10 18:00:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	171ba181ed764373859d09918dd52a5f
108	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjQzMzYyOCwiaWF0IjoxNzg1ODI4ODI4LCJqdGkiOiI5NWRiNDg3Nzk5MTg0M2E4OWY3YWIxZTY2N2M5ZjFhMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.gYoe04GpRRT2Zylg0LhVlo468d1JhFp-3bSnLuMWAts	2026-08-04 07:33:48.055005+00	2026-08-11 07:33:48+00	9a259d21-6303-464d-97fe-23a835dfdc29	95db4877991843a89f7ab1e667c9f1a3
109	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjQ1NTUzMCwiaWF0IjoxNzg1ODUwNzMwLCJqdGkiOiI0MWUwMWZkYjZiMjg0MThjODc2MTg4NDM4YmZmZGVlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.aFFpyJbZfxuu_rkCCzezuHtHvaiooRRb14hOEFKAIvA	2026-08-04 13:38:50.792216+00	2026-08-11 13:38:50+00	9a259d21-6303-464d-97fe-23a835dfdc29	41e01fdb6b28418c876188438bffdeec
110	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjQ1NjkxNSwiaWF0IjoxNzg1ODUyMTE1LCJqdGkiOiI3MDc4Mjc2ZTliM2I0NWY3YjEzZmM3NzMwZThkOTgwZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.7KIByL7QY1ljB2JhAGgQcG9_6a5lO_1mlee15Z0pMtE	2026-08-04 14:01:55.424438+00	2026-08-11 14:01:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	7078276e9b3b45f7b13fc7730e8d980f
111	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjUxNjIyOCwiaWF0IjoxNzg1OTExNDI4LCJqdGkiOiJjMTgxOWIxOGY5ZmU0NTdhYjE0MjE0YzQ3NTM5MzhjMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.UcAC78Z0ngKsemJVrs81ffJKQvcRGeQ2gmPfud26DyM	2026-08-05 06:30:28.832927+00	2026-08-12 06:30:28+00	9a259d21-6303-464d-97fe-23a835dfdc29	c1819b18f9fe457ab14214c4753938c3
112	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjUxNjI0NywiaWF0IjoxNzg1OTExNDQ3LCJqdGkiOiI5OTM4MzQzMzVjZDc0YjAyYTEzOTQ1NTNmY2M0M2MwYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.IlsTqNxAAm3f0KKTLGfh2gd7QDH1OL-qtvNntuhcXgg	2026-08-05 06:30:47.423522+00	2026-08-12 06:30:47+00	9a259d21-6303-464d-97fe-23a835dfdc29	993834335cd74b02a1394553fcc43c0b
113	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU0OTc3NiwiaWF0IjoxNzg1OTQ0OTc2LCJqdGkiOiIwMjllYTQ4YTgwNTY0OWNmYTJiNmE1YmQ3N2E5YTg3NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.hw02DWmHAu0Eq_hO3zz1npjFv4XLTXLFO8Sd8RdDl3w	2026-08-05 15:49:36.183239+00	2026-08-12 15:49:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	029ea48a805649cfa2b6a5bd77a9a876
114	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU0OTc4MSwiaWF0IjoxNzg1OTQ0OTgxLCJqdGkiOiI0YWQ0YTgxNWIzMjA0NzdkOGMzZTg1NjEzZjVlYzI3OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.wiKsgUr9_RfstOWWvZ15nzJGDxmxZasfar_o0gjkWco	2026-08-05 15:49:41.399752+00	2026-08-12 15:49:41+00	9a259d21-6303-464d-97fe-23a835dfdc29	4ad4a815b320477d8c3e85613f5ec279
115	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU1MzM5MiwiaWF0IjoxNzg1OTQ4NTkyLCJqdGkiOiIzZTE4NDZlNDIyOWE0MGZlYmMyZDk2NDRlNWJlZjRlZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.GMCa3MWWibRpj_YfIZ6a64CKW7eRCMr1qGsGeIwwalY	2026-08-05 16:49:52.343238+00	2026-08-12 16:49:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	3e1846e4229a40febc2d9644e5bef4ed
116	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU2NTkzMSwiaWF0IjoxNzg1OTYxMTMxLCJqdGkiOiJiMTA1M2RkMTVjN2Q0ZTgyODZjNWI2NTQ4MTc2YTE2NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.LmnAdaNIZQO5QcpXUICfDyApQgxqbZjUNkLXfFDaYQk	2026-08-05 20:18:51.401863+00	2026-08-12 20:18:51+00	9a259d21-6303-464d-97fe-23a835dfdc29	b1053dd15c7d4e8286c5b6548176a164
117	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU5NzM4MCwiaWF0IjoxNzg1OTkyNTgwLCJqdGkiOiIyNDc4NTRiMTUwMmY0OGRhOGFhMGQxMmZhYTVlOGFkZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.u7WG4X9VSycd0YQNQi3rMDaPGVwdmajl2dw2XgZiUZs	2026-08-06 05:03:00.202097+00	2026-08-13 05:03:00+00	9a259d21-6303-464d-97fe-23a835dfdc29	247854b1502f48da8aa0d12faa5e8ade
118	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjU5NzQwNSwiaWF0IjoxNzg1OTkyNjA1LCJqdGkiOiJmN2Q2MTYzMmYzNTM0ZDNhYTJiOTE2ZTNjZDcwMzk4ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.LzaqPiI24PGj4KMLE0d9wQzL1e6R2b2K_e4ESkMLurQ	2026-08-06 05:03:25.232506+00	2026-08-13 05:03:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	f7d61632f3534d3aa2b916e3cd70398f
119	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjYwMzI5MCwiaWF0IjoxNzg1OTk4NDkwLCJqdGkiOiJlZDU2NzhjMjM5YzY0ZWY3YmJkZTgyZDRlNWNhMzJhNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.lXWZO7zgTswREe4LA6Cu6dMfuH3gZZ1AKFM_1lMDcwM	2026-08-06 06:41:30.75641+00	2026-08-13 06:41:30+00	9a259d21-6303-464d-97fe-23a835dfdc29	ed5678c239c64ef7bbde82d4e5ca32a7
120	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjYwMzI5NiwiaWF0IjoxNzg1OTk4NDk2LCJqdGkiOiI3ZjcyOTRmMThkMzg0ZGZjOGQxZDBkODVkNjljZjBlMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.mVmCHqmxuffApXbMvIyNo0XIWfd0NQ5Fu9deVVbR7Ec	2026-08-06 06:41:36.085279+00	2026-08-13 06:41:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	7f7294f18d384dfc8d1d0d85d69cf0e0
121	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjYxNTA4MCwiaWF0IjoxNzg2MDEwMjgwLCJqdGkiOiI2N2U1MDdmYzcxYmY0YjNjOTMzMGI4ZDIwYmVmOTQ5OCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Lrawuy2oXacbPS9g36MAMHKXbWiiF3dmCqAgAJUDX0A	2026-08-06 09:58:00.463722+00	2026-08-13 09:58:00+00	9a259d21-6303-464d-97fe-23a835dfdc29	67e507fc71bf4b3c9330b8d20bef9498
122	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjYxOTAwNSwiaWF0IjoxNzg2MDE0MjA1LCJqdGkiOiI3NTdlM2VhNDkzOTY0MTM5ODUwNDNkNDAyZDQzNTQ2ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.F1qWpjiawCF881JVeVZaCOLKHF2pmnREug1aJFIv-Wc	2026-08-06 11:03:25.453395+00	2026-08-13 11:03:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	757e3ea49396413985043d402d43546e
123	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjY0MjY2OCwiaWF0IjoxNzg2MDM3ODY4LCJqdGkiOiI5ZTk3Zjc5NGQ1NzE0NmMxYmJjZDJmOGU4ODhjOWJlNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.WAV4qC-fL5bndCIl0jzfqT3NOKYxFd1UwkevAZrugVA	2026-08-06 17:37:48.44046+00	2026-08-13 17:37:48+00	9a259d21-6303-464d-97fe-23a835dfdc29	9e97f794d57146c1bbcd2f8e888c9be6
124	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjY0MjY3NCwiaWF0IjoxNzg2MDM3ODc0LCJqdGkiOiJkODIyNjAyZDM0NmQ0M2QyOGZmNDYzODE2YjVmZDBjYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.f-HHPX-SgrlP9qr7Egb9znWZeHAojqOdyvOtENk4i0I	2026-08-06 17:37:54.480577+00	2026-08-13 17:37:54+00	9a259d21-6303-464d-97fe-23a835dfdc29	d822602d346d43d28ff463816b5fd0cb
125	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc2OTE4OSwiaWF0IjoxNzg2MTY0Mzg5LCJqdGkiOiI2Yjk0OTQ0ZTBmZGQ0MzYxOWUyNDY4ZTk5NDkwMjc3ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.OcWDb70nzZp7eYlKMdiihPd6axEZ-p6WQJWfBJng2NI	2026-08-08 04:46:29.426182+00	2026-08-15 04:46:29+00	9a259d21-6303-464d-97fe-23a835dfdc29	6b94944e0fdd43619e2468e99490277e
126	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc2OTE5NiwiaWF0IjoxNzg2MTY0Mzk2LCJqdGkiOiJmMTFhMzgxMmMxNjc0YzNjOGM1NzU2NDUxZGQ5M2FhZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.sZ78wlbjbH5fHD-LakIu0yyz0vF23ewQSIxT3z9dK5A	2026-08-08 04:46:36.570808+00	2026-08-15 04:46:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	f11a3812c1674c3c8c5756451dd93aae
127	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc3OTM1MiwiaWF0IjoxNzg2MTc0NTUyLCJqdGkiOiI0OGVjMDUxNTVlZWE0MGMyOGM0MThlNjcyNDkzNTlmNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ateGKWeoepu2kQlSArV70zvpy2a60yXOu24GOUCTKck	2026-08-08 07:35:52.437719+00	2026-08-15 07:35:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	48ec05155eea40c28c418e67249359f6
128	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc3OTc2NCwiaWF0IjoxNzg2MTc0OTY0LCJqdGkiOiIyZTU4MTI5OWJlYTU0YmE5OGM2ZGUwNTM1YmQ4ZjdhYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.WabShFTpGE_mdKfySCxZgUagwgIRQLTznhBnXsg05kU	2026-08-08 07:42:44.515808+00	2026-08-15 07:42:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	2e581299bea54ba98c6de0535bd8f7ac
129	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc5MzQ0OSwiaWF0IjoxNzg2MTg4NjQ5LCJqdGkiOiJiMTAzMDNiNGRkY2I0MWJkODJiYzFiYjNlYzU4ZWEyMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Fr2iXVB3Pip9oCZgKg80EqFvCaZ0ZhFSKBQ0LPPD_AM	2026-08-08 11:30:49.835673+00	2026-08-15 11:30:49+00	9a259d21-6303-464d-97fe-23a835dfdc29	b10303b4ddcb41bd82bc1bb3ec58ea21
130	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njc5MzQ3OSwiaWF0IjoxNzg2MTg4Njc5LCJqdGkiOiIyZGNkZWJiYjhlNDE0NmM2YmIyM2FhZGVmZDAyMDA4OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.vOXkDAhJrrhABd2ldTvuj9O9Wf1dp7ZVB-PvqO9aVEM	2026-08-08 11:31:19.477838+00	2026-08-15 11:31:19+00	9a259d21-6303-464d-97fe-23a835dfdc29	2dcdebbb8e4146c6bb23aadefd020089
131	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgwMTM4MywiaWF0IjoxNzg2MTk2NTgzLCJqdGkiOiJkNDdhZTc2NGZhYTM0NTE5YWNkZDE4YzkyMjAwNTVlZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.cRc-MVzuZ6H9-ctTfnEg2XsDk4vSAQkFFskhf3i702U	2026-08-08 13:43:03.486119+00	2026-08-15 13:43:03+00	9a259d21-6303-464d-97fe-23a835dfdc29	d47ae764faa34519acdd18c9220055ef
132	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgwMTQ1NCwiaWF0IjoxNzg2MTk2NjU0LCJqdGkiOiJlNjlkMzBiZjAwZDM0M2VhYjEwMjU0MDViNzBlMjk3MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.hYJiknoSdXv8URXpBVoC3N0kU9NgpLk2zCI8inETpKo	2026-08-08 13:44:14.514945+00	2026-08-15 13:44:14+00	9a259d21-6303-464d-97fe-23a835dfdc29	e69d30bf00d343eab1025405b70e2972
133	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgwNTU1MiwiaWF0IjoxNzg2MjAwNzUyLCJqdGkiOiIzNTU5ZjRkZTA5MDA0ZDBmOTc2ODQ2MWUzZTJhMzFmYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.kq0YF5eWByYx_Ejv9ZxUGqFSJcGoLkI0Jg8ggxWuEr0	2026-08-08 14:52:32.617491+00	2026-08-15 14:52:32+00	9a259d21-6303-464d-97fe-23a835dfdc29	3559f4de09004d0f9768461e3e2a31fb
134	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgwODUxOSwiaWF0IjoxNzg2MjAzNzE5LCJqdGkiOiI2NTBlNDI2YzYzZjM0ZGQ3OTk2OGZlOWQyYTQ2MjVlOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.gRCiasJty7TLZE7f9-4rHAFYZP4pGw6uEGn_U9aOKl4	2026-08-08 15:41:59.028349+00	2026-08-15 15:41:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	650e426c63f34dd79968fe9d2a4625e9
135	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgwODUzMSwiaWF0IjoxNzg2MjAzNzMxLCJqdGkiOiJkZThiZmI3MGM1YmI0OTQyYjhiZjA5ZjhkYWZhZDdlZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.RRWj1e2SeKydFnbXNO3vg5i8OesqBq1hvsnDXUaNITo	2026-08-08 15:42:11.527319+00	2026-08-15 15:42:11+00	9a259d21-6303-464d-97fe-23a835dfdc29	de8bfb70c5bb4942b8bf09f8dafad7ee
136	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgxMjYzOCwiaWF0IjoxNzg2MjA3ODM4LCJqdGkiOiIwNGYyMDdmZTRlYjI0NTMwOTU0ZWM5Mjg1MmFhOWFlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ASntepMVDeSayKj5ndVza7pMRyybFa_GCSGknnCZJng	2026-08-08 16:50:38.695459+00	2026-08-15 16:50:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	04f207fe4eb24530954ec92852aa9aec
137	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjgxMjY0NCwiaWF0IjoxNzg2MjA3ODQ0LCJqdGkiOiI0MTViZTRlMDczOTQ0Mzc1YWE1MmZkYzY3OTJlMTdlMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.LL4Zxw8M6XqQ82ENF398OFGvev4JlSlH5p6GlERJLsU	2026-08-08 16:50:44.523891+00	2026-08-15 16:50:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	415be4e073944375aa52fdc6792e17e2
138	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njg4MDI4MCwiaWF0IjoxNzg2Mjc1NDgwLCJqdGkiOiJjYmFjZjNhOGIxMGQ0NTU5YmE4OWZkYzk4ZTcyOTQ0MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.BIyOnQR1Q6SSP_MXg3TyhD1SjRMJZoQptJRZaWvGRVo	2026-08-09 11:38:00.695852+00	2026-08-16 11:38:00+00	9a259d21-6303-464d-97fe-23a835dfdc29	cbacf3a8b10d4559ba89fdc98e729440
139	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njg5MzUyMCwiaWF0IjoxNzg2Mjg4NzIwLCJqdGkiOiIyZDYxY2Y2NmRlNWE0YmZiYTA5MzhhNmE4NDkxZWExYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.RiZRBu8LlGpNvlMvCZJSGK29N7ofpE4EKNwlXA6cp5o	2026-08-09 15:18:40.640814+00	2026-08-16 15:18:40+00	9a259d21-6303-464d-97fe-23a835dfdc29	2d61cf66de5a4bfba0938a6a8491ea1a
140	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjkwNDE0NSwiaWF0IjoxNzg2Mjk5MzQ1LCJqdGkiOiIwYzI3MDQ1ZWNhNjA0MWFiYTk3NGZhYTk5ZmQ1NzYyZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.cLtE_BP9cwyP7kIgZVvby0AbApb1fyVyM2WT790mqZ0	2026-08-09 18:15:45.549314+00	2026-08-16 18:15:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	0c27045eca6041aba974faa99fd5762f
141	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NjkwNDE4MCwiaWF0IjoxNzg2Mjk5MzgwLCJqdGkiOiJlNTE3N2JhNzA2N2Y0ODVjOGY4NTM3OTU5MzcxNTc5ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.xAdhnfpKA7iIgUbC5NTMiNWDLtrEsjrfrSDz7jq-Xug	2026-08-09 18:16:20.876852+00	2026-08-16 18:16:20+00	9a259d21-6303-464d-97fe-23a835dfdc29	e5177ba7067f485c8f8537959371579d
142	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njk1NjcxMCwiaWF0IjoxNzg2MzUxOTEwLCJqdGkiOiIzZDEzYjQzYzUzMWY0MDMyYjA1ZjI3NmIzNTgwNjZmMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.rnRJuFDxxKhQzgpWLcKHenyAZKpcCxDBD0NacHTNyRI	2026-08-10 08:51:50.999383+00	2026-08-17 08:51:50+00	9a259d21-6303-464d-97fe-23a835dfdc29	3d13b43c531f4032b05f276b358066f1
143	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Njk1Njg3MSwiaWF0IjoxNzg2MzUyMDcxLCJqdGkiOiIwODJjZjc0ZDQyMjg0NGEyOGYwYWJmMTFkZjE5YjE5ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.EqPNiuiRQ7JzpGR-wrHJ0I_00yKNpaAsJt_djbD36T8	2026-08-10 08:54:31.024707+00	2026-08-17 08:54:31+00	9a259d21-6303-464d-97fe-23a835dfdc29	082cf74d422844a28f0abf11df19b19e
144	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzA3NzU5NiwiaWF0IjoxNzg2NDcyNzk2LCJqdGkiOiIxZTZiZDA5MjJiYmU0ZDY1OGNiNzFhYjE5YThjZjg5ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.6uqrg0Jc9txUg9HJF5bwsI00rIDG6gDfyOTfR7oBTSo	2026-08-11 18:26:36.593528+00	2026-08-18 18:26:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	1e6bd0922bbe4d658cb71ab19a8cf89f
145	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzA3Nzk3MiwiaWF0IjoxNzg2NDczMTcyLCJqdGkiOiI5MWIzZGFmMDIyZmQ0YjRiODJjYWI2OTIwYjY5MDVmYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.eswTaj67JTRSjqAzBIhNaqcihyV8VLnCbE2eyBBtnOE	2026-08-11 18:32:52.039671+00	2026-08-18 18:32:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	91b3daf022fd4b4b82cab6920b6905fb
146	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzExODQzOSwiaWF0IjoxNzg2NTEzNjM5LCJqdGkiOiIzODJhM2ZjODQ5NjA0MThkODRmMjNhMTQ5N2U2NDdlOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.TDNdLK9dBCiVX9NDP-viYNYb3erxU9QF6h_yzot49NM	2026-08-12 05:47:19.266355+00	2026-08-19 05:47:19+00	9a259d21-6303-464d-97fe-23a835dfdc29	382a3fc84960418d84f23a1497e647e9
147	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzExOTY3NiwiaWF0IjoxNzg2NTE0ODc2LCJqdGkiOiIzNGRkYWEzNTNiYmU0NTg0Yjk1N2MxYmE2ZWE4Y2ViYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.4BTZEH7kMzhr_Fq0oEltdUgIV4smr6nK9QbFQVP1Vow	2026-08-12 06:07:56.973471+00	2026-08-19 06:07:56+00	9a259d21-6303-464d-97fe-23a835dfdc29	34ddaa353bbe4584b957c1ba6ea8cebc
148	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzEyMzQwOSwiaWF0IjoxNzg2NTE4NjA5LCJqdGkiOiIzYjhhN2U2YjBmNTE0NWE4ODNhOTRiNzU5MWFkYjc1YyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Vok82orpdYK69OnO8tGJ9NFYlnBUJMHyc697ZUIP4Dw	2026-08-12 07:10:09.492635+00	2026-08-19 07:10:09+00	9a259d21-6303-464d-97fe-23a835dfdc29	3b8a7e6b0f5145a883a94b7591adb75c
149	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzE1MTk0NSwiaWF0IjoxNzg2NTQ3MTQ1LCJqdGkiOiJhYzEwN2ZiYWRmZjY0M2Q2OGNmN2NjZjQ4OGJhYjIyMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.-CFGdQKml26TgWIr196Tco_pLSLxh2OzXf2gZ3cI-kU	2026-08-12 15:05:45.506965+00	2026-08-19 15:05:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	ac107fbadff643d68cf7ccf488bab220
150	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzE5NjAwMSwiaWF0IjoxNzg2NTkxMjAxLCJqdGkiOiIyZGJjMTJkZTc3Zjg0NzljOWJmY2RlZDYzZjYyNWI3MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.o_dUYGMhbP7WNow6VqPE4XBLIQ4pGWjYliSEUy3YMfY	2026-08-13 03:20:01.397033+00	2026-08-20 03:20:01+00	9a259d21-6303-464d-97fe-23a835dfdc29	2dbc12de77f8479c9bfcded63f625b70
151	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzE5NjAxMywiaWF0IjoxNzg2NTkxMjEzLCJqdGkiOiJhMjRkODNjNzViN2E0ZGJlOGE0YzcwZWUzMWRhZDI5MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.OmKYHOcnuTqmemEPUjn5vr243sawoaCtykFDL1W-8sU	2026-08-13 03:20:13.457884+00	2026-08-20 03:20:13+00	9a259d21-6303-464d-97fe-23a835dfdc29	a24d83c75b7a4dbe8a4c70ee31dad290
152	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzIxMDI3MiwiaWF0IjoxNzg2NjA1NDcyLCJqdGkiOiJiZDY1ZTVmNWYzOGU0MGYzOGQ3NzViOGJlZjNlZGFlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.egyFb8SI06GL0q-KTV-ExlmljjOr8mhNYZmt4yUuzzw	2026-08-13 07:17:52.700192+00	2026-08-20 07:17:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	bd65e5f5f38e40f38d775b8bef3edaec
153	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzIyMzM5NiwiaWF0IjoxNzg2NjE4NTk2LCJqdGkiOiI5MjU0Njg4ZWRhNjg0ZmM1YjdmZWM2ZTI4NWVkYTY5MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.-xrY7o8RPsy1T4kZIJ5rJeLQUzmALToi9rVQIm17TGs	2026-08-13 10:56:36.899222+00	2026-08-20 10:56:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	9254688eda684fc5b7fec6e285eda692
154	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzIyODUxMiwiaWF0IjoxNzg2NjIzNzEyLCJqdGkiOiI4Njk2YzUwZThlODA0NTIzOTcxZjNhMDRiMTVjNjkwOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.czXEv-9rdxljsMKCkplHLSF6rJv55FF7oCZ7Wohwcu0	2026-08-13 12:21:52.71006+00	2026-08-20 12:21:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	8696c50e8e804523971f3a04b15c6909
155	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzIyODUyNywiaWF0IjoxNzg2NjIzNzI3LCJqdGkiOiI1M2JjY2RmMGMxYzc0MmQ5OTUwNWIxYmJhYTU0MDE3ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.tKPqdRLTUN2mDpiHbdC29D6KzrhQ-Xu2O8NDPSF2h8s	2026-08-13 12:22:07.326691+00	2026-08-20 12:22:07+00	9a259d21-6303-464d-97fe-23a835dfdc29	53bccdf0c1c742d99505b1bbaa54017e
156	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzI0NTkyNSwiaWF0IjoxNzg2NjQxMTI1LCJqdGkiOiIzZTU5ZTE5NDNmNTM0OTZiOTg3MDMxODFjMThmMjhiNCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.TMDfcrmTrIapa3U_usG2YBCh6Yudvtle6tmVFRe-qvI	2026-08-13 17:12:05.060078+00	2026-08-20 17:12:05+00	9a259d21-6303-464d-97fe-23a835dfdc29	3e59e1943f53496b98703181c18f28b4
157	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzI0NTk0NiwiaWF0IjoxNzg2NjQxMTQ2LCJqdGkiOiJhOTRjNjI1YzFiZjY0Mzg2YTZiNmU0YTI4ZDhjZGY5NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Z6-p9e03mYCOGkvl5Q30t9waWXDwin3GPBiWUC7hJdo	2026-08-13 17:12:26.090425+00	2026-08-20 17:12:26+00	9a259d21-6303-464d-97fe-23a835dfdc29	a94c625c1bf64386a6b6e4a28d8cdf96
158	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzMwMzU5NSwiaWF0IjoxNzg2Njk4Nzk1LCJqdGkiOiI4N2IxMjc3MDAzNTI0MmVhODMyNTg3MGQxNmJlYjA0NyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ZJ_LOXF3XJ7QfwF_-9Sg0woBST1QRre8EHq1k5BMOxw	2026-08-14 09:13:15.019023+00	2026-08-21 09:13:15+00	9a259d21-6303-464d-97fe-23a835dfdc29	87b12770035242ea8325870d16beb047
159	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzMwMzYwMCwiaWF0IjoxNzg2Njk4ODAwLCJqdGkiOiI0MThjYWNkOTlhZGM0NGJmOGFiYzBiMTVmMDI2NTRjYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.j-457BTVhIGWZFQSh_LilUolWkPighAc42368kh8LqA	2026-08-14 09:13:20.529848+00	2026-08-21 09:13:20+00	9a259d21-6303-464d-97fe-23a835dfdc29	418cacd99adc44bf8abc0b15f02654ca
160	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzMzNTk3OCwiaWF0IjoxNzg2NzMxMTc4LCJqdGkiOiI0OTI2MDkxMDlhYzk0OTNmYjc1NTRlYjkyNDZlNDAwNCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.pjPGedFrx-voUBHWkDWEgzxvcfb03CbSJpVmG3Jmt-E	2026-08-14 18:12:58.682504+00	2026-08-21 18:12:58+00	9a259d21-6303-464d-97fe-23a835dfdc29	492609109ac9493fb7554eb9246e4004
161	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzQwNjE4OSwiaWF0IjoxNzg2ODAxMzg5LCJqdGkiOiJmM2MzYWU1MGMyYjQ0M2QyYTg1YWJmOGI5NzlmZDczYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.EzclxrjPDuayh5zciLEyiYx1OPBlMEEZg7d57uhmID0	2026-08-15 13:43:09.842544+00	2026-08-22 13:43:09+00	9a259d21-6303-464d-97fe-23a835dfdc29	f3c3ae50c2b443d2a85abf8b979fd73b
162	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzU3MDkxMiwiaWF0IjoxNzg2OTY2MTEyLCJqdGkiOiIyMTI4M2FmMzBiZTY0NzA3YTk5ZGNlZmYyOWRjZjliMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.5jsuZXwaL1zTW4sbEaPCUiJ1OzPf7rRBO2XmY6535a4	2026-08-17 11:28:32.783007+00	2026-08-24 11:28:32+00	9a259d21-6303-464d-97fe-23a835dfdc29	21283af30be64707a99dceff29dcf9b1
163	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzU3MDkyMiwiaWF0IjoxNzg2OTY2MTIyLCJqdGkiOiJhMWQ0Y2I1ZjNmNTY0ZjY4YTM3OWNmNjRlM2IzZTA5ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.PKKfCivkAODNc7YOweO-2K4mQvaMQpf-TGY50RuJpa0	2026-08-17 11:28:42.137912+00	2026-08-24 11:28:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	a1d4cb5f3f564f68a379cf64e3b3e09d
164	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzYwNTc0OSwiaWF0IjoxNzg3MDAwOTQ5LCJqdGkiOiJlYTgxYmJhOWFmZjc0MThjYWI2MGY1MTA1YTg0MjVkMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.IeYUwqTVlP57aclHC0T2dCsKvK9IcVE8vihZBkzla78	2026-08-17 21:09:09.523512+00	2026-08-24 21:09:09+00	9a259d21-6303-464d-97fe-23a835dfdc29	ea81bba9aff7418cab60f5105a8425d2
165	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzYwNTc1NSwiaWF0IjoxNzg3MDAwOTU1LCJqdGkiOiI1ZmQyYzg1NDQ1NTA0M2IxYjMyMGE1N2M1MmI1ODhlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.eKikKP5cK-h05dXK7pKQTDa6IPvrgavFUmY9EjIIKEM	2026-08-17 21:09:15.067902+00	2026-08-24 21:09:15+00	9a259d21-6303-464d-97fe-23a835dfdc29	5fd2c854455043b1b320a57c52b588ec
166	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY1NjU1OSwiaWF0IjoxNzg3MDUxNzU5LCJqdGkiOiIzODIyNTgzYzNiZmU0OGRlYjJiMzgyYzE0ODA4YzdlNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.ancfo4STLHnGX7SgJXTWgfRfcEeed6BEmZR5bg2syFA	2026-08-18 11:15:59.556344+00	2026-08-25 11:15:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	3822583c3bfe48deb2b382c14808c7e7
167	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY1NjU2OCwiaWF0IjoxNzg3MDUxNzY4LCJqdGkiOiI5MTNhYzU3MzZiNTk0YjdmOGM5MzE2Yjg5Mzg1ZDY4ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.z4olUXbGpwpPr0ih8qG4oGEd-Agr1TXBrHzGAKyx6wI	2026-08-18 11:16:08.05007+00	2026-08-25 11:16:08+00	9a259d21-6303-464d-97fe-23a835dfdc29	913ac5736b594b7f8c9316b89385d68f
168	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY1NzAwOSwiaWF0IjoxNzg3MDUyMjA5LCJqdGkiOiI3ODExMjQ2NGRjMzg0N2NkYmFhNDM2ZTFjNzAwNWI3ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.gzNTmW_1dwTYoBjhaZoG8szn17MiEh6nVLRXht7zplE	2026-08-18 11:23:29.34812+00	2026-08-25 11:23:29+00	9a259d21-6303-464d-97fe-23a835dfdc29	78112464dc3847cdbaa436e1c7005b7d
169	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY2NzQwNywiaWF0IjoxNzg3MDYyNjA3LCJqdGkiOiJiODVjNjYxOGU1Y2Y0YjE1OGZjMjVlZjM0YTQ0ZTBmNCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.csYFCXOeWzTROCBXU7VQF42bitLVibyXE3t4bSCo_mc	2026-08-18 14:16:47.962697+00	2026-08-25 14:16:47+00	9a259d21-6303-464d-97fe-23a835dfdc29	b85c6618e5cf4b158fc25ef34a44e0f4
170	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY2NzQyNSwiaWF0IjoxNzg3MDYyNjI1LCJqdGkiOiJmNGUyNDk5NzUzYWM0OTA4OWMzNzIyMGUxOTMyZDI2YiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ZGQbPcK-PVpnHrhwR8o7nEJOLfVaFLMiW7pf_Am_4mk	2026-08-18 14:17:05.503826+00	2026-08-25 14:17:05+00	9a259d21-6303-464d-97fe-23a835dfdc29	f4e2499753ac49089c37220e1932d26b
171	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY3NzQ4OCwiaWF0IjoxNzg3MDcyNjg4LCJqdGkiOiI3NzM3MzFhZjRhODA0M2YxYTgxOTkwM2JmYjI0MThiMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.EIrsRw6gm5f52Qq7qMU-2GA7SVq0RC9-HdTJpQ327Jw	2026-08-18 17:04:48.709677+00	2026-08-25 17:04:48+00	9a259d21-6303-464d-97fe-23a835dfdc29	773731af4a8043f1a819903bfb2418b3
172	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzY3NzUwNiwiaWF0IjoxNzg3MDcyNzA2LCJqdGkiOiJjNDg0YWQ4MmM5NWM0MDU2YmQ5OTI0MWZlZTEzNDMwYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.YCiQ1zGsRP39Vg03gkk0vwEyTV6aPS2NTF48NwFirZ8	2026-08-18 17:05:06.14769+00	2026-08-25 17:05:06+00	9a259d21-6303-464d-97fe-23a835dfdc29	c484ad82c95c4056bd99241fee13430b
173	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzc0MzI3MiwiaWF0IjoxNzg3MTM4NDcyLCJqdGkiOiIyNGQ2YzU0MTMyYWM0YmNiYjY2YmJhODEyZmMzMWFmZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.LTqnnMTRjplZ1NEXxqbOQSQyotHUW10SHhTQYQLXpPE	2026-08-19 11:21:12.672595+00	2026-08-26 11:21:12+00	9a259d21-6303-464d-97fe-23a835dfdc29	24d6c54132ac4bcbb66bba812fc31afd
174	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzc0MzU0NSwiaWF0IjoxNzg3MTM4NzQ1LCJqdGkiOiIyYTMyZDRhNzBlNTk0MzkzYjJiMGI5MzEyODVmNmI0NCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.svlyWvC_Aqi0TlQrnDCcAIWOh49nHmk0s7gQ8MOWnB8	2026-08-19 11:25:45.912913+00	2026-08-26 11:25:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	2a32d4a70e594393b2b0b931285f6b44
175	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzgxMzA0MywiaWF0IjoxNzg3MjA4MjQzLCJqdGkiOiI3OTNlMDVhMjdkYjY0MWMyODUzNzI5YTcyMGFmYzY2ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.6ngBZ6eFzyetbHYp66MGoNJ8K5ZPaDbWEboG24aEe1M	2026-08-20 06:44:03.546976+00	2026-08-27 06:44:03+00	9a259d21-6303-464d-97fe-23a835dfdc29	793e05a27db641c2853729a720afc66d
176	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4NzgxMzA1MCwiaWF0IjoxNzg3MjA4MjUwLCJqdGkiOiI2MDEwNzIwMmZmOTA0NmY2YmY5YjYyZTYwNmJjODVlZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.KQxH_Gc7NE56-p_-coZzfae4UhjEmweKPVUDm-JEsK4	2026-08-20 06:44:10.582909+00	2026-08-27 06:44:10+00	9a259d21-6303-464d-97fe-23a835dfdc29	60107202ff9046f6bf9b62e606bc85ed
177	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzg0MjM0MiwiaWF0IjoxNzg3MjM3NTQyLCJqdGkiOiIwOWE2ZTcwZmEyYmY0NDQ5YTg1NTc5ODFlM2I4ODQ3NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.bqjZ-UVbSbMLRVc2KpNEFP2LihoNpj9fgVs0BHJtkMo	2026-08-20 14:52:22.338485+00	2026-08-27 14:52:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	09a6e70fa2bf4449a8557981e3b88476
178	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzg0MjM1NiwiaWF0IjoxNzg3MjM3NTU2LCJqdGkiOiI4ZDNlZmRjN2NhZjM0NDY2ODAwOTYzYWVmZmZkNDEyZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.CcqpjRe9tVjiLRdyTYq4U4pp_O3s9yL_ajLsErv5Vk4	2026-08-20 14:52:36.26065+00	2026-08-27 14:52:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	8d3efdc7caf34466800963aefffd412e
179	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzg1NDIzNywiaWF0IjoxNzg3MjQ5NDM3LCJqdGkiOiI4ODRlZjg4NGFiZTg0ZTM1OWM2ZTc5YWU1MmU1NjRjZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.JpOow-e-xyMsPBpvJ_kW4Olw7WmTM77qHl31s25PUUM	2026-08-20 18:10:37.975854+00	2026-08-27 18:10:37+00	9a259d21-6303-464d-97fe-23a835dfdc29	884ef884abe84e359c6e79ae52e564cd
180	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzg1NDI0NiwiaWF0IjoxNzg3MjQ5NDQ2LCJqdGkiOiI0YzFmNGQ0ODE1Mzc0ODhlODdiY2Y4MjhkOTFjODcyZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.JfA5djN_1zztSmnf_pnJ_Wh1IbSTeOKRX_uOobxxow4	2026-08-20 18:10:46.718824+00	2026-08-27 18:10:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	4c1f4d481537488e87bcf828d91c872f
181	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4Nzg1NDM1MiwiaWF0IjoxNzg3MjQ5NTUyLCJqdGkiOiI2YTJkM2I4ZWVhZDE0MjFhYWNlYzM3ZWVjN2MyMWE4ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.A9RtbYvP8WY0dVU3VtCwURcm-UvYzAZd6ZXeO5jgqu0	2026-08-20 18:12:32.91697+00	2026-08-27 18:12:32+00	9a259d21-6303-464d-97fe-23a835dfdc29	6a2d3b8eead1421aacec37eec7c21a8f
182	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODA4MDU1OCwiaWF0IjoxNzg3NDc1NzU4LCJqdGkiOiI0MzZjZjkxNWMwYjY0OTIzYWRhNjE0ZDFlYjVlMjJkMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.GXPh1j0Y9H_SN3TQOBwk9jlpymBaMvXYbYu2ImiKzAw	2026-08-23 09:02:38.051518+00	2026-08-30 09:02:38+00	9a259d21-6303-464d-97fe-23a835dfdc29	436cf915c0b64923ada614d1eb5e22d2
183	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODA4MDU2NiwiaWF0IjoxNzg3NDc1NzY2LCJqdGkiOiIwYTk0YzE3ZTIwOTA0MzcwODc0MDlhNDg4N2YwMGZkYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.dcK6Br454G-KqpSv8RXUglK9oD5kcZPd1AKnwC3IsNQ	2026-08-23 09:02:46.775223+00	2026-08-30 09:02:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	0a94c17e2090437087409a4887f00fdb
184	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODA5NDg4OSwiaWF0IjoxNzg3NDkwMDg5LCJqdGkiOiI5ZWQyMjAwNTg1NGE0OTc3YmYwYTUyOTg1NWRmOGVhMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.hwuKXe2wkyTUV-Taw3HIpvFO7B3QlHaMmR7gP4ByCD0	2026-08-23 13:01:29.570904+00	2026-08-30 13:01:29+00	9a259d21-6303-464d-97fe-23a835dfdc29	9ed22005854a4977bf0a529855df8ea1
185	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODA5NDg5NSwiaWF0IjoxNzg3NDkwMDk1LCJqdGkiOiIwNGM3OGNlN2E3Nzc0MTJiODgzMzQxNDJkZmM1MGUxMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.QuQF3i-XXQDd2OE_49pCf4DDvYCsc95VMaqayjed3vA	2026-08-23 13:01:35.802259+00	2026-08-30 13:01:35+00	9a259d21-6303-464d-97fe-23a835dfdc29	04c78ce7a777412b88334142dfc50e11
186	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwMjgzMCwiaWF0IjoxNzg3NDk4MDMwLCJqdGkiOiIzNjhhODEyN2U1YmM0OWE3OWE4MTkxYjdmNjJhNjY4NSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.OpzgH6uo_fYa6fqVYzDdv-aPDOOb61Yu42lyFLSm38k	2026-08-23 15:13:50.350605+00	2026-08-30 15:13:50+00	9a259d21-6303-464d-97fe-23a835dfdc29	368a8127e5bc49a79a8191b7f62a6685
187	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwMzM3MywiaWF0IjoxNzg3NDk4NTczLCJqdGkiOiIyMDUwODFjYjk1Nzg0ZjQwYmEwMDNkNzMxNjNhOTA4MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.AB3LydhRQbse9wosf5LhMJBxzQMaDJVFQFn6D3HIGoU	2026-08-23 15:22:53.498698+00	2026-08-30 15:22:53+00	9a259d21-6303-464d-97fe-23a835dfdc29	205081cb95784f40ba003d73163a9083
188	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwNDI2MSwiaWF0IjoxNzg3NDk5NDYxLCJqdGkiOiI3ODg5YzE2YmE3M2I0NGUzYWRhZDhmN2M3ZGM3ZDEwMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.v4sNZR7xDflfZW44M6mjv9lml1C3xpshUPb9IlXDx3g	2026-08-23 15:37:41.5747+00	2026-08-30 15:37:41+00	9a259d21-6303-464d-97fe-23a835dfdc29	7889c16ba73b44e3adad8f7c7dc7d100
189	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwODUzNywiaWF0IjoxNzg3NTAzNzM3LCJqdGkiOiI0OGJmYTRjMTg0NzI0OGQ4OWY5NmUzMTE2MzNmN2M2ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ss_7-f5WSraTF6h_EnRS0mjji7ZZNxijaT_l7t7Tbgw	2026-08-23 16:48:57.40754+00	2026-08-30 16:48:57+00	9a259d21-6303-464d-97fe-23a835dfdc29	48bfa4c1847248d89f96e311633f7c6d
190	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwOTA3MSwiaWF0IjoxNzg3NTA0MjcxLCJqdGkiOiI1MTU3NzQ1ODk3M2M0NTQ1YTRmY2U0MDk1YzE2MWM0ZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ._jdsXHWe_r1zW42SBDzFQVfIxBDzYeH5eyJZsa_ZHVk	2026-08-23 16:57:51.0907+00	2026-08-30 16:57:51+00	9a259d21-6303-464d-97fe-23a835dfdc29	51577458973c4545a4fce4095c161c4f
191	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODEwOTU0OSwiaWF0IjoxNzg3NTA0NzQ5LCJqdGkiOiJiMmRjYzk5MmQyN2Q0ODE2OGZlMjI2MWNhMzg2M2MzZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.LKCbibS66qQaoGoUD5dAfNoKVtC4s__4BCdR9iIc0Ho	2026-08-23 17:05:49.537259+00	2026-08-30 17:05:49+00	9a259d21-6303-464d-97fe-23a835dfdc29	b2dcc992d27d48168fe2261ca3863c3f
192	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMDA4OSwiaWF0IjoxNzg3NTA1Mjg5LCJqdGkiOiJkMGNmYjNhNGNhMWU0MTBiODE5MDc1ZTkxZjkxMmVhYSIsInVzZXJfaWQiOiJkMjJkNjY2Yy01MjM2LTRhYmQtYThjNC02YjNmOGUwM2ZhNDgifQ.Ba2P3LraN9hqXmrTwWd0TNrzviIP4LVMreWxIFDqG6E	2026-08-23 17:14:49.847224+00	2026-08-30 17:14:49+00	\N	d0cfb3a4ca1e410b819075e91f912eaa
193	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMDE0MCwiaWF0IjoxNzg3NTA1MzQwLCJqdGkiOiI0ZjBmZmQyNzFjZmY0YWZmYjIyYzk3YzViNWZhNmE0ZCIsInVzZXJfaWQiOiJkMjJkNjY2Yy01MjM2LTRhYmQtYThjNC02YjNmOGUwM2ZhNDgifQ._VwCCsM7F9U2x5y8kSjqp5lpqnlTrEx0QY8UCYTElDU	2026-08-23 17:15:40.555122+00	2026-08-30 17:15:40+00	\N	4f0ffd271cff4affb22c97c5b5fa6a4d
194	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMDU5MSwiaWF0IjoxNzg3NTA1NzkxLCJqdGkiOiJhNmRlZmI3ZWYzMjk0ZTkyOGUwNjFkMjFkM2M5NmVmNCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Ti1FzbNrH9LiXnihdDn1t73YML1ff3eAMa3KGmHelH4	2026-08-23 17:23:11.498324+00	2026-08-30 17:23:11+00	9a259d21-6303-464d-97fe-23a835dfdc29	a6defb7ef3294e928e061d21d3c96ef4
195	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMTAzMSwiaWF0IjoxNzg3NTA2MjMxLCJqdGkiOiI4ZDM3ZTU2Mzc0NzE0ZjExYTdhNWViZTQzN2U3OWZiMyIsInVzZXJfaWQiOiJjMjhhODQ2ZC0wZTIzLTRkZjMtOTMzZC0yZjAxYTU2NDU4N2MifQ.YojBpG6scVGNnoiaawELjrFMP73j3oa45TciAkZVBak	2026-08-23 17:30:31.550756+00	2026-08-30 17:30:31+00	\N	8d37e56374714f11a7a5ebe437e79fb3
196	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMTExNSwiaWF0IjoxNzg3NTA2MzE1LCJqdGkiOiIwZjkwNGFlMDE4YmM0Y2M2ODZkMDA5YjI1MTkyMjU3MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.hB7WUxsPvVYpNbKqj6WVUu_Ew2IgGXD8A869HbhpKJ0	2026-08-23 17:31:55.499293+00	2026-08-30 17:31:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	0f904ae018bc4cc686d009b251922573
197	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMTEzNiwiaWF0IjoxNzg3NTA2MzM2LCJqdGkiOiI5Zjk4MmNmODMzZTY0MmVhOWU4YmMyMjc5NmU2MzRiZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.36AdHGdRK_0G9hjcvksmc-k5u7Yq_8XHZ-_vAdMUCog	2026-08-23 17:32:16.109338+00	2026-08-30 17:32:16+00	9a259d21-6303-464d-97fe-23a835dfdc29	9f982cf833e642ea9e8bc22796e634bd
198	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMTk4MSwiaWF0IjoxNzg3NTA3MTgxLCJqdGkiOiJlYTJlMTU4NGI4MzE0YjExYTUxMGYyYTMyNGFmNDE1ZSIsInVzZXJfaWQiOiIzMzNiZjY5MC02NDBlLTRhMWEtOTM1OC1iY2Q1NWUwZGIzMWIifQ.t-i7Ue2KwwvN4A9Go-WfcBpfI1Ix9C_V9N9QeSG94oI	2026-08-23 17:46:21.506847+00	2026-08-30 17:46:21+00	\N	ea2e1584b8314b11a510f2a324af415e
199	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMjA3NCwiaWF0IjoxNzg3NTA3Mjc0LCJqdGkiOiIxNDViODMyMWIyZmI0ODhiODc4YzE2MGY2NjQ2OWYzNyIsInVzZXJfaWQiOiIzMzNiZjY5MC02NDBlLTRhMWEtOTM1OC1iY2Q1NWUwZGIzMWIifQ.ZJ9Ce47Yf0X_rk-65XYS3Wcf3wvo8VwCuMtBF2He55Y	2026-08-23 17:47:54.811952+00	2026-08-30 17:47:54+00	\N	145b8321b2fb488b878c160f66469f37
200	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMzA0MSwiaWF0IjoxNzg3NTA4MjQxLCJqdGkiOiJkNGY3NmMxZWEyODQ0NmE2OTVkNjI3ZDMyNTc1N2FhZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.agslq5r4nmCP620dW9fa2BKwbFq0Uol1K6_Kunzc0XM	2026-08-23 18:04:01.705195+00	2026-08-30 18:04:01+00	9a259d21-6303-464d-97fe-23a835dfdc29	d4f76c1ea28446a695d627d325757aad
201	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExMzA4MSwiaWF0IjoxNzg3NTA4MjgxLCJqdGkiOiI0YjExZWI3MWVjNDQ0MWM3OTFkMmYwMjhmN2U1NDZkZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.QNLXmVNgwX0vWYWEEB6eg8LXrtK_wX5UCRJGnN3OwqY	2026-08-23 18:04:41.30457+00	2026-08-30 18:04:41+00	9a259d21-6303-464d-97fe-23a835dfdc29	4b11eb71ec4441c791d2f028f7e546de
202	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExNzUxOSwiaWF0IjoxNzg3NTEyNzE5LCJqdGkiOiI1ZTgyYmEzNGQ1YjE0MTNlYTk3NzNjNGM0OTE0NWI2ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.X8hq71t9irgMzmB41eXMZctzpon4gICUcyWUvSiqvqo	2026-08-23 19:18:39.611777+00	2026-08-30 19:18:39+00	9a259d21-6303-464d-97fe-23a835dfdc29	5e82ba34d5b1413ea9773c4c49145b6e
203	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODExNzUyNSwiaWF0IjoxNzg3NTEyNzI1LCJqdGkiOiJjYmM5Nzc4ZmRiMGI0YTAzYWJhYjhiNjI5ZmJiMTBmNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.yjBRC4GIsnASUt16gC2F-jBnjArwSZlw8Svjc6hDK70	2026-08-23 19:18:45.546563+00	2026-08-30 19:18:45+00	9a259d21-6303-464d-97fe-23a835dfdc29	cbc9778fdb0b4a03abab8b629fbb10f6
204	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODE3ODc5MSwiaWF0IjoxNzg3NTczOTkxLCJqdGkiOiIxYjU3YzZiNTg0MjU0ODY5ODA1NDU0MmM4ZjRlNWE4MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.p4TEwvdPt5mLn83I8RqGylSxtI4Hr44vfSR-clw_9og	2026-08-24 12:19:51.839254+00	2026-08-31 12:19:51+00	9a259d21-6303-464d-97fe-23a835dfdc29	1b57c6b5842548698054542c8f4e5a83
205	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODE3ODc5OSwiaWF0IjoxNzg3NTczOTk5LCJqdGkiOiI2MDJlMjNmNTBhODk0YzQ1YjI4YWZmZWE0ZGM1MTIwZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.kdWmk2ziEAUVdcp2QJu1LiGIBqZSEgV-wdJ0nx1hy7Y	2026-08-24 12:19:59.750709+00	2026-08-31 12:19:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	602e23f50a894c45b28affea4dc5120d
206	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODI0NjI3NywiaWF0IjoxNzg3NjQxNDc3LCJqdGkiOiJlNDdjN2U3ZWRmZTc0OWYwOGY2OWUyNWVlOWM4ZGE4NyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.Ujaz6XmQVYAKZ7mqojqruZTfCD9Y60n0YMAvwBtJSD0	2026-08-25 07:04:37.557273+00	2026-09-01 07:04:37+00	9a259d21-6303-464d-97fe-23a835dfdc29	e47c7e7edfe749f08f69e25ee9c8da87
207	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODI0NjMyNCwiaWF0IjoxNzg3NjQxNTI0LCJqdGkiOiI1ZTZlZDA5MWNkNjE0NGZjYjY1NGY4MzY3MDU1MTVhYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.0_z0Ic7yXtU7Duqer8MpAn2ATj9hvgcSdB9GHiXOKiE	2026-08-25 07:05:24.186618+00	2026-09-01 07:05:24+00	9a259d21-6303-464d-97fe-23a835dfdc29	5e6ed091cd6144fcb654f836705515aa
208	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODM2MTY0NiwiaWF0IjoxNzg3NzU2ODQ2LCJqdGkiOiIyYWJjN2ZhNjg0MGI0NjY1YjIwMjZkODU0ODYwNWMxOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.hZkIT3J0QB3ASH2OxRRZ56DeTpOKdMthhERX_bC2mJI	2026-08-26 15:07:26.505638+00	2026-09-02 15:07:26+00	9a259d21-6303-464d-97fe-23a835dfdc29	2abc7fa6840b4665b2026d8548605c18
209	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODM2MTY1NiwiaWF0IjoxNzg3NzU2ODU2LCJqdGkiOiI1ZDI1M2JhZWJjNTc0NWVjYTRjMTQ5OGU2YTgwMWM5ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.WAoXl3AEj6XKuWf7jnnzzE8-hTO_6w97hIebk9hphSg	2026-08-26 15:07:36.33877+00	2026-09-02 15:07:36+00	9a259d21-6303-464d-97fe-23a835dfdc29	5d253baebc5745eca4c1498e6a801c9d
210	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQwOTI3MSwiaWF0IjoxNzg3ODA0NDcxLCJqdGkiOiJhNWYxNDQ5NTY0NjI0YTk4ODllZTNkMDg2MGE3ZTZkMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.4uHBMm_ufc62FR3Fb_ucAxhujAgcJAhgQhOIuIqLhHk	2026-08-27 04:21:11.512092+00	2026-09-03 04:21:11+00	9a259d21-6303-464d-97fe-23a835dfdc29	a5f1449564624a9889ee3d0860a7e6d2
211	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQwOTI3NiwiaWF0IjoxNzg3ODA0NDc2LCJqdGkiOiIxNGNjMGVjYzJiZDM0NDEwYTdkZGZjYWEyMGE2ZTY3ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.hlMIDy67IxCeMri8oUTSedrJw-WdMHZJh1zWKrAed9E	2026-08-27 04:21:16.464899+00	2026-09-03 04:21:16+00	9a259d21-6303-464d-97fe-23a835dfdc29	14cc0ecc2bd34410a7ddfcaa20a6e67e
212	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQxODMwNywiaWF0IjoxNzg3ODEzNTA3LCJqdGkiOiIwMjE2YjkwNWQ0MTc0MGEwYTViM2M1ZjAyZjA2OWZlYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.JO-UDxMsFu7AWqXduJk2FkZqzNtcOa84LZatnSy9h58	2026-08-27 06:51:47.474465+00	2026-09-03 06:51:47+00	9a259d21-6303-464d-97fe-23a835dfdc29	0216b905d41740a0a5b3c5f02f069feb
213	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQxODMxMiwiaWF0IjoxNzg3ODEzNTEyLCJqdGkiOiJjMDFkODU1MThmNmM0NWUxYWQ2ZTNiMjRlNTY4YTRmOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.HGC6gIt1afHp39pBah0gx1s_vM15LL7JC-8kz3Rxdvs	2026-08-27 06:51:52.235355+00	2026-09-03 06:51:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	c01d85518f6c45e1ad6e3b24e568a4f9
214	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQxOTA4MiwiaWF0IjoxNzg3ODE0MjgyLCJqdGkiOiIyNDJjZGViOGY2MGE0ODAxYmFkYmUxMDk4OWVmMDMyOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.V1yXQbLW86TMRWTKM4RrvcThoTQVUrgTZ_56_VSukTU	2026-08-27 07:04:42.534875+00	2026-09-03 07:04:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	242cdeb8f60a4801badbe10989ef0329
215	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQxOTA4MiwiaWF0IjoxNzg3ODE0MjgyLCJqdGkiOiJmYTdlNDIxMWMzYjE0MDc1YWI2MWQ4YjNiMjVmZDU0ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0._yCOqCjZL938HhxOUr0V9ZWo2apE8j8jLS3NKLE6QIc	2026-08-27 07:04:42.65381+00	2026-09-03 07:04:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	fa7e4211c3b14075ab61d8b3b25fd54e
216	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQxOTA4MiwiaWF0IjoxNzg3ODE0MjgyLCJqdGkiOiI2NzYzZTMyYmRiOTE0ZjA3ODYwMThkZTE2NGZlNzYyYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.naTUyBJgyAVFyOneQQAtvG45sddzOL1EmI8xOlDqFbE	2026-08-27 07:04:42.668609+00	2026-09-03 07:04:42+00	9a259d21-6303-464d-97fe-23a835dfdc29	6763e32bdb914f0786018de164fe762b
217	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQyODkwMSwiaWF0IjoxNzg3ODI0MTAxLCJqdGkiOiIyNzk0N2Q2OTYwYTA0Mjc3OWZmNzU5MTI2YjdhYTkzOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.l8LfluiuizoB2Y06euq4TiJe8Dq_odY5ObV9Ae7A4e8	2026-08-27 09:48:21.433387+00	2026-09-03 09:48:21+00	9a259d21-6303-464d-97fe-23a835dfdc29	27947d6960a042779ff759126b7aa938
218	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQyODkxMCwiaWF0IjoxNzg3ODI0MTEwLCJqdGkiOiJjZjNhN2YzYTRmNjY0OTZkYTRjNWZkODdjZTNkOWM4OSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.VVuYkSszLUyjhYI-n4amQlPPLAbzm_MnKB_kZICu0LA	2026-08-27 09:48:30.860108+00	2026-09-03 09:48:30+00	9a259d21-6303-464d-97fe-23a835dfdc29	cf3a7f3a4f66496da4c5fd87ce3d9c89
219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODQyOTQ1MiwiaWF0IjoxNzg3ODI0NjUyLCJqdGkiOiIzODNhNmYyZDBmMjU0YjU0OTkyOGZmZWEzMmVlYTRiZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.NPS_AIFaYgra0-VEbFV4uNCNf9JwdWYK0n3riMz6AcY	2026-08-27 09:57:32.891706+00	2026-09-03 09:57:32+00	9a259d21-6303-464d-97fe-23a835dfdc29	383a6f2d0f254b549928ffea32eea4bd
220	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODUxNjQ5MiwiaWF0IjoxNzg3OTExNjkyLCJqdGkiOiJmMTFkNWJjMTA3Yzg0MTQ5OWM2NTBmMGRmYmY2YTk0MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.FApzBJ54DlWys91DgohbfpfjIRli1jLNAwewBw9okBE	2026-08-28 10:08:12.299114+00	2026-09-04 10:08:12+00	9a259d21-6303-464d-97fe-23a835dfdc29	f11d5bc107c841499c650f0dfbf6a943
221	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODYyNTA5NCwiaWF0IjoxNzg4MDIwMjk0LCJqdGkiOiJkZWI4MDExM2Q2Y2E0NTI0YWRhMzMxZDA5ZDRiODhmYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.1DlAyrdSdRHd7bmB9E7xRTJi2mL_JXbBMiLhfycAtuY	2026-08-29 16:18:14.537396+00	2026-09-05 16:18:14+00	9a259d21-6303-464d-97fe-23a835dfdc29	deb80113d6ca4524ada331d09d4b88fc
222	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODYyODU3MSwiaWF0IjoxNzg4MDIzNzcxLCJqdGkiOiIwNTQ2MzU1MjA4ODk0MjBlYTg0NTQ0NzQzNmRmZDczMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ewr9NP08ooHP2pz28wX842U4dTtCtrAkO7ub6n-UvzY	2026-08-29 17:16:11.582298+00	2026-09-05 17:16:11+00	9a259d21-6303-464d-97fe-23a835dfdc29	054635520889420ea845447436dfd730
223	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODY4OTgxNSwiaWF0IjoxNzg4MDg1MDE1LCJqdGkiOiJmM2MxMWUxZWYzOTU0YTY0YWQ1MDgwMGViNjhhNGIxZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.nJgzm5vQ5KDPKwXkkq7uuetryfHqsDFDHkvJc_2A9F8	2026-08-30 10:16:55.071968+00	2026-09-06 10:16:55+00	9a259d21-6303-464d-97fe-23a835dfdc29	f3c11e1ef3954a64ad50800eb68a4b1f
224	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODY4OTgyMiwiaWF0IjoxNzg4MDg1MDIyLCJqdGkiOiJhNDJhYjQ2N2FjNGU0MjJhOGI2YzkzYjhmY2NhZGY3MSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.EVuUT881mCW6tOsk67UvBchg-Mhs-63YqRyTxMzScdk	2026-08-30 10:17:02.324002+00	2026-09-06 10:17:02+00	9a259d21-6303-464d-97fe-23a835dfdc29	a42ab467ac4e422a8b6c93b8fccadf71
225	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODcxNzUwMiwiaWF0IjoxNzg4MTEyNzAyLCJqdGkiOiI0YTE1NGJiZTVjNmI0YmI1OGEwMTA2NDkwNzA5NzMwYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.3jZhkwqTQB5qerV_iuoIYdgCx5nBwGY2f_NyXo3k8vA	2026-08-30 17:58:22.644812+00	2026-09-06 17:58:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	4a154bbe5c6b4bb58a0106490709730c
226	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODcxNzUyMCwiaWF0IjoxNzg4MTEyNzIwLCJqdGkiOiI3NGVhMGRjMjliODI0ZDYyYTllNmZkOGE4NTdhMWJjMSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.9yXTvSydlUO130R01Yk16a8pT7D2B7OV4a6kMRBkD2s	2026-08-30 17:58:40.59242+00	2026-09-06 17:58:40+00	9a259d21-6303-464d-97fe-23a835dfdc29	74ea0dc29b824d62a9e6fd8a857a1bc1
227	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODg1NzEzMCwiaWF0IjoxNzg4MjUyMzMwLCJqdGkiOiJkZjgzZTVmZjY2ZDk0YzNhODI5YTAzYzgyZThmZjRmYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.nMQP1GdJceNPzSDQ-Wz9kCPSjYa1OQG0OHHGX9DZkls	2026-09-01 08:45:30.790517+00	2026-09-08 08:45:30+00	9a259d21-6303-464d-97fe-23a835dfdc29	df83e5ff66d94c3a829a03c82e8ff4fb
228	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODg1NzE1MCwiaWF0IjoxNzg4MjUyMzUwLCJqdGkiOiJlZmU5NzY4OGMxODk0NGM1YWRhNWI5OTJlMTQ2OGJiZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.L0inCclBRPxD_9qo17itfLeTMlGUuXIrwIrC9D7Gj4A	2026-09-01 08:45:50.039921+00	2026-09-08 08:45:50+00	9a259d21-6303-464d-97fe-23a835dfdc29	efe97688c18944c5ada5b992e1468bbe
229	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODg2MjM2OCwiaWF0IjoxNzg4MjU3NTY4LCJqdGkiOiJhY2IyMTYxMTdmODQ0ZWQ3OGEyMTczM2MzM2I4MzE1ZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.TtYdnZFDrQtImt02Th_LFG_TyxlMki7CMB2011k032k	2026-09-01 10:12:48.647603+00	2026-09-08 10:12:48+00	9a259d21-6303-464d-97fe-23a835dfdc29	acb216117f844ed78a21733c33b8315e
230	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODg2MjM5MywiaWF0IjoxNzg4MjU3NTkzLCJqdGkiOiJlYjBlM2IwN2E2M2U0ZjY0OTU3Y2IzZDg5NGYyZTI3MyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.p3oZfJBV79XqKPzg18dBwBRmTCjeKLxUN_6vfhFCSYk	2026-09-01 10:13:13.747563+00	2026-09-08 10:13:13+00	9a259d21-6303-464d-97fe-23a835dfdc29	eb0e3b07a63e4f64957cb3d894f2e273
231	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4ODg4NjY5NywiaWF0IjoxNzg4MjgxODk3LCJqdGkiOiJkZTNlNmQzYTRhNjA0NWI4OGMzZTJjMjI2NWZhMjQxYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.t8MmmAZbebxFG5FNxGXwm_wrknRAZmohUmbXeOO-74w	2026-09-01 16:58:17.779578+00	2026-09-08 16:58:17+00	9a259d21-6303-464d-97fe-23a835dfdc29	de3e6d3a4a6045b88c3e2c2265fa241c
232	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTAyODU0NSwiaWF0IjoxNzg4NDIzNzQ1LCJqdGkiOiIxNzBlNjcyZDBjMDA0MzVlYmNmYjQ4MDk4ZGZiZWU5MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.5egrB-1qJQOCTa__dRKdOEdoRPjkF9B_9LYOJImpv98	2026-09-03 08:22:25.68508+00	2026-09-10 08:22:25+00	9a259d21-6303-464d-97fe-23a835dfdc29	170e672d0c00435ebcfb48098dfbee92
233	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTA1NDIyMiwiaWF0IjoxNzg4NDQ5NDIyLCJqdGkiOiJhNGRhZTBiZDMzNmI0YjZhYmQ5NDFkZTRhZGNlNWYzYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.XsvgJ9ScxUEopqu7PJlWv-B_nbmZhqML9jUyPRiSQb8	2026-09-03 15:30:22.36618+00	2026-09-10 15:30:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	a4dae0bd336b4b6abd941de4adce5f3b
234	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTA1NDYwMSwiaWF0IjoxNzg4NDQ5ODAxLCJqdGkiOiIwZjZhOWUzMjVkNGI0ODY0ODU0YTBjMTc2OWNjNWMyNiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.Blpj3Brb5RYURzmtY7zWPt7368KMGqKZ7kjr_aJ8DDI	2026-09-03 15:36:41.300149+00	2026-09-10 15:36:41+00	9a259d21-6303-464d-97fe-23a835dfdc29	0f6a9e325d4b4864854a0c1769cc5c26
235	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTA1OTU2MCwiaWF0IjoxNzg4NDU0NzYwLCJqdGkiOiI0ODhlYTY4ZjdlYjQ0MGI4YTBjMmUwMGVjNDkyZTc4NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.QIHL8ZM6WQogPHvcBu55jihLK6m8OQoO7-rGwPdBQ_8	2026-09-03 16:59:20.85663+00	2026-09-10 16:59:20+00	9a259d21-6303-464d-97fe-23a835dfdc29	488ea68f7eb440b8a0c2e00ec492e786
236	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTA1OTYyNywiaWF0IjoxNzg4NDU0ODI3LCJqdGkiOiJlZTI5NTNlNjRmMDg0MTI5OGJjZWFhMjg4Y2QwY2IxNyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.EiOmLXMen9RwVjq4LHzHvmZYr4XonBNhlrsxBQi5Kus	2026-09-03 17:00:27.155885+00	2026-09-10 17:00:27+00	9a259d21-6303-464d-97fe-23a835dfdc29	ee2953e64f0841298bceaa288cd0cb17
237	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTE0NTU4MywiaWF0IjoxNzg4NTQwNzgzLCJqdGkiOiI3ZjE1MWRmZGQ3MTU0YTM1YTQ4ZTA2N2E3NjNlMDIwYSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.cNFzd1_v9CMf0y1L457166ZK22NbgmnIN3YxwF4vCik	2026-09-04 16:53:03.874037+00	2026-09-11 16:53:03+00	9a259d21-6303-464d-97fe-23a835dfdc29	7f151dfdd7154a35a48e067a763e020a
238	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTE0NTYwMiwiaWF0IjoxNzg4NTQwODAyLCJqdGkiOiI2OGIxYWI3YTFkZTA0MDVlODJhMmQ1ODlmMzI0NTU3YSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.BLRV9DIk8USW1rPvD73zjUV75ETg_8TDOvVoTf74Txc	2026-09-04 16:53:22.447485+00	2026-09-11 16:53:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	68b1ab7a1de0405e82a2d589f324557a
239	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTE1NDcyNCwiaWF0IjoxNzg4NTQ5OTI0LCJqdGkiOiJkZDk2NjJiYjFhNzc0OGRhYWExNjE3Mzg5ZDcxNjZhOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.GWCSsKzFGfFe5q-B8HBaRiqUXENbsCqJqSN4vunQZFU	2026-09-04 19:25:24.567485+00	2026-09-11 19:25:24+00	9a259d21-6303-464d-97fe-23a835dfdc29	dd9662bb1a7748daaa1617389d7166a9
240	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTIxMTE2MSwiaWF0IjoxNzg4NjA2MzYxLCJqdGkiOiIxYjI0YzdmMWYxNTQ0OWEzODI1NzA4YThlYzczNjhmOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.64ddxLmnIDOg4ZXpN1I0G7knzk2o_JuLtebRIMmkZu8	2026-09-05 11:06:01.315625+00	2026-09-12 11:06:01+00	9a259d21-6303-464d-97fe-23a835dfdc29	1b24c7f1f15449a3825708a8ec7368f9
241	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTMwMTIzMiwiaWF0IjoxNzg4Njk2NDMyLCJqdGkiOiI0YWNkODlkYmIyNGU0NTFmYjUxN2EyODdjNzFjMzVhZSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.HLde5dUoStJq-u5AU5Rh2_8QG2B0jcH7GBvv3JUKMzc	2026-09-06 12:07:12.84665+00	2026-09-13 12:07:12+00	9a259d21-6303-464d-97fe-23a835dfdc29	4acd89dbb24e451fb517a287c71c35ae
242	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTMwMTI1OSwiaWF0IjoxNzg4Njk2NDU5LCJqdGkiOiJkNGZjMWM5MDMzOTM0NTFmYjQ5N2Y1ZGU3MjM5MzU2ZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.JmLiBFuvGKrbJgogQbGJ9WTGuYrJGJ5Uozcruv7NSCE	2026-09-06 12:07:39.895747+00	2026-09-13 12:07:39+00	9a259d21-6303-464d-97fe-23a835dfdc29	d4fc1c903393451fb497f5de7239356d
243	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTMyODk4NywiaWF0IjoxNzg4NzI0MTg3LCJqdGkiOiJiNGM5ZTQ3NDk3NDA0Y2I3OTQ2MTM4ZDFiN2IzNDg2YiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.BhoOMuGMzxHhiDbsq0b6fE8MpirdPaogWaLt9AFSTIg	2026-09-06 19:49:47.45311+00	2026-09-13 19:49:47+00	9a259d21-6303-464d-97fe-23a835dfdc29	b4c9e47497404cb7946138d1b7b3486b
244	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTM3MzM0NCwiaWF0IjoxNzg4NzY4NTQ0LCJqdGkiOiI4MDk0ZWEyZGQ0MDQ0NTU3YTY1MDgwZjQyNWEwMTUzOSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.VbwZCJsak94PSvzlzjEqpYoIAF6ASYnsbCqc0EucaBg	2026-09-07 08:09:04.134875+00	2026-09-14 08:09:04+00	9a259d21-6303-464d-97fe-23a835dfdc29	8094ea2dd4044557a65080f425a01539
245	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTQ1MjE3MywiaWF0IjoxNzg4ODQ3MzczLCJqdGkiOiJhOTIwOGIwMTczMzg0YjczOTM1NTFlMTlkMDk4ZWM4NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.MWBFeBphj09ndIobaM7l0iYL2QUBsHnbX7wDwHo0A7I	2026-09-08 06:02:53.233814+00	2026-09-15 06:02:53+00	9a259d21-6303-464d-97fe-23a835dfdc29	a9208b0173384b7393551e19d098ec86
246	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTQ1MjE3OCwiaWF0IjoxNzg4ODQ3Mzc4LCJqdGkiOiJjNTdkNzhhNDhmNGY0YTExOWY5M2E5YTNhODM5YTYwYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.itSac-spiz4M4fG8I3zgmnG0xLCeXgdRX1ZS3nsvgRk	2026-09-08 06:02:58.58913+00	2026-09-15 06:02:58+00	9a259d21-6303-464d-97fe-23a835dfdc29	c57d78a48f4f4a119f93a9a3a839a60c
247	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTQ1NzgxNywiaWF0IjoxNzg4ODUzMDE3LCJqdGkiOiI0OGQ4ZGViM2RkYWQ0ZTZjOTE1MjE5YjM4MWIyMTA4NiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.j_Lu-OyzkVM3USg_j7nBswYgFxY5-hxjsxsnFi61Q0o	2026-09-08 07:36:57.089873+00	2026-09-15 07:36:57+00	9a259d21-6303-464d-97fe-23a835dfdc29	48d8deb3ddad4e6c915219b381b21086
248	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTc0Mzk2MiwiaWF0IjoxNzg5MTM5MTYyLCJqdGkiOiJmZjViNjAzNGM4MWE0NmY2ODhjMTk1NWQ4ZDQ5NjYxYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.xRU3A8Etd3nMY1Fs2OHJrTT8h7h3aS7OGlxDoXwXmZs	2026-09-11 15:06:02.998159+00	2026-09-18 15:06:02+00	9a259d21-6303-464d-97fe-23a835dfdc29	ff5b6034c81a46f688c1955d8d49661c
249	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTg5MDAyOSwiaWF0IjoxNzg5Mjg1MjI5LCJqdGkiOiIyMzVjODE4MTEzM2Y0ZWM4ODc4Zjc2MDg5YWFmOTI3YyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.lWuxvueeMLJks4TptlJh7eloGksEQ9ZCUxa_390ObKg	2026-09-13 07:40:29.366671+00	2026-09-20 07:40:29+00	9a259d21-6303-464d-97fe-23a835dfdc29	235c8181133f4ec8878f76089aaf927c
250	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc4OTg5MjQ1OSwiaWF0IjoxNzg5Mjg3NjU5LCJqdGkiOiI4NmY0MzdmOTUyNzg0YTdkOWNjODBjY2RhZTkwYzZjZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.0Dfy3cNQ0uwBTvyYk7t9NExpL8zyq5ve55BgQklXLOg	2026-09-13 08:20:59.116263+00	2026-09-20 08:20:59+00	9a259d21-6303-464d-97fe-23a835dfdc29	86f437f952784a7d9cc80ccdae90c6cd
251	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDAyMDQ2OSwiaWF0IjoxNzg5NDE1NjY5LCJqdGkiOiIxZmVmODE4M2ZlMmI0ZTRkYWUyMzZmMjcyNGQxZGU1MCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.fzH_pAYmal7LHJHaxuSS3c8L90Xs64SRk7iG7E6Hlcs	2026-09-14 19:54:29.574705+00	2026-09-21 19:54:29+00	9a259d21-6303-464d-97fe-23a835dfdc29	1fef8183fe2b4e4dae236f2724d1de50
252	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDAyMDUxOCwiaWF0IjoxNzg5NDE1NzE4LCJqdGkiOiJjOTFjNmU0OTY4ODM0OGVmYjRhZDI3NzU2OTEzYzE1MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ki3deSSTBmKyxvNpOqspXlDFoGpCJTLcnQ6nyyhQL8g	2026-09-14 19:55:18.810304+00	2026-09-21 19:55:18+00	9a259d21-6303-464d-97fe-23a835dfdc29	c91c6e49688348efb4ad27756913c152
253	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDA1ODIxOSwiaWF0IjoxNzg5NDUzNDE5LCJqdGkiOiI4OTdkMDc0NDgyMDc0MjQwOWQzODM5MDg3YzQzZmNmZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.RT4qhHYPHOgwGbCpK_qSdpcuwYx2NPjgoH36EyelDbc	2026-09-15 06:23:39.911891+00	2026-09-22 06:23:39+00	9a259d21-6303-464d-97fe-23a835dfdc29	897d0744820742409d3839087c43fcfd
254	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDA3MzQwNCwiaWF0IjoxNzg5NDY4NjA0LCJqdGkiOiI5OTQ4OTU5YTE1OTI0YmJhYTM5Mjg3ZjI1MDhkYjMxNSIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.TCTGvCL-ibrLOXcI-g5swo129UWWDHVnIiYBuHOAbrw	2026-09-15 10:36:44.606214+00	2026-09-22 10:36:44+00	9a259d21-6303-464d-97fe-23a835dfdc29	9948959a15924bbaa39287f2508db315
255	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDQxNzAwOCwiaWF0IjoxNzg5ODEyMjA4LCJqdGkiOiI1YmJlZjEwN2MxMTQ0YjAxYTllZmNhNDI0MjlhOTBlYyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.HzpqBPTBPi9rkS7jSfUR_y3JTedKXVjcTV6CzBhNQss	2026-09-19 10:03:28.901737+00	2026-09-26 10:03:28+00	9a259d21-6303-464d-97fe-23a835dfdc29	5bbef107c1144b01a9efca42429a90ec
256	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDU3MDYwMiwiaWF0IjoxNzg5OTY1ODAyLCJqdGkiOiIzZDk1NDgyMmQ0NDA0YzNmOTUwZGM5NjA3YWRhZWZiZCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.vS7c0ONVYGY1NoTr0i9t6XEV8b07qFefNoY18oV6em0	2026-09-21 04:43:22.537308+00	2026-09-28 04:43:22+00	9a259d21-6303-464d-97fe-23a835dfdc29	3d954822d4404c3f950dc9607adaefbd
257	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDU3MDYwNiwiaWF0IjoxNzg5OTY1ODA2LCJqdGkiOiJhOGJiNTQ4YzdlMzI0MjU2YTc4ZTAxZWQ0ZjgwM2NlOCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.ln4KC1ragfO11CDaLDVwkN0IejaaE1Q4dFqub_a2iWc	2026-09-21 04:43:26.630859+00	2026-09-28 04:43:26+00	9a259d21-6303-464d-97fe-23a835dfdc29	a8bb548c7e324256a78e01ed4f803ce8
258	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDU3ODkxOCwiaWF0IjoxNzg5OTc0MTE4LCJqdGkiOiIwNjc3ZGIwYzQ4Mjc0NzEzOWFjMjliODJmZGYzZDMxZiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.BzTlIebVRP4PO3puLd65ZDeiWiSysvCTYhLyqo5u2Zo	2026-09-21 07:01:58.264365+00	2026-09-28 07:01:58+00	9a259d21-6303-464d-97fe-23a835dfdc29	0677db0c482747139ac29b82fdf3d31f
259	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDU3OTMyNiwiaWF0IjoxNzg5OTc0NTI2LCJqdGkiOiI1MzNiZDQ4MmZlZTA0NGUxODRjYmJjNzZjMWYzOWMzNCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.a6mzoGtel6Kr4FFhYdbOjMojVA4M9REHzY-zg2YKwOw	2026-09-21 07:08:46.843786+00	2026-09-28 07:08:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	533bd482fee044e184cbbc76c1f39c34
260	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDY3MjM4NiwiaWF0IjoxNzkwMDY3NTg2LCJqdGkiOiJmM2RjMjcwY2U1NmQ0MTNjOWFiNmI2M2FlY2NjOGUyMyIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.bej0fSuiNMG4PjzwI905bt4Gvv7V7xY9xrvnG9lG6QI	2026-09-22 08:59:46.637774+00	2026-09-29 08:59:46+00	9a259d21-6303-464d-97fe-23a835dfdc29	f3dc270ce56d413c9ab6b63aeccc8e23
261	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDY3MjQwNiwiaWF0IjoxNzkwMDY3NjA2LCJqdGkiOiI2ZjIxNjk3ZDgwZmU0NDdkODBhZjk3N2QzYTQ4NjI0MiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ._bZ-5Hrp_6J_opFIRKYvtQWdhkEkMUiGJrTCZFze6gk	2026-09-22 09:00:06.665807+00	2026-09-29 09:00:06+00	9a259d21-6303-464d-97fe-23a835dfdc29	6f21697d80fe447d80af977d3a486242
262	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDg1OTgxMiwiaWF0IjoxNzkwMjU1MDEyLCJqdGkiOiJjYmVmZTYyY2JmZTE0OTU1YTA3N2Y4YWU2MDBkMTExYiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.MVeM1LIwQjM7HV2xzIx3uojGh40k3K5Xwps0fSm9JXI	2026-09-24 13:03:32.964339+00	2026-10-01 13:03:32+00	9a259d21-6303-464d-97fe-23a835dfdc29	cbefe62cbfe14955a077f8ae600d111b
263	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MDg1OTgzMiwiaWF0IjoxNzkwMjU1MDMyLCJqdGkiOiI1MmJhMjA3NDlhNDc0MzM5YmRlMWZjNmQ2YzZjMjJjMiIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkifQ.il0ycizLMBB5-rgWZegfC___rFodRg5P-3bVGWBw1ow	2026-09-24 13:03:52.824569+00	2026-10-01 13:03:52+00	9a259d21-6303-464d-97fe-23a835dfdc29	52ba20749a474339bde1fc6d6c6c22c2
264	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc5MTQzMDk0MSwiaWF0IjoxNzkwODI2MTQxLCJqdGkiOiI1MTg2NzYzZGNmNGE0NzMwODg4YWI3NTBiODEyNzkyMCIsInVzZXJfaWQiOiI5YTI1OWQyMS02MzAzLTQ2NGQtOTdmZS0yM2E4MzVkZmRjMjkiLCJyb2xlIjoiYWRtaW4iLCJuYW1lIjoiQWJkdWwgV2FoZWQgTnVyIn0.JvUZKWOWtzYGO7P17hcUeTapDnwpg0IqUl3j0nu8ioc	2026-10-01 03:42:21.378462+00	2026-10-08 03:42:21+00	9a259d21-6303-464d-97fe-23a835dfdc29	5186763dcf4a4730888ab750b8127920
\.


--
-- Name: accounts_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.accounts_user_groups_id_seq', 1, false);


--
-- Name: accounts_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.accounts_user_user_permissions_id_seq', 1, false);


--
-- Name: assets_asset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.assets_asset_id_seq', 3, true);


--
-- Name: assets_assetincident_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.assets_assetincident_id_seq', 1, false);


--
-- Name: audit_auditlog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_auditlog_id_seq', 1308, true);


--
-- Name: audit_auditlogentry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_auditlogentry_id_seq', 458, true);


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 136, true);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.customers_customer_id_seq', 131, true);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 2, true);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 34, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 59, true);


--
-- Name: ecommerce_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ecommerce_order_id_seq', 1, false);


--
-- Name: ecommerce_orderitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ecommerce_orderitem_id_seq', 1, false);


--
-- Name: expenses_expense_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.expenses_expense_id_seq', 28, true);


--
-- Name: invoices_invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_invoice_id_seq', 74, true);


--
-- Name: invoices_invoicemeterentry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_invoicemeterentry_id_seq', 105, true);


--
-- Name: invoices_invoicepayment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_invoicepayment_id_seq', 74, true);


--
-- Name: invoices_invoiceproductline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_invoiceproductline_id_seq', 1, false);


--
-- Name: invoices_invoiceserviceline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invoices_invoiceserviceline_id_seq', 126, true);


--
-- Name: loans_loan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loans_loan_id_seq', 4, true);


--
-- Name: loans_loaninstallmentpayment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loans_loaninstallmentpayment_id_seq', 56, true);


--
-- Name: meters_meter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.meters_meter_id_seq', 43, true);


--
-- Name: meters_mileagecorrectiondevice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.meters_mileagecorrectiondevice_id_seq', 5, true);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_notification_id_seq', 1, false);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_product_id_seq', 19, true);


--
-- Name: products_productrestockevent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_productrestockevent_id_seq', 18, true);


--
-- Name: products_purchase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_purchase_id_seq', 1, false);


--
-- Name: products_purchaselineitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_purchaselineitem_id_seq', 1, false);


--
-- Name: services_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_service_id_seq', 9, true);


--
-- Name: services_servicecategory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_servicecategory_id_seq', 8, true);


--
-- Name: shop_profile_shopprofile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shop_profile_shopprofile_id_seq', 1, false);


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.suppliers_supplier_id_seq', 2, true);


--
-- Name: token_blacklist_blacklistedtoken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.token_blacklist_blacklistedtoken_id_seq', 125, true);


--
-- Name: token_blacklist_outstandingtoken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.token_blacklist_outstandingtoken_id_seq', 264, true);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);


--
-- Name: invitation invitation_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.invitation
    ADD CONSTRAINT invitation_pkey PRIMARY KEY (id);


--
-- Name: jwks jwks_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.jwks
    ADD CONSTRAINT jwks_pkey PRIMARY KEY (id);


--
-- Name: member member_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization organization_slug_key; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.organization
    ADD CONSTRAINT organization_slug_key UNIQUE (slug);


--
-- Name: project_config project_config_endpoint_id_key; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.project_config
    ADD CONSTRAINT project_config_endpoint_id_key UNIQUE (endpoint_id);


--
-- Name: project_config project_config_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.project_config
    ADD CONSTRAINT project_config_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: session session_token_key; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.session
    ADD CONSTRAINT session_token_key UNIQUE (token);


--
-- Name: user user_email_key; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth."user"
    ADD CONSTRAINT user_email_key UNIQUE (email);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: verification verification_pkey; Type: CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.verification
    ADD CONSTRAINT verification_pkey PRIMARY KEY (id);


--
-- Name: accounts_user accounts_user_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user
    ADD CONSTRAINT accounts_user_email_key UNIQUE (email);


--
-- Name: accounts_user_groups accounts_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_groups
    ADD CONSTRAINT accounts_user_groups_pkey PRIMARY KEY (id);


--
-- Name: accounts_user_groups accounts_user_groups_user_id_group_id_59c0b32f_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_groups
    ADD CONSTRAINT accounts_user_groups_user_id_group_id_59c0b32f_uniq UNIQUE (user_id, group_id);


--
-- Name: accounts_user accounts_user_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user
    ADD CONSTRAINT accounts_user_phone_key UNIQUE (phone);


--
-- Name: accounts_user accounts_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user
    ADD CONSTRAINT accounts_user_pkey PRIMARY KEY (id);


--
-- Name: accounts_user_user_permissions accounts_user_user_permi_user_id_permission_id_2ab516c2_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_user_permissions
    ADD CONSTRAINT accounts_user_user_permi_user_id_permission_id_2ab516c2_uniq UNIQUE (user_id, permission_id);


--
-- Name: accounts_user_user_permissions accounts_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_user_permissions
    ADD CONSTRAINT accounts_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: assets_asset assets_asset_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_asset
    ADD CONSTRAINT assets_asset_pkey PRIMARY KEY (id);


--
-- Name: assets_assetincident assets_assetincident_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_assetincident
    ADD CONSTRAINT assets_assetincident_pkey PRIMARY KEY (id);


--
-- Name: audit_auditlog audit_auditlog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlog
    ADD CONSTRAINT audit_auditlog_pkey PRIMARY KEY (id);


--
-- Name: audit_auditlogentry audit_auditlogentry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlogentry
    ADD CONSTRAINT audit_auditlogentry_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: customers_customer customers_customer_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers_customer
    ADD CONSTRAINT customers_customer_phone_key UNIQUE (phone);


--
-- Name: customers_customer customers_customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers_customer
    ADD CONSTRAINT customers_customer_pkey PRIMARY KEY (id);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: ecommerce_order ecommerce_order_order_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_order
    ADD CONSTRAINT ecommerce_order_order_no_key UNIQUE (order_no);


--
-- Name: ecommerce_order ecommerce_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_order
    ADD CONSTRAINT ecommerce_order_pkey PRIMARY KEY (id);


--
-- Name: ecommerce_order ecommerce_order_tracking_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_order
    ADD CONSTRAINT ecommerce_order_tracking_token_key UNIQUE (tracking_token);


--
-- Name: ecommerce_orderitem ecommerce_orderitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_orderitem
    ADD CONSTRAINT ecommerce_orderitem_pkey PRIMARY KEY (id);


--
-- Name: expenses_expense expenses_expense_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses_expense
    ADD CONSTRAINT expenses_expense_pkey PRIMARY KEY (id);


--
-- Name: invoices_invoice invoices_invoice_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoice
    ADD CONSTRAINT invoices_invoice_invoice_no_key UNIQUE (invoice_no);


--
-- Name: invoices_invoice invoices_invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoice
    ADD CONSTRAINT invoices_invoice_pkey PRIMARY KEY (id);


--
-- Name: invoices_invoice invoices_invoice_public_share_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoice
    ADD CONSTRAINT invoices_invoice_public_share_token_key UNIQUE (public_share_token);


--
-- Name: invoices_invoicemeterentry invoices_invoicemeterentry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicemeterentry
    ADD CONSTRAINT invoices_invoicemeterentry_pkey PRIMARY KEY (id);


--
-- Name: invoices_invoicepayment invoices_invoicepayment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicepayment
    ADD CONSTRAINT invoices_invoicepayment_pkey PRIMARY KEY (id);


--
-- Name: invoices_invoiceproductline invoices_invoiceproductline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceproductline
    ADD CONSTRAINT invoices_invoiceproductline_pkey PRIMARY KEY (id);


--
-- Name: invoices_invoiceserviceline invoices_invoiceserviceline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserviceline_pkey PRIMARY KEY (id);


--
-- Name: loans_loan loans_loan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans_loan
    ADD CONSTRAINT loans_loan_pkey PRIMARY KEY (id);


--
-- Name: loans_loaninstallmentpayment loans_loaninstallmentpayment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans_loaninstallmentpayment
    ADD CONSTRAINT loans_loaninstallmentpayment_pkey PRIMARY KEY (id);


--
-- Name: meters_meter meters_meter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meters_meter
    ADD CONSTRAINT meters_meter_pkey PRIMARY KEY (id);


--
-- Name: meters_mileagecorrectiondevice meters_mileagecorrectiondevice_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meters_mileagecorrectiondevice
    ADD CONSTRAINT meters_mileagecorrectiondevice_name_key UNIQUE (name);


--
-- Name: meters_mileagecorrectiondevice meters_mileagecorrectiondevice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meters_mileagecorrectiondevice
    ADD CONSTRAINT meters_mileagecorrectiondevice_pkey PRIMARY KEY (id);


--
-- Name: notifications_notification notifications_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notification_pkey PRIMARY KEY (id);


--
-- Name: products_product products_product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_product
    ADD CONSTRAINT products_product_pkey PRIMARY KEY (id);


--
-- Name: products_product products_product_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_product
    ADD CONSTRAINT products_product_sku_key UNIQUE (sku);


--
-- Name: products_productrestockevent products_productrestockevent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_productrestockevent
    ADD CONSTRAINT products_productrestockevent_pkey PRIMARY KEY (id);


--
-- Name: products_purchase products_purchase_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchase
    ADD CONSTRAINT products_purchase_pkey PRIMARY KEY (id);


--
-- Name: products_purchaselineitem products_purchaselineitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchaselineitem
    ADD CONSTRAINT products_purchaselineitem_pkey PRIMARY KEY (id);


--
-- Name: services_service services_service_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_service
    ADD CONSTRAINT services_service_pkey PRIMARY KEY (id);


--
-- Name: services_servicecategory services_servicecategory_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_servicecategory
    ADD CONSTRAINT services_servicecategory_name_key UNIQUE (name);


--
-- Name: services_servicecategory services_servicecategory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_servicecategory
    ADD CONSTRAINT services_servicecategory_pkey PRIMARY KEY (id);


--
-- Name: shop_profile_shopprofile shop_profile_shopprofile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_profile_shopprofile
    ADD CONSTRAINT shop_profile_shopprofile_pkey PRIMARY KEY (id);


--
-- Name: suppliers_supplier suppliers_supplier_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers_supplier
    ADD CONSTRAINT suppliers_supplier_phone_key UNIQUE (phone);


--
-- Name: suppliers_supplier suppliers_supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers_supplier
    ADD CONSTRAINT suppliers_supplier_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_token_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_token_id_key UNIQUE (token_id);


--
-- Name: token_blacklist_outstandingtoken token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_uniq UNIQUE (jti);


--
-- Name: token_blacklist_outstandingtoken token_blacklist_outstandingtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outstandingtoken_pkey PRIMARY KEY (id);


--
-- Name: account_userId_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX "account_userId_idx" ON neon_auth.account USING btree ("userId");


--
-- Name: invitation_email_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX invitation_email_idx ON neon_auth.invitation USING btree (email);


--
-- Name: invitation_organizationId_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX "invitation_organizationId_idx" ON neon_auth.invitation USING btree ("organizationId");


--
-- Name: member_organizationId_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX "member_organizationId_idx" ON neon_auth.member USING btree ("organizationId");


--
-- Name: member_userId_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX "member_userId_idx" ON neon_auth.member USING btree ("userId");


--
-- Name: organization_slug_uidx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE UNIQUE INDEX organization_slug_uidx ON neon_auth.organization USING btree (slug);


--
-- Name: session_userId_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX "session_userId_idx" ON neon_auth.session USING btree ("userId");


--
-- Name: verification_identifier_idx; Type: INDEX; Schema: neon_auth; Owner: -
--

CREATE INDEX verification_identifier_idx ON neon_auth.verification USING btree (identifier);


--
-- Name: accounts_user_created_by_id_ba68b522; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_created_by_id_ba68b522 ON public.accounts_user USING btree (created_by_id);


--
-- Name: accounts_user_email_b2644a56_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_email_b2644a56_like ON public.accounts_user USING btree (email varchar_pattern_ops);


--
-- Name: accounts_user_groups_group_id_bd11a704; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_groups_group_id_bd11a704 ON public.accounts_user_groups USING btree (group_id);


--
-- Name: accounts_user_groups_user_id_52b62117; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_groups_user_id_52b62117 ON public.accounts_user_groups USING btree (user_id);


--
-- Name: accounts_user_phone_c603acdd_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_phone_c603acdd_like ON public.accounts_user USING btree (phone varchar_pattern_ops);


--
-- Name: accounts_user_user_permissions_permission_id_113bb443; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_user_permissions_permission_id_113bb443 ON public.accounts_user_user_permissions USING btree (permission_id);


--
-- Name: accounts_user_user_permissions_user_id_e4f0a161; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_user_user_permissions_user_id_e4f0a161 ON public.accounts_user_user_permissions USING btree (user_id);


--
-- Name: assets_asset_created_by_id_4d70f031; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_asset_created_by_id_4d70f031 ON public.assets_asset USING btree (created_by_id);


--
-- Name: assets_asset_supplier_id_f96f177e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_asset_supplier_id_f96f177e ON public.assets_asset USING btree (supplier_id);


--
-- Name: assets_assetincident_asset_id_25212a3d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_assetincident_asset_id_25212a3d ON public.assets_assetincident USING btree (asset_id);


--
-- Name: assets_assetincident_created_by_id_a29d683b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_assetincident_created_by_id_a29d683b ON public.assets_assetincident USING btree (created_by_id);


--
-- Name: audit_audit_content_4c2ead_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_audit_content_4c2ead_idx ON public.audit_auditlog USING btree (content_type_id, object_id);


--
-- Name: audit_audit_content_82c7f9_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_audit_content_82c7f9_idx ON public.audit_auditlogentry USING btree (content_type_id, object_id);


--
-- Name: audit_auditlog_content_type_id_61188c00; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_auditlog_content_type_id_61188c00 ON public.audit_auditlog USING btree (content_type_id);


--
-- Name: audit_auditlog_created_by_id_fd11b280; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_auditlog_created_by_id_fd11b280 ON public.audit_auditlog USING btree (created_by_id);


--
-- Name: audit_auditlogentry_content_type_id_327d6926; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_auditlogentry_content_type_id_327d6926 ON public.audit_auditlogentry USING btree (content_type_id);


--
-- Name: audit_auditlogentry_created_by_id_be378cba; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_auditlogentry_created_by_id_be378cba ON public.audit_auditlogentry USING btree (created_by_id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: customers_customer_created_by_id_e3e9e010; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customers_customer_created_by_id_e3e9e010 ON public.customers_customer USING btree (created_by_id);


--
-- Name: customers_customer_phone_01182399_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customers_customer_phone_01182399_like ON public.customers_customer USING btree (phone varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: ecommerce_order_created_by_id_a23ae917; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_order_created_by_id_a23ae917 ON public.ecommerce_order USING btree (created_by_id);


--
-- Name: ecommerce_order_order_no_fbcda28c_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_order_order_no_fbcda28c_like ON public.ecommerce_order USING btree (order_no varchar_pattern_ops);


--
-- Name: ecommerce_order_tracking_token_ba15320a_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_order_tracking_token_ba15320a_like ON public.ecommerce_order USING btree (tracking_token varchar_pattern_ops);


--
-- Name: ecommerce_orderitem_created_by_id_fa4d9c2e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_orderitem_created_by_id_fa4d9c2e ON public.ecommerce_orderitem USING btree (created_by_id);


--
-- Name: ecommerce_orderitem_order_id_626b0534; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_orderitem_order_id_626b0534 ON public.ecommerce_orderitem USING btree (order_id);


--
-- Name: ecommerce_orderitem_product_id_c2e62996; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ecommerce_orderitem_product_id_c2e62996 ON public.ecommerce_orderitem USING btree (product_id);


--
-- Name: expenses_expense_created_by_id_a2610358; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenses_expense_created_by_id_a2610358 ON public.expenses_expense USING btree (created_by_id);


--
-- Name: invoices_invoice_created_by_id_9b878bcd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoice_created_by_id_9b878bcd ON public.invoices_invoice USING btree (created_by_id);


--
-- Name: invoices_invoice_customer_id_137e7301; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoice_customer_id_137e7301 ON public.invoices_invoice USING btree (customer_id);


--
-- Name: invoices_invoice_invoice_no_2c7f0cce_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoice_invoice_no_2c7f0cce_like ON public.invoices_invoice USING btree (invoice_no varchar_pattern_ops);


--
-- Name: invoices_invoice_public_share_token_b0a7bd32_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoice_public_share_token_b0a7bd32_like ON public.invoices_invoice USING btree (public_share_token varchar_pattern_ops);


--
-- Name: invoices_invoicemeterentry_created_by_id_19716a61; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicemeterentry_created_by_id_19716a61 ON public.invoices_invoicemeterentry USING btree (created_by_id);


--
-- Name: invoices_invoicemeterentry_invoice_id_abedc8c0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicemeterentry_invoice_id_abedc8c0 ON public.invoices_invoicemeterentry USING btree (invoice_id);


--
-- Name: invoices_invoicemeterentry_meter_id_f4bdbfa9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicemeterentry_meter_id_f4bdbfa9 ON public.invoices_invoicemeterentry USING btree (meter_id);


--
-- Name: invoices_invoicemeterentry_mileage_correction_device__3e9542ba; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicemeterentry_mileage_correction_device__3e9542ba ON public.invoices_invoicemeterentry USING btree (mileage_correction_device_id);


--
-- Name: invoices_invoicepayment_created_by_id_ecbc3972; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicepayment_created_by_id_ecbc3972 ON public.invoices_invoicepayment USING btree (created_by_id);


--
-- Name: invoices_invoicepayment_invoice_id_2cade89c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoicepayment_invoice_id_2cade89c ON public.invoices_invoicepayment USING btree (invoice_id);


--
-- Name: invoices_invoiceproductline_created_by_id_9a008ed8; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceproductline_created_by_id_9a008ed8 ON public.invoices_invoiceproductline USING btree (created_by_id);


--
-- Name: invoices_invoiceproductline_invoice_id_2818d8e7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceproductline_invoice_id_2818d8e7 ON public.invoices_invoiceproductline USING btree (invoice_id);


--
-- Name: invoices_invoiceproductline_product_id_dcf47530; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceproductline_product_id_dcf47530 ON public.invoices_invoiceproductline USING btree (product_id);


--
-- Name: invoices_invoiceserviceline_asset_used_id_3233d4ba; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_asset_used_id_3233d4ba ON public.invoices_invoiceserviceline USING btree (asset_used_id);


--
-- Name: invoices_invoiceserviceline_created_by_id_f1f9b1c2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_created_by_id_f1f9b1c2 ON public.invoices_invoiceserviceline USING btree (created_by_id);


--
-- Name: invoices_invoiceserviceline_invoice_id_648fca08; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_invoice_id_648fca08 ON public.invoices_invoiceserviceline USING btree (invoice_id);


--
-- Name: invoices_invoiceserviceline_meter_entry_id_529992cd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_meter_entry_id_529992cd ON public.invoices_invoiceserviceline USING btree (meter_entry_id);


--
-- Name: invoices_invoiceserviceline_product_used_id_fd91376c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_product_used_id_fd91376c ON public.invoices_invoiceserviceline USING btree (product_used_id);


--
-- Name: invoices_invoiceserviceline_service_id_9098728a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoices_invoiceserviceline_service_id_9098728a ON public.invoices_invoiceserviceline USING btree (service_id);


--
-- Name: loans_loan_created_by_id_cbe2b2ae; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX loans_loan_created_by_id_cbe2b2ae ON public.loans_loan USING btree (created_by_id);


--
-- Name: loans_loaninstallmentpayment_created_by_id_8672469e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX loans_loaninstallmentpayment_created_by_id_8672469e ON public.loans_loaninstallmentpayment USING btree (created_by_id);


--
-- Name: loans_loaninstallmentpayment_loan_id_ee7a8058; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX loans_loaninstallmentpayment_loan_id_ee7a8058 ON public.loans_loaninstallmentpayment USING btree (loan_id);


--
-- Name: meters_meter_created_by_id_da2f68be; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meters_meter_created_by_id_da2f68be ON public.meters_meter USING btree (created_by_id);


--
-- Name: meters_mileagecorrectiondevice_created_by_id_7906ba0f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meters_mileagecorrectiondevice_created_by_id_7906ba0f ON public.meters_mileagecorrectiondevice USING btree (created_by_id);


--
-- Name: meters_mileagecorrectiondevice_name_b4e59cc2_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meters_mileagecorrectiondevice_name_b4e59cc2_like ON public.meters_mileagecorrectiondevice USING btree (name varchar_pattern_ops);


--
-- Name: notificatio_content_702c56_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notificatio_content_702c56_idx ON public.notifications_notification USING btree (content_type_id, object_id);


--
-- Name: notifications_notification_content_type_id_74ab3a2c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_content_type_id_74ab3a2c ON public.notifications_notification USING btree (content_type_id);


--
-- Name: notifications_notification_created_by_id_44297423; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_created_by_id_44297423 ON public.notifications_notification USING btree (created_by_id);


--
-- Name: products_product_created_by_id_dd4af40e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_product_created_by_id_dd4af40e ON public.products_product USING btree (created_by_id);


--
-- Name: products_product_sku_3c51a516_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_product_sku_3c51a516_like ON public.products_product USING btree (sku varchar_pattern_ops);


--
-- Name: products_product_supplier_id_b9ff64a9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_product_supplier_id_b9ff64a9 ON public.products_product USING btree (supplier_id);


--
-- Name: products_productrestockevent_created_by_id_96476097; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_productrestockevent_created_by_id_96476097 ON public.products_productrestockevent USING btree (created_by_id);


--
-- Name: products_productrestockevent_product_id_276e55f6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_productrestockevent_product_id_276e55f6 ON public.products_productrestockevent USING btree (product_id);


--
-- Name: products_purchase_created_by_id_cca9c788; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_purchase_created_by_id_cca9c788 ON public.products_purchase USING btree (created_by_id);


--
-- Name: products_purchase_supplier_id_74c65336; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_purchase_supplier_id_74c65336 ON public.products_purchase USING btree (supplier_id);


--
-- Name: products_purchaselineitem_created_by_id_b6f65391; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_purchaselineitem_created_by_id_b6f65391 ON public.products_purchaselineitem USING btree (created_by_id);


--
-- Name: products_purchaselineitem_product_id_c71fcd5b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_purchaselineitem_product_id_c71fcd5b ON public.products_purchaselineitem USING btree (product_id);


--
-- Name: products_purchaselineitem_purchase_id_6de933c7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_purchaselineitem_purchase_id_6de933c7 ON public.products_purchaselineitem USING btree (purchase_id);


--
-- Name: services_service_category_id_e15f8b7e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_service_category_id_e15f8b7e ON public.services_service USING btree (category_id);


--
-- Name: services_service_created_by_id_d0083628; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_service_created_by_id_d0083628 ON public.services_service USING btree (created_by_id);


--
-- Name: services_servicecategory_created_by_id_e7ef1e9c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_servicecategory_created_by_id_e7ef1e9c ON public.services_servicecategory USING btree (created_by_id);


--
-- Name: services_servicecategory_name_ad9afa2a_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_servicecategory_name_ad9afa2a_like ON public.services_servicecategory USING btree (name varchar_pattern_ops);


--
-- Name: shop_profile_shopprofile_created_by_id_6c7d0676; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shop_profile_shopprofile_created_by_id_6c7d0676 ON public.shop_profile_shopprofile USING btree (created_by_id);


--
-- Name: suppliers_supplier_created_by_id_6d4c0d43; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppliers_supplier_created_by_id_6d4c0d43 ON public.suppliers_supplier USING btree (created_by_id);


--
-- Name: suppliers_supplier_phone_e4d29be1_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppliers_supplier_phone_e4d29be1_like ON public.suppliers_supplier USING btree (phone varchar_pattern_ops);


--
-- Name: token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_like ON public.token_blacklist_outstandingtoken USING btree (jti varchar_pattern_ops);


--
-- Name: token_blacklist_outstandingtoken_user_id_83bc629a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_blacklist_outstandingtoken_user_id_83bc629a ON public.token_blacklist_outstandingtoken USING btree (user_id);


--
-- Name: account account_userId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.account
    ADD CONSTRAINT "account_userId_fkey" FOREIGN KEY ("userId") REFERENCES neon_auth."user"(id) ON DELETE CASCADE;


--
-- Name: invitation invitation_inviterId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.invitation
    ADD CONSTRAINT "invitation_inviterId_fkey" FOREIGN KEY ("inviterId") REFERENCES neon_auth."user"(id) ON DELETE CASCADE;


--
-- Name: invitation invitation_organizationId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.invitation
    ADD CONSTRAINT "invitation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES neon_auth.organization(id) ON DELETE CASCADE;


--
-- Name: member member_organizationId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.member
    ADD CONSTRAINT "member_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES neon_auth.organization(id) ON DELETE CASCADE;


--
-- Name: member member_userId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.member
    ADD CONSTRAINT "member_userId_fkey" FOREIGN KEY ("userId") REFERENCES neon_auth."user"(id) ON DELETE CASCADE;


--
-- Name: session session_userId_fkey; Type: FK CONSTRAINT; Schema: neon_auth; Owner: -
--

ALTER TABLE ONLY neon_auth.session
    ADD CONSTRAINT "session_userId_fkey" FOREIGN KEY ("userId") REFERENCES neon_auth."user"(id) ON DELETE CASCADE;


--
-- Name: accounts_user accounts_user_created_by_id_ba68b522_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user
    ADD CONSTRAINT accounts_user_created_by_id_ba68b522_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_user_groups accounts_user_groups_group_id_bd11a704_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_groups
    ADD CONSTRAINT accounts_user_groups_group_id_bd11a704_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_user_groups accounts_user_groups_user_id_52b62117_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_groups
    ADD CONSTRAINT accounts_user_groups_user_id_52b62117_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_user_user_permissions accounts_user_user_p_permission_id_113bb443_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_user_permissions
    ADD CONSTRAINT accounts_user_user_p_permission_id_113bb443_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_user_user_permissions accounts_user_user_p_user_id_e4f0a161_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_user_user_permissions
    ADD CONSTRAINT accounts_user_user_p_user_id_e4f0a161_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: assets_asset assets_asset_created_by_id_4d70f031_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_asset
    ADD CONSTRAINT assets_asset_created_by_id_4d70f031_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: assets_asset assets_asset_supplier_id_f96f177e_fk_suppliers_supplier_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_asset
    ADD CONSTRAINT assets_asset_supplier_id_f96f177e_fk_suppliers_supplier_id FOREIGN KEY (supplier_id) REFERENCES public.suppliers_supplier(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: assets_assetincident assets_assetincident_asset_id_25212a3d_fk_assets_asset_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_assetincident
    ADD CONSTRAINT assets_assetincident_asset_id_25212a3d_fk_assets_asset_id FOREIGN KEY (asset_id) REFERENCES public.assets_asset(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: assets_assetincident assets_assetincident_created_by_id_a29d683b_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets_assetincident
    ADD CONSTRAINT assets_assetincident_created_by_id_a29d683b_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: audit_auditlog audit_auditlog_content_type_id_61188c00_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlog
    ADD CONSTRAINT audit_auditlog_content_type_id_61188c00_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: audit_auditlog audit_auditlog_created_by_id_fd11b280_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlog
    ADD CONSTRAINT audit_auditlog_created_by_id_fd11b280_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: audit_auditlogentry audit_auditlogentry_content_type_id_327d6926_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlogentry
    ADD CONSTRAINT audit_auditlogentry_content_type_id_327d6926_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: audit_auditlogentry audit_auditlogentry_created_by_id_be378cba_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_auditlogentry
    ADD CONSTRAINT audit_auditlogentry_created_by_id_be378cba_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: customers_customer customers_customer_created_by_id_e3e9e010_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers_customer
    ADD CONSTRAINT customers_customer_created_by_id_e3e9e010_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_accounts_user_id FOREIGN KEY (user_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ecommerce_order ecommerce_order_created_by_id_a23ae917_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_order
    ADD CONSTRAINT ecommerce_order_created_by_id_a23ae917_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ecommerce_orderitem ecommerce_orderitem_created_by_id_fa4d9c2e_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_orderitem
    ADD CONSTRAINT ecommerce_orderitem_created_by_id_fa4d9c2e_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ecommerce_orderitem ecommerce_orderitem_order_id_626b0534_fk_ecommerce_order_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_orderitem
    ADD CONSTRAINT ecommerce_orderitem_order_id_626b0534_fk_ecommerce_order_id FOREIGN KEY (order_id) REFERENCES public.ecommerce_order(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ecommerce_orderitem ecommerce_orderitem_product_id_c2e62996_fk_products_product_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_orderitem
    ADD CONSTRAINT ecommerce_orderitem_product_id_c2e62996_fk_products_product_id FOREIGN KEY (product_id) REFERENCES public.products_product(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: expenses_expense expenses_expense_created_by_id_a2610358_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses_expense
    ADD CONSTRAINT expenses_expense_created_by_id_a2610358_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoice invoices_invoice_created_by_id_9b878bcd_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoice
    ADD CONSTRAINT invoices_invoice_created_by_id_9b878bcd_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoice invoices_invoice_customer_id_137e7301_fk_customers_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoice
    ADD CONSTRAINT invoices_invoice_customer_id_137e7301_fk_customers_customer_id FOREIGN KEY (customer_id) REFERENCES public.customers_customer(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicemeterentry invoices_invoicemete_created_by_id_19716a61_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicemeterentry
    ADD CONSTRAINT invoices_invoicemete_created_by_id_19716a61_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicemeterentry invoices_invoicemete_invoice_id_abedc8c0_fk_invoices_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicemeterentry
    ADD CONSTRAINT invoices_invoicemete_invoice_id_abedc8c0_fk_invoices_ FOREIGN KEY (invoice_id) REFERENCES public.invoices_invoice(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicemeterentry invoices_invoicemete_mileage_correction_d_3e9542ba_fk_meters_mi; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicemeterentry
    ADD CONSTRAINT invoices_invoicemete_mileage_correction_d_3e9542ba_fk_meters_mi FOREIGN KEY (mileage_correction_device_id) REFERENCES public.meters_mileagecorrectiondevice(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicemeterentry invoices_invoicemeterentry_meter_id_f4bdbfa9_fk_meters_meter_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicemeterentry
    ADD CONSTRAINT invoices_invoicemeterentry_meter_id_f4bdbfa9_fk_meters_meter_id FOREIGN KEY (meter_id) REFERENCES public.meters_meter(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicepayment invoices_invoicepaym_created_by_id_ecbc3972_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicepayment
    ADD CONSTRAINT invoices_invoicepaym_created_by_id_ecbc3972_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoicepayment invoices_invoicepaym_invoice_id_2cade89c_fk_invoices_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoicepayment
    ADD CONSTRAINT invoices_invoicepaym_invoice_id_2cade89c_fk_invoices_ FOREIGN KEY (invoice_id) REFERENCES public.invoices_invoice(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceproductline invoices_invoiceprod_created_by_id_9a008ed8_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceproductline
    ADD CONSTRAINT invoices_invoiceprod_created_by_id_9a008ed8_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceproductline invoices_invoiceprod_invoice_id_2818d8e7_fk_invoices_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceproductline
    ADD CONSTRAINT invoices_invoiceprod_invoice_id_2818d8e7_fk_invoices_ FOREIGN KEY (invoice_id) REFERENCES public.invoices_invoice(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceproductline invoices_invoiceprod_product_id_dcf47530_fk_products_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceproductline
    ADD CONSTRAINT invoices_invoiceprod_product_id_dcf47530_fk_products_ FOREIGN KEY (product_id) REFERENCES public.products_product(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_asset_used_id_3233d4ba_fk_assets_as; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_asset_used_id_3233d4ba_fk_assets_as FOREIGN KEY (asset_used_id) REFERENCES public.assets_asset(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_created_by_id_f1f9b1c2_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_created_by_id_f1f9b1c2_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_invoice_id_648fca08_fk_invoices_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_invoice_id_648fca08_fk_invoices_ FOREIGN KEY (invoice_id) REFERENCES public.invoices_invoice(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_meter_entry_id_529992cd_fk_invoices_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_meter_entry_id_529992cd_fk_invoices_ FOREIGN KEY (meter_entry_id) REFERENCES public.invoices_invoicemeterentry(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_product_used_id_fd91376c_fk_products_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_product_used_id_fd91376c_fk_products_ FOREIGN KEY (product_used_id) REFERENCES public.products_product(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: invoices_invoiceserviceline invoices_invoiceserv_service_id_9098728a_fk_services_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices_invoiceserviceline
    ADD CONSTRAINT invoices_invoiceserv_service_id_9098728a_fk_services_ FOREIGN KEY (service_id) REFERENCES public.services_service(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: loans_loan loans_loan_created_by_id_cbe2b2ae_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans_loan
    ADD CONSTRAINT loans_loan_created_by_id_cbe2b2ae_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: loans_loaninstallmentpayment loans_loaninstallmen_created_by_id_8672469e_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans_loaninstallmentpayment
    ADD CONSTRAINT loans_loaninstallmen_created_by_id_8672469e_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: loans_loaninstallmentpayment loans_loaninstallmentpayment_loan_id_ee7a8058_fk_loans_loan_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans_loaninstallmentpayment
    ADD CONSTRAINT loans_loaninstallmentpayment_loan_id_ee7a8058_fk_loans_loan_id FOREIGN KEY (loan_id) REFERENCES public.loans_loan(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: meters_meter meters_meter_created_by_id_da2f68be_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meters_meter
    ADD CONSTRAINT meters_meter_created_by_id_da2f68be_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: meters_mileagecorrectiondevice meters_mileagecorrec_created_by_id_7906ba0f_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meters_mileagecorrectiondevice
    ADD CONSTRAINT meters_mileagecorrec_created_by_id_7906ba0f_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_content_type_id_74ab3a2c_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_content_type_id_74ab3a2c_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_created_by_id_44297423_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_created_by_id_44297423_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_product products_product_created_by_id_dd4af40e_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_product
    ADD CONSTRAINT products_product_created_by_id_dd4af40e_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_product products_product_supplier_id_b9ff64a9_fk_suppliers_supplier_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_product
    ADD CONSTRAINT products_product_supplier_id_b9ff64a9_fk_suppliers_supplier_id FOREIGN KEY (supplier_id) REFERENCES public.suppliers_supplier(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_productrestockevent products_productrest_created_by_id_96476097_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_productrestockevent
    ADD CONSTRAINT products_productrest_created_by_id_96476097_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_productrestockevent products_productrest_product_id_276e55f6_fk_products_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_productrestockevent
    ADD CONSTRAINT products_productrest_product_id_276e55f6_fk_products_ FOREIGN KEY (product_id) REFERENCES public.products_product(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_purchase products_purchase_created_by_id_cca9c788_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchase
    ADD CONSTRAINT products_purchase_created_by_id_cca9c788_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_purchase products_purchase_supplier_id_74c65336_fk_suppliers_supplier_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchase
    ADD CONSTRAINT products_purchase_supplier_id_74c65336_fk_suppliers_supplier_id FOREIGN KEY (supplier_id) REFERENCES public.suppliers_supplier(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_purchaselineitem products_purchaselin_created_by_id_b6f65391_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchaselineitem
    ADD CONSTRAINT products_purchaselin_created_by_id_b6f65391_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_purchaselineitem products_purchaselin_product_id_c71fcd5b_fk_products_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchaselineitem
    ADD CONSTRAINT products_purchaselin_product_id_c71fcd5b_fk_products_ FOREIGN KEY (product_id) REFERENCES public.products_product(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: products_purchaselineitem products_purchaselin_purchase_id_6de933c7_fk_products_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_purchaselineitem
    ADD CONSTRAINT products_purchaselin_purchase_id_6de933c7_fk_products_ FOREIGN KEY (purchase_id) REFERENCES public.products_purchase(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: services_service services_service_category_id_e15f8b7e_fk_services_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_service
    ADD CONSTRAINT services_service_category_id_e15f8b7e_fk_services_ FOREIGN KEY (category_id) REFERENCES public.services_servicecategory(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: services_service services_service_created_by_id_d0083628_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_service
    ADD CONSTRAINT services_service_created_by_id_d0083628_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: services_servicecategory services_servicecate_created_by_id_e7ef1e9c_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services_servicecategory
    ADD CONSTRAINT services_servicecate_created_by_id_e7ef1e9c_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: shop_profile_shopprofile shop_profile_shoppro_created_by_id_6c7d0676_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_profile_shopprofile
    ADD CONSTRAINT shop_profile_shoppro_created_by_id_6c7d0676_fk_accounts_ FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: suppliers_supplier suppliers_supplier_created_by_id_6d4c0d43_fk_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers_supplier
    ADD CONSTRAINT suppliers_supplier_created_by_id_6d4c0d43_fk_accounts_user_id FOREIGN KEY (created_by_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_token_id_3cc7fe56_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_token_id_3cc7fe56_fk FOREIGN KEY (token_id) REFERENCES public.token_blacklist_outstandingtoken(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: token_blacklist_outstandingtoken token_blacklist_outs_user_id_83bc629a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outs_user_id_83bc629a_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

\unrestrict dsxIodPy6USXZGi0UBOLR6nl8u9YaR3SKeY7RsHj3AAcp97h34yrlJCMUdz8bUl

