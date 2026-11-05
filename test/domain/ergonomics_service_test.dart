import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/services/ergonomics_service.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';

void main() {
  group('ErgonomicsService Tests', () {
    const service = ErgonomicsService();

    test('Identifica mueble de cocina/gabinete bajo estándar como óptimo', () {
      final furniture = Furniture(
        id: 'test_cab',
        name: 'Gabinete Bajo',
        type: FurnitureType.cabinet,
        overallSize: const Size3(width: 800, height: 900, depth: 600),
        settings: const ConstructionSettings(),
        parts: const [],
      );

      const profile = AntropometricProfile(userHeightCm: 170); // codo a 1071mm, ideal ~950mm
      final report = service.evaluate(furniture, profile);

      expect(report.alerts, isNotEmpty);
      expect(report.alerts.any((a) => a.dimensionName.contains('Altura')), isTrue);
    });

    test('Alerta sobre mesa demasiado alta para percentiles estándar', () {
      final furniture = Furniture(
        id: 'test_table',
        name: 'Mesa Alta',
        type: FurnitureType.table,
        overallSize: const Size3(width: 1400, height: 860, depth: 800), // 860 mm es muy alta para comer
        settings: const ConstructionSettings(),
        parts: const [],
      );

      const profile = AntropometricProfile(userHeightCm: 170);
      final report = service.evaluate(furniture, profile);

      expect(report.overallStatus, equals(ErgonomicStatus.hazard));
      expect(report.alerts.any((a) => a.explanation.contains('antebrazos y hombros')), isTrue);
    });
  });
}
