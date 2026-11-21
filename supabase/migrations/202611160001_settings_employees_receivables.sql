-- Remaining workspace administration and customer receivables.
-- Costing policy is intentionally excluded until the business decision is approved.

alter table public.sales add column if not exists due_date date;
alter table public.companies add column if not exists address text;
alter table public.companies add column if not exists phone text;
alter table public.companies add column if not exists email text;
alter table public.companies add column if not exists logo_path text;

create table public.employees (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  branch_id uuid not null,
  employee_code text not null,
  full_name text not null,
  position_title text,
  phone text,
  email text,
  is_active boolean not null default true,
  notes text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (company_id, branch_id) references public.branches(company_id, id),
  unique (company_id, employee_code),
  unique (company_id, id)
);
alter table public.employees enable row level security;
create policy employees_branch_read on public.employees for select to authenticated
  using (private.has_branch_access(company_id, branch_id));
create trigger employees_audit after insert or update on public.employees
  for each row execute function private.audit_row();
create trigger companies_audit after update on public.companies
  for each row execute function private.audit_row();
create trigger branches_audit after insert or update on public.branches
  for each row execute function private.audit_row();
create trigger warehouses_audit after insert or update on public.warehouses
  for each row execute function private.audit_row();
create trigger user_roles_access_audit after insert or update or delete on public.user_roles
  for each row execute function private.audit_row();
create trigger user_branch_access_audit after insert or update or delete on public.user_branch_access
  for each row execute function private.audit_row();

create or replace function public.update_company_profile(
  p_company_id uuid, p_name text, p_legal_name text, p_currency_code text,
  p_timezone text, p_address text, p_phone text, p_email text, p_logo_path text
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id, array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak ubah profil perusahaan ditolak' using errcode='42501';
  end if;
  if nullif(trim(p_name),'') is null or length(trim(p_name))>160
    or p_currency_code !~ '^[A-Z]{3}$'
    or not exists(select 1 from pg_catalog.pg_timezone_names where name=p_timezone) then
    raise exception 'Nama, kode mata uang, atau zona waktu tidak valid';
  end if;
  update public.companies set name=trim(p_name),legal_name=nullif(trim(p_legal_name),''),
    currency_code=p_currency_code,timezone=p_timezone,address=nullif(trim(p_address),''),
    phone=nullif(trim(p_phone),''),email=nullif(trim(p_email),''),logo_path=nullif(trim(p_logo_path),'')
    where id=p_company_id;
  if not found then raise exception 'Perusahaan tidak ditemukan'; end if;
end $$;

create or replace function public.create_branch(p_company_id uuid,p_code text,p_name text,p_address text default null,p_phone text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid:=gen_random_uuid();
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak tambah cabang ditolak' using errcode='42501';
  end if;
  if nullif(trim(p_code),'') is null or nullif(trim(p_name),'') is null then raise exception 'Kode dan nama cabang wajib diisi'; end if;
  insert into public.branches(id,company_id,code,name,address,phone)
    values(v_id,p_company_id,upper(trim(p_code)),trim(p_name),nullif(trim(p_address),''),nullif(trim(p_phone),''));
  return v_id;
end $$;

create or replace function public.update_branch_profile(p_company_id uuid,p_branch_id uuid,p_code text,p_name text,p_address text,p_phone text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_branch_access(p_company_id,p_branch_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak ubah cabang ditolak' using errcode='42501';
  end if;
  if nullif(trim(p_code),'') is null or nullif(trim(p_name),'') is null then raise exception 'Kode dan nama cabang wajib diisi'; end if;
  update public.branches set code=upper(trim(p_code)),name=trim(p_name),address=nullif(trim(p_address),''),phone=nullif(trim(p_phone),'')
    where company_id=p_company_id and id=p_branch_id;
  if not found then raise exception 'Cabang tidak ditemukan'; end if;
end $$;

create or replace function public.create_warehouse(p_company_id uuid,p_branch_id uuid,p_code text,p_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid:=gen_random_uuid();
begin
  if not private.has_branch_access(p_company_id,p_branch_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin']::public.app_role[]) then
    raise exception 'Hak tambah gudang ditolak' using errcode='42501';
  end if;
  if nullif(trim(p_code),'') is null or nullif(trim(p_name),'') is null then raise exception 'Kode dan nama gudang wajib diisi'; end if;
  insert into public.warehouses(id,company_id,branch_id,code,name)
    values(v_id,p_company_id,p_branch_id,upper(trim(p_code)),trim(p_name));
  return v_id;
end $$;

create or replace function public.upsert_employee(p_company_id uuid,p_employee_id uuid,p_branch_id uuid,p_code text,p_name text,p_position text,p_phone text,p_email text,p_notes text,p_is_active boolean default true)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid:=coalesce(p_employee_id,gen_random_uuid());
begin
  if not private.has_branch_access(p_company_id,p_branch_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin']::public.app_role[]) then
    raise exception 'Hak pengelolaan karyawan ditolak' using errcode='42501';
  end if;
  if nullif(trim(p_code),'') is null or nullif(trim(p_name),'') is null then raise exception 'Kode dan nama karyawan wajib diisi'; end if;
  if p_employee_id is null then
    insert into public.employees(id,company_id,branch_id,employee_code,full_name,position_title,phone,email,notes,created_by,is_active)
      values(v_id,p_company_id,p_branch_id,upper(trim(p_code)),trim(p_name),nullif(trim(p_position),''),nullif(trim(p_phone),''),nullif(trim(p_email),''),nullif(trim(p_notes),''),auth.uid(),p_is_active);
  else
    update public.employees set branch_id=p_branch_id,employee_code=upper(trim(p_code)),full_name=trim(p_name),
      position_title=nullif(trim(p_position),''),phone=nullif(trim(p_phone),''),email=nullif(trim(p_email),''),
      notes=nullif(trim(p_notes),''),is_active=p_is_active,updated_at=now()
      where company_id=p_company_id and id=p_employee_id;
    if not found then raise exception 'Data karyawan tidak ditemukan'; end if;
  end if;
  return v_id;
end $$;

create or replace function public.get_user_access_directory(p_company_id uuid)
returns table(user_id uuid,email text,display_name text,roles text[],branch_ids uuid[])
language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak lihat pengguna perusahaan ditolak' using errcode='42501';
  end if;
  return query
    select u.id,u.email,p.display_name,
      coalesce(array_agg(distinct ur.role::text) filter(where ur.role is not null),array[]::text[]),
      coalesce(array_agg(distinct ba.branch_id) filter(where ba.branch_id is not null),array[]::uuid[])
    from auth.users u
    left join public.profiles p on p.user_id=u.id
    left join public.user_roles ur on ur.company_id=p_company_id and ur.user_id=u.id
    left join public.user_branch_access ba on ba.company_id=p_company_id and ba.user_id=u.id
    group by u.id,u.email,p.display_name order by u.email;
end $$;

create or replace function public.set_user_access(p_company_id uuid,p_user_id uuid,p_roles public.app_role[],p_branch_ids uuid[])
returns void language plpgsql security definer set search_path = '' as $$
declare v_owner_count integer; v_target_has_owner boolean; v_invalid_count integer;
begin
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak ubah akses pengguna ditolak' using errcode='42501';
  end if;
  if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'Akun Auth tidak ditemukan'; end if;
  select count(*) into v_invalid_count from unnest(coalesce(p_branch_ids,array[]::uuid[])) b(id)
    where not exists(select 1 from public.branches br where br.company_id=p_company_id and br.id=b.id);
  if v_invalid_count>0 then raise exception 'Daftar cabang memuat cabang di luar perusahaan'; end if;
  select count(*) into v_owner_count from public.user_roles where company_id=p_company_id and role='owner';
  select exists(select 1 from public.user_roles where company_id=p_company_id and user_id=p_user_id and role='owner') into v_target_has_owner;
  if v_target_has_owner and not ('owner'=any(coalesce(p_roles,array[]::public.app_role[]))) and v_owner_count<=1 then
    raise exception 'Perusahaan harus tetap memiliki minimal satu Owner';
  end if;
  delete from public.user_roles where company_id=p_company_id and user_id=p_user_id;
  insert into public.user_roles(company_id,user_id,role)
    select p_company_id,p_user_id,r from unnest(coalesce(p_roles,array[]::public.app_role[])) r
    on conflict do nothing;
  delete from public.user_branch_access where company_id=p_company_id and user_id=p_user_id;
  insert into public.user_branch_access(company_id,branch_id,user_id)
    select p_company_id,b,p_user_id from unnest(coalesce(p_branch_ids,array[]::uuid[])) b
    on conflict(branch_id,user_id) do update set company_id=excluded.company_id;
end $$;

create or replace function public.get_receivables_report(p_company_id uuid,p_branch_id uuid,p_as_of date default current_date)
returns table(sale_id uuid,document_number text,customer_id uuid,customer_name text,invoice_date date,due_date date,
  invoice_total numeric,paid_total numeric,outstanding numeric,days_overdue integer,aging_bucket text)
language plpgsql security definer set search_path = '' as $$
begin
  if not private.has_branch_access(p_company_id,p_branch_id)
    or not private.has_any_role(p_company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance','supervisor']::public.app_role[]) then
    raise exception 'Hak lihat piutang ditolak' using errcode='42501';
  end if;
  return query select s.id,s.document_number,s.customer_id,coalesce(c.name,'Pelanggan umum'),s.created_at::date,s.due_date,
    s.total_amount,s.paid_amount,greatest(s.total_amount-s.paid_amount,0),
    case when s.due_date is null then 0 else greatest(p_as_of-s.due_date,0) end,
    case when s.due_date is null then 'Belum diatur' when s.due_date>=p_as_of then 'Belum jatuh tempo'
      when p_as_of-s.due_date<=30 then '1–30 hari' when p_as_of-s.due_date<=60 then '31–60 hari'
      when p_as_of-s.due_date<=90 then '61–90 hari' else '>90 hari' end
  from public.sales s left join public.customers c on c.company_id=s.company_id and c.id=s.customer_id
  where s.company_id=p_company_id and s.branch_id=p_branch_id and s.customer_id is not null
    and s.status='posted' and s.paid_amount<s.total_amount
  order by s.due_date nulls last,s.created_at;
end $$;

create or replace function public.set_sales_due_date(p_sale_id uuid,p_due_date date)
returns void language plpgsql security definer set search_path = '' as $$
declare v public.sales%rowtype;
begin
  select * into v from public.sales where id=p_sale_id for update;
  if not found or not private.has_branch_access(v.company_id,v.branch_id) then raise exception 'Invoice tidak ditemukan atau akses ditolak' using errcode='42501'; end if;
  if not private.has_any_role(v.company_id,array['owner','super_admin','central_admin','branch_admin','cashier','finance']::public.app_role[]) then
    raise exception 'Hak ubah jatuh tempo piutang ditolak' using errcode='42501';
  end if;
  if v.status<>'posted' or v.paid_amount>=v.total_amount then raise exception 'Jatuh tempo hanya dapat diubah pada invoice terbuka'; end if;
  update public.sales set due_date=p_due_date where id=v.id;
end $$;

revoke execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) from public,anon;
revoke execute on function public.create_branch(uuid,text,text,text,text) from public,anon;
revoke execute on function public.update_branch_profile(uuid,uuid,text,text,text,text) from public,anon;
revoke execute on function public.create_warehouse(uuid,uuid,text,text) from public,anon;
revoke execute on function public.upsert_employee(uuid,uuid,uuid,text,text,text,text,text,text,boolean) from public,anon;
revoke execute on function public.get_user_access_directory(uuid) from public,anon;
revoke execute on function public.set_user_access(uuid,uuid,public.app_role[],uuid[]) from public,anon;
revoke execute on function public.get_receivables_report(uuid,uuid,date) from public,anon;
revoke execute on function public.set_sales_due_date(uuid,date) from public,anon;
grant execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.create_branch(uuid,text,text,text,text) to authenticated;
grant execute on function public.update_branch_profile(uuid,uuid,text,text,text,text) to authenticated;
grant execute on function public.create_warehouse(uuid,uuid,text,text) to authenticated;
grant execute on function public.upsert_employee(uuid,uuid,uuid,text,text,text,text,text,text,boolean) to authenticated;
grant execute on function public.get_user_access_directory(uuid) to authenticated;
grant execute on function public.set_user_access(uuid,uuid,public.app_role[],uuid[]) to authenticated;
grant execute on function public.get_receivables_report(uuid,uuid,date) to authenticated;
grant execute on function public.set_sales_due_date(uuid,date) to authenticated;
