import 'package:flutter/material.dart';
import 'package:orchestra_timer/widgets/timer_screen/play_pause_button.dart';

class AnimatedPlayPauseContainer extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const AnimatedPlayPauseContainer({
    Key? key,
    required this.isRunning,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: isRunning ? 100 : 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(40),
      ),
      child: PlayPauseButton(
        isRunning: isRunning,
        onPressed: onPressed,
      ),
    );
  }
}
