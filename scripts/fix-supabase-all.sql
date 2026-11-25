-- ============================================================================
-- SCRIPT MASTER PERBAIKAN TOTAL SUPABASE ERP AGI AYAM & BEBEK
-- Jalankan script ini langsung di:
-- https://supabase.com/dashboard/project/yzkcodffkayuqhqqflif/sql/new
-- ============================================================================

-- 1. PERBAIKI FUNGSI AUDIT_ROW (Akar masalah error 23502 not-null audit_logs)
-- Pada tabel 'companies', ID perusahaan adalah kolom 'id', bukan 'company_id'.
create or replace function private.audit_row()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_row jsonb := to_jsonb(coalesce(new, old));
  v_company uuid;
  v_branch uuid;
  v_id uuid;
begin
  if tg_table_name = 'companies' then
    v_company := nullif(v_row->>'id', '')::uuid;
  else
    v_company := coalesce(nullif(v_row->>'company_id', '')::uuid, nullif(v_row->>'id', '')::uuid);
  end if;

  v_branch := nullif(v_row->>'branch_id', '')::uuid;
  v_id := nullif(v_row->>'id', '')::uuid;

  insert into public.audit_logs(company_id, branch_id, actor_id, action, entity_type, entity_id, before_data, after_data)
  values (
    v_company,
    v_branch,
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    v_id,
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

-- 2. PASTIKAN KOLOM IDENTITAS PERUSAHAAN TERSEDIA DI TABEL COMPANIES
alter table public.companies add column if not exists address text;
alter table public.companies add column if not exists phone text;
alter table public.companies add column if not exists email text;
alter table public.companies add column if not exists logo_path text;

-- 3. UPDATE LANGSUNG IDENTITAS RESMI PERUSAHAAN DI DATABASE
do $$
declare
  v_company uuid;
  v_branch uuid;
  v_warehouse uuid;
  r_user record;
begin
  -- Ambil atau buat perusahaan utama
  select id into v_company from public.companies order by created_at asc limit 1;
  if v_company is null then
    insert into public.companies (name, legal_name, currency_code, timezone, address, phone, email)
    values (
      'AGI Ayam & Bebek',
      'CV. AGI Ayam dan Bebek',
      'IDR',
      'Asia/Jakarta',
      'Dusun Tenggulunan RT05 RW03 Desa Tunggul Wulung Kec. Pandaan Kab. Pasuruan Jawa Timur, kode Pos: 67156',
      '0813-3312-3012',
      'kontak@agi.id'
    ) returning id into v_company;
  else
    update public.companies
    set
      name = 'AGI Ayam & Bebek',
      legal_name = 'CV. AGI Ayam dan Bebek',
      currency_code = 'IDR',
      timezone = 'Asia/Jakarta',
      address = 'Dusun Tenggulunan RT05 RW03 Desa Tunggul Wulung Kec. Pandaan Kab. Pasuruan Jawa Timur, kode Pos: 67156',
      phone = '0813-3312-3012',
      email = 'kontak@agi.id'
    where id = v_company;
  end if;

  -- 4. PASTIKAN CABANG PUSAT TERSEDIA
  select id into v_branch from public.branches where company_id = v_company and code = 'PUSAT' limit 1;
  if v_branch is null then
    select id into v_branch from public.branches where company_id = v_company limit 1;
  end if;
  if v_branch is null then
    insert into public.branches (company_id, code, name, address, phone)
    values (
      v_company,
      'PUSAT',
      'Cabang Pusat (Pandaan)',
      'Dusun Tenggulunan RT05 RW03 Desa Tunggul Wulung Kec. Pandaan Kab. Pasuruan',
      '0813-3312-3012'
    ) returning id into v_branch;
  end if;

  -- 5. PASTIKAN GUDANG UTAMA TERSEDIA
  select id into v_warehouse from public.warehouses where company_id = v_company and branch_id = v_branch limit 1;
  if v_warehouse is null then
    insert into public.warehouses (company_id, branch_id, code, name)
    values (v_company, v_branch, 'UTAMA', 'Gudang Utama Fresh & Frozen')
    returning id into v_warehouse;
  end if;

  -- 6. BERIKAN HAK AKSES OWNER & SUPER ADMIN KE SEMUA PENGGUNA TERDAFTAR
  for r_user in (select id from auth.users) loop
    -- Profil Pengguna
    insert into public.profiles (user_id, display_name)
    values (r_user.id, 'Direktur / Owner')
    on conflict (user_id) do update set display_name = 'Direktur / Owner';

    -- Hak Akses Peran Lengkap
    insert into public.user_roles (company_id, user_id, role)
    values 
      (v_company, r_user.id, 'owner'),
      (v_company, r_user.id, 'super_admin'),
      (v_company, r_user.id, 'central_admin'),
      (v_company, r_user.id, 'branch_admin'),
      (v_company, r_user.id, 'cashier'),
      (v_company, r_user.id, 'purchasing'),
      (v_company, r_user.id, 'finance')
    on conflict do nothing;

    -- Hak Akses Cabang
    insert into public.user_branch_access (company_id, branch_id, user_id)
    values (v_company, v_branch, r_user.id)
    on conflict do nothing;
  end loop;

  raise notice 'Database Supabase berhasil disinkronkan untuk Perusahaan % dan Cabang %', v_company, v_branch;
end $$;

-- 7. PERBARUI FUNGSI UPDATE PROFIL PERUSAHAAN
create or replace function public.update_company_profile(
  p_company_id uuid,
  p_name text,
  p_legal_name text,
  p_currency_code text,
  p_timezone text,
  p_address text,
  p_phone text,
  p_email text,
  p_logo_path text
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id, array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak ubah profil perusahaan ditolak' using errcode='42501';
  end if;

  if nullif(trim(p_name),'') is null or length(trim(p_name)) > 160 then
    raise exception 'Nama usaha wajib diisi (maks 160 karakter)';
  end if;

  update public.companies set
    name = trim(p_name),
    legal_name = nullif(trim(p_legal_name),''),
    currency_code = coalesce(nullif(trim(p_currency_code),''), 'IDR'),
    timezone = coalesce(nullif(trim(p_timezone),''), 'Asia/Jakarta'),
    address = nullif(trim(p_address),''),
    phone = nullif(trim(p_phone),''),
    email = nullif(trim(p_email),''),
    logo_path = nullif(trim(p_logo_path),''),
    updated_at = now()
  where id = p_company_id;

  if not found then
    raise exception 'Perusahaan tidak ditemukan';
  end if;
end $$;

revoke execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) to authenticated;

-- 8. PASTIKAN RLS COMPANIES
grant select, update on public.companies to authenticated;
drop policy if exists company_member_read on public.companies;
create policy company_member_read on public.companies for select to authenticated using (private.has_company_access(id));
drop policy if exists company_owner_update on public.companies;
create policy company_owner_update on public.companies for update to authenticated
  using (private.has_any_role(id, array['owner','super_admin','central_admin']::public.app_role[]))
  with check (private.has_any_role(id, array['owner','super_admin','central_admin']::public.app_role[]));

-- 9. PERBAIKI RPC DIREKTORI AKSES PENGGUNA (cast auth.users.email -> text agar cocok return table)
create or replace function public.get_user_access_directory(p_company_id uuid)
returns table(user_id uuid,email text,display_name text,roles text[],branch_ids uuid[])
language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak lihat pengguna perusahaan ditolak' using errcode='42501';
  end if;
  return query
    select u.id,u.email::text,p.display_name,
      coalesce(array_agg(distinct ur.role::text) filter(where ur.role is not null),array[]::text[]),
      coalesce(array_agg(distinct ba.branch_id) filter(where ba.branch_id is not null),array[]::uuid[])
    from auth.users u
    left join public.profiles p on p.user_id=u.id
    left join public.user_roles ur on ur.company_id=p_company_id and ur.user_id=u.id
    left join public.user_branch_access ba on ba.company_id=p_company_id and ba.user_id=u.id
    group by u.id,u.email,p.display_name order by u.email;
end $$;

revoke execute on function public.get_user_access_directory(uuid) from public,anon;
grant execute on function public.get_user_access_directory(uuid) to authenticated;

-- 10. PERBAIKI RPC POSTING PRODUKSI (hindari tabrakan variabel loop record vs jsonb v_line)
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

revoke execute on function public.post_production_batch(jsonb,uuid) from public,anon;
grant execute on function public.post_production_batch(jsonb,uuid) to authenticated;
