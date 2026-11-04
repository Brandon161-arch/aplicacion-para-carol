import 'dart:math' as math;

import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
import '../../domain/entities/hardware_item.dart';
import '../../domain/entities/joint.dart';
import '../../domain/entities/mechanism.dart';
import '../../domain/entities/part.dart';
import '../../domain/generators/cabinet_doors_drawer_generator.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import 'material_seed.dart';
import 'sample_furniture.dart';

/// Mueble de ejemplo mostrado en la sección "Explorar".
class PresetFurniture {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final Furniture furniture;

  const PresetFurniture({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.furniture,
  });
}

List<PresetFurniture> buildPresetFurniture() {
  const generator = CabinetDoorsDrawerGenerator();

  Furniture cabinet(CabinetSpec spec) =>
      generator.generate(spec: spec, catalog: sampleMaterialCatalog);

  final repisa = cabinet(sampleCabinetSpec);
  final armario = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 900, height: 1900, depth: 550),
      defaultMaterialId: 'mdf_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 20,
        plinthHeightMm: 80,
      ),
      shelfCount: 4,
      doorCount: 2,
      drawerCount: 1,
      drawerHeightMm: 200,
    ),
  );
  final tv = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 1500, height: 500, depth: 420),
      defaultMaterialId: 'mdf_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 20,
        plinthHeightMm: 60,
      ),
      shelfCount: 1,
      doorCount: 2,
      drawerCount: 1,
      drawerHeightMm: 140,
    ),
  );
  final kitchenBase = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 800, height: 850, depth: 570),
      defaultMaterialId: 'mdf_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 20,
        plinthHeightMm: 100,
      ),
      shelfCount: 1,
      doorCount: 2,
      drawerCount: 1,
      drawerHeightMm: 160,
    ),
  );
  final bathroomCabinet = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 700, height: 600, depth: 350),
      defaultMaterialId: 'particleboard_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 15,
        plinthHeightMm: 80,
      ),
      shelfCount: 1,
      doorCount: 2,
      drawerCount: 1,
      drawerHeightMm: 120,
    ),
  );
  final shoeCabinet = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 900, height: 500, depth: 350),
      defaultMaterialId: 'particleboard_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 15,
        plinthHeightMm: 60,
      ),
      shelfCount: 3,
      doorCount: 2,
      drawerCount: 1,
      drawerHeightMm: 100,
    ),
  );
  final nightstand = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 450, height: 600, depth: 400),
      defaultMaterialId: 'mdf_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 20,
        plinthHeightMm: 60,
      ),
      shelfCount: 1,
      doorCount: 1,
      drawerCount: 1,
      drawerHeightMm: 140,
    ),
  );
  final openCabinet = cabinet(
    const CabinetSpec(
      overallSize: Size3(width: 1000, height: 850, depth: 400),
      defaultMaterialId: 'mdf_18',
      settings: ConstructionSettings(
        panelThicknessMm: 18,
        backPanelThicknessMm: 5,
        doorGapMm: 2,
        shelfSetbackMm: 20,
        plinthHeightMm: 60,
      ),
      shelfCount: 3,
      doorCount: 0,
      drawerCount: 1,
      drawerHeightMm: 160,
    ),
  );
  final drawerChest = _drawerChest();

  return [
    PresetFurniture(
      id: 'preset_repisa',
      name: 'Repisa baja con puertas',
      description:
          'Mueble bajo de 1000 x 750 x 450 mm con dos puertas y un cajón.',
      tags: const ['repisa', 'puertas', 'cajón', 'sala'],
      furniture: repisa,
    ),
    PresetFurniture(
      id: 'preset_armario',
      name: 'Armario 2 puertas',
      description: 'Armario alto de 900 x 1900 x 550 mm con cajón superior.',
      tags: const ['armario', 'dormitorio', 'puertas'],
      furniture: armario,
    ),
    PresetFurniture(
      id: 'preset_estanteria',
      name: 'Estantería abierta',
      description: 'Estantería de 900 x 1800 x 300 mm con cuatro estantes.',
      tags: const ['estantería', 'libros', 'abierta'],
      furniture: _openBookshelf(),
    ),
    PresetFurniture(
      id: 'preset_escritorio',
      name: 'Escritorio recto',
      description: 'Escritorio de 1200 x 750 x 600 mm con cuatro patas.',
      tags: const ['escritorio', 'oficina', 'estudio'],
      furniture: _desk(),
    ),
    PresetFurniture(
      id: 'preset_mesa',
      name: 'Mesa comedor',
      description: 'Mesa de 900 x 760 x 900 mm para cuatro puestos.',
      tags: const ['mesa', 'comedor', 'cocina'],
      furniture: _diningTable(),
    ),
    PresetFurniture(
      id: 'preset_tv',
      name: 'Mueble para TV',
      description: 'Mueble bajo y ancho de 1500 x 500 x 420 mm.',
      tags: const ['tv', 'sala', 'puertas', 'cajón'],
      furniture: tv,
    ),
    PresetFurniture(
      id: 'preset_cocina_baja',
      name: 'Mueble bajo de cocina',
      description: 'Bajo de 800 x 850 x 570 mm con cajón, puertas y estante.',
      tags: const ['cocina', 'bajo', 'puertas', 'cajón'],
      furniture: kitchenBase,
    ),
    PresetFurniture(
      id: 'preset_bano',
      name: 'Mueble de baño',
      description: 'Mueble compacto de 700 x 600 x 350 mm para baño.',
      tags: const ['baño', 'vanitorio', 'puertas'],
      furniture: bathroomCabinet,
    ),
    PresetFurniture(
      id: 'preset_zapatera',
      name: 'Zapatera baja',
      description:
          'Zapatera de 900 x 500 x 350 mm con tres estantes interiores.',
      tags: const ['zapatera', 'dormitorio', 'almacenamiento'],
      furniture: shoeCabinet,
    ),
    PresetFurniture(
      id: 'preset_mesa_noche',
      name: 'Mesa de noche',
      description: 'Mesita de 450 x 600 x 400 mm con cajón, puerta y estante.',
      tags: const ['mesa de noche', 'dormitorio', 'cajón'],
      furniture: nightstand,
    ),
    PresetFurniture(
      id: 'preset_bajo_abierto',
      name: 'Mueble bajo abierto',
      description:
          'Mueble de 1000 x 850 x 400 mm con cajón y repisas abiertas.',
      tags: const ['repisa', 'abierto', 'sala'],
      furniture: openCabinet,
    ),
    PresetFurniture(
      id: 'preset_mesa_centro',
      name: 'Mesa de centro',
      description: 'Mesa baja de 1000 x 420 x 600 mm con cuatro patas.',
      tags: const ['mesa', 'sala', 'centro'],
      furniture: _coffeeTable(),
    ),
    PresetFurniture(
      id: 'preset_cajonera',
      name: 'Cajonera de 3 cajones',
      description: 'Cajonera de 800 x 900 x 450 mm con tres cajones iguales.',
      tags: const ['cajonera', 'cajones', 'dormitorio'],
      furniture: drawerChest,
    ),
  ];
}

Map<PanelEdge, EdgeBanding> _banding(Set<PanelEdge> edges) => {
  for (final edge in edges) edge: const EdgeBanding(materialId: 'pvc_edge'),
};

Furniture _openBookshelf() {
  const width = 900.0;
  const height = 1800.0;
  const depth = 300.0;
  const thickness = 18.0;
  const backThickness = 5.0;
  const setback = 20.0;
  const shelfCount = 4;
  final bodyDepth = depth - backThickness;
  final innerWidth = width - 2 * thickness;
  final parts = <Part>[];

  parts.addAll([
    Part(
      id: 'shelf_side_left',
      name: 'Lateral',
      kind: PartKind.sidePanel,
      size: const Size3(width: thickness, height: height, depth: depth),
      cutSize: const CutSize(
        length: height,
        width: depth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      position: Vector3.zero,
      edgeBanding: _banding(const {PanelEdge.longEdge1}),
    ),
    Part(
      id: 'shelf_side_right',
      name: 'Lateral',
      kind: PartKind.sidePanel,
      size: const Size3(width: thickness, height: height, depth: depth),
      cutSize: const CutSize(
        length: height,
        width: depth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      position: const Vector3(width - thickness, 0, 0),
      edgeBanding: _banding(const {PanelEdge.longEdge1}),
    ),
    Part(
      id: 'shelf_bottom',
      name: 'Base',
      kind: PartKind.bottomPanel,
      size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
      cutSize: CutSize(
        length: innerWidth,
        width: bodyDepth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      position: const Vector3(thickness, 0, 0),
      edgeBanding: _banding(const {PanelEdge.longEdge1}),
    ),
    Part(
      id: 'shelf_top',
      name: 'Tapa',
      kind: PartKind.topPanel,
      size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
      cutSize: CutSize(
        length: innerWidth,
        width: bodyDepth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      position: Vector3(thickness, height - thickness, 0),
      edgeBanding: _banding(const {PanelEdge.longEdge1}),
    ),
    Part(
      id: 'shelf_back',
      name: 'Fondo',
      kind: PartKind.backPanel,
      size: Size3(
        width: innerWidth,
        height: height - 2 * thickness,
        depth: backThickness,
      ),
      cutSize: CutSize(
        length: innerWidth,
        width: height - 2 * thickness,
        thickness: backThickness,
      ),
      materialId: 'mdf_5',
      position: Vector3(thickness, thickness, depth - backThickness),
      structural: false,
    ),
  ]);

  final totalSpace = height - 2 * thickness;
  final gap = (totalSpace - shelfCount * thickness) / (shelfCount + 1);
  final shelfWidth = innerWidth - 2;
  final shelfDepth = math.max(10.0, bodyDepth - setback);
  for (var index = 0; index < shelfCount; index++) {
    final y = thickness + gap + index * (thickness + gap);
    parts.add(
      Part(
        id: 'shelf_board_$index',
        name: 'Estante',
        kind: PartKind.shelf,
        size: Size3(width: shelfWidth, height: thickness, depth: shelfDepth),
        cutSize: CutSize(
          length: shelfWidth,
          width: shelfDepth,
          thickness: thickness,
        ),
        materialId: 'mdf_18',
        position: Vector3(thickness + 1, y, setback),
        grain: GrainDirection.alongLength,
        edgeBanding: _banding(const {PanelEdge.longEdge1}),
        structural: false,
      ),
    );
  }

  return Furniture(
    id: 'preset_estanteria_model',
    name: 'Estantería abierta',
    type: FurnitureType.bookshelf,
    overallSize: const Size3(width: width, height: height, depth: depth),
    settings: const ConstructionSettings(
      panelThicknessMm: thickness,
      backPanelThicknessMm: backThickness,
      doorGapMm: 0,
      shelfSetbackMm: setback,
      plinthHeightMm: 0,
    ),
    parts: parts,
  );
}

Part _leg({
  required String id,
  required Vector3 position,
  required double heightMm,
  required double thicknessMm,
}) => Part(
  id: id,
  name: 'Pata',
  kind: PartKind.leg,
  size: Size3(width: thicknessMm, height: heightMm, depth: thicknessMm),
  cutSize: CutSize(
    length: heightMm,
    width: thicknessMm,
    thickness: thicknessMm,
  ),
  materialId: 'solid_wood_60',
  position: position,
  grain: GrainDirection.alongLength,
  structural: true,
);

Furniture _desk() {
  const width = 1200.0;
  const height = 750.0;
  const depth = 600.0;
  const legSize = 60.0;
  const topThickness = 25.0;
  const legHeight = height - topThickness;
  final parts = <Part>[
    Part(
      id: 'desk_top',
      name: 'Tablero',
      kind: PartKind.desktop,
      size: const Size3(width: width, height: topThickness, depth: depth),
      cutSize: const CutSize(
        length: width,
        width: depth,
        thickness: topThickness,
      ),
      materialId: 'mdf_25',
      position: const Vector3(0, legHeight, 0),
      grain: GrainDirection.alongLength,
      edgeBanding: _banding(const {
        PanelEdge.longEdge1,
        PanelEdge.shortEdge1,
        PanelEdge.shortEdge2,
      }),
    ),
    _leg(
      id: 'desk_leg_1',
      position: Vector3.zero,
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'desk_leg_2',
      position: const Vector3(width - legSize, 0, 0),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'desk_leg_3',
      position: const Vector3(0, 0, depth - legSize),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'desk_leg_4',
      position: const Vector3(width - legSize, 0, depth - legSize),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
  ];

  return Furniture(
    id: 'preset_escritorio_model',
    name: 'Escritorio recto',
    type: FurnitureType.desk,
    overallSize: const Size3(width: width, height: height, depth: depth),
    settings: const ConstructionSettings(
      panelThicknessMm: 18,
      backPanelThicknessMm: 5,
      doorGapMm: 0,
      shelfSetbackMm: 0,
      plinthHeightMm: 0,
    ),
    parts: parts,
  );
}

Furniture _diningTable() {
  const width = 900.0;
  const height = 760.0;
  const depth = 900.0;
  const legSize = 60.0;
  const topThickness = 25.0;
  const legHeight = height - topThickness;
  const inset = 40.0;
  final parts = <Part>[
    Part(
      id: 'table_top',
      name: 'Tablero',
      kind: PartKind.desktop,
      size: const Size3(width: width, height: topThickness, depth: depth),
      cutSize: const CutSize(
        length: width,
        width: depth,
        thickness: topThickness,
      ),
      materialId: 'mdf_25',
      position: const Vector3(0, legHeight, 0),
      grain: GrainDirection.alongLength,
      edgeBanding: _banding(const {
        PanelEdge.longEdge1,
        PanelEdge.longEdge2,
        PanelEdge.shortEdge1,
        PanelEdge.shortEdge2,
      }),
    ),
    _leg(
      id: 'table_leg_1',
      position: const Vector3(inset, 0, inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'table_leg_2',
      position: const Vector3(width - legSize - inset, 0, inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'table_leg_3',
      position: const Vector3(inset, 0, depth - legSize - inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'table_leg_4',
      position: const Vector3(
        width - legSize - inset,
        0,
        depth - legSize - inset,
      ),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
  ];

  return Furniture(
    id: 'preset_mesa_model',
    name: 'Mesa comedor',
    type: FurnitureType.table,
    overallSize: const Size3(width: width, height: height, depth: depth),
    settings: const ConstructionSettings(
      panelThicknessMm: 18,
      backPanelThicknessMm: 5,
      doorGapMm: 0,
      shelfSetbackMm: 0,
      plinthHeightMm: 0,
    ),
    parts: parts,
  );
}

Furniture _drawerChest() {
  const width = 800.0;
  const height = 900.0;
  const depth = 450.0;
  const thickness = 18.0;
  const backThickness = 5.0;
  const drawerThickness = 15.0;
  const gap = 2.0;
  const plinthHeight = 60.0;
  const drawerCount = 3;
  const slideLength = 400.0;

  final innerWidth = width - 2 * thickness;
  final bodyDepth = depth - backThickness;
  final bottomTop = plinthHeight + thickness;
  final topBottom = height - thickness;
  final frontZoneHeight = topBottom - bottomTop - 2 * gap;
  final frontHeight = (frontZoneHeight - (drawerCount - 1) * gap) / drawerCount;
  final frontWidth = innerWidth - 2 * gap;
  final boxWidth = innerWidth - 25;
  const slideClearance = 12.5;
  final boxLeftX = thickness + slideClearance;
  final boxRightX = boxLeftX + boxWidth - drawerThickness;
  final boxBackWidth = boxWidth - 2 * drawerThickness;
  final boxFrontZ = thickness;
  final boxBackZ = boxFrontZ + slideLength;
  final boxBottomDepth = slideLength - drawerThickness;

  final parts = <Part>[];
  final joints = <Joint>[];
  final mechanisms = <Mechanism>[];

  Part makePart({
    required String id,
    required String name,
    required PartKind kind,
    required Vector3 position,
    required Size3 size,
    required CutSize cutSize,
    required String materialId,
    GrainDirection grain = GrainDirection.none,
    Set<PanelEdge> bandedEdges = const {},
    bool structural = true,
  }) => Part(
    id: id,
    name: name,
    kind: kind,
    size: size,
    cutSize: cutSize,
    materialId: materialId,
    position: position,
    grain: grain,
    edgeBanding: _banding(bandedEdges),
    structural: structural,
  );

  parts.addAll([
    makePart(
      id: 'chest_side_left',
      name: 'Lateral',
      kind: PartKind.sidePanel,
      position: Vector3.zero,
      size: const Size3(width: thickness, height: height, depth: depth),
      cutSize: const CutSize(
        length: height,
        width: depth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      bandedEdges: const {PanelEdge.longEdge1},
    ),
    makePart(
      id: 'chest_side_right',
      name: 'Lateral',
      kind: PartKind.sidePanel,
      position: const Vector3(width - thickness, 0, 0),
      size: const Size3(width: thickness, height: height, depth: depth),
      cutSize: const CutSize(
        length: height,
        width: depth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      bandedEdges: const {PanelEdge.longEdge1},
    ),
    makePart(
      id: 'chest_bottom',
      name: 'Base',
      kind: PartKind.bottomPanel,
      position: const Vector3(thickness, plinthHeight, 0),
      size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
      cutSize: CutSize(
        length: innerWidth,
        width: bodyDepth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      bandedEdges: const {PanelEdge.longEdge1},
    ),
    makePart(
      id: 'chest_top',
      name: 'Tapa',
      kind: PartKind.topPanel,
      position: const Vector3(thickness, height - thickness, 0),
      size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
      cutSize: CutSize(
        length: innerWidth,
        width: bodyDepth,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      bandedEdges: const {PanelEdge.longEdge1},
    ),
    makePart(
      id: 'chest_back',
      name: 'Fondo',
      kind: PartKind.backPanel,
      position: Vector3(thickness, bottomTop, depth - backThickness),
      size: Size3(
        width: innerWidth,
        height: height - plinthHeight - 2 * thickness,
        depth: backThickness,
      ),
      cutSize: CutSize(
        length: innerWidth,
        width: height - plinthHeight - 2 * thickness,
        thickness: backThickness,
      ),
      materialId: 'mdf_5',
      structural: false,
    ),
    makePart(
      id: 'chest_plinth',
      name: 'Zócalo',
      kind: PartKind.plinth,
      position: const Vector3(thickness, 0, 0),
      size: const Size3(
        width: width - 2 * thickness,
        height: plinthHeight,
        depth: thickness,
      ),
      cutSize: const CutSize(
        length: width - 2 * thickness,
        width: plinthHeight,
        thickness: thickness,
      ),
      materialId: 'mdf_18',
      bandedEdges: const {PanelEdge.longEdge1},
    ),
  ]);

  for (var index = 0; index < drawerCount - 1; index++) {
    final frontY = bottomTop + gap + index * (frontHeight + gap);
    final dividerY = frontY + frontHeight;
    parts.add(
      makePart(
        id: 'chest_divider_$index',
        name: 'División',
        kind: PartKind.divider,
        position: Vector3(thickness, dividerY, thickness),
        size: Size3(
          width: innerWidth,
          height: thickness,
          depth: bodyDepth - thickness,
        ),
        cutSize: CutSize(
          length: innerWidth,
          width: bodyDepth - thickness,
          thickness: thickness,
        ),
        materialId: 'mdf_18',
        bandedEdges: const {PanelEdge.longEdge1},
      ),
    );
  }

  const confirmat = FastenerSpec(
    kind: HardwareKind.confirmat,
    diameterMm: 7,
    lengthMm: 50,
    label: 'Confirmat 7 x 50 mm',
  );
  const dowel = FastenerSpec(
    kind: HardwareKind.dowel,
    diameterMm: 8,
    lengthMm: 30,
    label: 'Tarugo 8 x 30 mm',
  );
  const nail = FastenerSpec(
    kind: HardwareKind.nail,
    diameterMm: 1.6,
    lengthMm: 30,
    label: 'Clavo 1,6 x 30 mm',
  );

  void addJoint(
    String id,
    JointType type,
    String partA,
    String partB,
    int count,
    FastenerSpec fastener,
  ) {
    joints.add(
      Joint(
        id: id,
        type: type,
        partAId: partA,
        partBId: partB,
        count: count,
        fastener: fastener,
      ),
    );
  }

  addJoint(
    'chest_left_bottom',
    JointType.confirmat,
    'chest_side_left',
    'chest_bottom',
    3,
    confirmat,
  );
  addJoint(
    'chest_right_bottom',
    JointType.confirmat,
    'chest_side_right',
    'chest_bottom',
    3,
    confirmat,
  );
  addJoint(
    'chest_left_top',
    JointType.confirmat,
    'chest_side_left',
    'chest_top',
    3,
    confirmat,
  );
  addJoint(
    'chest_right_top',
    JointType.confirmat,
    'chest_side_right',
    'chest_top',
    3,
    confirmat,
  );
  addJoint(
    'chest_back_left',
    JointType.nail,
    'chest_back',
    'chest_side_left',
    8,
    nail,
  );
  addJoint(
    'chest_back_right',
    JointType.nail,
    'chest_back',
    'chest_side_right',
    8,
    nail,
  );
  addJoint(
    'chest_back_bottom',
    JointType.nail,
    'chest_back',
    'chest_bottom',
    6,
    nail,
  );
  addJoint(
    'chest_back_top',
    JointType.nail,
    'chest_back',
    'chest_top',
    6,
    nail,
  );

  for (var index = 0; index < drawerCount; index++) {
    final frontY = bottomTop + gap + index * (frontHeight + gap);
    final frontId = 'chest_drawer_${index}_front';
    final leftId = 'chest_drawer_${index}_side_left';
    final rightId = 'chest_drawer_${index}_side_right';
    final backId = 'chest_drawer_${index}_back';
    final bottomId = 'chest_drawer_${index}_bottom';
    final boxHeight = frontHeight - 40;
    final boxY = frontY + (frontHeight - boxHeight) / 2;
    final bottomY = boxY + 10;

    parts.addAll([
      makePart(
        id: frontId,
        name: 'Frente de cajón',
        kind: PartKind.drawerFront,
        position: Vector3(thickness + gap, frontY, 0),
        size: Size3(width: frontWidth, height: frontHeight, depth: thickness),
        cutSize: CutSize(
          length: frontWidth,
          width: frontHeight,
          thickness: thickness,
        ),
        materialId: 'mdf_18',
        grain: GrainDirection.alongLength,
        bandedEdges: const {
          PanelEdge.longEdge1,
          PanelEdge.longEdge2,
          PanelEdge.shortEdge1,
          PanelEdge.shortEdge2,
        },
        structural: false,
      ),
      makePart(
        id: leftId,
        name: 'Lado de cajón',
        kind: PartKind.drawerSide,
        position: Vector3(boxLeftX, boxY, boxFrontZ),
        size: Size3(
          width: drawerThickness,
          height: boxHeight,
          depth: slideLength,
        ),
        cutSize: CutSize(
          length: slideLength,
          width: boxHeight,
          thickness: drawerThickness,
        ),
        materialId: 'mdf_15',
        grain: GrainDirection.alongLength,
        structural: false,
      ),
      makePart(
        id: rightId,
        name: 'Lado de cajón',
        kind: PartKind.drawerSide,
        position: Vector3(boxRightX, boxY, boxFrontZ),
        size: Size3(
          width: drawerThickness,
          height: boxHeight,
          depth: slideLength,
        ),
        cutSize: CutSize(
          length: slideLength,
          width: boxHeight,
          thickness: drawerThickness,
        ),
        materialId: 'mdf_15',
        grain: GrainDirection.alongLength,
        structural: false,
      ),
      makePart(
        id: backId,
        name: 'Trasera de cajón',
        kind: PartKind.drawerBack,
        position: Vector3(
          boxLeftX + drawerThickness,
          boxY,
          boxBackZ - drawerThickness,
        ),
        size: Size3(
          width: boxBackWidth,
          height: boxHeight,
          depth: drawerThickness,
        ),
        cutSize: CutSize(
          length: boxBackWidth,
          width: boxHeight,
          thickness: drawerThickness,
        ),
        materialId: 'mdf_15',
        grain: GrainDirection.alongLength,
        structural: false,
      ),
      makePart(
        id: bottomId,
        name: 'Fondo de cajón',
        kind: PartKind.drawerBottom,
        position: Vector3(boxLeftX + drawerThickness, bottomY, boxFrontZ),
        size: Size3(
          width: boxBackWidth,
          height: backThickness,
          depth: boxBottomDepth,
        ),
        cutSize: CutSize(
          length: boxBackWidth,
          width: boxBottomDepth,
          thickness: backThickness,
        ),
        materialId: 'mdf_5',
        structural: false,
      ),
    ]);

    mechanisms.add(
      DrawerMechanism(
        id: 'chest_drawer_mechanism_$index',
        partIds: [frontId, leftId, rightId, backId, bottomId],
        frontPartId: frontId,
        boxPartIds: [leftId, rightId, backId, bottomId],
        travelMm: slideLength,
        slideSpec: 'Corredera telescópica ${slideLength.round()} mm',
      ),
    );
    addJoint(
      'chest_drawer_${index}_front_left',
      JointType.buttScrew,
      frontId,
      leftId,
      2,
      confirmat,
    );
    addJoint(
      'chest_drawer_${index}_front_right',
      JointType.buttScrew,
      frontId,
      rightId,
      2,
      confirmat,
    );
    addJoint(
      'chest_drawer_${index}_left_back',
      JointType.dowel,
      leftId,
      backId,
      2,
      dowel,
    );
    addJoint(
      'chest_drawer_${index}_right_back',
      JointType.dowel,
      rightId,
      backId,
      2,
      dowel,
    );
    addJoint(
      'chest_drawer_${index}_left_bottom',
      JointType.dowel,
      leftId,
      bottomId,
      2,
      dowel,
    );
    addJoint(
      'chest_drawer_${index}_right_bottom',
      JointType.dowel,
      rightId,
      bottomId,
      2,
      dowel,
    );
  }

  for (var index = 0; index < drawerCount - 1; index++) {
    final dividerId = 'chest_divider_$index';
    addJoint(
      'chest_divider_left_$index',
      JointType.confirmat,
      'chest_side_left',
      dividerId,
      2,
      confirmat,
    );
    addJoint(
      'chest_divider_right_$index',
      JointType.confirmat,
      'chest_side_right',
      dividerId,
      2,
      confirmat,
    );
  }

  return Furniture(
    id: 'preset_drawer_chest_model',
    name: 'Cajonera de 3 cajones',
    type: FurnitureType.drawerUnit,
    overallSize: const Size3(width: width, height: height, depth: depth),
    settings: const ConstructionSettings(
      panelThicknessMm: thickness,
      backPanelThicknessMm: backThickness,
      doorGapMm: gap,
      shelfSetbackMm: 0,
      plinthHeightMm: plinthHeight,
    ),
    parts: parts,
    joints: joints,
    mechanisms: mechanisms,
  );
}

Furniture _coffeeTable() {
  const width = 1000.0;
  const height = 420.0;
  const depth = 600.0;
  const legSize = 60.0;
  const topThickness = 25.0;
  const legHeight = height - topThickness;
  const inset = 30.0;
  final parts = <Part>[
    Part(
      id: 'coffee_table_top',
      name: 'Tablero',
      kind: PartKind.desktop,
      size: const Size3(width: width, height: topThickness, depth: depth),
      cutSize: const CutSize(
        length: width,
        width: depth,
        thickness: topThickness,
      ),
      materialId: 'mdf_25',
      position: const Vector3(0, legHeight, 0),
      grain: GrainDirection.alongLength,
      edgeBanding: _banding(const {
        PanelEdge.longEdge1,
        PanelEdge.longEdge2,
        PanelEdge.shortEdge1,
        PanelEdge.shortEdge2,
      }),
    ),
    _leg(
      id: 'coffee_leg_1',
      position: const Vector3(inset, 0, inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'coffee_leg_2',
      position: const Vector3(width - legSize - inset, 0, inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'coffee_leg_3',
      position: const Vector3(inset, 0, depth - legSize - inset),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
    _leg(
      id: 'coffee_leg_4',
      position: const Vector3(
        width - legSize - inset,
        0,
        depth - legSize - inset,
      ),
      heightMm: legHeight,
      thicknessMm: legSize,
    ),
  ];

  return Furniture(
    id: 'preset_coffee_table_model',
    name: 'Mesa de centro',
    type: FurnitureType.table,
    overallSize: const Size3(width: width, height: height, depth: depth),
    settings: const ConstructionSettings(
      panelThicknessMm: 18,
      backPanelThicknessMm: 5,
      doorGapMm: 0,
      shelfSetbackMm: 0,
      plinthHeightMm: 0,
    ),
    parts: parts,
  );
}
