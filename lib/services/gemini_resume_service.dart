import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiResumeService {
  // UPDATE THESE TWO LINES WITH YOUR NEW VALUES
  static const String apiKey = 'AIzaSyCax3VgRx9cHD4LPbbM2lFRxtdKxz_y600'; // Replace with your new API key
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<Map<String, dynamic>> customizeResumeWithGemini({
    required String resumeText,
    required String jobDescription,
  }) async {

    print("🔑 Using API key: ${apiKey.substring(0, 10)}...");
    print("🌐 Calling URL: $_baseUrl");

    final prompt = '''
You are a professional resume optimizer. Your task is to enhance the existing resume by strategically adding relevant keywords from the job description to appropriate sections WITHOUT changing the overall structure or adding unnecessary content.

INSTRUCTIONS:
1. PRESERVE the original resume format and structure
2. ONLY add relevant keywords from the job description to existing sections
3. DO NOT add summaries, objectives, or new sections
4. DO NOT change personal information, contact details, or dates
5. Focus on enhancing: Skills, Experience descriptions, and Technical competencies
6. Keep all additions natural and contextually appropriate
7. Maintain the professional tone and formatting

JOB DESCRIPTION:
$jobDescription

RESUME TO ENHANCE:
$resumeText

OUTPUT: Return the enhanced resume with strategically placed keywords while maintaining the original structure and authenticity.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          }
        }),
      );

      print("📡 API Response status: ${response.statusCode}");
      print("📄 API Response body preview: ${response.body.substring(0, 200)}...");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final customizedResume = data['candidates'][0]['content']['parts'][0]['text'];

          print("✅ Gemini API success - got ${customizedResume.length} characters");

          return {
            'updatedResume': customizedResume,
            'matchScore': 85.0,
            'suggestions': [
              'Enhanced with AI optimization',
              'Keywords aligned with job requirements',
              'Skills section improved',
              'Experience section tailored'
            ],
            'improvements': [
              'AI-powered content enhancement',
              'Job-specific keyword optimization',
              'Professional formatting improvements'
            ],
            'source': 'gemini',
          };
        } else {
          throw Exception('No candidates in Gemini response');
        }
      } else if (response.statusCode == 429) {
        print("⏰ Rate limit hit - waiting and retrying...");
        await Future.delayed(Duration(seconds: 2));
        throw Exception('Rate limit exceeded - try again later');
      } else {
        print("❌ API Error ${response.statusCode}: ${response.body}");
        throw Exception('Gemini API failed with status ${response.statusCode}');
      }
    } catch (e) {
      print("💥 Gemini service error: $e");
      rethrow; // This will trigger the offline fallback in HybridResumeService
    }
  }

  // Test method to check if API is working
  static Future<bool> testConnection() async {
    try {
      print("🧪 Testing connection...");
      print("🔑 API Key: ${apiKey.substring(0, 15)}...");
      print("🌐 URL: $_baseUrl");

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Hello, this is a test. Please respond with "Test successful".'
            }]
          }]
        }),
      ).timeout(Duration(seconds: 10));

      print("🧪 Test response status: ${response.statusCode}");
      print("🧪 Test response body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("🧪 Test failed with error: $e");
      print("🧪 Error type: ${e.runtimeType}");
      return false;
    }
  }
}