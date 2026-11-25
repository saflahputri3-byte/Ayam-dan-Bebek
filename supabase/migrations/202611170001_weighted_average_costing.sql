-- Company-wide moving weighted-average inventory valuation.
-- Production joint cost is allocated by output base weight as approved by the business.
alter table public.inventory_movements
  add column if not exists unit_cost numeric(14,4) not null default 0,
  add column if not exists value_delta numeric(16,2) not null default 0;

alter table public.sales_items
  add column if not exists unit_cost numeric(14,4) not null default 0,
  add column if not exists cogs_amount numeric(16,2) not null default 0;

create table if not exists public.inventory_cost_balances (
  company_id uuid not null references public.companies(id),
  product_id uuid not null references public.products(id),
  quantity numeric(16,3) not null default 0,
  inventory_value numeric(18,2) not null default 0,
  average_unit_cost numeric(14,4) not null default 0,
  updated_at timestamptz not null default now(),
  primary key(company_id, product_id),
  check(quantity >= 0),
  check(inventory_value >= 0)
);

alter table public.inventory_cost_balances enable row level security;
drop policy if exists inventory_cost_balances_read on public.inventory_cost_balances;
create policy inventory_cost_balances_read on public.inventory_cost_balances
  for select to authenticated using (private.has_any_role(company_id, array['owner','super_admin','central_admin','branch_admin','finance']::public.app_role[]));
revoke all on public.inventory_cost_balances from anon, authenticated;
grant select on public.inventory_cost_balances to authenticated;

-- Existing stock is carried forward at the weighted average of recorded receipts.
-- Any opening stock without a recorded receipt remains at zero until valued by the business.
insert into public.inventory_cost_balances(company_id,product_id,quantity,inventory_value,average_unit_cost)
select ib.company_id,ib.product_id,sum(ib.quantity),round(sum(ib.quantity)*coalesce(rc.average_cost,0),2),coalesce(rc.average_cost,0)
from public.inventory_balances ib
left join lateral (
  select round(sum(gri.base_quantity*gri.unit_cost/pu.base_units_per_unit)/nullif(sum(gri.base_quantity),0),4) as average_cost
  from public.goods_receipt_items gri join public.product_units pu on pu.company_id=gri.company_id and pu.product_id=gri.product_id and pu.unit_code=gri.unit_code
  where gri.company_id=ib.company_id and gri.product_id=ib.product_id
) rc on true
group by ib.company_id,ib.product_id,rc.average_cost
on conflict(company_id,product_id) do nothing;

create or replace function private.value_inventory_movement()
returns trigger language plpgsql security definer set search_path='' as $$
declare
  v_qty numeric(16,3);
  v_value numeric(18,2);
  v_avg numeric(14,4);
  v_incoming_cost numeric(14,4);
  v_receipt_cost numeric(14,2);
  v_allocated_value numeric(18,2);
  v_output_total_weight numeric(16,3);
  v_output_weight numeric(16,3);
  v_original_cost numeric(14,4);
  v_inventory_account uuid;
  v_cogs_account uuid;
  v_period uuid;
  v_journal uuid;
  v_document text;
begin
  perform pg_advisory_xact_lock(hashtextextended(new.company_id::text||':'||new.product_id::text,0));
  insert into public.inventory_cost_balances(company_id,product_id) values(new.company_id,new.product_id)
    on conflict(company_id,product_id) do nothing;
  select quantity,inventory_value,average_unit_cost into v_qty,v_value,v_avg
    from public.inventory_cost_balances where company_id=new.company_id and product_id=new.product_id for update;

  if new.quantity_delta > 0 then
    if new.movement_type='receipt' and new.source_type='goods_receipt' then
      select gri.unit_cost/pu.base_units_per_unit into v_receipt_cost from public.goods_receipt_items gri
       join public.product_units pu on pu.company_id=gri.company_id and pu.product_id=gri.product_id and pu.unit_code=gri.unit_code
       where gri.company_id=new.company_id and gri.receipt_id=new.source_id and gri.product_id=new.product_id and gri.batch_id=new.batch_id
       limit 1;
      v_incoming_cost:=coalesce(v_receipt_cost,0);
    elsif new.movement_type='production_output' and new.source_type='production_output' then
      select coalesce(sum(abs(m.quantity_delta)*m.unit_cost),0) into v_allocated_value
        from public.production_inputs i join public.inventory_movements m
          on m.company_id=i.company_id and m.source_type='production_input' and m.source_id=i.id
       where i.company_id=new.company_id and i.production_batch_id=(select production_batch_id from public.production_outputs where id=new.source_id);
      select sum(case when p.base_unit='kg' then o.base_quantity else o.base_quantity/nullif(kg.base_units_per_unit,0) end)
        into v_output_total_weight
        from public.production_outputs o join public.products p on p.company_id=o.company_id and p.id=o.product_id
        left join public.product_units kg on kg.company_id=o.company_id and kg.product_id=o.product_id and kg.unit_code='kg'
       where o.company_id=new.company_id and o.production_batch_id=(select production_batch_id from public.production_outputs where id=new.source_id);
      select case when p.base_unit='kg' then o.base_quantity else o.base_quantity/nullif(kg.base_units_per_unit,0) end
        into v_output_weight from public.production_outputs o join public.products p on p.company_id=o.company_id and p.id=o.product_id
        left join public.product_units kg on kg.company_id=o.company_id and kg.product_id=o.product_id and kg.unit_code='kg'
       where o.id=new.source_id;
      -- All output rows are created before output movements by post_production_batch.
      if coalesce(v_output_total_weight,0)<=0 or v_output_weight is null then raise exception 'Konversi berat kg setiap output produksi wajib diatur untuk alokasi HPP'; end if;
      v_incoming_cost:=round((v_allocated_value*v_output_weight/v_output_total_weight)/(select base_quantity from public.production_outputs where id=new.source_id),4);
    elsif new.movement_type='transfer_in' and new.source_type='stock_transfer' then
      select coalesce(m.unit_cost,0) into v_incoming_cost
        from public.stock_transfer_items i join public.inventory_movements m
          on m.company_id=i.company_id and m.source_type='stock_transfer' and m.source_id=new.source_id
         and m.movement_type='transfer_out' and m.product_id=i.product_id and m.batch_id=i.source_batch_id
       where i.company_id=new.company_id and i.transfer_id=new.source_id and i.product_id=new.product_id
       order by m.created_at desc limit 1;
      v_incoming_cost:=coalesce(v_incoming_cost,v_avg);
    elsif new.movement_type='adjustment' and new.source_type='sales_return' then
      select si.unit_cost into v_original_cost from public.sales_return_items ri
        join public.sales_items si on si.id=ri.sale_item_id
       where ri.company_id=new.company_id and ri.return_id=new.source_id and ri.source_batch_id=new.batch_id limit 1;
      v_incoming_cost:=coalesce(v_original_cost,v_avg);
    else
      v_incoming_cost:=coalesce(v_avg,0);
    end if;
    new.unit_cost:=coalesce(v_incoming_cost,0);
    new.value_delta:=round(new.quantity_delta*new.unit_cost,2);
    v_qty:=v_qty+new.quantity_delta;
    v_value:=v_value+new.value_delta;
  else
    if v_qty+new.quantity_delta < 0 then raise exception 'Saldo nilai persediaan tidak mencukupi' using errcode='23514'; end if;
    new.unit_cost:=coalesce(v_avg,0);
    new.value_delta:=round(new.quantity_delta*new.unit_cost,2);
    v_qty:=v_qty+new.quantity_delta;
    v_value:=greatest(0,v_value+new.value_delta);
  end if;

  if v_qty=0 then v_value:=0; end if;
  v_avg:=case when v_qty>0 then round(v_value/v_qty,4) else 0 end;
  update public.inventory_cost_balances set quantity=v_qty,inventory_value=v_value,average_unit_cost=v_avg,updated_at=now()
   where company_id=new.company_id and product_id=new.product_id;

  if new.movement_type='sale' and new.source_type='sale' then
    update public.sales_items set unit_cost=new.unit_cost,cogs_amount=abs(new.value_delta)
     where company_id=new.company_id and sale_id=new.source_id and product_id=new.product_id and batch_id is not distinct from new.batch_id
       and cogs_amount=0;
  end if;
  return new;
end $$;

drop trigger if exists inventory_movement_weighted_cost on public.inventory_movements;
create trigger inventory_movement_weighted_cost before insert on public.inventory_movements
  for each row execute function private.value_inventory_movement();

create or replace function private.auto_journal_sale_cogs()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_inventory uuid; v_cogs uuid; v_period uuid; v_sale public.sales%rowtype; v_journal uuid:=gen_random_uuid(); v_doc text;
begin
  if new.movement_type<>'sale' or new.value_delta>=0 then return new; end if;
  select * into v_sale from public.sales where id=new.source_id and company_id=new.company_id;
  select account_id into v_inventory from public.company_account_mappings where company_id=new.company_id and mapping_key='inventory';
  select account_id into v_cogs from public.company_account_mappings where company_id=new.company_id and mapping_key='cost_of_goods_sold';
  select id into v_period from public.fiscal_periods where company_id=new.company_id and v_sale.created_at::date between starts_on and ends_on and not is_closed;
  if v_inventory is null or v_cogs is null or v_period is null then
    if not exists(select 1 from public.notifications where company_id=new.company_id and entity_type='sale' and entity_id=new.source_id and notification_type='cogs_journal_setup_required') then
      insert into public.notifications(company_id,branch_id,notification_type,title,message,entity_type,entity_id)
       values(new.company_id,new.branch_id,'cogs_journal_setup_required','Jurnal HPP belum terbentuk','Lengkapi pemetaan akun persediaan/HPP dan periode fiskal.','sale',new.source_id);
    end if;
    return new;
  end if;
  v_doc:=private.next_document_number(new.company_id,new.branch_id,'journal');
  insert into public.journals(id,company_id,branch_id,period_id,journal_date,document_number,memo,source_type,source_id,posted_by,idempotency_key)
   values(v_journal,new.company_id,new.branch_id,v_period,v_sale.created_at::date,v_doc,'HPP penjualan '||v_sale.document_number,'sale_cogs',new.id,auth.uid(),new.id);
  insert into public.journal_lines(company_id,journal_id,account_id,debit,credit,description) values
   (new.company_id,v_journal,v_cogs,abs(new.value_delta),0,'Harga pokok penjualan'),
   (new.company_id,v_journal,v_inventory,0,abs(new.value_delta),'Pengurangan nilai persediaan');
  return new;
end $$;

drop trigger if exists inventory_movement_sale_cogs_journal on public.inventory_movements;
create trigger inventory_movement_sale_cogs_journal after insert on public.inventory_movements
  for each row when(new.movement_type='sale') execute function private.auto_journal_sale_cogs();

-- Create every output row first so the joint input cost can be divided by total output weight.
create or replace function public.post_production_batch(p_payload jsonb, p_idempotency_key uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid:=auth.uid(); v_company uuid:=(p_payload->>'company_id')::uuid; v_branch uuid:=(p_payload->>'branch_id')::uuid;
  v_warehouse uuid:=(p_payload->>'warehouse_id')::uuid; v_prod uuid:=gen_random_uuid(); v_doc text; v_line jsonb;
  v_product public.products%rowtype; v_unit public.product_units%rowtype; v_batch public.product_batches%rowtype;
  v_qty numeric(14,3); v_base numeric(14,3); v_balance numeric(14,3); v_output_batch uuid; v_output_id uuid;
  v_input_id uuid; v_number text; v_old jsonb; v_result jsonb; v_out record;
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
    select * into v_unit from public.product_units u where u.company_id=v_company and u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
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
    select * into v_unit from public.product_units u where u.company_id=v_company and u.product_id=v_product.id and u.unit_code=(v_line->>'unit_code');
    if not found then raise exception 'Output unit is not configured'; end if;
    v_qty:=(v_line->>'quantity')::numeric; if v_qty is null or v_qty<=0 then raise exception 'Output quantity must be greater than zero'; end if;
    if v_product.base_unit<>'kg' and not exists(select 1 from public.product_units kg where kg.company_id=v_company and kg.product_id=v_product.id and kg.unit_code='kg' and kg.base_units_per_unit>0) then
      raise exception 'Atur konversi kg produk % sebelum memakai alokasi HPP berdasarkan berat',v_product.name;
    end if;
    v_base:=round(v_qty*v_unit.base_units_per_unit,3); v_output_batch:=gen_random_uuid();
    v_number:=coalesce(nullif(v_line->>'batch_number',''),v_doc||'-'||v_product.sku||'-'||left(v_output_batch::text,4));
    insert into public.product_batches(id,company_id,branch_id,product_id,batch_number,source_type,source_id,produced_at,quality_status)
      values(v_output_batch,v_company,v_branch,v_product.id,v_number,'production',v_prod,now(),'pending');
    insert into public.production_outputs(company_id,branch_id,production_batch_id,product_id,batch_id,quantity,unit_code,base_quantity)
      values(v_company,v_branch,v_prod,v_product.id,v_output_batch,v_qty,v_unit.unit_code,v_base) returning id into v_output_id;
    insert into public.inventory_balances(company_id,branch_id,warehouse_id,product_id,batch_id,quantity)
      values(v_company,v_branch,v_warehouse,v_product.id,v_output_batch,v_base);
  end loop;
  for v_out in select id,product_id,batch_id,base_quantity from public.production_outputs where company_id=v_company and production_batch_id=v_prod loop
    select * into v_product from public.products where company_id=v_company and id=v_out.product_id;
    insert into public.inventory_movements(company_id,branch_id,warehouse_id,product_id,batch_id,movement_type,quantity_delta,unit_code,source_type,source_id,idempotency_key,created_by)
      values(v_company,v_branch,v_warehouse,v_out.product_id,v_out.batch_id,'production_output',v_out.base_quantity,v_product.base_unit,'production_output',v_out.id,gen_random_uuid(),v_user);
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

comment on table public.inventory_cost_balances is 'Moving weighted-average inventory valuation, consolidated per company and product.';
comment on column public.inventory_movements.value_delta is 'Signed inventory valuation impact for weighted-average costing.';
