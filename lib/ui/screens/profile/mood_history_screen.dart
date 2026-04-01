import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/animated_particles_background.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  Map<DateTime, MoodType> _monthMoods = {};
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  String _tr(
    String key, {
    String? fallback,
    Map<String, String>? namedArgs,
  }) {
    final value = key.tr(namedArgs: namedArgs ?? const <String, String>{});
    return value == key ? (fallback ?? key) : value;
  }

  String _localeString() {
    final locale = context.locale;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  String _formatMonthYear() {
    final formatted = DateFormat('MMMM yyyy', _localeString()).format(
      _currentMonth,
    );
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _moodLabel(MoodType mood) {
    return _tr(
      'mood.${mood.name}',
      fallback: mood.label,
    );
  }

  Future<void> _loadMonth() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final end = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        0,
        23,
        59,
      );
      final moods = await auth.getDiaryCalendarMoods(start, end);
      if (mounted) {
        setState(() {
          _monthMoods = moods;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1),
    );
    _loadMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
      return;
    }
    setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1),
    );
    _loadMonth();
  }

  List<Map<String, String>> _getTips(MoodType? mood) {
    if (mood == null) return [];

    switch (mood) {
      case MoodType.happy:
        return [
          {
            'emoji': '🌟',
            'title': _tr(
              'moodHistory.tips.happy.0.title',
              fallback: 'Comparte tu alegría',
            ),
            'desc': _tr(
              'moodHistory.tips.happy.0.desc',
              fallback:
                  'La felicidad se multiplica cuando la compartes con otros.',
            ),
          },
          {
            'emoji': '📝',
            'title': _tr(
              'moodHistory.tips.happy.1.title',
              fallback: 'Anota lo que te hace feliz',
            ),
            'desc': _tr(
              'moodHistory.tips.happy.1.desc',
              fallback:
                  'Registrar momentos felices te ayuda a recrearlos.',
            ),
          },
          {
            'emoji': '🙏',
            'title': _tr(
              'moodHistory.tips.happy.2.title',
              fallback: 'Practica gratitud',
            ),
            'desc': _tr(
              'moodHistory.tips.happy.2.desc',
              fallback:
                  'Agradecer lo bueno fortalece las emociones positivas.',
            ),
          },
        ];
      case MoodType.excited:
        return [
          {
            'emoji': '🎯',
            'title': _tr(
              'moodHistory.tips.excited.0.title',
              fallback: 'Canaliza la energía',
            ),
            'desc': _tr(
              'moodHistory.tips.excited.0.desc',
              fallback:
                  'Aprovecha este impulso para proyectos creativos o metas.',
            ),
          },
          {
            'emoji': '📸',
            'title': _tr(
              'moodHistory.tips.excited.1.title',
              fallback: 'Captura el momento',
            ),
            'desc': _tr(
              'moodHistory.tips.excited.1.desc',
              fallback:
                  'Guarda fotos o escribe sobre esta emoción para recordarla.',
            ),
          },
          {
            'emoji': '🤝',
            'title': _tr(
              'moodHistory.tips.excited.2.title',
              fallback: 'Inspira a otros',
            ),
            'desc': _tr(
              'moodHistory.tips.excited.2.desc',
              fallback:
                  'Tu entusiasmo puede contagiar a quienes te rodean.',
            ),
          },
        ];
      case MoodType.grateful:
        return [
          {
            'emoji': '💌',
            'title': _tr(
              'moodHistory.tips.grateful.0.title',
              fallback: 'Expresa tu gratitud',
            ),
            'desc': _tr(
              'moodHistory.tips.grateful.0.desc',
              fallback: 'Dile a alguien lo importante que es para ti.',
            ),
          },
          {
            'emoji': '📖',
            'title': _tr(
              'moodHistory.tips.grateful.1.title',
              fallback: 'Lleva un diario de gratitud',
            ),
            'desc': _tr(
              'moodHistory.tips.grateful.1.desc',
              fallback:
                  'Escribe 3 cosas por las que estás agradecido cada día.',
            ),
          },
          {
            'emoji': '🌱',
            'title': _tr(
              'moodHistory.tips.grateful.2.title',
              fallback: 'Cultiva esta emoción',
            ),
            'desc': _tr(
              'moodHistory.tips.grateful.2.desc',
              fallback:
                  'La gratitud constante mejora tu bienestar general.',
            ),
          },
        ];
      case MoodType.calm:
        return [
          {
            'emoji': '🧘',
            'title': _tr(
              'moodHistory.tips.calm.0.title',
              fallback: 'Profundiza la calma',
            ),
            'desc': _tr(
              'moodHistory.tips.calm.0.desc',
              fallback:
                  'Medita 5 minutos para mantener este estado de paz.',
            ),
          },
          {
            'emoji': '🌿',
            'title': _tr(
              'moodHistory.tips.calm.1.title',
              fallback: 'Conecta con la naturaleza',
            ),
            'desc': _tr(
              'moodHistory.tips.calm.1.desc',
              fallback: 'Un paseo tranquilo refuerza la serenidad.',
            ),
          },
          {
            'emoji': '📚',
            'title': _tr(
              'moodHistory.tips.calm.2.title',
              fallback: 'Lee algo inspirador',
            ),
            'desc': _tr(
              'moodHistory.tips.calm.2.desc',
              fallback:
                  'La tranquilidad es ideal para absorber conocimiento.',
            ),
          },
        ];
      case MoodType.neutral:
        return [
          {
            'emoji': '🎨',
            'title': _tr(
              'moodHistory.tips.neutral.0.title',
              fallback: 'Prueba algo nuevo',
            ),
            'desc': _tr(
              'moodHistory.tips.neutral.0.desc',
              fallback:
                  'Un día neutral es perfecto para explorar nuevas actividades.',
            ),
          },
          {
            'emoji': '💪',
            'title': _tr(
              'moodHistory.tips.neutral.1.title',
              fallback: 'Haz ejercicio ligero',
            ),
            'desc': _tr(
              'moodHistory.tips.neutral.1.desc',
              fallback:
                  'El movimiento puede elevar tu estado de ánimo naturalmente.',
            ),
          },
          {
            'emoji': '🎵',
            'title': _tr(
              'moodHistory.tips.neutral.2.title',
              fallback: 'Escucha música',
            ),
            'desc': _tr(
              'moodHistory.tips.neutral.2.desc',
              fallback:
                  'La música que te gusta puede transformar tu día.',
            ),
          },
        ];
      case MoodType.tired:
        return [
          {
            'emoji': '😴',
            'title': _tr(
              'moodHistory.tips.tired.0.title',
              fallback: 'Descansa sin culpa',
            ),
            'desc': _tr(
              'moodHistory.tips.tired.0.desc',
              fallback:
                  'Tu cuerpo necesita recuperarse. Permítete descansar.',
            ),
          },
          {
            'emoji': '💧',
            'title': _tr(
              'moodHistory.tips.tired.1.title',
              fallback: 'Hidrátate bien',
            ),
            'desc': _tr(
              'moodHistory.tips.tired.1.desc',
              fallback:
                  'La deshidratación aumenta la fatiga. Toma agua.',
            ),
          },
          {
            'emoji': '🌙',
            'title': _tr(
              'moodHistory.tips.tired.2.title',
              fallback: 'Mejora tu sueño',
            ),
            'desc': _tr(
              'moodHistory.tips.tired.2.desc',
              fallback:
                  'Evita pantallas 1 hora antes de dormir.',
            ),
          },
        ];
      case MoodType.bored:
        return [
          {
            'emoji': '🎮',
            'title': _tr(
              'moodHistory.tips.bored.0.title',
              fallback: 'Prueba un hobby nuevo',
            ),
            'desc': _tr(
              'moodHistory.tips.bored.0.desc',
              fallback:
                  'Pintar, cocinar, jardinería... hay mucho por descubrir.',
            ),
          },
          {
            'emoji': '📱',
            'title': _tr(
              'moodHistory.tips.bored.1.title',
              fallback: 'Llama a un amigo',
            ),
            'desc': _tr(
              'moodHistory.tips.bored.1.desc',
              fallback:
                  'Una conversación puede cambiar completamente tu día.',
            ),
          },
          {
            'emoji': '🚶',
            'title': _tr(
              'moodHistory.tips.bored.2.title',
              fallback: 'Sal a caminar',
            ),
            'desc': _tr(
              'moodHistory.tips.bored.2.desc',
              fallback:
                  'Cambiar de ambiente rompe la monotonía.',
            ),
          },
        ];
      case MoodType.sad:
        return [
          {
            'emoji': '💙',
            'title': _tr(
              'moodHistory.tips.sad.0.title',
              fallback: 'Está bien sentirse triste',
            ),
            'desc': _tr(
              'moodHistory.tips.sad.0.desc',
              fallback:
                  'Permitirte sentir es el primer paso para sanar.',
            ),
          },
          {
            'emoji': '🤗',
            'title': _tr(
              'moodHistory.tips.sad.1.title',
              fallback: 'Busca apoyo',
            ),
            'desc': _tr(
              'moodHistory.tips.sad.1.desc',
              fallback:
                  'Habla con alguien de confianza sobre cómo te sientes.',
            ),
          },
          {
            'emoji': '🌤️',
            'title': _tr(
              'moodHistory.tips.sad.2.title',
              fallback: 'Esto también pasará',
            ),
            'desc': _tr(
              'moodHistory.tips.sad.2.desc',
              fallback:
                  'Los días difíciles hacen más valiosos los buenos momentos.',
            ),
          },
        ];
      case MoodType.anxious:
        return [
          {
            'emoji': '🫁',
            'title': _tr(
              'moodHistory.tips.anxious.0.title',
              fallback: 'Respiración 4-7-8',
            ),
            'desc': _tr(
              'moodHistory.tips.anxious.0.desc',
              fallback:
                  'Inhala 4s, sostén 7s, exhala 8s. Repite 4 veces.',
            ),
          },
          {
            'emoji': '✍️',
            'title': _tr(
              'moodHistory.tips.anxious.1.title',
              fallback: 'Escribe tus preocupaciones',
            ),
            'desc': _tr(
              'moodHistory.tips.anxious.1.desc',
              fallback:
                  'Sacar los pensamientos al papel reduce la ansiedad.',
            ),
          },
          {
            'emoji': '🧊',
            'title': _tr(
              'moodHistory.tips.anxious.2.title',
              fallback: 'Técnica de grounding',
            ),
            'desc': _tr(
              'moodHistory.tips.anxious.2.desc',
              fallback:
                  'Nombra 5 cosas que ves, 4 que tocas, 3 que oyes.',
            ),
          },
        ];
      case MoodType.angry:
        return [
          {
            'emoji': '⏸️',
            'title': _tr(
              'moodHistory.tips.angry.0.title',
              fallback: 'Haz una pausa',
            ),
            'desc': _tr(
              'moodHistory.tips.angry.0.desc',
              fallback:
                  'Cuenta hasta 10 antes de reaccionar. Date espacio.',
            ),
          },
          {
            'emoji': '🏃',
            'title': _tr(
              'moodHistory.tips.angry.1.title',
              fallback: 'Mueve el cuerpo',
            ),
            'desc': _tr(
              'moodHistory.tips.angry.1.desc',
              fallback:
                  'El ejercicio físico libera la tensión acumulada.',
            ),
          },
          {
            'emoji': '📝',
            'title': _tr(
              'moodHistory.tips.angry.2.title',
              fallback: 'Escribe sin filtro',
            ),
            'desc': _tr(
              'moodHistory.tips.angry.2.desc',
              fallback:
                  'Vacía tus pensamientos en papel. No tienes que mostrárselo a nadie.',
            ),
          },
        ];
      case MoodType.stressed:
        return [
          {
            'emoji': '📋',
            'title': _tr(
              'moodHistory.tips.stressed.0.title',
              fallback: 'Prioriza tareas',
            ),
            'desc': _tr(
              'moodHistory.tips.stressed.0.desc',
              fallback:
                  'Haz una lista y enfócate en lo más importante primero.',
            ),
          },
          {
            'emoji': '🧘',
            'title': _tr(
              'moodHistory.tips.stressed.1.title',
              fallback: 'Micro-descansos',
            ),
            'desc': _tr(
              'moodHistory.tips.stressed.1.desc',
              fallback:
                  'Cada 25 min, toma 5 min de pausa. Tu mente lo agradecerá.',
            ),
          },
          {
            'emoji': '🎶',
            'title': _tr(
              'moodHistory.tips.stressed.2.title',
              fallback: 'Música relajante',
            ),
            'desc': _tr(
              'moodHistory.tips.stressed.2.desc',
              fallback:
                  'Sonidos de la naturaleza o lo-fi pueden reducir el estrés.',
            ),
          },
        ];
      case MoodType.lonely:
        return [
          {
            'emoji': '💬',
            'title': _tr(
              'moodHistory.tips.lonely.0.title',
              fallback: 'Conecta con alguien',
            ),
            'desc': _tr(
              'moodHistory.tips.lonely.0.desc',
              fallback:
                  'Envía un mensaje a un amigo o familiar. No estás solo.',
            ),
          },
          {
            'emoji': '🐾',
            'title': _tr(
              'moodHistory.tips.lonely.1.title',
              fallback: 'Compañía de mascotas',
            ),
            'desc': _tr(
              'moodHistory.tips.lonely.1.desc',
              fallback:
                  'Si tienes mascota, dedícale tiempo. Su amor es incondicional.',
            ),
          },
          {
            'emoji': '🌐',
            'title': _tr(
              'moodHistory.tips.lonely.2.title',
              fallback: 'Únete a una comunidad',
            ),
            'desc': _tr(
              'moodHistory.tips.lonely.2.desc',
              fallback:
                  'Hay grupos de intereses donde puedes conocer gente nueva.',
            ),
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final moodCounts = <MoodType, int>{};
    for (final mood in _monthMoods.values) {
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalMoods = _monthMoods.length;
    final dominantMood = sortedMoods.isNotEmpty ? sortedMoods.first.key : null;
    final tips = _getTips(dominantMood);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr('moodHistory.title', fallback: 'Historial de ánimo'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12,
            maxShootingStars: isDark ? 1 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : (dominantMood?.color ?? const Color(0xFFEC4899))
                    .withValues(alpha: 0.1),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        _formatMonthYear(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _currentMonth.month == DateTime.now().month &&
                                  _currentMonth.year == DateTime.now().year
                              ? AppColors.textSecondary.withValues(alpha: 0.3)
                              : null,
                        ),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (totalMoods == 0) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.sentiment_neutral_rounded,
                              color: Color(0xFFEC4899),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _tr(
                              'moodHistory.noDataThisMonth',
                              fallback: 'Sin datos este mes',
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tr(
                              'moodHistory.noDataDesc',
                              fallback:
                                  'Escribe en tu diario para ver tu historial',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  if (dominantMood != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            dominantMood.color.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            dominantMood.color.withValues(
                              alpha: isDark ? 0.06 : 0.03,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: dominantMood.color.withValues(
                            alpha: isDark ? 0.2 : 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dominantMood.emoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tr(
                              'moodHistory.dominantMoodTitle',
                              fallback: 'Tu emoción predominante',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _moodLabel(dominantMood),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: dominantMood.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalMoods == 1
                                ? _tr(
                                    'moodHistory.recordsThisMonthSingular',
                                    fallback: '1 registro este mes',
                                    namedArgs: {'count': '1'},
                                  )
                                : _tr(
                                    'moodHistory.recordsThisMonthPlural',
                                    fallback:
                                        '$totalMoods registros este mes',
                                    namedArgs: {
                                      'count': totalMoods.toString(),
                                    },
                                  ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 20),
                  if (tips.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (dominantMood?.color ?? AppColors.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: dominantMood?.color ?? AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _tr(
                            'moodHistory.tipsTitle',
                            fallback: 'Consejos para ti',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(tips.length, (i) {
                      final tip = tips[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: (dominantMood?.color ?? AppColors.primary)
                                  .withValues(alpha: isDark ? 0.12 : 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip['emoji']!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tip['title']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tip['desc']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (100 * i).ms, duration: 400.ms)
                          .slideX(begin: -0.03, end: 0);
                    }),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    _tr(
                      'moodHistory.distributionTitle',
                      fallback: 'Distribución',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(sortedMoods.length, (i) {
                    final entry = sortedMoods[i];
                    final percent = (entry.value / totalMoods * 100).round();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: entry.key.color.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              entry.key.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _moodLabel(entry.key),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${entry.value} ($percent%)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: entry.key.color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value / totalMoods,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.grey.shade200,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        entry.key.color,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (80 * i).ms, duration: 400.ms);
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
