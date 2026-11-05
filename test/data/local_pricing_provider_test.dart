import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/hardware_item.dart';
import 'package:mueble_cad/domain/entities/pricing_settings.dart';
import 'package:mueble_cad/presentation/providers/designer_providers.dart';
import 'package:mueble_cad/presentation/providers/pricing_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persiste precios de materiales, herrajes y servicios', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(localPricingProvider.future);
    const settings = PricingSettings(
      wastePercent: 15,
      cutPricePerSheetOverrideCents: 650000,
      laborRateCentsPerHour: 2500000,
      estimatedLaborHours: 4,
    );
    await container
        .read(localPricingProvider.notifier)
        .updateAll(
          materialPriceOverrides: const {'mdf_18': 20000000},
          hardwarePriceOverrides: const {'hinge': 500000},
          settings: settings,
        );

    final updated = await container.read(localPricingProvider.future);
    expect(updated.materialPriceOverrides['mdf_18'], 20000000);
    expect(updated.hardwarePriceOverrides['hinge'], 500000);
    expect(updated.settings.wastePercent, 15);
    expect(updated.settings.cutPricePerSheetOverrideCents, 650000);
    expect(
      container.read(materialCatalogProvider).byId('mdf_18')?.priceCents,
      20000000,
    );
    expect(
      container.read(hardwarePriceCatalogProvider).priceFor(HardwareKind.hinge),
      500000,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('mueblecad.pricing.v1'), isNotNull);
  });
}
