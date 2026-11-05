import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/hardware_price_seed.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/entities/material.dart';
import 'package:mueble_cad/domain/entities/pricing_settings.dart';
import 'package:mueble_cad/domain/entities/regional_catalog.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/furniture_estimator.dart';

void main() {
  final furniture = const CabinetDoorsDrawerGenerator().generate(
    spec: sampleCabinetSpec,
    catalog: sampleMaterialCatalog,
  );
  const estimator = FurnitureEstimator();

  test('estima materiales, desperdicio, corte y herrajes', () {
    final estimate = estimator.calculate(
      furniture: furniture,
      catalog: sampleMaterialCatalog,
      hardwarePrices: sampleHardwarePrices,
      pricingSettings: const PricingSettings(
        cutPricePerSheetOverrideCents: 500000,
      ),
    );
    final report = estimate.costs;

    expect(report.materialTotalCents, greaterThan(0));
    expect(report.wasteTotalCents, greaterThan(0));
    expect(report.edgeBandingTotalCents, greaterThan(0));
    expect(report.cuttingTotalCents, greaterThan(0));
    expect(report.hardwareTotalCents, greaterThan(0));
    expect(report.estimatedSheets, greaterThan(0));
    expect(report.estimatedWasteAreaM2, greaterThan(0));
    expect(report.grandTotalCents, greaterThan(report.materialTotalCents));
    expect(report.currency, 'COP');
  });

  test('el costo total reconcilia los rubros sin duplicar el desperdicio', () {
    final report = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(),
        )
        .costs;

    expect(
      report.grandTotalCents,
      report.materialTotalCents +
          report.edgeBandingTotalCents +
          report.cuttingTotalCents +
          report.hardwareTotalCents +
          report.laborTotalCents,
    );
    expect(
      report.lines.any((line) => line.label.contains('Desperdicio')),
      isTrue,
    );
  });

  test('calcula impuesto local por separado y lo suma al total final', () {
    final report = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(),
          taxPercent: 19,
        )
        .costs;

    expect(report.taxPercent, 19);
    expect(report.taxTotalCents, (report.grandTotalCents * 0.19).round());
    expect(
      report.totalWithTaxCents,
      report.grandTotalCents + report.taxTotalCents,
    );
  });

  test('una tarifa de corte manual reemplaza la tarifa por rango', () {
    const manualCutPriceCents = 1000000; // COP 10.000 por lámina
    final report = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(
            cutPricePerSheetOverrideCents: manualCutPriceCents,
          ),
        )
        .costs;

    expect(
      report.cuttingTotalCents,
      report.estimatedSheets * manualCutPriceCents,
    );
  });

  test('aplica la tarifa de corte configurada para el perfil regional', () {
    const regionalTiers = [
      CutPriceTier(maxPiecesPerSheet: 10, priceCents: 600000),
      CutPriceTier(maxPiecesPerSheet: null, priceCents: 1200000),
    ];
    final report = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(),
          cutPriceTiers: regionalTiers,
        )
        .costs;

    expect(report.cuttingTotalCents, greaterThan(0));
  });

  test('mayor desperdicio no reduce la compra ni el costo estimado', () {
    final lowWaste = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(wastePercent: 0),
        )
        .costs;
    final highWaste = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(wastePercent: 25),
        )
        .costs;

    expect(
      highWaste.estimatedSheets,
      greaterThanOrEqualTo(lowWaste.estimatedSheets),
    );
    expect(
      highWaste.grandTotalCents,
      greaterThanOrEqualTo(lowWaste.grandTotalCents),
    );
  });

  test('un precio de tablero más alto aumenta el costo del mueble', () {
    final expensiveCatalog = MaterialCatalog([
      for (final material in sampleMaterialCatalog.materials)
        if (material.id == 'mdf_18')
          material.copyWith(priceCents: material.priceCents * 2)
        else
          material,
    ]);
    final base = estimator
        .calculate(
          furniture: furniture,
          catalog: sampleMaterialCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(),
        )
        .costs;
    final expensive = estimator
        .calculate(
          furniture: furniture,
          catalog: expensiveCatalog,
          hardwarePrices: sampleHardwarePrices,
          pricingSettings: const PricingSettings(),
        )
        .costs;

    expect(expensive.grandTotalCents, greaterThan(base.grandTotalCents));
  });
}
