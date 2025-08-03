import 'package:flutter/material.dart';
import 'package:resume_ai_app/screens/upload_screen.dart';
import 'screens/splash_screen.dart';
//import 'utils/theme.dart';

void main() {
  runApp(const ResumeAIApp());
}

class ResumeAIApp extends StatelessWidget {
  const ResumeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume AI',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}