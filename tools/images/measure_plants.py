"""Mide dónde se apoya cada ilustración de planta dentro de su lienzo y
escribe `lib/ui/screens/garden/plant_metrics.dart`.

Las ilustraciones traen mucho aire transparente, y cada etapa lo reparte
distinto: la base del dibujo (la tierra) cae entre el 66% y el 96% del alto
del lienzo según el archivo. Como en el jardín todas se pintan centradas en un
mismo cuadrado, al crecer la planta saltaba y la tierra quedaba fuera del
hueco. Con estas medidas el jardín apoya todas las etapas en la misma línea.

Uso:

    python tools/images/measure_plants.py

Hay que volver a correrlo al añadir o cambiar una ilustración de planta;
`test/ui/garden_plant_metrics_test.dart` falla si falta alguna.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLANTS = os.path.join(ROOT, 'assets', 'images', 'plants')
OUT = os.path.join(ROOT, 'lib', 'ui', 'screens', 'garden', 'plant_metrics.dart')

# Por debajo de este alfa se considera transparente: los bordes suaves de la
# acuarela dejan un halo casi invisible que, contado, agranda el dibujo.
ALPHA = 12

HEADER = '''// GENERADO por tools/images/measure_plants.py — no editar a mano.
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
'''


def measure(path):
    """(topY, baseY, centerX) dentro del cuadrado dibujado, con BoxFit.contain."""
    with Image.open(path) as im:
        im = im.convert('RGBA')
        w, h = im.size
        mask = im.getchannel('A').point(lambda a: 255 if a > ALPHA else 0)
        box = mask.getbbox()
    if box is None:
        return None
    left, top, right, bottom = box
    l, r = left / w, right / w
    t, b = top / h, bottom / h
    cx = (l + r) / 2
    if w >= h:
        # contain ajusta al ancho: el alto dibujado ocupa h/w del cuadrado.
        drawn = h / w
        pad = (1 - drawn) / 2
        return (pad + t * drawn, pad + b * drawn, cx)
    # contain ajusta al alto: el ancho dibujado ocupa w/h del cuadrado.
    drawn = w / h
    return (t, b, (1 - drawn) / 2 + cx * drawn)


def main():
    rows = []
    for name in sorted(os.listdir(PLANTS)):
        if not name.endswith('.webp'):
            continue
        result = measure(os.path.join(PLANTS, name))
        if result is None:
            print('  sin dibujo, se salta: ' + name)
            continue
        top_y, base_y, center_x = result
        rows.append((name.rsplit('.', 1)[0], top_y, base_y, center_x))

    lines = [HEADER]
    for key, top_y, base_y, center_x in rows:
        lines.append(
            "  '%s': PlantMetrics(topY: %.4f, baseY: %.4f, centerX: %.4f),\n"
            % (key, top_y, base_y, center_x)
        )
    lines.append('};\n')
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(''.join(lines))

    print('%d ilustraciones medidas -> %s' % (len(rows), os.path.relpath(OUT, ROOT)))
    plants = {}
    for key, _, base_y, _ in rows:
        plant = '_'.join(key.split('_')[:-2])
        plants.setdefault(plant, []).append(base_y)
    for plant, bases in sorted(plants.items()):
        print('  %-16s la tierra saltaba %.0f%% del alto entre etapas'
              % (plant, (max(bases) - min(bases)) * 100))


if __name__ == '__main__':
    main()
