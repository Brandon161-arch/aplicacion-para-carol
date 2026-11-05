import 'package:flutter/material.dart';

import '../../domain/entities/furniture.dart';
import '../../domain/services/rendering/orbit_camera.dart';
import '../../domain/services/rendering/scene_projector.dart';
import '../../domain/value_objects/vector3.dart';
import 'part_palette.dart';

/// Dibuja el mueble con proyección perspectiva y algoritmo del pintor.
class ScenePainter extends CustomPainter {
  final Furniture furniture;
  final OrbitCamera camera;
  final String? selectedPartId;
  final bool showBounds;

  const ScenePainter({
    required this.furniture,
    required this.camera,
    this.selectedPartId,
    this.showBounds = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final backgroundRect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E2832), Color(0xFF101519)],
      ).createShader(backgroundRect);
    canvas.drawRect(backgroundRect, background);

    _drawFloorGrid(canvas, size);

    final projection = const SceneProjector().project(
      furniture: furniture,
      camera: camera,
      viewportWidth: size.width,
      viewportHeight: size.height,
    );

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x33000000);
    final selectedStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFFFFB74D);

    for (final face in projection.faces) {
      if (face.points.length < 3) continue;
      final path = Path()..moveTo(face.points.first.x, face.points.first.y);
      for (final point in face.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();

      fillPaint.color = _shade(partColor(face.kind), face.shade);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(
        path,
        face.partId == selectedPartId ? selectedStroke : strokePaint,
      );
    }
    if (showBounds) _drawOverallBounds(canvas, size);
  }

  void _drawOverallBounds(Canvas canvas, Size size) {
    final width = furniture.overallSize.width;
    final height = furniture.overallSize.height;
    final depth = furniture.overallSize.depth;
    const projector = SceneProjector();

    final corners = <Vector3>[
      const Vector3(0, 0, 0),
      Vector3(width, 0, 0),
      Vector3(width, height, 0),
      Vector3(0, height, 0),
      Vector3(0, 0, depth),
      Vector3(width, 0, depth),
      Vector3(width, height, depth),
      Vector3(0, height, depth),
    ];
    final projected = [
      for (final corner in corners)
        projector.projectPoint(
          point: corner,
          camera: camera,
          viewportWidth: size.width,
          viewportHeight: size.height,
        ),
    ];

    final linePaint = Paint()
      ..color = const Color(0x77FFFFFF)
      ..strokeWidth = 1.2;
    final floorPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = 1.6;

    void drawEdge(int a, int b, Paint paint) {
      final start = projected[a];
      final end = projected[b];
      if (start == null || end == null) return;
      canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);
    }

    const edges = [
      (0, 1),
      (1, 2),
      (2, 3),
      (3, 0),
      (4, 5),
      (5, 6),
      (6, 7),
      (7, 4),
      (0, 4),
      (1, 5),
      (2, 6),
      (3, 7),
    ];
    for (final edge in edges) {
      drawEdge(edge.$1, edge.$2, linePaint);
    }
    for (final edge in const [(0, 1), (1, 5), (5, 4), (4, 0)]) {
      drawEdge(edge.$1, edge.$2, floorPaint);
    }
  }

  void _drawFloorGrid(Canvas canvas, Size size) {
    const margin = 400.0;
    const step = 200.0;
    final width = furniture.overallSize.width;
    final depth = furniture.overallSize.depth;
    final paint = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 1;
    const projector = SceneProjector();

    void drawSegment(Vector3 from, Vector3 to) {
      final start = projector.projectPoint(
        point: from,
        camera: camera,
        viewportWidth: size.width,
        viewportHeight: size.height,
      );
      final end = projector.projectPoint(
        point: to,
        camera: camera,
        viewportWidth: size.width,
        viewportHeight: size.height,
      );
      if (start == null || end == null) return;
      canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);
    }

    var z = -margin;
    while (z <= depth + margin) {
      drawSegment(Vector3(-margin, 0, z), Vector3(width + margin, 0, z));
      z += step;
    }

    var x = -margin;
    while (x <= width + margin) {
      drawSegment(Vector3(x, 0, -margin), Vector3(x, 0, depth + margin));
      x += step;
    }
  }

  Color _shade(Color base, double shade) {
    final hsl = HSLColor.fromColor(base);
    final lightness = (hsl.lightness * (0.48 + 0.72 * shade))
        .clamp(0.06, 0.92)
        .toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.selectedPartId != selectedPartId ||
      oldDelegate.showBounds != showBounds ||
      !identical(oldDelegate.furniture, furniture);
}
