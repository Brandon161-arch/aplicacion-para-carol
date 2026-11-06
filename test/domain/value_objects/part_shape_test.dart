import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/value_objects/part_shape.dart';

void main() {
  test('el círculo conserva área y perímetro aproximados', () {
    const shape = PartShape(kind: PartShapeKind.circle);
    const diameter = 1000.0;
    const expectedArea = math.pi * 500 * 500;
    final area = shape.areaMm2(diameter, diameter);
    final perimeter = shape.perimeterMm(diameter, diameter);

    expect(area, closeTo(expectedArea, expectedArea * 0.01));
    expect(perimeter, closeTo(math.pi * diameter, 5));
    expect(shape.outlineFor(diameter, diameter).length, greaterThan(20));
  });

  test('la elipse se mantiene dentro de su caja', () {
    const shape = PartShape(kind: PartShapeKind.ellipse);
    final points = shape.outlineFor(1200, 600);
    for (final point in points) {
      expect(point.x, inInclusiveRange(0, 1200));
      expect(point.y, inInclusiveRange(0, 600));
    }
    final area = shape.areaMm2(1200, 600);
    expect(area, closeTo(math.pi * 600 * 300, math.pi * 600 * 300 * 0.01));
  });

  test('el rectángulo redondeado respeta el radio', () {
    const shape = PartShape(
      kind: PartShapeKind.roundedRectangle,
      cornerRadiusMm: 80,
    );
    final points = shape.outlineFor(800, 400);
    expect(points.length, greaterThan(20));
    for (final point in points) {
      expect(point.x, inInclusiveRange(0, 800));
      expect(point.y, inInclusiveRange(0, 400));
    }
    expect(shape.areaMm2(800, 400), lessThan(800 * 400));
  });

  test('el polígono usa la cantidad de lados pedida', () {
    const shape = PartShape(kind: PartShapeKind.polygon, sides: 6);
    final points = shape.outlineFor(1000, 1000);
    expect(points.length, 6);
  });

  test('la forma sobrevive a JSON', () {
    const shape = PartShape(
      kind: PartShapeKind.polygon,
      sides: 8,
      cornerRadiusMm: 60,
    );
    final restored = PartShape.fromJson(shape.toJson());
    expect(restored, shape);
  });
}
