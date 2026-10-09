import 'package:flutter/material.dart';

/// Theme + card-back catalog for Spades.
///
/// Every theme stays inside the Card Room material world (real felt, wood
/// rails, brass/copper/silver, ivory cards) — the variety comes from
/// different felts, rail woods, metal accents and player-color gem tones.
/// No neon, no cyberpunk, no AI-dashboard aesthetics.
class FeltThemeDef {
  final String id;
  final String name;
  final Color felt; // card-table cloth
  final Color feltDeep; // table cloth shading
  final Color railDark; // wooden rail
  final Color railMid;
  final Color railDeep;
  final Color accent; // brass / copper / silver trim
  final Color accentLight;
  final Color accentDark;
  final Color ivory; // card faces
  final Color cardRed;
  final Color cardBlack;
  final Color text;
  final Color muted;
  final List<Color> playerColors;
  final List<String> playerColorNames;

  const FeltThemeDef({
    required this.id,
    required this.name,
    required this.felt,
    required this.feltDeep,
    required this.railDark,
    required this.railMid,
    required this.railDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.cardRed,
    required this.cardBlack,
    required this.text,
    required this.muted,
    required this.playerColors,
    required this.playerColorNames,
  });
}

class FeltThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'emerald',
    'burgundy',
    'midnight',
  ];

  static const List<FeltThemeDef> all = [
    FeltThemeDef(
      id: 'classic',
      name: 'Classic Casino',
      felt: Color(0xFF1E5C43),
      feltDeep: Color(0xFF123B2A),
      railDark: Color(0xFF3B2416),
      railMid: Color(0xFF5C3A21),
      railDeep: Color(0xFF241309),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      cardRed: Color(0xFFB02A30),
      cardBlack: Color(0xFF1E2430),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFC9BFA6),
      playerColors: [
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
        Color(0xFF1B7A4D),
        Color(0xFFD99A2B),
      ],
      playerColorNames: ['Ruby', 'Sapphire', 'Emerald', 'Amber'],
    ),
    FeltThemeDef(
      id: 'emerald',
      name: 'Emerald Club',
      felt: Color(0xFF0F4A35),
      feltDeep: Color(0xFF09301F),
      railDark: Color(0xFF2E3B22),
      railMid: Color(0xFF4A5A34),
      railDeep: Color(0xFF1A2312),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF6F1E4),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF22303E),
      text: Color(0xFFF6F1E4),
      muted: Color(0xFFCFC6A8),
      playerColors: [
        Color(0xFFB03A2E),
        Color(0xFF2E86C1),
        Color(0xFFD4AC0D),
        Color(0xFF8E44AD),
      ],
      playerColorNames: ['Claret', 'Steel', 'Ochre', 'Plum'],
    ),
    FeltThemeDef(
      id: 'burgundy',
      name: 'Burgundy Velvet',
      felt: Color(0xFF6E1E30),
      feltDeep: Color(0xFF471220),
      railDark: Color(0xFF4A1F14),
      railMid: Color(0xFF6E2F1C),
      railDeep: Color(0xFF2B1009),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF8F1E2),
      cardRed: Color(0xFF8E1F2C),
      cardBlack: Color(0xFF1F2532),
      text: Color(0xFFF8F1E2),
      muted: Color(0xFFD8BFA8),
      playerColors: [
        Color(0xFFD4AC0D),
        Color(0xFF7D3C98),
        Color(0xFF1E8449),
        Color(0xFF2471A3),
      ],
      playerColorNames: ['Topaz', 'Amethyst', 'Jade', 'Teal'],
    ),
    FeltThemeDef(
      id: 'midnight',
      name: 'Midnight Den',
      felt: Color(0xFF1E2A44),
      feltDeep: Color(0xFF121A2E),
      railDark: Color(0xFF1C2438),
      railMid: Color(0xFF2C3A55),
      railDeep: Color(0xFF101624),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2EEE4),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF1A2233),
      text: Color(0xFFF2EEE4),
      muted: Color(0xFFB9C0D0),
      playerColors: [
        Color(0xFFD64545),
        Color(0xFF4A90D9),
        Color(0xFF3FB97F),
        Color(0xFFE0A83C),
      ],
      playerColorNames: ['Candle', 'Moonstone', 'Fern', 'Lantern'],
    ),
    FeltThemeDef(
      id: 'cherry',
      name: 'Cherry Study',
      felt: Color(0xFF24523F),
      feltDeep: Color(0xFF16372A),
      railDark: Color(0xFF5A2A1A),
      railMid: Color(0xFF7C3F24),
      railDeep: Color(0xFF381408),
      accent: Color(0xFFB08D3E),
      accentLight: Color(0xFFDFC084),
      accentDark: Color(0xFF7A6128),
      ivory: Color(0xFFF7EFE0),
      cardRed: Color(0xFFA93226),
      cardBlack: Color(0xFF1E2430),
      text: Color(0xFFF7EFE0),
      muted: Color(0xFFCFBF9E),
      playerColors: [
        Color(0xFFC0392B),
        Color(0xFF2471A3),
        Color(0xFF229954),
        Color(0xFFD4AC0D),
      ],
      playerColorNames: ['Poppy', 'Teal', 'Moss', 'Wheat'],
    ),
    FeltThemeDef(
      id: 'copper',
      name: 'Walnut & Copper',
      felt: Color(0xFF2A5A48),
      feltDeep: Color(0xFF1B3D31),
      railDark: Color(0xFF3B2416),
      railMid: Color(0xFF5C3A21),
      railDeep: Color(0xFF241309),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      ivory: Color(0xFFF5EFE0),
      cardRed: Color(0xFFB02A30),
      cardBlack: Color(0xFF232B38),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFC9BFA6),
      playerColors: [
        Color(0xFFA31621),
        Color(0xFF1F618D),
        Color(0xFF1E8449),
        Color(0xFFCA8A2B),
      ],
      playerColorNames: ['Ruby', 'Denim', 'Leaf', 'Bronze'],
    ),
    FeltThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      felt: Color(0xFF2F5A34),
      feltDeep: Color(0xFF1E3D22),
      railDark: Color(0xFF3E3226),
      railMid: Color(0xFF5D4C36),
      railDeep: Color(0xFF26201A),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF1EAD8),
      cardRed: Color(0xFFB03A2E),
      cardBlack: Color(0xFF1F2A22),
      text: Color(0xFFF1EAD8),
      muted: Color(0xFFC8BFA0),
      playerColors: [
        Color(0xFFB03A2E),
        Color(0xFF2E86C1),
        Color(0xFFE67E22),
        Color(0xFF7D6608),
      ],
      playerColorNames: ['Brick', 'River', 'Ember', 'Hay'],
    ),
    FeltThemeDef(
      id: 'sapphire',
      name: 'Sapphire Parlor',
      felt: Color(0xFF24406E),
      feltDeep: Color(0xFF162A4C),
      railDark: Color(0xFF16233F),
      railMid: Color(0xFF24365C),
      railDeep: Color(0xFF0C1526),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2EEE4),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF1A2740),
      text: Color(0xFFF2EEE4),
      muted: Color(0xFFBCC4D4),
      playerColors: [
        Color(0xFFC0392B),
        Color(0xFFD4AC0D),
        Color(0xFF229954),
        Color(0xFFE67E22),
      ],
      playerColorNames: ['Poppy', 'Wheat', 'Moss', 'Ember'],
    ),
    FeltThemeDef(
      id: 'ivory',
      name: 'Ivory & Gold',
      felt: Color(0xFFE8DFC8),
      feltDeep: Color(0xFFCFC2A2),
      railDark: Color(0xFFEFE3C8),
      railMid: Color(0xFFE2D0A6),
      railDeep: Color(0xFFC9B586),
      accent: Color(0xFF9A7B1E),
      accentLight: Color(0xFFD4AF37),
      accentDark: Color(0xFF6E5514),
      ivory: Color(0xFF2E2118),
      cardRed: Color(0xFF9E2B26),
      cardBlack: Color(0xFF2E2118),
      text: Color(0xFF2E2118),
      muted: Color(0xFF6E6046),
      playerColors: [
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
        Color(0xFF1B7A4D),
        Color(0xFFB26A00),
      ],
      playerColorNames: ['Ruby', 'Sapphire', 'Emerald', 'Honey'],
    ),
    FeltThemeDef(
      id: 'ebony',
      name: 'Ebony & Silver',
      felt: Color(0xFF2A2A30),
      feltDeep: Color(0xFF17171B),
      railDark: Color(0xFF1A1A1E),
      railMid: Color(0xFF2A2A30),
      railDeep: Color(0xFF0C0C0E),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFF0F2F8),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2EEE4),
      cardRed: Color(0xFFE74C3C),
      cardBlack: Color(0xFF14141A),
      text: Color(0xFFF2EEE4),
      muted: Color(0xFFB8B4A8),
      playerColors: [
        Color(0xFFE74C3C),
        Color(0xFF3498DB),
        Color(0xFF2ECC71),
        Color(0xFFF39C12),
      ],
      playerColorNames: ['Flame', 'Sky', 'Mint', 'Gold'],
    ),
    FeltThemeDef(
      id: 'teal',
      name: 'Teal Atelier',
      felt: Color(0xFF155A55),
      feltDeep: Color(0xFF0E3D3A),
      railDark: Color(0xFF1E3A38),
      railMid: Color(0xFF2E5654),
      railDeep: Color(0xFF10201F),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF0EDE2),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF1B2F2D),
      text: Color(0xFFF0EDE2),
      muted: Color(0xFFBFC6A8),
      playerColors: [
        Color(0xFFC0392B),
        Color(0xFFD4AC0D),
        Color(0xFF8E44AD),
        Color(0xFFE67E22),
      ],
      playerColorNames: ['Poppy', 'Wheat', 'Plum', 'Ember'],
    ),
    FeltThemeDef(
      id: 'rosewood',
      name: 'Rosewood',
      felt: Color(0xFF5A2E42),
      feltDeep: Color(0xFF3C1E2C),
      railDark: Color(0xFF3F1D24),
      railMid: Color(0xFF5E2C36),
      railDeep: Color(0xFF241016),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      ivory: Color(0xFFF5EFE0),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF2A1E26),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFD3BCA8),
      playerColors: [
        Color(0xFFD4AC0D),
        Color(0xFF2E86C1),
        Color(0xFF229954),
        Color(0xFFAF601A),
      ],
      playerColorNames: ['Wheat', 'Steel', 'Leaf', 'Caramel'],
    ),
    FeltThemeDef(
      id: 'slate',
      name: 'Slate & Brass',
      felt: Color(0xFF3B4252),
      feltDeep: Color(0xFF262B38),
      railDark: Color(0xFF2E3440),
      railMid: Color(0xFF434C5E),
      railDeep: Color(0xFF1A1E26),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFECEFF4),
      cardRed: Color(0xFFBF616A),
      cardBlack: Color(0xFF242A38),
      text: Color(0xFFECEFF4),
      muted: Color(0xFFB8C0CE),
      playerColors: [
        Color(0xFFBF616A),
        Color(0xFF5E81AC),
        Color(0xFFA3BE8C),
        Color(0xFFEBCB8B),
      ],
      playerColorNames: ['Aurora', 'Frost', 'Sage', 'Nord'],
    ),
    FeltThemeDef(
      id: 'winecellar',
      name: 'Wine Cellar',
      felt: Color(0xFF46244E),
      feltDeep: Color(0xFF2F1636),
      railDark: Color(0xFF2E1A2E),
      railMid: Color(0xFF462844),
      railDeep: Color(0xFF180E18),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      cardRed: Color(0xFFC0392B),
      cardBlack: Color(0xFF2A1E30),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFCDB9A8),
      playerColors: [
        Color(0xFFD4AC0D),
        Color(0xFF5DADE2),
        Color(0xFF58D68D),
        Color(0xFFEC7063),
      ],
      playerColorNames: ['Sauternes', 'Mist', 'Verde', 'Rosé'],
    ),
  ];

  static FeltThemeDef byId(String id, {FeltThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Card-back styles (the face-down deck design). 0-2 = FREE, 3+ = PRO.
class CardBacks {
  static const names = [
    'Ivory Classic',
    'Brass Lattice',
    'Felt Green',
    'Midnight Pip',
    'Crimson Brocade',
    'Copper Weave',
    'Art Deco',
    'Golden Spade',
  ];
  static const descriptions = [
    'Plain ivory card stock, brass rim',
    'Cross-hatched brass lattice',
    'Deep green felt inlay',
    'Navy with silver spade',
    'Wine-red brocade swirl',
    'Woven copper chevron',
    'Sunburst art-deco fan',
    'Large gold spade on ebony',
  ];

  /// Styles free players may use.
  static const freeCount = 3;
  static bool isPro(int index) => index >= freeCount;
}
