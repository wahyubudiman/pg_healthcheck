# PostgreSQL Health Check & Assessment Script

Script ini digunakan untuk melakukan audit kesehatan komprehensif pada sistem operasi (OS), hardware host, dan basis data PostgreSQL. Laporan hasil akhir akan digenerate secara otomatis dalam format **Markdown (.md)** untuk mempermudah pembacaan.

Script ini dikembangkan dari `pg_healthcheck.sh` (Version: 1.2; https://github.com/francs/PostgreSQL-healthcheck-script) dan telah ditambahkan banyak perintah diagnostik sistem operasi Linux serta query analisis PostgreSQL kustom (termasuk penyesuaian untuk lingkungan CloudNativePG/Kubernetes).

---

## Prasyarat & Kebutuhan Sistem

### 1. Izin Akses (Permissions)
* Script ini **harus dijalankan sebagai user `root`** (menggunakan `sudo`) karena memerlukan akses ke utilitas sistem tingkat rendah seperti `dmidecode`, `lshw`, `lspci`, konfigurasi LVM, dan info hardware lainnya.

### 2. Dependensi Paket Linux
Untuk mendapatkan informasi hardware, memori, disk, dan jaringan yang lengkap, pastikan paket-paket berikut sudah terinstall di sistem operasi:
* `lsscsi`, `lshw`, `sysfsutils`, `sg3_utils`, `numactl`, `dmidecode`, `ethtool`, `hwinfo`
* `sysstat`, `lsof`, `net-tools`, `psmisc`, `setools-console`, `policycoreutils-python-utils`

### 3. Ekstensi PostgreSQL
* Sangat direkomendasikan untuk mengaktifkan ekstensi `pg_stat_statements` di PostgreSQL agar script dapat melakukan analisis performa query (DML terlambat, CPU load, dsb.) secara optimal.

---

## Cara Menggunakan

### Langkah 1: Persiapan awal (Opsional)
Pastikan tidak ada file kunci/pid sisa dari eksekusi sebelumnya:
```bash
rm -f hc.pid hc.log.tmp
```

### Langkah 2: Jalankan Script
Gunakan perintah `sudo` untuk mengeksekusi script:
```bash
sudo ./hc-md.sh
```

### Langkah 3: Isi Prompt Interaktif
Selama eksekusi, script akan menanyakan beberapa konfigurasi interaktif. Anda dapat menekan **Enter** untuk menggunakan nilai bawaan (default):

1. **Postgres Cluster Owner (Linux User):** Masukkan nama user OS yang menjalankan proses PostgreSQL (default: `postgres`).
2. **PGDATA Path:** (Hanya ditanyakan jika terdeteksi lebih dari 1 kluster PG berjalan di mesin tersebut) Tentukan path direktori data PG yang ingin diperiksa.
3. **Host to Connect:** IP/Host database (default: `127.0.0.1`).
4. **Port to Connect:** Port database (default: `5432`).
5. **Superuser name:** Nama user superuser database (default: `postgres`).
6. **Password:** Sandi untuk user superuser (input disembunyikan/hidden demi keamanan).
7. **Database to Connect:** Nama database awal untuk melakukan koneksi awal (default: `postgres`).

---

## Hasil Output Laporan

Setelah proses audit selesai (memakan waktu beberapa menit tergantung beban database), script akan mem-parsing seluruh data diagnostik menjadi file laporan tunggal:

* **`[tanggal]_[jam]_[hostname]_hc.md`**: File laporan kesehatan akhir dalam format Markdown (misalnya: `20260708_092530_my-server_hc.md`).

Anda dapat memindahkan file laporan ini ke folder dokumentasi Anda atau membukanya dengan Markdown viewer/aplikasi editor (seperti VS Code atau Obsidian) untuk melihat visualisasi laporan yang rapi.

