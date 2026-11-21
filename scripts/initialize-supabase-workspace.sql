-- One-time initial workspace setup for the selected Supabase project.
-- Guarded so it only assigns Owner when exactly one Auth user exists.
do $bootstrap$
declare
  v_user uuid;
  v_company uuid;
  v_branch uuid;
  v_warehouse uuid;
  v_count integer;
begin
  select count(*) into v_count from auth.users;
  if v_count <> 1 then
    raise exception 'Expected exactly one Auth user for initial Owner assignment; found %', v_count;
  end if;
  select id into v_user from auth.users limit 1;

  select id into v_company from public.companies where name = 'AGI Ayam & Bebek' limit 1;
  if v_company is null then
    select count(*) into v_count from public.companies;
    if v_count <> 0 then
      raise exception 'Companies already exist; choose the intended company before bootstrap';
    end if;
    insert into public.companies(name) values ('AGI Ayam & Bebek') returning id into v_company;
  end if;

  select id into v_branch from public.branches where company_id = v_company and code = 'PUSAT' limit 1;
  if v_branch is null then
    select count(*) into v_count from public.branches where company_id = v_company;
    if v_count <> 0 then
      raise exception 'Company already has branches; choose the intended branch before bootstrap';
    end if;
    insert into public.branches(company_id, code, name)
      values (v_company, 'PUSAT', 'Pusat') returning id into v_branch;
  end if;

  select id into v_warehouse from public.warehouses
    where company_id = v_company and branch_id = v_branch and code = 'UTAMA' limit 1;
  if v_warehouse is null then
    select count(*) into v_count from public.warehouses where company_id = v_company and branch_id = v_branch;
    if v_count <> 0 then
      raise exception 'Branch already has warehouses; choose the intended warehouse before bootstrap';
    end if;
    insert into public.warehouses(company_id, branch_id, code, name)
      values (v_company, v_branch, 'UTAMA', 'Gudang Utama') returning id into v_warehouse;
  end if;

  insert into public.user_roles(company_id, user_id, role)
    values (v_company, v_user, 'owner') on conflict (company_id, user_id, role) do nothing;
  insert into public.user_branch_access(company_id, branch_id, user_id)
    values (v_company, v_branch, v_user)
    on conflict (branch_id, user_id) do update set company_id = excluded.company_id;
end
$bootstrap$;
