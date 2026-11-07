import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/cut_list_calculator.dart';
import '../providers/designer_providers.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/dimension_panel.dart';
import '../widgets/flow_steps.dart';
import '../widgets/flat_patterns_panel.dart';
import '../widgets/furniture_estimate_panel.dart';
import '../widgets/part_detail_dialog.dart';
import '../widgets/regional_material_panel.dart';
import '../widgets/viewer_card.dart';
import '../widgets/workspace_layout.dart';

class DesignerScreen extends ConsumerWidget {
  const DesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furniture = ref.watch(furnitureProvider);
    final cutList = ref.watch(cutListProvider);
    final catalog = ref.watch(materialCatalogProvider);
    final highlightDimension = ref.watch(dimensionFocusProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    void openDetail(BuildContext context, CutListItem item) {
      final part = furniture.partById(item.partIds.first);
      if (part == null) return;
      showPartDetailDialog(context, part: part, item: item, catalog: catalog);
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diseño del mueble', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Mueble de ejemplo: repisa baja con 2 puertas y 1 cajón. '
          'Cambia las medidas y todo se recalcula.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const FlowSteps(
          steps: [
            'Ajusta medidas',
            'Elige material',
            'Revisa el 3D',
            'Usa el despiece',
          ],
        ),
      ],
    );

    final left = Column(
      children: [
        const DimensionPanel(),
        const SizedBox(height: 14),
        const RegionalMaterialPanel(),
      ],
    );

    final right = Column(
      children: [
        FlatPatternsPanel(
          cutList: cutList,
          catalog: catalog,
          onOpen: (item) => openDetail(context, item),
        ),
        const SizedBox(height: 16),
        CutListTable(
          cutList: cutList,
          catalog: catalog,
          onItemTap: (item) => openDetail(context, item),
        ),
        const SizedBox(height: 20),
        FurnitureEstimatePanel(furniture: furniture),
        const SizedBox(height: 24),
        _FooterNote(theme: theme),
      ],
    );

    return WorkspaceLayout(
      header: header,
      left: left,
      viewer: ViewerCard(
        furniture: furniture,
        fillHeight: true,
        highlightDimension: highlightDimension,
      ),
      right: right,
    );
  }
}

class _FooterNote extends StatelessWidget {
  final ThemeData theme;

  const _FooterNote({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Toca cualquier fila del despiece o cualquier plantilla para ver '
              'la pieza aislada en 3D, sus cotas y cómo se corta. '
              'La biblioteca de muebles se guarda en este dispositivo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
