enum CostCategory { material, waste, edgeBanding, cutting, hardware, labor }

class CostLine {
  final CostCategory category;
  final String label;
  final double quantity;
  final String unit;
  final int unitPriceCents;
  final int totalCents;
  final String? detail;

  const CostLine({
    required this.category,
    required this.label,
    required this.quantity,
    required this.unit,
    required this.unitPriceCents,
    required this.totalCents,
    this.detail,
  });
}

class CostReport {
  final List<CostLine> lines;
  final int materialTotalCents;
  final int wasteTotalCents;
  final int edgeBandingTotalCents;
  final int cuttingTotalCents;
  final int hardwareTotalCents;
  final int laborTotalCents;
  final int grandTotalCents;
  final double cutAreaM2;
  final double estimatedWasteAreaM2;
  final int estimatedSheets;
  final String currency;
  final String pricingNote;

  const CostReport({
    required this.lines,
    required this.materialTotalCents,
    required this.wasteTotalCents,
    required this.edgeBandingTotalCents,
    required this.cuttingTotalCents,
    required this.hardwareTotalCents,
    required this.laborTotalCents,
    required this.grandTotalCents,
    required this.cutAreaM2,
    required this.estimatedWasteAreaM2,
    required this.estimatedSheets,
    required this.currency,
    required this.pricingNote,
  });
}
