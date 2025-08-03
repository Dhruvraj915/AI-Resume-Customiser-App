import 'package:file_picker/file_picker.dart';
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

  void _selectPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFileName = result.files.single.name;
        // String filePath = result.files.single.path!;
        // You can now use filePath to send the file to a backend or store locally
      });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
    }
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
            title: "Job Description",
            hint: "Write or paste the job description here",
            controller: _jobDescController,
            isMultiline: true,
          ),
            const SizedBox(height: 170),
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