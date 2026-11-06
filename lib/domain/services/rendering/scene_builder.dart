import 'dart:math' as math;

import '../../entities/furniture.dart';
import '../../entities/mechanism.dart';
import '../../entities/part.dart';
import '../../value_objects/vector3.dart';

/// Caja de una pieza preparada para el render.
class ScenePart {
  final Part part;
  final List<Vector3> corners;
  final Vector3 center;

  const ScenePart({
    required this.part,
    required this.corners,
    required this.center,
  });

  factory ScenePart.fromPart(
    Part part, {
    Vector3? translation,
    double rotationAngleRad = 0.0,
    Vector3? rotationPivot,
    Vector3? explodeOffset,
  }) {
    final x0 = part.position.x;
    final y0 = part.position.y;
    final z0 = part.position.z;
    final x1 = x0 + part.size.width;
    final y1 = y0 + part.size.height;
    final z1 = z0 + part.size.depth;

    var rawCorners = [
      Vector3(x0, y0, z0),
      Vector3(x1, y0, z0),
      Vector3(x1, y1, z0),
      Vector3(x0, y1, z0),
      Vector3(x0, y0, z1),
      Vector3(x1, y0, z1),
      Vector3(x1, y1, z1),
      Vector3(x0, y1, z1),
    ];

    // Aplicar rotación sobre pivote si existe (para puertas abatibles)
    if (rotationAngleRad != 0.0 && rotationPivot != null) {
      final cosA = math.cos(rotationAngleRad);
      final sinA = math.sin(rotationAngleRad);
      final px = rotationPivot.x;
      final pz = rotationPivot.z;

      rawCorners = rawCorners.map((v) {
        final relX = v.x - px;
        final relZ = v.z - pz;
        // Rotación alrededor del eje vertical Y
        final rotX = relX * cosA - relZ * sinA;
        final rotZ = relX * sinA + relZ * cosA;
        return Vector3(rotX + px, v.y, rotZ + pz);
      }).toList();
    }

    // Aplicar traslación (para cajones que se abren)
    if (translation != null) {
      rawCorners = rawCorners
          .map(
            (v) => Vector3(
              v.x + translation.x,
              v.y + translation.y,
              v.z + translation.z,
            ),
          )
          .toList();
    }

    // Aplicar explosionado
    if (explodeOffset != null) {
      rawCorners = rawCorners
          .map(
            (v) => Vector3(
              v.x + explodeOffset.x,
              v.y + explodeOffset.y,
              v.z + explodeOffset.z,
            ),
          )
          .toList();
    }

    double cx = 0, cy = 0, cz = 0;
    for (final c in rawCorners) {
      cx += c.x;
      cy += c.y;
      cz += c.z;
    }
    final center = Vector3(cx / 8, cy / 8, cz / 8);

    return ScenePart(part: part, corners: rawCorners, center: center);
  }
}

class SceneBuilder {
  const SceneBuilder();

  /// Construye las partes de la escena considerando puertas abiertas, cajones abiertos y vista explosionada.
  List<ScenePart> build(
    Furniture furniture, {
    double doorOpenProgress = 0.0,
    double drawerOpenProgress = 0.0,
    double explodeProgress = 0.0,
  }) {
    final result = <ScenePart>[];
    final centerFurniture = Vector3(
      furniture.overallSize.width / 2,
      furniture.overallSize.height / 2,
      furniture.overallSize.depth / 2,
    );

    // Mapeo rápido de mecanismos
    final doorMechanisms = <String, HingedDoorMechanism>{};
    final drawerMechanisms = <String, DrawerMechanism>{};

    for (final mech in furniture.mechanisms) {
      if (mech is HingedDoorMechanism) {
        doorMechanisms[mech.doorPartId] = mech;
      } else if (mech is DrawerMechanism) {
        for (final pId in mech.partIds) {
          drawerMechanisms[pId] = mech;
        }
      }
    }

    for (final part in furniture.parts) {
      Vector3? translation;
      double rotationAngle = 0.0;
      Vector3? rotationPivot;
      Vector3? explodeOffset;

      // 1. Mecanismo de puerta
      final doorMech = doorMechanisms[part.id];
      if (doorMech != null && doorOpenProgress > 0.0) {
        final maxAngleRad = (doorMech.maxOpenAngleDeg * math.pi) / 180.0;
        final currentAngle = maxAngleRad * doorOpenProgress;

        if (doorMech.hingeSide == HingeSide.left) {
          // Gira sobre arista izquierda (hacia el frente, Z negativo)
          rotationPivot = Vector3(part.position.x, 0, part.position.z);
          rotationAngle = -currentAngle;
        } else {
          // Gira sobre arista derecha
          rotationPivot = Vector3(
            part.position.x + part.size.width,
            0,
            part.position.z,
          );
          rotationAngle = currentAngle;
        }
      }

      // 2. Mecanismo de cajón
      final drawerMech = drawerMechanisms[part.id];
      if (drawerMech != null && drawerOpenProgress > 0.0) {
        // Se traslada hacia el frente (Z negativo)
        final travel = drawerMech.travelMm * drawerOpenProgress;
        translation = Vector3(0, 0, -travel);
      }

      // 3. Explosionado
      if (explodeProgress > 0.0) {
        final partCenter = Vector3(
          part.position.x + part.size.width / 2,
          part.position.y + part.size.height / 2,
          part.position.z + part.size.depth / 2,
        );
        final dir = Vector3(
          partCenter.x - centerFurniture.x,
          partCenter.y - centerFurniture.y,
          partCenter.z - centerFurniture.z,
        );
        final factor = explodeProgress * 1.5;
        explodeOffset = Vector3(dir.x * factor, dir.y * factor, dir.z * factor);
      }

      result.add(
        ScenePart.fromPart(
          part,
          translation: translation,
          rotationAngleRad: rotationAngle,
          rotationPivot: rotationPivot,
          explodeOffset: explodeOffset,
        ),
      );
    }

    return result;
  }
}
