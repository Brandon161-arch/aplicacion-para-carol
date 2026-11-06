import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/services/rendering/orbit_camera.dart';
import 'package:mueble_cad/domain/services/rendering/scene_projector.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/part_shape.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

void main() {
  const furniture = Furniture(
    id: 'round',
    name: 'Mesa redonda',
    type: FurnitureType.table,
    overallSize: Size3(width: 1200, height: 750, depth: 1200),
    settings: ConstructionSettings(),
    parts: [
      Part(
        id: 'round_top',
        name: 'Tapa redonda',
        kind: PartKind.desktop,
        size: Size3(width: 1200, height: 18, depth: 1200),
        cutSize: CutSize(length: 1200, width: 1200, thickness: 18),
        materialId: 'oak_18',
        position: Vector3(0, 732, 0),
        shape: PartShape(kind: PartShapeKind.circle),
      ),
    ],
  );

  const camera = OrbitCamera(
    yaw: 0.62,
    pitch: 0.34,
    distance: 2400,
    target: Vector3(600, 375, 600),
  );

  test('proyecta la tapa circular como polígono, no como caja', () {
    final result = const SceneProjector().project(
      furniture: furniture,
      camera: camera,
      viewportWidth: 800,
      viewportHeight: 600,
    );

    expect(result.faces, isNotEmpty);
    expect(
      result.faces.any((face) => face.points.length > 4),
      isTrue,
      reason: 'La cara superior redonda debe tener muchos vértices.',
    );
    for (final face in result.faces) {
      for (final point in face.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
    }
  });

  test('se puede seleccionar la pieza circular en el centro', () {
    final topCenter = const SceneProjector().projectPoint(
      point: const Vector3(600, 741, 600),
      camera: camera,
      viewportWidth: 800,
      viewportHeight: 600,
    );
    expect(topCenter, isNotNull);
    final picked = const SceneProjector().pickPart(
      furniture: furniture,
      camera: camera,
      viewportWidth: 800,
      viewportHeight: 600,
      screenX: topCenter!.x,
      screenY: topCenter.y,
    );
    expect(picked, 'round_top');
  });
}
