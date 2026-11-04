import 'furniture.dart';

/// Mueble guardado en la biblioteca local del usuario.
class SavedFurniture {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final DateTime createdAt;
  final Furniture furniture;

  const SavedFurniture({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.createdAt,
    required this.furniture,
  });
}
