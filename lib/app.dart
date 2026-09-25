import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/profile_setup/profile_setup_screen.dart';
import 'ui/shell/main_shell.dart';
import 'domain/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'ui/screens/auth/forgot_password_screen.dart';
import 'ui/screens/auth/verify_email_screen.dart';
import 'ui/screens/crisis/crisis_support_screen.dart';
import 'domain/services/analytics_service.dart';
import 'domain/services/motion_service.dart';
import 'ui/widgets/theme_fade.dart';
import 'core/utils/app_route_observer.dart';

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    AnalyticsService.instance.setLanguage(context.locale.languageCode);
    final analyticsObserver = AnalyticsService.instance.observer(
      // La ayuda en crisis nunca se registra: es un dato de salud.
      excludedRoutes: {AppRoutes.crisisSupport},
    );

    return MaterialApp(
      title: 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: AppRoutes.splash,
      navigatorObservers: [?analyticsObserver, appRouteObserver],
      // "Reducir animaciones" del perfil se suma a la opción del sistema, y
      // todo el árbol la lee desde MediaQuery.disableAnimations.
      builder: (context, child) => ListenableBuilder(
        listenable: MotionService.instance,
        builder: (context, _) {
          final media = MediaQuery.of(context);
          final brightness = switch (themeProvider.themeMode) {
            ThemeMode.dark => Brightness.dark,
            ThemeMode.light => Brightness.light,
            ThemeMode.system => media.platformBrightness,
          };
          return MediaQuery(
            data: media.copyWith(
              disableAnimations:
                  media.disableAnimations || MotionService.instance.userReduce,
            ),
            // Claro ↔ oscuro sin dar un salto de luz (ver ThemeFade). Va aquí
            // dentro para que lea el "reducir animaciones" ya inyectado.
            child: ThemeFade(brightness: brightness, child: child!),
          );
        },
      ),
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.profileSetup: (_) => const ProfileSetupScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.verifyEmail: (_) => const VerifyEmailScreen(),
        AppRoutes.onboardingIntro: (_) => const OnboardingScreen(),
        AppRoutes.crisisSupport: (_) => const CrisisSupportScreen(),
      },
    );
  }
}