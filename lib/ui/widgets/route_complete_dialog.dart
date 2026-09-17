import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/wellness_route.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/services/sound_service.dart';
import 'route_share_card.dart';

/// Celebración al completar una ruta, con la tarjeta lista para compartir.
class RouteCompleteDialog extends StatefulWidget {
  final WellnessRoute route;
  final DateTime completedAt;

  const RouteCompleteDialog({super.key, required this.route, required this.completedAt});

  static Future<void> show(BuildContext context, WellnessRoute route, {DateTime? completedAt}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'route_complete',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => RouteCompleteDialog(route: route, completedAt: completedAt ?? DateTime.now()),
      transitionBuilder: (_, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<RouteCompleteDialog> createState() => _RouteCompleteDialogState();
}

class _RouteCompleteDialogState extends State<RouteCompleteDialog> {
  final _cardKey = GlobalKey();
  late final ConfettiController _confetti;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.flip, volume: 0.7);

    final text = 'routeShare.shareText'.tr(namedArgs: {
      'route': widget.route.title,
      'emoji': widget.route.emoji,
    });
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 360×450 lógicos → 1080×1350 px
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw Exception('empty image');

      await SharePlus.instance.share(ShareParams(
        text: text,
        files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png')],
        fileNameOverrides: ['lumen_${widget.route.id}.png'],
      ));
      AnalyticsService.instance.routeCardShared(widget.route.id);
    } catch (e) {
      debugPrint('Share card error: $e');
      // Si no se puede compartir la imagen (p. ej. en algunos navegadores),
      // al menos se comparte el texto.
      try {
        await SharePlus.instance.share(ShareParams(text: text));
      } catch (_) {}
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    // La tarjeta se escala para caber, pero se exporta a su tamaño lógico fijo
    final scale = ((screen.width - 48) / RouteShareCard.width)
        .clamp(0.5, 1.0)
        .toDouble();
    final fitsHeight = (screen.height - 250) / RouteShareCard.height;
    final cardScale = scale < fitsHeight ? scale : fitsHeight.clamp(0.5, 1.0).toDouble();

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'routeShare.dialogTitle'.tr(),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.3, end: 0),
                const SizedBox(height: 16),
                SizedBox(
                  width: RouteShareCard.width * cardScale,
                  height: RouteShareCard.height * cardScale,
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: RouteShareCard(route: widget.route, completedAt: widget.completedAt),
                    ),
                  ),
                )
                    .animate()
                    .rotate(begin: -0.03, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -5, duration: 1800.ms, curve: Curves.easeInOut),
                const SizedBox(height: 10),
                Text(
                  'routeShare.privacy'.tr(),
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('common.close'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _sharing ? null : _share,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.ios_share_rounded),
                          label: Text('routeShare.share'.tr()),
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.route.color,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.25,
              colors: [widget.route.color, const Color(0xFFFBBF24), Colors.white, Colors.pinkAccent],
            ),
          ),
        ],
      ),
    );
  }
}
