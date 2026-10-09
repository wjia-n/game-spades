import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/spades_engine.dart';
import '../theme/felt_themes.dart';

/// A physical-feeling playing card: ivory stock, rounded corners, printed
/// pips with subtle shading, soft drop shadow — like a real card on felt.
class PlayingCard extends StatelessWidget {
  final SpadesCard card;
  final FeltThemeDef theme;
  final double width;
  final bool dimmed; // illegal / not your turn
  final bool highlighted; // just played / winner

  const PlayingCard({
    super.key,
    required this.card,
    required this.theme,
    this.width = 64,
    this.dimmed = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 1.42;
    final w = width;
    final pipColor = isRedSuit(card.suit) ? theme.cardRed : theme.cardBlack;
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
            if (highlighted)
              BoxShadow(
                color: theme.accentLight.withValues(alpha: 0.85),
                offset: Offset.zero,
                blurRadius: 10,
              ),
          ],
        ),
        child: CustomPaint(
          painter: _CardFacePainter(
            card: card,
            theme: theme,
            pipColor: pipColor,
          ),
        ),
      ),
    );
  }
}

class _CardFacePainter extends CustomPainter {
  final SpadesCard card;
  final FeltThemeDef theme;
  final Color pipColor;

  _CardFacePainter(
      {required this.card, required this.theme, required this.pipColor});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.11;
    final rect = Offset.zero & size;
    // Ivory card stock with a faint top-light sheen.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.ivory,
            Color.lerp(theme.ivory, Colors.black, 0.06)!,
          ],
        ).createShader(rect),
    );
    // Thin printed border.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.deflate(size.width * 0.045), Radius.circular(r * 0.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = pipColor.withValues(alpha: 0.25),
    );
    final suit = suitGlyphs[card.suit];
    final rank = rankGlyph(card.rank);
    void drawGlyph(String text, Offset pos, double fs, {double alpha = 1}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w900,
            color: pipColor.withValues(alpha: alpha),
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    final cornerFs = size.width * 0.24;
    // Top-left corner index.
    final tl = Offset(size.width * 0.16, size.height * 0.075);
    final tpRank = TextPainter(
      text: TextSpan(
        text: rank,
        style: TextStyle(
          fontSize: cornerFs,
          fontWeight: FontWeight.w900,
          color: pipColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpRank.paint(canvas, Offset(tl.dx - tpRank.width / 2, tl.dy - tpRank.height / 2));
    drawGlyph(suit, Offset(tl.dx, tl.dy + cornerFs * 1.05), cornerFs * 0.95);
    // Center pip: big suit glyph with soft emboss.
    drawGlyph(suit, Offset(size.width / 2, size.height * 0.52),
        size.width * 0.52,
        alpha: 0.16);
    drawGlyph(suit, Offset(size.width / 2, size.height * 0.50),
        size.width * 0.52);
    // Bottom-right index (rotated).
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(3.14159265);
    tpRank.paint(canvas, Offset(tl.dx - tpRank.width / 2, tl.dy - tpRank.height / 2));
    drawGlyph(suit, Offset(tl.dx, tl.dy + cornerFs * 1.05), cornerFs * 0.95);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CardFacePainter old) =>
      old.card != card || old.theme != theme;
}

/// Face-down card showing the selected card-back design.
class CardBack extends StatelessWidget {
  final FeltThemeDef theme;
  final int style;
  final double width;

  const CardBack({
    super.key,
    required this.theme,
    required this.style,
    this.width = 44,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 1.42;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(painter: _BackPainter(theme: theme, style: style)),
    );
  }
}

class _BackPainter extends CustomPainter {
  final FeltThemeDef theme;
  final int style;

  _BackPainter({required this.theme, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.11;
    final rect = Offset.zero & size;
    final base = switch (style) {
      1 => theme.accentDark, // Brass Lattice
      2 => theme.feltDeep, // Felt Green
      3 => const Color(0xFF1B2440), // Midnight Pip
      4 => const Color(0xFF5A1A26), // Crimson Brocade
      5 => const Color(0xFF6E4A24), // Copper Weave
      6 => const Color(0xFF22303E), // Art Deco
      7 => const Color(0xFF14141A), // Golden Spade
      _ => theme.ivory, // Ivory Classic
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.18)!],
        ).createShader(rect),
    );
    // Rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.deflate(size.width * 0.05), Radius.circular(r * 0.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.width * 0.02)
        ..color = theme.accentLight.withValues(alpha: 0.85),
    );
    final cx = size.width / 2;
    final cy = size.height / 2;
    void glyph(String text, double fs, Color c) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: fs, fontWeight: FontWeight.w900, color: c, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    switch (style) {
      case 1: // Brass Lattice
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = theme.accentLight.withValues(alpha: 0.4);
        final step = size.width / 6;
        for (double x = -size.height; x < size.width + size.height; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
          canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), p);
        }
        glyph('♠', size.width * 0.5, theme.accentLight);
        break;
      case 2: // Felt Green inlay
        glyph('♠', size.width * 0.55, theme.accent);
        break;
      case 3: // Midnight Pip
        glyph('♠', size.width * 0.55, const Color(0xFFC0C6D4));
        break;
      case 4: // Crimson Brocade
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = theme.accentLight.withValues(alpha: 0.35);
        canvas.drawCircle(Offset(cx, cy), size.width * 0.32, p);
        canvas.drawCircle(Offset(cx, cy), size.width * 0.24, p);
        glyph('♠', size.width * 0.42, theme.accentLight);
        break;
      case 5: // Copper Weave
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = theme.accentLight.withValues(alpha: 0.45);
        final step = size.width / 5;
        for (double y = 0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y + step), p);
        }
        glyph('♠', size.width * 0.44, theme.accentLight);
        break;
      case 6: // Art Deco sunburst
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = theme.accentLight.withValues(alpha: 0.5);
        for (int i = 0; i < 12; i++) {
          final a = i * math.pi / 6;
          canvas.drawLine(
            Offset(cx, cy),
            Offset(cx + 30 * math.cos(a), cy + 30 * math.sin(a)),
            p,
          );
        }
        glyph('♠', size.width * 0.4, theme.accentLight);
        break;
      case 7: // Golden Spade on ebony
        glyph('♠', size.width * 0.62, const Color(0xFFD4AF37));
        break;
      default: // Ivory Classic
        glyph('♠', size.width * 0.5, theme.accentDark);
    }
  }

  @override
  bool shouldRepaint(covariant _BackPainter old) =>
      old.style != style || old.theme != theme;
}