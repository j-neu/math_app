import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/diagnostic_question.dart';
import '../models/foerderplan.dart';
import 'diagnostic_service.dart';
import 'kurz_foerderplan_service.dart';
import 'skill_catalog.dart';

/// Generates a Kurzförderplan as a .docx (OOXML) file.
///
/// Every cell in a Word document is editable by default — teachers open it in
/// Word, LibreOffice, or Google Docs and type directly into any field.
/// Auto-filled columns (Ist / Soll / Lernweg) are pre-populated from the
/// diagnostic data; blank columns (Absprachen / Reflexion) show light-grey
/// writing lines where the teacher types.
class DocxKurzFoerderplanService {
  // Column widths in twips (1 inch = 1440 twips).
  // A4 landscape content width ≈ 15400 twips (28pt margins ≈ 1134 twips each).
  static const _wLabel = 1400;
  static const _wIst = 2800;
  static const _wSoll = 2500;
  static const _wLernweg = 2800;
  static const _wAbsprachen = 2950;
  static const _wReflexion = 2950;

  Future<Uint8List> generateDocx(Foerderplan plan) async {
    await SkillCatalog.instance.load();

    Map<int, DiagnosticQuestion> questionsById = {};
    try {
      final qs = await DiagnosticService().loadQuestions();
      questionsById = {for (final q in qs) q.listNumber: q};
    } catch (_) {}

    final data = KurzFoerderplanService().generate(plan, questionsById);

    final archive = Archive();
    _add(archive, '[Content_Types].xml', _contentTypes());
    _add(archive, '_rels/.rels', _topRels());
    _add(archive, 'word/_rels/document.xml.rels', _docRels());
    _add(archive, 'word/styles.xml', _styles());
    _add(archive, 'word/document.xml', _document(data));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  void _add(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  // ─────────────────────────────────────── package boilerplate

  String _contentTypes() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '</Types>';

  String _topRels() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  String _docRels() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  String _styles() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:rPr><w:b/><w:sz w:val="28"/></w:rPr>
  </w:style>
  <w:style w:type="table" w:styleId="TableGrid">
    <w:name w:val="Table Grid"/>
    <w:tblPr>
      <w:tblBorders>
        <w:top    w:val="single" w:sz="4" w:space="0" w:color="808080"/>
        <w:left   w:val="single" w:sz="4" w:space="0" w:color="808080"/>
        <w:bottom w:val="single" w:sz="4" w:space="0" w:color="808080"/>
        <w:right  w:val="single" w:sz="4" w:space="0" w:color="808080"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="808080"/>
        <w:insideV w:val="single" w:sz="4" w:space="0" w:color="808080"/>
      </w:tblBorders>
    </w:tblPr>
  </w:style>
</w:styles>''';

  // ─────────────────────────────────────── main document

  String _document(KurzFoerderplanData data) {
    final buf = StringBuffer();
    buf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buf.write('<w:body>');

    // Title
    buf.write(_para('Foerderplan', bold: true, sz: 28));
    buf.write(_spacer());

    // Name field
    buf.write(_labelLine('Name der Schulerin / des Schulers:'));
    buf.write(_spacer());

    // Date range
    buf.write(_labelLine('Fur die Zeit von: ________________  bis: ________________'));
    buf.write(_spacer());

    // Table
    if (data.rows.isEmpty) {
      buf.write(_para(
        'Keine Foerderschwerpunkte erkannt - herzlichen Glueckwunsch!',
        italic: true,
      ));
    } else {
      buf.write(_table(data.rows));
    }

    // Page break → page 2
    buf.write(_pageBreak());

    // Page 2 content
    buf.write(_para('Weitere Vereinbarungen', bold: true, sz: 24));
    buf.write(_spacer());
    buf.write(_writingLines(10));
    buf.write(_spacer());
    buf.write(_para('Gesprachsdokumentation', bold: true, sz: 22));
    buf.write(_spacer());
    buf.write(_labelLine('Gesprach wurde durchgefuhrt am: __________  mit: ___________________________'));
    buf.write(_spacer());
    buf.write(_para('Unterschrift der Anwesenden', bold: true, sz: 22));
    buf.write(_spacer());
    buf.write(_signatureRow());
    buf.write(_spacer());
    buf.write(_para('Information der Erziehungsberechtigten', bold: true, sz: 22));
    buf.write(_para(
      'Wenn nicht anwesend, Information an die Erziehungsberechtigten.',
      color: '666666',
    ));
    buf.write(_spacer());
    buf.write(_labelLine('Datum: __________'));
    buf.write(_spacer());
    buf.write(_signatureRow(label: 'Unterschrift Erziehungsberechtigte/r'));

    // Section properties → landscape A4
    buf.write(
      '<w:sectPr>'
      '<w:pgSz w:w="16840" w:h="11906" w:orient="landscape"/>'
      '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="709" w:footer="709"/>'
      '</w:sectPr>',
    );

    buf.write('</w:body></w:document>');
    return buf.toString();
  }

  // ─────────────────────────────────────── table

  String _table(List<KurzFoerderplanRow> rows) {
    final buf = StringBuffer();
    buf.write('<w:tbl>');
    buf.write(
      '<w:tblPr>'
      '<w:tblStyle w:val="TableGrid"/>'
      '<w:tblW w:w="0" w:type="auto"/>'
      '<w:tblLayout w:type="fixed"/>'
      '<w:tblCellMar>'
      '<w:top w:w="80" w:type="dxa"/>'
      '<w:left w:w="80" w:type="dxa"/>'
      '<w:bottom w:w="80" w:type="dxa"/>'
      '<w:right w:w="80" w:type="dxa"/>'
      '</w:tblCellMar>'
      '</w:tblPr>',
    );
    buf.write(
      '<w:tblGrid>'
      '<w:gridCol w:w="$_wLabel"/>'
      '<w:gridCol w:w="$_wIst"/>'
      '<w:gridCol w:w="$_wSoll"/>'
      '<w:gridCol w:w="$_wLernweg"/>'
      '<w:gridCol w:w="$_wAbsprachen"/>'
      '<w:gridCol w:w="$_wReflexion"/>'
      '</w:tblGrid>',
    );

    // Header row
    buf.write(_headerRow());

    // Data rows
    for (final row in rows) {
      buf.write(_dataRow(row));
    }

    buf.write('</w:tbl>');
    return buf.toString();
  }

  String _headerRow() {
    final headers = [
      ('', _wLabel),
      ('Beobachtung / Bedarf\n(= Stellungnahme)', _wIst),
      ('Ziele', _wSoll),
      ('Paed. Angebote /\nMassnahmen /\nLernarrangements', _wLernweg),
      ('Absprachen\n(Wer? Wie?\nMit wem? Bis wann?)', _wAbsprachen),
      ('Reflexion /\nEvaluation /\nModifikation', _wReflexion),
    ];
    final buf = StringBuffer('<w:tr>');
    for (final (text, width) in headers) {
      buf.write(_tc(
        width: width,
        content: _multilineRuns(text, bold: true, sz: 16),
        shading: 'E0E0E0',
        minHeight: 600,
      ));
    }
    buf.write('</w:tr>');
    return buf.toString();
  }

  String _dataRow(KurzFoerderplanRow row) {
    final buf = StringBuffer('<w:tr>');

    // Category label cell
    buf.write(_tc(
      width: _wLabel,
      content: _multilineRuns(row.category, bold: true, sz: 15),
      minHeight: 2000,
    ));

    // Auto-filled cells
    buf.write(_tc(width: _wIst, content: _multilineRuns(row.ist)));
    buf.write(_tc(width: _wSoll, content: _multilineRuns(row.soll)));
    buf.write(_tc(width: _wLernweg, content: _multilineRuns(row.lernweg)));

    // Fillable cells — grey background with writing lines
    buf.write(_tc(
      width: _wAbsprachen,
      content: _writingLines(8),
      shading: 'F8F8F8',
    ));
    buf.write(_tc(
      width: _wReflexion,
      content: _writingLines(8),
      shading: 'F8F8F8',
    ));

    buf.write('</w:tr>');
    return buf.toString();
  }

  String _tc({
    required int width,
    required String content,
    String? shading,
    int? minHeight,
  }) {
    final shadingXml = shading != null
        ? '<w:shd w:val="clear" w:color="auto" w:fill="$shading"/>'
        : '';
    final heightXml = minHeight != null
        ? '<w:trHeight w:val="$minHeight" w:hRule="atLeast"/>'
        : '';
    return '<w:tc>'
        '<w:tcPr>'
        '<w:tcW w:w="$width" w:type="dxa"/>'
        '$shadingXml'
        '</w:tcPr>'
        '$heightXml'
        '$content'
        '</w:tc>';
  }

  // ─────────────────────────────────────── text helpers

  String _multilineRuns(String text, {bool bold = false, int sz = 18}) {
    final lines = text.split('\n');
    return lines.map((line) {
      final escaped = _esc(line);
      final boldTag = bold ? '<w:b/>' : '';
      return '<w:p>'
          '<w:pPr><w:spacing w:after="0"/></w:pPr>'
          '<w:r>'
          '<w:rPr>$boldTag<w:sz w:val="$sz"/><w:szCs w:val="$sz"/></w:rPr>'
          '<w:t xml:space="preserve">$escaped</w:t>'
          '</w:r>'
          '</w:p>';
    }).join();
  }

  String _para(
    String text, {
    bool bold = false,
    bool italic = false,
    int sz = 18,
    String? color,
  }) {
    final b = bold ? '<w:b/>' : '';
    final i = italic ? '<w:i/>' : '';
    final c = color != null ? '<w:color w:val="$color"/>' : '';
    return '<w:p>'
        '<w:r>'
        '<w:rPr>$b$i$c<w:sz w:val="$sz"/><w:szCs w:val="$sz"/></w:rPr>'
        '<w:t xml:space="preserve">${_esc(text)}</w:t>'
        '</w:r>'
        '</w:p>';
  }

  String _labelLine(String text) {
    return '<w:p>'
        '<w:pPr><w:spacing w:after="0"/></w:pPr>'
        '<w:r>'
        '<w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>'
        '<w:t xml:space="preserve">${_esc(text)}</w:t>'
        '</w:r>'
        '</w:p>';
  }

  /// Empty paragraphs with a bottom border — acts as ruled writing lines.
  String _writingLines(int count) {
    const line = '<w:p>'
        '<w:pPr>'
        '<w:pBdr><w:bottom w:val="single" w:sz="4" w:space="1" w:color="BBBBBB"/></w:pBdr>'
        '<w:spacing w:before="280" w:after="0"/>'
        '</w:pPr>'
        '<w:r><w:t xml:space="preserve"> </w:t></w:r>'
        '</w:p>';
    return line * count;
  }

  String _signatureRow({String label = 'Unterschrift'}) {
    String lineCell(int width) => '<w:tc>'
        '<w:tcPr><w:tcW w:w="$width" w:type="dxa"/><w:tcBorders>'
        '<w:bottom w:val="single" w:sz="6" w:space="0" w:color="333333"/>'
        '</w:tcBorders></w:tcPr>'
        '<w:p><w:pPr><w:spacing w:before="600" w:after="0"/></w:pPr>'
        '<w:r><w:t> </w:t></w:r></w:p>'
        '</w:tc>';
    final gapCell = '<w:tc>'
        '<w:tcPr><w:tcW w:w="800" w:type="dxa"/><w:tcBorders></w:tcBorders></w:tcPr>'
        '<w:p><w:r><w:t> </w:t></w:r></w:p>'
        '</w:tc>';
    return '<w:tbl>'
        '<w:tblPr><w:tblW w:w="0" w:type="auto"/>'
        '<w:tblBorders><w:insideH w:val="none"/><w:insideV w:val="none"/>'
        '<w:top w:val="none"/><w:left w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tblBorders>'
        '</w:tblPr>'
        '<w:tblGrid><w:gridCol w:w="7000"/><w:gridCol w:w="800"/><w:gridCol w:w="7000"/></w:tblGrid>'
        '<w:tr>${lineCell(7000)}$gapCell${lineCell(7000)}</w:tr>'
        '<w:tr>'
        '${_labelTc(7000, label)}$gapCell${_labelTc(7000, label)}'
        '</w:tr>'
        '</w:tbl>';
  }

  String _labelTc(int width, String text) {
    return '<w:tc>'
        '<w:tcPr><w:tcW w:w="$width" w:type="dxa"/><w:tcBorders>'
        '<w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>'
        '</w:tcBorders></w:tcPr>'
        '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
        '<w:r><w:rPr><w:sz w:val="15"/><w:color w:val="666666"/></w:rPr>'
        '<w:t>${_esc(text)}</w:t></w:r></w:p>'
        '</w:tc>';
  }

  String _spacer() => '<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>';

  String _pageBreak() =>
      '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
