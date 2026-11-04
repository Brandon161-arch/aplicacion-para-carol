/// Parámetros editables para estimar el costo de fabricación.
class PricingSettings {
  final String currency;
  final double wastePercent;

  /// Si es null, se usan las tarifas de corte por lámina de referencia.
  final int? cutPricePerSheetOverrideCents;
  final int laborRateCentsPerHour;
  final double estimatedLaborHours;

  const PricingSettings({
    this.currency = 'COP',
    this.wastePercent = 10,
    this.cutPricePerSheetOverrideCents,
    this.laborRateCentsPerHour = 0,
    this.estimatedLaborHours = 0,
  });

  PricingSettings copyWith({
    String? currency,
    double? wastePercent,
    int? cutPricePerSheetOverrideCents,
    bool clearCutPriceOverride = false,
    int? laborRateCentsPerHour,
    double? estimatedLaborHours,
  }) => PricingSettings(
    currency: currency ?? this.currency,
    wastePercent: wastePercent ?? this.wastePercent,
    cutPricePerSheetOverrideCents: clearCutPriceOverride
        ? null
        : cutPricePerSheetOverrideCents ?? this.cutPricePerSheetOverrideCents,
    laborRateCentsPerHour: laborRateCentsPerHour ?? this.laborRateCentsPerHour,
    estimatedLaborHours: estimatedLaborHours ?? this.estimatedLaborHours,
  );
}
