import 'dart:math' as math;

import '../entities/material.dart';
import '../entities/regional_catalog.dart';
import '../entities/part.dart';

class NestingPiece {
  final String partId;
  final String partName;
  final String materialId;
  final double lengthMm;
  final double widthMm;
  final GrainDirection grain;

  const NestingPiece({
    required this.partId,
    required this.partName,
    required this.materialId,
    required this.lengthMm,
    required this.widthMm,
    required this.grain,
  });

  double get longSide => math.max(lengthMm, widthMm);
}

class NestingPlacement {
  final String partId;
  final String partName;
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;
  final bool rotated;

  const NestingPlacement({
    required this.partId,
    required this.partName,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    required this.rotated,
  });

  double get areaM2 => widthMm * heightMm / 1000000;
}

class NestingSheet {
  final int index;
  final BoardFormat board;
  final List<NestingPlacement> placements;

  const NestingSheet({
    required this.index,
    required this.board,
    required this.placements,
  });

  double get usedAreaM2 =>
      placements.fold(0, (total, placement) => total + placement.areaM2);

  double get utilization => board.widthMm * board.heightMm == 0
      ? 0
      : usedAreaM2 / (board.widthMm * board.heightMm / 1000000);
}

class MaterialNestingResult {
  final String materialId;
  final String materialName;
  final List<NestingSheet> sheets;
  final List<String> unplacedPartIds;

  const MaterialNestingResult({
    required this.materialId,
    required this.materialName,
    required this.sheets,
    required this.unplacedPartIds,
  });

  int get sheetCount => sheets.length;

  bool get isComplete => unplacedPartIds.isEmpty;

  double get usedAreaM2 =>
      sheets.fold(0, (total, sheet) => total + sheet.usedAreaM2);
}

class NestingResult {
  final double kerfMm;
  final Map<String, MaterialNestingResult> byMaterial;

  const NestingResult({required this.kerfMm, required this.byMaterial});

  int get totalSheets => byMaterial.values.fold(
    0,
    (total, material) => total + material.sheetCount,
  );

  List<String> get unplacedPartIds => [
    for (final material in byMaterial.values) ...material.unplacedPartIds,
  ];
}

/// Nesting rectangular parts into sheets with a conservative kerf gap.
///
/// This is a deterministic MaxRects best-short-side-fit heuristic, not an
/// industrial guillotine-cut optimizer. Grain-constrained pieces keep their
/// grain axis aligned with the long axis of the sheet.
class BoardNestingCalculator {
  const BoardNestingCalculator();

  NestingResult calculate({
    required List<NestingPiece> pieces,
    required MaterialCatalog catalog,
    required double kerfMm,
  }) {
    final results = <String, MaterialNestingResult>{};
    final materialIds = pieces.map((piece) => piece.materialId).toSet();
    for (final materialId in materialIds) {
      final material = catalog.byId(materialId);
      final materialPieces = pieces
          .where((piece) => piece.materialId == materialId)
          .toList(growable: false);
      final board = material?.sheetSize;
      if (material == null) {
        results[materialId] = MaterialNestingResult(
          materialId: materialId,
          materialName: material?.name ?? materialId,
          sheets: const [],
          unplacedPartIds: materialPieces.map((piece) => piece.partId).toList(),
        );
        continue;
      }
      if (board == null && material.priceUnit != PriceUnit.perSheet) continue;
      if (board == null) {
        results[materialId] = MaterialNestingResult(
          materialId: materialId,
          materialName: material.name,
          sheets: const [],
          unplacedPartIds: materialPieces.map((piece) => piece.partId).toList(),
        );
        continue;
      }
      results[materialId] = _nestMaterial(
        material: material,
        board: BoardFormat(widthMm: board.widthMm, heightMm: board.heightMm),
        pieces: materialPieces,
        kerfMm: math.max(0, kerfMm).toDouble(),
      );
    }
    return NestingResult(kerfMm: kerfMm, byMaterial: results);
  }

  MaterialNestingResult _nestMaterial({
    required Material material,
    required BoardFormat board,
    required List<NestingPiece> pieces,
    required double kerfMm,
  }) {
    final boardWidth = math.max(board.widthMm, board.heightMm).toDouble();
    final boardHeight = math.min(board.widthMm, board.heightMm).toDouble();
    final sorted = [...pieces]
      ..sort((a, b) {
        final byArea = (b.lengthMm * b.widthMm).compareTo(
          a.lengthMm * a.widthMm,
        );
        return byArea != 0 ? byArea : b.longSide.compareTo(a.longSide);
      });

    final sheetBuilders = <_SheetBuilder>[];
    final unplaced = <String>[];
    for (final piece in sorted) {
      _Fit? fit;
      _SheetBuilder? chosenSheet;
      for (final sheet in sheetBuilders) {
        fit = sheet.bestFit(piece, kerfMm);
        if (fit != null) {
          chosenSheet = sheet;
          break;
        }
      }
      if (fit == null) {
        final sheet = _SheetBuilder(
          widthMm: boardWidth,
          heightMm: boardHeight,
          kerfMm: kerfMm,
        );
        fit = sheet.bestFit(piece, kerfMm);
        if (fit == null) {
          unplaced.add(piece.partId);
          continue;
        }
        chosenSheet = sheet;
        sheetBuilders.add(sheet);
      }
      chosenSheet!.place(piece, fit, kerfMm);
    }

    return MaterialNestingResult(
      materialId: material.id,
      materialName: material.name,
      sheets: [
        for (var index = 0; index < sheetBuilders.length; index++)
          NestingSheet(
            index: index + 1,
            board: board,
            placements: List.unmodifiable(sheetBuilders[index].placements),
          ),
      ],
      unplacedPartIds: List.unmodifiable(unplaced),
    );
  }
}

class _Rect {
  final double x;
  final double y;
  final double width;
  final double height;

  const _Rect(this.x, this.y, this.width, this.height);

  double get right => x + width;
  double get bottom => y + height;
  double get area => width * height;
}

class _Orientation {
  final double width;
  final double height;
  final bool rotated;

  const _Orientation(this.width, this.height, this.rotated);
}

class _Fit {
  final _Rect freeRect;
  final _Orientation orientation;
  final double shortSideWaste;
  final double areaWaste;

  const _Fit({
    required this.freeRect,
    required this.orientation,
    required this.shortSideWaste,
    required this.areaWaste,
  });
}

class _SheetBuilder {
  final double widthMm;
  final double heightMm;
  final double kerfMm;
  final List<_Rect> _freeRects;
  final List<NestingPlacement> placements = [];

  _SheetBuilder({
    required this.widthMm,
    required this.heightMm,
    required this.kerfMm,
  }) : _freeRects = [_Rect(0, 0, widthMm + kerfMm, heightMm + kerfMm)];

  _Fit? bestFit(NestingPiece piece, double kerf) {
    _Fit? best;
    for (final free in _freeRects) {
      for (final orientation in _orientations(piece)) {
        final allocatedWidth = orientation.width + kerf;
        final allocatedHeight = orientation.height + kerf;
        if (allocatedWidth > free.width || allocatedHeight > free.height) {
          continue;
        }
        final remainingWidth = free.width - allocatedWidth;
        final remainingHeight = free.height - allocatedHeight;
        final candidate = _Fit(
          freeRect: free,
          orientation: orientation,
          shortSideWaste: math.min(remainingWidth, remainingHeight),
          areaWaste: free.area - allocatedWidth * allocatedHeight,
        );
        if (best == null ||
            candidate.shortSideWaste < best.shortSideWaste ||
            (candidate.shortSideWaste == best.shortSideWaste &&
                candidate.areaWaste < best.areaWaste)) {
          best = candidate;
        }
      }
    }
    return best;
  }

  List<_Orientation> _orientations(NestingPiece piece) => switch (piece.grain) {
    GrainDirection.none => [
      _Orientation(piece.lengthMm, piece.widthMm, false),
      _Orientation(piece.widthMm, piece.lengthMm, true),
    ],
    GrainDirection.alongLength => [
      _Orientation(piece.lengthMm, piece.widthMm, false),
    ],
    GrainDirection.alongWidth => [
      _Orientation(piece.widthMm, piece.lengthMm, true),
    ],
  };

  void place(NestingPiece piece, _Fit fit, double kerf) {
    final used = _Rect(
      fit.freeRect.x,
      fit.freeRect.y,
      fit.orientation.width + kerf,
      fit.orientation.height + kerf,
    );
    final updated = <_Rect>[];
    for (final free in _freeRects) {
      if (!_intersects(free, used)) {
        updated.add(free);
        continue;
      }
      if (used.x > free.x) {
        updated.add(_Rect(free.x, free.y, used.x - free.x, free.height));
      }
      if (used.right < free.right) {
        updated.add(
          _Rect(used.right, free.y, free.right - used.right, free.height),
        );
      }
      if (used.y > free.y) {
        updated.add(_Rect(free.x, free.y, free.width, used.y - free.y));
      }
      if (used.bottom < free.bottom) {
        updated.add(
          _Rect(free.x, used.bottom, free.width, free.bottom - used.bottom),
        );
      }
    }
    _freeRects
      ..clear()
      ..addAll(_prune(updated));
    placements.add(
      NestingPlacement(
        partId: piece.partId,
        partName: piece.partName,
        xMm: used.x,
        yMm: used.y,
        widthMm: fit.orientation.width,
        heightMm: fit.orientation.height,
        rotated: fit.orientation.rotated,
      ),
    );
  }

  bool _intersects(_Rect first, _Rect second) =>
      second.x < first.right &&
      second.right > first.x &&
      second.y < first.bottom &&
      second.bottom > first.y;

  List<_Rect> _prune(List<_Rect> rects) {
    final candidates = rects
        .where((rect) => rect.width > 0.01 && rect.height > 0.01)
        .toList();
    final kept = <_Rect>[];
    for (var index = 0; index < candidates.length; index++) {
      var contained = false;
      for (var other = 0; other < candidates.length; other++) {
        if (index == other) continue;
        if (_contains(candidates[other], candidates[index])) {
          contained = true;
          break;
        }
      }
      if (!contained) kept.add(candidates[index]);
    }
    return kept;
  }

  bool _contains(_Rect outer, _Rect inner) =>
      inner.x >= outer.x - 0.001 &&
      inner.y >= outer.y - 0.001 &&
      inner.right <= outer.right + 0.001 &&
      inner.bottom <= outer.bottom + 0.001;
}
