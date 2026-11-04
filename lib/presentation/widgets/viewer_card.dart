import 'package:flutter/material.dart';

import '../../domain/entities/furniture.dart';
import '../../domain/entities/part.dart';
import '../painters/part_palette.dart';
import 'stat_chip.dart';
import 'surface_card.dart';
import 'viewer_3d.dart';

class ViewerCard extends StatelessWidget {
  final Furniture furniture;
  final double viewerHeight;

  const ViewerCard({
    super.key,
    required this.furniture,
    this.viewerHeight = 460,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vista 3D', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Mueble armado · arrastra para rotar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatChip(
                  icon: Icons.view_in_ar_outlined,
                  label: '${furniture.parts.length} piezas',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: viewerHeight,
                child: Viewer3D(furniture: furniture),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _LegendItem(kind: PartKind.sidePanel, label: 'Carcasa'),
                _LegendItem(kind: PartKind.shelf, label: 'Estantes'),
                _LegendItem(kind: PartKind.door, label: 'Puertas y frentes'),
                _LegendItem(kind: PartKind.backPanel, label: 'Fondos'),
                _LegendItem(kind: PartKind.drawerBottom, label: 'Cajón'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final PartKind kind;
  final String label;

  const _LegendItem({required this.kind, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: partColor(kind),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
