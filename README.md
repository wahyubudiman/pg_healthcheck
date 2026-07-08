# PostgreSQL Health Check & Assessment Script

Script ini digunakan untuk melakukan audit kesehatan komprehensif pada sistem operasi (OS), hardware host, dan basis data PostgreSQL. Laporan hasil akhir akan digenerate secara otomatis dalam format **Markdown (.md)** untuk mempermudah pembacaan.

Script ini dikembangkan dari `pg_healthcheck.sh` (Version: 1.2; https://github.com/francs/PostgreSQL-healthcheck-script) dan telah ditambahkan banyak perintah diagnostik sistem operasi Linux serta query analisis PostgreSQL kustom (termasuk penyesuaian untuk lingkungan CloudNativePG/Kubernetes dan kontainer Docker).

---

## Fitur Unggulan Terbaru

1. **Penamaan File Output Dinamis (Anti-Overwrite):**
   Output laporan secara otomatis menggunakan prefix tanggal, waktu, dan hostname server pelaksana (`[YYYYMMDD]_[HHMMSS]_[HOSTNAME]_hc.md`). Hal ini mencegah file laporan lama tertimpa ketika script dijalankan berulang kali.

2. **Bypass Mode untuk Database Docker & Remote:**
   Jika script dijalankan di host VPS dan tidak mendeteksi PostgreSQL lokal (karena PostgreSQL berjalan di dalam kontainer Docker atau di server remote), script akan menawarkan opsi **Docker/Remote Database**. Pada mode ini:
   * **Bypass File `postmaster.pid`:** Script tidak akan mati/crash karena mendeteksi file pid kosong.
   * **Bypass `su - postgres` & `id -a postgres`:** Mencegah script meminta password sistem operasi `postgres` yang dapat memicu `su: Authentication failure`.
   * **Bypass File Konfigurasi Fisik:** Melewati pembacaan fisik file `postgresql.conf`/`pg_hba.conf` yang berada di dalam kontainer/remote, namun **tetap mengaudit 95%+ statistik performa database** via query SQL (psql).

---

## Prasyarat & Kebutuhan Sistem

### 1. Izin Akses (Permissions)
* Script ini **direkomendasikan dijalankan sebagai user `root`** (menggunakan `sudo`) jika ingin melakukan audit OS & hardware host secara lengkap (`dmidecode`, `lshw`, konfigurasi LVM, dll.).
* Jika dijalankan sebagai user biasa (non-root), bagian audit hardware tetap berjalan tetapi akan memunculkan beberapa pesan *Permission Denied* pada tool sistem. Audit database PostgreSQL-nya sendiri akan tetap berjalan normal 100%.

### 2. Dependensi Paket Linux (Untuk Audit OS/Hardware Host)
Pastikan paket-paket berikut terpasang di sistem operasi host Anda:
* `lsscsi`, `lshw`, `sysfsutils`, `sg3_utils`, `numactl`, `dmidecode`, `ethtool`, `hwinfo`
* `sysstat`, `lsof`, `net-tools`, `psmisc`, `setools-console`, `policycoreutils-python-utils`

### 3. Ekstensi PostgreSQL
* Sangat direkomendasikan untuk mengaktifkan ekstensi `pg_stat_statements` di PostgreSQL agar script dapat melakukan analisis performa query (DML terberat, CPU load, dsb.) secara optimal.

---

## Cara Menggunakan

### Langkah 1: Persiapan awal (Opsional)
Pastikan tidak ada file kunci/pid sisa dari eksekusi sebelumnya:
```bash
rm -f hc.pid hc.log.tmp
```

### Langkah 2: Jalankan Script
Gunakan perintah `sudo` atau jalankan langsung dari terminal VPS Anda:
```bash
# Menjalankan sebagai root (Direkomendasikan untuk audit hardware lengkap)
sudo ./hc-md.sh

# ATAU menjalankan sebagai user biasa (Aman untuk audit Docker/Remote DB)
./hc-md.sh
```

### Langkah 3: Isi Prompt Interaktif

1. **Postgres Cluster Owner (Linux User):** Tentukan nama user OS yang menjalankan proses PostgreSQL (default: `postgres`).
2. **Docker / Remote Bypass Prompt:** (Hanya muncul jika tidak terdeteksi PostgreSQL lokal di OS host) 
   * Ketik **`Y`** jika database berjalan di dalam **Docker kontainer** atau **Server Remote**.
3. **Host to Connect:** IP/Host database (default: `127.0.0.1`). *(Gunakan `127.0.0.1` jika kontainer Docker dipetakan portnya ke host localhost).*
4. **Port to Connect:** Port database (default: `5432`).
5. **Superuser name:** Nama user superuser database (default: `postgres`).
6. **Password:** Sandi database superuser. *(Wajib diisi dengan benar jika menggunakan mode Docker/Remote karena koneksi terjalin lewat port TCP/IP).*
7. **Database to Connect:** Nama database awal untuk melakukan koneksi awal (default: `postgres`).

---

## Hasil Output Laporan

Setelah proses audit selesai (memakan waktu beberapa menit tergantung beban database), script akan mem-parsing seluruh data diagnostik menjadi file laporan tunggal:

* **`[tanggal]_[jam]_[hostname]_hc.md`**: File laporan kesehatan akhir dalam format Markdown (misalnya: `20260708_115318_VM-16-180-opencloudos_hc.md`).

Anda dapat memindahkan file laporan ini ke folder dokumentasi Anda atau membukanya dengan Markdown viewer/aplikasi editor (seperti VS Code atau Obsidian) untuk melihat visualisasi laporan yang rapi.


