# Panduan Penggunaan Skrip Health Check CloudNativePG (`hc-cnpg.sh`)

Skrip `hc-cnpg.sh` adalah utilitas untuk melakukan audit dan pemeriksaan kesehatan (*health check*) pada klaster PostgreSQL yang dikelola oleh **CloudNativePG (CNPG)** di Kubernetes. Skrip ini dijalankan dari mesin lokal Anda (di luar Kubernetes) dan menyalurkan (*pipe*) kueri SQL diagnostik langsung ke pod *primary* klaster target.

Laporan pemeriksaan kesehatan akan dihasilkan secara otomatis dalam format **Markdown (`.md`)** agar mudah dibaca menggunakan editor modern (seperti VS Code, GitHub, Obsidian, atau Notion).

---

## 📋 Prasyarat

Sebelum menjalankan skrip, pastikan Anda memenuhi kriteria berikut pada mesin lokal Anda:

1. **`kubectl`**: Terpasang dan sudah dikonfigurasi dengan akses ke klaster Kubernetes target.
2. **Konteks K8s yang Tepat**: Sesi `kubectl` Anda terhubung ke namespace tempat klaster CNPG berada.
3. **`kubectl-cnpg` Plugin** *(Opsional, sangat disarankan)*: Plugin CLI resmi dari CloudNativePG untuk menampilkan status klaster secara mendetail.
4. **Struktur Folder**: File skrip `hc-cnpg.sh` harus berada di direktori yang sama dengan sub-folder `sql/` (berisi kumpulan kueri audit `.sql`).

---

## 🚀 Cara Penggunaan

Gunakan perintah di bawah ini pada direktori tempat skrip berada:

```bash
./hc-cnpg.sh -c <nama_klaster_cnpg> [opsi_lainnya...]
```

### Opsi Parameter:

| Parameter | Keterangan | Bawaan (*Default*) |
| :--- | :--- | :--- |
| **`-c`** | **(Wajib)** Nama Klaster CNPG target Anda. | *Tidak ada* |
| **`-n`** | Namespace Kubernetes tempat klaster berada. | Namespace aktif saat ini (atau `default`) |
| **`-u`** | User superuser PostgreSQL untuk masuk ke DB. | `postgres` |
| **`-d`** | Nama database spesifik yang ingin diaudit. Ketik `all` untuk mengecek semua database non-sistem. | `all` |
| **`-o`** | Lokasi dan nama berkas laporan keluaran (Markdown). | `hc-cnpg.md` |
| **`-h`** | Menampilkan panduan bantuan penggunaan parameter. | *Tidak ada* |

---

## 💡 Contoh Contoh Perintah

### 1. Health Check Standar
Melakukan audit pada klaster bernama `my-db` di namespace saat ini dengan semua pengaturan bawaan:
```bash
./hc-cnpg.sh -c my-db
```
*Laporan audit akan disimpan di file `hc-cnpg.md`.*

### 2. Menentukan Namespace dan User Tertentu
Melakukan audit klaster `sales-db` di namespace `prod` menggunakan superuser custom `app_admin`:
```bash
./hc-cnpg.sh -c sales-db -n prod -u app_admin
```

### 3. Mengaudit Satu Database Saja dan Mengubah Nama File Output
Melakukan audit hanya pada database `customer_orders` di dalam klaster `my-db` dan menyimpannya ke folder lain:
```bash
./hc-cnpg.sh -c my-db -d customer_orders -o ~/reports/my-db-report.md
```

---

## 📊 Struktur Laporan Output (`hc-cnpg.md`)

File Markdown yang dihasilkan terstruktur dalam beberapa bagian penting:

1. **Header Informasi**: Menunjukkan tanggal audit dijalankan, nama klaster, namespace, nama pod utama (*primary pod*), dan nomor versi PostgreSQL.
2. **Kubernetes & CNPG Status**: Menampilkan YAML spesifikasi klaster, status kesehatan klaster berbasis operator CNPG (`kubectl cnpg status`), status resource pod, dan event-event terbaru dari Kubernetes.
3. **Instance-Level Settings**: Laporan konfigurasi global PostgreSQL, aturan berkas HBA (`pg_hba.conf`), ukuran database, hak akses user global, rasio rollback/cache hit, serta laporan performa *Background Writer* dan *Checkpoint*.
4. **Replication Status**: Menampilkan status sinkronisasi master-replica, info WAL receiver, status slot replikasi, dan recovery conflict.
5. **Performance & Active Sessions**: Kueri DML/SELECT aktif yang berjalan lama (> 15 detik), status transaksi yang terkunci (*locking/blocking*), dan 20 kueri paling berat (jika `pg_stat_statements` terinstal).
6. **Per-Database Audit**: Looping audit objek detail untuk setiap database (ukuran tabel > 8GB, bloat indeks/tabel, sequence hampir penuh, indeks yang mubazir/tidak terpakai, indeks yang disarankan, pengecekan fillfactor, dst).

---

## 🛠️ Troubleshooting (Pemecahan Masalah)

* **Error: SQL directory not found at...**
  * *Solusi:* Pastikan folder `sql` yang berisi file-file `.sql` berada di folder yang sama dengan skrip `hc-cnpg.sh`.
* **Error: Failed to connect to PostgreSQL database using user...**
  * *Solusi:* Pastikan superuser yang Anda masukkan lewat opsi `-u` sudah benar dan memiliki hak akses koneksi lokal tanpa kata sandi (karena koneksi dilakukan di dalam pod via Unix Socket / Trust authentication).
* **Warning: pg_stat_statements is NOT enabled. Performance queries will be skipped.**
  * *Solusi:* Pesan ini wajar jika klaster Anda belum memuat modul `pg_stat_statements`. Bila ingin mengaktifkannya, tambahkan modul ini di bagian `shared_preload_libraries` pada manifest YAML CNPG Anda.
