import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/services/cut_list_calculator.dart';
import '../providers/app_section_provider.dart';
import '../providers/custom_model_providers.dart';
import '../providers/designer_providers.dart';
import '../providers/library_providers.dart';
import '../widgets/cut_list_table.dart';
import '../widgets/flat_patterns_panel.dart';
import '../widgets/part_detail_dialog.dart';
import '../widgets/stat_chip.dart';
import '../widgets/surface_card.dart';
import '../widgets/viewer_card.dart';

class ModelPreviewScreen extends ConsumerStatefulWidget {
  final Furniture furniture;
  final String name;
  final String? description;
  final List<String> tags;
  final String? savedId;

  const ModelPreviewScreen({
    super.key,
    required this.furniture,
    required this.name,
    this.description,
    this.tags = const [],
    this.savedId,
  });

  @override
  ConsumerState<ModelPreviewScreen> createState() => _ModelPreviewScreenState();
}

class _ModelPreviewScreenState extends ConsumerState<ModelPreviewScreen> {
  String? _savedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedId = widget.savedId;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _useAsBase() {
    ref
        .read(customModelProvider.notifier)
        .loadFurniture(widget.furniture, name: widget.name);
    ref.read(appSectionProvider.notifier).select(AppSection.create);
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final item = await ref
          .read(savedFurnitureProvider.notifier)
          .save(
            widget.furniture,
            name: widget.name,
            description: widget.description,
            tags: widget.tags,
          );
      if (!mounted) return;
      setState(() {
        _savedId = item.id;
        _saving = false;
      });
      _snack('${item.name} guardado en tu biblioteca.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('No se pudo guardar: $error');
    }
  }

  Future<void> _delete() async {
    final id = _savedId;
    if (id == null) return;
    try {
      await ref.read(savedFurnitureProvider.notifier).delete(id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      _snack('No se pudo eliminar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = ref.watch(materialCatalogProvider);
    final cutList = const CutListCalculator().build(widget.furniture, catalog);
    final furniture = widget.furniture;

    void openDetail(CutListItem item) {
      final part = furniture.partById(item.partIds.first);
      if (part == null) return;
      showPartDetailDialog(context, part: part, item: item, catalog: catalog);
    }

    final templates = FlatPatternsPanel(
      cutList: cutList,
      catalog: catalog,
      height: 480,
      onOpen: openDetail,
    );

    final content = furniture.parts.isEmpty
        ? SurfaceCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'Este mueble todavía no tiene piezas.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        : Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1100) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ViewerCard(
                            furniture: furniture,
                            viewerHeight: 480,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(width: 400, child: templates),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      ViewerCard(furniture: furniture, viewerHeight: 420),
                      const SizedBox(height: 20),
                      templates,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              CutListTable(
                cutList: cutList,
                catalog: catalog,
                onItemTap: openDetail,
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Usar como base para crear',
            icon: const Icon(Icons.architecture),
            onPressed: _useAsBase,
          ),
          if (_savedId == null)
            IconButton(
              tooltip: 'Guardar en mi biblioteca',
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _saving ? null : _save,
            )
          else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: 'Guardado en tu biblioteca',
                child: Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar de mi biblioteca',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: theme.textTheme.headlineSmall),
                if (widget.description != null &&
                    widget.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatChip(
                      icon: Icons.straighten,
                      label:
                          '${formatMm(furniture.overallSize.width)} × ${formatMm(furniture.overallSize.height)} × ${formatMm(furniture.overallSize.depth)} mm',
                    ),
                    StatChip(
                      icon: Icons.widgets_outlined,
                      label: countLabel(
                        furniture.parts.length,
                        'pieza',
                        'piezas',
                      ),
                    ),
                    StatChip(
                      icon: Icons.square_foot,
                      label: '${formatM2(cutList.totalAreaM2)} m² de corte',
                    ),
                    for (final tag in widget.tags.take(3))
                      StatChip(icon: Icons.label_outline, label: tag),
                  ],
                ),
                const SizedBox(height: 18),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
