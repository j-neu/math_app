// Throwaway dev entry point to preview the 3 items that closed the
// remaining content gaps (master ListNumbers 109-111: place_on_numberline_zr20,
// place_on_numberline_zr100, number_word_dictation_zr100) without going
// through login or the other questions. Delete this file when done reviewing.
//
// Run with: flutter run -t lib/dev_preview_gap_items.dart -d windows
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
      title: 'Gap Items Preview',
      home: DiagnosticScreen(
        userProfile: UserProfile(
          id: 'dev-preview',
          name: 'Dev Preview',
          age: 8,
          skillTags: const [],
        ),
        retryMode: true,
        retryQuestionNumbers: const [109, 110, 111],
      ),
    );
  }
}
