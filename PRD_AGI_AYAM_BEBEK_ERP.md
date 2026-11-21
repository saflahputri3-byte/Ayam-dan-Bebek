# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## AGI AYAM & BEBEK --- Sistem ERP Terintegrasi

**Versi dokumen:** 1.0\
**Tanggal:** 14 November 2026\
**Status:** Draft kebutuhan produk berdasarkan hasil diskusi\
**Platform target:** Web responsif / PWA (ponsel, tablet, laptop,
desktop)\
**Nama produk:** AGI AYAM & BEBEK

> Dokumen ini menjadi acuan utama untuk perancangan dan pembangunan
> aplikasi ERP. Keputusan yang belum ditetapkan secara eksplisit
> ditandai **Perlu Konfirmasi**. Jangan mengasumsikan keputusan tersebut
> sebagai fakta bisnis.

------------------------------------------------------------------------

## 1. Ringkasan Produk

AGI AYAM & BEBEK adalah aplikasi ERP untuk mengelola usaha perdagangan,
pemotongan/pengolahan, penyimpanan, dan distribusi ayam serta bebek.
Aplikasi harus mengintegrasikan aktivitas pembelian unggas hidup,
penerimaan, produksi/pemotongan, pencatatan hasil produksi, pengelolaan
persediaan, penjualan, pengiriman, pembayaran, keuangan, akuntansi,
dokumen, dan pelaporan.

Sistem ditujukan untuk penggunaan multi-cabang dan multi-gudang. Data
terpusat pada satu basis data, sedangkan hak akses dan transaksi
dibatasi sesuai peran serta cabang pengguna.

Aplikasi harus nyaman digunakan pada ponsel dengan pola antarmuka
seperti aplikasi modern: beranda berupa kotak-kotak menu (app launcher),
ikon yang jelas, navigasi bawah, formulir yang mudah disentuh, serta
tampilan desktop dengan sidebar dan tabel operasional yang lebih
lengkap.

## 2. Latar Belakang dan Masalah

Operasional usaha melibatkan banyak proses yang saling memengaruhi.
Pencatatan yang terpisah dapat menimbulkan: - Perbedaan antara jumlah
unggas, berat kilogram, dan jumlah potongan. - Ketidaksesuaian stok
fisik dengan catatan. - Kesulitan menelusuri asal bahan baku dan hasil
produksi. - Perhitungan hasil produksi, susut, limbah, dan harga pokok
yang tidak konsisten. - Kesulitan menghubungkan pembelian, penerimaan,
produksi, penjualan, pembayaran, dan laba. - Dokumen transaksi yang
tersebar dan sulit dicari. - Risiko transaksi atau pergerakan stok
tercatat dua kali. - Keterbatasan pemantauan kinerja antar-cabang.

## 3. Tujuan Produk

1.  Menyatukan proses utama usaha dalam satu aplikasi.
2.  Menyediakan data stok yang akurat dan dapat ditelusuri.
3.  Mengelola proses pembelian hingga penjualan secara terintegrasi.
4.  Mencatat hasil produksi dan menghitung HPP dengan kebijakan yang
    transparan.
5.  Mengelola kas, bank, utang, piutang, biaya, dan laporan keuangan.
6.  Menghasilkan invoice/nota yang dapat dipratinjau, dicetak, dan
    disimpan sebagai PDF.
7.  Mempercepat input dokumen melalui pemindaian/OCR dengan pemeriksaan
    manusia.
8.  Memberikan kontrol akses berbasis peran dan cabang.
9.  Menyediakan laporan operasional dan keuangan untuk pemilik serta
    manajemen.
10. Memberikan pengalaman penggunaan yang baik pada perangkat mobile
    maupun desktop.

## 4. Ruang Lingkup

### 4.1 Termasuk dalam ruang lingkup

-   Dashboard dan ringkasan operasional.
-   Master data perusahaan, cabang, gudang, pengguna, pemasok,
    pelanggan, produk, satuan, dan karyawan.
-   Pembelian dan penerimaan barang.
-   Produksi/pemotongan, input bahan baku, output produk, hasil, susut,
    limbah, dan biaya.
-   Persediaan, mutasi stok, stok opname, penyesuaian, dan transfer
    antar-gudang/cabang.
-   Penjualan/POS, pesanan, retur, pengiriman, dan pembayaran.
-   Invoice, nota, dokumen transaksi, dan riwayat cetak.
-   Pemindaian nota/struk/dokumen dengan OCR.
-   Kas, bank, pengeluaran, utang, piutang, jurnal, dan laporan.
-   Pelacakan batch dan riwayat asal-usul produk.
-   Kontrol kualitas dan pencatatan suhu.
-   Notifikasi, audit log, dan pengaturan.
-   Antarmuka responsif dan dukungan instalasi PWA jika memungkinkan.

### 4.2 Di luar ruang lingkup awal

Hal-hal berikut belum dipastikan dan tidak boleh dianggap otomatis
tersedia: - Integrasi langsung dengan bank atau payment gateway. -
Integrasi pajak/e-Faktur atau sistem pemerintah. - Integrasi timbangan
digital, printer kasir, barcode scanner, atau perangkat IoT. - Payroll
lengkap dan perhitungan pajak karyawan. - Integrasi marketplace atau
aplikasi pihak ketiga. - Prediksi permintaan atau optimasi produksi
berbasis AI.

Masing-masing dapat menjadi fase lanjutan setelah kebutuhan dan penyedia
layanan dikonfirmasi.

## 5. Profil Operasional Usaha

Berdasarkan diskusi: - Usaha membeli ayam dan bebek hidup. - Unggas
dapat diproses/dipotong dan dijual sebagai produk olahan. - Produk dapat
dijual hidup maupun dalam bentuk karkas, potongan, jeroan, dan hasil
samping. - Volume operasional lebih dari 200 ekor per hari. -
Operasional melibatkan beberapa cabang dan gudang. - Aplikasi digunakan
melalui HP, tablet, laptop, dan komputer.

### 5.1 Kelompok produk

Contoh kelompok produk: - Unggas hidup: ayam hidup dan bebek hidup. -
Karkas/utuh. - Potongan: dada, paha, sayap, kaki, kepala, leher. -
Jeroan: hati, ampela, jantung, usus. - Hasil samping lain yang
ditetapkan perusahaan.

Daftar produk final, kode SKU, kategori, dan metode valuasi **Perlu
Konfirmasi**.

### 5.2 Satuan

Sistem wajib membedakan secara tegas: - Ekor/buah/pcs. - Kilogram
(kg). - Satuan lain yang diperlukan.

Konversi satuan tidak boleh dilakukan dengan asumsi tersembunyi. Rasio
konversi, toleransi, dan aturan pembulatan **Perlu Konfirmasi**.

------------------------------------------------------------------------

## 6. Pengguna, Peran, dan Hak Akses

Peran yang direncanakan: 1. **Owner** --- akses pemantauan dan
persetujuan sesuai kebijakan perusahaan. 2. **Admin Pusat** ---
pengelolaan konfigurasi, master data, pengguna, dan kontrol pusat. 3.
**Admin Cabang** --- pengelolaan aktivitas cabang sesuai kewenangan. 4.
**Purchasing** --- pemasok, permintaan/pesanan pembelian, dan pembelian.
5. **Produksi** --- batch produksi, input bahan baku, output, hasil, dan
catatan proses. 6. **Gudang** --- penerimaan, stok, transfer, opname,
dan penyesuaian sesuai izin. 7. **Kasir** --- transaksi penjualan dan
penerimaan pembayaran sesuai kewenangan. 8. **Keuangan** --- kas, bank,
pembayaran, biaya, utang, piutang, dan rekonsiliasi. 9. **Supervisor**
--- pemantauan dan persetujuan proses yang ditugaskan. 10.
**Pengiriman** --- daftar pengiriman dan status serah terima.

Hak akses harus dapat dikonfigurasi dengan prinsip least privilege.
Seorang pengguna dapat memiliki lebih dari satu peran jika diizinkan.

### 6.1 Pembatasan cabang

-   Pengguna hanya boleh melihat dan mengubah data cabang yang menjadi
    kewenangannya.
-   Admin pusat/owner dapat memiliki akses lintas cabang sesuai
    kebijakan.
-   Pembatasan harus ditegakkan di backend dan Supabase Row Level
    Security (RLS), bukan hanya dengan menyembunyikan menu di antarmuka.
-   Akses lintas cabang dan perubahan hak akses harus tercatat di audit
    log.

Matriks izin final dan siapa yang berwenang menyetujui transaksi **Perlu
Konfirmasi**.

------------------------------------------------------------------------

## 7. Modul dan Kebutuhan Fungsional

### 7.1 Dashboard

Dashboard menampilkan informasi sesuai hak akses: - Ringkasan pembelian,
penjualan, penerimaan, dan produksi. - Stok dan peringatan stok. -
Ringkasan kas/bank, utang, dan piutang sesuai izin. - Aktivitas
terbaru. - Notifikasi tugas atau transaksi yang perlu ditinjau. - Filter
tanggal, cabang, dan gudang.

Angka dashboard harus berasal dari data transaksi yang sah, bukan data
demo. Data contoh harus diberi label **DEMO** dan tidak boleh bercampur
dengan data produksi.

### 7.2 Master Data

Kelola: - Perusahaan dan identitas dokumen. - Cabang. - Gudang. -
Pengguna, peran, dan izin. - Pemasok. - Pelanggan. - Kategori produk. -
Produk dan SKU. - Satuan dan konversi satuan. - Daftar harga/harga
jual. - Karyawan. - Kategori biaya dan pengaturan aplikasi.

Setiap data master perlu mendukung pencarian, filter, tambah, ubah,
status aktif/nonaktif, dan riwayat perubahan. Penghapusan master data
yang sudah dipakai transaksi harus dibatasi; gunakan status nonaktif
atau mekanisme arsip.

### 7.3 Pembelian

Fungsi: - Membuat transaksi/pesanan pembelian. - Memilih pemasok,
cabang, gudang tujuan, tanggal, dan item. - Mencatat jenis
unggas/produk, jumlah ekor, berat kg, harga, dan total. - Mencatat biaya
tambahan, diskon, dan catatan bila relevan. - Melacak status: draft,
diajukan, disetujui, diterima sebagian, diterima penuh, dibatalkan. -
Menghubungkan pembelian dengan penerimaan dan pembayaran pemasok. -
Menyimpan lampiran dokumen.

Aturan persetujuan, termin pembayaran, dan format nomor dokumen **Perlu
Konfirmasi**.

### 7.4 Penerimaan Barang

Fungsi: - Menerima barang berdasarkan transaksi pembelian atau
penerimaan langsung jika diizinkan. - Mencatat jumlah ekor, berat,
kondisi, waktu, pemasok, dan gudang. - Mendukung penerimaan sebagian. -
Mencatat selisih dari pesanan. - Menyimpan bukti penerimaan dan
pemeriksaan. - Membuat batch bahan baku untuk kebutuhan pelacakan.

**Penerimaan yang telah dikonfirmasi** menjadi salah satu titik
pencatatan stok masuk. Pemindaian nota saja tidak boleh menambah stok.

### 7.5 Produksi/Pemotongan

Fungsi: - Membuat batch produksi. - Memilih bahan baku/batch input dan
gudang asal. - Mencatat jumlah unggas dan berat input. - Mencatat
tanggal, waktu, operator, dan lokasi proses. - Mencatat output per jenis
produk: karkas, potongan, jeroan, dan hasil samping. - Mencatat susut,
limbah, produk rusak, dan hasil yang tidak dapat dijual. - Mencatat
biaya tenaga kerja, proses, kemasan, dan biaya terkait. - Menghasilkan
batch produk jadi dan mutasi stok ke gudang tujuan. - Menyediakan
laporan yield/hasil produksi.

Sistem harus memvalidasi bahwa total input/output dan selisih berada
dalam aturan toleransi yang ditentukan. Rumus yield, kategori limbah,
dan toleransi **Perlu Konfirmasi**.

### 7.6 HPP dan Alokasi Biaya Produksi

-   HPP harus berasal dari biaya bahan baku dan biaya produksi yang
    relevan.
-   Biaya bersama untuk beberapa jenis output harus dialokasikan dengan
    metode yang dipilih perusahaan.
-   Kandidat metode alokasi: berdasarkan berat output atau nilai jual
    relatif.
-   Metode yang digunakan harus konsisten, terdokumentasi, dan dapat
    ditelusuri.
-   Sistem tidak boleh menyederhanakan HPP sebagai penjualan dikurangi
    pembelian pada hari yang sama.
-   Perubahan kebijakan HPP harus memiliki tanggal efektif dan jejak
    audit.

Keputusan bisnis: metode valuasi persediaan **rata-rata tertimbang bergerak** pada tingkat perusahaan per produk. Biaya bersama produksi multi-output dialokasikan **berdasarkan berat output**. Produk berbasis kg memakai kuantitas dasarnya; produk berbasis pcs/ekor wajib memiliki konversi satuan kg di Master Data agar bobotnya dapat dihitung. Biaya penerimaan dikonversi ke satuan dasar; biaya bahan input dibawa ke output dan menjadi HPP ketika output terjual. Nilai produk opening tanpa riwayat penerimaan harus ditetapkan sebelum dipakai untuk laporan resmi.

Perlakuan finansial susut/limbah, overhead tambahan, dan jurnal penyesuaian positif/negatif masih **Perlu Konfirmasi**. Sampai ditetapkan, biaya input produksi yang tercatat dialokasikan seluruhnya ke output berdasarkan berat; biaya overhead tambahan dan pembebanan terpisah ke susut/limbah belum disertakan.

### 7.7 Persediaan dan Gudang

Fungsi: - Melihat stok per produk, batch, cabang, dan gudang. - Melihat
stok dalam satuan yang benar. - Riwayat mutasi masuk/keluar. - Stok
opname. - Penyesuaian stok dengan alasan dan persetujuan. - Transfer
antar-gudang/cabang. - Pencatatan barang rusak, kedaluwarsa, atau tidak
layak. - Peringatan stok minimum jika batas ditentukan.

**Prinsip wajib:** gunakan inventory movement ledger sebagai sumber
riwayat mutasi yang tidak diubah sembarangan. Saldo stok adalah hasil
perhitungan/rekap mutasi. Jangan hanya mengandalkan satu angka stok yang
dapat ditimpa tanpa jejak.

Transaksi yang sudah diposting tidak boleh dihapus langsung. Koreksi
dilakukan melalui reversal/penyesuaian dengan alasan dan audit trail.

### 7.8 Transfer Antar-Gudang/Cabang

Alur minimum: 1. Pengguna membuat permintaan transfer. 2. Pihak
berwenang menyetujui sesuai aturan. 3. Gudang asal menyiapkan dan
mengirim barang. 4. Sistem mencatat status dalam perjalanan. 5. Gudang
tujuan menerima dan mengonfirmasi jumlah aktual. 6. Selisih dicatat dan
ditindaklanjuti. 7. Sistem menyimpan riwayat serta bukti transfer.

Status transfer harus membedakan stok yang masih berada di gudang asal,
sedang dikirim, dan sudah diterima.

### 7.9 Penjualan / POS

Fungsi: - Membuat transaksi penjualan cepat. - Memilih pelanggan atau
pelanggan umum sesuai izin. - Memilih cabang dan gudang sumber stok. -
Menambahkan produk, kuantitas, satuan, harga, diskon, dan biaya. -
Menampilkan ketersediaan stok. - Mendukung transaksi berdasarkan kg
maupun pcs/ekor tanpa mencampur satuan. - Menghitung subtotal dan total
secara otomatis. - Menyimpan transaksi dan mengurangi stok melalui
ledger saat transaksi diposting sesuai aturan. - Mencetak
nota/invoice. - Menghubungkan transaksi ke pembayaran dan pengiriman. -
Mendukung retur penjualan dengan alasan dan pemeriksaan stok.

Kebijakan penjualan kredit, batas diskon, persetujuan harga khusus, dan
pelanggan umum **Perlu Konfirmasi**.

### 7.10 Pelanggan, Pesanan, dan Pengiriman

-   Data pelanggan dan informasi kontak.
-   Riwayat transaksi dan saldo piutang.
-   Pesanan penjualan jika digunakan.
-   Penjadwalan pengiriman.
-   Penugasan petugas/pengemudi.
-   Daftar barang dan jumlah yang dikirim.
-   Status: disiapkan, dikirim, diterima, gagal, atau dikembalikan.
-   Bukti serah terima bila diperlukan.

Kebutuhan tanda tangan digital, foto bukti, dan pelacakan lokasi **Perlu
Konfirmasi**.

### 7.11 Pembayaran, Kas, dan Bank

-   Penerimaan pembayaran pelanggan.
-   Pembayaran pemasok.
-   Alokasi pembayaran ke satu atau beberapa invoice.
-   Pembayaran sebagian.
-   Pencatatan metode pembayaran dan akun kas/bank.
-   Pengeluaran operasional.
-   Transfer antar-akun jika diperlukan.
-   Saldo kas/bank dan riwayat transaksi.
-   Rekonsiliasi sesuai prosedur.

Bukti transfer berupa gambar atau struk **tidak otomatis membuktikan
dana telah diterima**. Status lunas harus dikonfirmasi oleh pengguna
berwenang atau melalui integrasi pembayaran yang benar-benar
tervalidasi.

### 7.12 Utang dan Piutang

-   Daftar tagihan pemasok.
-   Daftar tagihan pelanggan.
-   Jatuh tempo dan umur utang/piutang.
-   Pembayaran sebagian dan pelunasan.
-   Alokasi pembayaran.
-   Pengingat jatuh tempo.
-   Riwayat perubahan saldo.

### 7.13 Pengeluaran

-   Kategori biaya.
-   Tanggal, cabang, akun kas/bank, penerima, nominal, dan keterangan.
-   Lampiran bukti.
-   Alur persetujuan jika diperlukan.
-   Hubungan ke jurnal akuntansi.

### 7.14 Akuntansi dan Jurnal

-   Daftar akun (chart of accounts).
-   Jurnal umum.
-   Jurnal transaksi otomatis dari modul terkait.
-   Jurnal berpasangan debit/kredit.
-   Periode fiskal.
-   Penutupan/perlindungan periode.
-   Buku besar dan neraca saldo.
-   Laporan laba rugi dan arus kas sesuai rancangan akuntansi.

Setiap jurnal harus seimbang. Pemetaan akun otomatis untuk pembelian,
persediaan, produksi, HPP, penjualan, pembayaran, retur, dan biaya
**Perlu Konfirmasi** dengan akuntan/penanggung jawab keuangan.

### 7.15 Invoice, Nota, dan Dokumen

Sistem menghasilkan dokumen dari transaksi yang sudah tersimpan: -
Invoice penjualan. - Nota/struk penjualan. - Dokumen pembelian. - Bukti
penerimaan. - Bukti pembayaran. - Bukti transfer stok. - Dokumen lain
yang disetujui.

Fitur: - Nomor dokumen unik dan dibuat di sisi server/database. -
Pratinjau sebelum cetak. - Cetak ukuran A4. - Cetak printer thermal 80
mm dan 58 mm. - Simpan/unduh PDF. - Cetak ulang dari riwayat. -
Pencarian dokumen berdasarkan nomor, tanggal, pelanggan/pemasok, dan
cabang. - Template dokumen dengan identitas perusahaan/cabang, logo,
alamat, dan informasi kontak. - Lampiran dokumen tersimpan dengan akses
yang sesuai.

Nomor awal, pola penomoran, identitas legal, logo, dan format pajak
**Perlu Konfirmasi**.

### 7.16 Scan Nota dan OCR

Sumber input: - Kamera ponsel. - Unggah gambar. - Unggah PDF.

Alur: 1. Pengguna mengambil foto atau mengunggah dokumen. 2. File
disimpan secara privat. 3. OCR/AI Vision mengekstrak teks dan kandidat
data. 4. Sistem menampilkan hasil ekstraksi dengan tingkat
keyakinan/peringatan. 5. Pengguna memeriksa dan mengoreksi
pemasok/pelanggan, nomor nota, tanggal, item, jumlah, kg, satuan, harga,
subtotal, diskon, biaya, pajak jika tertulis, total, dan pembayaran. 6.
Sistem menghitung ulang serta memberi peringatan jika nilai tidak cocok.
7. Pengguna yang berwenang mengonfirmasi. 8. Data dihubungkan ke
transaksi yang tepat atau dibuat sebagai draft transaksi. 9. Transaksi
baru diposting hanya setelah pemeriksaan dan konfirmasi sesuai alur
bisnis.

Aturan wajib: - OCR tidak boleh mengarang data yang tidak terbaca. -
Data dengan keyakinan rendah ditandai untuk pemeriksaan. - Deteksi
kemungkinan dokumen duplikat. - Pemindaian tidak boleh otomatis
memposting stok. - Pemindaian bukti pembayaran tidak boleh otomatis
menandai pembayaran lunas. - Simpan dokumen asli dan riwayat
pemrosesan. - Pemrosesan OCR dilakukan di lingkungan server yang aman;
jangan menaruh API key AI di frontend.

### 7.17 Kualitas, Suhu, dan Keamanan Pangan

-   Pemeriksaan kualitas bahan baku dan hasil produksi.
-   Status lolos/tidak lolos pemeriksaan.
-   Catatan kondisi produk.
-   Catatan suhu dengan waktu, lokasi, dan petugas.
-   Pencatatan produk rusak/limbah.
-   Riwayat inspeksi yang terhubung ke batch.

Batas suhu, masa simpan, prosedur karantina, dan standar operasional
harus ditentukan oleh pihak usaha yang kompeten. Aplikasi hanya mencatat
aturan yang telah disetujui; aplikasi tidak boleh mengklaim sertifikasi
atau kepatuhan yang belum diverifikasi.

### 7.18 Pelacakan Batch (Traceability)

Sistem harus mampu menelusuri rantai: **Pemasok → penerimaan → batch
bahan baku → produksi → batch hasil produksi → gudang →
penjualan/pengiriman → pelanggan.**

Dari satu batch, pengguna berwenang dapat melihat: - Asal pemasok dan
dokumen penerimaan. - Waktu dan lokasi penerimaan. - Pemeriksaan
kualitas. - Proses produksi dan input/output. - Mutasi antar-gudang. -
Transaksi penjualan dan pengiriman terkait.

### 7.19 Laporan

Laporan operasional: - Pembelian per periode/pemasok/cabang. -
Penerimaan dan selisih. - Produksi dan yield. - Pemakaian bahan baku dan
hasil output. - Stok per produk/batch/gudang/cabang. - Kartu stok dan
mutasi. - Stok opname dan penyesuaian. - Transfer antar-gudang/cabang. -
Penjualan per periode/produk/pelanggan/cabang. - Retur dan pengiriman. -
Produk rusak dan limbah.

Laporan keuangan: - Penjualan dan pembelian. - HPP dan laba kotor. -
Laba rugi. - Arus kas. - Saldo kas dan bank. - Utang dan piutang. - Umur
utang/piutang. - Jurnal, buku besar, dan neraca saldo sesuai
konfigurasi.

Laporan harus memiliki filter periode, cabang, gudang, dan ekspor sesuai
hak akses. Definisi final tiap indikator dan format laporan **Perlu
Konfirmasi**.

### 7.20 Notifikasi dan Audit

Notifikasi dapat mencakup: - Transaksi menunggu persetujuan. -
Penerimaan/transfer belum selesai. - Stok minimum. - Selisih penerimaan
atau opname. - Dokumen OCR perlu ditinjau. - Utang/piutang mendekati
jatuh tempo. - Kegagalan proses atau sinkronisasi.

Audit log minimal mencatat pengguna, waktu, aksi, entitas, nilai
sebelum/sesudah bila sesuai, dan alasan perubahan. Data audit harus
dilindungi dari perubahan oleh pengguna biasa.

------------------------------------------------------------------------

## 8. Kebutuhan UI/UX dan Responsivitas

### 8.1 Prinsip desain

-   Mobile-first, modern, bersih, konsisten, dan mudah dipelajari.
-   Beranda mobile menggunakan kotak menu/grid seperti app launcher pada
    aplikasi modern.
-   Ikon mudah dikenali, label singkat, jarak antar-kontrol cukup.
-   Gunakan hierarki visual yang jelas, kartu ringkasan, warna status
    yang konsisten, dan tipografi terbaca.
-   Jangan menjejalkan seluruh fitur dalam satu layar; kelompokkan ke
    kategori dan halaman detail.
-   Hindari kontrol yang hanya muncul saat hover.

### 8.2 Beranda mobile

Komponen: - Header dengan logo/nama aplikasi, cabang aktif, notifikasi,
dan profil. - Ringkasan KPI yang relevan. - Grid menu utama berbentuk
kartu/kotak. - Menu pencarian atau akses cepat jika diperlukan. -
Aktivitas terbaru dan notifikasi penting.

Contoh menu utama: - Dashboard - Pembelian - Penerimaan - Produksi -
Persediaan - Transfer - Penjualan - Pelanggan - Pengiriman - Invoice -
Scan Nota - Keuangan - Utang - Piutang - Laporan - Master Data -
Karyawan - Pengaturan

Menu ditampilkan sesuai izin pengguna.

### 8.3 Navigasi bawah mobile

Navigasi bawah yang direncanakan: - Beranda - Operasional - Transaksi -
Laporan - Profil

Item dan struktur final **Perlu Konfirmasi** setelah prototipe diuji.

### 8.4 Pengelompokan submenu

**Operasional** - Pembelian ayam/bebek - Penerimaan - Produksi - Hasil
produksi - Stok gudang - Stok opname - Transfer cabang - Produk rusak -
Pemeriksaan kualitas

**Penjualan** - Penjualan baru - Daftar transaksi - Pelanggan -
Invoice/nota - Retur - Pengiriman - Piutang pelanggan

**Keuangan** - Kas - Bank - Pembayaran pemasok - Pembayaran pelanggan -
Pengeluaran - Utang - Piutang - Jurnal - Laba rugi - Arus kas

**Master Data** - Cabang - Gudang - Pemasok - Pelanggan - Produk -
Kategori - Satuan - Karyawan - Pengguna

### 8.5 Perilaku responsif

-   Ponsel kecil: grid 2 kolom bila ruang terbatas.
-   Ponsel standar: grid 3 kolom jika label tetap terbaca.
-   Tablet: 3--4 kolom sesuai lebar.
-   Desktop: sidebar, header, dashboard multi-kolom, dan tabel lengkap.
-   Formulir panjang disusun satu kolom di ponsel.
-   Modal di desktop dapat berubah menjadi bottom sheet/full-screen
    sheet di ponsel.
-   Tabel lebar berubah menjadi kartu/list pada layar kecil atau
    menyediakan tampilan alternatif yang mudah dibaca.
-   Filter kompleks dapat dibuka melalui filter sheet.
-   Tombol dan area sentuh harus nyaman digunakan, dengan target sekitar
    44 px bila memungkinkan.
-   Perhatikan safe area perangkat, keyboard virtual, dan orientasi
    layar.

### 8.6 Breakpoint awal

Breakpoint merupakan titik awal yang harus diuji, bukan batas kaku: - Di
bawah 480 px: ponsel kecil. - 480--767 px: ponsel besar. - 768--1023 px:
tablet. - 1024 px ke atas: desktop/laptop.

### 8.7 Komponen UI yang disarankan

-   `MobileHome`
-   `AppLauncherGrid`
-   `AppMenuCard`
-   `BottomNavigation`
-   `MobileHeader`
-   `MobilePageHeader`
-   `ResponsiveDataCard`
-   `MobileFilterSheet`
-   `MobileFormLayout`
-   `DesktopSidebar`

Komponen harus mengikuti sistem desain bersama agar konsisten.

------------------------------------------------------------------------

## 9. Arsitektur dan Teknologi

### 9.1 Teknologi yang dipilih dalam diskusi

-   Frontend: React + TypeScript.
-   Backend/data: Supabase.
-   Database: PostgreSQL di Supabase.
-   Autentikasi: Supabase Auth.
-   Penyimpanan file: Supabase Storage.
-   Version control: GitHub.
-   Hosting: Vercel.
-   Bentuk aplikasi: web responsif, dengan opsi PWA.

Versi framework, library UI, dan pola server/API final **Perlu
Konfirmasi** berdasarkan proyek yang sedang dibangun di Google AI
Studio.

### 9.2 Prinsip arsitektur

-   Modular berdasarkan domain bisnis.
-   Pemisahan komponen UI, logika bisnis, akses data, dan validasi.
-   Operasi sensitif dilakukan melalui backend/server-side functions
    atau mekanisme aman yang sesuai.
-   Gunakan transaksi database untuk proses yang harus atomik.
-   Gunakan constraint, foreign key, dan validasi database untuk menjaga
    integritas.
-   Sediakan migrasi SQL bertahap dan dapat diulang secara terkontrol.
-   Hindari logika bisnis penting yang hanya berjalan di browser.

### 9.3 Keamanan kredensial

-   Jangan pernah menaruh Supabase `service_role` key atau password
    database di frontend.
-   Jangan commit secret/API key ke GitHub.
-   Simpan secret di environment variables/secret manager pada layanan
    server/hosting.
-   Kunci publik Supabase hanya digunakan sesuai rancangan keamanan dan
    tetap dilindungi RLS.
-   Jangan meminta pengguna membagikan secret melalui chat atau
    screenshot publik.

### 9.4 RLS dan otorisasi

-   Aktifkan dan uji RLS pada tabel yang berisi data bisnis.
-   Kebijakan harus memeriksa identitas pengguna, peran, cabang, dan
    kewenangan.
-   Jangan mengandalkan filter frontend sebagai pengamanan.
-   Uji skenario akses lintas cabang, akses tanpa izin, dan pengguna
    nonaktif.
-   Aksi administratif dan persetujuan penting harus dibatasi.

### 9.5 Penyimpanan file

-   Gunakan bucket privat untuk dokumen bisnis.
-   Akses file melalui kebijakan dan signed URL dengan masa berlaku yang
    sesuai.
-   Simpan metadata dokumen di database.
-   Batasi jenis dan ukuran file, validasi file, dan catat siapa yang
    mengunggah.
-   Dokumen sensitif tidak boleh tersedia melalui URL publik tanpa
    alasan dan persetujuan.

------------------------------------------------------------------------

## 10. Model Data Awal

Daftar berikut adalah rancangan awal untuk dibahas dan dimigrasikan
bertahap. Struktur final, tipe data, relasi, indeks, dan constraint
harus dirancang serta diuji oleh pengembang.

### 10.1 Organisasi dan akses

-   `companies`
-   `branches`
-   `warehouses`
-   `profiles`
-   `roles`
-   `permissions`
-   `role_permissions`
-   `user_branch_access`
-   `user_roles`

### 10.2 Master data

-   `suppliers`
-   `customers`
-   `product_categories`
-   `products`
-   `units`
-   `unit_conversions`
-   `price_lists`
-   `product_prices`
-   `employees`

### 10.3 Pembelian dan penerimaan

-   `purchases`
-   `purchase_items`
-   `goods_receipts`
-   `goods_receipt_items`
-   `supplier_payments`
-   `supplier_payment_allocations`

### 10.4 Produksi dan kualitas

-   `production_batches`
-   `production_inputs`
-   `production_outputs`
-   `production_costs`
-   `quality_inspections`
-   `quality_checks`
-   `temperature_logs`
-   `waste_records`
-   `batch_traceability`

### 10.5 Persediaan

-   `product_batches`
-   `inventory_movements`
-   `inventory_balances` (rekap/proyeksi saldo, bukan pengganti ledger)
-   `stock_opnames`
-   `stock_opname_items`
-   `stock_adjustments`
-   `stock_transfers`
-   `stock_transfer_items`

### 10.6 Penjualan dan distribusi

-   `sales`
-   `sales_items`
-   `sales_orders`
-   `deliveries`
-   `delivery_items`
-   `sales_returns`
-   `sales_return_items`
-   `customer_payments`
-   `customer_payment_allocations`

### 10.7 Keuangan dan akuntansi

-   `cash_accounts`
-   `bank_accounts`
-   `expenses`
-   `expense_categories`
-   `accounts`
-   `journals`
-   `journal_lines`
-   `fiscal_periods`

### 10.8 Dokumen dan OCR

-   `documents`
-   `document_templates`
-   `document_sequences`
-   `scanned_documents`
-   `ocr_extractions`
-   `ocr_extraction_items`
-   `document_transaction_links`
-   `document_processing_logs`

### 10.9 Sistem dan kontrol

-   `audit_logs`
-   `notifications`
-   `document_attachments`
-   `idempotency_keys`
-   `app_settings`

------------------------------------------------------------------------

## 11. Aturan Integritas Transaksi yang Wajib

### 11.1 Idempotensi

-   Setiap operasi posting transaksi yang berpotensi dikirim ulang harus
    memiliki kunci idempotensi.
-   Klik ganda, refresh, retry jaringan, atau pengiriman ulang tidak
    boleh menggandakan transaksi, stok, atau jurnal.
-   Kunci unik dan pemeriksaan duplikasi dilakukan di backend/database.

### 11.2 Posting dan pembatalan

-   Pisahkan status draft dari posted/final.
-   Transaksi yang telah diposting tidak boleh dihapus langsung.
-   Koreksi dilakukan dengan pembatalan/reversal atau transaksi
    penyesuaian yang terhubung ke transaksi asal.
-   Catat alasan, pengguna, waktu, dan referensi transaksi asal.

### 11.3 Nomor dokumen

-   Nomor invoice/nota harus dibuat di server/database.
-   Terapkan unique constraint.
-   Hindari nomor dokumen yang hanya dihitung di browser.
-   Format nomor dan reset periodik **Perlu Konfirmasi**.

### 11.4 Konsistensi stok dan keuangan

-   Posting transaksi stok dan jurnal terkait harus atomik sejauh
    memungkinkan.
-   Jika salah satu proses gagal, sistem harus memiliki mekanisme
    rollback atau status gagal yang dapat dipulihkan.
-   Saldo stok dan saldo keuangan harus dapat direkonsiliasi dengan
    ledger sumber.

------------------------------------------------------------------------

## 12. Kebutuhan Nonfungsional

### 12.1 Kinerja

-   Halaman utama dan transaksi umum harus responsif pada jaringan
    operasional yang wajar.
-   Gunakan pagination, pencarian server-side, indeks database, dan
    pemuatan data seperlunya.
-   Hindari memuat seluruh riwayat transaksi sekaligus.

Target waktu respons numerik **Perlu Konfirmasi** setelah pengujian pada
data realistis.

### 12.2 Keandalan

-   Transaksi penting tidak boleh hilang saat terjadi refresh atau
    gangguan jaringan.
-   Berikan status proses yang jelas.
-   Tangani kegagalan jaringan dan retry dengan aman.
-   Sediakan backup dan prosedur pemulihan.

### 12.3 Keamanan

-   Autentikasi dan otorisasi server-side.
-   RLS pada tabel terkait.
-   Validasi input di frontend dan backend.
-   Proteksi file dan secret.
-   Audit log untuk aksi penting.
-   Sesi dan akses pengguna dapat dicabut.

### 12.4 Kemudahan penggunaan

-   Antarmuka konsisten dan mudah dipelajari.
-   Bahasa utama Indonesia.
-   Format tanggal, waktu, angka, dan mata uang mengikuti konfigurasi
    Indonesia.
-   Formulir memberi validasi dan pesan kesalahan yang jelas.
-   Tindakan berisiko memerlukan konfirmasi.

### 12.5 Kompatibilitas

-   Browser modern di Android, iOS, Windows, dan macOS.
-   Layout diuji pada ponsel, tablet, laptop, dan desktop.
-   Dukungan printer bergantung pada browser, perangkat, dan konfigurasi
    printer.

### 12.6 Skalabilitas

-   Mendukung pertumbuhan transaksi, cabang, gudang, produk, dan
    pengguna.
-   Gunakan pagination dan desain indeks yang tepat.
-   Hindari query yang tidak dibatasi pada tabel transaksi besar.

------------------------------------------------------------------------

## 13. Tahapan Implementasi

Tahapan berikut merupakan urutan yang disarankan. Setiap tahap harus
dikerjakan dan diverifikasi dalam **satu proyek aplikasi yang sama**,
bukan membuat proyek baru untuk setiap prompt.

### Tahap 1 --- Fondasi dan UI

-   Struktur React + TypeScript.
-   Design system dan navigasi.
-   Dashboard dan halaman awal.
-   Layout desktop dan mobile.
-   Data demo diberi label jelas.
-   Belum mengklaim transaksi nyata terhubung sebelum backend siap.

### Tahap 2 --- Database dan keamanan

-   Skema PostgreSQL dan migrasi SQL bertahap.
-   Supabase Auth.
-   Profil, peran, izin, cabang, dan gudang.
-   RLS dan storage privat.
-   Audit log dan idempotency.
-   Pengujian akses lintas cabang.

### Tahap 3 --- Master data, pembelian, penerimaan, produksi, stok

-   Master data.
-   Pembelian dan penerimaan.
-   Batch produksi dan output.
-   HPP awal sesuai kebijakan yang disetujui.
-   Inventory movement ledger.
-   Transfer, opname, dan kontrol kualitas.

### Tahap 4 --- Penjualan dan keuangan

-   POS/penjualan.
-   Pelanggan, retur, pengiriman.
-   Pembayaran pelanggan dan pemasok.
-   Pengeluaran, kas, dan bank.
-   Jurnal akuntansi dan laporan dasar.

### Tahap 5 --- Dokumen, OCR, laporan, dan kontrol

-   Invoice/nota dan template cetak.
-   Ekspor PDF.
-   Scan dokumen/OCR dengan review.
-   Laporan lanjutan.
-   Traceability.
-   Notifikasi, audit, dan dokumentasi backup.

### Tahap 6 --- Pengujian dan rilis

-   Uji integrasi.
-   Uji keamanan/RLS.
-   Uji beban data realistis.
-   Uji ponsel dan desktop.
-   Perbaikan bug.
-   Integrasi GitHub.
-   Deploy Vercel dengan environment variables yang aman.
-   Dokumentasi penggunaan dan pemeliharaan.

**Catatan:** Penyebutan GitHub/Vercel dalam dokumen ini bukan bukti
bahwa repository atau deployment sudah dibuat. Koneksi akun, izin,
konfigurasi environment, migrasi, dan proses deploy tetap harus
dilakukan serta diverifikasi.

------------------------------------------------------------------------

## 14. Strategi Pengujian

### 14.1 Pengujian fungsional

-   Buat, ubah, dan cari master data.
-   Alur pembelian hingga penerimaan.
-   Penerimaan sebagian dan selisih.
-   Produksi dengan beberapa output.
-   Perhitungan yield dan HPP.
-   Stok masuk/keluar, transfer, dan opname.
-   Penjualan berdasarkan kg dan pcs/ekor.
-   Retur dan pengiriman.
-   Pembayaran sebagian dan pelunasan.
-   Jurnal seimbang.
-   Invoice dan cetak ulang.
-   OCR dengan hasil terbaca, tidak terbaca, dan total yang tidak cocok.

### 14.2 Pengujian keamanan

-   Pengguna cabang A tidak dapat mengakses data cabang B tanpa izin.
-   Pengguna tanpa peran tidak dapat melakukan aksi terlarang.
-   File privat tidak dapat diakses tanpa otorisasi.
-   Secret tidak muncul pada bundle frontend atau repository.
-   Aksi sensitif tercatat di audit log.

### 14.3 Pengujian integritas

-   Klik ganda tidak membuat transaksi ganda.
-   Retry tidak menggandakan mutasi stok/jurnal.
-   Transaksi posted tidak dapat dihapus langsung.
-   Reversal mengembalikan dampak secara terkontrol.
-   Total transaksi dan jurnal dapat direkonsiliasi.
-   Saldo stok sama dengan hasil ledger sesuai aturan.

### 14.4 Pengujian perangkat dan ukuran layar

Uji minimal pada lebar: - 360 px - 375 px - 390 px - 430 px - 768 px -
1024 px - 1440 px

Pastikan tidak ada horizontal overflow yang tidak diperlukan, tombol
dapat disentuh, form dapat digunakan dengan keyboard virtual, dan tabel
memiliki alternatif mobile.

------------------------------------------------------------------------

## 15. Kriteria Penerimaan (Acceptance Criteria)

Produk dapat dinilai memenuhi PRD awal apabila:

1.  Pengguna dapat login dan melihat menu sesuai peran.
2.  Akses data lintas cabang dibatasi oleh backend/RLS.
3.  Master data dapat dikelola dan dipakai transaksi.
4.  Pembelian dapat dihubungkan dengan penerimaan.
5.  Penerimaan terkonfirmasi membuat mutasi stok yang benar.
6.  Produksi dapat mencatat input dan beberapa output.
7.  Hasil, susut, limbah, dan biaya dapat ditelusuri.
8.  Stok dapat dilihat per produk, batch, dan gudang.
9.  Transfer dan opname memiliki riwayat serta kontrol persetujuan.
10. Penjualan membedakan kg dan pcs/ekor dengan benar.
11. Pembayaran dapat dialokasikan ke invoice dan mendukung pembayaran
    sebagian.
12. Jurnal seimbang dan dapat ditelusuri ke transaksi sumber.
13. Invoice/nota dapat dipratinjau dan dicetak pada format yang
    disediakan.
14. OCR hanya menghasilkan draft/hasil ekstraksi untuk diperiksa
    manusia, tidak otomatis memposting transaksi.
15. Riwayat batch dapat ditelusuri dari pemasok hingga pelanggan.
16. Laporan memiliki filter yang sesuai hak akses.
17. Klik ganda atau retry tidak menggandakan transaksi.
18. Koreksi transaksi posted dilakukan melalui reversal/penyesuaian
    dengan audit trail.
19. Antarmuka dapat digunakan pada ponsel, tablet, dan desktop.
20. Dokumentasi konfigurasi, migrasi, pengujian, dan deployment
    tersedia.

Kriteria ini harus diuji pada data uji yang representatif sebelum sistem
digunakan untuk transaksi riil.

------------------------------------------------------------------------

## 16. Risiko dan Mitigasi

  -----------------------------------------------------------------------
  Risiko                  Dampak                  Mitigasi
  ----------------------- ----------------------- -----------------------
  Stok hanya disimpan     Riwayat dan saldo tidak Gunakan inventory
  sebagai angka yang      dapat dipercaya         movement ledger
  dapat ditimpa                                   

  Satuan ekor, pcs, dan   Salah stok, harga, dan  Validasi satuan dan
  kg tercampur            laporan                 konversi eksplisit

  Posting ganda karena    Stok dan jurnal ganda   Idempotency key dan
  klik/retry                                      constraint database

  RLS hanya diterapkan di Kebocoran data          RLS dan otorisasi
  UI                      antar-cabang            backend, lalu uji

  OCR salah membaca nota  Salah transaksi         Review manusia dan
                                                  validasi total

  Bukti transfer dianggap Status pembayaran salah Konfirmasi penerimaan
  sebagai dana masuk                              dana oleh pihak
                                                  berwenang

  HPP tidak konsisten     Laporan laba keliru     Tetapkan metode biaya
                                                  dan dokumentasikan

  Secret masuk ke         Risiko keamanan         Environment variables
  GitHub/frontend                                 dan pemeriksaan
                                                  repository

  UI mobile terlalu padat Pengguna sulit          App launcher,
                          bertransaksi            pengelompokan menu,
                                                  bottom sheet, dan uji
                                                  perangkat

  Deployment dianggap     Sistem gagal saat       Checklist migrasi, env,
  selesai padahal belum   digunakan               RLS, dan smoke test
  diuji                                           
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 17. Keputusan yang Masih Perlu Konfirmasi

Sebelum transaksi riil dan laporan keuangan dijadikan dasar keputusan,
konfirmasikan:

1.  Identitas perusahaan yang harus tampil di invoice/nota.
2.  Alamat, kontak, logo, dan informasi legal yang ditampilkan.
3.  Daftar cabang dan gudang beserta hubungan organisasinya.
4.  Daftar final peran dan matriks izin.
5.  Alur persetujuan pembelian, diskon, pembayaran, stok opname, dan
    transfer.
6.  Daftar produk/SKU dan kategori final.
7.  Aturan satuan, konversi, pembulatan, dan toleransi berat.
8.  Metode valuasi persediaan.
9.  Metode alokasi biaya produksi dan perhitungan HPP.
10. Perlakuan susut, limbah, produk rusak, dan hasil samping.
11. Aturan harga jual, diskon, harga khusus, dan penjualan kredit.
12. Format dan pola nomor invoice/nota.
13. Metode pembayaran dan daftar akun kas/bank.
14. Chart of accounts dan pemetaan jurnal.
15. Definisi laporan dan indikator dashboard.
16. Prosedur kualitas, suhu, masa simpan, dan karantina.
17. Kebutuhan integrasi printer, timbangan, barcode, bank, atau payment
    gateway.
18. Kebijakan backup, retensi dokumen, dan pemulihan data.
19. Target performa dan jumlah pengguna serentak.
20. Apakah PWA/offline terbatas dibutuhkan dan proses apa yang boleh
    berjalan offline.

------------------------------------------------------------------------

## 18. Panduan Penggunaan PRD di Google AI Studio

Gunakan dokumen ini sebagai sumber acuan utama saat membangun aplikasi.

Instruksi untuk AI developer: - Baca seluruh PRD sebelum mengubah
kode. - Pertahankan satu proyek dan struktur yang sudah ada; jangan
membuat ulang aplikasi dari nol tanpa persetujuan. - Implementasikan
secara bertahap sesuai tahapan pada PRD. - Jangan menghapus fitur yang
sudah berjalan. - Jangan mengarang keputusan yang ditandai **Perlu
Konfirmasi**; gunakan konfigurasi sementara yang jelas atau minta
keputusan. - Bedakan fitur yang sudah selesai, masih berupa UI/demo,
sudah terhubung database, dan sudah diuji. - Jangan memasukkan data demo
ke transaksi produksi. - Buat migrasi database yang aman dan
dokumentasikan setiap perubahan skema. - Jangan pernah menaruh service
role key, password database, atau secret AI di frontend/repository. -
Jalankan tes setelah setiap tahap dan laporkan hasilnya. - Sebelum
mengubah modul inti, jelaskan file yang akan diubah dan dampaknya. -
Prioritaskan integritas data, keamanan, dan konsistensi transaksi
dibanding sekadar tampilan. - Jangan menyatakan aplikasi siap produksi
sebelum alur utama, RLS, migrasi, backup, dan pengujian diverifikasi.

## 19. Definisi Status Pekerjaan

Setiap modul harus diberi salah satu status berikut: - **Belum
Dibangun** --- belum ada implementasi. - **UI Saja** --- tampilan ada,
belum terhubung ke data nyata. - **Terhubung Database** --- sudah
membaca/menulis data. - **Terintegrasi** --- alur antar-modul sudah
terhubung. - **Lulus Pengujian** --- skenario pengujian terkait sudah
berhasil. - **Siap Produksi** --- keamanan, integritas, backup,
monitoring, dan proses operasional telah diverifikasi.

Jangan menyamakan tampilan yang sudah muncul dengan fitur yang sudah
berfungsi penuh.

------------------------------------------------------------------------

## 20. Snapshot Implementasi (15 November 2026)

Status berikut mencatat kondisi kode di repository, bukan bukti sistem telah
diterapkan atau siap dipakai pada transaksi riil. Status dapat berubah setelah
migrasi Supabase, konfigurasi proyek, dan skenario penerimaan dijalankan.

| Area | Status saat ini | Catatan |
| --- | --- | --- |
| Antarmuka React/TypeScript, navigasi peran, dan PWA app shell | Terintegrasi | Build produksi berhasil; cache offline hanya app shell, mutasi tidak diantrikan. |
| Auth, setup workspace, profil perusahaan/cabang/gudang, RLS, Storage privat, audit, dan idempotency | Terhubung Database | Migrasi inti, operasi, pengaturan, dan rata-rata tertimbang diterapkan pada proyek Supabase terpilih; bootstrap perusahaan, cabang, gudang, serta Owner tersedia. Skenario RLS masih perlu diuji dengan akun lintas peran/cabang. |
| Master data produk, satuan, pemasok, pelanggan | Terintegrasi | CRUD dan arsip; perusahaan/cabang/gudang serta akun awal perlu bootstrap tepercaya. |
| Pembelian, persetujuan, penerimaan parsial/penuh, ledger stok | Terintegrasi | Belum diuji dengan PostgreSQL/Supabase lokal atau proyek nyata. |
| Transfer antar gudang/cabang, persetujuan, kirim, terima, dan selisih | Terintegrasi | Mutasi ke/dari ledger; alasan wajib untuk selisih. Belum diuji di database. |
| Stok opname, pengajuan, persetujuan, dan penyesuaian ledger | Terintegrasi | Hitung per batch bila stok berbatches; stok positif baru masuk karantina. Nilai penyesuaian biaya belum dijurnal. |
| Produksi multi-output, inspeksi kualitas, traceability batch | Terintegrasi | Biaya input memakai rata-rata tertimbang dan dialokasikan ke output menurut berat satuan dasar. Yield lintas satuan, overhead, dan perlakuan biaya susut/limbah tetap perlu keputusan. |
| Penjualan, alokasi pembayaran pelanggan, invoice/cetak | Terintegrasi | Retur tersedia; reversal transaksi belum tersedia. |
| Retur penjualan dan pengiriman | Terintegrasi | Batch retur dikarantina; status dan penerima pengiriman dicatat. Refund/kredit dan lampiran bukti belum otomatis. |
| Scan dokumen/OCR dan review manusia | Terintegrasi | Edge Function dan secret belum diterapkan; hasil OCR tidak mem-posting transaksi. |
| Laporan penjualan, pembelian, produksi, stok, mutasi, ekspor CSV | Terintegrasi | Laporan keuangan memakai jurnal; ringkasan nilai persediaan dan biaya rata-rata tersedia untuk administrator/keuangan. Transaksi lama sebelum kebijakan tidak dijurnal ulang; stok opening tanpa harga penerimaan tercatat bernilai nol sampai divaluasi. |
| Utang pemasok, kas/bank, pengeluaran, jurnal, laporan finansial | Terintegrasi | Perlu chart of accounts, periode, akun kas/bank, dan pemetaan. Jurnal HPP otomatis terbentuk jika akun persediaan/HPP dan periode fiskal tersedia; retur/refund dan penyesuaian stok belum dijurnal otomatis. |
| Piutang pelanggan dan umur tagihan | Terhubung Database | Laporan sisa tagihan, umur 1–30/31–60/61–90/>90 hari, tanggal jatuh tempo, ekspor CSV, dan akses invoice untuk pembayaran. Pengingat email/WhatsApp belum tersedia. |
| Direktori karyawan, peran, dan akses cabang | Terhubung Database | CRUD data karyawan serta pengaturan peran/cabang untuk akun Auth yang sudah diundang. Undangan akun tetap dilakukan lewat Dashboard Supabase. |
| Pengaturan perusahaan, cabang, gudang, dan audit | Terhubung Database | Identitas perusahaan dapat diubah, cabang/gudang dapat ditambah, serta audit log ditampilkan. Upload logo, pengarsipan, dan preferensi notifikasi belum tersedia. |
| Notifikasi dalam aplikasi | Terintegrasi | Inbox per pengguna dan notifikasi persetujuan/OCR/transfer/retur/pengiriman/stok minimum. Email dan push belum tersedia. |
| Skrip backup logical dan panduan pemulihan | Terintegrasi | Mencakup schema `public/private`; Auth, Storage objects, secret, dan konfigurasi proyek harus dipulihkan terpisah. Backup platform belum diverifikasi. |
| Uji RLS, integrasi database, dan perangkat | Belum Dibangun | Perlu lingkungan Supabase dan skenario data uji representatif. |

Verifikasi yang sudah dilakukan pada tanggal snapshot: migrasi Supabase diterapkan
ke proyek target dan `npm run build` berhasil (TypeScript dan bundling Vite).
Belum ada automated test script dalam package. Build dan keberhasilan penerapan
migrasi tidak memverifikasi semua alur RPC/RLS, Edge Function, skrip backup,
atau alur UI terhadap backend nyata. Aplikasi belum berstatus **Lulus Pengujian** atau
**Siap Produksi**.

------------------------------------------------------------------------

**Akhir dokumen PRD --- AGI AYAM & BEBEK ERP**
