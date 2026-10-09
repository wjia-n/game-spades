import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';

/// Settings: audio controls, lifetime stats, data reset, about.
class SettingsScreen extends StatefulWidget {
  final SpadesAudio audio;
  final SpadesSettings settings;

  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SpadesSettings get _s => widget.settings;
  FeltThemeDef get _t => _s.theme;

  void _applyAudio() {
    widget.audio.configure(
      musicOn: _s.musicOn,
      sfxOn: _s.sfxOn,
      volume: _s.volume,
    );
    if (_s.musicOn) {
      widget.audio.startMenuMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.felt,
      appBar: AppBar(
        backgroundColor: _t.railDeep,
        foregroundColor: _t.text,
        title: Text('Settings ⚙️', style: Felt.display(20, theme: _t)),
      ),
      body: FeltBackdrop(
        theme: _t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('Sound & music 🎵', style: Felt.display(20, theme: _t)),
              const SizedBox(height: 10),
              SettingRow(
                label: 'Music',
                theme: _t,
                control: FeltToggle(
                  value: _s.musicOn,
                  theme: _t,
                  onChanged: (v) {
                    widget.audio.click();
                    _s.setMusic(v).then((_) => _applyAudio());
                  },
                ),
              ),
              SettingRow(
                label: 'Sound effects',
                theme: _t,
                control: FeltToggle(
                  value: _s.sfxOn,
                  theme: _t,
                  onChanged: (v) {
                    _s.setSfx(v).then((_) => _applyAudio());
                    widget.audio.click();
                  },
                ),
              ),
              SettingRow(
                label: 'Volume',
                theme: _t,
                control: SizedBox(
                  width: 150,
                  child: BeadSlider(
                    value: _s.volume,
                    theme: _t,
                    onChanged: (v) {
                      _s.setVolume(v).then((_) => _applyAudio());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Your table stats 📊', style: Felt.display(20, theme: _t)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _t.railDeep.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _t.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${_s.gamesPlayed}', 'matches'),
                    _stat('${_s.wins}', 'won 🏆'),
                    _stat(
                        _s.bestScore == 0 ? '—' : '${_s.bestScore}',
                        'best score'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('About ♠️', style: Felt.display(20, theme: _t)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _t.railDeep.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _t.accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Spades by WAJIHA — the classic trick-taking card game. '
                  'Bid bold, trump hard, and race to 500.\n\n'
                  'Version 1.0.0 • Made with ♠️ in Karachi.',
                  style: Felt.body(13, theme: _t),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: _confirmReset,
                  child: Text('Reset all data 🗑️',
                      style: Felt.label(14,
                          theme: _t, color: _t.cardRed)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: Felt.display(26, theme: _t)),
      Text(label, style: Felt.body(12, theme: _t)),
    ]);
  }

  void _confirmReset() {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (_) => FeltDialog(
        emoji: '🗑️',
        title: 'Reset everything?',
        theme: _t,
        children: [
          Text(
            'This clears your names, themes, stats and settings. PRO unlock is tied to your Google Play purchase and can be restored.',
            textAlign: TextAlign.center,
            style: Felt.body(14, theme: _t),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: FeltButton(
                label: 'Cancel',
                theme: _t,
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FeltButton(
                label: 'Reset',
                theme: _t,
                onTap: () async {
                  Navigator.pop(context);
                  // Fresh settings object values, then persist.
                  final keep = _s.isPro;
                  _s.musicOn = true;
                  _s.sfxOn = true;
                  _s.volume = 0.8;
                  _s.humans = 1;
                  _s.difficulty = 1;
                  _s.targetScore = 500;
                  _s.nilAllowed = true;
                  _s.playerNames = List.of(SpadesSettings.defaultNames);
                  _s.themeId = 'classic';
                  _s.cardBack = 0;
                  _s.wins = 0;
                  _s.gamesPlayed = 0;
                  _s.bestScore = 0;
                  _s.reviewAsks = 0;
                  _s.isPro = keep;
                  await _s.resetCustomColors();
                  _applyAudio();
                  if (mounted) setState(() {});
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
