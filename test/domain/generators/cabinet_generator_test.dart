import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/mechanism.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';

void main() {
  const generator = CabinetDoorsDrawerGenerator();

  Furniture generate(CabinetSpec spec) =>
      generator.generate(spec: spec, catalog: sampleMaterialCatalog);

  group('CabinetDoorsDrawerGenerator', () {
    test('genera las 16 piezas del mueble de ejemplo', () {
      final furniture = generate(sampleCabinetSpec);

      expect(furniture.parts.length, 16);
      expect(furniture.parts.map((part) => part.id).toSet().length, 16);
      expect(furniture.overallSize.width, 1000);
      expect(furniture.overallSize.height, 750);
      expect(furniture.overallSize.depth, 450);
    });

    test('cada pieza tiene medidas de corte coherentes con su caja', () {
      final furniture = generate(sampleCabinetSpec);

      for (final part in furniture.parts) {
        expect(
          part.hasConsistentDimensions,
          isTrue,
          reason: '${part.name} (${part.id}) no es coherente',
        );
      }
    });

    test('ninguna pieza queda fuera del volumen general', () {
      final furniture = generate(sampleCabinetSpec);
      const tolerance = 0.01;

      for (final part in furniture.parts) {
        expect(part.position.x, greaterThanOrEqualTo(-tolerance));
        expect(part.position.y, greaterThanOrEqualTo(-tolerance));
        expect(part.position.z, greaterThanOrEqualTo(-tolerance));
        expect(
          part.position.x + part.size.width,
          lessThanOrEqualTo(furniture.overallSize.width + tolerance),
        );
        expect(
          part.position.y + part.size.height,
          lessThanOrEqualTo(furniture.overallSize.height + tolerance),
        );
        expect(
          part.position.z + part.size.depth,
          lessThanOrEqualTo(furniture.overallSize.depth + tolerance),
        );
      }
    });

    test('todas las uniones apuntan a piezas existentes', () {
      final furniture = generate(sampleCabinetSpec);
      final ids = furniture.parts.map((part) => part.id).toSet();

      expect(furniture.joints, isNotEmpty);
      for (final joint in furniture.joints) {
        expect(ids, contains(joint.partAId));
        expect(ids, contains(joint.partBId));
        expect(joint.count, greaterThan(0));
      }
    });

    test('genera dos puertas y un cajón con mecanismos válidos', () {
      final furniture = generate(sampleCabinetSpec);
      final ids = furniture.parts.map((part) => part.id).toSet();
      final doors = furniture.partsOfKind(PartKind.door).toList();
      final hinged = furniture.mechanisms
          .whereType<HingedDoorMechanism>()
          .toList();
      final drawers = furniture.mechanisms
          .whereType<DrawerMechanism>()
          .toList();

      expect(doors.length, 2);
      expect(hinged.length, 2);
      expect(hinged.first.hingeSide, HingeSide.left);
      expect(hinged.last.hingeSide, HingeSide.right);
      expect(drawers.length, 1);
      expect(drawers.single.travelMm, 400);
      for (final mechanism in furniture.mechanisms) {
        for (final partId in mechanism.partIds) {
          expect(ids, contains(partId));
        }
      }
      expect(furniture.partsOfKind(PartKind.drawerFront).length, 1);
      expect(furniture.partsOfKind(PartKind.drawerSide).length, 2);
      expect(furniture.partsOfKind(PartKind.drawerBack).length, 1);
      expect(furniture.partsOfKind(PartKind.drawerBottom).length, 1);
    });

    test('respeta las medidas de puertas y cajón del ejemplo', () {
      final furniture = generate(sampleCabinetSpec);
      final door = furniture.partsOfKind(PartKind.door).first;
      final drawerFront = furniture.partsOfKind(PartKind.drawerFront).single;

      expect(door.cutSize.length, closeTo(448, 0.001));
      expect(door.cutSize.width, closeTo(479, 0.001));
      expect(door.cutSize.thickness, 18);
      expect(drawerFront.cutSize.length, closeTo(960, 0.001));
      expect(drawerFront.cutSize.width, closeTo(180, 0.001));
    });

    test('cambiar el ancho recalcula las puertas', () {
      final wide = generate(
        sampleCabinetSpec.copyWith(
          overallSize: const Size3(width: 1200, height: 750, depth: 450),
        ),
      );
      final door = wide.partsOfKind(PartKind.door).first;

      // (1200 - 2*18 - 3*2) / 2 = 579
      expect(door.cutSize.width, closeTo(579, 0.001));
      expect(wide.partsOfKind(PartKind.door).length, 2);
    });

    test('cambiar el alto recalcula las puertas', () {
      final tall = generate(
        sampleCabinetSpec.copyWith(
          overallSize: const Size3(width: 1000, height: 900, depth: 450),
        ),
      );
      final door = tall.partsOfKind(PartKind.door).first;

      // 900 - 180 - 60 - 3*18 - 4*2 = 598
      expect(door.cutSize.length, closeTo(598, 0.001));
    });

    test('cambiar la cantidad de estantes cambia el número de piezas', () {
      final withFourShelves = generate(
        sampleCabinetSpec.copyWith(shelfCount: 4),
      );

      expect(withFourShelves.partsOfKind(PartKind.shelf).length, 4);
      expect(withFourShelves.parts.length, 18);
    });

    test('asigna el material correcto a fondo y cajón', () {
      final furniture = generate(sampleCabinetSpec);
      final back = furniture.partsOfKind(PartKind.backPanel).single;
      final drawerSides = furniture.partsOfKind(PartKind.drawerSide).toList();
      final drawerBottom = furniture.partsOfKind(PartKind.drawerBottom).single;

      expect(back.materialId, 'mdf_5');
      expect(drawerBottom.materialId, 'mdf_5');
      expect(drawerSides.every((part) => part.materialId == 'mdf_15'), isTrue);
    });
  });
}
