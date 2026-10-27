import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileExportService {
  /// Handles JSON backup & template downloads triggered inside the Study Room app
  static Future<void> saveAndShareJsonFile({
    required BuildContext context,
    required String filename,
    required String content,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final cleanName = filename.endsWith('.json') ? filename : '$filename.json';
      final file = File('${directory.path}/$cleanName');
      await file.writeAsString(content, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: cleanName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ফাইল সংরক্ষণে সমস্যা হয়েছে: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
