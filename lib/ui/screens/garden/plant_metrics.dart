// GENERADO por tools/images/measure_plants.py — no editar a mano.
//
// Dónde se apoya el dibujo de cada etapa dentro de su lienzo, ya convertido a
// fracciones del cuadrado en que se pinta (`BoxFit.contain`). El jardín las
// usa para que todas las etapas de una planta se apoyen en la misma línea de
// tierra: sin esto la planta saltaba al crecer, porque cada ilustración
// reparte su espacio transparente a su manera.

/// Dónde cae el dibujo de una ilustración dentro del cuadrado que la contiene.
class PlantMetrics {
  /// Borde superior del dibujo (0 arriba, 1 abajo).
  final double topY;

  /// Borde inferior del dibujo: la línea de la tierra.
  final double baseY;

  /// Centro horizontal del dibujo (0.5 = centrado en su lienzo).
  final double centerX;

  const PlantMetrics({
    required this.topY,
    required this.baseY,
    required this.centerX,
  });

  /// Centro vertical del dibujo, para medallones y vitrinas (ahí no hay
  /// suelo: lo que molesta es el aire de más arriba o abajo).
  double get centerY => (topY + baseY) / 2;
}

/// Medidas por nombre de archivo, sin carpeta ni extensión
/// (`bamboo_4_adult`).
const Map<String, PlantMetrics> kPlantMetrics = {
  'bamboo_1_seed': PlantMetrics(topY: 0.4473, baseY: 0.9062, centerX: 0.4863),
  'bamboo_2_sprout': PlantMetrics(topY: 0.1118, baseY: 0.9062, centerX: 0.4863),
  'bamboo_3_young': PlantMetrics(topY: 0.0996, baseY: 0.9062, centerX: 0.4868),
  'bamboo_4_adult': PlantMetrics(topY: 0.0879, baseY: 0.9551, centerX: 0.5059),
  'cactus_1_seed': PlantMetrics(topY: 0.4966, baseY: 0.9058, centerX: 0.4863),
  'cactus_2_sprout': PlantMetrics(topY: 0.4614, baseY: 0.9053, centerX: 0.4866),
  'cactus_3_young': PlantMetrics(topY: 0.2495, baseY: 0.8877, centerX: 0.4883),
  'cactus_4_adult': PlantMetrics(topY: 0.1289, baseY: 0.9058, centerX: 0.4866),
  'cherry_1_seed': PlantMetrics(topY: 0.6152, baseY: 0.9551, centerX: 0.4900),
  'cherry_2_sprout': PlantMetrics(topY: 0.3892, baseY: 0.9551, centerX: 0.4900),
  'cherry_3_young': PlantMetrics(topY: 0.0811, baseY: 0.9551, centerX: 0.4900),
  'cherry_4_adult': PlantMetrics(topY: 0.0615, baseY: 0.9551, centerX: 0.4995),
  'christmas_tree_1_seed': PlantMetrics(topY: 0.3020, baseY: 0.8100, centerX: 0.5070),
  'christmas_tree_2_sprout': PlantMetrics(topY: 0.2120, baseY: 0.7600, centerX: 0.5000),
  'christmas_tree_3_young': PlantMetrics(topY: 0.0820, baseY: 0.9300, centerX: 0.5000),
  'christmas_tree_4_adult': PlantMetrics(topY: 0.0560, baseY: 0.9400, centerX: 0.5000),
  'clover_1_seed': PlantMetrics(topY: 0.3564, baseY: 0.7266, centerX: 0.5122),
  'clover_2_sprout': PlantMetrics(topY: 0.2397, baseY: 0.7241, centerX: 0.5103),
  'clover_3_young': PlantMetrics(topY: 0.2305, baseY: 0.7236, centerX: 0.4866),
  'clover_4_adult': PlantMetrics(topY: 0.2173, baseY: 0.9053, centerX: 0.4868),
  'lotus_1_seed': PlantMetrics(topY: 0.3994, baseY: 0.6567, centerX: 0.4988),
  'lotus_2_sprout': PlantMetrics(topY: 0.1953, baseY: 0.8604, centerX: 0.4883),
  'lotus_3_young': PlantMetrics(topY: 0.2300, baseY: 0.8628, centerX: 0.4880),
  'lotus_4_adult': PlantMetrics(topY: 0.1665, baseY: 0.8643, centerX: 0.5044),
  'pumpkin_1_seed': PlantMetrics(topY: 0.3480, baseY: 0.7200, centerX: 0.5000),
  'pumpkin_2_sprout': PlantMetrics(topY: 0.2082, baseY: 0.8180, centerX: 0.5008),
  'pumpkin_3_young': PlantMetrics(topY: 0.1980, baseY: 0.8980, centerX: 0.5090),
  'pumpkin_4_adult': PlantMetrics(topY: 0.1560, baseY: 0.8980, centerX: 0.5100),
};
