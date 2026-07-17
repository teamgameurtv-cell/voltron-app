-- Voltron — schéma initial Supabase (Sprint 6)
-- À exécuter dans Supabase : Dashboard > SQL Editor > New query > coller > Run
-- Ce script est rejouable sans erreur même si une partie a déjà été exécutée.

-- ============ EXTENSIONS ============
create extension if not exists "pgcrypto";

-- ============ PROFILES (liés à auth.users) ============
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text not null default '',
  phone text not null default '',
  loyalty_points int not null default 0,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- Crée automatiquement un profil quand un utilisateur s'inscrit
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============ PRODUITS ============
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  price numeric(10,2) not null default 0,
  rating numeric(2,1) not null default 0,
  review_count int not null default 0,
  tagline text,
  icon_name text not null default 'shopping_bag',
  is_best_seller boolean not null default false,
  stock int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists product_specs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  label text not null,
  value text not null,
  position int not null default 0
);

create table if not exists product_colors (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  color_hex text not null
);

create table if not exists stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  product_name text not null,
  delta int not null,
  created_at timestamptz not null default now()
);

-- ============ FIDÉLITÉ ============
create table if not exists rewards (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  points int not null,
  icon_name text not null default 'card_giftcard'
);

create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references profiles(id) on delete cascade unique,
  plan_id text not null,
  started_at timestamptz not null default now()
);

-- ============ GARAGE ============
create table if not exists scooters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  brand text not null,
  model text not null,
  serial_number text not null default '',
  purchase_date date not null default current_date
);

-- ============ RÉPARATIONS ============
create table if not exists repair_orders (
  id uuid primary key default gen_random_uuid(),
  display_id text not null,
  client_id uuid not null references profiles(id) on delete cascade,
  scooter_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists repair_steps (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references repair_orders(id) on delete cascade,
  label text not null,
  status text not null check (status in ('done','current','pending')),
  step_date text,
  position int not null default 0
);

create table if not exists quotes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references repair_orders(id) on delete cascade unique,
  display_id text not null,
  quote_date text not null,
  estimated_delay text not null default '',
  status text not null default 'pendingApproval' check (status in ('pendingApproval','accepted','refused'))
);

create table if not exists quote_lines (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references quotes(id) on delete cascade,
  label text not null,
  price numeric(10,2) not null
);

-- ============ RÉSERVATIONS ============
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references profiles(id) on delete cascade,
  service_name text not null,
  client_name text not null,
  day text not null,
  time text not null,
  status text not null default 'pending' check (status in ('confirmed','pending','cancelled')),
  created_at timestamptz not null default now()
);

-- ============ COMPTE ============
create table if not exists addresses (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references profiles(id) on delete cascade,
  label text not null,
  details text not null
);

create table if not exists payment_methods (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references profiles(id) on delete cascade,
  brand text not null,
  last4 text not null,
  expiry text not null
);

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references profiles(id) on delete cascade,
  label text not null,
  invoice_date text not null,
  amount numeric(10,2) not null
);

-- ============ NOTIFICATIONS ============
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references profiles(id) on delete cascade, -- null = diffusée à tous
  type text not null check (type in ('repair','order','loyalty','promo','reminder')),
  title text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  read boolean not null default false
);

-- ============ ROW LEVEL SECURITY ============
alter table profiles enable row level security;
alter table products enable row level security;
alter table product_specs enable row level security;
alter table product_colors enable row level security;
alter table stock_movements enable row level security;
alter table rewards enable row level security;
alter table subscriptions enable row level security;
alter table scooters enable row level security;
alter table repair_orders enable row level security;
alter table repair_steps enable row level security;
alter table quotes enable row level security;
alter table quote_lines enable row level security;
alter table bookings enable row level security;
alter table addresses enable row level security;
alter table payment_methods enable row level security;
alter table invoices enable row level security;
alter table notifications enable row level security;

-- Fonction utilitaire : l'utilisateur connecté est-il admin ?
create or replace function is_admin()
returns boolean as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false);
$$ language sql stable security definer;

-- Profiles : chacun voit/modifie le sien, l'admin voit tout
drop policy if exists "profiles_select_own_or_admin" on profiles;
create policy "profiles_select_own_or_admin" on profiles for select using (auth.uid() = id or is_admin());
drop policy if exists "profiles_update_own_or_admin" on profiles;
create policy "profiles_update_own_or_admin" on profiles for update using (auth.uid() = id or is_admin());

-- Catalogue produit : lecture publique, écriture admin uniquement
drop policy if exists "products_select_all" on products;
create policy "products_select_all" on products for select using (true);
drop policy if exists "products_write_admin" on products;
create policy "products_write_admin" on products for all using (is_admin()) with check (is_admin());
drop policy if exists "product_specs_select_all" on product_specs;
create policy "product_specs_select_all" on product_specs for select using (true);
drop policy if exists "product_specs_write_admin" on product_specs;
create policy "product_specs_write_admin" on product_specs for all using (is_admin()) with check (is_admin());
drop policy if exists "product_colors_select_all" on product_colors;
create policy "product_colors_select_all" on product_colors for select using (true);
drop policy if exists "product_colors_write_admin" on product_colors;
create policy "product_colors_write_admin" on product_colors for all using (is_admin()) with check (is_admin());
drop policy if exists "stock_movements_admin_only" on stock_movements;
create policy "stock_movements_admin_only" on stock_movements for all using (is_admin()) with check (is_admin());

-- Récompenses : lecture publique, écriture admin
drop policy if exists "rewards_select_all" on rewards;
create policy "rewards_select_all" on rewards for select using (true);
drop policy if exists "rewards_write_admin" on rewards;
create policy "rewards_write_admin" on rewards for all using (is_admin()) with check (is_admin());

-- Abonnements : le client voit/gère le sien, admin voit tout
drop policy if exists "subscriptions_own_or_admin" on subscriptions;
create policy "subscriptions_own_or_admin" on subscriptions for all
  using (client_id = auth.uid() or is_admin()) with check (client_id = auth.uid() or is_admin());

-- Garage : le client voit/gère ses véhicules, admin voit tout
drop policy if exists "scooters_own_or_admin" on scooters;
create policy "scooters_own_or_admin" on scooters for all
  using (owner_id = auth.uid() or is_admin()) with check (owner_id = auth.uid() or is_admin());

-- Réparations : le client voit les siennes, admin gère tout
drop policy if exists "repair_orders_own_or_admin" on repair_orders;
create policy "repair_orders_own_or_admin" on repair_orders for select using (client_id = auth.uid() or is_admin());
drop policy if exists "repair_orders_write_admin" on repair_orders;
create policy "repair_orders_write_admin" on repair_orders for insert with check (is_admin());
drop policy if exists "repair_orders_update_admin" on repair_orders;
create policy "repair_orders_update_admin" on repair_orders for update using (is_admin());

drop policy if exists "repair_steps_own_or_admin" on repair_steps;
create policy "repair_steps_own_or_admin" on repair_steps for select using (
  exists (select 1 from repair_orders o where o.id = order_id and (o.client_id = auth.uid() or is_admin()))
);
drop policy if exists "repair_steps_write_admin" on repair_steps;
create policy "repair_steps_write_admin" on repair_steps for all using (is_admin()) with check (is_admin());

drop policy if exists "quotes_own_or_admin" on quotes;
create policy "quotes_own_or_admin" on quotes for select using (
  exists (select 1 from repair_orders o where o.id = order_id and (o.client_id = auth.uid() or is_admin()))
);
drop policy if exists "quotes_update_own_or_admin" on quotes;
create policy "quotes_update_own_or_admin" on quotes for update using (
  exists (select 1 from repair_orders o where o.id = order_id and (o.client_id = auth.uid() or is_admin()))
);
drop policy if exists "quotes_write_admin" on quotes;
create policy "quotes_write_admin" on quotes for insert with check (is_admin());

drop policy if exists "quote_lines_own_or_admin" on quote_lines;
create policy "quote_lines_own_or_admin" on quote_lines for select using (
  exists (
    select 1 from quotes q join repair_orders o on o.id = q.order_id
    where q.id = quote_id and (o.client_id = auth.uid() or is_admin())
  )
);
drop policy if exists "quote_lines_write_admin" on quote_lines;
create policy "quote_lines_write_admin" on quote_lines for all using (is_admin()) with check (is_admin());

-- Réservations : le client voit les siennes, admin gère tout
drop policy if exists "bookings_own_or_admin" on bookings;
create policy "bookings_own_or_admin" on bookings for select using (client_id = auth.uid() or is_admin());
drop policy if exists "bookings_insert_own" on bookings;
create policy "bookings_insert_own" on bookings for insert with check (client_id = auth.uid() or is_admin());
drop policy if exists "bookings_update_admin" on bookings;
create policy "bookings_update_admin" on bookings for update using (is_admin());

-- Compte : chacun gère le sien
drop policy if exists "addresses_own" on addresses;
create policy "addresses_own" on addresses for all using (client_id = auth.uid()) with check (client_id = auth.uid());
drop policy if exists "payment_methods_own" on payment_methods;
create policy "payment_methods_own" on payment_methods for all using (client_id = auth.uid()) with check (client_id = auth.uid());
drop policy if exists "invoices_own_or_admin" on invoices;
create policy "invoices_own_or_admin" on invoices for select using (client_id = auth.uid() or is_admin());

-- Notifications : le client voit les siennes + les diffusions globales (client_id null)
drop policy if exists "notifications_own_or_broadcast" on notifications;
create policy "notifications_own_or_broadcast" on notifications for select using (
  client_id = auth.uid() or client_id is null
);
drop policy if exists "notifications_update_own" on notifications;
create policy "notifications_update_own" on notifications for update using (client_id = auth.uid());
drop policy if exists "notifications_insert_admin" on notifications;
drop policy if exists "notifications_insert_self_or_admin" on notifications;
create policy "notifications_insert_self_or_admin" on notifications for insert
  with check (client_id = auth.uid() or is_admin());

-- ============ DONNÉES DE DÉPART (catalogue, récompenses) ============
insert into products (name, category, price, rating, review_count, tagline, icon_name, is_best_seller, stock)
select * from (values
  ('DUALTRON VICTOR LUXURY', 'Trottinettes', 2890.00, 0, 0, 'La puissance à l''état pur', 'electric_scooter', false, 6),
  ('Pneu 10x2.5', 'Pièces', 59.90, 4.8, 132, null, 'tire_repair', true, 24),
  ('Chargeur 42V 2A', 'Accessoires', 19.90, 4.7, 89, null, 'power', true, 40)
) as v(name, category, price, rating, review_count, tagline, icon_name, is_best_seller, stock)
where not exists (select 1 from products);

insert into rewards (label, points, icon_name)
select * from (values
  ('-10% sur votre prochaine commande', 200, 'local_offer'),
  ('Révision complète offerte', 500, 'hourglass_bottom'),
  ('Accessoire offert', 300, 'lock_open')
) as v(label, points, icon_name)
where not exists (select 1 from rewards);

-- ============ PHOTOS PRODUITS (colonne + bucket de stockage) ============
alter table products add column if not exists image_url text;
alter table products add column if not exists description text;

insert into storage.buckets (id, name, public)
select 'product-images', 'product-images', true
where not exists (select 1 from storage.buckets where id = 'product-images');

drop policy if exists "product images public read" on storage.objects;
create policy "product images public read" on storage.objects
  for select using (bucket_id = 'product-images');

drop policy if exists "product images admin write" on storage.objects;
create policy "product images admin write" on storage.objects
  for insert with check (bucket_id = 'product-images' and is_admin());

drop policy if exists "product images admin update" on storage.objects;
create policy "product images admin update" on storage.objects
  for update using (bucket_id = 'product-images' and is_admin());

drop policy if exists "product images admin delete" on storage.objects;
create policy "product images admin delete" on storage.objects
  for delete using (bucket_id = 'product-images' and is_admin());

-- ============ PHOTOS DE PROFIL CLIENT (colonne + bucket de stockage) ============
alter table profiles add column if not exists avatar_url text;

insert into storage.buckets (id, name, public)
select 'avatars', 'avatars', true
where not exists (select 1 from storage.buckets where id = 'avatars');

drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatars owner write" on storage.objects;
create policy "avatars owner write" on storage.objects
  for insert with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update" on storage.objects
  for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars owner delete" on storage.objects;
create policy "avatars owner delete" on storage.objects
  for delete using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ============ SERVICES DE RÉPARATION (catalogue configurable par l'admin) ============
create table if not exists repair_services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  duration text not null default '',
  price_label text not null default '',
  description text,
  image_url text,
  created_at timestamptz not null default now()
);
alter table repair_services enable row level security;

drop policy if exists "repair_services_select_all" on repair_services;
create policy "repair_services_select_all" on repair_services for select using (true);

drop policy if exists "repair_services_admin_insert" on repair_services;
create policy "repair_services_admin_insert" on repair_services for insert with check (is_admin());

drop policy if exists "repair_services_admin_update" on repair_services;
create policy "repair_services_admin_update" on repair_services for update using (is_admin());

drop policy if exists "repair_services_admin_delete" on repair_services;
create policy "repair_services_admin_delete" on repair_services for delete using (is_admin());

insert into repair_services (name, duration, price_label)
select * from (values
  ('Changement de pneu', '45 min', 'à partir de 35 €'),
  ('Réglage des freins', '30 min', '25 €'),
  ('Révision complète', '1h00', '75 €'),
  ('Diagnostic électrique', '1h00', '45 €'),
  ('Réparation batterie', '1h30', 'à partir de 90 €'),
  ('Personnalisation', '', 'Sur devis')
) as v(name, duration, price_label)
where not exists (select 1 from repair_services);

insert into storage.buckets (id, name, public)
select 'service-images', 'service-images', true
where not exists (select 1 from storage.buckets where id = 'service-images');

drop policy if exists "service images public read" on storage.objects;
create policy "service images public read" on storage.objects
  for select using (bucket_id = 'service-images');

drop policy if exists "service images admin write" on storage.objects;
create policy "service images admin write" on storage.objects
  for insert with check (bucket_id = 'service-images' and is_admin());

drop policy if exists "service images admin update" on storage.objects;
create policy "service images admin update" on storage.objects
  for update using (bucket_id = 'service-images' and is_admin());

drop policy if exists "service images admin delete" on storage.objects;
create policy "service images admin delete" on storage.objects
  for delete using (bucket_id = 'service-images' and is_admin());

-- ============ OBJECTIFS FIDÉLITÉ (badges à réclamer, une fois chacun) ============
create table if not exists loyalty_goal_claims (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id) on delete cascade,
  goal_id text not null,
  points int not null,
  claimed_at timestamptz not null default now(),
  unique (client_id, goal_id)
);
alter table loyalty_goal_claims enable row level security;

drop policy if exists "loyalty_goal_claims_select_own" on loyalty_goal_claims;
create policy "loyalty_goal_claims_select_own" on loyalty_goal_claims
  for select using (client_id = auth.uid() or is_admin());

-- Le crédit de points ne passe que par cette fonction (jamais d'insert direct côté client),
-- pour garantir qu'un objectif ne peut être réclamé qu'une seule fois par utilisateur.
create or replace function claim_loyalty_goal(p_goal_id text, p_points int)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  already_claimed boolean;
begin
  select exists(
    select 1 from loyalty_goal_claims where client_id = auth.uid() and goal_id = p_goal_id
  ) into already_claimed;

  if already_claimed then
    return false;
  end if;

  insert into loyalty_goal_claims (client_id, goal_id, points) values (auth.uid(), p_goal_id, p_points);
  update profiles set loyalty_points = loyalty_points + p_points where id = auth.uid();
  return true;
end;
$$;

grant execute on function claim_loyalty_goal(text, int) to authenticated;
