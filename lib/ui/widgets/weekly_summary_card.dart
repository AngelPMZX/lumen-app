import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Aviso del Home: "Tu semana en Lumen está lista". Aparece domingo y lunes
/// hasta que se abre el resumen.
class WeeklySummaryCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const WeeklySummaryCard({
    super.key,
    required this.isDark,
    required this.onOpen,
    required this.onDismiss,
  });

  static const _violet = Color(0xFF8B5CF6);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _violet.withValues(alpha: isDark ? 0.35 : 0.18),
              _pink.withValues(alpha: isDark ? 0.2 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _violet.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 30))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1200.ms),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'summary.cardTitle'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'summary.cardSubtitle'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black26),
            ),
          ],
        ),
      ),
    );
  }
}
