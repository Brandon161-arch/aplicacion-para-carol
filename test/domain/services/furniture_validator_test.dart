import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/services/furniture_validator.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';

void main() {
  const validator = FurnitureValidator();

  List<ValidationIssue> errors(List<ValidationIssue> issues) => issues
      .where((issue) => issue.severity == ValidationSeverity.error)
      .toList();

  group('FurnitureValidator', () {
    test('el mueble de ejemplo es válido', () {
      final issues = validator.validate(sampleCabinetSpec);
      expect(errors(issues), isEmpty);
    });

    test('rechaza un ancho demasiado pequeño', () {
      final issues = validator.validate(
        sampleCabinetSpec.copyWith(
          overallSize: const Size3(width: 200, height: 750, depth: 450),
        ),
      );

      expect(errors(issues).any((issue) => issue.field == 'width'), isTrue);
    });

    test('rechaza un cajón que deja sin espacio a las puertas', () {
      final issues = validator.validate(
        sampleCabinetSpec.copyWith(drawerHeightMm: 700),
      );

      expect(
        errors(issues).any((issue) => issue.field == 'drawerHeight'),
        isTrue,
      );
    });

    test('rechaza espesores fuera de rango', () {
      final issues = validator.validate(
        sampleCabinetSpec.copyWith(
          settings: sampleCabinetSpec.settings.copyWith(panelThicknessMm: 3),
        ),
      );

      expect(errors(issues).any((issue) => issue.field == 'thickness'), isTrue);
    });

    test('rechaza una cantidad de estantes fuera de rango', () {
      final issues = validator.validate(
        sampleCabinetSpec.copyWith(shelfCount: 20),
      );

      expect(
        errors(issues).any((issue) => issue.field == 'shelfCount'),
        isTrue,
      );
    });

    test('avisa cuando no hay exactamente dos puertas', () {
      final issues = validator.validate(
        sampleCabinetSpec.copyWith(doorCount: 1),
      );

      expect(
        issues.any(
          (issue) =>
              issue.field == 'doorCount' &&
              issue.severity == ValidationSeverity.warning,
        ),
        isTrue,
      );
    });
  });
}
