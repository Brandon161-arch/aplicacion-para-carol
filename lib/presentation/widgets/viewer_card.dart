import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/part.dart';
import '../painters/part_palette.dart';
import 'stat_chip.dart';
import 'surface_card.dart';
import 'viewer_3d.dart';

class ViewerCard extends StatelessWidget {
  final Furniture furniture;
  final double viewerHeight;
  final Widget? headerAction;
  final Widget? toolbar;
  final bool moveMode;
  final String? selectedPartId;
  final ValueChanged<String>? onPartSelected;
  final ValueChanged<Part>? onPartMoved;
  final Set<String> hiddenPartIds;

  const ViewerCard({
    super.key,
    required this.furniture,
    this.viewerHeight = 460,
    this.headerAction,
    this.toolbar,
    this.moveMode = false,
    this.selectedPartId,
    this.onPartSelected,
    this.onPartMoved,
    this.hiddenPartIds = const {},
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
                        moveMode
                            ? 'Mueble armado · arrastra una pieza para moverla'
                            : 'Mueble armado · arrastra para rotar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (headerAction != null) ...[
                  headerAction!,
                  const SizedBox(width: 8),
                ],
                StatChip(
                  icon: Icons.view_in_ar_outlined,
                  label: countLabel(
                    furniture.parts.length - hiddenPartIds.length,
                    'pieza',
                    'piezas',
                  ),
                ),
              ],
            ),
          ),
          if (toolbar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(height: 42, child: toolbar),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: viewerHeight,
                child: Viewer3D(
                  furniture: furniture,
                  moveMode: moveMode,
                  selectedPartId: selectedPartId,
                  onPartSelected: onPartSelected,
                  onPartMoved: onPartMoved,
                  hiddenPartIds: hiddenPartIds,
                ),
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
