import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../utils/strings.dart';

class HighlightsTab extends StatefulWidget {
  final String lang;
  const HighlightsTab({super.key, required this.lang});

  @override
  State<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<HighlightsTab> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                itemCount: mockHighlights.length,
                itemBuilder: (context, index) {
                  final mission = mockHighlights[index];
                  bool isCurrent = (index == 2); 

                  return Column(
                    children: [
                      if (isCurrent) 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            '--- [ ${i18n[widget.lang]!['now']!.replaceAll('현재 시간', '현재 시간 $currentTimeStr').replaceAll('CURRENT TIME', 'CURRENT TIME $currentTimeStr').replaceAll('当前时间', '当前时间 $currentTimeStr')} ] ---', 
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                          ),
                        ),
                      
                      Opacity(
                        opacity: mission.isPast ? 0.4 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border(left: BorderSide(color: mission.isPast ? Colors.grey : Colors.amber, width: 4)),
                          ),
                          child: Row(
                            children: [
                              Text(mission.timeWindow, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mission.missionType, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    Text(mission.biome, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.yellow[700],
                                child: Text(mission.buff ?? '', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
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
          ),
        ),
      ],
    );
  }
}