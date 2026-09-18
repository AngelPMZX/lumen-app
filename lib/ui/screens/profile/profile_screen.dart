import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/garden_item.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/medals.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/providers/theme_provider.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../auth/widgets/auth_widgets.dart' show openExternal, openMail;
import '../garden/widgets/garden_common.dart' show GardenSheet;
import '../summary/weekly_summary_screen.dart';
import 'achievements_screen.dart';
import 'edit_profile_screen.dart';
import 'mood_history_screen.dart';
import 'widgets/profile_widgets.dart';

/// Perfil: quién eres en Lumen (nivel, arquetipo, Lumi), tu camino en
/// números, la vitrina de medallas y los ajustes agrupados.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _lessonsCompleted = 0;
  int _decorationsPlaced = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtras());
  }

  /// Lo que no traen los contadores de `AuthProvider`: lecciones y
  /// decoraciones colocadas.
  Future<void> _loadExtras() async {
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();
    try {
      final lessons = await auth.getCompletedLessons();
      final decos = await garden.loadPlacedDecorations();
      if (!mounted) return;
      setState(() {
        _lessonsCompleted = lessons.where((id) => !id.startsWith('challenge_') && !id.startsWith('breathing_session')).length;
        _decorationsPlaced = decos.length;
      });
    } catch (_) {}
  }

  static String levelTitle(int level) {
    if (level <= 3) return 'userProgress.levelTitles.emotionalNovice'.tr();
    if (level <= 7) return 'userProgress.levelTitles.consciousApprentice'.tr();
    if (level <= 12) return 'userProgress.levelTitles.innerExplorer'.tr();
    if (level <= 18) return 'userProgress.levelTitles.resilientWarrior'.tr();
    return 'userProgress.levelTitles.zenMaster'.tr();
  }

  AchievementStats _stats(AuthProvider auth, GardenProvider garden) {
    final progress = auth.userProgress;
    final plants = garden.garden;
    return AchievementStats(
      currentStreak: auth.currentStreak,
      longestStreak: progress?.longestStreak ?? 0,
      totalXp: progress?.totalXp ?? 0,
      level: progress?.level ?? 1,
      diaryEntries: auth.diaryEntryCount,
      habitsCompleted: auth.habitsCompletedCount,
      moodCheckIns: auth.moodCheckInCount,
      lessonsCompleted: _lessonsCompleted,
      plantsInGarden: plants.length,
      adultPlants: plants.where((p) {
        final item = GardenCatalog.findById(p.itemId);
        return item != null && p.isAdult(item);
      }).length,
      decorationsPlaced: _decorationsPlaced,
      seenIds: auth.celebratedAchievementIds,
    );
  }

  Future<void> _openAchievements(AchievementStats stats) async {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    final auth = context.read<AuthProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AchievementsScreen(stats: stats, onSeen: auth.markAchievementsSeen)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openMedal(MedalStatus medal) async {
    final auth = context.read<AuthProvider>();
    await showMedalDetail(context, medal);
    if (medal.isNew) {
      await auth.markAchievementsSeen({medal.id});
      if (mounted) setState(() {});
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return GardenSheet(
          title: 'auth.logoutConfirmTitle'.tr(),
          leading: const LumiAvatar(mood: LumiMood.caring, size: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'profileScreen.logoutConfirm'.tr(),
                style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('auth.logout'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirm != true) return;
    await auth.logout();
    garden.resetOnLogout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
    }
  }

  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isSpanish = context.locale.languageCode == 'es';
        return GardenSheet(
          title: 'profileScreen.language'.tr(),
          child: Column(
            children: [
              for (final (code, flag, name) in const [('es', '🇲🇽', 'Español'), ('en', '🇺🇸', 'English')])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LanguageOption(
                    flag: flag,
                    name: name,
                    selected: (code == 'es') == isSpanish,
                    onTap: () {
                      SoundService.instance.play(Sfx.pop, volume: 0.4);
                      context.setLocale(Locale(code));
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAbout() {
    SoundService.instance.lumiChirp(0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final soft = isDark ? Colors.white70 : AppColors.textSecondary;
        return GardenSheet(
          kicker: 'profile.version'.tr(namedArgs: {'version': '1.0.0'}),
          title: 'Lumen',
          leading: const LumiAvatar(mood: LumiMood.happy, size: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('profileScreen.aboutBody'.tr(), style: TextStyle(fontSize: 14, height: 1.45, color: soft)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('profileScreen.aboutPrivacy'.tr(), style: TextStyle(fontSize: 13, height: 1.35, color: soft))),
                ],
              ),
              const SizedBox(height: 14),
              _AboutLink(
                icon: Icons.privacy_tip_rounded,
                label: 'profileScreen.privacyPolicy'.tr(),
                onTap: () => openExternal(AppLinks.privacy(context.locale.languageCode)),
                isDark: isDark,
              ),
              _AboutLink(
                icon: Icons.gavel_rounded,
                label: 'profileScreen.terms'.tr(),
                onTap: () => openExternal(AppLinks.terms),
                isDark: isDark,
              ),
              _AboutLink(
                icon: Icons.mail_rounded,
                label: 'profileScreen.contact'.tr(),
                onTap: () => openMail(AppLinks.supportMail('Lumen 1.0.0')),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Text(
                'profileScreen.aboutStudio'.tr(),
                style: JournalStyle.hand(TextStyle(fontSize: 19, color: isDark ? AppColors.primaryLight : AppColors.primary)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final garden = context.watch<GardenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = auth.userProgress;
    final stats = _stats(auth, garden);
    final medals = Medals.evaluate(stats);
    final archetype = auth.userModel?.archetype;
    final level = progress?.level ?? 1;
    final xpForNext = progress?.xpForNextLevel ?? 100;
    final xpInLevel = xpForNext == 0 ? 0 : stats.totalXp % xpForNext;

    final sections = <Widget>[
      ProfileHero(
        name: auth.userName,
        username: auth.userModel?.username,
        archetypeName: ArchetypeStyle.name(archetype),
        archetypeEmoji: ArchetypeStyle.emoji(archetype),
        colors: ArchetypeStyle.colors(archetype),
        level: level,
        levelTitle: levelTitle(level),
        xpInLevel: xpInLevel,
        xpForNext: xpForNext,
        memberSince: auth.userModel?.createdAt,
        line: ProfileLumi.lineFor(stats, medals),
        isDark: isDark,
        onEdit: _editProfile,
      ),
      const SizedBox(height: 22),
      _SectionTitle(kicker: 'profileScreen.journeyKicker'.tr(), title: 'profileScreen.journeyTitle'.tr(), isDark: isDark),
      const SizedBox(height: 10),
      ProfileStatsGrid(
        isDark: isDark,
        stats: [
          ProfileStat('🔥', stats.currentStreak, 'profileScreen.statStreak'.tr(), const Color(0xFFF97316)),
          ProfileStat('🏆', stats.longestStreak, 'profileScreen.statBestStreak'.tr(), const Color(0xFFF59E0B)),
          ProfileStat('⚡', stats.totalXp, 'profileScreen.statXp'.tr(), const Color(0xFF8B5CF6)),
          ProfileStat('📚', stats.lessonsCompleted, 'profileScreen.statLessons'.tr(), const Color(0xFF3B82F6)),
          ProfileStat('📝', stats.diaryEntries, 'profileScreen.statDiary'.tr(), const Color(0xFF10B981)),
          ProfileStat('😊', stats.moodCheckIns, 'profileScreen.statMoods'.tr(), const Color(0xFFEC4899)),
        ],
      ),
      const SizedBox(height: 22),
      MedalShowcaseCard(
        medals: medals,
        isDark: isDark,
        onOpen: () => _openAchievements(stats),
        onMedal: _openMedal,
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
      const SizedBox(height: 24),
      SettingsGroup(
        title: 'profileScreen.groupYou'.tr(),
        isDark: isDark,
        items: [
          SettingsItem(
            icon: Icons.person_rounded,
            color: ArchetypeStyle.colors(archetype).first,
            title: 'profile.editProfile'.tr(),
            subtitle: 'profileScreen.editProfileSubtitle'.tr(),
            onTap: _editProfile,
          ),
          SettingsItem(
            icon: Icons.auto_graph_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'summary.title'.tr(),
            subtitle: 'summary.menuSubtitle'.tr(),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklySummaryScreen(source: 'profile'))),
          ),
          SettingsItem(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFFEC4899),
            title: 'profile.moodHistory'.tr(),
            subtitle: 'profileScreen.moodHistorySubtitle'.tr(),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodHistoryScreen())),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SettingsGroup(
        title: 'profileScreen.groupPreferences'.tr(),
        isDark: isDark,
        items: [
          SettingsItem(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: const Color(0xFF6366F1),
            title: 'profileScreen.themeTitle'.tr(),
            subtitle: isDark ? 'profileScreen.darkModeOn'.tr() : 'profileScreen.lightModeOn'.tr(),
            toggle: isDark,
            onToggle: (_) => context.read<ThemeProvider>().toggleTheme(),
          ),
          SettingsItem(
            icon: SoundService.instance.effectsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: const Color(0xFFF59E0B),
            title: 'profileScreen.soundEffects'.tr(),
            subtitle: 'profileScreen.soundEffectsSubtitle'.tr(),
            toggle: SoundService.instance.effectsEnabled,
            onToggle: (v) async {
              await SoundService.instance.setEffectsEnabled(v);
              if (v) SoundService.instance.play(Sfx.toggleOn, volume: 0.4);
              if (mounted) setState(() {});
            },
          ),
          SettingsItem(
            icon: Icons.motion_photos_paused_rounded,
            color: const Color(0xFF14B8A6),
            title: 'profileScreen.reduceMotion'.tr(),
            subtitle: 'profileScreen.reduceMotionSubtitle'.tr(),
            toggle: MotionService.instance.userReduce,
            onToggle: (v) async {
              await MotionService.instance.setReduceMotion(v);
              if (mounted) setState(() {});
            },
          ),
          SettingsItem(
            icon: Icons.language_rounded,
            color: const Color(0xFF3B82F6),
            title: 'profileScreen.language'.tr(),
            subtitle: context.locale.languageCode == 'es' ? '🇲🇽 Español' : '🇺🇸 English',
            onTap: _changeLanguage,
          ),
        ],
      ),
      const SizedBox(height: 20),
      SettingsGroup(
        title: 'profileScreen.groupHelp'.tr(),
        isDark: isDark,
        items: [
          SettingsItem(
            icon: Icons.volunteer_activism_rounded,
            color: const Color(0xFF6C8FE8),
            title: 'crisis.card.title'.tr(),
            subtitle: 'crisis.menuSubtitle'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.crisisSupport),
          ),
          SettingsItem(
            icon: Icons.tour_rounded,
            color: const Color(0xFF10B981),
            title: 'profileScreen.watchTour'.tr(),
            subtitle: 'profileScreen.watchTourSubtitle'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.onboardingIntro),
          ),
          SettingsItem(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF64748B),
            title: 'profile.about'.tr(),
            subtitle: 'profile.version'.tr(namedArgs: {'version': '1.0.0'}),
            onTap: _showAbout,
          ),
        ],
      ),
      const SizedBox(height: 24),
      _LogoutButton(isDark: isDark, onTap: _logout),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF6F3FF),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadExtras,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            children: [
              for (final (i, w) in sections.indexed)
                i < 2
                    ? w
                    : w.animate().fadeIn(delay: (180 + i * 30).ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (result == true && mounted) setState(() {});
  }
}

/// Fila de "Acerca de": abre una página fuera de la app.
class _AboutLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _AboutLink({required this.icon, required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink))),
              Icon(Icons.open_in_new_rounded, size: 15, color: ink.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final bool isDark;
  const _SectionTitle({required this.kicker, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: JournalStyle.hand(TextStyle(fontSize: 18, height: 1.0, color: isDark ? AppColors.primaryLight : AppColors.primary))),
          Semantics(
            header: true,
            child: Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({required this.flag, required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF6366F1);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: name,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: isDark ? 0.2 : 0.08) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? accent : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)), width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? accent : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _LogoutButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return Semantics(
      button: true,
      label: 'auth.logout'.tr(),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: red.withValues(alpha: isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: red.withValues(alpha: isDark ? 0.25 : 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: red, size: 20),
              const SizedBox(width: 10),
              Text('auth.logout'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: red)),
            ],
          ),
        ),
      ),
    );
  }
}
