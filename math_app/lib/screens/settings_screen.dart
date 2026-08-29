import 'package:flutter/material.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/screens/diagnostic_screen.dart';
import 'package:math_app/screens/rewards_settings_screen.dart';
import 'package:math_app/services/user_service.dart';
import 'package:math_app/screens/diagnostic_report_screen.dart';
import 'package:math_app/services/diagnostic_report_generator.dart';
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
                ? 'Übungen gesperrt: Der Reihe nach freischalten'
                : 'Übungen freigegeben: Freie Auswahl',
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
            title: const Text('Diagnose läuft noch'),
            content: const Text(
              'Es läuft gerade eine Diagnose. Wenn du den Modus änderst, musst du die Diagnose von vorne beginnen.\n\n'
              'Möchtest du fortfahren?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Modus ändern'),
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
              'Diagnose zurückgesetzt. Modus geändert auf: ${value ? "Verkürzte Diagnose" : "Vollständige Diagnose"}',
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
                ? 'Diagnose-Modus: Verkürzt (schwere Fragen werden übersprungen)'
                : 'Diagnose-Modus: Vollständig (keine Auslassungen)',
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
        title: const Text('Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Learning & Progress Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Lernen & Fortschritt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Diagnose wiederholen'),
            subtitle: const Text('Setzt den Lernpfad zurück.'),
            onTap: () {
              _showRetakeDiagnosticDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Falsche Antworten wiederholen'),
            subtitle: const Text('Nur die verpassten Fragen üben.'),
            enabled: widget.userProfile.diagnosticHistory.isNotEmpty,
            onTap: () {
              _showRetakeIncorrectDialog(context);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.quiz),
            title: const Text('Diagnose-Modus'),
            subtitle: Text(
              _useBreakOffLogic
                  ? 'Verkürzte Diagnose (schwere Fragen werden übersprungen, wenn leichtere nicht gelöst wurden)'
                  : 'Vollständige Diagnose (alle Fragen, keine Auslassungen)',
            ),
            value: _useBreakOffLogic,
            onChanged: _toggleBreakOffLogic,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock),
            title: const Text('Übungen der Reihe nach freischalten'),
            subtitle: Text(
              _lockExercisesInOrder
                  ? 'Übungen werden nacheinander freigeschaltet'
                  : 'Kind kann frei wählen, welche Übung es macht',
            ),
            value: _lockExercisesInOrder,
            onChanged: _toggleLockExercises,
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Belohnungen'),
            subtitle: const Text('Belohnungen für Übungs-Meilensteine festlegen'),
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
              'Berichte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Förderplan ansehen'),
            subtitle: widget.userProfile.diagnosticHistory.isEmpty
                ? const Text('Noch keine Diagnose abgeschlossen')
                : Text('Zuletzt: ${DateFormat('d. MMMM yyyy', 'de_DE').format(widget.userProfile.diagnosticHistory.last.date)}'),
            enabled: widget.userProfile.diagnosticHistory.isNotEmpty,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              if (widget.userProfile.diagnosticHistory.isEmpty) return;
              final session = widget.userProfile.diagnosticHistory.last;
              final foerderplan = await DiagnosticReportGenerator()
                  .generate(widget.userProfile, session);
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiagnosticReportScreen(
                    userProfile: widget.userProfile,
                    session: session,
                    foerderplan: foerderplan,
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // Data Management Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Daten',
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
              'Profil löschen',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Profil und alle Daten dauerhaft löschen'),
            onTap: () {
              _showDeleteUserDialog(context);
            },
          ),
          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Über die App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App-Version'),
            subtitle: const Text('1.0.0 (Entwicklung)'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Pädagogisches Konzept'),
            subtitle: const Text(
                'Auf Grundlage der mathematikdidaktischen Forschung zur '
                'Prävention von Rechenschwierigkeiten'),
          ),
        ],
      ),
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
        const SnackBar(content: Text('Klasse! Du hast in der letzten Diagnose alle Fragen richtig beantwortet.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Falsche Antworten wiederholen?'),
          content: Text(
            'Du wiederholst die $incorrectCount Fragen, die du in der letzten Diagnose nicht richtig hattest.\n\n'
            'Daraus entsteht ein aktualisierter Lernpfad.\n\n'
            'Möchtest du fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
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
              child: const Text('Falsche wiederholen'),
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
          title: const Text('Diagnose wiederholen?'),
          content: const Text(
            'Dadurch werden dein Lernpfad und alle Bereiche zurückgesetzt. '
            'Du machst die Diagnose erneut und bekommst einen neuen, persönlichen Lernpfad.\n\n'
            'Möchtest du fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
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
              child: const Text('Diagnose wiederholen'),
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
          title: const Text('Profil löschen?'),
          content: Text(
            'Das Profil von „${widget.userProfile.name}" und alle Fortschritte werden dauerhaft gelöscht.\n\n'
            'Diese Aktion kann nicht rückgängig gemacht werden.\n\n'
            'Möchtest du fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
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
                      content: Text('Profil „${widget.userProfile.name}" gelöscht'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Profil löschen'),
            ),
          ],
        );
      },
    );
  }
}