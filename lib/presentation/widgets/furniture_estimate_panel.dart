import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/cost_report.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/hardware_requirement.dart';
import '../../domain/services/furniture_estimator.dart';
import '../providers/designer_providers.dart';
import '../providers/pricing_providers.dart';
import 'pricing_editor_dialog.dart';
import 'stat_chip.dart';
import 'surface_card.dart';

class FurnitureEstimatePanel extends ConsumerWidget {
  final Furniture furniture;

  const FurnitureEstimatePanel({super.key, required this.furniture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(materialCatalogProvider);
    final hardwarePrices = ref.watch(hardwarePriceCatalogProvider);
    final pricing = ref.watch(pricingSettingsProvider);
    final estimate = const FurnitureEstimator().calculate(
      furniture: furniture,
      catalog: catalog,
      hardwarePrices: hardwarePrices,
      pricingSettings: pricing,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hardwareCard = HardwareCard(requirements: estimate.hardware);
        final costCard = CostSummaryCard(
          report: estimate.costs,
          onEditPrices: () => showPricingEditorDialog(context, ref),
        );
        if (constraints.maxWidth >= 1100) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: hardwareCard),
              const SizedBox(width: 16),
              SizedBox(width: 380, child: costCard),
            ],
          );
        }
        return Column(
          children: [hardwareCard, const SizedBox(height: 16), costCard],
        );
      },
    );
  }
}

class HardwareCard extends StatelessWidget {
  final List<HardwareRequirement> requirements;

  const HardwareCard({super.key, required this.requirements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalPieces = requirements.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Herrajes y tornillos',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cantidad calculada y ubicación recomendada.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatChip(
                icon: Icons.hardware_outlined,
                label: countLabel(totalPieces, 'pieza', 'piezas'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (requirements.isEmpty)
            Text(
              'No se derivaron herrajes. Define uniones o mecanismos para calcularlos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var index = 0; index < requirements.length; index++) ...[
              _HardwareRow(requirement: requirements[index]),
              if (index < requirements.length - 1) const Divider(height: 14),
            ],
            const SizedBox(height: 10),
            Text(
              'Ubicaciones orientativas. Verifica diámetro, largo y patrón de perforación del fabricante antes de armar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HardwareRow extends StatelessWidget {
  final HardwareRequirement requirement;

  const _HardwareRow({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placements = requirement.placements
        .map(
          (placement) =>
              '${placement.location} (${placement.quantity}): ${placement.note}',
        )
        .join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(_hardwareIcon(requirement), size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requirement.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                requirement.spec,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (placements.isNotEmpty)
                Tooltip(
                  message: placements,
                  child: Text(
                    placements,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '×${requirement.quantity}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              formatMoney(requirement.totalPriceCents),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _hardwareIcon(HardwareRequirement item) => switch (item.kind) {
    HardwareKind.hinge => Icons.door_front_door_outlined,
    HardwareKind.drawerSlide => Icons.view_agenda_outlined,
    HardwareKind.screw || HardwareKind.confirmat => Icons.hardware_outlined,
    HardwareKind.dowel => Icons.circle_outlined,
    HardwareKind.shelfPin => Icons.horizontal_rule,
    HardwareKind.handle => Icons.drag_handle,
    HardwareKind.nail => Icons.push_pin_outlined,
    HardwareKind.glue => Icons.water_drop_outlined,
    _ => Icons.build_outlined,
  };
}

class CostSummaryCard extends StatelessWidget {
  final CostReport report;
  final VoidCallback onEditPrices;

  const CostSummaryCard({
    super.key,
    required this.report,
    required this.onEditPrices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final materialLines = report.lines
        .where((line) => line.category == CostCategory.material)
        .toList(growable: false);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Costo estimado', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Materiales, corte y herrajes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar precios y desperdicio',
                onPressed: onEditPrices,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(report.grandTotalCents, currency: report.currency),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in materialLines) _CostLineRow(line: line),
          const Divider(height: 16),
          _SummaryLine(label: 'Cantos', cents: report.edgeBandingTotalCents),
          _SummaryLine(
            label: 'Servicio de corte',
            cents: report.cuttingTotalCents,
          ),
          _SummaryLine(label: 'Herrajes', cents: report.hardwareTotalCents),
          if (report.laborTotalCents > 0)
            _SummaryLine(label: 'Mano de obra', cents: report.laborTotalCents),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Láminas estimadas: ${report.estimatedSheets} · '
              'desperdicio: ${formatM2(report.estimatedWasteAreaM2)} m² '
              '(incluido en la compra de láminas).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.pricingNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostLineRow extends StatelessWidget {
  final CostLine line;

  const _CostLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (line.detail != null)
                  Text(
                    line.detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(line.totalCents),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final int cents;

  const _SummaryLine({required this.label, required this.cents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            formatMoney(cents),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
