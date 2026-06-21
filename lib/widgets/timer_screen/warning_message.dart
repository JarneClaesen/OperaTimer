import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WarningMessage extends StatelessWidget {
  final String message;
  final String buttonMessage;
  final VoidCallback onCheckAgain;

  const WarningMessage({
    Key? key,
    required this.message,
    required this.buttonMessage,
    required this.onCheckAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: AppTheme.brLg,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: text.bodyMedium?.copyWith(color: scheme.onTertiaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer,
                backgroundColor:
                    scheme.onTertiaryContainer.withValues(alpha: 0.16),
              ),
              onPressed: onCheckAgain,
              child: Text(buttonMessage),
            ),
          ],
        ),
      ),
    );
  }
}
