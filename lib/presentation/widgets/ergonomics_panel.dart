import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/ergonomics_service.dart';
import '../providers/designer_providers.dart';
import 'surface_card.dart';

class ErgonomicsPanel extends ConsumerStatefulWidget {
  const ErgonomicsPanel({super.key});

  @override
  ConsumerState<ErgonomicsPanel> createState() => _ErgonomicsPanelState();
}

class _ErgonomicsPanelState extends ConsumerState<ErgonomicsPanel> {
  double _userHeight = 170.0;

  @override
  Widget build(BuildContext context) {
    final furniture = ref.watch(furnitureProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final profile = AntropometricProfile(
      userHeightCm: _userHeight,
      isCustomUserHeight: true,
    );

    const service = ErgonomicsService();
    final report = service.evaluate(furniture, profile);

    final statusColor = switch (report.overallStatus) {
      ErgonomicStatus.optimal => const Color(0xFF2E7D32), // Verde
      ErgonomicStatus.caution => const Color(0xFFF57C00), // Amarillo/Naranja
      ErgonomicStatus.hazard => const Color(0xFFD32F2F),  // Rojo
    };

    final statusLabel = switch (report.overallStatus) {
      ErgonomicStatus.optimal => 'Óptimo para la salud postural',
      ErgonomicStatus.caution => 'Precaución ergonómica',
      ErgonomicStatus.hazard => 'Riesgo ergonómico detectado',
    };

    final statusIcon = switch (report.overallStatus) {
      ErgonomicStatus.optimal => Icons.check_circle_outline,
      ErgonomicStatus.caution => Icons.warning_amber_rounded,
      ErgonomicStatus.hazard => Icons.error_outline_rounded,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ergonomía & Antropometría',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Semáforo ergonómico y postura',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selector de Estatura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.height, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estatura del usuario:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_userHeight.round()} cm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _userHeight,
                        min: 140.0,
                        max: 205.0,
                        divisions: 65,
                        onChanged: (v) => setState(() => _userHeight = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Semáforo Principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Codos a ${profile.elbowHeightStandingMm.round()} mm · Alcance a ${profile.maxComfortableReachMm.round()} mm',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lista de Alertas Detalladas
          for (final alert in report.alerts) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: alert.status == ErgonomicStatus.optimal
                      ? Colors.green.withValues(alpha: 0.25)
                      : (alert.status == ErgonomicStatus.hazard
                          ? Colors.red.withValues(alpha: 0.4)
                          : Colors.orange.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.dimensionName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${alert.currentValueMm.round()} mm',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: alert.status == ErgonomicStatus.optimal
                              ? Colors.green
                              : (alert.status == ErgonomicStatus.hazard ? Colors.red : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.explanation,
                    style: TextStyle(fontSize: 11.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85)),
                  ),
                  if (alert.needsAdjustment) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert.recommendation,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            // Ajustar altura automáticamente a la recomendada
                            ref.read(designerProvider.notifier).updateOverallSize(height: alert.idealValueMm);
                          },
                          icon: const Icon(Icons.auto_fix_high, size: 14),
                          label: const Text('Auto-ajustar', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
