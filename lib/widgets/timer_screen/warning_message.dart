import 'package:flutter/material.dart';

class WarningMessage extends StatelessWidget {
  final String message;
  final VoidCallback onCheckAgain;

  const WarningMessage({
    Key? key,
    required this.message,
    required this.onCheckAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.onTertiaryContainer),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Check Again',
                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                  ),
                  onPressed: onCheckAgain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
