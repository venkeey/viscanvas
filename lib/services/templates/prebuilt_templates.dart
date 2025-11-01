import '../../models/documents/document_content.dart';
import '../../models/documents/block_types.dart';
import '../../models/templates/document_template.dart';
import '../../models/templates/template_category.dart';
import '../../models/templates/template_metadata.dart';
import '../../models/templates/template_variable.dart';
import '../../models/templates/template_preview.dart';

class PrebuiltTemplateFactory {
  static final Map<String, DocumentTemplate> _templates = {};
  static bool _initialized = false;
  
  static void _initialize() {
    if (_initialized) return;
    
    _templates['prebuilt_meeting_notes_v1'] = createMeetingNotesTemplate();
    _templates['prebuilt_project_planning_v1'] = createProjectPlanningTemplate();
    
    _initialized = true;
  }
  
  static DocumentTemplate createMeetingNotesTemplate() {
    final blocks = [
      // Heading 1: Meeting Title
      BasicBlock(
        id: 'block_1',
        type: BlockType.heading1,
        content: {'text': '{{meeting_title:placeholder:Enter meeting title}}'},
      ),
      
      // Paragraph: Date and Time
      BasicBlock(
        id: 'block_2',
        type: BlockType.paragraph,
        content: {
          'text': 'Date: {{meeting_date:type:date}}\nTime: {{meeting_time:placeholder:10:00 AM}}'
        },
      ),
      
      // Divider
      BasicBlock(
        id: 'block_3',
        type: BlockType.divider,
        content: {},
      ),
      
      // Heading 2: Attendees
      BasicBlock(
        id: 'block_4',
        type: BlockType.heading2,
        content: {'text': 'Attendees'},
      ),
      
      // Bulleted list for attendees
      BasicBlock(
        id: 'block_5',
        type: BlockType.bulletedListItem,
        content: {'text': '{{attendees:placeholder:Add attendees}}'},
      ),
      
      // Heading 2: Agenda
      BasicBlock(
        id: 'block_6',
        type: BlockType.heading2,
        content: {'text': 'Agenda'},
      ),
      
      // Todo items for agenda
      BasicBlock(
        id: 'block_7',
        type: BlockType.toDo,
        content: {'text': 'Item 1', 'checked': false},
      ),
      BasicBlock(
        id: 'block_8',
        type: BlockType.toDo,
        content: {'text': 'Item 2', 'checked': false},
      ),
      
      // Heading 2: Notes
      BasicBlock(
        id: 'block_9',
        type: BlockType.heading2,
        content: {'text': 'Notes'},
      ),
      
      // Paragraph for notes
      BasicBlock(
        id: 'block_10',
        type: BlockType.paragraph,
        content: {'text': '{{meeting_notes:placeholder:Take notes here}}'},
      ),
      
      // Heading 2: Action Items
      BasicBlock(
        id: 'block_11',
        type: BlockType.heading2,
        content: {'text': 'Action Items'},
      ),
      
      // Todo items for action items
      BasicBlock(
        id: 'block_12',
        type: BlockType.toDo,
        content: {'text': '{{action_item_1:placeholder:Add action item}}', 'checked': false},
      ),
    ];
    
    final hierarchy = BlockHierarchy();
    // Setup parent-child relationships
    hierarchy.addBlock(blocks[0]); // Title
    hierarchy.addBlock(blocks[1]); // Date/Time
    hierarchy.addBlock(blocks[2]); // Divider
    hierarchy.addBlock(blocks[3]); // Attendees heading
    hierarchy.addBlock(blocks[4], parentId: blocks[3].id); // Attendees list
    hierarchy.addBlock(blocks[5]); // Agenda heading
    hierarchy.addBlock(blocks[6], parentId: blocks[5].id); // Agenda item 1
    hierarchy.addBlock(blocks[7], parentId: blocks[5].id); // Agenda item 2
    hierarchy.addBlock(blocks[8]); // Notes heading
    hierarchy.addBlock(blocks[9], parentId: blocks[8].id); // Notes content
    hierarchy.addBlock(blocks[10]); // Action Items heading
    hierarchy.addBlock(blocks[11], parentId: blocks[10].id); // Action item
    
    final content = DocumentContent(
      id: 'template_meeting_notes',
      blocks: blocks,
      hierarchy: hierarchy,
    );
    
    final variables = [
      TemplateVariable(
        name: 'meeting_title',
        displayName: 'Meeting Title',
        type: VariableType.text,
        required: true,
        placeholder: 'Enter meeting title',
      ),
      TemplateVariable(
        name: 'meeting_date',
        displayName: 'Meeting Date',
        type: VariableType.date,
        defaultValue: DateTime.now().toString().split(' ')[0],
      ),
      TemplateVariable(
        name: 'meeting_time',
        displayName: 'Meeting Time',
        type: VariableType.text,
        placeholder: '10:00 AM',
      ),
      TemplateVariable(
        name: 'attendees',
        displayName: 'Attendees',
        type: VariableType.text,
        placeholder: 'Add attendees',
      ),
      TemplateVariable(
        name: 'meeting_notes',
        displayName: 'Meeting Notes',
        type: VariableType.text,
        placeholder: 'Take notes here',
      ),
      TemplateVariable(
        name: 'action_item_1',
        displayName: 'Action Item 1',
        type: VariableType.text,
        placeholder: 'Add action item',
      ),
    ];
    
    return DocumentTemplate(
      id: 'prebuilt_meeting_notes_v1',
      name: 'Meeting Notes',
      description: 'Template for taking structured meeting notes with agenda, attendees, and action items',
      category: TemplateCategory.meetingNotes,
      content: content,
      metadata: TemplateMetadata(
        tags: ['meeting', 'notes', 'agenda', 'action items'],
        useCases: ['team meetings', 'client meetings', 'stand-ups'],
        estimatedTimeMinutes: 3,
      ),
      variables: variables,
      preview: TemplatePreview(
        previewText: TemplatePreview.generatePreviewText(
          'Meeting Notes\nTemplate for taking structured meeting notes with agenda, attendees, and action items',
        ),
      ),
      authorId: 'system',
      authorName: 'VisCanvas',
      version: '1.0.0',
    );
  }
  
  static DocumentTemplate createProjectPlanningTemplate() {
    final blocks = [
      // Heading 1: Project Name
      BasicBlock(
        id: 'block_1',
        type: BlockType.heading1,
        content: {'text': '{{project_name:placeholder:Enter project name}}'},
      ),
      
      // Paragraph: Project Info
      BasicBlock(
        id: 'block_2',
        type: BlockType.paragraph,
        content: {
          'text': 'Start Date: {{start_date:type:date}}\nEnd Date: {{end_date:type:date}}\nStatus: {{status:placeholder:Planning}}'
        },
      ),
      
      // Divider
      BasicBlock(
        id: 'block_3',
        type: BlockType.divider,
        content: {},
      ),
      
      // Heading 2: Project Overview
      BasicBlock(
        id: 'block_4',
        type: BlockType.heading2,
        content: {'text': 'Project Overview'},
      ),
      
      // Paragraph for overview
      BasicBlock(
        id: 'block_5',
        type: BlockType.paragraph,
        content: {'text': '{{project_overview:placeholder:Describe the project goals and objectives}}'},
      ),
      
      // Heading 2: Team Members
      BasicBlock(
        id: 'block_6',
        type: BlockType.heading2,
        content: {'text': 'Team Members'},
      ),
      
      // Bulleted list for team
      BasicBlock(
        id: 'block_7',
        type: BlockType.bulletedListItem,
        content: {'text': '{{team_member_1:placeholder:Add team member}}'},
      ),
      
      // Heading 2: Milestones
      BasicBlock(
        id: 'block_8',
        type: BlockType.heading2,
        content: {'text': 'Milestones'},
      ),
      
      // Todo items for milestones
      BasicBlock(
        id: 'block_9',
        type: BlockType.toDo,
        content: {'text': '{{milestone_1:placeholder:Add milestone}}', 'checked': false},
      ),
      
      // Heading 2: Tasks
      BasicBlock(
        id: 'block_10',
        type: BlockType.heading2,
        content: {'text': 'Tasks'},
      ),
      
      // Todo items for tasks
      BasicBlock(
        id: 'block_11',
        type: BlockType.toDo,
        content: {'text': '{{task_1:placeholder:Add task}}', 'checked': false},
      ),
      
      // Heading 2: Resources
      BasicBlock(
        id: 'block_12',
        type: BlockType.heading2,
        content: {'text': 'Resources'},
      ),
      
      // Paragraph for resources
      BasicBlock(
        id: 'block_13',
        type: BlockType.paragraph,
        content: {'text': '{{resources:placeholder:List required resources}}'},
      ),
    ];
    
    final hierarchy = BlockHierarchy();
    // Setup parent-child relationships
    hierarchy.addBlock(blocks[0]); // Project name
    hierarchy.addBlock(blocks[1]); // Project info
    hierarchy.addBlock(blocks[2]); // Divider
    hierarchy.addBlock(blocks[3]); // Overview heading
    hierarchy.addBlock(blocks[4], parentId: blocks[3].id); // Overview content
    hierarchy.addBlock(blocks[5]); // Team heading
    hierarchy.addBlock(blocks[6], parentId: blocks[5].id); // Team member
    hierarchy.addBlock(blocks[7]); // Milestones heading
    hierarchy.addBlock(blocks[8], parentId: blocks[7].id); // Milestone
    hierarchy.addBlock(blocks[9]); // Tasks heading
    hierarchy.addBlock(blocks[10], parentId: blocks[9].id); // Task
    hierarchy.addBlock(blocks[11]); // Resources heading
    hierarchy.addBlock(blocks[12], parentId: blocks[11].id); // Resources content
    
    final content = DocumentContent(
      id: 'template_project_planning',
      blocks: blocks,
      hierarchy: hierarchy,
    );
    
    final variables = [
      TemplateVariable(
        name: 'project_name',
        displayName: 'Project Name',
        type: VariableType.text,
        required: true,
        placeholder: 'Enter project name',
      ),
      TemplateVariable(
        name: 'start_date',
        displayName: 'Start Date',
        type: VariableType.date,
        defaultValue: DateTime.now().toString().split(' ')[0],
      ),
      TemplateVariable(
        name: 'end_date',
        displayName: 'End Date',
        type: VariableType.date,
      ),
      TemplateVariable(
        name: 'status',
        displayName: 'Status',
        type: VariableType.text,
        placeholder: 'Planning',
      ),
      TemplateVariable(
        name: 'project_overview',
        displayName: 'Project Overview',
        type: VariableType.text,
        placeholder: 'Describe the project goals and objectives',
      ),
      TemplateVariable(
        name: 'team_member_1',
        displayName: 'Team Member 1',
        type: VariableType.text,
        placeholder: 'Add team member',
      ),
      TemplateVariable(
        name: 'milestone_1',
        displayName: 'Milestone 1',
        type: VariableType.text,
        placeholder: 'Add milestone',
      ),
      TemplateVariable(
        name: 'task_1',
        displayName: 'Task 1',
        type: VariableType.text,
        placeholder: 'Add task',
      ),
      TemplateVariable(
        name: 'resources',
        displayName: 'Resources',
        type: VariableType.text,
        placeholder: 'List required resources',
      ),
    ];
    
    return DocumentTemplate(
      id: 'prebuilt_project_planning_v1',
      name: 'Project Planning',
      description: 'Template for planning projects with milestones, tasks, team members, and resources',
      category: TemplateCategory.projectPlanning,
      content: content,
      metadata: TemplateMetadata(
        tags: ['project', 'planning', 'milestones', 'tasks', 'team'],
        useCases: ['project planning', 'project management', 'team collaboration'],
        estimatedTimeMinutes: 5,
      ),
      variables: variables,
      preview: TemplatePreview(
        previewText: TemplatePreview.generatePreviewText(
          'Project Planning\nTemplate for planning projects with milestones, tasks, team members, and resources',
        ),
      ),
      authorId: 'system',
      authorName: 'VisCanvas',
      version: '1.0.0',
    );
  }
  
  static List<DocumentTemplate> getAllPrebuiltTemplates() {
    _initialize();
    return _templates.values.toList();
  }
  
  Future<DocumentTemplate?> getTemplateById(String templateId) async {
    _initialize();
    return _templates[templateId];
  }
  
  Future<DocumentTemplate?> getTemplateByCategory(TemplateCategory category) async {
    _initialize();
    return _templates.values.firstWhere(
      (t) => t.category == category,
      orElse: () => _templates.values.first,
    );
  }
  
  // Factory methods
  static Future<DocumentTemplate?> getTemplateByIdStatic(String templateId) async {
    _initialize();
    return _templates[templateId];
  }
  
  static Future<DocumentTemplate?> getTemplateByCategoryStatic(TemplateCategory category) async {
    _initialize();
    try {
      return _templates.values.firstWhere((t) => t.category == category);
    } catch (e) {
      return null;
    }
  }
}

