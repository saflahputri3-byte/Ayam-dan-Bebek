-- Script untuk memberikan hak akses Owner penuh pada database Supabase
-- Jalankan script ini di: https://supabase.com/dashboard/project/yzkcodffkayuqhqqflif/sql/new

do $$
declare
  r_user record;
  v_company uuid;
  v_branch uuid;
  v_warehouse uuid;
begin
  -- 1. Ambil atau buat Perusahaan Utama
  select id into v_company from public.companies order by created_at asc limit 1;
  if v_company is null then
    insert into public.companies (name, legal_name, currency_code, timezone, address, phone, email)
    values (
      'AGI Ayam & Bebek',
      'PT Agi Unggas Berkah Nusantara',
      'IDR',
      'Asia/Jakarta',
      'Kawasan Sentra Niaga Rantai Dingin Kav. 8-10, Jakarta',
      '021-7890-1234',
      'kontak@agi-unggas.id'
    )
    returning id into v_company;
  end if;

  -- 2. Ambil atau buat Cabang Utama (PUSAT)
  select id into v_branch from public.branches where company_id = v_company and code = 'PUSAT' limit 1;
  if v_branch is null then
    select id into v_branch from public.branches where company_id = v_company limit 1;
  end if;
  if v_branch is null then
    insert into public.branches (company_id, code, name, address, phone)
    values (v_company, 'PUSAT', 'Cabang Utama (Pusat)', 'Sentra Rantai Dingin Kav. 8', '021-7890-1234')
    returning id into v_branch;
  end if;

  -- 3. Ambil atau buat Gudang Utama
  select id into v_warehouse from public.warehouses where company_id = v_company and branch_id = v_branch limit 1;
  if v_warehouse is null then
    insert into public.warehouses (company_id, branch_id, code, name)
    values (v_company, v_branch, 'UTAMA', 'Gudang Utama (Fresh)')
    returning id into v_warehouse;
  end if;

  -- 4. Berikan Hak Akses OWNER Penuh ke SEMUA Akun Pengguna yang terdaftar di auth.users
  for r_user in (select id from auth.users) loop
    -- Profil
    insert into public.profiles (user_id, display_name)
    values (r_user.id, 'Direktur / Owner')
    on conflict (user_id) do update set display_name = 'Direktur / Owner';

    -- Hak Akses Peran Lengkap (Owner, Super Admin, Central Admin, Branch Admin)
    insert into public.user_roles (company_id, user_id, role)
    values 
      (v_company, r_user.id, 'owner'),
      (v_company, r_user.id, 'super_admin'),
      (v_company, r_user.id, 'central_admin'),
      (v_company, r_user.id, 'branch_admin')
    on conflict do nothing;

    -- Hak Akses Cabang
    insert into public.user_branch_access (company_id, branch_id, user_id)
    values (v_company, v_branch, r_user.id)
    on conflict do nothing;
  end loop;

  raise notice 'Hak akses Owner berhasil ditetapkan untuk perusahaan % dan cabang %', v_company, v_branch;
end $$;
