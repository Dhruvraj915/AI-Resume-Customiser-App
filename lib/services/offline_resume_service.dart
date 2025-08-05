class OfflineResumeService {
  static String customizeResume({
    required String resumeText,
    required String jobDescription,
  }) {
    String improvedResume = _preserveResumeStructure(resumeText);
    final jobKeywords = _extractKeywords(jobDescription);

    improvedResume = _enhanceActionVerbs(improvedResume);
    improvedResume = _addSkillsIfMissing(improvedResume, jobKeywords);
    improvedResume = _enhanceKeywordPresence(improvedResume, jobKeywords);

    return improvedResume;
  }

  static String _preserveResumeStructure(String resumeText) {
    return resumeText.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(RegExp(r'^([A-Z][A-Z\s&]+)$', multiLine: true), (m) => '\n${m.group(1)}\n')
        .trim();
  }

  static List<String> _extractKeywords(String jobDescription) {
    final words = jobDescription.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet()
        .toList();
    final keywords = [
      'flutter', 'dart', 'react', 'javascript', 'typescript', 'python', 'java', 'kotlin',
      'swift', 'c', 'c++', 'c#', 'go', 'rust', 'ruby', 'php', 'sql', 'bash', 'r',
      'next.js', 'vue.js', 'nuxt.js', 'svelte', 'angular', 'tailwindcss', 'bootstrap',
      'firebase', 'supabase', 'mongodb', 'mysql', 'postgresql', 'sqlite', 'prisma',
      'node.js', 'express.js', 'django', 'flask', 'fastapi', 'spring boot', 'asp.net',
      'git', 'github', 'gitlab', 'bitbucket', 'docker', 'kubernetes', 'jenkins',
      'figma', 'adobe xd', 'photoshop', 'illustrator', 'canva',
      'tensorflow', 'pytorch', 'opencv', 'transformers', 'langchain', 'openai api',
      'linux', 'windows', 'android', 'ios', 'aws', 'azure', 'gcp',
      'vscode', 'android studio', 'xcode', 'postman', 'notion', 'slack', 'trello',
      'leadership', 'teamwork', 'problem solving', 'communication', 'critical thinking',
      'creativity', 'adaptability', 'time management', 'collaboration', 'decision making'

    ];
    return keywords.where((k) => words.any((w) => w.contains(k) || k.contains(w))).toList();
  }

  static String _enhanceActionVerbs(String resume) {
    final verbReplacements = {
      RegExp(r'\bworked on\b', caseSensitive: false): 'developed',
      RegExp(r'\bhelped with\b', caseSensitive: false): 'contributed to',
      RegExp(r'\bwas responsible for\b', caseSensitive: false): 'managed',
      RegExp(r'\bparticipated in\b', caseSensitive: false): 'collaborated on',
    };
    var improved = resume;
    verbReplacements.forEach((pattern, replacement) {
      improved = improved.replaceAll(pattern, replacement);
    });
    return improved;
  }

  static String _addSkillsIfMissing(String resume, List<String> keywords) {
    final existing = RegExp(r'(SKILLS?|TECHNICAL SKILLS?|CORE COMPETENCIES|TECHNOLOGIES)[\s:]*\n(.*?)(?=\n[A-Z][A-Z\s]+\n|\n\n[A-Z]|$)', caseSensitive: false, dotAll: true).firstMatch(resume);
    if (existing != null) {
      final curr = existing.group(2)?.trim() ?? '';
      final missing = keywords.where((k) => !curr.toLowerCase().contains(k.toLowerCase()));
      if (missing.isNotEmpty) {
        final joined = curr.contains(',') ? curr + ', ' + missing.join(', ') : curr + '\n-  ' + missing.join('\n-  ');
        return resume.replaceFirst(existing.group(0)!, '${existing.group(1)}\n$joined');
      }
      return resume;
    }
    // Add new skills section
    return resume + '\n\nTECHNICAL SKILLS\n-  ${keywords.join('\n-  ')}\n';
  }

  static String _enhanceKeywordPresence(String resume, List<String> keywords) {
    // You can enhance this further for your needs; for now, this is a pass-through
    return resume;
  }

  static double calculateMatchScore(String resume, String jobDescription) {
    final jobKeywords = _extractKeywords(jobDescription);
    if (jobKeywords.isEmpty) return 70.0;

    int matches = 0;
    final resumeText = resume.toLowerCase();
    for (final keyword in jobKeywords) {
      if (resumeText.contains(keyword.toLowerCase())) matches++;
    }
    final matchFraction = matches / jobKeywords.length;
    double score = 50 + matchFraction * 45; // Range 50–95
    return double.parse(score.clamp(50, 95).toStringAsFixed(1));
  }

  static List<String> getImprovementSuggestions(String resume, String jobDescription) {
    final suggestions = <String>[];
    final jobKeywords = _extractKeywords(jobDescription);
    final resumeText = resume.toLowerCase();

    final missing = jobKeywords.where((k) => !resumeText.contains(k.toLowerCase())).take(3).toList();
    if (missing.isNotEmpty) suggestions.add('Consider adding: ${missing.join(', ')}');
    if (resumeText.contains('worked on') || resumeText.contains('helped with')) {
      suggestions.add('Use stronger action verbs like "developed", "led", "implemented"');
    }
    if (!RegExp(r'\d+%|\d+\+|\d+k|\d+ years?').hasMatch(resumeText)) {
      suggestions.add('Add metrics and numbers to quantify achievements');
    }
    if (!resumeText.contains(RegExp(r'summary|objective|profile'))) {
      suggestions.add('Consider adding a professional summary section');
    }
    return suggestions.isNotEmpty ? suggestions : ['Your resume looks good! Consider customizing it further for specific roles.'];
  }
}
