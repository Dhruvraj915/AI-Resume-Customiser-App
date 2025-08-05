import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatelessWidget {
  final String updatedResume;
  final String originalResume;
  final double matchScore;
  final List<String> suggestions;

  const ResultScreen({
    super.key,
    required this.updatedResume,
    required this.originalResume,
    required this.matchScore,
    required this.suggestions,
  });

  Future<void> _downloadResume(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Customized Resume',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  )),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              updatedResume,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/custom_resume_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close loading indicator
      Navigator.pop(context);

      // Show success Snackbar and open file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Resume downloaded successfully!"),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
      OpenFile.open(file.path);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint("PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download resume. Please try again.")),
      );
    }
  }

  Future<void> _shareResume(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing to share...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Customized Resume',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  )),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              updatedResume,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/custom_resume_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is my customized resume',
        subject: 'Customized Resume',
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint("Share Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to share resume. Please try again.")),
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: updatedResume));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resume text copied to clipboard!")),
    );
  }

  void _showComparison(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before vs After'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Original'),
                    Tab(text: 'Customized'),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Text(
                          originalResume,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Text(
                          updatedResume,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Resume Customizer"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => _showComparison(context),
            tooltip: 'Compare Original vs Customized',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Success Icon and Message
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "Resume Customized Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),

            // Match Score
            Text(
              "Match Score: ${matchScore.toInt()}%",
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // Preview Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.preview, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Customized Resume Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // IconButton(
                        //   icon: const Icon(Icons.copy),
                        //   onPressed: () => _copyToClipboard(context),
                        //   tooltip: 'Copy to Clipboard',
                        // ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          updatedResume,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadResume(context),
                    icon: const Icon(Icons.download),
                    label: const Text("Download PDF"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.deepPurple),
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareResume(context),
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.deepPurple),
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Customize Another Resume"),
            ),
          ],
        ),
      ),
    );
  }
}
