# Product Requirements Document (PRD)
## WhatsGo (WA Web To Go Reborn)
**A Modern, Responsive, and Resilient WhatsApp Web Client for Android**

---

### 1. Ringkasan Eksekutif & Latar Belakang (Executive Summary)

#### 1.1 Latar Belakang
Aplikasi open-source legendaris di F-Droid yaitu **"WhatsApp Web To Go"** telah lama menjadi andalan pengguna Android yang ingin menjalankan WhatsApp di ponsel sekunder (tanpa perlu aplikasi modifikasi berisiko banned). Namun, saat ini aplikasi tersebut **sudah tidak berfungsi** karena:
1. **User-Agent Usang:** WhatsApp Web menerapkan pemblokiran bertahap terhadap versi browser Chromium lama dan browser mobile murni.
2. **Pembaruan Arsitektur WhatsApp:** Transisi ke multi-device architecture membutuhkan dukungan Web APIs modern (IndexedDB terenkripsi, WebAssembly, Service Workers, WebRTC) yang gagal dijalankan oleh konfigurasi WebView lama.
3. **Viewport & Layout Breakage:** Script injeksi CSS lama tidak lagi kompatibel dengan kelas DOM dan struktur antarmuka WhatsApp Web modern.
4. **Manajemen Background yang Dimatikan Android Modern:** Pembatasan agresif Android 12+ terhadap background process memutus koneksi WebSocket saat aplikasi diminimalkan.

#### 1.2 Visi Produk
**WhatsGo (WA Web To Go Reborn)** dibangun dari nol menggunakan **Flutter** dan **Modern InAppWebView** untuk menghadirkan kembali pengalaman menjalankan WhatsApp Web di smartphone dengan tampilan responsif selayaknya aplikasi native, dukungan notifikasi latar belakang yang persisten, fitur keamanan biometrik, serta mekanisme perlindungan *future-proof* (Dynamic User-Agent) agar aplikasi tidak mudah usang.

---

### 2. Tujuan & Sasaran Produk (Goals & Objectives)

1. **Kompatibilitas 100% WhatsApp Web:** Mampu memuat kode QR dan sinkronisasi sesi chat WhatsApp Multi-Device secara stabil tanpa pesan *"Browser tidak didukung"*.
2. **Pengalaman Mobile-First:** Mengubah tampilan 2-kolom WhatsApp Web menjadi 1-kolom yang nyaman dioperasikan satu tangan dengan integrasi gestur / tombol Back Android.
3. **Koneksi Selalu Siaga:** Menggunakan Android Foreground Service agar pengguna tetap menerima notifikasi pesan baru saat layar mati atau saat membuka aplikasi lain.
4. **Privasi & Keamanan Terjaga:** Melindungi akses chat dengan Biometrik (Sidik Jari/Face Unlock) dan PIN.
5. **Anti-Obsolescence (Tahan Masa Depan):** String User-Agent dapat diperbarui secara dinamis (remote fetch / manual input pengguna) tanpa harus menunggu build APK baru.

---

### 3. Persona Pengguna & Use Cases

#### 3.1 Target Pengguna
- **Pengguna Dual-Device:** Memiliki HP utama dan HP kedua/kerja, ingin membuka akun WhatsApp yang sama di kedua perangkat tanpa repot logout.
- **Pengguna Tablet/Lipat:** Ingin fleksibilitas tampilan responsif 1-kolom di layar HP atau tampilan 2-kolom desktop di layar lebar.
- **Pengguna Sadar Privasi:** Menolak aplikasi WhatsApp Mod (GBWhatsApp/FMWhatsApp) yang berisiko malware atau pemblokiran nomor akun WhatsApp resmi.

#### 3.2 Kasus Penggunaan Utama (Core Use Cases)
- **Login Sesi Pertama:** Membuka aplikasi -> Scan QR Code dari WhatsApp HP utama -> Sesi tersimpan permanen (persistent cookie/IndexedDB).
- **Membaca & Membalas Pesan:** Pengguna membuka chat dari daftar obrolan; layar beralih penuh ke obrolan; tombol Back fisik mengembalikan pengguna ke daftar chat.
- **Direct Chat:** Mengirim pesan ke nomor baru tanpa perlu menyimpan nomor tersebut ke buku telepon Android.
- **Menerima Pesan di Latar Belakang:** Layar HP terkunci -> Pesan masuk -> Foreground service meneruskan notifikasi Android -> Pengguna mengetuk notifikasi untuk langsung membuka chat.
- **Download/Upload Media:** Mengirim gambar dari galeri, merekam voice note via mikrofon, serta mengunduh dokumen/video langsung ke folder `Download` ponsel.

---

### 4. Arsitektur Teknis & Tech Stack

| Komponen | Pilihan Teknologi | Justifikasi |
| :--- | :--- | :--- |
| **Framework UI** | Flutter 3.x (Dart) | Memudahkan penyesuaian UI wrapper, kontrol app bar, dialog utilitas, dan potensi multi-platform. |
| **Browser Engine** | `flutter_inappwebview` v6+ | Berbasis Android System WebView modern; mendukung injeksi CSS/JS canggih, Service Worker, IndexedDB, WebRTC, dan penanganan unduhan file. |
| **Background Service** | `flutter_foreground_task` | Menjalankan Foreground Service Android dengan Persistent Notification agar WebSocket WhatsApp tetap terjaga. |
| **Keamanan & Biometrik** | `local_auth` & `flutter_secure_storage` | Otentikasi Biometrik (Fingerprint, Face) & enkripsi PIN/kunci pengaturan lokal. |
| **Storage & Preferences** | `shared_preferences` | Menyimpan konfigurasi User-Agent, preferensi tema, status zoom, dan riwayat direct chat. |
| **Android Target** | Min SDK 24 (Android 7.0), Target SDK 34/35 | Kompatibel dengan 95%+ perangkat Android aktif di seluruh dunia. |

---

### 5. Spesifikasi Fungsional (Functional Requirements)

#### 5.1 FR-1: Engine Browser & Anti-Obsolescence (User-Agent Manager)
- **FR-1.1 Default Modern User-Agent:** Aplikasi secara default menyuntikkan User-Agent Desktop Chrome versi modern terkini (misal: `Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36`).
- **FR-1.2 User-Agent Customization:** Menyediakan halaman pengaturan untuk mengubah string User-Agent secara manual jika WhatsApp sewaktu-waktu menaikkan versi minimum browser.
- **FR-1.3 Web API Support:** Mengaktifkan flags `domStorageEnabled`, `databaseEnabled`, `javaScriptCanOpenWindowsAutomatically`, `mediaPlaybackRequiresUserGesture: false`, dan WebRTC untuk voice note.
- **FR-1.4 Cache & Session Persistence:** Cookie dan data IndexedDB disimpan secara permanen pada disk aplikasi sehingga pengguna tidak perlu scan QR ulang setiap kali membuka aplikasi.

#### 5.2 FR-2: Mobile Viewport Adaptation (Responsive 1-Column Mode)
- **FR-2.1 CSS Injection (Single-Column UI):**
  - Menginjeksi stylesheet dinamis saat DOM selesai dimuat (`onLoadStop`).
  - Pada mode portrait HP: Jika sedang membuka daftar chat, sembunyikan panel pesan (lebar 100%). Jika chat diklik, sembunyikan daftar chat dan tampilkan panel obrolan selebar 100%.
- **FR-2.2 Integrasi Tombol Back Android:**
  - Mengintersepsi event `PopScope` (Back button / Back gesture).
  - Jika pengguna sedang berada di dalam ruang obrolan, tombol Back akan mengeklik tombol "Kembali" internal WhatsApp Web sehingga kembali ke daftar chat.
  - Jika sudah berada di daftar chat, tombol Back akan meminimalkan aplikasi (bukan kill session).
- **FR-2.3 Desktop View Toggle:** Tombol saklar di toolbar untuk mematikan injeksi CSS responsif dan beralih ke layout desktop asli 2-kolom (dengan pinch-to-zoom).

#### 5.3 FR-3: Background Service & Real-Time Notifications
- **FR-3.1 Persistent Foreground Service:**
  - Menjalankan notifikasi ongoing bertuliskan *"WhatsGo Siaga"* dengan ikon status bar.
  - Mencegah OS Android memutus alokasi RAM dan proses jaringan WebView.
- **FR-3.2 Web Notification Bridge:**
  - Menangkap Web Notification API dari WhatsApp Web melalui JavaScript Channel.
  - Menampilkan notifikasi lokal Android lengkap dengan nama pengirim dan cuplikan pesan (dapat disesuaikan di preferensi privasi).
  - Mengetuk notifikasi langsung membawa pengguna ke jendela aplikasi WhatsGo.

#### 5.4 FR-4: Keamanan & Privasi (App Lock)
- **FR-4.1 Biometric & PIN Lock:**
  - Opsi untuk mewajibkan otentikasi Biometrik (Fingerprint / Face ID) atau PIN angka setiap kali aplikasi dibuka.
- **FR-4.2 Auto-Lock Policy:**
  - Pilihan durasi kunci otomatis: *Segera (Immediately)* saat aplikasi pindah ke latar belakang, atau setelah jeda (1 menit, 5 menit).
- **FR-4.3 Privacy Notification Mask:**
  - Opsi untuk menyembunyikan cuplikan isi pesan di notifikasi status bar/layar kunci (hanya menampilkan *"Pesan baru diterima"*).

#### 5.5 FR-5: Fitur Utilitas Tambahan
- **FR-5.1 Direct Chat (Kirim Pesan Tanpa Simpan Kontak):**
  - Modal dialog cepat berisi input kode negara (default +62) dan nomor tujuan serta draft pesan opsional.
  - Membuka URL `https://web.whatsapp.com/send?phone=[nomor]&text=[pesan]` di WebView tanpa reload seluruh aplikasi.
- **FR-5.2 Manajemen Unduhan & Media Komprehensif:**
  - Mengizinkan perekaman audio (microphone permission) untuk merekam Voice Note langsung di browser.
  - Mendukung file picker untuk mengunggah gambar, video, dan dokumen.
  - Menangani event unduhan file dari WhatsApp Web dan menyimpannya ke direktori `Downloads/WhatsGo` menggunakan DownloadManager Android disertai notifikasi progres.
- **FR-5.3 Sinkronisasi Tema Gelap/Terang (Dark Mode Sync):**
  - Mendeteksi mode sistem Android (Dark / Light).
  - Menginjeksi preferensi tema ke WhatsApp Web (`body.dark` class atau media query `prefers-color-scheme: dark`) serta menyesuaikan warna Toolbar Flutter.

---

### 6. Persyaratan Non-Fungsional (Non-Functional Requirements)

1. **Performa & Konsumsi Memori:**
   - Konsumsi RAM standby di latar belakang diupayakan < 150 MB.
   - Waktu buka awal (cold start) < 3 detik (setelah sesi awal terautentikasi).
2. **Keamanan & Privasi Data:**
   - **Zero Intermediary Server:** Komunikasi data 100% langsung antara WebView perangkat dengan server resmi WhatsApp (`*.whatsapp.com` / `*.whatsapp.net`).
   - Tidak ada analitik pihak ketiga atau pelacak privasi yang disematkan.
3. **Ketahanan Terhadap Perubahan WhatsApp:**
   - Menggunakan selector CSS berbasis atribut stabil (bukan hash minified CSS yang berubah setiap minggu) untuk manipulasi DOM.
   - Mekanisme fail-safe: Jika script responsif gagal menemukan elemen DOM tertentu, aplikasi tetap bisa diakses dalam mode desktop fallback tanpa crash.

---

### 7. Desain Antarmuka & Alur Pengguna (UI/UX Flow)

```
[Icon App Dibuka]
        │
        ▼
[Layar Kunci Biometrik / PIN] (Jika diaktifkan)
        │ (Lolos Otentikasi)
        ▼
[Pemeriksaan Sesi Login]
   ├── Belum Login ──────► [Tampilkan Layar QR Code WhatsApp Web]
   └── Sudah Login ──────► [Tampilkan Daftar Chat 1-Kolom Responsif]
                                 │
                 ┌───────────────┼───────────────┐
                 ▼               ▼               ▼
         [Klik Chat]      [Direct Chat]     [Menu / Pengaturan]
                 │               │               │
                 ▼               ▼               ▼
        [Ruang Obrolan 100%]  [Input Nomor]  - Ganti User-Agent
        (Back: Ke List)       (Langsung Kirim)- Toggle Mode Desktop
                                             - Pengaturan Kunci
                                             - Pengaturan Notifikasi
```

---

### 8. Rencana Implementasi & Milestone Pengembangan

| Fase | Fokus Pekerjaan | Deliverable |
| :--- | :--- | :--- |
| **Milestone 1** | Inisialisasi Proyek Flutter & Setup InAppWebView | Inisialisasi Flutter project, konfigurasi Android manifest, perizinan, pemuatan `web.whatsapp.com` dengan Desktop UA & session persistence. |
| **Milestone 2** | Adaptasi Mobile Viewport & Back Navigation | Injeksi CSS/JS 1-kolom, handling `PopScope` tombol Back, toggle Desktop Mode. |
| **Milestone 3** | Foreground Service & Bridge Notifikasi | Implementasi persistent notification background service, penangkapan Web Notification ke Android Notification. |
| **Milestone 4** | Utilitas (Direct Chat, Media Download, Dark Mode) | Dialog Direct Chat, audio recording/upload permissions, download listener ke lokal, dark mode handler. |
| **Milestone 5** | Keamanan (Biometrik) & Halaman Pengaturan | Integrasi `local_auth` biometric & PIN, dynamic User-Agent editor di Settings. |
| **Milestone 6** | Hardening, Optimasi Baterai & Rilis APK | Pengujian pada berbagai versi Android (10, 11, 12, 13, 14, 15), build release APK untuk GitHub Releases. |

