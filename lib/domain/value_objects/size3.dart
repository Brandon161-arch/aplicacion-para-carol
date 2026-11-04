/// Dimensiones ortogonales en los ejes del mueble, en milímetros.
class Size3 {
  final double width; // eje X
  final double height; // eje Y
  final double depth; // eje Z

  const Size3({required this.width, required this.height, required this.depth});

  double get maxDimension =>
      [width, height, depth].reduce((a, b) => a > b ? a : b);

  double get volumeM3 => (width * height * depth) / 1000000000;

  Size3 copyWith({double? width, double? height, double? depth}) => Size3(
    width: width ?? this.width,
    height: height ?? this.height,
    depth: depth ?? this.depth,
  );

  @override
  bool operator ==(Object other) =>
      other is Size3 &&
      other.width == width &&
      other.height == height &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(width, height, depth);

  @override
  String toString() => 'Size3($width x $height x $depth)';
}
