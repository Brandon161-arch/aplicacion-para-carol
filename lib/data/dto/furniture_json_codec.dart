import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/part.dart';
import '../../domain/entities/saved_furniture.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';

/// Serialización de muebles a JSON.
///
/// Se guardan las piezas y los parámetros geométricos. Las uniones y los
/// mecanismos se reconstruyen o se añaden en fases posteriores; el despiece,
/// las plantillas y la vista 3D funcionan solo con las piezas.
abstract final class FurnitureJsonCodec {
  static const int schemaVersion = 1;

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
  };

  static Furniture furnitureFromJson(Map<String, dynamic> json) {
    final overall = _asMap(json['overallSize']);
    final settings = _asMap(json['settings']);
    final parts = _asList(json['parts'])
        .map((part) => partFromJson(_asMap(part)))
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
      schemaVersion: _asInt(json['schemaVersion']),
    );
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

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static String _asString(Object? value) => value?.toString() ?? '';

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
