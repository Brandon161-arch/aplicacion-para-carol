import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/preset_furniture.dart';
import 'package:mueble_cad/domain/services/cut_list_calculator.dart';

void main() {
  final presets = buildPresetFurniture();

  test('hay al menos seis modelos de ejemplo con identificadores únicos', () {
    expect(presets.length, greaterThanOrEqualTo(12));
    expect(presets.map((preset) => preset.id).toSet().length, presets.length);
  });

  test('todas las piezas de los ejemplos son geométricamente válidas', () {
    for (final preset in presets) {
      final furniture = preset.furniture;
      expect(furniture.parts, isNotEmpty, reason: preset.name);

      for (final part in furniture.parts) {
        expect(
          part.hasConsistentDimensions,
          isTrue,
          reason: '${preset.name} / ${part.name}',
        );
        expect(sampleMaterialCatalog.byId(part.materialId), isNotNull);
        expect(part.position.x, greaterThanOrEqualTo(-0.01));
        expect(part.position.y, greaterThanOrEqualTo(-0.01));
        expect(part.position.z, greaterThanOrEqualTo(-0.01));
        expect(
          part.position.x + part.size.width,
          lessThanOrEqualTo(furniture.overallSize.width + 0.01),
          reason: '${preset.name} / ${part.name} se sale en X',
        );
        expect(
          part.position.y + part.size.height,
          lessThanOrEqualTo(furniture.overallSize.height + 0.01),
          reason: '${preset.name} / ${part.name} se sale en Y',
        );
        expect(
          part.position.z + part.size.depth,
          lessThanOrEqualTo(furniture.overallSize.depth + 0.01),
          reason: '${preset.name} / ${part.name} se sale en Z',
        );
      }
    }
  });

  test('el despiece de cada ejemplo se puede calcular', () {
    for (final preset in presets) {
      final cutList = const CutListCalculator().build(
        preset.furniture,
        sampleMaterialCatalog,
      );
      expect(cutList.items, isNotEmpty, reason: preset.name);
      expect(
        cutList.totalPieces,
        preset.furniture.parts.length,
        reason: preset.name,
      );
      expect(cutList.totalAreaM2, greaterThan(0), reason: preset.name);
    }
  });
}
