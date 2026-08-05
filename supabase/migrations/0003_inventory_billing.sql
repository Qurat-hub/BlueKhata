-- =============================================================
-- BlueKhata — Inventory & Billing (Migration 0003)
-- Powered by Zenvyro Labs
-- =============================================================

create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_id uuid references public.categories(id),
  name text not null,
  sku text,
  barcode text,
  unit text not null default 'pcs',
  purchase_price numeric(14,2) not null default 0,
  selling_price numeric(14,2) not null default 0,
  stock_quantity numeric(14,2) not null default 0,
  low_stock_threshold numeric(14,2) not null default 5,
  supplier_id uuid references public.customers(id),
  image_url text,
  is_deleted boolean not null default false,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_products_business on public.products(business_id);
create index if not exists idx_products_barcode on public.products(barcode);

drop trigger if exists trg_products_touch on public.products;
create trigger trg_products_touch before update on public.products
  for each row execute function public.touch_updated_at();

create table if not exists public.inventory_logs (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  change_type text not null check (change_type in ('purchase','sale','adjustment','return')),
  quantity_delta numeric(14,2) not null,
  note text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- Keeps products.stock_quantity in sync with inventory_logs.
create or replace function public.apply_inventory_log()
returns trigger language plpgsql as $$
begin
  update public.products
     set stock_quantity = stock_quantity + new.quantity_delta
   where id = new.product_id;
  return new;
end;
$$;

drop trigger if exists trg_inventory_logs_apply on public.inventory_logs;
create trigger trg_inventory_logs_apply
  after insert on public.inventory_logs
  for each row execute function public.apply_inventory_log();

create table if not exists public.invoices (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid references public.customers(id),
  invoice_type text not null default 'invoice'
    check (invoice_type in ('invoice','quotation','receipt','purchase_bill')),
  invoice_number text not null,
  status text not null default 'pending' check (status in ('paid','pending','partial','cancelled')),
  subtotal numeric(14,2) not null default 0,
  discount numeric(14,2) not null default 0,
  tax numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  amount_paid numeric(14,2) not null default 0,
  notes text,
  is_deleted boolean not null default false,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(business_id, invoice_number)
);

drop trigger if exists trg_invoices_touch on public.invoices;
create trigger trg_invoices_touch before update on public.invoices
  for each row execute function public.touch_updated_at();

create table if not exists public.invoice_items (
  id uuid primary key default uuid_generate_v4(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  product_id uuid references public.products(id),
  description text not null,
  quantity numeric(14,2) not null default 1,
  unit_price numeric(14,2) not null default 0,
  line_total numeric(14,2) not null default 0
);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.inventory_logs enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;

create policy categories_all on public.categories for all using (public.is_business_member(business_id));
create policy products_all on public.products for all using (public.is_business_member(business_id));
create policy inventory_logs_all on public.inventory_logs for all using (public.is_business_member(business_id));
create policy invoices_all on public.invoices for all using (public.is_business_member(business_id));
create policy invoice_items_all on public.invoice_items for all using (
  exists (select 1 from public.invoices i where i.id = invoice_id and public.is_business_member(i.business_id))
);
