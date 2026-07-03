-- ============================================================================
-- Migration: turn ingredient_purchases and expenses into multi-item
-- transactions (one header + many line items), mirroring orders/order_items.
--
-- WARNING: this drops the old flat ingredient_purchases and expenses tables
-- (cascade). Any rows already recorded there will be lost. Run this only on
-- a project where that data is disposable (e.g. still in testing).
-- ============================================================================

-- ---- ingredient_purchases -------------------------------------------------

drop trigger if exists trg_ingredient_purchase_stock on ingredient_purchases;
drop function if exists public.apply_ingredient_purchase_stock();
drop table if exists ingredient_purchases cascade;

create table ingredient_purchases (
  id uuid primary key default gen_random_uuid(),
  purchase_date date not null,
  notes text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table ingredient_purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references ingredient_purchases(id) on delete cascade,
  ingredient_id uuid not null references ingredients(id) on delete restrict,
  quantity numeric(12, 2) not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  total_price numeric(12, 2) not null check (total_price >= 0),
  created_at timestamptz not null default now()
);

create index idx_ingredient_purchases_date on ingredient_purchases(purchase_date);
create index idx_ingredient_purchase_items_purchase on ingredient_purchase_items(purchase_id);
create index idx_ingredient_purchase_items_ingredient on ingredient_purchase_items(ingredient_id);

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

create trigger trg_ingredient_purchase_stock
  after insert or update or delete on ingredient_purchase_items
  for each row execute function public.apply_ingredient_purchase_stock();

alter table ingredient_purchases enable row level security;
alter table ingredient_purchase_items enable row level security;

create policy "ingredient_purchases_owner_only"
  on ingredient_purchases for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "ingredient_purchase_items_owner_only"
  on ingredient_purchase_items for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

-- ---- expenses ---------------------------------------------------------------

drop table if exists expenses cascade;

create table expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null,
  notes text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table expense_items (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references expenses(id) on delete cascade,
  category text not null,
  description text,
  amount numeric(12, 2) not null check (amount >= 0),
  created_at timestamptz not null default now()
);

create index idx_expenses_date on expenses(expense_date);
create index idx_expense_items_expense on expense_items(expense_id);

alter table expenses enable row level security;
alter table expense_items enable row level security;

create policy "expenses_owner_only"
  on expenses for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');

create policy "expense_items_owner_only"
  on expense_items for all to authenticated
  using (public.current_role() = 'owner')
  with check (public.current_role() = 'owner');
