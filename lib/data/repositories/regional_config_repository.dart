import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/regional_catalog.dart';

class RegionalConfigRepository {
  final AssetBundle assetBundle;
  final String assetPath;

  const RegionalConfigRepository({
    required this.assetBundle,
    this.assetPath = 'assets/config/regional_profiles.json',
  });

  Future<RegionalCatalog> load() async {
    final raw = await assetBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'La raíz de la configuración debe ser JSON object.',
      );
    }
    return RegionalCatalog.fromJson(decoded.cast<String, dynamic>());
  }
}
