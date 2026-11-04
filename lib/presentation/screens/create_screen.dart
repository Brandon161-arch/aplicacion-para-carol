import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/part_palette.dart';
import '../providers/custom_model_providers.dart';
import '../providers/designer_providers.dart';
import '../providers/library_providers.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/flat_patterns_panel.dart';
import '../widgets/mm_field.dart';
import '../widgets/part_detail_dialog.dart';
import '../widgets/part_editor_dialog.dart';
import '../widgets/surface_card.dart';
import '../widgets/viewer_card.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late final TextEditingController _nameController;
  String? _selectedPartId;
  bool _moveMode = true;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(customModelProvider);
    final furniture = ref.watch(customFurnitureProvider);
    final cutList = ref.watch(customCutListProvider);
    final catalog = ref.watch(materialCatalogProvider);
    final presets = ref.watch(presetFurnitureProvider);
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
                  'Las medidas generales son la caja de referencia que ves en el 3D. '
                  'Las piezas conservan su tamaño; usa "Ajustar medidas al contenido" '
                  'para encajar la caja al volumen real.',
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

    Widget buildViewer(double height) => ViewerCard(
      furniture: furniture,
      viewerHeight: height,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreateHeader(
                    theme: theme,
                    canSave: draft.parts.isNotEmpty,
                    onSave: saveModel,
                    onNew: confirmNewModel,
                  ),
                  const SizedBox(height: 18),
                  if (selectedPart != null) ...[
                    _SelectedPartBar(
                      part: selectedPart,
                      onEdit: () => addPart(initial: selectedPart),
                      onFloor: () => updatePartPosition(selectedPart!, y: 0),
                      onUp: () => updatePartPosition(
                        selectedPart!,
                        y: selectedPart!.position.y + 10,
                      ),
                      onDown: () => updatePartPosition(
                        selectedPart!,
                        y: selectedPart!.position.y - 10,
                      ),
                      onCenterX: () => updatePartPosition(
                        selectedPart!,
                        x:
                            (draft.overallSize.width -
                                selectedPart!.size.width) /
                            2,
                      ),
                      onCenterZ: () => updatePartPosition(
                        selectedPart!,
                        z:
                            (draft.overallSize.depth -
                                selectedPart!.size.depth) /
                            2,
                      ),
                      onDelete: () => confirmDelete(selectedPart!),
                      onClose: () => setState(() => _selectedPartId = null),
                    ),
                    const SizedBox(height: 14),
                  ],
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

class _SelectedPartBar extends StatelessWidget {
  final Part part;
  final VoidCallback onEdit;
  final VoidCallback onFloor;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onCenterX;
  final VoidCallback onCenterZ;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const _SelectedPartBar({
    required this.part,
    required this.onEdit,
    required this.onFloor,
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
    final scheme = theme.colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(partIcon(part.kind), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pieza seleccionada: ${part.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${formatMm(part.cutSize.length)} × ${formatMm(part.cutSize.width)} × ${formatMm(part.cutSize.thickness)} mm · '
                      'X ${formatMm(part.position.x)} · Y ${formatMm(part.position.y)} · Z ${formatMm(part.position.z)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar selección',
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.straighten, size: 16),
                label: const Text('Medidas'),
              ),
              ActionChip(
                avatar: const Icon(Icons.vertical_align_bottom, size: 16),
                label: const Text('Piso'),
                onPressed: onFloor,
              ),
              ActionChip(
                avatar: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Subir 10'),
                onPressed: onUp,
              ),
              ActionChip(
                avatar: const Icon(Icons.arrow_downward, size: 16),
                label: const Text('Bajar 10'),
                onPressed: onDown,
              ),
              ActionChip(
                avatar: const Icon(Icons.align_horizontal_center, size: 16),
                label: const Text('Centrar X'),
                onPressed: onCenterX,
              ),
              ActionChip(
                avatar: const Icon(Icons.align_vertical_center, size: 16),
                label: const Text('Centrar Z'),
                onPressed: onCenterZ,
              ),
              ActionChip(
                avatar: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Eliminar'),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
