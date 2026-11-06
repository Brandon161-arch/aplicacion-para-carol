import 'package:flutter/material.dart';

import '../../domain/generators/geometric_templates.dart';
import 'surface_card.dart';

class GeometricTemplatePanel extends StatelessWidget {
  final ValueChanged<GeometricTemplate> onSelected;

  const GeometricTemplatePanel({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final templates = GeometricTemplates.all();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plantillas geométricas',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Formas L, U, T y esquinero armadas con paneles rectos. Cada plantilla se puede editar pieza por pieza.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in templates)
                ActionChip(
                  avatar: Icon(_iconFor(template.id), size: 16),
                  label: Text(template.name),
                  tooltip: template.description,
                  onPressed: () => onSelected(template),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
    'rectangular' => Icons.crop_square,
    'l_shape' => Icons.turn_left,
    'u_shape' => Icons.call_made,
    't_shape' => Icons.call_split,
    'corner' => Icons.vertical_split,
    'staggered' => Icons.stairs_outlined,
    _ => Icons.category_outlined,
  };
}
