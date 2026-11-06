import '../../core/constants/units.dart';
import '../value_objects/cut_size.dart';
import '../value_objects/part_shape.dart';
import '../value_objects/size3.dart';
import '../value_objects/vector3.dart';

/// Función estructural de una pieza dentro del mueble.
enum PartKind {
  sidePanel,
  topPanel,
  bottomPanel,
  shelf,
  backPanel,
  divider,
  door,
  drawerFront,
  drawerSide,
  drawerBack,
  drawerBottom,
  rail,
  plinth,
  desktop,
  leg,
  apron,
  other;

  String get label => switch (this) {
    PartKind.sidePanel => 'Lateral',
    PartKind.topPanel => 'Tapa',
    PartKind.bottomPanel => 'Base',
    PartKind.shelf => 'Estante',
    PartKind.backPanel => 'Fondo',
    PartKind.divider => 'División',
    PartKind.door => 'Puerta',
    PartKind.drawerFront => 'Frente de cajón',
    PartKind.drawerSide => 'Lado de cajón',
    PartKind.drawerBack => 'Trasera de cajón',
    PartKind.drawerBottom => 'Fondo de cajón',
    PartKind.rail => 'Larguero',
    PartKind.plinth => 'Zócalo',
    PartKind.desktop => 'Tablero',
    PartKind.leg => 'Pata',
    PartKind.apron => 'Faldón',
    PartKind.other => 'Otra',
  };
}

/// Dirección de la veta dentro del plano de la pieza.
enum GrainDirection {
  none,
  alongLength,
  alongWidth;

  String get label => switch (this) {
    GrainDirection.none => '—',
    GrainDirection.alongLength => 'Largo',
    GrainDirection.alongWidth => 'Ancho',
  };
}

/// Lados de la pieza sobre los que se puede aplicar canto.
enum PanelEdge { longEdge1, longEdge2, shortEdge1, shortEdge2 }

/// Canto aplicado a un lado de la pieza.
class EdgeBanding {
  final String materialId;
  final double thicknessMm;

  const EdgeBanding({required this.materialId, this.thicknessMm = 0.4});
}

/// Una pieza física del mueble.
///
/// En esta fase todas las piezas son ortogonales. [size] son las dimensiones
/// en los ejes del mundo (X, Y, Z) y [cutSize] son las medidas de corte
/// (largo, ancho, espesor). Ambas deben describir la misma caja; el validador
/// lo comprueba.
///
/// [position] es la esquina mínima de la pieza en coordenadas del mueble.
class Part {
  final String id;
  final String name;
  final PartKind kind;
  final Size3 size;
  final CutSize cutSize;
  final String materialId;
  final Vector3 position;
  final GrainDirection grain;
  final Map<PanelEdge, EdgeBanding> edgeBanding;
  final bool structural;

  /// Contorno de la pieza (rectángulo por defecto).
  final PartShape shape;

  const Part({
    required this.id,
    required this.name,
    required this.kind,
    required this.size,
    required this.cutSize,
    required this.materialId,
    required this.position,
    this.grain = GrainDirection.none,
    this.edgeBanding = const {},
    this.structural = true,
    this.shape = PartShape.rectangle,
  });

  Part copyWith({
    String? id,
    String? name,
    PartKind? kind,
    Size3? size,
    CutSize? cutSize,
    String? materialId,
    Vector3? position,
    GrainDirection? grain,
    Map<PanelEdge, EdgeBanding>? edgeBanding,
    bool? structural,
    PartShape? shape,
  }) => Part(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    size: size ?? this.size,
    cutSize: cutSize ?? this.cutSize,
    materialId: materialId ?? this.materialId,
    position: position ?? this.position,
    grain: grain ?? this.grain,
    edgeBanding: edgeBanding ?? this.edgeBanding,
    structural: structural ?? this.structural,
    shape: shape ?? this.shape,
  );

  Vector3 get center => Vector3(
    position.x + size.width / 2,
    position.y + size.height / 2,
    position.z + size.depth / 2,
  );

  double get cutAreaM2 =>
      shape.areaMm2(cutSize.length, cutSize.width) / 1000000;

  /// Longitud total de canto de esta pieza, en milímetros.
  double get bandingLengthMm {
    if (!shape.isRectangular) {
      return shape.perimeterMm(cutSize.length, cutSize.width);
    }
    var total = 0.0;
    for (final edge in edgeBanding.keys) {
      total += switch (edge) {
        PanelEdge.longEdge1 || PanelEdge.longEdge2 => cutSize.length,
        PanelEdge.shortEdge1 || PanelEdge.shortEdge2 => cutSize.width,
      };
    }
    return total;
  }

  /// Comprueba que [size] y [cutSize] representen la misma caja física.
  bool get hasConsistentDimensions {
    final worldDimensions = [size.width, size.height, size.depth]..sort();
    final cutDimensions = cutSize.sortedDimensions;
    for (var i = 0; i < 3; i++) {
      if ((worldDimensions[i] - cutDimensions[i]).abs() > defaultToleranceMm) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() => 'Part($id, $name, $size)';
}
