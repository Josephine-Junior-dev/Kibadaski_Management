-- Kibadaski Management: universal multi-business schema
-- Run in Supabase SQL Editor. Uses km_ prefix; does not touch other app tables.
create extension if not exists pgcrypto;

create table if not exists public.km_businesses (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 business_name text not null,
 business_type text not null default 'other',
 currency_code text not null default 'KES',
 phone text,
 email text,
 address text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_categories (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 name text not null,
 category_type text not null default 'product' check(category_type in ('product','expense')),
 created_at timestamptz not null default now(),
 unique(business_id,name,category_type)
);

create table if not exists public.km_products (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 category_id uuid references public.km_categories(id) on delete set null,
 name text not null,
 item_type text not null default 'product' check(item_type in ('product','service')),
 selling_price numeric(14,2) not null default 0 check(selling_price >= 0),
 unit_cost numeric(14,2) not null default 0 check(unit_cost >= 0),
 track_stock boolean not null default false,
 stock_quantity numeric(14,3) not null default 0,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);

create table if not exists public.km_customers (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 full_name text not null,
 phone text,
 email text,
 credit_terms text not null default 'flexible' check(credit_terms in ('daily','weekly','monthly','flexible')),
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_suppliers (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 supplier_name text not null,
 phone text,
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_sales (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 sale_number text,
 customer_id uuid references public.km_customers(id) on delete set null,
 customer_name text,
 sale_date timestamptz not null default now(),
 subtotal numeric(14,2) not null default 0,
 discount numeric(14,2) not null default 0,
 total_amount numeric(14,2) not null default 0,
 payment_status text not null default 'paid' check(payment_status in ('paid','partial','credit')),
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_sale_items (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 sale_id uuid not null references public.km_sales(id) on delete cascade,
 product_id uuid references public.km_products(id) on delete set null,
 item_name text not null,
 quantity numeric(14,3) not null check(quantity > 0),
 unit_price numeric(14,2) not null check(unit_price >= 0),
 unit_cost numeric(14,2) not null default 0,
 line_total numeric(14,2) not null check(line_total >= 0),
 created_at timestamptz not null default now()
);

create table if not exists public.km_customer_payments (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 customer_id uuid not null references public.km_customers(id) on delete restrict,
 sale_id uuid references public.km_sales(id) on delete set null,
 amount numeric(14,2) not null check(amount > 0),
 payment_method text not null default 'cash',
 payment_date timestamptz not null default now(),
 reference text,
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_purchases (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 supplier_id uuid references public.km_suppliers(id) on delete set null,
 supplier_name text,
 item_name text not null,
 quantity numeric(14,3) not null default 1 check(quantity > 0),
 unit text not null default 'unit',
 unit_cost numeric(14,2) not null default 0,
 total_cost numeric(14,2) not null check(total_cost >= 0),
 purchase_date timestamptz not null default now(),
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.km_expenses (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.km_businesses(id) on delete cascade,
 category_id uuid references public.km_categories(id) on delete set null,
 description text not null,
 amount numeric(14,2) not null check(amount > 0),
 expense_date timestamptz not null default now(),
 payment_method text,
 notes text,
 created_at timestamptz not null default now()
);

create index if not exists km_business_owner_idx on public.km_businesses(owner_id);
create index if not exists km_products_business_idx on public.km_products(business_id);
create index if not exists km_sales_business_date_idx on public.km_sales(business_id,sale_date);
create index if not exists km_sales_customer_idx on public.km_sales(business_id,customer_id);
create index if not exists km_sale_items_sale_idx on public.km_sale_items(sale_id);
create index if not exists km_customer_payments_customer_idx on public.km_customer_payments(business_id,customer_id,payment_date);
create index if not exists km_purchases_business_date_idx on public.km_purchases(business_id,purchase_date);
create index if not exists km_expenses_business_date_idx on public.km_expenses(business_id,expense_date);

alter table public.km_businesses enable row level security;
alter table public.km_categories enable row level security;
alter table public.km_products enable row level security;
alter table public.km_customers enable row level security;
alter table public.km_suppliers enable row level security;
alter table public.km_sales enable row level security;
alter table public.km_sale_items enable row level security;
alter table public.km_customer_payments enable row level security;
alter table public.km_purchases enable row level security;
alter table public.km_expenses enable row level security;

-- Business owners can only see/manage their own business profiles.
drop policy if exists km_businesses_owner on public.km_businesses;
create policy km_businesses_owner on public.km_businesses for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Child rows are accessible only when the linked business belongs to the signed-in owner.
do $$
declare t text;
begin
 foreach t in array array['km_categories','km_products','km_customers','km_suppliers','km_sales','km_sale_items','km_customer_payments','km_purchases','km_expenses']
 loop
  execute format('drop policy if exists %I on public.%I', t || '_owner', t);
  execute format(
   'create policy %I on public.%I for all to authenticated using (exists (select 1 from public.km_businesses b where b.id = business_id and b.owner_id = auth.uid())) with check (exists (select 1 from public.km_businesses b where b.id = business_id and b.owner_id = auth.uid()))',
   t || '_owner', t
  );
 end loop;
end $$;

grant usage on schema public to authenticated;
grant select,insert,update,delete on public.km_businesses,public.km_categories,public.km_products,public.km_customers,public.km_suppliers,public.km_sales,public.km_sale_items,public.km_customer_payments,public.km_purchases,public.km_expenses to authenticated;
