import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'diagnostic_complete_screen.dart';
import 'diagnostic_screen.dart';

// Entry screen for the short-URL classroom flow.
// The teacher writes the school URL on the board; each student enters their
// personal 4-character code here to start their diagnostic session.
class SchoolCodeEntryScreen extends StatefulWidget {
  final String schoolSlug;

  const SchoolCodeEntryScreen({super.key, required this.schoolSlug});

  @override
  State<SchoolCodeEntryScreen> createState() => _SchoolCodeEntryScreenState();
}

class _SchoolCodeEntryScreenState extends State<SchoolCodeEntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _error = 'Bitte gib genau 4 Zeichen ein.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (:sessionId, :resumed, :alreadyCompleted, :priorResults) =
          await ApiService().startSessionByCode(widget.schoolSlug, code);
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
    } on TicketNotFoundException {
      setState(() => _error = 'Code nicht gefunden. Bitte prüfe die Eingabe oder frage deine Lehrkraft.');
    } catch (_) {
      setState(() => _error = 'Ein Fehler ist aufgetreten. Bitte versuche es noch einmal.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.keyboard, color: Color(0xFF154761), size: 64),
                const SizedBox(height: 32),
                Text(
                  'Gib deinen Code ein',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dein Lehrer hat dir einen 4-stelligen Code gegeben.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: '_ _ _ _',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 40,
                      letterSpacing: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF154761), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEC4748), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF154761),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Weiter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
