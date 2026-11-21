-- One transactionally applied, clearly labelled presentation scenario for Pusat.
-- All business records are created in the existing company and central branch only.
do $demo$
declare
  v_company uuid := '92d6eb21-83e1-42e3-a69f-166d17218555';
  v_branch uuid := '0fd2719d-c242-4740-9cbd-c4d99ecffa25';
  v_user uuid;
  v_warehouse uuid;
  v_supplier uuid;
  v_customer uuid;
  v_raw uuid;
  v_fillet uuid;
  v_minced uuid;
  v_cash_ledger uuid;
  v_ar uuid;
  v_ap uuid;
  v_revenue uuid;
  v_inventory uuid;
  v_cogs uuid;
  v_equity uuid;
  v_cash uuid;
  v_period uuid;
  v_purchase jsonb;
  v_purchase_id uuid;
  v_purchase_item uuid;
  v_receipt jsonb;
  v_raw_batch uuid;
  v_production jsonb;
  v_production_id uuid;
  v_fillet_batch uuid;
  v_minced_batch uuid;
  v_sale jsonb;
  v_sale_id uuid;
  v_sale_item_fillet uuid;
  v_sale_item_minced uuid;
  v_delivery jsonb;
begin
  if exists (
    select 1 from public.purchases
    where company_id=v_company and branch_id=v_branch and notes='DEMO|AGI-DEMO-2026-PUSAT'
  ) then
    raise notice 'Demo Pusat sudah tersedia; tidak ada data yang diubah.';
    return;
  end if;

  if (select count(*) from public.branches where company_id=v_company) <> 1
     or not exists(select 1 from public.branches where company_id=v_company and id=v_branch and code='PUSAT') then
    raise exception 'Pemeriksaan cabang gagal; seed dihentikan agar tidak mengisi cabang lain.';
  end if;

  select user_id into v_user from public.user_roles
  where company_id=v_company and role='owner'::public.app_role order by created_at limit 1;
  select id into v_warehouse from public.warehouses
  where company_id=v_company and branch_id=v_branch and is_active order by created_at limit 1;
  if v_user is null or v_warehouse is null then
    raise exception 'Akun Owner atau gudang aktif Pusat tidak ditemukan.';
  end if;

  perform set_config('request.jwt.claim.sub',v_user::text,true);

  insert into public.suppliers(company_id,code,name,phone,address)
  values(v_company,'DEMO-PASOK-01','DEMO - Pemasok Ayam Segar','0812-0000-0001','Data contoh · Pusat')
  on conflict(company_id,code) do nothing;
  select id into v_supplier from public.suppliers where company_id=v_company and code='DEMO-PASOK-01';
  insert into public.customers(company_id,code,name,phone,address,credit_limit)
  values(v_company,'DEMO-PELANGGAN-01','DEMO - Toko Ayam Sejahtera','0812-0000-0002','Data contoh · Pusat',1000000)
  on conflict(company_id,code) do nothing;
  select id into v_customer from public.customers where company_id=v_company and code='DEMO-PELANGGAN-01';

  select id into v_raw from public.products where company_id=v_company and sku='DEMO-AYAM-RAW-01';
  if v_raw is null then v_raw:=public.create_product_master(jsonb_build_object('company_id',v_company,'sku','DEMO-AYAM-RAW-01','name','DEMO - Ayam Utuh Segar','species','chicken','category','Bahan baku','base_unit','kg','minimum_stock',2)); end if;
  select id into v_fillet from public.products where company_id=v_company and sku='DEMO-AYAM-FILLET-01';
  if v_fillet is null then v_fillet:=public.create_product_master(jsonb_build_object('company_id',v_company,'sku','DEMO-AYAM-FILLET-01','name','DEMO - Fillet Ayam','species','chicken','category','Hasil produksi','base_unit','kg','minimum_stock',1)); end if;
  select id into v_minced from public.products where company_id=v_company and sku='DEMO-AYAM-CINCANG-01';
  if v_minced is null then v_minced:=public.create_product_master(jsonb_build_object('company_id',v_company,'sku','DEMO-AYAM-CINCANG-01','name','DEMO - Ayam Cincang','species','chicken','category','Hasil produksi','base_unit','kg','minimum_stock',1)); end if;

  insert into public.product_units(company_id,product_id,unit_code,base_units_per_unit,is_sellable)
  values(v_company,v_fillet,'kg',1,true),(v_company,v_minced,'kg',1,true)
  on conflict(product_id,unit_code) do update set is_sellable=true;

  select id into v_cash_ledger from public.accounts where company_id=v_company and code='DEMO-1100';
  if v_cash_ledger is null then v_cash_ledger:=public.create_finance_account(v_company,'DEMO-1100','DEMO - Kas Pusat','asset',true); end if;
  select id into v_ar from public.accounts where company_id=v_company and code='DEMO-1200';
  if v_ar is null then v_ar:=public.create_finance_account(v_company,'DEMO-1200','DEMO - Piutang Usaha','asset',false); end if;
  select id into v_inventory from public.accounts where company_id=v_company and code='DEMO-1300';
  if v_inventory is null then v_inventory:=public.create_finance_account(v_company,'DEMO-1300','DEMO - Persediaan','asset',false); end if;
  select id into v_ap from public.accounts where company_id=v_company and code='DEMO-2100';
  if v_ap is null then v_ap:=public.create_finance_account(v_company,'DEMO-2100','DEMO - Utang Pemasok','liability',false); end if;
  select id into v_equity from public.accounts where company_id=v_company and code='DEMO-3100';
  if v_equity is null then v_equity:=public.create_finance_account(v_company,'DEMO-3100','DEMO - Ekuitas Saldo Awal','equity',false); end if;
  select id into v_revenue from public.accounts where company_id=v_company and code='DEMO-4100';
  if v_revenue is null then v_revenue:=public.create_finance_account(v_company,'DEMO-4100','DEMO - Penjualan','revenue',true); end if;
  select id into v_cogs from public.accounts where company_id=v_company and code='DEMO-5100';
  if v_cogs is null then v_cogs:=public.create_finance_account(v_company,'DEMO-5100','DEMO - Harga Pokok Penjualan','expense',true); end if;

  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='accounts_receivable') then perform public.set_account_mapping(v_company,'accounts_receivable',v_ar); end if;
  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='accounts_payable') then perform public.set_account_mapping(v_company,'accounts_payable',v_ap); end if;
  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='sales_revenue') then perform public.set_account_mapping(v_company,'sales_revenue',v_revenue); end if;
  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='inventory') then perform public.set_account_mapping(v_company,'inventory',v_inventory); end if;
  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='cost_of_goods_sold') then perform public.set_account_mapping(v_company,'cost_of_goods_sold',v_cogs); end if;
  if not exists(select 1 from public.company_account_mappings where company_id=v_company and mapping_key='opening_balance_equity') then perform public.set_account_mapping(v_company,'opening_balance_equity',v_equity); end if;

  select id into v_period from public.fiscal_periods where company_id=v_company and name='DEMO - November 2026';
  if v_period is null then
    v_period:=public.create_fiscal_period(v_company,'DEMO - November 2026',date '2026-11-01',date '2026-11-30');
  elsif v_period is not null and (select is_closed from public.fiscal_periods where id=v_period) then
    raise exception 'Periode DEMO November 2026 sudah ditutup; seed dihentikan.';
  end if;

  select id into v_cash from public.cash_accounts where company_id=v_company and branch_id=v_branch and code='DEMO-KAS-PUSAT';
  if v_cash is null then
    v_cash:=public.create_cash_account(v_company,v_branch,'DEMO-KAS-PUSAT','DEMO - Kas Pusat','cash',5000000,v_cash_ledger);
  end if;

  v_purchase:=public.create_purchase_draft(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'supplier_id',v_supplier,
      'notes','DEMO|AGI-DEMO-2026-PUSAT','items',jsonb_build_array(
        jsonb_build_object('product_id',v_raw,'quantity',10,'unit_code','kg','unit_price',30000)
      )),
    '8b08cc2b-75b8-4ef4-a542-202611150001'::uuid
  );
  v_purchase_id:=(v_purchase->>'purchase_id')::uuid;
  select id into v_purchase_item from public.purchase_items where company_id=v_company and purchase_id=v_purchase_id and product_id=v_raw;
  perform public.approve_purchase(v_purchase_id);
  perform public.set_purchase_due_date(v_purchase_id,current_date+14);
  v_receipt:=public.post_goods_receipt(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'warehouse_id',v_warehouse,'purchase_id',v_purchase_id,
      'items',jsonb_build_array(jsonb_build_object('purchase_item_id',v_purchase_item,'product_id',v_raw,'quantity',10,'unit_code','kg','unit_cost',30000,'batch_number','DEMO-PUSAT-BAHAN-001'))),
    'b8b08cc2-75b8-4ef4-a542-202611150002'::uuid
  );
  select batch_id into v_raw_batch from public.goods_receipt_items where company_id=v_company and receipt_id=(v_receipt->>'receipt_id')::uuid;
  perform public.inspect_product_batch(v_raw_batch,'passed','DEMO · pemeriksaan kualitas contoh lulus');

  v_production:=public.post_production_batch(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'warehouse_id',v_warehouse,
      'notes','DEMO|HPP rata-rata tertimbang; biaya dibagi berdasarkan berat hasil.',
      'inputs',jsonb_build_array(jsonb_build_object('product_id',v_raw,'batch_id',v_raw_batch,'quantity',5,'unit_code','kg')),
      'outputs',jsonb_build_array(
        jsonb_build_object('product_id',v_fillet,'quantity',3.5,'unit_code','kg','batch_number','DEMO-PUSAT-FILLET-001'),
        jsonb_build_object('product_id',v_minced,'quantity',1.5,'unit_code','kg','batch_number','DEMO-PUSAT-CINCANG-001')
      ),'waste','[]'::jsonb),
    'c8b08cc2-75b8-4ef4-a542-202611150003'::uuid
  );
  v_production_id:=(v_production->>'production_batch_id')::uuid;
  select batch_id into v_fillet_batch from public.production_outputs where company_id=v_company and production_batch_id=v_production_id and product_id=v_fillet;
  select batch_id into v_minced_batch from public.production_outputs where company_id=v_company and production_batch_id=v_production_id and product_id=v_minced;
  perform public.inspect_product_batch(v_fillet_batch,'passed','DEMO · hasil produksi contoh lulus');
  perform public.inspect_product_batch(v_minced_batch,'passed','DEMO · hasil produksi contoh lulus');

  v_sale:=public.post_sale(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'warehouse_id',v_warehouse,'customer_id',v_customer,
      'discount_amount',0,'shipping_amount',0,'notes','DEMO|AGI-DEMO-2026-PUSAT',
      'items',jsonb_build_array(
        jsonb_build_object('product_id',v_fillet,'batch_id',v_fillet_batch,'quantity',2,'unit_code','kg','unit_price',70000,'discount_amount',0),
        jsonb_build_object('product_id',v_minced,'batch_id',v_minced_batch,'quantity',0.5,'unit_code','kg','unit_price',30000,'discount_amount',0)
      )),
    'd8b08cc2-75b8-4ef4-a542-202611150004'::uuid
  );
  v_sale_id:=(v_sale->>'sale_id')::uuid;
  select id into v_sale_item_fillet from public.sales_items where company_id=v_company and sale_id=v_sale_id and product_id=v_fillet;
  select id into v_sale_item_minced from public.sales_items where company_id=v_company and sale_id=v_sale_id and product_id=v_minced;

  perform public.record_supplier_payment(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'supplier_id',v_supplier,'cash_account_id',v_cash,
      'amount',150000,'payment_method','cash','reference','DEMO · pembayaran sebagian','allocations',jsonb_build_array(
        jsonb_build_object('purchase_id',v_purchase_id,'amount',150000)
      )),
    'e8b08cc2-75b8-4ef4-a542-202611150005'::uuid
  );
  perform public.record_customer_payment_v2(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'customer_id',v_customer,'cash_account_id',v_cash,
      'amount',100000,'payment_method','cash','reference','DEMO · pembayaran sebagian','allocations',jsonb_build_array(
        jsonb_build_object('sale_id',v_sale_id,'amount',100000)
      )),
    'f8b08cc2-75b8-4ef4-a542-202611150006'::uuid
  );

  v_delivery:=public.create_delivery(
    jsonb_build_object('company_id',v_company,'branch_id',v_branch,'sale_id',v_sale_id,'notes','DEMO · pengiriman contoh',
      'items',jsonb_build_array(
        jsonb_build_object('sale_item_id',v_sale_item_fillet,'quantity',2),
        jsonb_build_object('sale_item_id',v_sale_item_minced,'quantity',0.5)
      )),
    '08b08cc2-75b8-4ef4-a542-202611150007'::uuid
  );
  perform public.update_delivery_status((v_delivery->>'delivery_id')::uuid,'shipped',null,null,'DEMO · pesanan berangkat dari Pusat');
  perform public.update_delivery_status((v_delivery->>'delivery_id')::uuid,'received','Penerima Contoh',null,'DEMO · pesanan diterima');

  raise notice 'Data DEMO Pusat berhasil dibuat. Pembelian %, produksi %, invoice %.',v_purchase->>'document_number',v_production->>'batch_number',v_sale->>'document_number';
end
$demo$;
