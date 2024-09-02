import 'package:flutter/material.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const PlayPauseButton({
    Key? key,
    required this.isRunning,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: ValueKey(isRunning),
          color: Theme.of(context).colorScheme.onPrimary,
          size: 40,
        ),
      ),
      onPressed: onPressed,
    );
  }
}
