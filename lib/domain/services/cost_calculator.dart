import 'dart:math' as math;

import '../entities/cost_report.dart';
import '../entities/hardware_requirement.dart';
import '../entities/material.dart';
import '../entities/pricing_settings.dart';
import 'cut_list_calculator.dart';

/// Estima compra de material por lámina, cantos, corte y herrajes.
///
/// El cálculo de láminas usa área más desperdicio; no reemplaza un nesting
/// optimizado. Las tarifas de corte son referencias públicas de Madecentro.
class CostCalculator {
  const CostCalculator();

  CostReport calculate({
    required CutList cutList,
    required MaterialCatalog catalog,
    required List<HardwareRequirement> hardware,
    required PricingSettings settings,
  }) {
    final lines = <CostLine>[];
    final materialLines = <_MaterialEstimate>[];
    var materialTotal = 0;
    var estimatedWasteArea = 0.0;
    var sheetCountTotal = 0;

    final wasteFraction = math.max(0.0, settings.wastePercent) / 100;

    for (final material in catalog.materials) {
      final area = cutList.areaByMaterial[material.id] ?? 0;
      final pieces = cutList.piecesByMaterial[material.id] ?? 0;
      if (pieces == 0) continue;

      switch (material.priceUnit) {
        case PriceUnit.perSheet:
          final sheetSize = material.sheetSize;
          if (sheetSize == null || sheetSize.areaM2 <= 0) continue;
          final requiredArea = area * (1 + wasteFraction);
          final sheets = math.max(1, (requiredArea / sheetSize.areaM2).ceil());
          final cost = sheets * material.priceCents;
          final purchasedArea = sheets * sheetSize.areaM2;
          final wasteArea = math.max(0.0, purchasedArea - area);
          materialTotal += cost;
          estimatedWasteArea += wasteArea;
          sheetCountTotal += sheets;
          materialLines.add(
            _MaterialEstimate(
              material: material,
              quantity: sheets.toDouble(),
              unit: sheets == 1 ? 'lámina' : 'láminas',
              unitPriceCents: material.priceCents,
              totalCents: cost,
              areaM2: area,
              sheets: sheets,
              pieces: pieces,
              wasteAreaM2: wasteArea,
            ),
          );
          lines.add(
            CostLine(
              category: CostCategory.material,
              label: material.name,
              quantity: sheets.toDouble(),
              unit: sheets == 1 ? 'lámina' : 'láminas',
              unitPriceCents: material.priceCents,
              totalCents: cost,
              detail:
                  '${area.toStringAsFixed(2)} m² en piezas; $pieces piezas; '
                  'lámina ${sheetSize.widthMm.round()} x ${sheetSize.heightMm.round()} mm',
            ),
          );

        case PriceUnit.perSquareMeter:
          final cost = (area * material.priceCents).round();
          materialTotal += cost;
          materialLines.add(
            _MaterialEstimate(
              material: material,
              quantity: area,
              unit: 'm²',
              unitPriceCents: material.priceCents,
              totalCents: cost,
              areaM2: area,
              sheets: 0,
              pieces: pieces,
              wasteAreaM2: 0,
            ),
          );
          lines.add(
            CostLine(
              category: CostCategory.material,
              label: material.name,
              quantity: area,
              unit: 'm²',
              unitPriceCents: material.priceCents,
              totalCents: cost,
            ),
          );

        case PriceUnit.perUnit:
          final cost = pieces * material.priceCents;
          materialTotal += cost;
          materialLines.add(
            _MaterialEstimate(
              material: material,
              quantity: pieces.toDouble(),
              unit: pieces == 1 ? 'unidad' : 'unidades',
              unitPriceCents: material.priceCents,
              totalCents: cost,
              areaM2: area,
              sheets: 0,
              pieces: pieces,
              wasteAreaM2: 0,
            ),
          );
          lines.add(
            CostLine(
              category: CostCategory.material,
              label: material.name,
              quantity: pieces.toDouble(),
              unit: pieces == 1 ? 'unidad' : 'unidades',
              unitPriceCents: material.priceCents,
              totalCents: cost,
            ),
          );

        case PriceUnit.perLinearMeter:
          // Los materiales lineales se calculan desde el canto más abajo.
          continue;
      }
    }

    final wasteCost = _estimateWasteCost(materialLines);
    if (estimatedWasteArea > 0) {
      lines.add(
        CostLine(
          category: CostCategory.waste,
          label: 'Desperdicio estimado (incluido en las láminas)',
          quantity: estimatedWasteArea,
          unit: 'm²',
          unitPriceCents: 0,
          totalCents: wasteCost,
          detail:
              'Área sobrante aproximada después de comprar láminas completas.',
        ),
      );
    }

    final bandingLengths = <String, double>{};
    for (final item in cutList.items) {
      if (item.bandingLengthM <= 0) continue;
      final bandingMaterialId = item.bandingMaterialIds.isEmpty
          ? 'pvc_edge'
          : item.bandingMaterialIds.first;
      bandingLengths.update(
        bandingMaterialId,
        (length) => length + item.bandingLengthM,
        ifAbsent: () => item.bandingLengthM,
      );
    }

    var edgeBandingTotal = 0;
    for (final entry in bandingLengths.entries) {
      final material = catalog.byId(entry.key);
      final pricePerMeter = material?.priceUnit == PriceUnit.perLinearMeter
          ? material!.priceCents
          : material?.edgeBandingPricePerMeterCents ?? 0;
      final cost = (entry.value * pricePerMeter).round();
      edgeBandingTotal += cost;
      if (cost == 0) continue;
      lines.add(
        CostLine(
          category: CostCategory.edgeBanding,
          label: material?.name ?? 'Canto',
          quantity: entry.value,
          unit: 'm',
          unitPriceCents: pricePerMeter,
          totalCents: cost,
        ),
      );
    }

    var cuttingTotal = 0;
    for (final estimate in materialLines.where((line) => line.sheets > 0)) {
      final piecesPerSheet = (estimate.pieces / estimate.sheets).ceil();
      final pricePerSheet =
          settings.cutPricePerSheetOverrideCents ??
          _madecentroCutPricePerSheet(piecesPerSheet);
      final cost = pricePerSheet * estimate.sheets;
      cuttingTotal += cost;
      lines.add(
        CostLine(
          category: CostCategory.cutting,
          label: 'Corte · ${estimate.material.name}',
          quantity: estimate.sheets.toDouble(),
          unit: estimate.sheets == 1 ? 'lámina' : 'láminas',
          unitPriceCents: pricePerSheet,
          totalCents: cost,
          detail: settings.cutPricePerSheetOverrideCents == null
              ? 'Tarifa de referencia Madecentro para $piecesPerSheet piezas/lámina.'
              : 'Tarifa manual por lámina.',
        ),
      );
    }

    var hardwareTotal = 0;
    for (final requirement in hardware) {
      final cost = requirement.totalPriceCents;
      hardwareTotal += cost;
      lines.add(
        CostLine(
          category: CostCategory.hardware,
          label: requirement.name,
          quantity: requirement.quantity.toDouble(),
          unit: 'unidades',
          unitPriceCents: requirement.unitPriceCents,
          totalCents: cost,
          detail: requirement.spec,
        ),
      );
    }

    final laborTotal =
        (settings.estimatedLaborHours * settings.laborRateCentsPerHour).round();
    if (laborTotal > 0) {
      lines.add(
        CostLine(
          category: CostCategory.labor,
          label: 'Mano de obra estimada',
          quantity: settings.estimatedLaborHours,
          unit: 'horas',
          unitPriceCents: settings.laborRateCentsPerHour,
          totalCents: laborTotal,
        ),
      );
    }

    return CostReport(
      lines: lines,
      materialTotalCents: materialTotal,
      wasteTotalCents: wasteCost,
      edgeBandingTotalCents: edgeBandingTotal,
      cuttingTotalCents: cuttingTotal,
      hardwareTotalCents: hardwareTotal,
      laborTotalCents: laborTotal,
      grandTotalCents:
          materialTotal +
          edgeBandingTotal +
          cuttingTotal +
          hardwareTotal +
          laborTotal,
      cutAreaM2: cutList.totalAreaM2,
      estimatedWasteAreaM2: estimatedWasteArea,
      estimatedSheets: sheetCountTotal,
      currency: settings.currency,
      pricingNote: 'Precios de referencia Madecentro/Homecenter; varían por ciudad, marca, color y disponibilidad. El corte se estima por lámina, sin nesting optimizado.',
    );
  }

  int _madecentroCutPricePerSheet(int piecesPerSheet) {
    // Madecentro publica tarifas por rangos de piezas por lámina. Para 1–15
    // piezas se aplica como referencia el primer rango publicado (16–25).
    if (piecesPerSheet <= 25) return 535400; // COP 5.354
    if (piecesPerSheet <= 35) return 815000; // COP 8.150
    if (piecesPerSheet <= 50) return 1344300; // COP 13.443
    if (piecesPerSheet <= 100) return 1993100; // COP 19.931
    return 2832500; // COP 28.325
  }

  int _estimateWasteCost(List<_MaterialEstimate> estimates) {
    var total = 0;
    for (final estimate in estimates) {
      if (estimate.sheets == 0 || estimate.wasteAreaM2 <= 0) continue;
      final sheetArea = estimate.material.sheetSize?.areaM2 ?? 0;
      if (sheetArea <= 0) continue;
      final wasteFraction =
          estimate.wasteAreaM2 / (estimate.sheets * sheetArea);
      total += (estimate.totalCents * wasteFraction).round();
    }
    return total;
  }
}

class _MaterialEstimate {
  final Material material;
  final double quantity;
  final String unit;
  final int unitPriceCents;
  final int totalCents;
  final double areaM2;
  final int sheets;
  final int pieces;
  final double wasteAreaM2;

  const _MaterialEstimate({
    required this.material,
    required this.quantity,
    required this.unit,
    required this.unitPriceCents,
    required this.totalCents,
    required this.areaM2,
    required this.sheets,
    required this.pieces,
    required this.wasteAreaM2,
  });
}
