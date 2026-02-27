import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/mission_card.dart';
import '../data/mock_data.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';

class LiveMissionsTab extends StatefulWidget {
  final String lang;
  const LiveMissionsTab({super.key, required this.lang});

  @override
  State<LiveMissionsTab> createState() => _LiveMissionsTabState();
}

class _LiveMissionsTabState extends State<LiveMissionsTab> {
  int _timeOffset = 0; // -1: Past, 0: Current, 1: Next
  late Timer _timer;
  int _secondsUntilNext = 0;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final next30 = (now.minute < 30) ? 30 : 60;
    final target = DateTime(now.year, now.month, now.day, now.hour, next30, 0);
    setState(() {
      _secondsUntilNext = target.difference(now).inSeconds;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _changeOffset(int change) {
    setState(() {
      _timeOffset = (_timeOffset + change).clamp(-1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Mission> displayList;
    String statusText;

    if (_timeOffset == -1) {
      displayList = List.from(mockPrevMissions);
      statusText = i18n[widget.lang]!['past']!;
    } else if (_timeOffset == 1) {
      displayList = List.from(mockNextMissions);
      statusText = i18n[widget.lang]!['upcoming']!;
    } else {
      displayList = List.from(mockCurrentMissions);
      statusText = i18n[widget.lang]!['current']!;
    }

    // [Req 1] Double XP 상단 고정 정렬 로직
    displayList.sort((a, b) {
      if (a.buff == "Double XP" && b.buff != "Double XP") return -1;
      if (a.buff != "Double XP" && b.buff == "Double XP") return 1;
      return 0;
    });

    final minutes = (_secondsUntilNext ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsUntilNext % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        // 시간 탐색기 및 카운트다운 헤더
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          color: Colors.black45,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: _timeOffset > -1 ? Colors.orange : Colors.grey),
                    onPressed: () => _changeOffset(-1),
                  ),
                  Text(statusText, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: _timeOffset < 1 ? Colors.orange : Colors.grey),
                    onPressed: () => _changeOffset(1),
                  ),
                ],
              ),
              if (_timeOffset == 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${i18n[widget.lang]!['time_left']} $minutes:$seconds',
                  style: const TextStyle(fontSize: 14, color: Colors.orangeAccent),
                ),
              ]
            ],
          ),
        ),
        // 미션 리스트 영역
        Expanded(
          child: ListView.builder(
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              return MissionCard(mission: displayList[index], lang: widget.lang);
            },
          ),
        ),
      ],
    );
  }
}