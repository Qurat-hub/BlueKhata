# BlueKhata Database Verification Checklist

All items below were actually checked by running the installer against a
real Postgres 16 instance (not just visual inspection) — see
`migration_report.md` for the exact commands.

## Pre-flight (Step 1–4 of the original request)

- [x] Every `.dart` file under `lib/` scanned for `.from(`, `.insert(`,
      `.update(`, `.delete(`, `.select(`, `.rpc(`, `.storage`, `.bucket(`,
      `.auth`, `.onConflict(`, `.eq(`, `.order(`, `.stream(`
- [x] Every table/column/FK/enum/constraint/index/function/trigger/view/
      bucket/RLS policy in `supabase/migrations/0001–0004` catalogued
- [x] Every repository (`AuthRepository`, `BusinessRepository`,
      `CustomerRepository`, `LedgerRepository`) verified query-by-query
      against the schema
- [x] `SyncQueueService` checked — confirmed generic/table-agnostic, no
      independent schema assumptions
- [x] Dashboard, providers, and screens scanned for any Supabase call not
      already covered by a repository — none found
- [x] Mismatches catalogued in `flutter_database_compatibility_report.md`
      (1 found: `profiles` vs `users`)

## SQL installer correctness (Step 7 of the original request)

- [x] No duplicate tables — every `create table` uses `if not exists`
- [x] No duplicate policies — every `create policy` is preceded by
      `drop policy if exists` on the same name/table, confirmed by running
      the installer **twice in a row** with zero errors
- [x] No missing foreign keys — 48 FKs created successfully in one pass;
      cross-checked against `database_relationships.md`
- [x] No circular dependencies — installer runs top-to-bottom in a single
      transaction-free pass with no forward-reference errors (strict
      dependency order: extensions → shared functions → profiles →
      businesses → business_members → customers → everything else)
- [x] No invalid triggers — all 10 triggers created and 2 of them
      (`trg_ledger_entries_apply_balance`,
      `trg_ledger_entries_reverse_on_delete`) functionally verified with
      real insert/update statements producing the expected balances
- [x] No missing functions — all 8 custom functions created before first
      use (verified: `is_business_member` is defined after
      `business_members` exists but before any policy references it)
- [x] No syntax errors — full file executed with `ON_ERROR_STOP=1` and
      exited 0
- [x] Compatible with current Supabase Postgres (16.x) — tested directly
      against Postgres 16.14

## Functional verification performed (beyond static checks)

- [x] Simulated Supabase auth signup (`auth.users` insert) → confirmed
      `trg_auth_user_created` auto-creates a `profiles` row
- [x] Simulated Flutter's exact `profiles` upsert payload
      (`id, full_name, phone`) → succeeded, columns match exactly
- [x] Simulated `BusinessRepository.createBusiness()` insert payload →
      succeeded, all 10 columns accepted
- [x] Simulated `CustomerRepository.createCustomer()` insert payload →
      succeeded; confirmed `current_balance` auto-initialized from
      `opening_balance` (1000 → 1000)
- [x] Simulated `LedgerRepository.addEntry()` for a credit of 500 →
      confirmed `balance_after` = 1500 and `customers.current_balance`
      updated to 1500 by the trigger (not client-side)
- [x] Simulated a second entry, a debit of 200 → confirmed balance drops
      to 1300
- [x] Simulated `LedgerRepository.softDeleteEntry()` on the credit entry →
      confirmed the reversal trigger correctly recomputes
      `current_balance` back down to 800 (1300 − 500)
- [x] Queried `business_dashboard_summary` view → confirmed it reflects
      the same 800 receivable balance
- [x] Confirmed Row Level Security is enabled (`rowsecurity = true`) on
      all 25 public tables
- [x] Confirmed all 5 storage buckets were created and are queryable

## Deliverables produced (Step 8 of the original request)

- [x] `bluekhata_complete_database.sql` — single, idempotent installer
- [x] `database_schema.md`
- [x] `database_relationships.md`
- [x] `database_checklist.md` — this file
- [x] `flutter_database_compatibility_report.md`
- [x] `migration_report.md`

## What was intentionally NOT changed

- [x] No Flutter/Dart file was modified — the fix is 100% on the database
      side, per the "Flutter is the source of truth" instruction
- [x] No table structure was invented beyond what the original migrations
      + the install spec's explicit deliverable list called for
      (`payment_methods`, dashboard views, storage buckets — all clearly
      marked "ADDITIVE" in the SQL and in `database_schema.md`, and none
      of them can break any existing Flutter query since nothing in
      `lib/` references them yet)
