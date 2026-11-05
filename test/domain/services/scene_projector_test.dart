import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/rendering/orbit_camera.dart';
import 'package:mueble_cad/domain/services/rendering/scene_projector.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

const _cube = Furniture(
  id: 'cube',
  name: 'Cubo de prueba',
  type: FurnitureType.cabinet,
  overallSize: Size3(width: 100, height: 100, depth: 100),
  settings: ConstructionSettings(),
  parts: [
    Part(
      id: 'cube_part',
      name: 'Cubo',
      kind: PartKind.sidePanel,
      size: Size3(width: 100, height: 100, depth: 100),
      cutSize: CutSize(length: 100, width: 100, thickness: 100),
      materialId: 'mdf_18',
      position: Vector3.zero,
    ),
  ],
);

void main() {
  const projector = SceneProjector();

  group('SceneProjector', () {
    test('la cámara frontal queda delante del mueble', () {
      const camera = OrbitCamera(
        yaw: 0,
        pitch: 0,
        distance: 500,
        target: Vector3(50, 50, 50),
      );

      expect(camera.position.x, closeTo(50, 0.001));
      expect(camera.position.y, closeTo(50, 0.001));
      expect(camera.position.z, closeTo(-450, 0.001));
    });

    test('proyecta el objetivo en el centro de la pantalla', () {
      const camera = OrbitCamera(
        yaw: 0.35,
        pitch: 0.3,
        distance: 500,
        target: Vector3(50, 50, 50),
      );
      final point = projector.projectPoint(
        point: const Vector3(50, 50, 50),
        camera: camera,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      expect(point, isNotNull);
      expect(point!.x, closeTo(400, 0.01));
      expect(point.y, closeTo(300, 0.01));
    });

    test('convierte el puntero al plano horizontal para mover piezas', () {
      const camera = OrbitCamera(
        yaw: 0.35,
        pitch: 0.3,
        distance: 500,
        target: Vector3(50, 50, 50),
      );
      final point = projector.screenToPlane(
        screenX: 400,
        screenY: 300,
        camera: camera,
        viewportWidth: 800,
        viewportHeight: 600,
        planeY: 50,
      );

      expect(point, isNotNull);
      expect(point!.x, closeTo(50, 0.01));
      expect(point.y, closeTo(50, 0.01));
      expect(point.z, closeTo(50, 0.01));
    });

    test('selecciona la pieza visible bajo el puntero', () {
      const camera = OrbitCamera(
        yaw: 0.35,
        pitch: 0.3,
        distance: 500,
        target: Vector3(50, 50, 50),
      );

      expect(
        projector.pickPart(
          furniture: _cube,
          camera: camera,
          viewportWidth: 800,
          viewportHeight: 600,
          screenX: 400,
          screenY: 300,
        ),
        'cube_part',
      );
      expect(
        projector.pickPart(
          furniture: _cube,
          camera: camera,
          viewportWidth: 800,
          viewportHeight: 600,
          screenX: 5,
          screenY: 5,
        ),
        isNull,
      );
    });

    test('solo devuelve caras visibles y ordenadas de lejos a cerca', () {
      const camera = OrbitCamera(
        yaw: 0.35,
        pitch: 0.3,
        distance: 500,
        target: Vector3(50, 50, 50),
      );
      final result = projector.project(
        furniture: _cube,
        camera: camera,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      expect(result.faces.length, 3);
      for (var index = 0; index < result.faces.length; index++) {
        final face = result.faces[index];
        expect(face.points.length, 4);
        for (final point in face.points) {
          expect(point.x.isFinite, isTrue);
          expect(point.y.isFinite, isTrue);
          expect(point.x, inInclusiveRange(0, 800));
          expect(point.y, inInclusiveRange(0, 600));
        }
        if (index > 0) {
          expect(
            result.faces[index - 1].depth,
            greaterThanOrEqualTo(face.depth),
          );
        }
      }
    });

    test('las sombras de las caras están normalizadas', () {
      const camera = OrbitCamera(
        yaw: 0.35,
        pitch: 0.3,
        distance: 500,
        target: Vector3(50, 50, 50),
      );
      final result = projector.project(
        furniture: _cube,
        camera: camera,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      for (final face in result.faces) {
        expect(face.shade, inInclusiveRange(0, 1));
      }
    });

    test('al ampliar el mueble crece su proyección sin auto-zoom', () {
      const generator = CabinetDoorsDrawerGenerator();
      final normal = generator.generate(
        spec: sampleCabinetSpec,
        catalog: sampleMaterialCatalog,
      );
      final wider = generator.generate(
        spec: sampleCabinetSpec.copyWith(
          overallSize: const Size3(width: 1200, height: 750, depth: 450),
        ),
        catalog: sampleMaterialCatalog,
      );

      ProjectionResult project(Furniture furniture) {
        final camera = OrbitCamera(
          yaw: 0.62,
          pitch: 0.34,
          distance: 2000,
          target: Vector3(
            furniture.overallSize.width / 2,
            furniture.overallSize.height / 2,
            furniture.overallSize.depth / 2,
          ),
        );
        return projector.project(
          furniture: furniture,
          camera: camera,
          viewportWidth: 800,
          viewportHeight: 600,
        );
      }

      double projectedWidth(ProjectionResult result) {
        final xs = result.faces
            .expand((face) => face.points)
            .map((point) => point.x)
            .toList();
        final minX = xs.reduce(math.min);
        final maxX = xs.reduce(math.max);
        return maxX - minX;
      }

      expect(
        projectedWidth(project(wider)),
        greaterThan(projectedWidth(project(normal))),
      );
    });
  });
}
