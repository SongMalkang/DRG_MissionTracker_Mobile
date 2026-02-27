import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_missions_tab.dart';
import 'highlights_tab.dart';
import 'deep_dives_tab.dart';
import 'settings_screen.dart';
import '../utils/strings.dart';
import '../services/settings_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _currentLang = 'KR';
  String _currentSeason = 's0';
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await _settingsService.getLanguage();
    final season = await _settingsService.getSeason();
    setState(() {
      _currentLang = lang;
      _currentSeason = season;
    });
  }

  void _onLangChange(String lang) {
    setState(() {
      _currentLang = lang;
    });
    _settingsService.saveLanguage(lang);
  }

  void _onSeasonChange(String season) {
    setState(() {
      _currentSeason = season;
    });
    _settingsService.saveSeason(season);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      LiveMissionsTab(lang: _currentLang, currentSeason: _currentSeason, onSeasonChange: _onSeasonChange),
      HighlightsTab(lang: _currentLang),
      DeepDivesTab(lang: _currentLang),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AnimatedBosco(),
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
                    onLangChange: _onLangChange,
                    currentSeason: _currentSeason,
                    onSeasonChange: _onSeasonChange,
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
            'assets/images/bosco.png',
            width: 35,
            height: 35,
          ),
        ),
      ),
    );
  }
}