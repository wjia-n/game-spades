import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

const _suits = ['♠', '♥', '♦', '♣'];
bool _red(int s) => s == 1 || s == 2;
String _rs(int r) => r == 1 ? 'A' : r == 11 ? 'J' : r == 12 ? 'Q' : r == 13 ? 'K' : '$r';

class _C {
  final int s, r;
  _C(this.s, this.r);
}

class _Seat {
  final Player p;
  final hand = <_C>[];
  _Seat(this.p);
}

class _Play {
  final int seat;
  final _C card;
  _Play(this.seat, this.card);
}

class SpadesScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const SpadesScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SpadesScreen> createState() => _SpadesScreenState();
}

class _SpadesScreenState extends State<SpadesScreen> {
  late List<_Seat> seats;
  int phase = 0; // 0 = bidding, 1 = playing
  int bidTurn = 0;
  var bids = [0, 0, 0, 0];
  var isNil = [false, false, false, false];
  var tricksWon = [0, 0, 0, 0];
  final trick = <_Play>[];
  int turn = 0, handNo = 0;
  bool spadesBroken = false, busy = false, finished = false;

  bool get solo => widget.players.length == 1;
  int get viewSeat => phase == 0 ? bidTurn : (solo ? 0 : turn);

  @override
  void initState() {
    super.initState();
    seats = widget.players.length == 4
        ? widget.players.map((p) => _Seat(p)).toList()
        : [_Seat(widget.players[0]), for (var i = 1; i < 4; i++) _Seat(PlayerPresets.make(i, isBot: true))];
    _newHand();
  }

  void _newHand() {
    final deck = [for (var s = 0; s < 4; s++) for (var r = 1; r <= 13; r++) _C(s, r)]..shuffle(Random());
    for (var i = 0; i < 4; i++) {
      seats[i].hand
        ..clear()
        ..addAll(deck.sublist(i * 13, i * 13 + 13));
      seats[i].hand.sort((a, b) => a.s != b.s ? a.s.compareTo(b.s) : b.r.compareTo(a.r));
    }
    setState(() {
      bids = [0, 0, 0, 0];
      isNil = [false, false, false, false];
      tricksWon = [0, 0, 0, 0];
      trick.clear();
      handNo++;
      spadesBroken = false;
      busy = false;
      phase = 0;
      bidTurn = 0;
    });
    _maybeBotBid();
  }

  // ---------------- bidding ----------------

  double _estimate(int seat) {
    final hand = seats[seat].hand;
    var est = 0.0;
    for (var s = 0; s < 4; s++) {
      final cards = hand.where((c) => c.s == s).map((c) => c.r).toList()..sort((a, b) => b.compareTo(a));
      if (cards.isEmpty) continue;
      if (cards.contains(1)) est += 1.0;
      if (cards.contains(13)) est += cards.length >= 2 ? 0.7 : 0.3;
      if (cards.contains(12)) est += cards.length >= 3 ? 0.5 : 0.15;
      if (s == 0) est += max(0, cards.length - 3) * 0.45;
    }
    return est;
  }

  void _maybeBotBid() {
    if (finished || phase != 0 || !seats[bidTurn].p.isBot) return;
    setState(() => busy = true);
    Future.delayed(Duration(milliseconds: 600 + Random().nextInt(300)), () {
      if (!mounted || finished || phase != 0) return;
      final est = _estimate(bidTurn);
      final maxR = seats[bidTurn].hand.map((c) => c.r).reduce(max);
      final nil = est < 1.1 && maxR <= 11 && Random().nextDouble() < 0.22;
      _placeBid(bidTurn, nil ? 0 : est.round().clamp(0, 13), nil: nil);
    });
  }

  void _placeBid(int seat, int bid, {bool nil = false}) {
    setState(() {
      bids[seat] = nil ? 0 : bid;
      isNil[seat] = nil;
      busy = false;
      bidTurn = (bidTurn + 1) % 4;
    });
    Sfx.tap();
    if (bidTurn == 0) {
      setState(() {
        phase = 1;
        turn = 0;
      });
      widget.callbacks.setActivePlayer(turn);
      _maybeBotMove();
    } else {
      _maybeBotBid();
    }
  }

  // ---------------- trick play ----------------

  List<_C> _legal(int seat) {
    final hand = seats[seat].hand;
    if (trick.isEmpty) {
      if (!spadesBroken) {
        final nonSpades = hand.where((c) => c.s != 0).toList();
        if (nonSpades.isNotEmpty) return nonSpades;
      }
      return [...hand];
    }
    final led = trick.first.card.s;
    final follow = hand.where((c) => c.s == led).toList();
    return follow.isNotEmpty ? follow : [...hand];
  }

  _C _botCard(int seat) {
    final legal = _legal(seat);
    final need = bids[seat] - tricksWon[seat];
    final nil = isNil[seat];
    if (trick.isEmpty) {
      // lead low from longest non-spade suit (or low spade if only spades)
      final cands = legal.where((c) => c.s != 0).toList();
      final pool = (cands.isNotEmpty ? cands : legal)..sort((a, b) => a.r.compareTo(b.r));
      return pool.first;
    }
    final led = trick.first.card.s;
    final follow = legal.where((c) => c.s == led).toList();
    int curWinRank = -1;
    bool spadeWinning = false;
    for (final p in trick) {
      if (p.card.s == 0) {
        spadeWinning = true;
        if (p.card.r > curWinRank) curWinRank = p.card.r;
      } else if (!spadeWinning && p.card.s == led && p.card.r > curWinRank) {
        curWinRank = p.card.r;
      }
    }
    _C lowest(List<_C> l) => ([...l]..sort((a, b) => a.r.compareTo(b.r))).first;
    if (follow.isNotEmpty) {
      if (nil) return lowest(follow); // duck everything
      final winners = follow.where((c) {
        if (spadeWinning) return false;
        return led == 0 ? c.r > curWinRank : c.r > curWinRank;
      }).toList();
      if (need > 0 && winners.isNotEmpty) return lowest(winners);
      return lowest(follow);
    }
    // can't follow: consider trumping
    final spades = legal.where((c) => c.s == 0).toList();
    if (!nil && need > 0 && spades.isNotEmpty && !spadeWinning) {
      return lowest(spades); // trump in cheap
    }
    final nonSpades = legal.where((c) => c.s != 0).toList();
    return lowest(nonSpades.isNotEmpty ? nonSpades : legal);
  }

  void _tapCard(_C c) {
    if (finished || busy || phase != 1) return;
    if (turn != viewSeat || seats[turn].p.isBot) return;
    if (!_legal(turn).contains(c)) {
      Sfx.tap();
      return;
    }
    _playCard(turn, c);
  }

  void _playCard(int seat, _C card) {
    setState(() {
      seats[seat].hand.remove(card);
      trick.add(_Play(seat, card));
      if (card.s == 0) spadesBroken = true;
      busy = false;
    });
    Sfx.tap();
    if (trick.length == 4) {
      setState(() => busy = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || finished) return;
        _resolveTrick();
      });
    } else {
      setState(() => turn = (turn + 1) % 4);
      widget.callbacks.setActivePlayer(turn);
      _maybeBotMove();
    }
  }

  void _maybeBotMove() {
    if (finished || phase != 1 || !seats[turn].p.isBot) return;
    setState(() => busy = true);
    Future.delayed(Duration(milliseconds: 650 + Random().nextInt(350)), () {
      if (!mounted || finished || phase != 1) return;
      _playCard(turn, _botCard(turn));
    });
  }

  void _resolveTrick() {
    final led = trick.first.card.s;
    var win = trick.first;
    for (final p in trick) {
      final wSpade = win.card.s == 0;
      final pSpade = p.card.s == 0;
      if (pSpade && (!wSpade || p.card.r > win.card.r)) {
        win = p;
      } else if (!pSpade && !wSpade && p.card.s == led && p.card.r > win.card.r) {
        win = p;
      }
    }
    setState(() {
      tricksWon[win.seat]++;
      trick.clear();
      turn = win.seat;
      busy = false;
    });
    Sfx.move();
    widget.callbacks.setActivePlayer(turn);
    if (seats.every((s) => s.hand.isEmpty)) {
      _endHand();
    } else {
      _maybeBotMove();
    }
  }

  void _endHand() {
    final deltas = <int>[];
    setState(() {
      for (var i = 0; i < 4; i++) {
        int d;
        if (isNil[i]) {
          d = tricksWon[i] == 0 ? 100 : -100;
        } else if (tricksWon[i] >= bids[i]) {
          d = bids[i] * 10 + (tricksWon[i] - bids[i]);
        } else {
          d = -bids[i] * 10;
        }
        deltas.add(d);
        seats[i].p.score += d;
      }
    });
    widget.callbacks.refreshHud();
    Sfx.win();
    final matchOver = seats.any((s) => s.p.score >= 500);
    final t = ThemeController.of(context).theme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WajihaDialog(
        emoji: '♠️',
        title: 'Hand $handNo done!',
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${seats[i].p.emoji} ${seats[i].p.name}: bid ${isNil[i] ? 'NIL' : bids[i]}, took ${tricksWon[i]} → ${deltas[i] >= 0 ? '+' : ''}${deltas[i]} (total ${seats[i].p.score})',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          const SizedBox(height: 6),
          Text(
              matchOver
                  ? 'Someone hit 500 — crown the champion! 👑'
                  : 'First to 500 wins. Bid braver next time! 😎',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 14),
          WajihaButton(
            label: matchOver ? 'See results 🏁' : 'Next hand ♠️',
            onTap: () {
              Navigator.pop(context);
              if (matchOver) {
                _finishMatch();
              } else {
                _newHand();
              }
            },
          ),
        ],
      ),
    );
  }

  void _finishMatch() {
    if (finished) return;
    finished = true;
    var w = 0;
    for (var i = 1; i < 4; i++) {
      if (seats[i].p.score > seats[w].p.score) w = i;
    }
    final scores = seats.map((s) => '${s.p.emoji} ${s.p.name}: ${s.p.score}').join('   •   ');
    widget.callbacks.finish(
      headline: '🏆 ${seats[w].p.name} wins the match!',
      subline:
          'Final scores — $scores. ${w == 0 ? '500 club, baby! You trumped them all! 💛' : 'The bots bow to no one. Rematch? 🤖'}',
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final vs = viewSeat;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        if (solo) ScoreChips(players: seats.map((s) => s.p).toList(), activeIndex: phase == 1 ? turn : bidTurn),
        const SizedBox(height: 6),
        _opponents(t),
        const SizedBox(height: 8),
        Expanded(child: _table(t)),
        const SizedBox(height: 8),
        if (phase == 0) _bidBar(t) else _turnInfo(t),
        const SizedBox(height: 8),
        _hand(t, vs),
      ]),
    );
  }

  Widget _opponents(GameTheme t) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (var i = 1; i < 4; i++) _oppSeat(t, i)],
      );

  Widget _oppSeat(GameTheme t, int i) {
    final s = seats[i];
    final active = (phase == 1 && turn == i) || (phase == 0 && bidTurn == i);
    final bidTxt = phase == 0
        ? (i < bidTurn || (bidTurn == 0 && phase == 1) ? '' : '…')
        : 'bid ${isNil[i] ? 'NIL' : bids[i]} • took ${tricksWon[i]}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? s.p.color.withValues(alpha: 0.25) : t.surface,
        borderRadius: t.radius,
        border: Border.all(
            color: active ? s.p.color : t.muted.withValues(alpha: 0.3), width: active ? 2.5 : 1.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${s.p.emoji} ${s.p.name}',
            style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🂠', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text('${s.hand.length}', style: TextStyle(color: t.muted, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('⭐ ${s.p.score}', style: TextStyle(color: t.muted, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
        if (bidTxt.isNotEmpty)
          Text(bidTxt, style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
    );
  }

  Widget _table(GameTheme t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surface.withValues(alpha: 0.5),
          borderRadius: t.radius,
          border: Border.all(color: t.primary.withValues(alpha: 0.25)),
        ),
        child: trick.isEmpty
            ? Center(
                child: Text(
                  phase == 0
                      ? '♠️ ${solo ? 'Place your bid' : '${seats[bidTurn].p.name}, place your bid'} — how many tricks will you take?'
                      : '♠️ ${spadesBroken ? 'Spades are BROKEN! 💥' : 'Spades not broken yet'} — waiting for ${seats[turn].p.name}…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              )
            : Center(
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in trick)
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        _miniCard(t, p.card, 54),
                        const SizedBox(height: 2),
                        Text(seats[p.seat].p.emoji, style: const TextStyle(fontSize: 14)),
                      ]),
                  ],
                ),
              ),
      );

  Widget _turnInfo(GameTheme t) {
    final cur = seats[turn];
    final label = cur.p.isBot
        ? '${cur.p.emoji} ${cur.p.name} is thinking… 🤖'
        : solo
            ? 'Your turn — play a card! 👆'
            : '${cur.p.emoji} ${cur.p.name}, your turn! 👆';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [cur.p.color.withValues(alpha: 0.85), cur.p.color.withValues(alpha: 0.55)]),
          borderRadius: t.radius),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }

  Widget _bidBar(GameTheme t) {
    final humanTurn = !seats[bidTurn].p.isBot && (solo ? bidTurn == 0 : true);
    return Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          solo
              ? 'Your bid: how many tricks? (NIL = 0 tricks for ±100!)'
              : '${seats[bidTurn].p.emoji} ${seats[bidTurn].p.name}, your bid!',
          style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 15,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final isNilBtn = i == 14;
              final label = isNilBtn ? 'NIL 😱' : '$i';
              return GestureDetector(
                onTap: !humanTurn || busy
                    ? null
                    : () => _placeBid(bidTurn, isNilBtn ? 0 : i, nil: isNilBtn),
                child: Opacity(
                  opacity: !humanTurn || busy ? 0.4 : 1,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: t.headerGradient,
                      borderRadius: t.radius,
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              );
            },
          ),
        ),
      ]);
  }

  Widget _hand(GameTheme t, int vs) {
    final hand = seats[vs].hand;
    final playable = phase == 1 && turn == vs && !seats[vs].p.isBot ? _legal(vs).toSet() : null;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hand.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = hand[i];
          final ok = playable == null ? true : playable.contains(c);
          return GestureDetector(
            onTap: () => _tapCard(c),
            child: Opacity(
              opacity: ok ? 1 : 0.45,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: _miniCard(t, c, 62),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniCard(GameTheme t, _C c, double w) {
    final h = w * 1.42;
    final col = _red(c.s) ? Colors.red.shade700 : Colors.grey.shade900;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(w * 0.08),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_rs(c.r),
            style: TextStyle(fontSize: w * 0.30, fontWeight: FontWeight.w900, color: col, height: 1)),
        Text(_suits[c.s], style: TextStyle(fontSize: w * 0.30, color: col, height: 1.1)),
        const Spacer(),
        Align(
            alignment: Alignment.bottomRight,
            child: Text(_suits[c.s], style: TextStyle(fontSize: w * 0.34, height: 1))),
      ]),
    );
  }
}
