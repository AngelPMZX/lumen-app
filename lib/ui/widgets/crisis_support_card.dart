import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/crisis/crisis_support_screen.dart';

/// Tarjeta discreta que ofrece ayuda cuando el home detecta varios días
/// difíciles seguidos. Tono de acompañamiento, nunca de alarma: no dice que
/// algo esté mal, solo deja la puerta abierta.
class CrisisSupportCard extends StatelessWidget {
  final bool isDark;

  /// Permite al usuario ocultarla por hoy.
  final VoidCallback? onDismiss;

  const CrisisSupportCard({
    super.key,
    required this.isDark,
    this.onDismiss,
  });

  static const _deep = Color(0xFF1E2A54);
  static const _soft = Color(0xFF6C8FE8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrisisSupportScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _soft.withValues(alpha: 0.18),
                      _deep.withValues(alpha: 0.3),
                    ]
                  : [
                      _soft.withValues(alpha: 0.12),
                      _soft.withValues(alpha: 0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _soft.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _soft.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volunteer_activism_rounded,
                        size: 19, color: isDark ? Colors.white : _deep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'crisis.card.title'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _deep,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.white38
                                : _deep.withValues(alpha: 0.35)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'crisis.card.message'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : _deep.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'crisis.card.cta'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _soft,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: _soft),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}
