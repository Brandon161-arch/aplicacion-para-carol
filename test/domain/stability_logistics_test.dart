import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/material.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/services/industrial_exporter.dart';
import 'package:mueble_cad/domain/services/stability_logistics_calculator.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

void main() {
  group('Stability and Logistics Tests', () {
    const calc = StabilityLogisticsCalculator();
    final catalog = MaterialCatalog([
      Material(
        id: 'mel_18',
        name: 'Melamina 18mm',
        category: MaterialCategory.particleboard,
        thicknessesMm: const [18],
        priceCents: 150000,
        priceUnit: PriceUnit.perSheet,
      ),
    ]);

    test('Calcula masa y centro de gravedad correctamente', () {
      final part = Part(
        id: 'top',
        name: 'Tapa',
        kind: PartKind.topPanel,
        size: const Size3(width: 1000, height: 18, depth: 500),
        cutSize: const CutSize(length: 1000, width: 500, thickness: 18),
        materialId: 'mel_18',
        position: const Vector3(0, 900, 0),
        grain: GrainDirection.alongLength,
        edgeBanding: const {},
      );

      final furniture = Furniture(
        id: 'm1',
        name: 'Mueble Test',
        type: FurnitureType.cabinet,
        overallSize: const Size3(width: 1000, height: 918, depth: 500),
        settings: const ConstructionSettings(),
        parts: [part],
      );

      final stability = calc.calculateStability(furniture, catalog);
      expect(stability.totalMassKg, greaterThan(0));
      expect(stability.centerOfGravityMm.y, closeTo(909, 10));

      final packing = calc.calculatePacking(furniture, catalog);
      expect(packing.totalBoxCount, equals(1));
      expect(packing.packages.first.weightKg, greaterThan(0));
    });

    test('Exporta DXF y G-Code con sintaxis válida', () {
      const exporter = IndustrialExporter();
      final part = Part(
        id: 'p1',
        name: 'Lateral',
        kind: PartKind.sidePanel,
        size: const Size3(width: 18, height: 800, depth: 400),
        cutSize: const CutSize(length: 800, width: 400, thickness: 18),
        materialId: 'mel_18',
        position: const Vector3(0, 0, 0),
        grain: GrainDirection.alongLength,
        edgeBanding: const {},
      );

      final furniture = Furniture(
        id: 'm1',
        name: 'Mueble Test',
        type: FurnitureType.cabinet,
        overallSize: const Size3(width: 800, height: 800, depth: 400),
        settings: const ConstructionSettings(),
        parts: [part],
      );

      final dxf = exporter.exportToDxf(furniture);
      expect(dxf.contains('SECTION'), isTrue);
      expect(dxf.contains('OUTLINE'), isTrue);
      expect(dxf.contains('EOF'), isTrue);

      final gcode = exporter.exportToGCode(furniture);
      expect(gcode.contains('G21'), isTrue);
      expect(gcode.contains('M03'), isTrue);
      expect(gcode.contains('M30'), isTrue);

      final csv = exporter.exportToCutListCsv(furniture);
      expect(csv.contains('Lateral'), isTrue);
      expect(csv.contains('800'), isTrue);
    });
  });
}
