import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_constants.dart';
import 'screens/webview_screen.dart';
import 'services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation and status bar appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConstants.primaryTealDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Android Foreground Service settings
  AppForegroundService.init();

  runApp(const WhatsGoApp());
}

class WhatsGoApp extends StatelessWidget {
  const WhatsGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsGo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryTeal,
          primary: AppConstants.primaryTeal,
          secondary: AppConstants.accentGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryTeal,
          primary: AppConstants.primaryTeal,
          secondary: AppConstants.accentGreen,
          brightness: Brightness.dark,
          surface: AppConstants.cardDark,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryTealDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const WebViewScreen(),
    );
  }
}
