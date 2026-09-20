import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _prefKeyBiometricEnabled = 'pref_biometric_lock_enabled';
  static const String _prefKeyLockTimeout = 'pref_biometric_lock_timeout_minutes';

  static DateTime? _lastPausedTime;

  /// Check if the device hardware supports biometrics or device credentials (PIN/Pattern/Password)
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Check whether the device actually has biometrics or credentials enrolled and ready
  static Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      return (canCheck && biometrics.isNotEmpty) || isSupported;
    } catch (e) {
      debugPrint('Error checking canAuthenticate: $e');
      return false;
    }
  }

  /// Get list of available biometric hardware types (e.g. fingerprint, face, weak, strong)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Failed to get available biometrics: $e');
      return [];
    }
  }

  /// Authenticate the user via Biometric or Device Credential fallback (PIN/Pattern/Password)
  static Future<bool> authenticate({
    String reason = 'Gunakan biometrik atau PIN untuk membuka WhatsGo',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometric/Device Credential is not supported on this device.');
        // Auto-disable if not supported to prevent soft-lock
        await setBiometricEnabled(false);
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows Android PIN/Pattern/Password fallback
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      final errStr = e.toString().toLowerCase();
      // If no credentials or biometrics are enrolled on emulator/device, auto-disable
      if (errStr.contains('notenrolled') ||
          errStr.contains('not available') ||
          errStr.contains('passcodenotset') ||
          errStr.contains('not supported')) {
        await setBiometricEnabled(false);
        return true; // Bypass lock so user is not permanently stuck
      }
      return false;
    }
  }

  /// Check whether biometric app lock is enabled by the user
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBiometricEnabled) ?? false;
  }

  /// Save biometric app lock toggle state
  static Future<bool> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_prefKeyBiometricEnabled, enabled);
  }

  /// Get auto-lock timeout duration in minutes (0 = Immediately, 1, 5, 15)
  static Future<int> getLockTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyLockTimeout) ?? 0;
  }

  /// Save auto-lock timeout duration in minutes
  static Future<bool> setLockTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_prefKeyLockTimeout, minutes);
  }

  /// Record timestamp when application transitions to background / paused state
  static void recordAppPaused() {
    _lastPausedTime = DateTime.now();
  }

  /// Clear the paused timestamp once verified or unlocked
  static void clearPausedTime() {
    _lastPausedTime = null;
  }

  /// Check if the application should be locked when resumed from background
  static Future<bool> shouldLockOnResume() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    // Check whether the device actually supports authentication
    final canAuth = await canAuthenticate();
    if (!canAuth) {
      await setBiometricEnabled(false);
      return false;
    }

    if (_lastPausedTime == null) return false;

    final timeoutMinutes = await getLockTimeoutMinutes();
    if (timeoutMinutes <= 0) {
      // Lock immediately
      return true;
    }

    final elapsed = DateTime.now().difference(_lastPausedTime!);
    return elapsed.inMinutes >= timeoutMinutes;
  }
}

