import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../data/models/garden_item.dart';
import '../../../data/models/reward_service.dart';
import '../../../domain/providers/garden_provider.dart';
import 'dart:ui' as ui;
import './seed_icon.dart';

// ═════════════════════════════════════════════════════════════════════════════
// RewardDialog — muestra la recompensa ganada (semillas o item)
// ═════════════════════════════════════════════════════════════════════════════

class RewardDialog extends StatefulWidget {
  final RewardResult reward;
  final VoidCallback? onDismiss;

  const RewardDialog({
    super.key,
    required this.reward,
    this.onDismiss,
  });

  /// Muestra el dialog de recompensa
  static Future<void> show(BuildContext context, RewardResult reward) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => RewardDialog(
        reward: reward,
        onDismiss: () {
          context.read<GardenProvider>().consumePendingReward();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog>
    with TickerProviderStateMixin {

  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Generar partículas según tipo de recompensa
    _particles = List.generate(
      widget.reward.isItem ? 20 : 30,
      (_) => _Particle(_rng, widget.reward),
    );
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (widget.reward.isItem) {
      return _rarityColor(widget.reward.item!.rarity);
    }
    return const Color(0xFF10B981); // verde semillas
  }

  Color _rarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:    return const Color(0xFF6366F1);
      case ItemRarity.rare:      return const Color(0xFF3B82F6);
      case ItemRarity.epic:      return const Color(0xFF8B5CF6);
      case ItemRarity.legendary: return const Color(0xFFF59E0B);
      case ItemRarity.seasonal:  return const Color(0xFFEC4899);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Partículas de fondo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                    color: _accentColor,
                  ),
                ),
              ),
            ),

            // Card principal
            _buildCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono principal
          _buildMainIcon(),
          const SizedBox(height: 20),

          // Título
          Text(
            widget.reward.titleKey.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 10),

          // Mensaje
          _buildMessage(isDark),

          const SizedBox(height: 24),

          // Badge de recompensa
          _buildRewardBadge(isDark),

          const SizedBox(height: 24),

          // Botón
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: widget.onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'garden.reward.tapToContinue'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 8),

          // Hint jardín
          Text(
            '🌱 ${_gardenHint()}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }

  Widget _buildMainIcon() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [
            _accentColor.withOpacity(0.25 + _pulseCtrl.value * 0.1),
            _accentColor.withOpacity(0.05),
          ]),
          shape: BoxShape.circle,
          border: Border.all(
            color: _accentColor.withOpacity(0.4 + _pulseCtrl.value * 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.3 + _pulseCtrl.value * 0.15),
              blurRadius: 20 + _pulseCtrl.value * 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.reward.emoji,
            style: const TextStyle(fontSize: 46),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildMessage(bool isDark) {
    String message;
    if (widget.reward.isItem && widget.reward.item != null) {
      message = 'garden.reward.itemMessage'.tr(
        namedArgs: {'name': widget.reward.item!.nameKey.tr()},
      );
    } else {
      message = 'garden.reward.seedsMessage'.tr(
        namedArgs: {'count': '${widget.reward.seeds}'},
      );
    }

    return Text(
      message,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: isDark ? Colors.white70 : Colors.grey.shade700,
      ),
      textAlign: TextAlign.center,
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildRewardBadge(bool isDark) {
    if (widget.reward.isItem && widget.reward.item != null) {
      final item = widget.reward.item!;
      return _buildItemBadge(item, isDark);
    }
    return _buildSeedsBadge(isDark);
  }

  Widget _buildSeedsBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _accentColor.withOpacity(0.15),
          _accentColor.withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SeedIcon(size: 40, animated: true),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+${widget.reward.seeds}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _accentColor,
                  height: 1,
                ),
              ),
              Text(
                'garden.seeds'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: _accentColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    ).fadeIn(duration: 300.ms);
  }

  Widget _buildItemBadge(GardenItem item, bool isDark) {
  final rarityColor = _rarityColor(item.rarity);
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        rarityColor.withOpacity(0.15),
        rarityColor.withOpacity(0.05),
      ]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: rarityColor.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visual del item — ahora con imagen ilustrada
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: rarityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _itemVisualForReward(item, size: 40),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nameKey.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'garden.rarity.${item.rarity.name}'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rarityColor,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ).animate(delay: 400.ms).scale(
    begin: const Offset(0.8, 0.8),
    end: const Offset(1, 1),
    duration: 400.ms,
    curve: Curves.easeOutBack,
  ).fadeIn(duration: 300.ms);
}

/// Helper local: renderiza la imagen ilustrada del item con fallback a emoji.
/// Similar al de shop_screen pero sin dependencia externa.
Widget _itemVisualForReward(GardenItem item, {double size = 48}) {
  Widget visual;

  if (item.type == ItemType.plant) {
    final name = item.id.replaceFirst('plant_', '');
    visual = Image.asset(
      'assets/images/plants/${name}_4_adult.png',
      width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(item.emoji, style: TextStyle(fontSize: size * 0.9)),
    );
  } else if (item.type == ItemType.decoration) {
    final name = item.id.replaceFirst('deco_', '');
    visual = Image.asset(
      'assets/images/decorations/$name.png',
      width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(item.emoji, style: TextStyle(fontSize: size * 0.9)),
    );
  } else if (item.type == ItemType.booster) {
    final name = item.id.replaceFirst('boost_', '');
    visual = Image.asset(
      'assets/images/boosters/$name.png',
      width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(item.emoji, style: TextStyle(fontSize: size * 0.9)),
    );
  } else {
    visual = Text(item.emoji, style: TextStyle(fontSize: size * 0.9));
  }

  return SizedBox(width: size, height: size, child: visual);
}

  String _gardenHint() {
    if (widget.reward.isItem) {
      return 'garden.inventory'.tr();
    }
    final t = 'garden.subtitle'.tr();
    return t;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Partículas
// ═════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double wobble;
  final double wobbleSpeed;
  final double rotation;
  final String emoji;

  static const _seedEmojis = ['✨', '🌟', '⭐', '💫', '🌱'];
  static const _itemEmojis = ['✨', '💎', '🌟', '⭐', '🎁'];

  _Particle(math.Random rng, RewardResult reward)
      : x = rng.nextDouble(),
        startY = -0.05 - rng.nextDouble() * 0.2,
        size = 12 + rng.nextDouble() * 14,
        speed = 0.3 + rng.nextDouble() * 0.6,
        wobble = 0.03 + rng.nextDouble() * 0.04,
        wobbleSpeed = 2 + rng.nextDouble() * 3,
        rotation = rng.nextDouble() * math.pi * 2,
        emoji = reward.isItem
            ? _itemEmojis[rng.nextInt(_itemEmojis.length)]
            : _seedEmojis[rng.nextInt(_seedEmojis.length)];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.startY + progress * p.speed * 1.8;
      if (y > 1.1) continue;

      final x = p.x +
          math.sin(progress * p.wobbleSpeed * math.pi * 2) * p.wobble;

      final opacity = progress < 0.15
          ? progress / 0.15
          : progress > 0.65
              ? (1.0 - progress) / 0.35
              : 1.0;

      final textPainter = TextPainter(
  text: TextSpan(
    text: p.emoji,
    style: TextStyle(fontSize: p.size * opacity.clamp(0.3, 1.0)),
  ),
  textScaler: TextScaler.noScaling,
  textDirection: ui.TextDirection.ltr,
)..layout();

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.rotation + progress * 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}