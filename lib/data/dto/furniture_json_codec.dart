import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/joint.dart';
import '../../domain/entities/mechanism.dart';
import '../../domain/entities/part.dart';
import '../../domain/entities/saved_furniture.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/part_shape.dart';
import '../../domain/value_objects/vector3.dart';

/// Serialización completa de muebles a JSON, incluyendo piezas, uniones y mecanismos.
abstract final class FurnitureJsonCodec {
  static const int schemaVersion = 2;

  static Map<String, dynamic> furnitureToJson(Furniture furniture) => {
    'schemaVersion': schemaVersion,
    'id': furniture.id,
    'name': furniture.name,
    'type': furniture.type.name,
    'overallSize': {
      'width': furniture.overallSize.width,
      'height': furniture.overallSize.height,
      'depth': furniture.overallSize.depth,
    },
    'settings': {
      'panelThicknessMm': furniture.settings.panelThicknessMm,
      'backPanelThicknessMm': furniture.settings.backPanelThicknessMm,
      'doorGapMm': furniture.settings.doorGapMm,
      'shelfSetbackMm': furniture.settings.shelfSetbackMm,
      'plinthHeightMm': furniture.settings.plinthHeightMm,
    },
    'parts': furniture.parts.map(partToJson).toList(growable: false),
    'joints': furniture.joints.map(jointToJson).toList(growable: false),
    'mechanisms': furniture.mechanisms
        .map(mechanismToJson)
        .toList(growable: false),
  };

  static Furniture furnitureFromJson(Map<String, dynamic> json) {
    final overall = _asMap(json['overallSize']);
    final settings = _asMap(json['settings']);
    final parts = _asList(json['parts'])
        .map((part) => partFromJson(_asMap(part)))
        .toList(growable: false);

    final joints = _asList(json['joints'])
        .map((j) => jointFromJson(_asMap(j)))
        .toList(growable: false);

    final mechanisms = _asList(json['mechanisms'])
        .map((m) => mechanismFromJson(_asMap(m)))
        .whereType<Mechanism>()
        .toList(growable: false);

    return Furniture(
      id: _asString(json['id']),
      name: _asString(json['name']),
      type: _enumByName(
        FurnitureType.values,
        json['type'],
        FurnitureType.custom,
      ),
      overallSize: Size3(
        width: _asDouble(overall['width']),
        height: _asDouble(overall['height']),
        depth: _asDouble(overall['depth']),
      ),
      settings: ConstructionSettings(
        panelThicknessMm: _asDouble(settings['panelThicknessMm']),
        backPanelThicknessMm: _asDouble(settings['backPanelThicknessMm']),
        doorGapMm: _asDouble(settings['doorGapMm']),
        shelfSetbackMm: _asDouble(settings['shelfSetbackMm']),
        plinthHeightMm: _asDouble(settings['plinthHeightMm']),
      ),
      parts: parts,
      joints: joints,
      mechanisms: mechanisms,
      schemaVersion: _asInt(json['schemaVersion']),
    );
  }

  static Map<String, dynamic> jointToJson(Joint joint) => {
    'id': joint.id,
    'type': joint.type.name,
    'partAId': joint.partAId,
    'partBId': joint.partBId,
    'count': joint.count,
    'fastener': joint.fastener == null
        ? null
        : {
            'kind': joint.fastener!.kind.name,
            'label': joint.fastener!.label,
            'diameterMm': joint.fastener!.diameterMm,
            'lengthMm': joint.fastener!.lengthMm,
          },
    'notes': joint.notes,
  };

  static Joint jointFromJson(Map<String, dynamic> json) {
    final fastenerMap = _asMapOrNull(json['fastener']);
    FastenerSpec? fastener;
    if (fastenerMap != null) {
      fastener = FastenerSpec(
        kind: _enumByName(
          HardwareKind.values,
          fastenerMap['kind'],
          HardwareKind.screw,
        ),
        label: _asString(fastenerMap['label']),
        diameterMm: _asDoubleOrNull(fastenerMap['diameterMm']),
        lengthMm: _asDoubleOrNull(fastenerMap['lengthMm']),
      );
    }

    return Joint(
      id: _asString(json['id']),
      type: _enumByName(JointType.values, json['type'], JointType.buttScrew),
      partAId: _asString(json['partAId']),
      partBId: _asString(json['partBId']),
      count: _asInt(json['count']),
      fastener: fastener,
      notes: _asStringOrNull(json['notes']),
    );
  }

  static Map<String, dynamic> mechanismToJson(Mechanism mech) {
    if (mech is HingedDoorMechanism) {
      return {
        'type': 'hingedDoor',
        'id': mech.id,
        'partIds': mech.partIds,
        'doorPartId': mech.doorPartId,
        'hingeSide': mech.hingeSide.name,
        'maxOpenAngleDeg': mech.maxOpenAngleDeg,
        'hingeCount': mech.hingeCount,
        'hingeKind': mech.hingeKind.name,
        'hingeSpec': mech.hingeSpec,
      };
    } else if (mech is DrawerMechanism) {
      return {
        'type': 'drawer',
        'id': mech.id,
        'partIds': mech.partIds,
        'frontPartId': mech.frontPartId,
        'boxPartIds': mech.boxPartIds,
        'travelMm': mech.travelMm,
        'slideKind': mech.slideKind.name,
        'slideSpec': mech.slideSpec,
      };
    }
    return {'type': 'generic', 'id': mech.id, 'partIds': mech.partIds};
  }

  static Mechanism? mechanismFromJson(Map<String, dynamic> json) {
    final type = _asString(json['type']);
    final id = _asString(json['id']);
    final partIds = _asList(json['partIds']).map((e) => e.toString()).toList();

    if (type == 'hingedDoor') {
      return HingedDoorMechanism(
        id: id,
        partIds: partIds,
        doorPartId: _asString(json['doorPartId']),
        hingeSide: _enumByName(
          HingeSide.values,
          json['hingeSide'],
          HingeSide.left,
        ),
        maxOpenAngleDeg: _asDouble(json['maxOpenAngleDeg']),
        hingeCount: _asInt(json['hingeCount']),
        hingeKind: _enumByName(
          HardwareKind.values,
          json['hingeKind'],
          HardwareKind.hinge,
        ),
        hingeSpec: _asStringOrNull(json['hingeSpec']),
      );
    } else if (type == 'drawer') {
      return DrawerMechanism(
        id: id,
        partIds: partIds,
        frontPartId: _asString(json['frontPartId']),
        boxPartIds: _asList(json['boxPartIds'])
            .map((e) => e.toString())
            .toList(),
        travelMm: _asDouble(json['travelMm']),
        slideKind: _enumByName(
          HardwareKind.values,
          json['slideKind'],
          HardwareKind.drawerSlide,
        ),
        slideSpec: _asStringOrNull(json['slideSpec']),
      );
    }
    return null;
  }

  static Map<String, dynamic> partToJson(Part part) => {
    'id': part.id,
    'name': part.name,
    'kind': part.kind.name,
    'size': {
      'width': part.size.width,
      'height': part.size.height,
      'depth': part.size.depth,
    },
    'cutSize': {
      'length': part.cutSize.length,
      'width': part.cutSize.width,
      'thickness': part.cutSize.thickness,
    },
    'materialId': part.materialId,
    'position': {
      'x': part.position.x,
      'y': part.position.y,
      'z': part.position.z,
    },
    'grain': part.grain.name,
    'edgeBanding': {
      for (final entry in part.edgeBanding.entries)
        entry.key.name: {
          'materialId': entry.value.materialId,
          'thicknessMm': entry.value.thicknessMm,
        },
    },
    'structural': part.structural,
    'shape': part.shape.toJson(),
  };

  static Part partFromJson(Map<String, dynamic> json) {
    final size = _asMap(json['size']);
    final cutSize = _asMap(json['cutSize']);
    final position = _asMap(json['position']);
    final edgeBanding = <PanelEdge, EdgeBanding>{};
    final rawBanding = _asMap(json['edgeBanding']);
    for (final edge in PanelEdge.values) {
      final raw = _asMapOrNull(rawBanding[edge.name]);
      if (raw == null) continue;
      edgeBanding[edge] = EdgeBanding(
        materialId: _asString(raw['materialId']),
        thicknessMm: _asDouble(raw['thicknessMm']),
      );
    }

    return Part(
      id: _asString(json['id']),
      name: _asString(json['name']),
      kind: _enumByName(PartKind.values, json['kind'], PartKind.other),
      size: Size3(
        width: _asDouble(size['width']),
        height: _asDouble(size['height']),
        depth: _asDouble(size['depth']),
      ),
      cutSize: CutSize(
        length: _asDouble(cutSize['length']),
        width: _asDouble(cutSize['width']),
        thickness: _asDouble(cutSize['thickness']),
      ),
      materialId: _asString(json['materialId']),
      position: Vector3(
        _asDouble(position['x']),
        _asDouble(position['y']),
        _asDouble(position['z']),
      ),
      grain: _enumByName(
        GrainDirection.values,
        json['grain'],
        GrainDirection.none,
      ),
      edgeBanding: edgeBanding,
      structural: json['structural'] != false,
      shape: json['shape'] is Map
          ? PartShape.fromJson((json['shape'] as Map).cast<String, dynamic>())
          : PartShape.rectangle,
    );
  }

  static Map<String, dynamic> savedToJson(SavedFurniture item) => {
    'schemaVersion': schemaVersion,
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'tags': item.tags,
    'createdAt': item.createdAt.toIso8601String(),
    'furniture': furnitureToJson(item.furniture),
  };

  static SavedFurniture savedFromJson(Map<String, dynamic> json) =>
      SavedFurniture(
        id: _asString(json['id']),
        name: _asString(json['name']),
        description: _asString(json['description']),
        tags: _asList(json['tags'])
            .map((tag) => tag.toString())
            .toList(growable: false),
        createdAt:
            DateTime.tryParse(_asString(json['createdAt'])) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        furniture: furnitureFromJson(_asMap(json['furniture'])),
      );

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static Map<String, dynamic>? _asMapOrNull(Object? value) {
    if (value is! Map) return null;
    return value.cast<String, dynamic>();
  }

  static List<dynamic> _asList(Object? value) =>
      value is List ? value : const [];

  static double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

  static double? _asDoubleOrNull(Object? value) =>
      value is num ? value.toDouble() : null;

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static String _asString(Object? value) => value?.toString() ?? '';

  static String? _asStringOrNull(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final text = name?.toString();
    for (final value in values) {
      if (value.name == text) return value;
    }
    return fallback;
  }
}
