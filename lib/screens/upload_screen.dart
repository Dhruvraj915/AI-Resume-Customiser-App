import 'package:flutter/material.dart';
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
  final TextEditingController _jobDescController = TextEditingController();

  void _selectPDF() {
    // TODO: Add file picker logic here
    setState(() {
      _pdfFileName = "MyResume.pdf";
    });
  }

  void _customizeResume() {
    if (_pdfFileName != null && _jobDescController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResultScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Resume Customizer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResumeInputCard(
              title: "Upload Your Resume",
              subtitle: _pdfFileName ?? "Select PDF File",
              icon: Icons.upload_file,
              onTap: _selectPDF,
            ),

            const SizedBox(height: 20),

            JobDescriptionInputCard(
              title: "Job Description Link",
              hint: "Paste the URL of the job you're applying to",
              controller: _jobDescController,
            ),
            const Spacer(),
            CustomButton(
              text: "Customize My Resume",
              onPressed: _customizeResume,
            )
            ,
          ],
        ),
      ),
    );
  }
}