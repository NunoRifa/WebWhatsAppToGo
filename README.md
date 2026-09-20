# WhatsGo (WA Web To Go Reborn)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%207.0%2B-3DDC84?logo=android)](https://android.com)
[![Package](https://img.shields.io/badge/Package-whatsgo.nunorifa.my.id-blue)](https://nunorifa.my.id)
[![License](https://img.shields.io/badge/License-GPLv3%20%2F%20MIT-green)](#lisensi)

**WhatsGo** adalah aplikasi klien Android modern berbasis **Flutter** dan **Modern InAppWebView** untuk menjalankan WhatsApp Web di smartphone. Aplikasi ini merupakan penerus spiritual dari proyek legendaris F-Droid *"WhatsApp Web To Go"* yang telah berhenti berfungsi karena perubahan arsitektur browser dan pemblokiran User-Agent oleh WhatsApp.

WhatsGo dirancang agar **tahan masa depan (anti-obsolescence)**, responsif selayaknya aplikasi native, dan kaya fitur utilitas.

---

## 🚀 Fitur Unggulan

### 1. 📱 Tampilan Responsif 1-Kolom (Mobile-First)
- Mengubah layout desktop 2-kolom WhatsApp Web menjadi 1-kolom yang pas dan nyaman dioperasikan dengan satu tangan.
- Menggunakan **`MutationObserver` cerdas**: saat obrolan dibuka, daftar chat disembunyikan dan ruang chat diperluas 100% selebar layar ponsel.
- Menyuntikkan tombol virtual **"Kembali"** di header obrolan.
- **Toggle Desktop View:** Tombol cepat di toolbar untuk beralih kembali ke tampilan desktop 2-kolom jika dibutuhkan.

### 2. 🛡️ Anti-Obsolescence (Dynamic User-Agent)
- Menggunakan identitas browser Chrome Desktop Windows 64-bit modern secara default untuk mencegah pesan *"Browser tidak didukung"*.
- Dilengkapi **menu konfigurasi User-Agent**: pengguna dapat memperbarui string User-Agent secara mandiri jika WhatsApp menaikkan versi minimum browser di masa mendatang tanpa perlu menunggu rilis APK baru.
- Spoofing properti browser internal (`navigator.platform = 'Win32'`, `navigator.vendor = 'Google Inc.'`).

### 3. 💬 Direct Chat (Kirim Pesan Tanpa Simpan Kontak)
- Floating Action Button (FAB) hijau khas WhatsApp di pojok kanan bawah.
- Dialog cepat dengan pembersihan otomatis format nomor telepon internasional (default kode negara `+62` Indonesia).
- Tombol tempel langsung dari clipboard dan kolom draft pesan awal opsional.
- Menyimpan riwayat hingga 10 nomor terakhir yang pernah dihubungi untuk akses cepat.

### 4. 🔄 Integrasi Tombol Back Android Cerdas
- **Saat di dalam ruang chat:** Menekan tombol Back Android (fisik / gestur) akan menutup obrolan aktif dan kembali ke daftar pesan.
- **Saat di daftar pesan utama:** Menekan tombol Back akan meminimalkan aplikasi ke latar belakang (*move task to back*), menjaga koneksi WebSocket dan sesi WhatsApp tetap aktif.

### 5. 💾 Sesi Persisten (Session Persistence)
- Cookie, LocalStorage, dan database IndexedDB tersimpan secara permanen pada memori aplikasi.
- Anda hanya perlu melakukan pemindaian QR Code **sekali saja** saat login pertama kali.

---

## 🏗️ Tech Stack & Arsitektur

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Framework UI** | Flutter 3.x (Dart) | Material 3 Theming, Responsive Layout, Dialogs |
| **Browser Engine** | `flutter_inappwebview` v6+ | Chromium-based Android System WebView, WebRTC, Service Workers |
| **Penyimpanan Lokal**| `shared_preferences` | User-Agent preference, Direct Chat history, Mode toggle |
| **Native Bridge** | Android Kotlin MethodChannel | `moveTaskToBack` background keep-alive |
| **Keamanan Data** | Direct Client-to-Server | 100% koneksi langsung ke server WhatsApp tanpa server perantara |

Dokumentasi arsitektur lebih dalam dapat dibaca pada [**docs/ARCHITECTURE.md**](docs/ARCHITECTURE.md).

---

## 📂 Struktur Direktori Proyek

```
WebWhatsAppToGo/
├── android/                             # Konfigurasi Native Android
│   ├── app/
│   │   ├── build.gradle                 # Application ID: whatsgo.nunorifa.my.id
│   │   └── src/main/
│   │       ├── AndroidManifest.xml      # Izin Hardware & FileProvider
│   │       └── kotlin/.../MainActivity.kt # Kotlin MethodChannel Handler
│   ├── build.gradle
│   └── settings.gradle
├── docs/                                # Dokumentasi Lengkap
│   ├── ARCHITECTURE.md                  # Arsitektur & Teknis InAppWebView
│   └── USER_GUIDE.md                    # Panduan Penggunaan & Pemecahan Masalah
├── lib/                                 # Kode Sumber Flutter (Dart)
│   ├── constants/
│   │   ├── app_constants.dart           # URL, Colors, Default Desktop UA
│   │   └── responsive_scripts.dart      # Injeksi CSS/JS 1-Kolom & Observer
│   ├── screens/
│   │   └── webview_screen.dart          # Layar Utama InAppWebView & PopScope
│   ├── services/
│   │   ├── direct_chat_service.dart     # Logika sanitasi nomor & riwayat
│   │   └── user_agent_service.dart      # Layanan User-Agent SharedPreferences
│   ├── widgets/
│   │   ├── direct_chat_dialog.dart      # Dialog modal Direct Chat
│   │   ├── error_view.dart              # Layar offline / koneksi error
│   │   └── slim_app_bar.dart            # Auto-hide Slim Toolbar
│   └── main.dart                        # Entrypoint & Material 3 Theming
├── PRD.md                               # Product Requirements Document
├── pubspec.yaml                         # Spesifikasi Dependensi Flutter
└── README.md                            # Dokumentasi Utama
```

---

## 🛠️ Panduan Build & Instalasi

### Prasyarat
1. **Flutter SDK** (versi 3.19.0 atau yang lebih baru).
2. **Java Development Kit (JDK)** versi 17 atau 21.
3. **Android SDK** dengan platform SDK 34 (Android 14).

### Langkah-Langkah

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/your-username/WebWhatsAppToGo.git
   cd WebWhatsAppToGo
   ```

2. **Unduh dependensi Flutter:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat Android / Emulator:**
   ```bash
   flutter run
   ```

4. **Membangun APK Rilis Mandiri:**
   ```bash
   flutter build apk --release
   ```
   File APK hasil kompilasi akan berada di:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🗺️ Roadmap Pengembangan

- [x] **Milestone 1:** Inisialisasi Proyek, Konfigurasi Android (`whatsgo.nunorifa.my.id`), Setup Desktop UA Spoofing, dan Session Persistence.
- [x] **Milestone 2:** Adaptasi Mobile Viewport (Injeksi CSS/JS 1-Kolom), Navigasi Back Cerdas, dan Fitur Direct Chat.
- [ ] **Milestone 3:** Android Foreground Service dengan Persistent Notification untuk menjaga koneksi WebSocket di latar belakang.
- [ ] **Milestone 4:** Manajemen Unduhan & Upload Media Komprehensif (Voice Note mic, Camera/Gallery picker, Local Download Manager).
- [ ] **Milestone 5:** Keamanan Biometrik (Fingerprint & Face Unlock) dan Fallback PIN.
- [ ] **Milestone 6:** Hardening, Pengujian Baterai, dan Rilis Publik GitHub Releases / F-Droid.

---

## ⚖️ Penafian (Disclaimer)

Aplikasi ini adalah klien web pihak ketiga independen yang memuat antarmuka resmi WhatsApp Web. Aplikasi ini **tidak berafiliasi, disponsori, atau didukung secara resmi oleh WhatsApp LLC atau Meta Platforms, Inc.** WhatsApp adalah merek dagang terdaftar milik Meta Platforms, Inc.
