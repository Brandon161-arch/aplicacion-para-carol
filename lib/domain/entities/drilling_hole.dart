/// Tipo y propósito de perforación para carpintería.
enum HoleType {
  hingeCup35,      // Cazoleta de bisagra Ø35mm (profundidad 11.5mm)
  hingePlateMount, // Orificios fijación placa bisagra en lateral (Ø5mm sistema 32)
  drawerSlideMount,// Orificios corredera telescópica en lateral (Ø5mm sistema 32)
  confirmatThrough,// Pasante para Confirmat en cara (Ø7mm)
  confirmatEdge,   // En canto para Confirmat (Ø5mm x 50mm)
  minifixCam15,    // Caja de leva Minifix Ø15mm (a 34mm del canto)
  minifixBoltEdge, // En canto para perno Minifix Ø8mm
  minifixBoltFace, // En cara para anclar espiga Minifix Ø5mm
  dowel8,          // Tarugo / espiga de madera Ø8mm x 30mm
  shelfPin5,       // Pines o soporte de estantes móviles Ø5mm
  handleScrew,     // Perforación para tornillo de manija / tirador Ø4.5mm
}

/// Una perforación específica con sus coordenadas X/Y en la cara o canto de la pieza.
class DrillingHole {
  final HoleType type;
  final double xMm;
  final double yMm;
  final double diameterMm;
  final double depthMm;
  final String face; // 'front', 'back', 'top_edge', 'bottom_edge', 'left_edge', 'right_edge'
  final String description;

  const DrillingHole({
    required this.type,
    required this.xMm,
    required this.yMm,
    required this.diameterMm,
    required this.depthMm,
    this.face = 'front',
    required this.description,
  });
}

/// Mapa de perforaciones de una pieza específica.
class PartDrillingPattern {
  final String partId;
  final String partName;
  final double lengthMm;
  final double widthMm;
  final double thicknessMm;
  final List<DrillingHole> holes;

  const PartDrillingPattern({
    required this.partId,
    required this.partName,
    required this.lengthMm,
    required this.widthMm,
    required this.thicknessMm,
    required this.holes,
  });

  int get holeCount => holes.length;
}
