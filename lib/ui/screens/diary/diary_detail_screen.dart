import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/diary_entry.dart';
import '../../../domain/providers/auth_provider.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  String _formatDate(DateTime date) {
    final months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final days = [
      '', 'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    final dayName = days[date.weekday];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayName, ${date.day} de ${months[date.month]} · $hour:$minute';
  }

  Future<void> _deleteEntry(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar entrada',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.deleteDiaryEntry(entry.id);
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada del diario',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444)),
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    entry.mood.color.withValues(alpha: isDark ? 0.2 : 0.1),
                    entry.mood.color.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: entry.mood.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(entry.mood.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    entry.mood.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: entry.mood.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(entry.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Texto de la entrada
            Text(
              'Lo que escribí',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                entry.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
            ),

            // Sección de gratitud
            if (entry.gratitude != null && entry.gratitude!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Gratitud',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.04),
                            Colors.white.withValues(alpha: 0.02),
                          ]
                        : [const Color(0xFFFEF9C3), const Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.prompt != null) ...[
                      Text(
                        entry.prompt!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      entry.gratitude!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF78350F),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}