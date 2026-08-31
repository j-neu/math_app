/// The child-facing learning-path screen (P2 plan §6, task 10).
///
/// Loads the child's token + display name from [StudentAuthService] prefs
/// (both injectable for tests), fetches the server [LearningPath] via
/// [LearningPathService] and renders one tile per [PathItem]. States:
/// no token → sign-in prompt; loading → spinner; load failed → German error
/// + retry; no active path → friendly "Lehrkraft bereitet deinen Lernpfad
/// vor" empty state; path present → header with child name + logout, an
/// overview strip and the item list. Available / in-progress tiles open
/// [PracticeScreen]; returning from practice refetches the path so the
/// mastered/unlock state is fresh. Every state is conveyed by icon + text,
/// never colour alone (ADHD/a11y guideline).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/learning_path.dart';
import '../models/skill_spec.dart';
import '../services/learning_path_service.dart';
import '../services/skill_spec_store.dart';
import '../services/student_auth_service.dart';
import 'practice_screen.dart';

/// The child-facing learning-path screen.
class ChildPathScreen extends StatefulWidget {
  /// Optional token override (tests). When null the screen reads the stored
  /// token from [StudentAuthService] prefs.
  final String? token;

  /// Optional display-name override (tests). When null the screen reads the
  /// stored name from [StudentAuthService] prefs.
  final String? displayName;

  /// Optional service (tests). Defaults to a real [LearningPathService].
  final LearningPathService? service;

  /// Optional spec store (tests). Defaults to the bundled asset specs.
  final SkillSpecStore? store;

  const ChildPathScreen({
    super.key,
    this.token,
    this.displayName,
    this.service,
    this.store,
  });

  @override
  State<ChildPathScreen> createState() => _ChildPathScreenState();
}

class _ChildPathScreenState extends State<ChildPathScreen> {
  late final LearningPathService _service = widget.service ?? LearningPathService();

  bool _loading = true;
  String? _error;
  String? _token;
  String? _name;
  LearningPath? _path;
  SkillSpecStore? _store;

  @override
  void initState() {
    super.initState();
    // Deferred so the first synchronous setState from _load() does not run
    // during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _resolve();
  }

  /// Refetches the path without blanking the screen (used on return from
  /// practice, so the old list stays visible while it refreshes).
  Future<void> _refresh() => _resolve();

  Future<void> _resolve() async {
    try {
      final token = widget.token ?? await StudentAuthService().storedToken();
      if (!mounted) return;
      if (token == null) {
        setState(() {
          _token = null;
          _name = null;
          _path = null;
          _store = null;
          _loading = false;
          _error = null;
        });
        return;
      }
      final name = widget.displayName ?? await StudentAuthService().storedName();
      final path = await _service.fetchPath(token);
      final store = widget.store ?? await SkillSpecStore.load();
      if (!mounted) return;
      setState(() {
        _token = token;
        _name = name;
        _path = path;
        _store = store;
        _loading = false;
        _error = null;
      });
    } on LearningPathException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Der Lernpfad konnte gerade nicht geladen werden. '
            'Bitte versuche es gleich noch einmal.';
      });
    }
  }

  Future<void> _logout() async {
    await StudentAuthService().logout();
    if (mounted) context.go('/');
  }

  Future<void> _openPractice(PathItem item) async {
    final token = _token;
    final store = _store;
    if (token == null || store == null) return;
    final SkillSpec spec;
    try {
      spec = store.byId(item.skillId);
    } on ArgumentError {
      if (!mounted) return;
      setState(() {
        _error =
            'Für diese Übung gibt es noch keine Aufgaben. '
            'Bitte frage deine Lehrkraft.';
      });
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          token: token,
          spec: spec,
          level: item.nextLevel,
          skillStore: store,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _name != null && _name!.isNotEmpty ? 'Hallo, $_name!' : 'Mein Lernpfad',
        ),
        actions: [
          if (_token != null)
            IconButton(
              key: const ValueKey('logout'),
              tooltip: 'Abmelden',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) return _buildError(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_token == null) return _buildNoToken(context);
    final path = _path;
    if (path == null || !path.hasActivePath) return _buildNoPath(context);
    return _buildPath(context, path);
  }

  Widget _buildNoToken(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_open,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bitte melde dich an.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text(
                  'Zur Anmeldung',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _load,
                child: const Text(
                  'Nochmal versuchen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPath(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Deine Lehrkraft bereitet deinen Lernpfad gerade vor. '
              'Schau bald wieder vorbei.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _load,
                child: const Text(
                  'Aktualisieren',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPath(BuildContext context, LearningPath path) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverview(context, path),
        const SizedBox(height: 8),
        for (final item in path.items) _buildItemTile(context, item),
      ],
    );
  }

  Widget _buildOverview(BuildContext context, LearningPath path) {
    final scheme = Theme.of(context).colorScheme;
    final open = path.openItems.length;
    final mastered =
        path.items.where((i) => i.state == PathItemState.mastered).length;
    return Container(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.rocket_launch, size: 32, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open == 1
                      ? '1 Übung für dich bereit'
                      : '$open Übungen für dich bereit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (mastered > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Du hast schon $mastered Bereiche geschafft',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, PathItem item) {
    final scheme = Theme.of(context).colorScheme;
    final tappable = item.state == PathItemState.available ||
        item.state == PathItemState.inProgress;
    final (IconData icon, Color color) = switch (item.state) {
      PathItemState.locked => (Icons.lock, scheme.outline),
      PathItemState.available => (Icons.play_circle, scheme.primary),
      PathItemState.inProgress => (Icons.refresh, scheme.primary),
      PathItemState.mastered => (Icons.check_circle, Colors.green.shade700),
      PathItemState.skipped => (Icons.remove_circle_outline, scheme.outline),
    };
    final label = _stateLabel(item.state);
    final dimmed =
        item.state == PathItemState.locked || item.state == PathItemState.skipped;

    return Semantics(
      button: tappable,
      label: '${item.titleDe}. ${item.descriptionDe}. $label',
      child: Container(
        key: ValueKey('path-item-${item.skillId}'),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tappable ? () => _openPractice(item) : null,
            child: Opacity(
              opacity: dimmed ? 0.55 : 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titleDe,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.descriptionDe.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.descriptionDe,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var level = 1; level <= 3; level++)
                                _levelPip(item, level),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 36, color: color),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelPip(PathItem item, int level) {
    final mastered = item.progressForLevel(level)?.isMastered ?? false;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        label: mastered ? 'Stufe $level geschafft' : 'Stufe $level',
        child: Container(
          key: ValueKey('pip-${item.skillId}-$level'),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mastered ? Colors.green.shade700 : Colors.grey.shade400,
            border: Border.all(color: Colors.grey.shade600, width: 1),
          ),
          // A mastered level is signalled by icon + colour, never colour
          // alone (ADHD/a11y guideline).
          child: mastered
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

String _stateLabel(PathItemState state) => switch (state) {
      PathItemState.available => 'Verfügbar',
      PathItemState.inProgress => 'Weiterüben',
      PathItemState.mastered => 'Geschafft',
      PathItemState.locked => 'Noch gesperrt',
      PathItemState.skipped => 'Übersprungen',
    };
