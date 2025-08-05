import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiResumeService {
  static const String _apiKey = 'AIzaSyCTsVv7zyjlHxGl26PxXCR2D96PZXDBILg'; // Replace with your API key!
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<Map<String, dynamic>> customizeResumeWithGemini({
    required String resumeText,
    required String jobDescription,
  }) async {
    // Quick validation
    if (_apiKey == 'AIzaSyCTsVv7zyjlHxGl26PxXCR2D96PZXDBILg' || _apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    if (resumeText.trim().isEmpty || jobDescription.trim().isEmpty) {
      throw Exception('Resume text and job description cannot be empty');
    }

    try {
      final prompt = _buildPrompt(resumeText, jobDescription);

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'ResumeCustomizer/1.0',
        },
        body: jsonEncode({
          'contents': [
            {'parts': [{'text': prompt}]}
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.8,
            'maxOutputTokens': 3000, // Reduced to prevent timeouts
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 12)); // Reduced timeout

      print("📡 Gemini API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if response has expected structure
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Invalid response structure from Gemini API');
        }

        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];

        if (generatedText == null || generatedText.toString().trim().isEmpty) {
          throw Exception('Empty response from Gemini API');
        }

        return _parseGeminiResponse(generatedText, resumeText);

      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Gemini API Bad Request: ${errorData['error']['message'] ?? 'Unknown error'}');
      } else if (response.statusCode == 403) {
        throw Exception('Gemini API Key invalid or quota exceeded');
      } else if (response.statusCode == 429) {
        throw Exception('Gemini API rate limit exceeded');
      } else {
        throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: Check internet connection - $e');
    } on FormatException catch (e) {
      throw Exception('JSON parsing error: $e');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Request timeout: Gemini API is taking too long');
      }
      print('Gemini API unexpected error: $e');
      rethrow;
    }
  }

  static String _buildPrompt(String resume, String jobDesc) {
    // Truncate if too long to prevent API limits
    final truncatedResume = resume.length > 2000 ? resume.substring(0, 2000) + '...' : resume;
    final truncatedJobDesc = jobDesc.length > 1500 ? jobDesc.substring(0, 1500) + '...' : jobDesc;

    return '''
You are an expert professional resume writer and ATS optimization specialist.

TASK: Customize this resume for the given job description while preserving the original formatting and layout.

RESUME:
"""
$truncatedResume
"""

JOB DESCRIPTION:
"""
$truncatedJobDesc
"""

INSTRUCTIONS:
- Enhance relevant resume parts with job keywords.
- Strengthen action verbs and quantify achievements where possible.
- Do NOT change section layout/formatting.
- Keep the response concise and focused.
- After the new resume, append "---METADATA---", then:
MATCH_SCORE: [0-100]
IMPROVEMENTS_MADE: [max 3 items]
SUGGESTIONS: [max 3 actionable items]

Only return the improved resume, followed by the metadata block as shown.
''';
  }

  static Map<String, dynamic> _parseGeminiResponse(String response, String originalResume) {
    final parts = response.split('---METADATA---');
    String improvedResume = parts[0].trim();

    double matchScore = 75.0;
    List<String> improvements = [];
    List<String> suggestions = [];

    if (parts.length > 1) {
      final meta = parts[1];

      // Parse match score
      final scoreMatch = RegExp(r'MATCH_SCORE:\s*(\d+(?:\.\d+)?)').firstMatch(meta);
      if (scoreMatch != null) {
        matchScore = double.tryParse(scoreMatch.group(1) ?? '75') ?? 75.0;
      }

      // Parse improvements
      final improvementMatch = RegExp(r'IMPROVEMENTS_MADE:\s*(.*?)(?=SUGGESTIONS:|$)', dotAll: true).firstMatch(meta);
      if (improvementMatch != null) {
        improvements = improvementMatch.group(1)!
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
            .take(3)
            .toList();
      }

      // Parse suggestions
      final suggestionsMatch = RegExp(r'SUGGESTIONS:\s*(.*)', dotAll: true).firstMatch(meta);
      if (suggestionsMatch != null) {
        suggestions = suggestionsMatch.group(1)!
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
            .take(3)
            .toList();
      }
    }

    // Validate improved resume
    if (improvedResume.isEmpty || improvedResume.length < originalResume.length * 0.5) {
      print("⚠️ Generated resume too short, using original");
      improvedResume = originalResume;
      improvements = ['Resume structure preserved due to generation issue'];
    }

    return {
      'updatedResume': improvedResume,
      'matchScore': matchScore.clamp(0.0, 100.0),
      'improvements': improvements.isNotEmpty ? improvements : ['Enhanced resume content', 'Improved keyword matching'],
      'suggestions': suggestions.isNotEmpty ? suggestions : ['Consider adding more quantified achievements'],
      'source': 'gemini',
    };
  }
}