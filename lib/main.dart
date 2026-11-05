import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'data/repositories/regional_config_repository.dart';
import 'presentation/providers/project_context_provider.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final regionalCatalog = await RegionalConfigRepository(
    assetBundle: rootBundle,
  ).load();
  runApp(
    ProviderScope(
      overrides: [regionalCatalogProvider.overrideWithValue(regionalCatalog)],
      child: const MuebleCadApp(),
    ),
  );
}
