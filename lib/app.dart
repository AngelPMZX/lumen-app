import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/profile_setup/profile_setup_screen.dart';
import 'ui/shell/main_shell.dart';
import 'domain/providers/theme_provider.dart';  
import 'package:provider/provider.dart';

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,  
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.profileSetup: (_) => const ProfileSetupScreen(),
      },
    );
  }
}