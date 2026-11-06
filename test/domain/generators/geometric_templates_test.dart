import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/generators/geometric_templates.dart';

void main() {
  final templates = GeometricTemplates.all();

  test('ofrece seis formas geométricas editables', () {
    expect(templates.length, 6);
    expect(
      templates.map((template) => template.id),
      containsAll([
        'rectangular',
        'l_shape',
        'u_shape',
        't_shape',
        'corner',
        'staggered',
      ]),
    );
  });

  test('todas las piezas están dentro del volumen y son válidas', () {
    for (final template in templates) {
      final furniture = template.furniture;
      expect(furniture.parts, isNotEmpty, reason: template.name);
      final ids = furniture.parts.map((part) => part.id).toSet();
      expect(ids.length, furniture.parts.length, reason: template.name);
      for (final part in furniture.parts) {
        expect(part.size.width, greaterThan(0), reason: template.name);
        expect(part.size.height, greaterThan(0), reason: template.name);
        expect(part.size.depth, greaterThan(0), reason: template.name);
        expect(part.position.x, greaterThanOrEqualTo(0), reason: template.name);
        expect(part.position.y, greaterThanOrEqualTo(0), reason: template.name);
        expect(part.position.z, greaterThanOrEqualTo(0), reason: template.name);
        expect(
          part.position.x + part.size.width,
          lessThanOrEqualTo(furniture.overallSize.width + 0.1),
          reason: '${template.name}: ${part.name} se sale en X',
        );
        expect(
          part.position.y + part.size.height,
          lessThanOrEqualTo(furniture.overallSize.height + 0.1),
          reason: '${template.name}: ${part.name} se sale en Y',
        );
        expect(
          part.position.z + part.size.depth,
          lessThanOrEqualTo(furniture.overallSize.depth + 0.1),
          reason: '${template.name}: ${part.name} se sale en Z',
        );
      }
    }
  });
}
