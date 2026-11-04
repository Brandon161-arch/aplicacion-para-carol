import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/services/rendering/orbit_camera.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/scene_painter.dart';

/// Visor 3D con órbita, zoom con rueda/pinza y doble toque para restablecer.
class Viewer3D extends StatefulWidget {
  final Furniture furniture;

  const Viewer3D({super.key, required this.furniture});

  @override
  State<Viewer3D> createState() => _Viewer3DState();
}

class _Viewer3DState extends State<Viewer3D> {
  static const double _defaultYaw = 0.62;
  static const double _defaultPitch = 0.34;

  late double _yaw;
  late double _pitch;
  late double _distance;
  double _startYaw = 0;
  double _startPitch = 0;
  double _startDistance = 0;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _yaw = _defaultYaw;
    _pitch = _defaultPitch;
    _distance = _fitDistance;
  }

  @override
  void didUpdateWidget(covariant Viewer3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    _distance = _distance.clamp(_minDistance, _maxDistance).toDouble();
  }

  double get _fitDistance =>
      math.max(300.0, widget.furniture.overallSize.maxDimension * 2.0);

  double get _minDistance =>
      math.max(200.0, widget.furniture.overallSize.maxDimension * 0.7);

  double get _maxDistance =>
      math.max(800.0, widget.furniture.overallSize.maxDimension * 8);

  void _resetView() {
    setState(() {
      _yaw = _defaultYaw;
      _pitch = _defaultPitch;
      _distance = _fitDistance;
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final factor = math.exp(event.scrollDelta.dy * 0.0012);
    setState(() {
      _distance = (_distance * factor)
          .clamp(_minDistance, _maxDistance)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.furniture.overallSize;
    final camera = OrbitCamera(
      yaw: _yaw,
      pitch: _pitch,
      distance: _distance,
      target: Vector3(size.width / 2, size.height / 2, size.depth / 2),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Listener(
            onPointerSignal: _handleScroll,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _resetView,
              onScaleStart: (details) {
                _startYaw = _yaw;
                _startPitch = _pitch;
                _startDistance = _distance;
                _startFocal = details.focalPoint;
              },
              onScaleUpdate: (details) {
                setState(() {
                  if (details.pointerCount >= 2) {
                    _distance = (_startDistance / details.scale)
                        .clamp(_minDistance, _maxDistance)
                        .toDouble();
                  } else {
                    _yaw =
                        _startYaw -
                        (details.focalPoint.dx - _startFocal.dx) * 0.008;
                    _pitch =
                        (_startPitch +
                                (details.focalPoint.dy - _startFocal.dy) *
                                    0.006)
                            .clamp(-1.2, 1.2)
                            .toDouble();
                  }
                });
              },
              child: CustomPaint(
                painter: ScenePainter(
                  furniture: widget.furniture,
                  camera: camera,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Restablecer vista',
              color: Colors.white,
              onPressed: _resetView,
              icon: const Icon(Icons.center_focus_strong, size: 20),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 12,
          child: IgnorePointer(
            child: Text(
              'Arrastra para rotar · rueda o pinza para zoom',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11.5,
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 10,
          child: IgnorePointer(
            child: Text(
              '${formatMm(size.width)} × ${formatMm(size.height)} × ${formatMm(size.depth)} mm',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
