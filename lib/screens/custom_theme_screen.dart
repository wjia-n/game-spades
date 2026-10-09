import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';

/// Custom felt creator (PRO): tune every color of the card room.
class CustomThemeScreen extends StatefulWidget {
  final SpadesAudio audio;
  final SpadesSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  SpadesSettings get _s => widget.settings;

  static const _keys = [
    ('felt', 'Table felt'),
    ('feltDeep', 'Felt shading'),
    ('railDark', 'Rail wood'),
    ('railMid', 'Rail mid'),
    ('railDeep', 'Rail shadow'),
    ('accent', 'Trim metal'),
    ('accentLight', 'Trim highlight'),
    ('accentDark', 'Trim shadow'),
    ('ivory', 'Card stock'),
    ('cardRed', 'Red pips'),
    ('cardBlack', 'Black pips'),
    ('pc0', 'Seat 1 color'),
    ('pc1', 'Seat 2 color'),
    ('pc2', 'Seat 3 color'),
    ('pc3', 'Seat 4 color'),
  ];

  // Curated swatch palette: warm physical-material tones, no neon.
  static const _swatches = [
    0xFF1E5C43, 0xFF0F4A35, 0xFF24523F, 0xFF2F5A34, 0xFF155A55, 0xFF1E2A44,
    0xFF24406E, 0xFF6E1E30, 0xFF5A2E42, 0xFF46244E, 0xFF3B2416, 0xFF5C3A21,
    0xFF4A1F14, 0xFF2E3B22, 0xFF1C2438, 0xFF2E3440, 0xFF3B4252, 0xFF242424,
    0xFFC9A227, 0xFFE8CE7A, 0xFFD4AF37, 0xFFB87333, 0xFFC0C6D4, 0xFFF5EFE0,
    0xFFEFE3C8, 0xFF2E2118, 0xFFB02A30, 0xFFC0392B, 0xFF8E1F2C, 0xFF1E2430,
    0xFFA31621, 0xFF1D4E9E, 0xFF1B7A4D, 0xFFD99A2B, 0xFF7D3C98, 0xFFE67E22,
  ];

  @override
  Widget build(BuildContext context) {
    final t = _s.theme;
    return Scaffold(
      backgroundColor: t.felt,
      appBar: AppBar(
        backgroundColor: t.railDeep,
        foregroundColor: t.text,
        title: Text('Custom felt 🎨', style: Felt.display(20, theme: t)),
      ),
      body: FeltBackdrop(
        theme: t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                'Design your own card room. Pick a part, then a color.',
                style: Felt.body(14, theme: t),
              ),
              const SizedBox(height: 14),
              for (final (key, label) in _keys) _colorRow(t, key, label),
              const SizedBox(height: 18),
              Center(
                child: FeltButton(
                  label: 'Use my felt ✓',
                  theme: t,
                  onTap: () {
                    widget.audio.gameStart();
                    _s.setTheme('custom');
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    _s.resetCustomColors();
                    setState(() {});
                  },
                  child: Text('Reset colors ↺',
                      style: Felt.label(14, theme: t)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedKey = 0;

  Widget _colorRow(FeltThemeDef t, String key, String label) {
    final idx = _keys.indexWhere((e) => e.$1 == key);
    final selected = _selectedKey == idx;
    final current = Color(_s.customColors[key] ?? 0xFF000000);
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        setState(() => _selectedKey = idx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.railDeep.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.35),
              width: selected ? 2.5 : 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.accent, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Felt.body(15, theme: t)),
            ]),
            if (selected) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sw in _swatches)
                    GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        _s.setCustomColor(key, sw);
                        setState(() {});
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(sw),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: _s.customColors[key] == sw
                                ? t.accentLight
                                : Colors.black.withValues(alpha: 0.35),
                            width: _s.customColors[key] == sw ? 3 : 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
