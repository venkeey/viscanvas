enum TemplateCategory {
  // Pre-built categories
  meetingNotes,
  projectPlanning,
  taskManagement,
  documentation,
  brainstorming,
  personal,
  business,
  education,
  custom,  // User-created templates
  
  // Future categories
  engineering,
  design,
  marketing,
  sales,
  hr,
}

extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.meetingNotes:
        return 'Meeting Notes';
      case TemplateCategory.projectPlanning:
        return 'Project Planning';
      case TemplateCategory.taskManagement:
        return 'Task Management';
      case TemplateCategory.documentation:
        return 'Documentation';
      case TemplateCategory.brainstorming:
        return 'Brainstorming';
      case TemplateCategory.personal:
        return 'Personal';
      case TemplateCategory.business:
        return 'Business';
      case TemplateCategory.education:
        return 'Education';
      case TemplateCategory.custom:
        return 'Custom';
      case TemplateCategory.engineering:
        return 'Engineering';
      case TemplateCategory.design:
        return 'Design';
      case TemplateCategory.marketing:
        return 'Marketing';
      case TemplateCategory.sales:
        return 'Sales';
      case TemplateCategory.hr:
        return 'Human Resources';
    }
  }
  
  String get icon {
    switch (this) {
      case TemplateCategory.meetingNotes:
        return '📝';
      case TemplateCategory.projectPlanning:
        return '📊';
      case TemplateCategory.taskManagement:
        return '✅';
      case TemplateCategory.documentation:
        return '📚';
      case TemplateCategory.brainstorming:
        return '💡';
      case TemplateCategory.personal:
        return '👤';
      case TemplateCategory.business:
        return '💼';
      case TemplateCategory.education:
        return '🎓';
      case TemplateCategory.custom:
        return '⭐';
      case TemplateCategory.engineering:
        return '⚙️';
      case TemplateCategory.design:
        return '🎨';
      case TemplateCategory.marketing:
        return '📢';
      case TemplateCategory.sales:
        return '💰';
      case TemplateCategory.hr:
        return '👥';
    }
  }
}

