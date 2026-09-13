// Throwaway dev entry point to preview the new v3 Stellenwerte verstehen
// diagnostic slice (ListNumbers 401-408) without going through login or the
// other questions. Delete this file when done reviewing.
//
// Run with: flutter run -t lib/dev_preview_stellenwerte.dart -d windows
// (or -d chrome / -d edge for the web target)

import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'screens/diagnostic_screen.dart';

void main() {
  runApp(const DevPreviewApp());
}

class DevPreviewApp extends StatelessWidget {
  const DevPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellenwerte v3 Preview',
      home: DiagnosticScreen(
        userProfile: UserProfile(
          id: 'dev-preview',
          name: 'Dev Preview',
          age: 8,
          skillTags: const [],
        ),
        retryMode: true,
        retryQuestionNumbers: List.generate(8, (i) => 401 + i),
      ),
    );
  }
}
