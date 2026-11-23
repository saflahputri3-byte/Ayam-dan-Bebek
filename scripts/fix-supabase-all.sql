-- ============================================================================
-- SCRIPT MASTER PERBAIKAN TOTAL SUPABASE ERP AGI AYAM & BEBEK
-- Jalankan script ini langsung di:
-- https://supabase.com/dashboard/project/yzkcodffkayuqhqqflif/sql/new
-- ============================================================================

-- 1. PASTIKAN KOLOM IDENTITAS PERUSAHAAN TERSEDIA DI TABEL COMPANIES
alter table public.companies add column if not exists address text;
alter table public.companies add column if not exists phone text;
alter table public.companies add column if not exists email text;
alter table public.companies add column if not exists logo_path text;

-- 2. UPDATE LANGSUNG IDENTITAS PERUSAHAAN DENGAN DATA RESMI AGI AYAM & BEBEK
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

  -- 3. PASTIKAN CABANG PUSAT TERSEDIA
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

  -- 4. PASTIKAN GUDANG UTAMA TERSEDIA
  select id into v_warehouse from public.warehouses where company_id = v_company and branch_id = v_branch limit 1;
  if v_warehouse is null then
    insert into public.warehouses (company_id, branch_id, code, name)
    values (v_company, v_branch, 'UTAMA', 'Gudang Utama Fresh & Frozen')
    returning id into v_warehouse;
  end if;

  -- 5. KENDALIKAN PENUH: BERIKAN AKSES OWNER & SUPER ADMIN KE SEMUA PENGGUNA TERDAFTAR
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

-- 6. PERBARUI FUNGSI UPDATE_COMPANY_PROFILE AGAR SELALU AMAN & VALID
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
  -- Periksa izin akses (hanya owner, super_admin, atau central_admin)
  if not private.has_company_access(p_company_id)
    or not private.has_any_role(p_company_id, array['owner','super_admin','central_admin']::public.app_role[]) then
    raise exception 'Hak ubah profil perusahaan ditolak' using errcode='42501';
  end if;

  -- Validasi input fleksibel
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

-- Berikan izin eksekusi ke authenticated user
revoke execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function public.update_company_profile(uuid,text,text,text,text,text,text,text,text) to authenticated;

-- 7. PASTIKAN RLS PADA COMPANIES MEMPERBOLEHKAN SELECT & UPDATE
grant select, update on public.companies to authenticated;

drop policy if exists company_member_read on public.companies;
create policy company_member_read on public.companies
  for select to authenticated
  using (private.has_company_access(id));

drop policy if exists company_owner_update on public.companies;
create policy company_owner_update on public.companies
  for update to authenticated
  using (private.has_any_role(id, array['owner','super_admin','central_admin']::public.app_role[]))
  with check (private.has_any_role(id, array['owner','super_admin','central_admin']::public.app_role[]));
