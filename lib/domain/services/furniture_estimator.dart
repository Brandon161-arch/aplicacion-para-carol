import '../entities/cost_report.dart';
import '../entities/furniture.dart';
import '../entities/hardware_price_catalog.dart';
import '../entities/hardware_requirement.dart';
import '../entities/material.dart';
import '../entities/pricing_settings.dart';
import '../entities/regional_catalog.dart';
import 'cost_calculator.dart';
import 'cut_list_calculator.dart';
import 'hardware_calculator.dart';

class FurnitureEstimate {
  final CutList cutList;
  final List<HardwareRequirement> hardware;
  final CostReport costs;

  const FurnitureEstimate({
    required this.cutList,
    required this.hardware,
    required this.costs,
  });
}

/// Orquesta el despiece, los herrajes y el costo desde el mismo modelo.
class FurnitureEstimator {
  const FurnitureEstimator();

  FurnitureEstimate calculate({
    required Furniture furniture,
    required MaterialCatalog catalog,
    required HardwarePriceCatalog hardwarePrices,
    required PricingSettings pricingSettings,
    double taxPercent = 0,
    double kerfMm = 3.2,
    List<CutPriceTier> cutPriceTiers = const [],
    String pricingNote = 'Precios locales no configurados.',
  }) {
    final cutList = const CutListCalculator().build(
      furniture,
      catalog,
      kerfMm: kerfMm,
    );
    final hardware = const HardwareCalculator().calculate(
      furniture,
      hardwarePrices,
    );
    final costs = const CostCalculator().calculate(
      cutList: cutList,
      catalog: catalog,
      hardware: hardware,
      settings: pricingSettings,
      taxPercent: taxPercent,
      cutPriceTiers: cutPriceTiers,
      pricingNote: pricingNote,
    );
    return FurnitureEstimate(
      cutList: cutList,
      hardware: hardware,
      costs: costs,
    );
  }
}
