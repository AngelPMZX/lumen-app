import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  Future<void> _loadMonth() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59);
      final moods = await auth.getDiaryCalendarMoods(start, end);
      if (mounted) setState(() { _monthMoods = moods; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
    _loadMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) return;
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
    _loadMonth();
  }

  /// Consejos personalizados según la emoción predominante
  List<Map<String, String>> _getTips(MoodType? mood) {
    if (mood == null) return [];
    switch (mood) {
      case MoodType.happy:
        return [
          {'emoji': '🌟', 'title': 'Comparte tu alegría', 'desc': 'La felicidad se multiplica cuando la compartes con otros.'},
          {'emoji': '📝', 'title': 'Anota lo que te hace feliz', 'desc': 'Registrar momentos felices te ayuda a recrearlos.'},
          {'emoji': '🙏', 'title': 'Practica gratitud', 'desc': 'Agradecer lo bueno fortalece las emociones positivas.'},
        ];
      case MoodType.excited:
        return [
          {'emoji': '🎯', 'title': 'Canaliza la energía', 'desc': 'Aprovecha este impulso para proyectos creativos o metas.'},
          {'emoji': '📸', 'title': 'Captura el momento', 'desc': 'Guarda fotos o escribe sobre esta emoción para recordarla.'},
          {'emoji': '🤝', 'title': 'Inspira a otros', 'desc': 'Tu entusiasmo puede contagiar a quienes te rodean.'},
        ];
      case MoodType.grateful:
        return [
          {'emoji': '💌', 'title': 'Expresa tu gratitud', 'desc': 'Dile a alguien lo importante que es para ti.'},
          {'emoji': '📖', 'title': 'Lleva un diario de gratitud', 'desc': 'Escribe 3 cosas por las que estás agradecido cada día.'},
          {'emoji': '🌱', 'title': 'Cultiva esta emoción', 'desc': 'La gratitud constante mejora tu bienestar general.'},
        ];
      case MoodType.calm:
        return [
          {'emoji': '🧘', 'title': 'Profundiza la calma', 'desc': 'Medita 5 minutos para mantener este estado de paz.'},
          {'emoji': '🌿', 'title': 'Conecta con la naturaleza', 'desc': 'Un paseo tranquilo refuerza la serenidad.'},
          {'emoji': '📚', 'title': 'Lee algo inspirador', 'desc': 'La tranquilidad es ideal para absorber conocimiento.'},
        ];
      case MoodType.neutral:
        return [
          {'emoji': '🎨', 'title': 'Prueba algo nuevo', 'desc': 'Un día neutral es perfecto para explorar nuevas actividades.'},
          {'emoji': '💪', 'title': 'Haz ejercicio ligero', 'desc': 'El movimiento puede elevar tu estado de ánimo naturalmente.'},
          {'emoji': '🎵', 'title': 'Escucha música', 'desc': 'La música que te gusta puede transformar tu día.'},
        ];
      case MoodType.tired:
        return [
          {'emoji': '😴', 'title': 'Descansa sin culpa', 'desc': 'Tu cuerpo necesita recuperarse. Permítete descansar.'},
          {'emoji': '💧', 'title': 'Hidrátate bien', 'desc': 'La deshidratación aumenta la fatiga. Toma agua.'},
          {'emoji': '🌙', 'title': 'Mejora tu sueño', 'desc': 'Evita pantallas 1 hora antes de dormir.'},
        ];
      case MoodType.bored:
        return [
          {'emoji': '🎮', 'title': 'Prueba un hobby nuevo', 'desc': 'Pintar, cocinar, jardinería... hay mucho por descubrir.'},
          {'emoji': '📱', 'title': 'Llama a un amigo', 'desc': 'Una conversación puede cambiar completamente tu día.'},
          {'emoji': '🚶', 'title': 'Sal a caminar', 'desc': 'Cambiar de ambiente rompe la monotonía.'},
        ];
      case MoodType.sad:
        return [
          {'emoji': '💙', 'title': 'Está bien sentirse triste', 'desc': 'Permitirte sentir es el primer paso para sanar.'},
          {'emoji': '🤗', 'title': 'Busca apoyo', 'desc': 'Habla con alguien de confianza sobre cómo te sientes.'},
          {'emoji': '🌤️', 'title': 'Esto también pasará', 'desc': 'Los días difíciles hacen más valiosos los buenos momentos.'},
        ];
      case MoodType.anxious:
        return [
          {'emoji': '🫁', 'title': 'Respiración 4-7-8', 'desc': 'Inhala 4s, sostén 7s, exhala 8s. Repite 4 veces.'},
          {'emoji': '✍️', 'title': 'Escribe tus preocupaciones', 'desc': 'Sacar los pensamientos al papel reduce la ansiedad.'},
          {'emoji': '🧊', 'title': 'Técnica de grounding', 'desc': 'Nombra 5 cosas que ves, 4 que tocas, 3 que oyes.'},
        ];
      case MoodType.angry:
        return [
          {'emoji': '⏸️', 'title': 'Haz una pausa', 'desc': 'Cuenta hasta 10 antes de reaccionar. Date espacio.'},
          {'emoji': '🏃', 'title': 'Mueve el cuerpo', 'desc': 'El ejercicio físico libera la tensión acumulada.'},
          {'emoji': '📝', 'title': 'Escribe sin filtro', 'desc': 'Vacía tus pensamientos en papel. No tienes que mostrárselo a nadie.'},
        ];
      case MoodType.stressed:
        return [
          {'emoji': '📋', 'title': 'Prioriza tareas', 'desc': 'Haz una lista y enfócate en lo más importante primero.'},
          {'emoji': '🧘', 'title': 'Micro-descansos', 'desc': 'Cada 25 min, toma 5 min de pausa. Tu mente lo agradecerá.'},
          {'emoji': '🎶', 'title': 'Música relajante', 'desc': 'Sonidos de la naturaleza o lo-fi pueden reducir el estrés.'},
        ];
      case MoodType.lonely:
        return [
          {'emoji': '💬', 'title': 'Conecta con alguien', 'desc': 'Envía un mensaje a un amigo o familiar. No estás solo.'},
          {'emoji': '🐾', 'title': 'Compañía de mascotas', 'desc': 'Si tienes mascota, dedícale tiempo. Su amor es incondicional.'},
          {'emoji': '🌐', 'title': 'Únete a una comunidad', 'desc': 'Hay grupos de intereses donde puedes conocer gente nueva.'},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthNames = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

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
        title: const Text('Historial de ánimo', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true, backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12, maxShootingStars: isDark ? 1 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : (dominantMood?.color ?? const Color(0xFFEC4899)).withValues(alpha: 0.1),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navegación
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: _previousMonth),
                      Text('${monthNames[_currentMonth.month]} ${_currentMonth.year}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary)),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: _currentMonth.month == DateTime.now().month &&
                                    _currentMonth.year == DateTime.now().year
                                ? AppColors.textSecondary.withValues(alpha: 0.3) : null),
                        onPressed: _nextMonth),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (totalMoods == 0) ...[
                  Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      Container(width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.sentiment_neutral_rounded, color: Color(0xFFEC4899), size: 32)),
                      const SizedBox(height: 16),
                      Text('Sin datos este mes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Escribe en tu diario para ver tu historial',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ]),
                  )),
                ] else ...[
                  // Emoción predominante
                  if (dominantMood != null)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          dominantMood.color.withValues(alpha: isDark ? 0.15 : 0.08),
                          dominantMood.color.withValues(alpha: isDark ? 0.06 : 0.03)]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: dominantMood.color.withValues(alpha: isDark ? 0.2 : 0.15)),
                      ),
                      child: Column(children: [
                        Text(dominantMood.emoji, style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        Text('Tu emoción predominante', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(dominantMood.label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dominantMood.color)),
                        const SizedBox(height: 4),
                        Text('$totalMoods ${totalMoods == 1 ? "registro" : "registros"} este mes',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 20),

                  // ── Consejos personalizados ──
                  if (tips.isNotEmpty) ...[
                    Row(children: [
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: (dominantMood?.color ?? AppColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.lightbulb_rounded,
                            color: dominantMood?.color ?? AppColors.primary, size: 16)),
                      const SizedBox(width: 10),
                      Text('Consejos para ti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 12),
                    ...List.generate(tips.length, (i) {
                      final tip = tips[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: (dominantMood?.color ?? AppColors.primary).withValues(alpha: isDark ? 0.12 : 0.08)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tip['emoji']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tip['title']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(tip['desc']!, style: TextStyle(fontSize: 13,
                                      color: AppColors.textSecondary, height: 1.4)),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (100 * i).ms, duration: 400.ms)
                          .slideX(begin: -0.03, end: 0);
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Distribución
                  Text('Distribución', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...List.generate(sortedMoods.length, (i) {
                    final entry = sortedMoods[i];
                    final percent = (entry.value / totalMoods * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: entry.key.color.withValues(alpha: isDark ? 0.15 : 0.1)),
                        ),
                        child: Row(children: [
                          Text(entry.key.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(entry.key.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('${entry.value} ($percent%)', style: TextStyle(fontSize: 13,
                                    color: entry.key.color, fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: entry.value / totalMoods,
                                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(entry.key.color),
                                  minHeight: 6),
                              ),
                            ],
                          )),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms);
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