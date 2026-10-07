import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SpadesApp());

class SpadesApp extends StatelessWidget {
  const SpadesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Spades',
      tagline: 'Bid bold, trump hard, and race to 500 in the king of trick-taking games!',
      emoji: '♠️',
      slug: 'spades',
      howToPlay:
          '• You + 3 rivals. Bid how many tricks you\'ll take — or go NIL for a 100-pt thrill!\n• Follow suit if you can. Spades are trump but can\'t lead until broken.\n• Make your bid: 10× bid + 1 per overtrick. Miss it: −10× bid. Ouch.\n• First to 500 wins the match. Play solo vs bots or pass-and-play!',
      playerOptions: const [1, 4],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => SpadesScreen(players: players, callbacks: cb),
    );
  }
}
