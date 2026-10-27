import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/file_export_service.dart';

class JsBridgeHandler {
  static Future<void> handleOrientationMessage(String message) async {
    if (message == 'landscape') {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  static Future<void> handleDownloadMessage(
    BuildContext context,
    String rawJson,
  ) async {
    try {
      final Map<String, dynamic> data = jsonDecode(rawJson);
      final String filename =
          (data['filename'] as String?) ?? 'study-room-backup.json';
      final String content = (data['content'] as String?) ?? '{}';
      await FileExportService.saveAndShareJsonFile(
        context: context,
        filename: filename,
        content: content,
      );
    } catch (e) {
      debugPrint('Download bridge error: $e');
    }
  }
}
