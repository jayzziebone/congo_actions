-- ============================================================================
-- SEED INITIAL LIVE CAMPAIGNS & ALLOCATION SPLITS
-- ============================================================================

-- 1. Ensure Fondation Panzi NGO exists for multi-partner pooled fund
INSERT INTO public.ngos (id, admin_user_id, name, legal_registration_number, mission_statement, contact_email, contact_phone, verification_status)
SELECT 
    'a0000000-0000-0000-0000-000000000001'::UUID,
    (SELECT id FROM public.profiles WHERE role = 'NGO_ADMIN' LIMIT 1),
    'Fondation Panzi (Dr. Denis Mukwege)',
    'ARRETE-MIN-045/CAB/2021',
    'Holistic medical, psychological, and legal care for survivors of sexual violence in Eastern DRC.',
    'contact@fondationpanzidrc.org',
    '+243998877665',
    'VERIFIED'
WHERE NOT EXISTS (SELECT 1 FROM public.ngos WHERE name LIKE 'Fondation Panzi%');

-- Ensure Kivu Clean Water NGO exists
INSERT INTO public.ngos (id, admin_user_id, name, legal_registration_number, mission_statement, contact_email, contact_phone, verification_status)
SELECT 
    'a0000000-0000-0000-0000-000000000002'::UUID,
    (SELECT id FROM public.profiles WHERE role = 'NGO_ADMIN' LIMIT 1),
    'Kivu Clean Water Initiative',
    'F92-JUST-2019-KIVU',
    'Building sustainable solar-powered water purification wells across North & South Kivu.',
    'info@kivuclearwater.org',
    '+243812345678',
    'VERIFIED'
WHERE NOT EXISTS (SELECT 1 FROM public.ngos WHERE name LIKE 'Kivu Clean Water%');

-- Ensure Orphanage NGO exists
INSERT INTO public.ngos (id, admin_user_id, name, legal_registration_number, mission_statement, contact_email, contact_phone, verification_status)
SELECT 
    'a0000000-0000-0000-0000-000000000003'::UUID,
    (SELECT id FROM public.profiles WHERE role = 'NGO_ADMIN' LIMIT 1),
    'Orphelinat de Kinshasa (Ngaliema)',
    'F92-JUST-2022-KIN',
    'Shelter, nutritional meals, and primary schooling for 140 orphaned children in Kinshasa.',
    'contact@orphelinatkinshasa.cd',
    '+243891234567',
    'VERIFIED'
WHERE NOT EXISTS (SELECT 1 FROM public.ngos WHERE name LIKE 'Orphelinat de Kinshasa%');

-- Create ledger payable accounts for these NGOs
INSERT INTO public.accounts (code, name, type, currency, ngo_id)
SELECT '2010_PAYABLE_' || id::TEXT || '_USD', 'Payable to ' || name || ' (USD)', 'LIABILITY', 'USD', id
FROM public.ngos
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.accounts (code, name, type, currency, ngo_id)
SELECT '2020_PAYABLE_' || id::TEXT || '_CDF', 'Payable to ' || name || ' (CDF)', 'LIABILITY', 'CDF', id
FROM public.ngos
ON CONFLICT (code) DO NOTHING;

-- 2. Insert Core Live Campaigns into public.campaigns
-- Campaign 1: Eastern DRC Emergency Relief Pool (Multi-partner pooled fund)
INSERT INTO public.campaigns (
    id,
    title,
    subtitle,
    description,
    category,
    is_pooled_fund,
    target_amount_usd_cents,
    raised_amount_usd_cents,
    target_amount_cdf,
    raised_amount_cdf,
    image_url,
    location,
    status
) VALUES (
    'c0000000-0000-0000-0000-000000000001'::UUID,
    'Eastern DRC Emergency & Health Relief Pool',
    '100% transparent automated redistribution across 3 top-rated hospitals and water stations.',
    'Providing critical trauma surgery, emergency cholera water purification kits, and maternal intensive care in Goma and Bukavu. 100% of incoming funds are automatically split via double-entry ledger between verified local responders.',
    'HEALTH',
    TRUE,
    10000000, -- $100,000.00 USD
    4285000,  -- $42,850.00 USD
    280000000, -- 280,000,000 CDF
    120000000, -- 120,000,000 CDF
    'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1200&q=80',
    'Goma & Bukavu, North & South Kivu',
    'ACTIVE'
) ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description;

-- Campaign 2: Code for Congo: IT Labs for 500 Youths
INSERT INTO public.campaigns (
    id,
    ngo_id,
    title,
    subtitle,
    description,
    category,
    is_pooled_fund,
    target_amount_usd_cents,
    raised_amount_usd_cents,
    target_amount_cdf,
    raised_amount_cdf,
    image_url,
    location,
    status
) VALUES (
    'c0000000-0000-0000-0000-000000000002'::UUID,
    (SELECT id FROM public.ngos WHERE name = 'Sauvons Congo' LIMIT 1),
    'Code for Congo: IT Labs for 500 Youths',
    'Equipping two solar-powered computer centers in Kinshasa (Masina & Limete).',
    'Empowering underprivileged Congolese high school graduates with high-speed Starlink satellite internet, certified Python programming courses, and digital freelancing skillsets.',
    'EDUCATION',
    FALSE,
    3500000, -- $35,000.00 USD
    1820000, -- $18,200.00 USD
    98000000,
    50960000,
    'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=1200&q=80',
    'Masina & Limete, Kinshasa, DRC',
    'ACTIVE'
) ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description;

-- Campaign 3: Clean Solar Water for 10,000 Displaced Families
INSERT INTO public.campaigns (
    id,
    ngo_id,
    title,
    subtitle,
    description,
    category,
    is_pooled_fund,
    target_amount_usd_cents,
    raised_amount_usd_cents,
    target_amount_cdf,
    raised_amount_cdf,
    image_url,
    location,
    status
) VALUES (
    'c0000000-0000-0000-0000-000000000003'::UUID,
    'a0000000-0000-0000-0000-000000000002'::UUID,
    'Clean Solar Water for 10,000 Displaced Families',
    'Drilling 4 solar water boreholes in Mugunga IDP camps outside Goma.',
    'Immediate eradication of water-borne pathogens and cholera outbreaks by installing deep 120-meter solar pumping systems with chlorinated collection points.',
    'EMERGENCY',
    FALSE,
    6000000, -- $60,000.00 USD
    3890000, -- $38,900.00 USD
    168000000,
    108920000,
    'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=800&q=80',
    'Mugunga Camp, Goma, DRC',
    'ACTIVE'
) ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description;

-- 3. Set Up Campaign Allocation Splits for Pooled Fund
INSERT INTO public.campaign_splits (campaign_id, ngo_id, split_percentage, is_active)
VALUES
    ('c0000000-0000-0000-0000-000000000001'::UUID, 'a0000000-0000-0000-0000-000000000001'::UUID, 40.0, TRUE),
    ('c0000000-0000-0000-0000-000000000001'::UUID, 'a0000000-0000-0000-0000-000000000002'::UUID, 35.0, TRUE),
    ('c0000000-0000-0000-0000-000000000001'::UUID, 'a0000000-0000-0000-0000-000000000003'::UUID, 25.0, TRUE)
ON CONFLICT (campaign_id, ngo_id) DO UPDATE
SET split_percentage = EXCLUDED.split_percentage;

-- 4. Initial Verified Impact Update
INSERT INTO public.impact_updates (campaign_id, ngo_id, title, content, media_urls, receipt_image_url)
VALUES (
    'c0000000-0000-0000-0000-000000000001'::UUID,
    'a0000000-0000-0000-0000-000000000001'::UUID,
    'New Maternal Care Unit Operational in Bukavu',
    'Thanks to pooled donor funds, 120 new medical delivery kits and solar refrigeration units have arrived at Panzi Hospital.',
    ARRAY['https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80'],
    'https://images.unsplash.com/photo-1554415707-9e4466a9c396?auto=format&fit=crop&w=400&q=80'
) ON CONFLICT DO NOTHING;
