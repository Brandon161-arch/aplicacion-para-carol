import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/part.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/part_shape.dart';
import '../painters/flat_pattern_painter.dart';

/// Plantilla que permite cambiar largo y ancho arrastrando el tirador naranja.
class InteractiveFlatPattern extends StatefulWidget {
  final CutSize cutSize;
  final GrainDirection grain;
  final Set<PanelEdge> bandedEdges;
  final Color panelColor;
  final ValueChanged<CutSize> onChanged;
  final PartShape shape;

  const InteractiveFlatPattern({
    super.key,
    required this.cutSize,
    required this.grain,
    required this.bandedEdges,
    required this.panelColor,
    required this.onChanged,
    this.shape = PartShape.rectangle,
  });

  @override
  State<InteractiveFlatPattern> createState() => _InteractiveFlatPatternState();
}

class _InteractiveFlatPatternState extends State<InteractiveFlatPattern> {
  bool _dragging = false;
  CutSize? _startCutSize;
  Offset _startGlobalPosition = Offset.zero;
  double _startScale = 1;

  void _applyResize(Offset globalPosition) {
    final start = _startCutSize;
    if (!_dragging || start == null) return;
    final delta = globalPosition - _startGlobalPosition;
    final length = math.max(20.0, start.length + delta.dx / _startScale);
    final width = math.max(20.0, start.width - delta.dy / _startScale);
    widget.onChanged(
      CutSize(length: length, width: width, thickness: start.thickness),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final metrics = calculateFlatPatternMetrics(
          size,
          widget.cutSize,
          showDimensions: true,
        );
        const handleSize = 24.0;
        final handleCenter = metrics.panelRect.bottomRight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: FlatPatternPainter(
                cutSize: widget.cutSize,
                grain: widget.grain,
                bandedEdges: widget.bandedEdges,
                panelColor: widget.panelColor,
                showResizeHandle: true,
                shape: widget.shape,
              ),
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: handleCenter.dx - handleSize / 2,
              top: handleCenter.dy - handleSize / 2,
              width: handleSize,
              height: handleSize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: Listener(
                  onPointerDown: (event) =>
                      _startGlobalPosition = event.position,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      _startCutSize = widget.cutSize;
                      _startScale = math.max(0.0001, metrics.scale);
                      setState(() => _dragging = true);
                      _applyResize(details.globalPosition);
                    },
                    onPanUpdate: (details) =>
                        _applyResize(details.globalPosition),
                    onPanEnd: (_) => setState(() => _dragging = false),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.01),
                        shape: BoxShape.circle,
                        border: _dragging
                            ? Border.all(
                                color: const Color(0xFFB26A00),
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
