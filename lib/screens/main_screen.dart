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
import 'package:package_info_plus/package_info_plus.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../widgets/changelog_dialog.dart';
import '../widgets/update_dialog.dart';

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
  final MissionService _missionService = MissionService();

  @override
  void initState() {
    super.initState();
    _missionService.addListener(_onDataChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _missionService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    final lang = await _settingsService.getLanguage();
    final season = await _settingsService.getSeason();
    await _missionService.initialize();

    if (mounted) {
      setState(() {
        _currentLang = lang;
        _currentSeason = season;
      });
      // 언어 로드 완료 후 업데이트 확인 (비동기, UI 블로킹 없음)
      _checkForUpdate();
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

  // ── 디버그 액션 메뉴 (보스코 롱프레스) ───────────────────────────────────
  void _showDebugMenu() {
    if (!kDebugMode) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '🛠 DEBUG MENU',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('테스트 Push 알림 발송',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _testPushAlarm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: const Text('Changelog 팝업 표시',
                  style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(ctx);
                final info = await PackageInfo.fromPlatform();
                if (mounted) {
                  showChangelogDialog(context, _currentLang, info.version);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.orange),
              title: const Text('DataStatus 순환',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _cycleDebugStatus();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _testPushAlarm() async {
    try {
      final notifService = NotificationService();

      // 알림 권한 확인 → 미부여 시 요청
      if (!await notifService.hasPermission()) {
        final granted = await notifService.requestPermission();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debug: 알림 권한이 필요합니다 🔒'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      await notifService.showTestNotification(_currentLang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug: 테스트 알림 발송 완료 📡'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug: 알림 실패 — $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _cycleDebugStatus() {
    final current = _missionService.status;
    DataStatus next;

    if (current == DataStatus.online) {
      next = DataStatus.offline;
    } else if (current == DataStatus.offline) {
      next = DataStatus.outdated;
    } else if (current == DataStatus.outdated) {
      next = DataStatus.refreshing;
    } else {
      next = DataStatus.online;
    }

    _missionService.debugSetStatus(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Debug: DataStatus → ${next.name.toUpperCase()}"),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      LiveMissionsTab(
        lang: _currentLang,
        currentSeason: _currentSeason,
        onSeasonChange: _onSeasonChange
      ),
      HighlightsTab(lang: _currentLang),
      DeepDivesTab(lang: _currentLang),
      if (!kIsWeb) DwarfVoiceTab(lang: _currentLang),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: AnimatedBosco(onLongPress: kDebugMode ? _showDebugMenu : null),
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
        bottom: _missionService.status == DataStatus.refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              tabs[_currentIndex],
              if (_missionService.status == DataStatus.offline ||
                  _missionService.status == DataStatus.outdated)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildOfflineWarning(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          heightFactor: 1.0, // 세로 확장 방지: Center가 전체 높이를 차지하지 않도록
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
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
                  if (!kIsWeb) BottomNavigationBarItem(icon: const Icon(Icons.record_voice_over), label: i18n[_currentLang]!['dwarf_voice']),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineWarning() {
    bool isOutdated = _missionService.status == DataStatus.outdated;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOutdated ? Colors.red.withValues(alpha: 0.9) : Colors.orange.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Image.asset(AppConstants.boscoImage, width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOutdated
                      ? (i18n[_currentLang]!['signal_lost'] ?? "SIGNAL LOST!")
                      : (i18n[_currentLang]!['offline_mode'] ?? "OFFLINE MODE"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  isOutdated
                      ? (i18n[_currentLang]!['signal_lost_desc'] ?? "Data is too old.")
                      : (i18n[_currentLang]!['offline_mode_desc'] ?? "Using cached data."),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _missionService.forceRefresh(),
          )
        ],
      ),
    );
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
