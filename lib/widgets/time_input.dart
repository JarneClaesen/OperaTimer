import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeDisplay(context),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 1.4,
                    children: [
                      ...List.generate(9, (index) {
                        return _buildDigitButton((index + 1).toString(), setState);
                      }),
                      const SizedBox.shrink(),
                      _buildDigitButton('0', setState),
                      _buildBackspaceButton(setState),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onTimeChanged(_parseTime(_input));
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Set time'),
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

  Widget _buildTimeDisplay(BuildContext context) {
    final paddedInput = _input.padLeft(6, '0');
    final hours = paddedInput.substring(0, 2);
    final minutes = paddedInput.substring(2, 4);
    final seconds = paddedInput.substring(4, 6);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bool empty = _input.isEmpty;

    return Text(
      '$hours:$minutes:$seconds',
      style: text.displaySmall?.copyWith(
        color: empty
            ? scheme.onSurface.withValues(alpha: 0.35)
            : scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        onPressed: () => _showNumberPad(context),
        icon: const Icon(Icons.schedule_rounded),
        label: const Text('Add play time'),
      ),
    );
  }

  Widget _buildDigitButton(String digit, StateSetter setState) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: AppTheme.shapeMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _addDigit(digit);
          });
        },
        child: Center(
          child: Text(
            digit,
            style: text.headlineSmall?.copyWith(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(StateSetter setState) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      shape: AppTheme.shapeMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _removeDigit();
          });
        },
        child: Center(
          child: Icon(Icons.backspace_rounded,
              size: 24, color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
