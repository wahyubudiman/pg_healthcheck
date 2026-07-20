# PostgreSQL Health Check & Assessment Script

Script ini digunakan untuk melakukan audit kesehatan komprehensif pada sistem operasi (OS), hardware host, dan basis data PostgreSQL. Laporan hasil akhir akan digenerate secara otomatis dalam format **Markdown (.md)** untuk mempermudah pembacaan.

Script ini dikembangkan dari `pg_healthcheck.sh` (Version: 1.2; https://github.com/francs/PostgreSQL-healthcheck-script) dan telah ditambahkan banyak perintah diagnostik sistem operasi Linux serta query analisis PostgreSQL kustom (termasuk penyesuaian untuk lingkungan CloudNativePG/Kubernetes dan kontainer Docker).

---

## Variasi Script Healthcheck

1. **`hc-md.sh`**: Script audit standar untuk host Linux / PostgreSQL tradisional atau remote/Docker dengan mode prompt & env var.
2. **`hc-docker.sh`**: **[TERBARU]** Script spesifik untuk PostgreSQL yang berjalan di kontainer Docker. Mendukung pengumpulan statistik kontainer (`docker inspect`, `docker stats`, `docker logs`) serta eksekusi query non-interaktif via TCP/IP atau `docker exec`.
3. **`hc-cnpg.sh`**: Script spesifik untuk PostgreSQL yang dikelola oleh CloudNativePG (CNPG) di Kubernetes.

---

## Fitur Unggulan Script `hc-docker.sh` (Spesifik Docker)

* **Otomatisasi Non-Interaktif & AI-Friendly:** Mendukung flag CLI (`-c`, `-H`, `-P`, `-u`, `-w`, `-d`, `-o`, `-e`) serta variabel lingkungan (`DOCKER_CONTAINER`, `PGHOST`, `PGPORT`, `PGUSR`, `PGPASSWORD`, `DBNAME`).
* **Metrik Kontainer Docker:** Mengaudit status kontainer, penggunaan CPU & Memory (`docker stats`), pemetaan port, volume mount, serta log error kontainer terbaru.
* **Dual Execution Mode:** Otomatis mencoba koneksi jaringan TCP/IP (`PGHOST:PGPORT`), dan jika dipasang flag `-e` atau koneksi TCP gagal, script otomatis beralih ke `docker exec`.
* **Audit Database Komprehensif:** Memeriksa ukuran DB, bloat tabel/indeks, autovacuum, replikasi, query lambat, dan tabel tanpa statistik (`never_analyzed`).

---

## Cara Menggunakan `hc-docker.sh`

### Menggunakan Flag CLI:
```bash
# Menjalankan health check pada kontainer 'posdb' di localhost port 5432
./hc-docker.sh -c posdb -u postgres -w sandidb -d posdb

# Menjalankan health check pada kontainer remote di IP 10.10.0.22 port 5433 untuk semua database
./hc-docker.sh -c posdb -H 10.10.0.22 -P 5433 -u postgres -w sandidb -d all

# Memaksa eksekusi query via 'docker exec' di host VPS
./hc-docker.sh -c posdb -e
```

### Menggunakan Environment Variables (Cocok untuk OpenClaw / Automation):
```bash
DOCKER_CONTAINER=posdb PGHOST=10.10.0.22 PGPORT=5433 PGUSR=postgres PGPASSWORD=sandidb DBNAME=all ./hc-docker.sh
```

---

## Prasyarat & Kebutuhan Sistem

### 1. Izin Akses (Permissions)
* Script `hc-md.sh` **direkomendasikan dijalankan sebagai user `root`** (menggunakan `sudo`) jika ingin melakukan audit OS & hardware host secara lengkap (`dmidecode`, `lshw`, konfigurasi LVM, dll.).
* Script `hc-docker.sh` dapat dijalankan oleh user biasa yang memiliki akses ke perintah `docker` atau akses jaringan TCP ke port PostgreSQL.

### 2. Dependensi Paket Linux (Untuk Audit OS/Hardware Host `hc-md.sh`)
Pastikan paket-paket berikut terpasang di sistem operasi host Anda:
* `lsscsi`, `lshw`, `sysfsutils`, `sg3_utils`, `numactl`, `dmidecode`, `ethtool`, `hwinfo`
* `sysstat`, `lsof`, `net-tools`, `psmisc`, `setools-console`, `policycoreutils-python-utils`

### 3. Ekstensi PostgreSQL
* Sangat direkomendasikan untuk mengaktifkan ekstensi `pg_stat_statements` di PostgreSQL agar script dapat melakukan analisis performa query (DML terberat, CPU load, dsb.) secara optimal.

---

## Hasil Output Laporan

Setelah proses audit selesai, script akan mem-parsing seluruh data diagnostik menjadi file laporan tunggal:

* **`[tanggal]_[jam]_[hostname]_hc-docker.md`**: File laporan kesehatan akhir dalam format Markdown.

Anda dapat memindahkan file laporan ini ke folder dokumentasi Anda atau membukanya dengan Markdown viewer/aplikasi editor (seperti VS Code atau Obsidian) untuk melihat visualisasi laporan yang rapi.



