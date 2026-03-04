import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/mission_service.dart';
import '../services/notification_service.dart';
import 'changelog_dialog.dart';

/// 디버그 메뉴 표시 (보스코 롱프레스)
void showDebugMenu({
  required BuildContext context,
  required String currentLang,
  required MissionService missionService,
}) {
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
              _testPushAlarm(context, currentLang);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.orange),
            title: const Text('Changelog 팝업 표시',
                style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(ctx);
              final info = await PackageInfo.fromPlatform();
              if (context.mounted) {
                showChangelogDialog(context, currentLang, info.version);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.orange),
            title: const Text('DataStatus 순환',
                style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(ctx);
              _cycleDebugStatus(context, missionService);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _testPushAlarm(BuildContext context, String currentLang) async {
  try {
    final notifService = NotificationService();

    // 알림 권한 확인 → 미부여 시 요청
    if (!await notifService.hasPermission()) {
      final granted = await notifService.requestPermission();
      if (!granted && context.mounted) {
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

    await notifService.showTestNotification(currentLang);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug: 테스트 알림 발송 완료 📡'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
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

void _cycleDebugStatus(BuildContext context, MissionService missionService) {
  final current = missionService.status;
  final DataStatus next;

  if (current == DataStatus.online) {
    next = DataStatus.offline;
  } else if (current == DataStatus.offline) {
    next = DataStatus.outdated;
  } else if (current == DataStatus.outdated) {
    next = DataStatus.refreshing;
  } else {
    next = DataStatus.online;
  }

  missionService.debugSetStatus(next);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Debug: DataStatus → ${next.name.toUpperCase()}"),
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.blueGrey,
    ),
  );
}
