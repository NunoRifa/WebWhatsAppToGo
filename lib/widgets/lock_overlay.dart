import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/biometric_service.dart';

class LockOverlay extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockOverlay({
    super.key,
    required this.onUnlock,
  });

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAuthentication();
    });
  }

  Future<void> _triggerAuthentication() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final success = await BiometricService.authenticate(
      reason: 'Otentikasi untuk membuka WhatsGo',
    );

    if (!mounted) return;

    if (success) {
      BiometricService.clearPausedTime();
      widget.onUnlock();
    } else {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Autentikasi gagal atau dibatalkan. Ketuk tombol untuk mencoba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.backgroundDark : const Color(0xFFF0F2F5);
    final cardColor = isDark ? AppConstants.cardDark : Colors.white;
    final textColor = isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight;
    final subtextColor = isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight;

    return PopScope(
      canPop: false,
      child: Material(
        color: bgColor,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Icon with Lock Badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryTeal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.accentGreen.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 48,
                          color: AppConstants.primaryTeal,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'WhatsGo Terkunci',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Gunakan sidik jari, wajah, atau PIN perangkat Anda untuk membuka obrolan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Unlock Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.fingerprint_rounded, size: 24),
                      label: Text(
                        _isAuthenticating ? 'Memverifikasi...' : 'Buka Kunci',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isAuthenticating ? null : _triggerAuthentication,
                    ),
                  ),

                  // Error message if authentication failed
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

