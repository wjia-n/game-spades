import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment → game logo + name,
/// animated loading line, "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final SpadesAudio audio;
  final SpadesSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Company splash moment first.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _companyDone = true);
    // Pre-warm audio while the game splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B08),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _companyDone
            ? _GameSplash(key: const ValueKey('game'), theme: theme, loader: _loader)
            : _CompanySplash(key: const ValueKey('company')),
      ),
    );
  }
}

/// Company splash: the official WAJIHA winged-W mark, untouched.
class _CompanySplash extends StatelessWidget {
  const _CompanySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const Text(
              'WAJIHA',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8CE7A),
                letterSpacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final FeltThemeDef theme;
  final AnimationController loader;
  const _GameSplash({super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return FeltBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/spades_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Spades', style: Felt.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'THE CARD ROOM EDITION',
              style: Felt.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Shuffling the deck…' : 'Ready!',
                      style: Felt.body(13,
                          theme: theme,
                          color: theme.text.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Felt.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
