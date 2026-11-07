import 'dart:math' as math;

import '../entities/furniture.dart';
import '../entities/furniture_spec.dart';
import '../entities/hardware_item.dart';
import '../entities/joint.dart';
import '../entities/material.dart';
import '../entities/mechanism.dart';
import '../entities/part.dart';
import '../value_objects/cut_size.dart';
import '../value_objects/size3.dart';
import '../value_objects/vector3.dart';
import 'furniture_generator.dart';

/// Genera un mueble bajo con 2 puertas abatibles y 1 cajón superior.
///
/// Construcción de la Fase 1:
/// - Carcasa de paneles rectangulares.
/// - Fondo de 5 mm embutido entre laterales, base y tapa.
/// - Zócalo frontal.
/// - División horizontal que separa el cajón de las puertas.
/// - Estantes ajustables en el compartimento inferior.
/// - Puertas y frente de cajón alineados (montaje embutido).
///
/// Todas las piezas son ortogonales y se definen por su caja en el mundo.
class CabinetDoorsDrawerGenerator implements FurnitureGenerator {
  const CabinetDoorsDrawerGenerator();

  static const double _drawerPanelThicknessMm = 15;
  static const double _slideSideClearanceMm = 12.5;
  static const List<double> _slideLengthsMm = [
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    550,
  ];

  @override
  FurnitureType get type => FurnitureType.cabinet;

  @override
  Furniture generate({
    required FurnitureSpec spec,
    required MaterialCatalog catalog,
  }) {
    if (spec is! CabinetSpec) {
      throw ArgumentError(
        'CabinetDoorsDrawerGenerator solo puede generar un CabinetSpec.',
      );
    }

    // Se limitan valores extremos para no producir geometría negativa.
    // El validador muestra los errores al usuario; el visor nunca debe caerse.
    final width = math.max(100.0, spec.overallSize.width);
    final height = math.max(100.0, spec.overallSize.height);
    final depth = math.max(50.0, spec.overallSize.depth);
    final thickness = math.max(1.0, spec.settings.panelThicknessMm);
    final backThickness = math.max(1.0, spec.settings.backPanelThicknessMm);
    final gap = math.max(0.0, spec.settings.doorGapMm);
    final plinthHeight = math.max(
      0.0,
      math.min(spec.settings.plinthHeightMm, height * 0.4),
    );
    final shelfSetback = math.max(0.0, spec.settings.shelfSetbackMm);

    final bodyMaterial =
        catalog.byId(spec.defaultMaterialId) ??
        catalog.findByThickness(thickness, category: MaterialCategory.mdf) ??
        catalog.sheetMaterials.first;
    final backMaterial =
        catalog.findByThickness(
          backThickness,
          category: MaterialCategory.mdf,
        ) ??
        bodyMaterial;
    final drawerMaterial =
        catalog.findByThickness(
          _drawerPanelThicknessMm,
          category: MaterialCategory.mdf,
        ) ??
        bodyMaterial;
    final edgeBandingMaterialId =
        catalog.byId('pvc_edge')?.id ?? bodyMaterial.id;

    final innerWidth = math.max(10.0, width - 2 * thickness);
    final bodyDepth = math.max(10.0, depth - backThickness);
    final backHeight = math.max(10.0, height - plinthHeight - 2 * thickness);
    final bottomPanelTop = plinthHeight + thickness;
    final topPanelBottom = height - thickness;

    final maxDrawerHeight = math.max(
      60.0,
      topPanelBottom - bottomPanelTop - 3 * thickness - 4 * gap - 120,
    );
    final drawerHeight = spec.drawerCount > 0
        ? math.max(0.0, math.min(spec.drawerHeightMm, maxDrawerHeight))
        : 0.0;
    final drawerTop = topPanelBottom - gap;
    final drawerBottom = drawerTop - drawerHeight;
    final dividerTop = drawerBottom - gap;
    final dividerBottom = dividerTop - thickness;
    final doorsTop = dividerBottom - gap;
    final doorsBottom = bottomPanelTop + gap;
    final doorHeight = math.max(10.0, doorsTop - doorsBottom);

    final doorCount = math.max(0, spec.doorCount);
    final doorWidth = doorCount == 0
        ? 0.0
        : math.max(10.0, (innerWidth - (doorCount + 1) * gap) / doorCount);

    final drawerFrontWidth = math.max(10.0, innerWidth - 2 * gap);
    final availableDrawerDepth = math.max(
      0.0,
      depth - backThickness - thickness - 12,
    );
    final slideLength = _chooseSlideLength(availableDrawerDepth);
    final boxDepth = math.max(50.0, slideLength);
    final boxHeight = math.max(60.0, drawerHeight - 40);
    final boxBottomY = drawerBottom + (drawerHeight - boxHeight) / 2;
    final boxOuterWidth = math.max(
      50.0,
      innerWidth - 2 * _slideSideClearanceMm,
    );
    final boxLeftX = thickness + _slideSideClearanceMm;
    final boxRightX = boxLeftX + boxOuterWidth - _drawerPanelThicknessMm;
    final boxBackWidth = math.max(
      10.0,
      boxOuterWidth - 2 * _drawerPanelThicknessMm,
    );
    final boxFrontZ = thickness;
    final boxBackZ = boxFrontZ + boxDepth;
    final boxBottomZ = boxFrontZ;
    final boxBottomDepth = math.max(10.0, boxDepth - _drawerPanelThicknessMm);
    final drawerBottomY = boxBottomY + 10;
    final drawerBottomThickness = backThickness;

    final parts = <Part>[];
    final joints = <Joint>[];
    final mechanisms = <Mechanism>[];

    Part buildPart({
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
    }) {
      return Part(
        id: id,
        name: name,
        kind: kind,
        size: size,
        cutSize: cutSize,
        materialId: materialId,
        position: position,
        grain: grain,
        edgeBanding: {
          for (final edge in bandedEdges)
            edge: EdgeBanding(materialId: edgeBandingMaterialId),
        },
        structural: structural,
      );
    }

    // ------------- Carcasa -------------
    parts.addAll([
      buildPart(
        id: 'side_left',
        name: 'Lateral',
        kind: PartKind.sidePanel,
        position: const Vector3(0, 0, 0),
        size: Size3(width: thickness, height: height, depth: depth),
        cutSize: CutSize(length: height, width: depth, thickness: thickness),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'side_right',
        name: 'Lateral',
        kind: PartKind.sidePanel,
        position: Vector3(width - thickness, 0, 0),
        size: Size3(width: thickness, height: height, depth: depth),
        cutSize: CutSize(length: height, width: depth, thickness: thickness),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'bottom_panel',
        name: 'Base',
        kind: PartKind.bottomPanel,
        position: Vector3(thickness, plinthHeight, 0),
        size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
        cutSize: CutSize(
          length: innerWidth,
          width: bodyDepth,
          thickness: thickness,
        ),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'top_panel',
        name: 'Tapa',
        kind: PartKind.topPanel,
        position: Vector3(thickness, height - thickness, 0),
        size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
        cutSize: CutSize(
          length: innerWidth,
          width: bodyDepth,
          thickness: thickness,
        ),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'divider_panel',
        name: 'División',
        kind: PartKind.divider,
        position: Vector3(thickness, dividerBottom, 0),
        size: Size3(width: innerWidth, height: thickness, depth: bodyDepth),
        cutSize: CutSize(
          length: innerWidth,
          width: bodyDepth,
          thickness: thickness,
        ),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'plinth',
        name: 'Zócalo',
        kind: PartKind.plinth,
        position: Vector3(thickness, 0, 0),
        size: Size3(width: innerWidth, height: plinthHeight, depth: thickness),
        cutSize: CutSize(
          length: innerWidth,
          width: plinthHeight,
          thickness: thickness,
        ),
        materialId: bodyMaterial.id,
        bandedEdges: const {PanelEdge.longEdge1},
      ),
      buildPart(
        id: 'back_panel',
        name: 'Fondo',
        kind: PartKind.backPanel,
        position: Vector3(thickness, bottomPanelTop, depth - backThickness),
        size: Size3(
          width: innerWidth,
          height: backHeight,
          depth: backThickness,
        ),
        cutSize: CutSize(
          length: innerWidth,
          width: backHeight,
          thickness: backThickness,
        ),
        materialId: backMaterial.id,
        structural: false,
      ),
    ]);

    // ------------- Estantes ajustables -------------
    final shelfCount = math.max(0, math.min(spec.shelfCount, 8));
    if (shelfCount > 0) {
      final shelfSpace = math.max(0.0, dividerBottom - bottomPanelTop);
      final shelfGap = math.max(
        0.0,
        (shelfSpace - shelfCount * thickness) / (shelfCount + 1),
      );
      final shelfWidth = math.max(10.0, innerWidth - 2);
      final shelfZ = math.max(0.0, math.min(shelfSetback, bodyDepth - 10));
      final shelfDepth = math.max(10.0, bodyDepth - shelfZ);

      for (var index = 0; index < shelfCount; index++) {
        final shelfY =
            bottomPanelTop + shelfGap + index * (thickness + shelfGap);
        parts.add(
          buildPart(
            id: 'shelf_$index',
            name: 'Estante',
            kind: PartKind.shelf,
            position: Vector3(thickness + 1, shelfY, shelfZ),
            size: Size3(
              width: shelfWidth,
              height: thickness,
              depth: shelfDepth,
            ),
            cutSize: CutSize(
              length: shelfWidth,
              width: shelfDepth,
              thickness: thickness,
            ),
            materialId: bodyMaterial.id,
            grain: GrainDirection.alongLength,
            bandedEdges: const {PanelEdge.longEdge1},
            structural: false,
          ),
        );
      }
    }

    // ------------- Puertas -------------
    for (var index = 0; index < doorCount; index++) {
      final doorX = thickness + gap + index * (doorWidth + gap);
      final doorId = 'door_$index';
      parts.add(
        buildPart(
          id: doorId,
          name: 'Puerta',
          kind: PartKind.door,
          position: Vector3(doorX, doorsBottom, 0),
          size: Size3(width: doorWidth, height: doorHeight, depth: thickness),
          cutSize: CutSize(
            length: doorHeight,
            width: doorWidth,
            thickness: thickness,
          ),
          materialId: bodyMaterial.id,
          grain: GrainDirection.alongLength,
          bandedEdges: const {
            PanelEdge.longEdge1,
            PanelEdge.longEdge2,
            PanelEdge.shortEdge1,
            PanelEdge.shortEdge2,
          },
          structural: false,
        ),
      );

      mechanisms.add(
        HingedDoorMechanism(
          id: 'hinge_$index',
          partIds: [doorId],
          doorPartId: doorId,
          hingeSide: index == 0
              ? HingeSide.left
              : index == doorCount - 1
              ? HingeSide.right
              : HingeSide.left,
          hingeCount: doorHeight <= 900
              ? 2
              : doorHeight <= 1600
              ? 3
              : 4,
          hingeSpec: 'Bisagra de cazoleta 35 mm, apertura 110°',
        ),
      );
    }

    // ───────────── Cajón ─────────────
    if (spec.drawerCount > 0 && drawerHeight > 0) {
      final drawerFrontId = 'drawer_front';
      parts.add(
        buildPart(
          id: drawerFrontId,
          name: 'Frente de cajón',
          kind: PartKind.drawerFront,
          position: Vector3(thickness + gap, drawerBottom, 0),
          size: Size3(
            width: drawerFrontWidth,
            height: drawerHeight,
            depth: thickness,
          ),
          cutSize: CutSize(
            length: drawerFrontWidth,
            width: drawerHeight,
            thickness: thickness,
          ),
          materialId: bodyMaterial.id,
          grain: GrainDirection.alongLength,
          bandedEdges: const {
            PanelEdge.longEdge1,
            PanelEdge.longEdge2,
            PanelEdge.shortEdge1,
            PanelEdge.shortEdge2,
          },
          structural: false,
        ),
      );

      final drawerSideLeftId = 'drawer_side_left';
      final drawerSideRightId = 'drawer_side_right';
      final drawerBackId = 'drawer_back';
      final drawerBottomId = 'drawer_bottom';

      parts.addAll([
        buildPart(
          id: drawerSideLeftId,
          name: 'Lado de cajón',
          kind: PartKind.drawerSide,
          position: Vector3(boxLeftX, boxBottomY, boxFrontZ),
          size: Size3(
            width: _drawerPanelThicknessMm,
            height: boxHeight,
            depth: boxDepth,
          ),
          cutSize: CutSize(
            length: boxDepth,
            width: boxHeight,
            thickness: _drawerPanelThicknessMm,
          ),
          materialId: drawerMaterial.id,
          grain: GrainDirection.alongLength,
          structural: false,
        ),
        buildPart(
          id: drawerSideRightId,
          name: 'Lado de cajón',
          kind: PartKind.drawerSide,
          position: Vector3(boxRightX, boxBottomY, boxFrontZ),
          size: Size3(
            width: _drawerPanelThicknessMm,
            height: boxHeight,
            depth: boxDepth,
          ),
          cutSize: CutSize(
            length: boxDepth,
            width: boxHeight,
            thickness: _drawerPanelThicknessMm,
          ),
          materialId: drawerMaterial.id,
          grain: GrainDirection.alongLength,
          structural: false,
        ),
        buildPart(
          id: drawerBackId,
          name: 'Trasera de cajón',
          kind: PartKind.drawerBack,
          position: Vector3(
            boxLeftX + _drawerPanelThicknessMm,
            boxBottomY,
            boxBackZ - _drawerPanelThicknessMm,
          ),
          size: Size3(
            width: boxBackWidth,
            height: boxHeight,
            depth: _drawerPanelThicknessMm,
          ),
          cutSize: CutSize(
            length: boxBackWidth,
            width: boxHeight,
            thickness: _drawerPanelThicknessMm,
          ),
          materialId: drawerMaterial.id,
          grain: GrainDirection.alongLength,
          structural: false,
        ),
        buildPart(
          id: drawerBottomId,
          name: 'Fondo de cajón',
          kind: PartKind.drawerBottom,
          position: Vector3(
            boxLeftX + _drawerPanelThicknessMm,
            drawerBottomY,
            boxBottomZ,
          ),
          size: Size3(
            width: boxBackWidth,
            height: drawerBottomThickness,
            depth: boxBottomDepth,
          ),
          cutSize: CutSize(
            length: boxBackWidth,
            width: boxBottomDepth,
            thickness: drawerBottomThickness,
          ),
          materialId: backMaterial.id,
          structural: false,
        ),
      ]);

      mechanisms.add(
        DrawerMechanism(
          id: 'drawer_slide',
          partIds: [
            drawerFrontId,
            drawerSideLeftId,
            drawerSideRightId,
            drawerBackId,
            drawerBottomId,
          ],
          frontPartId: drawerFrontId,
          boxPartIds: [
            drawerSideLeftId,
            drawerSideRightId,
            drawerBackId,
            drawerBottomId,
          ],
          travelMm: slideLength,
          slideSpec: 'Corredera telescópica ${slideLength.round()} mm',
        ),
      );
    }

    // ------------- Uniones -------------
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
      String partB, {
      int count = 1,
      FastenerSpec? fastener,
    }) {
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
      'side_left_bottom',
      JointType.confirmat,
      'side_left',
      'bottom_panel',
      count: 3,
      fastener: confirmat,
    );
    addJoint(
      'side_right_bottom',
      JointType.confirmat,
      'side_right',
      'bottom_panel',
      count: 3,
      fastener: confirmat,
    );
    addJoint(
      'side_left_top',
      JointType.confirmat,
      'side_left',
      'top_panel',
      count: 3,
      fastener: confirmat,
    );
    addJoint(
      'side_right_top',
      JointType.confirmat,
      'side_right',
      'top_panel',
      count: 3,
      fastener: confirmat,
    );
    addJoint(
      'side_left_divider',
      JointType.confirmat,
      'side_left',
      'divider_panel',
      count: 2,
      fastener: confirmat,
    );
    addJoint(
      'side_right_divider',
      JointType.confirmat,
      'side_right',
      'divider_panel',
      count: 2,
      fastener: confirmat,
    );
    addJoint(
      'side_left_plinth',
      JointType.confirmat,
      'side_left',
      'plinth',
      count: 2,
      fastener: confirmat,
    );
    addJoint(
      'side_right_plinth',
      JointType.confirmat,
      'side_right',
      'plinth',
      count: 2,
      fastener: confirmat,
    );
    addJoint(
      'back_left',
      JointType.nail,
      'back_panel',
      'side_left',
      count: 8,
      fastener: nail,
    );
    addJoint(
      'back_right',
      JointType.nail,
      'back_panel',
      'side_right',
      count: 8,
      fastener: nail,
    );
    addJoint(
      'back_bottom',
      JointType.nail,
      'back_panel',
      'bottom_panel',
      count: 6,
      fastener: nail,
    );
    addJoint(
      'back_top',
      JointType.nail,
      'back_panel',
      'top_panel',
      count: 6,
      fastener: nail,
    );

    if (spec.drawerCount > 0 && drawerHeight > 0) {
      addJoint(
        'drawer_front_left',
        JointType.buttScrew,
        'drawer_front',
        'drawer_side_left',
        count: 2,
        fastener: confirmat,
      );
      addJoint(
        'drawer_front_right',
        JointType.buttScrew,
        'drawer_front',
        'drawer_side_right',
        count: 2,
        fastener: confirmat,
      );
      addJoint(
        'drawer_left_back',
        JointType.dowel,
        'drawer_side_left',
        'drawer_back',
        count: 2,
        fastener: dowel,
      );
      addJoint(
        'drawer_right_back',
        JointType.dowel,
        'drawer_side_right',
        'drawer_back',
        count: 2,
        fastener: dowel,
      );
      addJoint(
        'drawer_left_bottom',
        JointType.dowel,
        'drawer_side_left',
        'drawer_bottom',
        count: 2,
        fastener: dowel,
      );
      addJoint(
        'drawer_right_bottom',
        JointType.dowel,
        'drawer_side_right',
        'drawer_bottom',
        count: 2,
        fastener: dowel,
      );
    }

    return Furniture(
      id: 'sample_cabinet',
      name:
          'Mueble bajo con ${spec.doorCount} puertas y ${spec.drawerCount} cajón',
      type: FurnitureType.cabinet,
      overallSize: Size3(width: width, height: height, depth: depth),
      settings: spec.settings,
      parts: parts,
      joints: joints,
      mechanisms: mechanisms,
    );
  }

  double _chooseSlideLength(double availableMm) {
    var selected = _slideLengthsMm.first;
    for (final length in _slideLengthsMm) {
      if (length <= availableMm) selected = length;
    }
    return math.min(selected, math.max(50.0, availableMm));
  }
}
