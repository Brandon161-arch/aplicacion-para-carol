import 'hardware_item.dart' show HardwareKind;

/// Lado por el que pivota una puerta.
enum HingeSide {
  left,
  right,
  top,
  bottom;

  String get label => switch (this) {
    HingeSide.left => 'Izquierda',
    HingeSide.right => 'Derecha',
    HingeSide.top => 'Superior',
    HingeSide.bottom => 'Inferior',
  };
}

/// Movimiento que se podrá animar en el visor 3D.
sealed class Mechanism {
  final String id;
  final List<String> partIds;

  const Mechanism({required this.id, required this.partIds});
}

class HingedDoorMechanism extends Mechanism {
  final String doorPartId;
  final HingeSide hingeSide;
  final double maxOpenAngleDeg;
  final int hingeCount;
  final HardwareKind hingeKind;
  final String? hingeSpec;

  const HingedDoorMechanism({
    required super.id,
    required super.partIds,
    required this.doorPartId,
    required this.hingeSide,
    this.maxOpenAngleDeg = 110,
    this.hingeCount = 2,
    this.hingeKind = HardwareKind.hinge,
    this.hingeSpec,
  });
}

class DrawerMechanism extends Mechanism {
  final String frontPartId;
  final List<String> boxPartIds;
  final double travelMm;
  final HardwareKind slideKind;
  final String? slideSpec;

  const DrawerMechanism({
    required super.id,
    required super.partIds,
    required this.frontPartId,
    required this.boxPartIds,
    required this.travelMm,
    this.slideKind = HardwareKind.drawerSlide,
    this.slideSpec,
  });
}
