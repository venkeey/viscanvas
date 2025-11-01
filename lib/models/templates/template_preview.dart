class TemplatePreview {
  final String? thumbnailPath;  // Local file path
  final String? thumbnailUrl;  // Remote URL (marketplace)
  final List<String> screenshotPaths;
  final String? previewText;  // First 200 chars of content
  
  TemplatePreview({
    this.thumbnailPath,
    this.thumbnailUrl,
    this.screenshotPaths = const [],
    this.previewText,
  });
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'thumbnailPath': thumbnailPath,
      'thumbnailUrl': thumbnailUrl,
      'screenshotPaths': screenshotPaths,
      'previewText': previewText,
    };
  }
  
  factory TemplatePreview.fromJson(Map<String, dynamic> json) {
    return TemplatePreview(
      thumbnailPath: json['thumbnailPath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      screenshotPaths: json['screenshotPaths'] != null
        ? List<String>.from(json['screenshotPaths'] as List)
        : [],
      previewText: json['previewText'] as String?,
    );
  }
  
  TemplatePreview copyWith({
    String? thumbnailPath,
    String? thumbnailUrl,
    List<String>? screenshotPaths,
    String? previewText,
  }) {
    return TemplatePreview(
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      screenshotPaths: screenshotPaths ?? this.screenshotPaths,
      previewText: previewText ?? this.previewText,
    );
  }
  
  // Helper to generate preview text from document content
  static String generatePreviewText(String content, {int maxLength = 200}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }
}

