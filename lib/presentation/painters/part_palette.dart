import 'package:flutter/material.dart';

import '../../domain/entities/part.dart';

/// Color base de cada tipo de pieza en el visor 3D.
Color partColor(PartKind kind) => switch (kind) {
  PartKind.sidePanel ||
  PartKind.topPanel ||
  PartKind.bottomPanel ||
  PartKind.divider => const Color(0xFFD8A56F),
  PartKind.shelf => const Color(0xFFE3BC8B),
  PartKind.backPanel => const Color(0xFF8D6748),
  PartKind.door => const Color(0xFFC38656),
  PartKind.drawerFront => const Color(0xFFB67647),
  PartKind.drawerSide || PartKind.drawerBack => const Color(0xFFC99560),
  PartKind.drawerBottom => const Color(0xFFB8895D),
  PartKind.plinth => const Color(0xFF7A573D),
  PartKind.rail || PartKind.apron => const Color(0xFFB98A5C),
  PartKind.desktop || PartKind.leg => const Color(0xFFD0A273),
  PartKind.other => const Color(0xFFC89B6A),
};

IconData partIcon(PartKind kind) => switch (kind) {
  PartKind.sidePanel => Icons.view_sidebar_outlined,
  PartKind.topPanel => Icons.vertical_align_top,
  PartKind.bottomPanel => Icons.vertical_align_bottom,
  PartKind.shelf => Icons.horizontal_rule,
  PartKind.backPanel => Icons.crop_square,
  PartKind.divider => Icons.horizontal_split,
  PartKind.door => Icons.door_front_door_outlined,
  PartKind.drawerFront => Icons.view_agenda_outlined,
  PartKind.drawerSide => Icons.view_week_outlined,
  PartKind.drawerBack => Icons.view_day_outlined,
  PartKind.drawerBottom => Icons.crop_16_9,
  PartKind.plinth => Icons.space_bar,
  PartKind.rail => Icons.horizontal_rule,
  PartKind.desktop => Icons.table_restaurant_outlined,
  PartKind.leg => Icons.straighten,
  PartKind.apron => Icons.linear_scale,
  PartKind.other => Icons.category_outlined,
};
