import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/repositories/shared_preferences_furniture_library_repository.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/saved_furniture.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guarda, lista y elimina muebles', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesFurnitureLibraryRepository(preferences);
    final furniture = const CabinetDoorsDrawerGenerator().generate(
      spec: sampleCabinetSpec,
      catalog: sampleMaterialCatalog,
    );
    final item = SavedFurniture(
      id: 'saved_1',
      name: 'Repisa de prueba',
      description: 'Guardada desde un test',
      tags: const ['test'],
      createdAt: DateTime.utc(2026, 11, 4),
      furniture: furniture,
    );

    expect(await repository.load(), isEmpty);

    await repository.save(item);
    final loaded = await repository.load();

    expect(loaded.length, 1);
    expect(loaded.first.id, item.id);
    expect(loaded.first.name, item.name);
    expect(loaded.first.furniture.parts.length, furniture.parts.length);

    await repository.delete(item.id);
    expect(await repository.load(), isEmpty);
  });

  test('ignora datos corruptos sin lanzar excepción', () async {
    SharedPreferences.setMockInitialValues({
      'mueblecad.library.v1': 'esto no es json',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesFurnitureLibraryRepository(preferences);

    expect(await repository.load(), isEmpty);
  });
}
