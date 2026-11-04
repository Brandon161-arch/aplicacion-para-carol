import 'package:flutter/material.dart';

import '../presentation/screens/designer_screen.dart';
import 'theme/app_theme.dart';

class MuebleCadApp extends StatelessWidget {
  const MuebleCadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuebleCAD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const DesignerScreen(),
    );
  }
}
