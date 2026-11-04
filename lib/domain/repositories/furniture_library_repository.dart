import '../entities/saved_furniture.dart';

/// Contrato de la biblioteca de muebles del usuario.
///
/// La implementación actual guarda en el dispositivo. Más adelante se puede
/// sustituir por una API sin cambiar la UI ni los casos de uso.
abstract interface class FurnitureLibraryRepository {
  Future<List<SavedFurniture>> load();

  Future<void> save(SavedFurniture item);

  Future<void> delete(String id);
}
