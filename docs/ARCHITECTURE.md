# Dokumentasi Arsitektur Teknis WhatsGo

Dokumen ini menjelaskan rancangan arsitektur teknis dari aplikasi **WhatsGo** (*WA Web To Go Reborn*), mencakup integrasi mesin browser, manipulasi DOM dinamis, jembatan komunikasi native (*native bridge*), serta strategi ketahanan terhadap perubahan sistem WhatsApp Web.

---

## 1. Diagram Alur Sistem

```
┌────────────────────────────────────────────────────────┐
│                   Aplikasi WhatsGo (Flutter)           │
├────────────────────────────────────────────────────────┤
│  SlimAppBar (Auto-hide Toolbar)                        │
│  ├── Reload Button                                     │
│  ├── Toggle Desktop / Mobile Mode                      │
│  └── Settings Sheet (User-Agent, Foreground, Privacy)  │
├────────────────────────────────────────────────────────┤
│  Lapis InAppWebView (Android System WebView Engine)    │
│  ├── WebSettings: Desktop UA, DOM Storage, WebRTC      │
│  ├── Pre-document Script:                              │
│  │    ├── Win32 & Google Inc. Platform Spoofing        │
│  │    ├── window.Notification Interception Bridge      │
│  │    └── HTMLAnchorElement Blob Download Interceptor  │
│  └── onLoadStop Injection:                             │
│       ├── Responsive CSS (1-Column Layout)             │
│       └── MutationObserver JS (#side vs #main)         │
├────────────────────────────────────────────────────────┤
│  Native Android Layer (Kotlin MainActivity)            │
│  ├── MethodChannel: moveTaskToBack(true)               │
│  ├── FileProvider: whatsgo.nunorifa.my.id.fileprovider │
│  └── Notification Channels:                            │
│       ├── whatsgo_foreground_service (Status Bar Low)  │
│       ├── whatsgo_messages_channel (Heads-Up High)     │
│       └── whatsgo_downloads_channel (Downloads Default)│
├────────────────────────────────────────────────────────┤
│  Komponen Utilitas & Latar Belakang                    │
│  ├── AppForegroundService (flutter_foreground_task)    │
│  ├── DownloadService (/storage/.../Download/WhatsGo)   │
│  └── DirectChatDialog + DirectChatService (+62 format) │
└───────────────────────────┬────────────────────────────┘
                            │ (Direct HTTPS / WSS)
                            ▼
              ┌───────────────────────────┐
              │   Server Resmi WhatsApp   │
              │   (*.whatsapp.com / .net) │
              └───────────────────────────┘
```

---

## 2. Konfigurasi Mesin Browser (`InAppWebView`)

WhatsGo menggunakan plugin `flutter_inappwebview` versi 6.x yang berjalan di atas *Android System WebView* (berbasis Chromium).

### 2.1 WebSettings Kritis

```dart
InAppWebViewSettings(
  userAgent: _currentUserAgent,
  useShouldOverrideUrlLoading: true,
  mediaPlaybackRequiresUserGesture: false,
  javaScriptEnabled: true,
  javaScriptCanOpenWindowsAutomatically: true,
  domStorageEnabled: true,       // Diperlukan untuk LocalStorage & IndexedDB
  databaseEnabled: true,         // Diperlukan untuk penyimpanan pesan lokal WhatsApp
  clearCache: false,             // Menjaga sesi login tetap permanen
  supportZoom: true,             // Memungkinkan zoom pada mode desktop
  builtInZoomControls: true,
  displayZoomControls: false,
  useHybridComposition: true,   // Performa render hardware-accelerated optimal
  allowFileAccessFromFileURLs: true,
  allowUniversalAccessFromFileURLs: true,
  allowFileAccess: true,
  allowContentAccess: true,
  allowsInlineMediaPlayback: true,
  cacheMode: CacheMode.LOAD_DEFAULT,
)
```

### 2.2 Spoofing Lingkungan Eksekusi JavaScript
WhatsApp Web melakukan pengecekan platform selain User-Agent string. Untuk mencegah deteksi perangkat mobile, script berikut disuntikkan pada tahap `UserScriptInjectionTime.AT_DOCUMENT_START`:

```javascript
Object.defineProperty(navigator, 'platform', {
  get: function() { return 'Win32'; },
  configurable: true
});
Object.defineProperty(navigator, 'vendor', {
  get: function() { return 'Google Inc.'; },
  configurable: true
});
Object.defineProperty(navigator, 'maxTouchPoints', {
  get: function() { return 1; },
  configurable: true
});
```

---

## 3. Adaptasi Mobile Viewport & Injeksi DOM

WhatsApp Web desktop dirancang dengan struktur 2 kolom:
- Kolom kiri: `#side` (daftar kontak & riwayat obrolan)
- Kolom kanan: `#main` (isi ruang obrolan)

### 3.1 CSS Injeksi (`ResponsiveScripts.mobileCss`)
Pada layar smartphone, kedua panel dipaksa memiliki lebar 100%:
- Saat kelas `.whatsgo-in-list` aktif: `#side` tampil selebar 100%, sedangkan `#main` disembunyikan (`display: none !important`).
- Saat kelas `.whatsgo-in-chat` aktif: `#side` disembunyikan, sedangkan `#main` tampil selebar 100%.

### 3.2 Dynamic `MutationObserver`
Sebuah `MutationObserver` JavaScript terus memantau `document.body`.
1. Jika elemen `#main` terdeteksi di DOM, observer mengaktifkan kelas `.whatsgo-in-chat` dan menyuntikkan tombol *Virtual Back* (`.whatsgo-back-btn`) ke dalam header obrolan.
2. Observer memanggil channel JavaScript ke Flutter:
   ```javascript
   window.flutter_inappwebview.callHandler('onChatStateChanged', inChat);
   ```
   sehingga aplikasi Flutter mengetahui secara pasti apakah pengguna sedang berada di dalam ruang chat atau di daftar utama.

---

## 4. Penanganan Navigasi Tombol Back Android

Algoritma penanganan tombol Back (`PopScope`) bekerja secara berlapis:

```
[Tombol Back Android Ditekan]
             │
             ▼
    Apakah Mode Mobile Aktif?
      ├── Ya: Apakah _isInChat == true?
      │         ├── Ya: Jalankan window.whatsGoCloseChat() 
      │         │       (Kirim event Escape -> Kembali ke daftar chat)
      │         └── Tidak: Lanjut ke pemeriksaan riwayat browser
      └── Tidak: Lanjut ke pemeriksaan riwayat browser
             │
             ▼
    Apakah WebView bisa mundur (canGoBack)?
      ├── Ya: Jalankan webViewController.goBack()
      └── Tidak: Jalankan MethodChannel moveTaskToBack(true)
                 (Aplikasi diminimalkan ke background, koneksi WebSocket tetap hidup)
```

---

## 5. Layanan Siaga Latar Belakang (Android Foreground Service)

Pada Android 10+, sistem operasi secara agresif menghentikan soket jaringan atau menidurkan proses (*Doze Mode*) aplikasi yang diminimalkan.

WhatsGo menerapkan **`AppForegroundService`** via `flutter_foreground_task`:
1. **Persistent Notification:** Menampilkan notifikasi persisten bertuliskan *"WhatsGo Siaga: Menjaga koneksi pesan tetap aktif"* dengan prioritas `LOW` pada channel `whatsgo_foreground_service`.
2. **Action Buttons:** Dilengkapi tombol "Buka" (membawa aplikasi ke depan) dan "Hentikan" (mematikan foreground service dari panel notifikasi).
3. **Keep-Alive:** Memastikan koneksi WebSocket (`wss://web.whatsapp.com/ws/chat`) tetap menerima heartbeat sehingga pesan masuk tidak tertunda.

---

## 6. Bridge Notifikasi Pesan Masuk (Web Notification Bridge)

WhatsApp Web memicu pesan masuk menggunakan API browser standar `new Notification(title, options)`.

1. **Injeksi Intersepsi (`NotificationScripts.notificationInterceptionScript`):**
   - Menggantikan objek `window.Notification` dengan implementasi kustom WhatsGo.
   - Otomatis memberikan status `Notification.permission = 'granted'`.
2. **Penerusan ke Flutter:**
   - Ketika ada pesan baru, konstruktor `CustomNotification` memanggil:
     `window.flutter_inappwebview.callHandler('onIncomingWebNotification', { title, body, icon, tag })`.
3. **Notifikasi Native Android (`showIncomingNotification`):**
   - Flutter meneruskan data ke native Android via `MethodChannel`.
   - Native Kotlin membangun `NotificationCompat.Builder` dengan prioritas tinggi (`IMPORTANCE_HIGH`), suara, dan getaran pada channel `whatsgo_messages_channel`.
   - Jika pengguna mengaktifkan fitur **"Sembunyikan Isi Pesan"**, teks notifikasi otomatis digantikan dengan *"Pesan baru diterima"*.

---

## 7. Manajemen Unduhan & Media Komprehensif

### 7.1 Perekaman Voice Note & Kamera/Galeri
- Permintaan WebRTC (`navigator.mediaDevices.getUserMedia`) dicegat melalui callback `onPermissionRequest`.
- Aplikasi meminta izin runtime Android (`Permission.camera` dan `Permission.microphone`) secara dinamis dan memberikan persetujuan ke Chromium engine.

### 7.2 Intersepsi Unduhan Berkas Enkripsi Blob
Media terenkripsi WhatsApp Web diunduh melalui `blob:` URI buatan JavaScript.
1. `DownloadScripts.blobInterceptorScript` mencegat event `.click()` pada elemen jangkar (`<a>`) yang memiliki atribut `download` atau `href="blob:..."`.
2. Skrip mengambil blob melalui API `fetch(href)` dan mengonversinya menjadi string Base64 menggunakan `FileReader`.
3. Data Base64 dikirim ke Flutter melalui `window.flutter_inappwebview.callHandler('onBlobDownloadRequest', ...)`.
4. `DownloadService` menulis file ke direktori publik `/storage/emulated/0/Download/WhatsGo/`.

### 7.3 Android FileProvider & Notifikasi Selesai
Setelah file disimpan:
- Native Kotlin memicu notifikasi pada `whatsgo_downloads_channel`.
- Notifikasi disematkan `PendingIntent` dengan `Intent.ACTION_VIEW` dan `FileProvider.getUriForFile` (`whatsgo.nunorifa.my.id.fileprovider`).
- Pengguna dapat mengetuk tombol **"Buka Berkas"** untuk langsung membuka dokumen atau media di aplikasi default ponsel.

---

## 8. Strategi Anti-Obsolescence (Tahan Masa Depan)

Aplikasi klien WhatsApp Web lama umumnya gagal karena string User-Agent di-hardcode ke versi browser lama. Ketika WhatsApp menaikkan syarat minimum browser, seluruh aplikasi menjadi rusak.

WhatsGo mengatasi masalah ini dengan dua lapis perlindungan:
1. **Pembaruan Mandiri Pengguna:** Pengguna dapat membuka menu *Pengaturan WhatsGo -> Konfigurasi User-Agent* dan memasukkan string Chrome Desktop terkini.
2. **Tombol Reset:** Kemampuan untuk kembali ke string default yang terbukti stabil sewaktu-waktu.

---

## 9. Jaminan Keamanan & Privasi Data

- **Zero Middleware Server:** Tidak ada peladen (server) perantara atau API proxy yang digunakan. Seluruh lalu lintas data bergerak langsung antara WebView perangkat dengan server resmi `*.whatsapp.com`.
- **Enkripsi End-to-End Bawaan:** Enkripsi end-to-end asli WhatsApp Web tetap berjalan secara utuh melalui mesin Web Cryptography API di dalam WebView.
- **Penyimpanan Lokal:** Cookie sesi dan kredensial IndexedDB disimpan di direktori aplikasi privat Android (`/data/data/whatsgo.nunorifa.my.id/app_webview`).

---

## 10. Keamanan Biometrik & Layar Kunci Privasi (Milestone 5)

WhatsGo mengintegrasikan perlindungan biometrik level perangkat (*hardware-backed security*) untuk melindungi privasi obrolan pengguna dari akses fisik tanpa izin:

### 10.1 Layanan Biometrik (`BiometricService`)
- Memanfaatkan plugin `local_auth` dengan konfigurasi `biometricOnly: false` dan `stickyAuth: true`.
- **Fallback Kredensial Perangkat:** Jika pemindai biometrik (sidik jari / wajah) gagal atau tidak tersedia, sistem secara mulus beralih ke autentikasi PIN, Pola, atau Sandi perangkat native yang diamankan oleh Android TEE/Keystore.
- **Auto-Lock Timeout Manager:** Menyimpan durasi batas waktu di `SharedPreferences` (*Segera, 1 Menit, 5 Menit, atau 15 Menit*). Saat siklus hidup aplikasi beralih ke `AppLifecycleState.paused`, timestamp dicatat; saat beralih ke `resumed`, selisih waktu dihitung untuk menentukan apakah layar kunci wajib diaktifkan kembali.

### 10.2 Layar Penutup Privasi (`LockOverlay`)
- Ditampilkan di atas WebView melalui `Stack` ketika `_isAppLocked == true`.
- Mencegah kebocoran cuplikan obrolan (*chat preview leak*) saat berpindah antar-aplikasi di panel Recent Apps / App Switcher.
- Otomatis memicu *prompt* autentikasi saat layar tampil pertama kali menggunakan `addPostFrameCallback`.
- Saat terkunci, tombol navigasi Back Android otomatis mengarahkan aplikasi ke latar belakang (`moveTaskToBack`), mencegah pengguna melewati lapisan autentikasi.

---

## 11. Arsitektur Hardening, Pengoptimalan Baterai & Distribusi Rilis (Milestone 6)

### 11.1 Pengabaian Optimasi Baterai (Battery Optimization / Doze Mode Exemption)
Sistem operasi Android (khususnya custom OEM ROM seperti Xiaomi HyperOS/MIUI, Samsung OneUI, ColorOS) memiliki manajemen daya agresif yang memutus soket jaringan dan mematikan background service saat layar mati dalam durasi lama.

WhatsGo mengatasi hal ini melalui integrasi permintaan pengecualian optimasi baterai:
- **Manifest:** Menyertakan izin `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- **Layanan Siaga:** `AppForegroundService` mengekspos fungsi `isIgnoringBatteryOptimizations()` dan `requestIgnoreBatteryOptimization()`.
- **Antarmuka Pengguna:** Di dalam Sheet Pengaturan -> Layanan Latar Belakang, pengguna dapat mengetuk opsi **"Pengecualian Optimasi Baterai"** untuk memicu dialog sistem Android native yang menempatkan WhatsGo ke dalam daftar putih (*whitelist*) Doze Mode.

### 11.2 R8 / ProGuard Code Hardening & Minifikasi
Untuk rilis publik yang aman dan berkinerja tinggi, WhatsGo menerapkan aturan R8/ProGuard khusus pada `android/app/proguard-rules.pro`:
- **JavaScript Interface Bridge:** Mempertahankan method yang dianotasi `@JavascriptInterface` dan class bridge `com.pichillilorenzo.flutter_inappwebview_android.*` agar komunikasi injeksi skrip JavaScript (responsif CSS, intersepsi unduhan blob, bridge notifikasi) tidak terhapus (*stripped*) atau ter-obfuscate oleh compiler.
- **Layanan Latar Belakang:** Menjaga class `com.pravera.flutter_foreground_task.*` dan service worker Android native agar pemanggilan siklus hidup background service tetap valid.
- **Biometrik & Autentikasi:** Menjaga class `io.flutter.plugins.localauth.*` dan Android BiometricPrompt framework.
- **AndroidX & Kotlin Coroutines:** Menjaga metadata refleksi untuk library runtime AndroidX dan Kotlin runtime.

### 11.3 Pipeline Distribusi & Kemasan Multi-Arsitektur (Packaging)
WhatsGo mengadopsi dua strategi kompilasi berkas rilis untuk efisiensi distribusi:
1. **Split APKs per-ABI:**
   - Menghasilkan berkas APK terpisah untuk `arm64-v8a` (~22.4 MB), `armeabi-v7a` (~19.9 MB), dan `x86_64` (~23.8 MB).
   - Mengurangi ukuran unduhan hingga **>50%** dibandingkan APK universal karena hanya memuat library binary native (`.so`) yang dibutuhkan oleh arsitektur CPU perangkat target.
2. **Universal Fat APK:**
   - Menghasilkan satu berkas APK gabungan `whatsgo-v1.0.0-universal.apk` (~55.3 MB) yang mendukung semua ABI untuk memudahkan sideloading langsung oleh pengguna umum tanpa perlu memeriksa arsitektur CPU perangkat mereka.
3. **Integritas & Otomasi Rilis:**
   - **Skrip Build Lokal:** `scripts/build_release.ps1` mengotomatisasi kompilasi, penghitungan hash SHA-256 (`dist/release/checksums.txt`), dan verifikasi tanda tangan APK (`apksigner`).
   - **GitHub Actions CI/CD:** `.github/workflows/release.yml` secara otomatis membangun berkas rilis dan mempublikasikannya ke GitHub Releases saat git tag rilis (misal `v1.0.0`) di-*push*.
   - **F-Droid Recipe:** `metadata/whatsgo.nunorifa.my.id.yml` menyediakan spesifikasi metadata untuk pengajuan ke katalog repositori F-Droid open-source.


