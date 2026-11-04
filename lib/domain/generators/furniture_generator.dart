import '../entities/furniture.dart';
import '../entities/furniture_spec.dart';
import '../entities/material.dart';

/// Contrato de los generadores paramétricos.
///
/// Cada tipo de mueble tendrá su propio generador. El generador recibe los
/// parámetros y devuelve la geometría completa (piezas, uniones y mecanismos).
abstract interface class FurnitureGenerator {
  FurnitureType get type;

  Furniture generate({
    required FurnitureSpec spec,
    required MaterialCatalog catalog,
  });
}
