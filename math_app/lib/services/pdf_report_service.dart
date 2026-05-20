import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/diagnostic_question.dart';
import '../models/diagnostic_session.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';
import 'diagnostic_service.dart';
import 'skill_catalog.dart';

class PdfReportService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  Map<int, DiagnosticQuestion> _questionsById = {};

  Future<Uint8List> generatePdf(
    Foerderplan plan,
    DiagnosticSession session,
  ) async {
    await SkillCatalog.instance.load();
    await _loadQuestions();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          _buildHeader(plan),
          pw.SizedBox(height: 16),
          _buildBriefPlan(plan),
          pw.SizedBox(height: 14),
          if (plan.slowResponseFlag) ...[
            _buildCountingBanner(),
            pw.SizedBox(height: 14),
          ],
          if (plan.categoryStats.isNotEmpty) ...[
            _buildCategoryOverview(plan),
            pw.SizedBox(height: 14),
          ],
          _buildExtendedPlan(plan),
          pw.SizedBox(height: 14),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildDetailTableHeader(),
          pw.SizedBox(height: 6),
          _buildDetailTable(session),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
    return pdf.save();
  }

  // ──────────────────────────────────────────────────────────── header

  pw.Widget _buildHeader(Foerderplan plan) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Förderplan',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Math App',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Kind: ${plan.studentName}',
                style: const pw.TextStyle(fontSize: 13)),
            pw.Text('Datum: ${_dateFormat.format(plan.sessionDate)}',
                style: const pw.TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────── brief plan

  pw.Widget _buildBriefPlan(Foerderplan plan) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Kurzer Förderplan',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        if (plan.briefSkills.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              'Keine Förderschwerpunkte erkannt — herzlichen Glückwunsch!',
              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          )
        else
          ...plan.briefSkills.map(_buildSkillRow),
      ],
    );
  }

  pw.Widget _buildSkillRow(SkillRecommendation skill) {
    final color = _pdfColor(skill.categoryColor);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  skill.skillNameDe,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              _buildCategoryBadge(skill.category, color),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            skill.descriptionDe,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryBadge(String category, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        category,
        style: pw.TextStyle(fontSize: 9, color: color),
      ),
    );
  }

  // ─────────────────────────────────────────────── counting banner

  pw.Widget _buildCountingBanner() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber700),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Dieses Kind benötigt häufig viel Zeit zum Rechnen — vermutlich zählt es noch. '
        'Empfehlung: Schwerpunkt auf Grundstrategien zur Ablösung vom zählenden Rechnen.',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
  }

  // ────────────────────────────────────────── category overview

  pw.Widget _buildCategoryOverview(Foerderplan plan) {
    final rows = plan.categoryStats.entries.map((e) {
      final stats = e.value;
      return [e.key, '${stats.failed} / ${stats.total} falsch'];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Kategorie-Übersicht',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Kategorie', 'Ergebnis'],
          data: rows,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellHeight: 20,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────── extended plan

  pw.Widget _buildExtendedPlan(Foerderplan plan) {
    if (plan.recommendedSkills.isEmpty) return pw.SizedBox();

    final byCategory = <String, List<SkillRecommendation>>{};
    for (final s in plan.recommendedSkills) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Vollständiger Förderplan',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...byCategory.entries.expand((e) {
          final color = _pdfColor(e.value.first.categoryColor);
          return [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 4, horizontal: 8),
              margin: const pw.EdgeInsets.only(bottom: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border:
                    pw.Border(bottom: pw.BorderSide(color: color, width: 2)),
              ),
              child: pw.Text(
                e.key,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color),
              ),
            ),
            ...e.value.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(s.skillNameDe,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(s.descriptionDe,
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ];
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────── detail table

  pw.Widget _buildDetailTableHeader() {
    return pw.Text(
      'Detail-Tabelle',
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _buildDetailTable(DiagnosticSession session) {
    final data = session.results.map((r) {
      final qId = int.tryParse(r.questionId) ?? 0;
      final q = _questionsById[qId];
      final text = (q?.german.isNotEmpty ?? false)
          ? q!.german
          : (q?.questionText ?? '—');
      final truncated = text.length > 45
          ? '${text.substring(0, 42)}…'
          : text;

      late final String status;
      if (r.status == 'timeout') {
        status = 'Timeout';
      } else if (r.wasCorrect) {
        status = 'Richtig';
      } else {
        status = 'Falsch';
      }

      return [
        r.questionId,
        truncated,
        q?.correctAnswer ?? '—',
        r.userAnswer ?? '—',
        '${r.responseTimeSeconds.toStringAsFixed(1)} s',
        status,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Q#', 'Frage', 'Richtig', 'Antwort', 'Zeit', 'Status'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellHeight: 22,
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FixedColumnWidth(36),
        5: const pw.FixedColumnWidth(42),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
      },
    );
  }

  // ──────────────────────────────────────────────────────── footer

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Erstellt von Math App',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  // ──────────────────────────────────────────────────── helpers

  Future<void> _loadQuestions() async {
    if (_questionsById.isNotEmpty) return;
    try {
      final qs = await DiagnosticService().loadQuestions();
      _questionsById = {for (final q in qs) q.listNumber: q};
    } catch (e) {
      // non-fatal — detail table will show '—' for unknown questions
    }
  }

  PdfColor _pdfColor(String name) {
    switch (name.toLowerCase()) {
      case 'green':
        return PdfColors.green700;
      case 'yellow':
        return PdfColors.amber700;
      case 'blue':
        return PdfColors.blue700;
      case 'purple':
        return PdfColors.purple700;
      case 'gray':
      case 'grey':
        return PdfColors.grey700;
      case 'pink':
        return PdfColors.pink600;
      case 'orange':
        return PdfColors.orange700;
      case 'teal':
        return PdfColors.teal700;
      case 'brown':
        return const PdfColor.fromInt(0xFF6D4C41);
      default:
        return PdfColors.blueGrey700;
    }
  }
}
