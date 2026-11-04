import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/shared_preferences_furniture_library_repository.dart';
import '../../data/seeds/preset_furniture.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/saved_furniture.dart';
import '../../domain/repositories/furniture_library_repository.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final furnitureLibraryRepositoryProvider =
    FutureProvider<FurnitureLibraryRepository>((ref) async {
      final preferences = await ref.watch(sharedPreferencesProvider.future);
      return SharedPreferencesFurnitureLibraryRepository(preferences);
    });

class SavedFurnitureController extends AsyncNotifier<List<SavedFurniture>> {
  @override
  Future<List<SavedFurniture>> build() async {
    final repository = await ref.watch(
      furnitureLibraryRepositoryProvider.future,
    );
    return repository.load();
  }

  Future<SavedFurniture> save(
    Furniture furniture, {
    String? name,
    String? description,
    List<String> tags = const [],
  }) async {
    final repository = await ref.read(
      furnitureLibraryRepositoryProvider.future,
    );
    final item = SavedFurniture(
      id: 'saved_${DateTime.now().microsecondsSinceEpoch}',
      name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : furniture.name,
      description: description ?? 'Mueble guardado en este dispositivo.',
      tags: tags,
      createdAt: DateTime.now(),
      furniture: furniture,
    );
    await repository.save(item);
    state = AsyncData(await repository.load());
    return item;
  }

  Future<void> delete(String id) async {
    final repository = await ref.read(
      furnitureLibraryRepositoryProvider.future,
    );
    await repository.delete(id);
    state = AsyncData(await repository.load());
  }
}

final savedFurnitureProvider =
    AsyncNotifierProvider<SavedFurnitureController, List<SavedFurniture>>(
      SavedFurnitureController.new,
    );

final presetFurnitureProvider = Provider<List<PresetFurniture>>(
  (ref) => buildPresetFurniture(),
);
