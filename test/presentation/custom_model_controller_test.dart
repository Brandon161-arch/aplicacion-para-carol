import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';
import 'package:mueble_cad/presentation/providers/custom_model_providers.dart';

void main() {
  test('Ajustar medidas al contenido encuadra y desplaza todas las piezas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(customModelProvider.notifier);

    controller.addPart(
      const Part(
        id: 'part_a',
        name: 'Estante',
        kind: PartKind.shelf,
        size: Size3(width: 100, height: 20, depth: 50),
        cutSize: CutSize(length: 100, width: 50, thickness: 20),
        materialId: 'mdf_18',
        position: Vector3(50, 10, 20),
      ),
    );
    controller.addPart(
      const Part(
        id: 'part_b',
        name: 'Lateral',
        kind: PartKind.sidePanel,
        size: Size3(width: 30, height: 80, depth: 40),
        cutSize: CutSize(length: 80, width: 40, thickness: 30),
        materialId: 'mdf_18',
        position: Vector3(200, 50, 100),
      ),
    );

    controller.fitToContent();
    final draft = container.read(customModelProvider);

    expect(draft.overallSize, const Size3(width: 180, height: 120, depth: 120));
    expect(draft.parts.first.position, Vector3.zero);
    expect(draft.parts.last.position, const Vector3(150, 40, 80));
  });

  test('escalar al volumen cambia las caras y conserva espesores', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(customModelProvider.notifier);
    controller.updateOverallSize(width: 360, height: 240, depth: 240);
    controller.addPart(
      const Part(
        id: 'horizontal',
        name: 'Estante',
        kind: PartKind.shelf,
        size: Size3(width: 100, height: 20, depth: 50),
        cutSize: CutSize(length: 100, width: 50, thickness: 20),
        materialId: 'mdf_18',
        position: Vector3(50, 10, 20),
      ),
    );
    controller.addPart(
      const Part(
        id: 'vertical',
        name: 'Lateral',
        kind: PartKind.sidePanel,
        size: Size3(width: 30, height: 80, depth: 40),
        cutSize: CutSize(length: 80, width: 40, thickness: 30),
        materialId: 'mdf_18',
        position: Vector3(200, 50, 100),
      ),
    );

    controller.scalePartsToOverall();
    final draft = container.read(customModelProvider);
    final horizontal = draft.parts.first;
    final vertical = draft.parts.last;

    expect(horizontal.cutSize.length, closeTo(200, 0.001));
    expect(horizontal.cutSize.width, closeTo(100, 0.001));
    expect(horizontal.cutSize.thickness, 20);
    expect(vertical.cutSize.length, closeTo(160, 0.001));
    expect(vertical.cutSize.width, closeTo(80, 0.001));
    expect(vertical.cutSize.thickness, 30);
    expect(horizontal.hasConsistentDimensions, isTrue);
    expect(vertical.hasConsistentDimensions, isTrue);
    expect(draft.overallSize, const Size3(width: 360, height: 240, depth: 240));
  });
}
