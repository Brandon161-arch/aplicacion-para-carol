import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/generators/geometric_templates.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/services/manufacturability_validator.dart';
import '../../domain/value_objects/vector3.dart';
import '../../domain/value_objects/measurement_unit.dart';
import '../painters/part_palette.dart';
import '../providers/custom_model_providers.dart';
import '../providers/designer_providers.dart';
import '../providers/library_providers.dart';
import '../providers/project_context_provider.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/flat_patterns_panel.dart';
import '../widgets/furniture_estimate_panel.dart';
import '../widgets/geometric_template_panel.dart';
import '../widgets/material_selector_panel.dart';
import '../widgets/mm_field.dart';
import '../widgets/part_detail_dialog.dart';
import '../widgets/part_editor_dialog.dart';
import '../widgets/plan_sketch_panel.dart';
import '../widgets/regional_material_panel.dart';
import '../widgets/surface_card.dart';
import '../widgets/viewer_card.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late final TextEditingController _nameController;
  final ScrollController _scrollController = ScrollController();
  String? _selectedPartId;
  bool _moveMode = true;
  bool _sketchDrawing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(customModelProvider).name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(customModelProvider);
    final furniture = ref.watch(customFurnitureProvider);
    final cutList = ref.watch(customCutListProvider);
    final catalog = ref.watch(materialCatalogProvider);
    final presets = ref.watch(presetFurnitureProvider);
    final projectContext = ref.watch(projectContextValueProvider);
    final displayUnit = projectContext?.unit ?? MeasurementUnit.millimeter;
    final buildabilityIssues = [
      ...const ManufacturabilityValidator().validate(
        furniture: furniture,
        materials: catalog,
        boardFormats: projectContext?.country.boardSizes ?? const [],
        kerfMm: projectContext?.kerfMm ?? 3.2,
      ),
      if (cutList.nesting.unplacedPartIds.isNotEmpty)
        BuildabilityIssue(
          severity: BuildabilitySeverity.error,
          code: 'nesting-incomplete',
          message:
              '${cutList.nesting.unplacedPartIds.length} pieza(s) no caben en los mapas de tablero.',
          suggestion: 'Revisa tamaño, orientación o formato de tablero antes de guardar.',
          partIds: cutList.nesting.unplacedPartIds,
        ),
    ];
    final hasBuildabilityErrors = buildabilityIssues.any(
      (issue) => issue.severity == BuildabilitySeverity.error,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(customModelProvider.notifier);

    ref.listen(customModelProvider.select((value) => value.name), (
      previous,
      next,
    ) {
      if (_nameController.text != next) {
        _nameController.text = next;
      }
    });

    Part? selectedPart;
    if (_selectedPartId != null) {
      for (final part in draft.parts) {
        if (part.id == _selectedPartId) {
          selectedPart = part;
          break;
        }
      }
    }
    final selected = selectedPart;

    void selectPart(String id) => setState(() => _selectedPartId = id);

    void updatePartPosition(Part part, {double? x, double? y, double? z}) {
      final maxX = math.max(0.0, draft.overallSize.width - part.size.width);
      final maxY = math.max(0.0, draft.overallSize.height - part.size.height);
      final maxZ = math.max(0.0, draft.overallSize.depth - part.size.depth);
      controller.updatePart(
        part.copyWith(
          position: Vector3(
            (x ?? part.position.x).clamp(0.0, maxX).toDouble(),
            (y ?? part.position.y).clamp(0.0, maxY).toDouble(),
            (z ?? part.position.z).clamp(0.0, maxZ).toDouble(),
          ),
        ),
      );
    }

    void fitToContent() {
      controller.fitToContent();
      final updated = ref.read(customModelProvider);
      _snack(
        context,
        'Medidas ajustadas a ${formatMm(updated.overallSize.width)} × '
        '${formatMm(updated.overallSize.height)} × '
        '${formatMm(updated.overallSize.depth)} mm.',
      );
    }

    void scalePartsToOverall() {
      controller.scalePartsToOverall();
      _snack(
        context,
        'Piezas escaladas al volumen. Se conservaron los espesores de los paneles.',
      );
    }

    CutListItem? itemForPart(String partId) {
      for (final item in cutList.items) {
        if (item.partIds.contains(partId)) return item;
      }
      return null;
    }

    void openPartDetail(Part part) {
      final item = itemForPart(part.id);
      if (item == null) return;
      showPartDetailDialog(context, part: part, item: item, catalog: catalog);
    }

    Future<void> addPart({Part? initial}) async {
      final result = await showPartEditorDialog(
        context,
        catalog: catalog,
        overallSize: draft.overallSize,
        defaultThickness: draft.settings.panelThicknessMm,
        initialPart: initial,
        displayUnit: displayUnit,
        initialMaterialId: draft.defaultMaterialId,
      );
      if (result == null || !mounted) return;
      if (initial == null) {
        controller.addPart(result);
        final updated = ref.read(customModelProvider);
        if (updated.parts.isNotEmpty) {
          setState(() => _selectedPartId = updated.parts.last.id);
        }
      } else {
        controller.updatePart(result);
        setState(() => _selectedPartId = result.id);
      }
    }

    Future<void> saveModel() async {
      if (draft.parts.isEmpty) {
        _snack(context, 'Agrega al menos una pieza antes de guardar.');
        return;
      }
      if (hasBuildabilityErrors) {
        _snack(
          context,
          'Corrige los errores de fabricabilidad antes de guardar. Revisa el panel de validación.',
        );
        return;
      }
      try {
        final item = await ref
            .read(savedFurnitureProvider.notifier)
            .save(
              furniture,
              name: draft.name,
              description: 'Mueble creado desde el constructor.',
              tags: const ['personalizado'],
            );
        if (!context.mounted) return;
        _snack(context, '${item.name} guardado en tu biblioteca.');
      } catch (error) {
        if (!context.mounted) return;
        _snack(context, 'No se pudo guardar: $error');
      }
    }

    Future<void> confirmDelete(Part part) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar pieza'),
          content: Text('¿Eliminar "${part.name}" del mueble?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmed == true) controller.removePart(part.id);
    }

    Future<void> confirmNewModel() async {
      if (draft.parts.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nuevo mueble'),
            content: const Text(
              'Se quitarán todas las piezas actuales. ¿Continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Crear nuevo'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        if (!context.mounted) return;
      }
      controller.startBlank();
      setState(() => _selectedPartId = null);
      _snack(context, 'Mueble nuevo listo para empezar.');
    }

    Future<void> loadPreset(String name, Furniture furnitureModel) async {
      if (draft.parts.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cargar plantilla'),
            content: Text(
              'Se reemplazará el mueble actual por "$name". ¿Continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cargar'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        if (!context.mounted) return;
      }
      controller.loadFurniture(furnitureModel, name: name);
      setState(() => _selectedPartId = null);
      _snack(context, 'Plantilla "$name" cargada. Puedes editarla.');
    }

    Future<void> loadGeometricTemplate(GeometricTemplate template) async {
      if (draft.parts.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cargar forma geométrica'),
            content: Text(
              'Se reemplazará el mueble actual por "${template.name}". ¿Continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cargar'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        if (!context.mounted) return;
      }
      controller.loadFurniture(template.furniture, name: template.name);
      setState(() => _selectedPartId = null);
      _snack(context, '${template.name}: ${template.description}');
    }

    void addSketchParts(List<Part> parts) {
      controller.addParts(parts);
      final updated = ref.read(customModelProvider);
      if (updated.parts.isNotEmpty) {
        setState(() => _selectedPartId = updated.parts.last.id);
      }
      _snack(
        context,
        'Se agregaron ${parts.length} pieza(s) desde el dibujo de planta.',
      );
    }

    void stackSelected(Part part) {
      var targetY = 0.0;
      for (final other in draft.parts) {
        if (other.id == part.id) continue;
        final overlapX =
            math.min(
              part.position.x + part.size.width,
              other.position.x + other.size.width,
            ) -
            math.max(part.position.x, other.position.x);
        final overlapZ =
            math.min(
              part.position.z + part.size.depth,
              other.position.z + other.size.depth,
            ) -
            math.max(part.position.z, other.position.z);
        if (overlapX > 1 && overlapZ > 1) {
          targetY = math.max(targetY, other.position.y + other.size.height);
        }
      }
      updatePartPosition(part, y: targetY);
      _snack(context, 'Pieza apilada a ${formatMm(targetY)} mm de altura.');
    }

    final leftPanel = Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                key: const Key('create_name_field'),
                controller: _nameController,
                onChanged: controller.setName,
                decoration: const InputDecoration(
                  labelText: 'Nombre del mueble',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MmField(
                      fieldKey: const Key('create_width_field'),
                      label: 'Ancho',
                      value: draft.overallSize.width,
                      unit: displayUnit,
                      onChanged: (value) =>
                          controller.updateOverallSize(width: value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MmField(
                      fieldKey: const Key('create_height_field'),
                      label: 'Alto',
                      value: draft.overallSize.height,
                      unit: displayUnit,
                      onChanged: (value) =>
                          controller.updateOverallSize(height: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MmField(
                fieldKey: const Key('create_depth_field'),
                label: 'Fondo',
                value: draft.overallSize.depth,
                unit: displayUnit,
                onChanged: (value) =>
                    controller.updateOverallSize(depth: value),
              ),
              const SizedBox(height: 14),
              Text('Espesor por defecto', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 15, label: Text('15')),
                    ButtonSegment(value: 18, label: Text('18')),
                    ButtonSegment(value: 25, label: Text('25')),
                  ],
                  selected: {
                    if ({
                      15.0,
                      18.0,
                      25.0,
                    }.contains(draft.settings.panelThicknessMm))
                      draft.settings.panelThicknessMm
                    else
                      18.0,
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      controller.updatePanelThickness(selection.first),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Se usa como valor inicial al agregar piezas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Las medidas generales son la caja de referencia del 3D. '
                  'Al cambiar las cotas, pulsa "Escalar piezas al volumen" para adaptar '
                  'los paneles conservando su espesor. "Ajustar medidas al contenido" '
                  'hace lo contrario: encaja la caja a las piezas actuales.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MaterialSelectorPanel(selectedPartId: _selectedPartId),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Herramientas', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('add_part_button'),
                  onPressed: () => addPart(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar pieza'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: draft.parts.isEmpty ? null : fitToContent,
                  icon: const Icon(Icons.fit_screen_outlined, size: 18),
                  label: const Text('Ajustar medidas al contenido'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: draft.parts.isEmpty ? null : scalePartsToOverall,
                  icon: const Icon(Icons.open_in_full, size: 18),
                  label: const Text('Escalar piezas al volumen'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: confirmNewModel,
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: const Text('Nuevo mueble'),
                ),
              ),
              const Divider(height: 26),
              Text(
                'Partir de una plantilla',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final preset in presets)
                    ActionChip(
                      label: Text(preset.name),
                      onPressed: () =>
                          loadPreset(preset.name, preset.furniture),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GeometricTemplatePanel(onSelected: loadGeometricTemplate),
        const SizedBox(height: 14),
        PlanSketchPanel(
          overallSize: draft.overallSize,
          thickness: draft.settings.panelThicknessMm,
          materialId: draft.defaultMaterialId,
          catalog: catalog,
          onPartsCreated: addSketchParts,
          onDrawingChanged: (drawing) {
            if (_sketchDrawing != drawing) {
              setState(() => _sketchDrawing = drawing);
            }
          },
        ),
        const SizedBox(height: 14),
        const RegionalMaterialPanel(),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Piezas (${draft.parts.length})',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (draft.parts.isNotEmpty)
                    Text(
                      '${formatM2(cutList.totalAreaM2)} m²',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (draft.parts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Aún no hay piezas. Usa "Agregar pieza" o carga una plantilla.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: draft.parts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final part = draft.parts[index];
                      final material = catalog.byId(part.materialId);
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          selected: _selectedPartId == part.id,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.crop_square,
                              size: 17,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            part.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${formatMm(part.cutSize.length)} × ${formatMm(part.cutSize.width)} × ${formatMm(part.cutSize.thickness)} mm'
                            '${material == null ? '' : ' · ${material.name}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => selectPart(part.id),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Acciones de la pieza',
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  addPart(initial: part);
                                  break;
                                case 'duplicate':
                                  controller.duplicatePart(part.id);
                                  break;
                                case 'delete':
                                  confirmDelete(part);
                                  break;
                                case 'detail':
                                  openPartDetail(part);
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'detail',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Ver 3D y plantilla'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Duplicar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (draft.parts.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Toca una pieza de la lista para ver su 3D y su plantilla.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    Widget emptyViewer() => SurfaceCard(
      child: SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_box_outlined,
                size: 48,
                color: scheme.primary.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 12),
              Text('Tu mueble empieza aquí', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Agrega una pieza con medidas reales o carga una plantilla.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => addPart(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar primera pieza'),
              ),
            ],
          ),
        ),
      ),
    );

    Widget selectionToolbar() {
      if (selected == null) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _moveMode
                ? 'Arrastra una pieza para seleccionarla y moverla.'
                : 'Activa Mover para arrastrar piezas en X/Z.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
      }

      return _SelectedPartToolbar(
        part: selected,
        onEdit: () => addPart(initial: selected),
        onFloor: () => updatePartPosition(selected, y: 0),
        onStack: () => stackSelected(selected),
        onUp: () => updatePartPosition(selected, y: selected.position.y + 10),
        onDown: () => updatePartPosition(selected, y: selected.position.y - 10),
        onCenterX: () => updatePartPosition(
          selected,
          x: (draft.overallSize.width - selected.size.width) / 2,
        ),
        onCenterZ: () => updatePartPosition(
          selected,
          z: (draft.overallSize.depth - selected.size.depth) / 2,
        ),
        onDelete: () => confirmDelete(selected),
        onClose: () => setState(() => _selectedPartId = null),
      );
    }

    Widget buildViewer(double height) => ViewerCard(
      furniture: furniture,
      viewerHeight: height,
      toolbar: selectionToolbar(),
      headerAction: FilterChip(
        label: const Text('Mover'),
        selected: _moveMode,
        visualDensity: VisualDensity.compact,
        onSelected: (value) => setState(() => _moveMode = value),
      ),
      moveMode: _moveMode,
      selectedPartId: _selectedPartId,
      onPartSelected: selectPart,
      onPartMoved: controller.updatePart,
    );

    final templates = FlatPatternsPanel(
      cutList: cutList,
      catalog: catalog,
      height: 480,
      onOpen: (item) {
        final part = furniture.partById(item.partIds.first);
        if (part != null) {
          showPartDetailDialog(
            context,
            part: part,
            item: item,
            catalog: catalog,
          );
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        final templatesBeside = constraints.maxWidth >= 1280;

        final main = draft.parts.isEmpty
            ? Column(
                children: [
                  emptyViewer(),
                  const SizedBox(height: 20),
                  templates,
                ],
              )
            : Column(
                children: [
                  if (templatesBeside)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildViewer(480)),
                        const SizedBox(width: 20),
                        SizedBox(width: 400, child: templates),
                      ],
                    )
                  else ...[
                    buildViewer(420),
                    const SizedBox(height: 20),
                    templates,
                  ],
                  const SizedBox(height: 20),
                  CutListTable(
                    cutList: cutList,
                    catalog: catalog,
                    onItemTap: (item) {
                      final part = furniture.partById(item.partIds.first);
                      if (part != null) {
                        showPartDetailDialog(
                          context,
                          part: part,
                          item: item,
                          catalog: catalog,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  FurnitureEstimatePanel(furniture: furniture),
                ],
              );

        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 370, child: leftPanel),
                  const SizedBox(width: 20),
                  Expanded(child: main),
                ],
              )
            : Column(children: [leftPanel, const SizedBox(height: 20), main]);

        return SingleChildScrollView(
          controller: _scrollController,
          physics: _sketchDrawing ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreateHeader(
                    theme: theme,
                    canSave: draft.parts.isNotEmpty && !hasBuildabilityErrors,
                    onSave: saveModel,
                    onNew: confirmNewModel,
                  ),
                  const SizedBox(height: 18),
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedPartToolbar extends StatelessWidget {
  final Part part;
  final VoidCallback onEdit;
  final VoidCallback onFloor;
  final VoidCallback onStack;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onCenterX;
  final VoidCallback onCenterZ;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const _SelectedPartToolbar({
    required this.part,
    required this.onEdit,
    required this.onFloor,
    required this.onStack,
    required this.onUp,
    required this.onDown,
    required this.onCenterX,
    required this.onCenterZ,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        '${part.name} · ${formatMm(part.cutSize.length)} × ${formatMm(part.cutSize.width)} × ${formatMm(part.cutSize.thickness)} mm';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(partIcon(part.kind), size: 17),
          const SizedBox(width: 6),
          SizedBox(
            width: 180,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ToolIconButton(
            tooltip: 'Editar medidas',
            icon: Icons.straighten,
            onPressed: onEdit,
          ),
          _ToolIconButton(
            tooltip: 'Apilar sobre la pieza de abajo',
            icon: Icons.vertical_align_center,
            onPressed: onStack,
          ),
          _ToolIconButton(
            tooltip: 'Poner en el piso',
            icon: Icons.vertical_align_bottom,
            onPressed: onFloor,
          ),
          _ToolIconButton(
            tooltip: 'Subir 10 mm',
            icon: Icons.arrow_upward,
            onPressed: onUp,
          ),
          _ToolIconButton(
            tooltip: 'Bajar 10 mm',
            icon: Icons.arrow_downward,
            onPressed: onDown,
          ),
          _ToolIconButton(
            tooltip: 'Centrar en X',
            icon: Icons.align_horizontal_center,
            onPressed: onCenterX,
          ),
          _ToolIconButton(
            tooltip: 'Centrar en Z',
            icon: Icons.align_vertical_center,
            onPressed: onCenterZ,
          ),
          _ToolIconButton(
            tooltip: 'Eliminar pieza',
            icon: Icons.delete_outline,
            onPressed: onDelete,
          ),
          _ToolIconButton(
            tooltip: 'Quitar selección',
            icon: Icons.close,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    iconSize: 17,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon),
  );
}

class _CreateHeader extends StatelessWidget {
  final ThemeData theme;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onNew;

  const _CreateHeader({
    required this.theme,
    required this.canSave,
    required this.onSave,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crear mueble', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Agrega piezas con medidas reales. Todo se puede manejar con el mouse.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: const Text('Nuevo'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('save_model_button'),
              onPressed: canSave ? onSave : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar'),
            ),
          ],
        );
        if (constraints.maxWidth >= 620) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 12), actions],
        );
      },
    );
  }
}
