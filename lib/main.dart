import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/strings_service.dart';

// 조건부 임포트: 웹에서는 no-op stub, 네이티브에서는 AlarmManager+Notification 초기화
import 'platform/platform_init_stub.dart'
    if (dart.library.io) 'platform/platform_init_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 전용 초기화 (웹에서는 no-op)
  await platformInit();

  // 번역 캐시 로드 (빠름) + 백그라운드 갱신 예약
  await StringsService().initialize();
  runApp(const DRGMissionTrackerApp());
}

class DRGMissionTrackerApp extends StatelessWidget {
  const DRGMissionTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    return MaterialApp(
      title: 'Bosco Terminal',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF9800),
        splashColor: Colors.orange.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9800),
          secondary: Color(0xFFFFB74D),
          surface: Color(0xFF242424),
        ),
        textTheme: GoogleFonts.russoOneTextTheme(
          baseTheme.textTheme.apply(bodyColor: Colors.grey[300], displayColor: Colors.white),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A), centerTitle: true, elevation: 0),
      ),
      home: const CustomSplashScreen(),
    );
  }
}
