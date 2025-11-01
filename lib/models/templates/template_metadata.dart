enum TemplateLanguage {
  en,
  es,
  fr,
  de,
  it,
  pt,
  zh,
  ja,
  ko,
  // Add more as needed
}

enum TemplateDifficulty {
  beginner,
  intermediate,
  advanced,
}

class TemplateMetadata {
  final List<String> tags;
  final TemplateLanguage language;
  final TemplateDifficulty difficulty;
  final int estimatedTimeMinutes;
  final List<String> useCases;
  final Map<String, dynamic> customProperties;
  
  TemplateMetadata({
    this.tags = const [],
    this.language = TemplateLanguage.en,
    this.difficulty = TemplateDifficulty.beginner,
    this.estimatedTimeMinutes = 5,
    this.useCases = const [],
    this.customProperties = const {},
  });
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
      'language': language.toString(),
      'difficulty': difficulty.toString(),
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'useCases': useCases,
      'customProperties': customProperties,
    };
  }
  
  factory TemplateMetadata.fromJson(Map<String, dynamic> json) {
    return TemplateMetadata(
      tags: json['tags'] != null 
        ? List<String>.from(json['tags'] as List)
        : [],
      language: TemplateLanguage.values.firstWhere(
        (l) => l.toString() == json['language'],
        orElse: () => TemplateLanguage.en,
      ),
      difficulty: TemplateDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => TemplateDifficulty.beginner,
      ),
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 5,
      useCases: json['useCases'] != null
        ? List<String>.from(json['useCases'] as List)
        : [],
      customProperties: json['customProperties'] != null
        ? Map<String, dynamic>.from(json['customProperties'] as Map)
        : {},
    );
  }
  
  TemplateMetadata copyWith({
    List<String>? tags,
    TemplateLanguage? language,
    TemplateDifficulty? difficulty,
    int? estimatedTimeMinutes,
    List<String>? useCases,
    Map<String, dynamic>? customProperties,
  }) {
    return TemplateMetadata(
      tags: tags ?? this.tags,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      useCases: useCases ?? this.useCases,
      customProperties: customProperties ?? this.customProperties,
    );
  }
  
  // Helper methods
  bool hasTag(String tag) => tags.contains(tag.toLowerCase());
  
  void addTag(String tag) {
    if (!tags.contains(tag.toLowerCase())) {
      tags.add(tag.toLowerCase());
    }
  }
  
  void removeTag(String tag) {
    tags.remove(tag.toLowerCase());
  }
}

