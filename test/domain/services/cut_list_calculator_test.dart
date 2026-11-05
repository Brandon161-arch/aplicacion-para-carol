import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/cut_list_calculator.dart';

void main() {
  final furniture = const CabinetDoorsDrawerGenerator().generate(
    spec: sampleCabinetSpec,
    catalog: sampleMaterialCatalog,
  );
  final cutList = const CutListCalculator().build(
    furniture,
    sampleMaterialCatalog,
  );

  group('CutListCalculator', () {
    test('agrupa piezas idénticas y cuenta el total correcto', () {
      expect(cutList.totalPieces, 16);
      expect(cutList.items.length, 12);

      final lateral = cutList.items.firstWhere(
        (item) => item.name == 'Lateral',
      );
      final puerta = cutList.items.firstWhere((item) => item.name == 'Puerta');
      final estante = cutList.items.firstWhere(
        (item) => item.name == 'Estante',
      );
      final cajonLado = cutList.items.firstWhere(
        (item) => item.name == 'Lado de cajón',
      );

      expect(lateral.quantity, 2);
      expect(puerta.quantity, 2);
      expect(estante.quantity, 2);
      expect(cajonLado.quantity, 2);
    });

    test('usa las medidas de corte exactas', () {
      final lateral = cutList.items.firstWhere(
        (item) => item.name == 'Lateral',
      );
      final puerta = cutList.items.firstWhere((item) => item.name == 'Puerta');
      final fondo = cutList.items.firstWhere((item) => item.name == 'Fondo');
      final frente = cutList.items.firstWhere(
        (item) => item.name == 'Frente de cajón',
      );

      expect(lateral.cutSize.length, closeTo(750, 0.001));
      expect(lateral.cutSize.width, closeTo(450, 0.001));
      expect(lateral.cutSize.thickness, closeTo(18, 0.001));

      expect(puerta.cutSize.length, closeTo(448, 0.001));
      expect(puerta.cutSize.width, closeTo(479, 0.001));

      expect(fondo.cutSize.length, closeTo(964, 0.001));
      expect(fondo.cutSize.width, closeTo(654, 0.001));
      expect(fondo.cutSize.thickness, closeTo(5, 0.001));

      expect(frente.cutSize.length, closeTo(960, 0.001));
      expect(frente.cutSize.width, closeTo(180, 0.001));
    });

    test('calcula áreas y cantos por fila', () {
      final lateral = cutList.items.firstWhere(
        (item) => item.name == 'Lateral',
      );
      final puerta = cutList.items.firstWhere((item) => item.name == 'Puerta');
      final estante = cutList.items.firstWhere(
        (item) => item.name == 'Estante',
      );
      final fondo = cutList.items.firstWhere((item) => item.name == 'Fondo');

      expect(lateral.areaM2, closeTo(0.675, 0.0001));
      expect(lateral.bandingLengthM, closeTo(1.5, 0.0001));
      expect(puerta.areaM2, closeTo(0.429184, 0.000001));
      expect(puerta.bandingLengthM, closeTo(3.708, 0.0001));
      expect(estante.areaM2, closeTo(0.8177, 0.0001));
      expect(fondo.bandedEdgeCount, 0);
      expect(fondo.areaM2, closeTo(0.630456, 0.000001));
    });

    test('el área total coincide con la suma de las piezas', () {
      expect(cutList.totalAreaM2, closeTo(4.659145, 0.00001));
      expect(cutList.piecesByMaterial['mdf_18'], 11);
      expect(cutList.piecesByMaterial['mdf_15'], 3);
      expect(cutList.piecesByMaterial['mdf_5'], 2);
    });

    test('estima material consumido por kerf sin alterar medidas de corte', () {
      final kerf4 = const CutListCalculator().build(
        furniture,
        sampleMaterialCatalog,
        kerfMm: 4,
      );

      expect(cutList.kerfMm, 3.2);
      expect(cutList.estimatedCutLengthM, greaterThan(0));
      expect(cutList.estimatedKerfLossM2, greaterThan(0));
      expect(
        kerf4.estimatedKerfLossM2,
        greaterThan(cutList.estimatedKerfLossM2),
      );
      expect(
        kerf4.items.first.cutSize.length,
        cutList.items.first.cutSize.length,
      );
    });

    test('las filas indican el material y la veta', () {
      final puerta = cutList.items.firstWhere((item) => item.name == 'Puerta');

      expect(puerta.materialId, 'mdf_18');
      expect(puerta.materialName, 'MDF 18 mm');
      expect(puerta.bandedEdgeCount, 4);
    });
  });
}
