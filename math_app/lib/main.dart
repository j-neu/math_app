import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/screens/diagnostic_screen.dart';
import 'package:math_app/screens/learning_path_screen.dart';
import 'package:math_app/screens/settings_screen.dart';
import 'package:math_app/screens/user_selection_screen.dart';
import 'package:math_app/screens/school_code_entry_screen.dart';
import 'package:math_app/screens/web_diagnostic_entry_screen.dart';
import 'package:math_app/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy(); // Clean URLs: /s/<ticket> instead of /#/s/<ticket>
  }
  await initializeDateFormatting('de_DE', null);
  runApp(const MyApp());
}

final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          kIsWeb ? const NoTicketScreen() : const UserSelectionScreen(),
    ),
    GoRoute(
      path: '/s/:param',
      builder: (context, state) {
        final param = state.pathParameters['param']!;
        // UUIDs are 8-4-4-4-12 hex with dashes (36 chars); anything else is a school slug.
        if (_uuidRegex.hasMatch(param)) {
          return WebDiagnosticEntryScreen(ticketId: param);
        }
        return SchoolCodeEntryScreen(schoolSlug: param);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Numeris – Mathe-Diagnose',
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF154761),
          primary: const Color(0xFF154761),
          secondary: const Color(0xFF77CDD5),
          error: const Color(0xFFEC4748),
        ),
        useMaterial3: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;

  const HomeScreen({super.key, required this.userProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProfile _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('=== HomeScreen._loadUserProfile() - Loading user ${widget.userProfile.id} ===');
    final userService = UserService();
    final freshProfile = await userService.getUserById(widget.userProfile.id);

    print('=== HomeScreen._loadUserProfile() - Fresh profile loaded ===');
    if (freshProfile != null) {
      print('  - diagnosticProgress: ${freshProfile.diagnosticProgress}');
      print('  - skillTags: ${freshProfile.skillTags.length}');
      print('  - diagnosticAnswers: ${freshProfile.diagnosticAnswers?.length ?? 0}');
    } else {
      print('  - WARNING: freshProfile is null, using widget.userProfile');
    }

    setState(() {
      _currentProfile = freshProfile ?? widget.userProfile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool hasInProgressDiagnostic = _currentProfile.diagnosticProgress != null;
    final bool hasCompletedDiagnostic = _currentProfile.skillTags.isNotEmpty;

    final bool hasActuallyCompletedDiagnostic =
        (_currentProfile.diagnosticResults != null && _currentProfile.diagnosticResults!.isNotEmpty) ||
        (_currentProfile.diagnosticHistory.isNotEmpty && _currentProfile.diagnosticHistory.last.results.isNotEmpty);

    final bool bypassedDiagnostic =
        _currentProfile.diagnosticProgress == null &&
        _currentProfile.diagnosticResults == null &&
        _currentProfile.skillTags.length > 50;

    String buttonText;
    Widget destinationScreen;
    String message;

    if (hasInProgressDiagnostic) {
      buttonText = 'Diagnose fortsetzen';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'Du hast schon ${_currentProfile.diagnosticProgress! + 1} Fragen geschafft!';
    } else if (hasActuallyCompletedDiagnostic || bypassedDiagnostic) {
      buttonText = 'Zum Lernpfad';
      destinationScreen = LearningPathScreen(userProfile: _currentProfile);
      message = bypassedDiagnostic
          ? 'Bereit zum Üben? Es warten ${_currentProfile.skillTags.length} Bereiche auf dich!'
          : 'Bereit für die nächste Aufgabe?';
    } else if (hasCompletedDiagnostic) {
      buttonText = 'Diagnose fortsetzen';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'Lass uns da weitermachen, wo du aufgehört hast!';
    } else {
      buttonText = 'Diagnose starten';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'Lass uns herausfinden, was du schon kannst!';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo, ${_currentProfile.name}!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(userProfile: _currentProfile),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => destinationScreen,
                    ),
                  );
                  _loadUserProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
