-- Operational controls and configurable finance modules.
-- Costing and automatic account mappings are intentionally not inferred.

create table public.stock_transfers (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  source_branch_id uuid not null, destination_branch_id uuid not null, source_warehouse_id uuid not null,
  destination_warehouse_id uuid not null, document_number text not null, status text not null default 'requested'
    check (status in ('requested','approved','shipped','partially_received','received','rejected')),
  notes text, requested_by uuid not null references auth.users(id), approved_by uuid references auth.users(id),
  shipped_at timestamptz, received_at timestamptz, idempotency_key uuid not null, created_at timestamptz not null default now(),
  foreign key (company_id,source_branch_id,source_warehouse_id) references public.warehouses(company_id,branch_id,id),
  foreign key (company_id,destination_branch_id,destination_warehouse_id) references public.warehouses(company_id,branch_id,id),
  check (source_warehouse_id<>destination_warehouse_id), unique(company_id,document_number),
  unique(company_id,requested_by,idempotency_key), unique(company_id,id)
);
create table public.stock_transfer_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, transfer_id uuid not null,
  product_id uuid not null, source_batch_id uuid not null, destination_batch_id uuid,
  requested_quantity numeric(14,3) not null check(requested_quantity>0), shipped_quantity numeric(14,3) not null default 0,
  received_quantity numeric(14,3) not null default 0, unit_code text not null, discrepancy_note text,
  foreign key(company_id,transfer_id) references public.stock_transfers(company_id,id),
  foreign key(company_id,product_id) references public.products(company_id,id),
  foreign key(company_id,source_batch_id) references public.product_batches(company_id,id),
  foreign key(company_id,destination_batch_id) references public.product_batches(company_id,id)
);

create table public.stock_opnames (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  warehouse_id uuid not null, document_number text not null, status text not null default 'draft'
    check(status in ('draft','submitted','posted','rejected')), reason text not null, notes text,
  created_by uuid not null references auth.users(id), submitted_at timestamptz, posted_by uuid references auth.users(id),
  posted_at timestamptz, idempotency_key uuid not null, created_at timestamptz not null default now(),
  foreign key(company_id,branch_id,warehouse_id) references public.warehouses(company_id,branch_id,id),
  unique(company_id,document_number), unique(company_id,created_by,idempotency_key), unique(company_id,branch_id,id)
);
create table public.stock_opname_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, branch_id uuid not null, opname_id uuid not null,
  product_id uuid not null, batch_id uuid, expected_quantity numeric(14,3) not null, counted_quantity numeric(14,3) not null check(counted_quantity>=0),
  unit_code text not null, variance numeric(14,3) generated always as (counted_quantity-expected_quantity) stored,
  foreign key(company_id,branch_id,opname_id) references public.stock_opnames(company_id,branch_id,id),
  foreign key(company_id,product_id) references public.products(company_id,id),
  foreign key(company_id,branch_id,batch_id) references public.product_batches(company_id,branch_id,id)
);

create table public.sales_returns (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  sale_id uuid not null, warehouse_id uuid not null, document_number text not null, status text not null default 'draft'
    check(status in ('draft','posted','rejected')), reason text not null, notes text,
  created_by uuid not null references auth.users(id), posted_by uuid references auth.users(id), posted_at timestamptz,
  idempotency_key uuid not null, created_at timestamptz not null default now(),
  foreign key(company_id,branch_id,sale_id) references public.sales(company_id,branch_id,id),
  foreign key(company_id,branch_id,warehouse_id) references public.warehouses(company_id,branch_id,id),
  unique(company_id,document_number), unique(company_id,created_by,idempotency_key), unique(company_id,branch_id,id)
);
create table public.sales_return_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, branch_id uuid not null, return_id uuid not null,
  sale_item_id uuid not null, product_id uuid not null, source_batch_id uuid not null, returned_batch_id uuid,
  quantity numeric(14,3) not null check(quantity>0), unit_code text not null, disposition text not null default 'quarantine'
    check(disposition in ('quarantine','restock_after_inspection','dispose')),
  foreign key(company_id,branch_id,return_id) references public.sales_returns(company_id,branch_id,id),
  foreign key(company_id,product_id) references public.products(company_id,id),
  foreign key(company_id,source_batch_id) references public.product_batches(company_id,id),
  foreign key(company_id,returned_batch_id) references public.product_batches(company_id,id)
);

create table public.deliveries (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  sale_id uuid not null, document_number text not null, status text not null default 'prepared'
    check(status in ('prepared','shipped','received','failed','returned')), assigned_to uuid references auth.users(id),
  recipient_name text, evidence_path text, notes text, created_by uuid not null references auth.users(id),
  shipped_at timestamptz, completed_at timestamptz, idempotency_key uuid not null, created_at timestamptz not null default now(), unique(company_id,document_number),
  unique(company_id,created_by,idempotency_key),
  foreign key(company_id,branch_id,sale_id) references public.sales(company_id,branch_id,id), unique(company_id,branch_id,id)
);
create table public.delivery_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, branch_id uuid not null, delivery_id uuid not null,
  sale_item_id uuid not null, quantity numeric(14,3) not null check(quantity>0), unit_code text not null,
  foreign key(company_id,branch_id,delivery_id) references public.deliveries(company_id,branch_id,id)
);

alter table public.purchases add column if not exists due_date date;
create table public.supplier_payments (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  supplier_id uuid not null, document_number text not null, amount numeric(14,2) not null check(amount>0),
  payment_method text not null check(payment_method in ('cash','bank_transfer','other')), reference text,
  paid_at timestamptz not null default now(), paid_by uuid not null references auth.users(id),
  idempotency_key uuid not null, foreign key(company_id,branch_id) references public.branches(company_id,id),
  foreign key(company_id,supplier_id) references public.suppliers(company_id,id), unique(company_id,document_number),
  unique(company_id,paid_by,idempotency_key), unique(company_id,id)
);
create table public.supplier_payment_allocations (
  company_id uuid not null, branch_id uuid not null, payment_id uuid not null, purchase_id uuid not null,
  amount numeric(14,2) not null check(amount>0), primary key(payment_id,purchase_id),
  foreign key(company_id,payment_id) references public.supplier_payments(company_id,id),
  foreign key(company_id,branch_id,purchase_id) references public.purchases(company_id,branch_id,id)
);

create table public.cash_accounts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  code text not null, name text not null, account_type text not null check(account_type in ('cash','bank')),
  opening_balance numeric(14,2) not null default 0, is_active boolean not null default true, created_at timestamptz not null default now(),
  foreign key(company_id,branch_id) references public.branches(company_id,id), unique(company_id,branch_id,code), unique(company_id,branch_id,id)
);
alter table public.cash_accounts add column ledger_account_id uuid;
alter table public.customer_payments add column cash_account_id uuid;
alter table public.supplier_payments add column cash_account_id uuid;
create table public.cash_transactions (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, branch_id uuid not null, cash_account_id uuid not null,
  transaction_type text not null check(transaction_type in ('opening','receipt','payment','transfer_in','transfer_out','expense','customer_payment','supplier_payment')),
  amount numeric(14,2) not null check(amount>0), reference_type text, reference_id uuid, description text not null,
  occurred_at timestamptz not null default now(), created_by uuid not null references auth.users(id),
  idempotency_key uuid not null, transfer_pair_id uuid,
  foreign key(company_id,branch_id,cash_account_id) references public.cash_accounts(company_id,branch_id,id),
  unique(company_id,created_by,idempotency_key)
);
create table public.expenses (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, branch_id uuid not null, cash_account_id uuid not null,
  expense_account_id uuid not null, document_number text not null, amount numeric(14,2) not null check(amount>0),
  payee text, description text not null, spent_at date not null default current_date, status text not null default 'posted' check(status in ('posted','voided')),
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
  foreign key(company_id,branch_id,cash_account_id) references public.cash_accounts(company_id,branch_id,id),
  unique(company_id,document_number), unique(company_id,branch_id,id)
);
create table public.accounts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), code text not null, name text not null,
  account_type text not null check(account_type in ('asset','liability','equity','revenue','expense')),
  is_cash_flow boolean not null default false, is_active boolean not null default true, created_at timestamptz not null default now(),
  unique(company_id,code), unique(company_id,id)
);
create table public.fiscal_periods (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), name text not null,
  starts_on date not null, ends_on date not null, is_closed boolean not null default false, closed_at timestamptz,
  check(ends_on>=starts_on), unique(company_id,name), unique(company_id,id)
);
create table public.company_account_mappings (
  company_id uuid not null references public.companies(id), mapping_key text not null
    check(mapping_key in ('accounts_receivable','accounts_payable','sales_revenue','sales_discount','shipping_revenue','inventory','cost_of_goods_sold','purchase_expense','cash_over_short','opening_balance_equity')),
  account_id uuid not null, updated_by uuid not null references auth.users(id), updated_at timestamptz not null default now(),
  primary key(company_id,mapping_key), foreign key(company_id,account_id) references public.accounts(company_id,id)
);
create table public.journals (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid not null,
  period_id uuid not null, journal_date date not null, document_number text not null, memo text not null, source_type text not null default 'manual', source_id uuid,
  status text not null default 'posted' check(status in ('posted','reversed')), posted_by uuid not null references auth.users(id),
  posted_at timestamptz not null default now(), idempotency_key uuid not null,
  foreign key(company_id,branch_id) references public.branches(company_id,id), foreign key(company_id,period_id) references public.fiscal_periods(company_id,id),
  unique(company_id,document_number), unique(company_id,posted_by,idempotency_key), unique(company_id,id)
);
create table public.journal_lines (
  id uuid primary key default gen_random_uuid(), company_id uuid not null, journal_id uuid not null, account_id uuid not null,
  debit numeric(14,2) not null default 0 check(debit>=0), credit numeric(14,2) not null default 0 check(credit>=0), description text,
  check((debit>0 and credit=0) or (credit>0 and debit=0)),
  foreign key(company_id,journal_id) references public.journals(company_id,id), foreign key(company_id,account_id) references public.accounts(company_id,id)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), branch_id uuid,
  recipient_id uuid references auth.users(id), notification_type text not null, title text not null, message text not null,
  entity_type text, entity_id uuid, created_at timestamptz not null default now(), read_at timestamptz,
  foreign key(company_id,branch_id) references public.branches(company_id,id)
);
create table public.notification_reads (
  notification_id uuid not null references public.notifications(id), user_id uuid not null references auth.users(id),
  read_at timestamptz not null default now(), primary key(notification_id,user_id)
);

alter table public.cash_accounts add constraint cash_accounts_ledger_fk foreign key(company_id,ledger_account_id) references public.accounts(company_id,id);
alter table public.customer_payments add constraint customer_payments_cash_account_fk foreign key(company_id,branch_id,cash_account_id) references public.cash_accounts(company_id,branch_id,id);
alter table public.supplier_payments add constraint supplier_payments_cash_account_fk foreign key(company_id,branch_id,cash_account_id) references public.cash_accounts(company_id,branch_id,id);
alter table public.expenses add column idempotency_key uuid;
alter table public.expenses add column cash_transaction_id uuid;
alter table public.expenses add constraint expenses_account_fk foreign key(company_id,expense_account_id) references public.accounts(company_id,id);
alter table public.expenses add constraint expenses_idempotency_unique unique(company_id,created_by,idempotency_key);
alter table public.journals add constraint journal_date_period_check check(journal_date is not null);

create index cash_transactions_scope_date on public.cash_transactions(company_id,branch_id,cash_account_id,occurred_at desc);
create index journals_scope_date on public.journals(company_id,branch_id,posted_at desc);
create index notifications_inbox on public.notifications(company_id,recipient_id,created_at desc) where read_at is null;

create or replace function public.create_finance_account(p_company_id uuid,p_code text,p_name text,p_type text,p_is_cash_flow boolean default false)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid:=gen_random_uuid();
begin
 if not private.has_company_access(p_company_id) or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak kelola akun keuangan ditolak' using errcode='42501'; end if;
 if p_type not in ('asset','liability','equity','revenue','expense') or nullif(trim(p_code),'') is null or nullif(trim(p_name),'') is null then raise exception 'Kode, nama, dan jenis akun wajib diisi'; end if;
 insert into public.accounts(id,company_id,code,name,account_type,is_cash_flow) values(v_id,p_company_id,trim(p_code),trim(p_name),p_type,p_is_cash_flow);
 return v_id;
end $$;

create or replace function public.create_fiscal_period(p_company_id uuid,p_name text,p_starts date,p_ends date)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid:=gen_random_uuid();
begin
 if not private.has_company_access(p_company_id) or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak kelola periode ditolak' using errcode='42501'; end if;
 if p_ends<p_starts or exists(select 1 from public.fiscal_periods where company_id=p_company_id and daterange(starts_on,ends_on,'[]') && daterange(p_starts,p_ends,'[]')) then raise exception 'Periode tidak valid atau bertumpang tindih'; end if;
 insert into public.fiscal_periods(id,company_id,name,starts_on,ends_on) values(v_id,p_company_id,trim(p_name),p_starts,p_ends); return v_id;
end $$;

create or replace function public.set_account_mapping(p_company_id uuid,p_mapping_key text,p_account_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_type text;
begin
 if not private.has_company_access(p_company_id) or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak pemetaan akun ditolak' using errcode='42501'; end if;
 select account_type into v_type from public.accounts where company_id=p_company_id and id=p_account_id and is_active;
 if not found then raise exception 'Akun tidak aktif atau tidak ditemukan'; end if;
 if (p_mapping_key in ('accounts_receivable','inventory') and v_type<>'asset') or (p_mapping_key='accounts_payable' and v_type<>'liability') or (p_mapping_key='opening_balance_equity' and v_type<>'equity')
   or (p_mapping_key in ('sales_revenue','shipping_revenue') and v_type<>'revenue') or (p_mapping_key in ('sales_discount','purchase_expense','cost_of_goods_sold','cash_over_short') and v_type<>'expense') then raise exception 'Jenis akun tidak sesuai untuk pemetaan ini'; end if;
 insert into public.company_account_mappings(company_id,mapping_key,account_id,updated_by) values(p_company_id,p_mapping_key,p_account_id,auth.uid())
 on conflict(company_id,mapping_key) do update set account_id=excluded.account_id,updated_by=excluded.updated_by,updated_at=now();
end $$;

create or replace function public.create_cash_account(p_company_id uuid,p_branch_id uuid,p_code text,p_name text,p_type text,p_opening numeric,p_ledger_account_id uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid:=gen_random_uuid(); v_equity uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_doc text;
begin
 if not private.has_branch_access(p_company_id,p_branch_id) or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak kelola kas/bank ditolak' using errcode='42501'; end if;
 if p_type not in ('cash','bank') or coalesce(p_opening,0)<0 then raise exception 'Jenis atau saldo awal tidak valid'; end if;
 if p_ledger_account_id is not null and not exists(select 1 from public.accounts where company_id=p_company_id and id=p_ledger_account_id and account_type='asset') then raise exception 'Akun buku besar kas/bank harus bertipe aset'; end if;
 if coalesce(p_opening,0)>0 then
  if p_ledger_account_id is null then raise exception 'Saldo awal memerlukan akun buku besar kas/bank'; end if;
  select m.account_id into v_equity from public.company_account_mappings m join public.accounts a on a.company_id=m.company_id and a.id=m.account_id and a.account_type='equity' where m.company_id=p_company_id and m.mapping_key='opening_balance_equity';
  select id into v_period from public.fiscal_periods where company_id=p_company_id and current_date between starts_on and ends_on and not is_closed;
  if v_equity is null or v_period is null then raise exception 'Konfigurasikan akun ekuitas saldo awal dan periode fiskal terbuka'; end if;
 end if;
 insert into public.cash_accounts(id,company_id,branch_id,code,name,account_type,opening_balance,ledger_account_id) values(v_id,p_company_id,p_branch_id,trim(p_code),trim(p_name),p_type,coalesce(p_opening,0),p_ledger_account_id);
 if coalesce(p_opening,0)>0 then
  v_doc:=private.next_document_number(p_company_id,p_branch_id,'journal');
  insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,posted_by,idempotency_key)
   values(v_journal,p_company_id,p_branch_id,v_period,current_date,v_doc,'Saldo awal akun kas/bank '||trim(p_name),'opening_balance',auth.uid(),gen_random_uuid());
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit) values(p_company_id,v_journal,p_ledger_account_id,p_opening,0),(p_company_id,v_journal,v_equity,0,p_opening);
 end if;
 return v_id;
end $$;

create or replace function public.post_manual_journal(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
 v_period uuid:=(p_payload->>'period_id')::uuid; v_date date:=(p_payload->>'entry_date')::date; v_id uuid:=gen_random_uuid(); v_doc text;
 v_item jsonb; v_debit numeric:=0; v_credit numeric:=0; v_count int:=0; v_old jsonb; v_period_row public.fiscal_periods%rowtype;
begin
 if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak posting jurnal ditolak' using errcode='42501'; end if;
 select * into v_period_row from public.fiscal_periods where company_id=v_company and id=v_period for update;
 if not found or v_period_row.is_closed or v_date not between v_period_row.starts_on and v_period_row.ends_on then raise exception 'Tanggal harus berada dalam periode fiskal yang terbuka'; end if;
 insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'post_manual_journal') on conflict do nothing;
 select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
 if v_old is not null then return v_old; end if;
 if jsonb_array_length(p_payload->'lines')<2 then raise exception 'Jurnal minimal memiliki dua baris'; end if;
 for v_item in select value from jsonb_array_elements(p_payload->'lines') loop
  if not exists(select 1 from public.accounts where company_id=v_company and id=(v_item->>'account_id')::uuid and is_active) then raise exception 'Akun tidak aktif atau tidak tersedia'; end if;
  v_debit:=v_debit+coalesce((v_item->>'debit')::numeric,0); v_credit:=v_credit+coalesce((v_item->>'credit')::numeric,0); v_count:=v_count+1;
 end loop;
 if v_debit<=0 or v_debit<>v_credit then raise exception 'Total debit dan kredit harus sama dan lebih dari nol'; end if;
 v_doc:=private.next_document_number(v_company,v_branch,'journal');
 insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,posted_by,idempotency_key)
  values(v_id,v_company,v_branch,v_period,v_date,v_doc,trim(p_payload->>'memo'),v_user,p_idempotency_key);
 for v_item in select value from jsonb_array_elements(p_payload->'lines') loop
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description)
   values(v_company,v_id,(v_item->>'account_id')::uuid,coalesce((v_item->>'debit')::numeric,0),coalesce((v_item->>'credit')::numeric,0),nullif(v_item->>'description',''));
 end loop;
 v_old:=jsonb_build_object('journal_id',v_id,'document_number',v_doc,'status','posted');
 update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
 return v_old;
end $$;

create or replace function public.close_fiscal_period(p_period_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v public.fiscal_periods%rowtype;
begin
 select * into v from public.fiscal_periods where id=p_period_id for update;
 if not found or not private.has_company_access(v.company_id) or not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Periode tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
 if exists(select 1 from public.journals where period_id=v.id and status<>'posted') then raise exception 'Ada jurnal yang perlu ditinjau sebelum periode ditutup'; end if;
 update public.fiscal_periods set is_closed=true,closed_at=now() where id=v.id;
end $$;

create or replace function public.record_supplier_payment(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
 v_supplier uuid:=(p_payload->>'supplier_id')::uuid; v_cash uuid:=(p_payload->>'cash_account_id')::uuid; v_amount numeric:=(p_payload->>'amount')::numeric;
 v_id uuid:=gen_random_uuid(); v_doc text; v_item jsonb; v_purchase public.purchases%rowtype; v_alloc numeric; v_sum numeric:=0; v_paid numeric; v_received numeric; v_old jsonb;
 v_cash_ledger uuid; v_ap uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_jdoc text;
begin
 if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak pembayaran pemasok ditolak' using errcode='42501'; end if;
 if v_amount<=0 or p_payload->>'payment_method' not in ('cash','bank_transfer','other') or jsonb_array_length(p_payload->'allocations')=0 then raise exception 'Nominal, metode, dan alokasi pembayaran wajib valid'; end if;
 select ca.ledger_account_id into v_cash_ledger from public.cash_accounts ca where ca.company_id=v_company and ca.branch_id=v_branch and ca.id=v_cash and ca.is_active;
 select m.account_id into v_ap from public.company_account_mappings m join public.accounts a on a.company_id=m.company_id and a.id=m.account_id and a.account_type='liability' and a.is_active where m.company_id=v_company and m.mapping_key='accounts_payable';
 if v_cash_ledger is null or v_ap is null then raise exception 'Konfigurasikan akun buku besar kas/bank dan akun utang pemasok sebelum membayar'; end if;
 select id into v_period from public.fiscal_periods where company_id=v_company and current_date between starts_on and ends_on and not is_closed;
 if v_period is null then raise exception 'Buat periode fiskal terbuka sebelum mencatat pembayaran'; end if;
 insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'record_supplier_payment') on conflict do nothing;
 select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
 if v_old is not null then return v_old; end if;
 v_doc:=private.next_document_number(v_company,v_branch,'supplier_payment');
 insert into public.supplier_payments(id,company_id,branch_id,supplier_id,document_number,amount,payment_method,reference,paid_by,idempotency_key,cash_account_id)
  values(v_id,v_company,v_branch,v_supplier,v_doc,v_amount,p_payload->>'payment_method',nullif(p_payload->>'reference',''),v_user,p_idempotency_key,v_cash);
 for v_item in select value from jsonb_array_elements(p_payload->'allocations') loop
  select * into v_purchase from public.purchases where company_id=v_company and branch_id=v_branch and supplier_id=v_supplier and id=(v_item->>'purchase_id')::uuid for update;
  if not found then raise exception 'Tagihan pemasok tidak ditemukan'; end if;
  select coalesce(sum(gri.quantity*gri.unit_cost),0) into v_received from public.goods_receipt_items gri join public.goods_receipts gr on gr.id=gri.receipt_id and gr.status='posted' where gri.company_id=v_company and gri.branch_id=v_branch and gri.purchase_item_id in (select id from public.purchase_items where purchase_id=v_purchase.id);
  select coalesce(sum(spa.amount),0) into v_paid from public.supplier_payment_allocations spa where spa.purchase_id=v_purchase.id;
  v_alloc:=(v_item->>'amount')::numeric;
  if v_alloc<=0 or v_paid+v_alloc>v_received then raise exception 'Alokasi melampaui nilai barang yang sudah diterima'; end if;
  insert into public.supplier_payment_allocations(company_id,branch_id,payment_id,purchase_id,amount) values(v_company,v_branch,v_id,v_purchase.id,v_alloc);
  v_sum:=v_sum+v_alloc;
 end loop;
 if v_sum<>v_amount then raise exception 'Total alokasi harus sama dengan nominal pembayaran'; end if;
 insert into public.cash_transactions(company_id,branch_id,cash_account_id,transaction_type,amount,reference_type,reference_id,description,created_by,idempotency_key)
  values(v_company,v_branch,v_cash,'supplier_payment',v_amount,'supplier_payment',v_id,'Pembayaran pemasok '||v_doc,v_user,p_idempotency_key);
 v_jdoc:=private.next_document_number(v_company,v_branch,'journal');
 insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
  values(v_journal,v_company,v_branch,v_period,current_date,v_jdoc,'Pembayaran utang pemasok '||v_doc,'supplier_payment',v_id,v_user,gen_random_uuid());
 insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values
  (v_company,v_journal,v_ap,v_amount,0,'Pelunasan utang pemasok'),(v_company,v_journal,v_cash_ledger,0,v_amount,'Pengeluaran kas/bank');
 v_old:=jsonb_build_object('supplier_payment_id',v_id,'document_number',v_doc,'amount',v_amount,'status','posted');
 update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
 return v_old;
end $$;

create or replace function public.set_purchase_due_date(p_purchase_id uuid,p_due_date date)
returns void language plpgsql security definer set search_path='' as $$
declare v public.purchases%rowtype;
begin
 select * into v from public.purchases where id=p_purchase_id for update;
 if not found or not private.has_branch_access(v.company_id,v.branch_id) then raise exception 'Pembelian tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
 if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','purchasing','finance']::public.app_role[]) then raise exception 'Hak ubah tanggal jatuh tempo ditolak' using errcode='42501'; end if;
 if v.status='voided' then raise exception 'Tanggal jatuh tempo tidak dapat diubah pada pembelian batal'; end if;
 update public.purchases set due_date=p_due_date where id=v.id;
end $$;

create or replace function public.record_customer_payment_v2(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_result jsonb; v_payment uuid; v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid; v_cash uuid:=(p_payload->>'cash_account_id')::uuid; v_amount numeric:=(p_payload->>'amount')::numeric;
 v_cash_ledger uuid; v_ar uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_jdoc text; v_actual_amount numeric; v_existing_cash uuid;
begin
 select ca.ledger_account_id into v_cash_ledger from public.cash_accounts ca where ca.company_id=v_company and ca.branch_id=v_branch and ca.id=v_cash and ca.is_active;
 select m.account_id into v_ar from public.company_account_mappings m join public.accounts a on a.company_id=m.company_id and a.id=m.account_id and a.account_type='asset' and a.is_active where m.company_id=v_company and m.mapping_key='accounts_receivable';
 if v_cash_ledger is null or v_ar is null then raise exception 'Konfigurasikan akun kas/bank dan piutang sebelum mencatat pembayaran'; end if;
 select id into v_period from public.fiscal_periods where company_id=v_company and current_date between starts_on and ends_on and not is_closed;
 if v_period is null then raise exception 'Buat periode fiskal terbuka sebelum mencatat pembayaran'; end if;
 v_result:=public.record_customer_payment(p_payload,p_idempotency_key); v_payment:=(v_result->>'payment_id')::uuid;
 select amount,cash_account_id into v_actual_amount,v_existing_cash from public.customer_payments where company_id=v_company and id=v_payment for update;
 if v_existing_cash is not null and v_existing_cash<>v_cash then raise exception 'Pembayaran idempoten sudah tercatat pada akun kas/bank lain'; end if;
 update public.customer_payments set cash_account_id=coalesce(cash_account_id,v_cash) where company_id=v_company and id=v_payment;
 insert into public.cash_transactions(company_id,branch_id,cash_account_id,transaction_type,amount,reference_type,reference_id,description,created_by,idempotency_key)
  values(v_company,v_branch,v_cash,'customer_payment',v_actual_amount,'customer_payment',v_payment,'Penerimaan pelanggan '||(v_result->>'document_number'),auth.uid(),p_idempotency_key)
  on conflict(company_id,created_by,idempotency_key) do nothing;
 if not exists(select 1 from public.journals where company_id=v_company and source_type='customer_payment' and source_id=v_payment) then
  v_jdoc:=private.next_document_number(v_company,v_branch,'journal');
  insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
   values(v_journal,v_company,v_branch,v_period,current_date,v_jdoc,'Penerimaan pembayaran pelanggan','customer_payment',v_payment,auth.uid(),gen_random_uuid());
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values
   (v_company,v_journal,v_cash_ledger,v_actual_amount,0,'Penerimaan kas/bank'),(v_company,v_journal,v_ar,0,v_actual_amount,'Pelunasan piutang');
 end if;
 return v_result;
end $$;

create or replace function public.post_cash_movement(p_company_id uuid,p_branch_id uuid,p_cash_account_id uuid,p_type text,p_amount numeric,p_description text,p_idempotency_key uuid,p_destination_account_id uuid default null,p_counter_account_id uuid default null,p_occurred_at date default current_date)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_id uuid:=gen_random_uuid(); v_pair uuid:=gen_random_uuid(); v_cash_ledger uuid; v_counter uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_jdoc text; v_existing public.cash_transactions%rowtype;
begin
 if not private.has_branch_access(p_company_id,p_branch_id) or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak kas/bank ditolak' using errcode='42501'; end if;
 if p_type not in ('receipt','payment','transfer') or p_amount<=0 or nullif(trim(p_description),'') is null then raise exception 'Jenis, nominal, dan keterangan wajib valid'; end if;
 select * into v_existing from public.cash_transactions where company_id=p_company_id and created_by=v_user and idempotency_key=p_idempotency_key;
 if found then return v_existing.id; end if;
 select ledger_account_id into v_cash_ledger from public.cash_accounts where company_id=p_company_id and branch_id=p_branch_id and id=p_cash_account_id and is_active;
 if v_cash_ledger is null then raise exception 'Akun kas/bank harus dipetakan ke akun buku besar'; end if;
 select id into v_period from public.fiscal_periods where company_id=p_company_id and p_occurred_at between starts_on and ends_on and not is_closed;
 if v_period is null then raise exception 'Buat periode fiskal terbuka sebelum mencatat arus kas'; end if;
 if p_type='transfer' then
  select ledger_account_id into v_counter from public.cash_accounts where company_id=p_company_id and branch_id=p_branch_id and id=p_destination_account_id and is_active;
  if p_destination_account_id is null or p_destination_account_id=p_cash_account_id or v_counter is null then raise exception 'Akun tujuan transfer harus valid dan dipetakan'; end if;
  insert into public.cash_transactions(company_id,branch_id,cash_account_id,transaction_type,amount,description,created_by,idempotency_key,transfer_pair_id,occurred_at)
   values(p_company_id,p_branch_id,p_cash_account_id,'transfer_out',p_amount,trim(p_description),v_user,p_idempotency_key,v_pair,p_occurred_at::timestamp at time zone 'Asia/Jakarta') returning id into v_id;
  insert into public.cash_transactions(company_id,branch_id,cash_account_id,transaction_type,amount,description,created_by,idempotency_key,transfer_pair_id,occurred_at)
   values(p_company_id,p_branch_id,p_destination_account_id,'transfer_in',p_amount,trim(p_description),v_user,gen_random_uuid(),v_pair,p_occurred_at::timestamp at time zone 'Asia/Jakarta');
 else
  insert into public.cash_transactions(company_id,branch_id,cash_account_id,transaction_type,amount,description,created_by,idempotency_key,occurred_at)
   values(p_company_id,p_branch_id,p_cash_account_id,p_type,p_amount,trim(p_description),v_user,p_idempotency_key,p_occurred_at::timestamp at time zone 'Asia/Jakarta') returning id into v_id;
  if p_counter_account_id is null or not exists(select 1 from public.accounts where company_id=p_company_id and id=p_counter_account_id and is_active) then raise exception 'Pilih akun lawan untuk jurnal kas/bank'; end if;
  v_counter:=p_counter_account_id;
 end if;
 v_jdoc:=private.next_document_number(p_company_id,p_branch_id,'journal');
 insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
  values(v_journal,p_company_id,p_branch_id,v_period,p_occurred_at,v_jdoc,trim(p_description),'cash_transaction',v_id,v_user,gen_random_uuid());
 if p_type='receipt' or p_type='transfer' then
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit) values(p_company_id,v_journal,v_cash_ledger,p_amount,0),(p_company_id,v_journal,v_counter,0,p_amount);
 else
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit) values(p_company_id,v_journal,v_counter,p_amount,0),(p_company_id,v_journal,v_cash_ledger,0,p_amount);
 end if;
 return v_id;
end $$;

create or replace function public.record_expense(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid; v_cash uuid:=(p_payload->>'cash_account_id')::uuid;
 v_expense_account uuid:=(p_payload->>'expense_account_id')::uuid; v_amount numeric:=(p_payload->>'amount')::numeric; v_date date:=coalesce((p_payload->>'spent_at')::date,current_date);
 v_cash_tx uuid; v_id uuid:=gen_random_uuid(); v_doc text; v_old public.expenses%rowtype;
begin
 if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]) then raise exception 'Hak mencatat biaya ditolak' using errcode='42501'; end if;
 if v_amount<=0 or nullif(trim(p_payload->>'description'),'') is null then raise exception 'Nominal dan keterangan biaya wajib diisi'; end if;
 select * into v_old from public.expenses where company_id=v_company and created_by=auth.uid() and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('expense_id',v_old.id,'document_number',v_old.document_number,'status',v_old.status); end if;
 if not exists(select 1 from public.accounts where company_id=v_company and id=v_expense_account and is_active and account_type='expense') then raise exception 'Pilih akun biaya aktif'; end if;
 v_cash_tx:=public.post_cash_movement(v_company,v_branch,v_cash,'payment',v_amount,trim(p_payload->>'description'),p_idempotency_key,null,v_expense_account,v_date);
 v_doc:=private.next_document_number(v_company,v_branch,'expense');
 insert into public.expenses(id,company_id,branch_id,cash_account_id,expense_account_id,document_number,amount,payee,description,spent_at,created_by,idempotency_key,cash_transaction_id)
  values(v_id,v_company,v_branch,v_cash,v_expense_account,v_doc,v_amount,nullif(p_payload->>'payee',''),trim(p_payload->>'description'),v_date,auth.uid(),p_idempotency_key,v_cash_tx);
 return jsonb_build_object('expense_id',v_id,'document_number',v_doc,'status','posted');
end $$;

create or replace function public.get_payables_report(p_company_id uuid,p_branch_id uuid,p_as_of date)
returns table(purchase_id uuid,document_number text,supplier_name text,received_total numeric,paid_total numeric,balance numeric,due_date date,days_overdue integer)
language sql stable security definer set search_path='' as $$
 select pu.id,pu.document_number,s.name,coalesce(r.received_total,0),coalesce(p.paid_total,0),coalesce(r.received_total,0)-coalesce(p.paid_total,0),pu.due_date,
  case when pu.due_date is not null and pu.due_date<p_as_of then p_as_of-pu.due_date else 0 end
 from public.purchases pu join public.suppliers s on s.company_id=pu.company_id and s.id=pu.supplier_id
 left join lateral(select sum(gri.quantity*gri.unit_cost) received_total from public.purchase_items pi join public.goods_receipt_items gri on gri.company_id=pi.company_id and gri.purchase_item_id=pi.id join public.goods_receipts gr on gr.id=gri.receipt_id and gr.status='posted' where pi.purchase_id=pu.id) r on true
 left join lateral(select sum(spa.amount) paid_total from public.supplier_payment_allocations spa where spa.purchase_id=pu.id) p on true
 where pu.company_id=p_company_id and (p_branch_id is null or pu.branch_id=p_branch_id) and coalesce(r.received_total,0)>coalesce(p.paid_total,0)
 and private.has_branch_access(pu.company_id,pu.branch_id) order by pu.due_date nulls last,pu.created_at
$$;

create or replace function public.get_batch_traceability_extended(p_batch_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_result jsonb; v_extra jsonb;
begin
 v_result:=public.get_batch_traceability(p_batch_id);
 if v_result is null then return null; end if;
 select coalesce(jsonb_agg(e.event order by e.happened_at,e.event_type),'[]'::jsonb) into v_extra from (
  select t.shipped_at happened_at,'transfer_out' event_type,jsonb_build_object('event_type','transfer_out','happened_at',t.shipped_at,
   'description','Batch dikirim ke cabang tujuan','reference',t.document_number,'related_reference',db.name,'party_name',null,
   'quantity',i.shipped_quantity,'unit_code',i.unit_code,'related_batch_id',i.destination_batch_id,'related_batch_number',dest.batch_number,'notes',i.discrepancy_note) event
  from public.stock_transfer_items i join public.stock_transfers t on t.company_id=i.company_id and t.id=i.transfer_id
  join public.branches db on db.company_id=t.company_id and db.id=t.destination_branch_id left join public.product_batches dest on dest.company_id=i.company_id and dest.id=i.destination_batch_id
  where i.source_batch_id=p_batch_id and t.shipped_at is not null and private.has_branch_access(t.company_id,t.source_branch_id)
  union all
  select t.received_at,'transfer_in',jsonb_build_object('event_type','transfer_in','happened_at',t.received_at,
   'description','Batch diterima dari cabang asal','reference',t.document_number,'related_reference',sb.name,'party_name',null,
   'quantity',i.received_quantity,'unit_code',i.unit_code,'related_batch_id',i.source_batch_id,'related_batch_number',src.batch_number,'notes',i.discrepancy_note)
  from public.stock_transfer_items i join public.stock_transfers t on t.company_id=i.company_id and t.id=i.transfer_id
  join public.branches sb on sb.company_id=t.company_id and sb.id=t.source_branch_id left join public.product_batches src on src.company_id=i.company_id and src.id=i.source_batch_id
  where i.destination_batch_id=p_batch_id and t.received_at is not null and private.has_branch_access(t.company_id,t.destination_branch_id)
  union all
  select d.created_at,'delivery',jsonb_build_object('event_type','delivery','happened_at',d.created_at,'description','Pengiriman invoice: '||d.status,
   'reference',d.document_number,'related_reference',s.document_number,'party_name',coalesce(c.name,'Pelanggan umum'),'quantity',di.quantity,
   'unit_code',di.unit_code,'related_batch_id',null,'related_batch_number',null,'notes',d.recipient_name)
  from public.sales_items si join public.delivery_items di on di.sale_item_id=si.id join public.deliveries d on d.company_id=di.company_id and d.id=di.delivery_id
  join public.sales s on s.company_id=d.company_id and s.id=d.sale_id left join public.customers c on c.company_id=s.company_id and c.id=s.customer_id
  where si.batch_id=p_batch_id and private.has_branch_access(d.company_id,d.branch_id)
  union all
  select r.posted_at,'sales_return',jsonb_build_object('event_type','sales_return','happened_at',r.posted_at,'description','Barang retur diterima dan dikarantina',
   'reference',r.document_number,'related_reference',s.document_number,'party_name',coalesce(c.name,'Pelanggan umum'),'quantity',ri.quantity,
   'unit_code',ri.unit_code,'related_batch_id',ri.source_batch_id,'related_batch_number',src.batch_number,'notes',r.reason)
  from public.sales_return_items ri join public.sales_returns r on r.company_id=ri.company_id and r.id=ri.return_id
  join public.sales s on s.company_id=r.company_id and s.id=r.sale_id left join public.customers c on c.company_id=s.company_id and c.id=s.customer_id
  left join public.product_batches src on src.company_id=ri.company_id and src.id=ri.source_batch_id
  where ri.returned_batch_id=p_batch_id and r.status='posted' and private.has_branch_access(r.company_id,r.branch_id)
 ) e;
 return jsonb_set(v_result,'{events}',coalesce(v_result->'events','[]'::jsonb)||v_extra,true);
end $$;

create or replace function public.get_cash_balances(p_company_id uuid,p_branch_id uuid)
returns table(account_id uuid,account_code text,account_name text,account_type text,opening_balance numeric,inflow numeric,outflow numeric,balance numeric)
language sql stable security definer set search_path='' as $$
 select ca.id,ca.code,ca.name,ca.account_type,ca.opening_balance,
  coalesce(sum(case when ct.transaction_type in ('receipt','transfer_in','customer_payment') then ct.amount else 0 end),0),
  coalesce(sum(case when ct.transaction_type in ('payment','transfer_out','expense','supplier_payment') then ct.amount else 0 end),0),
  ca.opening_balance+coalesce(sum(case when ct.transaction_type in ('receipt','transfer_in','customer_payment') then ct.amount when ct.transaction_type in ('payment','transfer_out','expense','supplier_payment') then -ct.amount else 0 end),0)
 from public.cash_accounts ca left join public.cash_transactions ct on ct.company_id=ca.company_id and ct.branch_id=ca.branch_id and ct.cash_account_id=ca.id
 where ca.company_id=p_company_id and (p_branch_id is null or ca.branch_id=p_branch_id) and private.has_branch_access(ca.company_id,ca.branch_id)
 group by ca.id order by ca.name
$$;

create or replace function public.get_trial_balance(p_company_id uuid,p_branch_id uuid,p_from date,p_to date)
returns table(account_id uuid,account_code text,account_name text,account_type text,debit_total numeric,credit_total numeric,net_balance numeric)
language sql stable security definer set search_path='' as $$
 select a.id,a.code,a.name,a.account_type,coalesce(sum(case when j.id is not null then jl.debit else 0 end),0),coalesce(sum(case when j.id is not null then jl.credit else 0 end),0),coalesce(sum(case when j.id is not null then jl.debit-jl.credit else 0 end),0)
 from public.accounts a left join public.journal_lines jl on jl.company_id=a.company_id and jl.account_id=a.id left join public.journals j on j.id=jl.journal_id and j.company_id=a.company_id and j.status='posted' and j.journal_date between p_from and p_to and (p_branch_id is null or j.branch_id=p_branch_id) and private.has_branch_access(j.company_id,j.branch_id)
 where a.company_id=p_company_id and private.has_company_access(a.company_id)
 group by a.id order by a.code
$$;

create or replace function public.get_income_statement(p_company_id uuid,p_branch_id uuid,p_from date,p_to date)
returns table(account_id uuid,account_code text,account_name text,account_type text,amount numeric)
language sql stable security definer set search_path='' as $$
 select a.id,a.code,a.name,a.account_type,case when a.account_type='revenue' then sum(jl.credit-jl.debit) else sum(jl.debit-jl.credit) end
 from public.accounts a join public.journal_lines jl on jl.company_id=a.company_id and jl.account_id=a.id join public.journals j on j.id=jl.journal_id and j.status='posted'
 where a.company_id=p_company_id and a.account_type in ('revenue','expense') and j.journal_date between p_from and p_to and (p_branch_id is null or j.branch_id=p_branch_id) and private.has_branch_access(j.company_id,j.branch_id)
 group by a.id order by a.account_type,a.code
$$;

create or replace function public.get_cash_flow_report(p_company_id uuid,p_branch_id uuid,p_from date,p_to date)
returns table(day date,account_name text,inflow numeric,outflow numeric,net numeric)
language sql stable security definer set search_path='' as $$
 select ct.occurred_at::date,ca.name,sum(case when ct.transaction_type in ('receipt','transfer_in','customer_payment') then ct.amount else 0 end),
  sum(case when ct.transaction_type in ('payment','transfer_out','expense','supplier_payment') then ct.amount else 0 end),
  sum(case when ct.transaction_type in ('receipt','transfer_in','customer_payment') then ct.amount when ct.transaction_type in ('payment','transfer_out','expense','supplier_payment') then -ct.amount else 0 end)
 from public.cash_transactions ct join public.cash_accounts ca on ca.id=ct.cash_account_id
 where ct.company_id=p_company_id and (p_branch_id is null or ct.branch_id=p_branch_id) and ct.occurred_at::date between p_from and p_to and private.has_branch_access(ct.company_id,ct.branch_id)
 group by 1,2 order by 1 desc,2
$$;

create or replace function public.get_notifications(p_company_id uuid,p_branch_id uuid,p_limit int default 50)
returns table(id uuid,company_id uuid,branch_id uuid,recipient_id uuid,notification_type text,title text,message text,entity_type text,entity_id uuid,created_at timestamptz,read_at timestamptz)
language sql stable security definer set search_path='' as $$
 select n.id,n.company_id,n.branch_id,n.recipient_id,n.notification_type,n.title,n.message,n.entity_type,n.entity_id,n.created_at,nr.read_at
 from public.notifications n left join public.notification_reads nr on nr.notification_id=n.id and nr.user_id=auth.uid()
 where n.company_id=p_company_id and (n.branch_id is null or n.branch_id=p_branch_id)
  and (n.recipient_id is null or n.recipient_id=auth.uid()) and private.has_branch_access(n.company_id,coalesce(n.branch_id,p_branch_id))
 order by n.created_at desc limit least(greatest(coalesce(p_limit,50),1),200)
$$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.notifications n where n.id=p_notification_id and (n.recipient_id is null or n.recipient_id=auth.uid()) and (private.has_company_access(n.company_id) or private.has_branch_access(n.company_id,n.branch_id))) then raise exception 'Notifikasi tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
 insert into public.notification_reads(notification_id,user_id,read_at) values(p_notification_id,auth.uid(),now()) on conflict(notification_id,user_id) do update set read_at=excluded.read_at;
end $$;

-- Read policies only. All business writes above remain behind checked RPCs.
do $$ declare t text; begin
 foreach t in array array['stock_transfers','stock_transfer_items','stock_opnames','stock_opname_items','sales_returns','sales_return_items','deliveries','delivery_items','supplier_payments','supplier_payment_allocations','cash_accounts','cash_transactions','expenses','journals','journal_lines','notifications','notification_reads','company_account_mappings','accounts','fiscal_periods'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon,authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
 end loop;
end $$;

create policy stock_transfer_read on public.stock_transfers for select to authenticated using (
 private.has_branch_access(company_id,source_branch_id) or private.has_branch_access(company_id,destination_branch_id)
);
create policy stock_transfer_item_read on public.stock_transfer_items for select to authenticated using (
 exists(select 1 from public.stock_transfers t where t.company_id=stock_transfer_items.company_id and t.id=stock_transfer_items.transfer_id and (private.has_branch_access(t.company_id,t.source_branch_id) or private.has_branch_access(t.company_id,t.destination_branch_id)))
);
create policy master_company_read on public.accounts for select to authenticated using(private.has_company_access(company_id));
create policy fiscal_company_read on public.fiscal_periods for select to authenticated using(private.has_company_access(company_id));
create policy mapping_company_read on public.company_account_mappings for select to authenticated using(private.has_company_access(company_id));
do $$ declare t text; begin
 foreach t in array array['stock_opnames','stock_opname_items','sales_returns','sales_return_items','deliveries','delivery_items','supplier_payments','supplier_payment_allocations','cash_accounts','cash_transactions','expenses','journals','notifications'] loop
  execute format('create policy branch_read on public.%I for select to authenticated using (private.has_branch_access(company_id,branch_id))',t);
 end loop;
end $$;
create policy journal_line_read on public.journal_lines for select to authenticated using(
 exists(select 1 from public.journals j where j.company_id=journal_lines.company_id and j.id=journal_lines.journal_id and private.has_branch_access(j.company_id,j.branch_id))
);
create policy notification_read_own on public.notification_reads for select to authenticated using(user_id=auth.uid());

create trigger stock_transfers_audit after insert or update on public.stock_transfers for each row execute function private.audit_row();
create trigger stock_opnames_audit after insert or update on public.stock_opnames for each row execute function private.audit_row();
create trigger sales_returns_audit after insert or update on public.sales_returns for each row execute function private.audit_row();
create trigger deliveries_audit after insert or update on public.deliveries for each row execute function private.audit_row();
create trigger supplier_payments_audit after insert on public.supplier_payments for each row execute function private.audit_row();
create trigger cash_transactions_audit after insert on public.cash_transactions for each row execute function private.audit_row();
create trigger expenses_audit after insert on public.expenses for each row execute function private.audit_row();
create trigger journals_audit after insert on public.journals for each row execute function private.audit_row();

create or replace function private.notify_scan_review()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.status in ('needs_review','duplicate_candidate') and old.status is distinct from new.status then
  insert into public.notifications(company_id,branch_id,recipient_id,notification_type,title,message,entity_type,entity_id)
   values(new.company_id,new.branch_id,new.created_by,'ocr_review','Dokumen OCR perlu ditinjau','Periksa hasil ekstraksi dan peringatan sebelum mengonfirmasi.','scanned_document',new.id);
 end if;
 return new;
end $$;
create trigger scanned_document_review_notification after update of status on public.scanned_documents for each row execute function private.notify_scan_review();

create or replace function private.notify_low_stock()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_min numeric; v_total numeric;
begin
 select p.minimum_stock into v_min from public.products p where p.company_id=new.company_id and p.id=new.product_id;
 select coalesce(sum(ib.quantity),0) into v_total from public.inventory_balances ib where ib.company_id=new.company_id and ib.branch_id=new.branch_id and ib.product_id=new.product_id;
 if v_min>0 and v_total<v_min and not exists(select 1 from public.notifications n where n.company_id=new.company_id and n.branch_id=new.branch_id and n.entity_type='product' and n.entity_id=new.product_id and n.notification_type='low_stock' and n.read_at is null) then
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
   values(new.company_id,new.branch_id,'low_stock','Stok di bawah batas minimum','Total saldo produk turun di bawah batas minimum yang ditetapkan.','product',new.product_id);
 end if;
 return new;
end $$;
create trigger inventory_low_stock_notification after insert or update of quantity on public.inventory_balances for each row execute function private.notify_low_stock();

create or replace function private.auto_journal_sales_invoice()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_sale public.sales%rowtype; v_ar uuid; v_revenue uuid; v_discount uuid; v_shipping uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_doc text;
begin
 if new.document_type<>'sales_invoice' or new.source_type<>'sale' then return new; end if;
 select * into v_sale from public.sales where company_id=new.company_id and id=new.source_id;
 if not found then return new; end if;
 select account_id into v_ar from public.company_account_mappings where company_id=new.company_id and mapping_key='accounts_receivable';
 select account_id into v_revenue from public.company_account_mappings where company_id=new.company_id and mapping_key='sales_revenue';
 if v_sale.discount_amount>0 then select account_id into v_discount from public.company_account_mappings where company_id=new.company_id and mapping_key='sales_discount'; end if;
 if v_sale.shipping_amount>0 then select account_id into v_shipping from public.company_account_mappings where company_id=new.company_id and mapping_key='shipping_revenue'; end if;
 select id into v_period from public.fiscal_periods where company_id=new.company_id and v_sale.created_at::date between starts_on and ends_on and not is_closed;
 if v_ar is null or v_revenue is null or (v_sale.discount_amount>0 and v_discount is null) or (v_sale.shipping_amount>0 and v_shipping is null) or v_period is null then
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
   values(new.company_id,new.branch_id,'journal_setup_required','Invoice belum masuk jurnal otomatis','Lengkapi pemetaan akun pendapatan/piutang, diskon/pengiriman, dan periode fiskal.','sale',v_sale.id);
  return new;
 end if;
 if exists(select 1 from public.journals where company_id=new.company_id and source_type='sale' and source_id=v_sale.id) then return new; end if;
 v_doc:=private.next_document_number(new.company_id,new.branch_id,'journal');
 insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
  values(v_journal,new.company_id,new.branch_id,v_period,v_sale.created_at::date,v_doc,'Posting invoice '||v_sale.document_number,'sale',v_sale.id,auth.uid(),gen_random_uuid());
 insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values(new.company_id,v_journal,v_ar,v_sale.total_amount,0,'Piutang dari invoice');
 insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values(new.company_id,v_journal,v_revenue,0,v_sale.subtotal,'Pendapatan penjualan');
 if v_sale.discount_amount>0 then insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values(new.company_id,v_journal,v_discount,v_sale.discount_amount,0,'Diskon penjualan'); end if;
 if v_sale.shipping_amount>0 then insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values(new.company_id,v_journal,v_shipping,0,v_sale.shipping_amount,'Pendapatan pengiriman'); end if;
 return new;
end $$;
create trigger sales_invoice_auto_journal after insert on public.documents for each row when(new.document_type='sales_invoice') execute function private.auto_journal_sales_invoice();

create or replace function private.auto_journal_goods_receipt()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_receipt public.goods_receipts%rowtype; v_inventory uuid; v_payable uuid; v_period uuid; v_journal uuid:=gen_random_uuid(); v_doc text; v_value numeric;
begin
 select * into v_receipt from public.goods_receipts where company_id=new.company_id and id=new.receipt_id and status='posted';
 if not found then return new; end if;
 select account_id into v_inventory from public.company_account_mappings where company_id=new.company_id and mapping_key='inventory';
 select account_id into v_payable from public.company_account_mappings where company_id=new.company_id and mapping_key='accounts_payable';
 select id into v_period from public.fiscal_periods where company_id=new.company_id and v_receipt.received_at::date between starts_on and ends_on and not is_closed;
 if v_inventory is null or v_payable is null or v_period is null then
  if not exists(select 1 from public.notifications where company_id=new.company_id and entity_type='goods_receipt' and entity_id=v_receipt.id and notification_type='journal_setup_required') then
   insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
    values(new.company_id,new.branch_id,'journal_setup_required','Penerimaan belum masuk jurnal otomatis','Lengkapi pemetaan akun persediaan/utang dan periode fiskal.','goods_receipt',v_receipt.id);
  end if;
  return new;
 end if;
 if exists(select 1 from public.journals where company_id=new.company_id and source_type='goods_receipt_item' and source_id=new.id) then return new; end if;
 v_value:=round(new.quantity*new.unit_cost,2); if v_value<=0 then return new; end if;
 v_doc:=private.next_document_number(new.company_id,new.branch_id,'journal');
 insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
  values(v_journal,new.company_id,new.branch_id,v_period,v_receipt.received_at::date,v_doc,'Penerimaan barang '||v_receipt.document_number,'goods_receipt_item',new.id,auth.uid(),gen_random_uuid());
 insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values
  (new.company_id,v_journal,v_inventory,v_value,0,'Persediaan diterima'),(new.company_id,v_journal,v_payable,0,v_value,'Utang pemasok');
 return new;
end $$;
create trigger goods_receipt_item_auto_journal after insert on public.goods_receipt_items for each row execute function private.auto_journal_goods_receipt();


create or replace function public.create_stock_transfer(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_from uuid:=(p_payload->>'source_branch_id')::uuid;
  v_to uuid:=(p_payload->>'destination_branch_id')::uuid; v_wh_from uuid:=(p_payload->>'source_warehouse_id')::uuid;
  v_wh_to uuid:=(p_payload->>'destination_warehouse_id')::uuid; v_id uuid:=gen_random_uuid(); v_doc text; v_item jsonb;
  v_product uuid; v_batch uuid; v_qty numeric; v_unit text; v_base numeric; v_old jsonb;
begin
  if v_user is null or not private.has_branch_access(v_company,v_from) or not private.has_branch_access(v_company,v_to) then raise exception 'Branch access denied' using errcode='42501'; end if;
  if not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','warehouse','supervisor']::public.app_role[]) then raise exception 'Transfer permission denied' using errcode='42501'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'create_stock_transfer') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  if v_from=v_to and v_wh_from=v_wh_to then raise exception 'Gudang asal dan tujuan harus berbeda'; end if;
  if jsonb_typeof(p_payload->'items')<>'array' or jsonb_array_length(p_payload->'items')=0 then raise exception 'Minimal satu item transfer harus diisi'; end if;
  if not exists(select 1 from public.warehouses where company_id=v_company and branch_id=v_from and id=v_wh_from and is_active)
    or not exists(select 1 from public.warehouses where company_id=v_company and branch_id=v_to and id=v_wh_to and is_active) then raise exception 'Gudang tidak tersedia'; end if;
  v_doc:=private.next_document_number(v_company,v_from,'transfer');
  insert into public.stock_transfers(id,company_id,source_branch_id,destination_branch_id,source_warehouse_id,destination_warehouse_id,document_number,notes,requested_by,idempotency_key)
    values(v_id,v_company,v_from,v_to,v_wh_from,v_wh_to,v_doc,nullif(p_payload->>'notes',''),v_user,p_idempotency_key);
  for v_item in select value from jsonb_array_elements(p_payload->'items') loop
    v_product:=(v_item->>'product_id')::uuid; v_batch:=(v_item->>'batch_id')::uuid; v_qty:=(v_item->>'quantity')::numeric; v_unit:=v_item->>'unit_code';
    select v_qty*pu.base_units_per_unit into v_base from public.product_units pu where pu.company_id=v_company and pu.product_id=v_product and pu.unit_code=v_unit;
    if v_base is null or v_qty<=0 then raise exception 'Produk, satuan, atau jumlah tidak valid'; end if;
    if not exists(select 1 from public.product_batches b where b.company_id=v_company and b.branch_id=v_from and b.id=v_batch and b.product_id=v_product and b.quality_status='passed') then raise exception 'Batch sumber tidak lolos inspeksi'; end if;
    if not exists(select 1 from public.inventory_balances ib where ib.company_id=v_company and ib.branch_id=v_from and ib.warehouse_id=v_wh_from and ib.product_id=v_product and ib.batch_id=v_batch and ib.quantity>=v_base) then raise exception 'Stok sumber tidak mencukupi'; end if;
    insert into public.stock_transfer_items(company_id,transfer_id,product_id,source_batch_id,requested_quantity,unit_code) values(v_company,v_id,v_product,v_batch,v_qty,v_unit);
  end loop;
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
    values(v_company,v_to,'transfer_pending','Transfer stok menunggu persetujuan',v_doc,'stock_transfer',v_id);
  v_old:=jsonb_build_object('transfer_id',v_id,'document_number',v_doc,'status','requested');
  update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_old;
end $$;

create or replace function public.approve_stock_transfer(p_transfer_id uuid,p_approve boolean,p_reason text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v public.stock_transfers%rowtype;
begin
  select * into v from public.stock_transfers where id=p_transfer_id for update;
  if not found or not private.has_branch_access(v.company_id,v.destination_branch_id) then raise exception 'Transfer tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','supervisor']::public.app_role[]) then raise exception 'Persetujuan transfer memerlukan supervisor/admin' using errcode='42501'; end if;
  if v.status<>'requested' then raise exception 'Status transfer bukan menunggu persetujuan'; end if;
  update public.stock_transfers set status=case when p_approve then 'approved' else 'rejected' end,approved_by=auth.uid(),notes=concat_ws(E'\n',notes,case when p_approve then null else 'Ditolak: '||coalesce(nullif(p_reason,''),'tanpa alasan') end) where id=p_transfer_id;
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id,recipient_id)
    values(v.company_id,v.source_branch_id,'transfer_decision',case when p_approve then 'Transfer disetujui' else 'Transfer ditolak' end,v.document_number,'stock_transfer',v.id,v.requested_by);
end $$;

create or replace function public.dispatch_stock_transfer(p_transfer_id uuid,p_idempotency_key uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v public.stock_transfers%rowtype; r record; v_user uuid:=auth.uid();
begin
  select * into v from public.stock_transfers where id=p_transfer_id for update;
  if not found or not private.has_branch_access(v.company_id,v.source_branch_id) then raise exception 'Transfer tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','warehouse','supervisor']::public.app_role[]) then raise exception 'Hak kirim transfer ditolak' using errcode='42501'; end if;
  if v.status<>'approved' then raise exception 'Transfer harus disetujui sebelum dikirim'; end if;
  for r in select i.*,pu.base_units_per_unit from public.stock_transfer_items i join public.product_units pu on pu.company_id=i.company_id and pu.product_id=i.product_id and pu.unit_code=i.unit_code where i.transfer_id=v.id loop
    update public.inventory_balances set quantity=quantity-(r.requested_quantity*r.base_units_per_unit),updated_at=now()
      where company_id=v.company_id and branch_id=v.source_branch_id and warehouse_id=v.source_warehouse_id and product_id=r.product_id and batch_id=r.source_batch_id and quantity>=r.requested_quantity*r.base_units_per_unit;
    if not found then raise exception 'Stok berubah dan tidak cukup saat pengiriman'; end if;
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v.company_id,v.source_branch_id,v.source_warehouse_id,r.product_id,r.source_batch_id,'transfer_out',-(r.requested_quantity*r.base_units_per_unit),r.unit_code,'stock_transfer',v.id,p_idempotency_key,v_user);
    update public.stock_transfer_items set shipped_quantity=r.requested_quantity where id=r.id;
  end loop;
  update public.stock_transfers set status='shipped',shipped_at=now() where id=v.id;
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
    values(v.company_id,v.destination_branch_id,'transfer_in_transit','Transfer sedang dikirim',v.document_number,'stock_transfer',v.id);
end $$;

create or replace function public.receive_stock_transfer(p_transfer_id uuid,p_items jsonb,p_idempotency_key uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v public.stock_transfers%rowtype; v_item jsonb; r public.stock_transfer_items%rowtype; v_actual numeric; v_base numeric; v_dest_batch uuid; v_user uuid:=auth.uid(); v_number text;
begin
  select * into v from public.stock_transfers where id=p_transfer_id for update;
  if not found or not private.has_branch_access(v.company_id,v.destination_branch_id) then raise exception 'Transfer tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','warehouse','supervisor']::public.app_role[]) then raise exception 'Hak penerimaan transfer ditolak' using errcode='42501'; end if;
  if v.status<>'shipped' then raise exception 'Transfer belum dikirim atau sudah diterima'; end if;
  if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0
    or (select count(distinct (value->>'item_id')::uuid) from jsonb_array_elements(p_items))<>jsonb_array_length(p_items)
    or jsonb_array_length(p_items)<>(select count(*) from public.stock_transfer_items where transfer_id=v.id) then
    raise exception 'Daftar penerimaan harus memuat setiap item transfer tepat satu kali';
  end if;
  for v_item in select value from jsonb_array_elements(p_items) loop
    select * into r from public.stock_transfer_items where id=(v_item->>'item_id')::uuid and transfer_id=v.id for update;
    if not found then raise exception 'Item transfer tidak ditemukan'; end if;
    v_actual:=(v_item->>'received_quantity')::numeric;
    if v_actual<0 or v_actual>r.shipped_quantity then raise exception 'Jumlah aktual tidak valid atau melebihi jumlah dikirim'; end if;
    if v_actual<>r.shipped_quantity and nullif(trim(v_item->>'discrepancy_note'),'') is null then raise exception 'Wajib mencatat alasan selisih transfer'; end if;
    select v_actual*base_units_per_unit into v_base from public.product_units where company_id=v.company_id and product_id=r.product_id and unit_code=r.unit_code;
    v_dest_batch:=gen_random_uuid(); v_number:=private.next_document_number(v.company_id,v.destination_branch_id,'batch');
    insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,quality_status)
      select v_dest_batch,v.company_id,v.destination_branch_id,r.product_id,v_number,'adjustment',v.id,b.quality_status from public.product_batches b where b.id=r.source_batch_id;
    insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity)
      values(v.company_id,v.destination_branch_id,v.destination_warehouse_id,r.product_id,v_dest_batch,v_base)
      on conflict(warehouse_id,product_id,batch_key) do update set quantity=public.inventory_balances.quantity+excluded.quantity,updated_at=now();
    if v_base>0 then insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v.company_id,v.destination_branch_id,v.destination_warehouse_id,r.product_id,v_dest_batch,'transfer_in',v_base,r.unit_code,'stock_transfer',v.id,p_idempotency_key,v_user); end if;
    update public.stock_transfer_items set received_quantity=v_actual,destination_batch_id=v_dest_batch,discrepancy_note=nullif(v_item->>'discrepancy_note','') where id=r.id;
  end loop;
  if exists(select 1 from public.stock_transfer_items where transfer_id=v.id and destination_batch_id is null) then raise exception 'Semua item transfer harus dikonfirmasi'; end if;
  update public.stock_transfers set status=case when exists(select 1 from public.stock_transfer_items where transfer_id=v.id and received_quantity<>shipped_quantity) then 'partially_received' else 'received' end,received_at=now() where id=v.id;
  if exists(select 1 from public.stock_transfer_items where transfer_id=v.id and received_quantity<>shipped_quantity) then
    insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id,recipient_id)
      values(v.company_id,v.source_branch_id,'transfer_discrepancy','Ada selisih penerimaan transfer','Periksa jumlah dan alasan selisih pada dokumen '||v.document_number,'stock_transfer',v.id,v.requested_by);
  end if;
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id,recipient_id)
    values(v.company_id,v.source_branch_id,'transfer_received','Penerimaan transfer dikonfirmasi',v.document_number,'stock_transfer',v.id,v.requested_by);
end $$;

create or replace function public.create_stock_opname(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid; v_wh uuid:=(p_payload->>'warehouse_id')::uuid;
  v_id uuid:=gen_random_uuid(); v_doc text; v_item jsonb; v_product uuid; v_batch uuid; v_count numeric; v_expected numeric; v_unit text; v_old jsonb;
begin
  if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','warehouse','supervisor']::public.app_role[]) then raise exception 'Hak opname ditolak' using errcode='42501'; end if;
  if nullif(trim(p_payload->>'reason'),'') is null or jsonb_typeof(p_payload->'items')<>'array' or jsonb_array_length(p_payload->'items')=0 then raise exception 'Alasan dan item opname wajib diisi'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'create_stock_opname') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'opname');
  insert into public.stock_opnames(id,company_id,branch_id,warehouse_id,document_number,reason,notes,created_by,idempotency_key)
    values(v_id,v_company,v_branch,v_wh,v_doc,trim(p_payload->>'reason'),nullif(p_payload->>'notes',''),v_user,p_idempotency_key);
  for v_item in select value from jsonb_array_elements(p_payload->'items') loop
    v_product:=(v_item->>'product_id')::uuid; v_batch:=nullif(v_item->>'batch_id','')::uuid; v_count:=(v_item->>'counted_quantity')::numeric; v_unit:=v_item->>'unit_code';
    if not exists(select 1 from public.products p where p.id=v_product and p.company_id=v_company and p.is_active)
      or not exists(select 1 from public.warehouses w where w.id=v_wh and w.company_id=v_company and w.branch_id=v_branch and w.is_active) then
      raise exception 'Produk atau gudang opname tidak valid';
    end if;
    if v_batch is not null and not exists(select 1 from public.product_batches b where b.id=v_batch and b.company_id=v_company and b.branch_id=v_branch and b.product_id=v_product) then
      raise exception 'Batch opname tidak sesuai dengan produk atau cabang';
    end if;
    if v_batch is null and exists(select 1 from public.inventory_balances ib where ib.company_id=v_company and ib.branch_id=v_branch and ib.warehouse_id=v_wh and ib.product_id=v_product and ib.batch_id is not null and ib.quantity<>0) then
      raise exception 'Lakukan hitung opname per batch untuk produk yang memiliki saldo berbatches';
    end if;
    select coalesce(sum(ib.quantity),0) into v_expected from public.inventory_balances ib where ib.company_id=v_company and ib.branch_id=v_branch and ib.warehouse_id=v_wh and ib.product_id=v_product and ib.batch_id is not distinct from v_batch;
    if v_count<0 or not exists(select 1 from public.product_units where company_id=v_company and product_id=v_product and unit_code=v_unit) then raise exception 'Jumlah atau satuan opname tidak valid'; end if;
    select v_count*base_units_per_unit into v_count from public.product_units where company_id=v_company and product_id=v_product and unit_code=v_unit;
    insert into public.stock_opname_items(company_id,branch_id,opname_id,product_id,batch_id,expected_quantity,counted_quantity,unit_code)
      values(v_company,v_branch,v_id,v_product,v_batch,v_expected,v_count,v_unit);
  end loop;
  v_old:=jsonb_build_object('opname_id',v_id,'document_number',v_doc,'status','draft');
  update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_old;
end $$;

create or replace function public.post_stock_opname(p_opname_id uuid,p_submit boolean default false)
returns void language plpgsql security definer set search_path='' as $$
declare v public.stock_opnames%rowtype; r record; v_user uuid:=auth.uid(); v_delta numeric; v_batch uuid; v_number text;
begin
  select * into v from public.stock_opnames where id=p_opname_id for update;
  if not found or not private.has_branch_access(v.company_id,v.branch_id) then raise exception 'Opname tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if p_submit then
    if v.created_by<>v_user and not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','warehouse']::public.app_role[]) then raise exception 'Hak pengajuan opname ditolak' using errcode='42501'; end if;
    if v.status<>'draft' then raise exception 'Opname tidak dalam status draft'; end if;
    update public.stock_opnames set status='submitted',submitted_at=now() where id=v.id;
    insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
      values(v.company_id,v.branch_id,'opname_pending','Opname menunggu persetujuan',v.document_number,'stock_opname',v.id);
    return;
  end if;
  if v.status<>'submitted' or not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','supervisor']::public.app_role[]) then raise exception 'Opname perlu diajukan dan diposting oleh supervisor/admin' using errcode='42501'; end if;
  for r in select * from public.stock_opname_items where opname_id=v.id loop
    v_delta:=r.counted_quantity-r.expected_quantity;
    if v_delta=0 then continue; end if;
    v_batch:=r.batch_id;
    if v_delta>0 and v_batch is null then
      v_batch:=gen_random_uuid(); v_number:=private.next_document_number(v.company_id,v.branch_id,'batch');
      insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,quality_status)
        values(v_batch,v.company_id,v.branch_id,r.product_id,v_number,'adjustment',v.id,'quarantined');
    end if;
    if v_delta<0 then
      update public.inventory_balances set quantity=quantity+v_delta,updated_at=now() where company_id=v.company_id and branch_id=v.branch_id and warehouse_id=v.warehouse_id and product_id=r.product_id and batch_id is not distinct from v_batch and quantity>=-v_delta;
      if not found then raise exception 'Saldo stok berubah; hitung ulang opname'; end if;
    else
      insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity) values(v.company_id,v.branch_id,v.warehouse_id,r.product_id,v_batch,v_delta)
        on conflict(warehouse_id,product_id,batch_key) do update set quantity=public.inventory_balances.quantity+excluded.quantity,updated_at=now();
    end if;
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v.company_id,v.branch_id,v.warehouse_id,r.product_id,v_batch,'adjustment',v_delta,r.unit_code,'stock_opname',v.id,v.idempotency_key,v_user);
  end loop;
  update public.stock_opnames set status='posted',posted_by=v_user,posted_at=now() where id=v.id;
end $$;

create or replace function public.create_sales_return(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_sale uuid:=(p_payload->>'sale_id')::uuid; v_wh uuid:=(p_payload->>'warehouse_id')::uuid; v_id uuid:=gen_random_uuid(); v_doc text; v_item jsonb; r record; v_qty numeric; v_unit text; v_sold numeric; v_old jsonb;
begin
  if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','cashier','finance','supervisor']::public.app_role[]) then raise exception 'Hak retur ditolak' using errcode='42501'; end if;
  if not exists(select 1 from public.sales where company_id=v_company and branch_id=v_branch and id=v_sale and status='posted') then raise exception 'Invoice tidak ditemukan'; end if;
  if jsonb_array_length(p_payload->'items')=0 or nullif(trim(p_payload->>'reason'),'') is null then raise exception 'Alasan dan item retur wajib diisi'; end if;
  insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'create_sales_return') on conflict do nothing;
  select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
  if v_old is not null then return v_old; end if;
  v_doc:=private.next_document_number(v_company,v_branch,'return');
  insert into public.sales_returns(id,company_id,branch_id,sale_id,warehouse_id,document_number,reason,notes,created_by,idempotency_key)
    values(v_id,v_company,v_branch,v_sale,v_wh,v_doc,trim(p_payload->>'reason'),nullif(p_payload->>'notes',''),v_user,p_idempotency_key);
  for v_item in select value from jsonb_array_elements(p_payload->'items') loop
    select si.*,pu.base_units_per_unit into r from public.sales_items si join public.product_units pu on pu.company_id=si.company_id and pu.product_id=si.product_id and pu.unit_code=si.unit_code
      where si.id=(v_item->>'sale_item_id')::uuid and si.sale_id=v_sale for update of si;
    if not found then raise exception 'Baris invoice tidak ditemukan'; end if;
    v_qty:=(v_item->>'quantity')::numeric; v_unit:=v_item->>'unit_code';
    if v_unit<>r.unit_code or v_qty<=0 then raise exception 'Jumlah/satuan retur harus mengikuti invoice'; end if;
    select coalesce(sum(sr.quantity),0) into v_sold from public.sales_return_items sr join public.sales_returns sret on sret.id=sr.return_id where sr.sale_item_id=r.id and sret.status='posted';
    if (v_sold+v_qty)*r.base_units_per_unit>r.base_quantity then raise exception 'Jumlah retur melebihi jumlah yang terjual'; end if;
    insert into public.sales_return_items(company_id,branch_id,return_id,sale_item_id,product_id,source_batch_id,quantity,unit_code,disposition)
      values(v_company,v_branch,v_id,r.id,r.product_id,r.batch_id,v_qty,v_unit,coalesce(nullif(v_item->>'disposition',''),'quarantine'));
  end loop;
  v_old:=jsonb_build_object('return_id',v_id,'document_number',v_doc,'status','draft');
  update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
  return v_old;
end $$;

create or replace function public.post_sales_return(p_return_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v public.sales_returns%rowtype; r record; v_batch uuid; v_num text; v_base numeric; v_prior numeric; v_user uuid:=auth.uid();
begin
  select * into v from public.sales_returns where id=p_return_id for update;
  if not found or not private.has_branch_access(v.company_id,v.branch_id) then raise exception 'Retur tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','supervisor','finance']::public.app_role[]) then raise exception 'Posting retur memerlukan persetujuan supervisor/finance' using errcode='42501'; end if;
  if v.status<>'draft' then raise exception 'Retur tidak dalam status draft'; end if;
  for r in select sri.*,si.base_quantity,pu.base_units_per_unit from public.sales_return_items sri join public.sales_items si on si.id=sri.sale_item_id
    join public.product_units pu on pu.company_id=sri.company_id and pu.product_id=sri.product_id and pu.unit_code=sri.unit_code where sri.return_id=v.id loop
    perform 1 from public.sales_items where id=r.sale_item_id for update;
    select coalesce(sum(other.quantity*other_unit.base_units_per_unit),0) into v_prior
      from public.sales_return_items other join public.sales_returns other_return on other_return.id=other.return_id and other_return.status='posted'
      join public.product_units other_unit on other_unit.company_id=other.company_id and other_unit.product_id=other.product_id and other_unit.unit_code=other.unit_code
      where other.sale_item_id=r.sale_item_id and other.return_id<>v.id;
    if v_prior+(r.quantity*r.base_units_per_unit)>r.base_quantity then raise exception 'Jumlah retur terposting sudah melampaui kuantitas invoice'; end if;
    v_batch:=null;
    if r.disposition<>'dispose' then
      v_batch:=gen_random_uuid(); v_num:=private.next_document_number(v.company_id,v.branch_id,'batch'); v_base:=r.quantity*r.base_units_per_unit;
      insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,quality_status)
        values(v_batch,v.company_id,v.branch_id,r.product_id,v_num,'adjustment',v.id,'quarantined');
      insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity) values(v.company_id,v.branch_id,v.warehouse_id,r.product_id,v_batch,v_base);
      insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
        values(v.company_id,v.branch_id,v.warehouse_id,r.product_id,v_batch,'adjustment',v_base,r.unit_code,'sales_return',v.id,v.idempotency_key,v_user);
    end if;
    update public.sales_return_items set returned_batch_id=v_batch where id=r.id;
  end loop;
  update public.sales_returns set status='posted',posted_by=v_user,posted_at=now() where id=v.id;
  insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
    values(v.company_id,v.branch_id,'return_posted','Retur diposting dan menunggu peninjauan kualitas',v.document_number,'sales_return',v.id);
end $$;

create or replace function public.create_delivery(p_payload jsonb,p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid; v_sale uuid:=(p_payload->>'sale_id')::uuid;
 v_id uuid:=gen_random_uuid(); v_doc text; v_item jsonb; r record; v_qty numeric; v_prior numeric; v_old jsonb;
begin
 if not private.has_branch_access(v_company,v_branch) or not private.has_any_role(v_company,array['owner','super_admin','central_admin','branch_admin','cashier','delivery','supervisor']::public.app_role[]) then raise exception 'Hak pengiriman ditolak' using errcode='42501'; end if;
 if not exists(select 1 from public.sales where company_id=v_company and branch_id=v_branch and id=v_sale and status='posted') then raise exception 'Invoice tidak ditemukan atau belum diposting'; end if;
 if jsonb_array_length(p_payload->'items')=0 then raise exception 'Minimal satu item pengiriman wajib diisi'; end if;
 insert into public.idempotency_keys(company_id,user_id,idempotency_key,operation) values(v_company,v_user,p_idempotency_key,'create_delivery') on conflict do nothing;
 select response into v_old from public.idempotency_keys where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key for update;
 if v_old is not null then return v_old; end if;
 v_doc:=private.next_document_number(v_company,v_branch,'delivery');
 insert into public.deliveries(id,company_id,branch_id,sale_id,document_number,assigned_to,notes,created_by,idempotency_key)
  values(v_id,v_company,v_branch,v_sale,v_doc,nullif(p_payload->>'assigned_to','')::uuid,nullif(p_payload->>'notes',''),v_user,p_idempotency_key);
 for v_item in select value from jsonb_array_elements(p_payload->'items') loop
   select * into r from public.sales_items where company_id=v_company and branch_id=v_branch and sale_id=v_sale and id=(v_item->>'sale_item_id')::uuid for update;
   if not found then raise exception 'Item penjualan tidak ditemukan'; end if;
   v_qty:=(v_item->>'quantity')::numeric; if v_qty<=0 then raise exception 'Kuantitas pengiriman harus positif'; end if;
   select coalesce(sum(di.quantity),0) into v_prior from public.delivery_items di join public.deliveries d on d.id=di.delivery_id where di.sale_item_id=r.id and d.status not in ('failed','returned');
   if v_prior+v_qty>r.quantity then raise exception 'Jumlah pengiriman melebihi item invoice'; end if;
   insert into public.delivery_items(company_id,branch_id,delivery_id,sale_item_id,quantity,unit_code) values(v_company,v_branch,v_id,r.id,v_qty,r.unit_code);
 end loop;
 v_old:=jsonb_build_object('delivery_id',v_id,'document_number',v_doc,'status','prepared');
 update public.idempotency_keys set response=v_old where company_id=v_company and user_id=v_user and idempotency_key=p_idempotency_key;
 return v_old;
end $$;

create or replace function public.update_delivery_status(p_delivery_id uuid,p_status text,p_recipient text default null,p_evidence_path text default null,p_notes text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v public.deliveries%rowtype;
begin
 select * into v from public.deliveries where id=p_delivery_id for update;
 if not found or not private.has_branch_access(v.company_id,v.branch_id) then raise exception 'Pengiriman tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
 if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','cashier','delivery','supervisor']::public.app_role[]) then raise exception 'Hak perubahan status pengiriman ditolak' using errcode='42501'; end if;
 if not ((v.status='prepared' and p_status in ('shipped','failed')) or (v.status='shipped' and p_status in ('received','failed','returned'))) then raise exception 'Perubahan status pengiriman tidak valid'; end if;
 if p_status='received' and nullif(trim(p_recipient),'') is null then raise exception 'Nama penerima wajib dicatat'; end if;
 update public.deliveries set status=p_status,recipient_name=coalesce(nullif(p_recipient,''),recipient_name),evidence_path=coalesce(nullif(p_evidence_path,''),evidence_path),notes=concat_ws(E'\n',notes,nullif(p_notes,'')),
  shipped_at=case when p_status='shipped' then now() else shipped_at end,completed_at=case when p_status in ('received','failed','returned') then now() else completed_at end where id=v.id;
 insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
  values(v.company_id,v.branch_id,'delivery_status','Status pengiriman diperbarui',v.document_number||' · '||p_status,'delivery',v.id);
end $$;

-- Restrict all operational RPCs after their definitions exist.
revoke execute on function public.create_stock_transfer(jsonb,uuid) from public,anon;
revoke execute on function public.approve_stock_transfer(uuid,boolean,text) from public,anon;
revoke execute on function public.dispatch_stock_transfer(uuid,uuid) from public,anon;
revoke execute on function public.receive_stock_transfer(uuid,jsonb,uuid) from public,anon;
revoke execute on function public.create_stock_opname(jsonb,uuid) from public,anon;
revoke execute on function public.post_stock_opname(uuid,boolean) from public,anon;
revoke execute on function public.create_sales_return(jsonb,uuid) from public,anon;
revoke execute on function public.post_sales_return(uuid) from public,anon;
revoke execute on function public.create_delivery(jsonb,uuid) from public,anon;
revoke execute on function public.update_delivery_status(uuid,text,text,text,text) from public,anon;
revoke execute on function public.create_finance_account(uuid,text,text,text,boolean) from public,anon;
revoke execute on function public.create_fiscal_period(uuid,text,date,date) from public,anon;
revoke execute on function public.set_account_mapping(uuid,text,uuid) from public,anon;
revoke execute on function public.create_cash_account(uuid,uuid,text,text,text,numeric,uuid) from public,anon;
revoke execute on function public.post_manual_journal(jsonb,uuid) from public,anon;
revoke execute on function public.close_fiscal_period(uuid) from public,anon;
revoke execute on function public.record_supplier_payment(jsonb,uuid) from public,anon;
revoke execute on function public.set_purchase_due_date(uuid,date) from public,anon;
revoke execute on function public.record_customer_payment_v2(jsonb,uuid) from public,anon;
revoke execute on function public.post_cash_movement(uuid,uuid,uuid,text,numeric,text,uuid,uuid,uuid,date) from public,anon;
revoke execute on function public.record_expense(jsonb,uuid) from public,anon;
revoke execute on function public.get_payables_report(uuid,uuid,date) from public,anon;
revoke execute on function public.get_batch_traceability_extended(uuid) from public,anon;
revoke execute on function public.get_cash_balances(uuid,uuid) from public,anon;
revoke execute on function public.get_trial_balance(uuid,uuid,date,date) from public,anon;
revoke execute on function public.get_income_statement(uuid,uuid,date,date) from public,anon;
revoke execute on function public.get_cash_flow_report(uuid,uuid,date,date) from public,anon;
revoke execute on function public.get_notifications(uuid,uuid,integer) from public,anon;
revoke execute on function public.mark_notification_read(uuid) from public,anon;

grant execute on function public.create_stock_transfer(jsonb,uuid) to authenticated;
grant execute on function public.approve_stock_transfer(uuid,boolean,text) to authenticated;
grant execute on function public.dispatch_stock_transfer(uuid,uuid) to authenticated;
grant execute on function public.receive_stock_transfer(uuid,jsonb,uuid) to authenticated;
grant execute on function public.create_stock_opname(jsonb,uuid) to authenticated;
grant execute on function public.post_stock_opname(uuid,boolean) to authenticated;
grant execute on function public.create_sales_return(jsonb,uuid) to authenticated;
grant execute on function public.post_sales_return(uuid) to authenticated;
grant execute on function public.create_delivery(jsonb,uuid) to authenticated;
grant execute on function public.update_delivery_status(uuid,text,text,text,text) to authenticated;
grant execute on function public.create_finance_account(uuid,text,text,text,boolean) to authenticated;
grant execute on function public.create_fiscal_period(uuid,text,date,date) to authenticated;
grant execute on function public.set_account_mapping(uuid,text,uuid) to authenticated;
grant execute on function public.create_cash_account(uuid,uuid,text,text,text,numeric,uuid) to authenticated;
grant execute on function public.post_manual_journal(jsonb,uuid) to authenticated;
grant execute on function public.close_fiscal_period(uuid) to authenticated;
grant execute on function public.record_supplier_payment(jsonb,uuid) to authenticated;
grant execute on function public.set_purchase_due_date(uuid,date) to authenticated;
grant execute on function public.record_customer_payment_v2(jsonb,uuid) to authenticated;
grant execute on function public.post_cash_movement(uuid,uuid,uuid,text,numeric,text,uuid,uuid,uuid,date) to authenticated;
grant execute on function public.record_expense(jsonb,uuid) to authenticated;
grant execute on function public.get_payables_report(uuid,uuid,date) to authenticated;
grant execute on function public.get_batch_traceability_extended(uuid) to authenticated;
grant execute on function public.get_cash_balances(uuid,uuid) to authenticated;
grant execute on function public.get_trial_balance(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_income_statement(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_cash_flow_report(uuid,uuid,date,date) to authenticated;
grant execute on function public.get_notifications(uuid,uuid,integer) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
revoke execute on function public.record_customer_payment(jsonb,uuid) from authenticated;

