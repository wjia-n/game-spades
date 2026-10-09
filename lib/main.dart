import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/cardroom.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SpadesSettings();
  await settings.load();
  final audio = SpadesAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SpadesApp(settings: settings, audio: audio));
}

class SpadesApp extends StatefulWidget {
  final SpadesSettings settings;
  final SpadesAudio audio;
  const SpadesApp({super.key, required this.settings, required this.audio});

  @override
  State<SpadesApp> createState() => _SpadesAppState();
}

class _SpadesAppState extends State<SpadesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Spades',
        debugShowCheckedModeBanner: false,
        theme: Felt.theme(widget.settings.theme),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
