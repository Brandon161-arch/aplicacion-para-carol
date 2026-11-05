import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/seeds/hardware_price_seed.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/hardware_price_catalog.dart';
import '../../domain/entities/pricing_settings.dart';
import 'project_context_provider.dart';

class LocalPricingData {
  /// Compatibilidad con preferencias antiguas: valores de Colombia (CO).
  final Map<String, int> materialPriceOverrides;
  final Map<String, int> hardwarePriceOverrides;
  final PricingSettings settings;
  final Map<String, Map<String, int>> materialOverridesByCountry;
  final Map<String, Map<String, int>> hardwareOverridesByCountry;
  final Map<String, PricingSettings> settingsByCountry;

  const LocalPricingData({
    this.materialPriceOverrides = const {},
    this.hardwarePriceOverrides = const {},
    this.settings = const PricingSettings(),
    this.materialOverridesByCountry = const {},
    this.hardwareOverridesByCountry = const {},
    this.settingsByCountry = const {},
  });

  Map<String, int> materialPricesFor(String countryCode) =>
      materialOverridesByCountry[countryCode] ??
      (countryCode == 'CO' ? materialPriceOverrides : const {});

  Map<String, int> hardwarePricesFor(String countryCode) =>
      hardwareOverridesByCountry[countryCode] ??
      (countryCode == 'CO' ? hardwarePriceOverrides : const {});

  PricingSettings settingsFor(String countryCode) =>
      settingsByCountry[countryCode] ??
      (countryCode == 'CO' ? settings : const PricingSettings());
}

/// Precios editables que se conservan en el dispositivo/navegador.
class LocalPricingController extends AsyncNotifier<LocalPricingData> {
  static const String _storageKey = 'mueblecad.pricing.v1';

  @override
  Future<LocalPricingData> build() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const LocalPricingData();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const LocalPricingData();
      final data = decoded.cast<String, dynamic>();
      final materialByCountry = <String, Map<String, int>>{};
      final hardwareByCountry = <String, Map<String, int>>{};
      final settingsByCountry = <String, PricingSettings>{};
      final rawRegions = data['regions'];
      if (rawRegions is Map) {
        for (final entry in rawRegions.entries) {
          if (entry.value is! Map) continue;
          final region = (entry.value as Map).cast<String, dynamic>();
          final code = entry.key.toString();
          materialByCountry[code] = _pricesFromJson(region['materialPrices']);
          hardwareByCountry[code] = _pricesFromJson(region['hardwarePrices']);
          final rawSettings = region['settings'];
          if (rawSettings is Map) {
            settingsByCountry[code] = _settingsFromJson(
              rawSettings.cast<String, dynamic>(),
            );
          }
        }
      }

      // Importa el formato antiguo como configuración de Colombia.
      final legacyMaterials = _pricesFromJson(data['materialPrices']);
      final legacyHardware = _pricesFromJson(data['hardwarePrices']);
      final rawLegacySettings = data['settings'];
      final legacySettings = rawLegacySettings is Map
          ? _settingsFromJson(rawLegacySettings.cast<String, dynamic>())
          : const PricingSettings();
      materialByCountry.putIfAbsent('CO', () => legacyMaterials);
      hardwareByCountry.putIfAbsent('CO', () => legacyHardware);
      settingsByCountry.putIfAbsent('CO', () => legacySettings);

      return LocalPricingData(
        materialPriceOverrides: materialByCountry['CO'] ?? const {},
        hardwarePriceOverrides: hardwareByCountry['CO'] ?? const {},
        settings: settingsByCountry['CO'] ?? const PricingSettings(),
        materialOverridesByCountry: _freezeNested(materialByCountry),
        hardwareOverridesByCountry: _freezeNested(hardwareByCountry),
        settingsByCountry: Map.unmodifiable(settingsByCountry),
      );
    } on FormatException catch (_) {
      return const LocalPricingData();
    }
  }

  Future<void> updateAll({
    String countryCode = 'CO',
    required Map<String, int> materialPriceOverrides,
    Map<String, int> hardwarePriceOverrides = const {},
    required PricingSettings settings,
  }) async {
    final current = state.asData?.value ?? const LocalPricingData();
    final materialByCountry = {
      ...current.materialOverridesByCountry,
      countryCode: Map<String, int>.unmodifiable(materialPriceOverrides),
    };
    final hardwareByCountry = {
      ...current.hardwareOverridesByCountry,
      countryCode: Map<String, int>.unmodifiable(hardwarePriceOverrides),
    };
    final settingsByCountry = {
      ...current.settingsByCountry,
      countryCode: settings,
    };
    final updated = LocalPricingData(
      materialPriceOverrides: materialByCountry['CO'] ?? const {},
      hardwarePriceOverrides: hardwareByCountry['CO'] ?? const {},
      settings: settingsByCountry['CO'] ?? const PricingSettings(),
      materialOverridesByCountry: _freezeNested(materialByCountry),
      hardwareOverridesByCountry: _freezeNested(hardwareByCountry),
      settingsByCountry: Map.unmodifiable(settingsByCountry),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_toJson(updated)));
    state = AsyncData(updated);
  }

  Future<void> reset({String countryCode = 'CO'}) => updateAll(
    countryCode: countryCode,
    materialPriceOverrides: const {},
    hardwarePriceOverrides: const {},
    settings: const PricingSettings(),
  );

  Map<String, dynamic> _toJson(LocalPricingData data) {
    final codes = <String>{
      ...data.materialOverridesByCountry.keys,
      ...data.hardwareOverridesByCountry.keys,
      ...data.settingsByCountry.keys,
    };
    return {
      'regions': {
        for (final code in codes)
          code: {
            'materialPrices': data.materialPricesFor(code),
            'hardwarePrices': data.hardwarePricesFor(code),
            'settings': _settingsToJson(data.settingsFor(code)),
          },
      },
    };
  }

  static Map<String, int> _pricesFromJson(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).round(),
    };
  }

  static Map<String, Map<String, int>> _freezeNested(
    Map<String, Map<String, int>> source,
  ) => Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: Map<String, int>.unmodifiable(entry.value),
  });

  Map<String, dynamic> _settingsToJson(PricingSettings settings) => {
    'currency': settings.currency,
    'wastePercent': settings.wastePercent,
    'cutPricePerSheetOverrideCents': settings.cutPricePerSheetOverrideCents,
    'taxPercentOverride': settings.taxPercentOverride,
    'laborRateCentsPerHour': settings.laborRateCentsPerHour,
    'estimatedLaborHours': settings.estimatedLaborHours,
  };

  PricingSettings _settingsFromJson(Map<String, dynamic> json) {
    final override = json['cutPricePerSheetOverrideCents'];
    return PricingSettings(
      currency: json['currency']?.toString() ?? 'COP',
      wastePercent: (json['wastePercent'] as num?)?.toDouble() ?? 10,
      cutPricePerSheetOverrideCents: override is num ? override.round() : null,
      taxPercentOverride: (json['taxPercentOverride'] as num?)?.toDouble(),
      laborRateCentsPerHour:
          (json['laborRateCentsPerHour'] as num?)?.round() ?? 0,
      estimatedLaborHours:
          (json['estimatedLaborHours'] as num?)?.toDouble() ?? 0,
    );
  }
}

final localPricingProvider =
    AsyncNotifierProvider<LocalPricingController, LocalPricingData>(
      LocalPricingController.new,
    );

final pricingSettingsProvider = Provider<PricingSettings>((ref) {
  final localPricing = ref.watch(localPricingProvider).asData?.value;
  final country = ref.watch(projectContextValueProvider)?.country;
  final stored = country == null
      ? localPricing?.settings ?? const PricingSettings()
      : localPricing?.settingsFor(country.code) ?? const PricingSettings();
  if (country == null) return stored;
  return stored.copyWith(
    currency: country.currency,
    laborRateCentsPerHour: stored.laborRateCentsPerHour > 0
        ? stored.laborRateCentsPerHour
        : country.laborRateCentsPerHour,
  );
});

final hardwarePriceCatalogProvider = Provider<HardwarePriceCatalog>((ref) {
  final overrides = ref.watch(localPricingProvider).asData?.value;
  final country = ref.watch(projectContextValueProvider)?.country;
  final regionalOverrides = country == null
      ? overrides?.hardwarePriceOverrides ?? const <String, int>{}
      : overrides?.hardwarePricesFor(country.code) ?? const <String, int>{};
  return HardwarePriceCatalog({
    for (final kind in HardwareKind.values)
      kind:
          regionalOverrides[kind.name] ??
          country?.hardwarePricesCents[kind.name] ??
          (country != null && !country.priceDataAvailable
              ? 0
              : sampleHardwarePrices.priceFor(kind)),
  });
});
