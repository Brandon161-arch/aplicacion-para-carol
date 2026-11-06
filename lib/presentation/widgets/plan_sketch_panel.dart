import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;

import '../../domain/entities/material.dart';
import '../../domain/entities/part.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/part_shape.dart';
import '../../domain/value_objects/size3.dart';
import '../../domain/value_objects/vector3.dart';
import 'surface_card.dart';

/// Dibujo de planta con el mouse, estilo PowerPoint.
///
/// Cada rectángulo dibujado se convierte en un panel físico rectangular. La
/// herramienta sirve para componer formas L, U o escalonadas dibujando varios
/// rectángulos; las curvas todavía no son construibles con este modelo.
class PlanSketchPanel extends StatefulWidget {
  final Size3 overallSize;
  final double thickness;
  final String materialId;
  final MaterialCatalog catalog;
  final ValueChanged<List<Part>> onPartsCreated;
  final ValueChanged<bool>? onDrawingChanged;

  const PlanSketchPanel({
    super.key,
    required this.overallSize,
    required this.thickness,
    required this.materialId,
    required this.catalog,
    required this.onPartsCreated,
    this.onDrawingChanged,
  });

  @override
  State<PlanSketchPanel> createState() => _PlanSketchPanelState();
}

class _PlanSketchPanelState extends State<PlanSketchPanel> {
  final List<_SketchRect> _rects = [];
  _SketchRect? _preview;
  Offset? _dragStart;
  PartShapeKind _tool = PartShapeKind.rectangle;

  PartShape get _toolShape =>
      PartShape(kind: _tool, cornerRadiusMm: 80, sides: 6);

  double _snap(double value) => (value / 10).round() * 10.0;

  _SketchRect? _rectFromPoints(Offset start, Offset end) {
    final left = math.min(start.dx, end.dx);
    final top = math.min(start.dy, end.dy);
    final right = math.max(start.dx, end.dx);
    final bottom = math.max(start.dy, end.dy);
    final width = _snap(right - left);
    final depth = _snap(bottom - top);
    if (width < 50 || depth < 50) return null;
    return _SketchRect(
      x: _snap(left),
      z: _snap(top),
      width: math.min(width, widget.overallSize.width),
      depth: math.min(depth, widget.overallSize.depth),
      shape: _toolShape,
    );
  }

  _SketchRect? _clampedRect(_SketchRect rect) {
    final maxX = math.max(0.0, widget.overallSize.width - 50);
    final maxZ = math.max(0.0, widget.overallSize.depth - 50);
    final x = rect.x.clamp(0.0, maxX).toDouble();
    final z = rect.z.clamp(0.0, maxZ).toDouble();
    final width = rect.width
        .clamp(50.0, widget.overallSize.width - x)
        .toDouble();
    final depth = rect.depth
        .clamp(50.0, widget.overallSize.depth - z)
        .toDouble();
    return _SketchRect(
      x: x,
      z: z,
      width: width,
      depth: depth,
      shape: rect.shape,
    );
  }

  Offset _toModel(Offset local, Size size) {
    final scale = math.min(
      size.width / widget.overallSize.width,
      size.height / widget.overallSize.depth,
    );
    final origin = Offset(
      (size.width - widget.overallSize.width * scale) / 2,
      (size.height - widget.overallSize.depth * scale) / 2,
    );
    return Offset(
      ((local.dx - origin.dx) / scale).clamp(0.0, widget.overallSize.width),
      ((local.dy - origin.dy) / scale).clamp(0.0, widget.overallSize.depth),
    );
  }

  void _createParts() {
    if (_rects.isEmpty) return;
    final material = widget.catalog.byId(widget.materialId);
    final thickness = widget.thickness;
    var counter = 0;
    final parts = <Part>[
      for (final rect in _rects)
        Part(
          id: 'sketch_${DateTime.now().microsecondsSinceEpoch}_${counter++}',
          name: 'Panel dibujado $counter',
          kind: PartKind.shelf,
          size: Size3(width: rect.width, height: thickness, depth: rect.depth),
          cutSize: CutSize(
            length: rect.width,
            width: rect.depth,
            thickness: thickness,
          ),
          materialId: material?.id ?? widget.materialId,
          position: Vector3(rect.x, 0, rect.z),
          grain: (material?.hasGrain ?? false)
              ? GrainDirection.alongLength
              : GrainDirection.none,
          shape: rect.shape,
        ),
    ];
    widget.onPartsCreated(parts);
    setState(() => _rects.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dibujar planta',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${_rects.length} forma(s)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Arrastra el mouse sobre la cuadrícula para crear paneles. Se ajustan a 10 mm.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final kind in const [
                PartShapeKind.rectangle,
                PartShapeKind.circle,
                PartShapeKind.ellipse,
                PartShapeKind.roundedRectangle,
                PartShapeKind.polygon,
              ])
                ChoiceChip(
                  label: Text(_toolLabel(kind)),
                  selected: _tool == kind,
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _tool = kind),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 240);
                return Listener(
                  key: const Key('plan_sketch_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    widget.onDrawingChanged?.call(true);
                    final point = _toModel(event.localPosition, size);
                    _dragStart = point;
                    setState(
                      () => _preview = _SketchRect(
                        x: point.dx,
                        z: point.dy,
                        width: 0,
                        depth: 0,
                        shape: _toolShape,
                      ),
                    );
                  },
                  onPointerMove: (event) {
                    final start = _dragStart;
                    if (start == null) return;
                    final point = _toModel(event.localPosition, size);
                    setState(() {
                      _preview = _rectFromPoints(start, point);
                    });
                  },
                  onPointerUp: (_) {
                    final preview = _preview;
                    if (preview != null && preview.width >= 50) {
                      setState(() => _rects.add(_clampedRect(preview)!));
                    }
                    _dragStart = null;
                    setState(() => _preview = null);
                    widget.onDrawingChanged?.call(false);
                  },
                  onPointerCancel: (_) {
                    _dragStart = null;
                    setState(() => _preview = null);
                    widget.onDrawingChanged?.call(false);
                  },
                  child: CustomPaint(
                    painter: _PlanSketchPainter(
                      overallSize: widget.overallSize,
                      rects: _rects,
                      preview: _preview,
                      fillColor: _materialColor(
                        widget.catalog.byId(widget.materialId),
                      ),
                      gridColor: scheme.outlineVariant.withValues(alpha: 0.5),
                      borderColor: scheme.primary,
                      labelColor: scheme.onSurfaceVariant,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('sketch_create_parts'),
                onPressed: _rects.isEmpty ? null : _createParts,
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: Text('Crear ${_rects.length} pieza(s)'),
              ),
              OutlinedButton.icon(
                onPressed: _rects.isEmpty
                    ? null
                    : () => setState(() => _rects.removeLast()),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Borrar último'),
              ),
              OutlinedButton.icon(
                onPressed: _rects.isEmpty
                    ? null
                    : () => setState(() => _rects.clear()),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las piezas se crean al piso (Y = 0). Luego puedes subirlas, apilarlas o editar su material en el visor 3D.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _toolLabel(PartShapeKind kind) => switch (kind) {
    PartShapeKind.rectangle => 'Rect�ngulo',
    PartShapeKind.circle => 'C�rculo',
    PartShapeKind.ellipse => 'Elipse',
    PartShapeKind.roundedRectangle => 'Redondeado',
    PartShapeKind.polygon => 'Hex�gono',
  };

  Color _materialColor(Material? material) {
    final value = material?.colorValue;
    return value == null ? const Color(0xFFD8A56F) : Color(value);
  }
}

class _SketchRect {
  final double x;
  final double z;
  final double width;
  final double depth;
  final PartShape shape;

  const _SketchRect({
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
    required this.shape,
  });
}

class _PlanSketchPainter extends CustomPainter {
  final Size3 overallSize;
  final List<_SketchRect> rects;
  final _SketchRect? preview;
  final Color fillColor;
  final Color gridColor;
  final Color borderColor;
  final Color labelColor;

  const _PlanSketchPainter({
    required this.overallSize,
    required this.rects,
    required this.preview,
    required this.fillColor,
    required this.gridColor,
    required this.borderColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / overallSize.width,
      size.height / overallSize.depth,
    );
    final origin = Offset(
      (size.width - overallSize.width * scale) / 2,
      (size.height - overallSize.depth * scale) / 2,
    );
    final board = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      overallSize.width * scale,
      overallSize.depth * scale,
    );
    canvas.drawRect(board, Paint()..color = const Color(0xFFF7F3EC));
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.6;
    for (var x = 0.0; x <= overallSize.width; x += 100) {
      final dx = board.left + x * scale;
      canvas.drawLine(Offset(dx, board.top), Offset(dx, board.bottom), grid);
    }
    for (var z = 0.0; z <= overallSize.depth; z += 100) {
      final dz = board.top + z * scale;
      canvas.drawLine(Offset(board.left, dz), Offset(board.right, dz), grid);
    }
    canvas.drawRect(
      board,
      Paint()
        ..color = borderColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    void drawRect(_SketchRect rect, {required bool isPreview}) {
      final r = Rect.fromLTWH(
        board.left + rect.x * scale,
        board.top + rect.z * scale,
        rect.width * scale,
        rect.depth * scale,
      );
      final points = rect.shape.outlineFor(r.width, r.height);
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = Offset(r.left + points[index].x, r.top + points[index].y);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = fillColor.withValues(alpha: isPreview ? 0.35 : 0.9),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = isPreview ? borderColor : const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isPreview ? 1.8 : 1,
      );
      if (r.width > 46 && r.height > 18) {
        final text = TextPainter(
          text: TextSpan(
            text: '${rect.width.round()}×${rect.depth.round()}',
            style: TextStyle(fontSize: 9, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: r.width - 4);
        text.paint(canvas, r.topLeft + const Offset(3, 3));
      }
    }

    for (final rect in rects) {
      if (rect.width > 0) drawRect(rect, isPreview: false);
    }
    final current = preview;
    if (current != null && current.width > 0) {
      drawRect(current, isPreview: true);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanSketchPainter oldDelegate) =>
      oldDelegate.rects != rects ||
      oldDelegate.preview != preview ||
      oldDelegate.overallSize != overallSize ||
      oldDelegate.fillColor != fillColor;
}
