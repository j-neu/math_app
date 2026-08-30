import 'package:flutter/material.dart';
import '../services/student_auth_service.dart';

/// Three steps, one decision each: type the class code, tap your name, then
/// a calm confirmation that login worked. Nothing on this screen requires
/// reading beyond a first-grader's level — the confirmation step is a
/// placeholder for the learning-path screen, which replaces it once built.
class ChildLoginScreen extends StatefulWidget {
  final String schoolSlug;
  final StudentAuthService? authService;

  const ChildLoginScreen({super.key, required this.schoolSlug, this.authService});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

enum _Step { code, roster, welcome }

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  late final StudentAuthService _auth = widget.authService ?? StudentAuthService();
  final _codeController = TextEditingController();

  Roster? _roster;
  String? _error;
  bool _busy = false;
  _Step _step = _Step.code;
  String? _loggedInName;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roster = await _auth.fetchRoster(
        schoolSlug: widget.schoolSlug,
        classCode: _codeController.text,
      );
      setState(() {
        _roster = roster;
        _step = _Step.roster;
      });
    } on StudentAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Es hat nicht geklappt. Bitte noch einmal versuchen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(RosterEntry entry) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _auth.login(studentId: entry.id);
      if (!mounted) return;
      setState(() {
        _loggedInName =
            session.displayName.isNotEmpty ? session.displayName : entry.displayName;
        _step = _Step.welcome;
      });
    } on StudentAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToCode() {
    setState(() {
      _step = _Step.code;
      _roster = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: switch (_step) {
                  _Step.code => _buildCodeStep(context),
                  _Step.roster => _buildRosterStep(context),
                  _Step.welcome => _buildWelcomeStep(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Klassencode',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Gib den Code von der Tafel ein.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 4,
          style: const TextStyle(fontSize: 40, letterSpacing: 12),
          decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
          onSubmitted: (_) => _loadRoster(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 18)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _busy ? null : _loadRoster,
            child: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Weiter', style: TextStyle(fontSize: 22)),
          ),
        ),
      ],
    );
  }

  Widget _buildRosterStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Wer bist du?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 18)),
          const SizedBox(height: 16),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            for (final entry in _roster!.students)
              InkWell(
                onTap: _busy ? null : () => _pick(entry),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 96, minWidth: 96),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_avatarGlyph(entry.avatar), style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(entry.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _busy ? null : _backToCode,
            child: const Text('Zurück', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    final name = _loggedInName ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '⭐',
            style: TextStyle(
              fontSize: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Hallo $name!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text(
          'Schön, dass du da bist! Deine Aufgaben werden gerade vorbereitet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _busy ? null : _backToCode,
            child: const Text('Zurück zur Anmeldung', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  String _avatarGlyph(String? avatar) {
    const glyphs = {
      'fuchs': '🦊', 'eule': '🦉', 'schildkroete': '🐢', 'biene': '🐝',
      'igel': '🦔', 'wal': '🐳', 'frosch': '🐸', 'baer': '🐻',
    };
    return glyphs[avatar] ?? '⭐';
  }
}
