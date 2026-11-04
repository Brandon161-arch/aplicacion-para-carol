import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../data/seeds/preset_furniture.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/saved_furniture.dart';
import '../providers/app_section_provider.dart';
import '../providers/library_providers.dart';
import '../widgets/mini_furniture_preview.dart';
import '../widgets/surface_card.dart';
import 'model_preview_screen.dart';

enum _SourceFilter {
  all('Todos'),
  presets('Ejemplos'),
  saved('Mis muebles');

  final String label;
  const _SourceFilter(this.label);
}

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  _SourceFilter _source = _SourceFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String name, String description, List<String> tags) {
    if (_query.trim().isEmpty) return true;
    final text = '$name $description ${tags.join(' ')}'.toLowerCase();
    return text.contains(_query.trim().toLowerCase());
  }

  void _openPreset(PresetFurniture preset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModelPreviewScreen(
          furniture: preset.furniture,
          name: preset.name,
          description: preset.description,
          tags: preset.tags,
        ),
      ),
    );
  }

  void _openSaved(SavedFurniture saved) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModelPreviewScreen(
          furniture: saved.furniture,
          name: saved.name,
          description: saved.description,
          tags: saved.tags,
          savedId: saved.id,
        ),
      ),
    );
  }

  Future<void> _deleteSaved(SavedFurniture saved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mueble'),
        content: Text('¿Eliminar "${saved.name}" de tu biblioteca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(savedFurnitureProvider.notifier).delete(saved.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mueble eliminado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
    }
  }

  void _goToCreate() {
    ref.read(appSectionProvider.notifier).select(AppSection.create);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final presets = ref
        .watch(presetFurnitureProvider)
        .where(
          (preset) => _matches(preset.name, preset.description, preset.tags),
        )
        .toList(growable: false);
    final savedAsync = ref.watch(savedFurnitureProvider);
    final saved = [...(savedAsync.asData?.value ?? const <SavedFurniture>[])]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explorar muebles', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Modelos de ejemplo y tus propios diseños guardados en este dispositivo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final search = TextField(
                      key: const Key('explore_search_field'),
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        labelText: 'Buscar por nombre o etiqueta',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar búsqueda',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    );
                    final Widget filters;
                    if (constraints.maxWidth >= 760) {
                      filters = SegmentedButton<_SourceFilter>(
                        segments: [
                          for (final filter in _SourceFilter.values)
                            ButtonSegment(
                              value: filter,
                              label: Text(filter.label),
                            ),
                        ],
                        selected: {_source},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) =>
                            setState(() => _source = selection.first),
                      );
                      return Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 14),
                          filters,
                        ],
                      );
                    }

                    filters = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in _SourceFilter.values)
                          ChoiceChip(
                            label: Text(filter.label),
                            selected: _source == filter,
                            onSelected: (_) => setState(() => _source = filter),
                          ),
                      ],
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [search, const SizedBox(height: 12), filters],
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              if (_source != _SourceFilter.saved) ...[
                _SectionHeader(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  title: 'Modelos de ejemplo',
                  subtitle:
                      '${presets.length} diseños listos para abrir o usar como base.',
                  action: FilledButton.tonalIcon(
                    onPressed: _goToCreate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear mueble'),
                  ),
                ),
                const SizedBox(height: 12),
                if (presets.isEmpty)
                  _InfoMessage(
                    icon: Icons.search_off,
                    title: 'No hay ejemplos que coincidan.',
                    message: 'Prueba con otra búsqueda o borra el filtro.',
                  )
                else
                  _ModelGrid(
                    children: [
                      for (final preset in presets)
                        _ModelCard(
                          furniture: preset.furniture,
                          name: preset.name,
                          description: preset.description,
                          tags: preset.tags,
                          onOpen: () => _openPreset(preset),
                        ),
                    ],
                  ),
                const SizedBox(height: 26),
              ],
              if (_source != _SourceFilter.presets) ...[
                _SectionHeader(
                  icon: Icons.folder_special_outlined,
                  title: 'Mi biblioteca',
                  subtitle: savedAsync.isLoading
                      ? 'Cargando tus muebles guardados...'
                      : '${countLabel(saved.length, 'mueble guardado', 'muebles guardados')} en este dispositivo.',
                  action: OutlinedButton.icon(
                    onPressed: _goToCreate,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Crear'),
                  ),
                ),
                const SizedBox(height: 12),
                savedAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => _InfoMessage(
                    icon: Icons.folder_off_outlined,
                    title: 'No se pudo cargar la biblioteca local.',
                    message:
                        'La app necesita acceso al almacenamiento del dispositivo. '
                        'Detalle: $error',
                    action: TextButton.icon(
                      onPressed: () => ref.invalidate(savedFurnitureProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reintentar'),
                    ),
                  ),
                  data: (items) {
                    final visible =
                        items
                            .where(
                              (item) => _matches(
                                item.name,
                                item.description,
                                item.tags,
                              ),
                            )
                            .toList(growable: false)
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    if (visible.isEmpty) {
                      return _InfoMessage(
                        icon: Icons.bookmark_border,
                        title: queryIsEmpty
                            ? 'Todavía no has guardado muebles.'
                            : 'Ningún mueble guardado coincide.',
                        message: queryIsEmpty
                            ? 'Crea un mueble en la sección Crear y guárdalo para verlo aquí.'
                            : 'Prueba con otra búsqueda.',
                        action: queryIsEmpty
                            ? FilledButton.icon(
                                onPressed: _goToCreate,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Crear mi primer mueble'),
                              )
                            : null,
                      );
                    }
                    return _ModelGrid(
                      children: [
                        for (final item in visible)
                          _ModelCard(
                            furniture: item.furniture,
                            name: item.name,
                            description: item.description,
                            tags: item.tags,
                            saved: true,
                            onOpen: () => _openSaved(item),
                            onDelete: () => _deleteSaved(item),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get queryIsEmpty => _query.trim().isEmpty;
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 8), action],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}

class _ModelGrid extends StatelessWidget {
  final List<Widget> children;

  const _ModelGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 330,
        mainAxisExtent: 310,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ModelCard extends StatelessWidget {
  final Furniture furniture;
  final String name;
  final String description;
  final List<String> tags;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final bool saved;

  const _ModelCard({
    required this.furniture,
    required this.name,
    required this.description,
    required this.tags,
    required this.onOpen,
    this.onDelete,
    this.saved = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: MiniFurniturePreview(furniture: furniture),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (saved)
                            Icon(
                              Icons.bookmark,
                              size: 16,
                              color: scheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          for (final tag in tags.take(2))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatMm(furniture.overallSize.width)} × ${formatMm(furniture.overallSize.height)} × ${formatMm(furniture.overallSize.depth)} mm · ${furniture.parts.length} pzs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          if (onDelete != null)
                            IconButton(
                              tooltip: 'Eliminar de mi biblioteca',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 30,
                                height: 30,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 17,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          TextButton(
                            onPressed: onOpen,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: const Text('Abrir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _InfoMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 34,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      ),
    );
  }
}
