import '../entities/furniture.dart';
import '../entities/furniture_spec.dart';

/// Nivel del semáforo ergonómico.
enum ErgonomicStatus {
  optimal, // Verde: ergonómicamente seguro y confortable
  caution, // Amarillo: precaución, fuera del rango ideal
  hazard, // Rojo: riesgo ergonómico / tensión postural
}

/// Alerta ergonómica individual con su recomendación.
class ErgonomicAlert {
  final ErgonomicStatus status;
  final String dimensionName;
  final double currentValueMm;
  final double recommendedMinMm;
  final double recommendedMaxMm;
  final double idealValueMm;
  final String explanation;
  final String recommendation;

  const ErgonomicAlert({
    required this.status,
    required this.dimensionName,
    required this.currentValueMm,
    required this.recommendedMinMm,
    required this.recommendedMaxMm,
    required this.idealValueMm,
    required this.explanation,
    required this.recommendation,
  });

  bool get needsAdjustment => status != ErgonomicStatus.optimal;
}

/// Perfil antropométrico del usuario o población.
class AntropometricProfile {
  final double userHeightCm;
  final bool isCustomUserHeight;
  final String countryCode;

  const AntropometricProfile({
    this.userHeightCm = 170.0,
    this.isCustomUserHeight = false,
    this.countryCode = 'CO',
  });

  /// Altura de los ojos de pie (~93% de estatura)
  double get eyeHeightStandingMm => userHeightCm * 10 * 0.93;

  /// Altura de los codos flexionados de pie (~63% de estatura)
  /// Altura óptima para mesadas de trabajo de cocina o taller.
  double get elbowHeightStandingMm => userHeightCm * 10 * 0.63;

  /// Altura de codos sentado (~40% de estatura)
  /// Altura óptima para escritorios y mesas de comedor.
  double get elbowHeightSeatedMm => userHeightCm * 10 * 0.42;

  /// Altura poplítea (suelo a flexión de rodilla) (~25% de estatura)
  /// Altura óptima para asientos y sillas.
  double get poplitealHeightMm => userHeightCm * 10 * 0.25;

  /// Alcance máximo vertical cómodo (~125% de estatura)
  double get maxComfortableReachMm => userHeightCm * 10 * 1.22;
}

/// Resultado de la evaluación ergonómica.
class ErgonomicsReport {
  final ErgonomicStatus overallStatus;
  final List<ErgonomicAlert> alerts;
  final AntropometricProfile profile;

  const ErgonomicsReport({
    required this.overallStatus,
    required this.alerts,
    required this.profile,
  });

  bool get hasIssues => alerts.any((a) => a.status != ErgonomicStatus.optimal);
  int get hazardCount =>
      alerts.where((a) => a.status == ErgonomicStatus.hazard).length;
  int get cautionCount =>
      alerts.where((a) => a.status == ErgonomicStatus.caution).length;
}

/// Evaluador de ergonomía según antropometría y tipo de mueble.
class ErgonomicsService {
  const ErgonomicsService();

  ErgonomicsReport evaluate(Furniture furniture, AntropometricProfile profile) {
    final alerts = <ErgonomicAlert>[];

    final h = furniture.overallSize.height;
    final w = furniture.overallSize.width;
    final d = furniture.overallSize.depth;

    switch (furniture.type) {
      case FurnitureType.cabinet:
      case FurnitureType.kitchenBase:
      case FurnitureType.drawerUnit:
        _evaluateCabinet(h, w, d, profile, alerts);
        break;
      case FurnitureType.bookshelf:
      case FurnitureType.wardrobe:
      case FurnitureType.kitchenWall:
      case FurnitureType.tvStand:
        _evaluateShelf(h, w, d, profile, alerts);
        break;
      case FurnitureType.table:
        _evaluateTable(h, w, d, profile, alerts);
        break;
      case FurnitureType.desk:
        _evaluateDesk(h, w, d, profile, alerts);
        break;
      case FurnitureType.custom:
        _evaluateGeneral(h, w, d, profile, alerts);
        break;
    }

    ErgonomicStatus overall = ErgonomicStatus.optimal;
    if (alerts.any((a) => a.status == ErgonomicStatus.hazard)) {
      overall = ErgonomicStatus.hazard;
    } else if (alerts.any((a) => a.status == ErgonomicStatus.caution)) {
      overall = ErgonomicStatus.caution;
    }

    return ErgonomicsReport(
      overallStatus: overall,
      alerts: alerts,
      profile: profile,
    );
  }

  void _evaluateCabinet(
    double h,
    double w,
    double d,
    AntropometricProfile profile,
    List<ErgonomicAlert> alerts,
  ) {
    // Para muebles tipo bajo mesada / gabinete de cocina:
    // Altura óptima = altura de codos menos 100-150 mm
    final idealWorkingHeight = profile.elbowHeightStandingMm - 120;
    final minWorkingHeight = idealWorkingHeight - 60;
    final maxWorkingHeight = idealWorkingHeight + 60;

    // Si el mueble es bajo (menos de 1300 mm), se asume mueble bajo / cubierta de trabajo
    if (h < 1300) {
      if (h < minWorkingHeight - 60 || h > maxWorkingHeight + 80) {
        alerts.add(
          ErgonomicAlert(
            status: ErgonomicStatus.hazard,
            dimensionName: 'Altura de superficie de trabajo',
            currentValueMm: h,
            recommendedMinMm: minWorkingHeight,
            recommendedMaxMm: maxWorkingHeight,
            idealValueMm: idealWorkingHeight.roundToDouble(),
            explanation: h < minWorkingHeight
                ? 'La superficie es excesivamente baja, obligando a flexión lumbar continua y dolor de espalda.'
                : 'La superficie es demasiado alta, obligando a elevar los hombros causando tensión cervical y trapecio.',
            recommendation:
                'Ajustar la altura a ${idealWorkingHeight.round()} mm según tu estatura de ${profile.userHeightCm.round()} cm.',
          ),
        );
      } else if (h < minWorkingHeight || h > maxWorkingHeight) {
        alerts.add(
          ErgonomicAlert(
            status: ErgonomicStatus.caution,
            dimensionName: 'Altura de superficie',
            currentValueMm: h,
            recommendedMinMm: minWorkingHeight,
            recommendedMaxMm: maxWorkingHeight,
            idealValueMm: idealWorkingHeight.roundToDouble(),
            explanation:
                'La altura se desvía levemente de la postura neutra de brazos.',
            recommendation:
                'Se recomienda calibrar a ${idealWorkingHeight.round()} mm.',
          ),
        );
      } else {
        alerts.add(
          ErgonomicAlert(
            status: ErgonomicStatus.optimal,
            dimensionName: 'Altura de trabajo',
            currentValueMm: h,
            recommendedMinMm: minWorkingHeight,
            recommendedMaxMm: maxWorkingHeight,
            idealValueMm: idealWorkingHeight.roundToDouble(),
            explanation: 'Excelente alineación con la altura de tus codos (postura ergonómica neutra).',
            recommendation: 'Dimensión óptima.',
          ),
        );
      }
    } else {
      // Mueble alto / armario: verificar alcance superior
      final maxReach = profile.maxComfortableReachMm;
      if (h > maxReach + 150) {
        alerts.add(
          ErgonomicAlert(
            status: ErgonomicStatus.caution,
            dimensionName: 'Altura total de armario',
            currentValueMm: h,
            recommendedMinMm: 1800,
            recommendedMaxMm: maxReach,
            idealValueMm: maxReach.roundToDouble(),
            explanation:
                'Los estantes superiores exceden el alcance cómodo sin escalera ($h mm > ${maxReach.round()} mm).',
            recommendation: 'Diseñar los niveles superiores solo para almacenamiento de baja frecuencia.',
          ),
        );
      }
    }

    // Profundidad de gabinete: el estándar es 500-650 mm para no sobrecargar el alcance de brazos
    if (d > 750) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.caution,
          dimensionName: 'Profundidad de mueble',
          currentValueMm: d,
          recommendedMinMm: 450,
          recommendedMaxMm: 650,
          idealValueMm: 600,
          explanation: 'Profundidad excesiva (> 650 mm): el fondo del mueble requerirá flexión excesiva del tronco para alcanzar objetos.',
          recommendation: 'Limitar la profundidad a 600 mm o usar cajones de extracción total.',
        ),
      );
    } else if (d < 350) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.caution,
          dimensionName: 'Profundidad reducida',
          currentValueMm: d,
          recommendedMinMm: 400,
          recommendedMaxMm: 600,
          idealValueMm: 500,
          explanation: 'Profundidad menor a 400 mm limita el almacenamiento de platos, ollas o carpetas estándar.',
          recommendation: 'Aumentar a mínimo 450 mm si se usarán cajones con correderas telescópicas estándar.',
        ),
      );
    }
  }

  void _evaluateTable(
    double h,
    double w,
    double d,
    AntropometricProfile profile,
    List<ErgonomicAlert> alerts,
  ) {
    // Mesa comedor estándar: 730 - 760 mm
    final idealH = 750.0;
    if (h < 690 || h > 800) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.hazard,
          dimensionName: 'Altura de mesa',
          currentValueMm: h,
          recommendedMinMm: 720,
          recommendedMaxMm: 770,
          idealValueMm: idealH,
          explanation: h < 720
              ? 'Poco espacio para las piernas y muslos al sentarse (falta de luz libre bajo mesa).'
              : 'Mesa excesivamente alta; obliga a elevar los antebrazos y hombros al comer.',
          recommendation: 'Ajustar a 750 mm para sillas estándar de 450 mm.',
        ),
      );
    } else {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.optimal,
          dimensionName: 'Altura de mesa',
          currentValueMm: h,
          recommendedMinMm: 720,
          recommendedMaxMm: 770,
          idealValueMm: idealH,
          explanation: 'Altura compatible con percentiles antropométricos de sillas estándar.',
          recommendation: 'Dimensión óptima.',
        ),
      );
    }
  }

  void _evaluateDesk(
    double h,
    double w,
    double d,
    AntropometricProfile profile,
    List<ErgonomicAlert> alerts,
  ) {
    // Escritorio: 700 - 750 mm
    final idealH = profile.elbowHeightSeatedMm + 30; // ~730 mm
    if (h < 680 || h > 780) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.hazard,
          dimensionName: 'Altura de escritorio',
          currentValueMm: h,
          recommendedMinMm: 700,
          recommendedMaxMm: 750,
          idealValueMm: idealH.roundToDouble(),
          explanation:
              'Riesgo ergonómico para uso con teclado y monitor prolongado.',
          recommendation:
              'Ajustar a ${idealH.round()} mm para evitar síndrome de túnel carpiano y tensión cervical.',
        ),
      );
    }
  }

  void _evaluateShelf(
    double h,
    double w,
    double d,
    AntropometricProfile profile,
    List<ErgonomicAlert> alerts,
  ) {
    if (h > profile.maxComfortableReachMm + 200) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.caution,
          dimensionName: 'Alcance estantería',
          currentValueMm: h,
          recommendedMinMm: 1200,
          recommendedMaxMm: profile.maxComfortableReachMm,
          idealValueMm: profile.maxComfortableReachMm.roundToDouble(),
          explanation: 'Niveles altos fuera del alcance seguro sin peldaño.',
          recommendation:
              'Colocar los objetos de uso diario por debajo de ${profile.maxComfortableReachMm.round()} mm.',
        ),
      );
    }
  }

  void _evaluateGeneral(
    double h,
    double w,
    double d,
    AntropometricProfile profile,
    List<ErgonomicAlert> alerts,
  ) {
    if (h > 2100) {
      alerts.add(
        ErgonomicAlert(
          status: ErgonomicStatus.caution,
          dimensionName: 'Altura total',
          currentValueMm: h,
          recommendedMinMm: 600,
          recommendedMaxMm: 2100,
          idealValueMm: 1900,
          explanation: 'Altura considerable que supera el alcance normal.',
          recommendation: 'Prever anclaje seguro a pared.',
        ),
      );
    }
  }
}
