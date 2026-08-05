# BlueKhata Database Schema Reference

25 tables · 2 views · 8 custom functions · 10 triggers · 54 RLS policies ·
48 foreign keys · 5 storage buckets. Verified by executing the installer
twice in a row (idempotency) and end-to-end against a live Postgres 16
instance (see `migration_report.md`).

Legend: 🟢 = actively used by the current Flutter code. ⚪ = schema-ready,
not yet called by any Flutter repository (per README's module status).

---

## 🟢 `profiles`
*(renamed from the original migration's `users` — see
`flutter_database_compatibility_report.md`)*

| Column | Type | Null | Default |
|---|---|---|---|
| id | uuid PK | no | — (FK → `auth.users.id`, cascade delete) |
| full_name | text | yes | — |
| phone | text | yes | — |
| avatar_url | text | yes | — |
| preferred_language | text | yes | `'en'` |
| role | text | no | `'business_owner'` — check: `super_admin, business_owner, manager, cashier, staff, viewer` |
| is_blocked | boolean | no | `false` |
| created_at | timestamptz | no | `now()` |
| updated_at | timestamptz | no | `now()` |

Triggers: `trg_profiles_touch` (updated_at). Also: `trg_auth_user_created`
on `auth.users` auto-inserts a bare profile row on signup (belt-and-braces;
Flutter's own upsert still runs on top of it).
RLS: select/update/insert self only (`id = auth.uid()`).

## 🟢 `businesses`

| Column | Type | Null | Default |
|---|---|---|---|
| id | uuid PK | no | `uuid_generate_v4()` |
| owner_id | uuid FK → profiles.id | no | — |
| name | text | no | — |
| logo_url | text | yes | — |
| banner_url | text | yes | — |
| business_type | text | yes | `'General'` |
| currency | text | no | `'PKR'` |
| address | text | yes | — |
| tax_number | text | yes | — |
| phone | text | yes | — |
| email | text | yes | — |
| is_archived | boolean | no | `false` |
| is_deleted | boolean | no | `false` |
| deleted_at | timestamptz | yes | — |
| created_by | uuid FK → profiles.id | yes | — |
| created_at / updated_at | timestamptz | no | `now()` |

Index: `idx_businesses_owner(owner_id)`. Trigger: `trg_businesses_touch`.
RLS: select via `is_business_member(id)`; insert/update/delete require
`owner_id = auth.uid()`.

## ⚪ `business_members`
Role-based access per business. Columns: `id, business_id→businesses,
user_id→profiles, role (owner|manager|cashier|staff|viewer), status
(active|invited|removed), created_at`. Unique `(business_id, user_id)`.
Indexes on both FK columns. RLS: select for members; write restricted to
the business owner.

## 🟢 `customers`
*(also represents suppliers/vendors via `is_supplier`)*

| Column | Type | Null | Default |
|---|---|---|---|
| id | uuid PK | no | `uuid_generate_v4()` |
| business_id | uuid FK → businesses.id | no | — |
| name | text | no | — |
| phone / address / cnic / image_url | text | yes | — |
| opening_balance | numeric(14,2) | no | `0` |
| current_balance | numeric(14,2) | no | `0` (server-maintained, see trigger) |
| credit_limit | numeric(14,2) | yes | — |
| notes | text | yes | — |
| tags | text[] | no | `'{}'` |
| is_favorite / is_supplier | boolean | no | `false` |
| is_deleted | boolean | no | `false` |
| deleted_at | timestamptz | yes | — |
| created_by | uuid FK → profiles.id | yes | — |
| created_at / updated_at | timestamptz | no | `now()` |

Indexes: `idx_customers_business`, trigram GIN index on `name` for fast
`ilike` search (matches `customer_repository.dart`'s search-by-name).
Triggers: `trg_customers_initial_balance` (before insert, copies
`opening_balance` → `current_balance`), `trg_customers_touch`.
RLS: full CRUD gated by `is_business_member(business_id)`.

## 🟢 `ledger_entries`
The core credit/debit ledger.

| Column | Type | Null | Default |
|---|---|---|---|
| id | uuid PK | no | `uuid_generate_v4()` |
| business_id | uuid FK → businesses.id | no | — |
| customer_id | uuid FK → customers.id | no | — |
| type | text, check `credit|debit` | no | — |
| amount | numeric(14,2), check `> 0` | no | — |
| balance_after | numeric(14,2) | no | `0` (server-computed) |
| note / category | text | yes | — |
| attachment_urls | text[] | no | `'{}'` |
| entry_date | timestamptz | no | `now()` |
| is_deleted | boolean | no | `false` |
| deleted_at | timestamptz | yes | — |
| created_by | uuid FK → profiles.id | no | — |
| created_at / updated_at | timestamptz | no | `now()` |

Indexes: `(customer_id, entry_date desc)`, `(business_id, entry_date desc)`.
Triggers (both verified end-to-end, see `migration_report.md`):
- `trg_ledger_entries_apply_balance` — before insert, adds/subtracts
  `amount` from `customers.current_balance` and stamps `balance_after`.
- `trg_ledger_entries_reverse_on_delete` — before update, reverses the
  balance effect when `is_deleted` flips `false → true` (soft delete).

RLS: select for members; insert requires `created_by = auth.uid()`; update
for members (used by soft delete).

## ⚪ `cashbook_entries`
`id, business_id, type (cash_in|cash_out|income|expense|transfer),
amount (>0), category, note, entry_date, is_deleted, deleted_at,
created_by, created_at`. RLS: select for members, insert requires
`created_by = auth.uid()`.

## ⚪ `bank_accounts` / `bank_transactions`
`bank_accounts`: `id, business_id, bank_name, account_title,
account_number, current_balance, is_deleted, created_at`.
`bank_transactions`: `id, bank_account_id→bank_accounts, business_id,
type (deposit|withdrawal|transfer|cheque), amount (>0), note,
cheque_number, cheque_status (pending|cleared|bounced), entry_date,
created_by, created_at`.

## ⚪ `categories` / `products` / `inventory_logs`
`categories`: `id, business_id, name, created_at`.
`products`: `id, business_id, category_id→categories, name, sku, barcode,
unit, purchase_price, selling_price, stock_quantity,
low_stock_threshold, supplier_id→customers, image_url, is_deleted,
created_by, created_at, updated_at`.
`inventory_logs`: `id, business_id, product_id→products,
change_type (purchase|sale|adjustment|return), quantity_delta, note,
created_by, created_at`. Trigger `trg_inventory_logs_apply` keeps
`products.stock_quantity` in sync after every insert.

## ⚪ `invoices` / `invoice_items`
`invoices`: `id, business_id, customer_id→customers,
invoice_type (invoice|quotation|receipt|purchase_bill), invoice_number
(unique per business), status (paid|pending|partial|cancelled), subtotal,
discount, tax, total, amount_paid, notes, is_deleted, created_by,
created_at, updated_at`.
`invoice_items`: `id, invoice_id→invoices, product_id→products,
description, quantity, unit_price, line_total`.

## ⚪ `staff` / `attendance` / `salary`
`staff`: `id, business_id, user_id→profiles, full_name, phone,
role_title, monthly_salary, joined_at, is_active, created_at`.
`attendance`: `id, staff_id→staff, business_id, date,
status (present|absent|leave|half_day), check_in, check_out,
created_at`, unique `(staff_id, date)`.
`salary`: `id, staff_id→staff, business_id, month, base_amount, bonus,
advance, overtime, net_paid, paid_at, created_at`.

## ⚪ `reminders`
`id, business_id, customer_id→customers, remind_at,
channel (push|sms|whatsapp), recurring, recurrence_interval_days,
status (pending|sent|dismissed), created_by, created_at`. Partial index
on `remind_at where status = 'pending'`.

## ⚪ `notifications`
`id, user_id→profiles, business_id→businesses, type (11 allowed values —
announcement, business_update, payment_reminder, due_reminder,
inventory_alert, low_stock, invoice_created, invoice_paid,
promotional_campaign, system_update, emergency_alert), title, body,
data (jsonb), is_read, created_at`. RLS: only the owning user can select.

## ⚪ `announcements` / `banners` / `settings`
Admin-managed content. `announcements`/`banners`: public read when
`is_active = true`, write restricted to `is_super_admin()`. `settings`:
`key` (PK) / `value` (jsonb) — public read, admin-only write.

## ⚪ `audit_logs` / `deleted_records` / `backup_history`
`audit_logs`: `id, business_id, user_id→profiles, action, table_name,
record_id, before_data (jsonb), after_data (jsonb), created_at`.
`deleted_records`: full JSON snapshot of anything soft/hard-deleted, for
recovery. `backup_history`: `status (pending|completed|failed)` tracking.

## ⚪ `payment_methods` — ADDITIVE
Not called by Flutter yet. `id, business_id→businesses (nullable = global
default), name, is_default, is_active, created_at`, unique
`(business_id, name)`. Seeded with 6 global defaults (Cash, Bank Transfer,
JazzCash, EasyPaisa, Cheque, Credit Card) — see `migration_report.md`.

## Views — ADDITIVE
- `business_dashboard_summary` — per-business customer count, total
  receivable, total payable.
- `daily_ledger_summary` — per-business, per-day credit/debit totals.

## Storage buckets — ADDITIVE
`avatars` (public), `business-assets` (public), `customer-images`
(public), `ledger-attachments` (private), `product-images` (public).
Folder convention: `<bucket>/<business_id_or_user_id>/<file>`, enforced by
storage policies using `is_business_member()` (or `auth.uid()` for
avatars).

## Shared functions
- `touch_updated_at()` — generic `updated_at = now()` on any row update.
- `is_business_member(business_id)` — true if the caller owns or is an
  active member of that business. Used in nearly every RLS policy.
- `is_super_admin()` — true if `profiles.role = 'super_admin'`.
- `set_customer_initial_balance()` — copies `opening_balance` into
  `current_balance` on customer insert.
- `apply_ledger_entry_balance()` / `reverse_ledger_entry_balance()` —
  keep `customers.current_balance` and `ledger_entries.balance_after`
  correct and race-safe (server-side, not client-computed).
- `apply_inventory_log()` — keeps `products.stock_quantity` in sync.
- `handle_new_auth_user()` — auto-creates a `profiles` row on signup.
