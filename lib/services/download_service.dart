import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DownloadService {
  static const MethodChannel _appChannel = MethodChannel('whatsgo.nunorifa.my.id/app');
  static const String defaultDownloadPath = '/storage/emulated/0/Download/WhatsGo';

  /// Ensure target directory exists
  static Future<Directory> getDownloadDirectory() async {
    final dir = Directory(defaultDownloadPath);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        debugPrint('WhatsGo: Error creating WhatsGo download dir, using fallback: $e');
        final fallback = Directory('/storage/emulated/0/Download');
        if (!await fallback.exists()) {
          await fallback.create(recursive: true);
        }
        return fallback;
      }
    }
    return dir;
  }

  /// Sanitize filename to avoid invalid filesystem characters
  static String sanitizeFileName(String fileName) {
    var cleaned = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) {
      cleaned = 'whatsgo_${DateTime.now().millisecondsSinceEpoch}';
    }
    return cleaned;
  }

  /// Generate unique file path to prevent accidental overwrites
  static Future<File> getUniqueFile(Directory dir, String fileName) async {
    var targetFile = File('${dir.path}/$fileName');
    if (!await targetFile.exists()) {
      return targetFile;
    }

    final extIndex = fileName.lastIndexOf('.');
    String name = fileName;
    String ext = '';

    if (extIndex != -1) {
      name = fileName.substring(0, extIndex);
      ext = fileName.substring(extIndex);
    }

    int counter = 1;
    while (await targetFile.exists()) {
      targetFile = File('${dir.path}/${name}_$counter$ext');
      counter++;
    }

    return targetFile;
  }

  /// Save base64-encoded file (from blob interceptor)
  static Future<File?> saveBase64Data({
    required String filename,
    required String base64Data,
    String? mimeType,
  }) async {
    try {
      final dir = await getDownloadDirectory();
      final cleanName = sanitizeFileName(filename);
      final file = await getUniqueFile(dir, cleanName);

      final bytes = base64Decode(base64Data);
      await file.writeAsBytes(bytes);

      // Trigger native notification with Open File action
      await notifyDownloadCompleted(
        filePath: file.path,
        fileName: file.uri.pathSegments.last,
        mimeType: mimeType ?? 'application/octet-stream',
      );

      return file;
    } catch (e) {
      debugPrint('WhatsGo: Error saving base64 download: $e');
      return null;
    }
  }

  /// Download file from standard HTTP/HTTPS URL
  static Future<File?> downloadHttpUrl({
    required String url,
    required String suggestedFilename,
    String? mimeType,
  }) async {
    try {
      final dir = await getDownloadDirectory();
      final cleanName = sanitizeFileName(suggestedFilename);
      final file = await getUniqueFile(dir, cleanName);

      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.close();

        // Trigger native notification with Open File action
        await notifyDownloadCompleted(
          filePath: file.path,
          fileName: file.uri.pathSegments.last,
          mimeType: mimeType ?? 'application/octet-stream',
        );

        return file;
      }
      return null;
    } catch (e) {
      debugPrint('WhatsGo: Error downloading HTTP file: $e');
      return null;
    }
  }

  /// Trigger native notification on Android with PendingIntent to open file
  static Future<void> notifyDownloadCompleted({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      await _appChannel.invokeMethod('showDownloadNotification', {
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': mimeType,
      });
    } catch (e) {
      debugPrint('WhatsGo: Error triggering download notification: $e');
    }
  }

  /// Open file directly with default Android application
  static Future<void> openFileDirectly(String filePath, String mimeType) async {
    try {
      await _appChannel.invokeMethod('openFileDirectly', {
        'filePath': filePath,
        'mimeType': mimeType,
      });
    } catch (e) {
      debugPrint('WhatsGo: Error opening file directly: $e');
    }
  }
}
