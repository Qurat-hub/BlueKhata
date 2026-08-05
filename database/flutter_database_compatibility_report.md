# Flutter ↔ Database Compatibility Report — BlueKhata

## Method

Every file under `lib/` was scanned for Supabase call sites:
`.from(`, `.insert(`, `.update(`, `.delete(`, `.select(`, `.rpc(`, `.storage`,
`.bucket(`, `.auth`, `.onConflict(`, `.eq(`, `.order(`, `.stream(`.

Call sites found, by file:

| File | Tables touched |
|---|---|
| `auth_repository.dart` | `profiles` |
| `business_repository.dart` | `businesses` |
| `customer_repository.dart` | `customers` |
| `ledger_repository.dart` | `ledger_entries` |
| `sync_queue_service.dart` | generic — replays whatever table name is queued (no schema assumption of its own) |

No other file (`dashboard_screen.dart`, providers, screens, `main.dart`) makes
a direct Supabase call — they all go through the repositories above. That
means the entire compatibility surface is these 4 table names plus whatever
columns their corresponding entity/model files (`toInsertMap()` /
`fromMap()`) reference.

The existing `supabase/migrations/0001–0004` were then diffed column-by-column
against those 4 repositories.

## Result: 1 breaking mismatch found

### ❌ `profiles` (Flutter) vs `users` (database)

**Flutter expects**, in `auth_repository.dart`:
```dart
_client.from('profiles').select().eq('id', user.id).maybeSingle();
_client.from('profiles').upsert({'id': id, 'full_name': fullName, 'phone': phone});
```

**Database contained** (migration 0001): a table named `public.users` with a
column `display_name` — no `full_name` column, and no `profiles` table at
all.

**Impact:** every sign-up and every `ensureProfile()` call would have thrown
`PostgrestException: relation "public.profiles" does not exist` (or, if
someone patched it by bolting on an empty `profiles` table without touching
`users`, the app would silently write into an orphaned table while every
foreign key in the rest of the schema still pointed at `users`).

**Fix applied:** `public.users` is renamed to `public.profiles`, its name
column is renamed `display_name` → `full_name` (matching the exact upsert
payload), and every foreign key in the other 21 tables that referenced
`public.users(id)` (businesses.owner_id, customers.created_by,
ledger_entries.created_by, staff.user_id, audit_logs.user_id, etc. — 15
references total) now points at `public.profiles(id)`. `is_super_admin()`
was updated to read `profiles.role` accordingly. This is a rename, not a
new/duplicate table, so there's exactly one profile row per user, matching
what the app's `upsert` logic assumes.

## Result: everything else matched exactly

### `businesses`
Flutter's `Business.fromMap`/`toInsertMap()` (business.dart) reference:
`id, owner_id, name, logo_url, banner_url, business_type, currency, address,
tax_number, phone, email, is_archived, created_at`, plus
`business_repository.dart` additionally uses `is_deleted, deleted_at` for
soft delete. **All present in migration 0001, unchanged.**

### `customers`
`Customer.fromMap`/`toInsertMap()` (customer.dart) reference: `id,
business_id, name, phone, address, cnic, image_url, opening_balance,
credit_limit, notes, tags, is_favorite, is_supplier, current_balance,
created_at`, plus `is_deleted, deleted_at` for soft delete/restore.
**All present in migration 0001, unchanged.** `tags` is `text[]` in the DB,
matching the `List<String>` the model expects.

### `ledger_entries`
`LedgerEntry.fromMap`/`toInsertMap()` (ledger_entry.dart) reference: `id,
business_id, customer_id, type, amount, balance_after, note, category,
attachment_urls, entry_date, created_at, created_by`, plus `is_deleted,
deleted_at` for soft delete. **All present in migration 0002, unchanged.**
The `type` check constraint (`'credit'`/`'debit'`) matches
`LedgerEntryType.credit`/`.debit` exactly.

The comment in `ledger_repository.dart` explicitly names the two triggers it
depends on — `trg_ledger_entries_apply_balance` and
`trg_ledger_entries_reverse_on_delete` — both exist in migration 0002 and
were verified end-to-end against a live Postgres instance (see
`migration_report.md` → "Verification performed").

## Repositories that don't exist yet (README-confirmed)

`lib/README.md` explicitly lists these as schema-ready but not yet wired to
a Flutter repository: Cash Book, Bank Book, Inventory/Barcode, Billing/
Invoices, Staff/Payroll, Reminders, Notifications (push), Admin panel,
Backup/Restore. Their tables (`cashbook_entries`, `bank_accounts`,
`bank_transactions`, `categories`, `products`, `inventory_logs`, `invoices`,
`invoice_items`, `staff`, `attendance`, `salary`, `reminders`,
`notifications`, `announcements`, `banners`, `settings`, `audit_logs`,
`deleted_records`, `backup_history`) were carried into the installer
unchanged in structure (only their `*_by`/`user_id` foreign keys were
retargeted from `users` to `profiles`, same as everywhere else). There is
nothing in `lib/` yet to be incompatible with them.

## Non-schema observation (does not affect the database)

`README.md` describes the auth flow as "Supabase phone/OTP authentication,"
but `auth_repository.dart` actually implements email + password
(`signUp`, `signInWithPassword`, `resetPasswordForEmail`). This is a
documentation/code mismatch, not a database mismatch — no schema change is
needed either way, since `auth.users` and `public.profiles` support both
flows identically. Flagged here in case it's relevant to your Supabase Auth
provider configuration (Phone provider vs Email provider).

## Summary table

| Flutter expects | Database had | Status |
|---|---|---|
| `profiles.id` | `users.id` | Fixed — table renamed |
| `profiles.full_name` | `users.display_name` | Fixed — column renamed |
| `profiles.phone` | `users.phone` | OK (name already matched) |
| `businesses.*` (12 cols) | `businesses.*` | OK — exact match |
| `customers.*` (13 cols) | `customers.*` | OK — exact match |
| `ledger_entries.*` (12 cols) | `ledger_entries.*` | OK — exact match |
| Any other table | — | Not yet called by Flutter; carried over unchanged |
