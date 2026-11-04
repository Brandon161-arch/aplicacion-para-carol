import '../entities/furniture.dart';
import '../entities/material.dart';
import '../entities/part.dart';
import '../value_objects/cut_size.dart';

/// Fila del despiece. Agrupa piezas físicamente idénticas.
class CutListItem {
  final List<String> partIds;
  final String name;
  final PartKind kind;
  final int quantity;
  final CutSize cutSize;
  final String materialId;
  final String materialName;
  final GrainDirection grain;
  final Set<PanelEdge> bandedEdges;
  final Set<String> bandingMaterialIds;

  /// Área total de corte de la fila (todas las unidades).
  final double areaM2;

  /// Canto total de la fila, en metros.
  final double bandingLengthM;

  const CutListItem({
    required this.partIds,
    required this.name,
    required this.kind,
    required this.quantity,
    required this.cutSize,
    required this.materialId,
    required this.materialName,
    required this.grain,
    required this.bandedEdges,
    required this.bandingMaterialIds,
    required this.areaM2,
    required this.bandingLengthM,
  });

  bool get hasBanding => bandedEdges.isNotEmpty;
  int get bandedEdgeCount => bandedEdges.length;
}

class CutList {
  final List<CutListItem> items;
  final int totalPieces;
  final double totalAreaM2;
  final Map<String, double> areaByMaterial;
  final Map<String, int> piecesByMaterial;

  const CutList({
    required this.items,
    required this.totalPieces,
    required this.totalAreaM2,
    required this.areaByMaterial,
    required this.piecesByMaterial,
  });
}

/// Deriva el despiece agrupando piezas con la misma firma de corte.
///
/// La cantidad no se guarda en [Part]: se obtiene de la geometría. Así una
/// pieza duplicada nunca puede quedar con un contador inconsistente.
class CutListCalculator {
  const CutListCalculator();

  CutList build(Furniture furniture, MaterialCatalog catalog) {
    final groups = <String, _CutGroup>{};
    for (final part in furniture.parts) {
      final signature = _signature(part);
      groups.putIfAbsent(signature, () => _CutGroup(part)).add(part);
    }

    final items = <CutListItem>[];
    final areaByMaterial = <String, double>{};
    final piecesByMaterial = <String, int>{};

    for (final group in groups.values) {
      final representative = group.representative;
      final materialName =
          catalog.byId(representative.materialId)?.name ??
          representative.materialId;
      final item = CutListItem(
        partIds: group.partIds,
        name: representative.name,
        kind: representative.kind,
        quantity: group.quantity,
        cutSize: representative.cutSize,
        materialId: representative.materialId,
        materialName: materialName,
        grain: representative.grain,
        bandedEdges: representative.edgeBanding.keys.toSet(),
        bandingMaterialIds: representative.edgeBanding.values
            .map((banding) => banding.materialId)
            .toSet(),
        areaM2: group.areaM2,
        bandingLengthM: group.bandingLengthMm / 1000,
      );
      items.add(item);
      areaByMaterial.update(
        item.materialId,
        (value) => value + item.areaM2,
        ifAbsent: () => item.areaM2,
      );
      piecesByMaterial.update(
        item.materialId,
        (value) => value + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    return CutList(
      items: items,
      totalPieces: furniture.parts.length,
      totalAreaM2: items.fold(0, (total, item) => total + item.areaM2),
      areaByMaterial: areaByMaterial,
      piecesByMaterial: piecesByMaterial,
    );
  }

  String _signature(Part part) {
    final edges = part.edgeBanding.keys.map((edge) => edge.index).toList()
      ..sort();
    final bandingMaterialIds =
        part.edgeBanding.values
            .map((banding) => banding.materialId)
            .toSet()
            .toList()
          ..sort();
    return [
      part.name,
      part.materialId,
      part.cutSize.length.toStringAsFixed(3),
      part.cutSize.width.toStringAsFixed(3),
      part.cutSize.thickness.toStringAsFixed(3),
      part.grain.name,
      edges.join(','),
      bandingMaterialIds.join(','),
    ].join('|');
  }
}

class _CutGroup {
  final Part representative;
  final List<String> partIds = [];
  double areaM2 = 0;
  double bandingLengthMm = 0;

  _CutGroup(this.representative);

  int get quantity => partIds.length;

  void add(Part part) {
    partIds.add(part.id);
    areaM2 += part.cutAreaM2;
    bandingLengthMm += part.bandingLengthMm;
  }
}
