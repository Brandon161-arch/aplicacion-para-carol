import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/material.dart';
import '../../domain/services/cut_list_calculator.dart';
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
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
