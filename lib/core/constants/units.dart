/// Unidades internas del proyecto.
///
/// Todas las dimensiones se manejan en milímetros y el dinero en centavos.
/// La UI redondea a 0,1 mm y a la moneda correspondiente.
const double millimetersPerMeter = 1000;
const double squareMillimetersPerSquareMeter = 1000000;
const double defaultToleranceMm = 0.01;

/// Redondea una medida a una décima de milímetro.
double roundMm(double value) => (value * 10).roundToDouble() / 10;

/// Formatea milímetros para mostrar en pantalla (coma decimal en español).
String formatMm(double value) {
  final text = roundMm(value).toStringAsFixed(1);
  if (text.endsWith('.0')) {
    return text.substring(0, text.length - 2);
  }
  return text.replaceAll('.', ',');
}

/// Formatea metros cuadrados con tres decimales.
String formatM2(double value) => value.toStringAsFixed(3).replaceAll('.', ',');

/// Formatea una longitud en metros con dos decimales.
String formatMeters(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

/// Devuelve "1 pieza" o "2 piezas" según corresponda.
String countLabel(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
