# Template System Usage Guide

## Overview

The template system allows you to create document blocks from pre-built templates or custom templates. Templates support variables like `{{variable_name}}` that can be replaced when creating a new document.

## Pre-built Templates

The system comes with two pre-built templates:

1. **Meeting Notes** - For structured meeting notes with agenda, attendees, and action items
2. **Project Planning** - For project planning with milestones, tasks, and team members

## How to Use Templates

### Step 1: Initialize Services

In your `canvas_screen.dart` or main initialization code, set up the template services:

```dart
import 'package:path_provider/path_provider.dart';
import '../services/document_service.dart';
import '../services/templates/template_service.dart';
import '../services/templates/template_repository.dart';
import '../services/templates/template_integration_service.dart';

class _CanvasScreenState extends State<CanvasScreen> {
  late final CanvasService _service;
  late final DocumentServiceImpl _documentService;
  late final TemplateService _templateService;
  late final TemplateIntegrationService _templateIntegration;
  
  @override
  void initState() {
    super.initState();
    _service = CanvasService();
    
    // Initialize document service
    _documentService = DocumentServiceImpl();
    
    // Initialize template services
    _initTemplateServices();
    
    // ... rest of initialization
  }
  
  Future<void> _initTemplateServices() async {
    final directory = await getApplicationDocumentsDirectory();
    final templatesDir = '${directory.path}/templates';
    final thumbnailsDir = '${directory.path}/templates/thumbnails';
    
    final repository = LocalTemplateRepository(
      templatesDirectory: templatesDir,
      thumbnailsDirectory: thumbnailsDir,
    );
    
    _templateService = TemplateServiceImpl(
      repository: repository,
    );
    
    _templateIntegration = TemplateIntegrationService(
      templateService: _templateService,
      canvasService: _service,
      documentService: _documentService,
    );
  }
}
```

### Step 2: Open Template Library

Update the `_showAITemplatesDialog` method to open the template library:

```dart
void _showAITemplatesDialog() async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => TemplateLibraryScreen(
        templateService: _templateService,
        onTemplateSelected: (content) {
          // Template was selected and instantiated
          // The document block is already created on the canvas
        },
      ),
    ),
  );
}
```

### Step 3: Using Templates

1. **Open Template Library**: Click the "AI Templates" button in the sidebar
2. **Browse Templates**: You'll see pre-built templates and any custom templates
3. **Filter Templates**: Use search and category filters to find what you need
4. **Select Template**: Click on a template card
5. **Configure Variables**: If the template has variables, a dialog will appear:
   - Fill in the required variables (marked with *)
   - Optional variables can be left empty
   - Dates can be selected from a date picker
   - Select fields show dropdown options
6. **Create Document Block**: Click "Use Template" - a document block will appear on your canvas

## Template Variables

Templates support variables in the format `{{variable_name}}`. Variables can have metadata:

- `{{variable_name}}` - Simple text variable
- `{{variable_name:type:date}}` - Date variable
- `{{variable_name:placeholder:Enter value}}` - Variable with placeholder text
- `{{variable_name:required:true}}` - Required variable

### Variable Types

- `text` - Plain text input (default)
- `date` - Date picker
- `number` - Numeric input
- `select` - Dropdown with options
- `email` - Email validation
- `url` - URL validation

## Creating Custom Templates

### From Existing Document

1. Create or edit a document block on the canvas
2. Right-click or use context menu
3. Select "Save as Template"
4. Fill in template details:
   - Name
   - Description
   - Category
5. Variables will be automatically extracted from `{{variable}}` patterns in the document

### Programmatically

```dart
final document = // Your DocumentContent
final template = await _templateService.createTemplate(
  document,
  'My Template',
  'Description of my template',
  TemplateCategory.custom,
);
```

## Accessing Pre-built Templates

Pre-built templates are automatically available through the template service:

```dart
// Get all pre-built templates
final prebuiltTemplates = await _templateService.getPreBuiltTemplates();

// Get specific template
final meetingNotes = await _templateService.getPreBuiltTemplate(
  TemplateCategory.meetingNotes,
);
```

## Example: Creating a Document Block from Template

```dart
// Method 1: Using the integration service (recommended)
await _templateIntegration.createDocumentBlockFromTemplate(
  'prebuilt_meeting_notes_v1',
  {
    'meeting_title': 'Team Standup',
    'meeting_date': '2024-01-15',
    'meeting_time': '10:00 AM',
    'attendees': 'John, Jane, Bob',
    'meeting_notes': 'Discussed sprint progress...',
    'action_item_1': 'Finish authentication module',
  },
  Offset(100, 100), // Position on canvas
);

// Method 2: Through template library UI
await _templateIntegration.openTemplateLibrary(
  context,
  Offset(100, 100), // Position on canvas
);
```

## Template Storage

Templates are stored locally in:
- Location: `{app documents directory}/templates/`
- Format: JSON files
- Structure: Each template has its own directory with `template.json` and optional `thumbnail.png`

## Best Practices

1. **Use Pre-built Templates**: Start with Meeting Notes or Project Planning templates
2. **Name Variables Clearly**: Use descriptive variable names like `meeting_title` instead of `var1`
3. **Provide Placeholders**: Add helpful placeholder text for variables
4. **Organize by Category**: Assign templates to appropriate categories for easier discovery
5. **Add Descriptions**: Write clear descriptions so users know what each template is for

## Troubleshooting

### Template Not Found

If a template ID isn't found:
- Check if it's a pre-built template (starts with `prebuilt_`)
- Verify the template exists in the local storage
- Try refreshing the template library

### Variables Not Replaced

- Ensure variables use the format `{{variable_name}}`
- Check that variable names match exactly (case-sensitive)
- Verify variable values are provided when instantiating

### Document Block Not Appearing

- Check that `canvasService.addObject()` is called
- Verify the canvas service is properly initialized
- Ensure the document service can save documents

