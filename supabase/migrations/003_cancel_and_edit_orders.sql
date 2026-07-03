-- ============================================================================
-- Migration: allow cancelling an order, and let kasir edit an on_process
-- order's details/items (not just create it).
-- ============================================================================

-- Add 'cancelled' to the allowed order statuses.
alter table orders drop constraint if exists orders_status_check;
alter table orders add constraint orders_status_check
  check (status in ('on_process', 'served', 'paid', 'cancelled'));

-- Kasir can edit table/customer/date on an order they haven't served yet
-- (status stays on_process — this policy does not permit a status change).
create policy "orders_update_kasir_edit"
  on orders for update to authenticated
  using (public.current_role() = 'kasir' and status = 'on_process')
  with check (status = 'on_process');

-- Kasir can cancel an order any time before it's paid.
create policy "orders_update_kasir_cancel"
  on orders for update to authenticated
  using (public.current_role() = 'kasir' and status in ('on_process', 'served'))
  with check (status = 'cancelled');

-- Editing an order's items is implemented as delete-all-then-reinsert, so
-- kasir needs delete rights on order_items while the parent order is still
-- on_process (replaces the old owner-only delete policy).
drop policy if exists "order_items_delete_owner" on order_items;
create policy "order_items_delete_kasir_or_owner"
  on order_items for delete to authenticated
  using (
    public.current_role() = 'owner'
    or (
      public.current_role() = 'kasir'
      and exists (
        select 1 from public.orders o
        where o.id = order_items.order_id and o.status = 'on_process'
      )
    )
  );
