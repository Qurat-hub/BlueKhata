# BlueKhata — Smart Business Ledger

A modern, Blue-themed bookkeeping app built with **Flutter + Supabase**.
Powered by Zenvyro Labs.

This repo is a **production-grade starting scaffold**, not a finished
19-module app — see [Module Status](#module-status) for what's wired
end-to-end today vs. what's next.

---

## What's included in this build pass

- ✅ Clean/feature-first architecture (`core/` + `features/<name>/{data,domain,presentation}`)
- ✅ Riverpod state management, Go Router navigation with auth redirects
- ✅ Material 3 Blue Design System theme (light + dark)
- ✅ Supabase phone/OTP authentication
- ✅ Business creation, listing, and switching (multi-business support)
- ✅ Customer management (CRUD, search, favorites)
- ✅ Ledger module: credit/debit entries with **server-side running balance**
  (Postgres triggers keep `customers.current_balance` and
  `ledger_entries.balance_after` correct and race-safe)
- ✅ Dashboard: today's credit/cash summary, quick actions, recent customers
- ✅ Offline-first scaffolding: Hive local cache boxes + a sync queue
  (`SyncQueueService`) ready to be wired into repositories
- ✅ Full SQL schema (4 migrations) covering **every module in the spec**
  — ledger, cashbook, bank book, inventory, billing/invoices, staff,
  reminders, notifications, admin content, audit logs, soft-delete,
  backups — with Row Level Security on every table
- ✅ Zenvyro Labs branding wired into Splash + Dashboard footer (see `BRANDING.md`)

## Not yet built (schema exists, UI/repos pending)

Cash Book UI, Bank Book UI, Inventory & Barcode scanning, Billing/Invoice
PDF generation, Staff/Payroll, Reports & Analytics charts, Reminder
scheduling + FCM push, Backup/Restore UI, full Settings (App Lock,
biometrics, multi-language runtime switching), Business Card generator,
and the separate **Flutter Web Super Admin Panel**. The SQL for all of
these already exists in `supabase/migrations/`, so each is a matter of
adding a `features/<module>` folder that follows the same
repository → provider → screen pattern as `customers`/`ledger`.

---

## Getting started

### 1. Prerequisites
- Flutter SDK (stable channel)
- A Supabase project ([supabase.com](https://supabase.com))

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Set up Supabase
Run the SQL migrations in order against your Supabase project (SQL Editor,
or `supabase db push` if using the Supabase CLI):

```
supabase/migrations/0001_core_schema.sql
supabase/migrations/0002_ledger_cashbook_bank.sql
supabase/migrations/0003_inventory_billing.sql
supabase/migrations/0004_staff_notifications_audit.sql
```

In your Supabase project dashboard, enable **Phone Auth** (Authentication →
Providers → Phone) and configure an SMS provider (Twilio, MessageBird, etc.)
for OTP delivery.

### 4. Run the app
Supabase credentials are injected via `--dart-define` (never hardcoded):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Tip: create a `run_dev.sh` (gitignored) wrapping this command so you don't
retype it. Do not commit real keys.

### 5. Code generation (once you add Freezed/Hive models)
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture

```
lib/
  core/
    config/        # AppConfig — env-driven constants, branding strings
    theme/          # AppColors, AppTheme, AppSpacing (Blue Design System)
    routes/         # go_router config + AppRoutes path constants
    services/       # SupabaseService, LocalStorageService, SyncQueueService
    shared/widgets/ # AppButton, AppCard, state widgets, BrandingFooter
  features/
    authentication/ # phone/OTP login, splash, language selection
    business/       # create/select/switch businesses
    customers/       # customer CRUD + search
    ledger/         # credit/debit entries, running balance
    dashboard/      # home tab, bottom nav shell
```

Each feature follows **Repository Pattern + Clean Architecture**:
`data/repositories` (Supabase calls) → `presentation/providers` (Riverpod
`StateNotifier`/`FutureProvider`) → `presentation/screens` (UI only, no
business logic). This is the pattern to replicate for every remaining
module (cashbook, bank, inventory, billing, staff, reports, admin).

## Database design notes

- Every table has `created_at`, soft-delete flags (`is_deleted`/`deleted_at`
  or `is_archived`), and RLS scoped by business membership via the
  `is_business_member(business_id)` helper function.
- `ledger_entries` balance is **not** computed client-side — a trigger
  (`apply_ledger_entry_balance`) atomically updates `customers.current_balance`
  on insert, and `reverse_ledger_entry_balance` reverses it on soft-delete.
  This avoids race conditions from concurrent devices/offline sync.
- `products.stock_quantity` is similarly maintained by `inventory_logs`
  triggers rather than direct writes, so stock history is always auditable.

## Branding

See [`BRANDING.md`](./BRANDING.md) — "Powered by Zenvyro Labs" is required
on the Splash Screen and Dashboard, enforced via the reusable
`BrandingFooter` widget. Do not remove.

## Suggested next steps

1. Wire `SyncQueueService` into the customer/ledger repositories for true
   offline-first writes (queue on `SocketException`, flush on
   `connectivity_plus` reconnect).
2. Build the Cash Book and Bank Book features (schema is ready).
3. Add the Invoice module + PDF export using the `pdf`/`printing` packages.
4. Stand up the Flutter Web Super Admin Panel as a second app target
   (`lib_admin/` or a separate package) using the same Supabase project
   with `role = 'super_admin'` gated RLS policies already in migration 0004.
5. Integrate Firebase (FCM) for the notification types already modeled in
   `public.notifications`.
