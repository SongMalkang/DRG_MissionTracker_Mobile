import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/strings.dart';
import '../services/settings_service.dart';
import '../services/mission_service.dart';
import '../services/notification_settings_service.dart';
import '../widgets/settings/notification_settings_section.dart';
import '../widgets/settings/about_section.dart';

// 조건부 임포트: 웹에서는 Android 알림 패키지 import 차단
import '../platform/notification_helpers_stub.dart'
    if (dart.library.io) '../platform/notification_helpers_native.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  final Function(String) onLangChange;
  final String currentSeason;
  final Function(String) onSeasonChange;

  const SettingsScreen({
    super.key,
    required this.currentLang,
    required this.onLangChange,
    required this.currentSeason,
    required this.onSeasonChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showWarnings = true;
  late String _selectedLang;
  late String _selectedSeason;
  final SettingsService _settingsService = SettingsService();
  final MissionService _missionService = MissionService();
  final NotificationSettingsService _notifSettings = NotificationSettingsService();

  // 알림 설정 상태
  bool _notifEnabled = false;
  TimeOfDay _notifTime    = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _notifEndTime = const TimeOfDay(hour: 22, minute: 0);
  List<int> _notifDays = [1, 2, 3, 4, 5, 6, 7];
  Set<String> _excludedTypes = {};
  DateTime? _lastNotificationFired;

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.currentLang;
    _selectedSeason = widget.currentSeason;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final show = await _settingsService.getShowWarnings();
    await _missionService.initialize();

    final notifOn      = await _notifSettings.isEnabled();
    final notifTime    = await _notifSettings.getScheduledTime();
    final notifEndTime = await _notifSettings.getEndTime();
    final notifDays    = await _notifSettings.getEnabledDays();
    final excluded     = await _notifSettings.getExcludedMissionTypes();

    // 마지막 알림 발화 시각 로드
    final prefs = await SharedPreferences.getInstance();
    final lastFiredMs = prefs.getInt('last_notification_fired');
    final lastFired = lastFiredMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastFiredMs)
        : null;

    setState(() {
      _showWarnings   = show;
      _notifEnabled   = notifOn;
      _notifTime      = notifTime;
      _notifEndTime   = notifEndTime;
      _notifDays      = notifDays;
      _excludedTypes  = excluded;
      _lastNotificationFired = lastFired;
    });
  }

  void _nextLang() {
    final langs = i18n.keys.toList();
    final idx = langs.indexOf(_selectedLang);
    final next = langs[(idx + 1) % langs.length];
    setState(() {
      _selectedLang = next;
    });
    widget.onLangChange(next);
  }

  void _prevLang() {
    final langs = i18n.keys.toList();
    final idx = langs.indexOf(_selectedLang);
    final prev = langs[(idx - 1 + langs.length) % langs.length];
    setState(() {
      _selectedLang = prev;
    });
    widget.onLangChange(prev);
  }

  void _nextSeason() {
    final available = _missionService.availableSeasons;
    if (available.isEmpty) return;
    final idx = available.indexOf(_selectedSeason);
    final next = available[(idx + 1) % available.length];
    setState(() {
      _selectedSeason = next;
    });
    widget.onSeasonChange(next);
  }

  void _prevSeason() {
    final available = _missionService.availableSeasons;
    if (available.isEmpty) return;
    final idx = available.indexOf(_selectedSeason);
    final prev = available[(idx - 1 + available.length) % available.length];
    setState(() {
      _selectedSeason = prev;
    });
    widget.onSeasonChange(prev);
  }

  void _toggleWarnings(bool val) {
    setState(() {
      _showWarnings = val;
    });
    _settingsService.saveShowWarnings(val);
  }

  Future<void> _toggleNotification(bool val) async {
    if (val) {
      final granted = await requestNotificationPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(i18n[_selectedLang]!['notif_permission_denied']!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }
    setState(() => _notifEnabled = val);
    await _notifSettings.setEnabled(val);
    if (val) {
      await scheduleNotificationAlarms();
    } else {
      await cancelAllNotificationAlarms();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? (i18n[_selectedLang]!['notif_enabled'] ?? 'Notifications enabled.')
                : (i18n[_selectedLang]!['notif_disabled'] ?? 'Notifications disabled.'),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: val ? Colors.green[700] : Colors.grey[700],
        ),
      );
    }
  }

  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifTime,
    );
    if (picked != null) {
      setState(() => _notifTime = picked);
      await _notifSettings.setScheduledTime(picked.hour, picked.minute);
      if (_notifEnabled) await scheduleNotificationAlarms();
    }
  }

  Future<void> _pickNotifEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifEndTime,
    );
    if (picked != null) {
      setState(() => _notifEndTime = picked);
      await _notifSettings.setEndTime(picked.hour, picked.minute);

      // 종료 시간이 시작 시간보다 앞인 경우 경고
      final startMinutes = _notifTime.hour * 60 + _notifTime.minute;
      final endMinutes = picked.hour * 60 + picked.minute;
      if (endMinutes <= startMinutes && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              i18n[_selectedLang]!['notif_time_warning'] ??
                  'End time is before start time.',
            ),
            backgroundColor: Colors.amber[800],
          ),
        );
      }

      if (_notifEnabled) await scheduleNotificationAlarms();
    }
  }

  Future<void> _toggleNotifDay(int day) async {
    setState(() {
      if (_notifDays.contains(day)) {
        _notifDays.remove(day);
      } else {
        _notifDays.add(day);
      }
    });
    await _notifSettings.setEnabledDays(_notifDays);
    if (_notifEnabled) await scheduleNotificationAlarms();
  }

  Future<void> _toggleExcludedType(String type) async {
    setState(() {
      if (_excludedTypes.contains(type)) {
        _excludedTypes.remove(type);
      } else {
        _excludedTypes.add(type);
      }
    });
    await _notifSettings.setExcludedMissionTypes(_excludedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[_selectedLang]!;
    final seasonLabel = _selectedSeason == "s0"
        ? langMap['standard']!
        : "SEASON ${_selectedSeason.replaceAll('s', '')}";

    return ColoredBox(
      color: const Color(0xFF0D0D0D), // Scaffold 바깥 영역 배경
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Scaffold(
            appBar: AppBar(title: Text(langMap['settings']!)),
            body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Disclaimer (상단 이동)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(langMap['disclaimer_title']!, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(langMap['disclaimer_body']!, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 24),

          // 2. Language
          _buildSectionTitle(langMap['lang_select']!),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _prevLang, icon: const Icon(Icons.chevron_left, color: Colors.orange, size: 24)),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: Text(_selectedLang, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              IconButton(onPressed: _nextLang, icon: const Icon(Icons.chevron_right, color: Colors.orange, size: 24)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // 3. Season
          _buildSectionTitle(langMap['season_select']!),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _prevSeason, icon: const Icon(Icons.chevron_left, color: Colors.orange, size: 24)),
              Container(
                width: 160,
                alignment: Alignment.center,
                child: Text(seasonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              IconButton(onPressed: _nextSeason, icon: const Icon(Icons.chevron_right, color: Colors.orange, size: 24)),
            ],
          ),
          Text(langMap['season_note']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Divider(color: Colors.white10, height: 24),

          // 4. UI Settings
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(langMap['show_warnings']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
            activeThumbColor: Colors.orange,
            value: _showWarnings,
            onChanged: _toggleWarnings,
          ),
          const Divider(color: Colors.white10, height: 24),

          // 5. Notification Settings
          NotificationSettingsSection(
            lang: _selectedLang,
            notifEnabled: _notifEnabled,
            notifTime: _notifTime,
            notifEndTime: _notifEndTime,
            notifDays: _notifDays,
            excludedTypes: _excludedTypes,
            onToggleNotification: _toggleNotification,
            onPickNotifTime: _pickNotifTime,
            onPickNotifEndTime: _pickNotifEndTime,
            onToggleNotifDay: _toggleNotifDay,
            onToggleExcludedType: _toggleExcludedType,
          ),
          // 알림 상태 정보
          if (_notifEnabled) _buildNotifStatus(),
          const Divider(color: Colors.white10, height: 24),

          // 6. Steam & About
          AboutSection(lang: _selectedLang),

          const SizedBox(height: 20),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifStatus() {
    final langMap = i18n[_selectedLang]!;
    String lastFiredText;
    bool isWarning = false;

    if (_lastNotificationFired != null) {
      final diff = DateTime.now().difference(_lastNotificationFired!);
      final label = langMap['notif_last_fired'] ?? 'Last notification:';
      if (diff.inMinutes < 60) {
        lastFiredText = '$label ${diff.inMinutes} ${langMap['minutes_ago'] ?? 'm ago'}';
      } else if (diff.inHours < 48) {
        lastFiredText = '$label ${diff.inHours} ${langMap['hours_ago'] ?? 'h ago'}';
      } else {
        lastFiredText = '$label ${diff.inDays} ${langMap['days_ago'] ?? 'd ago'}';
        isWarning = true; // 48시간 이상 미발생
      }
    } else {
      lastFiredText = langMap['notif_never_fired'] ?? 'No notifications sent yet';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isWarning
              ? Colors.amber.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: isWarning
              ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.notifications_active,
              color: isWarning ? Colors.amber : Colors.white38,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lastFiredText,
                style: TextStyle(
                  color: isWarning ? Colors.amber : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
