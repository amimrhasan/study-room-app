import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config/app_config.dart';

class LocalServerService {
  static final LocalServerService _instance = LocalServerService._internal();
  factory LocalServerService() => _instance;
  LocalServerService._internal();

  InAppLocalhostServer? _localhostServer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> startServer() async {
    if (kIsWeb || _isRunning) return;
    _localhostServer = InAppLocalhostServer(
      port: AppConfig.localServerPort,
      directoryIndex: 'index.html',
      documentRoot: 'assets/web',
      shared: true,
    );
    try {
      await _localhostServer!.start();
      _isRunning = true;
    } catch (e) {
      debugPrint('LocalhostServer start notice: $e');
    }
  }

  String get entryUrl {
    if (kIsWeb) {
      return 'assets/assets/web/index.html';
    }
    return 'http://localhost:${AppConfig.localServerPort}/index.html';
  }

  Future<void> disposeServer() async {
    if (_localhostServer != null && _isRunning) {
      await _localhostServer!.close();
      _isRunning = false;
    }
  }
}
