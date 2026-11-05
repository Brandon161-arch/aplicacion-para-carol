import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/material.dart' as domain;
import '../../domain/entities/hardware_item.dart';
import '../providers/designer_providers.dart';
import '../providers/pricing_providers.dart';

Future<void> showPricingEditorDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  LocalPricingData pricingData;
  try {
    pricingData = await ref.read(localPricingProvider.future);
  } catch (_) {
    pricingData = const LocalPricingData();
  }
  if (!context.mounted) return;

  final catalog = ref.read(materialCatalogProvider);
  final controllers = <String, TextEditingController>{
    for (final material in catalog.materials)
      material.id: TextEditingController(
        text: (material.priceCents / 100).round().toString(),
      ),
  };
  final hardwareCatalog = ref.read(hardwarePriceCatalogProvider);
  final hardwareControllers = <HardwareKind, TextEditingController>{
    for (final kind in HardwareKind.values)
      kind: TextEditingController(
        text: (hardwareCatalog.priceFor(kind) / 100).round().toString(),
      ),
  };
  final wasteController = TextEditingController(
    text: pricingData.settings.wastePercent.toStringAsFixed(0),
  );
  final cutController = TextEditingController(
    text: pricingData.settings.cutPricePerSheetOverrideCents == null
        ? ''
        : (pricingData.settings.cutPricePerSheetOverrideCents! / 100)
              .round()
              .toString(),
  );
  final laborRateController = TextEditingController(
    text: (pricingData.settings.laborRateCentsPerHour / 100).round().toString(),
  );
  final laborHoursController = TextEditingController(
    text: pricingData.settings.estimatedLaborHours.toStringAsFixed(1),
  );

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> save() async {
                final overrides = <String, int>{};
                for (final material in catalog.materials) {
                  final value = _parseCop(controllers[material.id]!);
                  if (value != null) overrides[material.id] = value;
                }
                final hardwareOverrides = <String, int>{};
                for (final kind in HardwareKind.values) {
                  final value = _parseCop(hardwareControllers[kind]!);
                  if (value != null) hardwareOverrides[kind.name] = value;
                }
                final currentSettings = pricingData.settings;
                final settings = currentSettings.copyWith(
                  wastePercent:
                      _parseDouble(wasteController.text) ??
                      currentSettings.wastePercent,
                  cutPricePerSheetOverrideCents:
                      cutController.text.trim().isEmpty
                      ? null
                      : _parseCop(cutController) ??
                            currentSettings.cutPricePerSheetOverrideCents,
                  clearCutPriceOverride: cutController.text.trim().isEmpty,
                  laborRateCentsPerHour:
                      _parseCop(laborRateController) ??
                      currentSettings.laborRateCentsPerHour,
                  estimatedLaborHours:
                      _parseDouble(laborHoursController.text) ??
                      currentSettings.estimatedLaborHours,
                );
                await ref
                    .read(localPricingProvider.notifier)
                    .updateAll(
                      materialPriceOverrides: overrides,
                      hardwarePriceOverrides: hardwareOverrides,
                      settings: settings,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              }

              Future<void> reset() async {
                await ref.read(localPricingProvider.notifier).reset();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              }

              final theme = Theme.of(context);
              final scheme = theme.colorScheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.price_change_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precios de referencia',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                'Edita valores en pesos colombianos (COP).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materiales',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final material in catalog.materials) ...[
                            _MaterialPriceRow(
                              material: material,
                              controller: controllers[material.id]!,
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Divider(height: 28),
                          Text(
                            'Herrajes y tornillos',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Precios unitarios de referencia; puedes cambiarlos según tu proveedor.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final kind in HardwareKind.values) ...[
                            _HardwarePriceRow(
                              kind: kind,
                              controller: hardwareControllers[kind]!,
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Divider(height: 28),
                          Text(
                            'Servicios y desperdicio',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final waste = _PriceNumberField(
                                controller: wasteController,
                                label: 'Desperdicio',
                                suffix: '%',
                              );
                              final cut = _PriceNumberField(
                                controller: cutController,
                                label: 'Corte / lámina',
                                suffix: 'COP',
                                helper: 'Vacío = tarifa de referencia Madecentro por rango de piezas.',
                              );
                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    waste,
                                    const SizedBox(height: 10),
                                    cut,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: waste),
                                  const SizedBox(width: 12),
                                  Expanded(child: cut),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mano de obra (opcional)',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final rate = _PriceNumberField(
                                controller: laborRateController,
                                label: 'Tarifa por hora',
                                suffix: 'COP',
                              );
                              final hours = _PriceNumberField(
                                controller: laborHoursController,
                                label: 'Horas estimadas',
                                suffix: 'h',
                              );
                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    rate,
                                    const SizedBox(height: 10),
                                    hours,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: rate),
                                  const SizedBox(width: 12),
                                  Expanded(child: hours),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Referencia consultada: Madecentro (tableros melamínicos y tarifas de corte por lámina) y Homecenter (MDF crudo). Los precios pueden variar por ciudad, marca, color, sede e inventario; verifica antes de comprar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: reset,
                          child: const Text('Restablecer referencia'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton.icon(
                          onPressed: save,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar precios'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  } finally {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final controller in hardwareControllers.values) {
      controller.dispose();
    }
    wasteController.dispose();
    cutController.dispose();
    laborRateController.dispose();
    laborHoursController.dispose();
  }
}

class _MaterialPriceRow extends StatelessWidget {
  final domain.Material material;
  final TextEditingController controller;

  const _MaterialPriceRow({required this.material, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = [
      material.priceUnit.label,
      material.priceSource,
      material.priceNote,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(material.name, style: theme.textTheme.labelLarge),
        Text(
          source,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Precio COP'),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Precio COP'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HardwarePriceRow extends StatelessWidget {
  final HardwareKind kind;
  final TextEditingController controller;

  const _HardwarePriceRow({required this.kind, required this.controller});

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Precio COP', isDense: true),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kind.label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              field,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(kind.label)),
            const SizedBox(width: 10),
            SizedBox(width: 180, child: field),
          ],
        );
      },
    );
  }
}

class _PriceNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? helper;

  const _PriceNumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      helperText: helper,
    ),
  );
}

int? _parseCop(TextEditingController controller) {
  final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value < 0) return null;
  return (value * 100).round();
}

double? _parseDouble(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  return value;
}
