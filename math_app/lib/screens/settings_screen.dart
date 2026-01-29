import 'package:flutter/material.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/screens/diagnostic_screen.dart';
import 'package:math_app/screens/rewards_settings_screen.dart';
import 'package:math_app/services/user_service.dart';
import 'package:math_app/screens/diagnostic_report_screen.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const SettingsScreen({super.key, required this.userProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useBreakOffLogic;
  late bool _lockExercisesInOrder;

  @override
  void initState() {
    super.initState();
    _useBreakOffLogic = widget.userProfile.useBreakOffLogic;
    _lockExercisesInOrder = widget.userProfile.lockExercisesInOrder;
  }

  Future<void> _toggleLockExercises(bool value) async {
    setState(() {
      _lockExercisesInOrder = value;
    });

    final updatedProfile = widget.userProfile.copyWith(
      lockExercisesInOrder: value,
    );

    final userService = UserService();
    await userService.saveUser(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Exercises locked: Complete in order'
                : 'Exercises unlocked: Free choice',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleBreakOffLogic(bool value) async {
    // Check if user has in-progress diagnostic
    final hasInProgressDiagnostic = widget.userProfile.diagnosticProgress != null;

    // Warn if changing mode during active diagnostic
    if (hasInProgressDiagnostic) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Diagnostic In Progress'),
            content: const Text(
              'You have an in-progress diagnostic test. Changing the test mode will require you to restart the diagnostic from the beginning.\n\n'
              'Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Change Mode'),
              ),
            ],
          );
        },
      );

      // User cancelled
      if (shouldProceed != true) return;

      // Clear diagnostic progress since they're changing modes
      final clearedProfile = widget.userProfile.copyWith(
        useBreakOffLogic: value,
        clearDiagnosticProgress: true,
      );

      final userService = UserService();
      await userService.saveUser(clearedProfile);

      if (mounted) {
        setState(() {
          _useBreakOffLogic = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diagnostic progress reset. Mode changed to: ${value ? "Shortened Test" : "Complete Test"}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // No in-progress diagnostic, just save the preference
    setState(() {
      _useBreakOffLogic = value;
    });

    final updatedProfile = widget.userProfile.copyWith(
      useBreakOffLogic: value,
    );

    final userService = UserService();
    await userService.saveUser(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Diagnostic set to: Shortened Test (skips harder questions)'
                : 'Diagnostic set to: Complete Test (no skips)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Language Selection Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Language & Display',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English (default)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Placeholder: Show language selection dialog
              _showLanguageDialog(context);
            },
          ),
          const Divider(),

          // Learning & Progress Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Learning & Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Retake Diagnostic Test'),
            subtitle: const Text('This will reset your learning path.'),
            onTap: () {
              _showRetakeDiagnosticDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Retake Incorrect Questions'),
            subtitle: const Text('Practice only what you missed.'),
            enabled: widget.userProfile.diagnosticHistory.isNotEmpty,
            onTap: () {
              _showRetakeIncorrectDialog(context);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.quiz),
            title: const Text('Diagnostic Test Mode'),
            subtitle: Text(
              _useBreakOffLogic
                  ? 'Shortened Test (skips harder questions when easier ones fail)'
                  : 'Complete Test (all questions shown, no skips)',
            ),
            value: _useBreakOffLogic,
            onChanged: _toggleBreakOffLogic,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock),
            title: const Text('Lock Exercises in Order'),
            subtitle: Text(
              _lockExercisesInOrder
                  ? 'Exercises must be completed sequentially'
                  : 'Child can freely choose which exercise to practice',
            ),
            value: _lockExercisesInOrder,
            onChanged: _toggleLockExercises,
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Reward Settings'),
            subtitle: const Text('Configure rewards for practice milestones'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // Navigate to rewards settings screen
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RewardsSettingsScreen(
                    userProfile: widget.userProfile,
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // Reports Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Reports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('View Evaluation Report'),
            subtitle: widget.userProfile.diagnosticHistory.isEmpty
                ? const Text('No diagnostic reports available')
                : Text('Latest: ${DateFormat('MMM d, yyyy').format(widget.userProfile.diagnosticHistory.last.date)}'),
            enabled: widget.userProfile.diagnosticHistory.isNotEmpty,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (widget.userProfile.diagnosticHistory.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DiagnosticReportScreen(
                      userProfile: widget.userProfile,
                      session: widget.userProfile.diagnosticHistory.last,
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(),

          // Data Management Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete User Profile',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Permanently delete this user and all data'),
            onTap: () {
              _showDeleteUserDialog(context);
            },
          ),
          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Development)'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Pedagogical Framework'),
            subtitle: const Text('Based on iMINT & PIKAS research'),
          ),
        ],
      ),
    );
  }

  /// Show language selection dialog (placeholder)
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧'),
                title: const Text('English'),
                trailing: const Icon(Icons.check, color: Colors.green),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language already set to English'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Text('🇩🇪'),
                title: const Text('Deutsch (German)'),
                subtitle: const Text('Coming soon'),
                enabled: false,
                onTap: () {
                  // Placeholder: Will be implemented in Phase 3, Task 3.4
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Show retake incorrect confirmation dialog
  void _showRetakeIncorrectDialog(BuildContext context) {
    // Check if there are actually any incorrect questions
    if (widget.userProfile.diagnosticHistory.isEmpty) return;
    
    final lastSession = widget.userProfile.diagnosticHistory.last;
    final incorrectCount = lastSession.results.where((r) => !r.wasCorrect).length;
    
    if (incorrectCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great job! You answered all questions correctly in the last test.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retake Incorrect Questions?'),
          content: Text(
            'You will retake the $incorrectCount questions you missed in the last diagnostic test.\n\n'
            'This will create a new updated learning path based on your new answers.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
                if (context.mounted) Navigator.of(context).pop();
                // Close the settings screen
                if (context.mounted) Navigator.of(context).pop();
                
                // Navigate to diagnostic test in retry mode
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DiagnosticScreen(
                        userProfile: widget.userProfile,
                        retryMode: true,
                      ),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Retake Incorrect'),
            ),
          ],
        );
      },
    );
  }

  /// Show retake diagnostic confirmation dialog
  void _showRetakeDiagnosticDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retake Diagnostic Test?'),
          content: const Text(
            'This will reset your current learning path and skill tags. '
            'You will retake the diagnostic test to create a new personalized learning path.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Clear all diagnostic data from the user profile
                final clearedProfile = widget.userProfile.copyWith(
                  skillTags: [],
                  diagnosticResults: [],
                  clearDiagnosticProgress: true,
                );

                // Save the cleared profile
                final userService = UserService();
                await userService.saveUser(clearedProfile);

                // Close the dialog
                if (context.mounted) Navigator.of(context).pop();
                // Close the settings screen
                if (context.mounted) Navigator.of(context).pop();
                // Navigate to diagnostic test with cleared profile
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DiagnosticScreen(userProfile: clearedProfile),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Retake Test'),
            ),
          ],
        );
      },
    );
  }

  /// Show delete user confirmation dialog
  void _showDeleteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User Profile?'),
          content: Text(
            'This will permanently delete the profile for "${widget.userProfile.name}" and all associated progress/data.\n\n'
            'This action cannot be undone.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the user
                final userService = UserService();
                await userService.deleteUser(widget.userProfile.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate back to the user selection screen (root)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User "${widget.userProfile.name}" deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete User'),
            ),
          ],
        );
      },
    );
  }
}