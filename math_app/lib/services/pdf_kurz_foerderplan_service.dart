import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/diagnostic_question.dart';
import '../models/foerderplan.dart';
import 'diagnostic_service.dart';
import 'kurz_foerderplan_service.dart';
import 'skill_catalog.dart';

/// Generates a two-page A4 Kurzförderplan PDF in the official Berlin school
/// template format (foerderplan-pdf_02a.pdf).
///
/// Columns 2–4 (Ist / Soll / Lernweg) are auto-filled from diagnostic data,
/// referencing the iMINT Kartei "Auf dem Weg zum denkenden Rechnen".
/// Columns 5–6 (Absprachen / Reflexion) and all of page 2 are left blank
/// with visible fill-in boxes for the teacher.
class PdfKurzFoerderplanService {
  Future<Uint8List> generatePdf(Foerderplan plan) async {
    await SkillCatalog.instance.load();

    Map<int, DiagnosticQuestion> questionsById = {};
    try {
      final qs = await DiagnosticService().loadQuestions();
      questionsById = {for (final q in qs) q.listNumber: q};
    } catch (_) {}

    final data = KurzFoerderplanService().generate(plan, questionsById);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        build: (_) => [
          _buildHeader(),
          pw.SizedBox(height: 14),
          _buildMainTable(data),
          pw.SizedBox(height: 8),
          _buildFooter(),
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        build: (_) => _buildPage2(),
      ),
    );

    return pdf.save();
  }

  // ──────────────────────────────────────────────────── page 1 header

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Förderplan',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text(
              'Name der Schülerin / des Schülers:',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(child: _inputBox(height: 18)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('Für die Zeit von:', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(width: 6),
            pw.SizedBox(width: 90, child: _inputBox(height: 18)),
            pw.SizedBox(width: 8),
            pw.Text('bis:', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(width: 6),
            pw.SizedBox(width: 90, child: _inputBox(height: 18)),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────── main table

  pw.Widget _buildMainTable(KurzFoerderplanData data) {
    if (data.rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Center(
          child: pw.Text(
            'Keine Förderschwerpunkte erkannt – herzlichen Glückwunsch!',
            style: pw.TextStyle(
                fontSize: 11, fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(50),   // category label
        1: const pw.FlexColumnWidth(2.2),   // Ist
        2: const pw.FlexColumnWidth(2.0),   // Soll
        3: const pw.FlexColumnWidth(2.2),   // Lernweg
        4: const pw.FlexColumnWidth(1.8),   // Absprachen (fillable)
        5: const pw.FlexColumnWidth(1.8),   // Reflexion (fillable)
      },
      children: [
        _tableHeader(),
        ...data.rows.map(_tableRow),
      ],
    );
  }

  pw.TableRow _tableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _headerCell(''),
        _headerCell('Beobachtung / Bedarf\n(= Stellungnahme)'),
        _headerCell('Ziele'),
        _headerCell('Päd. Angebote /\nMaßnahmen /\nLernarrangements'),
        _headerCell('Absprachen\n(Wer? Wie?\nMit wem? Bis wann?)'),
        _headerCell('Reflexion /\nEvaluation /\nModifikation'),
      ],
    );
  }

  pw.TableRow _tableRow(KurzFoerderplanRow row) {
    final color = _pdfColor(row.categoryColor);
    return pw.TableRow(
      children: [
        // category label column with colored left border
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(6, 6, 4, 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
          ),
          child: pw.Text(
            row.category,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        _contentCell(row.ist),
        _contentCell(row.soll),
        _contentCell(row.lernweg),
        _fillableCell(),
        _fillableCell(),
      ],
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _contentCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7.5)),
    );
  }

  pw.Widget _fillableCell() {
    return pw.Container(
      color: PdfColors.grey50,
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        'Hier eintragen …',
        style: pw.TextStyle(
          fontSize: 7,
          color: PdfColors.grey300,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────── page 1 footer

  pw.Widget _buildFooter() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Erstellt mit Math App',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
      ),
    );
  }

  // ──────────────────────────────────────────────────── page 2

  pw.Widget _buildPage2() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Weitere Vereinbarungen'),
        pw.SizedBox(height: 6),
        _largeInputBox(minHeight: 130),
        pw.SizedBox(height: 22),
        _sectionTitle('Gesprächsdokumentation'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text(
              'Gespräch wurde durchgeführt am:',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(width: 6),
            pw.SizedBox(width: 100, child: _inputBox(height: 18)),
            pw.SizedBox(width: 12),
            pw.Text('mit:', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(width: 6),
            pw.Expanded(child: _inputBox(height: 18)),
          ],
        ),
        pw.SizedBox(height: 26),
        _sectionTitle('Unterschrift der Anwesenden'),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            pw.Expanded(child: _signatureLine()),
            pw.SizedBox(width: 32),
            pw.Expanded(child: _signatureLine()),
          ],
        ),
        pw.SizedBox(height: 26),
        _sectionTitle('Information der Erziehungsberechtigten'),
        pw.SizedBox(height: 5),
        pw.Text(
          'Wenn nicht anwesend, Information an die Erziehungsberechtigten.',
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Text('Datum:', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(width: 6),
            pw.SizedBox(width: 100, child: _inputBox(height: 18)),
            pw.SizedBox(width: 32),
            pw.Expanded(child: _signatureLine()),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.SizedBox(width: 214), // align label under the signature line
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  'Unterschrift Erziehungsberechtigte/r',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey600),
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Erstellt mit Math App',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────── shared helpers

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _inputBox({double height = 24}) {
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
    );
  }

  pw.Widget _largeInputBox({double minHeight = 80}) {
    return pw.Container(
      width: double.infinity,
      constraints: pw.BoxConstraints(minHeight: minHeight),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        'Hier eintragen …',
        style: pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey300,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  pw.Widget _signatureLine() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey600, thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Text(
          'Unterschrift',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
        ),
      ],
    );
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
