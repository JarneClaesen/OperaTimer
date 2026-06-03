import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../providers/timer_provider.dart';

class JumpButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final TimerProvider timerProvider;  // Add timerProvider parameter

  const JumpButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.timerProvider,  // New required parameter
  }) : super(key: key);

  @override
  _JumpButtonState createState() => _JumpButtonState();
}

class _JumpButtonState extends State<JumpButton> {
  bool _isDisabled = false;

  void _handlePress() {
    if (!_isDisabled) {
      setState(() {
        _isDisabled = true;
      });
      widget.onPressed();
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isDisabled = false;
          });
        }
      });
    }
  }

  // Add method to show the jump seconds picker dialog
  void _showJumpSecondsPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int currentValue = widget.timerProvider.jumpSeconds;
        return AlertDialog(
          title: Text('Set Jump Seconds'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return NumberPicker(
                value: currentValue,
                minValue: 1,
                maxValue: 60,
                onChanged: (value) => setState(() => currentValue = value),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                widget.timerProvider.setJumpSeconds(currentValue);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showJumpSecondsPicker(context), // Add long press handler
      child: IconButton(
        icon: Icon(widget.icon),
        onPressed: _isDisabled ? null : _handlePress,
        color: _isDisabled ? Colors.grey : null,
      ),
    );
  }
}