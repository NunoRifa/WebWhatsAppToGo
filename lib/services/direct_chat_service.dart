import 'package:shared_preferences/shared_preferences.dart';

class DirectChatService {
  static const String _prefKeyRecentNumbers = 'pref_recent_direct_chat_numbers';
  static const int _maxRecentNumbers = 10;

  /// Sanitize phone number into international format without '+' or spaces.
  /// Example: '0812-3456-7890' with countryCode '+62' -> '6281234567890'
  static String? sanitizePhoneNumber(String rawNumber, {String countryCode = '62'}) {
    // Clean country code: remove leading '+' and spaces
    var cleanCountry = countryCode.replaceAll(RegExp(r'\D'), '');
    if (cleanCountry.isEmpty) cleanCountry = '62';

    // Remove all non-digit characters except potential leading '+'
    var cleaned = rawNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleanCountry + cleaned.substring(1);
    } else if (!cleaned.startsWith(cleanCountry)) {
      cleaned = cleanCountry + cleaned;
    }

    // Only allow pure digits
    cleaned = cleaned.replaceAll(RegExp(r'\D'), '');

    // Validate length (E.164: usually 7 to 15 digits)
    if (cleaned.length < 7 || cleaned.length > 16) {
      return null;
    }

    return cleaned;
  }

  /// Construct WhatsApp Web send URL
  static String buildWhatsAppWebUrl(String cleanNumber, {String? text}) {
    final buffer = StringBuffer('https://web.whatsapp.com/send?phone=$cleanNumber');
    if (text != null && text.trim().isNotEmpty) {
      buffer.write('&text=${Uri.encodeComponent(text.trim())}');
    }
    return buffer.toString();
  }

  /// Retrieve list of recent phone numbers
  static Future<List<String>> getRecentNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKeyRecentNumbers) ?? [];
  }

  /// Add a phone number to recents (stored at top, max 10 unique items)
  static Future<void> saveRecentNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_prefKeyRecentNumbers) ?? [];

    // Remove if already exists to push to front
    current.remove(phoneNumber);
    current.insert(0, phoneNumber);

    if (current.length > _maxRecentNumbers) {
      current.removeRange(_maxRecentNumbers, current.length);
    }

    await prefs.setStringList(_prefKeyRecentNumbers, current);
  }

  /// Remove a specific number from recents
  static Future<void> removeRecentNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_prefKeyRecentNumbers) ?? [];
    current.remove(phoneNumber);
    await prefs.setStringList(_prefKeyRecentNumbers, current);
  }

  /// Clear all recent numbers
  static Future<void> clearRecentNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRecentNumbers);
  }
}

