import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchestra_timer/widgets/timer_screen/play_pause_button.dart';

class AnimatedPlayPauseContainer extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const AnimatedPlayPauseContainer({Key? key, required this.isRunning, required this.onPressed}) : super(key: key);

  @override
  _AnimatedPlayPauseContainerState createState() => _AnimatedPlayPauseContainerState();
}

class _AnimatedPlayPauseContainerState extends State<AnimatedPlayPauseContainer> {
  late bool _isRunning;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isRunning;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isRunning ? 100 : 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(40),
      ),
      child: PlayPauseButton(
        isRunning: _isRunning,
        onPressed: _handlePress,
      ),
    );
  }

  void _handlePress() {
    widget.onPressed();
    Future.delayed(Duration(milliseconds: 1), () {
      if (mounted) {
        setState(() {
          _isRunning = !_isRunning;
        });
      }
    });
  }
}
