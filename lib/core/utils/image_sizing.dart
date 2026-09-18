import 'package:flutter/widgets.dart';

/// Cuántos píxeles reales hace falta decodificar para una imagen que se va a
/// ver a [logical] dp de ancho.
///
/// **Siempre** hay que pasarle el resultado a `Image.asset(cacheWidth: ...)`.
/// Sin eso Flutter decodifica el archivo a su tamaño original y lo guarda así
/// en la caché de imágenes. Las ilustraciones del jardín son de 2048×2048: son
/// 250 KB en disco, pero **16 MB en memoria cada una**, aunque la planta se vea
/// a 100 dp. Con el jardín lleno eso desborda la caché (100 MB), obliga a
/// decodificar las mismas imágenes una y otra vez al desplazarse, y deja la
/// app tan grande que Android la mata en cuanto pasa a segundo plano.
///
/// A 100 dp en un teléfono de 3x se decodifican 300 px: 0.36 MB en vez de 16.
int decodePixels(BuildContext context, double logical, {int max = 1536}) {
  final ratio = MediaQuery.devicePixelRatioOf(context);
  final pixels = (logical * ratio).ceil();
  // Se redondea hacia arriba en pasos de 64 px: los huecos del jardín tienen
  // escalas distintas, y sin esto la misma planta se decodificaría y se
  // guardaría en caché una vez por cada tamaño ligeramente diferente.
  final stepped = ((pixels + _step - 1) ~/ _step) * _step;
  return stepped.clamp(1, max);
}

const int _step = 64;
