import 'package:flutter/material.dart';
import 'felt_themes.dart';

/// Card Room — the design system for Spades.
/// Real felt, wooden rails, brass trim, ivory playing cards.
/// No neon, no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [FeltThemeDef]; they default to the
/// Classic Casino theme so call sites keep working.
class Felt {
  static TextStyle display(double size, {Color? color, FeltThemeDef? theme}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(
              color: Color(0xAA000000),
              offset: Offset(0, 2),
              blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, FeltThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.text ?? Colors.white,
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, FeltThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([FeltThemeDef? t]) {
    t ??= FeltThemes.byId('classic');
    final lightBg = t.id == 'ivory';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.felt,
      colorScheme: ColorScheme(
        brightness: lightBg ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.railDeep,
        secondary: t.accentLight,
        onSecondary: t.railDeep,
        surface: t.railMid,
        onSurface: t.text,
        error: t.cardRed,
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.railMid),
    );
  }
}

/// Felt table background: cloth color, radial vignette, cloth weave texture.
class FeltBackdrop extends StatelessWidget {
  final Widget child;
  final FeltThemeDef? theme;
  const FeltBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(color: t.felt),
      child: CustomPaint(
        painter: _FeltPainter(t),
        child: child,
      ),
    );
  }
}

class _FeltPainter extends CustomPainter {
  final FeltThemeDef t;
  _FeltPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.2),
      radius: 1.2,
      colors: [
        t.felt.withValues(alpha: 0.0),
        t.feltDeep.withValues(alpha: 0.55),
        Colors.black.withValues(alpha: 0.45),
      ],
      stops: const [0.35, 0.75, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    // Cloth weave: faint cross-hatch.
    final weave = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 9.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), weave);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weave);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky wooden-rail button with metal trim — looks physically pressable.
class FeltButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final FeltThemeDef? theme;

  const FeltButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.theme,
  });

  @override
  State<FeltButton> createState() => _FeltButtonState();
}

class _FeltButtonState extends State<FeltButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? FeltThemes.byId('classic');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [t.railMid, t.railDark, t.railDeep]
                : [
                    t.railDeep.withValues(alpha: 0.7),
                    t.railDeep.withValues(alpha: 0.5)
                  ],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.05 : 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Felt.display(widget.fontSize,
              theme: t,
              color: enabled
                  ? t.text
                  : t.text.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

/// An engraved brass plaque for titles.
class BrassPlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final FeltThemeDef? theme;
  const BrassPlaque(
      {super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.railDeep, t.railDark],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.7),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Felt.display(30, theme: t), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: Felt.body(14,
                    theme: t, color: t.text.withValues(alpha: 0.75)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// A metal lever toggle for settings.
class FeltToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final FeltThemeDef? theme;
  const FeltToggle(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.railDeep,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wooden-bead volume slider on a metal rail.
class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final FeltThemeDef? theme;
  const BeadSlider(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.railDeep,
        thumbShape: _BeadThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final FeltThemeDef t;
  const _BeadThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2), 12, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final FeltThemeDef? theme;
  const SettingRow(
      {super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.railDeep.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Felt.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}

/// A wood-framed dialog with brass trim, matching the card room.
class FeltDialog extends StatelessWidget {
  final String title;
  final String? emoji;
  final List<Widget> children;
  final FeltThemeDef? theme;

  const FeltDialog({
    super.key,
    required this.title,
    this.emoji,
    required this.children,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? FeltThemes.byId('classic');
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.railMid, t.railDark],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                offset: const Offset(0, 10),
                blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 40)),
            if (emoji != null) const SizedBox(height: 8),
            Text(title,
                style: Felt.display(24, theme: t),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
