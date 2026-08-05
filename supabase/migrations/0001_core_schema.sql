-- =============================================================
-- BlueKhata — Core Schema (Migration 0001)
-- Users, Businesses, Business Members, Customers
-- Powered by Zenvyro Labs
-- =============================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------
-- users: mirrors auth.users with app-specific profile fields
-- ---------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  display_name text,
  avatar_url text,
  preferred_language text default 'en',
  role text not null default 'business_owner'
    check (role in ('super_admin','business_owner','manager','cashier','staff','viewer')),
  is_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- businesses
-- ---------------------------------------------------------------
create table if not exists public.businesses (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  logo_url text,
  banner_url text,
  business_type text default 'General',
  currency text not null default 'PKR',
  address text,
  tax_number text,
  phone text,
  email text,
  is_archived boolean not null default false,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_businesses_owner on public.businesses(owner_id);

-- ---------------------------------------------------------------
-- business_members: role-based access per business
-- ---------------------------------------------------------------
create table if not exists public.business_members (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'staff'
    check (role in ('owner','manager','cashier','staff','viewer')),
  status text not null default 'active' check (status in ('active','invited','removed')),
  created_at timestamptz not null default now(),
  unique(business_id, user_id)
);

create index if not exists idx_business_members_business on public.business_members(business_id);
create index if not exists idx_business_members_user on public.business_members(user_id);

-- ---------------------------------------------------------------
-- customers (also used for suppliers/vendors/dealers via is_supplier)
-- ---------------------------------------------------------------
create table if not exists public.customers (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  phone text,
  address text,
  cnic text,
  image_url text,
  opening_balance numeric(14,2) not null default 0,
  current_balance numeric(14,2) not null default 0,
  credit_limit numeric(14,2),
  notes text,
  tags text[] not null default '{}',
  is_favorite boolean not null default false,
  is_supplier boolean not null default false,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_customers_business on public.customers(business_id);
create index if not exists idx_customers_name on public.customers using gin (name gin_trgm_ops);
create extension if not exists pg_trgm;

-- Initialize current_balance from opening_balance on insert.
create or replace function public.set_customer_initial_balance()
returns trigger language plpgsql as $$
begin
  new.current_balance := coalesce(new.opening_balance, 0);
  return new;
end;
$$;

drop trigger if exists trg_customers_initial_balance on public.customers;
create trigger trg_customers_initial_balance
  before insert on public.customers
  for each row execute function public.set_customer_initial_balance();

-- ---------------------------------------------------------------
-- updated_at maintenance (generic, reused by all tables)
-- ---------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_businesses_touch on public.businesses;
create trigger trg_businesses_touch before update on public.businesses
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_customers_touch on public.customers;
create trigger trg_customers_touch before update on public.customers
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_users_touch on public.users;
create trigger trg_users_touch before update on public.users
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------
alter table public.users enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.customers enable row level security;

-- users: a user can read/update only their own profile row.
create policy users_select_self on public.users
  for select using (id = auth.uid());
create policy users_update_self on public.users
  for update using (id = auth.uid());
create policy users_insert_self on public.users
  for insert with check (id = auth.uid());

-- helper: is the current user a member (any role) of a business?
create or replace function public.is_business_member(target_business_id uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.businesses b
    where b.id = target_business_id and b.owner_id = auth.uid()
  ) or exists (
    select 1 from public.business_members m
    where m.business_id = target_business_id
      and m.user_id = auth.uid()
      and m.status = 'active'
  );
$$;

-- businesses: owners manage their own; members can read.
create policy businesses_select on public.businesses
  for select using (public.is_business_member(id));
create policy businesses_insert on public.businesses
  for insert with check (owner_id = auth.uid());
create policy businesses_update on public.businesses
  for update using (owner_id = auth.uid());
create policy businesses_delete on public.businesses
  for delete using (owner_id = auth.uid());

-- business_members: visible to members of the same business; managed by owner/manager.
create policy business_members_select on public.business_members
  for select using (public.is_business_member(business_id));
create policy business_members_write on public.business_members
  for all using (
    exists (select 1 from public.businesses b where b.id = business_id and b.owner_id = auth.uid())
  );

-- customers: scoped strictly to business members.
create policy customers_select on public.customers
  for select using (public.is_business_member(business_id));
create policy customers_insert on public.customers
  for insert with check (public.is_business_member(business_id));
create policy customers_update on public.customers
  for update using (public.is_business_member(business_id));
create policy customers_delete on public.customers
  for delete using (public.is_business_member(business_id));
