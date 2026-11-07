import 'dart:math' as math;

import '../entities/furniture.dart';
import '../entities/hardware_item.dart';
import '../entities/hardware_price_catalog.dart';
import '../entities/hardware_requirement.dart';
import '../entities/joint.dart';
import '../entities/mechanism.dart';
import '../entities/part.dart';
import '../value_objects/vector3.dart';

/// Calcula cantidades de herrajes y da una guía de ubicación.
///
/// Las posiciones son recomendaciones de montaje. La perforación exacta
/// depende del fabricante del herraje y se debe comprobar antes de taladrar.
class HardwareCalculator {
  const HardwareCalculator();

  List<HardwareRequirement> calculate(
    Furniture furniture,
    HardwarePriceCatalog prices,
  ) {
    final grouped = <String, _RequirementAccumulator>{};
    final doorIds = <String>{};
    final drawerFrontIds = <String>{};
    final explicitJointPairs = furniture.joints
        .map((joint) => _pairKey(joint.partAId, joint.partBId))
        .toSet();

    void add({
      required HardwareKind kind,
      required String name,
      required String spec,
      required int quantity,
      required String location,
      required String note,
      String? groupName,
      int? unitPriceCents,
    }) {
      if (quantity <= 0) return;
      final key = '${kind.name}|$spec|${groupName ?? name}';
      final accumulator = grouped.putIfAbsent(
        key,
        () => _RequirementAccumulator(
          kind: kind,
          name: name,
          spec: spec,
          unitPriceCents: unitPriceCents ?? prices.priceFor(kind),
        ),
      );
      accumulator.add(quantity: quantity, location: location, note: note);
    }

    // Cuenta primero los sujetadores declarados explícitamente en las uniones.
    for (final joint in furniture.joints) {
      final fastener = joint.fastener ?? _defaultFastener(joint);
      if (fastener == null) continue;
      final partA = furniture.partById(joint.partAId);
      final partB = furniture.partById(joint.partBId);
      final location =
          '${partA == null ? joint.partAId : _displayPartName(furniture, partA)} ? '
          '${partB == null ? joint.partBId : _displayPartName(furniture, partB)}';
      add(
        kind: fastener.kind,
        name: fastener.label,
        spec: fastener.label,
        quantity: joint.count,
        location: location,
        note: _jointPlacementNote(joint),
      );
    }

    // En modelos creados a mano, infiere tornillos donde dos paneles
    // estructurales están en contacto, salvo que ya exista una unión explícita.
    final structuralParts = furniture.parts
        .where(_isInferableStructuralPart)
        .toList(growable: false);
    for (
      var firstIndex = 0;
      firstIndex < structuralParts.length;
      firstIndex++
    ) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < structuralParts.length;
        secondIndex++
      ) {
        final first = structuralParts[firstIndex];
        final second = structuralParts[secondIndex];
        if (explicitJointPairs.contains(_pairKey(first.id, second.id))) {
          continue;
        }
        final contactLength = _touchingContactLength(first, second);
        if (contactLength == null) continue;

        final minThickness = math.min(
          first.cutSize.thickness,
          second.cutSize.thickness,
        );
        final fastenerKind = minThickness >= 15
            ? HardwareKind.confirmat
            : HardwareKind.screw;
        final fastenerSpec = minThickness >= 15
            ? 'Confirmat 7 x 50 mm'
            : 'Tornillo para madera 4 x 40 mm';
        final count = math.max(2, (contactLength / 250).ceil() + 1);
        add(
          kind: fastenerKind,
          name: fastenerSpec,
          spec: fastenerSpec,
          quantity: count,
          location:
              '${_displayPartName(furniture, first)} ? ${_displayPartName(furniture, second)}',
          note:
              'Unión inferida por contacto; repartir aprox. cada 250 mm. '
              'Verificar antes de perforar.',
        );
      }
    }

    // Bisagras, correderas y sus tornillos se derivan de los mecanismos.
    for (final mechanism in furniture.mechanisms) {
      if (mechanism is HingedDoorMechanism) {
        doorIds.add(mechanism.doorPartId);
        final door = furniture.partById(mechanism.doorPartId);
        final doorName = door == null
            ? 'Puerta'
            : _displayPartName(furniture, door);
        final hingeSpec = mechanism.hingeSpec ?? 'Bisagra de cazoleta 35 mm';
        add(
          kind: mechanism.hingeKind,
          name: hingeSpec,
          spec: hingeSpec,
          quantity: mechanism.hingeCount,
          location:
              '$doorName · bisagras en el lado ${_hingeSideName(mechanism.hingeSide)}',
          note: _hingePlacementNote(mechanism.hingeCount),
        );
        add(
          kind: HardwareKind.screw,
          name: 'Tornillo para bisagra',
          spec: '3,5 x 16 mm',
          quantity: mechanism.hingeCount * 4,
          location: 'Fijación de las bisagras de $doorName',
          note: '2 tornillos en la cazoleta y 2 en la placa por bisagra.',
        );
        add(
          kind: HardwareKind.handle,
          name: 'Tirador',
          spec: 'Tirador estándar',
          quantity: 1,
          location: '$doorName · lado opuesto a las bisagras',
          note: 'Centrar a la altura de uso.',
        );
        add(
          kind: HardwareKind.screw,
          name: 'Tornillo para tirador',
          spec: 'M4 (largo según tirador)',
          quantity: 2,
          location: 'Tirador de $doorName',
          note: '2 tornillos por tirador.',
        );
      } else if (mechanism is DrawerMechanism) {
        drawerFrontIds.add(mechanism.frontPartId);
        final front = furniture.partById(mechanism.frontPartId);
        final drawerName = front == null
            ? 'Cajón'
            : _displayPartName(furniture, front);
        final slideSpec = mechanism.slideSpec ?? 'Corredera telescópica';
        add(
          kind: mechanism.slideKind,
          name: slideSpec,
          spec: slideSpec,
          quantity: 2,
          location: '$drawerName · una corredera a cada lado',
          note:
              'Verificar que el largo sea menor que el fondo útil del mueble.',
        );
        add(
          kind: HardwareKind.screw,
          name: 'Tornillo para corredera',
          spec: '3,5 x 16 mm',
          quantity: 8,
          location: 'Fijación de las dos correderas del cajón',
          note: '4 tornillos por corredera como referencia.',
        );
        add(
          kind: HardwareKind.handle,
          name: 'Tirador',
          spec: 'Tirador estándar',
          quantity: 1,
          location: '$drawerName · centrado en el frente',
          note: 'Ubicar a una altura cómoda.',
        );
        add(
          kind: HardwareKind.screw,
          name: 'Tornillo para tirador',
          spec: 'M4 (largo según tirador)',
          quantity: 2,
          location: 'Tirador de $drawerName',
          note: '2 tornillos por tirador.',
        );
      }
    }

    // Sugiere herrajes para frentes creados manualmente sin mecanismo asociado.
    for (final door in furniture.partsOfKind(PartKind.door)) {
      if (doorIds.contains(door.id)) continue;
      add(
        kind: HardwareKind.hinge,
        name: 'Bisagra de cazoleta 35 mm',
        spec: 'Bisagra 35 mm, 110°',
        quantity: door.size.height <= 900 ? 2 : 3,
        location:
            '${_displayPartName(furniture, door)} · lado de montaje a definir',
        note: 'Aprox. 100 mm desde arriba y abajo.',
      );
      add(
        kind: HardwareKind.screw,
        name: 'Tornillo para bisagra',
        spec: '3,5 x 16 mm',
        quantity: (door.size.height <= 900 ? 2 : 3) * 4,
        location: 'Bisagras de ${_displayPartName(furniture, door)}',
        note: '4 tornillos por bisagra.',
      );
      add(
        kind: HardwareKind.handle,
        name: 'Tirador',
        spec: 'Tirador estándar',
        quantity: 1,
        location: '${_displayPartName(furniture, door)} · lado de apertura',
        note: 'Centrar a la altura de uso.',
      );
      add(
        kind: HardwareKind.screw,
        name: 'Tornillo para tirador',
        spec: 'M4 (largo según tirador)',
        quantity: 2,
        location: 'Tirador de ${_displayPartName(furniture, door)}',
        note: '2 tornillos por tirador.',
      );
    }

    for (final front in furniture.partsOfKind(PartKind.drawerFront)) {
      if (drawerFrontIds.contains(front.id)) continue;
      add(
        kind: HardwareKind.drawerSlide,
        name: 'Corredera telescópica',
        spec: 'Largo según fondo del cajón',
        quantity: 2,
        location:
            '${_displayPartName(furniture, front)} · una corredera a cada lado',
        note: 'Medir el fondo útil antes de comprar.',
      );
      add(
        kind: HardwareKind.screw,
        name: 'Tornillo para corredera',
        spec: '3,5 x 16 mm',
        quantity: 8,
        location: 'Fijación de las correderas del cajón',
        note: '4 tornillos por corredera.',
      );
      add(
        kind: HardwareKind.handle,
        name: 'Tirador',
        spec: 'Tirador estándar',
        quantity: 1,
        location: '${_displayPartName(furniture, front)} · centrado',
        note: 'Ubicar a una altura cómoda.',
      );
      add(
        kind: HardwareKind.screw,
        name: 'Tornillo para tirador',
        spec: 'M4 (largo según tirador)',
        quantity: 2,
        location: 'Tirador del cajón',
        note: '2 tornillos por tirador.',
      );
    }

    // Cada estante ajustable necesita cuatro soportes.
    final shelves = furniture.partsOfKind(PartKind.shelf).toList();
    for (var index = 0; index < shelves.length; index++) {
      add(
        kind: HardwareKind.shelfPin,
        name: 'Soporte de estante',
        spec: 'Perno 5 mm',
        quantity: 4,
        location: _displayPartName(furniture, shelves[index]),
        note: '2 soportes por lateral, debajo del estante.',
      );
    }

    // Estimación básica para patas de mesas y escritorios sin uniones explícitas.
    final legs = furniture.partsOfKind(PartKind.leg).toList();
    for (var index = 0; index < legs.length; index++) {
      add(
        kind: HardwareKind.screw,
        name: 'Tornillo para pata',
        spec: '8 x 40 mm',
        quantity: 2,
        location: 'Pata ${index + 1} ? tablero',
        note: '2 tornillos por pata, desde la cara interior.',
      );
    }

    // Los fondos de modelos manuales se fijan con clavos si no tienen unión definida.
    final backParts = furniture.partsOfKind(PartKind.backPanel).toList();
    for (final back in backParts) {
      final hasExplicitJoint = furniture.joints.any(
        (joint) => joint.partAId == back.id || joint.partBId == back.id,
      );
      if (hasExplicitJoint) continue;
      final estimatedNails =
          (2 * (back.cutSize.length + back.cutSize.width) / 180).ceil();
      add(
        kind: HardwareKind.nail,
        name: 'Clavo para fondo',
        spec: '1,6 x 30 mm',
        quantity: estimatedNails,
        location: 'Perímetro del fondo ${back.name}',
        note: 'Distribuir aproximadamente cada 180 mm.',
      );
    }

    // Herrajes cargados manualmente por el usuario.
    for (final item in furniture.manualHardware) {
      final location = item.partIds
          .map((id) {
            final part = furniture.partById(id);
            return part == null ? id : _displayPartName(furniture, part);
          })
          .join(', ');
      add(
        kind: item.kind,
        name: item.name,
        spec: item.spec ?? item.name,
        quantity: item.quantity,
        location: location.isEmpty ? 'Ubicación manual' : location,
        note: 'Agregado manualmente por el usuario.',
        groupName: item.name,
        unitPriceCents: item.unitPriceCents,
      );
    }

    final result = grouped.values.map((item) => item.build()).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  FastenerSpec? _defaultFastener(Joint joint) => switch (joint.type) {
    JointType.confirmat => const FastenerSpec(
      kind: HardwareKind.confirmat,
      label: 'Confirmat 7 x 50 mm',
      diameterMm: 7,
      lengthMm: 50,
    ),
    JointType.dowel => const FastenerSpec(
      kind: HardwareKind.dowel,
      label: 'Tarugo 8 x 30 mm',
      diameterMm: 8,
      lengthMm: 30,
    ),
    JointType.nail => const FastenerSpec(
      kind: HardwareKind.nail,
      label: 'Clavo 1,6 x 30 mm',
      diameterMm: 1.6,
      lengthMm: 30,
    ),
    JointType.buttScrew => const FastenerSpec(
      kind: HardwareKind.screw,
      label: 'Tornillo para madera 4 x 40 mm',
      diameterMm: 4,
      lengthMm: 40,
    ),
    JointType.camLock => const FastenerSpec(
      kind: HardwareKind.camLock,
      label: 'Minifix estándar',
    ),
    JointType.glueOnly => const FastenerSpec(
      kind: HardwareKind.glue,
      label: 'Cola para madera',
    ),
    JointType.dado ||
    JointType.rabbet ||
    JointType.miter ||
    JointType.biscuit => null,
  };

  String _jointPlacementNote(Joint joint) {
    if (joint.type == JointType.nail) {
      return 'Repartir sobre el perímetro, aproximadamente cada 150–180 mm.';
    }
    if (joint.count == 1) return 'Centrar en la unión.';
    if (joint.count == 2) return 'Uno cerca de cada extremo de la unión.';
    if (joint.count == 3) {
      return 'Uno en cada extremo y uno al centro.';
    }
    return 'Repartir uniformemente a lo largo de la unión.';
  }

  String _hingePlacementNote(int count) {
    if (count <= 2) return 'Aprox. 100 mm desde la parte superior e inferior.';
    if (count == 3) {
      return 'Aprox. 100 mm desde los extremos y una bisagra al centro.';
    }
    return 'Aprox. 100 mm desde los extremos y repartir las demás uniformemente.';
  }

  String _hingeSideName(HingeSide side) => switch (side) {
    HingeSide.left => 'izquierdo',
    HingeSide.right => 'derecho',
    HingeSide.top => 'superior',
    HingeSide.bottom => 'inferior',
  };

  String _displayPartName(Furniture furniture, Part part) {
    if (part.kind == PartKind.sidePanel) {
      return part.center.x < furniture.overallSize.width / 2
          ? 'Lateral izquierdo'
          : 'Lateral derecho';
    }
    if (part.kind == PartKind.door) {
      return part.center.x < furniture.overallSize.width / 2
          ? 'Puerta izquierda'
          : 'Puerta derecha';
    }
    if (part.kind == PartKind.drawerSide) {
      return part.center.x < furniture.overallSize.width / 2
          ? 'Lado de cajón izquierdo'
          : 'Lado de cajón derecho';
    }
    if (part.kind == PartKind.shelf || part.kind == PartKind.drawerFront) {
      final sameKind = furniture.partsOfKind(part.kind).toList()
        ..sort((a, b) => a.position.y.compareTo(b.position.y));
      if (sameKind.length > 1) {
        final index = sameKind.indexWhere((item) => item.id == part.id);
        final level = index == 0
            ? 'inferior'
            : index == sameKind.length - 1
            ? 'superior'
            : 'intermedio';
        return '${part.name} ${index + 1} ($level)';
      }
    }
    if (part.kind == PartKind.backPanel) return 'Fondo posterior';
    return part.name;
  }

  bool _isInferableStructuralPart(Part part) => switch (part.kind) {
    PartKind.sidePanel ||
    PartKind.topPanel ||
    PartKind.bottomPanel ||
    PartKind.divider ||
    PartKind.plinth ||
    PartKind.desktop ||
    PartKind.rail ||
    PartKind.apron => true,
    _ => false,
  };

  String _pairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

  double? _touchingContactLength(Part a, Part b) {
    const toleranceMm = 1.0;
    final aMin = a.position;
    final aMax =
        a.position + Vector3(a.size.width, a.size.height, a.size.depth);
    final bMin = b.position;
    final bMax =
        b.position + Vector3(b.size.width, b.size.height, b.size.depth);

    double overlap(double minA, double maxA, double minB, double maxB) =>
        math.min(maxA, maxB) - math.max(minA, minB);

    final touchesX =
        (aMax.x - bMin.x).abs() <= toleranceMm ||
        (bMax.x - aMin.x).abs() <= toleranceMm;
    if (touchesX) {
      final overlapY = overlap(aMin.y, aMax.y, bMin.y, bMax.y);
      final overlapZ = overlap(aMin.z, aMax.z, bMin.z, bMax.z);
      if (overlapY > 5 && overlapZ > 5) return math.max(overlapY, overlapZ);
    }

    final touchesY =
        (aMax.y - bMin.y).abs() <= toleranceMm ||
        (bMax.y - aMin.y).abs() <= toleranceMm;
    if (touchesY) {
      final overlapX = overlap(aMin.x, aMax.x, bMin.x, bMax.x);
      final overlapZ = overlap(aMin.z, aMax.z, bMin.z, bMax.z);
      if (overlapX > 5 && overlapZ > 5) return math.max(overlapX, overlapZ);
    }

    final touchesZ =
        (aMax.z - bMin.z).abs() <= toleranceMm ||
        (bMax.z - aMin.z).abs() <= toleranceMm;
    if (touchesZ) {
      final overlapX = overlap(aMin.x, aMax.x, bMin.x, bMax.x);
      final overlapY = overlap(aMin.y, aMax.y, bMin.y, bMax.y);
      if (overlapX > 5 && overlapY > 5) return math.max(overlapX, overlapY);
    }
    return null;
  }
}

class _RequirementAccumulator {
  final HardwareKind kind;
  final String name;
  final String spec;
  final int unitPriceCents;
  int quantity = 0;
  final List<HardwarePlacement> placements = [];

  _RequirementAccumulator({
    required this.kind,
    required this.name,
    required this.spec,
    required this.unitPriceCents,
  });

  void add({
    required int quantity,
    required String location,
    required String note,
  }) {
    this.quantity += quantity;
    placements.add(
      HardwarePlacement(location: location, quantity: quantity, note: note),
    );
  }

  HardwareRequirement build() => HardwareRequirement(
    kind: kind,
    name: name,
    spec: spec,
    quantity: quantity,
    unitPriceCents: unitPriceCents,
    placements: List<HardwarePlacement>.unmodifiable(placements),
  );
}
