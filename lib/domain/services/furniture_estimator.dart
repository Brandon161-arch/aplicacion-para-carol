import '../entities/cost_report.dart';
import '../entities/furniture.dart';
import '../entities/hardware_price_catalog.dart';
import '../entities/hardware_requirement.dart';
import '../entities/material.dart';
import '../entities/pricing_settings.dart';
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
  }) {
    final cutList = const CutListCalculator().build(furniture, catalog);
    final hardware = const HardwareCalculator().calculate(
      furniture,
      hardwarePrices,
    );
    final costs = const CostCalculator().calculate(
      cutList: cutList,
      catalog: catalog,
      hardware: hardware,
      settings: pricingSettings,
    );
    return FurnitureEstimate(
      cutList: cutList,
      hardware: hardware,
      costs: costs,
    );
  }
}
