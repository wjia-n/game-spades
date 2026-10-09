import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/spades_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';
import '../widgets/playing_card.dart';

/// The card table: opponents strip, felt table with animated trick play,
/// bidding bar, and the viewing seat's hand. The engine owns all state;
/// this screen only renders and forwards human taps.
class GameScreen extends StatefulWidget {
  final SpadesEngine engine;
  final SpadesAudio audio;
  final SpadesSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  SpadesEngine get _e => widget.engine;
  SpadesSettings get _s => widget.settings;
  FeltThemeDef get _t => _s.theme;

  int _shownScoreHand = -1;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.startGameMusic();
    _e.onEvent = _onEvent;
    _e.addListener(_onEngine);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngine);
    _e.onEvent = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine while backgrounded; watchdog re-arms on resume.
    if (state == AppLifecycleState.paused) {
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      _e.setPaused(false);
    }
  }

  void _onEngine() {
    if (!mounted) return;
    setState(() {});
    // Hand scored → show the score sheet (once per hand).
    if (_e.phase == SpadesPhase.handScore && _shownScoreHand != _e.handNo) {
      _shownScoreHand = _e.handNo;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHandScore());
    }
    // Match over → results sheet (once).
    if (_e.phase == SpadesPhase.matchOver && !_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMatchOver());
    }
  }

  void _onEvent(SpadesEvent ev) {
    final a = widget.audio;
    switch (ev) {
      case SpadesEvent.shuffle:
        a.shuffle();
        break;
      case SpadesEvent.deal:
        a.deal();
        break;
      case SpadesEvent.bid:
        a.bid();
        break;
      case SpadesEvent.cardPlay:
        a.cardPlay();
        break;
      case SpadesEvent.spadeBroken:
        a.spadeBroken();
        break;
      case SpadesEvent.trickWon:
        a.trickWon();
        break;
      case SpadesEvent.nilGood:
        a.nilGood();
        break;
      case SpadesEvent.nilBad:
        a.nilBad();
        break;
      case SpadesEvent.handDone:
      case SpadesEvent.invalid:
        a.invalid();
        break;
      case SpadesEvent.humanWon:
        a.win();
        break;
      case SpadesEvent.botWon:
        a.lose();
        break;
    }
  }

  // ------------------------------------------------------------- overlays
  Future<void> _showHandScore() async {
    if (!mounted) return;
    final matchOver = _e.players.any((p) => p.score >= _e.targetScore);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeltDialog(
        emoji: '♠️',
        title: 'Hand ${_e.handNo} scored!',
        theme: _t,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${_e.players[i].name}: bid ${_e.isNil[i] ? 'NIL' : _e.bids[i]}, '
                'took ${_e.tricksWon[i]} → '
                '${_e.lastDeltas[i] >= 0 ? '+' : ''}${_e.lastDeltas[i]} '
                '(total ${_e.players[i].score})',
                textAlign: TextAlign.center,
                style: Felt.body(14, theme: _t),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            matchOver
                ? 'Someone hit ${_e.targetScore} — crown the champion! 👑'
                : 'First to ${_e.targetScore} wins. Bid braver next time! 😎',
            textAlign: TextAlign.center,
            style: Felt.body(13,
                theme: _t, color: _t.text.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          FeltButton(
            label: matchOver ? 'See results 🏁' : 'Next hand ♠️',
            theme: _t,
            onTap: () {
              Navigator.pop(context);
              if (!matchOver) _e.nextHand();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMatchOver() async {
    if (!mounted) return;
    final w = _e.winnerSeat ?? 0;
    final humanWon = !_e.players[w].isBot;
    await _s.recordGame(humanWon: humanWon, score: _e.players[w].score);
    // Sensible review moment: a human victory, throttled.
    if (humanWon && _s.reviewAsks < 2) {
      await _s.bumpReviewAsks();
      _requestReview();
    }
    if (!mounted) return;
    final scores = _e.players
        .map((p) => '${p.name}: ${p.score}')
        .join('   •   ');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeltDialog(
        emoji: '🏆',
        title: '${_e.players[w].name} wins!',
        theme: _t,
        children: [
          Text(
            'Final scores — $scores.',
            textAlign: TextAlign.center,
            style: Felt.body(14, theme: _t),
          ),
          const SizedBox(height: 6),
          Text(
            humanWon
                ? 'You trumped them all! The table bows to you. ♠️'
                : 'The bots bow to no one. Rematch? 🤖',
            textAlign: TextAlign.center,
            style: Felt.body(13,
                theme: _t, color: _t.text.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          FeltButton(
            label: 'Rematch ♠️',
            theme: _t,
            onTap: () {
              widget.audio.gameStart();
              Navigator.pop(context);
              _recorded = false;
              _shownScoreHand = -1;
              _e.restart();
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallBtn('Share 📣', () {
                widget.audio.click();
                Share.share(
                  'I just played Spades — bid bold, trump hard! '
                  'https://play.google.com/store/apps/details?id=com.gameswajiha.spades',
                );
              }),
              const SizedBox(width: 10),
              _smallBtn('Menu 🏠', () {
                Navigator.pop(context);
                Navigator.pop(context);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _t.accent, width: 2),
          color: _t.railDeep.withValues(alpha: 0.6),
        ),
        child: Text(label, style: Felt.label(14, theme: _t)),
      ),
    );
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Graceful: review UI unavailable on this device/build — stay silent.
    }
  }

  void _pauseMenu() {
    widget.audio.click();
    _e.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeltDialog(
        emoji: '⏸️',
        title: 'Paused',
        theme: _t,
        children: [
          FeltButton(
            label: 'Resume ▶️',
            theme: _t,
            onTap: () {
              Navigator.pop(context);
              _e.setPaused(false);
            },
          ),
          const SizedBox(height: 10),
          FeltButton(
            label: 'Restart match 🔄',
            theme: _t,
            onTap: () {
              Navigator.pop(context);
              _recorded = false;
              _shownScoreHand = -1;
              _e.restart();
            },
          ),
          const SizedBox(height: 10),
          FeltButton(
            label: 'How to play 📖',
            theme: _t,
            onTap: () {
              // Keep the pause menu open underneath; "Got it" just closes
              // the rules sheet back to the still-paused menu.
              widget.audio.click();
              _howToPlay();
            },
          ),
          const SizedBox(height: 10),
          FeltButton(
            label: 'Quit to menu 🏠',
            theme: _t,
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _e.phase != SpadesPhase.matchOver) _e.setPaused(false);
    });
  }

  void _howToPlay() {
    showDialog(
      context: context,
      builder: (_) => FeltDialog(
        emoji: '📖',
        title: 'How to play',
        theme: _t,
        children: [
          Text(
            '• Bid how many tricks you\'ll take — or go NIL for a ±100 thrill!\n'
            '• Follow suit if you can. Spades are trump but can\'t lead until broken.\n'
            '• Make your bid: 10× bid + 1 per overtrick. Miss it: −10× bid.\n'
            '• First to ${_e.targetScore} wins the match.',
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

  // ----------------------------------------------------------------- UI

  /// Which seat's hand the device currently shows face-up.
  int get _viewSeat {
    if (_soloView) return 0;
    if (_e.phase == SpadesPhase.bidding) return _e.bidTurn;
    if (_e.phase == SpadesPhase.playing) return _e.turn;
    return 0;
  }

  bool get _soloView {
    // Solo mode: exactly one human (seat 0), rest bots.
    return _e.players.where((p) => !p.isBot).length == 1 &&
        !_e.players[0].isBot;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _e.setPaused(true);
      },
      child: Scaffold(
        backgroundColor: _t.felt,
        appBar: AppBar(
          backgroundColor: _t.railDeep,
          foregroundColor: _t.text,
          title: Text('Spades — Hand ${_e.handNo}',
              style: Felt.display(18, theme: _t)),
          actions: [
            IconButton(
              icon: const Text('⏸️', style: TextStyle(fontSize: 22)),
              onPressed: _pauseMenu,
            ),
          ],
        ),
        body: FeltBackdrop(
          theme: _t,
          child: SafeArea(
            child: Column(
              children: [
                _opponentsStrip(),
                const SizedBox(height: 6),
                Expanded(child: _table()),
                const SizedBox(height: 6),
                _banner(),
                const SizedBox(height: 8),
                if (_e.phase == SpadesPhase.bidding)
                  _bidBar()
                else
                  _handArea(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _opponentsStrip() {
    // Seats 1..3 sit around the table; each has its own tray.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (var i = 1; i < 4; i++) _seatTray(i)],
      ),
    );
  }

  Widget _seatTray(int i) {
    final p = _e.players[i];
    final active = (_e.phase == SpadesPhase.playing && _e.turn == i) ||
        (_e.phase == SpadesPhase.bidding && _e.bidTurn == i);
    final bidTxt = _e.phase == SpadesPhase.dealing
        ? ''
        : _e.phase == SpadesPhase.bidding
            ? (i == _e.bidTurn ? 'bidding…' : '')
            : 'bid ${_e.isNil[i] ? 'NIL' : _e.bids[i]} • took ${_e.tricksWon[i]}';
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? p.color.withValues(alpha: 0.30)
              : _t.railDeep.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? _t.accentLight : _t.accent.withValues(alpha: 0.35),
              width: active ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: 6),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(p.name,
              style: Felt.label(13, theme: _t),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            CardBack(theme: _t, style: _s.cardBack, width: 20),
            const SizedBox(width: 4),
            Text('×${_e.hands[i].length}',
                style: Felt.body(12, theme: _t)),
            const SizedBox(width: 8),
            Text('⭐ ${p.score}',
                style: Felt.body(12, theme: _t)),
          ]),
          if (bidTxt.isNotEmpty)
            Text(bidTxt,
                style: Felt.body(11,
                    theme: _t, color: _t.accentLight)),
        ]),
      ),
    );
  }

  Widget _table() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _t.accent, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 6),
                blurRadius: 14),
            BoxShadow(
                color: _t.accentLight.withValues(alpha: 0.25),
                offset: const Offset(0, -2),
                blurRadius: 4),
          ],
          gradient: RadialGradient(
            center: const Alignment(0, 0),
            radius: 1.1,
            colors: [
              _t.felt.withValues(alpha: 0.9),
              _t.feltDeep,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Trick cards around the center, one slot per seat.
            ..._trickSlots(w, h),
            // Deck + dealing animation.
            if (_e.phase == SpadesPhase.dealing) _dealOverlay(w, h),
            // Spades-broken badge.
            if (_e.spadesBroken &&
                _e.phase != SpadesPhase.dealing)
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _t.railDeep.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _t.accent, width: 1.5),
                  ),
                  child: Text('💥 Spades broken',
                      style: Felt.label(12, theme: _t)),
                ),
              ),
            // Empty-table hint.
            if (_e.trick.isEmpty &&
                _e.phase != SpadesPhase.dealing)
              Center(
                child: Text(
                  _e.phase == SpadesPhase.bidding
                      ? '♠️ Bids are in soon…'
                      : '♠️ Waiting for ${{
                        0: 'bottom',
                        1: 'left',
                        2: 'top',
                        3: 'right'
                      }[_e.turn] ?? ''} player…',
                  textAlign: TextAlign.center,
                  style: Felt.body(15,
                      theme: _t,
                      color: _t.text.withValues(alpha: 0.6)),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Table slot per seat: bottom(0), left(1), top(2), right(3).
  List<Widget> _trickSlots(double w, double h) {
    final slots = <int, Offset>{
      0: Offset(w / 2, h - 78),
      1: Offset(52, h / 2),
      2: Offset(w / 2, 78),
      3: Offset(w - 52, h / 2),
    };
    return [
      for (final play in _e.trick)
        Positioned(
          left: slots[play.seat]!.dx - 31,
          top: slots[play.seat]!.dy - 44,
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 220),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayingCard(
                  card: play.card,
                  theme: _t,
                  width: 62,
                  highlighted: _e.trickWinnerSeat == play.seat,
                ),
                const SizedBox(height: 2),
                Text(
                  _e.players[play.seat].name,
                  style: Felt.label(10, theme: _t),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _dealOverlay(double w, double h) {
    // Deck in the middle; a card back flies to the current seat each step.
    final seatTargets = <int, Offset>{
      0: Offset(w / 2, h - 60),
      1: Offset(44, h / 2),
      2: Offset(w / 2, 60),
      3: Offset(w - 44, h / 2),
    };
    final seat = (_e.dealer + 1 + _e.dealStep) % 4;
    final target = seatTargets[seat]!;
    return Stack(
      children: [
        // Deck.
        Positioned(
          left: w / 2 - 22,
          top: h / 2 - 31,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(left: i * 3.0, top: i * 3.0),
                  child: CardBack(theme: _t, style: _s.cardBack, width: 44),
                ),
            ],
          ),
        ),
        // Flying card, keyed per step so it re-animates every deal.
        TweenAnimationBuilder<double>(
          key: ValueKey(_e.dealStep),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 75),
          builder: (_, v, __) {
            final dx = w / 2 + (target.dx - w / 2) * v;
            final dy = h / 2 + (target.dy - h / 2) * v;
            return Positioned(
              left: dx - 22,
              top: dy - 31,
              child: Opacity(
                opacity: 1 - v * 0.4,
                child: CardBack(theme: _t, style: _s.cardBack, width: 44),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _t.railDeep.withValues(alpha: 0.75),
        border: Border.all(color: _t.accent.withValues(alpha: 0.5)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(
          _e.banner,
          key: ValueKey(_e.banner),
          textAlign: TextAlign.center,
          style: Felt.body(14, theme: _t),
        ),
      ),
    );
  }

  Widget _bidBar() {
    final humanTurn = _e.awaitingHumanBid &&
        !_e.players[_e.bidTurn].isBot &&
        _e.phase == SpadesPhase.bidding;
    final name = _e.players[_e.bidTurn].name;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        humanTurn
            ? '$name — your bid! How many tricks? (NIL = ±100!)'
            : '♠️ $name is bidding…',
        style: Felt.label(14, theme: _t),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _s.nilAllowed ? 15 : 14,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final isNilBtn = i == 14;
            final label = isNilBtn ? 'NIL 😱' : '$i';
            return GestureDetector(
              onTap: !humanTurn
                  ? null
                  : () {
                      widget.audio.click();
                      _e.placeBid(_e.bidTurn, isNilBtn ? 0 : i,
                          nil: isNilBtn);
                    },
              child: Opacity(
                opacity: !humanTurn ? 0.4 : 1,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isNilBtn
                          ? [_t.cardRed, _t.cardBlack]
                          : [_t.railMid, _t.railDeep],
                    ),
                    border: Border.all(color: _t.accent, width: 2),
                  ),
                  child: Text(label,
                      style: Felt.display(16, theme: _t)),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _handArea() {
    final vs = _viewSeat;
    final hand = _e.hands[vs];
    final isViewer = !_e.players[vs].isBot;
    final myTurn =
        _e.phase == SpadesPhase.playing && _e.turn == vs && isViewer;
    final legal = myTurn ? _e.legalCards(vs).toSet() : null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          isViewer
              ? '${_e.players[vs].name}\'s hand'
              : '${_e.players[vs].name}\'s cards',
          style: Felt.label(13, theme: _t),
        ),
        const SizedBox(width: 10),
        if (_e.phase != SpadesPhase.dealing)
          Text(
            'bid ${_e.isNil[vs] ? 'NIL' : _e.bids[vs]} • took ${_e.tricksWon[vs]} • ⭐ ${_e.players[vs].score}',
            style: Felt.body(12,
                theme: _t, color: _t.text.withValues(alpha: 0.75)),
          ),
      ]),
      const SizedBox(height: 6),
      SizedBox(
        height: 104,
        child: isViewer
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: hand.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final c = hand[i];
                  final ok = legal == null ? false : legal.contains(c);
                  final tappable = myTurn && ok;
                  return GestureDetector(
                    onTap: !tappable
                        ? (myTurn && !ok
                            ? () => widget.audio.invalid()
                            : null)
                        : () => _e.playCard(vs, c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transform: Matrix4.translationValues(
                          0, tappable && ok ? 0 : (myTurn ? 6 : 0), 0),
                      child: PlayingCard(
                        card: c,
                        theme: _t,
                        width: 66,
                        dimmed: myTurn ? !ok : !myTurn,
                      ),
                    ),
                  );
                },
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < hand.length.clamp(0, 8); i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: CardBack(
                          theme: _t, style: _s.cardBack, width: 40),
                    ),
                  if (hand.isEmpty)
                    Text('No cards yet — dealing…',
                        style: Felt.body(13, theme: _t)),
                ],
              ),
      ),
    ]);
  }
}
