import 'offline_resume_service.dart';
import 'gemini_resume_service.dart';

class HybridResumeService {
  static Future<Map<String, dynamic>> customizeResume({
    required String resumeText,
    required String jobDescription,
    bool forceOffline = false,
  }) async {
    if (forceOffline) {
      print("🔄 Forcing offline mode");
      return _runOffline(resumeText, jobDescription);
    }

    try {
      print("🤖 Attempting Gemini customization...");

      // Add timeout and better error handling
      final geminiResult = await GeminiResumeService.customizeResumeWithGemini(
        resumeText: resumeText,
        jobDescription: jobDescription,
      ).timeout(
        const Duration(seconds: 15), // Reduced from 30 to 15 seconds
        onTimeout: () {
          print("⏰ Gemini API timeout - switching to offline");
          throw Exception('Gemini API timeout');
        },
      );

      print("✅ Gemini customization successful!");
      return geminiResult;

    } catch (e) {
      print("⚠️ Gemini failed, using offline fallback: $e");
      return _runOffline(resumeText, jobDescription);
    }
  }

  static Map<String, dynamic> _runOffline(String resumeText, String jobDescription) {
    try {
      print("🔧 Running offline customization...");

      final improved = OfflineResumeService.customizeResume(
        resumeText: resumeText,
        jobDescription: jobDescription,
      );

      final score = OfflineResumeService.calculateMatchScore(improved, jobDescription);
      final suggestions = OfflineResumeService.getImprovementSuggestions(improved, jobDescription);

      print("✅ Offline customization completed!");

      return {
        'updatedResume': improved,
        'matchScore': score,
        'improvements': ['Enhanced action verbs', 'Added relevant keywords', 'Improved skills section'],
        'suggestions': suggestions,
        'source': 'offline',
      };
    } catch (e) {
      print("❌ Offline customization failed: $e");
      // Return original resume if everything fails
      return {
        'updatedResume': resumeText,
        'matchScore': 50.0,
        'improvements': ['Resume preserved due to processing error'],
        'suggestions': ['Please try again or check your input format'],
        'source': 'fallback',
      };
    }
  }

  // Add this method for testing connectivity
  static Future<bool> testGeminiConnection() async {
    try {
      await GeminiResumeService.customizeResumeWithGemini(
        resumeText: "Test resume",
        jobDescription: "Test job",
      ).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print("🔗 Gemini connection test failed: $e");
      return false;
    }
  }
}