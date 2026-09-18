@Tags(['branding'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brand_art.dart';

/// Genera el ícono de la app y los gráficos de la ficha de Play a partir del
/// arte dibujado con código (`brand_art.dart`), así que siempre coinciden con
/// la Lumi de la app.
///
///     flutter test tool/branding/generate_branding_test.dart
///
/// Salida en `branding/`. No es una prueba de verdad: es la herramienta que
/// exporta los PNG (Flutter no trae una forma más simple de rasterizar
/// widgets desde línea de comandos).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // La fuente del sistema para que el texto del gráfico no salga en cuadros
    final loader = FontLoader('Branding');
    for (final path in [r'C:\Windows\Fonts\segoeuib.ttf', r'C:\Windows\Fonts\segoeui.ttf']) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
      }
    }
    await loader.load();
  });

  Future<void> export(WidgetTester tester, Widget art, Size size, String name, {double pixelRatio = 1}) async {
    await tester.binding.setSurfaceSize(size);
    final key = GlobalKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Branding'),
            child: Center(
              child: RepaintBoundary(key: key, child: art),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Rasterizar y codificar a PNG necesita el motor de verdad: va en runAsync
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('branding/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      // ignore: avoid_print
      print('  branding/$name.png  ${(file.lengthSync() / 1024).toStringAsFixed(0)} KB');
    });
  }

  testWidgets('genera el ícono y los gráficos de marca', (tester) async {
    // Ícono cuadrado para Play (512) y para las tiendas / iOS (1024)
    await export(tester, const LumenIcon(size: 512), const Size(512, 512), 'icon_512');
    await export(tester, const LumenIcon(size: 512), const Size(512, 512), 'icon_1024', pixelRatio: 2);

    // Ícono adaptativo de Android: el sistema recorta hasta 25 % por lado, así
    // que el contenido va más chico y el fondo va aparte.
    await export(
      tester,
      const LumenIcon(size: 432, transparentBackground: true, contentScale: 0.62),
      const Size(432, 432),
      'adaptive_foreground',
    );
    await export(tester, const LumenIcon(size: 432, contentScale: 0), const Size(432, 432), 'adaptive_background');

    // Ícono monocromo (Android 13+, íconos con el color del sistema)
    await export(
      tester,
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: const LumenIcon(size: 432, transparentBackground: true, contentScale: 0.62),
      ),
      const Size(432, 432),
      'adaptive_monochrome',
    );

    // Gráfico de funciones de Play, en los dos idiomas de la ficha
    await export(
      tester,
      const LumenFeatureGraphic(
        tagline: 'Tu gimnasio emocional',
        subtitle: 'Lecciones · diario · respiración · jardín',
      ),
      const Size(1024, 500),
      'feature_graphic_es',
    );
    await export(
      tester,
      const LumenFeatureGraphic(
        tagline: 'Your emotional gym',
        subtitle: 'Lessons · journal · breathing · garden',
      ),
      const Size(1024, 500),
      'feature_graphic_en',
    );
  });
}
