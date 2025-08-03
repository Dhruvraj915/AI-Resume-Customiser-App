import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  void _downloadResume() {
    // TODO: Add PDF download logic
    debugPrint("Download Custom Resume");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Resume Customizer")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Resume Customized Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your resume has been tailored to match the job description.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: "Download Custom Resume",
              onPressed: _downloadResume,
            ),
          ],
        ),
      ),
    );
  }
}
