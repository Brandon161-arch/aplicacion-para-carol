import 'dart:math' as math;

import '../../value_objects/vector3.dart';

/// Cámara orbital alrededor del centro del mueble.
///
/// - [yaw] gira horizontalmente (radianes).
/// - [pitch] inclina la vista (radianes).
/// - [distance] es la distancia al objetivo, en milímetros.
class OrbitCamera {
  final double yaw;
  final double pitch;
  final double distance;
  final double fovDeg;
  final Vector3 target;

  const OrbitCamera({
    this.yaw = 0.62,
    this.pitch = 0.34,
    this.distance = 2400,
    this.fovDeg = 50,
    this.target = Vector3.zero,
  });

  Vector3 get position {
    final horizontal = distance * math.cos(pitch);
    return Vector3(
      target.x + horizontal * math.sin(yaw),
      target.y + distance * math.sin(pitch),
      target.z - horizontal * math.cos(yaw),
    );
  }

  OrbitCamera copyWith({
    double? yaw,
    double? pitch,
    double? distance,
    double? fovDeg,
    Vector3? target,
  }) => OrbitCamera(
    yaw: yaw ?? this.yaw,
    pitch: pitch ?? this.pitch,
    distance: distance ?? this.distance,
    fovDeg: fovDeg ?? this.fovDeg,
    target: target ?? this.target,
  );

  @override
  bool operator ==(Object other) =>
      other is OrbitCamera &&
      other.yaw == yaw &&
      other.pitch == pitch &&
      other.distance == distance &&
      other.fovDeg == fovDeg &&
      other.target == target;

  @override
  int get hashCode => Object.hash(yaw, pitch, distance, fovDeg, target);
}
