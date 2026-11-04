import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/services/furniture_validator.dart';
import '../providers/designer_providers.dart';
import 'mm_field.dart';
import 'stat_chip.dart';
import 'surface_card.dart';

class DimensionPanel extends ConsumerWidget {
  const DimensionPanel({super.key});

  static const List<double> _thicknessOptions = [15, 18, 25];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = ref.watch(designerProvider);
    final controller = ref.read(designerProvider.notifier);
    final issues = ref.watch(validationProvider);
    final settings = spec.settings;
    final theme = Theme.of(context);
    final selectedThickness =
        _thicknessOptions.contains(settings.panelThicknessMm)
        ? settings.panelThicknessMm
        : 18.0;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dimensiones', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Cambia las medidas y el despiece y la vista 3D se recalculan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ValidationBanner(issues: issues),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MmField(
                  fieldKey: const Key('width_field'),
                  label: 'Ancho',
                  value: spec.overallSize.width,
                  onChanged: (value) =>
                      controller.updateOverallSize(width: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MmField(
                  fieldKey: const Key('height_field'),
                  label: 'Alto',
                  value: spec.overallSize.height,
                  onChanged: (value) =>
                      controller.updateOverallSize(height: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MmField(
                  fieldKey: const Key('depth_field'),
                  label: 'Fondo',
                  value: spec.overallSize.depth,
                  onChanged: (value) =>
                      controller.updateOverallSize(depth: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MmField(
                  fieldKey: const Key('plinth_field'),
                  label: 'Zócalo',
                  value: settings.plinthHeightMm,
                  onChanged: controller.updatePlinthHeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MmField(
                  fieldKey: const Key('drawer_height_field'),
                  label: 'Alto del cajón',
                  value: spec.drawerHeightMm,
                  onChanged: controller.updateDrawerHeight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _ShelfCountField(spec: spec)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Espesor del panel', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              segments: [
                for (final thickness in _thicknessOptions)
                  ButtonSegment<double>(
                    value: thickness,
                    label: Text(formatMm(thickness)),
                  ),
              ],
              selected: {selectedThickness},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  controller.updatePanelThickness(selection.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El material se ajusta al espesor. Los cantos y el fondo se calculan aparte.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Restablecer mueble'),
            ),
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(
                icon: Icons.layers_outlined,
                label: 'Panel ${formatMm(settings.panelThicknessMm)} mm',
              ),
              StatChip(
                icon: Icons.layers,
                label: 'Fondo ${formatMm(settings.backPanelThicknessMm)} mm',
              ),
              StatChip(
                icon: Icons.space_bar,
                label: 'Holgura ${formatMm(settings.doorGapMm)} mm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final List<ValidationIssue> issues;

  const _ValidationBanner({required this.issues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (issues.isEmpty) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 17,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Text(
            'Geometría válida',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      );
    }

    final sorted = [...issues]
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
    final hasError = sorted.any(
      (issue) => issue.severity == ValidationSeverity.error,
    );
    final color = hasError ? scheme.error : const Color(0xFFB26A00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.warning_amber_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                hasError ? 'Revisa las medidas' : 'Ten en cuenta',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final issue in sorted.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• ${issue.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (sorted.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• y ${sorted.length - 3} aviso(s) más',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShelfCountField extends ConsumerWidget {
  final CabinetSpec spec;

  const _ShelfCountField({required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(designerProvider.notifier);
    final count = spec.shelfCount;
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Estantes'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Quitar estante',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            onPressed: count > 0
                ? () => controller.updateShelfCount(count - 1)
                : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$count', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            tooltip: 'Agregar estante',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            onPressed: count < 8
                ? () => controller.updateShelfCount(count + 1)
                : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}
