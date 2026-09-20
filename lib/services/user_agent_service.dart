import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class UserAgentService {
  static const String _prefKeyUserAgent = 'pref_custom_user_agent';
  static const String _prefKeyDesktopMode = 'pref_desktop_mode_forced';

  /// Get active User-Agent string (custom or default)
  static Future<String> getUserAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final customUa = prefs.getString(_prefKeyUserAgent);
    if (customUa != null && customUa.trim().isNotEmpty) {
      return customUa.trim();
    }
    return AppConstants.defaultDesktopUserAgent;
  }

  /// Save custom User-Agent
  static Future<bool> setUserAgent(String newUserAgent) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_prefKeyUserAgent, newUserAgent.trim());
  }

  /// Reset User-Agent to default Chrome Desktop string
  static Future<bool> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_prefKeyUserAgent);
  }

  /// Check whether Desktop layout mode is toggled on
  static Future<bool> isDesktopModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyDesktopMode) ?? false;
  }

  /// Save Desktop layout toggle preference
  static Future<bool> setDesktopModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_prefKeyDesktopMode, enabled);
  }
}

