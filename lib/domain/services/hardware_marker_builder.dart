import 'dart:math' as math;

import '../entities/furniture.dart';
import '../entities/joint.dart';
import '../entities/mechanism.dart';
import '../entities/part.dart';
import '../value_objects/vector3.dart';

enum HardwareMarkerKind { hinge, screw, drawerSlide, handle }

/// Punto donde se dibuja un herraje dentro del visor 3D.
class HardwareMarker {
  final Vector3 position;
  final HardwareMarkerKind kind;
  final String label;
  final int count;

  const HardwareMarker({
    required this.position,
    required this.kind,
    required this.label,
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
      final point = _junctionPoint(first, second);
      markers.add(
        HardwareMarker(
          position: point,
          kind: joint.type == JointType.camLock
              ? HardwareMarkerKind.hinge
              : HardwareMarkerKind.screw,
          label: '${joint.type.label} (${joint.count})',
          count: joint.count,
        ),
      );
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
          markers.add(
            HardwareMarker(
              position: _junctionPoint(a, b),
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
    for (var index = 0; index < count; index++) {
      final t = count == 1 ? 0.5 : index / (count - 1);
      final y = door.position.y + door.size.height * 0.16 + usableHeight * t;
      markers.add(
        HardwareMarker(
          position: Vector3(x, y, door.position.z),
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
        position: Vector3(
          handleX,
          door.position.y + door.size.height * 0.5,
          door.position.z,
        ),
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
    for (final side in [0.0, 1.0]) {
      markers.add(
        HardwareMarker(
          position: Vector3(
            front.position.x + front.size.width * side,
            centerY,
            z,
          ),
          kind: HardwareMarkerKind.drawerSlide,
          label: side == 0 ? 'Corredera izquierda' : 'Corredera derecha',
        ),
      );
    }
    markers.add(
      HardwareMarker(
        position: Vector3(front.position.x + front.size.width / 2, centerY, z),
        kind: HardwareMarkerKind.handle,
        label: 'Tirador de cajón',
      ),
    );
  }

  Vector3 _junctionPoint(Part first, Part second) {
    final centerA = Vector3(
      first.position.x + first.size.width / 2,
      first.position.y + first.size.height / 2,
      first.position.z + first.size.depth / 2,
    );
    final centerB = Vector3(
      second.position.x + second.size.width / 2,
      second.position.y + second.size.height / 2,
      second.position.z + second.size.depth / 2,
    );
    final overlapX = _overlap(
      first.position.x,
      first.position.x + first.size.width,
      second.position.x,
      second.position.x + second.size.width,
    );
    final overlapY = _overlap(
      first.position.y,
      first.position.y + first.size.height,
      second.position.y,
      second.position.y + second.size.height,
    );
    final overlapZ = _overlap(
      first.position.z,
      first.position.z + first.size.depth,
      second.position.z,
      second.position.z + second.size.depth,
    );
    return Vector3(
      overlapX == null
          ? (centerA.x + centerB.x) / 2
          : (overlapX.$1 + overlapX.$2) / 2,
      overlapY == null
          ? (centerA.y + centerB.y) / 2
          : (overlapY.$1 + overlapY.$2) / 2,
      overlapZ == null
          ? (centerA.z + centerB.z) / 2
          : (overlapZ.$1 + overlapZ.$2) / 2,
    );
  }

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
