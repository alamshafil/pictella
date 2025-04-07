import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'utils/app_preferences.dart';
import 'utils/app_settings.dart';
import 'screens/main_screen.dart';
import 'screens/api_key_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load app settings
  await AppSettings.instance.initialize();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    final hasSeenOnboarding = await AppPreferences.hasSeenOnboarding();
    final hasApiKey = await AppPreferences.hasApiKey();

    setState(() {
      _hasSeenOnboarding = hasSeenOnboarding;
      _hasApiKey = hasApiKey;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pictella',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.albertSansTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF64B5F6),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: _isLoading ? const _LoadingScreen() : _getStartScreen(),
    );
  }

  Widget _getStartScreen() {
    if (!_hasSeenOnboarding) {
      return const WelcomeScreen();
    } else if (!_hasApiKey) {
      return const ApiKeyScreen(isFirstSetup: true);
    } else {
      return const MainScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
