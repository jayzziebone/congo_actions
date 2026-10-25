# CongoActions: Mobile Giving & NGO Redistribution Platform

Cross-platform Flutter application (iOS & Android) with Supabase (PostgreSQL 16+) and double-entry financial ledger for transparent charitable giving in the Democratic Republic of Congo (DRC) and international diaspora markets.

---

## 📖 Complete Documentation & Technical Roadmap
Detailed architectural breakdowns, PostgreSQL schemas, double-entry ledger triggers, Supabase Edge Functions, and Riverpod state management are documented in:
👉 **[ARCHITECTURE_AND_IMPLEMENTATION.md](file:///Users/jayzziebone/Documents/CongoActions/ARCHITECTURE_AND_IMPLEMENTATION.md)**

---

## 🚀 Key Features

1. **Dual-Currency Minor Unit Accounting:** Tracks US Dollars ($ USD stored as integer cents) and Congolese Francs (FC CDF stored as integer whole units).
2. **Immutable Double-Entry Ledger:** Zero-balance balance invariant trigger ensuring $\sum \text{Debits} \equiv \sum \text{Credits}$ across clearing and NGO payable accounts.
3. **Atomic Pooled Redistribution:** Stored procedure (`execute_pooled_donation_split`) redistributing funds across verified grassroots NGOs (e.g., Hospital Panzi, Kivu Clean Water, Kinshasa Orphanage).
4. **DRC Mobile Money & International Card Rails:**
   - DRC: Vodacom M-Pesa, Orange Money, Airtel Money, Africell Afrimoney USSD push.
   - Diaspora: Stripe / Flutterwave web checkout adhering to Apple App Store Guideline 3.2.1(vi).
5. **Offline-First 3G Resilient:** Local caching via SQLite/SharedPreferences to withstand unstable 3G networks in the DRC.
6. **Unified Role Switching:** Instant role switching between **Donor**, **NGO Organizer**, and **SuperAdmin** personas via `go_router` navigation guards.
7. **Soft Pastel DRC Theme:** Calm, trustworthy visual design derived from the subtle tones of the DRC flag.

---

## 🧪 Verification & Testing

```bash
# Run unit and widget tests
flutter test

# Run static code analysis
flutter analyze --no-fatal-infos

# Run the app locally (iOS / Android / Web)
flutter run
```
