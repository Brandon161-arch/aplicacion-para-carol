import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_section_provider.dart';
import '../widgets/onboarding_tour.dart';
import 'create_screen.dart';
import 'designer_screen.dart';
import 'explore_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    final preferences = await SharedPreferences.getInstance();
    final seen = preferences.getBool(onboardingSeenKey) ?? false;
    if (!seen && mounted) {
      await showOnboardingTour(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = ref.watch(appSectionProvider);
    final controller = ref.read(appSectionProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    void select(int index) => controller.select(AppSection.values[index]);

    final pages = const [DesignerScreen(), CreateScreen(), ExploreScreen()];

    const sections = [
      (
        label: 'Diseñar',
        description: 'Ajusta las medidas del mueble y mira el resultado.',
        icon: Icons.design_services_outlined,
        selectedIcon: Icons.design_services,
      ),
      (
        label: 'Crear',
        description: 'Haz un mueble desde cero o empieza con una plantilla.',
        icon: Icons.add_box_outlined,
        selectedIcon: Icons.add_box,
      ),
      (
        label: 'Explorar',
        description: 'Revisa ejemplos y los muebles que hayas guardado.',
        icon: Icons.search_outlined,
        selectedIcon: Icons.search,
      ),
    ];

    final railDestinations = [
      for (final section in sections)
        NavigationRailDestination(
          icon: Tooltip(
            message: section.description,
            child: Icon(section.icon),
          ),
          selectedIcon: Tooltip(
            message: section.description,
            child: Icon(section.selectedIcon),
          ),
          label: Text(section.label),
        ),
    ];
    final bottomDestinations = [
      for (final section in sections)
        NavigationDestination(
          icon: Tooltip(
            message: section.description,
            child: Icon(section.icon),
          ),
          selectedIcon: Tooltip(
            message: section.description,
            child: Icon(section.selectedIcon),
          ),
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
              mainAxisSize: MainAxisSize.max,
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
                const Expanded(
                  child: Text(
                    'Mueble Maestro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Abrir guía rápida',
                icon: const Icon(Icons.school_outlined),
                onPressed: () => showOnboardingTour(context),
              ),
              IconButton(
                tooltip: 'Acerca de Mueble Maestro',
                icon: const Icon(Icons.info_outline),
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'Mueble Maestro',
                  applicationVersion: 'MVP',
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
