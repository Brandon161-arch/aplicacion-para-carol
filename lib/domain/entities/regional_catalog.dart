/// Configuración regional editable cargada desde assets/config.
class RegionalCatalog {
  final int schemaVersion;
  final List<CountryProfile> countries;
  final List<MaterialProfile> materials;
  final List<ClimateOption> climates;
  final List<PlaceUseOption> uses;

  const RegionalCatalog({
    required this.schemaVersion,
    required this.countries,
    required this.materials,
    required this.climates,
    required this.uses,
  });

  factory RegionalCatalog.fromJson(Map<String, dynamic> json) {
    final countries = json['countries'] as List? ?? const [];
    final materials = json['materialProfiles'] as List? ?? const [];
    final climates = json['climates'] as List? ?? const [];
    final uses = json['uses'] as List? ?? const [];
    return RegionalCatalog(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      countries: countries
          .whereType<Map>()
          .map(
            (value) => CountryProfile.fromJson(value.cast<String, dynamic>()),
          )
          .toList(growable: false),
      materials: materials
          .whereType<Map>()
          .map(
            (value) => MaterialProfile.fromJson(value.cast<String, dynamic>()),
          )
          .toList(growable: false),
      climates: climates
          .whereType<Map>()
          .map((value) => ClimateOption.fromJson(value.cast<String, dynamic>()))
          .toList(growable: false),
      uses: uses
          .whereType<Map>()
          .map(
            (value) => PlaceUseOption.fromJson(value.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  CountryProfile? countryByCode(String code) {
    for (final country in countries) {
      if (country.code == code) return country;
    }
    return null;
  }
}

class BoardFormat {
  final double widthMm;
  final double heightMm;

  const BoardFormat({required this.widthMm, required this.heightMm});

  factory BoardFormat.fromJson(List<dynamic> json) => BoardFormat(
    widthMm: (json[0] as num).toDouble(),
    heightMm: (json[1] as num).toDouble(),
  );

  String get label => '${widthMm.round()} × ${heightMm.round()} mm';
}

class CountryProfile {
  final String code;
  final String name;
  final String currency;
  final String defaultUnit;
  final String taxName;
  final double? standardTaxPercent;
  final String taxSource;
  final String taxUpdatedAt;
  final String taxNote;
  final List<BoardFormat> boardSizes;
  final bool priceDataAvailable;
  final String priceDataNote;
  final String pricingNote;
  final Map<String, RegionalMaterialPrice> materialPrices;
  final Map<String, int> hardwarePricesCents;
  final List<CutPriceTier> cutPriceTiers;
  final int laborRateCentsPerHour;

  const CountryProfile({
    required this.code,
    required this.name,
    required this.currency,
    required this.defaultUnit,
    required this.taxName,
    required this.standardTaxPercent,
    required this.taxSource,
    required this.taxUpdatedAt,
    required this.taxNote,
    required this.boardSizes,
    required this.priceDataAvailable,
    required this.priceDataNote,
    required this.pricingNote,
    required this.materialPrices,
    required this.hardwarePricesCents,
    required this.cutPriceTiers,
    required this.laborRateCentsPerHour,
  });

  factory CountryProfile.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['boardSizesMm'] as List? ?? const [];
    final rawMaterialPrices = json['materialPrices'];
    final rawHardwarePrices = json['hardwarePricesCents'];
    final rawCutTiers = json['cutPriceTiers'] as List? ?? const [];
    return CountryProfile(
      code: json['code'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      defaultUnit: json['defaultUnit'] as String? ?? 'mm',
      taxName: json['taxName'] as String? ?? 'Impuesto',
      standardTaxPercent: (json['standardTaxPercent'] as num?)?.toDouble(),
      taxSource: json['taxSource'] as String? ?? '',
      taxUpdatedAt: json['taxUpdatedAt'] as String? ?? '',
      taxNote: json['taxNote'] as String? ?? '',
      boardSizes: rawSizes
          .whereType<List>()
          .map((value) => BoardFormat.fromJson(value))
          .toList(growable: false),
      priceDataAvailable: json['priceDataAvailable'] as bool? ?? false,
      priceDataNote: json['priceDataNote'] as String? ?? '',
      pricingNote: json['pricingNote'] as String? ?? '',
      materialPrices: rawMaterialPrices is Map
          ? {
              for (final entry in rawMaterialPrices.entries)
                entry.key.toString(): RegionalMaterialPrice.fromJson(
                  (entry.value as Map).cast<String, dynamic>(),
                ),
            }
          : const {},
      hardwarePricesCents: rawHardwarePrices is Map
          ? {
              for (final entry in rawHardwarePrices.entries)
                entry.key.toString(): (entry.value as num).toInt(),
            }
          : const {},
      cutPriceTiers: rawCutTiers
          .whereType<Map>()
          .map((value) => CutPriceTier.fromJson(value.cast<String, dynamic>()))
          .toList(growable: false),
      laborRateCentsPerHour:
          (json['laborRateCentsPerHour'] as num?)?.toInt() ?? 0,
    );
  }
}

class RegionalMaterialPrice {
  final int priceCents;
  final String source;
  final String note;
  final BoardFormat? sheetSize;

  const RegionalMaterialPrice({
    required this.priceCents,
    required this.source,
    required this.note,
    required this.sheetSize,
  });

  factory RegionalMaterialPrice.fromJson(Map<String, dynamic> json) {
    final rawSheet = json['sheetSizeMm'];
    return RegionalMaterialPrice(
      priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
      sheetSize: rawSheet is List ? BoardFormat.fromJson(rawSheet) : null,
    );
  }
}

class CutPriceTier {
  final int? maxPiecesPerSheet;
  final int priceCents;

  const CutPriceTier({
    required this.maxPiecesPerSheet,
    required this.priceCents,
  });

  factory CutPriceTier.fromJson(Map<String, dynamic> json) => CutPriceTier(
    maxPiecesPerSheet: (json['maxPiecesPerSheet'] as num?)?.toInt(),
    priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
  );
}

class MaterialProfile {
  final String id;
  final String name;
  final String? catalogMaterialId;
  final String costBand;
  final List<String> pros;
  final List<String> cons;
  final Map<String, int> climateScores;
  final Map<String, int> useScores;

  const MaterialProfile({
    required this.id,
    required this.name,
    required this.catalogMaterialId,
    required this.costBand,
    required this.pros,
    required this.cons,
    required this.climateScores,
    required this.useScores,
  });

  factory MaterialProfile.fromJson(Map<String, dynamic> json) =>
      MaterialProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        catalogMaterialId: json['catalogMaterialId'] as String?,
        costBand: json['costBand'] as String? ?? 'por cotizar',
        pros: (json['pros'] as List? ?? const []).cast<String>(),
        cons: (json['cons'] as List? ?? const []).cast<String>(),
        climateScores: _scoreMap(json['scores']),
        useScores: _scoreMap(json['useScores']),
      );

  static Map<String, int> _scoreMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): (entry.value as num).toInt(),
    };
  }
}

class ClimateOption {
  final String id;
  final String label;

  const ClimateOption({required this.id, required this.label});

  factory ClimateOption.fromJson(Map<String, dynamic> json) =>
      ClimateOption(id: json['id'] as String, label: json['label'] as String);
}

class PlaceUseOption {
  final String id;
  final String label;

  const PlaceUseOption({required this.id, required this.label});

  factory PlaceUseOption.fromJson(Map<String, dynamic> json) =>
      PlaceUseOption(id: json['id'] as String, label: json['label'] as String);
}
