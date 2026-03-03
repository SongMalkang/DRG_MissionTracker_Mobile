import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';
import '../services/mission_service.dart';
import '../services/deep_dive_service.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late AnimationController _textController;
  late Animation<double> _textFade;

  bool _animationDone = false;
  bool _dataDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Start animations
    _logoController.forward().then((_) {
      _textController.forward();
    });

    // 데이터 프리로딩 (병렬 실행)
    _preloadData();

    // 최소 애니메이션 시간 보장 (2.5초)
    Timer(const Duration(milliseconds: 2500), () {
      _animationDone = true;
      _tryNavigate();
    });
  }

  Future<void> _preloadData() async {
    await Future.wait([
      MissionService().initialize(),
      DeepDiveService().loadDeepDives(),
    ]);
    _dataDone = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_animationDone && _dataDone && !_navigated && mounted) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Bosco Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/bosco.png',
                width: 180,
                height: 180,
              ),
            ),
            const SizedBox(height: 30),
            // Animated Text
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFade.value,
                  child: child,
                );
              },
              child: Column(
                children: [
                  Text(
                    "BOSCO",
                    style: GoogleFonts.russoOne(
                      fontSize: 32,
                      color: const Color(0xFFFF9800),
                      letterSpacing: 8,
                    ),
                  ),
                  Text(
                    "TERMINAL",
                    style: GoogleFonts.russoOne(
                      fontSize: 18,
                      color: Colors.white54,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
            // Loading indicator at bottom
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Color(0xFFFF9800),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
