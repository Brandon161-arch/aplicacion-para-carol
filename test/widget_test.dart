import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MuebleCadApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el mueble de ejemplo, la vista 3D y el despiece', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('MuebleCAD'), findsOneWidget);
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

  testWidgets('crea una pieza desde el constructor', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MuebleCadApp()));
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

  testWidgets('las tres secciones se adaptan a una pantalla móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MuebleCadApp()));
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
}
