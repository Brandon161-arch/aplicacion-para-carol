import 'dart:math' as math;

/// Vector tridimensional en milímetros.
///
/// Convención del proyecto:
/// - X crece hacia la derecha (ancho).
/// - Y crece hacia arriba (alto).
/// - Z crece hacia atrás (fondo).
/// - El origen está en la esquina inferior izquierda de la cara frontal.
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  static const Vector3 zero = Vector3(0, 0, 0);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  Vector3 operator *(double factor) =>
      Vector3(x * factor, y * factor, z * factor);

  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(dot(this));

  Vector3 get normalized => length == 0 ? zero : this * (1 / length);

  @override
  bool operator ==(Object other) =>
      other is Vector3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vector3($x, $y, $z)';
}
