import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../constants/download_scripts.dart';
import '../constants/notification_scripts.dart';
import '../constants/responsive_scripts.dart';
import '../services/biometric_service.dart';
import '../services/download_service.dart';
import '../services/foreground_service.dart';
import '../services/user_agent_service.dart';
import '../widgets/direct_chat_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/lock_overlay.dart';
import '../widgets/slim_app_bar.dart';
import '../widgets/user_agent_dialog.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  static const MethodChannel _appChannel = MethodChannel('whatsgo.nunorifa.my.id/app');

  InAppWebViewController? _webViewController;
  String _currentUserAgent = AppConstants.defaultDesktopUserAgent;
  bool _isDesktopMode = false;
  double _progress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showSlimBar = true;
  bool _isInChat = false;

  // Foreground Service & Notification settings
  bool _isForegroundServiceEnabled = true;
  bool _hideNotificationPreview = false;

  // Biometric App Lock settings
  bool _isBiometricEnabled = false;
  int _lockTimeoutMinutes = 0;
  bool _isAppLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialConfiguration();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      BiometricService.recordAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _checkAppLockOnResume();
    }
  }

  Future<void> _checkAppLockOnResume() async {
    final shouldLock = await BiometricService.shouldLockOnResume();
    if (shouldLock && mounted) {
      setState(() {
        _isAppLocked = true;
      });
    }
  }

  Future<void> _loadInitialConfiguration() async {
    final ua = await UserAgentService.getUserAgent();
    final desktop = await UserAgentService.isDesktopModeEnabled();
    final serviceEnabled = await AppForegroundService.isServiceEnabledPreference();
    final hidePreview = await AppForegroundService.isHidePreviewPreference();
    final bioEnabled = await BiometricService.isBiometricEnabled();
    final timeout = await BiometricService.getLockTimeoutMinutes();

    // Request notification & media permissions for Android
    await Permission.notification.request();

    if (mounted) {
      setState(() {
        _currentUserAgent = ua;
        _isDesktopMode = desktop;
        _isForegroundServiceEnabled = serviceEnabled;
        _hideNotificationPreview = hidePreview;
        _isBiometricEnabled = bioEnabled;
        _lockTimeoutMinutes = timeout;
        if (bioEnabled) {
          _isAppLocked = true;
        }
      });
    }

    // Start background foreground service if enabled
    if (serviceEnabled) {
      await AppForegroundService.startService();
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
      allowFileAccess: true,
      allowContentAccess: true,
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
      UserScript(
        source: NotificationScripts.notificationInterceptionScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      UserScript(
        source: DownloadScripts.blobInterceptorScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  Future<PermissionResponse> _handlePermissionRequest(
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
    return PermissionResponse(
      resources: resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  /// Inject or remove responsive CSS/JS based on current desktop toggle
  Future<void> _applyResponsiveMode() async {
    if (_webViewController == null) return;

    if (!_isDesktopMode) {
      await _webViewController!.injectCSSCode(source: ResponsiveScripts.mobileCss);
      await _webViewController!.evaluateJavascript(source: ResponsiveScripts.mobileJs);
    } else {
      await _webViewController!.evaluateJavascript(source: ResponsiveScripts.disableMobileScript);
    }
  }

  void _reloadPage() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
      _progress = 0.0;
      _isInChat = false;
    });
    _webViewController?.reload();
  }

  void _toggleDesktopMode() async {
    final newMode = !_isDesktopMode;
    await UserAgentService.setDesktopModeEnabled(newMode);
    setState(() {
      _isDesktopMode = newMode;
      _isInChat = false;
    });
    _applyResponsiveMode();
  }

  /// Move app to background without destroying process or WebSocket connection
  Future<void> _moveTaskToBack() async {
    try {
      await _appChannel.invokeMethod('moveTaskToBack');
    } catch (e) {
      SystemNavigator.pop();
    }
  }

  void _openDirectChat() {
    DirectChatDialog.show(
      context,
      onStartChat: (targetUrl) {
        _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(targetUrl)),
        );
      },
    );
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
    return StatefulBuilder(
      builder: (context, setModalState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
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

                  // Direct Chat shortcut
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: AppConstants.primaryTeal),
                    title: const Text('Direct Chat'),
                    subtitle: const Text('Kirim pesan tanpa simpan nomor kontak'),
                    onTap: () {
                      Navigator.pop(context);
                      _openDirectChat();
                    },
                  ),

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

                  const Divider(),

                  // Foreground Service Toggle
                  SwitchListTile(
                    title: const Text('Layanan Latar Belakang (Siaga)'),
                    subtitle: const Text('Menjaga koneksi tetap aktif agar notifikasi masuk lancar'),
                    value: _isForegroundServiceEnabled,
                    onChanged: (val) async {
                      setModalState(() {
                        _isForegroundServiceEnabled = val;
                      });
                      setState(() {
                        _isForegroundServiceEnabled = val;
                      });
                      await AppForegroundService.setServiceEnabledPreference(val);
                      if (val) {
                        await AppForegroundService.startService();
                      } else {
                        await AppForegroundService.stopService();
                      }
                    },
                  ),

                  // Privacy Notification Masking
                  SwitchListTile(
                    title: const Text('Sembunyikan Isi Pesan di Notifikasi'),
                    subtitle: const Text('Hanya tampilkan nama pengirim tanpa teks pesan'),
                    value: _hideNotificationPreview,
                    onChanged: (val) async {
                      setModalState(() {
                        _hideNotificationPreview = val;
                      });
                      setState(() {
                        _hideNotificationPreview = val;
                      });
                      await AppForegroundService.setHidePreviewPreference(val);
                    },
                  ),

                  const Divider(),

                  // Security & Biometric Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Keamanan & Privasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryTeal,
                      ),
                    ),
                  ),

                  // Biometric App Lock Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppConstants.primaryTeal),
                    title: const Text('Kunci Sidik Jari / Biometrik'),
                    subtitle: const Text('Kunci WhatsGo saat aplikasi ditutup atau di latar belakang'),
                    value: _isBiometricEnabled,
                    onChanged: (val) async {
                      final authSuccess = await BiometricService.authenticate(
                        reason: val
                            ? 'Konfirmasi biometrik atau PIN untuk mengaktifkan kunci'
                            : 'Konfirmasi biometrik atau PIN untuk menonaktifkan kunci',
                      );
                      if (authSuccess) {
                        await BiometricService.setBiometricEnabled(val);
                        setModalState(() {
                          _isBiometricEnabled = val;
                        });
                        setState(() {
                          _isBiometricEnabled = val;
                        });
                      }
                    },
                  ),

                  // Auto-Lock Timeout Picker
                  if (_isBiometricEnabled)
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: const Text('Kunci Otomatis'),
                      subtitle: Text(_getTimeoutLabel(_lockTimeoutMinutes)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selected = await _showTimeoutPicker(context, _lockTimeoutMinutes);
                        if (selected != null) {
                          await BiometricService.setLockTimeoutMinutes(selected);
                          setModalState(() {
                            _lockTimeoutMinutes = selected;
                          });
                          setState(() {
                            _lockTimeoutMinutes = selected;
                          });
                        }
                      },
                    ),

                  const Divider(),

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
                    subtitle: const Text('WA Web To Go Reborn - v1.0.0 (Milestone 5)'),
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
          ),
        );
      },
    );
  }

  String _getTimeoutLabel(int minutes) {
    switch (minutes) {
      case 0:
        return 'Segera';
      case 1:
        return 'Setelah 1 menit';
      case 5:
        return 'Setelah 5 menit';
      case 15:
        return 'Setelah 15 menit';
      default:
        return 'Setelah $minutes menit';
    }
  }

  Future<int?> _showTimeoutPicker(BuildContext context, int currentMinutes) {
    final options = [
      {'label': 'Segera', 'value': 0},
      {'label': 'Setelah 1 menit', 'value': 1},
      {'label': 'Setelah 5 menit', 'value': 5},
      {'label': 'Setelah 15 menit', 'value': 15},
    ];

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Kunci Otomatis'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          children: options.map((opt) {
            final isSelected = currentMinutes == opt['value'];
            return ListTile(
              title: Text(opt['label'] as String),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppConstants.primaryTeal : Colors.grey,
              ),
              onTap: () => Navigator.pop(ctx, opt['value'] as int),
            );
          }).toList(),
        );
      },
    );
  }

  void _showUserAgentDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => UserAgentDialog(
        onApplied: (newUa) {
          setState(() {
            _currentUserAgent = newUa;
          });
          _reloadPage();
        },
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
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 0. If app is locked, back button minimizes app to background
        if (_isAppLocked) {
          await _moveTaskToBack();
          return;
        }

        // 1. If currently inside an active chat in 1-column mode, close the chat and return to list
        if (!_isDesktopMode && _isInChat) {
          await _webViewController?.evaluateJavascript(
            source: 'window.whatsGoCloseChat && window.whatsGoCloseChat();',
          );
          return;
        }

        // 2. If browser has web history, navigate back
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
          return;
        }

        // 3. At root of chat list: send app to background (keep WebSocket alive)
        await _moveTaskToBack();
      },
      child: Scaffold(
        body: Column(
          children: [
            // Collapsible / Tap-toggleable Slim Top Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: (!_isAppLocked && _showSlimBar)
                  ? 48.0 + MediaQuery.of(context).padding.top
                  : 0.0,
              child: (!_isAppLocked && _showSlimBar)
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

                      // Register JavaScript Handler for chat state updates
                      controller.addJavaScriptHandler(
                        handlerName: 'onChatStateChanged',
                        callback: (args) {
                          if (args.isNotEmpty && args[0] is bool) {
                            setState(() {
                              _isInChat = args[0] as bool;
                            });
                          }
                        },
                      );

                      // Register JavaScript Handler for incoming web notifications
                      controller.addJavaScriptHandler(
                        handlerName: 'onIncomingWebNotification',
                        callback: (args) async {
                          if (args.isNotEmpty && args[0] is Map) {
                            final data = Map<String, dynamic>.from(args[0] as Map);
                            final title = (data['title'] ?? 'WhatsApp').toString();
                            final body = (data['body'] ?? '').toString();

                            // Dispatch native Android notification with privacy check
                            try {
                              await _appChannel.invokeMethod('showIncomingNotification', {
                                'title': title,
                                'body': body,
                                'hidePreview': _hideNotificationPreview,
                              });
                            } catch (e) {
                              debugPrint('WhatsGo: Error displaying native notification: $e');
                            }
                          }
                        },
                      );

                      // Register JavaScript Handler for Blob file downloads
                      controller.addJavaScriptHandler(
                        handlerName: 'onBlobDownloadRequest',
                        callback: (args) async {
                          if (args.isNotEmpty && args[0] is Map) {
                            final data = Map<String, dynamic>.from(args[0] as Map);
                            final filename = (data['filename'] ?? 'whatsgo_media').toString();
                            final mimeType = (data['mimeType'] ?? 'application/octet-stream').toString();
                            final base64Data = (data['base64Data'] ?? '').toString();

                            if (base64Data.isNotEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mengunduh: $filename...'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }

                              final file = await DownloadService.saveBase64Data(
                                filename: filename,
                                base64Data: base64Data,
                                mimeType: mimeType,
                              );

                              if (file != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tersimpan di Download/WhatsGo: $filename'),
                                    backgroundColor: AppConstants.primaryTeal,
                                    action: SnackBarAction(
                                      label: 'Buka',
                                      textColor: AppConstants.accentGreen,
                                      onPressed: () {
                                        DownloadService.openFileDirectly(file.path, mimeType);
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      );
                    },
                    onPermissionRequest: (controller, request) async {
                      return await _handlePermissionRequest(controller, request);
                    },
                    onDownloadStartRequest: (controller, downloadStartRequest) async {
                      final url = downloadStartRequest.url.toString();
                      final suggestedFilename = downloadStartRequest.suggestedFilename ?? 'whatsgo_file';
                      final mimeType = downloadStartRequest.mimeType ?? 'application/octet-stream';

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mengunduh $suggestedFilename...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      final file = await DownloadService.downloadHttpUrl(
                        url: url,
                        suggestedFilename: suggestedFilename,
                        mimeType: mimeType,
                      );

                      if (file != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tersimpan di Download/WhatsGo: $suggestedFilename'),
                            backgroundColor: AppConstants.primaryTeal,
                            action: SnackBarAction(
                              label: 'Buka',
                              textColor: AppConstants.accentGreen,
                              onPressed: () {
                                DownloadService.openFileDirectly(file.path, mimeType);
                              },
                            ),
                          ),
                        );
                      }
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
                      // Apply responsive single-column layout
                      await _applyResponsiveMode();
                      // Ensure notification and download scripts are active
                      await controller.evaluateJavascript(
                        source: NotificationScripts.notificationInterceptionScript,
                      );
                      await controller.evaluateJavascript(
                        source: DownloadScripts.blobInterceptorScript,
                      );
                    },
                    onReceivedError: (controller, request, error) {
                      if (request.isForMainFrame ?? false) {
                        setState(() {
                          _isLoading = false;
                          _hasError = true;
                          _errorMessage = error.description;
                        });
                      }
                    },
                    onScrollChanged: (controller, x, y) {
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
                            color: AppConstants.primaryTeal.withValues(alpha: 0.85),
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

                  // Lock Screen Overlay (Privacy Protection)
                  if (_isAppLocked)
                    Positioned.fill(
                      child: LockOverlay(
                        onUnlock: () {
                          setState(() {
                            _isAppLocked = false;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // WhatsApp-styled Floating Action Button for Direct Chat
        floatingActionButton: _isAppLocked
            ? null
            : FloatingActionButton(
                backgroundColor: AppConstants.accentGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                tooltip: 'Direct Chat (Kirim Pesan Tanpa Simpan Kontak)',
                onPressed: _openDirectChat,
                child: const Icon(Icons.chat, size: 24),
              ),
      ),
    );
  }
}
