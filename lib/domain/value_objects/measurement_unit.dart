enum MeasurementUnit {
  millimeter('mm', 'Milímetros', 1),
  centimeter('cm', 'Centímetros', 10),
  meter('m', 'Metros', 1000),
  inch('in', 'Pulgadas', 25.4);

  final String code;
  final String label;
  final double millimetersPerUnit;

  const MeasurementUnit(this.code, this.label, this.millimetersPerUnit);

  double fromMillimeters(double millimeters) =>
      millimeters / millimetersPerUnit;

  double toMillimeters(double value) => value * millimetersPerUnit;

  String formatValue(double millimeters, {int? decimals}) {
    final value = fromMillimeters(millimeters);
    final precision =
        decimals ??
        switch (this) {
          MeasurementUnit.millimeter => 1,
          MeasurementUnit.centimeter => 2,
          MeasurementUnit.meter => 3,
          MeasurementUnit.inch => 3,
        };
    final formatted = value.toStringAsFixed(precision);
    final trimmed = formatted.contains('.')
        ? formatted
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '')
        : formatted;
    return trimmed.replaceAll('.', ',');
  }

  static MeasurementUnit fromCode(String? code) => switch (code) {
    'cm' => MeasurementUnit.centimeter,
    'm' => MeasurementUnit.meter,
    'in' => MeasurementUnit.inch,
    _ => MeasurementUnit.millimeter,
  };

  String format(double millimeters, {int? decimals}) {
    return '${formatValue(millimeters, decimals: decimals)} $code';
  }
}
