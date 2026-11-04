import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/saved_furniture.dart';
import '../../domain/repositories/furniture_library_repository.dart';
import '../dto/furniture_json_codec.dart';

/// Guarda la biblioteca del usuario en el almacenamiento local del dispositivo.
///
/// En web usa localStorage y en Android/Windows usa las preferencias nativas.
/// Una fase posterior puede reemplazarla por una API sin tocar la UI.
class SharedPreferencesFurnitureLibraryRepository
    implements FurnitureLibraryRepository {
  static const String _storageKey = 'mueblecad.library.v1';

  final SharedPreferences _preferences;

  SharedPreferencesFurnitureLibraryRepository(this._preferences);

  @override
  Future<List<SavedFurniture>> load() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                FurnitureJsonCodec.savedFromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(SavedFurniture item) async {
    final items = await load();
    final updated = [
      ...items.where((existing) => existing.id != item.id),
      item,
    ];
    await _write(updated);
  }

  @override
  Future<void> delete(String id) async {
    final items = await load();
    await _write(items.where((item) => item.id != id).toList(growable: false));
  }

  Future<void> _write(List<SavedFurniture> items) async {
    final raw = jsonEncode(
      items.map(FurnitureJsonCodec.savedToJson).toList(growable: false),
    );
    await _preferences.setString(_storageKey, raw);
  }
}
