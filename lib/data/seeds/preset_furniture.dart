import 'dart:math' as math;

import '../../domain/entities/construction_settings.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/furniture_spec.dart';
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
