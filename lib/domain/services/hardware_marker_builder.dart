import 'dart:math' as math;

import '../entities/furniture.dart';
import '../entities/joint.dart';
import '../entities/mechanism.dart';
import '../entities/part.dart';
import '../value_objects/vector3.dart';

enum HardwareMarkerKind { hinge, screw, drawerSlide, handle }

/// Punto donde se dibuja un herraje dentro del visor 3D.
///
/// [position] es la entrada/cabeza y [direction] apunta hacia dentro del
/// material, de modo que la punta queda en position + direction * lengthMm.
class HardwareMarker {
  final Vector3 position;
  final Vector3 direction;
  final double lengthMm;
  final HardwareMarkerKind kind;
  final String label;
  final int count;

  const HardwareMarker({
    required this.position,
    required this.kind,
    required this.label,
    this.direction = const Vector3(0, 0, 1),
    this.lengthMm = 16,
    this.count = 1,
  });
}

/// Deriva posiciones aproximadas de herrajes a partir de mecanismos y uniones.
///
/// Las coordenadas son una guía visual del modelo. El mapa de perforación con
/// medidas exactas sigue siendo el del taller/fabricante.
class HardwareMarkerBuilder {
  const HardwareMarkerBuilder();

  List<HardwareMarker> build(Furniture furniture) {
    final markers = <HardwareMarker>[];
    for (final mechanism in furniture.mechanisms) {
      if (mechanism is HingedDoorMechanism) {
        _addHinges(furniture, mechanism, markers);
      } else if (mechanism is DrawerMechanism) {
        _addDrawerSlides(furniture, mechanism, markers);
      }
    }

    for (final joint in furniture.joints) {
      final first = furniture.partById(joint.partAId);
      final second = furniture.partById(joint.partBId);
      if (first == null || second == null) continue;
      final insertion = _insertionFor(first, second);
      final copies = joint.count.clamp(1, 4);
      for (var index = 0; index < copies; index++) {
        final offset = copies == 1 ? 0.0 : (index / (copies - 1) - 0.5) * 0.6;
        markers.add(
          HardwareMarker(
            position: _spreadEntry(first, second, insertion, offset),
            direction: insertion.direction,
            lengthMm: insertion.length,
            kind: joint.type == JointType.camLock
                ? HardwareMarkerKind.hinge
                : HardwareMarkerKind.screw,
            label: '${joint.type.label} (${joint.count})',
            count: joint.count,
          ),
        );
      }
    }

    // En muebles creados a mano no siempre hay uniones explícitas: marcamos
    // los contactos entre paneles como referencia de atornillado.
    if (furniture.joints.isEmpty) {
      for (var first = 0; first < furniture.parts.length; first++) {
        for (
          var second = first + 1;
          second < furniture.parts.length;
          second++
        ) {
          final a = furniture.parts[first];
          final b = furniture.parts[second];
          if (!_areTouching(a, b)) continue;
          final insertion = _insertionFor(a, b);
          markers.add(
            HardwareMarker(
              position: insertion.entry,
              direction: insertion.direction,
              lengthMm: insertion.length,
              kind: HardwareMarkerKind.screw,
              label: 'Unión ${a.name} / ${b.name}',
            ),
          );
        }
      }
    }
    return markers;
  }

  void _addHinges(
    Furniture furniture,
    HingedDoorMechanism mechanism,
    List<HardwareMarker> markers,
  ) {
    final door = furniture.partById(mechanism.doorPartId);
    if (door == null) return;
    final isLeft = mechanism.hingeSide == HingeSide.left;
    final x = isLeft
        ? door.position.x + math.min(30.0, door.size.width * 0.12)
        : door.position.x +
              door.size.width -
              math.min(30.0, door.size.width * 0.12);
    final count = math.max(1, mechanism.hingeCount);
    final usableHeight = door.size.height * 0.68;
    final doorInsertion = _insertionIntoPart(furniture, door);
    for (var index = 0; index < count; index++) {
      final t = count == 1 ? 0.5 : index / (count - 1);
      final y = door.position.y + door.size.height * 0.16 + usableHeight * t;
      markers.add(
        HardwareMarker(
          position: _replaceAxisPoint(
            doorInsertion.entry,
            axisIndex: doorInsertion.axis,
            x: x,
            y: y,
          ),
          direction: doorInsertion.direction,
          lengthMm: doorInsertion.length,
          kind: HardwareMarkerKind.hinge,
          label: 'Bisagra ${index + 1}',
        ),
      );
    }

    final handleX = isLeft
        ? door.position.x + door.size.width - 60
        : door.position.x + 60;
    markers.add(
      HardwareMarker(
        position: _replaceAxisPoint(
          doorInsertion.entry,
          axisIndex: doorInsertion.axis,
          x: handleX,
          y: door.position.y + door.size.height * 0.5,
        ),
        direction: doorInsertion.direction,
        lengthMm: doorInsertion.length,
        kind: HardwareMarkerKind.handle,
        label: 'Tirador',
      ),
    );
  }

  void _addDrawerSlides(
    Furniture furniture,
    DrawerMechanism mechanism,
    List<HardwareMarker> markers,
  ) {
    final front = furniture.partById(mechanism.frontPartId);
    if (front == null) return;
    final centerY = front.position.y + front.size.height / 2;
    final z = front.position.z;
    final frontCenterZ = front.position.z + front.size.depth / 2;
    final furnitureCenterZ = furniture.overallSize.depth / 2;
    final outwardZ = frontCenterZ >= furnitureCenterZ ? 1.0 : -1.0;
    for (final side in [0.0, 1.0]) {
      markers.add(
        HardwareMarker(
          position: Vector3(
            front.position.x + front.size.width * side,
            centerY,
            z,
          ),
          direction: Vector3(side == 0 ? 1 : -1, 0, 0),
          lengthMm: 10,
          kind: HardwareMarkerKind.drawerSlide,
          label: side == 0 ? 'Corredera izquierda' : 'Corredera derecha',
        ),
      );
    }
    markers.add(
      HardwareMarker(
        position: Vector3(
          front.position.x + front.size.width / 2,
          centerY,
          outwardZ > 0 ? front.position.z : front.position.z + front.size.depth,
        ),
        direction: Vector3(0, 0, outwardZ),
        lengthMm: front.size.depth + 2,
        kind: HardwareMarkerKind.handle,
        label: 'Tirador de cajón',
      ),
    );
  }

  _Insertion _insertionFor(Part first, Part second) {
    final gaps = [
      _gap(
        _minAxis(first, 0),
        _maxAxis(first, 0),
        _minAxis(second, 0),
        _maxAxis(second, 0),
      ),
      _gap(
        _minAxis(first, 1),
        _maxAxis(first, 1),
        _minAxis(second, 1),
        _maxAxis(second, 1),
      ),
      _gap(
        _minAxis(first, 2),
        _maxAxis(first, 2),
        _minAxis(second, 2),
        _maxAxis(second, 2),
      ),
    ];
    var axis = 0;
    for (var index = 1; index < 3; index++) {
      if (gaps[index] < gaps[axis]) axis = index;
    }
    if (gaps[axis] > 0.6) {
      // Sin contacto claro: usa el eje con mayor separación entre centros.
      var largest = 0.0;
      for (var index = 0; index < 3; index++) {
        final delta = (_centerAxis(second, index) - _centerAxis(first, index))
            .abs();
        if (delta > largest) {
          largest = delta;
          axis = index;
        }
      }
    }
    final delta = _centerAxis(second, axis) - _centerAxis(first, axis);
    final sign = delta >= 0 ? 1.0 : -1.0;
    final entryCoord = sign > 0 ? _minAxis(first, axis) : _maxAxis(first, axis);
    final coordinates = [
      (_centerAxis(first, 0) + _centerAxis(second, 0)) / 2,
      (_centerAxis(first, 1) + _centerAxis(second, 1)) / 2,
      (_centerAxis(first, 2) + _centerAxis(second, 2)) / 2,
    ];
    for (var index = 0; index < 3; index++) {
      if (index == axis) continue;
      final overlap = _overlap(
        _minAxis(first, index),
        _maxAxis(first, index),
        _minAxis(second, index),
        _maxAxis(second, index),
      );
      if (overlap != null) coordinates[index] = (overlap.$1 + overlap.$2) / 2;
    }
    coordinates[axis] = entryCoord;
    return _Insertion(
      entry: Vector3(coordinates[0], coordinates[1], coordinates[2]),
      direction: _axisUnit(axis, sign),
      length: _sizeAxis(first, axis) + 5,
      axis: axis,
    );
  }

  _Insertion _insertionIntoPart(Furniture furniture, Part part) {
    final axis = _thicknessAxis(part);
    final center = _centerAxis(part, axis);
    final furnitureCenter =
        [
          furniture.overallSize.width,
          furniture.overallSize.height,
          furniture.overallSize.depth,
        ][axis] /
        2;
    final outward = center >= furnitureCenter ? 1.0 : -1.0;
    final entryCoord = outward > 0
        ? _minAxis(part, axis)
        : _maxAxis(part, axis);
    final coordinates = [
      part.position.x + part.size.width / 2,
      part.position.y + part.size.height / 2,
      part.position.z + part.size.depth / 2,
    ];
    coordinates[axis] = entryCoord;
    return _Insertion(
      entry: Vector3(coordinates[0], coordinates[1], coordinates[2]),
      direction: _axisUnit(axis, outward),
      length: _sizeAxis(part, axis) + 2,
      axis: axis,
    );
  }

  Vector3 _spreadEntry(
    Part first,
    Part second,
    _Insertion insertion,
    double offset,
  ) {
    if (offset == 0) return insertion.entry;
    var spreadAxis = (insertion.axis + 1) % 3;
    final otherAxis = (insertion.axis + 2) % 3;
    (double, double)? spreadOverlap = _overlap(
      _minAxis(first, spreadAxis),
      _maxAxis(first, spreadAxis),
      _minAxis(second, spreadAxis),
      _maxAxis(second, spreadAxis),
    );
    final otherOverlap = _overlap(
      _minAxis(first, otherAxis),
      _maxAxis(first, otherAxis),
      _minAxis(second, otherAxis),
      _maxAxis(second, otherAxis),
    );
    final spreadLength = spreadOverlap == null
        ? 0.0
        : spreadOverlap.$2 - spreadOverlap.$1;
    final otherLength = otherOverlap == null
        ? 0.0
        : otherOverlap.$2 - otherOverlap.$1;
    if (otherLength > spreadLength) {
      spreadAxis = otherAxis;
      spreadOverlap = otherOverlap;
    }
    if (spreadOverlap == null || spreadOverlap.$2 - spreadOverlap.$1 < 2) {
      return insertion.entry;
    }
    final coordinates = [
      insertion.entry.x,
      insertion.entry.y,
      insertion.entry.z,
    ];
    final start = spreadOverlap.$1;
    final end = spreadOverlap.$2;
    coordinates[spreadAxis] = (start + end) / 2 + offset * (end - start);
    return Vector3(coordinates[0], coordinates[1], coordinates[2]);
  }

  Vector3 _replaceAxisPoint(
    Vector3 point, {
    required int axisIndex,
    required double x,
    required double y,
  }) {
    final coordinates = [point.x, point.y, point.z];
    if (axisIndex != 0) coordinates[0] = x;
    if (axisIndex != 1) coordinates[1] = y;
    return Vector3(coordinates[0], coordinates[1], coordinates[2]);
  }

  int _thicknessAxis(Part part) {
    final dimensions = [part.size.width, part.size.height, part.size.depth];
    var axis = 0;
    for (var index = 1; index < 3; index++) {
      if (dimensions[index] < dimensions[axis]) axis = index;
    }
    return axis;
  }

  Vector3 _axisUnit(int axis, double sign) => switch (axis) {
    0 => Vector3(sign, 0, 0),
    1 => Vector3(0, sign, 0),
    _ => Vector3(0, 0, sign),
  };

  double _minAxis(Part part, int axis) => switch (axis) {
    0 => part.position.x,
    1 => part.position.y,
    _ => part.position.z,
  };

  double _maxAxis(Part part, int axis) => switch (axis) {
    0 => part.position.x + part.size.width,
    1 => part.position.y + part.size.height,
    _ => part.position.z + part.size.depth,
  };

  double _sizeAxis(Part part, int axis) => switch (axis) {
    0 => part.size.width,
    1 => part.size.height,
    _ => part.size.depth,
  };

  double _centerAxis(Part part, int axis) =>
      (_minAxis(part, axis) + _maxAxis(part, axis)) / 2;

  (double, double)? _overlap(
    double startA,
    double endA,
    double startB,
    double endB,
  ) {
    final start = math.max(startA, startB);
    final end = math.min(endA, endB);
    return end > start ? (start, end) : null;
  }

  bool _areTouching(Part first, Part second) {
    const tolerance = 0.6;
    final x = _gap(
      first.position.x,
      first.position.x + first.size.width,
      second.position.x,
      second.position.x + second.size.width,
    );
    final y = _gap(
      first.position.y,
      first.position.y + first.size.height,
      second.position.y,
      second.position.y + second.size.height,
    );
    final z = _gap(
      first.position.z,
      first.position.z + first.size.depth,
      second.position.z,
      second.position.z + second.size.depth,
    );
    final touchingAxes = [x, y, z].where((gap) => gap <= tolerance).length;
    return touchingAxes >= 2;
  }

  double _gap(double startA, double endA, double startB, double endB) {
    if (endA < startB) return startB - endA;
    if (endB < startA) return startA - endB;
    return 0;
  }
}

class _Insertion {
  final Vector3 entry;
  final Vector3 direction;
  final double length;
  final int axis;

  const _Insertion({
    required this.entry,
    required this.direction,
    required this.length,
    required this.axis,
  });
}
