import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_section_provider.dart';
import 'create_screen.dart';
import 'designer_screen.dart';
import 'explore_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(appSectionProvider);
    final controller = ref.read(appSectionProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    void select(int index) => controller.select(AppSection.values[index]);

    final pages = const [DesignerScreen(), CreateScreen(), ExploreScreen()];

    const sections = [
      (
        label: 'Diseñar',
        icon: Icons.design_services_outlined,
        selectedIcon: Icons.design_services,
      ),
      (
        label: 'Crear',
        icon: Icons.add_box_outlined,
        selectedIcon: Icons.add_box,
      ),
      (
        label: 'Explorar',
        icon: Icons.search_outlined,
        selectedIcon: Icons.search,
      ),
    ];

    final railDestinations = [
      for (final section in sections)
        NavigationRailDestination(
          icon: Icon(section.icon),
          selectedIcon: Icon(section.selectedIcon),
          label: Text(section.label),
        ),
    ];
    final bottomDestinations = [
      for (final section in sections)
        NavigationDestination(
          icon: Icon(section.icon),
          selectedIcon: Icon(section.selectedIcon),
          label: section.label,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final body = IndexedStack(index: section.index, children: pages);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.carpenter,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('MuebleCAD'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Acerca de MuebleCAD',
                icon: const Icon(Icons.info_outline),
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'MuebleCAD',
                  applicationVersion: 'Fase 2',
                  applicationLegalese: 'Diseño paramétrico de muebles.',
                  children: const [
                    SizedBox(height: 8),
                    Text(
                      'Diseñar: mueble de ejemplo con medidas editables. '
                      'Crear: constructor libre para agregar piezas, verlas '
                      'en 3D y obtener sus plantillas de corte. '
                      'Explorar: modelos de ejemplo y tu biblioteca local.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: section.index,
                      onDestinationSelected: select,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      destinations: railDestinations,
                    ),
                    VerticalDivider(width: 1, color: scheme.outlineVariant),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: section.index,
                  onDestinationSelected: select,
                  destinations: bottomDestinations,
                ),
        );
      },
    );
  }
}
