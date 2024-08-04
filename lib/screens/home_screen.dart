import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import '../models/opera.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import 'opera_screen.dart';
import 'add_opera_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<int> _selectedIndexes = Set<int>();

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the selected operas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final box = Hive.box<Opera>('operas');
      final indexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
      for (var index in indexes) {
        await box.deleteAt(index);
      }
      _clearSelection();
    }
  }

  void _editSelected() {
    if (_selectedIndexes.length == 1) {
      final index = _selectedIndexes.first;
      final opera = Hive.box<Opera>('operas').getAt(index);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddOperaScreen(opera: opera, index: index),
        ),
      ).then((_) => _clearSelection());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select only one opera to edit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opera Timer'),
        actions: _selectedIndexes.isNotEmpty
            ? [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editSelected,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteSelected,
          ),
        ]
            : [],
      ),
      body: Consumer<TimerProvider>(
        builder: (context, timerProvider, child) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Opera>('operas').listenable(),
            builder: (context, Box<Opera> box, _) {
              if (box.values.isEmpty) {
                return Center(child: Text('No operas added yet.'));
              }

              return ListView.builder(
                itemCount: box.values.length,
                itemBuilder: (context, index) {
                  final opera = box.getAt(index);
                  final isSelected = _selectedIndexes.contains(index);
                  final isPlaying = timerProvider.currentOperaName == opera!.name;

                  return GestureDetector(
                    onLongPress: () {
                      _toggleSelection(index);
                    },
                    child: ListTile(
                      leading: _selectedIndexes.isNotEmpty
                          ? Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          _toggleSelection(index);
                        },
                      )
                          : null,
                      title: Text(opera.name),
                      trailing: isPlaying
                          ? Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        if (_selectedIndexes.isNotEmpty) {
                          _toggleSelection(index);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OperaScreen(opera: opera),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.0), // Adjust this value as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddOperaScreen()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
