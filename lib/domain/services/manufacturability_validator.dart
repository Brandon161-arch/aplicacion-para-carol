import '../entities/furniture.dart';
import '../entities/material.dart';
import '../entities/part.dart';
import '../entities/regional_catalog.dart';
import '../value_objects/cut_size.dart';
import '../value_objects/size3.dart';

enum BuildabilitySeverity { error, warning }

class BuildabilityIssue {
  final BuildabilitySeverity severity;
  final String code;
  final String message;
  final String suggestion;
  final List<String> partIds;

  const BuildabilityIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.suggestion,
    this.partIds = const [],
  });
}

class ManufacturabilityValidator {
  const ManufacturabilityValidator();

  List<BuildabilityIssue> validate({
    required Furniture furniture,
    required MaterialCatalog materials,
    List<BoardFormat> boardFormats = const [],
    double kerfMm = 3.2,
  }) {
    final issues = <BuildabilityIssue>[];
    void error(String code, String message, String suggestion, [String? id]) {
      issues.add(
        BuildabilityIssue(
          severity: BuildabilitySeverity.error,
          code: code,
          message: message,
          suggestion: suggestion,
          partIds: id == null ? const [] : [id],
        ),
      );
    }

    void warning(
      String code,
      String message,
      String suggestion, [
      List<String> ids = const [],
    ]) {
      issues.add(
        BuildabilityIssue(
          severity: BuildabilitySeverity.warning,
          code: code,
          message: message,
          suggestion: suggestion,
          partIds: ids,
        ),
      );
    }

    if (furniture.parts.isEmpty) {
      warning(
        'empty',
        'El mueble no tiene piezas para fabricar.',
        'Agrega piezas o carga un modelo paramétrico.',
      );
      return issues;
    }
    if (!kerfMm.isFinite || kerfMm < 0.5 || kerfMm > 8) {
      error(
        'kerf',
        'El kerf de sierra está fuera del rango esperado (0,5–8 mm).',
        'Configura el ancho real del disco o la herramienta de corte.',
      );
    }

    for (final part in furniture.parts) {
      final dimensions = [
        part.size.width,
        part.size.height,
        part.size.depth,
        part.cutSize.length,
        part.cutSize.width,
        part.cutSize.thickness,
      ];
      if (dimensions.any((value) => !value.isFinite || value <= 0)) {
        error(
          'invalid-dimensions',
          '“${part.name}” tiene una medida no válida.',
          'Usa medidas positivas y finitas en las tres dimensiones.',
          part.id,
        );
        continue;
      }

      if (!_sameDimensions(part.size, part.cutSize)) {
        error(
          'cut-world-mismatch',
          'Las medidas 3D y las medidas de corte de “${part.name}” no coinciden.',
          'Revisa la orientación y el espesor de la pieza.',
          part.id,
        );
      }

      final p = part.position;
      if (![p.x, p.y, p.z].every((value) => value.isFinite) ||
          p.x < -0.1 ||
          p.y < -0.1 ||
          p.z < -0.1 ||
          p.x + part.size.width > furniture.overallSize.width + 0.1 ||
          p.y + part.size.height > furniture.overallSize.height + 0.1 ||
          p.z + part.size.depth > furniture.overallSize.depth + 0.1) {
        error(
          'outside-envelope',
          '“${part.name}” queda fuera del volumen general.',
          'Mueve o reduce la pieza, o ajusta las dimensiones generales.',
          part.id,
        );
      }

      final material = materials.byId(part.materialId);
      if (material == null) {
        error(
          'unknown-material',
          '“${part.name}” usa un material que no existe en el catálogo.',
          'Selecciona un material del catálogo regional.',
          part.id,
        );
      } else {
        if (material.thicknessesMm.isNotEmpty &&
            !material.thicknessesMm.any(
              (thickness) => (thickness - part.cutSize.thickness).abs() < 0.1,
            )) {
          warning(
            'thickness-not-stocked',
            'El espesor de “${part.name}” no aparece en las opciones de ${material.name}.',
            'Confirma la disponibilidad local o cambia a un espesor comercial.',
            [part.id],
          );
        }
        if (material.sheetSize != null &&
            !_fitsAnyBoard(
              part,
              boardFormats.isEmpty
                  ? [
                      BoardFormat(
                        widthMm: material.sheetSize!.widthMm,
                        heightMm: material.sheetSize!.heightMm,
                      ),
                    ]
                  : boardFormats,
            )) {
          error(
            'board-too-small',
            '“${part.name}” no cabe en los tableros configurados para ${material.name}.',
            'Divide la pieza, elige un tablero mayor o cambia su orientación/veta.',
            part.id,
          );
        }
      }
    }

    for (var first = 0; first < furniture.parts.length; first++) {
      for (var second = first + 1; second < furniture.parts.length; second++) {
        final a = furniture.parts[first];
        final b = furniture.parts[second];
        if (_overlapVolume(a, b)) {
          warning(
            'possible-collision',
            '“${a.name}” y “${b.name}” se intersecan en el modelo 3D.',
            'Revisa el encuentro y define un rebaje o una unión que elimine la colisión.',
            [a.id, b.id],
          );
        }
      }
    }
    return issues;
  }

  bool _sameDimensions(Size3 size, CutSize cut) {
    final world = [size.width, size.height, size.depth]..sort();
    final panel = [cut.length, cut.width, cut.thickness]..sort();
    return List.generate(
      3,
      (index) => (world[index] - panel[index]).abs() < 0.1,
    ).every((matches) => matches);
  }

  bool _fitsAnyBoard(Part part, List<BoardFormat> boards) {
    for (final board in boards) {
      final longSide = board.widthMm > board.heightMm
          ? board.widthMm
          : board.heightMm;
      final shortSide = board.widthMm < board.heightMm
          ? board.widthMm
          : board.heightMm;
      final length = part.cutSize.length;
      final width = part.cutSize.width;
      if (part.grain == GrainDirection.none) {
        if ((length <= board.widthMm && width <= board.heightMm) ||
            (width <= board.widthMm && length <= board.heightMm)) {
          return true;
        }
      } else {
        final grainLength = part.grain == GrainDirection.alongLength
            ? length
            : width;
        final crossGrain = part.grain == GrainDirection.alongLength
            ? width
            : length;
        if (grainLength <= longSide && crossGrain <= shortSide) return true;
      }
    }
    return false;
  }

  bool _overlapVolume(Part first, Part second) {
    const tolerance = 0.1;
    final x = _intersection(
      first.position.x,
      first.position.x + first.size.width,
      second.position.x,
      second.position.x + second.size.width,
    );
    final y = _intersection(
      first.position.y,
      first.position.y + first.size.height,
      second.position.y,
      second.position.y + second.size.height,
    );
    final z = _intersection(
      first.position.z,
      first.position.z + first.size.depth,
      second.position.z,
      second.position.z + second.size.depth,
    );
    return x > tolerance && y > tolerance && z > tolerance;
  }

  double _intersection(
    double startA,
    double endA,
    double startB,
    double endB,
  ) => (endA < endB ? endA : endB) - (startA > startB ? startA : startB);
}
