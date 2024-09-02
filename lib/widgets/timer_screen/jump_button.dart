import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class JumpButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const JumpButton({Key? key, required this.icon, required this.onPressed}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.icon),
      onPressed: _isDisabled ? null : _handlePress,
      color: _isDisabled ? Colors.grey : null,
    );
  }
}
