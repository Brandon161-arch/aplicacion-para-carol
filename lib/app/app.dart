import 'package:flutter/material.dart';

import '../presentation/screens/app_shell.dart';
import 'theme/app_theme.dart';

class MuebleCadApp extends StatelessWidget {
  const MuebleCadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuebleCAD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
