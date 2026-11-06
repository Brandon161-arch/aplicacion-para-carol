import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/material.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/services/board_nesting_calculator.dart';
import '../painters/part_palette.dart';
import 'stat_chip.dart';
import 'surface_card.dart';

class CutListTable extends StatelessWidget {
  final CutList cutList;
  final MaterialCatalog catalog;
  final void Function(CutListItem item)? onItemTap;

  const CutListTable({
    super.key,
    required this.cutList,
    required this.catalog,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Despiece', style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          onItemTap == null
              ? 'Medidas de corte exactas y cantidades agrupadas.'
              : 'Toca una fila para ver la pieza en 3D y su plantilla.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final chips = [
      StatChip(
        icon: Icons.format_list_numbered,
        label: countLabel(cutList.items.length, 'fila', 'filas'),
      ),
      StatChip(
        icon: Icons.widgets_outlined,
        label: countLabel(cutList.totalPieces, 'pieza', 'piezas'),
      ),
      StatChip(
        icon: Icons.square_foot,
        label: '${formatM2(cutList.totalAreaM2)} m²',
      ),
      StatChip(
        icon: Icons.content_cut,
        label: 'Kerf ${formatMm(cutList.kerfMm)} mm',
      ),
    ];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                return Row(
                  children: [
                    Expanded(child: title),
                    for (var index = 0; index < chips.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      chips[index],
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Kerf ${formatMm(cutList.kerfMm)} mm · recorrido estimado por perímetros: ${formatMeters(cutList.estimatedCutLengthM)} m · pérdida estimada: ${formatM2(cutList.estimatedKerfLossM2)} m². Los mapas siguientes usan un nesting heurístico y deben verificarse con el patrón de corte de tu taller.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.85),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1010),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 44,
                    dataRowMinHeight: 42,
                    dataRowMaxHeight: 48,
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                    dataTextStyle: theme.textTheme.bodyMedium,
                    columns: const [
                      DataColumn(label: Text('Pieza')),
                      DataColumn(label: Text('Cant.'), numeric: true),
                      DataColumn(label: Text('Largo'), numeric: true),
                      DataColumn(label: Text('Ancho'), numeric: true),
                      DataColumn(label: Text('Esp.'), numeric: true),
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Veta')),
                      DataColumn(label: Text('Cantos'), numeric: true),
                      DataColumn(label: Text('Área m²'), numeric: true),
                      DataColumn(label: Text('Ver')),
                    ],
                    rows: [
                      for (final item in cutList.items)
                        DataRow(
                          color: WidgetStatePropertyAll(
                            cutList.items.indexOf(item).isEven
                                ? Colors.transparent
                                : AppTheme.rowStripe,
                          ),
                          onSelectChanged: onItemTap == null
                              ? null
                              : (_) => onItemTap!(item),
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    partIcon(item.kind),
                                    size: 17,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                '×${item.quantity}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(Text(formatMm(item.cutSize.length))),
                            DataCell(Text(formatMm(item.cutSize.width))),
                            DataCell(Text(formatMm(item.cutSize.thickness))),
                            DataCell(Text(item.materialName)),
                            DataCell(Text(item.grain.label)),
                            DataCell(
                              Tooltip(
                                message: item.bandedEdgeCount == 0
                                    ? 'Sin canto'
                                    : '${formatMeters(item.bandingLengthM)} m de canto',
                                child: Text(_bandingLabel(item)),
                              ),
                            ),
                            DataCell(Text(formatM2(item.areaM2))),
                            DataCell(
                              Icon(
                                onItemTap == null
                                    ? Icons.remove
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: onItemTap == null
                                    ? scheme.outline
                                    : scheme.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _BoardNestingMaps(nesting: cutList.nesting),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in cutList.areaByMaterial.entries)
                Tooltip(
                  message: catalog.byId(entry.key)?.name ?? entry.key,
                  child: StatChip(
                    icon: Icons.layers_outlined,
                    label:
                        '${_shortMaterialName(entry.key)}: ${formatM2(entry.value)} m²',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Las medidas están en milímetros. El despiece se deriva de la geometría del mueble, no se digita aparte.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _bandingLabel(CutListItem item) {
    if (item.bandedEdgeCount == 0) return '—';
    if (item.bandedEdgeCount == 1) return '1 lado';
    return '${item.bandedEdgeCount} lados';
  }

  String _shortMaterialName(String id) {
    final name = catalog.byId(id)?.name ?? id;
    return name.split(' (').first.replaceAll(' mm', '');
  }
}

class _BoardNestingMaps extends StatelessWidget {
  final NestingResult nesting;

  const _BoardNestingMaps({required this.nesting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final materialLayouts = nesting.byMaterial.values
        .where((result) => result.sheets.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mapas heurísticos de tablero',
                style: theme.textTheme.titleSmall,
              ),
            ),
            StatChip(
              icon: Icons.layers_outlined,
              label: countLabel(nesting.totalSheets, 'tablero', 'tableros'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (nesting.unplacedPartIds.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'Piezas sin ubicar: ${nesting.unplacedPartIds.join(', ')}. Revisa material, tamaño del tablero y veta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        if (materialLayouts.isEmpty)
          Text(
            'No hay piezas de material en lámina para optimizar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final material in materialLayouts)
                  for (final sheet in material.sheets)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${material.materialName} · tablero ${sheet.index}/${material.sheetCount}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${sheet.board.label} · ${(sheet.utilization * 100).toStringAsFixed(1)}% utilizado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 280,
                              height: 190,
                              child: CustomPaint(
                                painter: _NestingSheetPainter(sheet),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NestingSheetPainter extends CustomPainter {
  final NestingSheet sheet;

  const _NestingSheetPainter(this.sheet);

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final boardRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final scale = math.min(
      boardRect.width / sheet.board.widthMm,
      boardRect.height / sheet.board.heightMm,
    );
    final renderedWidth = sheet.board.widthMm * scale;
    final renderedHeight = sheet.board.heightMm * scale;
    final origin = Offset(
      (size.width - renderedWidth) / 2,
      (size.height - renderedHeight) / 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, renderedWidth, renderedHeight),
      Paint()..color = const Color(0xFFF6F3EE),
    );
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, renderedWidth, renderedHeight),
      Paint()
        ..color = const Color(0xFF61574F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    const colors = [
      Color(0xFFB7D7C4),
      Color(0xFFC6D7E8),
      Color(0xFFE9D5A5),
      Color(0xFFE5C3B8),
    ];
    for (var index = 0; index < sheet.placements.length; index++) {
      final placement = sheet.placements[index];
      final rect = Rect.fromLTWH(
        origin.dx + placement.xMm * scale,
        origin.dy + placement.yMm * scale,
        placement.widthMm * scale,
        placement.heightMm * scale,
      );
      canvas.drawRect(rect, Paint()..color = colors[index % colors.length]);
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF39433F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      if (rect.width > 28 && rect.height > 12) {
        final label = placement.partName.length > 11
            ? '${placement.partName.substring(0, 10)}…'
            : placement.partName;
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 8, color: Color(0xFF26332C)),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 2);
        text.paint(canvas, rect.topLeft + const Offset(2, 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NestingSheetPainter oldDelegate) =>
      oldDelegate.sheet != sheet;
}
