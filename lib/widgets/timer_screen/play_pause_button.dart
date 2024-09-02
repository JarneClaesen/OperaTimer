import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayPauseButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const PlayPauseButton({Key? key, required this.isRunning, required this.onPressed}) : super(key: key);

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  late bool _isRunning;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isRunning;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: ValueKey<bool>(_isRunning),
          color: Theme.of(context).colorScheme.onPrimary,
          size: 40,
        ),
      ),
      onPressed: _isAnimating ? null : _handlePress,
    );
  }

  void _handlePress() {
    setState(() {
      _isAnimating = true;
    });

    widget.onPressed();

    Future.delayed(Duration(milliseconds: 1), () {
      if (mounted) {
        setState(() {
          _isRunning = !_isRunning;
          _isAnimating = false;
        });
      }
    });
  }
}
