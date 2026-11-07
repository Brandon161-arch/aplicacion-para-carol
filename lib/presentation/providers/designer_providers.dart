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
import 'pricing_providers.dart';
import 'project_context_provider.dart';

/// Catálogo de materiales mezclado con los precios editables del usuario.
final materialCatalogProvider = Provider<MaterialCatalog>((ref) {
  final context = ref.watch(projectContextValueProvider);
  final country = context?.country;
  final localPricing = ref.watch(localPricingProvider).asData?.value;
  final overrides = country == null
      ? localPricing?.materialPriceOverrides ?? const <String, int>{}
      : localPricing?.materialPricesFor(country.code) ?? const <String, int>{};
  if (overrides.isEmpty && country == null) return sampleMaterialCatalog;
  return MaterialCatalog([
    for (final material in sampleMaterialCatalog.materials)
      () {
        final regionalPrice = country?.materialPrices[material.id];
        final localPrice = country == null || country.code == 'CO'
            ? overrides[material.id]
            : null;
        return material.copyWith(
          priceCents:
              localPrice ??
              regionalPrice?.priceCents ??
              (country != null && !country.priceDataAvailable
                  ? 0
                  : material.priceCents),
          sheetSize: regionalPrice?.sheetSize != null
              ? SheetSize(
                  widthMm: regionalPrice!.sheetSize!.widthMm,
                  heightMm: regionalPrice.sheetSize!.heightMm,
                )
              : country != null &&
                    country.code != 'CO' &&
                    country.boardSizes.isNotEmpty
              ? SheetSize(
                  widthMm: country.boardSizes.first.widthMm,
                  heightMm: country.boardSizes.first.heightMm,
                )
              : material.sheetSize,
          priceSource: regionalPrice?.source ?? material.priceSource,
          priceNote: regionalPrice?.note ?? material.priceNote,
        );
      }(),
  ]);
});

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
  final kerfMm = ref.watch(projectContextValueProvider)?.kerfMm ?? 3.2;
  return const CutListCalculator().build(furniture, catalog, kerfMm: kerfMm);
});

final validationProvider = Provider<List<ValidationIssue>>((ref) {
  final spec = ref.watch(designerProvider);
  return const FurnitureValidator().validate(spec);
});

/// Medida que el usuario está editando, para resaltarla en el visor 3D.
class DimensionFocusController extends Notifier<String?> {
  @override
  String? build() => null;

  void focus(String? dimension) => state = dimension;
}

final dimensionFocusProvider =
    NotifierProvider<DimensionFocusController, String?>(
      DimensionFocusController.new,
    );
