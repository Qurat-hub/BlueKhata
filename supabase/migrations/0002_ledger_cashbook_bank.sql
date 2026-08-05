-- =============================================================
-- BlueKhata — Ledger, Cash Book, Bank Book (Migration 0002)
-- Powered by Zenvyro Labs
-- =============================================================

-- ---------------------------------------------------------------
-- ledger_entries: the core credit/debit customer ledger
-- ---------------------------------------------------------------
create table if not exists public.ledger_entries (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  type text not null check (type in ('credit','debit')),
  amount numeric(14,2) not null check (amount > 0),
  balance_after numeric(14,2) not null default 0,
  note text,
  category text,
  attachment_urls text[] not null default '{}',
  entry_date timestamptz not null default now(),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ledger_customer on public.ledger_entries(customer_id, entry_date desc);
create index if not exists idx_ledger_business on public.ledger_entries(business_id, entry_date desc);

drop trigger if exists trg_ledger_entries_touch on public.ledger_entries;
create trigger trg_ledger_entries_touch before update on public.ledger_entries
  for each row execute function public.touch_updated_at();

-- Applies a new entry's effect on the customer's running balance.
-- credit ("you gave") increases balance owed to you; debit ("you received") decreases it.
create or replace function public.apply_ledger_entry_balance()
returns trigger language plpgsql as $$
declare
  delta numeric(14,2);
  new_balance numeric(14,2);
begin
  delta := case when new.type = 'credit' then new.amount else -new.amount end;

  update public.customers
     set current_balance = current_balance + delta
   where id = new.customer_id
   returning current_balance into new_balance;

  new.balance_after := new_balance;
  return new;
end;
$$;

drop trigger if exists trg_ledger_entries_apply_balance on public.ledger_entries;
create trigger trg_ledger_entries_apply_balance
  before insert on public.ledger_entries
  for each row execute function public.apply_ledger_entry_balance();

-- Reverses a soft-deleted entry's effect on the running balance.
create or replace function public.reverse_ledger_entry_balance()
returns trigger language plpgsql as $$
declare
  delta numeric(14,2);
begin
  if new.is_deleted = true and old.is_deleted = false then
    delta := case when old.type = 'credit' then -old.amount else old.amount end;
    update public.customers
       set current_balance = current_balance + delta
     where id = old.customer_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_ledger_entries_reverse_on_delete on public.ledger_entries;
create trigger trg_ledger_entries_reverse_on_delete
  before update on public.ledger_entries
  for each row execute function public.reverse_ledger_entry_balance();

alter table public.ledger_entries enable row level security;

create policy ledger_entries_select on public.ledger_entries
  for select using (public.is_business_member(business_id));
create policy ledger_entries_insert on public.ledger_entries
  for insert with check (public.is_business_member(business_id) and created_by = auth.uid());
create policy ledger_entries_update on public.ledger_entries
  for update using (public.is_business_member(business_id));

-- ---------------------------------------------------------------
-- cashbook_entries: cash in / cash out / income / expense / transfer
-- ---------------------------------------------------------------
create table if not exists public.cashbook_entries (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('cash_in','cash_out','income','expense','transfer')),
  amount numeric(14,2) not null check (amount > 0),
  category text,
  note text,
  entry_date timestamptz not null default now(),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_cashbook_business on public.cashbook_entries(business_id, entry_date desc);

alter table public.cashbook_entries enable row level security;
create policy cashbook_select on public.cashbook_entries
  for select using (public.is_business_member(business_id));
create policy cashbook_insert on public.cashbook_entries
  for insert with check (public.is_business_member(business_id) and created_by = auth.uid());

-- ---------------------------------------------------------------
-- bank_accounts + bank_transactions
-- ---------------------------------------------------------------
create table if not exists public.bank_accounts (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  bank_name text not null,
  account_title text not null,
  account_number text,
  current_balance numeric(14,2) not null default 0,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.bank_transactions (
  id uuid primary key default uuid_generate_v4(),
  bank_account_id uuid not null references public.bank_accounts(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('deposit','withdrawal','transfer','cheque')),
  amount numeric(14,2) not null check (amount > 0),
  note text,
  cheque_number text,
  cheque_status text check (cheque_status in ('pending','cleared','bounced')),
  entry_date timestamptz not null default now(),
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_bank_txn_account on public.bank_transactions(bank_account_id, entry_date desc);

alter table public.bank_accounts enable row level security;
alter table public.bank_transactions enable row level security;

create policy bank_accounts_select on public.bank_accounts
  for select using (public.is_business_member(business_id));
create policy bank_accounts_write on public.bank_accounts
  for all using (public.is_business_member(business_id));

create policy bank_txn_select on public.bank_transactions
  for select using (public.is_business_member(business_id));
create policy bank_txn_insert on public.bank_transactions
  for insert with check (public.is_business_member(business_id) and created_by = auth.uid());
