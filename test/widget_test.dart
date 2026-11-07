import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/app/app.dart';
import 'package:mueble_cad/domain/entities/construction_settings.dart';
import 'package:mueble_cad/domain/entities/furniture.dart';
import 'package:mueble_cad/domain/entities/furniture_spec.dart';
import 'package:mueble_cad/domain/entities/part.dart';
import 'package:mueble_cad/domain/entities/regional_catalog.dart';
import 'package:mueble_cad/domain/services/rendering/orbit_camera.dart';
import 'package:mueble_cad/domain/services/rendering/scene_projector.dart';
import 'package:mueble_cad/domain/value_objects/cut_size.dart';
import 'package:mueble_cad/domain/value_objects/size3.dart';
import 'package:mueble_cad/domain/value_objects/vector3.dart';
import 'package:mueble_cad/domain/value_objects/measurement_unit.dart';
import 'package:mueble_cad/presentation/providers/project_context_provider.dart';
import 'package:mueble_cad/presentation/providers/app_section_provider.dart';
import 'package:mueble_cad/presentation/providers/custom_model_providers.dart';
import 'package:mueble_cad/presentation/painters/flat_pattern_painter.dart';
import 'package:mueble_cad/presentation/widgets/interactive_flat_pattern.dart';
import 'package:mueble_cad/presentation/widgets/viewer_3d.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'mueblecad.tour.seen.v1': true});
  });

  Widget testApp() => ProviderScope(
    overrides: [
      projectContextProvider.overrideWith(_TestProjectContextController.new),
    ],
    child: const MuebleCadApp(),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el mueble de ejemplo, la vista 3D y el despiece', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Mueble Maestro'), findsOneWidget);
    expect(find.text('Vista 3D'), findsOneWidget);
    expect(find.text('Despiece'), findsOneWidget);
    expect(find.text('Lateral'), findsWidgets);
    expect(find.text('16 piezas'), findsWidgets);
    expect(find.text('×2'), findsWidgets);
    expect(find.text('Plantillas de corte'), findsOneWidget);
  });

  testWidgets('al cambiar el ancho se recalcula el despiece', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('width_field')), '1200');
    await tester.pumpAndSettle();

    // (1200 - 2*18 - 3*2) / 2 = 579 mm por puerta.
    expect(find.text('579'), findsWidgets);
  });

  testWidgets('permite abrir el detalle de una pieza desde el despiece', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Lateral').first);
    await tester.pumpAndSettle();

    expect(find.text('Detalle de pieza'), findsOneWidget);
    expect(find.text('Plantilla de corte'), findsOneWidget);
    expect(find.text('Vista 3D de la pieza'), findsOneWidget);
  });

  testWidgets('navega a Crear y Explorar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Crear').first);
    await tester.pumpAndSettle();
    expect(find.text('Crear mueble'), findsOneWidget);

    await tester.tap(find.text('Explorar').first);
    await tester.pumpAndSettle();
    expect(find.text('Explorar muebles'), findsOneWidget);
    expect(find.text('Modelos de ejemplo'), findsOneWidget);
  });

  testWidgets('la región recomienda material y convierte entradas al país', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('country_selector')), findsOneWidget);
    expect(find.text('Materiales recomendados'), findsOneWidget);

    await tester.tap(find.byKey(const Key('country_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estados Unidos').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('USD'), findsWidgets);
    expect(
      tester
          .widget<DropdownButtonFormField<MeasurementUnit>>(
            find.byKey(const Key('unit_selector')),
          )
          .initialValue,
      MeasurementUnit.inch,
    );
    expect(find.text('Precios locales pendientes'), findsOneWidget);

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    final widthField = find.byKey(const Key('create_width_field'));
    expect(tester.widget<TextField>(widthField).controller!.text, '31,496');
    await tester.enterText(widthField, '40');
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(widthField));
    expect(container.read(customModelProvider).overallSize.width, 1016);
  });

  testWidgets('crea una pieza desde el constructor', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agregar pieza'));
    await tester.tap(find.text('Agregar pieza'));
    await tester.pumpAndSettle();

    expect(find.text('Medidas de corte'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Piezas (1)'), findsOneWidget);
    expect(find.text('Estante'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ofrece maderas y dibuja paneles con el mouse', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Maderas y tableros'));
    await tester.pumpAndSettle();
    expect(find.text('Roble 18 mm'), findsOneWidget);
    await tester.tap(find.text('Roble 18 mm'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.text('Maderas y tableros')),
    );
    expect(container.read(customModelProvider).defaultMaterialId, 'oak_18');

    final canvas = find.byKey(const Key('plan_sketch_canvas'));
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    final rect = tester.getRect(canvas);
    final gesture = await tester.startGesture(
      rect.topLeft + const Offset(20, 20),
    );
    await gesture.moveBy(const Offset(80, 55));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.textContaining('Crear 1 pieza'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sketch_create_parts')));
    await tester.pumpAndSettle();
    expect(container.read(customModelProvider).parts.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite ajustar largo con el tirador de la plantilla', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agregar pieza'));
    await tester.tap(find.text('Agregar pieza'));
    await tester.pumpAndSettle();

    final lengthField = find.byKey(const Key('part_length_field'));
    final beforeText = tester.widget<TextField>(lengthField).controller!.text;
    const initialCut = CutSize(length: 600, width: 300, thickness: 18);
    final pattern = find.byType(InteractiveFlatPattern);
    final patternRect = tester.getRect(pattern);
    final metrics = calculateFlatPatternMetrics(
      patternRect.size,
      initialCut,
      showDimensions: true,
    );
    final handle = patternRect.topLeft + metrics.panelRect.bottomRight;
    final gesture = await tester.startGesture(handle);
    await gesture.moveBy(const Offset(8, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final afterText = tester.widget<TextField>(lengthField).controller!.text;
    final before = double.parse(beforeText.replaceAll(',', '.'));
    final after = double.parse(afterText.replaceAll(',', '.'));
    expect(after, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrastra una pieza en el visor 3D del constructor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    const furniture = Furniture(
      id: 'drag_test',
      name: 'Prueba de arrastre',
      type: FurnitureType.custom,
      overallSize: Size3(width: 800, height: 600, depth: 600),
      settings: ConstructionSettings(),
      parts: [
        Part(
          id: 'drag_part',
          name: 'Panel',
          kind: PartKind.sidePanel,
          size: Size3(width: 300, height: 300, depth: 300),
          cutSize: CutSize(length: 300, width: 300, thickness: 300),
          materialId: 'mdf_18',
          position: Vector3(250, 150, 150),
        ),
      ],
    );
    container
        .read(customModelProvider.notifier)
        .loadFurniture(furniture, name: furniture.name);
    container.read(appSectionProvider.notifier).select(AppSection.create);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MuebleCadApp(),
      ),
    );
    await tester.pumpAndSettle();

    final viewer = find.byType(Viewer3D);
    expect(viewer, findsOneWidget);
    final viewerSize = tester.getSize(viewer);
    const camera = OrbitCamera(
      yaw: 0.62,
      pitch: 0.34,
      distance: 1600,
      target: Vector3(400, 300, 300),
    );
    expect(
      const SceneProjector().pickPart(
        furniture: furniture,
        camera: camera,
        viewportWidth: viewerSize.width,
        viewportHeight: viewerSize.height,
        screenX: viewerSize.width / 2,
        screenY: viewerSize.height / 2,
      ),
      'drag_part',
    );
    final before = container.read(customModelProvider).parts.single.position;
    final gesture = await tester.startGesture(tester.getRect(viewer).center);
    await gesture.moveBy(const Offset(8, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(37, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 15));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.textContaining('Panel · 300'), findsOneWidget);
    final after = container.read(customModelProvider).parts.single.position;
    expect(after.x != before.x || after.z != before.z, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre el editor de precios de materiales y corte', (
    tester,
  ) async {
    await pumpApp(tester);

    final editPrices = find.byTooltip('Editar precios y tarifas');
    await tester.ensureVisible(editPrices);
    await tester.tap(editPrices);
    await tester.pumpAndSettle();

    expect(find.text('Precios de Colombia'), findsOneWidget);
    expect(find.text('MDF 18 mm'), findsWidgets);
    expect(find.text('Corte / lámina'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Herrajes y tornillos'),
      ),
      findsOneWidget,
    );
    expect(find.text('Guardar precios'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('el editor de precios también se adapta a móvil', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    final editPrices = find.byTooltip('Editar precios y tarifas');
    await tester.ensureVisible(editPrices);
    await tester.tap(editPrices);
    await tester.pumpAndSettle();

    final dialog = find.byType(Dialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Herrajes y tornillos')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('las tres secciones se adaptan a una pantalla móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Crear mueble'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Explorar muebles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre la guía rápida desde el botón de ayuda', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Abrir guía rápida'));
    await tester.pumpAndSettle();
    expect(find.text('Guía rápida de Mueble Maestro'), findsOneWidget);
    expect(find.text('1 de 5'), findsOneWidget);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.text('Guía rápida de Mueble Maestro'), findsNothing);
  });

  testWidgets('muestra la guía la primera vez que se abre la app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    expect(find.text('Guía rápida de Mueble Maestro'), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
  });
}

class _TestProjectContextController extends ProjectContextController {
  @override
  Future<ProjectContext> build() async => ProjectContext(
    catalog: const RegionalCatalog(
      schemaVersion: 1,
      countries: [
        CountryProfile(
          code: 'CO',
          name: 'Colombia',
          currency: 'COP',
          defaultUnit: 'mm',
          taxName: 'IVA',
          standardTaxPercent: 19,
          taxSource: 'DIAN',
          taxUpdatedAt: '2026-11-04',
          taxNote: 'Referencia de prueba.',
          boardSizes: [BoardFormat(widthMm: 2440, heightMm: 1830)],
          priceDataAvailable: true,
          priceDataNote: 'Precios de prueba.',
          pricingNote: 'Tarifas de prueba.',
          materialPrices: {},
          hardwarePricesCents: {},
          cutPriceTiers: [
            CutPriceTier(maxPiecesPerSheet: null, priceCents: 500000),
          ],
          laborRateCentsPerHour: 0,
        ),
        CountryProfile(
          code: 'US',
          name: 'Estados Unidos',
          currency: 'USD',
          defaultUnit: 'in',
          taxName: 'Sales tax',
          standardTaxPercent: null,
          taxSource: 'Local',
          taxUpdatedAt: '2026-11-04',
          taxNote: 'Configurable.',
          boardSizes: [BoardFormat(widthMm: 2438.4, heightMm: 1219.2)],
          priceDataAvailable: false,
          priceDataNote: 'Precios locales pendientes.',
          pricingNote: '',
          materialPrices: {},
          hardwarePricesCents: {},
          cutPriceTiers: [],
          laborRateCentsPerHour: 0,
        ),
      ],
      materials: [
        MaterialProfile(
          id: 'plywood',
          name: 'Triplex sellado',
          catalogMaterialId: 'plywood_18',
          costBand: 'medio',
          pros: ['Resiste humedad moderada'],
          cons: ['Sellar cantos'],
          climateScores: {'temperate': 4},
          useScores: {'interior': 4},
        ),
      ],
      climates: [ClimateOption(id: 'temperate', label: 'Templado')],
      uses: [PlaceUseOption(id: 'interior', label: 'Interior')],
    ),
    countryCode: 'CO',
    unitCode: 'mm',
    climateId: 'temperate',
    useId: 'interior',
    kerfMm: 3.2,
  );
}
