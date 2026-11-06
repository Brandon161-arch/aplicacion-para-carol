import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/part.dart';
import '../../domain/value_objects/cut_size.dart';
import '../../domain/value_objects/part_shape.dart';

class FlatPatternMetrics {
  final Rect panelRect;
  final double scale;

  const FlatPatternMetrics({required this.panelRect, required this.scale});
}

/// Comparte la misma escala y posición entre el painter y el editor con mouse.
FlatPatternMetrics calculateFlatPatternMetrics(
  Size size,
  CutSize cutSize, {
  required bool showDimensions,
}) {
  final leftSpace = showDimensions ? 44.0 : 8.0;
  final rightSpace = showDimensions ? 12.0 : 8.0;
  final topSpace = showDimensions ? 22.0 : 8.0;
  final bottomSpace = showDimensions ? 34.0 : 8.0;
  final availableWidth = math.max(10.0, size.width - leftSpace - rightSpace);
  final availableHeight = math.max(10.0, size.height - topSpace - bottomSpace);
  final scale = math.min(
    availableWidth / math.max(1.0, cutSize.length),
    availableHeight / math.max(1.0, cutSize.width),
  );
  final panelWidth = cutSize.length * scale;
  final panelHeight = cutSize.width * scale;
  return FlatPatternMetrics(
    panelRect: Rect.fromLTWH(
      leftSpace + (availableWidth - panelWidth) / 2,
      topSpace + (availableHeight - panelHeight) / 2,
      panelWidth,
      panelHeight,
    ),
    scale: scale,
  );
}

/// Dibuja una pieza plana con sus cotas reales de corte.
///
/// Convención de cantos en el dibujo:
/// - longEdge1: borde superior
/// - longEdge2: borde inferior
/// - shortEdge1: borde izquierdo
/// - shortEdge2: borde derecho
class FlatPatternPainter extends CustomPainter {
  final CutSize cutSize;
  final GrainDirection grain;
  final Set<PanelEdge> bandedEdges;
  final Color panelColor;
  final Color inkColor;
  final Color bandingColor;
  final bool showDimensions;
  final bool showResizeHandle;
  final PartShape shape;

  const FlatPatternPainter({
    required this.cutSize,
    required this.grain,
    required this.bandedEdges,
    required this.panelColor,
    this.inkColor = const Color(0xFF3E332B),
    this.bandingColor = const Color(0xFFB26A00),
    this.showDimensions = true,
    this.showResizeHandle = false,
    this.shape = PartShape.rectangle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 20 || size.height < 20) return;

    final rect = calculateFlatPatternMetrics(
      size,
      cutSize,
      showDimensions: showDimensions,
    ).panelRect;

    final fillColor =
        Color.lerp(panelColor, Colors.white, 0.72) ??
        panelColor.withValues(alpha: 0.2);
    final panelPaint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final panelPath = _shapePath(rect);
    canvas.drawPath(panelPath, panelPaint);
    canvas.drawPath(panelPath, borderPaint);

    _drawGrain(canvas, rect, panelPath);
    _drawBandedEdges(canvas, rect);

    if (showDimensions) {
      _drawHorizontalDimension(canvas, rect);
      _drawVerticalDimension(canvas, rect);
      _drawText(
        canvas,
        'e = ${formatMm(cutSize.thickness)} mm',
        Offset(rect.left, rect.top - 9),
        color: inkColor.withValues(alpha: 0.8),
        fontSize: 9.5,
        bold: true,
        align: TextAlign.left,
      );
    }

    if (showResizeHandle) _drawResizeHandle(canvas, rect);
  }

  Path _shapePath(Rect rect) {
    final points = shape.outlineFor(rect.width, rect.height);
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(
        rect.left + points[index].x,
        rect.top + points[index].y,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawGrain(Canvas canvas, Rect rect, Path panelPath) {
    if (grain == GrainDirection.none) return;

    final isAlongLength = grain == GrainDirection.alongLength;
    final paint = Paint()
      ..color = inkColor.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    canvas.save();
    canvas.clipPath(panelPath);
    if (isAlongLength) {
      for (var y = rect.top + 10; y < rect.bottom; y += 18) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      }
    } else {
      for (var x = rect.left + 10; x < rect.right; x += 18) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
      }
    }
    canvas.restore();

    final arrowPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = rect.center;
    final half = math.min(rect.width, rect.height) * 0.30;
    final start = isAlongLength
        ? Offset(center.dx - half, center.dy)
        : Offset(center.dx, center.dy + half);
    final end = isAlongLength
        ? Offset(center.dx + half, center.dy)
        : Offset(center.dx, center.dy - half);

    canvas.drawLine(start, end, arrowPaint);
    _arrowHead(
      canvas,
      end,
      isAlongLength ? 1 : -1,
      arrowPaint.color,
      vertical: !isAlongLength,
    );
    _drawText(
      canvas,
      'VETA',
      isAlongLength
          ? Offset(center.dx, center.dy - 12)
          : Offset(center.dx + 14, center.dy),
      color: inkColor.withValues(alpha: 0.5),
      fontSize: 8,
      bold: true,
    );
  }

  void _drawBandedEdges(Canvas canvas, Rect rect) {
    if (!shape.isRectangular) {
      if (bandedEdges.isEmpty) return;
      canvas.drawPath(
        _shapePath(rect),
        Paint()
          ..color = bandingColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
      return;
    }
    final paint = Paint()
      ..color = bandingColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    const offset = 3.5;

    if (bandedEdges.contains(PanelEdge.longEdge1)) {
      canvas.drawLine(
        Offset(rect.left, rect.top - offset),
        Offset(rect.right, rect.top - offset),
        paint,
      );
    }
    if (bandedEdges.contains(PanelEdge.longEdge2)) {
      canvas.drawLine(
        Offset(rect.left, rect.bottom + offset),
        Offset(rect.right, rect.bottom + offset),
        paint,
      );
    }
    if (bandedEdges.contains(PanelEdge.shortEdge1)) {
      canvas.drawLine(
        Offset(rect.left - offset, rect.top),
        Offset(rect.left - offset, rect.bottom),
        paint,
      );
    }
    if (bandedEdges.contains(PanelEdge.shortEdge2)) {
      canvas.drawLine(
        Offset(rect.right + offset, rect.top),
        Offset(rect.right + offset, rect.bottom),
        paint,
      );
    }
  }

  void _drawResizeHandle(Canvas canvas, Rect rect) {
    final center = rect.bottomRight;
    canvas.drawCircle(center, 7, Paint()..color = bandingColor);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final mark = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2;
    canvas.drawLine(
      center + const Offset(-3, 3),
      center + const Offset(3, -3),
      mark,
    );
    canvas.drawLine(
      center + const Offset(0, 4),
      center + const Offset(4, 0),
      mark,
    );
  }

  void _drawHorizontalDimension(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = inkColor.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    final y = rect.bottom + 20;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    canvas.drawLine(
      Offset(rect.left, rect.bottom + 4),
      Offset(rect.left, y + 4),
      paint..color = inkColor.withValues(alpha: 0.24),
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom + 4),
      Offset(rect.right, y + 4),
      paint,
    );
    _arrowHead(canvas, Offset(rect.left, y), 1, paint.color);
    _arrowHead(canvas, Offset(rect.right, y), -1, paint.color);
    _drawText(
      canvas,
      '${formatMm(cutSize.length)} mm',
      Offset(rect.center.dx, y + 15),
      color: inkColor.withValues(alpha: 0.85),
      fontSize: 10,
      bold: true,
    );
  }

  void _drawVerticalDimension(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = inkColor.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    final x = rect.left - 22;
    canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    canvas.drawLine(
      Offset(rect.left - 4, rect.top),
      Offset(x - 4, rect.top),
      paint..color = inkColor.withValues(alpha: 0.24),
    );
    canvas.drawLine(
      Offset(rect.left - 4, rect.bottom),
      Offset(x - 4, rect.bottom),
      paint,
    );
    _arrowHead(canvas, Offset(x, rect.top), 1, paint.color, vertical: true);
    _arrowHead(canvas, Offset(x, rect.bottom), -1, paint.color, vertical: true);

    canvas.save();
    canvas.translate(rect.left - 34, rect.center.dy);
    canvas.rotate(-math.pi / 2);
    _drawText(
      canvas,
      '${formatMm(cutSize.width)} mm',
      Offset.zero,
      color: inkColor.withValues(alpha: 0.85),
      fontSize: 10,
      bold: true,
    );
    canvas.restore();
  }

  void _arrowHead(
    Canvas canvas,
    Offset tip,
    int direction,
    Color color, {
    bool vertical = false,
  }) {
    final path = Path();
    const size = 4.5;
    if (!vertical) {
      path
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + size * direction, tip.dy - size)
        ..lineTo(tip.dx + size * direction, tip.dy + size)
        ..close();
    } else {
      path
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - size, tip.dy + size * direction)
        ..lineTo(tip.dx + size, tip.dy + size * direction)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    required Color color,
    double fontSize = 10,
    bool bold = false,
    TextAlign align = TextAlign.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.left
        ? position.dx
        : position.dx - painter.width / 2;
    painter.paint(canvas, Offset(dx, position.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant FlatPatternPainter oldDelegate) =>
      oldDelegate.cutSize != cutSize ||
      oldDelegate.grain != grain ||
      !setEquals(oldDelegate.bandedEdges, bandedEdges) ||
      oldDelegate.panelColor != panelColor ||
      oldDelegate.inkColor != inkColor ||
      oldDelegate.bandingColor != bandingColor ||
      oldDelegate.showDimensions != showDimensions ||
      oldDelegate.showResizeHandle != showResizeHandle ||
      oldDelegate.shape != shape;
}
