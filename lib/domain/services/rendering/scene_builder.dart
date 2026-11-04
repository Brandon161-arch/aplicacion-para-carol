import '../../entities/furniture.dart';
import '../../entities/part.dart';
import '../../value_objects/vector3.dart';

/// Caja de una pieza preparada para el render.
///
/// Los ocho vértices se guardan en coordenadas del mueble. Más adelante el
/// explosionado y la animación de puertas/cajones reutilizarán estos datos.
class ScenePart {
  final Part part;
  final List<Vector3> corners;
  final Vector3 center;

  const ScenePart({
    required this.part,
    required this.corners,
    required this.center,
  });

  factory ScenePart.fromPart(Part part) {
    final x0 = part.position.x;
    final y0 = part.position.y;
    final z0 = part.position.z;
    final x1 = x0 + part.size.width;
    final y1 = y0 + part.size.height;
    final z1 = z0 + part.size.depth;

    return ScenePart(
      part: part,
      corners: [
        Vector3(x0, y0, z0),
        Vector3(x1, y0, z0),
        Vector3(x1, y1, z0),
        Vector3(x0, y1, z0),
        Vector3(x0, y0, z1),
        Vector3(x1, y0, z1),
        Vector3(x1, y1, z1),
        Vector3(x0, y1, z1),
      ],
      center: Vector3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
    );
  }
}

class SceneBuilder {
  const SceneBuilder();

  List<ScenePart> build(Furniture furniture) =>
      furniture.parts.map(ScenePart.fromPart).toList(growable: false);
}
