import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
 
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    authProvider.userName.isNotEmpty
                        ? authProvider.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(authProvider.userName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(authProvider.userEmail,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              if (authProvider.userModel?.archetype != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    authProvider.userModel!.archetype!.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary,
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              // Placeholder content
              Icon(Icons.person_rounded, size: 60,
                  color: AppColors.primary.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text('Configuración completa próximamente',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
