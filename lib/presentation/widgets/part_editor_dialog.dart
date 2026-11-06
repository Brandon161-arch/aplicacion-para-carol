import 'package:flutter/material.dart' hide Material;

import '../../core/constants/units.dart';
import '../../domain/entities/material.dart';
import '../../domain/entities/part.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/measurement_unit.dart';
import '../../domain/value_objects/part_shape.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/part_palette.dart';
import '../painters/wood_swatch_painter.dart';
import 'interactive_flat_pattern.dart';
import 'surface_card.dart';

enum PanelOrientation {
  horizontal('Horizontal', 'Estante, tapa o base'),
  frontVertical('Vertical frontal', 'Puerta, fondo o frente'),
  sideVertical('Vertical lateral', 'Lateral o división');

  final String label;
  final String hint;

  const PanelOrientation(this.label, this.hint);
}

Future<Part?> showPartEditorDialog(
  BuildContext context, {
  required MaterialCatalog catalog,
  required Size3 overallSize,
  required double defaultThickness,
  Part? initialPart,
  MeasurementUnit displayUnit = MeasurementUnit.millimeter,
  String? initialMaterialId,
}) {
  return showDialog<Part>(
    context: context,
    builder: (context) => PartEditorDialog(
      catalog: catalog,
      overallSize: overallSize,
      defaultThickness: defaultThickness,
      initialPart: initialPart,
      displayUnit: displayUnit,
      initialMaterialId: initialMaterialId,
    ),
  );
}

class PartEditorDialog extends StatefulWidget {
  final MaterialCatalog catalog;
  final Size3 overallSize;
  final double defaultThickness;
  final Part? initialPart;
  final MeasurementUnit displayUnit;
  final String? initialMaterialId;

  const PartEditorDialog({
    super.key,
    required this.catalog,
    required this.overallSize,
    required this.defaultThickness,
    this.displayUnit = MeasurementUnit.millimeter,
    this.initialPart,
    this.initialMaterialId,
  });

  @override
  State<PartEditorDialog> createState() => _PartEditorDialogState();
}

class _PartEditorDialogState extends State<PartEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _thicknessController;
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _zController;

  late PartKind _kind;
  late String _materialId;
  late GrainDirection _grain;
  late PanelOrientation _orientation;
  late Set<PanelEdge> _bandedEdges;
  late PartShape _shape;
  String? _error;

  MaterialCatalog get _catalog => widget.catalog;

  List<Material> get _panelMaterials => _catalog.materials
      .where((material) => material.category != MaterialCategory.other)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPart;
    final preferredId =
        initial?.materialId ?? widget.initialMaterialId ?? 'mdf_18';
    final material = _catalog.byId(preferredId) ?? _panelMaterials.first;

    _kind = initial?.kind ?? PartKind.shelf;
    _materialId = material.id;
    _grain = initial?.grain ?? GrainDirection.none;
    _orientation = initial == null
        ? _orientationForKind(_kind)
        : _inferOrientation(initial);
    _bandedEdges = {...?initial?.edgeBanding.keys};
    _shape = initial?.shape ?? PartShape.rectangle;

    final cut =
        initial?.cutSize ??
        CutSize(length: 600, width: 300, thickness: widget.defaultThickness);
    _nameController = TextEditingController(text: initial?.name ?? _kind.label);
    _lengthController = TextEditingController(
      text: widget.displayUnit.formatValue(cut.length),
    );
    _widthController = TextEditingController(
      text: widget.displayUnit.formatValue(cut.width),
    );
    _thicknessController = TextEditingController(
      text: widget.displayUnit.formatValue(cut.thickness),
    );
    _xController = TextEditingController(
      text: widget.displayUnit.formatValue(initial?.position.x ?? 0),
    );
    _yController = TextEditingController(
      text: widget.displayUnit.formatValue(initial?.position.y ?? 0),
    );
    _zController = TextEditingController(
      text: widget.displayUnit.formatValue(initial?.position.z ?? 0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    super.dispose();
  }

  PanelOrientation _orientationForKind(PartKind kind) => switch (kind) {
    PartKind.shelf ||
    PartKind.topPanel ||
    PartKind.bottomPanel ||
    PartKind.plinth ||
    PartKind.desktop ||
    PartKind.drawerBottom ||
    PartKind.rail ||
    PartKind.apron => PanelOrientation.horizontal,
    PartKind.door ||
    PartKind.drawerFront ||
    PartKind.backPanel => PanelOrientation.frontVertical,
    PartKind.sidePanel ||
    PartKind.divider ||
    PartKind.drawerSide ||
    PartKind.drawerBack ||
    PartKind.leg => PanelOrientation.sideVertical,
    PartKind.other => PanelOrientation.horizontal,
  };

  PanelOrientation _inferOrientation(Part part) {
    for (final orientation in PanelOrientation.values) {
      final candidate = _worldSize(part.cutSize, orientation);
      if (_sameSize(candidate, part.size)) return orientation;
    }
    return _orientationForKind(part.kind);
  }

  bool _sameSize(Size3 a, Size3 b) =>
      (a.width - b.width).abs() < 0.01 &&
      (a.height - b.height).abs() < 0.01 &&
      (a.depth - b.depth).abs() < 0.01;

  Size3 _worldSize(CutSize cut, PanelOrientation orientation) =>
      switch (orientation) {
        PanelOrientation.horizontal => Size3(
          width: cut.length,
          height: cut.thickness,
          depth: cut.width,
        ),
        PanelOrientation.frontVertical => Size3(
          width: cut.width,
          height: cut.length,
          depth: cut.thickness,
        ),
        PanelOrientation.sideVertical => Size3(
          width: cut.thickness,
          height: cut.length,
          depth: cut.width,
        ),
      };

  double? _parse(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    return value == null ? null : widget.displayUnit.toMillimeters(value);
  }

  CutSize? get _cutSize {
    final length = _parse(_lengthController);
    final width = _parse(_widthController);
    final thickness = _parse(_thicknessController);
    if (length == null ||
        width == null ||
        thickness == null ||
        length <= 0 ||
        width <= 0 ||
        thickness <= 0) {
      return null;
    }
    return CutSize(length: length, width: width, thickness: thickness);
  }

  Size3? get _world {
    final cut = _cutSize;
    return cut == null ? null : _worldSize(cut, _orientation);
  }

  void _onKindChanged(PartKind? kind) {
    if (kind == null) return;
    final previousLabel = _kind.label;
    setState(() {
      _kind = kind;
      _orientation = _orientationForKind(kind);
      if (_nameController.text.trim().isEmpty ||
          _nameController.text == previousLabel) {
        _nameController.text = kind.label;
      }
      if (kind == PartKind.leg) {
        final wood = _catalog.byId('solid_wood_60');
        if (wood != null) {
          _materialId = wood.id;
          _thicknessController.text = widget.displayUnit.formatValue(
            wood.thicknessesMm.first,
          );
        }
      }
    });
  }

  void _onMaterialChanged(String? id) {
    if (id == null) return;
    final material = _catalog.byId(id);
    setState(() {
      _materialId = id;
      if (material != null && material.thicknessesMm.isNotEmpty) {
        _thicknessController.text = widget.displayUnit.formatValue(
          material.thicknessesMm.first,
        );
      }
    });
  }

  void _setPosition({double? x, double? y, double? z}) {
    if (x != null) {
      _xController.text = widget.displayUnit.formatValue(x < 0 ? 0 : x);
    }
    if (y != null) {
      _yController.text = widget.displayUnit.formatValue(y < 0 ? 0 : y);
    }
    if (z != null) {
      _zController.text = widget.displayUnit.formatValue(z < 0 ? 0 : z);
    }
    setState(() {});
  }

  void _save() {
    final cut = _cutSize;
    final world = _world;
    final name = _nameController.text.trim();
    final x = _parse(_xController) ?? 0;
    final y = _parse(_yController) ?? 0;
    final z = _parse(_zController) ?? 0;

    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la pieza.');
      return;
    }
    if (cut == null || world == null) {
      setState(
        () => _error = 'Largo, ancho y espesor deben ser mayores que 0.',
      );
      return;
    }

    final edgeMaterialId = _catalog.byId('pvc_edge')?.id ?? 'pvc_edge';
    final part = Part(
      id: widget.initialPart?.id ?? '',
      name: name,
      kind: _kind,
      size: world,
      cutSize: cut,
      materialId: _materialId,
      position: Vector3(x, y, z),
      grain: _grain,
      edgeBanding: {
        for (final edge in _bandedEdges)
          edge: EdgeBanding(materialId: edgeMaterialId),
      },
      structural: _isStructural(_kind),
      shape: _shape,
    );
    Navigator.of(context).pop(part);
  }

  bool _isStructural(PartKind kind) => switch (kind) {
    PartKind.door ||
    PartKind.drawerFront ||
    PartKind.backPanel ||
    PartKind.shelf ||
    PartKind.drawerBottom => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cut = _cutSize;
    final world = _world;
    final material = _catalog.byId(_materialId);

    Widget patternPreview() => SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vista previa de la plantilla',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              if (material != null)
                Text(
                  material.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: cut == null
                ? Center(
                    child: Text(
                      'Completa las medidas para ver la plantilla.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : InteractiveFlatPattern(
                    cutSize: cut,
                    grain: _grain,
                    bandedEdges: _bandedEdges,
                    panelColor: partColor(_kind),
                    shape: _shape,
                    onChanged: (updated) {
                      _lengthController.text = widget.displayUnit.formatValue(
                        updated.length,
                      );
                      _widthController.text = widget.displayUnit.formatValue(
                        updated.width,
                      );
                      setState(() {});
                    },
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arrastra el punto naranja para ajustar largo y ancho con el mouse.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 880),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: partColor(_kind).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(partIcon(_kind), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.initialPart == null
                                    ? 'Agregar pieza'
                                    : 'Editar pieza',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                'Entrada en ${widget.displayUnit.label.toLowerCase()}; despiece técnico en mm. Ajusta la plantilla con el mouse.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 640;
                        return Column(
                          children: [
                            if (twoColumns)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _nameField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _kindField()),
                                ],
                              )
                            else ...[
                              _nameField(),
                              const SizedBox(height: 12),
                              _kindField(),
                            ],
                            const SizedBox(height: 12),
                            _materialField(),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('Medidas de corte', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final lengthField = _NumberField(
                          fieldKey: const Key('part_length_field'),
                          controller: _lengthController,
                          label: 'Largo',
                          unit: widget.displayUnit,
                          onChanged: () => setState(() {}),
                        );
                        final widthField = _NumberField(
                          fieldKey: const Key('part_width_field'),
                          controller: _widthController,
                          label: 'Ancho',
                          unit: widget.displayUnit,
                          onChanged: () => setState(() {}),
                        );
                        final thicknessField = _NumberField(
                          fieldKey: const Key('part_thickness_field'),
                          controller: _thicknessController,
                          label: 'Espesor',
                          unit: widget.displayUnit,
                          onChanged: () => setState(() {}),
                        );
                        if (constraints.maxWidth >= 560) {
                          return Row(
                            children: [
                              Expanded(child: lengthField),
                              const SizedBox(width: 10),
                              Expanded(child: widthField),
                              const SizedBox(width: 10),
                              Expanded(child: thicknessField),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: lengthField),
                                const SizedBox(width: 10),
                                Expanded(child: widthField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            thicknessField,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    patternPreview(),
                    const SizedBox(height: 16),
                    Text(
                      'Orientación en el mueble',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 560) {
                          return SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<PanelOrientation>(
                              segments: [
                                for (final orientation
                                    in PanelOrientation.values)
                                  ButtonSegment<PanelOrientation>(
                                    value: orientation,
                                    label: Text(_orientationLabel(orientation)),
                                  ),
                              ],
                              selected: {_orientation},
                              showSelectedIcon: false,
                              onSelectionChanged: (selection) => setState(
                                () => _orientation = selection.first,
                              ),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final orientation in PanelOrientation.values)
                              ChoiceChip(
                                label: Text(_orientationLabel(orientation)),
                                selected: _orientation == orientation,
                                onSelected: (_) =>
                                    setState(() => _orientation = orientation),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      world == null
                          ? 'Completa las medidas para ver el tamaño real.'
                          : '${_orientation.hint}. Ocupa ${formatMm(world.width)} × ${formatMm(world.height)} × ${formatMm(world.depth)} mm (ancho × alto × fondo).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _shapeField(),
                    const SizedBox(height: 16),
                    Text('Posición', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Esquina inferior izquierda de la pieza dentro del mueble.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            controller: _xController,
                            label: 'X',
                            unit: widget.displayUnit,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberField(
                            controller: _yController,
                            label: 'Y',
                            unit: widget.displayUnit,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _NumberField(
                            controller: _zController,
                            label: 'Z',
                            unit: widget.displayUnit,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Piso'),
                          onPressed: () => _setPosition(y: 0),
                        ),
                        ActionChip(
                          label: const Text('Centrar X'),
                          onPressed: world == null
                              ? null
                              : () => _setPosition(
                                  x:
                                      (widget.overallSize.width - world.width) /
                                      2,
                                ),
                        ),
                        ActionChip(
                          label: const Text('Centrar Z'),
                          onPressed: world == null
                              ? null
                              : () => _setPosition(
                                  z:
                                      (widget.overallSize.depth - world.depth) /
                                      2,
                                ),
                        ),
                        ActionChip(
                          label: const Text('Frente'),
                          onPressed: () => _setPosition(z: 0),
                        ),
                        ActionChip(
                          label: const Text('Fondo'),
                          onPressed: world == null
                              ? null
                              : () => _setPosition(
                                  z: widget.overallSize.depth - world.depth,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Veta y cantos', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Veta',
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<GrainDirection>(
                                isExpanded: true,
                                value: _grain,
                                items: [
                                  for (final grain in GrainDirection.values)
                                    DropdownMenuItem(
                                      value: grain,
                                      child: Text(grain.label),
                                    ),
                                ],
                                onChanged: (grain) {
                                  if (grain != null) {
                                    setState(() => _grain = grain);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final edge in PanelEdge.values)
                                FilterChip(
                                  label: Text(_edgeLabel(edge)),
                                  selected: _bandedEdges.contains(edge),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _bandedEdges.add(edge);
                                      } else {
                                        _bandedEdges.remove(edge);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        widget.initialPart == null
                            ? 'Agregar pieza'
                            : 'Guardar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _orientationLabel(PanelOrientation orientation) =>
      switch (orientation) {
        PanelOrientation.horizontal => 'Horizontal',
        PanelOrientation.frontVertical => 'Frontal',
        PanelOrientation.sideVertical => 'Lateral',
      };

  String _edgeLabel(PanelEdge edge) => switch (edge) {
    PanelEdge.longEdge1 => 'Largo sup.',
    PanelEdge.longEdge2 => 'Largo inf.',
    PanelEdge.shortEdge1 => 'Corto izq.',
    PanelEdge.shortEdge2 => 'Corto der.',
  };

  Widget _nameField() => TextField(
    controller: _nameController,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(labelText: 'Nombre de la pieza'),
  );

  Widget _kindField() => InputDecorator(
    decoration: const InputDecoration(labelText: 'Tipo de pieza'),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<PartKind>(
        isExpanded: true,
        value: _kind,
        items: [
          for (final kind in PartKind.values)
            DropdownMenuItem(value: kind, child: Text(kind.label)),
        ],
        onChanged: _onKindChanged,
      ),
    ),
  );

  Widget _shapeField() => LayoutBuilder(
    builder: (context, constraints) {
      final shapeSelector = DropdownButtonFormField<PartShapeKind>(
        isExpanded: true,
        initialValue: _shape.kind,
        decoration: const InputDecoration(labelText: 'Forma de la pieza'),
        items: [
          for (final kind in PartShapeKind.values)
            DropdownMenuItem(value: kind, child: Text(kind.label)),
        ],
        onChanged: (kind) {
          if (kind == null) return;
          setState(() => _shape = _shape.copyWith(kind: kind));
        },
      );
      final extra = switch (_shape.kind) {
        PartShapeKind.roundedRectangle => DropdownButtonFormField<double>(
          isExpanded: true,
          initialValue:
              [20.0, 40.0, 60.0, 80.0, 120.0].contains(_shape.cornerRadiusMm)
              ? _shape.cornerRadiusMm
              : 40.0,
          decoration: const InputDecoration(labelText: 'Radio de esquina'),
          items: [
            for (final radius in const [20.0, 40.0, 60.0, 80.0, 120.0])
              DropdownMenuItem(value: radius, child: Text(' mm')),
          ],
          onChanged: (radius) {
            if (radius == null) return;
            setState(() => _shape = _shape.copyWith(cornerRadiusMm: radius));
          },
        ),
        PartShapeKind.polygon => DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: _shape.sides,
          decoration: const InputDecoration(labelText: 'Número de lados'),
          items: [
            for (final sides in const [3, 4, 5, 6, 8, 10, 12])
              DropdownMenuItem(value: sides, child: Text(' lados')),
          ],
          onChanged: (sides) {
            if (sides == null) return;
            setState(() => _shape = _shape.copyWith(sides: sides));
          },
        ),
        _ => null,
      };
      if (extra == null) return shapeSelector;
      if (constraints.maxWidth >= 520) {
        return Row(
          children: [
            Expanded(child: shapeSelector),
            const SizedBox(width: 10),
            Expanded(child: extra),
          ],
        );
      }
      return Column(
        children: [shapeSelector, const SizedBox(height: 10), extra],
      );
    },
  );

  Widget _materialField() => InputDecorator(
    decoration: const InputDecoration(labelText: 'Material'),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: _panelMaterials.any((material) => material.id == _materialId)
            ? _materialId
            : _panelMaterials.first.id,
        items: [
          for (final material in _panelMaterials)
            DropdownMenuItem(
              value: material.id,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(
                        painter: WoodSwatchPainter(material: material),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: _onMaterialChanged,
      ),
    ),
  );
}

class _NumberField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final MeasurementUnit unit;

  const _NumberField({
    this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label, suffixText: unit.code),
    );
  }
}
