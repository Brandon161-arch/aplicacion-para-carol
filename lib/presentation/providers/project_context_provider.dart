import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/regional_catalog.dart';
import '../../domain/services/material_recommender.dart';
import '../../domain/value_objects/measurement_unit.dart';

class ProjectContext {
  final RegionalCatalog catalog;
  final String countryCode;
  final String unitCode;
  final String climateId;
  final String useId;
  final double kerfMm;

  const ProjectContext({
    required this.catalog,
    required this.countryCode,
    required this.unitCode,
    required this.climateId,
    required this.useId,
    required this.kerfMm,
  });

  CountryProfile get country =>
      catalog.countryByCode(countryCode) ?? catalog.countries.first;

  MeasurementUnit get unit => MeasurementUnit.fromCode(unitCode);

  ProjectContext copyWith({
    String? countryCode,
    String? unitCode,
    String? climateId,
    String? useId,
    double? kerfMm,
  }) => ProjectContext(
    catalog: catalog,
    countryCode: countryCode ?? this.countryCode,
    unitCode: unitCode ?? this.unitCode,
    climateId: climateId ?? this.climateId,
    useId: useId ?? this.useId,
    kerfMm: kerfMm ?? this.kerfMm,
  );
}

class ProjectContextController extends AsyncNotifier<ProjectContext> {
  static const _storageKey = 'mueblecad.project-context.v1';

  @override
  Future<ProjectContext> build() async {
    final catalog = ref.watch(regionalCatalogProvider);
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    final saved = stored == null
        ? <String, dynamic>{}
        : (jsonDecode(stored) as Map).cast<String, dynamic>();

    final preferredCountry = saved['countryCode']?.toString() ?? 'CO';
    final country =
        catalog.countryByCode(preferredCountry) ?? catalog.countries.first;
    final climateId = _validOption(
      saved['climateId']?.toString(),
      catalog.climates.map((option) => option.id),
      'temperate',
    );
    final useId = _validOption(
      saved['useId']?.toString(),
      catalog.uses.map((option) => option.id),
      'interior',
    );
    final unitCode = _validUnit(
      saved['unitCode']?.toString() ?? country.defaultUnit,
    );
    return ProjectContext(
      catalog: catalog,
      countryCode: country.code,
      unitCode: unitCode,
      climateId: climateId,
      useId: useId,
      kerfMm:
          (saved['kerfMm'] as num?)?.toDouble().clamp(0.5, 8.0).toDouble() ??
          3.2,
    );
  }

  Future<void> selectCountry(String countryCode) async {
    final current = state.asData?.value;
    if (current == null) return;
    final country = current.catalog.countryByCode(countryCode);
    if (country == null) return;
    await _update(
      current.copyWith(
        countryCode: country.code,
        unitCode: country.defaultUnit,
      ),
    );
  }

  Future<void> selectUnit(MeasurementUnit unit) async {
    final current = state.asData?.value;
    if (current != null) await _update(current.copyWith(unitCode: unit.code));
  }

  Future<void> selectClimate(String climateId) async {
    final current = state.asData?.value;
    if (current != null) {
      await _update(current.copyWith(climateId: climateId));
    }
  }

  Future<void> selectUse(String useId) async {
    final current = state.asData?.value;
    if (current != null) await _update(current.copyWith(useId: useId));
  }

  Future<void> selectKerf(double kerfMm) async {
    final current = state.asData?.value;
    if (current != null) {
      await _update(
        current.copyWith(kerfMm: kerfMm.clamp(0.5, 8.0).toDouble()),
      );
    }
  }

  Future<void> _update(ProjectContext context) async {
    state = AsyncData(context);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'countryCode': context.countryCode,
        'unitCode': context.unitCode,
        'climateId': context.climateId,
        'useId': context.useId,
        'kerfMm': context.kerfMm,
      }),
    );
  }

  String _validOption(
    String? value,
    Iterable<String> values,
    String fallback,
  ) => value != null && values.contains(value) ? value : fallback;

  String _validUnit(String? value) =>
      MeasurementUnit.values.any((unit) => unit.code == value)
      ? value!
      : MeasurementUnit.millimeter.code;
}

final projectContextProvider =
    AsyncNotifierProvider<ProjectContextController, ProjectContext>(
      ProjectContextController.new,
    );

final regionalCatalogProvider = Provider<RegionalCatalog>(
  (ref) => throw StateError(
    'regionalCatalogProvider debe inicializarse desde el archivo de configuración.',
  ),
);

final projectContextValueProvider = Provider<ProjectContext?>(
  (ref) => ref.watch(projectContextProvider).asData?.value,
);

final materialRecommendationsProvider = Provider<List<MaterialRecommendation>>((
  ref,
) {
  final context = ref.watch(projectContextValueProvider);
  if (context == null) return const [];
  return const MaterialRecommender().rank(
    catalog: context.catalog,
    climateId: context.climateId,
    useId: context.useId,
  );
});
