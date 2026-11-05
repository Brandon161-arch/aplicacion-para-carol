import 'dart:math' as math;

import '../entities/cost_report.dart';
import '../entities/hardware_requirement.dart';
import '../entities/material.dart';
import '../entities/pricing_settings.dart';
import '../entities/regional_catalog.dart';
import 'cut_list_calculator.dart';

/// Estima compra de material por lámina, cantos, corte y herrajes.
///
/// El cálculo de láminas usa área más kerf y desperdicio; no reemplaza un
/// nesting optimizado. Precios y rangos se reciben desde el perfil regional.
class CostCalculator {
  const CostCalculator();

  CostReport calculate({
    required CutList cutList,
    required MaterialCatalog catalog,
    required List<HardwareRequirement> hardware,
    required PricingSettings settings,
    double taxPercent = 0,
    List<CutPriceTier> cutPriceTiers = const [],
    String pricingNote = 'Precios locales no configurados.',
  }) {
    final lines = <CostLine>[];
    final materialLines = <_MaterialEstimate>[];
    var materialTotal = 0;
    var estimatedWasteArea = 0.0;
    var sheetCountTotal = 0;

    final wasteFraction = math.max(0.0, settings.wastePercent) / 100;

    for (final material in catalog.materials) {
      final area = cutList.areaByMaterial[material.id] ?? 0;
      final kerfArea = cutList.kerfLossM2ByMaterial[material.id] ?? 0;
      final pieces = cutList.piecesByMaterial[material.id] ?? 0;
      if (pieces == 0) continue;

      switch (material.priceUnit) {
        case PriceUnit.perSheet:
          final sheetSize = material.sheetSize;
          if (sheetSize == null || sheetSize.areaM2 <= 0) continue;
          final requiredArea = (area + kerfArea) * (1 + wasteFraction);
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
                  'kerf aprox. ${kerfArea.toStringAsFixed(3)} m²; '
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
          _cutPricePerSheet(piecesPerSheet, cutPriceTiers);
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
              ? 'Tarifa configurada para $piecesPerSheet piezas/lámina.'
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

    final productionTotal =
        materialTotal +
        edgeBandingTotal +
        cuttingTotal +
        hardwareTotal +
        laborTotal;
    final taxTotal = (productionTotal * math.max(0, taxPercent) / 100).round();

    return CostReport(
      lines: lines,
      materialTotalCents: materialTotal,
      wasteTotalCents: wasteCost,
      edgeBandingTotalCents: edgeBandingTotal,
      cuttingTotalCents: cuttingTotal,
      hardwareTotalCents: hardwareTotal,
      laborTotalCents: laborTotal,
      grandTotalCents: productionTotal,
      taxPercent: math.max(0, taxPercent).toDouble(),
      taxTotalCents: taxTotal,
      totalWithTaxCents: productionTotal + taxTotal,
      cutAreaM2: cutList.totalAreaM2,
      estimatedKerfLossM2: cutList.estimatedKerfLossM2,
      estimatedCutLengthM: cutList.estimatedCutLengthM,
      kerfMm: cutList.kerfMm,
      estimatedWasteAreaM2: estimatedWasteArea,
      estimatedSheets: sheetCountTotal,
      currency: settings.currency,
      pricingNote:
          '$pricingNote Kerf estimado conservadoramente desde perímetros; láminas por área, sin nesting optimizado.',
    );
  }

  int _cutPricePerSheet(int piecesPerSheet, List<CutPriceTier> tiers) {
    for (final tier in tiers) {
      final maximum = tier.maxPiecesPerSheet;
      if (maximum == null || piecesPerSheet <= maximum) {
        return tier.priceCents;
      }
    }
    return 0;
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
