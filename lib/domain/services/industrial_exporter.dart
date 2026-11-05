import 'dart:math' as math;

import '../entities/drilling_hole.dart';
import '../entities/furniture.dart';
import '../entities/part.dart';
import 'drilling_map_calculator.dart';

/// Exportador a formatos estándar de la industria (DXF, G-Code y CSV para seccionadoras).
class IndustrialExporter {
  const IndustrialExporter();

  /// Exporta el despiece completo a DXF (formato ASCII Release 12/2000 universal).
  /// Dibuja cada pieza como un rectángulo y añade los taladros como círculos concéntricos en la capa DRILL.
  String exportToDxf(Furniture furniture) {
    final drillingCalc = const DrillingMapCalculator();
    final patterns = drillingCalc.calculatePatterns(furniture);

    final sb = StringBuffer();
    // Cabecera DXF mínima
    sb.writeln('0\nSECTION\n2\nHEADER\n9\n\$ACADVER\n1\nAC1009\n0\nENDSEC');
    
    // Tablas y capas
    sb.writeln('0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n2');
    sb.writeln('0\nLAYER\n2\nOUTLINE\n70\n0\n62\n7\n6\nCONTINUOUS'); // Capa contorno
    sb.writeln('0\nLAYER\n2\nDRILL\n70\n0\n62\n1\n6\nCONTINUOUS');   // Capa taladros
    sb.writeln('0\nENDTAB\n0\nENDSEC');

    // Entidades
    sb.writeln('0\nSECTION\n2\nENTITIES');

    double currentXOffset = 0.0;
    const gap = 50.0; // Espacio entre piezas en el dibujo

    for (final part in furniture.parts) {
      final length = part.cutSize.length;
      final width = part.cutSize.width;

      // Dibujar polilínea rectangular de la pieza en capa OUTLINE
      _writeDxfPolylineRect(sb, currentXOffset, 0, width, length, 'OUTLINE');

      // Dibujar texto identificador
      _writeDxfText(sb, currentXOffset + 10, -25, 18, '${part.name} [${part.cutSize.thickness.round()}mm]');

      // Dibujar perforaciones
      final pattern = patterns[part.id];
      if (pattern != null) {
        for (final hole in pattern.holes) {
          final hx = currentXOffset + hole.xMm;
          final hy = hole.yMm;
          final r = hole.diameterMm / 2;
          _writeDxfCircle(sb, hx, hy, r, 'DRILL');
        }
      }

      currentXOffset += width + gap;
    }

    sb.writeln('0\nENDSEC\n0\nEOF');
    return sb.toString();
  }

  void _writeDxfPolylineRect(StringBuffer sb, double x, double y, double w, double h, String layer) {
    final pts = [
      [x, y],
      [x + w, y],
      [x + w, y + h],
      [x, y + h],
    ];

    sb.writeln('0\nPOLYLINE\n8\n$layer\n66\n1\n70\n1');
    for (final pt in pts) {
      sb.writeln('0\nVERTEX\n8\n$layer\n10\n${pt[0]}\n20\n${pt[1]}\n30\n0.0');
    }
    sb.writeln('0\nSEQEND');
  }

  void _writeDxfCircle(StringBuffer sb, double cx, double cy, double r, String layer) {
    sb.writeln('0\nCIRCLE\n8\n$layer\n10\n$cx\n20\n$cy\n30\n0.0\n40\n$r');
  }

  void _writeDxfText(StringBuffer sb, double x, double y, double h, String text) {
    sb.writeln('0\nTEXT\n8\nOUTLINE\n10\n$x\n20\n$y\n30\n0.0\n40\n$h\n1\n$text');
  }

  /// Exporta el mecanizado perimetral y taladros a G-Code estándar (ISO).
  String exportToGCode(Furniture furniture, {double feedRate = 3000, double spindleRpm = 18000}) {
    final drillingCalc = const DrillingMapCalculator();
    final patterns = drillingCalc.calculatePatterns(furniture);

    final sb = StringBuffer();
    sb.writeln('; MUEBLE MAESTRO - GENERADOR G-CODE CNC');
    sb.writeln('; Proyecto: ${furniture.name}');
    sb.writeln('; Unidades: Milímetros (G21)');
    sb.writeln('G21 ; Modo métrico');
    sb.writeln('G90 ; Coordenadas absolutas');
    sb.writeln('G17 ; Plano XY');
    sb.writeln('M03 S${spindleRpm.round()} ; Encendido de husillo');
    sb.writeln('G00 Z25.0 ; Altura segura de desplazamiento');
    sb.writeln('');

    int index = 1;
    for (final part in furniture.parts) {
      sb.writeln('; --- Pieza $index: ${part.name} (${part.cutSize.length}x${part.cutSize.width}x${part.cutSize.thickness} mm) ---');
      final w = part.cutSize.width;
      final l = part.cutSize.length;
      final depth = -(part.cutSize.thickness + 0.5); // traspaso 0.5 mm

      // Perfilado perimetral con fresa recta
      sb.writeln('G00 X0 Y0');
      sb.writeln('G00 Z2.0');
      sb.writeln('G01 Z$depth F1200');
      sb.writeln('G01 X$w F$feedRate');
      sb.writeln('G01 Y$l');
      sb.writeln('G01 X0');
      sb.writeln('G01 Y0');
      sb.writeln('G00 Z25.0');

      // Ciclos de taladrado (G81)
      final pattern = patterns[part.id];
      if (pattern != null && pattern.holes.isNotEmpty) {
        sb.writeln('; Perforaciones de la pieza:');
        for (final hole in pattern.holes) {
          final hDepth = -hole.depthMm;
          sb.writeln('G00 X${hole.xMm} Y${hole.yMm}');
          sb.writeln('G00 Z2.0');
          sb.writeln('G01 Z$hDepth F800 ; ${hole.description}');
          sb.writeln('G00 Z5.0');
        }
        sb.writeln('G00 Z25.0');
      }

      sb.writeln('');
      index++;
    }

    sb.writeln('M05 ; Apagar husillo');
    sb.writeln('G00 Z50.0');
    sb.writeln('G00 X0 Y0');
    sb.writeln('M30 ; Fin de programa');

    return sb.toString();
  }

  /// Exporta CSV estándar de corte y canteado listo para software de seccionadoras (ej. CorteX, Opticut, Leitz).
  String exportToCutListCsv(Furniture furniture) {
    final sb = StringBuffer();
    sb.writeln('ID,Pieza,Cantidad,Largo(mm),Ancho(mm),Espesor(mm),Material,Veta,Canto_Largo1,Canto_Largo2,Canto_Ancho1,Canto_Ancho2');

    for (final part in furniture.parts) {
      final edgeL1 = part.edgeBanding[PanelEdge.longEdge1] != null ? 'SI' : 'NO';
      final edgeL2 = part.edgeBanding[PanelEdge.longEdge2] != null ? 'SI' : 'NO';
      final edgeS1 = part.edgeBanding[PanelEdge.shortEdge1] != null ? 'SI' : 'NO';
      final edgeS2 = part.edgeBanding[PanelEdge.shortEdge2] != null ? 'SI' : 'NO';

      sb.writeln('${part.id},"${part.name}",1,${part.cutSize.length},${part.cutSize.width},${part.cutSize.thickness},"${part.materialId}",${part.grain.name},$edgeL1,$edgeL2,$edgeS1,$edgeS2');
    }

    return sb.toString();
  }
}
