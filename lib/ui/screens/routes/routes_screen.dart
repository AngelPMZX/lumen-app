import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
 
class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route_rounded, size: 80,
                  color: AppColors.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text('Rutas de Bienestar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Próximamente en Fase 3C',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
