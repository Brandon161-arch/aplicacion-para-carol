import '../entities/construction_settings.dart';
import '../entities/furniture.dart';
import '../entities/furniture_spec.dart';
import '../entities/part.dart';
import '../value_objects/cut_size.dart';
import '../value_objects/size3.dart';
import '../value_objects/vector3.dart';

class GeometricTemplate {
  final String id;
  final String name;
  final String description;
  final Furniture furniture;

  const GeometricTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.furniture,
  });
}

/// Plantillas de muebles no rectangulares, armadas con paneles rectangulares.
///
/// Las formas L, U, T y escalonada son construibles con tableros rectos.
/// Las curvas quedan fuera de esta fase porque el modelo aún es de cajas.
abstract final class GeometricTemplates {
  static const double _thickness = 18;
  static const double _legSize = 45;
  static const String _materialId = 'mdf_18';

  static List<GeometricTemplate> all() => [
    _rectangular(),
    _lShape(),
    _uShape(),
    _tShape(),
    _corner(),
    _staggered(),
  ];

  static GeometricTemplate _rectangular() {
    const width = 1200.0;
    const height = 750.0;
    const depth = 500.0;
    final parts = <Part>[
      _panel('Base', PartKind.bottomPanel, 0, 0, 0, width, depth),
      _panel(
        'Tapa',
        PartKind.topPanel,
        0,
        height - _thickness,
        0,
        width,
        depth,
      ),
      _vertical('Lateral izquierdo', 0, 0, 0, height, depth),
      _vertical('Lateral derecho', width - _thickness, 0, 0, height, depth),
      _panel(
        'Estante',
        PartKind.shelf,
        _thickness,
        420,
        20,
        width - 2 * _thickness,
        depth - 20,
      ),
      _back('Fondo', width, height, depth),
    ];
    return _template(
      'rectangular',
      'Rectángulo',
      'Módulo clásico con estante y fondo.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _lShape() {
    const width = 1800.0;
    const depth = 1400.0;
    const height = 750.0;
    const mainDepth = 700.0;
    const wingWidth = 700.0;
    final parts = <Part>[
      _tableTop('Tablero principal', 0, 0, width, mainDepth),
      _tableTop(
        'Tablero lateral',
        width - wingWidth,
        mainDepth,
        wingWidth,
        depth - mainDepth,
      ),
      _leg('Pata 1', 60, 60),
      _leg('Pata 2', width - _legSize - 60, 60),
      _leg('Pata 3', width - _legSize - 60, mainDepth - _legSize - 40),
      _leg('Pata 4', width - _legSize - 60, depth - _legSize - 60),
      _leg('Pata 5', width - wingWidth + 60, depth - _legSize - 60),
    ];
    return _template(
      'l_shape',
      'Forma L',
      'Escritorio o mesón en L con ala lateral.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _uShape() {
    const width = 2200.0;
    const depth = 1600.0;
    const height = 750.0;
    const mainDepth = 700.0;
    const wingWidth = 600.0;
    final parts = <Part>[
      _tableTop('Tablero frontal', 0, 0, width, mainDepth),
      _tableTop('Ala izquierda', 0, mainDepth, wingWidth, depth - mainDepth),
      _tableTop(
        'Ala derecha',
        width - wingWidth,
        mainDepth,
        wingWidth,
        depth - mainDepth,
      ),
      _leg('Pata frontal izq.', 60, 60),
      _leg('Pata frontal der.', width - _legSize - 60, 60),
      _leg('Pata trasera izq.', 60, depth - _legSize - 60),
      _leg('Pata trasera der.', width - _legSize - 60, depth - _legSize - 60),
      _leg(
        'Pata ala izq.',
        wingWidth - _legSize - 40,
        mainDepth - _legSize - 40,
      ),
      _leg('Pata ala der.', width - wingWidth + 40, mainDepth - _legSize - 40),
    ];
    return _template(
      'u_shape',
      'Forma U',
      'Mesón en U para cocina o estudio.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _tShape() {
    const width = 2000.0;
    const depth = 1500.0;
    const height = 750.0;
    const mainDepth = 650.0;
    const spineWidth = 700.0;
    final spineX = (width - spineWidth) / 2;
    final parts = <Part>[
      _tableTop('Tablero transversal', 0, 0, width, mainDepth),
      _tableTop(
        'Columna central',
        spineX,
        mainDepth,
        spineWidth,
        depth - mainDepth,
      ),
      _leg('Pata izq.', 60, 60),
      _leg('Pata der.', width - _legSize - 60, 60),
      _leg('Pata central izq.', spineX + 40, depth - _legSize - 60),
      _leg(
        'Pata central der.',
        spineX + spineWidth - _legSize - 40,
        depth - _legSize - 60,
      ),
    ];
    return _template(
      't_shape',
      'Forma T',
      'Mesa en T con columna central.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _corner() {
    const width = 900.0;
    const depth = 900.0;
    const height = 1800.0;
    const wing = 420.0;
    final parts = <Part>[
      _vertical('Lateral izquierdo', 0, 0, 0, height, depth),
      _vertical('Lateral derecho', width - _thickness, 0, 0, height, wing),
      _panel(
        'Tapa',
        PartKind.topPanel,
        0,
        height - _thickness,
        0,
        width,
        depth,
      ),
      _panel('Base', PartKind.bottomPanel, 0, 0, 0, width, depth),
      _back('Fondo', width, height, depth),
      for (var index = 1; index <= 3; index++)
        _panel(
          'Estante ${index + 1}',
          PartKind.shelf,
          _thickness,
          index * (height - _thickness) / 4,
          20,
          width - 2 * _thickness,
          wing - 40,
        ),
    ];
    return _template(
      'corner',
      'Esquinero',
      'Estantería de esquina con estantes escalonados.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _staggered() {
    const width = 1800.0;
    const depth = 420.0;
    const height = 1600.0;
    const moduleWidth = 600.0;
    final parts = <Part>[
      for (var index = 0; index < 3; index++)
        _vertical(
          'Lateral ${index + 1}',
          index * moduleWidth,
          0,
          0,
          index == 1 ? height : height - 300,
          depth,
        ),
      _vertical('Lateral final', width - _thickness, 0, 0, height, depth),
      for (var index = 0; index < 3; index++) ...[
        _panel(
          'Base ${index + 1}',
          PartKind.bottomPanel,
          index * moduleWidth + _thickness,
          0,
          0,
          moduleWidth - _thickness,
          depth,
        ),
        _panel(
          'Tapa ${index + 1}',
          PartKind.topPanel,
          index * moduleWidth + _thickness,
          (index == 1 ? height : height - 300) - _thickness,
          0,
          moduleWidth - _thickness,
          depth,
        ),
      ],
    ];
    return _template(
      'staggered',
      'Escalonada',
      'Tres módulos de alturas distintas unidos.',
      width,
      height,
      depth,
      parts,
    );
  }

  static GeometricTemplate _template(
    String id,
    String name,
    String description,
    double width,
    double height,
    double depth,
    List<Part> parts,
  ) => GeometricTemplate(
    id: id,
    name: name,
    description: description,
    furniture: Furniture(
      id: 'template_$id',
      name: name,
      type: FurnitureType.custom,
      overallSize: Size3(width: width, height: height, depth: depth),
      settings: const ConstructionSettings(panelThicknessMm: _thickness),
      parts: parts,
    ),
  );

  static Part _panel(
    String name,
    PartKind kind,
    double x,
    double y,
    double z,
    double width,
    double depth,
  ) => Part(
    id: '${name.toLowerCase().replaceAll(' ', '_')}_${x.round()}_${y.round()}',
    name: name,
    kind: kind,
    size: Size3(width: width, height: _thickness, depth: depth),
    cutSize: CutSize(length: width, width: depth, thickness: _thickness),
    materialId: _materialId,
    position: Vector3(x, y, z),
    grain: GrainDirection.alongLength,
    structural: true,
  );

  static Part _vertical(
    String name,
    double x,
    double y,
    double z,
    double height,
    double depth,
  ) => Part(
    id: '${name.toLowerCase().replaceAll(' ', '_')}_${x.round()}',
    name: name,
    kind: PartKind.sidePanel,
    size: Size3(width: _thickness, height: height, depth: depth),
    cutSize: CutSize(length: height, width: depth, thickness: _thickness),
    materialId: _materialId,
    position: Vector3(x, y, z),
    grain: GrainDirection.alongLength,
    structural: true,
  );

  static Part _tableTop(
    String name,
    double x,
    double z,
    double width,
    double depth,
  ) => Part(
    id: '${name.toLowerCase().replaceAll(' ', '_')}_${x.round()}_${z.round()}',
    name: name,
    kind: PartKind.desktop,
    size: Size3(width: width, height: _thickness, depth: depth),
    cutSize: CutSize(length: width, width: depth, thickness: _thickness),
    materialId: _materialId,
    position: Vector3(x, 750 - _thickness, z),
    grain: GrainDirection.alongLength,
    structural: true,
  );

  static Part _leg(String name, double x, double z) => Part(
    id: '${name.toLowerCase().replaceAll(' ', '_')}_${x.round()}_${z.round()}',
    name: name,
    kind: PartKind.leg,
    size: Size3(
      width: _legSize,
      height: _thickness == 0 ? 0 : _legHeight,
      depth: _legSize,
    ),
    cutSize: CutSize(length: _legHeight, width: _legSize, thickness: _legSize),
    materialId: 'pine_18',
    position: Vector3(x, 0, z),
    grain: GrainDirection.alongLength,
    structural: true,
  );

  static const double _legHeight = 750 - _thickness;

  static Part _back(String name, double width, double height, double depth) =>
      Part(
        id: 'fondo_${width.round()}',
        name: name,
        kind: PartKind.backPanel,
        size: Size3(
          width: width - 2 * _thickness,
          height: height - 2 * _thickness,
          depth: 5,
        ),
        cutSize: CutSize(
          length: width - 2 * _thickness,
          width: height - 2 * _thickness,
          thickness: 5,
        ),
        materialId: 'mdf_5',
        position: Vector3(_thickness, _thickness, depth - 5),
        structural: false,
      );
}
