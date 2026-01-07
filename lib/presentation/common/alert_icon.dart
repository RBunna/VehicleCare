import 'package:flutter/material.dart';

class AlertIcon extends StatelessWidget {
  final String status; // Expects 'CRITICAL', 'WARNING', 'OK', 'RED_ALERT', etc.

  const AlertIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // Mapping the string status (from Vehicle model) to visual attributes
    if (status == 'CRITICAL' || status == 'RED_ALERT') {
      icon = Icons.error;
      color = Theme.of(context).colorScheme.error; // Red
    } else if (status == 'WARNING' || status == 'GREEN_FLAG') {
      icon = Icons.warning;
      color = Theme.of(context).colorScheme.tertiary; // Orange/Yellow
    } else {
      icon = Icons.check_circle;
      color = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5); // Grey/Muted
    }

    return Tooltip(
      message: status,
      child: Icon(icon, color: color, size: 24),
    );
  }
}
