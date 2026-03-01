import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/strings.dart';
import '../services/settings_service.dart';
import '../services/mission_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../utils/constants.dart';

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
  final NotificationService _notifService = NotificationService();
  final NotificationSettingsService _notifSettings = NotificationSettingsService();

  // 알림 설정 상태
  bool _notifEnabled = false;
  TimeOfDay _notifTime    = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _notifEndTime = const TimeOfDay(hour: 22, minute: 0);
  List<int> _notifDays = [1, 2, 3, 4, 5, 6, 7];
  Set<String> _excludedTypes = {};

  /// iOS 또는 Web → Push 알림 미지원
  bool get _isPlatformUnsupported =>
      kIsWeb || (!kIsWeb && Platform.isIOS);

  static const List<String> _allMissionTypes = [
    'Mining Expedition', 'Egg Hunt', 'On-Site Refining',
    'Point Extraction', 'Salvage Operation', 'Escort Duty',
    'Elimination', 'Industrial Sabotage', 'Deep Scan', 'Heavy Excavation',
  ];

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

    setState(() {
      _showWarnings   = show;
      _notifEnabled   = notifOn;
      _notifTime      = notifTime;
      _notifEndTime   = notifEndTime;
      _notifDays      = notifDays;
      _excludedTypes  = excluded;
    });
  }

  void _nextLang() {
    List<String> langs = i18n.keys.toList();
    int idx = langs.indexOf(_selectedLang);
    String next = langs[(idx + 1) % langs.length];
    setState(() {
      _selectedLang = next;
    });
    widget.onLangChange(next);
  }

  void _prevLang() {
    List<String> langs = i18n.keys.toList();
    int idx = langs.indexOf(_selectedLang);
    String prev = langs[(idx - 1 + langs.length) % langs.length];
    setState(() {
      _selectedLang = prev;
    });
    widget.onLangChange(prev);
  }

  void _nextSeason() {
    final available = _missionService.availableSeasons;
    if (available.isEmpty) return;
    int idx = available.indexOf(_selectedSeason);
    String next = available[(idx + 1) % available.length];
    setState(() {
      _selectedSeason = next;
    });
    widget.onSeasonChange(next);
  }

  void _prevSeason() {
    final available = _missionService.availableSeasons;
    if (available.isEmpty) return;
    int idx = available.indexOf(_selectedSeason);
    String prev = available[(idx - 1 + available.length) % available.length];
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
      final granted = await _notifService.requestPermission();
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
      await _notifService.scheduleAlarms();
    } else {
      await _notifService.cancelAllAlarms();
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
      if (_notifEnabled) await _notifService.scheduleAlarms();
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
      if (_notifEnabled) await _notifService.scheduleAlarms();
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
    if (_notifEnabled) await _notifService.scheduleAlarms();
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

  Future<void> _launchSteam() async {
    final Uri url = Uri.parse('https://steamcommunity.com/id/VonVon93/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(AppConstants.privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _copySteamLink() {
    const String url = 'https://steamcommunity.com/id/VonVon93/';
    Clipboard.setData(const ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(i18n[_selectedLang]!['link_copied']!),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[_selectedLang]!;
    String seasonLabel = _selectedSeason == "s0" 
        ? langMap['standard']! 
        : "SEASON ${_selectedSeason.replaceAll('s', '')}";

    return Scaffold(
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
          _buildSectionTitle(langMap['notif_settings']!),
          // Double XP 설명 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    langMap['notif_double_xp_desc']!,
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // 플랫폼 미지원 배너 (iOS / Web)
          if (_isPlatformUnsupported)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off_outlined, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      langMap['notif_platform_unsupported']!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          // 마스터 스위치
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(langMap['notif_enable']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
            activeThumbColor: Colors.orange,
            // 미지원 플랫폼에서는 스위치 비활성화
            value: _isPlatformUnsupported ? false : _notifEnabled,
            onChanged: _isPlatformUnsupported ? null : _toggleNotification,
          ),
          // 아코디언: 활성화 시에만 펼쳐짐
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: _notifEnabled
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 알림 시간 범위: 시작 ~ 종료
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(langMap['notif_time_from']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _pickNotifTime,
                                      child: _buildTimePill(
                                        '${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 14, left: 8, right: 8),
                                child: Icon(Icons.arrow_forward, color: Colors.white24, size: 14),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(langMap['notif_time_to']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _pickNotifEndTime,
                                      child: _buildTimePill(
                                        '${_notifEndTime.hour.toString().padLeft(2, '0')}:${_notifEndTime.minute.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 요일 선택
                          Text(langMap['notif_days']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final entry in [
                                (1, langMap['mon']!), (2, langMap['tue']!), (3, langMap['wed']!),
                                (4, langMap['thu']!), (5, langMap['fri']!), (6, langMap['sat']!), (7, langMap['sun']!),
                              ])
                                GestureDetector(
                                  onTap: () => _toggleNotifDay(entry.$1),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _notifDays.contains(entry.$1)
                                          ? Colors.orange
                                          : Colors.white.withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: _notifDays.contains(entry.$1)
                                            ? Colors.orange
                                            : Colors.white.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Text(
                                      entry.$2,
                                      style: TextStyle(
                                        color: _notifDays.contains(entry.$1) ? Colors.black : Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 미션 타입 필터 (2열 컴팩트 그리드)
                          Row(
                            children: [
                              Text(langMap['notif_exclude_types']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  langMap['notif_exclude_note']!,
                                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(
                            (_allMissionTypes.length / 2).ceil(),
                            (rowIdx) {
                              final left  = _allMissionTypes[rowIdx * 2];
                              final right = rowIdx * 2 + 1 < _allMissionTypes.length
                                  ? _allMissionTypes[rowIdx * 2 + 1]
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Expanded(child: _buildTypeToggle(left)),
                                    if (right != null) Expanded(child: _buildTypeToggle(right)),
                                    if (right == null) const Expanded(child: SizedBox()),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),

          // 6. Steam & Community
          _buildSectionTitle(langMap['steam_profile']!),
          InkWell(
            onTap: _launchSteam,
            onLongPress: _copySteamLink,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171A21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Image.network(
                            'https://shared.fastly.steamstatic.com/community_assets/images/items/3331000/4ef70f99c425ae03163495f923c5d452f83ba978.gif',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.person, color: Colors.blueAccent, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pinyo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(langMap['visit_steam']!, style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: Colors.blueAccent, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("steamcommunity.com/id/VonVon93/", style: TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'monospace')),
                      Text(langMap['long_press_copy']!, style: const TextStyle(color: Colors.white24, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(langMap['bug_report_note']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const Divider(color: Colors.white10, height: 24),

          // 7. Privacy Policy & GitHub
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey, size: 20),
            title: Text(
              langMap['privacy_policy']!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 14),
            onTap: _launchPrivacyPolicy,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 시간 표시 pill 버튼
  Widget _buildTimePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.orange, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 미션 타입 토글 (컴팩트 2열 그리드 셀)
  Widget _buildTypeToggle(String type) {
    final included = !_excludedTypes.contains(type);
    return GestureDetector(
      onTap: () => _toggleExcludedType(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            Icon(
              included ? Icons.check_box : Icons.check_box_outline_blank,
              color: included ? Colors.orange : Colors.white24,
              size: 15,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                t(type, _selectedLang),
                style: TextStyle(
                  color: included ? Colors.white70 : Colors.white30,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
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
