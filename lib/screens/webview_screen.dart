import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../services/user_agent_service.dart';
import '../widgets/error_view.dart';
import '../widgets/slim_app_bar.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  String _currentUserAgent = AppConstants.defaultDesktopUserAgent;
  bool _isDesktopMode = false;
  double _progress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showSlimBar = true;

  @override
  void initState() {
    super.initState();
    _loadInitialConfiguration();
  }

  Future<void> _loadInitialConfiguration() async {
    final ua = await UserAgentService.getUserAgent();
    final desktop = await UserAgentService.isDesktopModeEnabled();
    if (mounted) {
      setState(() {
        _currentUserAgent = ua;
        _isDesktopMode = desktop;
      });
    }
  }

  InAppWebViewSettings _buildWebViewSettings() {
    return InAppWebViewSettings(
      userAgent: _currentUserAgent,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      clearCache: false,
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      useHybridComposition: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      allowsInlineMediaPlayback: true,
      transparentBackground: false,
      cacheMode: CacheMode.LOAD_DEFAULT,
    );
  }

  UnmodifiableListView<UserScript> _buildInitialUserScripts() {
    return UnmodifiableListView([
      UserScript(
        source: AppConstants.platformSpoofScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  Future<void> _handlePermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    final resources = request.resources;
    for (final resource in resources) {
      if (resource == PermissionResourceType.CAMERA) {
        await Permission.camera.request();
      } else if (resource == PermissionResourceType.MICROPHONE) {
        await Permission.microphone.request();
      }
    }
    // Grant resources after requesting Android permissions
    return controller.android.grantPermissions(
      request: request,
      resources: resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  void _reloadPage() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
      _progress = 0.0;
    });
    _webViewController?.reload();
  }

  void _toggleDesktopMode() async {
    final newMode = !_isDesktopMode;
    await UserAgentService.setDesktopModeEnabled(newMode);
    setState(() {
      _isDesktopMode = newMode;
    });
    _reloadPage();
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildSettingsSheet(ctx),
    );
  }

  Widget _buildSettingsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengaturan WhatsGo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Toggle Desktop View
            SwitchListTile(
              title: const Text('Mode Desktop Penuh'),
              subtitle: const Text('Tampilkan 2-kolom bawaan WhatsApp Web'),
              value: _isDesktopMode,
              onChanged: (val) {
                Navigator.pop(context);
                _toggleDesktopMode();
              },
            ),

            // User-Agent Editor
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Konfigurasi User-Agent'),
              subtitle: Text(
                _currentUserAgent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showUserAgentDialog();
              },
            ),

            // Clear Cache / Logout
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: const Text(
                'Bersihkan Cache & Cookie',
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: const Text('Akan mengeluarkan Anda dari sesi login saat ini'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearSession();
              },
            ),

            const Divider(),

            // About
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang WhatsGo'),
              subtitle: const Text('WA Web To Go Reborn - v1.0.0'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'WhatsGo',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'WhatsApp Web Client for Android',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserAgentDialog() {
    final controller = TextEditingController(text: _currentUserAgent);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Ubah String User-Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan User-Agent Chrome Desktop versi terbaru jika WhatsApp memblokir akses browser.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User-Agent String',
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await UserAgentService.resetToDefault();
              final defaultUa = await UserAgentService.getUserAgent();
              setState(() {
                _currentUserAgent = defaultUa;
              });
              Navigator.pop(dialogCtx);
              _reloadPage();
            },
            child: const Text('Reset ke Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUa = controller.text.trim();
              if (newUa.isNotEmpty) {
                await UserAgentService.setUserAgent(newUa);
                setState(() {
                  _currentUserAgent = newUa;
                });
                Navigator.pop(dialogCtx);
                _reloadPage();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan & Muat Ulang'),
          ),
        ],
      ),
    );
  }

  void _confirmClearSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan Sesi Login?'),
        content: const Text(
          'Tindakan ini akan menghapus cookie dan data lokal WhatsApp Web. Anda harus memindai QR Code ulang untuk masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await InAppWebViewController.clearAllCache();
              final cookieManager = CookieManager.instance();
              await cookieManager.deleteAllCookies();
              _reloadPage();
            },
            child: const Text('Hapus Sesi', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Try navigating back within WebView history first
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
          return;
        }

        // If at root of history, prompt or allow normal backgrounding
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Collapsible / Tap-toggleable Slim Top Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _showSlimBar ? 48.0 + MediaQuery.of(context).padding.top : 0.0,
              child: _showSlimBar
                  ? SlimAppBar(
                      progress: _progress,
                      isLoading: _isLoading,
                      isDesktopMode: _isDesktopMode,
                      onReload: _reloadPage,
                      onToggleDesktopMode: _toggleDesktopMode,
                      onOpenSettings: _showSettingsModal,
                    )
                  : const SizedBox.shrink(),
            ),

            // Main Content Area: InAppWebView or ErrorView
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(AppConstants.whatsAppWebUrl),
                    ),
                    initialSettings: _buildWebViewSettings(),
                    initialUserScripts: _buildInitialUserScripts(),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onPermissionRequest: (controller, request) async {
                      await _handlePermissionRequest(controller, request);
                      return null;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _progress = 0.1;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                        if (progress >= 100) {
                          _isLoading = false;
                        }
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {
                        _isLoading = false;
                        _progress = 1.0;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      // Only show full error view if the main frame failed to load
                      if (request.isForMainFrame ?? false) {
                        setState(() {
                          _isLoading = false;
                          _hasError = true;
                          _errorMessage = error.description;
                        });
                      }
                    },
                    onScrollChanged: (controller, x, y) {
                      // Auto-hide slim bar on downward scroll, reveal on upward scroll
                      if (y > 50 && _showSlimBar) {
                        setState(() {
                          _showSlimBar = false;
                        });
                      } else if (y <= 10 && !_showSlimBar) {
                        setState(() {
                          _showSlimBar = true;
                        });
                      }
                    },
                  ),

                  // Floating small trigger to unhide toolbar when collapsed
                  if (!_showSlimBar)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSlimBar = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryTeal.withOpacity(0.85),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  // Error Overlay
                  if (_hasError)
                    Positioned.fill(
                      child: ErrorView(
                        errorMessage: _errorMessage,
                        onRetry: _reloadPage,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

