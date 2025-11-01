enum VariableType {
  text,
  date,
  number,
  select,
  email,
  url,
}

class TemplateVariable {
  final String name;  // "project_name", "meeting_date"
  final String displayName;  // "Project Name", "Meeting Date"
  final VariableType type;  // text, date, number, select
  final String? defaultValue;
  final String? placeholder;
  final String? description;
  final List<String>? options;  // For select type
  final bool required;
  
  TemplateVariable({
    required this.name,
    required this.displayName,
    required this.type,
    this.defaultValue,
    this.placeholder,
    this.description,
    this.options,
    this.required = false,
  });
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'type': type.toString(),
      'defaultValue': defaultValue,
      'placeholder': placeholder,
      'description': description,
      'options': options,
      'required': required,
    };
  }
  
  factory TemplateVariable.fromJson(Map<String, dynamic> json) {
    return TemplateVariable(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      type: VariableType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => VariableType.text,
      ),
      defaultValue: json['defaultValue'] as String?,
      placeholder: json['placeholder'] as String?,
      description: json['description'] as String?,
      options: json['options'] != null 
        ? List<String>.from(json['options'] as List)
        : null,
      required: json['required'] as bool? ?? false,
    );
  }
  
  TemplateVariable copyWith({
    String? name,
    String? displayName,
    VariableType? type,
    String? defaultValue,
    String? placeholder,
    String? description,
    List<String>? options,
    bool? required,
  }) {
    return TemplateVariable(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      placeholder: placeholder ?? this.placeholder,
      description: description ?? this.description,
      options: options ?? this.options,
      required: required ?? this.required,
    );
  }
  
  @override
  String toString() => '{{$name}}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateVariable &&
          runtimeType == other.runtimeType &&
          name == other.name;
  
  @override
  int get hashCode => name.hashCode;
}

