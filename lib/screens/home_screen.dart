import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:orchestra_timer/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../models/opera.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import 'opera_screen.dart';
import 'add_opera_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _selectedIndexes = <int>{};
  Future<Box<Opera>>? _operaBoxFuture;

  @override
  void initState() {
    super.initState();
    _operaBoxFuture = Hive.openBox<Opera>('operas');
  }

  void _clearSelection() {
    setState(() => _selectedIndexes.clear());
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
    final count = _selectedIndexes.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: AppTheme.shapeLg,
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text('Delete ${count == 1 ? 'opera' : '$count operas'}?'),
        content: const Text('This permanently removes the selected operas and their parts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selecting = _selectedIndexes.isNotEmpty;

    return Scaffold(
      body: Consumer<TimerProvider>(
        builder: (context, timerProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                leading: selecting
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clearSelection,
                        tooltip: 'Clear selection',
                      )
                    : null,
                title: Text(selecting ? '${_selectedIndexes.length} selected' : 'Opera Timer'),
                actions: [
                  if (!selecting)
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: 'Settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen()),
                      ),
                    ),
                  if (selecting) ...[
                    if (_selectedIndexes.length == 1)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit',
                        onPressed: _editSelected,
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded),
                      tooltip: 'Delete',
                      onPressed: _deleteSelected,
                    ),
                  ],
                  const SizedBox(width: 4),
                ],
              ),
              FutureBuilder<Box<Opera>>(
                future: _operaBoxFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final operaBox = snapshot.data;
                  if (snapshot.hasError || operaBox == null) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Error: ${snapshot.error ?? 'failed to open storage'}')),
                    );
                  }
                  return ValueListenableBuilder<Box<Opera>>(
                    valueListenable: operaBox.listenable(),
                    builder: (context, box, _) {
                      if (box.values.isEmpty) {
                        return _EmptyState(onAdd: _addOpera);
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                        sliver: SliverList.builder(
                          itemCount: box.values.length,
                          itemBuilder: (context, index) {
                            final opera = box.getAt(index);
                            final isSelected = _selectedIndexes.contains(index);
                            final isPlaying =
                                timerProvider.currentOperaName == opera?.name;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OperaCard(
                                name: opera?.name ?? 'Unknown Opera',
                                partCount: opera?.parts.length ?? 0,
                                isPlaying: isPlaying,
                                isSelected: isSelected,
                                selecting: selecting,
                                onLongPress: () => _toggleSelection(index),
                                onTap: () {
                                  if (selecting) {
                                    _toggleSelection(index);
                                  } else if (opera != null) {
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
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: selecting
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 96.0),
              child: FloatingActionButton.extended(
                onPressed: _addOpera,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New opera'),
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
              ),
            ),
    );
  }

  void _addOpera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddOperaScreen()),
    );
  }
}

class _OperaCard extends StatelessWidget {
  final String name;
  final int partCount;
  final bool isPlaying;
  final bool isSelected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _OperaCard({
    required this.name,
    required this.partCount,
    required this.isPlaying,
    required this.isSelected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final Color container = isSelected
        ? scheme.secondaryContainer
        : isPlaying
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh;
    final Color onContainer = isSelected
        ? scheme.onSecondaryContainer
        : isPlaying
            ? scheme.onPrimaryContainer
            : scheme.onSurface;

    return Material(
      color: container,
      shape: AppTheme.shapeLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _LeadingBadge(
                selecting: selecting,
                isSelected: isSelected,
                isPlaying: isPlaying,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: onContainer),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$partCount ${partCount == 1 ? 'part' : 'parts'}'
                      '${isPlaying ? ' · Now playing' : ''}',
                      style: text.bodyMedium
                          ?.copyWith(color: onContainer.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selecting ? null : Icons.chevron_right_rounded,
                color: onContainer.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  final bool selecting;
  final bool isSelected;
  final bool isPlaying;
  const _LeadingBadge({
    required this.selecting,
    required this.isSelected,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    IconData icon;
    Color bg;
    Color fg;
    if (selecting) {
      icon = isSelected ? Icons.check_rounded : Icons.circle_outlined;
      bg = isSelected ? scheme.primary : scheme.surfaceContainerHighest;
      fg = isSelected ? scheme.onPrimary : scheme.onSurfaceVariant;
    } else if (isPlaying) {
      icon = Icons.graphic_eq_rounded;
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else {
      icon = Icons.theater_comedy_rounded;
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(selecting && isSelected ? 26 : 16),
      ),
      child: Icon(icon, color: fg),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(Icons.theater_comedy_rounded,
                  size: 48, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text('No operas yet', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Add an opera, give its parts their play times, and start the timer.',
              textAlign: TextAlign.center,
              style: text.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New opera'),
            ),
          ],
        ),
      ),
    );
  }
}
