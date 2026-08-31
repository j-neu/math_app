import 'package:flutter/material.dart';
import '../services/student_auth_service.dart';

/// Steps, one decision each: type the class code, tap your name, optionally
/// tap your four-picture Bildfolge, then a calm confirmation. Nothing here
/// requires reading beyond a first-grader's level — the confirmation step is
/// a placeholder for the learning-path screen, which replaces it once built.
class ChildLoginScreen extends StatefulWidget {
  final String schoolSlug;
  final StudentAuthService? authService;

  const ChildLoginScreen({super.key, required this.schoolSlug, this.authService});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

enum _Step { code, roster, pin, welcome }

/// The Bildfolge alphabet. Material icons, not emoji: the MaterialIcons font
/// ships with the app, so these render on every platform. Emoji depend on a
/// system font that a school tablet may not have.
const List<({String token, IconData icon, String label})> kPinSymbols = [
  (token: 'stern', icon: Icons.star, label: 'Stern'),
  (token: 'herz', icon: Icons.favorite, label: 'Herz'),
  (token: 'blume', icon: Icons.local_florist, label: 'Blume'),
  (token: 'sonne', icon: Icons.wb_sunny, label: 'Sonne'),
  (token: 'ball', icon: Icons.sports_soccer, label: 'Ball'),
  (token: 'auto', icon: Icons.directions_car, label: 'Auto'),
  (token: 'haus', icon: Icons.home, label: 'Haus'),
  (token: 'baum', icon: Icons.park, label: 'Baum'),
];

const int kPinLength = 4;

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  late final StudentAuthService _auth = widget.authService ?? StudentAuthService();
  final _codeController = TextEditingController();

  Roster? _roster;
  String? _error;
  bool _busy = false;
  _Step _step = _Step.code;
  String? _loggedInName;

  /// The student whose tile is waiting on the server, so only that tile spins.
  String? _pendingStudentId;

  RosterEntry? _pinFor;
  final List<String> _pinTokens = [];

  /// Synchronous re-entrancy latch for the requirePin branch of `_tapName`,
  /// which never touches `_busy` (it does no network call, so `_busy`'s
  /// "request in flight" meaning doesn't fit — and setting `_busy` there
  /// would also disable the picture-step's own symbol tiles once shown).
  /// Two fingers on two different name tiles in the same frame both run
  /// `_tapName` before either sees the rebuilt, disabled tile, so this must
  /// be checked and set synchronously, before the first `setState`. Reset
  /// on the way back out to the roster or code step, wherever a name tile
  /// becomes tappable again.
  bool _navigating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    // Same re-entrancy reasoning as `_login` below: two pointer-downs on
    // "Weiter" in the same frame both run against the widget tree built
    // while `_busy` was still false, so this must be checked synchronously,
    // before the first `await`, not left to the build-time `onPressed`
    // guard alone.
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roster = await _auth.fetchRoster(
        schoolSlug: widget.schoolSlug,
        classCode: _codeController.text,
      );
      if (!mounted) return;
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

  /// A class with Bildfolge switched on goes to the picture step first;
  /// otherwise the tap logs the child straight in.
  ///
  /// The `_busy ? null : ...` guard on the tile's `onTap` is only checked
  /// when the widget tree is built, so two pointer-down events landing in
  /// the same frame (a child mashing the tablet with two fingers) both call
  /// this handler with the stale, pre-tap `_busy == false`. This early
  /// return re-checks synchronously, before any `await`, so the second tap
  /// of the same frame is rejected even though the build-time guard let it
  /// through.
  void _tapName(RosterEntry entry) {
    if (_busy || _navigating) return;
    if (_roster?.requirePin ?? false) {
      // This branch never awaits and never sets `_busy` (there is no
      // network call yet — the request only happens once the four
      // pictures are entered) so `_navigating` is the guard here: set
      // synchronously before `setState`, so a second tap on a different
      // tile in the same frame is rejected instead of silently overwriting
      // `_pinFor`/`_pinTokens`/`_step` with the second child's tap.
      _navigating = true;
      setState(() {
        _pinFor = entry;
        _pinTokens.clear();
        _error = null;
        _step = _Step.pin;
      });
    } else {
      _login(entry);
    }
  }

  Future<void> _login(RosterEntry entry, {String? pin}) async {
    // Same re-entrancy reasoning as `_tapName`: this must be the very first
    // line, before the `setState` below, so a second concurrent call (from
    // a two-finger mash, or `_tapPinSymbol` firing twice) is rejected
    // synchronously instead of starting a second HTTP login that could
    // overwrite `_loggedInName`/`_step` with the wrong child's response.
    if (_busy) return;
    setState(() {
      _busy = true;
      _pendingStudentId = entry.id;
      _error = null;
    });
    try {
      final session = await _auth.login(studentId: entry.id, pin: pin);
      if (!mounted) return;
      setState(() {
        _loggedInName =
            session.displayName.isNotEmpty ? session.displayName : entry.displayName;
        _step = _Step.welcome;
      });
    } on StudentAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _pinTokens.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Es hat nicht geklappt. Bitte noch einmal versuchen.';
        _pinTokens.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pendingStudentId = null;
        });
      }
    }
  }

  void _tapPinSymbol(String token) {
    // Already a synchronous re-entrancy guard (checked before any `await`),
    // same reasoning as `_tapName`/`_login` above: a two-finger tap on the
    // fourth and final symbol runs both calls back-to-back with no yield in
    // between, so by the time the second one checks `_pinTokens.length` the
    // first has already pushed it to `kPinLength`, and this returns.
    if (_busy || _pinTokens.length >= kPinLength) return;
    setState(() {
      _pinTokens.add(token);
      _error = null;
    });
    if (_pinTokens.length == kPinLength && _pinFor != null) {
      _login(_pinFor!, pin: _pinTokens.join('-'));
    }
  }

  void _clearPin() => setState(() {
        _pinTokens.clear();
        _error = null;
      });

  Future<void> _backToCode() async {
    // Same re-entrancy reasoning as `_loadRoster`/`_login` above: two
    // pointer-downs on "Zurück" in the same frame both run against the
    // widget tree built while `_busy` was still false, so this must be
    // checked synchronously, before the `await` below, not left to the
    // build-time `onPressed` guard alone.
    if (_busy) return;
    setState(() => _busy = true);
    // Backing out must not leave the previous child signed in on a shared tablet.
    await _auth.logout();
    if (!mounted) return;
    setState(() {
      _step = _Step.code;
      _roster = null;
      _error = null;
      _pinFor = null;
      _pinTokens.clear();
      _loggedInName = null;
      _navigating = false;
      _busy = false;
    });
  }

  void _backToRoster() => setState(() {
        _step = _Step.roster;
        _pinFor = null;
        _pinTokens.clear();
        _error = null;
        _navigating = false;
      });

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
                  _Step.pin => _buildPinStep(context),
                  _Step.welcome => _buildWelcomeStep(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorText(BuildContext context) => Text(
        _error!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 18),
      );

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
          _errorText(context),
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
    final students = _roster?.students ?? const <RosterEntry>[];
    // Computed once per build over the whole roster (not per tile) so that
    // same-initial collisions can be resolved against each other — see
    // `_assignAvatarColours`.
    final avatarColours = _assignAvatarColours(students);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Wer bist du?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_error != null) ...[
          _errorText(context),
          const SizedBox(height: 16),
        ],
        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Für eure Klasse sind noch keine Kinder eingetragen. '
              'Sag das bitte deiner Lehrkraft.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              for (final entry in students) _nameTile(context, entry, avatarColours[entry.id]!),
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

  Widget _nameTile(BuildContext context, RosterEntry entry, Color avatarColour) {
    final scheme = Theme.of(context).colorScheme;
    final waiting = _pendingStudentId == entry.id;

    return InkWell(
      onTap: _busy ? null : () => _tapName(entry),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: waiting
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : _initialAvatar(context, entry, avatarColour),
            ),
            const SizedBox(height: 6),
            // Flexible so a long or hyphenated name shrinks instead of
            // overflowing its tile — German class lists are full of them.
            Flexible(
              child: Text(
                entry.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A circle carrying the child's initial, coloured per `_assignAvatarColours`.
  /// Renders on every platform (no emoji font needed).
  Widget _initialAvatar(BuildContext context, RosterEntry entry, Color avatarColour) {
    final initial =
        entry.displayName.isNotEmpty ? entry.displayName.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: avatarColour,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // All 20 swatches are dark enough to carry white bold text legibly (WCAG
  // contrast ratio against white is >= 4.5:1 for every entry here, well past
  // the 3:1 large-bold-text minimum). Two former swatches — an orange
  // (0xFFEF6C00, ratio ~3.1) and a custom brown (0xFF9E5700) — read visibly
  // weaker than the rest and were replaced. Cyan 800 (0xFF00838F, ratio
  // ~4.52:1) was later swapped for cyan 900 (0xFF006064, ratio ~7.35:1): it
  // cleared the 4.5:1 threshold by only 0.02, too fragile to rely on.
  static const List<Color> _avatarPalette = [
    Color(0xFFC62828), // red 800
    Color(0xFFB71C1C), // red 900
    Color(0xFFBF360C), // deep orange 900
    Color(0xFF5D4037), // brown 700
    Color(0xFF3E2723), // brown 900
    Color(0xFF827717), // olive (lime 900)
    Color(0xFF2E7D32), // green 800
    Color(0xFF1B5E20), // green 900
    Color(0xFF00695C), // teal 800
    Color(0xFF006064), // cyan 900
    Color(0xFF0277BD), // light blue 800
    Color(0xFF1565C0), // blue 800
    Color(0xFF283593), // indigo 800
    Color(0xFF1A237E), // indigo 900 / navy
    Color(0xFF4527A0), // deep purple 800
    Color(0xFF6A1B9A), // purple 800
    Color(0xFFAD1457), // pink 800
    Color(0xFF880E4F), // pink 900 / wine
    Color(0xFF37474F), // blue grey 800
    Color(0xFF424242), // grey 800
  ];

  /// The starting palette index for a child, before collision resolution.
  /// Deterministic on `id` alone.
  int _preferredColourIndex(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % _avatarPalette.length;
  }

  /// Assigns each student in [students] a colour from `_avatarPalette`.
  ///
  /// A pure per-id hash cannot guarantee two children with the same first
  /// initial get different colours — same-initial pairs are the norm in a
  /// German class list (Franziska/Finn, Marlene/Max, ...), not an edge case,
  /// and a child hunting for "my purple F" among two identical purple F's is
  /// exactly the failure this avoids. So: walk the roster in the stable
  /// order it is given, and whenever a child's hashed colour is already
  /// taken by an earlier child sharing their initial, advance to the next
  /// free colour in the palette for that initial.
  ///
  /// Deterministic: the same roster, in the same order, always produces the
  /// same colours, so a child's tile does not change between sessions.
  Map<String, Color> _assignAvatarColours(List<RosterEntry> students) {
    final colours = <String, Color>{};
    final usedByInitial = <String, Set<int>>{};
    for (final entry in students) {
      final initial =
          entry.displayName.isNotEmpty ? entry.displayName.substring(0, 1).toUpperCase() : '?';
      final used = usedByInitial.putIfAbsent(initial, () => <int>{});
      var index = _preferredColourIndex(entry.id);
      // Advance deterministically to the next free slot for this initial.
      // Since `used.length < _avatarPalette.length` here, an unused index
      // is guaranteed to exist and this always terminates.
      while (used.contains(index) && used.length < _avatarPalette.length) {
        index = (index + 1) % _avatarPalette.length;
      }
      used.add(index);
      colours[entry.id] = _avatarPalette[index];
    }
    return colours;
  }

  Widget _buildPinStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = _pinFor?.displayName ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Deine Bildfolge',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Hallo $name! Tippe deine vier Bilder an.',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kPinLength; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  key: ValueKey('pin-dot-$i'),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pinTokens.length ? scheme.primary : Colors.transparent,
                    border: Border.all(color: scheme.outline, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          _errorText(context),
          const SizedBox(height: 16),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final symbol in kPinSymbols)
              InkWell(
                onTap: _busy ? null : () => _tapPinSymbol(symbol.token),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant, width: 2),
                  ),
                  child: Semantics(
                    label: symbol.label,
                    child: Icon(symbol.icon, size: 36, color: scheme.primary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _busy || _pinTokens.isEmpty ? null : _clearPin,
            child: const Text('Nochmal', style: TextStyle(fontSize: 18)),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _busy ? null : _backToRoster,
            child: const Text('Zurück', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = _loggedInName ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(
              fontSize: 48,
              color: scheme.onPrimaryContainer,
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
            style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
            onPressed: _busy ? null : _backToCode,
            child: const Text('Zurück zur Anmeldung', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
