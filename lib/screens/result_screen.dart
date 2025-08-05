import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /* ────────── permission helper ────────── */
  Future<bool> _requestStoragePermission() async {
    // iOS / desktop never need it
    if (!Platform.isAndroid) return true;

    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

    // Android 10 (API 29) and higher use scoped storage; no WRITE_EXTERNAL_STORAGE runtime-perm
    if (sdk >= 29) return true;

    // Android 9 and below → ask for legacy storage permission
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    return result.isGranted;
  }


  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();

    // Split resume into paragraphs for better formatting
    final paragraphs = updatedResume.split('\n\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          for (String paragraph in paragraphs) {
            if (paragraph.trim().isNotEmpty) {
              // Check if it's a header (usually short and in caps or title case)
              if (paragraph.length < 50 &&
                  (paragraph.toUpperCase() == paragraph ||
                      paragraph.split(' ').every((word) => word.isNotEmpty && word[0].toUpperCase() == word[0]))) {
                // Header style
                content.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
                    child: pw.Text(
                      paragraph.trim(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                );
              } else {
                // Regular paragraph
                content.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      paragraph.trim(),
                      style: const pw.TextStyle(
                        fontSize: 11,
                        lineSpacing: 1.4,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                );
              }
            }
          }

          return content;
        },
      ),
    );

    return pdf;
  }

  Future<void> _downloadResume(BuildContext context) async {
    try {
      // Check permissions first
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission is required to download files")),
          );
        }
        return;
      }

      // Show loading dialog
      if (context.mounted) {
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
      }

      // Generate PDF
      final pdf = await _generatePDF();

      // Get the correct directory based on platform
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      // Create file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'customized_resume_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resume saved to ${Platform.isAndroid ? 'Downloads' : 'Documents'}"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await OpenFile.open(file.path);
                } catch (e) {
                  print("Error opening file: $e");
                }
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Auto-open file
      try {
        await OpenFile.open(file.path);
      } catch (e) {
        print("Error auto-opening file: $e");
      }

    } catch (e) {
      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print("Download Error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download resume: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareResume(BuildContext context) async {
    try {
      // Show loading dialog
      if (context.mounted) {
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
      }

      // Generate PDF
      final pdf = await _generatePDF();

      // Use temporary directory for sharing
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'customized_resume_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is my customized resume',
        subject: 'Customized Resume',
      );

    } catch (e) {
      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print("Share Error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to share resume: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: updatedResume));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Resume text copied to clipboard!"),
        backgroundColor: Colors.green,
      ),
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
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copy to Clipboard',
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
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   decoration: BoxDecoration(
            //     color: Colors.deepPurple.shade50,
            //     borderRadius: BorderRadius.circular(20),
            //     border: Border.all(color: Colors.deepPurple.shade200),
            //   ),
            //   child: Text(
            //     "Match Score: ${matchScore.toInt()}%",
            //     style: const TextStyle(
            //       fontSize: 16,
            //       color: Colors.deepPurple,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),

            //const SizedBox(height: 30),

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
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadResume(context),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Download PDF", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResume(context),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text("Share", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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