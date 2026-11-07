import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';

const String onboardingSeenKey = 'mueblecad.tour.seen.v1';

Future<void> showOnboardingTour(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool(onboardingSeenKey, true);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _OnboardingDialog(),
  );
}

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<({IconData icon, String title, String text})> _steps = [
    (
      icon: Icons.design_services_outlined,
      title: '1. Empieza con las medidas',
      text: 'En Diseñar ajusta el ancho, el alto y el fondo. El mueble, el despiece y los costos se actualizan solos.',
    ),
    (
      icon: Icons.view_in_ar_outlined,
      title: '2. Mira el mueble en 3D',
      text: 'Arrastra sobre el mueble para girarlo y usa la rueda sobre él para acercarte. Las vistas Frontal, Lateral y Planta te muestran cada lado.',
    ),
    (
      icon: Icons.grid_view_outlined,
      title: '3. Revisa las piezas',
      text: 'En Plantillas de corte ves cada pieza con su largo y ancho. El canto es la cinta que cubre los bordes para protegerlos y darles buen acabado.',
    ),
    (
      icon: Icons.format_list_bulleted,
      title: '4. Lleva el despiece al taller',
      text: 'En Despiece está la lista completa de piezas. ×2 significa dos piezas iguales. Puedes copiar la lista para mostrarla o enviarla.',
    ),
    (
      icon: Icons.explore_outlined,
      title: '5. Explora y crea',
      text: 'En Crear puedes partir de una plantilla o agregar piezas. En Explorar encontrarás ejemplos y tus muebles guardados.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(duration: AppTheme.normal, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final step = _steps[_index];
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(step.icon, color: scheme.primary, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Guía rápida de Mueble Maestro',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar guía',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = _steps[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(page.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          page.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_index + 1} de ${_steps.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (var index = 0; index < _steps.length; index++)
                    AnimatedContainer(
                      duration: AppTheme.fast,
                      margin: const EdgeInsets.only(right: 5),
                      width: index == _index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: index == _index
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Saltar'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _index == _steps.length - 1 ? 'Empezar' : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
