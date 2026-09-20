import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/direct_chat_service.dart';

class DirectChatDialog extends StatefulWidget {
  final Function(String targetUrl) onStartChat;

  const DirectChatDialog({
    super.key,
    required this.onStartChat,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String targetUrl) onStartChat,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DirectChatDialog(onStartChat: onStartChat),
    );
  }

  @override
  State<DirectChatDialog> createState() => _DirectChatDialogState();
}

class _DirectChatDialogState extends State<DirectChatDialog> {
  final TextEditingController _countryCodeController = TextEditingController(text: '62');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<String> _recentNumbers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final list = await DirectChatService.getRecentNumbers();
    if (mounted) {
      setState(() {
        _recentNumbers = list;
      });
    }
  }

  void _submit() async {
    final rawNumber = _phoneController.text.trim();
    final countryCode = _countryCodeController.text.trim();

    if (rawNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan nomor telepon tujuan';
      });
      return;
    }

    final sanitized = DirectChatService.sanitizePhoneNumber(
      rawNumber,
      countryCode: countryCode,
    );

    if (sanitized == null) {
      setState(() {
        _errorMessage = 'Nomor telepon tidak valid (7 - 15 digit)';
      });
      return;
    }

    // Save to recents
    await DirectChatService.saveRecentNumber(sanitized);

    // Build URL & trigger callback
    final targetUrl = DirectChatService.buildWhatsAppWebUrl(
      sanitized,
      text: _messageController.text,
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onStartChat(targetUrl);
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _phoneController.text = data!.text!;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.backgroundDark : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.accentGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: AppConstants.primaryTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Direct Chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Buka obrolan langsung ke nomor telepon tanpa perlu menyimpannya ke kontak.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 18),

            // Phone Input Row with Country Code
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country code
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: _countryCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '+',
                      labelText: 'Negara',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Phone number field
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      hintText: 'Contoh: 08123456789',
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste, size: 20),
                        tooltip: 'Tempel dari Clipboard',
                        onPressed: _pasteFromClipboard,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Optional Message Draft Field
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Pesan Awal (Opsional)',
                hintText: 'Tulis pesan yang ingin langsung dikirim...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Recent Numbers Section
            if (_recentNumbers.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nomor Terakhir Digunakan:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  InkWell(
                    onTap: () async {
                      await DirectChatService.clearRecentNumbers();
                      _loadRecents();
                    },
                    child: const Text(
                      'Hapus Riwayat',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _recentNumbers.map((number) {
                  return InputChip(
                    label: Text(
                      '+$number',
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.history, size: 14),
                    onPressed: () {
                      setState(() {
                        // Extract country code if starts with 62
                        if (number.startsWith('62')) {
                          _countryCodeController.text = '62';
                          _phoneController.text = number.substring(2);
                        } else {
                          _phoneController.text = number;
                        }
                        _errorMessage = null;
                      });
                    },
                    onDeleted: () async {
                      await DirectChatService.removeRecentNumber(number);
                      _loadRecents();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Mulai Obrolan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
