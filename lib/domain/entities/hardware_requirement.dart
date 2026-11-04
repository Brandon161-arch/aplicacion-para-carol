import 'hardware_item.dart';

/// Un lugar concreto donde se instala una cantidad de herrajes.
class HardwarePlacement {
  final String location;
  final int quantity;
  final String note;

  const HardwarePlacement({
    required this.location,
    required this.quantity,
    required this.note,
  });
}

/// Herraje calculado desde uniones, mecanismos y tipos de pieza.
class HardwareRequirement {
  final HardwareKind kind;
  final String name;
  final String spec;
  final int quantity;
  final int unitPriceCents;
  final List<HardwarePlacement> placements;

  const HardwareRequirement({
    required this.kind,
    required this.name,
    required this.spec,
    required this.quantity,
    required this.unitPriceCents,
    required this.placements,
  });

  int get totalPriceCents => quantity * unitPriceCents;
}
