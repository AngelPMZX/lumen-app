import 'dart:math' as math;

import '../../../data/models/garden_item.dart';
import '../../../data/models/lumi.dart';

/// Geometría del fondo del jardín. Todas las ilustraciones miden 1536×2752 y
/// se muestran con `BoxFit.cover`, así que parte puede quedar recortada según
/// la pantalla. Las posiciones se guardan como fracción de la ilustración
/// (no de la pantalla) para que plantas y decoraciones no se muevan de su
/// lugar en teléfonos con otra proporción.
class GardenLayout {
  GardenLayout._();

  static const double bgWidth = 1536;
  static const double bgHeight = 2752;

  /// Cuánto más alto que ancho es el fondo: convierte distancias verticales
  /// a la misma unidad que las horizontales.
  static const double aspect = bgHeight / bgWidth;

  static double _scale(double viewW, double viewH) =>
      math.max(viewW / bgWidth, viewH / bgHeight);

  /// Punto de la ilustración (fracción 0-1) → píxeles lógicos en pantalla.
  static (double, double) toScreen(double fx, double fy, double viewW, double viewH) {
    final s = _scale(viewW, viewH);
    final w = bgWidth * s;
    final h = bgHeight * s;
    return ((viewW - w) / 2 + fx * w, (viewH - h) / 2 + fy * h);
  }

  /// Píxeles lógicos en pantalla → punto de la ilustración (fracción 0-1).
  static (double, double) toBackground(double x, double y, double viewW, double viewH) {
    final s = _scale(viewW, viewH);
    final w = bgWidth * s;
    final h = bgHeight * s;
    return ((x - (viewW - w) / 2) / w, (y - (viewH - h) / 2) / h);
  }

  /// Parte visible de la ilustración, en fracciones: (izq, arriba, der, abajo).
  static (double, double, double, double) visibleArea(double viewW, double viewH) {
    final (l, t) = toBackground(0, 0, viewW, viewH);
    final (r, b) = toBackground(viewW, viewH, viewW, viewH);
    return (l, t, r, b);
  }

  /// Distancia entre dos puntos de la ilustración, en fracciones del ancho.
  static double distance(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = (ay - by) * aspect;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// Por qué no se puede soltar una decoración en un punto.
enum DecoPlacement { ok, nearPlant, nearDeco, outside }

class GardenRules {
  GardenRules._();

  /// Radio libre alrededor de un hueco de planta (fracción del ancho).
  static const double plantClearance = 0.15;

  /// Separación mínima entre decoraciones.
  static const double decoClearance = 0.11;

  /// Revisa si una decoración cabe en (fx, fy). [slots] y [decos] son puntos
  /// de la ilustración; [visible] es el área visible (izq, arriba, der, abajo).
  static DecoPlacement checkDecoration({
    required double fx,
    required double fy,
    required List<(double, double)> slots,
    required List<(double, double)> decos,
    required (double, double, double, double) visible,
  }) {
    final (l, t, r, b) = visible;
    const margin = 0.03;
    if (fx < l + margin || fx > r - margin || fy < t + margin || fy > b - margin) {
      return DecoPlacement.outside;
    }
    for (final (sx, sy) in slots) {
      if (GardenLayout.distance(fx, fy, sx, sy) < plantClearance) return DecoPlacement.nearPlant;
    }
    for (final (dx, dy) in decos) {
      if (GardenLayout.distance(fx, fy, dx, dy) < decoClearance) return DecoPlacement.nearDeco;
    }
    return DecoPlacement.ok;
  }

  /// Nivel de brillo (sonido y destellos) según la rareza: 0 común o raro,
  /// 1 épico, 2 legendario o de temporada.
  static int shineLevel(ItemRarity rarity) => switch (rarity) {
        ItemRarity.common || ItemRarity.rare => 0,
        ItemRarity.epic => 1,
        ItemRarity.legendary || ItemRarity.seasonal => 2,
      };

  /// Tiempo que falta como (horas, minutos), redondeando minutos hacia arriba
  /// para no mostrar "0m" cuando aún faltan segundos.
  static (int, int) hoursMinutes(Duration d) {
    final totalMinutes = (d.inSeconds / 60).ceil();
    return (totalMinutes ~/ 60, totalMinutes % 60);
  }
}

/// Lo que ve Lumi en el jardín en este momento.
class GardenSnapshot {
  final bool planting;
  final bool boosting;
  final bool draggingDeco;
  final int plants;
  final int readyToHarvest;
  final int growing;
  final int seedsInInventory;
  final int boostersInInventory;
  final int decosInInventory;

  const GardenSnapshot({
    this.planting = false,
    this.boosting = false,
    this.draggingDeco = false,
    this.plants = 0,
    this.readyToHarvest = 0,
    this.growing = 0,
    this.seedsInInventory = 0,
    this.boostersInInventory = 0,
    this.decosInInventory = 0,
  });
}

/// Qué dice Lumi en el jardín: lo más útil primero, sin presionar.
class GardenLumi {
  GardenLumi._();

  static LumiLine lineFor(GardenSnapshot s) {
    if (s.planting) return const LumiLine('garden.lumi.planting', LumiMood.curious);
    if (s.boosting) return const LumiLine('garden.lumi.boosting', LumiMood.excited);
    if (s.draggingDeco) return const LumiLine('garden.lumi.dragging', LumiMood.curious);
    if (s.readyToHarvest > 0) {
      return LumiLine(
        s.readyToHarvest == 1 ? 'garden.lumi.harvestOne' : 'garden.lumi.harvestMany',
        LumiMood.excited,
        {'count': '${s.readyToHarvest}'},
      );
    }
    if (s.plants == 0) {
      return s.seedsInInventory > 0
          ? const LumiLine('garden.lumi.emptyWithSeeds', LumiMood.happy)
          : const LumiLine('garden.lumi.emptyNoSeeds', LumiMood.caring);
    }
    if (s.growing > 0 && s.boostersInInventory > 0) {
      return const LumiLine('garden.lumi.growingBoosters', LumiMood.happy);
    }
    if (s.decosInInventory > 0) return const LumiLine('garden.lumi.decoHint', LumiMood.curious);
    if (s.growing > 0) return const LumiLine('garden.lumi.growing', LumiMood.calm);
    return const LumiLine('garden.lumi.allHarvested', LumiMood.proud);
  }
}
