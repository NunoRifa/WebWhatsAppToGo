# Project Rules: WhatsGo (WA Web To Go Reborn)

Aturan dan pedoman operasional wajib bagi setiap AI Coding Assistant / Agent yang bekerja pada repositori ini.

---

## 1. 📌 Aturan Wajib: Pembaruan Progres pada README.md (Mandatory Rule)

Setiap kali menyelesaikan sebuah **Milestone**, penambahan **fitur baru**, **perbaikan bug (bugfix)**, atau **perubahan arsitektur**:

1. **Update Roadmap:** Agen **WAJIB** segera memperbarui seksi `## 🗺️ Roadmap Pengembangan` pada [README.md](file:///d:/Nuno/WebWhatsAppToGo/README.md):
   - Tandai checkbox milestone yang telah selesai dengan `[x]`.
   - Jika ada fitur tambahan atau sub-task baru, tambahkan poin tersebut ke daftar roadmap.
2. **Update Fitur Unggulan:** Jika fitur baru memengaruhi pengalaman pengguna (UI/UX, utilitas, atau keamanan), tambahkan penjelasan ringkas pada seksi `## 🚀 Fitur Unggulan` di [README.md](file:///d:/Nuno/WebWhatsAppToGo/README.md).
3. **Sinkronisasi Dokumentasi Teknis:**
   - Jika ada perubahan arsitektur atau penambahan endpoint/method native, perbarui [docs/ARCHITECTURE.md](file:///d:/Nuno/WebWhatsAppToGo/docs/ARCHITECTURE.md).
   - Jika ada penambahan cara penggunaan fitur baru oleh pengguna, perbarui [docs/USER_GUIDE.md](file:///d:/Nuno/WebWhatsAppToGo/docs/USER_GUIDE.md).

---

## 2. 🏛️ Pedoman Arsitektur & Lingkungan Proyek

1. **Identitas Paket & Platform:**
   - Platform utama: **Android (Min SDK 24, Target SDK 34)**.
   - Application ID / Namespace: **`whatsgo.nunorifa.my.id`**.
   - Dilarang mengubah Application ID atau struktur package Kotlin tanpa konfirmasi eksplisit pengguna.
2. **InAppWebView & Session Persistence:**
   - Dilarang mengaktifkan `clearCache: true` pada inisialisasi WebView.
   - `domStorageEnabled`, `databaseEnabled`, dan `javaScriptEnabled` harus selalu bernilai `true` agar sesi login WhatsApp Web (IndexedDB & LocalStorage) tetap tersimpan permanen.
3. **Anti-Obsolescence (User-Agent):**
   - Dilarang me-hardcode string User-Agent secara statis di dalam controller WebView.
   - Seluruh pengambilan dan pembaruan User-Agent harus melewati [lib/services/user_agent_service.dart](file:///d:/Nuno/WebWhatsAppToGo/lib/services/user_agent_service.dart) dengan fallback ke [lib/constants/app_constants.dart](file:///d:/Nuno/WebWhatsAppToGo/lib/constants/app_constants.dart).
4. **Mobile Layout 1-Kolom & MutationObserver:**
   - Manipulasi DOM harus menggunakan atribut yang stabil (seperti `#side`, `#main`, `header`).
   - Jangan bergantung pada hash CSS minified WhatsApp Web yang dapat berubah sewaktu-waktu.
   - Selalu sediakan fallback aman (fail-safe) jika selector tidak ditemukan agar aplikasi tidak crash.
5. **Navigasi Back Cerdas:**
   - Tombol Back Android (`PopScope`) harus selalu mempertahankan urutan:
     1. Jika di dalam chat aktif (`_isInChat == true`): tutup chat dan kembali ke daftar pesan (`window.whatsGoCloseChat()`).
     2. Jika WebView memiliki riwayat mundur (`canGoBack`): jalankan `goBack()`.
     3. Jika di daftar chat utama (root): panggil native channel `moveTaskToBack(true)` agar proses WebSocket dan background service tidak dimatikan Android.

---

## 3. 🔒 Keamanan & Privasi Data

1. **Zero Intermediary:** Komunikasi data murni client-to-server antara WebView perangkat dan server resmi `*.whatsapp.com`. Dilarang menyematkan server perantara, proxy logging, atau tracking pihak ketiga.
2. **Izin Android (Permissions):** Hanya minta izin hardware (kamera, mikrofon, storage) saat fitur terkait benar-benar digunakan.

---

## 4. 📝 Standar Git & Commit

1. Gunakan konvensi commit terstruktur (*Conventional Commits*):
   - `feat:` untuk penambahan fitur atau penyelesaian milestone baru.
   - `fix:` untuk perbaikan bug.
   - `docs:` untuk pembaruan dokumentasi (README, docs, PRD).
   - `refactor:` untuk restrukturisasi kode tanpa mengubah fungsionalitas.
2. Jangan meninggalkan file temporary atau artifact build yang tidak perlu di git staging.

