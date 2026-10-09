import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/felt_themes.dart';

/// Persisted settings + stats for Spades. Survives app restarts.
///
/// Stores: audio toggles, player names (4 seats), theme/appearance choices
/// (incl. custom theme colors), game-mode setup (humans, difficulty,
/// target score, nil rule), Pro unlock state, and lifetime stats.
class SpadesSettings extends ChangeNotifier {
  static const _kMusic = 'spades_music_on';
  static const _kSfx = 'spades_sfx_on';
  static const _kVolume = 'spades_volume';
  static const _kHumans = 'spades_humans'; // 1..4 humans; rest are bots
  static const _kDifficulty = 'spades_bot_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kTarget = 'spades_target_score'; // 250 or 500
  static const _kNil = 'spades_nil_allowed';
  static const _kTheme = 'spades_theme_id';
  static const _kCardBack = 'spades_card_back';
  static const _kWins = 'spades_wins';
  static const _kGames = 'spades_games_played';
  static const _kBestScore = 'spades_best_score';
  static const _kReviewAsks = 'spades_review_asks';
  static const _kIsPro = 'spades_is_pro';
  static const _kCustomPrefix = 'spades_custom_';

  // Legacy keys (pre-exemplar builds). Migrated once, then removed.
  static const _legacyNamesList = 'spades_player_names';
  static const _legacyTheme = 'wajiha_theme_id';

  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so a
  /// StringList would scramble seat order on every restart. NEVER use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'spades_player_names_json';

  static const defaultNames = ['You', 'Viper', 'Jinx', 'Rogue'];

  /// Encode the 4 seat names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 4) {
        return [for (int i = 0; i < 4; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int humans = 1; // 1..4 humans; remaining seats are bots
  int difficulty = 1; // medium default
  int targetScore = 500;
  bool nilAllowed = true;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int cardBack = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestScore = 0; // highest winning human score (0 = none yet)
  int reviewAsks = 0; // review prompts shown this install (throttle)
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Casino.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'felt': 0xFF1E5C43,
    'feltDeep': 0xFF123B2A,
    'railDark': 0xFF3B2416,
    'railMid': 0xFF5C3A21,
    'railDeep': 0xFF241309,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF5EFE0,
    'cardRed': 0xFFB02A30,
    'cardBlack': 0xFF1E2430,
    'pc0': 0xFFA31621,
    'pc1': 0xFF1D4E9E,
    'pc2': 0xFF1B7A4D,
    'pc3': 0xFFD99A2B,
  };

  /// Builds the user-designed custom theme from stored colors.
  FeltThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return FeltThemeDef(
      id: 'custom',
      name: 'My Creation',
      felt: c('felt'),
      feltDeep: c('feltDeep'),
      railDark: c('railDark'),
      railMid: c('railMid'),
      railDeep: c('railDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      cardRed: c('cardRed'),
      cardBlack: c('cardBlack'),
      text: c('ivory'),
      muted: const Color(0xFFC9BFA6),
      playerColors: [c('pc0'), c('pc1'), c('pc2'), c('pc3')],
      playerColorNames: const ['One', 'Two', 'Three', 'Four'],
    );
  }

  FeltThemeDef get theme => FeltThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    humans = (p.getInt(_kHumans) ?? 1).clamp(1, 4);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    targetScore = p.getInt(_kTarget) ?? 500;
    if (targetScore != 250 && targetScore != 500) targetScore = 500;
    nilAllowed = p.getBool(_kNil) ?? true;
    // Player names: prefer the order-safe JSON key. Migrate the legacy
    // StringList key once (it may already be order-scrambled on Android,
    // which is exactly the bug this replaces), then remove it for good.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_legacyNamesList);
      playerNames = (legacy != null && legacy.length == 4)
          ? [for (int i = 0; i < 4; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
      await p.remove(_legacyNamesList);
    }
    // Legacy theme key from the shared core ('wajiha_theme_id').
    themeId = p.getString(_kTheme) ?? p.getString(_legacyTheme) ?? 'classic';
    await p.remove(_legacyTheme);
    cardBack = (p.getInt(_kCardBack) ?? 0).clamp(0, CardBacks.names.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestScore = p.getInt(_kBestScore) ?? 0;
    reviewAsks = p.getInt(_kReviewAsks) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kHumans, humans);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kTarget, targetScore);
    await p.setBool(_kNil, nilAllowed);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_legacyNamesList); // drop the legacy unordered key for good
    await p.remove(_legacyTheme);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kCardBack, cardBack);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestScore, bestScore);
    await p.setInt(_kReviewAsks, reviewAsks);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || FeltThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (CardBacks.isPro(cardBack)) {
      cardBack = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setSetup({
    required int humans,
    required int difficulty,
    required int targetScore,
    required bool nilAllowed,
  }) async {
    this.humans = humans.clamp(1, 4);
    this.difficulty = difficulty.clamp(0, 2);
    this.targetScore = (targetScore == 250) ? 250 : 500;
    this.nilAllowed = nilAllowed;
    // Hard mode is a Pro feature.
    if (!isPro && this.difficulty > 1) this.difficulty = 1;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 3) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows lock).
    if (!isPro && (id == 'custom' || FeltThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCardBack(int v) async {
    v = v.clamp(0, CardBacks.names.length - 1);
    if (!isPro && CardBacks.isPro(v)) return;
    cardBack = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished match. [humanWon] true if a human seat won.
  Future<void> recordGame({required bool humanWon, required int score}) async {
    gamesPlayed++;
    if (humanWon) {
      wins++;
      if (bestScore == 0 || score > bestScore) bestScore = score;
    }
    notifyListeners();
    await _save();
  }

  /// Count a review prompt shown (throttle: ask sparingly).
  Future<void> bumpReviewAsks() async {
    reviewAsks++;
    notifyListeners();
    await _save();
  }
}
