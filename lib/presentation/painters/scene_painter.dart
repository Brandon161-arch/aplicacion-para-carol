import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/furniture.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/hardware_marker_builder.dart';
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
  final double explodeFactor;
  final double doorOpenProgress;
  final double drawerOpenProgress;
  final bool showHardware;
  final Part? previewPart;

  const ScenePainter({
    required this.furniture,
    required this.camera,
    this.selectedPartId,
    this.showBounds = true,
    this.explodeFactor = 0.0,
    this.doorOpenProgress = 0.0,
    this.drawerOpenProgress = 0.0,
    this.showHardware = false,
    this.previewPart,
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
      explodeFactor: explodeFactor,
      doorOpenProgress: doorOpenProgress,
      drawerOpenProgress: drawerOpenProgress,
    );

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

      _paintFace(canvas, path, face);
      canvas.drawPath(
        path,
        face.partId == selectedPartId ? selectedStroke : strokePaint,
      );
    }
    if (showBounds) _drawOverallBounds(canvas, size);
    if (previewPart != null) _drawPreview(canvas, size, previewPart!);
    if (showHardware) _drawHardwareMarkers(canvas, size);
  }

  void _drawPreview(Canvas canvas, Size size, Part part) {
    final previewFurniture = Furniture(
      id: 'preview',
      name: 'preview',
      type: furniture.type,
      overallSize: furniture.overallSize,
      settings: furniture.settings,
      parts: [part],
    );
    final projection = const SceneProjector().project(
      furniture: previewFurniture,
      camera: camera,
      viewportWidth: size.width,
      viewportHeight: size.height,
    );
    final fill = Paint()
      ..color = const Color(0x55FFB74D)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final face in projection.faces) {
      if (face.points.length < 3) continue;
      final path = Path()..moveTo(face.points.first.x, face.points.first.y);
      for (final point in face.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  void _paintFace(Canvas canvas, Path path, ProjectedFace face) {
    final base = materialColorFor(face.materialId, face.kind);
    final shaded = _shade(base, face.shade);
    canvas.drawPath(path, Paint()..color = shaded);

    final family = _woodFamily(face.materialId);
    final bounds = path.getBounds();
    if (family != _SurfaceFamily.smooth &&
        bounds.width > 2 &&
        bounds.height > 2) {
      canvas.save();
      canvas.clipPath(path);
      if (family == _SurfaceFamily.wood) {
        _paintWoodGrain(canvas, bounds, base, face.shade, face.materialId);
      } else if (family == _SurfaceFamily.melamine) {
        _paintMelamineSpeckles(canvas, bounds, face.materialId);
      } else if (family == _SurfaceFamily.plywood) {
        _paintPlywoodLayers(canvas, bounds, base);
      }
      // Brillo diagonal suave para dar volumen a la cara.
      final sheen = Rect.fromLTWH(
        bounds.left,
        bounds.top,
        bounds.width,
        bounds.height * 0.55,
      );
      canvas.drawRect(
        sheen,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.10 * face.shade),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(bounds),
      );
      canvas.restore();
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x33000000),
    );
  }

  void _paintWoodGrain(
    Canvas canvas,
    Rect bounds,
    Color base,
    double shade,
    String materialId,
  ) {
    final seed = materialId.hashCode & 0x7fffffff;
    final alongWidth = bounds.width >= bounds.height;
    final lines = math.max(
      4,
      (math.min(bounds.width, bounds.height) / 6).round(),
    );
    final spacing = (alongWidth ? bounds.height : bounds.width) / (lines + 1);
    for (var index = 0; index < lines; index++) {
      final offset = spacing * (index + 1);
      final variation = ((seed >> (index % 12)) & 0xFF) / 255.0;
      final dark =
          Color.lerp(base, const Color(0xFF3E2415), 0.28) ??
          const Color(0xFF3E2415);
      final light = Color.lerp(base, Colors.white, 0.35) ?? Colors.white;
      final paint = Paint()
        ..color = (index.isEven ? dark : light).withValues(
          alpha: 0.10 + variation * 0.10,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7 + variation * 1.1;
      final path = Path();
      const steps = 10;
      for (var step = 0; step <= steps; step++) {
        final t = step / steps;
        final wobble =
            math.sin(t * math.pi * (2 + variation * 2) + index) *
            spacing *
            0.45;
        final point = alongWidth
            ? Offset(
                bounds.left + bounds.width * t,
                bounds.top + offset + wobble,
              )
            : Offset(
                bounds.left + offset + wobble,
                bounds.top + bounds.height * t,
              );
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Nudos pequeños y ocasionales.
    final knotPaint = Paint()
      ..color = const Color(0xFF4A2C18).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var index = 0; index < 2; index++) {
      final rx =
          bounds.left +
          bounds.width * (0.2 + 0.55 * ((seed >> (index * 3)) & 0x07) / 7);
      final ry =
          bounds.top +
          bounds.height * (0.25 + 0.5 * ((seed >> (index * 5)) & 0x07) / 7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: 9, height: 4),
        knotPaint,
      );
    }
  }

  void _paintPlywoodLayers(Canvas canvas, Rect bounds, Color base) {
    final paint = Paint()
      ..color = const Color(0xFF5A3A22).withValues(alpha: 0.12)
      ..strokeWidth = 0.8;
    for (var y = bounds.top + 3; y < bounds.bottom; y += 5) {
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
    }
  }

  void _paintMelamineSpeckles(Canvas canvas, Rect bounds, String materialId) {
    final paint = Paint()
      ..color = const Color(0xFF6B5A48).withValues(alpha: 0.10);
    final random = math.Random(
      bounds.width.round() * 31 + bounds.height.round(),
    );
    for (var index = 0; index < 70; index++) {
      canvas.drawCircle(
        Offset(
          bounds.left + random.nextDouble() * bounds.width,
          bounds.top + random.nextDouble() * bounds.height,
        ),
        random.nextDouble() * 0.7 + 0.2,
        paint,
      );
    }
  }

  _SurfaceFamily _woodFamily(String materialId) => switch (materialId) {
    'pine_18' ||
    'oak_18' ||
    'teak_18' ||
    'cedar_18' ||
    'walnut_18' ||
    'solid_wood_60' => _SurfaceFamily.wood,
    'plywood_18' => _SurfaceFamily.plywood,
    'particleboard_18' ||
    'mdf_15' ||
    'mdf_18' ||
    'mdf_25' ||
    'mdf_rh_18' => _SurfaceFamily.melamine,
    _ => _SurfaceFamily.smooth,
  };

  void _drawHardwareMarkers(Canvas canvas, Size size) {
    final markers = const HardwareMarkerBuilder().build(furniture);
    if (markers.isEmpty) return;
    const projector = SceneProjector();

    for (final marker in markers) {
      final point = projector.projectPoint(
        point: marker.position,
        camera: camera,
        viewportWidth: size.width,
        viewportHeight: size.height,
      );
      if (point == null) continue;
      final center = Offset(point.x, point.y);
      final scale = (1300 / point.depth).clamp(0.55, 1.65).toDouble();
      switch (marker.kind) {
        case HardwareMarkerKind.screw:
          _drawScrew(canvas, center, scale);
          break;
        case HardwareMarkerKind.hinge:
          _drawHinge(canvas, center, scale);
          break;
        case HardwareMarkerKind.drawerSlide:
          _drawSlide(canvas, center, scale);
          break;
        case HardwareMarkerKind.handle:
          _drawHandle(canvas, center, scale);
          break;
      }
    }
  }

  void _drawScrew(Canvas canvas, Offset center, double scale) {
    final radius = 4.6 * scale;
    // Sombra proyectada.
    canvas.drawCircle(
      center.translate(1.2 * scale, 1.4 * scale),
      radius,
      Paint()..color = const Color(0x55000000),
    );
    final head = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [Color(0xFFF6F7F8), Color(0xFFB7BEC4), Color(0xFF6B747B)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, head);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF2B3237)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    // Ranura en cruz.
    final slot = Paint()
      ..color = const Color(0xFF2D3438)
      ..strokeWidth = 1.35 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-radius * 0.58, 0),
      center.translate(radius * 0.58, 0),
      slot,
    );
    canvas.drawLine(
      center.translate(0, -radius * 0.58),
      center.translate(0, radius * 0.58),
      slot,
    );
    // Reflejo.
    canvas.drawArc(
      Rect.fromCircle(
        center: center.translate(-radius * 0.2, -radius * 0.22),
        radius: radius * 0.55,
      ),
      math.pi * 1.05,
      math.pi * 0.75,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * scale,
    );
  }

  void _drawHinge(Canvas canvas, Offset center, double scale) {
    final plate = Rect.fromCenter(
      center: center,
      width: 19 * scale,
      height: 12 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        plate.translate(0.8, 1.2),
        Radius.circular(3 * scale),
      ),
      Paint()..color = const Color(0x55000000),
    );
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7F3E7), Color(0xFFC9B27A), Color(0xFF8C7436)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(plate);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, Radius.circular(3 * scale)),
      metal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, Radius.circular(3 * scale)),
      Paint()
        ..color = const Color(0xFF4B3A16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    final cup = center.translate(-plate.width * 0.24, 0);
    canvas.drawCircle(
      cup,
      3.5 * scale,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFFFFF), Color(0xFFB8A15F), Color(0xFF695321)],
        ).createShader(Rect.fromCircle(center: cup, radius: 3.5 * scale)),
    );
    canvas.drawCircle(
      cup,
      3.5 * scale,
      Paint()
        ..color = const Color(0xFF3C2F11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    final screwPaint = Paint()..color = const Color(0xFF3A3F43);
    canvas.drawCircle(
      center.translate(plate.width * 0.18, -1.6 * scale),
      1.4 * scale,
      screwPaint,
    );
    canvas.drawCircle(
      center.translate(plate.width * 0.18, 1.6 * scale),
      1.4 * scale,
      screwPaint,
    );
    canvas.drawLine(
      center.translate(-plate.width * 0.06, -1.6 * scale),
      center.translate(plate.width * 0.30, -1.6 * scale),
      Paint()
        ..color = const Color(0xFFFFFDF4)
        ..strokeWidth = 0.7,
    );
  }

  void _drawSlide(Canvas canvas, Offset center, double scale) {
    final rect = Rect.fromCenter(
      center: center,
      width: 21 * scale,
      height: 8 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0.8, 1.2),
        Radius.circular(2 * scale),
      ),
      Paint()..color = const Color(0x55000000),
    );
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEAF0F2), Color(0xFF9AA8AE), Color(0xFF5D696E)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(2 * scale)),
      metal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(2 * scale)),
      Paint()
        ..color = const Color(0xFF30393D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(rect.left + 3 * scale, rect.top + rect.height * 0.35),
      Offset(rect.right - 3 * scale, rect.top + rect.height * 0.35),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = 0.9,
    );
    for (final dx in [-0.28, 0.0, 0.28]) {
      canvas.drawCircle(
        center.translate(rect.width * dx, 0),
        1.4 * scale,
        Paint()..color = const Color(0xFF2F3A3F),
      );
    }
  }

  void _drawHandle(Canvas canvas, Offset center, double scale) {
    final rect = Rect.fromCenter(
      center: center,
      width: 22 * scale,
      height: 6 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0.8, 1.3),
        Radius.circular(3 * scale),
      ),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(3 * scale)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1EEE8), Color(0xFFC2B9AA), Color(0xFF786E5F)],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(rect.left + 3 * scale, rect.top + 1.4 * scale),
      Offset(rect.right - 3 * scale, rect.top + 1.4 * scale),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(3 * scale)),
      Paint()
        ..color = const Color(0xFF3D352B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
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
      oldDelegate.showHardware != showHardware ||
      oldDelegate.previewPart != previewPart ||
      oldDelegate.explodeFactor != explodeFactor ||
      oldDelegate.doorOpenProgress != doorOpenProgress ||
      oldDelegate.drawerOpenProgress != drawerOpenProgress ||
      !identical(oldDelegate.furniture, furniture);
}

enum _SurfaceFamily { wood, plywood, melamine, smooth }
