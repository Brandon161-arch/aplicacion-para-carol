import 'dart:math' as math;

import '../entities/furniture.dart';
import '../entities/material.dart';
import '../entities/part.dart';
import '../value_objects/vector3.dart';

/// Resultado del cálculo del Centro de Gravedad y Estabilidad.
class StabilityReport {
  final Vector3 centerOfGravityMm;
  final double totalMassKg;
  final bool isTipOverRisk;
  final double tipOverRiskRatio; // Relación momento de vuelco vs momento estabilizador
  final String safetyLevel; // 'safe', 'warning', 'danger'
  final String safetyRecommendation;
  final bool wallAnchorRequired;

  const StabilityReport({
    required this.centerOfGravityMm,
    required this.totalMassKg,
    required this.isTipOverRisk,
    required this.tipOverRiskRatio,
    required this.safetyLevel,
    required this.safetyRecommendation,
    required this.wallAnchorRequired,
  });
}

/// Caja o paquete para el Packing List de transporte RTA.
class PackageBox {
  final int boxNumber;
  final double lengthMm;
  final double widthMm;
  final double heightMm;
  final double weightKg;
  final List<String> partNames;

  const PackageBox({
    required this.boxNumber,
    required this.lengthMm,
    required this.widthMm,
    required this.heightMm,
    required this.weightKg,
    required this.partNames,
  });

  double get volumeM3 => (lengthMm * widthMm * heightMm) / 1e9;
}

/// Reporte completo de logística y empaque RTA.
class LogisticsReport {
  final double totalWeightKg;
  final double totalPackedVolumeM3;
  final List<PackageBox> packages;
  final int totalBoxCount;

  const LogisticsReport({
    required this.totalWeightKg,
    required this.totalPackedVolumeM3,
    required this.packages,
    required this.totalBoxCount,
  });
}

/// Calculador de Centro de Gravedad, Estabilidad Antivuelco y Embalaje RTA.
class StabilityLogisticsCalculator {
  const StabilityLogisticsCalculator();

  /// Densidades típicas aproximadas en kg/m³ por categoría de material
  static double getMaterialDensity(MaterialCategory category) {
    return switch (category) {
      MaterialCategory.particleboard => 650.0, // Aglomerado estándar MDP
      MaterialCategory.mdf => 750.0,           // MDF
      MaterialCategory.plywood => 600.0,       // Triplex / contrachapado
      MaterialCategory.solidWood => 680.0,     // Madera maciza pino/roble promedio
      MaterialCategory.glass => 2500.0,
      MaterialCategory.metal => 7800.0,
      MaterialCategory.hpl => 1400.0,
      MaterialCategory.other => 700.0,
    };
  }

  /// Calcula el Centro de Gravedad (CoG) y la estabilidad ante vuelco.
  StabilityReport calculateStability(Furniture furniture, MaterialCatalog catalog) {
    double totalMass = 0.0;
    double momentX = 0.0;
    double momentY = 0.0;
    double momentZ = 0.0;

    for (final part in furniture.parts) {
      final material = catalog.byId(part.materialId);
      final density = getMaterialDensity(material?.category ?? MaterialCategory.particleboard);

      // Volumen en m³: W * H * D en mm convertidos a m
      final volM3 = (part.size.width * part.size.height * part.size.depth) / 1e9;
      final massKg = volM3 * density;

      // Centro geométrico de la pieza
      final cx = part.position.x + part.size.width / 2;
      final cy = part.position.y + part.size.height / 2;
      final cz = part.position.z + part.size.depth / 2;

      momentX += cx * massKg;
      momentY += cy * massKg;
      momentZ += cz * massKg;
      totalMass += massKg;
    }

    if (totalMass <= 0.001) {
      return const StabilityReport(
        centerOfGravityMm: Vector3(0, 0, 0),
        totalMassKg: 0,
        isTipOverRisk: false,
        tipOverRiskRatio: 0,
        safetyLevel: 'safe',
        safetyRecommendation: 'Sin masa detectable.',
        wallAnchorRequired: false,
      );
    }

    final cog = Vector3(
      momentX / totalMass,
      momentY / totalMass,
      momentZ / totalMass,
    );

    // Evaluación de antivuelco según normas internacionales (ASTM F2057 / EN 14749):
    // Criterio 1: Altura > 1000 mm y relación Altura / Profundidad > 2.5
    // Criterio 2: CoG en altura relativa > 55% de la altura total
    final h = furniture.overallSize.height;
    final d = furniture.overallSize.depth;
    final heightToDepthRatio = d > 0 ? h / d : 1.0;
    final cogRelativeHeight = h > 0 ? cog.y / h : 0.5;

    // Supongamos fuerza horizontal accidental en la parte superior de 50 N o niño colgando de cajón abierto (23 kg / 225 N)
    final double stabilizingMoment = totalMass * (d / 2); // Momento que mantiene el mueble firme
    final double overturningMoment = 225.0 * (h / 1000.0); // Momento con carga vertical en borde frontal abierto
    final double safetyRatio = stabilizingMoment > 0 ? overturningMoment / stabilizingMoment : 999.0;

    final bool isTall = h >= 900;
    final bool isSlender = heightToDepthRatio >= 2.8;
    final bool highCog = cogRelativeHeight >= 0.52;

    bool tipRisk = false;
    bool wallAnchor = false;
    String level = 'safe';
    String recommendation = 'Mueble estable en condiciones normales de uso.';

    if (isTall && (isSlender || highCog || safetyRatio > 1.2)) {
      tipRisk = true;
      wallAnchor = true;
      level = 'danger';
      recommendation = '⚠️ RIESGO CRÍTICO DE VUELCO: Mueble alto y esbelto (relación H/P = ${heightToDepthRatio.toStringAsFixed(1)}). Es OBLIGATORIO instalar herrajes de anclaje a la pared para evitar accidentes con niños o sismos.';
    } else if (isTall && heightToDepthRatio >= 2.0) {
      tipRisk = false;
      wallAnchor = true;
      level = 'warning';
      recommendation = 'Precaución de estabilidad: Altura considerable. Se recomienda fijación a pared con escuadra o kit antivuelco.';
    }

    return StabilityReport(
      centerOfGravityMm: cog,
      totalMassKg: totalMass,
      isTipOverRisk: tipRisk,
      tipOverRiskRatio: safetyRatio,
      safetyLevel: level,
      safetyRecommendation: recommendation,
      wallAnchorRequired: wallAnchor,
    );
  }

  /// Calcula el Packing List empaquetando piezas en cajas planas (máx 25-30 kg por caja).
  LogisticsReport calculatePacking(Furniture furniture, MaterialCatalog catalog) {
    final parts = List<Part>.from(furniture.parts);
    if (parts.isEmpty) {
      return const LogisticsReport(
        totalWeightKg: 0,
        totalPackedVolumeM3: 0,
        packages: [],
        totalBoxCount: 0,
      );
    }

    // Ordenamos piezas por longitud decreciente
    parts.sort((a, b) => b.cutSize.length.compareTo(a.cutSize.length));

    final packages = <PackageBox>[];
    List<Part> currentBoxParts = [];
    double currentBoxWeight = 0;
    const maxWeightPerBoxKg = 28.0; // Límite ergonómico para manipulación manual

    int boxIndex = 1;

    for (final part in parts) {
      final material = catalog.byId(part.materialId);
      final density = getMaterialDensity(material?.category ?? MaterialCategory.particleboard);
      final volM3 = (part.size.width * part.size.height * part.size.depth) / 1e9;
      final partMass = volM3 * density;

      if (currentBoxParts.isNotEmpty && (currentBoxWeight + partMass > maxWeightPerBoxKg)) {
        packages.add(_createBox(boxIndex++, currentBoxParts, currentBoxWeight));
        currentBoxParts = [];
        currentBoxWeight = 0;
      }

      currentBoxParts.add(part);
      currentBoxWeight += partMass;
    }

    if (currentBoxParts.isNotEmpty) {
      packages.add(_createBox(boxIndex, currentBoxParts, currentBoxWeight));
    }

    double totalWeight = 0;
    double totalVol = 0;
    for (final b in packages) {
      totalWeight += b.weightKg;
      totalVol += b.volumeM3;
    }

    return LogisticsReport(
      totalWeightKg: totalWeight,
      totalPackedVolumeM3: totalVol,
      packages: packages,
      totalBoxCount: packages.length,
    );
  }

  PackageBox _createBox(int number, List<Part> parts, double weight) {
    double maxL = 0;
    double maxW = 0;
    double stackThickness = 0;

    for (final p in parts) {
      maxL = math.max(maxL, p.cutSize.length);
      maxW = math.max(maxW, p.cutSize.width);
      stackThickness += p.cutSize.thickness;
    }

    // Margen de protección de cartón + poliestireno (20 mm de holgura por lado y 15 mm en grosor)
    final boxL = maxL + 40;
    final boxW = maxW + 40;
    final boxH = math.max(stackThickness + 30, 60.0);

    return PackageBox(
      boxNumber: number,
      lengthMm: boxL.roundToDouble(),
      widthMm: boxW.roundToDouble(),
      heightMm: boxH.roundToDouble(),
      weightKg: (weight + 1.2).roundToDouble(), // +1.2 kg de cartón y esquineros
      partNames: parts.map((p) => p.name).toList(),
    );
  }
}
