# Backup dan Pemulihan Supabase

## Cakupan

Skrip repository membuat logical backup schema `public` dan `private` dalam
format PostgreSQL custom, memverifikasi ukuran serta SHA-256, dan menyimpan
file di `backups/` yang diabaikan Git. File dapat berisi data operasional
sensitif. Simpan salinan terenkripsi di lokasi terpisah dengan akses terbatas
dan retensi yang disetujui pemilik usaha.

Logical backup repository ini **tidak** berisi Supabase Auth, objek Storage,
Edge Function secrets, konfigurasi proyek, atau custom role/password. Database
backup Supabase juga tidak menyertakan objek yang tersimpan melalui Storage API.
Aktifkan/konfirmasi backup platform pada proyek, dan siapkan replikasi objek
bucket `business-documents` ke penyimpanan yang dikelola organisasi. Tetapkan
frekuensi, retensi, RPO, dan RTO sebelum penggunaan operasional.

## Membuat backup aplikasi

1. Instal PostgreSQL client tools dan pastikan `pg_dump` dapat dijalankan.
2. Simpan URL database hanya ke environment shell tepercaya sebagai
   `SUPABASE_DB_URL`; jangan masukkan ke file frontend atau commit.
3. Jalankan dari root repository:

   ```powershell
   $env:SUPABASE_DB_URL = '<connection string dari Supabase Dashboard>'
   .\scripts\backup-supabase.ps1 -ProjectRef '<project-ref>'
   Remove-Item Env:\SUPABASE_DB_URL
   ```

4. Pindahkan hasil `.dump` dan manifest ke lokasi backup terenkripsi/off-site
   sesuai kebijakan organisasi. Jangan mengandalkan salinan pada komputer ini.

## Pemulihan

Lakukan latihan pemulihan terlebih dahulu pada proyek Supabase staging baru.
Pemulihan menghapus/mengganti objek pada schema aplikasi target. Gunakan dump
yang telah diverifikasi, lalu:

```powershell
$env:SUPABASE_RESTORE_DB_URL = '<connection string target staging>'
$env:SUPABASE_RESTORE_PROJECT_REF = '<ref target staging>'
.\scripts\restore-supabase.ps1 -BackupFile '.\backups\<file>.dump' -TargetProjectRef '<ref target staging>'
Remove-Item Env:\SUPABASE_RESTORE_DB_URL
Remove-Item Env:\SUPABASE_RESTORE_PROJECT_REF
```

Skrip memeriksa SHA-256, mencocokkan dua referensi proyek, dan meminta frasa
konfirmasi sebelum memulai `pg_restore --clean`. Setelah pemulihan, terapkan
migrasi terbaru sesuai prosedur rilis, pulihkan objek Storage dari replika
terpisah, atur ulang secret/provider Auth yang diperlukan, lalu verifikasi RLS,
login, transaksi, saldo ledger, dokumen privat, dan notifikasi sebelum membuka
kembali operasi.

## Latihan pemulihan wajib

- Jadwalkan latihan berkala; catat waktu mulai/selesai dan data terakhir yang
  berhasil dipulihkan.
- Cocokkan total saldo `inventory_balances` dengan agregat ledger per batch dan
  gudang.
- Periksa total debit/kredit semua jurnal, alokasi piutang/utang, dan saldo kas.
- Uji akses lintas cabang, login pengguna, file Storage, serta Edge Function.
- Tetapkan pemilik proses, retensi, RPO/RTO, dan prosedur komunikasi sebelum
  sistem dinyatakan siap produksi.

Belum ada koneksi proyek Supabase pada workspace ini, sehingga backup dan
restore belum pernah dijalankan terhadap database riil.
