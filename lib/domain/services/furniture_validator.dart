import '../entities/furniture_spec.dart';

enum ValidationSeverity { error, warning }

class ValidationIssue {
  final ValidationSeverity severity;
  final String field;
  final String message;

  const ValidationIssue({
    required this.severity,
    required this.field,
    required this.message,
  });
}

/// Reglas de validación del mueble paramétrico.
///
/// La UI muestra los errores, pero el generador igual produce una versión
/// segura para que el visor 3D no falle mientras el usuario escribe.
class FurnitureValidator {
  const FurnitureValidator();

  List<ValidationIssue> validate(FurnitureSpec spec) {
    if (spec is! CabinetSpec) {
      return const [
        ValidationIssue(
          severity: ValidationSeverity.error,
          field: 'type',
          message: 'Todavía no hay generador para este tipo de mueble.',
        ),
      ];
    }

    final issues = <ValidationIssue>[];
    final width = spec.overallSize.width;
    final height = spec.overallSize.height;
    final depth = spec.overallSize.depth;
    final thickness = spec.settings.panelThicknessMm;
    final backThickness = spec.settings.backPanelThicknessMm;
    final gap = spec.settings.doorGapMm;
    final plinth = spec.settings.plinthHeightMm;

    void error(String field, String message) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.error,
          field: field,
          message: message,
        ),
      );
    }

    void warning(String field, String message) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.warning,
          field: field,
          message: message,
        ),
      );
    }

    if (!_isPositiveFinite(width) || width < 300) {
      error('width', 'El ancho debe ser mayor o igual a 300 mm.');
    }
    if (!_isPositiveFinite(height) || height < 300) {
      error('height', 'El alto debe ser mayor o igual a 300 mm.');
    }
    if (!_isPositiveFinite(depth) || depth < 200) {
      error('depth', 'El fondo debe ser mayor o igual a 200 mm.');
    }
    if (thickness < 6 || thickness > 30) {
      error('thickness', 'El espesor del panel debe estar entre 6 y 30 mm.');
    } else if (thickness < 15) {
      warning(
        'thickness',
        'Para muebles de uso doméstico se recomienda 15 mm o más.',
      );
    }
    if (backThickness < 3 || backThickness > 12) {
      error('backThickness', 'El fondo debe tener entre 3 y 12 mm de espesor.');
    }
    if (gap < 0 || gap > 10) {
      error('gap', 'La holgura entre frentes debe estar entre 0 y 10 mm.');
    } else if (gap == 0) {
      warning('gap', 'Sin holgura las puertas y cajones pueden rozar.');
    }
    if (plinth < 0 || plinth >= height * 0.4) {
      error('plinth', 'La altura del zócalo no es válida para este alto.');
    }

    final innerWidth = width - 2 * thickness;
    final bodyDepth = depth - backThickness;
    if (innerWidth < 150) {
      error('width', 'El ancho no deja espacio interior suficiente.');
    }
    if (bodyDepth < 100) {
      error('depth', 'El fondo no deja espacio interior suficiente.');
    }

    final bottomPanelTop = plinth + thickness;
    final topPanelBottom = height - thickness;
    final dividerTop = topPanelBottom - gap - spec.drawerHeightMm - gap;
    final dividerBottom = dividerTop - thickness;
    final doorsTop = dividerBottom - gap;
    final doorsBottom = bottomPanelTop + gap;
    final doorHeight = doorsTop - doorsBottom;
    final doorWidth = (innerWidth - 3 * gap) / 2;

    if (spec.drawerCount != 1) {
      warning(
        'drawerCount',
        'El ejemplo de la Fase 1 está pensado para 1 cajón.',
      );
    }
    if (spec.doorCount != 2) {
      warning(
        'doorCount',
        'El ejemplo de la Fase 1 está pensado para 2 puertas.',
      );
    }
    if (spec.drawerHeightMm < 80) {
      error('drawerHeight', 'La altura del cajón debe ser de al menos 80 mm.');
    } else if (spec.drawerHeightMm > 300) {
      warning('drawerHeight', 'Un cajón de más de 300 mm puede ser incómodo.');
    }
    if (doorHeight < 150) {
      error(
        'drawerHeight',
        'El cajón deja las puertas sin altura suficiente. Reduce el cajón o aumenta el alto.',
      );
    }
    if (doorWidth < 100) {
      error('width', 'Las puertas quedarían demasiado estrechas.');
    }
    if (spec.shelfCount < 0 || spec.shelfCount > 8) {
      error('shelfCount', 'La cantidad de estantes debe estar entre 0 y 8.');
    } else if (spec.shelfCount > 0) {
      final shelfSpace = dividerBottom - bottomPanelTop;
      final minimumSpace = spec.shelfCount * thickness + 3 * 50;
      if (shelfSpace < minimumSpace) {
        error(
          'shelfCount',
          'No hay espacio vertical para ${spec.shelfCount} estantes.',
        );
      }
    }

    final availableDrawerDepth = depth - backThickness - thickness - 12;
    if (availableDrawerDepth < 200) {
      warning('depth', 'El cajón tendrá menos de 200 mm de recorrido útil.');
    }

    return issues;
  }

  bool _isPositiveFinite(double value) => value.isFinite && value > 0;
}
