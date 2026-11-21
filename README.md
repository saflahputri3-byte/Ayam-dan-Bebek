# Agi Ayam & Bebek ERP

Aplikasi ERP berbasis React + TypeScript dengan Clean Architecture, Supabase Auth/PostgreSQL/Storage, kontrol akses cabang melalui RLS, dan PWA. Cakupan serta keputusan domain mengikuti [PRD_AGI_AYAM_BEBEK_ERP.md](./PRD_AGI_AYAM_BEBEK_ERP.md).

## Menjalankan aplikasi

```sh
npm install
Copy-Item .env.example .env.local
npm run dev
```

Isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_PUBLISHABLE_KEY` dari proyek Supabase. Publishable key memang digunakan di browser; RLS wajib aktif. Jangan menaruh `service_role`, database password, atau API key Gemini di file `VITE_*`.

## Menyiapkan backend Supabase

1. Buat proyek Supabase, lalu tautkan CLI dan terapkan migrasi:

   ```sh
   npx supabase login
   npx supabase link --project-ref <project-ref>
   npx supabase db push
   ```

2. Matikan pendaftaran publik (sudah diset pada `supabase/config.toml`). Buat pengguna dari Supabase Dashboard/Admin API di lingkungan tepercaya. Setelah itu jalankan template bootstrap berikut **sekali** di SQL Editor dan ganti nama usaha/cabang/gudang/email:

   ```sql
   do $$
   declare
     v_user uuid;
     v_company uuid;
     v_branch uuid;
   begin
     select id into v_user from auth.users where lower(email)=lower('owner@contoh.id');
     if v_user is null then raise exception 'Buat user Auth terlebih dahulu'; end if;
     insert into public.companies(name) values ('Nama Usaha') returning id into v_company;
     insert into public.branches(company_id,code,name) values (v_company,'PUSAT','Cabang Utama') returning id into v_branch;
     insert into public.warehouses(company_id,branch_id,code,name) values (v_company,v_branch,'UTAMA','Gudang Utama');
     insert into public.profiles(user_id,display_name) values (v_user,'Administrator');
     insert into public.user_roles(company_id,user_id,role) values (v_company,v_user,'owner');
     insert into public.user_branch_access(company_id,branch_id,user_id) values (v_company,v_branch,v_user);
   end $$;
   ```

   Jangan membuat bootstrap admin memakai endpoint browser. Akun hanya melihat cabang yang diberikan oleh RLS. Perusahaan, cabang, dan gudang awal dibuat lewat bootstrap tepercaya; produk/satuan, pemasok, dan pelanggan selanjutnya dapat dikelola dari modul Master Data sesuai role. Rasio unit selain satuan dasar harus dimasukkan secara eksplisit.
3. Deploy OCR dan simpan secret di Supabase, bukan repository:

   ```sh
   # Buat file lokal yang diabaikan Git: supabase/.env.local
   # Isi GEMINI_API_KEY dan GEMINI_MODEL di file tersebut
   npx supabase secrets set --env-file supabase/.env.local
   npx supabase functions deploy extract-document
   ```

   Fungsi OCR memvalidasi JWT, membaca metadata dan file melalui client pengguna yang tunduk RLS, membatasi file sampai 12 MB, lalu menyimpan ekstraksi sebagai draft `needs_review`. UI meminta persetujuan sebelum dokumen dikirim ke Google Gemini. Konfirmasi OCR tidak membuat transaksi.

## Struktur Clean Architecture

```text
src/
  domain/                  Tipe domain dan navigasi/otorisasi modul
  application/             Port repository dan use case
  infrastructure/          Adapter Supabase Auth, RPC, Storage, dashboard
  presentation/             Halaman ERP, komponen, route dan styling
  main.tsx                 Composition root
supabase/
  migrations/              Skema, RLS, ledger, audit, RPC transaksi atomik
  functions/               Edge Function OCR dengan secret server-side
public/                    Web manifest, ikon dan service worker shell
```

Alur mutasi stok ditulis melalui RPC PostgreSQL dalam satu transaksi dan menghasilkan `inventory_movements` yang tidak dapat diubah langsung oleh client. Saldo tersedia untuk penjualan hanya dari batch yang lulus inspeksi. Service worker hanya menyimpan app shell; mutasi transaksi tidak diantrikan offline.

## Implementasi dan batas cakupan

- Supabase Auth dengan login email/kata sandi, akses peran dan pilihan cabang.
- RLS tenant/cabang dan Storage bucket privat; transaksi tulis melalui fungsi RPC terotorisasi. Master data mendukung pencarian, tambah/ubah, konversi satuan eksplisit, dan arsip nonaktif.
- Penjualan dan invoice bernomor server, pembayaran pelanggan, pembelian/penerimaan, produksi multi-output, inspeksi kualitas, transfer dengan approval dan selisih, stok opname/penyesuaian, retur karantina, pengiriman, utang/piutang dan umur tagihan, kas/bank, jurnal berpasangan, laporan trial balance/laba rugi/arus kas berbasis jurnal, notifikasi dalam aplikasi, pengaturan perusahaan/cabang/gudang, direktori karyawan dan akses pengguna, pemulihan kata sandi, OCR/review, cetak invoice, dan PWA.
- Metode valuasi persediaan memakai rata-rata tertimbang bergerak per produk pada tingkat perusahaan. Biaya bersama produksi multi-output dialokasikan menurut berat output; produk berbasis pcs/ekor memerlukan konversi satuan kg di Master Data. Ringkasan nilai stok dan biaya rata-rata ada di Laporan untuk administrator/keuangan. HPP penjualan dijurnal otomatis jika akun Persediaan/HPP serta periode fiskal sudah dipetakan. Produk opening tanpa riwayat penerimaan bernilai nol sampai dinilai; transaksi historis tidak dijurnal ulang. Overhead tambahan, jurnal susut/limbah, jurnal penyesuaian stok, dan refund retur tetap menunggu keputusan yang tercatat di PRD.
- Tabel master masih perlu di-bootstrap oleh admin tepercaya. Seed perusahaan/produk/pengguna tidak disertakan.
- Panduan backup/pemulihan ada di [docs/SUPABASE_BACKUP_RECOVERY.md](./docs/SUPABASE_BACKUP_RECOVERY.md). Logical dump repository tidak menyertakan Auth, objek Storage, secret, atau konfigurasi proyek; backup terkelola Supabase dan replika bucket perlu disiapkan terpisah.

Build lokal:

```sh
npm run build
npm run preview
```

PWA mendaftarkan service worker hanya pada build produksi yang di-serve melalui HTTPS (localhost diperbolehkan untuk pengembangan). Migrasi database telah diterapkan ke proyek Supabase terpilih. Edge Function OCR tersedia di repository tetapi perlu dideploy dan memerlukan `GEMINI_API_KEY` sebagai secret Supabase. Untuk pemulihan sandi, tambahkan URL aplikasi ke Auth Redirect URLs di Dashboard Supabase.
