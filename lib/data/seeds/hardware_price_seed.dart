import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/hardware_price_catalog.dart';

/// Precios unitarios de referencia en COP. Son editables por el usuario.
const HardwarePriceCatalog sampleHardwarePrices = HardwarePriceCatalog({
  HardwareKind.hinge: 450000, // COP 4.500 por bisagra
  HardwareKind.drawerSlide: 900000, // COP 9.000 por riel
  HardwareKind.confirmat: 70000, // COP 700 por tornillo
  HardwareKind.screw: 30000, // COP 300 por tornillo
  HardwareKind.dowel: 20000, // COP 200 por tarugo
  HardwareKind.nail: 5000, // COP 50 por clavo
  HardwareKind.shelfPin: 30000, // COP 300 por soporte
  HardwareKind.handle: 800000, // COP 8.000 por tirador
  HardwareKind.camLock: 150000, // COP 1.500 por minifix
  HardwareKind.foot: 250000, // COP 2.500 por nivelador
  HardwareKind.magnet: 100000, // COP 1.000 por cierre magnético
  HardwareKind.gasStrut: 2500000, // COP 25.000 por pistón
  HardwareKind.connector: 50000,
  HardwareKind.glue: 500000, // COP 5.000 por porción estimada
});
