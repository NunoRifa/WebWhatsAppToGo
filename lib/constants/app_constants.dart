import 'package:flutter/material.dart';

class AppConstants {
  // WhatsApp Web URL
  static const String whatsAppWebUrl = 'https://web.whatsapp.com';

  // Default modern Chrome Desktop User-Agent (Windows 10/11 64-bit)
  static const String defaultDesktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  // JavaScript to spoof navigator.platform and vendor before page loads
  static const String platformSpoofScript = '''
    (function() {
      try {
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
      } catch (e) {
        console.error('Error spoofing platform properties:', e);
      }
    })();
  ''';

  // Brand and Theme Colors
  static const Color primaryTeal = Color(0xFF005C4B);
  static const Color primaryTealDark = Color(0xFF0B141A);
  static const Color accentGreen = Color(0xFF25D366);
  static const Color backgroundLight = Color(0xFFEFEAE2);
  static const Color backgroundDark = Color(0xFF111B21);
  static const Color cardDark = Color(0xFF202C33);
  static const Color textPrimaryLight = Color(0xFF111B21);
  static const Color textPrimaryDark = Color(0xFFE9EDEF);
  static const Color textSecondaryLight = Color(0xFF667781);
  static const Color textSecondaryDark = Color(0xFF8696A0);
}

