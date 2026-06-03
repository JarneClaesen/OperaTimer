import 'package:flutter/material.dart';
import '../../utils/time_format.dart';

class TimelineItem extends StatelessWidget {
  final int time;
  final bool isPast;
  final bool isCurrent;

  const TimelineItem({
    Key? key,
    required this.time,
    required this.isPast,
    required this.isCurrent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isPast ? Colors.green : (isCurrent ? Colors.orange : Colors.grey);

    // Matches the per-item Card surface used by the opera list.
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        title: Text(
          formatHms(time),
          style: TextStyle(
            fontSize: 18,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: statusColor,
          ),
        ),
      ),
    );
  }
}