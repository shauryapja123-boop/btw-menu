create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'customer' check (role in ('customer', 'manager')),
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  tracking_code text not null unique,
  user_id uuid not null references auth.users (id) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  fulfillment text not null check (fulfillment in ('delivery', 'pickup')),
  delivery_address text not null default '',
  order_note text not null default '',
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  items_total integer not null check (items_total >= 0),
  status text not null default 'received'
    check (status in ('received', 'confirmed', 'preparing', 'out-for-delivery', 'delivered', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_user_created_idx on public.orders (user_id, created_at desc);
create index if not exists orders_created_idx on public.orders (created_at desc);

create or replace function public.is_manager()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'manager'
  );
$$;

revoke all on function public.is_manager() from public;
grant execute on function public.is_manager() to authenticated;

create or replace function public.create_customer_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, role) values (new.id, 'customer')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists create_customer_profile_after_signup on auth.users;
create trigger create_customer_profile_after_signup
  after insert on auth.users
  for each row execute procedure public.create_customer_profile();

alter table public.profiles enable row level security;
alter table public.orders enable row level security;

drop policy if exists "Users read their own profile" on public.profiles;
create policy "Users read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

drop policy if exists "Customers read their orders and managers read all" on public.orders;
create policy "Customers read their orders and managers read all"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_manager()));

drop policy if exists "Customers create their own received orders" on public.orders;
create policy "Customers create their own received orders"
  on public.orders for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'received');

drop policy if exists "Managers update order status" on public.orders;
create policy "Managers update order status"
  on public.orders for update to authenticated
  using ((select public.is_manager()))
  with check ((select public.is_manager()));

grant select on public.profiles to authenticated;
grant select, insert on public.orders to authenticated;
revoke update on public.orders from authenticated;
grant update (status) on public.orders to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.orders;
exception
  when duplicate_object then null;
end;
$$;