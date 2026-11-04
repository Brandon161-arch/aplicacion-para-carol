import '../value_objects/size3.dart';
import 'construction_settings.dart';

enum FurnitureType {
  cabinet,
  bookshelf,
  wardrobe,
  drawerUnit,
  desk,
  table,
  kitchenBase,
  kitchenWall,
  tvStand,
  custom;

  String get label => switch (this) {
    FurnitureType.cabinet => 'Mueble bajo',
    FurnitureType.bookshelf => 'Estantería',
    FurnitureType.wardrobe => 'Armario',
    FurnitureType.drawerUnit => 'Cajonera',
    FurnitureType.desk => 'Escritorio',
    FurnitureType.table => 'Mesa',
    FurnitureType.kitchenBase => 'Bajo cocina',
    FurnitureType.kitchenWall => 'Alto cocina',
    FurnitureType.tvStand => 'Mueble de TV',
    FurnitureType.custom => 'Personalizado',
  };
}

/// Parámetros de entrada del modelo. A partir de aquí se genera la geometría.
///
/// Es la fuente de verdad editable: si cambia una medida general, el mueble
/// se vuelve a generar.
sealed class FurnitureSpec {
  final FurnitureType type;
  final Size3 overallSize;
  final String defaultMaterialId;
  final ConstructionSettings settings;

  const FurnitureSpec({
    required this.type,
    required this.overallSize,
    required this.defaultMaterialId,
    required this.settings,
  });
}

/// Especificación del mueble bajo con puertas y cajón de la Fase 1.
class CabinetSpec extends FurnitureSpec {
  final int shelfCount;
  final int doorCount;
  final int drawerCount;
  final double drawerHeightMm;

  const CabinetSpec({
    required super.overallSize,
    required super.defaultMaterialId,
    required super.settings,
    this.shelfCount = 2,
    this.doorCount = 2,
    this.drawerCount = 1,
    this.drawerHeightMm = 180,
  }) : super(type: FurnitureType.cabinet);

  CabinetSpec copyWith({
    Size3? overallSize,
    String? defaultMaterialId,
    ConstructionSettings? settings,
    int? shelfCount,
    int? doorCount,
    int? drawerCount,
    double? drawerHeightMm,
  }) => CabinetSpec(
    overallSize: overallSize ?? this.overallSize,
    defaultMaterialId: defaultMaterialId ?? this.defaultMaterialId,
    settings: settings ?? this.settings,
    shelfCount: shelfCount ?? this.shelfCount,
    doorCount: doorCount ?? this.doorCount,
    drawerCount: drawerCount ?? this.drawerCount,
    drawerHeightMm: drawerHeightMm ?? this.drawerHeightMm,
  );
}
