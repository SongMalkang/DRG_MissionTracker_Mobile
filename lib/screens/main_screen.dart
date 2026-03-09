import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_missions_tab.dart';
import 'highlights_tab.dart';
import 'deep_dives_tab.dart';
import 'dwarf_voice_tab.dart';
import 'settings_screen.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../services/settings_service.dart';
import '../services/mission_service.dart';
import '../services/update_service.dart';
import '../widgets/changelog_dialog.dart';
import '../widgets/update_dialog.dart';
import '../widgets/debug_menu.dart';
import '../widgets/pwa_install_guide.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _currentLang = 'KR';
  String _currentSeason = 's0';
  bool _showWarnings = true;
  final SettingsService _settingsService = SettingsService();
  final MissionService _missionService = MissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _missionService.addListener(_onDataChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _missionService.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _missionService.pausePeriodicRefresh();
    } else if (state == AppLifecycleState.resumed) {
      _missionService.resumePeriodicRefresh();
    }
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    final lang = await _settingsService.getLanguage();
    final season = await _settingsService.getSeason();
    final showWarnings = await _settingsService.getShowWarnings();
    await _missionService.initialize();

    if (mounted) {
      setState(() {
        _currentLang = lang;
        _currentSeason = season;
        _showWarnings = showWarnings;
      });
      // 언어 로드 완료 후 업데이트 확인 (비동기, UI 블로킹 없음)
      unawaited(_checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService().checkForUpdate();
    if (info != null && mounted) {
      // 첫 프레임 렌더링 완료 후 업데이트 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showUpdateDialog(context, info, _currentLang);
      });
    } else if (mounted) {
      // 업데이트 없을 때만 changelog 팝업 확인 (중복 팝업 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkAndShowChangelog(context, _currentLang);
      });
    }
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
      LiveMissionsTab(
        lang: _currentLang,
        currentSeason: _currentSeason,
        onSeasonChange: _onSeasonChange,
        showWarnings: _showWarnings,
      ),
      HighlightsTab(lang: _currentLang, showWarnings: _showWarnings),
      DeepDivesTab(lang: _currentLang),
      DwarfVoiceTab(lang: _currentLang), // kIsWeb 필터 해제 (GSG 데모용 — 복원: if (!kIsWeb) 추가)
    ];

    return ColoredBox(
      color: const Color(0xFF0D0D0D), // Scaffold 바깥 영역 배경
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: AnimatedBosco(
                  onLongPress: kDebugMode
                      ? () => showDebugMenu(
                            context: context,
                            currentLang: _currentLang,
                            missionService: _missionService,
                          )
                      : null,
                ),
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
                  icon: const Icon(Icons.help_outline),
                  tooltip: i18n[_currentLang]!['pwa_guide_title'],
                  onPressed: () =>
                      showPwaInstallGuide(context, _currentLang),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
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
                    // Reload show_warnings setting when returning from settings
                    final showWarnings = await _settingsService.getShowWarnings();
                    if (mounted && showWarnings != _showWarnings) {
                      setState(() {
                        _showWarnings = showWarnings;
                      });
                    }
                  },
                ),
              ],
              bottom: _buildAppBarBottom(),
            ),
            body: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: tabs,
                  ),
                ),
              ],
            ),
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
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: i18n[_currentLang]!['live']),
                  BottomNavigationBarItem(icon: const Icon(Icons.star), label: i18n[_currentLang]!['highlights']),
                  BottomNavigationBarItem(icon: const Icon(Icons.diamond), label: i18n[_currentLang]!['deep_dives']),
                  BottomNavigationBarItem(icon: const Icon(Icons.casino), label: i18n[_currentLang]!['dwarf_voice']), // kIsWeb 필터 해제
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSize? _buildAppBarBottom() {
    final isRefreshing = _missionService.status == DataStatus.refreshing;
    final isOffline = _missionService.status == DataStatus.offline;
    final isOutdated = _missionService.status == DataStatus.outdated;

    if (isRefreshing) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (isOffline || isOutdated) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: GestureDetector(
          onTap: () => _missionService.forceRefresh(),
          child: Container(
            height: 28,
            color: isOutdated
                ? Colors.red.withValues(alpha: 0.8)
                : Colors.orange.withValues(alpha: 0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutdated ? Icons.warning_amber_rounded : Icons.cloud_off,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isOutdated
                      ? (i18n[_currentLang]!['signal_lost'] ?? 'STALE DATA')
                      : (i18n[_currentLang]!['offline_mode'] ?? 'OFFLINE MODE'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      );
    }

    return null;
  }
}

class AnimatedBosco extends StatefulWidget {
  final VoidCallback? onLongPress;
  const AnimatedBosco({super.key, this.onLongPress});

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
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _animation,
        child: Transform.rotate(
          angle: -0.25,
          child: Image.asset(
            AppConstants.boscoImage,
            width: 35,
            height: 35,
          ),
        ),
      ),
    );
  }
}
