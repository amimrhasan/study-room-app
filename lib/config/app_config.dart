import 'package:flutter/material.dart';

class AppConfig {
  static const String appTitle = 'Study Room - Junaid';
  static const Color primaryGreen = Color(0xFF07884B);
  static const Color primaryDark = Color(0xFF05663A);
  static const Color darkBg = Color(0xFF0A100D);
  static const Color lightBg = Color(0xFFF2F6F4);

  // Local localhost port used by InAppLocalhostServer so YouTube IFrame API,
  // Firebase Auth/Realtime DB, Google Drive PDF Preview & KaTeX work 100% identically
  // without file:// CORS or YouTube Error 150/153 restrictions.
  static const int localServerPort = 8765;
  static const String initialAssetPath = 'assets/web/index.html';
}
