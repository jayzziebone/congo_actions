# CongoActions: Architecture, Implementation Plan & Technical Blueprint

Cross-Platform Mobile Application (iOS & Android) for Charitable Donations & Pooled NGO Redistribution in the Democratic Republic of Congo (DRC) & International Diaspora Markets.

---

## 1. Executive Summary & Architecture Overview

**CongoActions** is a fintech charitable giving platform designed to connect domestic donors in the Democratic Republic of Congo (DRC) and international diaspora communities with verified, high-impact non-profit organizations (NGOs). 

The platform collects both one-time contributions and monthly recurring pledges via:
1. **DRC Domestic Rails:** USSD (STK) push requests for Vodacom M-Pesa, Orange Money, Airtel Money, and Africell Afrimoney.
2. **International Diaspora Rails:** International Visa, Mastercard, Apple Pay, and Google Pay (processed via `flutter_custom_tabs` adhering to Apple App Store Guideline 3.2.1(vi)).

All incoming capital is posted into an immutable PostgreSQL double-entry financial ledger that tracks funds in dual currencies:
- **US Dollars (USD):** Stored as integer cents (`BIGINT amount_usd_cents`) to eliminate IEEE 754 floating-point inaccuracies.
- **Congolese Francs (CDF):** Stored as whole integer units (`BIGINT amount_cdf`).

Pooled cause funds (e.g., Eastern DRC Emergency Relief) are redistributed across verified NGO wallets using atomic PostgreSQL database stored procedures with zero ledger balance variance.

---

## 2. Technical Stack & Specifications

| Layer | Technology | Key Capabilities & Rationale |
| :--- | :--- | :--- |
| **Mobile Client** | **Flutter (Dart 3.x)** | Single, unified codebase for iOS & Android with custom Soft Pastel DRC theme. |
| **Offline Layer** | **SQLite & SharedPreferences Cache** | Offline-first caching layer to survive unstable 3G networks in the DRC. |
| **State Management** | **Flutter Riverpod 2.x** | Declarative, testable state management with unidirectional data flow and repository pattern. |
| **Navigation & Guards** | **`go_router` (v14+)** | Role-based navigation guards driven by Supabase Auth JWT custom claims (`DONOR`, `NGO_ADMIN`, `SUPERADMIN`). |
| **Database & Ledger** | **Supabase (PostgreSQL 16+)** | Strict Row Level Security (RLS), immutable double-entry ledger triggers, atomic stored procedures. |
| **Serverless Functions** | **Supabase Edge Functions (Deno / TypeScript)** | HMAC-SHA256 signature verification, idempotent webhook processing, USSD dispatch, daily cron schedulers. |
| **Cloud Storage** | **Supabase Storage (S3-compatible)** | Private encrypted buckets for NGO legal KYC documents (*Arrêté Ministériel*, F92, director IDs). |
| **Design System** | **Soft Pastel DRC Theme** | Deep Slate Navy (`#1B365D`), Soft Sky-Cerulean Blue (`#5BA4E5`), Ice-Blue surfaces (`#F4F7FA`), 24px card radii. |

---

## 3. Step-by-Step Implementation Roadmap

### Phase 1: Database Architecture & Double-Entry Accounting Ledger
- **Integer Minor Units:** Prevent currency rounding errors by storing USD in cents and CDF in whole integer units.
- **Standardized Chart of Accounts:** Accounts for Central Clearing (`1010_CASH_USD`, `1020_CASH_CDF`), NGO Payable Liabilities (`2010_NGO_PAYABLE_USD`), Donation Revenue, and Platform Gateway Fee Revenue.
- **Ledger Invariant Trigger:** PostgreSQL trigger `verify_ledger_balance()` verifying $\sum \text{Debits} \equiv \sum \text{Credits}$ before any transaction transitions to `POSTED`.
- **Atomic Split Function:** `execute_pooled_donation_split(...)` performs clearing debits, fee credits, and mathematical allocation splits across participating NGO payable liabilities in a single ACID transaction.
- **Row Level Security (RLS):** Strict security policies verifying JWT claims (`auth.jwt() ->> 'role'`).

### Phase 2: Supabase Serverless Edge Functions
- `webhook-maishapay`: HMAC-SHA256 signature check, idempotency check via payment transaction references, and atomic ledger split invocation.
- `initiate-donation`: Payment routing directing DRC Mobile Money to USSD STK push and international card donations to compliant external browser checkout sessions.
- `cron-recurring-pledges`: Daily cron identifying active Mobile Money pledges requiring renewal, flagging `action_needed_today = true`, and dispatching FCM push reminders for 1-tap USSD execution.

### Phase 3: Flutter State Management & Offline-First Repository
- Riverpod Providers: Auth session state, persona switcher, dual-currency state ($ USD $\leftrightarrow$ FC CDF), donation flow state, and live campaign data.
- Offline resilience: Pre-seeded local cache ensuring donors can view campaigns and receipts regardless of network status.

### Phase 4: `go_router` Role-Based Dynamic Routing
- Unified application containing all 3 personas: `DONOR`, `NGO_ADMIN`, `SUPERADMIN`.
- Dynamic redirects guarding administrative and organizer routes based on active role credentials.

### Phase 5: Soft Pastel DRC Design System
- Pure White background (`#FFFFFF`) with soft Ice-Blue containers (`#F4F7FA`).
- Primary Cerulean Blue pill buttons (`#5BA4E5`) and Powder-Blue secondary buttons (`#E3F0FC`).
- Pastel category chips: Apricot (`#FFE5CC`), Buttercream (`#FFF4CC`), and Rose-Coral (`#FADBD8`).
- 24px border radius geometry and minimum 48x48 dp touch targets.

### Phase 6: Screen Catalog (17 Complete Screens)
- **Phase A (Auth):** Welcome Screen, Phone & Social Sign-In, 6-Digit OTP.
- **Phase B (Donor):** Home, Campaign Detail, Donation Setup, Payment Checkout, USSD Waiting, Success Receipt, Pooled Fund Visualizer, Subscriptions, Profile & Badges.
- **Phase C (NGO):** KYC Onboarding, Dashboard & Analytics, Payout Withdrawal, Post Impact Proof.
- **Phase D (Admin):** SuperAdmin Console (Ledger Gross Metrics, KYC Approval Queue, Pool Split Sliders, Batch Disbursement).

---

## 4. Strategic MVP Improvement Suggestions

1. **SMS Fallback for Unstable USSD Push:**
   In parts of eastern and central DRC, network towers periodically experience USSD push delivery drops. Adding an automated fallback that sends an SMS with a direct USSD dial string (e.g. `tel:*1122*1*...#`) allows donors to authorize payments with one tap if the background push times out.
2. **Forex Volatility Auto-Reconciliation (USD/CDF Dynamic Peg):**
   The Congolese Franc fluctuates against the USD. Integrating an automated daily Central Bank of Congo (BCC) or commercial bank exchange rate feed in an hourly cron prevents exchange rate arbitrage during donation conversion.
3. **Apple Guideline 3.2.1(vi) Charity Verification Submission Package:**
   Apple strictly requires registered non-profit documentation (501(c)(3) or Congolese *Arrêté Ministériel d'agrément*) to authorize in-app charitable donation links outside In-App Purchases. Pre-packaging verified NGO ministerial certificates directly in the reviewer payload accelerates App Store review.
4. **Offline Transaction Signing & Queuing:**
   Allow users in low-connectivity areas to prepare their donation while offline. The application queues the payload and automatically fires the USSD push once an active 2G/3G handshake is re-established.
5. **Anti-Fraud Rate Limiting on USSD Push:**
   Prevent abusive denial-of-wallet spam by applying a token-bucket rate limiter (maximum 3 USSD pushes per MSISDN per 15 minutes) in the `initiate-donation` edge function.

---

## 5. PostgreSQL Schema & Double-Entry Ledger Core

**Migration File:** `supabase/migrations/20260221000000_congo_actions_schema.sql`

```sql
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
```

---

## 6. Serverless Edge Functions

### 1. `webhook-maishapay/index.ts`
- Consumes asynchronous webhook callbacks from Vodacom M-Pesa, Orange, Airtel, and Africell.
- Performs HMAC-SHA256 signature verification.
- Enforces idempotency via `payment_reference`.
- Calls PostgreSQL stored procedure `execute_pooled_donation_split(...)`.

### 2. `initiate-donation/index.ts`
- Dispatches USSD push prompts for DRC mobile numbers.
- Generates compliant web checkout URLs for international card rails via `flutter_custom_tabs`.

### 3. `cron-recurring-pledges/index.ts`
- Daily scheduler flagging active Mobile Money subscriptions due today.
- Triggers 1-tap renewal prompts via push notifications.

---

## 7. Flutter Screen Catalog & Code Architecture

### Core Modules
- `lib/core/theme/app_theme.dart`: Soft Pastel DRC theme definitions.
- `lib/core/models/models.dart`: Domain data models with serialization.
- `lib/core/services/supabase_service.dart`: Offline-first repository with seeded Congolese NGOs.
- `lib/core/state/currency_state.dart`: Dual-currency toggle provider ($ USD cents $\leftrightarrow$ FC CDF units).
- `lib/core/state/auth_state.dart`: Authentication & persona role switcher provider.
- `lib/core/state/donation_state.dart`: Checkout flow and USSD countdown state.
- `lib/core/state/data_providers.dart`: Riverpod data providers for campaigns and KYC queue.
- `lib/core/router/app_router.dart`: `go_router` with role navigation guards.
- `lib/core/widgets/common_widgets.dart`: PillButton, PastelBadge, RoleSwitcherDrawer.

### Screens
- **Auth:**
  - `lib/features/auth/welcome_screen.dart`
  - `lib/features/auth/phone_signin_screen.dart`
  - `lib/features/auth/otp_screen.dart`
- **Donor:**
  - `lib/features/donor/donor_home_screen.dart`
  - `lib/features/donor/campaign_detail_screen.dart`
  - `lib/features/donor/donation_setup_screen.dart`
  - `lib/features/donor/payment_checkout_screen.dart`
  - `lib/features/donor/ussd_waiting_screen.dart`
  - `lib/features/donor/donation_success_screen.dart`
  - `lib/features/donor/pooled_fund_screen.dart`
  - `lib/features/donor/donor_subscriptions_screen.dart`
  - `lib/features/donor/donor_profile_screen.dart`
- **NGO Organizer:**
  - `lib/features/ngo/ngo_kyc_screen.dart`
  - `lib/features/ngo/ngo_dashboard_screen.dart`
  - `lib/features/ngo/ngo_withdrawal_screen.dart`
  - `lib/features/ngo/post_impact_update_screen.dart`
- **SuperAdmin:**
  - `lib/features/admin/superadmin_console_screen.dart`

---

## 8. Verification, Testing & Build Instructions

### Running Tests
Execute unit and widget tests:
```bash
flutter test
```
*Current result: 100% tests passing (`test/widget_test.dart`).*

### Code Analysis
Run Flutter static analysis:
```bash
flutter analyze --no-fatal-infos
```
*Current result: 0 errors, 0 warnings.*

### Launching Locally
To run the Flutter app on an iOS simulator, Android emulator, or Chrome:
```bash
flutter run
```
Use the **Role Switcher Drawer** (accessible from the top-left menu icon or profile screen) to instantly switch between:
- **Donor Persona** (`/donor`)
- **NGO Organizer Persona** (`/ngo`)
- **SuperAdmin Console** (`/admin`)
