# BlueKhata Database Relationships

## Entity relationship overview

```
auth.users (Supabase-managed)
  │ 1:1 (id, cascade)
  ▼
profiles ──────────────────────────────────────────────┐
  │ 1:N (owner_id)                                       │ referenced by
  ▼                                                       │ created_by / user_id /
businesses                                                │ deleted_by / initiated_by
  │ 1:N                          ┌─────────────────────────┘ on nearly every table
  ├──> business_members ─────────┘ (N:M profiles ↔ businesses)
  ├──> customers
  │      │ 1:N
  │      ├──> ledger_entries
  │      ├──> reminders
  │      └──> invoices (nullable FK — invoice can exist without a customer,
  │            e.g. a walk-in cash sale)
  ├──> cashbook_entries
  ├──> bank_accounts ──> bank_transactions
  ├──> categories ──> products ──> inventory_logs
  │                       │ nullable FK
  │                       └──> supplier_id → customers (a customer row
  │                            flagged is_supplier=true can supply products)
  ├──> invoices ──> invoice_items ──> product_id → products (nullable)
  ├──> staff ──> attendance
  │       └────> salary
  ├──> notifications (business_id nullable — can be a global/system notice)
  ├──> payment_methods (business_id nullable — null = global default)
  ├──> audit_logs / deleted_records / backup_history
  └──> announcements / banners / settings  (global, no business_id)
```

## Foreign key inventory (48 total)

| Child table | Column | Parent table | On delete |
|---|---|---|---|
| profiles | id | auth.users | cascade |
| businesses | owner_id | profiles | cascade |
| businesses | created_by | profiles | (none) |
| business_members | business_id | businesses | cascade |
| business_members | user_id | profiles | cascade |
| customers | business_id | businesses | cascade |
| customers | created_by | profiles | (none) |
| ledger_entries | business_id | businesses | cascade |
| ledger_entries | customer_id | customers | cascade |
| ledger_entries | created_by | profiles | (none) |
| cashbook_entries | business_id | businesses | cascade |
| cashbook_entries | created_by | profiles | (none) |
| bank_accounts | business_id | businesses | cascade |
| bank_transactions | bank_account_id | bank_accounts | cascade |
| bank_transactions | business_id | businesses | cascade |
| bank_transactions | created_by | profiles | (none) |
| categories | business_id | businesses | cascade |
| products | business_id | businesses | cascade |
| products | category_id | categories | (none) |
| products | supplier_id | customers | (none) |
| products | created_by | profiles | (none) |
| inventory_logs | business_id | businesses | cascade |
| inventory_logs | product_id | products | cascade |
| inventory_logs | created_by | profiles | (none) |
| invoices | business_id | businesses | cascade |
| invoices | customer_id | customers | (none) |
| invoices | created_by | profiles | (none) |
| invoice_items | invoice_id | invoices | cascade |
| invoice_items | product_id | products | (none) |
| staff | business_id | businesses | cascade |
| staff | user_id | profiles | (none) |
| attendance | staff_id | staff | cascade |
| attendance | business_id | businesses | cascade |
| salary | staff_id | staff | cascade |
| salary | business_id | businesses | cascade |
| reminders | business_id | businesses | cascade |
| reminders | customer_id | customers | cascade |
| reminders | created_by | profiles | (none) |
| notifications | user_id | profiles | cascade |
| notifications | business_id | businesses | (none) |
| announcements | created_by | profiles | (none) |
| audit_logs | business_id | businesses | (none) |
| audit_logs | user_id | profiles | (none) |
| deleted_records | business_id | businesses | (none) |
| deleted_records | deleted_by | profiles | (none) |
| backup_history | business_id | businesses | (none) |
| backup_history | initiated_by | profiles | (none) |
| payment_methods | business_id | businesses | cascade |

No circular dependencies: the graph is a strict DAG rooted at
`auth.users → profiles → businesses`, with every other table hanging off
`businesses` (directly or via `customers`/`staff`/`bank_accounts`/
`products`/`invoices`). Verified by executing the installer against a real
Postgres instance in a single pass with no forward-reference errors (see
`migration_report.md`).

## Cascade behavior notes

- Deleting a `businesses` row cascades to nearly everything under it
  (customers, ledger_entries, staff, products, etc.) — this is the "hard
  delete" path. The app itself never calls it; `BusinessRepository.
  deleteBusiness()` only sets `is_deleted = true` (soft delete). Hard
  delete via `on delete cascade` is a safety net for admin cleanup, not
  something Flutter triggers directly.
- `profiles` cascades from `auth.users` — deleting an auth user removes
  their profile, but *not* the businesses they own (`created_by`/
  `owner_id` on `businesses` only cascades from `profiles`, not the other
  way around — so businesses a deleted user owned would need manual
  reassignment; this mirrors the original migration's design).
- `ledger_entries`, `cashbook_entries`, `bank_transactions`, etc. reference
  `profiles` for `created_by` with no cascade — audit trail rows are never
  silently deleted just because a user account is removed.

## Data-flow relationships enforced by triggers (not FKs)

- `customers.current_balance` ← derived from `ledger_entries` via
  `apply_ledger_entry_balance()` / `reverse_ledger_entry_balance()`.
- `products.stock_quantity` ← derived from `inventory_logs` via
  `apply_inventory_log()`.
- `customers.current_balance` ← initialized from `customers.
  opening_balance` via `set_customer_initial_balance()` on insert.
