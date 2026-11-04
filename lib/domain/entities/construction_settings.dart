/// Parámetros constructivos que afectan la generación de piezas.
class ConstructionSettings {
  final double panelThicknessMm;
  final double backPanelThicknessMm;
  final double doorGapMm;
  final double shelfSetbackMm;
  final double plinthHeightMm;

  const ConstructionSettings({
    this.panelThicknessMm = 18,
    this.backPanelThicknessMm = 5,
    this.doorGapMm = 2,
    this.shelfSetbackMm = 20,
    this.plinthHeightMm = 60,
  });

  ConstructionSettings copyWith({
    double? panelThicknessMm,
    double? backPanelThicknessMm,
    double? doorGapMm,
    double? shelfSetbackMm,
    double? plinthHeightMm,
  }) => ConstructionSettings(
    panelThicknessMm: panelThicknessMm ?? this.panelThicknessMm,
    backPanelThicknessMm: backPanelThicknessMm ?? this.backPanelThicknessMm,
    doorGapMm: doorGapMm ?? this.doorGapMm,
    shelfSetbackMm: shelfSetbackMm ?? this.shelfSetbackMm,
    plinthHeightMm: plinthHeightMm ?? this.plinthHeightMm,
  );
}
