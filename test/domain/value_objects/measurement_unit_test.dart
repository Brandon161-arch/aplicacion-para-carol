import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/value_objects/measurement_unit.dart';

void main() {
  group('MeasurementUnit', () {
    test('convierte pulgadas a milímetros y conserva precisión', () {
      expect(MeasurementUnit.inch.toMillimeters(12.5), 317.5);
      expect(MeasurementUnit.inch.fromMillimeters(25.4), 1);
      expect(MeasurementUnit.inch.format(25.4), '1 in');
    });

    test('convierte centímetros y metros a milímetros', () {
      expect(MeasurementUnit.centimeter.toMillimeters(80), 800);
      expect(MeasurementUnit.meter.toMillimeters(1.2), 1200);
      expect(MeasurementUnit.centimeter.format(800), '80 cm');
      expect(MeasurementUnit.meter.format(1200), '1,2 m');
    });
  });
}
