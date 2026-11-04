import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/dto/furniture_json_codec.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/saved_furniture.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';

void main() {
  final furniture = const CabinetDoorsDrawerGenerator().generate(
    spec: sampleCabinetSpec,
    catalog: sampleMaterialCatalog,
  );

  test('un mueble sobrevive al viaje de ida y vuelta a JSON', () {
    final json = FurnitureJsonCodec.furnitureToJson(furniture);
    final restored = FurnitureJsonCodec.furnitureFromJson(json);

    expect(restored.id, furniture.id);
    expect(restored.name, furniture.name);
    expect(restored.type, furniture.type);
    expect(restored.overallSize, furniture.overallSize);
    expect(restored.parts.length, furniture.parts.length);
    expect(
      restored.settings.panelThicknessMm,
      furniture.settings.panelThicknessMm,
    );

    for (var index = 0; index < furniture.parts.length; index++) {
      final original = furniture.parts[index];
      final copy = restored.parts[index];
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.kind, original.kind);
      expect(copy.size, original.size);
      expect(copy.cutSize, original.cutSize);
      expect(copy.position, original.position);
      expect(copy.grain, original.grain);
      expect(copy.materialId, original.materialId);
      expect(copy.edgeBanding.keys.toSet(), original.edgeBanding.keys.toSet());
      expect(copy.hasConsistentDimensions, isTrue);
    }
  });

  test('un mueble guardado conserva nombre, etiquetas y fecha', () {
    final item = SavedFurniture(
      id: 'saved_test',
      name: 'Mi repisa',
      description: 'Prueba de serialización',
      tags: const ['repisa', 'prueba'],
      createdAt: DateTime.utc(2026, 11, 4, 12, 30),
      furniture: furniture,
    );

    final json = FurnitureJsonCodec.savedToJson(item);
    final restored = FurnitureJsonCodec.savedFromJson(json);

    expect(restored.id, item.id);
    expect(restored.name, item.name);
    expect(restored.description, item.description);
    expect(restored.tags, item.tags);
    expect(restored.createdAt, item.createdAt);
    expect(restored.furniture.parts.length, furniture.parts.length);
  });
}
