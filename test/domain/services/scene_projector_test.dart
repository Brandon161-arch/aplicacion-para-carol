import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
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
  });
}
