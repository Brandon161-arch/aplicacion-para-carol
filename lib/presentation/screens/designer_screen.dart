import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/cut_list_calculator.dart';
import '../providers/designer_providers.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/dimension_panel.dart';
import '../widgets/flat_patterns_panel.dart';
import '../widgets/part_detail_dialog.dart';
import '../widgets/viewer_card.dart';

class DesignerScreen extends ConsumerWidget {
  const DesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furniture = ref.watch(furnitureProvider);
    final cutList = ref.watch(cutListProvider);
    final catalog = ref.watch(materialCatalogProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    void openDetail(BuildContext context, CutListItem item) {
      final part = furniture.partById(item.partIds.first);
      if (part == null) return;
      showPartDetailDialog(context, part: part, item: item, catalog: catalog);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;
        final templatesBeside = constraints.maxWidth >= 1280;

        final templates = FlatPatternsPanel(
          cutList: cutList,
          catalog: catalog,
          height: templatesBeside ? 480 : 430,
          onOpen: (item) => openDetail(context, item),
        );

        final main = Column(
          children: [
            if (templatesBeside)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ViewerCard(furniture: furniture, viewerHeight: 480),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(width: 400, child: templates),
                ],
              )
            else ...[
              ViewerCard(furniture: furniture, viewerHeight: 420),
              const SizedBox(height: 20),
              templates,
            ],
            const SizedBox(height: 20),
            CutListTable(
              cutList: cutList,
              catalog: catalog,
              onItemTap: (item) => openDetail(context, item),
            ),
          ],
        );

        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 360, child: DimensionPanel()),
                  const SizedBox(width: 20),
                  Expanded(child: main),
                ],
              )
            : Column(
                children: [
                  const DimensionPanel(),
                  const SizedBox(height: 20),
                  main,
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diseño del mueble',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mueble de ejemplo: repisa baja con 2 puertas y 1 cajón. '
                    'Cambia las medidas y todo se recalcula.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  content,
                  const SizedBox(height: 24),
                  _FooterNote(theme: theme),
                ],
              ),
            ),
          ),
        );
      },
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
