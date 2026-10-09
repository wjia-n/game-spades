import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/spades_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';
import '../widgets/playing_card.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Card Room edition.
/// Logo, PLAY, mode setup (humans / difficulty / target / nil), theme picker,
/// card-back picker, player renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final SpadesAudio audio;
  final SpadesSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  SpadesSettings get _s => widget.settings;
  FeltThemeDef get _t => _s.theme;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
    _store.proPurchased.addListener(_onPro);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Felt.body(15, theme: _t)),
        backgroundColor: _t.railDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available.
  /// No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final colors = _t.playerColors;
    final players = [
      for (int i = 0; i < 4; i++)
        SpadesPlayer(
          name: _s.playerNames[i],
          color: colors[i],
          isBot: i >= _s.humans,
        ),
    ];
    final engine = SpadesEngine(
      players: players,
      botDifficulty: BotDifficulty.values[_s.difficulty],
      targetScore: _s.targetScore,
      nilAllowed: _s.nilAllowed,
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.felt,
      body: FeltBackdrop(
        theme: _t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _logo(),
              const SizedBox(height: 18),
              _playButton(),
              const SizedBox(height: 22),
              _sectionTitle('Table setup 🃏'),
              _modeSetup(),
              const SizedBox(height: 18),
              _sectionTitle('Players ✏️'),
              _playerNames(),
              const SizedBox(height: 18),
              _sectionTitle('Felt & finish 🎨'),
              _themePicker(),
              const SizedBox(height: 14),
              _cardBackPicker(),
              const SizedBox(height: 22),
              _footerButtons(),
              const SizedBox(height: 18),
              _tipJarStrip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(children: [
      Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _t.accent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 10),
              blurRadius: 22,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/spades_logo.png', fit: BoxFit.cover),
      ),
      const SizedBox(height: 14),
      Text('SPADES', style: Felt.display(46, theme: _t)),
      const SizedBox(height: 4),
      Text(
        'Bid bold. Trump hard. First to ${_s.targetScore}.',
        style: Felt.body(15, theme: _t, color: _t.text.withValues(alpha: 0.8)),
        textAlign: TextAlign.center,
      ),
      if (_s.isPro)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('♠️ PRO',
              style: Felt.label(14,
                  theme: _t, color: _t.accentLight)),
        ),
    ]);
  }

  Widget _playButton() {
    return Center(
      child: FeltButton(
        label: '▶  DEAL ME IN',
        theme: _t,
        width: 250,
        onTap: _play,
      ),
    );
  }

  Widget _sectionTitle(String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(s, style: Felt.display(20, theme: _t)),
    );
  }

  Widget _modeSetup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _t.railDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        _stepperRow(
          'Humans at the table',
          '${_s.humans} ${'👤' * _s.humans}${_s.humans < 4 ? '  +  ${4 - _s.humans} 🤖' : ''}',
          () => _s.setSetup(
              humans: _s.humans - 1,
              difficulty: _s.difficulty,
              targetScore: _s.targetScore,
              nilAllowed: _s.nilAllowed),
          () => _s.setSetup(
              humans: _s.humans + 1,
              difficulty: _s.difficulty,
              targetScore: _s.targetScore,
              nilAllowed: _s.nilAllowed),
        ),
        const SizedBox(height: 10),
        _choiceRow('Bot skill', const ['Chill 😌', 'Sharp 🧠', 'Shark 🦈🔒'],
            _s.difficulty, (i) {
          if (i == 2 && !_s.isPro) {
            _proNudge();
            return;
          }
          widget.audio.click();
          _s.setSetup(
              humans: _s.humans,
              difficulty: i,
              targetScore: _s.targetScore,
              nilAllowed: _s.nilAllowed);
        }),
        const SizedBox(height: 10),
        _choiceRow('Match target', const ['Quick 250 ⚡', 'Classic 500 🏆'],
            _s.targetScore == 250 ? 0 : 1, (i) {
          widget.audio.click();
          _s.setSetup(
              humans: _s.humans,
              difficulty: _s.difficulty,
              targetScore: i == 0 ? 250 : 500,
              nilAllowed: _s.nilAllowed);
        }),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: Text('Nil bidding (±100) 😱',
                  style: Felt.body(15, theme: _t))),
          FeltToggle(
            value: _s.nilAllowed,
            theme: _t,
            onChanged: (v) {
              widget.audio.click();
              _s.setSetup(
                  humans: _s.humans,
                  difficulty: _s.difficulty,
                  targetScore: _s.targetScore,
                  nilAllowed: v);
            },
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Solo = you vs 3 bots. 2–4 humans = pass-and-play on this device.',
          style: Felt.body(12,
              theme: _t, color: _t.text.withValues(alpha: 0.6)),
        ),
      ]),
    );
  }

  Widget _stepperRow(
      String label, String value, VoidCallback dec, VoidCallback inc) {
    return Row(children: [
      Expanded(child: Text(label, style: Felt.body(15, theme: _t))),
      _stepBtn('−', dec),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(value, style: Felt.label(14, theme: _t)),
      ),
      _stepBtn('+', inc),
    ]);
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _t.accent, width: 2),
          color: _t.railMid,
        ),
        child: Text(label, style: Felt.display(20, theme: _t)),
      ),
    );
  }

  Widget _choiceRow(String label, List<String> options, int selected,
      ValueChanged<int> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Felt.body(15, theme: _t)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < options.length; i++)
              GestureDetector(
                onTap: () => onPick(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: selected == i
                        ? _t.accent
                        : _t.railMid.withValues(alpha: 0.7),
                    border: Border.all(
                        color: _t.accent,
                        width: selected == i ? 2.5 : 1.5),
                  ),
                  child: Text(
                    options[i],
                    style: Felt.body(13,
                        theme: _t,
                        color: selected == i
                            ? _t.railDeep
                            : _t.text),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _proNudge() {
    widget.audio.click();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🦈 Shark bots are a PRO feature — check the Pro tab!',
            style: Felt.body(14, theme: _t)),
        backgroundColor: _t.railDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _playerNames() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _t.railDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _t.playerColors[i],
                  border: Border.all(color: _t.accent, width: 2),
                ),
                child: Text(
                  i < _s.humans ? '👤' : '🤖',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NameField(
                  key: ValueKey('name_$i'),
                  theme: _t,
                  initial: _s.playerNames[i],
                  hint: i < _s.humans ? 'Human ${i + 1}' : 'Bot ${i + 1}',
                  // Save on EVERY keystroke (not just keyboard-done) and
                  // commit on focus loss — names never get lost.
                  onChanged: (v) => _s.setPlayerName(i, v),
                  onSubmitted: (_) {
                    widget.audio.click();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ]),
          ),
        const SizedBox(height: 4),
        Text(
          'Tap a name to rename. Bots are seats after the humans.',
          style: Felt.body(12,
              theme: _t, color: _t.text.withValues(alpha: 0.6)),
        ),
      ]),
    );
  }

  Widget _themePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text('Table felt', style: Felt.body(15, theme: _t))),
          GestureDetector(
            onTap: () {
              widget.audio.click();
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => CustomThemeScreen(
                          audio: widget.audio, settings: _s)))
                  .then((_) => setState(() {}));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _t.accent, width: 2),
                color: _t.railMid,
              ),
              child: Text('🎨 Custom${_s.isPro ? '' : ' 🔒'}',
                  style: Felt.label(13, theme: _t)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemCount: FeltThemes.all.length,
          itemBuilder: (_, i) {
            final th = FeltThemes.all[i];
            final pro = FeltThemes.isProTheme(th.id);
            final sel = _s.themeId == th.id;
            return GestureDetector(
              onTap: () {
                if (pro && !_s.isPro) {
                  _proNudge();
                  return;
                }
                widget.audio.click();
                _s.setTheme(th.id);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: th.felt,
                  border: Border.all(
                      color: sel ? _t.accentLight : th.accent.withValues(alpha: 0.4),
                      width: sel ? 3 : 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4),
                  ],
                ),
                child: Stack(children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(th.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: th.text)),
                    ),
                  ),
                  if (pro && !_s.isPro)
                    const Positioned(
                      top: 4,
                      right: 6,
                      child: Text('🔒', style: TextStyle(fontSize: 12)),
                    ),
                  if (sel)
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Text('✓',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: th.accentLight)),
                    ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _cardBackPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card backs', style: Felt.body(15, theme: _t)),
        const SizedBox(height: 8),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CardBacks.names.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final pro = CardBacks.isPro(i);
              final sel = _s.cardBack == i;
              return GestureDetector(
                onTap: () {
                  if (pro && !_s.isPro) {
                    _proNudge();
                    return;
                  }
                  widget.audio.click();
                  _s.setCardBack(i);
                },
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel
                              ? _t.accentLight
                              : _t.accent.withValues(alpha: 0.35),
                          width: sel ? 3 : 1.5),
                    ),
                    child: Stack(children: [
                      CardBack(theme: _t, style: i, width: 52),
                      if (pro && !_s.isPro)
                        const Positioned(
                          top: 2,
                          right: 4,
                          child: Text('🔒', style: TextStyle(fontSize: 12)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(CardBacks.names[i],
                      style: Felt.body(10, theme: _t)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _footerButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _menuBtn('⚙️ Settings', () {
          widget.audio.click();
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                      audio: widget.audio, settings: _s)))
              .then((_) => setState(() {}));
        }),
        _menuBtn('♠️ Pro', () {
          widget.audio.click();
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (_) => ProScreen(
                      audio: widget.audio,
                      settings: _s,
                      store: _store)))
              .then((_) => setState(() {}));
        }),
        _menuBtn('📖 Rules', _showRules),
        _menuBtn('📣 Share', () {
          widget.audio.click();
          Share.share(
            'Spades — bid bold, trump hard! ♠️ '
            'https://play.google.com/store/apps/details?id=com.gameswajiha.spades',
          );
        }),
        _menuBtn('⭐ Rate', _requestReview),
      ],
    );
  }

  Widget _menuBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _t.railDeep.withValues(alpha: 0.7),
          border: Border.all(color: _t.accent, width: 2),
        ),
        child: Text(label, style: Felt.label(14, theme: _t)),
      ),
    );
  }

  void _showRules() {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (_) => FeltDialog(
        emoji: '📖',
        title: 'Quick rules',
        theme: _t,
        children: [
          Text(
            '• 4 players, 13 cards each. You bid first? No — dealer rotates!\n'
            '• Bid tricks you\'ll take, or NIL (±100).\n'
            '• Follow suit. Spades trump, can\'t lead until broken.\n'
            '• Bid made: 10× bid + overtricks. Missed: −10× bid.\n'
            '• First to ${_s.targetScore} wins. Details in RULES.',
            style: Felt.body(14, theme: _t),
          ),
          const SizedBox(height: 14),
          FeltButton(
            label: 'Got it 👍',
            theme: _t,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _tipJarStrip() {
    if (_store.storeReady) {
      final coffee = _store.coffeeProduct;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _t.railDeep.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              'Enjoying the table? A tip keeps the cards coming! ☕',
              style: Felt.body(13, theme: _t),
            ),
          ),
          if (coffee != null)
            _menuBtn('☕ ${coffee.price}', () => _store.buyTip(coffee)),
        ]),
      );
    }
    return Text(
      'Made with ♠️ by WAJIHA',
      textAlign: TextAlign.center,
      style: Felt.body(12, theme: _t, color: _t.text.withValues(alpha: 0.6)),
    );
  }
}

/// Inline rename field for a seat. Saves on every keystroke and commits
/// on focus loss, so a rename can never be lost.
class _NameField extends StatefulWidget {
  final FeltThemeDef theme;
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _NameField({
    super.key,
    required this.theme,
    required this.initial,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) widget.onChanged(_c.text);
      },
      child: TextField(
        controller: _c,
        maxLength: 14,
        style: Felt.body(15, theme: widget.theme),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: Felt.body(14,
              theme: widget.theme,
              color: widget.theme.text.withValues(alpha: 0.4)),
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: widget.theme.accent.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: widget.theme.accentLight, width: 2),
          ),
          filled: true,
          fillColor: widget.theme.railMid.withValues(alpha: 0.5),
        ),
        textInputAction: TextInputAction.done,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
