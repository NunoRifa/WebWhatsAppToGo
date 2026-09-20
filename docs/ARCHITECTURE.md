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
│  └── Settings Sheet (User-Agent Manager & Logout)      │
├────────────────────────────────────────────────────────┤
│  Lapis InAppWebView (Android System WebView Engine)    │
│  ├── WebSettings: Desktop UA, DOM Storage, WebRTC      │
│  ├── Pre-document Script: Win32 & Google Inc. Spoofing │
│  └── onLoadStop Injection:                             │
│       ├── Responsive CSS (1-Column Layout)             │
│       └── MutationObserver JS (#side vs #main)         │
├────────────────────────────────────────────────────────┤
│  Native Android Bridge (Kotlin MethodChannel)          │
│  └── moveTaskToBack(true) saat Back di Root List       │
├────────────────────────────────────────────────────────┤
│  Komponen Utilitas                                     │
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

## 5. Strategi Anti-Obsolescence (Tahan Masa Depan)

Aplikasi klien WhatsApp Web lama umumnya gagal karena string User-Agent di-hardcode ke versi browser lama. Ketika WhatsApp menaikkan syarat minimum browser, seluruh aplikasi menjadi rusak.

WhatsGo mengatasi masalah ini dengan dua lapis perlindungan:
1. **Pembaruan Mandiri Pengguna:** Pengguna dapat membuka menu *Pengaturan WhatsGo -> Konfigurasi User-Agent* dan memasukkan string Chrome Desktop terkini.
2. **Tombol Reset:** Kemampuan untuk kembali ke string default yang terbukti stabil sewaktu-waktu.

---

## 6. Jaminan Keamanan & Privasi Data

- **Zero Middleware Server:** Tidak ada peladen (server) perantara atau API proxy yang digunakan. Seluruh lalu lintas data bergerak langsung antara WebView perangkat dengan server resmi `*.whatsapp.com`.
- **Enkripsi End-to-End Bawaan:** Enkripsi end-to-end asli WhatsApp Web tetap berjalan secara utuh melalui mesin Web Cryptography API di dalam WebView.
- **Penyimpanan Lokal:** Cookie sesi dan kredensial IndexedDB disimpan di direktori aplikasi privat Android (`/data/data/whatsgo.nunorifa.my.id/app_webview`).
