import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_missions_tab.dart';
import 'highlights_tab.dart';
import 'deep_dives_tab.dart'; // [추가] 딥 다이브 탭 임포트
import 'settings_screen.dart'; // [추가] 설정 화면 임포트
import '../utils/strings.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _currentLang = 'KR';

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      LiveMissionsTab(lang: _currentLang),
      HighlightsTab(lang: _currentLang),
      DeepDivesTab(lang: _currentLang), 
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // [Req 2] 타이틀 가운데 정렬
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AnimatedBosco(), // [Req 2] 좌측에 애니메이션 보스코 배치
        ),
        title: Text(
          i18n[_currentLang]!['title']!,
          style: GoogleFonts.russoOne(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    currentLang: _currentLang,
                    onLangChange: (lang) => setState(() => _currentLang = lang),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: i18n[_currentLang]!['live']),
            BottomNavigationBarItem(icon: const Icon(Icons.star), label: i18n[_currentLang]!['highlights']),
            BottomNavigationBarItem(icon: const Icon(Icons.diamond), label: i18n[_currentLang]!['deep_dives']),
          ],
        ),
      ),
    );
  }
}

class AnimatedBosco extends StatefulWidget {
  const AnimatedBosco({super.key});

  @override
  State<AnimatedBosco> createState() => _AnimatedBoscoState();
}

class _AnimatedBoscoState extends State<AnimatedBosco> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  void _playAnimation() {
    _controller.forward().then((_) => _controller.reverse());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAnimation,
      child: ScaleTransition(
        scale: _animation,
        child: Transform.rotate(
          angle: -0.25,
          child: Image.asset(
            'assets/bosco.png',
            width: 35,
            height: 35,
          ),
        ),
      ),
    );
  }
}