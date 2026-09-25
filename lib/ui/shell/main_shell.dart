import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/home/home_screen.dart';
import '../screens/diary/diary_screen.dart';
import '../screens/routes/routes_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/discovery_dialog.dart';
import '../../data/models/win_back.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/services/notification_service.dart';
import '../../core/utils/app_route_observer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with WidgetsBindingObserver, RouteAware {
  int _currentIndex = 0;
  bool _isShowingCelebration = false;
  ModalRoute<dynamic>? _observedRoute;

  final _screens = const [
    HomeScreen(),
    DiaryScreen(),
    RoutesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleWinBack());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Para saber cuándo el shell vuelve a estar al frente (ver `_celebrate`).
    final route = ModalRoute.of(context);
    if (route == _observedRoute) return;
    if (_observedRoute != null) appRouteObserver.unsubscribe(this);
    _observedRoute = route;
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  /// Se cerró lo que estaba encima: si algo quedó por celebrar, ahora sí.
  @override
  void didPopNext() => _celebrate();

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app se corren los avisos de "te extrañamos": solo suenan
    // si de verdad pasan días sin abrirla.
    if (state == AppLifecycleState.resumed) _scheduleWinBack();
  }

  void _scheduleWinBack() {
    final variant = WinBack.variantFor(DateTime.now());
    NotificationService.instance.scheduleWinBackReminders(
      firstTitle: WinBack.firstTitleKey(variant).tr(),
      firstBody: WinBack.firstBodyKey(variant).tr(),
      secondTitle: WinBack.secondTitleKey.tr(),
      secondBody: WinBack.secondBodyKey.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el provider para detectar celebraciones
    final authProvider = context.watch<AuthProvider>();
    _checkPendingCelebrations(authProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Las 4 pestañas viven a la vez en el IndexedStack (para no perder
          // su estado al cambiar). Sin TickerMode, las que no se ven siguen
          // animando —Lumi, fondos, brillos— y se comen cuadros de la que sí
          // se está usando: la app entera se siente lenta.
          for (int i = 0; i < _screens.length; i++)
            TickerMode(enabled: _currentIndex == i, child: _screens[i]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'nav.home'.tr()),
                _buildNavItem(1, Icons.book_rounded, 'nav.diary'.tr()),
                _buildNavItem(2, Icons.route_rounded, 'nav.routes'.tr()),
                _buildNavItem(3, Icons.person_rounded, 'nav.profile'.tr()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkPendingCelebrations(AuthProvider authProvider) {
    if (_isShowingCelebration) return;
    if (authProvider.pendingCelebrations.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  /// Muestra lo que haya por celebrar, **solo con el shell al frente**.
  ///
  /// El XP de una página del diario o de una lección puede subir de nivel, y
  /// esta celebración se abría encima de esa pantalla, en medio de lo suyo:
  /// dos rutas apiladas cerrándose a la vez, y `Navigator.pop` cierra siempre
  /// la de arriba, así que cada una cerraba la del otro y el diario se quedaba
  /// "guardando" para siempre. Ahora espera a que esa pantalla se cierre
  /// (`didPopNext`), y se ve como el premio de vuelta al menú.
  Future<void> _celebrate() async {
    if (!mounted || _isShowingCelebration) return;
    if (!(_observedRoute?.isCurrent ?? true)) return; // vuelve en didPopNext
    final auth = context.read<AuthProvider>();
    if (auth.pendingCelebrations.isEmpty) return;
    final events = auth.consumeCelebrations();
    if (events.isEmpty) return;

    _isShowingCelebration = true;
    await CelebrationDialog.showCelebrations(context, events);
    _isShowingCelebration = false;
    // Si llegó algo más mientras se celebraba (el `didPopNext` de este mismo
    // diálogo pasó con la bandera puesta), sale a continuación.
    if (mounted && context.read<AuthProvider>().pendingCelebrations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
          // Diario y Rutas viven en el IndexedStack y se construyen al abrir la
          // app, así que su discovery moment se dispara al tocar la pestaña.
          if (index == 1) {
            DiscoveryDialog.maybeShow(context, DiscoveryFeature.diary);
          } else if (index == 2) {
            DiscoveryDialog.maybeShow(context, DiscoveryFeature.routes);
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 52 : 40,
              height: isSelected ? 32 : 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : isDark
                        ? Colors.white38
                        : Colors.grey.shade500,
                size: isSelected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : isDark
                        ? Colors.white38
                        : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}