import 'package:flutter/material.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/screens/diagnostic_screen.dart';
import 'package:math_app/screens/learning_path_screen.dart';
import 'package:math_app/screens/settings_screen.dart';
import 'package:math_app/screens/user_selection_screen.dart';
import 'package:math_app/services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numeris Math App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF154761), // Primary brand color
          primary: const Color(0xFF154761),
          secondary: const Color(0xFF77CDD5),
          error: const Color(0xFFEC4748),
        ),
        useMaterial3: true,
      ),
      home: const UserSelectionScreen(),
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
    // Always load fresh data from database when HomeScreen is shown
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

    // Determine user state: in-progress diagnostic, new user, or returning user
    final bool hasInProgressDiagnostic = _currentProfile.diagnosticProgress != null;
    final bool hasCompletedDiagnostic = _currentProfile.skillTags.isNotEmpty;

    // Check if diagnostic was actually completed (not just partially done)
    // A completed diagnostic should have diagnosticResults, not just skillTags
    final bool hasActuallyCompletedDiagnostic =
        _currentProfile.diagnosticResults != null &&
        _currentProfile.diagnosticResults!.isNotEmpty;

    // Check if user bypassed diagnostic (created via "Start Without Diagnostic")
    // These users have many skillTags (typically 87+) but no diagnosticProgress or diagnosticResults
    final bool bypassedDiagnostic =
        _currentProfile.diagnosticProgress == null &&
        _currentProfile.diagnosticResults == null &&
        _currentProfile.skillTags.length > 50; // Threshold: more than 50 skills = bypassed

    String buttonText;
    Widget destinationScreen;
    String message;

    if (hasInProgressDiagnostic) {
      // User has partially completed diagnostic
      buttonText = 'Continue Diagnostic Test';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'You\'re ${_currentProfile.diagnosticProgress! + 1} questions into the diagnostic test!';
    } else if (hasActuallyCompletedDiagnostic || bypassedDiagnostic) {
      // User has completed diagnostic OR bypassed it and has a learning path
      buttonText = 'View Learning Path';
      destinationScreen = LearningPathScreen(userProfile: _currentProfile);
      message = bypassedDiagnostic
          ? 'Ready to start practicing? ${_currentProfile.skillTags.length} skills available!'
          : 'Ready for your next challenge?';
    } else if (hasCompletedDiagnostic) {
      // User has some skill tags but diagnostic progress was lost - let them resume
      buttonText = 'Resume Diagnostic Test';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'Let\'s continue where you left off!';
    } else {
      // New user who hasn't started diagnostic yet
      buttonText = 'Start Diagnostic Test';
      destinationScreen = DiagnosticScreen(userProfile: _currentProfile);
      message = 'Let\'s find out what you already know!';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_currentProfile.name}!'),
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
                  // Reload user data when returning from diagnostic or learning path
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
