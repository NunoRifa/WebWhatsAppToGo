import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/user_agent_service.dart';

class UserAgentDialog extends StatefulWidget {
  final Function(String newUa) onApplied;

  const UserAgentDialog({
    super.key,
    required this.onApplied,
  });

  @override
  State<UserAgentDialog> createState() => _UserAgentDialogState();
}

class _UserAgentDialogState extends State<UserAgentDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUa();
  }

  Future<void> _loadCurrentUa() async {
    final currentUa = await UserAgentService.getUserAgent();
    if (mounted) {
      setState(() {
        _controller.text = currentUa;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetDefault() {
    setState(() {
      _controller.text = AppConstants.defaultDesktopUserAgent;
    });
  }

  Future<void> _saveAndApply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await UserAgentService.setUserAgent(text);
    if (!mounted) return;

    Navigator.pop(context);
    widget.onApplied(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.desktop_windows_outlined, color: AppConstants.primaryTeal),
          SizedBox(width: 10),
          Text(
            'User-Agent Browser',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WhatsGo menggunakan identitas browser desktop untuk mengakses WhatsApp Web. Anda dapat mengubahnya jika WhatsApp memperbarui batas minimum browser di masa mendatang.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: 'User-Agent String',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppConstants.cardDark
                          : const Color(0xFFF0F2F5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Reset ke Default'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryTeal,
                      ),
                      onPressed: _resetDefault,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryTeal,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _saveAndApply,
          child: const Text('Simpan & Muat Ulang'),
        ),
      ],
    );
  }
}

