import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/material.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/flat_pattern_painter.dart';
import '../painters/part_palette.dart';
import 'stat_chip.dart';
import 'surface_card.dart';
import 'viewer_3d.dart';

Future<void> showPartDetailDialog(
  BuildContext context, {
  required Part part,
  required CutListItem item,
  required MaterialCatalog catalog,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        PartDetailDialog(part: part, item: item, catalog: catalog),
  );
}

class PartDetailDialog extends StatelessWidget {
  final Part part;
  final CutListItem item;
  final MaterialCatalog catalog;

  const PartDetailDialog({
    super.key,
    required this.part,
    required this.item,
    required this.catalog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final previewSize = Size3(
      width: item.cutSize.length,
      height: item.cutSize.width,
      depth: item.cutSize.thickness,
    );
    final previewPart = part.copyWith(
      id: 'preview_${part.id}',
      size: previewSize,
      position: Vector3.zero,
    );
    final previewFurniture = Furniture(
      id: 'part_preview',
      name: part.name,
      type: FurnitureType.custom,
      overallSize: previewSize,
      settings: ConstructionSettings(panelThicknessMm: item.cutSize.thickness),
      parts: [previewPart],
    );
    final materialName =
        catalog.byId(item.materialId)?.name ?? item.materialName;
    final banding = item.bandedEdgeCount == 0
        ? 'Sin cantos'
        : '${item.bandedEdgeCount} ${item.bandedEdgeCount == 1 ? 'lado' : 'lados'} · ${formatMeters(item.bandingLengthM)} m';

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: partColor(part.kind).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      partIcon(part.kind),
                      color: scheme.onSurface,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle de pieza',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(part.name, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatChip(
                    icon: Icons.straighten,
                    label: 'Largo ${formatMm(item.cutSize.length)} mm',
                  ),
                  StatChip(
                    icon: Icons.swap_horiz,
                    label: 'Ancho ${formatMm(item.cutSize.width)} mm',
                  ),
                  StatChip(
                    icon: Icons.layers_outlined,
                    label: 'Espesor ${formatMm(item.cutSize.thickness)} mm',
                  ),
                  StatChip(
                    icon: Icons.widgets_outlined,
                    label: 'Cantidad ${item.quantity}',
                  ),
                  StatChip(icon: Icons.category_outlined, label: materialName),
                  StatChip(
                    icon: Icons.texture,
                    label: 'Veta: ${item.grain.label}',
                  ),
                  StatChip(icon: Icons.border_outer, label: banding),
                  StatChip(
                    icon: Icons.square_foot,
                    label: '${formatM2(item.areaM2)} m²',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final threeD = _PreviewPanel(
                    title: 'Vista 3D de la pieza',
                    subtitle: 'Pieza aislada · gírala con el mouse',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 300,
                        child: Viewer3D(furniture: previewFurniture),
                      ),
                    ),
                  );
                  final pattern = _PreviewPanel(
                    title: 'Plantilla de corte',
                    subtitle:
                        '${formatMm(item.cutSize.length)} × ${formatMm(item.cutSize.width)} mm · espesor ${formatMm(item.cutSize.thickness)} mm',
                    child: SizedBox(
                      height: 300,
                      child: CustomPaint(
                        painter: FlatPatternPainter(
                          cutSize: item.cutSize,
                          grain: item.grain,
                          bandedEdges: item.bandedEdges,
                          panelColor: partColor(part.kind),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 720) {
                    return Column(
                      children: [threeD, const SizedBox(height: 14), pattern],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: threeD),
                      const SizedBox(width: 14),
                      Expanded(flex: 10, child: pattern),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Las cotas están en milímetros y corresponden a la medida de corte. '
                  'La vista 3D muestra la pieza aislada; en el mueble puede estar girada '
                  'según su posición. Los cantos resaltados en naranja son los que se pegan.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PreviewPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
