import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
