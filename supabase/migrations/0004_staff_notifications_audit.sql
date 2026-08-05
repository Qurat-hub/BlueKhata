-- =============================================================
-- BlueKhata — Staff Book, Reminders, Notifications, Admin, Audit
-- Migration 0004 — Powered by Zenvyro Labs
-- =============================================================

create table if not exists public.staff (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid references public.users(id),
  full_name text not null,
  phone text,
  role_title text,
  monthly_salary numeric(14,2) default 0,
  joined_at date default current_date,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default uuid_generate_v4(),
  staff_id uuid not null references public.staff(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  date date not null,
  status text not null check (status in ('present','absent','leave','half_day')),
  check_in time,
  check_out time,
  created_at timestamptz not null default now(),
  unique(staff_id, date)
);

create table if not exists public.salary (
  id uuid primary key default uuid_generate_v4(),
  staff_id uuid not null references public.staff(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  month date not null,
  base_amount numeric(14,2) not null default 0,
  bonus numeric(14,2) not null default 0,
  advance numeric(14,2) not null default 0,
  overtime numeric(14,2) not null default 0,
  net_paid numeric(14,2) not null default 0,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- reminders (payment due / recovery reminders)
-- ---------------------------------------------------------------
create table if not exists public.reminders (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  remind_at timestamptz not null,
  channel text not null default 'push' check (channel in ('push','sms','whatsapp')),
  recurring boolean not null default false,
  recurrence_interval_days integer,
  status text not null default 'pending' check (status in ('pending','sent','dismissed')),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_reminders_due on public.reminders(remind_at) where status = 'pending';

-- ---------------------------------------------------------------
-- notifications (per-user inbox, fed by FCM sends)
-- ---------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id) on delete cascade,
  business_id uuid references public.businesses(id),
  type text not null check (type in (
    'announcement','business_update','payment_reminder','due_reminder',
    'inventory_alert','low_stock','invoice_created','invoice_paid',
    'promotional_campaign','system_update','emergency_alert'
  )),
  title text not null,
  body text,
  data jsonb default '{}',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);

-- ---------------------------------------------------------------
-- Admin-managed content
-- ---------------------------------------------------------------
create table if not exists public.announcements (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  body text not null,
  is_active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.banners (
  id uuid primary key default uuid_generate_v4(),
  image_url text not null,
  link_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- audit_logs / deleted_records / backup_history
-- ---------------------------------------------------------------
create table if not exists public.audit_logs (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid references public.businesses(id),
  user_id uuid references public.users(id),
  action text not null,
  table_name text,
  record_id uuid,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.deleted_records (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid references public.businesses(id),
  table_name text not null,
  record_id uuid not null,
  record_snapshot jsonb not null,
  deleted_by uuid references public.users(id),
  deleted_at timestamptz not null default now()
);

create table if not exists public.backup_history (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid references public.businesses(id),
  initiated_by uuid references public.users(id),
  backup_url text,
  status text not null default 'completed' check (status in ('pending','completed','failed')),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------
alter table public.staff enable row level security;
alter table public.attendance enable row level security;
alter table public.salary enable row level security;
alter table public.reminders enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.deleted_records enable row level security;
alter table public.backup_history enable row level security;

create policy staff_all on public.staff for all using (public.is_business_member(business_id));
create policy attendance_all on public.attendance for all using (public.is_business_member(business_id));
create policy salary_all on public.salary for all using (public.is_business_member(business_id));
create policy reminders_all on public.reminders for all using (public.is_business_member(business_id));
create policy notifications_select on public.notifications for select using (user_id = auth.uid());
create policy audit_logs_select on public.audit_logs for select using (public.is_business_member(business_id));
create policy deleted_records_select on public.deleted_records for select using (public.is_business_member(business_id));
create policy backup_history_select on public.backup_history for select using (public.is_business_member(business_id));

-- announcements/banners/settings: public read, admin-only write.
alter table public.announcements enable row level security;
alter table public.banners enable row level security;
alter table public.settings enable row level security;

create or replace function public.is_super_admin()
returns boolean language sql stable as $$
  select exists (select 1 from public.users u where u.id = auth.uid() and u.role = 'super_admin');
$$;

create policy announcements_select on public.announcements for select using (is_active = true);
create policy announcements_admin_write on public.announcements for all using (public.is_super_admin());

create policy banners_select on public.banners for select using (is_active = true);
create policy banners_admin_write on public.banners for all using (public.is_super_admin());

create policy settings_select on public.settings for select using (true);
create policy settings_admin_write on public.settings for all using (public.is_super_admin());
