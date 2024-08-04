// lib/widgets/screen_with_floating_timer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/floating_timer.dart';
import '../screens/timer_screen.dart';

class ScreenWithFloatingTimer extends StatelessWidget {
  final Widget child;

  const ScreenWithFloatingTimer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<TimerProvider>(
          builder: (context, timerProvider, _) {
            return FloatingTimer(
              onTap: () {
                if (timerProvider.currentOperaName != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimerScreen()),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}