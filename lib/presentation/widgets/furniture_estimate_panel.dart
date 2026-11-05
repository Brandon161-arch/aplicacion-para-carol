import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/cost_report.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/hardware_requirement.dart';
import '../../domain/services/furniture_estimator.dart';
import '../../domain/services/manufacturability_validator.dart';
import '../providers/designer_providers.dart';
import '../providers/pricing_providers.dart';
import '../providers/project_context_provider.dart';
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
    final projectContext = ref.watch(projectContextValueProvider);
    final country = projectContext?.country;
    final estimate = const FurnitureEstimator().calculate(
      furniture: furniture,
      catalog: catalog,
      hardwarePrices: hardwarePrices,
      pricingSettings: pricing,
      taxPercent:
          pricing.taxPercentOverride ?? country?.standardTaxPercent ?? 0,
      kerfMm: projectContext?.kerfMm ?? 3.2,
      cutPriceTiers: country?.cutPriceTiers ?? const [],
      pricingNote: country?.pricingNote ?? 'Precios locales no configurados.',
    );
    final materialPricesComplete = estimate.cutList.items.every((item) {
      final material = catalog.byId(item.materialId);
      return material != null && material.priceCents > 0;
    });
    final hardwarePricesComplete = estimate.hardware.every(
      (item) => item.unitPriceCents > 0,
    );
    final cutPriceConfigured =
        pricing.cutPricePerSheetOverrideCents != null ||
        (country?.cutPriceTiers.isNotEmpty ?? false);
    final regionalPricesAvailable =
        materialPricesComplete && hardwarePricesComplete && cutPriceConfigured;
    final buildabilityIssues = [
      ...const ManufacturabilityValidator().validate(
        furniture: furniture,
        materials: catalog,
        boardFormats: country?.boardSizes ?? const [],
        kerfMm: projectContext?.kerfMm ?? 3.2,
      ),
      if (estimate.cutList.nesting.unplacedPartIds.isNotEmpty)
        BuildabilityIssue(
          severity: BuildabilitySeverity.error,
          code: 'nesting-incomplete',
          message:
              '${estimate.cutList.nesting.unplacedPartIds.length} pieza(s) no caben en los mapas actuales de tablero.',
          suggestion: 'Revisa dimensiones, veta o formato de tablero; el estimador usa una heurística de nesting.',
          partIds: estimate.cutList.nesting.unplacedPartIds,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BuildabilityCard(issues: buildabilityIssues),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final hardwareCard = HardwareCard(
              requirements: estimate.hardware,
              showPrices: regionalPricesAvailable,
              currency: pricing.currency,
            );
            final costCard = CostSummaryCard(
              report: estimate.costs,
              onEditPrices: () => showPricingEditorDialog(context, ref),
            );
            final displayedCostCard = regionalPricesAvailable
                ? costCard
                : _RegionalCostUnavailableCard(
                    countryName: country?.name ?? 'este país',
                    currency: country?.currency ?? '',
                    onEditPrices: () => showPricingEditorDialog(context, ref),
                  );
            if (constraints.maxWidth >= 1100) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: hardwareCard),
                  const SizedBox(width: 16),
                  SizedBox(width: 380, child: displayedCostCard),
                ],
              );
            }
            return Column(
              children: [
                hardwareCard,
                const SizedBox(height: 16),
                displayedCostCard,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BuildabilityCard extends StatelessWidget {
  final List<BuildabilityIssue> issues;

  const _BuildabilityCard({required this.issues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final errors = issues
        .where((issue) => issue.severity == BuildabilitySeverity.error)
        .toList(growable: false);
    final warnings = issues
        .where((issue) => issue.severity == BuildabilitySeverity.warning)
        .toList(growable: false);
    final color = errors.isNotEmpty
        ? scheme.error
        : warnings.isNotEmpty
        ? const Color(0xFFB26A00)
        : const Color(0xFF2E7D32);
    final visibleIssues = [...errors, ...warnings].take(4);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errors.isNotEmpty
                    ? Icons.error_outline
                    : warnings.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errors.isNotEmpty
                      ? 'Hay problemas de fabricación'
                      : warnings.isNotEmpty
                      ? 'Revisa estas condiciones antes de fabricar'
                      : 'Validación geométrica sin alertas',
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
              Text(
                '${errors.length} errores · ${warnings.length} avisos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final issue in visibleIssues)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '• ${issue.message} ${issue.suggestion}',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          if (issues.isEmpty)
            Text(
              'Se comprobaron dimensiones, límites del tablero, veta y colisiones de cajas. Las uniones, cargas estructurales y holguras de herrajes todavía requieren verificación específica.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          if (issues.length > 4)
            Text(
              'Hay ${issues.length - 4} alertas adicionales.',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
        ],
      ),
    );
  }
}

class HardwareCard extends StatelessWidget {
  final List<HardwareRequirement> requirements;
  final bool showPrices;
  final String currency;

  const HardwareCard({
    super.key,
    required this.requirements,
    this.showPrices = true,
    this.currency = 'COP',
  });

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
              _HardwareRow(
                requirement: requirements[index],
                showPrices: showPrices,
                currency: currency,
              ),
              if (index < requirements.length - 1) const Divider(height: 14),
            ],
            const SizedBox(height: 10),
            Text(
              'Ubicaciones orientativas; en muebles creados a mano algunas uniones se infieren por contacto entre piezas. Verifica diámetro, largo y patrón del fabricante antes de perforar.',
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
  final bool showPrices;
  final String currency;

  const _HardwareRow({
    required this.requirement,
    required this.showPrices,
    required this.currency,
  });

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
              if (requirement.spec != requirement.name)
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
        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '×${requirement.quantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showPrices)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatMoney(requirement.totalPriceCents, currency: currency),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Text(
                  'precio local pendiente',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
            ],
          ),
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
                    Text(
                      'Costo total estimado',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Producción + impuesto local; sin margen comercial',
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
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(
                  report.totalWithTaxCents,
                  currency: report.currency,
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final line in materialLines)
            _CostLineRow(line: line, currency: report.currency),
          const Divider(height: 16),
          _SummaryLine(
            label: 'Cantos',
            cents: report.edgeBandingTotalCents,
            currency: report.currency,
          ),
          _SummaryLine(
            label: 'Servicio de corte',
            cents: report.cuttingTotalCents,
            currency: report.currency,
          ),
          _SummaryLine(
            label: 'Herrajes',
            cents: report.hardwareTotalCents,
            currency: report.currency,
          ),
          if (report.laborTotalCents > 0)
            _SummaryLine(
              label: 'Mano de obra',
              cents: report.laborTotalCents,
              currency: report.currency,
            ),
          const Divider(height: 16),
          _SummaryLine(
            label: 'Subtotal de producción',
            cents: report.grandTotalCents,
            currency: report.currency,
          ),
          if (report.taxPercent > 0)
            _SummaryLine(
              label:
                  'Impuesto local (${report.taxPercent.toStringAsFixed(0)}%)',
              cents: report.taxTotalCents,
              currency: report.currency,
            ),
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
              'kerf ${formatMm(report.kerfMm)} mm, recorrido aprox. ${formatMeters(report.estimatedCutLengthM)} m '
              '(${formatM2(report.estimatedKerfLossM2)} m²) · '
              'desperdicio: ${formatM2(report.estimatedWasteAreaM2)} m² '
              '(${formatMoney(report.wasteTotalCents, currency: report.currency)} aprox., incluido en láminas).',
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

class _RegionalCostUnavailableCard extends StatelessWidget {
  final String countryName;
  final String currency;
  final VoidCallback onEditPrices;

  const _RegionalCostUnavailableCard({
    required this.countryName,
    required this.currency,
    required this.onEditPrices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Precios locales pendientes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'La lista de materiales y cantidades sigue disponible, pero faltan precios locales para $countryName ($currency). No convertimos precios de otra moneda.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEditPrices,
            icon: const Icon(Icons.price_change_outlined, size: 18),
            label: Text('Configurar precios $currency'),
          ),
        ],
      ),
    );
  }
}

class _CostLineRow extends StatelessWidget {
  final CostLine line;
  final String currency;

  const _CostLineRow({required this.line, required this.currency});

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
          SizedBox(
            width: 92,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(line.totalCents, currency: currency),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
  final String currency;

  const _SummaryLine({
    required this.label,
    required this.cents,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          SizedBox(
            width: 92,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(cents, currency: currency),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
