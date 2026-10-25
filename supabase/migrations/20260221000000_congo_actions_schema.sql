-- ============================================================================
-- CONGO ACTIONS PLATFORM: PRODUCTION POSTGRESQL & DOUBLE-ENTRY LEDGER SCHEMA
-- Target: Supabase / PostgreSQL 16+
-- Currencies: USD (stored as integer cents), CDF (stored as integer whole units)
-- ============================================================================

-- 1. ENUMS & EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE user_role AS ENUM ('DONOR', 'NGO_ADMIN', 'SUPERADMIN');
CREATE TYPE verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');
CREATE TYPE doc_type AS ENUM ('ARRETE_MINISTERIEL', 'F92', 'NOTARIZED_STATUTES', 'DIRECTOR_ID');
CREATE TYPE doc_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE campaign_category AS ENUM ('HEALTH', 'EDUCATION', 'CHILDREN', 'EMERGENCY', 'INFRASTRUCTURE');
CREATE TYPE campaign_status AS ENUM ('ACTIVE', 'PAUSED', 'COMPLETED');
CREATE TYPE account_type AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE');
CREATE TYPE transaction_type AS ENUM ('DONATION_ONE_TIME', 'DONATION_SUBSCRIPTION', 'POOL_SPLIT_DISTRIBUTION', 'NGO_PAYOUT', 'FEE_DEDUCTION');
CREATE TYPE ledger_status AS ENUM ('PENDING', 'POSTED', 'VOID');
CREATE TYPE payment_method_type AS ENUM ('MPESA', 'ORANGE_MONEY', 'AIRTEL_MONEY', 'AFRIMONEY', 'CARD_STRIPE', 'CARD_FLUTTERWAVE');
CREATE TYPE donation_status AS ENUM ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED');
CREATE TYPE subscription_rail AS ENUM ('CARD_AUTO_DEBIT', 'MOBILE_MONEY_PLEDGE');
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'PAUSED', 'CANCELLED');
CREATE TYPE payout_destination AS ENUM ('BANK_RIB', 'MOBILE_MONEY');
CREATE TYPE payout_status AS ENUM ('REQUESTED', 'APPROVED', 'PROCESSING', 'COMPLETED', 'REJECTED');

-- ============================================================================
-- 2. USER PROFILES & AUTH EXTENSION
-- ============================================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    role user_role NOT NULL DEFAULT 'DONOR',
    avatar_url TEXT,
    preferred_currency VARCHAR(3) NOT NULL DEFAULT 'USD' CHECK (preferred_currency IN ('USD', 'CDF')),
    whatsapp_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. ORGANIZATIONS (NGOS) & VERIFICATION
-- ============================================================================
CREATE TABLE public.ngos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    legal_registration_number VARCHAR(128) NOT NULL UNIQUE, -- e.g. Arrêté Ministériel N° 045/CAB/MIN/J&DH/2021
    mission_statement TEXT NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(32) NOT NULL,
    website_url TEXT,
    verification_status verification_status NOT NULL DEFAULT 'PENDING',
    verified_at TIMESTAMPTZ,
    bank_name VARCHAR(128),
    bank_rib VARCHAR(64), -- Relevé d'Identité Bancaire (e.g. Rawbank or Equity BCDC)
    mobile_money_merchant_name VARCHAR(64),
    mobile_money_merchant_number VARCHAR(32),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- NGO KYC Compliance Documents
CREATE TABLE public.kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ngo_id UUID NOT NULL REFERENCES public.ngos(id) ON DELETE CASCADE,
    document_type doc_type NOT NULL,
    file_path TEXT NOT NULL, -- Supabase Storage key in bucket 'ngo-documents'
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(64) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    status doc_status NOT NULL DEFAULT 'PENDING',
    reviewer_notes TEXT,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES public.profiles(id)
);

-- ============================================================================
-- 4. CAMPAIGNS & POOLED REDISTRIBUTION FUNDS
-- ============================================================================
CREATE TABLE public.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ngo_id UUID REFERENCES public.ngos(id) ON DELETE RESTRICT, -- NULL if multi-NGO platform pooled fund
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    description TEXT NOT NULL,
    category campaign_category NOT NULL DEFAULT 'HEALTH',
    is_pooled_fund BOOLEAN NOT NULL DEFAULT FALSE,
    target_amount_usd_cents BIGINT NOT NULL DEFAULT 0,
    raised_amount_usd_cents BIGINT NOT NULL DEFAULT 0,
    target_amount_cdf BIGINT NOT NULL DEFAULT 0,
    raised_amount_cdf BIGINT NOT NULL DEFAULT 0,
    image_url TEXT NOT NULL,
    status campaign_status NOT NULL DEFAULT 'ACTIVE',
    location VARCHAR(128) NOT NULL DEFAULT 'Kinshasa, DRC',
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Split rules for pooled redistribution causes
CREATE TABLE public.campaign_splits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    ngo_id UUID NOT NULL REFERENCES public.ngos(id) ON DELETE RESTRICT,
    split_percentage NUMERIC(5, 2) NOT NULL CHECK (split_percentage > 0 AND split_percentage <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(campaign_id, ngo_id)
);

-- ============================================================================
-- 5. IMMUTABLE DOUBLE-ENTRY FINANCIAL LEDGER
-- ============================================================================
-- Chart of Accounts
CREATE TABLE public.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(64) NOT NULL UNIQUE, -- e.g. '1010_USD_CLEARING', '2010_NGO_PAYABLE_USD'
    name VARCHAR(128) NOT NULL,
    type account_type NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'CDF')),
    ngo_id UUID REFERENCES public.ngos(id) ON DELETE RESTRICT, -- NULL for platform central accounts
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ledger Transactions (The journal header)
CREATE TABLE public.ledger_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_reference VARCHAR(128) NOT NULL UNIQUE, -- Idempotency key from payment gateway
    description TEXT NOT NULL,
    transaction_type transaction_type NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'CDF')),
    status ledger_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    posted_at TIMESTAMPTZ
);

-- Ledger Entries (Debit & Credit debited atomically)
CREATE TABLE public.ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES public.ledger_transactions(id) ON DELETE RESTRICT,
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    debit_amount BIGINT NOT NULL DEFAULT 0,
    credit_amount BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_positive_amounts CHECK (debit_amount >= 0 AND credit_amount >= 0),
    CONSTRAINT chk_at_least_one_side CHECK (debit_amount > 0 OR credit_amount > 0),
    CONSTRAINT chk_not_both_sides CHECK (NOT (debit_amount > 0 AND credit_amount > 0))
);

CREATE INDEX idx_ledger_entries_tx ON public.ledger_entries(transaction_id);
CREATE INDEX idx_ledger_entries_account ON public.ledger_entries(account_id);

-- Enforce zero-balance double entry invariant upon POSTING
CREATE OR REPLACE FUNCTION public.verify_ledger_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_total_debit BIGINT;
    v_total_credit BIGINT;
BEGIN
    IF NEW.status = 'POSTED' AND OLD.status != 'POSTED' THEN
        SELECT COALESCE(SUM(debit_amount), 0), COALESCE(SUM(credit_amount), 0)
        INTO v_total_debit, v_total_credit
        FROM public.ledger_entries
        WHERE transaction_id = NEW.id;

        IF v_total_debit = 0 OR v_total_debit <> v_total_credit THEN
            RAISE EXCEPTION 'Double-entry balance violation: Transaction % has Total Debit = %, Total Credit = %',
                NEW.id, v_total_debit, v_total_credit;
        END IF;

        NEW.posted_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verify_ledger_balance
BEFORE UPDATE ON public.ledger_transactions
FOR EACH ROW EXECUTE FUNCTION public.verify_ledger_balance();

-- ============================================================================
-- 6. DONATIONS & RECURRING SUBSCRIPTIONS
-- ============================================================================
CREATE TABLE public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES public.ledger_transactions(id) ON DELETE SET NULL,
    donor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE RESTRICT,
    amount_usd_cents BIGINT NOT NULL DEFAULT 0,
    amount_cdf BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'CDF')),
    fee_covered_usd_cents BIGINT NOT NULL DEFAULT 0,
    fee_covered_cdf BIGINT NOT NULL DEFAULT 0,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    payment_method payment_method_type NOT NULL,
    payment_reference VARCHAR(128) NOT NULL UNIQUE,
    phone_number VARCHAR(32),
    status donation_status NOT NULL DEFAULT 'PENDING',
    receipt_number VARCHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE RESTRICT,
    amount_usd_cents BIGINT NOT NULL DEFAULT 0,
    amount_cdf BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'CDF')),
    payment_rail subscription_rail NOT NULL,
    phone_number VARCHAR(32),
    payment_token VARCHAR(255),
    billing_day_of_month SMALLINT NOT NULL CHECK (billing_day_of_month BETWEEN 1 AND 28),
    status subscription_status NOT NULL DEFAULT 'ACTIVE',
    action_needed_today BOOLEAN NOT NULL DEFAULT FALSE,
    next_billing_date DATE NOT NULL,
    last_billed_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 7. PAYOUT WITHDRAWALS & IMPACT PROOF
-- ============================================================================
CREATE TABLE public.payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ngo_id UUID NOT NULL REFERENCES public.ngos(id) ON DELETE RESTRICT,
    requested_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    amount_usd_cents BIGINT NOT NULL DEFAULT 0,
    amount_cdf BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'CDF')),
    destination_type payout_destination NOT NULL,
    destination_details JSONB NOT NULL,
    biometric_verified BOOLEAN NOT NULL DEFAULT FALSE,
    status payout_status NOT NULL DEFAULT 'REQUESTED',
    ledger_transaction_id UUID REFERENCES public.ledger_transactions(id),
    reviewer_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE public.impact_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    ngo_id UUID NOT NULL REFERENCES public.ngos(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    media_urls TEXT[] NOT NULL DEFAULT '{}',
    receipt_image_url TEXT,
    verified_by_admin BOOLEAN NOT NULL DEFAULT TRUE,
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 8. ATOMIC STORED PROCEDURE: POOLED FUND REDISTRIBUTION DISBURSEMENT
-- ============================================================================
CREATE OR REPLACE FUNCTION public.execute_pooled_donation_split(
    p_donation_id UUID,
    p_campaign_id UUID,
    p_net_amount BIGINT,
    p_currency VARCHAR(3),
    p_fee_amount BIGINT
) RETURNS UUID AS $$
DECLARE
    v_tx_id UUID;
    v_clearing_account_id UUID;
    v_fee_account_id UUID;
    v_split_record RECORD;
    v_ngo_account_id UUID;
    v_ngo_split_amount BIGINT;
    v_total_split BIGINT := 0;
    v_campaign_title VARCHAR(255);
BEGIN
    SELECT title INTO v_campaign_title FROM public.campaigns WHERE id = p_campaign_id;

    -- 1. Create Ledger Transaction
    INSERT INTO public.ledger_transactions (
        transaction_reference,
        description,
        transaction_type,
        currency,
        status
    ) VALUES (
        'TX-DON-' || p_donation_id::TEXT,
        'Pooled Donation for: ' || v_campaign_title,
        'POOL_SPLIT_DISTRIBUTION',
        p_currency,
        'PENDING'
    ) RETURNING id INTO v_tx_id;

    -- 2. Find Clearing Account (Asset) and Fee Account (Revenue)
    SELECT id INTO v_clearing_account_id FROM public.accounts 
    WHERE code = '1010_CLEARING_' || p_currency LIMIT 1;
    
    SELECT id INTO v_fee_account_id FROM public.accounts 
    WHERE code = '4010_PLATFORM_FEE_' || p_currency LIMIT 1;

    -- Debit Cash/Clearing with total received (Net + Fee)
    INSERT INTO public.ledger_entries (transaction_id, account_id, debit_amount, credit_amount)
    VALUES (v_tx_id, v_clearing_account_id, (p_net_amount + p_fee_amount), 0);

    -- Credit Platform Fee Revenue if fee exists
    IF p_fee_amount > 0 THEN
        INSERT INTO public.ledger_entries (transaction_id, account_id, debit_amount, credit_amount)
        VALUES (v_tx_id, v_fee_account_id, 0, p_fee_amount);
    END IF;

    -- 3. Loop through active NGO campaign splits and credit NGO Payable Accounts (Liabilities)
    FOR v_split_record IN 
        SELECT s.ngo_id, s.split_percentage, n.name AS ngo_name
        FROM public.campaign_splits s
        JOIN public.ngos n ON n.id = s.ngo_id
        WHERE s.campaign_id = p_campaign_id AND s.is_active = TRUE
    LOOP
        v_ngo_split_amount := ROUND((p_net_amount * v_split_record.split_percentage) / 100.0);
        v_total_split := v_total_split + v_ngo_split_amount;

        -- Find or create NGO payable account
        SELECT id INTO v_ngo_account_id FROM public.accounts
        WHERE ngo_id = v_split_record.ngo_id AND currency = p_currency AND type = 'LIABILITY' LIMIT 1;

        IF v_ngo_account_id IS NULL THEN
            INSERT INTO public.accounts (code, name, type, currency, ngo_id)
            VALUES (
                '2010_PAYABLE_' || v_split_record.ngo_id::TEXT || '_' || p_currency,
                'Payable to ' || v_split_record.ngo_name,
                'LIABILITY',
                p_currency,
                v_split_record.ngo_id
            ) RETURNING id INTO v_ngo_account_id;
        END IF;

        -- Credit individual NGO payable
        INSERT INTO public.ledger_entries (transaction_id, account_id, debit_amount, credit_amount)
        VALUES (v_tx_id, v_ngo_account_id, 0, v_ngo_split_amount);
    END LOOP;

    -- Adjust any rounding cents/units to match exact net amount (assign remainder to first NGO)
    IF (p_net_amount - v_total_split) <> 0 THEN
        UPDATE public.ledger_entries
        SET credit_amount = credit_amount + (p_net_amount - v_total_split)
        WHERE id = (SELECT id FROM public.ledger_entries WHERE transaction_id = v_tx_id AND credit_amount > 0 ORDER BY id LIMIT 1);
    END IF;

    -- 4. Mark transaction as POSTED (triggers zero-balance validation)
    UPDATE public.ledger_transactions SET status = 'POSTED' WHERE id = v_tx_id;

    -- 5. Update Campaign Raised Totals
    IF p_currency = 'USD' THEN
        UPDATE public.campaigns SET raised_amount_usd_cents = raised_amount_usd_cents + p_net_amount WHERE id = p_campaign_id;
    ELSE
        UPDATE public.campaigns SET raised_amount_cdf = raised_amount_cdf + p_net_amount WHERE id = p_campaign_id;
    END IF;

    -- 6. Link transaction to donation
    UPDATE public.donations SET transaction_id = v_tx_id, status = 'SUCCESS', completed_at = NOW() WHERE id = p_donation_id;

    RETURN v_tx_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.impact_updates ENABLE ROW LEVEL SECURITY;

-- Helper function to check role from auth JWT
CREATE OR REPLACE FUNCTION public.current_user_role() RETURNS user_role AS $$
    SELECT COALESCE(
        (current_setting('request.jwt.claims', true)::jsonb ->> 'role')::user_role,
        (SELECT role FROM public.profiles WHERE id = auth.uid())
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Profiles: Users can view & update own profile; SuperAdmin full access
CREATE POLICY profiles_user_policy ON public.profiles FOR ALL USING (auth.uid() = id OR public.current_user_role() = 'SUPERADMIN');
CREATE POLICY profiles_public_select ON public.profiles FOR SELECT USING (true);

-- Campaigns: Publicly readable; SuperAdmin or owner NGO Admin can write
CREATE POLICY campaigns_public_view ON public.campaigns FOR SELECT USING (true);
CREATE POLICY campaigns_admin_insert ON public.campaigns FOR INSERT WITH CHECK (
    public.current_user_role() = 'SUPERADMIN' OR 
    (public.current_user_role() = 'NGO_ADMIN' AND ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()))
);
CREATE POLICY campaigns_admin_update ON public.campaigns FOR UPDATE USING (
    public.current_user_role() = 'SUPERADMIN' OR 
    (public.current_user_role() = 'NGO_ADMIN' AND ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()))
);

-- NGOs: Public can view verified NGOs; NGO Admins manage their own; SuperAdmin full access
CREATE POLICY ngos_public_view ON public.ngos FOR SELECT USING (verification_status = 'VERIFIED' OR admin_user_id = auth.uid() OR public.current_user_role() = 'SUPERADMIN');
CREATE POLICY ngos_owner_update ON public.ngos FOR UPDATE USING (admin_user_id = auth.uid() OR public.current_user_role() = 'SUPERADMIN');
CREATE POLICY ngos_insert ON public.ngos FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- KYC Documents: Only NGO Admin owner and SuperAdmin can see/upload
CREATE POLICY kyc_owner_select ON public.kyc_documents FOR SELECT USING (
    public.current_user_role() = 'SUPERADMIN' OR 
    ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid())
);
CREATE POLICY kyc_owner_insert ON public.kyc_documents FOR INSERT WITH CHECK (
    ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()) OR 
    public.current_user_role() = 'SUPERADMIN'
);
CREATE POLICY kyc_admin_update ON public.kyc_documents FOR UPDATE USING (public.current_user_role() = 'SUPERADMIN');

-- Donations: Donors see own donations; NGOs see donations to their campaigns; SuperAdmin sees all
CREATE POLICY donations_donor_select ON public.donations FOR SELECT USING (
    auth.uid() = donor_id OR 
    public.current_user_role() = 'SUPERADMIN' OR
    campaign_id IN (SELECT id FROM public.campaigns WHERE ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()))
);
CREATE POLICY donations_insert ON public.donations FOR INSERT WITH CHECK (true);

-- Ledger: Read-only for NGO Admins (their accounts) and SuperAdmins. Immutable to direct mutations
CREATE POLICY accounts_admin_read ON public.accounts FOR SELECT USING (
    public.current_user_role() = 'SUPERADMIN' OR 
    ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid())
);
CREATE POLICY ledger_tx_admin_read ON public.ledger_transactions FOR SELECT USING (public.current_user_role() = 'SUPERADMIN');
CREATE POLICY ledger_entries_admin_read ON public.ledger_entries FOR SELECT USING (public.current_user_role() = 'SUPERADMIN');

-- Subscriptions: Donors manage own subscriptions; SuperAdmin full access
CREATE POLICY sub_owner_all ON public.subscriptions FOR ALL USING (donor_id = auth.uid() OR public.current_user_role() = 'SUPERADMIN');

-- Payouts: NGO Admin creates/reads own; SuperAdmin approves/executes
CREATE POLICY payout_ngo_all ON public.payout_requests FOR ALL USING (
    ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()) OR 
    public.current_user_role() = 'SUPERADMIN'
);

-- Impact Updates: Public can read; NGO Admin writes for own campaigns
CREATE POLICY impact_public_read ON public.impact_updates FOR SELECT USING (true);
CREATE POLICY impact_ngo_insert ON public.impact_updates FOR INSERT WITH CHECK (
    ngo_id IN (SELECT id FROM public.ngos WHERE admin_user_id = auth.uid()) OR 
    public.current_user_role() = 'SUPERADMIN'
);
