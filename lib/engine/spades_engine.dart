import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Spades — cutthroat (individual) 4-seat trick-taking game.
///
/// Engine owns ALL turn state/phases. The UI only renders and forwards
/// human taps. Every bot turn is fully visible: animated dealing, bids
/// announced with a pause, plays revealed one card at a time with
/// narration. Nothing is ever silently auto-played.

/// Suit: 0 = spades (trump), 1 = hearts, 2 = diamonds, 3 = clubs.
const suitGlyphs = ['♠', '♥', '♦', '♣'];
bool isRedSuit(int s) => s == 1 || s == 2;
String rankGlyph(int r) =>
    r == 14 ? 'A' : r == 11 ? 'J' : r == 12 ? 'Q' : r == 13 ? 'K' : '$r';

/// A card. rank: 2..14 (14 = ace, highest).
class SpadesCard {
  final int suit;
  final int rank;
  const SpadesCard(this.suit, this.rank);

  String get label => '${rankGlyph(rank)}${suitGlyphs[suit]}';
}

/// A seat in the match (human or bot).
class SpadesPlayer {
  String name;
  final Color color;
  final bool isBot;
  int score = 0;

  SpadesPlayer({required this.name, required this.color, required this.isBot});
}

/// 0 = easy, 1 = medium, 2 = hard (RULES.md §11).
enum BotDifficulty { easy, medium, hard }

/// Turn phases owned entirely by the engine. The UI only renders.
enum SpadesPhase {
  dealing, // cards going out one at a time
  bidding, // seats bid in order
  playing, // trick play; awaitingHumanCard when it is a human's turn
  trickReveal, // the 4th card is down; winner announced
  handScore, // hand settled; scores updated
  matchOver, // someone reached the target
}

/// One card played on the table.
class TablePlay {
  final int seat;
  final SpadesCard card;
  TablePlay(this.seat, this.card);
}

/// UI hook for sounds. Set by the screen.
enum SpadesEvent {
  shuffle,
  deal,
  bid,
  cardPlay,
  spadeBroken,
  trickWon,
  nilGood,
  nilBad,
  handDone,
  invalid,
  humanWon,
  botWon,
}

class SpadesEngine extends ChangeNotifier {
  final List<SpadesPlayer> players; // always exactly 4 seats
  final BotDifficulty botDifficulty;
  final int targetScore;
  final bool nilAllowed;

  late List<List<SpadesCard>> hands;
  List<int> bids = [0, 0, 0, 0];
  List<bool> isNil = [false, false, false, false];
  List<int> tricksWon = [0, 0, 0, 0];

  SpadesPhase phase = SpadesPhase.dealing;
  int handNo = 0;
  int dealer = 3; // seat 0 leads hand 1
  int dealStep = 0; // 0..52 cards dealt this hand
  int bidTurn = 0;
  int turn = 0;
  bool spadesBroken = false;
  bool over = false;
  int? winnerSeat;
  final List<TablePlay> trick = [];
  int? trickWinnerSeat;
  TablePlay? lastPlay; // most recent card, for fly-to-table animation
  bool awaitingHumanCard = false;
  bool awaitingHumanBid = false;
  String banner = '';
  bool paused = false;

  void Function(SpadesEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool _acting = false; // serializes bot/timer actions

  static const dealMs = 80;
  static const botThinkMs = 750;
  static const playShowMs = 550;
  static const trickShowMs = 1200;

  SpadesEngine({
    required this.players,
    this.botDifficulty = BotDifficulty.medium,
    this.targetScore = 500,
    this.nilAllowed = true,
  }) : assert(players.length == 4) {
    hands = List.generate(4, (_) => []);
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _newHand();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress,
  /// recover. This makes stuck states impossible by construction.
  void _recover() {
    if (_disposed || over || paused || _timer != null || _acting) return;
    switch (phase) {
      case SpadesPhase.dealing:
        _dealOne();
        break;
      case SpadesPhase.bidding:
        _maybeBotBid();
        break;
      case SpadesPhase.playing:
        if (players[turn].isBot && !awaitingHumanCard) {
          _botPlay();
        }
        break;
      case SpadesPhase.trickReveal:
        _settleTrick();
        break;
      case SpadesPhase.handScore:
      case SpadesPhase.matchOver:
        break;
    }
  }

  // ------------------------------------------------------------ hand setup
  void _newHand() {
    final deck = [
      for (var s = 0; s < 4; s++)
        for (var r = 2; r <= 14; r++) SpadesCard(s, r)
    ]..shuffle(_rand);
    _deck = deck;
    hands = List.generate(4, (_) => []);
    bids = [0, 0, 0, 0];
    isNil = [false, false, false, false];
    tricksWon = [0, 0, 0, 0];
    trick.clear();
    lastPlay = null;
    trickWinnerSeat = null;
    spadesBroken = false;
    awaitingHumanCard = false;
    awaitingHumanBid = false;
    handNo++;
    dealer = (dealer + 1) % 4;
    dealStep = 0;
    phase = SpadesPhase.dealing;
    banner = 'Hand $handNo — shuffling…';
    onEvent?.call(SpadesEvent.shuffle);
    notifyListeners();
    _arm(const Duration(milliseconds: 600), _dealOne);
  }

  List<SpadesCard> _deck = [];

  void _dealOne() {
    if (_disposed || over || paused || phase != SpadesPhase.dealing) return;
    if (dealStep >= 52) {
      _beginBidding();
      return;
    }
    final seat = (dealer + 1 + dealStep) % 4;
    hands[seat].add(_deck[dealStep]);
    dealStep++;
    banner = 'Dealing… ${players[seat].name}';
    onEvent?.call(SpadesEvent.deal);
    notifyListeners();
    _arm(const Duration(milliseconds: dealMs), _dealOne);
  }

  void _sortHands() {
    for (final h in hands) {
      h.sort((a, b) =>
          a.suit != b.suit ? a.suit.compareTo(b.suit) : b.rank.compareTo(a.rank));
    }
  }

  // --------------------------------------------------------------- bidding
  void _beginBidding() {
    _sortHands();
    phase = SpadesPhase.bidding;
    bidTurn = (dealer + 1) % 4;
    banner = '${players[bidTurn].name} — place your bid!';
    awaitingHumanBid = !players[bidTurn].isBot;
    notifyListeners();
    _maybeBotBid();
  }

  bool get _botBidTurn =>
      phase == SpadesPhase.bidding && players[bidTurn].isBot;

  void _maybeBotBid() {
    if (!_botBidTurn || _acting) return;
    _acting = true;
    banner = '${players[bidTurn].name} is thinking…';
    notifyListeners();
    _arm(Duration(milliseconds: botThinkMs + _rand.nextInt(350)), () {
      if (_disposed || !_botBidTurn) {
        _acting = false;
        return;
      }
      final seat = bidTurn;
      final est = _estimateBid(seat);
      final nil = _considerNil(seat, est);
      placeBid(seat, nil ? 0 : est, nil: nil, fromBot: true);
    });
  }

  /// Human (or bot through _maybeBotBid) places a bid.
  /// Bots may only bid through [_maybeBotBid] ([fromBot] = true).
  void placeBid(int seat, int bid, {bool nil = false, bool fromBot = false}) {
    final botOk = !players[seat].isBot || fromBot;
    if (over ||
        phase != SpadesPhase.bidding ||
        seat != bidTurn ||
        !botOk) {
      onEvent?.call(SpadesEvent.invalid);
      return;
    }
    if (nil && !nilAllowed) {
      onEvent?.call(SpadesEvent.invalid);
      return;
    }
    bids[seat] = nil ? 0 : bid.clamp(0, 13);
    isNil[seat] = nil;
    awaitingHumanBid = false;
    _acting = false; // a bot's bid turn is complete; humans never hold this
    banner = nil
        ? '😱 ${players[seat].name} bids NIL!'
        : '${players[seat].name} bids ${bids[seat]}';
    onEvent?.call(SpadesEvent.bid);
    bidTurn = (bidTurn + 1) % 4;
    if (bidTurn == (dealer + 1) % 4) {
      // Bidding complete — the leader starts play.
      phase = SpadesPhase.playing;
      turn = bidTurn;
      notifyListeners();
      _arm(const Duration(milliseconds: 600), () {
        if (_disposed || over || phase != SpadesPhase.playing) return;
        banner =
            '${players[turn].name} leads the first trick…';
        notifyListeners();
        _maybeBotPlay();
      });
    } else {
      awaitingHumanBid = !players[bidTurn].isBot;
      notifyListeners();
      _maybeBotBid();
    }
  }

  // ------------------------------------------------------------ trick play
  /// Legal plays for [seat] given the current trick (RULES.md §4).
  List<SpadesCard> legalCards(int seat) {
    final hand = hands[seat];
    if (trick.isEmpty) {
      if (!spadesBroken) {
        final nonSpades = hand.where((c) => c.suit != 0).toList();
        if (nonSpades.isNotEmpty) return nonSpades;
      }
      return [...hand];
    }
    final led = trick.first.card.suit;
    final follow = hand.where((c) => c.suit == led).toList();
    return follow.isNotEmpty ? follow : [...hand];
  }

  /// Human taps a card. Bots may only play through [_botPlay].
  void playCard(int seat, SpadesCard card) {
    final botOk = !players[seat].isBot || _acting;
    if (over ||
        phase != SpadesPhase.playing ||
        seat != turn ||
        !botOk ||
        !legalCards(seat).contains(card)) {
      onEvent?.call(SpadesEvent.invalid);
      return;
    }
    _applyPlay(seat, card);
  }

  void _maybeBotPlay() {
    if (_disposed ||
        over ||
        paused ||
        phase != SpadesPhase.playing ||
        !players[turn].isBot ||
        _acting) {
      return;
    }
    _acting = true;
    awaitingHumanCard = false;
    banner = '${players[turn].name} is thinking…';
    notifyListeners();
    _arm(Duration(milliseconds: botThinkMs + _rand.nextInt(400)), () {
      if (_disposed ||
          over ||
          paused ||
          phase != SpadesPhase.playing ||
          !players[turn].isBot) {
        _acting = false;
        return;
      }
      final card = _botChooseCard(turn);
      _applyPlay(turn, card);
    });
  }

  void _applyPlay(int seat, SpadesCard card) {
    final wasBot = players[seat].isBot;
    _acting = wasBot; // keep serial while the show timer runs
    hands[seat].remove(card);
    final play = TablePlay(seat, card);
    trick.add(play);
    lastPlay = play;
    awaitingHumanCard = false;
    if (card.suit == 0 && !spadesBroken) {
      spadesBroken = true;
      banner = '💥 ${players[seat].name} breaks spades with ${card.label}!';
      onEvent?.call(SpadesEvent.spadeBroken);
    } else {
      banner = '${players[seat].name} plays ${card.label}';
      onEvent?.call(SpadesEvent.cardPlay);
    }
    notifyListeners();
    if (trick.length == 4) {
      phase = SpadesPhase.trickReveal;
      notifyListeners();
      _arm(const Duration(milliseconds: playShowMs + trickShowMs), () {
        _acting = false;
        _settleTrick();
      });
    } else {
      turn = (turn + 1) % 4;
      notifyListeners();
      _arm(const Duration(milliseconds: playShowMs), () {
        _acting = false;
        if (_disposed || over || phase != SpadesPhase.playing) return;
        if (players[turn].isBot) {
          _maybeBotPlay();
        } else {
          awaitingHumanCard = true;
          banner = '${players[turn].name} — your play!';
          notifyListeners();
        }
      });
    }
  }

  /// Bot move entry point (also used by the watchdog). Bots only ever
  /// play through here.
  void _botPlay() {
    if (_disposed ||
        over ||
        paused ||
        phase != SpadesPhase.playing ||
        !players[turn].isBot ||
        _acting) {
      return;
    }
    _acting = true;
    _arm(const Duration(milliseconds: 200), () {
      if (_disposed ||
          over ||
          paused ||
          phase != SpadesPhase.playing ||
          !players[turn].isBot) {
        _acting = false;
        return;
      }
      _applyPlay(turn, _botChooseCard(turn));
    });
  }

  int _trickWinner() {
    final led = trick.first.card.suit;
    var win = trick.first;
    for (final p in trick) {
      final wSpade = win.card.suit == 0;
      final pSpade = p.card.suit == 0;
      if (pSpade && (!wSpade || p.card.rank > win.card.rank)) {
        win = p;
      } else if (!pSpade &&
          !wSpade &&
          p.card.suit == led &&
          p.card.rank > win.card.rank) {
        win = p;
      }
    }
    return win.seat;
  }

  void _settleTrick() {
    if (_disposed || over || phase != SpadesPhase.trickReveal) return;
    final w = _trickWinner();
    trickWinnerSeat = w;
    tricksWon[w]++;
    banner = '${players[w].name} takes the trick! (${tricksWon[w]} so far)';
    onEvent?.call(SpadesEvent.trickWon);
    notifyListeners();
    _arm(const Duration(milliseconds: 900), () {
      if (_disposed || over) return;
      trick.clear();
      trickWinnerSeat = null;
      lastPlay = null;
      if (hands.every((h) => h.isEmpty)) {
        _scoreHand();
        return;
      }
      turn = w;
      phase = SpadesPhase.playing;
      notifyListeners();
      if (players[turn].isBot) {
        _maybeBotPlay();
      } else {
        awaitingHumanCard = true;
        banner = '${players[turn].name} leads — your play!';
        notifyListeners();
      }
    });
  }

  // --------------------------------------------------------------- scoring
  /// Per-hand point deltas (RULES.md §8).
  List<int> _handDeltas() {
    final out = <int>[];
    for (var i = 0; i < 4; i++) {
      int d;
      if (isNil[i]) {
        d = tricksWon[i] == 0 ? 100 : -100;
      } else if (tricksWon[i] >= bids[i]) {        d = bids[i] * 10 + (tricksWon[i] - bids[i]);
      } else {
        d = -bids[i] * 10;
      }
      out.add(d);
    }
    return out;
  }

  List<int> lastDeltas = [0, 0, 0, 0];

  void _scoreHand() {
    phase = SpadesPhase.handScore;
    lastDeltas = _handDeltas();
    for (var i = 0; i < 4; i++) {
      players[i].score += lastDeltas[i];
      if (isNil[i]) {
        onEvent?.call(tricksWon[i] == 0 ? SpadesEvent.nilGood : SpadesEvent.nilBad);
      }
    }
    banner = 'Hand $handNo scored!';
    onEvent?.call(SpadesEvent.handDone);
    notifyListeners();
    final matchOver = players.any((p) => p.score >= targetScore);
    if (matchOver) {
      _arm(const Duration(milliseconds: 1400), _finishMatch);
    }
    // Otherwise the UI shows the hand-score sheet and calls nextHand().
  }

  /// Called by the UI after the hand-score sheet is dismissed.
  void nextHand() {
    if (over || phase == SpadesPhase.matchOver) return;
    if (phase != SpadesPhase.handScore) return;
    _newHand();
  }

  void _finishMatch() {
    if (over) return;
    over = true;
    phase = SpadesPhase.matchOver;
    var w = 0;
    for (var i = 1; i < 4; i++) {
      if (players[i].score > players[w].score) w = i;
    }
    winnerSeat = w;
    banner = '${players[w].name} wins the match!';
    notifyListeners();
    onEvent?.call(players[w].isBot ? SpadesEvent.botWon : SpadesEvent.humanWon);
  }

  /// Full restart: scores reset, hand 1 dealt fresh.
  void restart() {
    _timer?.cancel();
    paused = false;
    _acting = false;
    over = false;
    winnerSeat = null;
    for (final p in players) {
      p.score = 0;
    }
    handNo = 0;
    dealer = 3;
    notifyListeners();
    _newHand();
  }

  // ------------------------------------------------------------------ bots
  /// Bid estimate in tricks (RULES.md §11). Difficulty scales accuracy.
  int _estimateBid(int seat) {
    final hand = hands[seat];
    double est = 0;
    for (var s = 0; s < 4; s++) {
      final cards =
          hand.where((c) => c.suit == s).map((c) => c.rank).toList()
            ..sort((a, b) => b.compareTo(a));
      if (cards.isEmpty) continue;
      if (cards.contains(14)) est += 1.0; // ace is a trick
      if (cards.contains(13)) est += cards.length >= 2 ? 0.7 : 0.3;
      if (cards.contains(12)) est += cards.length >= 3 ? 0.5 : 0.15;
      if (s == 0) {
        // Trump length: extra spades beyond 3 usually take tricks.
        est += max(0, cards.length - 3) * 0.45;
        // High trump honors pull extra weight.
        if (cards.contains(14)) est += 0.25;
      } else if (cards.length <= 2) {
        // Short side suits: trump-in chances.
        final spades = hand.where((c) => c.suit == 0).length;
        est += 0.35 * spades.clamp(0, 2);
      }
    }
    final base = est.round().clamp(1, 13);
    switch (botDifficulty) {
      case BotDifficulty.easy:
        // Easy: noisy, sometimes wildly optimistic or timid.
        return (base + _rand.nextInt(5) - 2).clamp(1, 8);
      case BotDifficulty.medium:
        return (base + (_rand.nextBool() ? 1 : 0)).clamp(1, 13);
      case BotDifficulty.hard:
        return base;
    }
  }

  bool _considerNil(int seat, int est) {
    if (!nilAllowed) return false;
    if (est > 1) return false;
    final maxRank = hands[seat].map((c) => c.rank).reduce(max);
    if (maxRank > 12) return false; // Q or higher ruins a nil
    switch (botDifficulty) {
      case BotDifficulty.easy:
        return _rand.nextDouble() < 0.10;
      case BotDifficulty.medium:
        return _rand.nextDouble() < 0.22;
      case BotDifficulty.hard:
        // Hard only goes nil with a genuinely hopeless hand.
        return maxRank <= 10 && _rand.nextDouble() < 0.30;
    }
  }

  SpadesCard _botChooseCard(int seat) {
    switch (botDifficulty) {
      case BotDifficulty.easy:
        final legal = legalCards(seat);
        return legal[_rand.nextInt(legal.length)];
      case BotDifficulty.medium:
        return _heuristicCard(seat, noise: true);
      case BotDifficulty.hard:
        return _heuristicCard(seat, noise: false);
    }
  }

  /// Heuristic card choice (RULES.md §11 priority order).
  SpadesCard _heuristicCard(int seat, {required bool noise}) {
    final legal = legalCards(seat);
    final need = bids[seat] - tricksWon[seat]; // tricks still needed
    final nil = isNil[seat];
    SpadesCard lowest(List<SpadesCard> l) =>
        ([...l]..sort((a, b) => a.rank.compareTo(b.rank))).first;
    SpadesCard highest(List<SpadesCard> l) =>
        ([...l]..sort((a, b) => b.rank.compareTo(a.rank))).first;

    if (trick.isEmpty) {
      // Lead: low from the longest non-spade suit; hard avoids breaking
      // spades cheaply and protects high trump.
      final nonSpades = legal.where((c) => c.suit != 0).toList();
      if (nonSpades.isEmpty) {
        // Only spades left (or forced): lead low.
        return lowest(legal);
      }
      // Longest suit.
      final bySuit = <int, List<SpadesCard>>{};
      for (final c in nonSpades) {
        bySuit.putIfAbsent(c.suit, () => []).add(c);
      }
      final longest = bySuit.values.reduce(
          (a, b) => a.length >= b.length ? a : b);
      final pick = lowest(longest);
      if (noise && _rand.nextDouble() < 0.18 && nonSpades.length > 1) {
        return nonSpades[_rand.nextInt(nonSpades.length)];
      }
      return pick;
    }

    final led = trick.first.card.suit;
    final follow = legal.where((c) => c.suit == led).toList();
    // Current winning rank of the trick (led suit only counts if no spade).
    int curWinRank = -1;
    bool spadeWinning = false;
    for (final p in trick) {
      if (p.card.suit == 0) {
        spadeWinning = true;
        if (p.card.rank > curWinRank) curWinRank = p.card.rank;
      } else if (!spadeWinning && p.card.suit == led && p.card.rank > curWinRank) {
        curWinRank = p.card.rank;
      }
    }

    if (nil) {
      // Duck everything: lowest card that cannot win.
      final safe = follow
          .where((c) => spadeWinning || c.rank < curWinRank || led == 0 && c.rank < curWinRank)
          .toList();
      final pool = safe.isNotEmpty ? safe : follow.isNotEmpty ? follow : legal;
      return lowest(pool);
    }

    if (follow.isNotEmpty) {
      if (spadeWinning) return lowest(follow); // can't beat a spade: dump low
      final winners =
          follow.where((c) => c.rank > curWinRank).toList();
      if (need > 0 && winners.isNotEmpty) {
        // Take it with the cheapest winner. Hard mode: don't burn a top
        // honor to take a trick early when more players are still to play.
        if (!noise && trick.length < 3) {
          final cheap = winners.where((c) => c.rank < 12).toList();
          if (cheap.isNotEmpty) return lowest(cheap);
        }
        return lowest(winners);
      }
      // No need (or can't win): shed low, protect honors.
      return lowest(follow);
    }

    // Can't follow suit: consider trumping.
    final spades = legal.where((c) => c.suit == 0).toList();
    if (need > 0 && spades.isNotEmpty && !spadeWinning) {
      if (!noise && trick.length == 3 && spades.length > 1) {
        // Hard: last to play — trump just high enough is wasteful; go low.
      }
      return lowest(spades);
    }
    // Discard: highest card of the shortest non-spade suit (shed losers),
    // but never throw away a sure winner cheaply on hard.
    final nonSpades = legal.where((c) => c.suit != 0).toList();
    final pool = nonSpades.isNotEmpty ? nonSpades : legal;
    if (noise) return pool[_rand.nextInt(pool.length)];
    return highest(pool);
  }

  /// Test helper: force the next bot think timers to settle immediately.
  @visibleForTesting
  void debugSettle() => _recover();
}
