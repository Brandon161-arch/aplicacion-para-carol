import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mueble_cad/app/app.dart';

void main() {
  testWidgets('muestra el mueble de ejemplo, la vista 3D y el despiece', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MuebleCadApp()));
    await tester.pumpAndSettle();

    expect(find.text('MuebleCAD'), findsOneWidget);
    expect(find.text('Vista 3D'), findsOneWidget);
    expect(find.text('Despiece'), findsOneWidget);
    expect(find.text('Lateral'), findsOneWidget);
    expect(find.text('16 piezas'), findsWidgets);
    expect(find.text('×2'), findsWidgets);
  });

  testWidgets('al cambiar el ancho se recalcula el despiece', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MuebleCadApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('width_field')), '1200');
    await tester.pumpAndSettle();

    // (1200 - 2*18 - 3*2) / 2 = 579 mm por puerta.
    expect(find.text('579'), findsWidgets);
  });
}
