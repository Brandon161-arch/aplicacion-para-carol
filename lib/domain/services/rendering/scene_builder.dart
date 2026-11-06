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

  /// Contornos inferior y superior para piezas con forma no rectangular.
  final List<Vector3>? outlineBottom;
  final List<Vector3>? outlineTop;

  const ScenePart({
    required this.part,
    required this.corners,
    required this.center,
    this.outlineBottom,
    this.outlineTop,
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

    Vector3 transform(Vector3 value) {
      var point = value;
      if (rotationAngleRad != 0.0 && rotationPivot != null) {
        final cosA = math.cos(rotationAngleRad);
        final sinA = math.sin(rotationAngleRad);
        final px = rotationPivot.x;
        final pz = rotationPivot.z;
        final relX = point.x - px;
        final relZ = point.z - pz;
        point = Vector3(
          relX * cosA - relZ * sinA + px,
          point.y,
          relX * sinA + relZ * cosA + pz,
        );
      }
      if (translation != null) {
        point = point + translation;
      }
      if (explodeOffset != null) {
        point = point + explodeOffset;
      }
      return point;
    }

    final rawCorners = [
      Vector3(x0, y0, z0),
      Vector3(x1, y0, z0),
      Vector3(x1, y1, z0),
      Vector3(x0, y1, z0),
      Vector3(x0, y0, z1),
      Vector3(x1, y0, z1),
      Vector3(x1, y1, z1),
      Vector3(x0, y1, z1),
    ].map(transform).toList(growable: false);

    double cx = 0, cy = 0, cz = 0;
    for (final c in rawCorners) {
      cx += c.x;
      cy += c.y;
      cz += c.z;
    }
    final center = Vector3(cx / 8, cy / 8, cz / 8);

    List<Vector3>? outlineBottom;
    List<Vector3>? outlineTop;
    if (!part.shape.isRectangular) {
      final points = part.shape.outlineFor(
        part.cutSize.length,
        part.cutSize.width,
      );
      final thickness = part.cutSize.thickness;
      final xSize = part.size.width;
      final ySize = part.size.height;
      final zSize = part.size.depth;
      final thicknessAxis = _thicknessAxis(xSize, ySize, zSize, thickness);
      outlineBottom = [];
      outlineTop = [];
      for (final point in points) {
        switch (thicknessAxis) {
          case _Axis.x:
            outlineBottom.add(
              transform(Vector3(x0, y0 + point.y, z0 + point.x)),
            );
            outlineTop.add(transform(Vector3(x1, y0 + point.y, z0 + point.x)));
            break;
          case _Axis.y:
            outlineBottom.add(
              transform(Vector3(x0 + point.x, y0, z0 + point.y)),
            );
            outlineTop.add(transform(Vector3(x0 + point.x, y1, z0 + point.y)));
            break;
          case _Axis.z:
            outlineBottom.add(
              transform(Vector3(x0 + point.x, y0 + point.y, z0)),
            );
            outlineTop.add(transform(Vector3(x0 + point.x, y0 + point.y, z1)));
            break;
        }
      }
    }

    return ScenePart(
      part: part,
      corners: rawCorners,
      center: center,
      outlineBottom: outlineBottom,
      outlineTop: outlineTop,
    );
  }

  static _Axis _thicknessAxis(
    double width,
    double height,
    double depth,
    double thickness,
  ) {
    final candidates = [
      (_Axis.x, (width - thickness).abs()),
      (_Axis.y, (height - thickness).abs()),
      (_Axis.z, (depth - thickness).abs()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return candidates.first.$1;
  }
}

enum _Axis { x, y, z }

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
