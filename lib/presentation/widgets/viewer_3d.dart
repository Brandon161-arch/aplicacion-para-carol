import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/units.dart';
import '../../domain/entities/furniture.dart';
import '../../domain/entities/part.dart';
import '../../domain/services/rendering/orbit_camera.dart';
import '../../domain/services/rendering/scene_projector.dart';
import '../../domain/value_objects/vector3.dart';
import '../painters/scene_painter.dart';

/// Visor 3D con órbita, zoom y, opcionalmente, arrastre de piezas.
class Viewer3D extends StatefulWidget {
  final Furniture furniture;
  final bool moveMode;
  final String? selectedPartId;
  final ValueChanged<String>? onPartSelected;
  final ValueChanged<Part>? onPartMoved;
  final bool showBounds;

  const Viewer3D({
    super.key,
    required this.furniture,
    this.moveMode = false,
    this.selectedPartId,
    this.onPartSelected,
    this.onPartMoved,
    this.showBounds = true,
  });

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

  Part? _draggingPart;
  Vector3? _dragStartPosition;
  Vector3? _dragStartPlanePoint;
  double? _dragPlaneY;

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

  void _handleScaleStart(
    ScaleStartDetails details,
    OrbitCamera camera,
    Size viewport,
  ) {
    if (widget.moveMode &&
        details.pointerCount <= 1 &&
        widget.onPartMoved != null) {
      const projector = SceneProjector();
      final partId = projector.pickPart(
        furniture: widget.furniture,
        camera: camera,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
        screenX: details.localFocalPoint.dx,
        screenY: details.localFocalPoint.dy,
      );
      if (partId != null) {
        final part = widget.furniture.partById(partId);
        if (part != null) {
          final planeY = part.position.y + part.size.height / 2;
          final startPoint = projector.screenToPlane(
            screenX: details.localFocalPoint.dx,
            screenY: details.localFocalPoint.dy,
            camera: camera,
            viewportWidth: viewport.width,
            viewportHeight: viewport.height,
            planeY: planeY,
          );
          if (startPoint != null) {
            widget.onPartSelected?.call(partId);
            _draggingPart = part;
            _dragStartPosition = part.position;
            _dragStartPlanePoint = startPoint;
            _dragPlaneY = planeY;
            return;
          }
        }
      }
    }

    _draggingPart = null;
    _dragStartPlanePoint = null;
    _startYaw = _yaw;
    _startPitch = _pitch;
    _startDistance = _distance;
    _startFocal = details.localFocalPoint;
  }

  void _handleScaleUpdate(
    ScaleUpdateDetails details,
    OrbitCamera camera,
    Size viewport,
  ) {
    final draggingPart = _draggingPart;
    final startPosition = _dragStartPosition;
    final startPlanePoint = _dragStartPlanePoint;
    final planeY = _dragPlaneY;
    if (draggingPart != null &&
        startPosition != null &&
        startPlanePoint != null &&
        planeY != null &&
        widget.onPartMoved != null) {
      final current = const SceneProjector().screenToPlane(
        screenX: details.localFocalPoint.dx,
        screenY: details.localFocalPoint.dy,
        camera: camera,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
        planeY: planeY,
      );
      if (current == null) return;

      final maxX = math.max(
        0.0,
        widget.furniture.overallSize.width - draggingPart.size.width,
      );
      final maxZ = math.max(
        0.0,
        widget.furniture.overallSize.depth - draggingPart.size.depth,
      );
      final x = (startPosition.x + (current.x - startPlanePoint.x))
          .clamp(0.0, maxX)
          .toDouble();
      final z = (startPosition.z + (current.z - startPlanePoint.z))
          .clamp(0.0, maxZ)
          .toDouble();

      widget.onPartMoved!(
        draggingPart.copyWith(position: Vector3(x, startPosition.y, z)),
      );
      return;
    }

    setState(() {
      if (details.pointerCount >= 2) {
        _distance = (_startDistance / details.scale)
            .clamp(_minDistance, _maxDistance)
            .toDouble();
      } else {
        _yaw =
            _startYaw - (details.localFocalPoint.dx - _startFocal.dx) * 0.008;
        _pitch =
            (_startPitch +
                    (details.localFocalPoint.dy - _startFocal.dy) * 0.006)
                .clamp(-1.2, 1.2)
                .toDouble();
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _draggingPart = null;
    _dragStartPlanePoint = null;
    _dragPlaneY = null;
  }

  OrbitCamera get _camera {
    final size = widget.furniture.overallSize;
    return OrbitCamera(
      yaw: _yaw,
      pitch: _pitch,
      distance: _distance,
      target: Vector3(size.width / 2, size.height / 2, size.depth / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.furniture.overallSize;
    final camera = _camera;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            MouseRegion(
              cursor: widget.moveMode
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.grab,
              child: Listener(
                onPointerSignal: _handleScroll,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: _resetView,
                  onScaleStart: (details) =>
                      _handleScaleStart(details, camera, viewport),
                  onScaleUpdate: (details) =>
                      _handleScaleUpdate(details, camera, viewport),
                  onScaleEnd: _handleScaleEnd,
                  child: CustomPaint(
                    painter: ScenePainter(
                      furniture: widget.furniture,
                      camera: camera,
                      selectedPartId: widget.selectedPartId,
                      showBounds: widget.showBounds,
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
                  widget.moveMode
                      ? 'Arrastra una pieza para moverla · fondo para rotar'
                      : 'Arrastra para rotar · rueda o pinza para zoom',
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
      },
    );
  }
}
