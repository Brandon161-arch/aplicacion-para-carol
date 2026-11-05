import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/regional_catalog.dart';

void main() {
  test(
    'la configuración regional externa contiene perfiles utilizables',
    () async {
      final json = jsonDecode(
        await File('assets/config/regional_profiles.json').readAsString(),
      ) as Map<String, dynamic>;
      final catalog = RegionalCatalog.fromJson(json);

      final colombia = catalog.countryByCode('CO')!;
      expect(catalog.countries.map((country) => country.code), [
        'CO',
        'MX',
        'ES',
        'US',
      ]);
      expect(colombia.materialPrices['mdf_18']!.priceCents, 16990000);
      expect(colombia.hardwarePricesCents['hinge'], 450000);
      expect(colombia.cutPriceTiers, isNotEmpty);
      expect(catalog.climates, isNotEmpty);
      expect(catalog.uses, isNotEmpty);
    },
  );
}
