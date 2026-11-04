import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/core/constants/units.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

void main() {
  group('Vector3', () {
    test('suma, resta y producto punto', () {
      const a = Vector3(1, 2, 3);
      const b = Vector3(4, 5, 6);

      expect(a + b, const Vector3(5, 7, 9));
      expect(b - a, const Vector3(3, 3, 3));
      expect(a.dot(b), 32);
    });

    test('producto cruz y normalización', () {
      const x = Vector3(1, 0, 0);
      const y = Vector3(0, 1, 0);

      expect(x.cross(y), const Vector3(0, 0, 1));
      expect(const Vector3(0, 3, 4).normalized.z, closeTo(0.8, 0.0001));
    });
  });

  group('Size3', () {
    test('obtiene la dimensión mayor', () {
      const size = Size3(width: 1000, height: 750, depth: 450);
      expect(size.maxDimension, 1000);
    });
  });

  group('CutSize', () {
    test('calcula el área en metros cuadrados', () {
      const cut = CutSize(length: 750, width: 450, thickness: 18);
      expect(cut.areaM2, closeTo(0.3375, 0.000001));
    });
  });

  group('formato de unidades', () {
    test('redondea a una décima de milímetro', () {
      expect(roundMm(12.34), 12.3);
      expect(formatMm(1000), '1000');
      expect(formatMm(12.3), '12,3');
    });

    test('formatea metros cuadrados con coma decimal', () {
      expect(formatM2(4.659145), '4,659');
      expect(formatMeters(3.708), '3,71');
    });
  });
}
