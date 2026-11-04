/// Tipos de herraje que puede necesitar un mueble.
enum HardwareKind {
  hinge,
  drawerSlide,
  screw,
  dowel,
  camLock,
  confirmat,
  shelfPin,
  handle,
  foot,
  magnet,
  gasStrut,
  connector,
  nail,
  glue;

  String get label => switch (this) {
    HardwareKind.hinge => 'Bisagra',
    HardwareKind.drawerSlide => 'Corredera',
    HardwareKind.screw => 'Tornillo',
    HardwareKind.dowel => 'Tarugo',
    HardwareKind.camLock => 'Minifix',
    HardwareKind.confirmat => 'Confirmat',
    HardwareKind.shelfPin => 'Soporte de estante',
    HardwareKind.handle => 'Tirador',
    HardwareKind.foot => 'Pata / nivelador',
    HardwareKind.magnet => 'Imán / cierre',
    HardwareKind.gasStrut => 'Pistón a gas',
    HardwareKind.connector => 'Conector',
    HardwareKind.nail => 'Clavo',
    HardwareKind.glue => 'Cola',
  };
}

/// Herraje cargado manualmente por el usuario.
///
/// Los herrajes derivados de uniones y mecanismos se calcularán aparte en la
/// fase de herrajes, para no duplicar conteos.
class HardwareItem {
  final String id;
  final HardwareKind kind;
  final String name;
  final String? spec;
  final int quantity;
  final int? unitPriceCents;
  final List<String> partIds;
  final Map<String, Object?> attributes;

  const HardwareItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.quantity,
    this.spec,
    this.unitPriceCents,
    this.partIds = const [],
    this.attributes = const {},
  });
}
