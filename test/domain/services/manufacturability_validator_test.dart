import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/entities/regional_catalog.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/manufacturability_validator.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';

void main() {
  const validator = ManufacturabilityValidator();
  const boards = [BoardFormat(widthMm: 2440, heightMm: 1830)];

  test('el mueble paramétrico base pasa las reglas geométricas esenciales', () {
    final furniture = const CabinetDoorsDrawerGenerator().generate(
      spec: sampleCabinetSpec,
      catalog: sampleMaterialCatalog,
    );
    final issues = validator.validate(
      furniture: furniture,
      materials: sampleMaterialCatalog,
      boardFormats: boards,
      kerfMm: 3.2,
    );

    expect(
      issues.where((issue) => issue.severity == BuildabilitySeverity.error),
      isEmpty,
    );
  });

  test('detecta pieza fuera del volumen y mayor que el tablero', () {
    const part = Part(
      id: 'long_panel',
      name: 'Panel demasiado largo',
      kind: PartKind.shelf,
      size: Size3(width: 2500, height: 18, depth: 300),
      cutSize: CutSize(length: 2500, width: 300, thickness: 18),
      materialId: 'mdf_18',
      position: Vector3(0, 0, 0),
    );
    const furniture = Furniture(
      id: 'oversized',
      name: 'Mueble inválido',
      type: FurnitureType.custom,
      overallSize: Size3(width: 800, height: 500, depth: 400),
      settings: ConstructionSettings(),
      parts: [part],
    );

    final issues = validator.validate(
      furniture: furniture,
      materials: sampleMaterialCatalog,
      boardFormats: boards,
    );

    expect(issues.map((issue) => issue.code), contains('outside-envelope'));
    expect(issues.map((issue) => issue.code), contains('board-too-small'));
  });

  test('advierte cuando dos piezas ocupan el mismo espacio', () {
    const first = Part(
      id: 'a',
      name: 'Panel A',
      kind: PartKind.shelf,
      size: Size3(width: 500, height: 18, depth: 300),
      cutSize: CutSize(length: 500, width: 300, thickness: 18),
      materialId: 'mdf_18',
      position: Vector3(0, 0, 0),
    );
    const second = Part(
      id: 'b',
      name: 'Panel B',
      kind: PartKind.shelf,
      size: Size3(width: 500, height: 18, depth: 300),
      cutSize: CutSize(length: 500, width: 300, thickness: 18),
      materialId: 'mdf_18',
      position: Vector3(0, 0, 0),
    );
    const furniture = Furniture(
      id: 'collision',
      name: 'Modelo con choque',
      type: FurnitureType.custom,
      overallSize: Size3(width: 800, height: 500, depth: 400),
      settings: ConstructionSettings(),
      parts: [first, second],
    );

    final issues = validator.validate(
      furniture: furniture,
      materials: sampleMaterialCatalog,
      boardFormats: boards,
    );

    expect(issues.map((issue) => issue.code), contains('possible-collision'));
  });
}
