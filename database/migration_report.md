# BlueKhata Migration Report

## What this migration does

Consolidates `supabase/migrations/0001_core_schema.sql` through
`0004_staff_notifications_audit.sql` into a single, idempotent installer
(`bluekhata_complete_database.sql`), fixes the one breaking mismatch
between the schema and the Flutter app (`users` → `profiles`), and adds a
small set of clearly-marked, non-breaking extras that the install spec
asked for explicitly (payment methods lookup table, dashboard views,
storage buckets).

## How to run it

**New Supabase project:** open the SQL Editor, paste the full contents of
`bluekhata_complete_database.sql`, press RUN. Nothing else is required —
extensions, tables, functions, triggers, RLS, policies, seed data, and
storage buckets are all created in one pass.

**Existing project already running migrations 0001–0004:** paste and RUN
the same file. It is fully idempotent:
- `create table if not exists` — existing tables/data are untouched
- `create extension if not exists` — no-op if already installed
- `create index if not exists` — no-op if already present
- `drop policy if exists … create policy` — policies are refreshed, not
  duplicated
- `create or replace function/view` — functions/views are refreshed

The one exception is the **`users` → `profiles` rename**, which is a
one-time structural change (see below) — if you have an existing project
still on the raw `0001–0004` migrations with real data in `public.users`,
run the rename block manually first (see "Upgrading an existing `users`
table" below) before pasting the full installer, or the installer's
`create table if not exists public.profiles` will create a second, empty
table alongside your existing `users` table instead of migrating it.

### Upgrading an existing `users` table with real data

If your project already has data in `public.users` from a previous run of
the original migrations, run this **once**, before the full installer:

```sql
alter table public.users rename to profiles;
alter table public.profiles rename column display_name to full_name;
```

After that, running `bluekhata_complete_database.sql` will find
`public.profiles` already exists and simply add/refresh everything else
around it (indexes, triggers, RLS policies, and the 15 foreign keys in
other tables that need to point at `profiles` instead of `users` — those
were already pointing at the table by its old name via the FK constraint
internals, so no data is lost or orphaned by the rename; only the display
name of the referenced table changes).

## Verification performed

Static syntax checking is not sufficient for a schema this size — 25
tables, 48 foreign keys, 10 triggers, 54 policies — so this was verified by
actually running it, twice, against a real Postgres 16 instance:

```bash
apt-get install -y postgresql        # Postgres 16.14
service postgresql start
psql -c "create database bluekhata_test"
psql -d bluekhata_test -f 00_supabase_stub.sql   # minimal auth/storage stand-in
psql -d bluekhata_test -v ON_ERROR_STOP=1 -f bluekhata_complete_database.sql
# ↳ exited 0, only expected first-run NOTICEs, no ERROR lines
psql -d bluekhata_test -v ON_ERROR_STOP=1 -f bluekhata_complete_database.sql
# ↳ ran a second time — exited 0, zero errors, confirming idempotency
```

Then the exact call patterns from `auth_repository.dart`,
`business_repository.dart`, `customer_repository.dart`, and
`ledger_repository.dart` were replayed as real SQL against that database:

| Step | Result |
|---|---|
| Insert into `auth.users` | `trg_auth_user_created` created a matching `profiles` row automatically |
| Upsert `profiles` with `{id, full_name, phone}` (Flutter's exact payload) | Succeeded — columns match exactly |
| Insert `businesses` with Flutter's 10-column `toInsertMap()` | Succeeded |
| Insert `customers` with opening_balance = 1000 | Succeeded; `current_balance` auto-set to 1000.00 by trigger |
| Insert `ledger_entries` credit of 500 | `balance_after` = 1500.00; `customers.current_balance` = 1500.00 |
| Insert `ledger_entries` debit of 200 | `balance_after` = 1300.00; `customers.current_balance` = 1300.00 |
| Soft-delete the credit entry (`is_deleted = true`) | `customers.current_balance` reversed correctly to 800.00 |
| Query `business_dashboard_summary` | Reflected total_receivable = 800.00, matching the ledger |
| Check `rowsecurity` on all 25 public tables | All `true` |

Full command transcript and output is reproducible from the steps above;
the test database was dropped after verification (no persistent state was
left behind).

## Object counts (final schema)

| Object type | Count |
|---|---|
| Tables | 25 |
| Views | 2 |
| Custom functions | 8 |
| Triggers | 10 |
| RLS policies | 54 |
| Foreign keys | 48 |
| Storage buckets | 5 |

## Risk assessment

- **Zero risk** to the 4 tables Flutter actually uses today
  (`businesses`, `customers`, `ledger_entries`) — their structure is
  byte-for-byte unchanged from the original migrations.
- **One required, low-risk change**: `users` → `profiles` rename. Low risk
  because it's a rename (data-preserving), not a drop/recreate, and it is
  the only thing standing between the current schema and a working
  sign-up flow — without it, `auth_repository.dart` cannot function at
  all against the original migrations.
- **Zero risk** from the additive extras (`payment_methods`, the two
  dashboard views, the 5 storage buckets) — nothing in `lib/` references
  any of them yet, so they cannot change the behavior of any existing
  screen.

## Recommended next steps (not part of this migration, informational only)

1. When building the Cash Book / Bank Book / Inventory / Billing / Staff
   Flutter modules the README lists as "not yet built," their
   repositories can be written directly against the existing
   `cashbook_entries`, `bank_accounts`, `bank_transactions`, `categories`,
   `products`, `inventory_logs`, `invoices`, `invoice_items`, `staff`,
   `attendance`, `salary` tables — no further schema changes needed.
2. If you want new businesses to start with a default category list
   automatically, add an `after insert` trigger on `businesses` that
   inserts a few starter rows into `categories(business_id, name)` — not
   included here because "default categories" has no single objectively
   correct list and guessing one would violate the "do not guess" rule
   this task was run under; seeding it from the app's onboarding flow
   (where the user picks a business type) is the safer choice.
3. Resolve the phone/OTP-vs-email/password discrepancy between
   `README.md` and `auth_repository.dart` by either updating the README
   or switching the Supabase Auth provider configuration — purely a
   documentation/product decision, not something this migration needed to
   touch.
