import 'package:flutter/material.dart';

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
    final hours = time ~/ 3600;
    final minutes = (time % 3600) ~/ 60;
    final seconds = time % 60;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPast ? Colors.green : (isCurrent ? Colors.orange : Colors.grey),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPast ? Colors.green.withOpacity(0.1) : (isCurrent ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isPast ? Colors.green : (isCurrent ? Colors.orange : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}