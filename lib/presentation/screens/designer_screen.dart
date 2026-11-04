import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/designer_providers.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/dimension_panel.dart';
import '../widgets/viewer_card.dart';

class DesignerScreen extends ConsumerWidget {
  const DesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furniture = ref.watch(furnitureProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.carpenter, size: 18, color: scheme.onPrimary),
            ),
            const SizedBox(width: 10),
            const Text('MuebleCAD'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alcance de la Fase 1',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'MuebleCAD',
              applicationVersion: 'Fase 1',
              applicationLegalese: 'Modelo paramétrico, despiece y vista 3D.',
              children: const [
                SizedBox(height: 8),
                Text(
                  'Esta primera fase genera un mueble de ejemplo (repisa baja '
                  'con 2 puertas y 1 cajón) a partir de medidas generales. '
                  'La foto, la base de datos, los planos, el plano de corte, '
                  'los herrajes y los costos llegan en las fases siguientes.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;
          final content = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 360, child: DimensionPanel()),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          ViewerCard(furniture: furniture, viewerHeight: 480),
                          const SizedBox(height: 20),
                          const CutListTable(),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    const DimensionPanel(),
                    const SizedBox(height: 20),
                    ViewerCard(furniture: furniture, viewerHeight: 360),
                    const SizedBox(height: 20),
                    const CutListTable(),
                  ],
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
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
                    _PhaseNote(theme: theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhaseNote extends StatelessWidget {
  final ThemeData theme;

  const _PhaseNote({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fase 1: modelo paramétrico, despiece y visor 3D. '
              'La entrada por foto, la persistencia SQLite, los planos '
              'técnicos, el plano de corte, los herrajes, la ergonomía, '
              'los costos y la exportación a PDF se implementan en las '
              'siguientes fases.',
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
