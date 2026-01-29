import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/user_profile.dart';
import '../models/diagnostic_session.dart';
import '../services/pdf_report_service.dart';

class DiagnosticReportScreen extends StatelessWidget {
  final UserProfile userProfile;
  final DiagnosticSession session;

  const DiagnosticReportScreen({
    super.key,
    required this.userProfile,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Report'),
      ),
      body: PdfPreview(
        build: (format) => PdfReportService().generateReport(userProfile, session),
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'MathApp_Evaluation_${userProfile.name}_${session.date.toString().split(' ')[0]}.pdf',
      ),
    );
  }
}
