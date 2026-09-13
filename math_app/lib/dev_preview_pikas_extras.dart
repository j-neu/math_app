// Throwaway dev entry point to preview the new v3 PIKAS-extras diagnostic
// slice (ListNumbers 701-710: Ordinal Numbers, Representation Networking,
// Operational Sense, Advanced Number Line) without going through login or
// the other questions. Delete this file when done reviewing.
//
// Run with: flutter run -t lib/dev_preview_pikas_extras.dart -d windows
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
      title: 'PIKAS Extras v3 Preview',
      home: DiagnosticScreen(
        userProfile: UserProfile(
          id: 'dev-preview',
          name: 'Dev Preview',
          age: 8,
          skillTags: const [],
        ),
        retryMode: true,
        retryQuestionNumbers: List.generate(10, (i) => 701 + i),
      ),
    );
  }
}
