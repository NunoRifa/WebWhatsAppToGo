# Agent Instructions & Guidelines: WhatsGo

Aturan kerja agen untuk proyek **WhatsGo (WA Web To Go Reborn)**:

> **Aturan Utama:** Lihat rincian lengkap pedoman proyek dan aturan wajib pembaruan [README.md](file:///d:/Nuno/WebWhatsAppToGo/README.md) di [**.agents/rules/project_rules.md**](file:///d:/Nuno/WebWhatsAppToGo/.agents/rules/project_rules.md).

### Ringkasan Cepat:
1. **README.md Progress Update:** Setiap kali sebuah milestone atau fitur baru selesai dikerjakan, agen **WAJIB** memperbarui status checkbox pada seksi `Roadmap Pengembangan` dan menjelaskan fungsionalitasnya pada seksi `Fitur Unggulan` di `README.md`.
2. **Session Persistence:** Dilarang menghapus konfigurasi IndexedDB dan LocalStorage WebView (`clearCache: false`).
3. **Application ID:** Tetap gunakan `whatsgo.nunorifa.my.id`.
4. **Git Commits:** Gunakan format Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
