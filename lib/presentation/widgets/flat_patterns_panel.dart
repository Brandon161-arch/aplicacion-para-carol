import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/material.dart' show MaterialCatalog;
import '../../domain/services/cut_list_calculator.dart';
import '../painters/flat_pattern_painter.dart';
import '../painters/part_palette.dart';
import 'stat_chip.dart';
import 'help_tooltip.dart';
import 'surface_card.dart';

class FlatPatternsPanel extends StatefulWidget {
  final CutList cutList;
  final MaterialCatalog catalog;
  final double height;
  final void Function(CutListItem item)? onOpen;

  const FlatPatternsPanel({
    super.key,
    required this.cutList,
    required this.catalog,
    this.height = 480,
    this.onOpen,
  });

  @override
  State<FlatPatternsPanel> createState() => _FlatPatternsPanelState();
}

class _FlatPatternsPanelState extends State<FlatPatternsPanel> {
  bool _expanded = true;

  CutList get cutList => widget.cutList;
  MaterialCatalog get catalog => widget.catalog;
  void Function(CutListItem item)? get onOpen => widget.onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plantillas de corte',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Medidas reales en mm · toca una pieza para verla en grande',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const HelpTooltip(
                  message: 'Cada tarjeta es una pieza que debes cortar. Las medidas son el largo y ancho del panel; el canto es el borde que se cubre con una cinta.',
                ),
                const SizedBox(width: 4),
                StatChip(
                  icon: Icons.grid_view_outlined,
                  label: '${cutList.items.length}',
                ),
                IconButton(
                  tooltip: _expanded
                      ? 'Contraer plantillas'
                      : 'Expandir plantillas',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (cutList.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _EmptyPatterns(theme: theme),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = (constraints.maxWidth / 190).floor().clamp(
                    1,
                    4,
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: cutList.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 196,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final item = cutList.items[index];
                      return FlatPatternCard(
                        item: item,
                        catalog: catalog,
                        onTap: onOpen == null ? null : () => onOpen!(item),
                      );
                    },
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class FlatPatternCard extends StatefulWidget {
  final CutListItem item;
  final MaterialCatalog catalog;
  final VoidCallback? onTap;

  const FlatPatternCard({
    super.key,
    required this.item,
    required this.catalog,
    this.onTap,
  });

  @override
  State<FlatPatternCard> createState() => _FlatPatternCardState();
}

class _FlatPatternCardState extends State<FlatPatternCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = widget.item;
    final material = widget.catalog.byId(item.materialId);
    final subtitle = material == null
        ? 'e ${formatMm(item.cutSize.thickness)} mm'
        : '${material.name} · e ${formatMm(item.cutSize.thickness)} mm';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: AppTheme.shadow.withValues(alpha: 0.9),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            hoverColor: scheme.primary.withValues(alpha: 0.04),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: _hovered
                      ? scheme.primary.withValues(alpha: 0.35)
                      : scheme.outlineVariant.withValues(alpha: 0.85),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        partIcon(item.kind),
                        size: 15,
                        color: _hovered
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.quantity > 1)
                        Text(
                          '×${item.quantity}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (widget.onTap != null)
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: CustomPaint(
                      painter: FlatPatternPainter(
                        cutSize: item.cutSize,
                        grain: item.grain,
                        bandedEdges: item.bandedEdges,
                        panelColor: partColor(item.kind),
                        shape: item.shape,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatMm(item.cutSize.length)} × ${formatMm(item.cutSize.width)} mm',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      if (item.bandedEdgeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${item.bandedEdgeCount} canto${item.bandedEdgeCount == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPatterns extends StatelessWidget {
  final ThemeData theme;

  const _EmptyPatterns({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Todavía no hay piezas.',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Agrega o ajusta una pieza para ver su plantilla de corte.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
