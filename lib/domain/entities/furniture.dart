import '../value_objects/size3.dart';
import 'construction_settings.dart';
import 'furniture_spec.dart';
import 'hardware_item.dart';
import 'joint.dart';
import 'mechanism.dart';
import 'part.dart';

/// Modelo paramétrico generado.
///
/// Todo lo demás (despiece, planos, corte, herrajes y costos) se deriva de
/// esta clase; no se guardan totales duplicados.
class Furniture {
  final String id;
  final String name;
  final FurnitureType type;
  final Size3 overallSize;
  final ConstructionSettings settings;
  final List<Part> parts;
  final List<Joint> joints;
  final List<HardwareItem> manualHardware;
  final List<Mechanism> mechanisms;

  /// Versión del esquema para migraciones futuras.
  final int schemaVersion;

  const Furniture({
    required this.id,
    required this.name,
    required this.type,
    required this.overallSize,
    required this.settings,
    required this.parts,
    this.joints = const [],
    this.manualHardware = const [],
    this.mechanisms = const [],
    this.schemaVersion = 1,
  });

  Part? partById(String id) {
    for (final part in parts) {
      if (part.id == id) return part;
    }
    return null;
  }

  Iterable<Part> partsOfKind(PartKind kind) =>
      parts.where((part) => part.kind == kind);

  int get partCount => parts.length;
}
