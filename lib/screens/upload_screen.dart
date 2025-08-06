import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../services/gemini_resume_service.dart';
import '../services/hybrid_resume_service.dart'; // Use the hybrid service for AI+offline
import '../widgets/custom_button.dart';
import '../widgets/job_description_input_card.dart';
import '../widgets/resume_input_card.dart';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _pdfFileName;
  String? _pdfFilePath;
  String? _extractedResumeText;
  final TextEditingController _jobDescController = TextEditingController();
  bool _isProcessing = false; // Add this to prevent multiple clicks
  bool _forceOffline = false; // Toggle for offline mode

  Future<String?> _extractTextFromPDF(String filePath) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: File(filePath).readAsBytesSync());
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        extractedText += '\n';
      }
      document.dispose();
      return extractedText.trim();
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return null;
    }
  }

  void _selectPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Extracting text from PDF...'),
            ],
          ),
        ),
      );

      final extractedText = await _extractTextFromPDF(filePath);

      if (mounted) Navigator.pop(context); // Check if widget is still mounted

      if (extractedText != null && extractedText.isNotEmpty) {
        setState(() {
          _pdfFileName = result.files.single.name;
          _pdfFilePath = filePath;
          _extractedResumeText = extractedText;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PDF uploaded and text extracted successfully!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to extract text from PDF. Please try again.")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
      }
    }
  }

  void _updateResume() async {
    // Prevent multiple clicks
    if (_isProcessing) return;

    if (_extractedResumeText == null || _jobDescController.text.trim().isEmpty) {
      String message = "";
      if (_extractedResumeText == null) {
        message = "Please upload your resume PDF file first.";
      } else if (_jobDescController.text.trim().isEmpty) {
        message = "Please enter a job description.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Show loading dialog with more detailed status
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(_forceOffline ? 'Processing offline...' : 'Customizing your resume...'),
            const SizedBox(height: 8),
            // Text(
            //   _forceOffline
            //       ? 'Using local enhancement algorithms.'
            //       : 'Trying AI enhancement first, then offline backup.',
            //   style: const TextStyle(fontSize: 12, color: Colors.green),
            // ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      print("🚀 Starting resume customization...");
      print("🔧 Toggle state - Force offline: $_forceOffline");
      print("📄 Resume length: ${_extractedResumeText!.length} characters");
      print("💼 Job desc length: ${_jobDescController.text.trim().length} characters");

      // Use HybridResumeService: Gemini Pro if available, else offline
      final result = await HybridResumeService.customizeResume(
        resumeText: _extractedResumeText!,
        jobDescription: _jobDescController.text.trim(),
        forceOffline: _forceOffline, // Use the toggle value
      );

      print("🎉 Customization completed: ${result['source']}");
      print("✅ SUCCESS: Used ${result['source']} service for customization");

      if (mounted) Navigator.pop(context);

      // Show success message with source info
      if (mounted) {
        final source = result['source'] ?? 'unknown';
        final sourceEmoji = source == 'gemini' ? '🤖' : '🔧';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resume customized using ${source.toUpperCase()} service!"),
            backgroundColor: source == 'gemini' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              updatedResume: result['updatedResume'] ?? '',
              originalResume: _extractedResumeText!,
              matchScore: result['matchScore'] ?? 70.0,
              suggestions: List<String>.from(result['suggestions'] ?? result['improvements'] ?? []),
            ),
          ),
        );
      }
    } catch (e) {
      print("💥 Error in customization: $e");
      print("💥 Error type: ${e.runtimeType}");

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating resume: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _jobDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo1.png', // Path to your logo
              height: 35,        // Adjust height as needed
              width: 35,         // Adjust width as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 2), // Space between logo and text
            const Text("Curriq"),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Minimal AI/Offline toggle in top right
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Button
                GestureDetector(
                  onTap: () => setState(() => _forceOffline = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_forceOffline ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: !_forceOffline ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      "AI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_forceOffline ? Colors.deepPurple : Colors.white70,
                      ),
                    ),
                  ),
                ),
                // Offline Button
                GestureDetector(
                  onTap: () => setState(() => _forceOffline = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _forceOffline ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _forceOffline ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      "Offline",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _forceOffline ? Colors.deepPurple : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight - 32,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResumeInputCard(
                  title: "Upload Resume PDF",
                  subtitle: _pdfFileName ?? "Select PDF File",
                  icon: Icons.upload_file,
                  onTap: _selectPDF,
                ),
                if (_extractedResumeText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Resume loaded (${_extractedResumeText!.length} characters)",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                JobDescriptionInputCard(
                  title: "Job Description",
                  hint: "Paste or write your target job description here",
                  controller: _jobDescController,
                  isMultiline: true,
                ),
                const SizedBox(height: 20),
                const Spacer(),

                // Main Customize Resume Button
                CustomButton(
                  text: _isProcessing ? "Processing..." : "Customize Resume",
                  onPressed: _isProcessing ? () {} : _updateResume,
                ),

                const SizedBox(height: 10),

                // Test Button (you can remove this later)
                // ElevatedButton(
                //   onPressed: () async {
                //     final works = await GeminiResumeService.testConnection();
                //     if (mounted) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(
                //           content: Text("Gemini test: ${works ? '✅ WORKING' : '❌ FAILED'}"),
                //           backgroundColor: works ? Colors.green : Colors.red,
                //           duration: const Duration(seconds: 2),
                //         ),
                //       );
                //     }
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.grey.shade200,
                //     foregroundColor: Colors.grey.shade700,
                //     minimumSize: const Size(double.infinity, 45),
                //   ),
                //   child: const Text("🧪 Test Gemini Connection"),
                // ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}