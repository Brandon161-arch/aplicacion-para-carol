import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/data/seeds/material_seed.dart';
import 'package:mueble_cad/data/seeds/sample_furniture.dart';
import 'package:mueble_cad/domain/generators/cabinet_doors_drawer_generator.dart';
import 'package:mueble_cad/domain/services/hardware_marker_builder.dart';

void main() {
  final furniture = const CabinetDoorsDrawerGenerator().generate(
    spec: sampleCabinetSpec,
    catalog: sampleMaterialCatalog,
  );

  test('genera marcadores de bisagras sobre las puertas', () {
    final markers = const HardwareMarkerBuilder().build(furniture);
    final hinges = markers
        .where((marker) => marker.kind == HardwareMarkerKind.hinge)
        .toList();

    expect(hinges, isNotEmpty);
    expect(hinges.length, greaterThanOrEqualTo(2));
    for (final hinge in hinges) {
      expect(hinge.position.x.isFinite, isTrue);
      expect(hinge.position.y.isFinite, isTrue);
      expect(hinge.position.z.isFinite, isTrue);
    }
  });

  test('cada tornillo indica entrada, dirección y punta', () {
    final markers = const HardwareMarkerBuilder().build(furniture);
    final screws = markers
        .where((marker) => marker.kind == HardwareMarkerKind.screw)
        .toList();
    expect(screws, isNotEmpty);
    for (final screw in screws) {
      expect(screw.lengthMm, greaterThan(0));
      expect(screw.direction.length, closeTo(1, 0.001));
      final tip = screw.position + screw.direction * screw.lengthMm;
      expect(tip.x.isFinite && tip.y.isFinite && tip.z.isFinite, isTrue);
    }
  });

  test('incluye correderas y tornillos de unión', () {
    final markers = const HardwareMarkerBuilder().build(furniture);
    expect(
      markers.any((marker) => marker.kind == HardwareMarkerKind.drawerSlide),
      isTrue,
    );
    expect(
      markers.any((marker) => marker.kind == HardwareMarkerKind.screw),
      isTrue,
    );
  });
}
