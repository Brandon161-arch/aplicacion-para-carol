import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import 'designer_providers.dart';
import 'project_context_provider.dart';

/// Borrador editable de un mueble creado desde cero.
class CustomModelDraft {
  final String name;
  final Size3 overallSize;
  final ConstructionSettings settings;
  final List<Part> parts;
  final String defaultMaterialId;
  final Set<String> hiddenPartIds;

  const CustomModelDraft({
    required this.name,
    required this.overallSize,
    required this.settings,
    required this.parts,
    this.defaultMaterialId = 'mdf_18',
    this.hiddenPartIds = const {},
  });

  CustomModelDraft copyWith({
    String? name,
    Size3? overallSize,
    ConstructionSettings? settings,
    List<Part>? parts,
    String? defaultMaterialId,
    Set<String>? hiddenPartIds,
  }) => CustomModelDraft(
    name: name ?? this.name,
    overallSize: overallSize ?? this.overallSize,
    settings: settings ?? this.settings,
    parts: parts ?? this.parts,
    defaultMaterialId: defaultMaterialId ?? this.defaultMaterialId,
    hiddenPartIds: hiddenPartIds ?? this.hiddenPartIds,
  );
}

const CustomModelDraft emptyCustomModelDraft = CustomModelDraft(
  name: 'Mueble sin título',
  overallSize: Size3(width: 800, height: 800, depth: 400),
  settings: ConstructionSettings(),
  parts: [],
);

Furniture customFurnitureFromDraft(CustomModelDraft draft) => Furniture(
  id: 'custom_model',
  name: draft.name.trim().isEmpty ? 'Mueble sin título' : draft.name.trim(),
  type: FurnitureType.custom,
  overallSize: draft.overallSize,
  settings: draft.settings,
  parts: draft.parts,
);

class CustomModelController extends Notifier<CustomModelDraft> {
  int _counter = 0;

  @override
  CustomModelDraft build() => emptyCustomModelDraft;

  String _newPartId() =>
      'part_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  void startBlank() => state = emptyCustomModelDraft;

  void setName(String name) => state = state.copyWith(name: name);

  void updateOverallSize({double? width, double? height, double? depth}) {
    final current = state.overallSize;
    state = state.copyWith(
      overallSize: current.copyWith(width: width, height: height, depth: depth),
    );
  }

  void updatePanelThickness(double thicknessMm) {
    state = state.copyWith(
      settings: state.settings.copyWith(panelThicknessMm: thicknessMm),
    );
  }

  void updateDefaultMaterial(String materialId) {
    state = state.copyWith(defaultMaterialId: materialId);
  }

  void applyMaterialToPart(
    String partId,
    String materialId,
    double thicknessMm,
  ) {
    state = state.copyWith(
      parts: [
        for (final part in state.parts)
          if (part.id == partId)
            part.copyWith(
              materialId: materialId,
              cutSize: part.cutSize.copyWith(thickness: thicknessMm),
            )
          else
            part,
      ],
    );
  }

  void applyMaterialToAll(String materialId, double thicknessMm) {
    state = state.copyWith(
      defaultMaterialId: materialId,
      parts: [
        for (final part in state.parts)
          part.copyWith(
            materialId: materialId,
            cutSize: part.cutSize.copyWith(thickness: thicknessMm),
          ),
      ],
    );
  }

  void loadFurniture(Furniture furniture, {String? name}) {
    state = CustomModelDraft(
      name: name ?? furniture.name,
      overallSize: furniture.overallSize,
      settings: furniture.settings,
      parts: List<Part>.unmodifiable(furniture.parts),
      defaultMaterialId: furniture.parts.isNotEmpty
          ? furniture.parts.first.materialId
          : state.defaultMaterialId,
      hiddenPartIds: const {},
    );
  }

  void addPart(Part part) {
    final id = part.id.isEmpty ? _newPartId() : part.id;
    state = state.copyWith(
      parts: [
        ...state.parts,
        part.copyWith(id: id),
      ],
    );
  }

  void addParts(List<Part> parts) {
    if (parts.isEmpty) return;
    state = state.copyWith(
      parts: [
        ...state.parts,
        for (final part in parts) part.copyWith(id: _newPartId()),
      ],
      defaultMaterialId: parts.first.materialId,
    );
  }

  void updatePart(Part part) {
    state = state.copyWith(
      parts: [
        for (final existing in state.parts)
          if (existing.id == part.id) part else existing,
      ],
    );
  }

  void removePart(String id) {
    final hidden = {...state.hiddenPartIds}..remove(id);
    state = state.copyWith(
      parts: state.parts.where((part) => part.id != id).toList(growable: false),
      hiddenPartIds: hidden,
    );
  }

  void togglePartVisibility(String id) {
    final hidden = {...state.hiddenPartIds};
    if (!hidden.remove(id)) hidden.add(id);
    state = state.copyWith(hiddenPartIds: hidden);
  }

  void showAllParts() {
    state = state.copyWith(hiddenPartIds: const {});
  }

  void duplicatePart(String id) {
    Part? original;
    for (final part in state.parts) {
      if (part.id == id) {
        original = part;
        break;
      }
    }
    if (original == null) return;
    final copy = original.copyWith(
      id: _newPartId(),
      position: original.position + const Vector3(20, 0, 0),
    );
    state = state.copyWith(parts: [...state.parts, copy]);
  }

  /// Ajusta las medidas generales al volumen real ocupado por las piezas.
  void fitToContent() {
    if (state.parts.isEmpty) return;

    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    var maxZ = -double.infinity;

    for (final part in state.parts) {
      minX = math.min(minX, part.position.x);
      minY = math.min(minY, part.position.y);
      minZ = math.min(minZ, part.position.z);
      maxX = math.max(maxX, part.position.x + part.size.width);
      maxY = math.max(maxY, part.position.y + part.size.height);
      maxZ = math.max(maxZ, part.position.z + part.size.depth);
    }

    final shift = Vector3(-minX, -minY, -minZ);
    state = state.copyWith(
      overallSize: Size3(
        width: math.max(1.0, maxX - minX),
        height: math.max(1.0, maxY - minY),
        depth: math.max(1.0, maxZ - minZ),
      ),
      parts: [
        for (final part in state.parts)
          part.copyWith(position: part.position + shift),
      ],
    );
  }

  /// Escala las caras de las piezas para llenar las medidas generales actuales.
  ///
  /// Conserva el espesor de cada panel y escala sus dos dimensiones de corte.
  /// La posición también se escala para mantener las piezas dentro del volumen.
  void scalePartsToOverall() {
    if (state.parts.isEmpty) return;

    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    var maxZ = -double.infinity;
    for (final part in state.parts) {
      minX = math.min(minX, part.position.x);
      minY = math.min(minY, part.position.y);
      minZ = math.min(minZ, part.position.z);
      maxX = math.max(maxX, part.position.x + part.size.width);
      maxY = math.max(maxY, part.position.y + part.size.height);
      maxZ = math.max(maxZ, part.position.z + part.size.depth);
    }

    final currentWidth = math.max(1.0, maxX - minX);
    final currentHeight = math.max(1.0, maxY - minY);
    final currentDepth = math.max(1.0, maxZ - minZ);
    final scaleX = state.overallSize.width / currentWidth;
    final scaleY = state.overallSize.height / currentHeight;
    final scaleZ = state.overallSize.depth / currentDepth;

    state = state.copyWith(
      parts: [
        for (final part in state.parts)
          _scalePart(
            part,
            mapping: _mappingFor(part),
            scaleX: scaleX,
            scaleY: scaleY,
            scaleZ: scaleZ,
            offset: Vector3(-minX, -minY, -minZ),
          ),
      ],
    );
  }
}

enum _PanelMapping {
  horizontal,
  frontVertical,
  sideVertical,
  frontHorizontal,
  drawerSide,
}

_PanelMapping _mappingFor(Part part) {
  final preferred = switch (part.kind) {
    PartKind.sidePanel || PartKind.leg => _PanelMapping.sideVertical,
    PartKind.door => _PanelMapping.frontVertical,
    PartKind.drawerSide => _PanelMapping.drawerSide,
    PartKind.drawerFront ||
    PartKind.drawerBack ||
    PartKind.backPanel ||
    PartKind.plinth ||
    PartKind.rail ||
    PartKind.apron => _PanelMapping.frontHorizontal,
    _ => _PanelMapping.horizontal,
  };
  if (_sameSize(_worldSizeForCut(part.cutSize, preferred), part.size)) {
    return preferred;
  }
  for (final candidate in _PanelMapping.values) {
    if (_sameSize(_worldSizeForCut(part.cutSize, candidate), part.size)) {
      return candidate;
    }
  }
  return preferred;
}

bool _sameSize(Size3 first, Size3 second) =>
    (first.width - second.width).abs() < 0.01 &&
    (first.height - second.height).abs() < 0.01 &&
    (first.depth - second.depth).abs() < 0.01;

Size3 _worldSizeForCut(CutSize cut, _PanelMapping mapping) => switch (mapping) {
  _PanelMapping.horizontal => Size3(
    width: cut.length,
    height: cut.thickness,
    depth: cut.width,
  ),
  _PanelMapping.frontVertical => Size3(
    width: cut.width,
    height: cut.length,
    depth: cut.thickness,
  ),
  _PanelMapping.sideVertical => Size3(
    width: cut.thickness,
    height: cut.length,
    depth: cut.width,
  ),
  _PanelMapping.frontHorizontal => Size3(
    width: cut.length,
    height: cut.width,
    depth: cut.thickness,
  ),
  _PanelMapping.drawerSide => Size3(
    width: cut.thickness,
    height: cut.width,
    depth: cut.length,
  ),
};

Part _scalePart(
  Part part, {
  required _PanelMapping mapping,
  required double scaleX,
  required double scaleY,
  required double scaleZ,
  required Vector3 offset,
}) {
  final old = part.cutSize;
  final cut = switch (mapping) {
    _PanelMapping.horizontal => CutSize(
      length: old.length * scaleX,
      width: old.width * scaleZ,
      thickness: old.thickness,
    ),
    _PanelMapping.frontVertical => CutSize(
      length: old.length * scaleY,
      width: old.width * scaleX,
      thickness: old.thickness,
    ),
    _PanelMapping.sideVertical => CutSize(
      length: old.length * scaleY,
      width: old.width * scaleZ,
      thickness: old.thickness,
    ),
    _PanelMapping.frontHorizontal => CutSize(
      length: old.length * scaleX,
      width: old.width * scaleY,
      thickness: old.thickness,
    ),
    _PanelMapping.drawerSide => CutSize(
      length: old.length * scaleZ,
      width: old.width * scaleY,
      thickness: old.thickness,
    ),
  };
  final newPosition = Vector3(
    (part.position.x + offset.x) * scaleX,
    (part.position.y + offset.y) * scaleY,
    (part.position.z + offset.z) * scaleZ,
  );
  return part.copyWith(
    cutSize: cut,
    size: _worldSizeForCut(cut, mapping),
    position: newPosition,
  );
}

final customModelProvider =
    NotifierProvider<CustomModelController, CustomModelDraft>(
      CustomModelController.new,
    );

final customFurnitureProvider = Provider<Furniture>(
  (ref) => customFurnitureFromDraft(ref.watch(customModelProvider)),
);

final customCutListProvider = Provider<CutList>((ref) {
  final furniture = ref.watch(customFurnitureProvider);
  final catalog = ref.watch(materialCatalogProvider);
  final kerfMm = ref.watch(projectContextValueProvider)?.kerfMm ?? 3.2;
  return const CutListCalculator().build(furniture, catalog, kerfMm: kerfMm);
});
