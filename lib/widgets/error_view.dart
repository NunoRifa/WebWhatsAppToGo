import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppConstants.backgroundDark : AppConstants.backgroundLight,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.redAccent.shade700 : Colors.red.shade100)
                    .withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: isDark ? Colors.redAccent.shade200 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat WhatsApp Web',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.textPrimaryDark : AppConstants.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Pastikan perangkat Anda terhubung ke internet dan coba kembali.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

