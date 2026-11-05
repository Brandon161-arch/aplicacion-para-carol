import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/seeds/hardware_price_seed.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/hardware_price_catalog.dart';
import '../../domain/entities/pricing_settings.dart';
import 'project_context_provider.dart';

class LocalPricingData {
  final Map<String, int> materialPriceOverrides;
  final Map<String, int> hardwarePriceOverrides;
  final PricingSettings settings;

  const LocalPricingData({
    this.materialPriceOverrides = const {},
    this.hardwarePriceOverrides = const {},
    this.settings = const PricingSettings(),
  });
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
      final rawPrices = data['materialPrices'];
      final prices = <String, int>{};
      if (rawPrices is Map) {
        for (final entry in rawPrices.entries) {
          if (entry.value is num) {
            prices[entry.key.toString()] = (entry.value as num).round();
          }
        }
      }
      final rawHardwarePrices = data['hardwarePrices'];
      final hardwarePrices = <String, int>{};
      if (rawHardwarePrices is Map) {
        for (final entry in rawHardwarePrices.entries) {
          if (entry.value is num) {
            hardwarePrices[entry.key.toString()] = (entry.value as num).round();
          }
        }
      }
      final rawSettings = data['settings'];
      final settings = rawSettings is Map
          ? _settingsFromJson(rawSettings.cast<String, dynamic>())
          : const PricingSettings();
      return LocalPricingData(
        materialPriceOverrides: prices,
        hardwarePriceOverrides: hardwarePrices,
        settings: settings,
      );
    } on FormatException {
      return const LocalPricingData();
    }
  }

  Future<void> updateAll({
    required Map<String, int> materialPriceOverrides,
    Map<String, int> hardwarePriceOverrides = const {},
    required PricingSettings settings,
  }) async {
    final updated = LocalPricingData(
      materialPriceOverrides: Map<String, int>.unmodifiable(
        materialPriceOverrides,
      ),
      hardwarePriceOverrides: Map<String, int>.unmodifiable(
        hardwarePriceOverrides,
      ),
      settings: settings,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_toJson(updated)));
    state = AsyncData(updated);
  }

  Future<void> reset() => updateAll(
    materialPriceOverrides: const {},
    hardwarePriceOverrides: const {},
    settings: const PricingSettings(),
  );

  Map<String, dynamic> _toJson(LocalPricingData data) => {
    'materialPrices': data.materialPriceOverrides,
    'hardwarePrices': data.hardwarePriceOverrides,
    'settings': {
      'currency': data.settings.currency,
      'wastePercent': data.settings.wastePercent,
      'cutPricePerSheetOverrideCents':
          data.settings.cutPricePerSheetOverrideCents,
      'laborRateCentsPerHour': data.settings.laborRateCentsPerHour,
      'estimatedLaborHours': data.settings.estimatedLaborHours,
    },
  };

  PricingSettings _settingsFromJson(Map<String, dynamic> json) {
    final override = json['cutPricePerSheetOverrideCents'];
    return PricingSettings(
      currency: json['currency']?.toString() ?? 'COP',
      wastePercent: (json['wastePercent'] as num?)?.toDouble() ?? 10,
      cutPricePerSheetOverrideCents: override is num ? override.round() : null,
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
  final stored =
      ref.watch(localPricingProvider).asData?.value.settings ??
      const PricingSettings();
  final country = ref.watch(projectContextValueProvider)?.country;
  if (country == null) return stored;
  return stored.copyWith(
    currency: country.currency,
    laborRateCentsPerHour: stored.laborRateCentsPerHour > 0
        ? stored.laborRateCentsPerHour
        : country.laborRateCentsPerHour,
  );
});

final hardwarePriceCatalogProvider = Provider<HardwarePriceCatalog>((ref) {
  final overrides =
      ref.watch(localPricingProvider).asData?.value.hardwarePriceOverrides ??
      const <String, int>{};
  final country = ref.watch(projectContextValueProvider)?.country;
  return HardwarePriceCatalog({
    for (final kind in HardwareKind.values)
      kind:
          ((country == null || country.code == 'CO')
              ? overrides[kind.name]
              : null) ??
          country?.hardwarePricesCents[kind.name] ??
          (country != null && !country.priceDataAvailable
              ? 0
              : sampleHardwarePrices.priceFor(kind)),
  });
});
