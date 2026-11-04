import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seeds/material_seed.dart';
import '../../data/seeds/sample_furniture.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/material.dart';
import '../../domain/generators/cabinet_doors_drawer_generator.dart';
import '../../domain/generators/furniture_generator.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../../domain/services/furniture_validator.dart';

/// Catálogo de materiales de la Fase 1 (en memoria).
final materialCatalogProvider = Provider<MaterialCatalog>(
  (ref) => sampleMaterialCatalog,
);

/// Estado editable del mueble de ejemplo.
class DesignerController extends Notifier<CabinetSpec> {
  @override
  CabinetSpec build() => sampleCabinetSpec;

  void updateOverallSize({double? width, double? height, double? depth}) {
    final current = state.overallSize;
    state = state.copyWith(
      overallSize: current.copyWith(width: width, height: height, depth: depth),
    );
  }

  void updatePanelThickness(double thicknessMm) {
    final material = ref
        .read(materialCatalogProvider)
        .findByThickness(thicknessMm, category: MaterialCategory.mdf);
    state = state.copyWith(
      defaultMaterialId: material?.id ?? state.defaultMaterialId,
      settings: state.settings.copyWith(panelThicknessMm: thicknessMm),
    );
  }

  void updateShelfCount(int count) {
    final clamped = count < 0 ? 0 : (count > 8 ? 8 : count);
    state = state.copyWith(shelfCount: clamped);
  }

  void updateDrawerHeight(double heightMm) {
    state = state.copyWith(drawerHeightMm: heightMm);
  }

  void updatePlinthHeight(double heightMm) {
    state = state.copyWith(
      settings: state.settings.copyWith(plinthHeightMm: heightMm),
    );
  }

  void reset() => state = sampleCabinetSpec;
}

final designerProvider = NotifierProvider<DesignerController, CabinetSpec>(
  DesignerController.new,
);

final furnitureGeneratorProvider = Provider<FurnitureGenerator>(
  (ref) => const CabinetDoorsDrawerGenerator(),
);

/// Modelo derivado de la especificación. Cambia una medida y se regenera.
final furnitureProvider = Provider<Furniture>((ref) {
  final spec = ref.watch(designerProvider);
  final catalog = ref.watch(materialCatalogProvider);
  return ref
      .watch(furnitureGeneratorProvider)
      .generate(spec: spec, catalog: catalog);
});

/// Despiece derivado del modelo.
final cutListProvider = Provider<CutList>((ref) {
  final furniture = ref.watch(furnitureProvider);
  final catalog = ref.watch(materialCatalogProvider);
  return const CutListCalculator().build(furniture, catalog);
});

final validationProvider = Provider<List<ValidationIssue>>((ref) {
  final spec = ref.watch(designerProvider);
  return const FurnitureValidator().validate(spec);
});
