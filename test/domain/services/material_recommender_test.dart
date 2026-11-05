import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/regional_catalog.dart';
import 'package:mueble_cad/domain/services/material_recommender.dart';

void main() {
  const catalog = RegionalCatalog(
    schemaVersion: 1,
    countries: [],
    climates: [],
    uses: [],
    materials: [
      MaterialProfile(
        id: 'mdf',
        name: 'MDF',
        catalogMaterialId: 'mdf_18',
        costBand: 'bajo',
        pros: [],
        cons: [],
        climateScores: {'hotHumid': 1},
        useScores: {'bathroom': 1},
      ),
      MaterialProfile(
        id: 'marine',
        name: 'Triplex marino',
        catalogMaterialId: null,
        costBand: 'alto',
        pros: [],
        cons: [],
        climateScores: {'hotHumid': 5},
        useScores: {'bathroom': 5},
      ),
      MaterialProfile(
        id: 'plywood',
        name: 'Triplex sellado',
        catalogMaterialId: 'plywood_18',
        costBand: 'medio',
        pros: [],
        cons: [],
        climateScores: {'hotHumid': 3},
        useScores: {'bathroom': 3},
      ),
    ],
  );

  test('prioriza la resistencia a humedad y uso de baño', () {
    final ranked = const MaterialRecommender().rank(
      catalog: catalog,
      climateId: 'hotHumid',
      useId: 'bathroom',
    );

    expect(ranked.map((item) => item.material.id), [
      'marine',
      'plywood',
      'mdf',
    ]);
    expect(ranked.first.score, 10);
    expect(ranked.first.availableInPriceCatalog, isFalse);
  });
}
