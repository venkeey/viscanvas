# Hybrid Canvas-Document Architecture
## Notion-Style Block Editing in Infinite Canvas

### Executive Summary

This document outlines the architecture for integrating Notion-like block editing capabilities into an existing infinite canvas application. The solution enables users to create structured documents within the canvas while maintaining spatial awareness and seamless navigation between canvas elements and document blocks.

### Core Concept Expansion

**Your Original Request:**
> "User will choose any shape/block option which will open a block style editor...auto save and store the notion style document as a separate file...user can go back to canvas...even better if he can enter notes in blocks but at the same time pan the canvas to look at other shapes/text for reference"

**Enhanced Vision:**
1. **Spatial Document Blocks**: Canvas objects that can contain full Notion-style documents
2. **Contextual Editing**: Edit document blocks while maintaining visual reference to surrounding canvas elements
3. **Hybrid Navigation**: Seamless transition between canvas panning and document editing modes
4. **Persistent Storage**: Auto-save documents as separate files with canvas object references
5. **Standalone Viewing**: Documents can be viewed/edited independently of the canvas
6. **Cross-Reference System**: Link between canvas elements and document blocks

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  Canvas View  │  Document Editor  │  Hybrid Overlay Mode    │
│  - Pan/Zoom   │  - Block Editor   │  - Split View           │
│  - Selection  │  - Rich Text      │  - Contextual Panels    │
│  - Tools      │  - Slash Commands │  - Floating Editor      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  Canvas Manager  │  Document Manager  │  Hybrid Controller   │
│  - Object CRUD   │  - Block CRUD      │  - Mode Switching    │
│  - Transform     │  - Auto-save       │  - State Sync        │
│  - Events        │  - Persistence     │  - Cross-refs        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
├─────────────────────────────────────────────────────────────┤
│  Canvas Objects  │  Document Blocks  │  Hybrid Entities     │
│  - Spatial Data  │  - Rich Content   │  - DocumentBlock     │
│  - Transform     │  - Hierarchy      │  - CanvasReference   │
│  - Events        │  - Properties     │  - CrossReference    │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  Canvas Storage  │  Document Storage │  Hybrid Storage      │
│  - JSON Files    │  - Block Files    │  - Reference Index   │
│  - Spatial Index │  - Versioning     │  - Sync Service      │
│  - Persistence   │  - Auto-save      │  - Cross-ref Cache   │
└─────────────────────────────────────────────────────────────┘
```

### Data Models

#### 1. DocumentBlock (New Canvas Object Type)

```dart
class DocumentBlock extends CanvasObject {
  final String documentId;
  final String title;
  final DocumentContent content;
  final DocumentMetadata metadata;
  final List<CanvasReference> canvasReferences;
  final DocumentViewMode viewMode;
  
  // Canvas-specific properties
  final bool isExpanded;
  final bool isEditing;
  final DocumentBlockStyle style;
  
  // Methods
  void enterEditMode();
  void exitEditMode();
  void toggleExpanded();
  void addCanvasReference(CanvasObject object);
  void removeCanvasReference(String objectId);
}
```

#### 2. DocumentContent (Notion-style blocks)

```dart
class DocumentContent {
  final String id;
  final List<Block> blocks;
  final Map<String, Block> blockMap;
  final BlockHierarchy hierarchy;
  
  // Block operations
  void addBlock(Block block, {String? parentId, int? index});
  void removeBlock(String blockId);
  void moveBlock(String blockId, String newParentId, int newIndex);
  void updateBlock(String blockId, Map<String, dynamic> changes);
  
  // Auto-save
  void markDirty();
  bool get isDirty;
}
```

#### 3. CanvasReference (Cross-references)

```dart
class CanvasReference {
  final String id;
  final String canvasObjectId;
  final String documentBlockId;
  final ReferenceType type; // link, embed, mention
  final Offset? position; // For visual indicators
  final String? label;
  
  // Visual representation
  Widget buildCanvasIndicator();
  Widget buildDocumentLink();
}
```

#### 4. Hybrid View State

```dart
class HybridViewState {
  final CanvasViewMode canvasMode;
  final DocumentEditMode? documentMode;
  final String? activeDocumentId;
  final Set<String> visibleCanvasObjects;
  final Map<String, DocumentBlock> expandedDocuments;
  
  // Mode transitions
  void enterDocumentEditMode(String documentId);
  void exitDocumentEditMode();
  void toggleHybridMode();
  void syncCanvasDocumentState();
}
```

### User Experience Flows

#### 1. Creating a Document Block

```
User Action: Select "Document Block" from canvas tools
↓
Canvas: Show document block preview at cursor
↓
User Action: Click to place document block
↓
System: Create DocumentBlock object with default content
↓
User Action: Double-click or press Enter
↓
System: Enter document edit mode with floating editor
↓
User Action: Start typing or use slash commands
↓
System: Auto-save document content, update canvas preview
```

#### 2. Hybrid Editing Mode

```
User Action: Click on document block while in canvas mode
↓
System: Show document preview with "Edit" button
↓
User Action: Click "Edit" or double-click
↓
System: Enter hybrid mode:
  - Document editor opens in overlay/split view
  - Canvas remains visible and pannable
  - Document block highlighted on canvas
↓
User Action: Edit document while panning canvas
↓
System: 
  - Auto-save document changes
  - Update canvas preview in real-time
  - Maintain visual connection between editor and canvas block
```

#### 3. Cross-Reference Creation

```
User Action: In document editor, type "@" or select "Link to Canvas"
↓
System: Show canvas object picker overlay
↓
User Action: Click on canvas object or select from list
↓
System: Create CanvasReference, insert link in document
↓
User Action: Click reference link in document
↓
System: Pan canvas to show referenced object, highlight it
```

### Technical Implementation

#### 1. Extending Existing Canvas Architecture

```dart
// Extend your existing ToolType enum
enum ToolType {
  // ... existing tools
  document_block,  // New tool
  hybrid_edit,     // New mode
}

// Extend your existing CanvasObject hierarchy
abstract class CanvasObject {
  // ... existing properties
  bool get canContainDocument => false;
  DocumentBlock? get documentContent => null;
}

// New DocumentBlock implementation
class DocumentBlock extends CanvasObject {
  @override
  bool get canContainDocument => true;
  
  @override
  DocumentBlock? get documentContent => this;
  
  // Implement all required CanvasObject methods
  @override
  void render(Canvas canvas, Transform2D transform) {
    // Render document preview
    _renderDocumentPreview(canvas, transform);
  }
  
  @override
  bool hitTest(Offset point) {
    // Handle document block interactions
    return _hitTestDocumentBlock(point);
  }
}
```

#### 2. Document Editor Integration

```dart
class HybridDocumentEditor extends StatefulWidget {
  final DocumentBlock documentBlock;
  final CanvasController canvasController;
  final bool isHybridMode;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas view (if in hybrid mode)
        if (isHybridMode) 
          CanvasView(
            controller: canvasController,
            mode: CanvasViewMode.hybrid,
            highlightObject: documentBlock.id,
          ),
        
        // Document editor overlay
        DocumentEditorOverlay(
          document: documentBlock.content,
          onSave: _handleAutoSave,
          onCanvasReference: _handleCanvasReference,
          style: _getEditorStyle(),
        ),
      ],
    );
  }
}
```

#### 3. Auto-Save and Persistence

```dart
class DocumentPersistenceService {
  final String documentsPath;
  final Duration autoSaveInterval;
  final Map<String, Timer> _autoSaveTimers = {};
  
  void startAutoSave(String documentId, DocumentContent content) {
    _autoSaveTimers[documentId] = Timer.periodic(autoSaveInterval, (_) {
      _saveDocument(documentId, content);
    });
  }
  
  void stopAutoSave(String documentId) {
    _autoSaveTimers[documentId]?.cancel();
    _autoSaveTimers.remove(documentId);
  }
  
  Future<void> _saveDocument(String documentId, DocumentContent content) async {
    final file = File('$documentsPath/$documentId.json');
    await file.writeAsString(jsonEncode(content.toJson()));
  }
}
```

#### 4. Cross-Reference System

```dart
class CrossReferenceManager {
  final Map<String, List<CanvasReference>> _objectReferences = {};
  final Map<String, List<CanvasReference>> _documentReferences = {};
  
  void addReference(CanvasReference reference) {
    _objectReferences.putIfAbsent(reference.canvasObjectId, () => [])
        .add(reference);
    _documentReferences.putIfAbsent(reference.documentBlockId, () => [])
        .add(reference);
  }
  
  void navigateToReference(CanvasReference reference) {
    // Pan canvas to show referenced object
    canvasController.panToObject(reference.canvasObjectId);
    // Highlight the object
    canvasController.highlightObject(reference.canvasObjectId);
  }
  
  List<CanvasReference> getReferencesForObject(String objectId) {
    return _objectReferences[objectId] ?? [];
  }
}
```

### File Structure

```
lib/
├── pages/
│   ├── drawingCanvas.dart              # Your existing canvas
│   ├── drawing_persistence_service.dart # Your existing persistence
│   └── hybrid_document_editor.dart     # New hybrid editor
├── models/
│   ├── canvas_objects/
│   │   ├── document_block.dart         # New document block type
│   │   └── canvas_reference.dart       # Cross-reference model
│   ├── documents/
│   │   ├── document_content.dart       # Notion-style document
│   │   ├── block_types.dart           # All block types
│   │   └── block_hierarchy.dart       # Block organization
│   └── hybrid/
│       ├── hybrid_view_state.dart     # Combined state management
│       └── view_modes.dart            # Canvas/document modes
├── services/
│   ├── document_persistence_service.dart # Document auto-save
│   ├── cross_reference_manager.dart   # Reference management
│   └── hybrid_mode_controller.dart    # Mode switching logic
├── widgets/
│   ├── document_editor/
│   │   ├── block_editor.dart          # Individual block editor
│   │   ├── rich_text_editor.dart      # Rich text editing
│   │   ├── slash_command_menu.dart    # Notion-style commands
│   │   └── document_toolbar.dart      # Document-specific tools
│   ├── hybrid_ui/
│   │   ├── hybrid_overlay.dart        # Overlay mode UI
│   │   ├── split_view.dart            # Split canvas/document view
│   │   └── floating_editor.dart       # Floating document editor
│   └── canvas_indicators/
│       ├── document_preview.dart      # Canvas document preview
│       ├── reference_indicator.dart   # Cross-reference markers
│       └── edit_mode_indicator.dart   # Visual edit mode feedback
└── utils/
    ├── document_serialization.dart    # Document save/load
    └── canvas_document_sync.dart      # State synchronization
```

### Implementation Phases

#### Phase 1: Basic Document Blocks (2-3 weeks)
- [ ] Extend CanvasObject hierarchy with DocumentBlock
- [ ] Implement basic document content model
- [ ] Create simple document editor overlay
- [ ] Add document block tool to canvas
- [ ] Basic auto-save functionality

#### Phase 2: Rich Document Editing (3-4 weeks)
- [ ] Implement Notion-style block types (text, headings, lists, etc.)
- [ ] Add rich text editing capabilities
- [ ] Implement slash commands for block insertion
- [ ] Add drag-and-drop block reordering
- [ ] Enhanced auto-save with versioning

#### Phase 3: Hybrid Mode (2-3 weeks)
- [ ] Implement hybrid view mode
- [ ] Add canvas panning while editing documents
- [ ] Create floating/split view editor
- [ ] Add visual connection between editor and canvas block
- [ ] Implement mode switching logic

#### Phase 4: Cross-References (2-3 weeks)
- [ ] Implement CanvasReference system
- [ ] Add canvas object picker for references
- [ ] Create visual indicators for references
- [ ] Implement navigation between canvas and documents
- [ ] Add reference management UI

#### Phase 5: Advanced Features (3-4 weeks)
- [ ] Standalone document viewing/editing
- [ ] Document templates and presets
- [ ] Advanced block types (tables, embeds, etc.)
- [ ] Document search and organization
- [ ] Export/import functionality

#### Phase 6: Polish & Performance (2-3 weeks)
- [ ] Performance optimization for large documents
- [ ] Enhanced UI/UX polish
- [ ] Keyboard shortcuts and accessibility
- [ ] Error handling and recovery
- [ ] Documentation and testing

### Key Benefits of This Architecture

1. **Seamless Integration**: Builds upon your existing canvas architecture
2. **Spatial Awareness**: Users can reference canvas elements while editing
3. **Flexible Editing**: Multiple editing modes (overlay, split, standalone)
4. **Auto-Save**: Documents are automatically saved as separate files
5. **Cross-References**: Rich linking between canvas and document content
6. **Scalable**: Can handle complex documents with many blocks
7. **Extensible**: Easy to add new block types and features

### Technical Considerations

1. **Performance**: Use virtual scrolling for large documents
2. **Memory**: Implement lazy loading for document content
3. **Sync**: Ensure canvas and document state stay synchronized
4. **Persistence**: Robust auto-save with conflict resolution
5. **UX**: Smooth transitions between editing modes
6. **Accessibility**: Full keyboard navigation and screen reader support

This architecture provides a solid foundation for creating a powerful hybrid canvas-document editing experience that combines the spatial freedom of canvas tools with the structured editing capabilities of Notion-style documents.
