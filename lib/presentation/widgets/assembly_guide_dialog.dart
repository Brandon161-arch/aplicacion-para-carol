import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/drilling_hole.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/services/assembly_guide_generator.dart';
import '../../domain/services/drilling_map_calculator.dart';
import '../../domain/services/industrial_exporter.dart';

/// Diálogo modal con la guía de armado paso a paso y opciones de exportación industrial.
void showAssemblyAndExportDialog(BuildContext context, Furniture furniture) {
  showDialog(
    context: context,
    builder: (context) => _AssemblyAndExportDialog(furniture: furniture),
  );
}

class _AssemblyAndExportDialog extends StatefulWidget {
  final Furniture furniture;

  const _AssemblyAndExportDialog({required this.furniture});

  @override
  State<_AssemblyAndExportDialog> createState() =>
      _AssemblyAndExportDialogState();
}

class _AssemblyAndExportDialogState extends State<_AssemblyAndExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String title) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title copiado al portapapeles.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const guideGen = AssemblyGuideGenerator();
    final manual = guideGen.generate(widget.furniture);

    const drillingCalc = DrillingMapCalculator();
    final drillingPatterns = drillingCalc.calculatePatterns(widget.furniture);

    const exporter = IndustrialExporter();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
        child: Column(
          children: [
            // Cabecera del diálogo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual de Taller & Exportaciones Industriales',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.furniture.name} · Dificultad: ${manual.difficulty} · ~${manual.estimatedTimeMinutes} min',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Pestañas
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.construction, size: 18),
                  text: 'Manual de Armado',
                ),
                Tab(
                  icon: Icon(Icons.grain, size: 18),
                  text: 'Mapas de Perforación',
                ),
                Tab(
                  icon: Icon(Icons.download, size: 18),
                  text: 'Exportación Industrial',
                ),
                Tab(icon: Icon(Icons.qr_code, size: 18), text: 'Etiquetas QR'),
              ],
            ),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña 1: Manual de Armado interactivo
                  _buildManualTab(theme, manual),

                  // Pestaña 2: Mapas de Perforación (Drilling Maps)
                  _buildDrillingTab(theme, drillingPatterns),

                  // Pestaña 3: Exportación Industrial (DXF, G-Code, CSV seccionadora)
                  _buildExportTab(theme, exporter),

                  // Pestaña 4: Etiquetas QR por pieza
                  _buildQrLabelsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab(ThemeData theme, AssemblyManual manual) {
    final scheme = theme.colorScheme;
    final currentStep = manual.steps[_currentStepIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progreso de pasos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${_currentStepIndex + 1} de ${manual.totalSteps}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentStepIndex > 0
                        ? () => setState(() => _currentStepIndex--)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentStepIndex < manual.totalSteps - 1
                        ? () => setState(() => _currentStepIndex++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          LinearProgressIndicator(
            value: (_currentStepIndex + 1) / manual.totalSteps,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),

          // Tarjeta del paso activo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStep.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStep.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (currentStep.partNames.isNotEmpty) ...[
                  const Text(
                    'Piezas involucradas:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: currentStep.partNames
                        .map(
                          (name) => Chip(
                            label: Text(
                              name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (currentStep.fastenersNeeded.isNotEmpty) ...[
                  const Text(
                    'Herrajes requeridos:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  for (final f in currentStep.fastenersNeeded)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Text('• $f', style: const TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(height: 10),
                ],
                if (currentStep.safetyWarning.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentStep.safetyWarning,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Herramientas necesarias del proyecto
          Text(
            'Herramientas recomendadas para el ensamble:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: manual.toolsRequired
                .map(
                  (t) => Chip(
                    avatar: const Icon(Icons.handyman, size: 14),
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillingTab(
    ThemeData theme,
    Map<String, PartDrillingPattern> patterns,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patterns.length,
      itemBuilder: (context, index) {
        final pattern = patterns.values.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Text(
              '${pattern.partName} (${pattern.lengthMm.round()}×${pattern.widthMm.round()}×${pattern.thicknessMm.round()} mm)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              '${pattern.holeCount} perforación(es) detectadas',
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            children: [
              if (pattern.holes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Esta pieza no requiere perforaciones mecanizadas.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      for (final h in pattern.holes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${h.description} [X=${h.xMm.toStringAsFixed(1)} mm, Y=${h.yMm.toStringAsFixed(1)} mm]',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                'Ø${h.diameterMm.round()}×${h.depthMm.round()}mm',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportTab(ThemeData theme, IndustrialExporter exporter) {
    final dxf = exporter.exportToDxf(widget.furniture);
    final gcode = exporter.exportToGCode(widget.furniture);
    final csv = exporter.exportToCutListCsv(widget.furniture);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exportaciones listas para taller y maquinaria CNC:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 12),

          // DXF
          _exportCard(
            theme,
            title: 'Archivo DXF (AutoCAD / CNC AlphaCam / Fusion 360)',
            description: 'Vectores de corte perimetral en capa OUTLINE y círculos de perforación en capa DRILL.',
            icon: Icons.layers_outlined,
            onCopy: () => _copyToClipboard(dxf, 'Archivo DXF'),
            previewLength: '${(dxf.length / 1024).toStringAsFixed(1)} KB',
          ),
          const SizedBox(height: 10),

          // G-CODE
          _exportCard(
            theme,
            title: 'Código G-Code CNC (Fresadora / Seccionadora)',
            description: 'Instrucciones ISO estándar: encendido M03, avance perimetral G01 y perforaciones G81.',
            icon: Icons.precision_manufacturing_outlined,
            onCopy: () => _copyToClipboard(gcode, 'Código G-Code'),
            previewLength: '${(gcode.length / 1024).toStringAsFixed(1)} KB',
          ),
          const SizedBox(height: 10),

          // CSV Seccionadoras
          _exportCard(
            theme,
            title: 'Lista de Despiece CSV (CorteX / Opticut / Placacentro)',
            description: 'Tabla estandarizada con dimensiones exactas, espesores, orientación de veta y los 4 cantos.',
            icon: Icons.table_chart_outlined,
            onCopy: () => _copyToClipboard(csv, 'CSV de Despiece'),
            previewLength: '${csv.split('\n').length} líneas',
          ),
        ],
      ),
    );
  }

  Widget _exportCard(
    ThemeData theme, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onCopy,
    required String previewLength,
  }) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  'Tamaño: $previewLength',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copiar'),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrLabelsTab(ThemeData theme) {
    final parts = widget.furniture.parts;
    final scheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        final qrData =
            'MUEBLE_MAESTRO|ID:${part.id}|NOMBRE:${part.name}|DIM:${part.cutSize.length}x${part.cutSize.width}x${part.cutSize.thickness}mm|MATERIAL:${part.materialId}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Código QR interactivo
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                ),
                const SizedBox(width: 16),
                // Información de etiqueta para taller
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            part.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          Chip(
                            label: Text(
                              'ID: ${part.id}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dimensiones: ${part.cutSize.length.round()} × ${part.cutSize.width.round()} × ${part.cutSize.thickness.round()} mm',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Veta: ${part.grain.name} · Cantos: ${part.edgeBanding.length} lado(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📱 Escanea en taller para resaltar la pieza en el visor 3D',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
