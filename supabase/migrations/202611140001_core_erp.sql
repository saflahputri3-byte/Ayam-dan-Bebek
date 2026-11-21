-- Core ERP schema. No operational or demo records are seeded.
create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.app_role as enum (
  'owner', 'super_admin', 'central_admin', 'branch_admin', 'purchasing',
  'production', 'warehouse', 'cashier', 'finance', 'supervisor', 'delivery'
);
create type public.transaction_status as enum ('draft', 'approved', 'posted', 'partially_received', 'voided');

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  currency_code char(3) not null default 'IDR',
  timezone text not null default 'Asia/Jakarta',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.branches (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  code text not null,
  name text not null,
  address text,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (company_id, code),
  unique (company_id, id)
);

create table public.warehouses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  unique (branch_id, code),
  unique (company_id, branch_id, id)
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  company_id uuid not null references public.companies(id),
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  primary key (company_id, user_id, role)
);

create table public.user_branch_access (
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (branch_id, user_id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  code text not null,
  name text not null,
  phone text,
  address text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (company_id, code),
  unique (company_id, id)
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  code text not null,
  name text not null,
  phone text,
  address text,
  credit_limit numeric(14,2) not null default 0 check (credit_limit >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (company_id, code),
  unique (company_id, id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  sku text not null,
  name text not null,
  species text check (species in ('chicken', 'duck', 'other')),
  category text not null,
  base_unit text not null check (base_unit in ('kg', 'pcs', 'bird')),
  minimum_stock numeric(14,3) not null default 0 check (minimum_stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (company_id, sku),
  unique (company_id, id)
);

create table public.product_units (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  product_id uuid not null,
  unit_code text not null check (unit_code in ('kg', 'pcs', 'bird')),
  base_units_per_unit numeric(14,6) not null check (base_units_per_unit > 0),
  is_sellable boolean not null default true,
  unique (product_id, unit_code),
  foreign key (company_id, product_id) references public.products(company_id, id)
);

create table public.document_sequences (
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  document_type text not null,
  sequence_year integer not null,
  last_value bigint not null default 0,
  primary key (company_id, branch_id, document_type, sequence_year),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  warehouse_id uuid not null,
  customer_id uuid,
  document_number text not null,
  status public.transaction_status not null default 'posted',
  subtotal numeric(14,2) not null check (subtotal >= 0),
  discount_amount numeric(14,2) not null default 0 check (discount_amount >= 0),
  shipping_amount numeric(14,2) not null default 0 check (shipping_amount >= 0),
  total_amount numeric(14,2) not null check (total_amount >= 0),
  paid_amount numeric(14,2) not null default 0 check (paid_amount >= 0),
  notes text,
  idempotency_key uuid not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  voided_at timestamptz,
  voided_by uuid references auth.users(id),
  void_reason text,
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  foreign key (company_id, branch_id, warehouse_id) references public.warehouses(company_id, branch_id, id),
  foreign key (company_id, customer_id) references public.customers(company_id, id),
  unique (company_id, document_number),
  unique (company_id, created_by, idempotency_key),
  unique (company_id, id),
  unique (company_id, branch_id, id)
);

create table public.sales_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  sale_id uuid not null,
  product_id uuid not null,
  batch_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  base_quantity numeric(14,3) not null check (base_quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  discount_amount numeric(14,2) not null default 0 check (discount_amount >= 0),
  line_total numeric(14,2) not null check (line_total >= 0),
  foreign key (company_id, branch_id, sale_id) references public.sales(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  supplier_id uuid not null,
  document_number text not null,
  status public.transaction_status not null default 'draft',
  total_amount numeric(14,2) not null default 0 check (total_amount >= 0),
  notes text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  foreign key (company_id, supplier_id) references public.suppliers(company_id, id),
  unique (company_id, document_number),
  unique (company_id, id),
  unique (company_id, branch_id, id)
);

create table public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  purchase_id uuid not null,
  product_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  base_quantity numeric(14,3) not null check (base_quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  line_total numeric(14,2) not null check (line_total >= 0),
  foreign key (company_id, purchase_id) references public.purchases(company_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  unique (company_id, branch_id, id)
);

create table public.product_batches (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  product_id uuid not null,
  batch_number text not null,
  source_type text not null check (source_type in ('receipt', 'production', 'adjustment')),
  source_id uuid,
  produced_at timestamptz,
  expires_at timestamptz,
  quality_status text not null default 'pending' check (quality_status in ('pending', 'passed', 'rejected', 'quarantined')),
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  unique (company_id, batch_number),
  unique (company_id, id),
  unique (company_id, branch_id, id)
);

create table public.production_batches (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  warehouse_id uuid not null,
  batch_number text not null,
  status public.transaction_status not null default 'posted',
  produced_at timestamptz not null default now(),
  notes text,
  idempotency_key uuid not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id, warehouse_id) references public.warehouses(company_id, branch_id, id),
  unique (company_id, batch_number),
  unique (company_id, created_by, idempotency_key),
  unique (company_id, branch_id, id)
);

create table public.production_inputs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  production_batch_id uuid not null,
  product_id uuid not null,
  batch_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  base_quantity numeric(14,3) not null check (base_quantity > 0),
  foreign key (company_id, branch_id, production_batch_id) references public.production_batches(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, branch_id, batch_id) references public.product_batches(company_id, branch_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.production_outputs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  production_batch_id uuid not null,
  product_id uuid not null,
  batch_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  base_quantity numeric(14,3) not null check (base_quantity > 0),
  foreign key (company_id, branch_id, production_batch_id) references public.production_batches(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, branch_id, batch_id) references public.product_batches(company_id, branch_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.waste_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  production_batch_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  reason text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id, production_batch_id) references public.production_batches(company_id, branch_id, id)
);

create table public.quality_inspections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  batch_id uuid not null,
  result text not null check (result in ('passed','rejected','quarantined')),
  notes text,
  inspected_by uuid not null references auth.users(id),
  inspected_at timestamptz not null default now(),
  foreign key (company_id, branch_id, batch_id) references public.product_batches(company_id, branch_id, id)
);

create table public.goods_receipts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  warehouse_id uuid not null,
  purchase_id uuid not null,
  document_number text not null,
  status public.transaction_status not null default 'posted',
  received_at timestamptz not null default now(),
  received_by uuid not null references auth.users(id),
  idempotency_key uuid not null,
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id, warehouse_id) references public.warehouses(company_id, branch_id, id),
  foreign key (company_id, branch_id, purchase_id) references public.purchases(company_id, branch_id, id),
  unique (company_id, document_number),
  unique (company_id, received_by, idempotency_key),
  unique (company_id, id),
  unique (company_id, branch_id, id)
);

create table public.goods_receipt_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  receipt_id uuid not null,
  purchase_item_id uuid not null,
  product_id uuid not null,
  batch_id uuid not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_code text not null,
  base_quantity numeric(14,3) not null check (base_quantity > 0),
  unit_cost numeric(14,2) not null check (unit_cost >= 0),
  foreign key (company_id, receipt_id) references public.goods_receipts(company_id, id),
  foreign key (company_id, branch_id, purchase_item_id) references public.purchase_items(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, batch_id) references public.product_batches(company_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.inventory_balances (
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  warehouse_id uuid not null,
  product_id uuid not null,
  batch_id uuid,
  batch_key text generated always as (coalesce(batch_id::text, 'unbatched')) stored,
  quantity numeric(14,3) not null default 0,
  updated_at timestamptz not null default now(),
  foreign key (company_id, branch_id, warehouse_id) references public.warehouses(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, batch_id) references public.product_batches(company_id, id),
  check (quantity >= 0),
  unique (warehouse_id, product_id, batch_key)
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  warehouse_id uuid not null,
  product_id uuid not null,
  batch_id uuid,
  movement_type text not null check (movement_type in ('receipt', 'sale', 'production_input', 'production_output', 'transfer_in', 'transfer_out', 'adjustment', 'reversal')),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  unit_code text not null,
  source_type text not null,
  source_id uuid not null,
  idempotency_key uuid not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id, warehouse_id) references public.warehouses(company_id, branch_id, id),
  foreign key (company_id, product_id) references public.products(company_id, id),
  foreign key (company_id, batch_id) references public.product_batches(company_id, id)
);
create index inventory_movements_scope_idx on public.inventory_movements(company_id, branch_id, warehouse_id, product_id, created_at desc);
create index inventory_movements_source_idx on public.inventory_movements(company_id, source_type, source_id);
create index inventory_movements_batch_idx on public.inventory_movements(company_id, batch_id, created_at desc);
create index sales_scope_date_idx on public.sales(company_id, branch_id, created_at desc);

create table public.customer_payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  customer_id uuid not null,
  document_number text not null,
  amount numeric(14,2) not null check (amount > 0),
  payment_method text not null check (payment_method in ('cash', 'bank_transfer', 'other')),
  reference text,
  received_at timestamptz not null default now(),
  received_by uuid not null references auth.users(id),
  idempotency_key uuid not null,
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  foreign key (company_id, customer_id) references public.customers(company_id, id),
  unique (company_id, document_number),
  unique (company_id, id),
  unique (company_id, received_by, idempotency_key)
);

create table public.payment_allocations (
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  payment_id uuid not null references public.customer_payments(id),
  sale_id uuid not null references public.sales(id),
  amount numeric(14,2) not null check (amount > 0),
  primary key (payment_id, sale_id),
  foreign key (company_id, payment_id) references public.customer_payments(company_id, id),
  foreign key (company_id, branch_id, sale_id) references public.sales(company_id, branch_id, id),
  foreign key (company_id, branch_id) references public.branches(company_id, id)
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  document_type text not null check (document_type in ('sales_invoice', 'sales_receipt', 'purchase_invoice', 'goods_receipt', 'payment_receipt', 'credit_note', 'delivery_note')),
  document_number text not null,
  source_type text not null,
  source_id uuid not null,
  file_path text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  last_printed_at timestamptz,
  print_count integer not null default 0,
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  unique (company_id, document_number),
  unique (company_id, source_type, source_id, document_type)
);

create table public.scanned_documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  storage_path text not null,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  status text not null default 'uploaded' check (status in ('uploaded', 'processing', 'needs_review', 'confirmed', 'failed', 'duplicate_candidate')),
  source_hash text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  ai_consent_by uuid references auth.users(id),
  ai_consent_at timestamptz,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  unique (company_id, storage_path),
  unique (company_id, id)
);

create table public.ocr_extractions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  scanned_document_id uuid not null references public.scanned_documents(id),
  provider text not null,
  model text not null,
  extracted_data jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) check (confidence between 0 and 1),
  warnings jsonb not null default '[]'::jsonb,
  reviewed_data jsonb,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  foreign key (company_id, scanned_document_id) references public.scanned_documents(company_id, id)
);
alter table public.sales_items add constraint sales_items_batch_fk foreign key (company_id, batch_id) references public.product_batches(company_id, id);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  company_id uuid not null references public.companies(id),
  branch_id uuid,
  actor_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create table public.idempotency_keys (
  company_id uuid not null references public.companies(id),
  user_id uuid not null references auth.users(id),
  idempotency_key uuid not null,
  operation text not null,
  response jsonb,
  created_at timestamptz not null default now(),
  primary key (company_id, user_id, idempotency_key)
);

-- RLS membership helpers live in a non-exposed schema and pin search_path.
create or replace function private.has_company_access(p_company_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.user_roles ur where ur.company_id = p_company_id and ur.user_id = (select auth.uid())
  )
$$;

create or replace function private.has_branch_access(p_company_id uuid, p_branch_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and (
    exists (select 1 from public.user_branch_access uba where uba.company_id = p_company_id and uba.branch_id = p_branch_id and uba.user_id = (select auth.uid()))
    or exists (select 1 from public.user_roles ur where ur.company_id = p_company_id and ur.user_id = (select auth.uid()) and ur.role in ('owner','super_admin','central_admin'))
  )
$$;

create or replace function private.has_any_role(p_company_id uuid, p_roles public.app_role[])
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.user_roles ur where ur.company_id = p_company_id and ur.user_id = (select auth.uid()) and ur.role = any(p_roles)
  )
$$;

create or replace function private.next_document_number(p_company_id uuid, p_branch_id uuid, p_type text)
returns text language plpgsql security definer set search_path = '' as $$
declare v_year integer := extract(year from now() at time zone 'Asia/Jakarta')::integer; v_seq bigint; v_code text; v_prefix text;
begin
  if not private.has_branch_access(p_company_id, p_branch_id) then raise exception 'Branch access denied' using errcode = '42501'; end if;
  select b.code into v_code from public.branches b where b.company_id = p_company_id and b.id = p_branch_id and b.is_active;
  if v_code is null then raise exception 'Branch not found or inactive'; end if;
  insert into public.document_sequences(company_id, branch_id, document_type, sequence_year, last_value)
  values (p_company_id, p_branch_id, p_type, v_year, 1)
  on conflict (company_id, branch_id, document_type, sequence_year) do update set last_value = public.document_sequences.last_value + 1
  returning last_value into v_seq;
  v_prefix := case p_type when 'sales' then 'INV' when 'purchase' then 'BUY' when 'receipt' then 'RCV' when 'payment' then 'PAY' else upper(left(p_type,3)) end;
  return v_prefix || '/' || upper(v_code) || '/' || v_year::text || '/' || lpad(v_seq::text, 6, '0');
end
$$;

create or replace function private.audit_row()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_row jsonb := to_jsonb(coalesce(new, old)); v_company uuid; v_branch uuid; v_id uuid;
begin
  v_company := (v_row->>'company_id')::uuid;
  v_branch := nullif(v_row->>'branch_id','')::uuid;
  v_id := nullif(v_row->>'id','')::uuid;
  insert into public.audit_logs(company_id, branch_id, actor_id, action, entity_type, entity_id, before_data, after_data)
  values (v_company, v_branch, auth.uid(), lower(tg_op), tg_table_name, v_id,
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end);
  return coalesce(new, old);
end
$$;

create trigger customer_payments_audit after insert on public.customer_payments for each row execute function private.audit_row();
create trigger purchases_audit after insert or update on public.purchases for each row execute function private.audit_row();
create trigger production_batches_audit after insert on public.production_batches for each row execute function private.audit_row();
create trigger goods_receipts_audit after insert on public.goods_receipts for each row execute function private.audit_row();
create trigger sales_audit after insert or update on public.sales for each row execute function private.audit_row();
create trigger inventory_audit after insert on public.inventory_movements for each row execute function private.audit_row();
create trigger scanned_docs_audit after insert or update on public.scanned_documents for each row execute function private.audit_row();
create trigger documents_audit after insert or update on public.documents for each row execute function private.audit_row();
create trigger suppliers_audit after insert or update on public.suppliers for each row execute function private.audit_row();
create trigger customers_audit after insert or update on public.customers for each row execute function private.audit_row();
create trigger products_audit after insert or update on public.products for each row execute function private.audit_row();
create trigger product_units_audit after insert or update on public.product_units for each row execute function private.audit_row();

-- One RPC posts the sale, its lines, stock projection, immutable movements,
-- document number, invoice metadata, and idempotency response atomically.
create or replace function public.post_sale(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid(); v_company uuid := (p_payload->>'company_id')::uuid;
  v_branch uuid := (p_payload->>'branch_id')::uuid; v_warehouse uuid := (p_payload->>'warehouse_id')::uuid;
  v_customer uuid := nullif(p_payload->>'customer_id','')::uuid;
  v_sale_id uuid := gen_random_uuid(); v_doc text; v_subtotal numeric(14,2) := 0;
  v_discount numeric(14,2) := coalesce((p_payload->>'discount_amount')::numeric,0);
  v_shipping numeric(14,2) := coalesce((p_payload->>'shipping_amount')::numeric,0);
  v_total numeric(14,2); v_line jsonb; v_product public.products%rowtype;
  v_unit public.product_units%rowtype; v_batch uuid; v_qty numeric(14,3); v_base numeric(14,3);
  v_price numeric(14,2); v_line_discount numeric(14,2); v_line_total numeric(14,2);
  v_balance numeric(14,3); v_result jsonb; v_old jsonb;
begin
  if v_user is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_idempotency_key is null then raise exception 'Idempotency key is required'; end if;
  if not private.has_branch_access(v_company, v_branch) then raise exception 'Branch access denied' using errcode = '42501'; end if;
  if not private.has_any_role(v_company, array['owner','super_admin','central_admin','branch_admin','cashier']::public.app_role[]) then raise exception 'Sales permission denied' using errcode = '42501'; end if;
  if not exists (select 1 from public.warehouses w where w.company_id=v_company and w.branch_id=v_branch and w.id=v_warehouse and w.is_active) then raise exception 'Warehouse not found'; end if;
  if jsonb_typeof(p_payload->'items') <> 'array' or jsonb_array_length(p_payload->'items') = 0 then raise exception 'At least one sale item is required'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation)
  values(v_company,v_user,p_idempotency_key,'post_sale') on conflict do nothing;
  select k.response into v_old from public.idempotency_keys k where k.company_id=v_company and k.user_id=v_user and k.idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;

  if v_customer is not null and not exists(select 1 from public.customers c where c.company_id=v_company and c.id=v_customer and c.is_active) then raise exception 'Customer is not available'; end if;
  v_doc := private.next_document_number(v_company,v_branch,'sales');

  for v_line in select value from jsonb_array_elements(p_payload->'items') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid and p.is_active;
    if not found then raise exception 'Product is not available'; end if;
    select * into v_unit from public.product_units u where u.company_id=v_company and u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code') and u.is_sellable;
    if not found then raise exception 'Unit is not configured for this product'; end if;
    v_qty := (v_line->>'quantity')::numeric;
    if v_qty <= 0 then raise exception 'Quantity must be greater than zero'; end if;
    v_base := round(v_qty * v_unit.base_units_per_unit,3);
    v_price := (v_line->>'unit_price')::numeric;
    v_line_discount := coalesce((v_line->>'discount_amount')::numeric,0);
    if v_price < 0 or v_line_discount < 0 then raise exception 'Invalid line price or discount'; end if;
    v_line_total := round(v_qty * v_price - v_line_discount,2);
    if v_line_total < 0 then raise exception 'Line discount exceeds line amount'; end if;
    v_batch := nullif(v_line->>'batch_id','')::uuid;
    if v_batch is null then raise exception 'A passed inspection batch is required for every sale item'; end if;
    if v_batch is not null and not exists(select 1 from public.product_batches b where b.company_id=v_company and b.branch_id=v_branch and b.product_id=v_product.id and b.id=v_batch and b.quality_status='passed') then raise exception 'Batch is unavailable or has not passed quality inspection'; end if;
    v_subtotal := v_subtotal + v_line_total;
  end loop;
  if v_discount > v_subtotal or v_shipping < 0 then raise exception 'Invalid sale discount or shipping amount'; end if;
  v_total := v_subtotal - v_discount + v_shipping;
  insert into public.sales(id,company_id,branch_id,warehouse_id,customer_id,document_number,status,subtotal,discount_amount,shipping_amount,total_amount,paid_amount,notes,idempotency_key,created_by)
  values(v_sale_id,v_company,v_branch,v_warehouse,v_customer,v_doc,'posted',v_subtotal,v_discount,v_shipping,v_total,0,nullif(p_payload->>'notes',''),p_idempotency_key,v_user);

  for v_line in select value from jsonb_array_elements(p_payload->'items') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid;
    select * into v_unit from public.product_units u where u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    v_qty := (v_line->>'quantity')::numeric; v_base := round(v_qty * v_unit.base_units_per_unit,3); v_batch := nullif(v_line->>'batch_id','')::uuid;
    v_price := (v_line->>'unit_price')::numeric; v_line_discount := coalesce((v_line->>'discount_amount')::numeric,0);
    v_line_total := round(v_qty*v_price-v_line_discount,2);
    insert into public.sales_items(company_id,branch_id,sale_id,product_id,batch_id,quantity,unit_code,base_quantity,unit_price,discount_amount,line_total)
      values(v_company,v_branch,v_sale_id,v_product.id,v_batch,v_qty,v_unit.unit_code,v_base,v_price,v_line_discount,v_line_total);
    insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity)
    values(v_company,v_branch,v_warehouse,v_product.id,v_batch,0) on conflict (warehouse_id,product_id,batch_key) do nothing;
    update public.inventory_balances b set quantity=b.quantity-v_base, updated_at=now()
      where b.company_id=v_company and b.warehouse_id=v_warehouse and b.product_id=v_product.id and b.batch_key=coalesce(v_batch::text,'unbatched') and b.quantity>=v_base
      returning b.quantity into v_balance;
    if not found then raise exception 'Insufficient available stock for product %', v_product.name using errcode='23514'; end if;
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
    values(v_company,v_branch,v_warehouse,v_product.id,v_batch,'sale',-v_base,v_product.base_unit,'sale',v_sale_id,p_idempotency_key,v_user);
  end loop;

  insert into public.documents(company_id,branch_id,document_type,document_number,source_type,source_id,created_by)
  values(v_company,v_branch,'sales_invoice',v_doc,'sale',v_sale_id,v_user);
  v_result := jsonb_build_object('sale_id',v_sale_id,'document_number',v_doc,'status','posted','subtotal',v_subtotal,'discount_amount',v_discount,'shipping_amount',v_shipping,'total_amount',v_total);
  update public.idempotency_keys set response=v_result where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_result;
end
$$;

create or replace function public.create_purchase_draft(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_supplier uuid:=(p_payload->>'supplier_id')::uuid; v_purchase uuid:=gen_random_uuid(); v_doc text; v_line jsonb;
  v_product public.products%rowtype; v_unit public.product_units%rowtype; v_qty numeric(14,3); v_base numeric(14,3);
  v_price numeric(14,2); v_total numeric(14,2):=0; v_line_total numeric(14,2); v_old jsonb; v_result jsonb;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if not private.has_branch_access(v_company,v_branch) then raise exception 'Branch access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[]) then raise exception 'Purchasing permission denied' using errcode='42501'; end if;
  if p_idempotency_key is null or jsonb_typeof(p_payload->'items') <> 'array' or jsonb_array_length(p_payload->'items')=0 then raise exception 'Idempotency key and purchase items are required'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'create_purchase_draft') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  if not exists(select 1 from public.suppliers s where s.company_id=v_company and s.id=v_supplier and s.is_active) then raise exception 'Supplier is unavailable'; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'purchase');
  insert into public.purchases(id,company_id,branch_id,supplier_id,document_number,status,total_amount,notes,created_by)
    values(v_purchase,v_company,v_branch,v_supplier,v_doc,'draft',0,nullif(p_payload->>'notes',''),v_user);
  for v_line in select value from jsonb_array_elements(p_payload->'items') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid and p.is_active;
    if not found then raise exception 'Product is unavailable'; end if;
    select * into v_unit from public.product_units u where u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    if not found then raise exception 'Unit conversion is not configured'; end if;
    v_qty:=(v_line->>'quantity')::numeric; v_price:=(v_line->>'unit_price')::numeric;
    if v_qty is null or v_qty<=0 or v_price is null or v_price<0 then raise exception 'Invalid purchase quantity or price'; end if;
    v_base:=round(v_qty*v_unit.base_units_per_unit,3); v_line_total:=round(v_qty*v_price,2); v_total:=v_total+v_line_total;
    insert into public.purchase_items(company_id,branch_id,purchase_id,product_id,quantity,unit_code,base_quantity,unit_price,line_total)
      values(v_company,v_branch,v_purchase,v_product.id,v_qty,v_unit.unit_code,v_base,v_price,v_line_total);
  end loop;
  update public.purchases set total_amount=v_total where id=v_purchase;
  v_result:=jsonb_build_object('purchase_id',v_purchase,'document_number',v_doc,'status','draft','total_amount',v_total);
  update public.idempotency_keys set response=v_result where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_result;
end
$$;

create or replace function public.approve_purchase(p_purchase_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_purchase public.purchases%rowtype;
begin
  select * into v_purchase from public.purchases where id=p_purchase_id for update;
  if not found or not private.has_branch_access(v_purchase.company_id,v_purchase.branch_id) then raise exception 'Purchase not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_purchase.company_id,array['owner','super_admin','central_admin','branch_admin','supervisor']::public.app_role[]) then raise exception 'Approval permission denied' using errcode='42501'; end if;
  if v_purchase.status<>'draft' then raise exception 'Only draft purchases can be approved'; end if;
  update public.purchases set status='approved' where id=v_purchase.id;
end
$$;

create or replace function public.post_goods_receipt(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_warehouse uuid:=(p_payload->>'warehouse_id')::uuid; v_purchase uuid:=(p_payload->>'purchase_id')::uuid;
  v_receipt uuid:=gen_random_uuid(); v_doc text; v_line jsonb; v_product public.products%rowtype; v_purchase_row public.purchases%rowtype;
  v_unit public.product_units%rowtype; v_purchase_item public.purchase_items%rowtype; v_qty numeric(14,3); v_base numeric(14,3); v_cost numeric(14,2); v_batch uuid; v_received numeric(14,3);
  v_number text; v_old jsonb; v_result jsonb;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if not private.has_branch_access(v_company,v_branch) then raise exception 'Branch access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','purchasing','warehouse','supervisor']::public.app_role[]) then raise exception 'Receiving permission denied' using errcode='42501'; end if;
  if jsonb_typeof(p_payload->'items') <> 'array' or jsonb_array_length(p_payload->'items')=0 then raise exception 'Receipt items are required'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'post_goods_receipt') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  select * into v_purchase_row from public.purchases p where p.company_id=v_company and p.branch_id=v_branch and p.id=v_purchase for update;
  if not found or v_purchase_row.status not in ('approved','partially_received') then raise exception 'Purchase must be approved before receiving'; end if;
  if not exists(select 1 from public.warehouses w where w.company_id=v_company and w.branch_id=v_branch and w.id=v_warehouse and w.is_active) then raise exception 'Warehouse is not available'; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'receipt');
  insert into public.goods_receipts(id,company_id,branch_id,warehouse_id,purchase_id,document_number,status,received_by,idempotency_key)
    values(v_receipt,v_company,v_branch,v_warehouse,v_purchase,v_doc,'posted',v_user,p_idempotency_key);
  for v_line in select value from jsonb_array_elements(p_payload->'items') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid and p.is_active;
    if not found then raise exception 'Product is unavailable'; end if;
    select * into v_unit from public.product_units u where u.company_id=v_company and u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    if not found then raise exception 'Unit conversion is not configured'; end if;
    v_qty:=(v_line->>'quantity')::numeric; if v_qty<=0 then raise exception 'Quantity must be greater than zero'; end if;
    v_base:=round(v_qty*v_unit.base_units_per_unit,3); v_cost:=coalesce((v_line->>'unit_cost')::numeric,0);
    select * into v_purchase_item from public.purchase_items pi where pi.company_id=v_company and pi.branch_id=v_branch and pi.purchase_id=v_purchase and pi.id=(v_line->>'purchase_item_id')::uuid and pi.product_id=v_product.id for update;
    if not found then raise exception 'Purchase item does not match this receipt'; end if;
    select coalesce(sum(gri.base_quantity),0) into v_received from public.goods_receipt_items gri join public.goods_receipts gr on gr.id=gri.receipt_id where gri.purchase_item_id=v_purchase_item.id and gr.status='posted';
    if v_received+v_base>v_purchase_item.base_quantity then raise exception 'Receipt quantity exceeds the remaining purchase quantity'; end if;
    v_batch:=gen_random_uuid(); v_number:=coalesce(nullif(v_line->>'batch_number',''),'RCV-'||left(v_receipt::text,8)||'-'||left(v_product.id::text,4)||'-'||left(v_batch::text,4));
    insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,quality_status)
      values(v_batch,v_company,v_branch,v_product.id,v_number,'receipt',v_receipt,'pending');
    insert into public.goods_receipt_items(company_id,branch_id,receipt_id,purchase_item_id,product_id,batch_id,quantity,unit_code,base_quantity,unit_cost)
      values(v_company,v_branch,v_receipt,v_purchase_item.id,v_product.id,v_batch,v_qty,v_unit.unit_code,v_base,v_cost);
    insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity)
      values(v_company,v_branch,v_warehouse,v_product.id,v_batch,v_base);
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v_company,v_branch,v_warehouse,v_product.id,v_batch,'receipt',v_base,v_product.base_unit,'goods_receipt',v_receipt,p_idempotency_key,v_user);
  end loop;
  update public.purchases p set status=case when (
    select bool_and(coalesce(received.base_quantity,0)>=pi.base_quantity)
    from public.purchase_items pi
    left join lateral (
      select sum(gri.base_quantity) as base_quantity from public.goods_receipt_items gri
      join public.goods_receipts gr on gr.id=gri.receipt_id
      where gri.purchase_item_id=pi.id and gr.status='posted'
    ) received on true
    where pi.purchase_id=p.id
  ) then 'posted'::public.transaction_status else 'partially_received'::public.transaction_status end
  where p.id=v_purchase;
  v_result:=jsonb_build_object('receipt_id',v_receipt,'document_number',v_doc,'status','posted');
  update public.idempotency_keys set response=v_result where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_result;
end
$$;

create or replace function public.post_production_batch(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_warehouse uuid:=(p_payload->>'warehouse_id')::uuid; v_prod uuid:=gen_random_uuid(); v_doc text; v_line jsonb;
  v_product public.products%rowtype; v_unit public.product_units%rowtype; v_batch public.product_batches%rowtype;
  v_qty numeric(14,3); v_base numeric(14,3); v_balance numeric(14,3); v_output_batch uuid; v_output_id uuid;
  v_input_id uuid; v_number text; v_old jsonb; v_result jsonb;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if not private.has_branch_access(v_company,v_branch) then raise exception 'Branch access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','production','supervisor']::public.app_role[]) then raise exception 'Production permission denied' using errcode='42501'; end if;
  if p_idempotency_key is null or jsonb_typeof(p_payload->'inputs') <> 'array' or jsonb_array_length(p_payload->'inputs')=0 or jsonb_typeof(p_payload->'outputs') <> 'array' or jsonb_array_length(p_payload->'outputs')=0 then raise exception 'Production inputs and outputs are required'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'post_production_batch') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  if not exists(select 1 from public.warehouses w where w.company_id=v_company and w.branch_id=v_branch and w.id=v_warehouse and w.is_active) then raise exception 'Warehouse is unavailable'; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'production');
  insert into public.production_batches(id,company_id,branch_id,warehouse_id,batch_number,status,notes,idempotency_key,created_by)
    values(v_prod,v_company,v_branch,v_warehouse,v_doc,'posted',nullif(p_payload->>'notes',''),p_idempotency_key,v_user);
  for v_line in select value from jsonb_array_elements(p_payload->'inputs') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid and p.is_active;
    if not found then raise exception 'Input product is unavailable'; end if;
    select * into v_unit from public.product_units u where u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    if not found then raise exception 'Input unit is not configured'; end if;
    select * into v_batch from public.product_batches b where b.company_id=v_company and b.branch_id=v_branch and b.product_id=v_product.id and b.id=(v_line->>'batch_id')::uuid and b.quality_status='passed';
    if not found then raise exception 'Input batch is unavailable or has not passed quality inspection'; end if;
    v_qty:=(v_line->>'quantity')::numeric; if v_qty is null or v_qty<=0 then raise exception 'Input quantity must be greater than zero'; end if;
    v_base:=round(v_qty*v_unit.base_units_per_unit,3);
    insert into public.production_inputs(company_id,branch_id,production_batch_id,product_id,batch_id,quantity,unit_code,base_quantity)
      values(v_company,v_branch,v_prod,v_product.id,v_batch.id,v_qty,v_unit.unit_code,v_base) returning id into v_input_id;
    update public.inventory_balances b set quantity=b.quantity-v_base,updated_at=now()
      where b.company_id=v_company and b.warehouse_id=v_warehouse and b.product_id=v_product.id and b.batch_key=v_batch.id::text and b.quantity>=v_base returning b.quantity into v_balance;
    if not found then raise exception 'Insufficient stock for input product %',v_product.name using errcode='23514'; end if;
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v_company,v_branch,v_warehouse,v_product.id,v_batch.id,'production_input',-v_base,v_product.base_unit,'production_input',v_input_id,gen_random_uuid(),v_user);
  end loop;
  for v_line in select value from jsonb_array_elements(p_payload->'outputs') loop
    select * into v_product from public.products p where p.company_id=v_company and p.id=(v_line->>'product_id')::uuid and p.is_active;
    if not found then raise exception 'Output product is unavailable'; end if;
    select * into v_unit from public.product_units u where u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    if not found then raise exception 'Output unit is not configured'; end if;
    v_qty:=(v_line->>'quantity')::numeric; if v_qty is null or v_qty<=0 then raise exception 'Output quantity must be greater than zero'; end if;
    v_base:=round(v_qty*v_unit.base_units_per_unit,3); v_output_batch:=gen_random_uuid();
    v_number:=coalesce(nullif(v_line->>'batch_number',''),v_doc||'-'||v_product.sku||'-'||left(v_output_batch::text,4));
    insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,produced_at,quality_status)
      values(v_output_batch,v_company,v_branch,v_product.id,v_number,'production',v_prod,now(),'pending');
    insert into public.production_outputs(company_id,branch_id,production_batch_id,product_id,batch_id,quantity,unit_code,base_quantity)
      values(v_company,v_branch,v_prod,v_product.id,v_output_batch,v_qty,v_unit.unit_code,v_base) returning id into v_output_id;
    insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity)
      values(v_company,v_branch,v_warehouse,v_product.id,v_output_batch,v_base);
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v_company,v_branch,v_warehouse,v_product.id,v_output_batch,'production_output',v_base,v_product.base_unit,'production_output',v_output_id,gen_random_uuid(),v_user);
  end loop;
  if jsonb_typeof(p_payload->'waste')='array' then
    for v_line in select value from jsonb_array_elements(p_payload->'waste') loop
      v_qty:=(v_line->>'quantity')::numeric;
      if v_qty is null or v_qty<=0 or nullif(v_line->>'reason','') is null then raise exception 'Waste entries need a positive quantity and a reason'; end if;
      insert into public.waste_records(company_id,branch_id,production_batch_id,quantity,unit_code,reason,created_by)
        values(v_company,v_branch,v_prod,v_qty,v_line->>'unit_code',v_line->>'reason',v_user);
    end loop;
  end if;
  v_result:=jsonb_build_object('production_batch_id',v_prod,'batch_number',v_doc,'status','posted','quality_status','pending');
  update public.idempotency_keys set response=v_result where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_result;
end
$$;

create or replace function public.inspect_product_batch(p_batch_id uuid, p_result text, p_notes text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare v_batch public.product_batches%rowtype;
begin
  select * into v_batch from public.product_batches where id=p_batch_id for update;
  if not found or not private.has_branch_access(v_batch.company_id,v_batch.branch_id) then raise exception 'Batch not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_batch.company_id,array['owner','super_admin','central_admin','branch_admin','warehouse','production','supervisor']::public.app_role[]) then raise exception 'Quality inspection permission denied' using errcode='42501'; end if;
  if p_result not in ('passed','rejected','quarantined') then raise exception 'Invalid inspection result'; end if;
  if v_batch.quality_status<>'pending' then raise exception 'Only pending batches can be inspected'; end if;
  insert into public.quality_inspections(company_id,branch_id,batch_id,result,notes,inspected_by)
    values(v_batch.company_id,v_batch.branch_id,v_batch.id,p_result,nullif(p_notes,''),auth.uid());
  update public.product_batches set quality_status=p_result where id=v_batch.id;
end
$$;

create or replace function public.record_customer_payment(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_customer uuid:=(p_payload->>'customer_id')::uuid; v_amount numeric(14,2):=(p_payload->>'amount')::numeric;
  v_payment uuid:=gen_random_uuid(); v_doc text; v_item jsonb; v_sale public.sales%rowtype; v_alloc numeric(14,2); v_allocated numeric(14,2):=0;
  v_old jsonb; v_result jsonb; v_method text:=p_payload->>'payment_method';
begin
  if v_user is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if not private.has_branch_access(v_company,v_branch) then raise exception 'Branch access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','cashier','finance']::public.app_role[]) then raise exception 'Payment permission denied' using errcode='42501'; end if;
  if v_amount is null or v_amount<=0 or v_method not in ('cash','bank_transfer','other') then raise exception 'Invalid payment amount or method'; end if;
  if jsonb_typeof(p_payload->'allocations') <> 'array' or jsonb_array_length(p_payload->'allocations')=0 then raise exception 'Payment allocations are required'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'record_customer_payment') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  if not exists(select 1 from public.customers c where c.company_id=v_company and c.id=v_customer and c.is_active) then raise exception 'Customer is not available'; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'payment');
  insert into public.customer_payments(id,company_id,branch_id,customer_id,document_number,amount,payment_method,reference,received_by,idempotency_key)
    values(v_payment,v_company,v_branch,v_customer,v_doc,v_amount,v_method,nullif(p_payload->>'reference',''),v_user,p_idempotency_key);
  for v_item in select value from jsonb_array_elements(p_payload->'allocations') loop
    select * into v_sale from public.sales s where s.company_id=v_company and s.branch_id=v_branch and s.id=(v_item->>'sale_id')::uuid and s.customer_id=v_customer and s.status='posted' for update;
    if not found then raise exception 'Invoice not found for this customer and branch'; end if;
    v_alloc:=(v_item->>'amount')::numeric;
    if v_alloc is null or v_alloc<=0 or v_alloc > v_sale.total_amount-v_sale.paid_amount then raise exception 'Allocation exceeds invoice balance'; end if;
    insert into public.payment_allocations(company_id,branch_id,payment_id,sale_id,amount) values(v_company,v_branch,v_payment,v_sale.id,v_alloc);
    update public.sales set paid_amount=paid_amount+v_alloc where id=v_sale.id;
    v_allocated:=v_allocated+v_alloc;
  end loop;
  if v_allocated<>v_amount then raise exception 'Payment amount must equal total allocations'; end if;
  insert into public.documents(company_id,branch_id,document_type,document_number,source_type,source_id,created_by)
    values(v_company,v_branch,'payment_receipt',v_doc,'customer_payment',v_payment,v_user);
  v_result:=jsonb_build_object('payment_id',v_payment,'document_number',v_doc,'amount',v_amount,'status','posted');
  update public.idempotency_keys set response=v_result where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_result;
end
$$;

create or replace function public.record_document_print(p_source_type text, p_source_id uuid)
returns table(document_number text, print_count integer, printed_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare v_document public.documents%rowtype;
begin
  select * into v_document from public.documents d where d.source_type=p_source_type and d.source_id=p_source_id for update;
  if not found or not private.has_branch_access(v_document.company_id,v_document.branch_id) then raise exception 'Document not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_document.company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance','purchasing']::public.app_role[]) then raise exception 'Document print permission denied' using errcode='42501'; end if;
  update public.documents d set print_count=d.print_count+1,last_printed_at=now() where d.id=v_document.id returning d.document_number,d.print_count,d.last_printed_at into document_number,print_count,printed_at;
  return next;
end
$$;

create or replace function public.confirm_ocr_review(p_scan_id uuid, p_reviewed_data jsonb, p_duplicate boolean default false)
returns void language plpgsql security definer set search_path = '' as $$
declare v_scan public.scanned_documents%rowtype;
begin
  select * into v_scan from public.scanned_documents where id=p_scan_id for update;
  if not found or not private.has_branch_access(v_scan.company_id,v_scan.branch_id) then raise exception 'Document not found or access denied' using errcode='42501'; end if;
  if v_scan.status not in ('needs_review','duplicate_candidate') then raise exception 'Only extracted documents can be reviewed'; end if;
  if not private.has_any_role(v_scan.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance','cashier']::public.app_role[]) then raise exception 'Review permission denied' using errcode='42501'; end if;
  update public.scanned_documents set status=case when p_duplicate then 'duplicate_candidate' else 'confirmed' end, reviewed_by=auth.uid(), reviewed_at=now() where id=p_scan_id;
  update public.ocr_extractions set reviewed_data=p_reviewed_data, reviewed_by=auth.uid(), reviewed_at=now() where scanned_document_id=p_scan_id and company_id=v_scan.company_id;
end
$$;

create or replace function public.start_ocr_processing(p_scan_id uuid, p_consent boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare v_scan public.scanned_documents%rowtype;
begin
  select * into v_scan from public.scanned_documents where id=p_scan_id for update;
  if not found or not private.has_branch_access(v_scan.company_id,v_scan.branch_id) then raise exception 'Document not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_scan.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance','cashier']::public.app_role[]) then raise exception 'OCR permission denied' using errcode='42501'; end if;
  if p_consent is not true then raise exception 'Explicit AI processing consent is required' using errcode='42501'; end if;
  if v_scan.status not in ('uploaded','failed') then raise exception 'Document is already processing or reviewed'; end if;
  update public.scanned_documents set status='processing', ai_consent_by=auth.uid(), ai_consent_at=now() where id=p_scan_id;
end
$$;

create or replace function public.fail_ocr_processing(p_scan_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_scan public.scanned_documents%rowtype;
begin
  select * into v_scan from public.scanned_documents where id=p_scan_id for update;
  if not found or not private.has_branch_access(v_scan.company_id,v_scan.branch_id) then raise exception 'Document not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_scan.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance','cashier']::public.app_role[]) then raise exception 'OCR permission denied' using errcode='42501'; end if;
  if v_scan.status='processing' then update public.scanned_documents set status='failed' where id=p_scan_id; end if;
end
$$;

create or replace function public.save_ocr_result(p_scan_id uuid, p_provider text, p_model text, p_data jsonb, p_confidence numeric, p_warnings jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_scan public.scanned_documents%rowtype; v_id uuid:=gen_random_uuid(); v_duplicate boolean:=false; v_review_warnings jsonb;
begin
  select * into v_scan from public.scanned_documents where id=p_scan_id for update;
  if not found or not private.has_branch_access(v_scan.company_id,v_scan.branch_id) then raise exception 'Document not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_scan.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance','cashier']::public.app_role[]) then raise exception 'OCR permission denied' using errcode='42501'; end if;
  if v_scan.ai_consent_by is null or v_scan.ai_consent_at is null then raise exception 'Document owner consent for AI processing is missing' using errcode='42501'; end if;
  if v_scan.status not in ('uploaded','failed','processing') then raise exception 'Document is not eligible for OCR'; end if;
  if v_scan.source_hash is not null then
    select exists(select 1 from public.scanned_documents d where d.company_id=v_scan.company_id and d.branch_id=v_scan.branch_id and d.source_hash=v_scan.source_hash and d.id<>v_scan.id and d.status<>'failed') into v_duplicate;
  end if;
  v_review_warnings:=coalesce(p_warnings,'[]'::jsonb);
  if v_duplicate then v_review_warnings:=v_review_warnings||jsonb_build_array('File dengan hash sama sudah pernah dipindai pada cabang ini; periksa dokumen terkait.'); end if;
  insert into public.ocr_extractions(id,company_id,branch_id,scanned_document_id,provider,model,extracted_data,confidence,warnings)
    values(v_id,v_scan.company_id,v_scan.branch_id,v_scan.id,p_provider,p_model,coalesce(p_data,'{}'::jsonb),p_confidence,v_review_warnings);
  update public.scanned_documents set status=case when v_duplicate then 'duplicate_candidate' else 'needs_review' end where id=v_scan.id;
  return v_id;
end
$$;

create or replace function public.get_sales_report(p_company_id uuid, p_branch_id uuid, p_from date, p_to date)
returns table(day date, branch_id uuid, sales_count bigint, unpaid_count bigint, gross_sales numeric, paid_total numeric, receivable_total numeric)
language sql stable security definer set search_path = '' as $$
  select (s.created_at at time zone 'Asia/Jakarta')::date, s.branch_id, count(*)::bigint, count(*) filter (where s.total_amount>s.paid_amount)::bigint,
    sum(s.total_amount), sum(s.paid_amount), sum(s.total_amount-s.paid_amount)
  from public.sales s
  where s.company_id=p_company_id and (p_branch_id is null or s.branch_id=p_branch_id)
    and s.created_at >= (p_from::timestamp at time zone 'Asia/Jakarta') and s.created_at < ((p_to+1)::timestamp at time zone 'Asia/Jakarta') and s.status='posted'
    and private.has_branch_access(s.company_id,s.branch_id)
  group by 1,2 order by 1,2
$$;

create or replace function public.get_purchase_report(p_company_id uuid, p_branch_id uuid, p_from date, p_to date)
returns table(day date, supplier_id uuid, supplier_name text, purchase_count bigint, draft_count bigint, approved_count bigint, partial_count bigint, received_count bigint, voided_count bigint, ordered_total numeric)
language sql stable security definer set search_path = '' as $$
  select (pu.created_at at time zone 'Asia/Jakarta')::date,pu.supplier_id,su.name,count(*)::bigint,
    count(*) filter(where pu.status='draft')::bigint,count(*) filter(where pu.status='approved')::bigint,
    count(*) filter(where pu.status='partially_received')::bigint,count(*) filter(where pu.status='posted')::bigint,
    count(*) filter(where pu.status='voided')::bigint,sum(pu.total_amount)::numeric
  from public.purchases pu
  join public.suppliers su on su.company_id=pu.company_id and su.id=pu.supplier_id
  where pu.company_id=p_company_id and (p_branch_id is null or pu.branch_id=p_branch_id)
    and pu.created_at >= (p_from::timestamp at time zone 'Asia/Jakarta') and pu.created_at < ((p_to+1)::timestamp at time zone 'Asia/Jakarta')
    and private.has_branch_access(pu.company_id,pu.branch_id)
  group by 1,2,3 order by 1 desc,3
$$;

create or replace function public.get_production_report(p_company_id uuid, p_branch_id uuid, p_from date, p_to date)
returns table(production_batch_id uuid, branch_id uuid, produced_at timestamptz, batch_number text, notes text, inputs jsonb, outputs jsonb, waste jsonb)
language sql stable security definer set search_path = '' as $$
  select pb.id,pb.branch_id,pb.produced_at,pb.batch_number,pb.notes,
    coalesce((select jsonb_agg(jsonb_build_object('product_name',p.name,'sku',p.sku,'batch_number',b.batch_number,'quantity',pi.quantity,'unit_code',pi.unit_code) order by p.name)
      from public.production_inputs pi join public.products p on p.company_id=pi.company_id and p.id=pi.product_id
      join public.product_batches b on b.company_id=pi.company_id and b.id=pi.batch_id where pi.production_batch_id=pb.id),'[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('product_name',p.name,'sku',p.sku,'batch_number',b.batch_number,'quantity',po.quantity,'unit_code',po.unit_code) order by p.name)
      from public.production_outputs po join public.products p on p.company_id=po.company_id and p.id=po.product_id
      join public.product_batches b on b.company_id=po.company_id and b.id=po.batch_id where po.production_batch_id=pb.id),'[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('quantity',wr.quantity,'unit_code',wr.unit_code,'reason',wr.reason) order by wr.created_at)
      from public.waste_records wr where wr.production_batch_id=pb.id),'[]'::jsonb)
  from public.production_batches pb
  where pb.company_id=p_company_id and (p_branch_id is null or pb.branch_id=p_branch_id)
    and pb.produced_at >= (p_from::timestamp at time zone 'Asia/Jakarta') and pb.produced_at < ((p_to+1)::timestamp at time zone 'Asia/Jakarta')
    and private.has_branch_access(pb.company_id,pb.branch_id)
  order by pb.produced_at desc,pb.batch_number
$$;

create or replace function public.get_inventory_report(p_company_id uuid, p_branch_id uuid default null, p_warehouse_id uuid default null)
returns table(branch_id uuid, warehouse_id uuid, product_id uuid, product_name text, sku text, species text, batch_id uuid, quality_status text, quantity numeric, base_unit text, minimum_stock numeric)
language sql stable security definer set search_path = '' as $$
  select b.branch_id,b.warehouse_id,b.product_id,p.name,p.sku,p.species,b.batch_id,pb.quality_status,b.quantity,p.base_unit,p.minimum_stock
  from public.inventory_balances b join public.products p on p.company_id=b.company_id and p.id=b.product_id
  left join public.product_batches pb on pb.company_id=b.company_id and pb.id=b.batch_id
  where b.company_id=p_company_id and (p_branch_id is null or b.branch_id=p_branch_id)
    and (p_warehouse_id is null or b.warehouse_id=p_warehouse_id) and private.has_branch_access(b.company_id,b.branch_id)
  order by p.name,b.branch_id,b.warehouse_id
$$;

create or replace function public.get_inventory_movement_report(p_company_id uuid, p_branch_id uuid, p_warehouse_id uuid default null, p_product_id uuid default null, p_limit integer default 100)
returns table(movement_id uuid, branch_id uuid, warehouse_id uuid, warehouse_name text, product_id uuid, product_name text, sku text, batch_id uuid, batch_number text, movement_type text, quantity_delta numeric, unit_code text, source_type text, source_reference text, created_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select m.id,m.branch_id,m.warehouse_id,w.name,p.id,p.name,p.sku,m.batch_id,pb.batch_number,m.movement_type,m.quantity_delta,m.unit_code,m.source_type,
    coalesce(s.document_number,gr.document_number,prod.batch_number,pi.production_batch_id::text,po.production_batch_id::text,m.source_id::text),m.created_at
  from public.inventory_movements m
  join public.warehouses w on w.company_id=m.company_id and w.branch_id=m.branch_id and w.id=m.warehouse_id
  join public.products p on p.company_id=m.company_id and p.id=m.product_id
  left join public.product_batches pb on pb.company_id=m.company_id and pb.id=m.batch_id
  left join public.sales s on m.source_type='sale' and s.company_id=m.company_id and s.id=m.source_id
  left join public.goods_receipts gr on m.source_type='goods_receipt' and gr.company_id=m.company_id and gr.id=m.source_id
  left join public.production_inputs pi on m.source_type='production_input' and pi.company_id=m.company_id and pi.id=m.source_id
  left join public.production_outputs po on m.source_type='production_output' and po.company_id=m.company_id and po.id=m.source_id
  left join public.production_batches prod on prod.company_id=m.company_id and prod.id=coalesce(pi.production_batch_id,po.production_batch_id)
  where m.company_id=p_company_id and m.branch_id=p_branch_id
    and (p_warehouse_id is null or m.warehouse_id=p_warehouse_id)
    and (p_product_id is null or m.product_id=p_product_id)
    and private.has_branch_access(m.company_id,m.branch_id)
  order by m.created_at desc,m.id desc
  limit least(greatest(coalesce(p_limit,100),1),500)
$$;

create or replace function public.get_batch_traceability(p_batch_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'batch',jsonb_build_object(
      'id',b.id,'batch_number',b.batch_number,'source_type',b.source_type,'created_at',b.created_at,
      'produced_at',b.produced_at,'expires_at',b.expires_at,'quality_status',b.quality_status,
      'product_id',p.id,'product_name',p.name,'sku',p.sku,'base_unit',p.base_unit,'branch_id',b.branch_id,'branch_name',br.name
    ),
    'events',coalesce(jsonb_agg(e.event order by e.happened_at,e.sort_key) filter(where e.event is not null),'[]'::jsonb)
  )
  from public.product_batches b
  join public.products p on p.company_id=b.company_id and p.id=b.product_id
  join public.branches br on br.company_id=b.company_id and br.id=b.branch_id
  left join lateral (
    select gr.received_at as happened_at,gr.id::text as sort_key,
      jsonb_build_object('event_type','receipt','happened_at',gr.received_at,'description','Batch diterima dari pemasok',
        'reference',gr.document_number,'related_reference',pu.document_number,'party_name',su.name,
        'quantity',gri.quantity,'unit_code',gri.unit_code,'related_batch_id',null,'related_batch_number',null) as event
    from public.goods_receipt_items gri
    join public.goods_receipts gr on gr.company_id=gri.company_id and gr.id=gri.receipt_id
    join public.purchases pu on pu.company_id=gr.company_id and pu.id=gr.purchase_id
    left join public.suppliers su on su.company_id=pu.company_id and su.id=pu.supplier_id
    where gri.company_id=b.company_id and gri.branch_id=b.branch_id and gri.batch_id=b.id and gr.status='posted'
    union all
    select pb.produced_at,pb.id::text,
      jsonb_build_object('event_type','production_output','happened_at',pb.produced_at,'description','Batch dihasilkan dari proses produksi',
        'reference',pb.batch_number,'related_reference',null,'party_name',null,'quantity',po.quantity,'unit_code',po.unit_code,
        'related_batch_id',null,'related_batch_number',null)
    from public.production_outputs po
    join public.production_batches pb on pb.company_id=po.company_id and pb.branch_id=po.branch_id and pb.id=po.production_batch_id
    where po.company_id=b.company_id and po.branch_id=b.branch_id and po.batch_id=b.id
    union all
    select pb.produced_at,pb.id::text||outb.id::text,
      jsonb_build_object('event_type','production_input','happened_at',pb.produced_at,'description','Batch diproses menjadi '||outp.name,
        'reference',pb.batch_number,'related_reference',outb.batch_number,'party_name',null,'quantity',null,'unit_code',null,
        'related_batch_id',outb.id,'related_batch_number',outb.batch_number)
    from public.production_inputs pi
    join public.production_batches pb on pb.company_id=pi.company_id and pb.branch_id=pi.branch_id and pb.id=pi.production_batch_id
    join public.production_outputs po on po.company_id=pb.company_id and po.branch_id=pb.branch_id and po.production_batch_id=pb.id
    join public.product_batches outb on outb.company_id=po.company_id and outb.id=po.batch_id
    join public.products outp on outp.company_id=po.company_id and outp.id=po.product_id
    where pi.company_id=b.company_id and pi.branch_id=b.branch_id and pi.batch_id=b.id
    union all
    select qi.inspected_at,qi.id::text,
      jsonb_build_object('event_type','quality_inspection','happened_at',qi.inspected_at,'description','Hasil inspeksi: '||qi.result,
        'reference',null,'related_reference',null,'party_name',null,'quantity',null,'unit_code',null,
        'related_batch_id',null,'related_batch_number',null,'notes',qi.notes)
    from public.quality_inspections qi where qi.company_id=b.company_id and qi.branch_id=b.branch_id and qi.batch_id=b.id
    union all
    select s.created_at,s.id::text,
      jsonb_build_object('event_type','sale','happened_at',s.created_at,'description','Batch dijual',
        'reference',s.document_number,'related_reference',null,'party_name',coalesce(c.name,'Pelanggan umum'),
        'quantity',si.quantity,'unit_code',si.unit_code,'related_batch_id',null,'related_batch_number',null)
    from public.sales_items si
    join public.sales s on s.company_id=si.company_id and s.branch_id=si.branch_id and s.id=si.sale_id
    left join public.customers c on c.company_id=s.company_id and c.id=s.customer_id
    where si.company_id=b.company_id and si.branch_id=b.branch_id and si.batch_id=b.id and s.status='posted'
  ) e on true
  where b.id=p_batch_id and private.has_branch_access(b.company_id,b.branch_id)
  group by b.id,p.id,br.id
$$;

create or replace function public.get_receivables_total(p_company_id uuid, p_branch_id uuid default null)
returns numeric language sql stable security definer set search_path = '' as $$
  select coalesce(sum(s.total_amount-s.paid_amount),0)::numeric
  from public.sales s where s.company_id=p_company_id and (p_branch_id is null or s.branch_id=p_branch_id)
    and s.status='posted' and s.total_amount>s.paid_amount and private.has_branch_access(s.company_id,s.branch_id)
$$;

create or replace function public.create_product_master(p_payload jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_company uuid:=(p_payload->>'company_id')::uuid; v_product uuid:=gen_random_uuid(); v_sku text:=nullif(trim(p_payload->>'sku'),''); v_name text:=nullif(trim(p_payload->>'name'),''); v_unit text:=p_payload->>'base_unit';
begin
  if not private.has_company_access(v_company) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[]) then raise exception 'Product management permission denied' using errcode='42501'; end if;
  if v_sku is null or v_name is null or nullif(trim(p_payload->>'category'),'') is null or v_unit is null or v_unit not in ('kg','pcs','bird') then raise exception 'SKU, product name, category, and a valid base unit are required'; end if;
  insert into public.products(id,company_id,sku,name,species,category,base_unit,minimum_stock,is_active)
    values(v_product,v_company,v_sku,v_name,nullif(p_payload->>'species',''),trim(p_payload->>'category'),v_unit,coalesce((p_payload->>'minimum_stock')::numeric,0),true);
  insert into public.product_units(company_id,product_id,unit_code,base_units_per_unit,is_sellable)
    values(v_company,v_product,v_unit,1,true);
  return v_product;
end
$$;

create or replace function public.update_product_master(p_product_id uuid, p_payload jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare v_product public.products%rowtype;
begin
  select * into v_product from public.products where id=p_product_id for update;
  if not found or not private.has_company_access(v_product.company_id) then raise exception 'Product not found or access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_product.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[]) then raise exception 'Product management permission denied' using errcode='42501'; end if;
  update public.products set name=coalesce(nullif(trim(p_payload->>'name'),''),name),
    category=coalesce(nullif(trim(p_payload->>'category'),''),category),
    species=case when p_payload ? 'species' then nullif(p_payload->>'species','') else species end,
    minimum_stock=case when p_payload ? 'minimum_stock' then (p_payload->>'minimum_stock')::numeric else minimum_stock end,
    is_active=case when p_payload ? 'is_active' then (p_payload->>'is_active')::boolean else is_active end
  where id=p_product_id;
end
$$;

create or replace function private.enforce_base_unit_ratio()
returns trigger language plpgsql set search_path = '' as $$
begin
  if exists(select 1 from public.products p where p.company_id=new.company_id and p.id=new.product_id and p.base_unit=new.unit_code)
    and new.base_units_per_unit<>1 then
    raise exception 'A product base unit must always have a 1:1 conversion ratio';
  end if;
  return new;
end
$$;
create trigger product_unit_base_ratio_check before insert or update on public.product_units for each row execute function private.enforce_base_unit_ratio();

-- RLS on every application table; no anon access and no direct mutation of ledgers.
do $$
declare t text;
begin
  foreach t in array array['companies','branches','warehouses','profiles','user_roles','user_branch_access','suppliers','customers','products','product_units','document_sequences','sales','sales_items','purchases','purchase_items','product_batches','production_batches','production_inputs','production_outputs','waste_records','quality_inspections','goods_receipts','goods_receipt_items','inventory_balances','inventory_movements','customer_payments','payment_allocations','documents','scanned_documents','ocr_extractions','audit_logs','idempotency_keys'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from anon, authenticated',t);
    execute format('grant select on public.%I to authenticated',t);
  end loop;
end $$;

create policy supplier_master_insert on public.suppliers for insert to authenticated with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
);
create policy supplier_master_update on public.suppliers for update to authenticated using (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
) with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
);
create policy customer_master_insert on public.customers for insert to authenticated with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance']::public.app_role[])
);
create policy customer_master_update on public.customers for update to authenticated using (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance']::public.app_role[])
) with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance']::public.app_role[])
);
create policy product_units_master_insert on public.product_units for insert to authenticated with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
);
create policy product_units_master_update on public.product_units for update to authenticated using (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
) with check (
  private.has_company_access(company_id) and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing']::public.app_role[])
);

create policy profiles_self_read on public.profiles for select to authenticated using (user_id=(select auth.uid()));
create policy company_member_read on public.companies for select to authenticated using (private.has_company_access(id));
create policy branch_access_read on public.branches for select to authenticated using (private.has_branch_access(company_id,id));
create policy warehouse_access_read on public.warehouses for select to authenticated using (private.has_branch_access(company_id,branch_id));
create policy roles_company_read on public.user_roles for select to authenticated using (private.has_company_access(company_id));
create policy branch_users_self_read on public.user_branch_access for select to authenticated using (user_id=(select auth.uid()) or private.has_company_access(company_id));

do $$
declare t text;
begin
  foreach t in array array['suppliers','customers','products','product_units'] loop
    execute format('create policy company_scoped_read on public.%I for select to authenticated using (private.has_company_access(company_id))',t);
  end loop;
  foreach t in array array['sales','sales_items','purchases','purchase_items','product_batches','production_batches','production_inputs','production_outputs','waste_records','quality_inspections','goods_receipts','goods_receipt_items','inventory_balances','inventory_movements','customer_payments','payment_allocations','documents','scanned_documents','ocr_extractions'] loop
    execute format('create policy branch_scoped_read on public.%I for select to authenticated using (private.has_branch_access(company_id, branch_id))',t);
  end loop;
end $$;

create policy audit_branch_read on public.audit_logs for select to authenticated using (private.has_branch_access(company_id,branch_id) or (branch_id is null and private.has_company_access(company_id)));
create policy idempotency_owner_read on public.idempotency_keys for select to authenticated using (user_id=(select auth.uid()));
create policy scanned_docs_insert_own on public.scanned_documents for insert to authenticated with check (
  created_by=(select auth.uid()) and status='uploaded' and reviewed_by is null
  and private.has_branch_access(company_id,branch_id)
  and private.has_any_role(company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance','cashier']::public.app_role[])
);

-- No direct writes to posted business records. Writes happen through narrow RPCs.
revoke insert, update, delete on public.sales, public.sales_items, public.inventory_movements,
  public.inventory_balances, public.documents, public.goods_receipts, public.goods_receipt_items,
  public.product_batches, public.idempotency_keys, public.audit_logs from authenticated, anon;
grant insert on public.scanned_documents to authenticated;
grant insert, update on public.purchases, public.purchase_items, public.suppliers, public.customers,
  public.products, public.product_units to authenticated;
grant usage, select on all sequences in schema public to authenticated;

grant usage on schema private to authenticated;
grant execute on function private.has_company_access(uuid) to authenticated;
grant execute on function private.has_branch_access(uuid,uuid) to authenticated;
grant execute on function private.has_any_role(uuid,public.app_role[]) to authenticated;
revoke execute on function private.next_document_number(uuid,uuid,text) from public, anon, authenticated;
revoke execute on function private.audit_row() from public, anon, authenticated;
revoke execute on function public.post_sale(jsonb,uuid) from public, anon;
revoke execute on function public.post_goods_receipt(jsonb,uuid) from public, anon;
revoke execute on function public.post_production_batch(jsonb,uuid) from public, anon;
revoke execute on function public.inspect_product_batch(uuid,text,text) from public, anon;
revoke execute on function public.create_purchase_draft(jsonb,uuid) from public, anon;
revoke execute on function public.approve_purchase(uuid) from public, anon;
revoke execute on function public.confirm_ocr_review(uuid,jsonb,boolean) from public, anon;
revoke execute on function public.save_ocr_result(uuid,text,text,jsonb,numeric,jsonb) from public, anon;
revoke execute on function public.start_ocr_processing(uuid,boolean) from public, anon;
revoke execute on function public.fail_ocr_processing(uuid) from public, anon;
revoke execute on function public.get_sales_report(uuid,uuid,date,date) from public, anon;
revoke execute on function public.get_purchase_report(uuid,uuid,date,date) from public, anon;
revoke execute on function public.get_production_report(uuid,uuid,date,date) from public, anon;
revoke execute on function public.get_inventory_report(uuid,uuid,uuid) from public, anon;
revoke execute on function public.get_inventory_movement_report(uuid,uuid,uuid,uuid,integer) from public, anon;
revoke execute on function public.get_batch_traceability(uuid) from public, anon;
revoke execute on function public.create_product_master(jsonb) from public, anon;
revoke execute on function public.update_product_master(uuid,jsonb) from public, anon;
revoke execute on function public.get_receivables_total(uuid,uuid) from public, anon;
grant execute on function public.post_sale(jsonb,uuid) to authenticated;
grant execute on function public.post_goods_receipt(jsonb,uuid) to authenticated;
grant execute on function public.post_production_batch(jsonb,uuid) to authenticated;
grant execute on function public.inspect_product_batch(uuid,text,text) to authenticated;
grant execute on function public.create_purchase_draft(jsonb,uuid) to authenticated;
grant execute on function public.approve_purchase(uuid) to authenticated;
revoke execute on function public.record_customer_payment(jsonb,uuid) from public, anon;
revoke execute on function public.record_document_print(text,uuid) from public, anon;
grant execute on function public.record_customer_payment(jsonb,uuid) to authenticated;
grant execute on function public.record_document_print(text,uuid) to authenticated;
grant execute on function public.confirm_ocr_review(uuid,jsonb,boolean) to authenticated;
grant execute on function public.save_ocr_result(uuid,text,text,jsonb,numeric,jsonb) to authenticated;
grant execute on function public.start_ocr_processing(uuid,boolean) to authenticated;
grant execute on function public.fail_ocr_processing(uuid) to authenticated;
grant execute on function public.get_sales_report(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_purchase_report(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_production_report(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_inventory_report(uuid,uuid,uuid) to authenticated;
grant execute on function public.get_inventory_movement_report(uuid,uuid,uuid,uuid,integer) to authenticated;
grant execute on function public.get_batch_traceability(uuid) to authenticated;
grant execute on function public.create_product_master(jsonb) to authenticated;
grant execute on function public.update_product_master(uuid,jsonb) to authenticated;
grant execute on function public.get_receivables_total(uuid,uuid) to authenticated;

-- Private Storage bucket for original receipts and supporting documents.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('business-documents','business-documents',false,12582912,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public=false,file_size_limit=12582912,allowed_mime_types=excluded.allowed_mime_types;
create policy business_docs_read on storage.objects for select to authenticated using (
  bucket_id='business-documents' and private.has_branch_access((storage.foldername(name))[1]::uuid,(storage.foldername(name))[2]::uuid)
);
create policy business_docs_insert on storage.objects for insert to authenticated with check (
  bucket_id='business-documents' and (storage.foldername(name))[3]=(select auth.uid())::text
  and private.has_branch_access((storage.foldername(name))[1]::uuid,(storage.foldername(name))[2]::uuid)
);
create policy business_docs_update on storage.objects for update to authenticated using (
  bucket_id='business-documents' and (storage.foldername(name))[3]=(select auth.uid())::text
  and private.has_branch_access((storage.foldername(name))[1]::uuid,(storage.foldername(name))[2]::uuid)
) with check (
  bucket_id='business-documents' and (storage.foldername(name))[3]=(select auth.uid())::text
  and private.has_branch_access((storage.foldername(name))[1]::uuid,(storage.foldername(name))[2]::uuid)
);
create policy business_docs_delete_own on storage.objects for delete to authenticated using (
  bucket_id='business-documents' and (storage.foldername(name))[3]=(select auth.uid())::text
  and private.has_branch_access((storage.foldername(name))[1]::uuid,(storage.foldername(name))[2]::uuid)
);
