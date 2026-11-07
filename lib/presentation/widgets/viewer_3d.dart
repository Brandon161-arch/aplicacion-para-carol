import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
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
  final Set<String> hiddenPartIds;
  final String? highlightDimension;

  const Viewer3D({
    super.key,
    required this.furniture,
    this.moveMode = false,
    this.selectedPartId,
    this.onPartSelected,
    this.onPartMoved,
    this.showBounds = true,
    this.hiddenPartIds = const {},
    this.highlightDimension,
  });

  @override
  State<Viewer3D> createState() => _Viewer3DState();
}

class _Viewer3DState extends State<Viewer3D>
    with SingleTickerProviderStateMixin {
  static const double _defaultYaw = 0.62;
  static const double _defaultPitch = 0.34;
  static const double _snapMm = 10;

  late double _yaw;
  late double _pitch;
  late double _distance;
  double _startYaw = 0;
  double _startPitch = 0;
  double _startDistance = 0;
  Offset _startFocal = Offset.zero;

  Part? _draggingPart;
  Part? _previewPart;
  Vector3? _dragStartPosition;
  Vector3? _dragStartPlanePoint;
  double? _dragPlaneY;
  double _doorsProgress = 0.0;
  double _drawersProgress = 0.0;
  double _explodeProgress = 0.0;
  bool _controlsExpanded = false;
  bool _showHardware = true;
  bool _snapEnabled = true;
  Size _viewportSize = Size.zero;

  late final AnimationController _motionController;
  double _doorsStart = 0;
  double _drawersStart = 0;
  double _explodeStart = 0;
  double _doorsTarget = 0;
  double _drawersTarget = 0;
  double _explodeTarget = 0;

  void _setOrthogonalView(String view) {
    setState(() {
      switch (view) {
        case 'front':
          _yaw = 0.0;
          _pitch = 0.0;
          break;
        case 'side':
          _yaw = math.pi / 2;
          _pitch = 0.0;
          break;
        case 'top':
          _yaw = 0.0;
          _pitch = math.pi / 2 - 0.02;
          break;
        case 'iso':
        default:
          _yaw = _defaultYaw;
          _pitch = _defaultPitch;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _yaw = _defaultYaw;
    _pitch = _defaultPitch;
    _distance = _fitDistance;
    _motionController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 750),
        )..addListener(() {
          final t = Curves.easeInOutCubic.transform(_motionController.value);
          setState(() {
            _doorsProgress = _doorsStart + (_doorsTarget - _doorsStart) * t;
            _drawersProgress =
                _drawersStart + (_drawersTarget - _drawersStart) * t;
            _explodeProgress =
                _explodeStart + (_explodeTarget - _explodeStart) * t;
          });
        });
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  void _animateTo({double? doors, double? drawers, double? explode}) {
    _doorsStart = _doorsProgress;
    _drawersStart = _drawersProgress;
    _explodeStart = _explodeProgress;
    _doorsTarget = doors ?? _doorsProgress;
    _drawersTarget = drawers ?? _drawersProgress;
    _explodeTarget = explode ?? _explodeProgress;
    _motionController.forward(from: 0);
  }

  void _setProgress({double? doors, double? drawers, double? explode}) {
    _motionController.stop();
    setState(() {
      if (doors != null) _doorsProgress = doors;
      if (drawers != null) _drawersProgress = drawers;
      if (explode != null) _explodeProgress = explode;
    });
  }

  Furniture get _visibleFurniture {
    if (widget.hiddenPartIds.isEmpty) return widget.furniture;
    return Furniture(
      id: widget.furniture.id,
      name: widget.furniture.name,
      type: widget.furniture.type,
      overallSize: widget.furniture.overallSize,
      settings: widget.furniture.settings,
      parts: widget.furniture.parts
          .where((part) => !widget.hiddenPartIds.contains(part.id))
          .toList(growable: false),
      joints: widget.furniture.joints,
      manualHardware: widget.furniture.manualHardware,
      mechanisms: widget.furniture.mechanisms,
      schemaVersion: widget.furniture.schemaVersion,
    );
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
    // Solo zoom si el puntero está sobre el mueble proyectado. Fuera de él,
    // la rueda sigue desplazando la página.
    if (!_isPointerOverModel(event.localPosition)) return;
    // Registra el evento en el resolver: esto impide que el Scrollable
    // ancestor también lo procese y desplace la página al hacer zoom.
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent) return;
      _applyZoom(resolved.scrollDelta.dy);
    });
  }

  void _applyZoom(double deltaY) {
    final factor = math.exp(deltaY * 0.0012);
    setState(() {
      _distance = (_distance * factor)
          .clamp(_minDistance, _maxDistance)
          .toDouble();
    });
  }

  bool _isPointerOverModel(Offset position) {
    if (_viewportSize.isEmpty) return false;
    final size = widget.furniture.overallSize;
    final corners = <Vector3>[
      const Vector3(0, 0, 0),
      Vector3(size.width, 0, 0),
      Vector3(size.width, size.height, 0),
      Vector3(0, size.height, 0),
      Vector3(0, 0, size.depth),
      Vector3(size.width, 0, size.depth),
      Vector3(size.width, size.height, size.depth),
      Vector3(0, size.height, size.depth),
    ];
    const projector = SceneProjector();
    final projected = <Offset>[];
    for (final corner in corners) {
      final point = projector.projectPoint(
        point: corner,
        camera: _camera,
        viewportWidth: _viewportSize.width,
        viewportHeight: _viewportSize.height,
      );
      if (point != null) projected.add(Offset(point.x, point.y));
    }
    if (projected.length < 2) return false;
    var left = projected.first.dx;
    var right = projected.first.dx;
    var top = projected.first.dy;
    var bottom = projected.first.dy;
    for (final point in projected.skip(1)) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    ).inflate(14).contains(position);
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
        furniture: _visibleFurniture,
        camera: camera,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
        screenX: details.localFocalPoint.dx,
        screenY: details.localFocalPoint.dy,
      );
      if (partId != null) {
        final part = _visibleFurniture.partById(partId);
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
      var x = (startPosition.x + (current.x - startPlanePoint.x))
          .clamp(0.0, maxX)
          .toDouble();
      var z = (startPosition.z + (current.z - startPlanePoint.z))
          .clamp(0.0, maxZ)
          .toDouble();
      if (_snapEnabled) {
        x = _snapCoordinate(x, axisX: true, part: draggingPart, max: maxX);
        z = _snapCoordinate(z, axisX: false, part: draggingPart, max: maxZ);
      }
      final candidate = draggingPart.copyWith(
        position: Vector3(x, startPosition.y, z),
      );
      if (_collides(candidate)) return;
      setState(() => _previewPart = candidate);
      widget.onPartMoved!(candidate);
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
    if (_previewPart != null) setState(() => _previewPart = null);
  }

  double _snapCoordinate(
    double value, {
    required bool axisX,
    required Part part,
    required double max,
  }) {
    var snapped = (value / _snapMm).round() * _snapMm;
    const tolerance = 9.0;
    final size = axisX ? part.size.width : part.size.depth;
    double? best;
    var bestDistance = tolerance;
    for (final other in _visibleFurniture.parts) {
      if (other.id == part.id) continue;
      final start = axisX ? other.position.x : other.position.z;
      final extent = axisX ? other.size.width : other.size.depth;
      final candidates = [
        start,
        start + extent,
        start - size,
        start + extent - size,
      ];
      for (final candidate in candidates) {
        final distance = (candidate - value).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = candidate;
        }
      }
    }
    snapped = best ?? snapped;
    return snapped.clamp(0.0, max).toDouble();
  }

  bool _collides(Part candidate) {
    const tolerance = 0.6;
    for (final other in _visibleFurniture.parts) {
      if (other.id == candidate.id) continue;
      final overlapX = _overlap(
        candidate.position.x,
        candidate.position.x + candidate.size.width,
        other.position.x,
        other.position.x + other.size.width,
      );
      final overlapY = _overlap(
        candidate.position.y,
        candidate.position.y + candidate.size.height,
        other.position.y,
        other.position.y + other.size.height,
      );
      final overlapZ = _overlap(
        candidate.position.z,
        candidate.position.z + candidate.size.depth,
        other.position.z,
        other.position.z + other.size.depth,
      );
      if (overlapX > tolerance &&
          overlapY > tolerance &&
          overlapZ > tolerance) {
        return true;
      }
    }
    return false;
  }

  double _overlap(double startA, double endA, double startB, double endB) =>
      (endA < endB ? endA : endB) - (startA > startB ? startA : startB);

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
        _viewportSize = viewport;
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
                      furniture: _visibleFurniture,
                      camera: camera,
                      selectedPartId: widget.selectedPartId,
                      showBounds: widget.showBounds,
                      explodeFactor: _explodeProgress,
                      doorOpenProgress: _doorsProgress,
                      drawerOpenProgress: _drawersProgress,
                      showHardware:
                          _showHardware &&
                          _doorsProgress.abs() < 0.001 &&
                          _drawersProgress.abs() < 0.001 &&
                          _explodeProgress.abs() < 0.001,
                      previewPart: _previewPart,
                      highlightDimension: widget.highlightDimension,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // Barra de Vistas Ortogonales
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.viewerPanel,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.viewerPanelBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: BoxConstraints(maxWidth: viewport.width - 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _viewButton(
                        'ISOMÉTRICA',
                        'iso',
                        'Vista isométrica: el mueble en perspectiva.',
                      ),
                      _viewButton(
                        'FRONTAL',
                        'front',
                        'Vista frontal: de frente, como mirarías la puerta.',
                      ),
                      _viewButton(
                        'LATERAL',
                        'side',
                        'Vista lateral: de perfil, para ver la profundidad.',
                      ),
                      _viewButton(
                        'PLANTA',
                        'top',
                        'Vista de planta: desde arriba, como un plano.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Controles de Animación y Explosionado
            Positioned(
              top: 50,
              left: 10,
              child: Container(
                width: 236,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.viewerPanel,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.viewerPanelBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: 'Abre puertas, cajones o separa las piezas para ver cómo se arma el mueble. Los herrajes se ocultan mientras se mueve.',
                            child: Text(
                              'Simulación & Apertura',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: _controlsExpanded
                              ? 'Ocultar los controles de apertura'
                              : 'Mostrar los controles de apertura',
                          child: InkWell(
                            onTap: () => setState(
                              () => _controlsExpanded = !_controlsExpanded,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                _controlsExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _motionButton(
                          icon: Icons.door_front_door_outlined,
                          tooltip: 'Abrir/cerrar puertas',
                          onPressed: () =>
                              _animateTo(doors: _doorsProgress > 0.5 ? 0 : 1),
                        ),
                        _motionButton(
                          icon: Icons.view_agenda_outlined,
                          tooltip: 'Abrir/cerrar cajones',
                          onPressed: () => _animateTo(
                            drawers: _drawersProgress > 0.5 ? 0 : 1,
                          ),
                        ),
                        _motionButton(
                          icon: Icons.all_out,
                          tooltip: 'Explosionar/armar',
                          onPressed: () => _animateTo(
                            explode: _explodeProgress > 0.5 ? 0 : 1,
                          ),
                        ),
                        _motionButton(
                          icon: Icons.restart_alt,
                          tooltip: 'Cerrar todo',
                          onPressed: () =>
                              _animateTo(doors: 0, drawers: 0, explode: 0),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      children: [
                        _toggleChip(
                          label: 'Herrajes',
                          selected: _showHardware,
                          onSelected: (value) =>
                              setState(() => _showHardware = value),
                        ),
                        _toggleChip(
                          label: 'Encajar',
                          selected: _snapEnabled,
                          onSelected: (value) =>
                              setState(() => _snapEnabled = value),
                        ),
                      ],
                    ),
                    if (_controlsExpanded && _showHardware) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: const [
                          _MarkerLegend(
                            color: Color(0xFFE0A526),
                            label: 'Bisagra',
                          ),
                          _MarkerLegend(
                            color: Color(0xFF37474F),
                            label: 'Tornillo',
                          ),
                          _MarkerLegend(
                            color: Color(0xFF2E7D9A),
                            label: 'Corredera',
                          ),
                          _MarkerLegend(
                            color: Color(0xFFFF6D00),
                            label: 'Punta',
                          ),
                        ],
                      ),
                      Text(
                        'El aro marca la entrada y el punto naranja, la punta dentro de la madera.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                        ),
                      ),
                      if (_doorsProgress.abs() > 0.001 ||
                          _drawersProgress.abs() > 0.001)
                        Text(
                          'Los herrajes se ocultan durante la apertura.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 9,
                          ),
                        ),
                    ],
                    if (_controlsExpanded) ...[
                      const SizedBox(height: 6),
                      _sliderRow(
                        label: 'Puertas',
                        value: _doorsProgress,
                        onChanged: (v) => _setProgress(doors: v),
                      ),
                      _sliderRow(
                        label: 'Cajones',
                        value: _drawersProgress,
                        onChanged: (v) => _setProgress(drawers: v),
                      ),
                      _sliderRow(
                        label: 'Explosión',
                        value: _explodeProgress,
                        onChanged: (v) => _setProgress(explode: v),
                      ),
                    ],
                  ],
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
                      ? 'Arrastra una pieza para moverla · rueda sobre el mueble para zoom'
                      : 'Arrastra para girar · rueda sobre el mueble para zoom',
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

  Widget _motionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 17,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      showCheckmark: false,
      selectedColor: AppTheme.accent,
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF2E2620) : Colors.white,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
    );
  }

  bool _isViewActive(String viewKey) {
    const epsilon = 0.05;
    return switch (viewKey) {
      'front' => _yaw.abs() < epsilon && _pitch.abs() < epsilon,
      'side' => (_yaw - math.pi / 2).abs() < epsilon && _pitch.abs() < epsilon,
      'top' =>
        (_pitch - (math.pi / 2 - 0.02)).abs() < epsilon && _yaw.abs() < epsilon,
      _ =>
        (_yaw - _defaultYaw).abs() < epsilon &&
            (_pitch - _defaultPitch).abs() < epsilon,
    };
  }

  Widget _viewButton(String label, String viewKey, String tooltip) {
    final active = _isViewActive(viewKey);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _setOrthogonalView(viewKey),
        borderRadius: BorderRadius.circular(999),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accent.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppTheme.accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color(0xFFFFD9B0)
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: const Color(0xFFFFB74D),
                thumbColor: const Color(0xFFFFB74D),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MarkerLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
