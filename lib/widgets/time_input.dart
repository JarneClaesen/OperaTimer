import 'package:flutter/material.dart';

class TimeInput extends StatefulWidget {
  final Function(int) onTimeChanged;

  TimeInput({required this.onTimeChanged});

  @override
  _TimeInputState createState() => _TimeInputState();
}

class _TimeInputState extends State<TimeInput> {
  String _input = '';

  void _addDigit(String digit) {
    setState(() {
      if (_input.length < 6) {
        _input += digit;
      }
    });
  }

  void _removeDigit() {
    setState(() {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  int _parseTime(String input) {
    final paddedInput = input.padLeft(6, '0');
    final hours = int.parse(paddedInput.substring(0, 2));
    final minutes = int.parse(paddedInput.substring(2, 4));
    final seconds = int.parse(paddedInput.substring(4, 6));
    return hours * 3600 + minutes * 60 + seconds;
  }

  void _showNumberPad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeDisplay(),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 2.0,
                    children: [
                      ...List.generate(9, (index) {
                        return _buildDigitButton((index + 1).toString(), setState);
                      }),
                      _buildDigitButton('0', setState),
                      _buildBackspaceButton(setState),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        widget.onTimeChanged(_parseTime(_input));
                        Navigator.pop(context);
                      },
                      child: Text('Set Time'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDisplay() {
    final paddedInput = _input.padLeft(6, '0');
    final hours = paddedInput.substring(0, 2);
    final minutes = paddedInput.substring(2, 4);
    final seconds = paddedInput.substring(4, 6);

    return Text(
      '$hours:$minutes:$seconds',
      style: TextStyle(fontSize: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNumberPad(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Set Time',
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit, StateSetter setState) {
    return Container(
      height: 50,
      width: 50,
      child: TextButton(
        onPressed: () {
          setState(() {
            _addDigit(digit);
          });
        },
        child: Text(digit, style: TextStyle(fontSize: 24)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(8.0),
          minimumSize: Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(StateSetter setState) {
    return Container(
      height: 50,
      width: 50,
      child: TextButton(
        onPressed: () {
          setState(() {
            _removeDigit();
          });
        },
        child: Icon(Icons.backspace, size: 24),
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(8.0),
          minimumSize: Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
