import 'package:flutter/material.dart';

/// Marco de una captura para la ficha de Play: fondo de color, un título
/// arriba y la pantalla de la app abajo, con esquinas redondeadas.
///
/// El lienzo mide 540×1080 lógicos y se exporta a 1080×2160 px (Play pide
/// como máximo una proporción de 2:1).
class StoreShot extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;

  /// La pantalla de la app, dibujada a 390×700 lógicos.
  final Widget screen;

  static const canvas = Size(540, 1080);
  static const screenSize = Size(390, 700);

  const StoreShot({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvas.width,
      height: canvas.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
          DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Shot', fontFamilyFallback: ['ShotEmoji'], color: Colors.white),
            child: Column(
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: SizedBox(
                        width: 456,
                        height: 818,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox(
                            width: screenSize.width,
                            height: screenSize.height,
                            child: MediaQuery(
                              data: const MediaQueryData(
                                size: screenSize,
                                devicePixelRatio: 1,
                                padding: EdgeInsets.only(top: 26),
                                disableAnimations: true,
                              ),
                              child: screen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}
