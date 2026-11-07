import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/hardware_price_seed.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/data/seeds/preset_furniture.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/hardware_item.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/hardware_calculator.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

void main() {
  const calculator = HardwareCalculator();
  final sampleFurniture = const CabinetDoorsDrawerGenerator().generate(
    spec: sampleCabinetSpec,
    catalog: sampleMaterialCatalog,
  );

  group('HardwareCalculator', () {
    test('cuenta tornillos, bisagras, correderas, tiradores y soportes', () {
      final requirements = calculator.calculate(
        sampleFurniture,
        sampleHardwarePrices,
      );

      int quantityOf(HardwareKind kind) => requirements
          .where((item) => item.kind == kind)
          .fold(0, (total, item) => total + item.quantity);

      expect(quantityOf(HardwareKind.confirmat), 29);
      expect(quantityOf(HardwareKind.nail), 28);
      expect(quantityOf(HardwareKind.dowel), 8);
      expect(quantityOf(HardwareKind.hinge), 4);
      expect(quantityOf(HardwareKind.drawerSlide), 2);
      expect(quantityOf(HardwareKind.shelfPin), 8);
      expect(quantityOf(HardwareKind.handle), 3);
      expect(quantityOf(HardwareKind.screw), 30);
    });

    test('indica las uniones y la ubicación de los mecanismos', () {
      final requirements = calculator.calculate(
        sampleFurniture,
        sampleHardwarePrices,
      );
      final confirmats = requirements.firstWhere(
        (item) => item.kind == HardwareKind.confirmat,
      );
      final hinges = requirements.firstWhere(
        (item) => item.kind == HardwareKind.hinge,
      );
      final slides = requirements.firstWhere(
        (item) => item.kind == HardwareKind.drawerSlide,
      );

      expect(
        confirmats.placements.any((item) => item.location.contains('Base')),
        isTrue,
      );
      expect(hinges.placements, hasLength(2));
      expect(hinges.placements.first.note, contains('superior'));
      expect(slides.placements.single.location, contains('cada lado'));
      expect(slides.placements.single.note, contains('fondo útil'));
    });

    test('cuenta un par de correderas por cada cajón de una cajonera', () {
      final chest = buildPresetFurniture().firstWhere(
        (preset) => preset.id == 'preset_cajonera',
      );
      final requirements = calculator.calculate(
        chest.furniture,
        sampleHardwarePrices,
      );
      final slides = requirements.firstWhere(
        (item) => item.kind == HardwareKind.drawerSlide,
      );
      final handles = requirements.firstWhere(
        (item) => item.kind == HardwareKind.handle,
      );

      expect(slides.quantity, 6);
      expect(handles.quantity, 3);
      expect(slides.placements, hasLength(3));
    });

    test('estima confirmats por contacto en un modelo creado a mano', () {
      const customFurniture = Furniture(
        id: 'custom_contact',
        name: 'Modelo manual',
        type: FurnitureType.custom,
        overallSize: Size3(width: 600, height: 600, depth: 300),
        settings: ConstructionSettings(),
        parts: [
          Part(
            id: 'side',
            name: 'Lateral',
            kind: PartKind.sidePanel,
            size: Size3(width: 18, height: 600, depth: 300),
            cutSize: CutSize(length: 600, width: 300, thickness: 18),
            materialId: 'mdf_18',
            position: Vector3.zero,
          ),
          Part(
            id: 'base',
            name: 'Base',
            kind: PartKind.bottomPanel,
            size: Size3(width: 564, height: 18, depth: 295),
            cutSize: CutSize(length: 564, width: 295, thickness: 18),
            materialId: 'mdf_18',
            position: Vector3(18, 0, 0),
          ),
        ],
      );

      final requirements = calculator.calculate(
        customFurniture,
        sampleHardwarePrices,
      );
      final confirmats = requirements.single;

      expect(confirmats.kind, HardwareKind.confirmat);
      expect(confirmats.quantity, 3);
      expect(confirmats.placements.single.location, 'Lateral izquierdo ? Base');
      expect(confirmats.placements.single.note, contains('inferida'));
    });
  });
}
