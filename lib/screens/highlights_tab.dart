import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';
import '../services/mission_service.dart';

class HighlightsTab extends StatefulWidget {
  final String lang;
  const HighlightsTab({super.key, required this.lang});

  @override
  State<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<HighlightsTab> {
  late Timer _timer;
  late DateTime _now;
  final MissionService _missionService = MissionService();
  List<Map<String, dynamic>> _highlightItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _loadData();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _processHighlights(); // 시간 경과에 따른 isPast 등 갱신
        });
      }
    });
  }

  Future<void> _loadData() async {
    await _missionService.loadMissions();
    _processHighlights();
  }

  void _processHighlights() {
    List<Map<String, dynamic>> items = [];
    final allMissions = _missionService.allMissions;
    
    // 필터 기준 시간: 현재로부터 2시간 전
    DateTime startTime = _now.subtract(const Duration(hours: 2));
    
    List<String> sortedKeys = allMissions.keys.toList()..sort();

    for (String key in sortedKeys) {
      DateTime? utcTime = DateTime.tryParse(key);
      if (utcTime == null) continue;

      DateTime localTime = utcTime.toLocal();
      
      // 1. 2시간 전보다 이전 데이터는 제외
      if (localTime.isBefore(startTime)) continue;

      // 2. Double XP 미션만 수집
      List<Mission> doubleXpMissions = allMissions[key]!
          .where((m) => m.buff == "Double XP") 
          .toList();

      for (var mission in doubleXpMissions) {
        // 내일인지 여부 판단
        bool isTomorrow = localTime.day != _now.day;

        items.add({
          'time': localTime,
          'mission': mission,
          'isPast': localTime.add(const Duration(minutes: 30)).isBefore(_now),
          'isCurrent': localTime.isBefore(_now) && localTime.add(const Duration(minutes: 30)).isAfter(_now),
          'isTomorrow': isTomorrow,
        });
      }
    }

    if (mounted) {
      setState(() {
        _highlightItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    String currentTimeStr = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.black45,
          child: Text(
            i18n[widget.lang]!['timeline_title']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
        ),
        
        Expanded(
          child: _highlightItems.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 64, color: Colors.orange.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      i18n[widget.lang]!['no_highlights']!, 
                      style: const TextStyle(color: Colors.grey)
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _highlightItems.length,
                itemBuilder: (context, index) {
                  final item = _highlightItems[index];
                  final Mission mission = item['mission'];
                  final DateTime time = item['time'];
                  final bool isPast = item['isPast'];
                  final bool isCurrent = item['isCurrent'];
                  final bool isTomorrow = item['isTomorrow'];

                  String timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                  return Column(
                    children: [
                      // 내일 첫 번째 아이템 위에 헤더 표시
                      if (isTomorrow && (index == 0 || !_highlightItems[index-1]['isTomorrow']))
                        Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            i18n[widget.lang]!['tomorrow']!,
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),

                      if (isCurrent) 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            '--- [ ${i18n[widget.lang]!['now']!.replaceAll('현재 시간', '현재 시간 $currentTimeStr').replaceAll('CURRENT TIME', 'CURRENT TIME $currentTimeStr').replaceAll('当前时间', '当前时间 $currentTimeStr')} ] ---', 
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      
                      Opacity(
                        opacity: isPast ? 0.4 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.amber.withOpacity(0.1) : Colors.grey[900],
                            border: Border(
                              left: BorderSide(color: isPast ? Colors.grey : (isTomorrow ? Colors.blueAccent : Colors.amber), width: 4),
                              bottom: isCurrent ? const BorderSide(color: Colors.amber, width: 1) : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(timeStr, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                  if (isTomorrow) const Text("NEXT DAY", style: TextStyle(fontSize: 8, color: Colors.blueAccent)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t(mission.missionType, widget.lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    Text(t(mission.biome, widget.lang), style: const TextStyle(color: Colors.orange, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                color: Colors.yellow[700],
                                child: const Text("DOUBLE XP", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }
}
