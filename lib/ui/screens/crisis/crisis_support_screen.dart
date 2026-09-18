import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/crisis_resource.dart';
import '../breathing/breathing_screen.dart';
import '../../../domain/services/motion_service.dart';

/// Pantalla de líneas de ayuda en crisis.
///
/// Diseño deliberadamente calmado: sin rojos de alarma, sin urgencia visual.
/// El color guía es un azul noche suave y el gesto principal —llamar— está
/// siempre visible arriba, sin que haya que hacer scroll.
class CrisisSupportScreen extends StatefulWidget {
  const CrisisSupportScreen({super.key});

  @override
  State<CrisisSupportScreen> createState() => _CrisisSupportScreenState();
}

class _CrisisSupportScreenState extends State<CrisisSupportScreen>
    with TickerProviderStateMixin {
  late final AnimationController _auraCtrl;
  /// País elegido (o detectado). Null = no tenemos líneas verificadas del
  /// suyo y se le manda al directorio internacional.
  CrisisCountry? _country;

  /// El que se detectó solo, para poder decírselo sin dar por hecho nada.
  CrisisCountry? _detected;

  static const _deep = Color(0xFF1E2A54);
  static const _soft = Color(0xFF6C8FE8);
  static const _mist = Color(0xFFA9C0F5);

  @override
  void initState() {
    super.initState();
    // Respiración lenta del aura: 5 s por ciclo, como una inhalación tranquila.
    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeatUnlessReduced(reverse: true);
    // La región sale de los idiomas del **teléfono**, no del idioma de la app:
    // el de Lumen es solo `es` o `en`, sin país, así que preguntarle a él
    // nunca devolvía nada y todo el mundo veía las líneas de México.
    // Si no reconocemos el país se queda en null a propósito: mejor mandar al
    // directorio internacional que enseñar números de otro país como propios.
    // Nada de esto sale del teléfono.
    _country = CrisisResources.detect(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
    _detected = _country;
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _open(Uri uri, String fallbackText) async {
    HapticFeedback.mediumImpact();
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching $uri: $e');
    }
    if (!ok && mounted) {
      // Si no se pudo abrir el marcador, al menos que pueda copiar el número.
      await Clipboard.setData(ClipboardData(text: fallbackText));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('crisis.copiedToClipboard'
              .tr(namedArgs: {'number': fallbackText})),
          backgroundColor: _deep,
        ));
    }
  }

  Future<void> _call(String number) =>
      _open(Uri(scheme: 'tel', path: number), number);

  Future<void> _text(String number) =>
      _open(Uri.parse('sms:$number?body=AYUDA'), number);

  Future<void> _web(String url) => _open(Uri.parse(url), url);

  Future<void> _contact(CrisisLine line) {
    switch (line.type) {
      case CrisisContactType.phone:
        return _call(line.dial);
      case CrisisContactType.text:
        return _text(line.dial);
      case CrisisContactType.web:
        return _web(line.dial);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final country = _country;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1428) : const Color(0xFFF4F7FF),
      body: Stack(
        children: [
          _buildAura(isDark),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (country != null)
                          _buildPrimaryCall(country, country.lines.first, isDark)
                        else
                          _buildDirectoryHero(isDark),
                        const SizedBox(height: 26),
                        _sectionLabel('crisis.chooseCountry'.tr(), isDark, 0),
                        if (country != null && country == _detected) ...[
                          const SizedBox(height: 6),
                          _buildDetectedNote(country, isDark),
                        ],
                        const SizedBox(height: 10),
                        _buildCountryChips(isDark),
                        if (country != null) ...[
                          const SizedBox(height: 18),
                          _buildLines(country, isDark),
                        ],
                        const SizedBox(height: 14),
                        // Aunque no sepamos de qué país es: si hay riesgo
                        // inmediato hay que llamar a emergencias. Sin país no
                        // se inventa el número, solo se dice.
                        _buildEmergencyCard(country, isDark),
                        const SizedBox(height: 26),
                        _sectionLabel('crisis.meanwhile'.tr(), isDark, 500),
                        const SizedBox(height: 10),
                        _buildBreathingCard(isDark),
                        const SizedBox(height: 10),
                        _buildDirectoryCard(isDark),
                        const SizedBox(height: 22),
                        _buildDisclaimer(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aura de fondo: círculos concéntricos con alpha decreciente que laten
  /// despacio. Nada de MaskFilter.blur — crashea WebGL en Flutter web.
  Widget _buildAura(bool isDark) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _auraCtrl,
          builder: (_, _) => CustomPaint(
            painter: _AuraPainter(
              progress: _auraCtrl.value,
              color: isDark ? _soft : _mist,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : _deep;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                color: textColor,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'crisis.title'.tr(),
            style: TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 12),
          Text(
            'crisis.subtitle'.tr(),
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : _deep.withValues(alpha: 0.7),
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  /// Botón principal: llamar a la línea del país, con halo que late.
  Widget _buildPrimaryCall(CrisisCountry country, CrisisLine line, bool isDark) {
    return AnimatedBuilder(
      animation: _auraCtrl,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_auraCtrl.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _soft.withValues(alpha: 0.25 + t * 0.2),
                blurRadius: 26 + t * 18,
                spreadRadius: t * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _contact(line),
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_soft, _deep],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'crisis.callNow'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          line.display,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${country.flag}  ${line.nameKey?.tr() ?? line.name}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: 250.ms)
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1),
            duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _sectionLabel(String text, bool isDark, int delayMs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: isDark ? Colors.white38 : _deep.withValues(alpha: 0.45),
      ),
    ).animate(delay: Duration(milliseconds: 350 + delayMs)).fadeIn(duration: 400.ms);
  }

  Widget _buildCountryChips(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CrisisResources.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final country = CrisisResources.all[i];
          final selected = country.code == _country?.code;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _country = country);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? _soft.withValues(alpha: isDark ? 0.35 : 0.18)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? _soft.withValues(alpha: 0.7)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : _deep.withValues(alpha: 0.08)),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    country.nameKey.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: isDark
                          ? (selected ? Colors.white : Colors.white60)
                          : (selected ? _deep : _deep.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }

  /// Las líneas del país elegido. El AnimatedSwitcher hace que al cambiar de
  /// país la lista entre con un fundido en vez de saltar.
  Widget _buildLines(CrisisCountry country, bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(country.code),
        children: [
          for (int i = 0; i < country.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildLineCard(country.lines[i], isDark, i),
          ],
        ],
      ),
    );
  }

  /// Cuando no sabemos de qué país es: el directorio internacional ocupa el
  /// sitio de la llamada. Mismo peso visual, porque es lo que de verdad le
  /// sirve.
  Widget _buildDirectoryHero(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _web(CrisisResources.findAHelplineUrl),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_soft, _deep],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.travel_explore_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'crisis.unknownTitle'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'crisis.unknownMessage'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 500.ms);
  }

  /// "Detectamos que estás en X. Si no es así, elige el tuyo." Se dice, no se
  /// da por hecho: la detección viene del idioma del teléfono y puede fallar.
  Widget _buildDetectedNote(CrisisCountry country, bool isDark) {
    return Text(
      'crisis.yourCountry'.tr(namedArgs: {'country': country.nameKey.tr()}),
      style: TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: isDark ? Colors.white54 : _deep.withValues(alpha: 0.55),
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildLineCard(CrisisLine line, bool isDark, int index) {
    final isText = line.type == CrisisContactType.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _contact(line),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _deep.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _soft.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isText
                      ? Icons.chat_bubble_rounded
                      : Icons.phone_rounded,
                  color: isDark ? _mist : _soft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.display,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : _deep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line.nameKey?.tr() ?? line.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? _mist : _soft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line.descriptionKey.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? Colors.white60
                            : _deep.withValues(alpha: 0.65),
                      ),
                    ),
                    if (line.noteKey != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 13,
                              color: isDark ? Colors.white38 : _deep.withValues(alpha: 0.4)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              line.noteKey!.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? Colors.white38
                                    : _deep.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white24 : _deep.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildEmergencyCard(CrisisCountry? country, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: country == null ? null : () => _call(country.emergencyNumber),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A33D).withValues(alpha: isDark ? 0.12 : 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8A33D).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.emergency_rounded,
                  color: Color(0xFFE8A33D), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country == null
                          ? 'crisis.emergencyTitleGeneric'.tr()
                          : 'crisis.emergencyTitle'
                              .tr(namedArgs: {'number': country.emergencyNumber}),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _deep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'crisis.emergencyMessage'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? Colors.white54
                            : _deep.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 450.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildBreathingCard(bool isDark) {
    return _SoftActionCard(
      isDark: isDark,
      icon: Icons.air_rounded,
      title: 'crisis.breathingTitle'.tr(),
      subtitle: 'crisis.breathingMessage'.tr(),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BreathingScreen()));
      },
      delayMs: 550,
    );
  }

  Widget _buildDirectoryCard(bool isDark) {
    return _SoftActionCard(
      isDark: isDark,
      icon: Icons.public_rounded,
      title: 'crisis.directoryTitle'.tr(),
      subtitle: 'crisis.directoryMessage'.tr(),
      onTap: () => _web(CrisisResources.findAHelplineUrl),
      delayMs: 620,
    );
  }

  Widget _buildDisclaimer(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.favorite_rounded,
            size: 14,
            color: isDark ? Colors.white24 : _deep.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'crisis.disclaimer'.tr(),
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: isDark ? Colors.white38 : _deep.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    ).animate(delay: 700.ms).fadeIn(duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas de apoyo
// ═══════════════════════════════════════════════════════════════════════════

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _SoftActionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delayMs;

  const _SoftActionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    const deep = Color(0xFF1E2A54);
    const soft = Color(0xFF6C8FE8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : deep.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isDark ? const Color(0xFFA9C0F5) : soft),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : deep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? Colors.white54
                            : deep.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? Colors.white24 : deep.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: delayMs)).fadeIn(duration: 400.ms);
  }
}

/// Aura de fondo con círculos concéntricos de alpha decreciente.
/// (Regla del proyecto: nunca MaskFilter.blur en CustomPainter.)
class _AuraPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AuraPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(progress);
    final centers = [
      Offset(size.width * 0.18, size.height * 0.12),
      Offset(size.width * 0.9, size.height * 0.34),
      Offset(size.width * 0.3, size.height * 0.82),
    ];
    final baseRadii = [
      size.width * 0.55,
      size.width * 0.42,
      size.width * 0.5,
    ];

    for (int c = 0; c < centers.length; c++) {
      final radius = baseRadii[c] * (0.92 + t * 0.12);
      // 14 anillos con alpha decreciente imitan un degradado suave.
      const rings = 14;
      for (int i = rings; i > 0; i--) {
        final f = i / rings;
        final paint = Paint()
          ..color = color.withValues(alpha: 0.022 * (1 - f) + 0.004);
        canvas.drawCircle(centers[c], radius * f, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.progress != progress || old.color != color;
}
