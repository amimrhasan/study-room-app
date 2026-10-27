import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../bridge/js_bridge_handler.dart';
import '../config/app_config.dart';
import '../services/local_server_service.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  bool _isServerReady = false;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initLocalServer();
  }

  Future<void> _initLocalServer() async {
    await LocalServerService().startServer();
    if (mounted) {
      setState(() {
        _isServerReady = true;
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<bool> _handleBackNavigation() async {
    if (_webViewController == null) return true;

    // First check if fullscreen or modal or sub-level is open inside the Study Room app
    final result = await _webViewController!.evaluateJavascript(source: '''
      (function() {
        // 1. Close open modals/popups first
        const openModal = document.querySelector('.modalback.show');
        if (openModal && openModal.id !== 'confirmBack') {
          openModal.classList.remove('show');
          return 'HANDLED';
        }
        // 2. Exit pseudo-fullscreen video if active
        const vs = document.getElementById('videoShell');
        if (vs && (vs.classList.contains('pseudo-fullscreen') || vs.classList.contains('fs-portrait-rotate'))) {
          const fsBtn = document.getElementById('btnFullscreen');
          if (fsBtn) fsBtn.click();
          return 'HANDLED';
        }
        // 3. Step back inside Class Hierarchy (Player -> Classes -> Chapters -> Subjects)
        const studyView = document.getElementById('studyRoomView');
        const studyBackBtn = document.getElementById('studyBackBtn');
        if (studyView && studyView.classList.contains('active') && studyBackBtn && !studyBackBtn.classList.contains('hidden')) {
          studyBackBtn.click();
          return 'HANDLED';
        }
        // 4. Step back from Confirm Setup View or Study Tracker View or Result View
        const confirmSetupView = document.getElementById('confirmSetupView');
        if (confirmSetupView && confirmSetupView.classList.contains('active')) {
          const bBtn = document.getElementById('backFromStep3Btn');
          if (bBtn) bBtn.click();
          return 'HANDLED';
        }
        const trackerView = document.getElementById('studyTrackerView');
        if (trackerView && trackerView.classList.contains('active')) {
          const tBack = document.getElementById('trackerBackBtn');
          if (tBack) tBack.click();
          return 'HANDLED';
        }
        const resultView = document.getElementById('resultView');
        if (resultView && resultView.classList.contains('active')) {
          const rBack = document.getElementById('resultBackBtn');
          if (rBack) rBack.click();
          return 'HANDLED';
        }
        // 5. If on any non-Home tab, return to Home tab
        const homeView = document.getElementById('homeView');
        if (homeView && !homeView.classList.contains('active')) {
          const homeBtn = document.querySelector('[data-target="homeView"]');
          if (homeBtn) {
            homeBtn.click();
            return 'HANDLED';
          }
        }
        return 'EXIT';
      })();
    ''');

    if (result == 'HANDLED') {
      return false;
    }

    if (await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldExit = await _handleBackNavigation();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.darkBg,
        body: SafeArea(
          child: !_isServerReady
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConfig.primaryGreen,
                  ),
                )
              : Stack(
                  children: [
                    InAppWebView(
                      key: _webViewKey,
                      initialUrlRequest: URLRequest(
                        url: WebUri(LocalServerService().entryUrl),
                      ),
                      initialUserScripts: UnmodifiableListView<UserScript>([
                        UserScript(
                          source: '''
                            window.FlutterOrientationChannel = {
                              postMessage: function(msg) {
                                if (window.flutter_inappwebview) {
                                  window.flutter_inappwebview.callHandler('FlutterOrientationChannel', msg);
                                }
                              }
                            };
                            window.FlutterDownloadChannel = {
                              postMessage: function(msg) {
                                if (window.flutter_inappwebview) {
                                  window.flutter_inappwebview.callHandler('FlutterDownloadChannel', msg);
                                }
                              }
                            };
                          ''',
                          injectionTime:
                              UserScriptInjectionTime.AT_DOCUMENT_START,
                        ),
                      ]),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        iframeAllow:
                            'autoplay; fullscreen; encrypted-media; picture-in-picture',
                        iframeAllowFullscreen: true,
                        useShouldOverrideUrlLoading: true,
                        allowFileAccessFromFileURLs: true,
                        allowUniversalAccessFromFileURLs: true,
                        mixedContentMode:
                            MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                        supportZoom: false,
                        builtInZoomControls: false,
                        displayZoomControls: false,
                        transparentBackground: false,
                        userAgent:
                            'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;

                        controller.addJavaScriptHandler(
                          handlerName: 'FlutterOrientationChannel',
                          callback: (args) {
                            if (args.isNotEmpty) {
                              JsBridgeHandler.handleOrientationMessage(
                                args.first.toString(),
                              );
                            }
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'FlutterDownloadChannel',
                          callback: (args) {
                            if (args.isNotEmpty) {
                              JsBridgeHandler.handleDownloadMessage(
                                context,
                                args.first.toString(),
                              );
                            }
                          },
                        );
                      },
                      onEnterFullscreen: (controller) {
                        JsBridgeHandler.handleOrientationMessage('landscape');
                      },
                      onExitFullscreen: (controller) {
                        JsBridgeHandler.handleOrientationMessage('portrait');
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri == null) {
                          return NavigationActionPolicy.ALLOW;
                        }

                        final host = uri.host.toLowerCase();
                        final isMainFrame = navigationAction.isForMainFrame;

                        // Keep localhost & internal asset loads inside the app
                        if (host == 'localhost' ||
                            host == '127.0.0.1' ||
                            uri.scheme == 'file' ||
                            uri.scheme == 'data' ||
                            uri.scheme == 'blob' ||
                            uri.scheme == 'about') {
                          return NavigationActionPolicy.ALLOW;
                        }

                        // Allow embedded iframes (YouTube, Google Drive preview, Mega, Vimeo, etc.)
                        if (!isMainFrame) {
                          return NavigationActionPolicy.ALLOW;
                        }

                        // External target="_blank" links (like "নতুন ট্যাবে ওপেন" or YouTube watch link) open in system browser/YouTube app
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onCreateWindow: (controller, createWindowAction) async {
                        final uri = createWindowAction.request.url;
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                        return false;
                      },
                      onReceivedError: (controller, request, error) {
                        if (request.isForMainFrame == true) {
                          // Fallback to direct asset load if localhost port had any conflict
                          controller.loadFile(
                            assetFilePath: AppConfig.initialAssetPath,
                          );
                        }
                      },
                    ),
                    if (_hasLoadError)
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _hasLoadError = false);
                            _webViewController?.reload();
                          },
                          child: const Text('পুনরায় লোড করো'),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
