import '../entities/furniture.dart';
import '../entities/part.dart';

/// Un paso individual de ensamblado para el manual interactivo.
class AssemblyStep {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> partIds;
  final List<String> partNames;
  final List<String> requiredTools;
  final List<String> fastenersNeeded;
  final String safetyWarning;

  const AssemblyStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.partIds,
    required this.partNames,
    required this.requiredTools,
    required this.fastenersNeeded,
    this.safetyWarning = '',
  });
}

/// Manual completo de armado paso a paso.
class AssemblyManual {
  final String furnitureName;
  final String difficulty; // 'Fácil', 'Intermedio', 'Avanzado'
  final int estimatedTimeMinutes;
  final List<String> toolsRequired;
  final List<String> hardwareChecklist;
  final List<AssemblyStep> steps;

  const AssemblyManual({
    required this.furnitureName,
    required this.difficulty,
    required this.estimatedTimeMinutes,
    required this.toolsRequired,
    required this.hardwareChecklist,
    required this.steps,
  });

  int get totalSteps => steps.length;
}

/// Generador de la secuencia de armado según la lógica constructiva de carpintería.
class AssemblyGuideGenerator {
  const AssemblyGuideGenerator();

  AssemblyManual generate(Furniture furniture) {
    final steps = <AssemblyStep>[];
    int stepCounter = 1;

    // Herramientas generales de taller
    final commonTools = [
      'Destornillador Phillips (#2)',
      'Llave Allen de 4 mm (para Confirmats)',
      'Taladro / Atornillador con punta PZ2',
      'Martillo de goma o teflón',
      'Cinta métrica y escuadra de carpintero',
      'Nivel de burbuja',
    ];

    // Checklist de herrajes básicos
    final hardwareList = [
      'Tornillos Confirmat 7×50 mm',
      'Tarugos de madera 8×30 mm',
      'Cola vinílica para madera (PVA)',
      'Bisagras cazoleta 35 mm con tornillos',
      'Correderas telescópicas con tornillos autorroscantes 4×16 mm',
      'Soportes / pines para estantes',
      'Manijas / tiradores con pernos métricos M4',
    ];

    // Paso 1: Preparación y zócalo / base
    final plinthParts = furniture.parts.where((p) => p.kind == PartKind.plinth).toList();
    final baseParts = furniture.parts.where((p) => p.kind == PartKind.bottomPanel).toList();
    if (plinthParts.isNotEmpty || baseParts.isNotEmpty) {
      steps.add(AssemblyStep(
        stepNumber: stepCounter++,
        title: 'Paso 1: Armado de la Base y Nivelación',
        description: 'Ubique la base en una superficie plana y limpia. Fije los zócalos o patas niveladoras en la cara inferior usando tornillos autorroscantes o escuadras.',
        partIds: [...plinthParts.map((p) => p.id), ...baseParts.map((p) => p.id)],
        partNames: [...plinthParts.map((p) => p.name), ...baseParts.map((p) => p.name)],
        requiredTools: ['Destornillador Phillips', 'Escuadra de carpintero'],
        fastenersNeeded: ['Tornillos 4×30 mm o escuadras plásticas'],
        safetyWarning: 'Asegúrese de trabajar sobre una manta o cartón para evitar rayar la melamina.',
      ));
    }

    // Paso 2: Instalación de herrajes internos en los laterales antes de cerrar el mueble
    final sideParts = furniture.parts.where((p) => p.kind == PartKind.sidePanel).toList();
    if (sideParts.isNotEmpty) {
      steps.add(AssemblyStep(
        stepNumber: stepCounter++,
        title: 'Paso 2: Premontaje de Guías y Bases de Bisagra en Laterales',
        description: 'IMPORTANTE: Atornille las correderas telescópicas y las placas base de bisagra en las caras internas de los paneles laterales ANTES de unir la carcasa. Esto garantiza comodidad y acceso óptimo.',
        partIds: sideParts.map((p) => p.id).toList(),
        partNames: sideParts.map((p) => p.name).toList(),
        requiredTools: ['Taladro atornillador', 'Punta Phillips PZ2', 'Cinta métrica'],
        fastenersNeeded: ['Tornillos 3.5×16 mm de cabeza avellanada'],
        safetyWarning: 'Verifique que la orientación del frente y fondo sea la correcta en ambos laterales.',
      ));
    }

    // Paso 3: Ensamble del cuerpo principal (Laterales + Base + Divisiones)
    final divParts = furniture.parts.where((p) => p.kind == PartKind.divider).toList();
    steps.add(AssemblyStep(
      stepNumber: stepCounter++,
      title: 'Paso 3: Ensamblado de Carcasa y Divisiones',
      description: 'Una el lateral izquierdo y derecho a la base mediante tornillos Confirmat y tarugos encolados. Luego deslice y fije las divisiones interiores ajustando las excéntricas Minifix.',
      partIds: [...sideParts.map((p) => p.id), ...divParts.map((p) => p.id)],
      partNames: [...sideParts.map((p) => p.name), ...divParts.map((p) => p.name)],
      requiredTools: ['Llave Allen 4 mm', 'Martillo de goma', 'Cola blanca PVA'],
      fastenersNeeded: ['Confirmats 7×50 mm', 'Tarugos 8×30 mm'],
      safetyWarning: 'Apriete los tornillos firmemente sin rodar la rosca en el aglomerado.',
    ));

    // Paso 4: Colocación de la Tapa / Cubierta superior
    final topParts = furniture.parts.where((p) => p.kind == PartKind.topPanel).toList();
    if (topParts.isNotEmpty) {
      steps.add(AssemblyStep(
        stepNumber: stepCounter++,
        title: 'Paso 4: Fijación de la Tapa Superior',
        description: 'Coloque la tapa superior sobre la estructura. Introduzca los tornillos Confirmat desde las caras externas o apriete los pernos Minifix desde abajo para uniones invisibles.',
        partIds: topParts.map((p) => p.id).toList(),
        partNames: topParts.map((p) => p.name).toList(),
        requiredTools: ['Llave Allen 4 mm', 'Destornillador de cruz'],
        fastenersNeeded: ['Confirmats 7×50 mm o espigas Minifix'],
        safetyWarning: 'Verifique que la estructura esté a escuadra perfecta midiendo las diagonales en cruz.',
      ));
    }

    // Paso 5: Escuadre y Fondo (Back Panel)
    final backParts = furniture.parts.where((p) => p.kind == PartKind.backPanel).toList();
    if (backParts.isNotEmpty) {
      steps.add(AssemblyStep(
        stepNumber: stepCounter++,
        title: 'Paso 5: Clavado / Atornillado del Fondo y Escuadre',
        description: 'Mida las diagonales en cruz del mueble; ambas deben ser exactamente iguales. Luego clave o atornille el fondo de 3-5 mm cada 15 cm a lo largo de todo el perímetro.',
        partIds: backParts.map((p) => p.id).toList(),
        partNames: backParts.map((p) => p.name).toList(),
        requiredTools: ['Martillo de uña', 'Cinta métrica'],
        fastenersNeeded: ['Clavos de 1 pulgada con arandela plástica o tornillos traseros 3×15 mm'],
        safetyWarning: 'Este paso otorga el 80% de la rigidez estructural al mueble.',
      ));
    }

    // Paso 6: Cajones y Puertas
    final drawerParts = furniture.parts.where((p) => p.kind == PartKind.drawerFront || p.kind == PartKind.drawerSide || p.kind == PartKind.drawerBottom).toList();
    final doorParts = furniture.parts.where((p) => p.kind == PartKind.door).toList();
    if (drawerParts.isNotEmpty || doorParts.isNotEmpty) {
      steps.add(AssemblyStep(
        stepNumber: stepCounter++,
        title: 'Paso 6: Armado de Cajones, Puertas y Calibración',
        description: 'Arme los cajones e inserte las correderas. Monte las bisagras en las puertas e instálelas sobre las bases de los laterales. Regule los tornillos de ajuste de las bisagras para dejar luces uniformes de 2 mm.',
        partIds: [...drawerParts.map((p) => p.id), ...doorParts.map((p) => p.id)],
        partNames: [...drawerParts.map((p) => p.name), ...doorParts.map((p) => p.name)],
        requiredTools: ['Destornillador Phillips #2'],
        fastenersNeeded: ['Tornillos para bisagras y jaladeras'],
        safetyWarning: 'Ajuste la holgura con los tornillos excéntricos de la bisagra para evitar roces con la carcasa.',
      ));
    }

    // Paso 7: Anclaje de Seguridad Antivuelco
    steps.add(AssemblyStep(
      stepNumber: stepCounter++,
      title: 'Paso 7: Anclaje Antivuelco a la Pared',
      description: 'Fije la escuadra metálica de seguridad al travesaño superior o lateral del mueble y ancle firmemente con chazo/tarugo de expansión al muro de mampostería.',
      partIds: const [],
      partNames: const ['Mueble completo a Muro'],
      requiredTools: ['Taladro percutor', 'Broca de concreto', 'Llave o destornillador'],
      fastenersNeeded: ['Chazos plásticos de 8 mm y tornillos tirafondo de 2 pulgadas'],
      safetyWarning: 'OBLIGATORIO por seguridad de niños y prevención de caídas.',
    ));

    final totalMinutes = 30 + steps.length * 15;
    final diff = steps.length <= 4 ? 'Fácil' : (steps.length <= 6 ? 'Intermedio' : 'Avanzado');

    return AssemblyManual(
      furnitureName: furniture.name,
      difficulty: diff,
      estimatedTimeMinutes: totalMinutes,
      toolsRequired: commonTools,
      hardwareChecklist: hardwareList,
      steps: steps,
    );
  }
}
