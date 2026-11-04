import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/furniture.dart';
import '../../domain/services/rendering/orbit_camera.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/scene_painter.dart';

/// Miniatura 3D estática para las tarjetas de la galería.
class MiniFurniturePreview extends StatelessWidget {
  final Furniture furniture;

  const MiniFurniturePreview({super.key, required this.furniture});

  @override
  Widget build(BuildContext context) {
    final size = furniture.overallSize;
    final camera = OrbitCamera(
      yaw: 0.68,
      pitch: 0.30,
      distance: math.max(320.0, size.maxDimension * 1.95),
      target: Vector3(size.width / 2, size.height / 2, size.depth / 2),
    );

    if (furniture.parts.isEmpty) {
      return Container(
        color: const Color(0xFF1E2832),
        alignment: Alignment.center,
        child: Icon(
          Icons.view_in_ar_outlined,
          color: Colors.white.withValues(alpha: 0.35),
          size: 34,
        ),
      );
    }

    return ClipRect(
      child: CustomPaint(
        painter: ScenePainter(furniture: furniture, camera: camera),
        child: const SizedBox.expand(),
      ),
    );
  }
}
