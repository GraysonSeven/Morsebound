import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cloud/cloud_account_service.dart';
import 'ui/account_screen.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudAccountService.instance.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFF061218),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: Color(0xFFFFD166),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MORSEBOUND RECOVERY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A screen failed to render. Restart Morsebound or report '
                  'the Flutter terminal error.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF061218),
      systemNavigationBarColor: Color(0xFF061218),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runZonedGuarded(
    () => runApp(const MorseboundApp()),
    (error, stack) {
      debugPrint('Morsebound uncaught error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MorseboundApp extends StatelessWidget {
  const MorseboundApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF55D6BE);

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF67E3CD),
      onPrimary: const Color(0xFF02251F),
      secondary: const Color(0xFFFFD166),
      surface: const Color(0xFF0B1C22),
      onSurface: const Color(0xFFE7F0F2),
      outline: const Color(0xFF44616A),
    );

    return MaterialApp(
      title: 'Morsebound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF061218),
        cardTheme: CardThemeData(
          color: const Color(0xFF0C2027),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: const Color(0xFF47646D).withValues(alpha: 0.24),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF061218),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0A1B21),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3F5962)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF314A52)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF55D6BE),
              width: 1.5,
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF133039),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF284049),
        ),
      ),
      home: const _LaunchGate(),
    );
  }
}

/// Login-first entry point shared by Web and Android.
///
/// Existing authenticated users go straight to HomeScreen. Signed-out users
/// are asked to sign in/create an account before training. Offline/local mode
/// remains available, but must be deliberately chosen each app launch.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool _continueOfflineForSession = false;

  @override
  Widget build(BuildContext context) {
    final cloud = CloudAccountService.instance;

    return ValueListenableBuilder<CloudAccountState>(
      valueListenable: cloud.state,
      builder: (context, state, _) {
        if (state.signedIn || _continueOfflineForSession) {
          return const HomeScreen();
        }

        return AccountScreen(
          launchMode: true,
          onContinueOffline: () {
            setState(() => _continueOfflineForSession = true);
          },
        );
      },
    );
  }
}
