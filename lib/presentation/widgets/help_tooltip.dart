import 'package:flutter/material.dart';

/// Icono de ayuda con explicación breve para términos técnicos.
class HelpTooltip extends StatelessWidget {
  final String message;
  final double size;

  const HelpTooltip({super.key, required this.message, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: message,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: message,
        button: true,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            Icons.help_outline_rounded,
            size: size,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
