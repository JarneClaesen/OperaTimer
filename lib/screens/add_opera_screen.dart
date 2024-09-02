import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/opera.dart';
import '../models/setlist.dart';
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
      final parts = <Setlist>[];

      for (int i = 0; i < _partNameControllers.length; i++) {
        final partName = _partNameControllers[i].text;
        final playTimes = _playTimes[i];
        parts.add(Setlist(partName: partName, playTimes: playTimes));
      }

      final newOpera = Opera(name: operaName, parts: parts);
      final box = Hive.box<Opera>('operas');

      if (widget.opera == null) {
        await box.add(newOpera);
      } else {
        await box.putAt(widget.index!, newOpera);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.opera == null ? 'Add Opera' : 'Edit Opera'),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: TextButton(
              onPressed: _saveOpera,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: Text('Save'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _operaNameController,
                decoration: InputDecoration(labelText: 'Opera Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the opera name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('Parts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._partNameControllers.asMap().entries.map((entry) {
                final index = entry.key;
                return Column(
                  key: ValueKey(index),
                  children: [
                    TextFormField(
                      controller: _partNameControllers[index],
                      decoration: InputDecoration(labelText: 'Part Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the part name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TimeInput(
                      onTimeChanged: (time) {
                        _addTime(index, time);
                      },
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _playTimes[index].asMap().entries.map((entry) {
                        final timeIndex = entry.key;
                        final time = entry.value;
                        final hours = time ~/ 3600;
                        final minutes = (time % 3600) ~/ 60;
                        final seconds = time % 60;
                        return Chip(
                          label: Text('${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'),
                          deleteIcon: Icon(Icons.close_rounded),
                          onDeleted: () => _removeTime(index, timeIndex),
                        );
                      }).toList(),
                    ),
                    Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _removePartField(index),
                        child: Text('Remove Part'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: _addPartField,
                  child: Text('Add Part'),
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
        ),
      ),
    );
  }
}
