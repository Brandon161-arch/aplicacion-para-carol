import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import 'designer_providers.dart';

/// Borrador editable de un mueble creado desde cero.
class CustomModelDraft {
  final String name;
  final Size3 overallSize;
  final ConstructionSettings settings;
  final List<Part> parts;

  const CustomModelDraft({
    required this.name,
    required this.overallSize,
    required this.settings,
    required this.parts,
  });

  CustomModelDraft copyWith({
    String? name,
    Size3? overallSize,
    ConstructionSettings? settings,
    List<Part>? parts,
  }) => CustomModelDraft(
    name: name ?? this.name,
    overallSize: overallSize ?? this.overallSize,
    settings: settings ?? this.settings,
    parts: parts ?? this.parts,
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

  void loadFurniture(Furniture furniture, {String? name}) {
    state = CustomModelDraft(
      name: name ?? furniture.name,
      overallSize: furniture.overallSize,
      settings: furniture.settings,
      parts: List<Part>.unmodifiable(furniture.parts),
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

  void updatePart(Part part) {
    state = state.copyWith(
      parts: [
        for (final existing in state.parts)
          if (existing.id == part.id) part else existing,
      ],
    );
  }

  void removePart(String id) {
    state = state.copyWith(
      parts: state.parts.where((part) => part.id != id).toList(growable: false),
    );
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
  return const CutListCalculator().build(furniture, catalog);
});
