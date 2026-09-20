import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SlimAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double progress;
  final bool isLoading;
  final bool isDesktopMode;
  final VoidCallback onReload;
  final VoidCallback onToggleDesktopMode;
  final VoidCallback onOpenSettings;

  const SlimAppBar({
    super.key,
    required this.progress,
    required this.isLoading,
    required this.isDesktopMode,
    required this.onReload,
    required this.onToggleDesktopMode,
    required this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppConstants.primaryTealDark : AppConstants.primaryTeal;

    return Container(
      color: barBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    // Brand / Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLoading ? Colors.amber : AppConstants.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'WhatsGo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Toggle Desktop / Mobile View
                    IconButton(
                      icon: Icon(
                        isDesktopMode ? Icons.laptop : Icons.phone_android,
                        size: 20,
                        color: isDesktopMode ? AppConstants.accentGreen : Colors.white70,
                      ),
                      tooltip: isDesktopMode ? 'Mode Desktop Aktif' : 'Mode Mobile Aktif',
                      onPressed: onToggleDesktopMode,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // Reload Button
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 20,
                        color: Colors.white,
                      ),
                      tooltip: 'Muat Ulang Halaman',
                      onPressed: onReload,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // Settings / Options Menu
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.white,
                      ),
                      tooltip: 'Pengaturan & Opsi',
                      onPressed: onOpenSettings,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),

            // Progress bar at the bottom of the slim bar
            if (isLoading && progress < 1.0)
              LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accentGreen),
              )
            else
              const SizedBox(height: 2.5),
          ],
        ),
      ),
    );
  }
}

