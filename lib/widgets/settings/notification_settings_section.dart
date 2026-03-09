import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../utils/strings.dart';

class NotificationSettingsSection extends StatefulWidget {
  final String lang;
  final bool notifEnabled;
  final TimeOfDay notifTime;
  final TimeOfDay notifEndTime;
  final List<int> notifDays;
  final Set<String> excludedTypes;
  final ValueChanged<bool> onToggleNotification;
  final VoidCallback onPickNotifTime;
  final VoidCallback onPickNotifEndTime;
  final ValueChanged<int> onToggleNotifDay;
  final ValueChanged<String> onToggleExcludedType;

  static const List<String> allMissionTypes = [
    'Mining Expedition', 'Egg Hunt', 'On-Site Refining',
    'Point Extraction', 'Salvage Operation', 'Escort Duty',
    'Elimination', 'Industrial Sabotage', 'Deep Scan', 'Heavy Excavation',
  ];

  const NotificationSettingsSection({
    super.key,
    required this.lang,
    required this.notifEnabled,
    required this.notifTime,
    required this.notifEndTime,
    required this.notifDays,
    required this.excludedTypes,
    required this.onToggleNotification,
    required this.onPickNotifTime,
    required this.onPickNotifEndTime,
    required this.onToggleNotifDay,
    required this.onToggleExcludedType,
  });

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  // PWA 전환: 웹에서도 Web Notification API를 통해 알림 지원
  bool get _isPlatformUnsupported => false;

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[widget.lang]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // 웹 알림 안내 배너
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.web, color: Colors.lightBlueAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    langMap['notif_web_note'] ?? langMap['notif_platform_unsupported']!,
                    style:
                        const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        // 마스터 스위치
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(langMap['notif_enable']!,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          activeThumbColor: Colors.orange,
          value: _isPlatformUnsupported ? false : widget.notifEnabled,
          onChanged:
              _isPlatformUnsupported ? null : widget.onToggleNotification,
        ),
        // 아코디언: 활성화 시에만 펼쳐짐
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: widget.notifEnabled
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
                                  Text(langMap['notif_time_from']!,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: widget.onPickNotifTime,
                                    child: _buildTimePill(
                                      '${widget.notifTime.hour.toString().padLeft(2, '0')}:${widget.notifTime.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.only(top: 14, left: 8, right: 8),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.white24, size: 14),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(langMap['notif_time_to']!,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: widget.onPickNotifEndTime,
                                    child: _buildTimePill(
                                      '${widget.notifEndTime.hour.toString().padLeft(2, '0')}:${widget.notifEndTime.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 요일 선택
                        Text(langMap['notif_days']!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final entry in [
                              (1, langMap['mon']!),
                              (2, langMap['tue']!),
                              (3, langMap['wed']!),
                              (4, langMap['thu']!),
                              (5, langMap['fri']!),
                              (6, langMap['sat']!),
                              (7, langMap['sun']!),
                            ])
                              GestureDetector(
                                onTap: () =>
                                    widget.onToggleNotifDay(entry.$1),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.notifDays.contains(entry.$1)
                                        ? Colors.orange
                                        : Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color:
                                          widget.notifDays.contains(entry.$1)
                                              ? Colors.orange
                                              : Colors.white
                                                  .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Text(
                                    entry.$2,
                                    style: TextStyle(
                                      color:
                                          widget.notifDays.contains(entry.$1)
                                              ? Colors.black
                                              : Colors.white38,
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
                            Text(langMap['notif_exclude_types']!,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                langMap['notif_exclude_note']!,
                                style: const TextStyle(
                                    color: Colors.white24, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...List.generate(
                          (NotificationSettingsSection
                                      .allMissionTypes.length /
                                  2)
                              .ceil(),
                          (rowIdx) {
                            final left = NotificationSettingsSection
                                .allMissionTypes[rowIdx * 2];
                            final right = rowIdx * 2 + 1 <
                                    NotificationSettingsSection
                                        .allMissionTypes.length
                                ? NotificationSettingsSection
                                    .allMissionTypes[rowIdx * 2 + 1]
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Expanded(child: _buildTypeToggle(left)),
                                  if (right != null)
                                    Expanded(child: _buildTypeToggle(right)),
                                  if (right == null)
                                    const Expanded(child: SizedBox()),
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
      ],
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
            style: const TextStyle(
                color: Colors.orange,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 미션 타입 토글 (컴팩트 2열 그리드 셀)
  Widget _buildTypeToggle(String type) {
    final included = !widget.excludedTypes.contains(type);
    return GestureDetector(
      onTap: () => widget.onToggleExcludedType(type),
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
                t(type, widget.lang),
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
      child: Text(title,
          style: const TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
    );
  }
}
