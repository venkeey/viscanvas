import 'package:flutter/material.dart';

/// Rich text formatting options
enum TextFormat {
  bold,
  italic,
  underline,
  strikethrough,
  code,
  link,
}

/// Rich text segment with formatting
class RichTextSegment {
  final String text;
  final Set<TextFormat> formats;
  final String? linkUrl;
  final Color? color;

  const RichTextSegment({
    required this.text,
    this.formats = const {},
    this.linkUrl,
    this.color,
  });

  bool get isBold => formats.contains(TextFormat.bold);
  bool get isItalic => formats.contains(TextFormat.italic);
  bool get isUnderline => formats.contains(TextFormat.underline);
  bool get isStrikethrough => formats.contains(TextFormat.strikethrough);
  bool get isCode => formats.contains(TextFormat.code);
  bool get isLink => formats.contains(TextFormat.link);

  RichTextSegment copyWith({
    String? text,
    Set<TextFormat>? formats,
    String? linkUrl,
    Color? color,
  }) {
    return RichTextSegment(
      text: text ?? this.text,
      formats: formats ?? this.formats,
      linkUrl: linkUrl ?? this.linkUrl,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'formats': formats.map((f) => f.toString()).toList(),
      'linkUrl': linkUrl,
      'color': color?.value,
    };
  }

  factory RichTextSegment.fromJson(Map<String, dynamic> json) {
    return RichTextSegment(
      text: json['text'] ?? '',
      formats: (json['formats'] as List<dynamic>?)
          ?.map((f) => TextFormat.values.firstWhere((tf) => tf.toString() == f))
          .toSet() ?? {},
      linkUrl: json['linkUrl'],
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
}

/// Rich text content with multiple segments
class RichTextContent {
  final List<RichTextSegment> segments;

  const RichTextContent(this.segments);

  factory RichTextContent.plain(String text) {
    return RichTextContent([RichTextSegment(text: text)]);
  }

  factory RichTextContent.empty() {
    return const RichTextContent([]);
  }

  String get plainText {
    return segments.map((s) => s.text).join();
  }

  bool get isEmpty => segments.isEmpty || plainText.trim().isEmpty;

  RichTextContent copyWith({
    List<RichTextSegment>? segments,
  }) {
    return RichTextContent(segments ?? this.segments);
  }

  RichTextContent addSegment(RichTextSegment segment) {
    return RichTextContent([...segments, segment]);
  }

  RichTextContent insertSegment(int index, RichTextSegment segment) {
    final newSegments = List<RichTextSegment>.from(segments);
    newSegments.insert(index, segment);
    return RichTextContent(newSegments);
  }

  RichTextContent removeSegment(int index) {
    final newSegments = List<RichTextSegment>.from(segments);
    newSegments.removeAt(index);
    return RichTextContent(newSegments);
  }

  RichTextContent updateSegment(int index, RichTextSegment segment) {
    final newSegments = List<RichTextSegment>.from(segments);
    newSegments[index] = segment;
    return RichTextContent(newSegments);
  }

  Map<String, dynamic> toJson() {
    return {
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }

  factory RichTextContent.fromJson(Map<String, dynamic> json) {
    return RichTextContent(
      (json['segments'] as List<dynamic>?)
          ?.map((s) => RichTextSegment.fromJson(Map<String, dynamic>.from(s)))
          .toList() ?? [],
    );
  }
}

/// Widget for rendering rich text
class RichTextWidget extends StatelessWidget {
  final RichTextContent content;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;

  const RichTextWidget({
    Key? key,
    required this.content,
    this.baseStyle,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final spans = content.segments.map((segment) {
      TextStyle style = baseStyle ?? Theme.of(context).textTheme.bodyMedium!;

      if (segment.isBold) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      if (segment.isItalic) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      if (segment.isUnderline) {
        style = style.copyWith(decoration: TextDecoration.underline);
      }
      if (segment.isStrikethrough) {
        style = style.copyWith(decoration: TextDecoration.lineThrough);
      }
      if (segment.isCode) {
        style = style.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.withOpacity(0.2),
        );
      }
      if (segment.isLink) {
        style = style.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
      }
      if (segment.color != null) {
        style = style.copyWith(color: segment.color);
      }

      return TextSpan(
        text: segment.text,
        style: style,
        recognizer: segment.isLink && segment.linkUrl != null
            ? null // TODO: Add tap recognizer for links
            : null,
      );
    }).toList();

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
