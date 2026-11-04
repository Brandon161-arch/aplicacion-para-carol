/// Categorías de material que puede usar el mueble.
enum MaterialCategory {
  mdf,
  particleboard,
  plywood,
  solidWood,
  glass,
  metal,
  hpl,
  other;

  String get label => switch (this) {
    MaterialCategory.mdf => 'MDF',
    MaterialCategory.particleboard => 'Aglomerado',
    MaterialCategory.plywood => 'Triplex',
    MaterialCategory.solidWood => 'Madera maciza',
    MaterialCategory.glass => 'Vidrio',
    MaterialCategory.metal => 'Metal',
    MaterialCategory.hpl => 'HPL / laminado',
    MaterialCategory.other => 'Otro',
  };
}

/// Unidad con la que se vende un material.
enum PriceUnit {
  perSheet,
  perSquareMeter,
  perLinearMeter,
  perUnit;

  String get label => switch (this) {
    PriceUnit.perSheet => 'por lámina',
    PriceUnit.perSquareMeter => 'por m²',
    PriceUnit.perLinearMeter => 'por metro lineal',
    PriceUnit.perUnit => 'por unidad',
  };
}

/// Dimensiones estándar de una lámina.
class SheetSize {
  final double widthMm;
  final double heightMm;

  const SheetSize({required this.widthMm, required this.heightMm});

  double get areaM2 => (widthMm * heightMm) / 1000000;

  @override
  String toString() => '${widthMm.round()} x ${heightMm.round()} mm';
}

/// Material de construcción o de canto.
class Material {
  final String id;
  final String name;
  final MaterialCategory category;

  /// Espesores disponibles en milímetros.
  final List<double> thicknessesMm;

  /// Tamaño de lámina. Es null para materiales que no se compran por lámina.
  final SheetSize? sheetSize;

  final PriceUnit priceUnit;

  /// Precio en centavos, según [priceUnit].
  final int priceCents;

  final bool hasGrain;

  /// Precio del canto en centavos por metro lineal.
  final int? edgeBandingPricePerMeterCents;

  const Material({
    required this.id,
    required this.name,
    required this.category,
    required this.thicknessesMm,
    required this.priceUnit,
    required this.priceCents,
    this.sheetSize,
    this.hasGrain = false,
    this.edgeBandingPricePerMeterCents,
  });

  String get thicknessLabel => thicknessesMm
      .map((value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1))
      .join(' / ');
}

/// Catálogo de materiales disponibles para un proyecto.
class MaterialCatalog {
  final List<Material> materials;

  const MaterialCatalog(this.materials);

  Material? byId(String id) {
    for (final material in materials) {
      if (material.id == id) return material;
    }
    return null;
  }

  Material requireById(String id) {
    final material = byId(id);
    if (material == null) {
      throw StateError('No existe el material "$id" en el catálogo.');
    }
    return material;
  }

  /// Busca un material del espesor pedido; opcionalmente filtra por categoría.
  Material? findByThickness(double thicknessMm, {MaterialCategory? category}) {
    for (final material in materials) {
      if (category != null && material.category != category) continue;
      final matches = material.thicknessesMm.any(
        (thickness) => (thickness - thicknessMm).abs() < 0.01,
      );
      if (matches) return material;
    }
    return null;
  }

  List<Material> get sheetMaterials => materials
      .where((material) => material.sheetSize != null)
      .toList(growable: false);
}
