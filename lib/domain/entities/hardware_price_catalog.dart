import 'hardware_item.dart';

/// Precios de referencia de herrajes, expresados en centavos de COP.
class HardwarePriceCatalog {
  final Map<HardwareKind, int> priceCentsByKind;

  const HardwarePriceCatalog(this.priceCentsByKind);

  int priceFor(HardwareKind kind) => priceCentsByKind[kind] ?? 0;
}
