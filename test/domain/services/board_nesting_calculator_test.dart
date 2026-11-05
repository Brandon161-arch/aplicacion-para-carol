import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/services/board_nesting_calculator.dart';

void main() {
  const calculator = BoardNestingCalculator();

  test('anida piezas y conserva la orientación de veta', () {
    final result = calculator.calculate(
      catalog: sampleMaterialCatalog,
      kerfMm: 3.2,
      pieces: const [
        NestingPiece(
          partId: 'length_grain',
          partName: 'Veta largo',
          materialId: 'mdf_18',
          lengthMm: 2000,
          widthMm: 400,
          grain: GrainDirection.alongLength,
        ),
        NestingPiece(
          partId: 'width_grain',
          partName: 'Veta ancho',
          materialId: 'mdf_18',
          lengthMm: 400,
          widthMm: 2000,
          grain: GrainDirection.alongWidth,
        ),
      ],
    );

    final material = result.byMaterial['mdf_18']!;
    expect(material.isComplete, isTrue);
    expect(material.sheetCount, 1);
    final placements = material.sheets.expand((sheet) => sheet.placements);
    expect(placements.map((placement) => placement.partId), {
      'length_grain',
      'width_grain',
    });
    expect(
      placements
          .firstWhere((placement) => placement.partId == 'length_grain')
          .rotated,
      isFalse,
    );
    expect(
      placements
          .firstWhere((placement) => placement.partId == 'width_grain')
          .rotated,
      isTrue,
    );
  });

  test('reporta sin ubicar una pieza mayor que cualquier tablero', () {
    final result = calculator.calculate(
      catalog: sampleMaterialCatalog,
      kerfMm: 3.2,
      pieces: const [
        NestingPiece(
          partId: 'too_long',
          partName: 'Pieza larga',
          materialId: 'mdf_18',
          lengthMm: 2600,
          widthMm: 300,
          grain: GrainDirection.alongLength,
        ),
      ],
    );

    expect(result.byMaterial['mdf_18']!.unplacedPartIds, ['too_long']);
    expect(result.totalSheets, 0);
  });
}
