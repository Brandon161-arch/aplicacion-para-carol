import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/stability_logistics_calculator.dart';
import '../providers/designer_providers.dart';
import 'surface_card.dart';

class SecurityLogisticsPanel extends ConsumerWidget {
  const SecurityLogisticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furniture = ref.watch(furnitureProvider);
    final catalog = ref.watch(materialCatalogProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const calc = StabilityLogisticsCalculator();
    final stability = calc.calculateStability(furniture, catalog);
    final logistics = calc.calculatePacking(furniture, catalog);

    final isDanger = stability.safetyLevel == 'danger';
    final isWarning = stability.safetyLevel == 'warning';

    final badgeColor = isDanger
        ? Colors.red
        : (isWarning ? Colors.orange : Colors.green);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seguridad & Logística RTA',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Centro de gravedad, antivuelco y empaque plano',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fila de Estadísticas Rápidas
          Row(
            children: [
              Expanded(
                child: _statBox(
                  theme,
                  label: 'Peso Neto Total',
                  value: '${stability.totalMassKg.toStringAsFixed(1)} kg',
                  icon: Icons.scale,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  theme,
                  label: 'Centro Gravedad (Y)',
                  value: '${stability.centerOfGravityMm.y.round()} mm',
                  icon: Icons.vertical_align_center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  theme,
                  label: 'Cajas de Empaque',
                  value: '${logistics.totalBoxCount} caja${logistics.totalBoxCount > 1 ? 's' : ''}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alerta de Antivuelco / Estabilidad
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  stability.isTipOverRisk ? Icons.warning_rounded : Icons.verified_user_outlined,
                  color: badgeColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stability.isTipOverRisk
                            ? 'ALERTA DE SEGURIDAD ANTIVUELCO'
                            : (stability.wallAnchorRequired
                                ? 'Precaución de anclaje recomendada'
                                : 'Estabilidad comprobada (Segura)'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stability.safetyRecommendation,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Packing List / Cajas RTA
          Text(
            'Detalle de Empaque Plano (RTA):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          for (final box in logistics.packages) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caja #${box.boxNumber}: ${box.lengthMm.round()} × ${box.widthMm.round()} × ${box.heightMm.round()} mm',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Text(
                          '${box.partNames.length} piezas · ${(box.volumeM3 * 1000).toStringAsFixed(1)} L vol.',
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${box.weightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: box.weightKg > 25 ? Colors.orange : scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
