/// Medidas de corte de una pieza, en milímetros.
///
/// [length] y [width] forman la cara plana de la lámina.
/// [thickness] es el espesor (normal de la lámina).
class CutSize {
  final double length;
  final double width;
  final double thickness;

  const CutSize({
    required this.length,
    required this.width,
    required this.thickness,
  });

  double get areaM2 => (length * width) / 1000000;

  /// Las tres medidas ordenadas. Sirve para comprobar que [CutSize] y la
  /// caja en el mundo describen la misma pieza.
  List<double> get sortedDimensions => [length, width, thickness]..sort();

  CutSize copyWith({double? length, double? width, double? thickness}) =>
      CutSize(
        length: length ?? this.length,
        width: width ?? this.width,
        thickness: thickness ?? this.thickness,
      );

  @override
  bool operator ==(Object other) =>
      other is CutSize &&
      other.length == length &&
      other.width == width &&
      other.thickness == thickness;

  @override
  int get hashCode => Object.hash(length, width, thickness);

  @override
  String toString() => 'CutSize($length x $width x $thickness)';
}
