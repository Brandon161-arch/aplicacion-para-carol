import '../entities/drilling_hole.dart';
import '../entities/furniture.dart';
import '../entities/mechanism.dart';
import '../entities/part.dart';

/// Generador de mapas de perforación según la norma del Sistema 32 y herrajes asignados.
class DrillingMapCalculator {
  const DrillingMapCalculator();

  /// Calcula los patrones de perforación para todas las piezas del mueble.
  Map<String, PartDrillingPattern> calculatePatterns(Furniture furniture) {
    final result = <String, PartDrillingPattern>{};

    for (final part in furniture.parts) {
      final holes = <DrillingHole>[];

      // 1. Perforaciones derivadas de mecanismos (puertas abatibles y cajones)
      _addMechanismHoles(part, furniture, holes);

      // 2. Perforaciones derivadas de uniones estructurales
      _addStructuralJointHoles(part, furniture, holes);

      result[part.id] = PartDrillingPattern(
        partId: part.id,
        partName: part.name,
        lengthMm: part.cutSize.length,
        widthMm: part.cutSize.width,
        thicknessMm: part.cutSize.thickness,
        holes: holes,
      );
    }

    return result;
  }

  void _addMechanismHoles(
    Part part,
    Furniture furniture,
    List<DrillingHole> holes,
  ) {
    for (final mech in furniture.mechanisms) {
      if (mech is HingedDoorMechanism) {
        // Puerta: cazoletas Ø35mm a 21.5-22 mm del borde bisagrado
        if (part.id == mech.doorPartId) {
          final isLeft = mech.hingeSide == HingeSide.left;
          final xPos = isLeft ? 21.5 : (part.cutSize.width - 21.5);
          final h = part.cutSize.length;

          // Dos bisagras mínimo: a 100 mm de cada extremo
          holes.add(
            DrillingHole(
              type: HoleType.hingeCup35,
              xMm: xPos,
              yMm: 100.0,
              diameterMm: 35.0,
              depthMm: 11.5,
              description: 'Cazoleta bisagra inferior Ø35x11.5',
            ),
          );

          holes.add(
            DrillingHole(
              type: HoleType.hingeCup35,
              xMm: xPos,
              yMm: h - 100.0,
              diameterMm: 35.0,
              depthMm: 11.5,
              description: 'Cazoleta bisagra superior Ø35x11.5',
            ),
          );

          if (mech.hingeCount > 2) {
            holes.add(
              DrillingHole(
                type: HoleType.hingeCup35,
                xMm: xPos,
                yMm: h / 2,
                diameterMm: 35.0,
                depthMm: 11.5,
                description: 'Cazoleta bisagra intermedia Ø35x11.5',
              ),
            );
          }
        }

        // Si es el panel lateral que recibe la bisagra: placas base en Sistema 32 (a 37 mm del borde frontal)
        if (part.kind == PartKind.sidePanel) {
          final isLeftHinge = mech.hingeSide == HingeSide.left;
          final isLeftPanel = part.position.x < furniture.overallSize.width / 2;
          final isTargetSide =
              (isLeftHinge && isLeftPanel) || (!isLeftHinge && !isLeftPanel);

          if (isTargetSide) {
            // Suponemos que la puerta apoya a partir de la altura del zócalo
            final yOffset = furniture.settings.plinthHeightMm;
            holes.add(
              DrillingHole(
                type: HoleType.hingePlateMount,
                xMm: 37.0,
                yMm: yOffset + 100.0,
                diameterMm: 5.0,
                depthMm: 12.0,
                description: 'Base bisagra inf. (Sistema 32) Ø5x12',
              ),
            );
            holes.add(
              DrillingHole(
                type: HoleType.hingePlateMount,
                xMm: 37.0,
                yMm: yOffset + 100.0 + 32.0,
                diameterMm: 5.0,
                depthMm: 12.0,
                description: 'Base bisagra inf. sup. Ø5x12',
              ),
            );
          }
        }
      }

      if (mech is DrawerMechanism) {
        // En los paneles laterales: fijación de guías de cajón (a 37 mm del borde frontal + paso de 32 mm)
        if (part.kind == PartKind.sidePanel) {
          // Altura estimada del cajón
          final drawerY = part.cutSize.length - 150.0;
          holes.add(
            DrillingHole(
              type: HoleType.drawerSlideMount,
              xMm: 37.0,
              yMm: drawerY,
              diameterMm: 5.0,
              depthMm: 10.0,
              description: 'Fijación corredera frontal Ø5x10',
            ),
          );
          holes.add(
            DrillingHole(
              type: HoleType.drawerSlideMount,
              xMm: 37.0 + 192.0, // múltiplo de 32 mm (6 * 32)
              yMm: drawerY,
              diameterMm: 5.0,
              depthMm: 10.0,
              description: 'Fijación corredera posterior Ø5x10',
            ),
          );
        }
      }
    }
  }

  void _addStructuralJointHoles(
    Part part,
    Furniture furniture,
    List<DrillingHole> holes,
  ) {
    // Si es un lateral: orificios pasantes para Confirmats hacia la base y la tapa
    if (part.kind == PartKind.sidePanel) {
      final t = furniture.settings.panelThicknessMm;
      final w = part.cutSize.width;
      final h = part.cutSize.length;

      // Orificios hacia la base (a t/2 del borde inferior)
      holes.add(
        DrillingHole(
          type: HoleType.confirmatThrough,
          xMm: 50.0,
          yMm: t / 2,
          diameterMm: 7.0,
          depthMm: t,
          description: 'Pasante Confirmat hacia base frontal Ø7',
        ),
      );
      holes.add(
        DrillingHole(
          type: HoleType.confirmatThrough,
          xMm: w - 50.0,
          yMm: t / 2,
          diameterMm: 7.0,
          depthMm: t,
          description: 'Pasante Confirmat hacia base posterior Ø7',
        ),
      );

      // Orificios hacia la tapa (a t/2 del borde superior)
      holes.add(
        DrillingHole(
          type: HoleType.confirmatThrough,
          xMm: 50.0,
          yMm: h - t / 2,
          diameterMm: 7.0,
          depthMm: t,
          description: 'Pasante Confirmat hacia tapa frontal Ø7',
        ),
      );
      holes.add(
        DrillingHole(
          type: HoleType.confirmatThrough,
          xMm: w - 50.0,
          yMm: h - t / 2,
          diameterMm: 7.0,
          depthMm: t,
          description: 'Pasante Confirmat hacia tapa posterior Ø7',
        ),
      );

      // Pines para estantes móviles en el centro
      final midY = h / 2;
      holes.add(
        DrillingHole(
          type: HoleType.shelfPin5,
          xMm: 50.0,
          yMm: midY,
          diameterMm: 5.0,
          depthMm: 10.0,
          description: 'Soporte estante frontal Ø5x10',
        ),
      );
      holes.add(
        DrillingHole(
          type: HoleType.shelfPin5,
          xMm: w - 50.0,
          yMm: midY,
          diameterMm: 5.0,
          depthMm: 10.0,
          description: 'Soporte estante posterior Ø5x10',
        ),
      );
    }

    // Si es un estante o división: taladros Minifix en cara y canto
    if (part.kind == PartKind.shelf || part.kind == PartKind.divider) {
      final l = part.cutSize.length;

      // Cajas de leva Minifix a 34 mm del borde lateral y a 50 mm de los cantos
      holes.add(
        DrillingHole(
          type: HoleType.minifixCam15,
          xMm: 50.0,
          yMm: 34.0,
          diameterMm: 15.0,
          depthMm: 13.0,
          description: 'Caja leva Minifix Ø15x13',
        ),
      );
      holes.add(
        DrillingHole(
          type: HoleType.minifixCam15,
          xMm: l - 50.0,
          yMm: 34.0,
          diameterMm: 15.0,
          depthMm: 13.0,
          description: 'Caja leva Minifix Ø15x13',
        ),
      );
    }
  }
}
