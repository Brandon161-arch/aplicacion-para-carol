import '../entities/regional_catalog.dart';

class MaterialRecommendation {
  final MaterialProfile material;
  final int score;
  final int rank;

  const MaterialRecommendation({
    required this.material,
    required this.score,
    required this.rank,
  });

  bool get availableInPriceCatalog => material.catalogMaterialId != null;
}

class MaterialRecommender {
  const MaterialRecommender();

  List<MaterialRecommendation> rank({
    required RegionalCatalog catalog,
    required String climateId,
    required String useId,
    int limit = 3,
  }) {
    final ranked =
        catalog.materials
            .map(
              (material) => (
                material: material,
                score:
                    (material.climateScores[climateId] ?? 0) +
                    (material.useScores[useId] ?? 0),
              ),
            )
            .where((entry) => entry.score > 0)
            .toList()
          ..sort((first, second) {
            final byScore = second.score.compareTo(first.score);
            return byScore != 0
                ? byScore
                : first.material.name.compareTo(second.material.name);
          });

    return [
      for (var index = 0; index < ranked.length && index < limit; index++)
        MaterialRecommendation(
          material: ranked[index].material,
          score: ranked[index].score,
          rank: index + 1,
        ),
    ];
  }
}
