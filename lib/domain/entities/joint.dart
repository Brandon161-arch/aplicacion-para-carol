import 'hardware_item.dart';

/// Tipo de unión entre dos piezas.
enum JointType {
  buttScrew,
  confirmat,
  dowel,
  camLock,
  dado,
  rabbet,
  miter,
  biscuit,
  nail,
  glueOnly;

  String get label => switch (this) {
    JointType.buttScrew => 'Tornillo directo',
    JointType.confirmat => 'Confirmat',
    JointType.dowel => 'Tarugo',
    JointType.camLock => 'Minifix / excéntrica',
    JointType.dado => 'Ranura (dado)',
    JointType.rabbet => 'Rebaje',
    JointType.miter => 'Inglete',
    JointType.biscuit => 'Galleta',
    JointType.nail => 'Clavo',
    JointType.glueOnly => 'Solo cola',
  };
}

/// Especificación de un sujetador concreto.
class FastenerSpec {
  final HardwareKind kind;
  final double? diameterMm;
  final double? lengthMm;
  final String label;

  const FastenerSpec({
    required this.kind,
    required this.label,
    this.diameterMm,
    this.lengthMm,
  });
}

/// Unión entre dos piezas del mueble.
///
/// [count] indica cuántos sujetadores iguales se usan en esa unión.
/// La longitud y el tipo definitivo se validan en la fase de herrajes.
class Joint {
  final String id;
  final JointType type;
  final String partAId;
  final String partBId;
  final int count;
  final FastenerSpec? fastener;
  final String? notes;

  const Joint({
    required this.id,
    required this.type,
    required this.partAId,
    required this.partBId,
    this.count = 1,
    this.fastener,
    this.notes,
  });
}
