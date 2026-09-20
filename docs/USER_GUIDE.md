# Panduan Pengguna WhatsGo (User Guide)

Panduan praktis untuk menggunakan, mengonfigurasi, dan memecahkan masalah pada aplikasi **WhatsGo** (*WA Web To Go Reborn*).

---

## 1. Memulai: Login Pertama Kali

1. **Buka Aplikasi WhatsGo** di smartphone Anda.
2. Tunggu beberapa detik hingga halaman pemindaian **QR Code WhatsApp Web** muncul di layar.
3. Di HP utama Anda:
   - Buka WhatsApp resmi.
   - Ketuk menu titik tiga (Android) atau Pengaturan (iOS).
   - Pilih **Perangkat Tertaut (Linked Devices)** -> **Tautkan Perangkat (Link a Device)**.
4. Arahkan kamera HP utama ke QR Code di layar WhatsGo.
5. Setelah terhubung, daftar obrolan Anda akan langsung termuat dalam mode responsif 1-kolom.

> **Catatan:** Sesi Anda akan tersimpan secara otomatis. Anda tidak perlu memindai kode QR lagi saat membuka aplikasi berikutnya.

---

## 2. Navigasi & Tampilan

### 2.1 Membaca dan Membalas Obrolan
- Ketuk salah satu obrolan pada daftar pesan untuk membukanya.
- Layar obrolan akan terbuka penuh (100% selebar layar).
- Untuk kembali ke daftar pesan, Anda dapat:
  - Mengetuk tombol panah **"Kembali"** di pojok kiri atas obrolan, ATAU
  - Menekan tombol **Back fisik / gestur geser** bawaan Android.

### 2.2 Berpindah Antara Mode Mobile dan Desktop
- Ketuk tombol ikon **Laptop / Ponsel** di baris atas (Slim App Bar) untuk beralih antara:
  - **Mode Mobile:** Tampilan 1-kolom yang nyaman untuk layar smartphone.
  - **Mode Desktop:** Tampilan 2-kolom asli WhatsApp Web (bisa di-zoom manual menggunakan gestur dua jari).

### 2.3 Memunculkan / Menyembunyikan Toolbar
- Toolbar atas otomatis tersembunyi saat Anda menggulir obrolan ke bawah agar area baca lebih lega.
- Untuk memunculkan kembali toolbar, cukup ketuk tombol panah kecil melayang di kanan atas layar atau gulir ke bagian paling atas.

---

## 3. Menggunakan Fitur Direct Chat

Direct Chat memungkinkan Anda mengirim pesan ke nomor WhatsApp baru tanpa perlu menyimpannya ke buku kontak telepon.

1. Ketuk tombol bulat hijau **Floating Action Button (FAB)** berlambang pesan di pojok kanan bawah layar.
2. Masukkan kode negara (default: `62` untuk Indonesia).
3. Masukkan nomor telepon tujuan (contoh: `08123456789` atau `8123456789`). Anda juga dapat mengetuk ikon **Tempel** untuk menempelkan nomor dari clipboard.
4. *(Opsional)* Ketik draf pesan awal yang ingin langsung dikirimkan.
5. Ketuk tombol **Mulai Obrolan**. WhatsApp Web akan langsung membuka ruang chat dengan nomor tersebut.
6. **Riwayat Nomor:** Nomor yang baru saja Anda hubungi akan tersimpan di daftar "Nomor Terakhir Digunakan" untuk akses cepat di kemudian hari.

---

## 4. Konfigurasi User-Agent (Jika WhatsApp Minta Update Browser)

Jika suatu saat WhatsApp menampilkan pesan seperti *"WhatsApp requires Google Chrome 60+"* atau memblokir akses browser:

1. Buka toolbar atas, ketuk menu **Titik Tiga** -> pilih **Pengaturan WhatsGo**.
2. Pilih menu **Konfigurasi User-Agent**.
3. Ganti string User-Agent dengan string browser Chrome Desktop versi terbaru (misal versi Chrome yang sedang aktif di PC Anda).
4. Ketuk **Simpan & Muat Ulang**.
5. Jika ingin mengembalikan ke pengaturan semula, cukup ketuk tombol **Reset ke Default**.

---

## 5. Keluar / Ganti Akun (Logout)

1. Buka menu **Pengaturan WhatsGo**.
2. Ketuk tombol merah **Bersihkan Cache & Cookie**.
3. Konfirmasi dengan memilih **Hapus Sesi**.
4. Seluruh sesi login akan terhapus dan aplikasi akan kembali menampilkan layar QR Code baru.

---

## 6. Pemecahan Masalah (Troubleshooting)

### Q: Halaman WhatsApp Web hanya putih / tidak mau memuat
- Pastikan koneksi internet ponsel aktif dan stabil.
- Ketuk tombol **Muat Ulang (Refresh)** pada toolbar atas.
- Jika masih tidak muncul, periksa apakah User-Agent saat ini valid atau reset ke default melalui menu pengaturan.

### Q: Tombol Back langsung keluar dari aplikasi saat di dalam obrolan
- Pastikan mode mobile 1-kolom sedang aktif (bukan mode desktop penuh).
- Jika baru saja memuat halaman, tunggu hingga progress bar selesai (100%) agar skrip responsif terinjeksi sempurna.

