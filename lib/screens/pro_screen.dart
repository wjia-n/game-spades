import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/cardroom.dart';
import '../theme/felt_themes.dart';

/// Spades PRO: Free-vs-Pro comparison, one-time unlock, tip jar,
/// restore purchases. Graceful when the store/products aren't configured.
class ProScreen extends StatefulWidget {
  final SpadesAudio audio;
  final SpadesSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  SpadesSettings get _s => widget.settings;
  StoreService get _store => widget.store;
  FeltThemeDef get _t => _s.theme;

  @override
  void initState() {
    super.initState();
    _store.purchaseError.addListener(_onErr);
  }

  @override
  void dispose() {
    _store.purchaseError.removeListener(_onErr);
    super.dispose();
  }

  void _onErr() {
    final msg = _store.purchaseError.value;
    if (msg == null || !mounted) return;
    widget.audio.invalid();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Felt.body(14, theme: _t)),
        backgroundColor: _t.railDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.purchaseError.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.felt,
      appBar: AppBar(
        backgroundColor: _t.railDeep,
        foregroundColor: _t.text,
        title: Text('Spades PRO ♠️', style: Felt.display(20, theme: _t)),
      ),
      body: FeltBackdrop(
        theme: _t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              BrassPlaque(
                title: _s.isPro ? 'You are PRO! 👑' : 'Go PRO ♠️',
                subtitle: _s.isPro
                    ? 'Every felt, every card back, every shark is yours.'
                    : 'One purchase. Yours forever. No subscriptions, no ads.',
                theme: _t,
              ),
              const SizedBox(height: 18),
              _comparisonTable(),
              const SizedBox(height: 18),
              _buySection(),
              const SizedBox(height: 18),
              _tipJar(),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    _store.restore();
                  },
                  child: Text('Restore purchases ↺',
                      style: Felt.label(14, theme: _t)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Purchases are handled securely by Google Play. '
                'PRO unlocks sync to this device after purchase.',
                textAlign: TextAlign.center,
                style: Felt.body(11,
                    theme: _t, color: _t.text.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable() {
    const rows = [
      ('All 14 table felts', false, true),
      ('Custom felt creator 🎨', false, true),
      ('All 8 card backs', false, true),
      ('🦈 Shark bot difficulty', false, true),
      ('Nil bidding thrills', true, true),
      ('Pass-and-play party mode', true, true),
      ('Full game: bidding to 500', true, true),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _t.railDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Expanded(child: SizedBox()),
            SizedBox(
                width: 64,
                child: Text('Free',
                    textAlign: TextAlign.center,
                    style: Felt.label(13, theme: _t))),
            SizedBox(
                width: 64,
                child: Text('PRO',
                    textAlign: TextAlign.center,
                    style: Felt.label(13, theme: _t))),
          ]),
        ),
        for (final (label, free, pro) in rows)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: _t.accent.withValues(alpha: 0.2))),
            ),
            child: Row(children: [
              Expanded(child: Text(label, style: Felt.body(14, theme: _t))),
              SizedBox(
                  width: 64,
                  child: Text(free ? '✓' : '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: free
                              ? _t.accentLight
                              : _t.text.withValues(alpha: 0.35)))),
              SizedBox(
                  width: 64,
                  child: Text(pro ? '✓' : '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _t.accentLight))),
            ]),
          ),
      ]),
    );
  }

  Widget _buySection() {
    if (_s.isPro) {
      return Center(
        child: Text('PRO is active on this device. Enjoy the table! ♠️',
            textAlign: TextAlign.center, style: Felt.body(15, theme: _t)),
      );
    }
    final pro = _store.proProduct;
    if (!_store.storeReady || pro == null) {
      // Graceful pre-launch state: honest, never a fake buy button.
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _t.railDeep.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          'PRO unlock will be available here once the store listing is set up. '
          'Everything in the free game stays free forever. ♠️',
          textAlign: TextAlign.center,
          style: Felt.body(14, theme: _t),
        ),
      );
    }
    return Column(children: [
      Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: _store.purchaseInProgress,
          builder: (_, busy, __) => FeltButton(
            label: busy ? 'Working…' : 'Unlock PRO — ${pro.price}',
            theme: _t,
            width: 260,
            onTap: busy ? null : () => _store.buyPro(),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text('One-time purchase. Yours forever.',
          style: Felt.body(12,
              theme: _t, color: _t.text.withValues(alpha: 0.65))),
    ]);
  }

  Widget _tipJar() {
    final coffee = _store.coffeeProduct;
    final choc = _store.chocolateProduct;
    Widget tipBtn(String label, ProductDetails? p) {
      final ready = p != null;
      return Expanded(
        child: GestureDetector(
          onTap: !ready
              ? null
              : () {
                  widget.audio.click();
                  _store.buyTip(p);
                },
          child: Opacity(
            opacity: ready ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _t.railMid,
                border: Border.all(color: _t.accent, width: 2),
              ),
              child: Column(children: [
                Text(label, style: Felt.label(14, theme: _t)),
                const SizedBox(height: 2),
                Text(ready ? p.price : 'soon',
                    style: Felt.body(12, theme: _t)),
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _t.railDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _t.accent.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Text('☕ Tip jar', style: Felt.display(18, theme: _t)),
        const SizedBox(height: 6),
        Text(
          'Spades is free forever. A tip keeps the cards coming!',
          textAlign: TextAlign.center,
          style: Felt.body(13, theme: _t),
        ),
        const SizedBox(height: 10),
        Row(children: [
          tipBtn('☕ Coffee', coffee),
          const SizedBox(width: 10),
          tipBtn('🍫 Chocolate', choc),
        ]),
        if (!_store.storeReady) ...[
          const SizedBox(height: 8),
          Text('Tips activate once the store listing is set up.',
              textAlign: TextAlign.center,
              style: Felt.body(11,
                  theme: _t, color: _t.text.withValues(alpha: 0.6))),
        ],
      ]),
    );
  }
}
