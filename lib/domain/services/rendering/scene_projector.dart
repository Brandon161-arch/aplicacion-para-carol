import 'dart:math' as math;

import '../../entities/furniture.dart';
import '../../entities/part.dart';
import '../../value_objects/vector3.dart';
import 'orbit_camera.dart';
import 'scene_builder.dart';

/// Punto ya proyectado al plano de la pantalla.
class ProjectedPoint {
  final double x;
  final double y;
  final double depth;

  const ProjectedPoint({required this.x, required this.y, required this.depth});
}

/// Cara visible de una pieza.
class ProjectedFace {
  final String partId;
  final PartKind kind;
  final String materialId;
  final List<ProjectedPoint> points;
  final double depth;
  final double shade;

  const ProjectedFace({
    required this.partId,
    required this.kind,
    required this.materialId,
    required this.points,
    required this.depth,
    required this.shade,
  });
}

class ProjectionResult {
  final List<ProjectedFace> faces;
  final double viewportWidth;
  final double viewportHeight;

  const ProjectionResult({
    required this.faces,
    required this.viewportWidth,
    required this.viewportHeight,
  });
}

class _CameraBasis {
  final Vector3 eye;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;
  final double focalPixels;
  final double viewportWidth;
  final double viewportHeight;

  const _CameraBasis({
    required this.eye,
    required this.forward,
    required this.right,
    required this.up,
    required this.focalPixels,
    required this.viewportWidth,
    required this.viewportHeight,
  });
}

class _FaceDefinition {
  final List<int> cornerIndices;
  final Vector3 normal;

  const _FaceDefinition(this.cornerIndices, this.normal);
}

class _PartBounds {
  final String partId;
  final Vector3 min;
  final Vector3 max;

  const _PartBounds({
    required this.partId,
    required this.min,
    required this.max,
  });

  factory _PartBounds.fromCorners(String partId, List<Vector3> corners) {
    var minX = corners.first.x;
    var minY = corners.first.y;
    var minZ = corners.first.z;
    var maxX = minX;
    var maxY = minY;
    var maxZ = minZ;

    for (final corner in corners.skip(1)) {
      if (corner.x < minX) minX = corner.x;
      if (corner.y < minY) minY = corner.y;
      if (corner.z < minZ) minZ = corner.z;
      if (corner.x > maxX) maxX = corner.x;
      if (corner.y > maxY) maxY = corner.y;
      if (corner.z > maxZ) maxZ = corner.z;
    }

    return _PartBounds(
      partId: partId,
      min: Vector3(minX, minY, minZ),
      max: Vector3(maxX, maxY, maxZ),
    );
  }
}

class _PartRenderData {
  final ScenePart scenePart;
  final List<Vector3> corners;
  final _PartBounds bounds;

  const _PartRenderData({
    required this.scenePart,
    required this.corners,
    required this.bounds,
  });
}

/// Proyección perspectiva con algoritmo del pintor.
///
/// El dominio no depende de Flutter: devuelve puntos y sombras; el painter
/// decide colores y trazos.
class SceneProjector {
  const SceneProjector();

  static const List<_FaceDefinition> _faces = [
    _FaceDefinition([0, 1, 2, 3], Vector3(0, 0, -1)), // frente
    _FaceDefinition([4, 5, 6, 7], Vector3(0, 0, 1)), // atrás
    _FaceDefinition([0, 4, 7, 3], Vector3(-1, 0, 0)), // izquierda
    _FaceDefinition([1, 2, 6, 5], Vector3(1, 0, 0)), // derecha
    _FaceDefinition([0, 1, 5, 4], Vector3(0, -1, 0)), // abajo
    _FaceDefinition([3, 7, 6, 2], Vector3(0, 1, 0)), // arriba
  ];

  static const Vector3 _lightDirection = Vector3(-0.35, 0.82, -0.45);

  ProjectionResult project({
    required Furniture furniture,
    required OrbitCamera camera,
    required double viewportWidth,
    required double viewportHeight,
    double explodeFactor = 0,
  }) {
    final basis = _buildBasis(camera, viewportWidth, viewportHeight);
    final parts = const SceneBuilder().build(furniture);
    final furnitureCenter = Vector3(
      furniture.overallSize.width / 2,
      furniture.overallSize.height / 2,
      furniture.overallSize.depth / 2,
    );

    final partData = <_PartRenderData>[];
    for (final scenePart in parts) {
      final offset = explodeFactor == 0
          ? Vector3.zero
          : (scenePart.center - furnitureCenter).normalized *
                (explodeFactor * furniture.overallSize.maxDimension * 0.35);
      final corners = scenePart.corners
          .map((corner) => corner + offset)
          .toList(growable: false);
      partData.add(
        _PartRenderData(
          scenePart: scenePart,
          corners: corners,
          bounds: _PartBounds.fromCorners(scenePart.part.id, corners),
        ),
      );
    }
    final allBounds = partData
        .map((data) => data.bounds)
        .toList(growable: false);

    final faces = <ProjectedFace>[];

    for (final data in partData) {
      final scenePart = data.scenePart;
      final corners = data.corners;

      for (final face in _faces) {
        final facePoints = [
          for (final index in face.cornerIndices) corners[index],
        ];
        final faceCenter = _average(facePoints);
        final toEye = basis.eye - faceCenter;
        if (face.normal.dot(toEye) <= 0) continue;

        // Oculta caras interiores que quedan tapadas por otra pieza.
        // Sin esto, el algoritmo del pintor puede dibujar un estante
        // encima de una puerta por error de profundidad media.
        if (_isOccluded(
          origin: basis.eye,
          target: faceCenter,
          bounds: allBounds,
          selfPartId: scenePart.part.id,
        )) {
          continue;
        }

        final projected = <ProjectedPoint>[];
        var visible = true;
        for (final point in facePoints) {
          final screenPoint = _projectPoint(point, basis);
          if (screenPoint == null) {
            visible = false;
            break;
          }
          projected.add(screenPoint);
        }
        if (!visible) continue;

        final depth = _averageDepth(facePoints, basis);
        final brightness =
            0.42 +
            0.58 * math.max(0.0, face.normal.dot(_lightDirection.normalized));

        faces.add(
          ProjectedFace(
            partId: scenePart.part.id,
            kind: scenePart.part.kind,
            materialId: scenePart.part.materialId,
            points: projected,
            depth: depth,
            shade: brightness.clamp(0.0, 1.0).toDouble(),
          ),
        );
      }
    }

    faces.sort((a, b) {
      final byDepth = b.depth.compareTo(a.depth);
      if (byDepth != 0) return byDepth;
      return a.partId.compareTo(b.partId);
    });

    return ProjectionResult(
      faces: faces,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
  }

  /// Proyecta un punto suelto. Devuelve null si queda detrás de la cámara.
  /// Se usa para dibujar la cuadrícula del piso.
  ProjectedPoint? projectPoint({
    required Vector3 point,
    required OrbitCamera camera,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final basis = _buildBasis(camera, viewportWidth, viewportHeight);
    return _projectPoint(point, basis);
  }

  /// Devuelve la pieza visible bajo el puntero, o null si se tocó el fondo.
  String? pickPart({
    required Furniture furniture,
    required OrbitCamera camera,
    required double viewportWidth,
    required double viewportHeight,
    required double screenX,
    required double screenY,
  }) {
    final result = project(
      furniture: furniture,
      camera: camera,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    // Las caras vienen ordenadas de lejos a cerca; al revés se prueba
    // primero lo que está más cerca de la cámara.
    for (final face in result.faces.reversed) {
      if (!_pointInPolygon(screenX, screenY, face.points)) continue;
      return face.partId;
    }
    return null;
  }

  /// Convierte un punto de pantalla en un punto del plano horizontal y = [planeY].
  Vector3? screenToPlane({
    required double screenX,
    required double screenY,
    required OrbitCamera camera,
    required double viewportWidth,
    required double viewportHeight,
    required double planeY,
  }) {
    final basis = _buildBasis(camera, viewportWidth, viewportHeight);
    final cameraX = (screenX - viewportWidth / 2) / basis.focalPixels;
    final cameraY = -(screenY - viewportHeight / 2) / basis.focalPixels;
    final direction =
        (basis.right * cameraX + basis.up * cameraY + basis.forward).normalized;
    if (direction.y.abs() < 0.000001) return null;
    final t = (planeY - basis.eye.y) / direction.y;
    if (t <= 0) return null;
    return basis.eye + direction * t;
  }

  bool _pointInPolygon(double x, double y, List<ProjectedPoint> points) {
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final xi = points[i].x;
      final yi = points[i].y;
      final xj = points[j].x;
      final yj = points[j].y;
      final intersects =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  bool _isOccluded({
    required Vector3 origin,
    required Vector3 target,
    required List<_PartBounds> bounds,
    required String selfPartId,
  }) {
    final direction = target - origin;
    for (final candidate in bounds) {
      if (candidate.partId == selfPartId) continue;
      if (_rayHitsAabb(origin, direction, candidate)) return true;
    }
    return false;
  }

  bool _rayHitsAabb(Vector3 origin, Vector3 direction, _PartBounds bounds) {
    var tMin = 0.0;
    var tMax = 1.0;

    bool updateSlab(double o, double d, double min, double max) {
      if (d.abs() < 0.000000001) {
        return o >= min && o <= max;
      }
      var t1 = (min - o) / d;
      var t2 = (max - o) / d;
      if (t1 > t2) {
        final swap = t1;
        t1 = t2;
        t2 = swap;
      }
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      return tMin <= tMax;
    }

    if (!updateSlab(origin.x, direction.x, bounds.min.x, bounds.max.x)) {
      return false;
    }
    if (!updateSlab(origin.y, direction.y, bounds.min.y, bounds.max.y)) {
      return false;
    }
    if (!updateSlab(origin.z, direction.z, bounds.min.z, bounds.max.z)) {
      return false;
    }

    return tMin > 0.001 && tMin < 0.999;
  }

  _CameraBasis _buildBasis(
    OrbitCamera camera,
    double viewportWidth,
    double viewportHeight,
  ) {
    final eye = camera.position;
    final forward = (camera.target - eye).normalized;
    var right = const Vector3(0, 1, 0).cross(forward);
    if (right.length < 0.000001) {
      right = const Vector3(1, 0, 0);
    }
    right = right.normalized;
    final up = forward.cross(right).normalized;
    final fovRadians = camera.fovDeg * math.pi / 180;
    final focalPixels =
        (1 / math.tan(fovRadians / 2)) *
        (math.min(viewportWidth, viewportHeight) / 2);

    return _CameraBasis(
      eye: eye,
      forward: forward,
      right: right,
      up: up,
      focalPixels: focalPixels,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
  }

  ProjectedPoint? _projectPoint(Vector3 point, _CameraBasis basis) {
    final relative = point - basis.eye;
    final cameraX = relative.dot(basis.right);
    final cameraY = relative.dot(basis.up);
    final cameraZ = relative.dot(basis.forward);
    if (cameraZ <= 0.5) return null;

    final screenX =
        basis.viewportWidth / 2 + (cameraX / cameraZ) * basis.focalPixels;
    final screenY =
        basis.viewportHeight / 2 - (cameraY / cameraZ) * basis.focalPixels;

    return ProjectedPoint(x: screenX, y: screenY, depth: cameraZ);
  }

  double _averageDepth(List<Vector3> points, _CameraBasis basis) {
    var total = 0.0;
    for (final point in points) {
      total += (point - basis.eye).dot(basis.forward);
    }
    return total / points.length;
  }

  Vector3 _average(List<Vector3> points) {
    var total = Vector3.zero;
    for (final point in points) {
      total = total + point;
    }
    return total * (1 / points.length);
  }
}
