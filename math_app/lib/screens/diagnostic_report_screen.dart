import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/diagnostic_question.dart';
import '../models/diagnostic_result.dart';
import '../models/diagnostic_session.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';
import '../models/user_profile.dart';
import '../services/diagnostic_service.dart';
import '../services/docx_kurz_foerderplan_service.dart';
import '../services/pdf_kurz_foerderplan_service.dart';
import '../services/pdf_report_service.dart';

/// Native Förderplan screen shown immediately after a diagnostic completes.
class DiagnosticReportScreen extends StatefulWidget {
  final UserProfile userProfile;
  final DiagnosticSession session;
  final Foerderplan foerderplan;

  const DiagnosticReportScreen({
    super.key,
    required this.userProfile,
    required this.session,
    required this.foerderplan,
  });

  @override
  State<DiagnosticReportScreen> createState() => _DiagnosticReportScreenState();
}

class _DiagnosticReportScreenState extends State<DiagnosticReportScreen> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  Map<int, DiagnosticQuestion> _questionsById = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await DiagnosticService().loadQuestions();
    if (!mounted) return;
    setState(() {
      _questionsById = {for (final q in qs) q.listNumber: q};
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.foerderplan;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Förderplan – ${plan.studentName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(plan),
            const SizedBox(height: 16),
            if (plan.slowResponseFlag) ...[
              _buildCountingBanner(),
              const SizedBox(height: 16),
            ],
            _buildBriefPlan(plan),
            const SizedBox(height: 16),
            _buildCategoryOverview(plan),
            const SizedBox(height: 16),
            _buildExtendedPlan(plan),
            const SizedBox(height: 8),
            _buildDetailsTable(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Foerderplan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kind', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  plan.studentName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Datum', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  _dateFormat.format(plan.sessionDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.timer_outlined, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Dieses Kind benötigt häufig viel Zeit zum Rechnen — vermutlich zählt es noch. '
              'Empfehlung: Schwerpunkt auf Grundstrategien zur Ablösung vom zählenden Rechnen.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefPlan(Foerderplan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kurzer Förderplan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Die nächsten drei Übungs-Schwerpunkte.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (plan.briefSkills.isEmpty)
              _buildEmptyBrief()
            else
              ...plan.briefSkills.map(_buildBriefSkillTile),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBrief() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Text(
        'Keine Förderschwerpunkte erkannt — herzlichen Glückwunsch!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildBriefSkillTile(SkillRecommendation skill) {
    final color = _materialColor(skill.categoryColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.skillNameDe,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.descriptionDe,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                _categoryBadge(skill.category, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCategoryOverview(Foerderplan plan) {
    if (plan.categoryStats.isEmpty) return const SizedBox.shrink();
    final entries = plan.categoryStats.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategorie-Übersicht',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) {
              final stats = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 14))),
                    Text(
                      '${stats.failed} / ${stats.total} falsch',
                      style: TextStyle(
                        fontSize: 14,
                        color: stats.failed == 0 ? Colors.green.shade700 : Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExtendedPlan(Foerderplan plan) {
    if (plan.recommendedSkills.isEmpty) return const SizedBox.shrink();
    final byCategory = <String, List<SkillRecommendation>>{};
    for (final s in plan.recommendedSkills) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Vollständiger Förderplan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${plan.recommendedSkills.length} empfohlene Übungen'),
        children: byCategory.entries.map((e) {
          final color = _materialColor(e.value.first.categoryColor);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _categoryBadge(e.key, color),
                const SizedBox(height: 8),
                ...e.value.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.skillNameDe,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            s.descriptionDe,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsTable() {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Detail-Tabelle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${widget.session.results.length} Fragen'),
        children: [
          if (_questionsById.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                dataTextStyle: const TextStyle(fontSize: 12),
                columns: const [
                  DataColumn(label: Text('Q#')),
                  DataColumn(label: Text('Frage')),
                  DataColumn(label: Text('Richtig')),
                  DataColumn(label: Text('Antwort')),
                  DataColumn(label: Text('Zeit')),
                  DataColumn(label: Text('Status')),
                ],
                rows: widget.session.results.map(_buildResultRow).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildResultRow(DiagnosticResult r) {
    final qId = int.tryParse(r.questionId);
    final q = qId == null ? null : _questionsById[qId];
    final text = (q?.german.isNotEmpty ?? false) ? q!.german : (q?.questionText ?? '—');
    return DataRow(cells: [
      DataCell(Text(r.questionId)),
      DataCell(SizedBox(width: 220, child: Text(text, softWrap: true))),
      DataCell(Text(q?.correctAnswer ?? '—')),
      DataCell(Text(r.userAnswer ?? '—')),
      DataCell(Text('${r.responseTimeSeconds.toStringAsFixed(1)} s')),
      DataCell(_statusChip(r)),
    ]);
  }

  Widget _statusChip(DiagnosticResult r) {
    late final String label;
    late final Color color;
    if (r.status == 'timeout') {
      label = 'Timeout';
      color = Colors.orange;
    } else if (r.wasCorrect) {
      label = 'Richtig';
      color = Colors.green;
    } else {
      label = 'Falsch';
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Vollständiger Förderplan (PDF)'),
            onPressed: _exportPdf,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Kurzförderplan (PDF, Schulformat)'),
            onPressed: _exportKurzFoerderplan,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_document),
            label: const Text('Kurzförderplan (Word .docx, ausfüllbar)'),
            onPressed: _exportKurzFoerderplanDocx,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Weiter zum Üben'),
            onPressed: () => _continueToLearningPath(context),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf() async {
    await Printing.layoutPdf(
      onLayout: (_) =>
          PdfReportService().generatePdf(widget.foerderplan, widget.session),
      name: 'Foerderplan_${widget.userProfile.name}_'
          '${_dateFormat.format(widget.session.date)}.pdf',
    );
  }

  Future<void> _exportKurzFoerderplan() async {
    await Printing.layoutPdf(
      onLayout: (_) =>
          PdfKurzFoerderplanService().generatePdf(widget.foerderplan),
      name: 'Kurzfoerderplan_${widget.userProfile.name}_'
          '${_dateFormat.format(widget.session.date)}.pdf',
    );
  }

  Future<void> _exportKurzFoerderplanDocx() async {
    try {
      final bytes =
          await DocxKurzFoerderplanService().generateDocx(widget.foerderplan);
      final name =
          'Kurzfoerderplan_${widget.userProfile.name}_${_dateFormat.format(widget.session.date)}.docx';
      Directory dir;
      try {
        dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gespeichert: ${file.path}'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('Kurzförderplan export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Der Bericht konnte nicht gespeichert werden.')),
      );
    }
  }

  // The legacy practice engine (LearningPathScreen, retired skills) must not
  // be the child's next step after a diagnostic — practice now happens on the
  // server-driven learning path via the class code (integration-phase
  // decision, P2 plan Task 10). The child is told the teacher prepares the
  // path instead of being routed to retired exercises.
  void _continueToLearningPath(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dein Lernpfad'),
        content: const Text(
          'Deine Lehrkraft bereitet deinen persönlichen Lernpfad vor. '
          'Zum Üben bekommst du von ihr einen Code.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Color _materialColor(String name) {
    switch (name.toLowerCase()) {
      case 'green':
        return Colors.green.shade600;
      case 'yellow':
        return Colors.amber.shade700;
      case 'blue':
        return Colors.blue.shade600;
      case 'purple':
        return Colors.purple.shade600;
      case 'gray':
      case 'grey':
        return Colors.grey.shade700;
      case 'pink':
        return Colors.pink.shade400;
      case 'brown':
        return Colors.brown.shade600;
      case 'orange':
        return Colors.orange.shade700;
      case 'teal':
        return Colors.teal.shade600;
      case 'amber':
        return Colors.amber.shade700;
      case 'indigo':
        return Colors.indigo.shade600;
      case 'emerald':
        return Colors.green.shade600;
      case 'violet':
        return Colors.purple.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }
}
