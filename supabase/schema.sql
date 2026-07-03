-- ============================================================================
-- Resto POS — Supabase schema, triggers, and Row Level Security policies
-- Run this once against a fresh Supabase project (SQL Editor -> New query).
-- ============================================================================

create extension if not exists pgcrypto;

-- ============================================================================
-- 1. TABLES
-- ============================================================================

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('owner', 'kasir', 'karyawan')),
  created_at timestamptz not null default now()
);

create table if not exists menu_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references menu_categories(id) on delete set null,
  name text not null,
  description text,
  price numeric(12, 2) not null check (price >= 0),
  image_url text,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Bahan baku — intentionally NOT linked to menu_items (per product spec).
create table if not exists ingredients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  unit text not null,
  stock_quantity numeric(12, 2) not null default 0,
  created_at timestamptz not null default now()
);

-- One shopping trip (header) can cover several ingredients (items) — mirrors
-- orders/order_items so a single receipt can be recorded in one go.
create table if not exists ingredient_purchases (
  id uuid primary key default gen_random_uuid(),
  purchase_date date not null,
  notes text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists ingredient_purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references ingredient_purchases(id) on delete cascade,
  ingredient_id uuid not null references ingredients(id) on delete restrict,
  quantity numeric(12, 2) not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  total_price numeric(12, 2) not null check (total_price >= 0),
  created_at timestamptz not null default now()
);

-- One expense report (header) can cover several line items in one go.
create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null,
  notes text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists expense_items (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references expenses(id) on delete cascade,
  category text not null,
  description text,
  amount numeric(12, 2) not null check (amount >= 0),
  created_at timestamptz not null default now()
);

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  table_number text not null,
  customer_name text not null,
  order_date date not null default current_date,
  status text not null default 'on_process'
    check (status in ('on_process', 'served', 'paid')),
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  menu_item_id uuid references menu_items(id) on delete set null,
  quantity int not null default 1 check (quantity > 0),
  note text,
  price_at_order numeric(12, 2) not null check (price_at_order >= 0),
  created_at timestamptz not null default now()
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  payment_method text not null check (payment_method in ('cash', 'qris')),
  total_amount numeric(12, 2) not null check (total_amount >= 0),
  amount_given numeric(12, 2),
  change_amount numeric(12, 2),
  processed_by uuid references profiles(id) on delete set null,
  paid_at timestamptz not null default now()
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

create index if not exists idx_menu_items_category on menu_items(category_id);
create index if not exists idx_ingredient_purchases_date on ingredient_purchases(purchase_date);
create index if not exists idx_ingredient_purchase_items_purchase on ingredient_purchase_items(purchase_id);
create index if not exists idx_ingredient_purchase_items_ingredient on ingredient_purchase_items(ingredient_id);
create index if not exists idx_expenses_date on expenses(expense_date);
create index if not exists idx_expense_items_expense on expense_items(expense_id);
create index if not exists idx_orders_status on orders(status);
create index if not exists idx_orders_date on orders(order_date);
create index if not exists idx_order_items_order on order_items(order_id);
create index if not exists idx_payments_order on payments(order_id);

-- ============================================================================
-- 3. HELPER FUNCTIONS & TRIGGERS
-- ============================================================================

-- SECURITY DEFINER so RLS policies on `profiles` can call this without
-- recursively re-checking RLS on `profiles` itself.
create or replace function public.current_role()
returns text
language sql
security definer
set search_path = public
stable
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- Auto-creates a `profiles` row whenever a new `auth.users` row appears.
-- The Edge Function that creates kasir/karyawan accounts passes
-- `full_name`/`role` via user_metadata so this trigger sets the right role
-- immediately; self-service sign-ups default to 'kasir' and must be promoted
-- to 'owner' manually once (see README at the bottom of this file).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'kasir')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keeps `updated_at` accurate regardless of client clock.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_menu_items_updated_at on menu_items;
create trigger trg_menu_items_updated_at
  before update on menu_items
  for each row execute function public.set_updated_at();

drop trigger if exists trg_orders_updated_at on orders;
create trigger trg_orders_updated_at
  before update on orders
  for each row execute function public.set_updated_at();

-- Keeps `ingredients.stock_quantity` in sync with purchase history so the
-- app never has to do a read-modify-write from the client.
create or replace function public.apply_ingredient_purchase_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.ingredients
      set stock_quantity = stock_quantity + new.quantity
      where id = new.ingredient_id;
    return new;
  elsif tg_op = 'UPDATE' then
    update public.ingredients
      set stock_quantity = stock_quantity - old.quantity + new.quantity
      where id = new.ingredient_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.ingredients
      set stock_quantity = stock_quantity - old.quantity
      where id = old.ingredient_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_ingredient_purchase_stock on ingredient_purchase_items;
create trigger trg_ingredient_purchase_stock
  after insert or update or delete on ingredient_purchase_items
  for each row execute function public.apply_ingredient_purchase_stock();

-- ============================================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================================

alter table profiles enable row level security;
alter table menu_categories enable row level security;
alter table menu_items enable row level security;
alter table ingredients enable row level security;
alter table ingredient_purchases enable row level security;
alter table ingredient_purchase_items enable row level security;
alter table expenses enable row level security;
alter table expense_items enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table payments enable row level security;

-- ---- profiles -----------------------------------------------------------
-- No INSERT policy: rows are only ever created by the `handle_new_user`
-- trigger (SECURITY DEFINER) or the `create-employee` Edge Function
-- (service-role key) — both bypass RLS.

create policy "profiles_select_own_or_owner"
  on profiles for select to authenticated
  using (id = auth.uid() or public.current_role() = 'owner');

create policy "profiles_update_owner_only"
  on profiles for update to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "profiles_delete_owner_only"
  on profiles for delete to authenticated
  using (public.current_role() = 'owner');

-- ---- menu_categories / menu_items ----------------------------------------
-- Every signed-in role needs to read the menu (kasir builds orders, karyawan
-- doesn't need it but it's harmless); only the owner manages it.

create policy "menu_categories_select_all"
  on menu_categories for select to authenticated
  using (true);

create policy "menu_categories_write_owner"
  on menu_categories for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "menu_items_select_all"
  on menu_items for select to authenticated
  using (true);

create policy "menu_items_write_owner"
  on menu_items for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

-- ---- ingredients / ingredient_purchases / expenses -----------------------
-- Owner-only end to end, per spec.

create policy "ingredients_owner_only"
  on ingredients for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "ingredient_purchases_owner_only"
  on ingredient_purchases for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "ingredient_purchase_items_owner_only"
  on ingredient_purchase_items for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "expenses_owner_only"
  on expenses for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "expense_items_owner_only"
  on expense_items for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

-- ---- orders ---------------------------------------------------------------

create policy "orders_select_all"
  on orders for select to authenticated
  using (true);

create policy "orders_insert_kasir_or_owner"
  on orders for insert to authenticated
  with check (public.current_role() in ('kasir', 'owner'));

-- Karyawan may only flip on_process -> served.
create policy "orders_update_karyawan_serve"
  on orders for update to authenticated
  using (public.current_role() = 'karyawan' and status = 'on_process')
  with check (status = 'served');

-- Kasir may only flip served -> paid (happens together with a payments insert).
create policy "orders_update_kasir_pay"
  on orders for update to authenticated
  using (public.current_role() = 'kasir' and status = 'served')
  with check (status = 'paid');

-- Owner has unrestricted access, matching "akses penuh".
create policy "orders_all_owner"
  on orders for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

-- ---- order_items ------------------------------------------------------------

create policy "order_items_select_all"
  on order_items for select to authenticated
  using (true);

create policy "order_items_insert_kasir_or_owner"
  on order_items for insert to authenticated
  with check (public.current_role() in ('kasir', 'owner'));

create policy "order_items_write_owner"
  on order_items for update to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "order_items_delete_owner"
  on order_items for delete to authenticated
  using (public.current_role() = 'owner');

-- ---- payments ---------------------------------------------------------------

create policy "payments_select_all"
  on payments for select to authenticated
  using (true);

create policy "payments_insert_kasir_or_owner"
  on payments for insert to authenticated
  with check (public.current_role() in ('kasir', 'owner'));

create policy "payments_write_owner"
  on payments for update to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "payments_delete_owner"
  on payments for delete to authenticated
  using (public.current_role() = 'owner');

-- ============================================================================
-- 5. REALTIME
-- ============================================================================
-- The kitchen and cashier/payment screens subscribe to live changes on
-- `orders` (via Supabase Realtime "Postgres Changes"). Without this, the app
-- throws `RealtimeSubscribeException: Unable to subscribe to changes...`.
alter publication supabase_realtime add table orders;

-- ============================================================================
-- 6. STORAGE (menu photos)
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('menu-photos', 'menu-photos', true)
on conflict (id) do nothing;

create policy "menu_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'menu-photos');

create policy "menu_photos_owner_write"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'menu-photos' and public.current_role() = 'owner');

create policy "menu_photos_owner_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'menu-photos' and public.current_role() = 'owner')
  with check (bucket_id = 'menu-photos' and public.current_role() = 'owner');

create policy "menu_photos_owner_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'menu-photos' and public.current_role() = 'owner');

-- ============================================================================
-- 7. BOOTSTRAPPING THE FIRST OWNER ACCOUNT
-- ============================================================================
-- 1. Create the user via Supabase Studio -> Authentication -> Add user
--    (or have them sign up through the app), e.g. owner@yourrestaurant.com.
-- 2. The `handle_new_user` trigger above will insert a `profiles` row for
--    them with role 'kasir' by default. Promote them to owner once:
--
--      update public.profiles set role = 'owner' where id =
--        (select id from auth.users where email = 'owner@yourrestaurant.com');
--
-- 3. From then on, the owner can create kasir/karyawan accounts from inside
--    the app (Kelola Karyawan), which calls the `create-employee` Edge
--    Function and sets the correct role automatically.
