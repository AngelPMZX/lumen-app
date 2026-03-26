import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/providers/auth_provider.dart';

class UsernameStep extends StatefulWidget {
  final Function(String) onNext;

  const UsernameStep({super.key, required this.onNext});

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  final _controller = TextEditingController();
  String? _error;
  bool _isChecking = false;
  bool _isAvailable = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _isAvailable = false;
      _error = Validators.username(value);
    });

    if (_error != null || value.isEmpty) return;

    setState(() => _isChecking = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final authProvider = context.read<AuthProvider>();
      final taken = await authProvider.isUsernameTaken(value);

      if (mounted) {
        setState(() {
          _isChecking = false;
          if (taken) {
            _error = 'Este usuario ya está tomado';
            _isAvailable = false;
          } else {
            _error = null;
            _isAvailable = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Ícono
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.alternate_email_rounded,
              size: 50,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 32),

          const Text(
            'Elige tu usuario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Así te conocerán en Lumen',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),

          // Input
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: TextField(
              controller: _controller,
              onChanged: _onUsernameChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '@',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: _isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : _isAvailable
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981))
                        : null,
                hintText: 'tu_usuario',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 18,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _isAvailable
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                errorText: _error,
                errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),

          // Hint
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              'Letras minúsculas, números, puntos y guiones bajos',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Botón
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isAvailable
                  ? () => widget.onNext(_controller.text)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.2),
                disabledForegroundColor:
                    Colors.white.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}