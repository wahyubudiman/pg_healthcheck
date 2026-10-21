# Panduan Lengkap Script Health Check & Assessment PostgreSQL / EDB EPAS

Dokumen ini berisi panduan penggunaan lengkap untuk rangkaian script audit kesehatan (*health check & assessment*) sistem operasi, infrastruktur host, serta basis data **PostgreSQL** dan **EnterpriseDB (EDB) Postgres Advanced Server (EPAS)**. Seluruh script menghasilkan laporan akhir terstruktur dalam format **Markdown (`.md`)** yang siap digunakan untuk audit operasional, analisis performa, maupun dokumentasi berkala.

---

## 🧭 Matriks Pemilihan Script (*Script Selector*)

Pilih script yang sesuai dengan lingkungan dan kebutuhan database Anda:

| Lingkungan / Kebutuhan Target | Script yang Digunakan | Lokasi Script | Fokus & Fitur Utama |
| :--- | :--- | :--- | :--- |
| **EDB Postgres Advanced Server (EPAS)** | `edb-hc.sh` | `../edb-hc.sh` | **Audit Lengkap EPAS (v13–v18)**: 23 bab pemeriksaan, 6 fitur Enterprise EDB (PEM, TDE, Statement Audit, Oracle Redwood, Password Profile, Data Redaction), sizing, WAL, replikasi, dan XID age. |
| **EDB Postgres Enterprise Manager (PEM)** | `edb_pem_hc.sh` *(alias: `pem-hc.sh`)* | `../edb_pem_hc.sh` | **Audit Server & Agent PEM**: Apache Web UI, masa berlaku sertifikat SSL agent, backend DB `pem`, bloat tabel riwayat `pemhistory`, retention purge, dan SQL Profiler. |
| **PostgreSQL Bare-Metal / Linux VM** | `hc-md.sh` | `./hc-md.sh` | **Audit PostgreSQL Standar di Host Linux**: Metrik hardware host, kernel sysctl, LVM, memori, bloat, autovacuum, replikasi, dan Top Query. |
| **PostgreSQL di Kontainer Docker** | `hc-docker.sh` | `./hc-docker.sh` | **Audit PostgreSQL Container**: `docker inspect`, `docker stats`, log error kontainer, eksekusi via TCP atau fallback `docker exec`. |
| **PostgreSQL di Kubernetes (CloudNativePG)** | `hc-cnpg.sh` | `./hc-cnpg.sh` | **Audit CNPG Cluster**: Status Pod, PVC, volume storage, failover timeline, dan metrik operator CNPG. |
| **Pemeliharaan Manual Vacuum & Freeze** | `manual_vacuum.sh` | `../manual_vacuum.sh` | **Utilitas Maintenance Interaktif**: Cek real-time XID Age, reset XID database arsip (>100M), vacuum harian ETL (Airflow/DWH), non-blocking dengan parallel `--jobs=2`. |

---

## 1. Script `edb-hc.sh` (EDB Postgres Advanced Server)

Script komprehensif untuk server EDB EPAS (versi 15, 16, 17, hingga 18) maupun PostgreSQL Community Edition.

### Prasyarat Environment:
Sebelum menjalankan, pastikan direktori kerja dan binary client EDB (`psql`) sudah diset pada environment variable:
```bash
export WORKDIR=/path/to/nguserver     # Sesuaikan dengan lokasi direktori proyek Anda
export PATH=/usr/lib/edb-as/15/bin:$PATH
```

### Cara Menjalankan:
```bash
cd $WORKDIR/pgscript

# 1. Menjalankan secara otomatis (auto-detect port 5432/5444 & user enterprisedb)
./edb-hc.sh -u enterprisedb

# 2. Menjalankan dengan opsi lengkap
./edb-hc.sh -H 127.0.0.1 -P 5432 -u enterprisedb -d all -o laporan_edb_master.md

# 3. Menggunakan Environment Variables
PGHOST=127.0.0.1 PGPORT=5432 PGUSER=enterprisedb DBNAME=edb ./edb-hc.sh
```

---

## 2. Script `edb_pem_hc.sh` (EDB PEM Server & Agent)

Script audit operasional untuk **EDB Postgres Enterprise Manager (PEM)** guna memvalidasi Web Server, Backend Database `pem`, serta status seluruh Agent.

### Prasyarat Environment Variables:
```bash
export WORKDIR=/path/to/nguserver     # Sesuaikan dengan lokasi direktori proyek Anda
export PATH=/usr/lib/edb-as/15/bin:$PATH
export EDB_BIN=/usr/lib/edb-as/15/bin
export PGDATA=/data/edb-as/15/main
export PEM_HOST=127.0.0.1
export PEM_PORT=5432
export PEM_DB=pem
export PEM_USER=enterprisedb
export PEM_CERT_DIR=/root/.pem
```

### Cara Menjalankan:
```bash
cd $WORKDIR/pgscript

# Menjalankan health check PEM (menggunakan env vars di atas)
./edb_pem_hc.sh

# Atau menggunakan opsi CLI:
./edb_pem_hc.sh -H 127.0.0.1 -P 5432 -d pem -u enterprisedb -c /root/.pem
```

---

## 3. Script `hc-md.sh` (PostgreSQL Bare-Metal / Linux VM)

Script audit standar untuk instalasi PostgreSQL pada host Linux (Debian, Ubuntu, RHEL, CentOS, Rocky, OpenCloudOS).

### Cara Menjalankan:
```bash
cd $WORKDIR/pgscript/hc

# Dijalankan dengan hak akses sudo/root untuk inspeksi hardware & kernel penuh:
sudo ./hc-md.sh

# Menjalankan dengan menentukan database target dan superuser:
./hc-md.sh -u postgres -d all
```

---

## 4. Script `hc-docker.sh` (PostgreSQL di Kontainer Docker)

Khusus untuk instance PostgreSQL yang berjalan di dalam kontainer Docker lokal maupun remote.

### Cara Menjalankan:
```bash
cd $WORKDIR/pgscript/hc

# Menjalankan pada kontainer 'posdb' di port lokal 5432:
./hc-docker.sh -c posdb -u postgres -w <db_password> -d posdb

# Menjalankan pada host remote via TCP:
./hc-docker.sh -c posdb -H 192.168.1.100 -P 5433 -u postgres -w <db_password> -d all

# Memaksa eksekusi query internal via 'docker exec':
./hc-docker.sh -c posdb -e
```

---

## 5. Script `manual_vacuum.sh` (Pemeliharaan Vacuum & XID Freeze)

Script interaktif non-blocking untuk memantau usia transaksi (*XID Age*) dan menjalankan pembersihan rutin tanpa mengganggu jalannya aplikasi.

### Cara Menjalankan:
```bash
cd $WORKDIR/pgscript

# Jalankan menu interaktif:
./manual_vacuum.sh
# Atau jika membutuhkan user enterprisedb:
sudo -u enterprisedb ./manual_vacuum.sh
```

### Menu yang Tersedia:
1. **Opsi 1:** Cek Status XID Age seluruh database (mendeteksi potensi XID wraparound).
2. **Opsi 2:** Eksekusi `VACUUM FREEZE` mendesak pada database dengan XID Age > 100 Juta (database arsip tua).
3. **Opsi 3:** Eksekusi `VACUUM ANALYZE` pada database beban tinggi / ETL (Airflow, Data Warehouse).
4. **Opsi 4:** Eksekusi pada satu database pilihan secara spesifik.
5. **Opsi 5:** Eksekusi `VACUUM FREEZE` seluruh cluster secara paralel dengan kontrol `--jobs=2`.

---

## 🛡️ Prinsip Keamanan & Proteksi Performa (Zero-Impact Guardrails)

Seluruh script audit di repositori ini dilengkapi dengan pembatas keamanan (*safety guardrails*) otomatis:

1. **`default_transaction_read_only = on`**: Menjamin tidak ada perubahan data atau DDL yang dapat terjadi selama proses audit.
2. **`statement_timeout = 15000` (15 detik)**: Mencegah query diagnostik menggantung (*hang*) atau membebani CPU database secara berkepanjangan.
3. **`lock_timeout = 5000` (5 detik)**: Jika tabel katalog sedang terkunci oleh transaksi aplikasi lain, query diagnostik akan langsung batal (*abort*) dan tidak akan menyebabkan antrean kunci (*lock contention*).
4. **`idle_in_transaction_session_timeout = 10000` (10 detik)**: Menjamin sesi audit tidak meninggalkan transaksi terbuka (*open transaction*) yang tertidur.

---

## 📊 Checklist Poin Kritis yang Wajib Diperiksa pada Laporan Hasil

Setelah file laporan Markdown (`.md`) selesai digenerate, pastikan memeriksa parameter-parameter berisiko tinggi berikut:

1. **WAL Archiving (`pg_stat_archiver`):**
   * Pastikan `failed_count` bernilai `0` atau tidak bertambah. Jika gagal terus-menerus, partisi `/data` berisiko penuh 100% dan memicu database crash.
2. **Streaming Replication (`pg_stat_replication`):**
   * Pastikan Standby Replica aktif terhubung (`state = streaming`) dan nilai `replay_lag` rendah (< 1 detik).
3. **Transaction ID Age (`XID Age`):**
   * Pastikan `xid_age` tidak mendekati `autovacuum_freeze_max_age` (200.000.000). Jika > 150 juta, segera lakukan `VACUUM FREEZE`.
4. **Connection Load (`max_connections`):**
   * Periksa persentase koneksi aktif. Jika sesi `idle` sangat banyak, pertimbangkan penggunaan Connection Pooler (seperti PgBouncer).
5. **Ekstensi `pg_stat_statements`:**
   * Pastikan ekstensi ini berstatus `Enabled` agar riwayat eksekusi query lambat dapat terlacak dengan baik.
