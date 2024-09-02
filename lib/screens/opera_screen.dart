// lib/screens/opera_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/opera.dart';
import '../providers/timer_provider.dart';
import '../widgets/screen_with_floating_timer.dart';
import 'timer_screen.dart';

class OperaScreen extends StatelessWidget {
  final Opera opera;

  OperaScreen({required this.opera});

  String _formatPlayTimes(List<int> playTimes) {
    return playTimes.map((time) {
      final hours = time ~/ 3600;
      final minutes = (time % 3600) ~/ 60;
      final seconds = time % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithFloatingTimer(
      child: Scaffold(
        appBar: AppBar(title: Text(opera.name)),
        body: Consumer<TimerProvider>(
          builder: (context, timerProvider, child) {
            return ListView.builder(
              itemCount: opera.parts.length,
              itemBuilder: (context, index) {
                final part = opera.parts[index];
                final formattedPlayTimes = _formatPlayTimes(part.playTimes);
                final isSelected = timerProvider.currentOperaName == opera.name &&
                    listEquals(timerProvider.playTimes, part.playTimes);

                return ListTile(
                  title: Text(part.partName),
                  subtitle: Text(formattedPlayTimes),
                  trailing: isSelected
                      ? Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    timerProvider.setCurrentOpera(opera.name, part.playTimes);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TimerScreen()),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
