import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;

import '../../domain/entities/material.dart';

/// Muestra pequeña con veta, nudos y brillo para reconocer la madera.
class WoodSwatchPainter extends CustomPainter {
  final Material material;

  const WoodSwatchPainter({required this.material});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(math.min(size.width, size.height) * 0.22);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final base = material.colorValue == null
        ? const Color(0xFFD8A56F)
        : Color(material.colorValue!);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = base);

    final seed = material.id.hashCode & 0x7fffffff;
    final isWood = material.category == MaterialCategory.solidWood;
    final isPlywood = material.category == MaterialCategory.plywood;

    if (isWood || isPlywood) {
      final dark = Color.lerp(base, const Color(0xFF3B2416), 0.34)!;
      final light = Color.lerp(base, Colors.white, 0.35)!;
      final lines = math.max(4, (size.height / 4).round());
      final random = math.Random(seed);
      for (var index = 0; index < lines; index++) {
        final y = size.height * (index + 0.5) / lines;
        final paint = Paint()
          ..color = (index.isEven ? dark : light).withValues(alpha: 0.20)
          ..strokeWidth = 0.7 + random.nextDouble() * 0.7
          ..style = PaintingStyle.stroke;
        final path = Path();
        const steps = 6;
        for (var step = 0; step <= steps; step++) {
          final x = size.width * step / steps;
          final wobble = math.sin(step * 1.4 + index) * 1.2;
          if (step == 0) {
            path.moveTo(x, y + wobble);
          } else {
            path.lineTo(x, y + wobble);
          }
        }
        canvas.drawPath(path, paint);
      }
      if (isWood) {
        final knot = Offset(
          size.width * (0.25 + random.nextDouble() * 0.5),
          size.height * (0.3 + random.nextDouble() * 0.4),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: knot,
            width: size.width * 0.22,
            height: size.height * 0.10,
          ),
          Paint()
            ..color = dark.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    } else if (material.category == MaterialCategory.particleboard ||
        material.category == MaterialCategory.mdf) {
      final random = math.Random(seed);
      final speck = Paint()
        ..color = const Color(0xFF5F4C3A).withValues(alpha: 0.18);
      for (var index = 0; index < 22; index++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          random.nextDouble() * 0.6 + 0.2,
          speck,
        );
      }
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant WoodSwatchPainter oldDelegate) =>
      oldDelegate.material.id != material.id ||
      oldDelegate.material.colorValue != material.colorValue;
}
