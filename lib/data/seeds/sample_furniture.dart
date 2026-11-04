import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/value_objects/size3.dart';

/// Mueble de ejemplo de la Fase 1:
/// repisa baja de 1000 x 750 x 450 mm con 2 puertas y 1 cajón.
const CabinetSpec sampleCabinetSpec = CabinetSpec(
  overallSize: Size3(width: 1000, height: 750, depth: 450),
  defaultMaterialId: 'mdf_18',
  settings: ConstructionSettings(
    panelThicknessMm: 18,
    backPanelThicknessMm: 5,
    doorGapMm: 2,
    shelfSetbackMm: 20,
    plinthHeightMm: 60,
  ),
  shelfCount: 2,
  doorCount: 2,
  drawerCount: 1,
  drawerHeightMm: 180,
);
