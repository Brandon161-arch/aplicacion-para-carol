import 'package:flutter/material.dart' hide Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/material.dart';
import '../../domain/entities/part.dart';
import '../providers/custom_model_providers.dart';
import '../painters/wood_swatch_painter.dart';
import 'help_tooltip.dart';
import '../providers/designer_providers.dart';
import 'surface_card.dart';

/// Selector visual de maderas y tableros.
class MaterialSelectorPanel extends ConsumerWidget {
  final String? selectedPartId;

  const MaterialSelectorPanel({super.key, this.selectedPartId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(materialCatalogProvider);
    final draft = ref.watch(customModelProvider);
    final controller = ref.read(customModelProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final materials = catalog.materials
        .where((material) => material.category != MaterialCategory.other)
        .toList(growable: false);
    final selectedMaterial = catalog.byId(draft.defaultMaterialId);
    Part? selectedPart;
    for (final part in draft.parts) {
      if (part.id == selectedPartId) {
        selectedPart = part;
        break;
      }
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forest_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maderas y tableros',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const HelpTooltip(
                message: 'Elige el aspecto de la madera o tablero. El MDF y el aglomerado son económicos; las maderas duras resisten mejor la humedad.',
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            selectedPart == null
                ? 'Elige el material para las piezas nuevas.'
                : 'Se aplicará a “${selectedPart.name}” y a las piezas nuevas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final material in materials)
                _MaterialSwatch(
                  material: material,
                  selected: material.id == draft.defaultMaterialId,
                  onTap: () {
                    controller.updateDefaultMaterial(material.id);
                    if (selectedPartId != null) {
                      final thickness = _thicknessFor(material, selectedPart);
                      controller.applyMaterialToPart(
                        selectedPartId!,
                        material.id,
                        thickness,
                      );
                    }
                  },
                ),
            ],
          ),
          if (selectedMaterial != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 74,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CustomPaint(
                        painter: WoodSwatchPainter(material: selectedMaterial),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${selectedMaterial.name} · ${selectedMaterial.category.label} · '
                      '${selectedMaterial.thicknessLabel} mm'
                      '${selectedMaterial.hasGrain ? ' · con veta' : ''}.\n'
                      'Confirma humedad, acabado y disponibilidad local antes de comprar.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (draft.parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('apply_material_all_button'),
                onPressed: () {
                  final material = selectedMaterial;
                  if (material == null) return;
                  controller.applyMaterialToAll(
                    material.id,
                    material.thicknessesMm.first,
                  );
                },
                icon: const Icon(Icons.format_paint_outlined, size: 18),
                label: const Text('Aplicar a todas las piezas'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _thicknessFor(Material material, Part? part) {
    final current = part?.cutSize.thickness;
    if (current != null &&
        material.thicknessesMm.any(
          (thickness) => (thickness - current).abs() < 0.1,
        )) {
      return current;
    }
    return material.thicknessesMm.first;
  }
}

class _MaterialSwatch extends StatelessWidget {
  final Material material;
  final bool selected;
  final VoidCallback onTap;

  const _MaterialSwatch({
    required this.material,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message:
          '${material.category.label} · ${material.thicknessLabel} mm · '
          '${material.priceUnit.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 118,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: CustomPaint(
                        painter: WoodSwatchPainter(material: material),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (selected)
                    Icon(Icons.check_circle, size: 14, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                material.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
