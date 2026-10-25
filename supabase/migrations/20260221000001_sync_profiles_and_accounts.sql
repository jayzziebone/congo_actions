-- ============================================================================
-- CONGO ACTIONS: PROFILES & ACCOUNTS LEDGER ENHANCEMENT
-- ============================================================================

-- 1. Allow nullable phone_number and add contact_email to profiles
ALTER TABLE public.profiles ALTER COLUMN phone_number DROP NOT NULL;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_phone_number_key;
CREATE UNIQUE INDEX IF NOT EXISTS profiles_phone_number_unique_idx ON public.profiles (phone_number) WHERE phone_number IS NOT NULL AND phone_number <> '';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'contact_email') THEN
        ALTER TABLE public.profiles ADD COLUMN contact_email VARCHAR(255);
    END IF;
END $$;

-- 2. Automatically sync auth.users into public.profiles upon signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, contact_email, role, preferred_currency)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.email,
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'DONOR'::public.user_role),
        'USD'
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        contact_email = EXCLUDED.contact_email,
        role = EXCLUDED.role;

    -- If the user registered as NGO_ADMIN, auto-create an entry in public.ngos and an accounts ledger liability
    IF (NEW.raw_user_meta_data->>'role') = 'NGO_ADMIN' THEN
        INSERT INTO public.ngos (
            admin_user_id,
            name,
            legal_registration_number,
            mission_statement,
            contact_email,
            contact_phone
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'organization_name', 'NGO ' || COALESCE(NEW.raw_user_meta_data->>'full_name', 'Partner')),
            'REG-' || SUBSTRING(NEW.id::TEXT, 1, 8),
            'Charitable and community development operations in DRC.',
            COALESCE(NEW.email, 'ngo@congoactions.org'),
            ''
        )
        ON CONFLICT (legal_registration_number) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Seed Central Platform Accounts in public.accounts
INSERT INTO public.accounts (code, name, type, currency)
VALUES
    ('1010_CLEARING_USD', 'Central Platform Clearing Account (USD)', 'ASSET', 'USD'),
    ('1020_CLEARING_CDF', 'Central Platform Clearing Account (CDF)', 'ASSET', 'CDF'),
    ('4010_PLATFORM_FEE_USD', 'Platform Gateway Fee Revenue (USD)', 'REVENUE', 'USD'),
    ('4020_PLATFORM_FEE_CDF', 'Platform Gateway Fee Revenue (CDF)', 'REVENUE', 'CDF')
ON CONFLICT (code) DO NOTHING;

-- 4. Backfill existing registered users into public.profiles
INSERT INTO public.profiles (id, full_name, contact_email, role, preferred_currency)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'full_name', split_part(email, '@', 1)),
    email,
    COALESCE((raw_user_meta_data->>'role')::public.user_role, 'DONOR'::public.user_role),
    'USD'
FROM auth.users
ON CONFLICT (id) DO UPDATE
SET full_name = EXCLUDED.full_name,
    contact_email = EXCLUDED.contact_email,
    role = EXCLUDED.role;

-- Backfill existing NGO admin into public.ngos
INSERT INTO public.ngos (admin_user_id, name, legal_registration_number, mission_statement, contact_email, contact_phone)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'organization_name', 'Sauvons Congo'),
    'REG-' || SUBSTRING(id::TEXT, 1, 8),
    'Humanitarian support in the DRC.',
    email,
    ''
FROM auth.users
WHERE raw_user_meta_data->>'role' = 'NGO_ADMIN'
ON CONFLICT DO NOTHING;

-- Create NGO Payable ledger accounts for existing NGOs
INSERT INTO public.accounts (code, name, type, currency, ngo_id)
SELECT 
    '2010_PAYABLE_' || id::TEXT || '_USD',
    'Payable to ' || name || ' (USD)',
    'LIABILITY',
    'USD',
    id
FROM public.ngos
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.accounts (code, name, type, currency, ngo_id)
SELECT 
    '2020_PAYABLE_' || id::TEXT || '_CDF',
    'Payable to ' || name || ' (CDF)',
    'LIABILITY',
    'CDF',
    id
FROM public.ngos
ON CONFLICT (code) DO NOTHING;
