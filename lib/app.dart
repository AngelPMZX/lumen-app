import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/home/home_screen.dart';

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
      },
    );
  }
}
