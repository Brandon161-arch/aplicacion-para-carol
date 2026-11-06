import 'dart:math' as math;

enum PartShapeKind {
  rectangle,
  circle,
  ellipse,
  roundedRectangle,
  polygon;

  String get label => switch (this) {
    PartShapeKind.rectangle => 'Rectángulo',
    PartShapeKind.circle => 'Círculo',
    PartShapeKind.ellipse => 'Elipse / óvalo',
    PartShapeKind.roundedRectangle => 'Rectángulo redondeado',
    PartShapeKind.polygon => 'Polígono regular',
  };
}

class ShapePoint {
  final double x;
  final double y;

  const ShapePoint(this.x, this.y);
}

/// Contorno de una pieza dentro de su caja de corte.
///
/// [cornerRadiusMm] aplica solo a rectángulos redondeados y [sides] a
/// polígonos regulares. El contorno se calcula en milímetros y se recorta a
/// la caja [widthMm] x [depthMm].
class PartShape {
  final PartShapeKind kind;
  final double cornerRadiusMm;
  final int sides;

  const PartShape({
    this.kind = PartShapeKind.rectangle,
    this.cornerRadiusMm = 40,
    this.sides = 6,
  });

  static const PartShape rectangle = PartShape();

  bool get isRectangular => kind == PartShapeKind.rectangle;

  bool get isCircular =>
      kind == PartShapeKind.circle || kind == PartShapeKind.ellipse;

  PartShape copyWith({
    PartShapeKind? kind,
    double? cornerRadiusMm,
    int? sides,
  }) => PartShape(
    kind: kind ?? this.kind,
    cornerRadiusMm: cornerRadiusMm ?? this.cornerRadiusMm,
    sides: sides ?? this.sides,
  );

  /// Contorno cerrado en mm, en sentido horario, sin repetir el primer punto.
  List<ShapePoint> outlineFor(double widthMm, double depthMm) {
    final width = math.max(1.0, widthMm);
    final depth = math.max(1.0, depthMm);
    switch (kind) {
      case PartShapeKind.rectangle:
        return [
          ShapePoint(0, 0),
          ShapePoint(width, 0),
          ShapePoint(width, depth),
          ShapePoint(0, depth),
        ];
      case PartShapeKind.circle:
      case PartShapeKind.ellipse:
        const segments = 48;
        final radiusX = width / 2;
        final radiusY = depth / 2;
        return [
          for (var index = 0; index < segments; index++)
            ShapePoint(
              radiusX + radiusX * math.cos(index * 2 * math.pi / segments),
              radiusY + radiusY * math.sin(index * 2 * math.pi / segments),
            ),
        ];
      case PartShapeKind.roundedRectangle:
        final radius = cornerRadiusMm
            .clamp(0.0, math.min(width, depth) / 2)
            .toDouble();
        if (radius <= 0.5) return rectangle.outlineFor(width, depth);
        const segmentsPerCorner = 8;
        final points = <ShapePoint>[];
        final corners = [
          (width - radius, radius, -math.pi / 2),
          (width - radius, depth - radius, 0.0),
          (radius, depth - radius, math.pi / 2),
          (radius, radius, math.pi),
        ];
        for (final corner in corners) {
          for (var step = 0; step <= segmentsPerCorner; step++) {
            final angle = corner.$3 + (math.pi / 2) * step / segmentsPerCorner;
            points.add(
              ShapePoint(
                corner.$1 + radius * math.cos(angle),
                corner.$2 + radius * math.sin(angle),
              ),
            );
          }
        }
        return points;
      case PartShapeKind.polygon:
        final vertices = math.max(3, math.min(16, sides));
        final radiusX = width / 2;
        final radiusY = depth / 2;
        final offset = -math.pi / 2 + math.pi / vertices;
        return [
          for (var index = 0; index < vertices; index++)
            ShapePoint(
              radiusX +
                  radiusX * math.cos(offset + index * 2 * math.pi / vertices),
              radiusY +
                  radiusY * math.sin(offset + index * 2 * math.pi / vertices),
            ),
        ];
    }
  }

  double areaMm2(double widthMm, double depthMm) {
    if (isRectangular) return widthMm * depthMm;
    final points = outlineFor(widthMm, depthMm);
    var sum = 0.0;
    for (var index = 0; index < points.length; index++) {
      final next = points[(index + 1) % points.length];
      sum += points[index].x * next.y - next.x * points[index].y;
    }
    return (sum / 2).abs();
  }

  double perimeterMm(double widthMm, double depthMm) {
    final points = outlineFor(widthMm, depthMm);
    var total = 0.0;
    for (var index = 0; index < points.length; index++) {
      final next = points[(index + 1) % points.length];
      final dx = next.x - points[index].x;
      final dy = next.y - points[index].y;
      total += math.sqrt(dx * dx + dy * dy);
    }
    return total;
  }

  String get description => switch (kind) {
    PartShapeKind.rectangle => 'Rectángulo',
    PartShapeKind.circle => 'Círculo',
    PartShapeKind.ellipse => 'Elipse',
    PartShapeKind.roundedRectangle =>
      'Rectángulo redondeado (radio ${cornerRadiusMm.round()} mm)',
    PartShapeKind.polygon => 'Polígono de $sides lados',
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'cornerRadiusMm': cornerRadiusMm,
    'sides': sides,
  };

  factory PartShape.fromJson(Map<String, dynamic> json) => PartShape(
    kind: PartShapeKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => PartShapeKind.rectangle,
    ),
    cornerRadiusMm: (json['cornerRadiusMm'] as num?)?.toDouble() ?? 40,
    sides: (json['sides'] as num?)?.toInt() ?? 6,
  );

  @override
  bool operator ==(Object other) =>
      other is PartShape &&
      other.kind == kind &&
      (other.cornerRadiusMm - cornerRadiusMm).abs() < 0.01 &&
      other.sides == sides;

  @override
  int get hashCode => Object.hash(kind, cornerRadiusMm.round(), sides);

  @override
  String toString() => description;
}
