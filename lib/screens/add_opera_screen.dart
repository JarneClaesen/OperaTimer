import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/opera.dart';
import '../models/setlist.dart';
import '../services/hive_helper.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/time_input.dart';

class AddOperaScreen extends StatefulWidget {
  final Opera? opera;
  final int? index;

  AddOperaScreen({this.opera, this.index});

  @override
  _AddOperaScreenState createState() => _AddOperaScreenState();
}

class _AddOperaScreenState extends State<AddOperaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _operaNameController = TextEditingController();
  final List<TextEditingController> _partNameControllers = [];
  final List<List<int>> _playTimes = [];

  @override
  void initState() {
    super.initState();
    if (widget.opera != null) {
      _operaNameController.text = widget.opera!.name;
      for (var part in widget.opera!.parts) {
        _partNameControllers.add(TextEditingController(text: part.partName));
        _playTimes.add(List<int>.from(part.playTimes));
      }
    }
  }

  void _addPartField() {
    setState(() {
      _partNameControllers.add(TextEditingController());
      _playTimes.add([]);
    });
  }

  void _removePartField(int index) {
    setState(() {
      _partNameControllers.removeAt(index);
      _playTimes.removeAt(index);
    });
  }

  void _removeTime(int partIndex, int timeIndex) {
    setState(() {
      _playTimes[partIndex].removeAt(timeIndex);
    });
  }

  void _addTime(int partIndex, int time) {
    setState(() {
      _playTimes[partIndex].add(time);
      _playTimes[partIndex].sort();
    });
  }

  void _saveOpera() async {
    if (_formKey.currentState!.validate()) {
      final operaName = _operaNameController.text;
      final List<Setlist> parts = [];
      for (int i = 0; i < _partNameControllers.length; i++) {
        final partName = _partNameControllers[i].text;
        final playTimes = _playTimes[i];
        parts.add(Setlist(partName: partName, playTimes: playTimes));
      }
      final newOpera = Opera(name: operaName, parts: parts);

      final box = await HiveHelper.getOperasBox();
      if (widget.opera == null) {
        await box.add(newOpera);
      } else {
        await box.putAt(widget.index!, newOpera);
      }

      Navigator.pop(context);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: AppTheme.brMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.brMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.brMd,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: true,
              title: Text(widget.opera == null ? 'Add opera' : 'Edit opera'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TextFormField(
                    controller: _operaNameController,
                    decoration: _fieldDecoration('Opera name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the opera name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Parts', style: text.titleLarge),
                  const SizedBox(height: 12),
                  ..._partNameControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Padding(
                      key: ValueKey(index),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PartSection(
                        index: index,
                        controller: _partNameControllers[index],
                        playTimes: _playTimes[index],
                        decoration: _fieldDecoration('Part name'),
                        onTimeChanged: (time) => _addTime(index, time),
                        onRemoveTime: (timeIndex) =>
                            _removeTime(index, timeIndex),
                        onRemovePart: () => _removePartField(index),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addPartField,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add part'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveOpera,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save opera'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartSection extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final List<int> playTimes;
  final InputDecoration decoration;
  final ValueChanged<int> onTimeChanged;
  final ValueChanged<int> onRemoveTime;
  final VoidCallback onRemovePart;

  const _PartSection({
    required this.index,
    required this.controller,
    required this.playTimes,
    required this.decoration,
    required this.onTimeChanged,
    required this.onRemoveTime,
    required this.onRemovePart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      shape: AppTheme.shapeLg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: text.titleMedium
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: decoration,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the part name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onRemovePart,
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'Remove part',
                  color: scheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TimeInput(onTimeChanged: onTimeChanged),
            if (playTimes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: playTimes.asMap().entries.map((entry) {
                  final timeIndex = entry.key;
                  final time = entry.value;
                  return InputChip(
                    label: Text(formatHms(time)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    onDeleted: () => onRemoveTime(timeIndex),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
