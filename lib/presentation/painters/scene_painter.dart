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

  const ScenePainter({required this.furniture, required this.camera});

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

    for (final face in projection.faces) {
      if (face.points.length < 3) continue;
      final path = Path()..moveTo(face.points.first.x, face.points.first.y);
      for (final point in face.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();

      fillPaint.color = _shade(partColor(face.kind), face.shade);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
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
      !identical(oldDelegate.furniture, furniture);
}
