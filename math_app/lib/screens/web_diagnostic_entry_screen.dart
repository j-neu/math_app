import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'diagnostic_complete_screen.dart';
import 'diagnostic_screen.dart';

// Entry point for the web student flow: receives a ticket ID from the URL,
// exchanges it for a session, then launches DiagnosticScreen.
class WebDiagnosticEntryScreen extends StatefulWidget {
  final String ticketId;

  const WebDiagnosticEntryScreen({super.key, required this.ticketId});

  @override
  State<WebDiagnosticEntryScreen> createState() =>
      _WebDiagnosticEntryScreenState();
}

class _WebDiagnosticEntryScreenState extends State<WebDiagnosticEntryScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final (:sessionId, :resumed, :alreadyCompleted, :priorResults) =
          await ApiService().startSession(widget.ticketId);
      if (!mounted) return;

      if (alreadyCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DiagnosticCompleteScreen()),
        );
        return;
      }

      final profile = UserProfile(
        id: sessionId,
        name: 'Schüler',
        age: 7,
        skillTags: const [],
        useBreakOffLogic: true,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagnosticScreen(
            userProfile: profile,
            sessionId: sessionId,
            priorResults: resumed ? priorResults : null,
          ),
        ),
      );
    } on SessionExpiredException {
      setState(() => _error =
          'Dieser Link ist abgelaufen.\nBitte bitte deine Lehrkraft um einen neuen QR-Code.');
    } on TicketNotFoundException {
      setState(() => _error =
          'Dieser Link ist ungültig.\nBitte bitte deine Lehrkraft um einen neuen QR-Code.');
    } catch (_) {
      setState(() => _error =
          'Ein Fehler ist aufgetreten.\nBitte versuche es später noch einmal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEC4748), size: 64),
                    const SizedBox(height: 24),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Diagnose wird vorbereitet …',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Shown at the web root (/) when no ticket is in the URL.
class NoTicketScreen extends StatelessWidget {
  const NoTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner,
                  color: Color(0xFF154761), size: 80),
              const SizedBox(height: 32),
              Text(
                'Bitte scanne den QR-Code deines Lehrers,\num die Diagnose zu starten.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
