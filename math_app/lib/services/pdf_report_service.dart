import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../models/user_profile.dart';
import '../models/diagnostic_session.dart';
import '../models/diagnostic_question.dart';
import '../services/diagnostic_service.dart';

class PdfReportService {
  // Cache for skill metadata
  Map<String, Map<String, String>> _skillMetadata = {};
  // Cache for questions
  Map<int, DiagnosticQuestion> _questionMap = {};

  /// Generate a PDF report for a specific diagnostic session
  Future<Uint8List> generateReport(UserProfile user, DiagnosticSession session) async {
    // Ensure metadata is loaded
    if (_skillMetadata.isEmpty) {
      await _loadSkillMetadata();
    }
    
    // Ensure questions are loaded
    if (_questionMap.isEmpty) {
      await _loadQuestions();
    }

    final pdf = pw.Document();

    // Group skills by category
    final groupedSkills = _groupSkillsByCategory(session.generatedSkillTags);

    // Load font (using standard fonts for now, but could load custom fonts)
    // For German characters, we need a font that supports them.
    // PDF package has built-in Helvetica which supports basic Latin-1.

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(user, session),
            pw.SizedBox(height: 20),
            _buildSummary(session),
            pw.SizedBox(height: 20),
            pw.Text(
              'Individual Learning Plan',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Based on the diagnostic results, ${user.name} should practice the following skills:',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            ..._buildSkillCategories(groupedSkills),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Detailed Evaluation',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildDetailedResultsTable(session),
            pw.Divider(),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildDetailedResultsTable(DiagnosticSession session) {
    // Table headers
    final headers = ['Q#', 'Question', 'Answer', 'Correct', 'Result', 'Time'];

    final data = session.results.map((result) {
      final qId = int.tryParse(result.questionId) ?? 0;
      final question = _questionMap[qId];
      
      // Use the full English text if available, otherwise fallback to questionText
      final fullText = (question?.english != null && question!.english.isNotEmpty) 
          ? question.english 
          : (question?.questionText ?? 'Unknown Question');
      
      final correctAnswer = question?.correctAnswer ?? '';
      
      // Truncate long questions
      final displayQuestion = fullText.length > 40 
          ? '${fullText.substring(0, 37)}...' 
          : fullText;

      return [
        result.questionId,
        displayQuestion,
        result.userAnswer ?? '-',
        correctAnswer,
        result.wasCorrect ? 'Correct' : 'Incorrect',
        '${result.responseTimeSeconds.toStringAsFixed(1)}s',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellHeight: 25,
      columnWidths: {
        0: const pw.FixedColumnWidth(30),  // Q#
        1: const pw.FlexColumnWidth(3),    // Question
        2: const pw.FlexColumnWidth(1),    // Answer
        3: const pw.FlexColumnWidth(1),    // Correct
        4: const pw.FixedColumnWidth(50),  // Result
        5: const pw.FixedColumnWidth(40),  // Time
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildHeader(UserProfile user, DiagnosticSession session) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Diagnostic Evaluation',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Math App',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student: ${user.name}', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Age: ${user.age}', style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: ${dateFormat.format(session.date)}', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('ID: ${user.id.substring(0, 8)}...', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummary(DiagnosticSession session) {
    final totalQuestions = session.results.length;
    final attempted = session.results.where((r) => r.status == 'attempted').length;
    final correct = session.results.where((r) => r.wasCorrect).length;
    final skillsToLearn = session.generatedSkillTags.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Questions', '$attempted / $totalQuestions'),
          _buildSummaryItem('Correct', '$correct'),
          _buildSummaryItem('Focus Areas', '$skillsToLearn'),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }

  List<pw.Widget> _buildSkillCategories(Map<String, List<String>> groupedSkills) {
    final widgets = <pw.Widget>[];

    if (groupedSkills.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'No specific practice areas identified! Great job!',
            style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
      return widgets;
    }

    // Sort categories (optional custom order could be applied here)
    final sortedCategories = groupedSkills.keys.toList()..sort();

    for (final category in sortedCategories) {
      final skillIds = groupedSkills[category]!;
      
      // Get category display name (capitalize)
      final categoryName = category[0].toUpperCase() + category.substring(1);

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue200, width: 2)),
                ),
                width: double.infinity,
                child: pw.Text(
                  categoryName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
              ),
              pw.SizedBox(height: 8),
              ...skillIds.map((id) => _buildSkillItem(id)),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildSkillItem(String skillId) {
    final meta = _skillMetadata[skillId];
    final name = meta?['name'] ?? skillId;
    final description = meta?['description'] ?? 'Practice required';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 5, right: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey800,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(description, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Generated by Math App Evaluation System',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }
  
  Future<void> _loadQuestions() async {
    try {
      final service = DiagnosticService();
      final questions = await service.loadQuestions();
      for (var q in questions) {
        _questionMap[q.listNumber] = q;
      }
    } catch (e) {
      print('Error loading questions for PDF report: $e');
    }
  }

  Future<void> _loadSkillMetadata() async {
    try {
      final rawData = await rootBundle.loadString('Research/skills_taxonomy.csv');
      final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData, eol: '\n');

      // Skip header (row 0)
      for (var i = 1; i < listData.length; i++) {
        final row = listData[i];
        if (row.length < 8) continue;

        final id = row[0].toString();
        final nameEn = row[5].toString(); // skill_name_en
        final descEn = row[7].toString(); // description_en
        
        // We could switch to German based on a locale parameter if needed
        // final nameDe = row[4].toString();
        // final descDe = row[6].toString();

        _skillMetadata[id] = {
          'name': nameEn,
          'description': descEn,
        };
      }
    } catch (e) {
      print('Error loading skill metadata: $e');
    }
  }

  Map<String, List<String>> _groupSkillsByCategory(List<String> skillIds) {
    final Map<String, List<String>> groups = {};

    for (final id in skillIds) {
      // Skill ID format: category_number (e.g., counting_1)
      final parts = id.split('_');
      String category = 'Other';
      
      if (parts.isNotEmpty) {
        // Special case for multi-word categories like 'place_value'
        if (id.startsWith('place_value')) {
          category = 'Place Value';
        } else if (id.startsWith('basic_strategy')) {
          category = 'Basic Strategies';
        } else if (id.startsWith('combined_strategy')) {
          category = 'Combined Strategies';
        } else if (id.startsWith('number_line')) {
          category = 'Number Line';
        } else if (id.startsWith('operation_sense')) {
          category = 'Operation Sense';
        } else {
          category = parts[0];
        }
      }

      if (!groups.containsKey(category)) {
        groups[category] = [];
      }
      groups[category]!.add(id);
    }

    return groups;
  }
}
