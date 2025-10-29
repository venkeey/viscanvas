# Hybrid Canvas-Document Architecture Discussion
## Notion-Style Block Editing in Infinite Canvas

**Date**: 2025-10-11  
**Status**: Architecture Review Complete  
**Version**: 1.0

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Analysis](#system-analysis)
3. [Architecture Gaps](#architecture-gaps)
4. [Revised Architecture](#revised-architecture)
5. [UX Failure Points](#ux-failure-points)
6. [Implementation Strategy](#implementation-strategy)
7. [Technical Specifications](#technical-specifications)
8. [File Structure](#file-structure)
9. [Key Decisions](#key-decisions)
10. [Success Criteria](#success-criteria)

---

## 📊 Executive Summary

### Objective
Create a hybrid canvas-document editing system where users can place Notion-style document blocks on an infinite canvas, edit documents in floating/split views while panning the canvas, with cross-references between canvas objects and document content.

### Current State
- **Canvas System**: Robust implementation with spatial indexing, event sourcing, persistence ✅
- **Notion Clone**: Comprehensive wireframe with block specs and UI/UX design ✅
- **Integration**: **ZERO integration between systems** 🚨

### Critical Findings
1. No integration bridge between canvas and Notion systems
2. DocumentBlock class not implemented
3. Hybrid editing modes not architected
4. Cross-reference system missing
5. Document persistence architecture incomplete
6. State synchronization not designed

---

## 🔍 System Analysis

### Existing Canvas System (✅ Excellent)

**Location**: `C:/code/misc/viscanvas/lib/pages/drawingCanvas.dart` (3,719 lines)

**Architecture Layers**:
```
Domain Layer      → Business logic (CanvasObject, Events)
Application Layer → Use cases, Commands (Undo/Redo)
Infrastructure    → Rendering, Storage
Presentation      → UI Components
```

**Key Components**:

1. **Spatial Indexing**: QuadTree implementation
   - Capacity: 4 objects per node
   - Max depth: 8 levels
   - Query performance: O(log n)
   - Hit testing: O(log n)

2. **Transform System**: Matrix4-based
   - Pan: Translation offset
   - Zoom: Scale factor (0.1-10.0)
   - Screen-to-world coordinate conversion

3. **Event Sourcing**:
   - Command pattern for undo/redo
   - History stack: 100 commands
   - Events: ObjectCreated, ObjectModified, ObjectDeleted

4. **Persistence**:
   - Auto-save: Every 30 seconds
   - Format: JSON with version field
   - Storage: JSON files with `.canvas.json` extension
   - Web storage simulation for web builds

5. **Object Types**:
   - FreehandPath: Stroke-based drawing
   - CanvasRectangle: Rectangle shapes
   - CanvasCircle: Circle shapes
   - StickyNote: Text notes with background
   - Connector: Smart curved connections

6. **Advanced Features**:
   - Smart anchor points for connections
   - S-curve and C-curve connectors
   - Freehand-to-connector conversion
   - Magnetic connection points

### Existing Notion Clone System (✅ Well-Designed)

**Location**: `c:/code/misc/misc/visdev/notion_clone_flutter`

**Specifications**:

1. **Block Types** (25+ types):
   - Text: paragraph, heading_1, heading_2, heading_3
   - Lists: bulleted_list_item, numbered_list_item, to_do, toggle
   - Media: image, video, file, pdf, embed, bookmark
   - Layout: column_list, column, table, table_row, divider
   - Special: code, quote, callout, table_of_contents, breadcrumb
   - References: link_to_page, child_page, child_database, synced_block

2. **Property Types** (18 types):
   - Basic: title, rich_text, number, checkbox, url, email, phone_number
   - Selection: select, multi_select, status
   - Relationships: people, files, relation, rollup
   - Computed: formula, created_time, created_by, last_edited_time, last_edited_by
   - ID: unique_id

3. **UI/UX Design Tokens**:
   - Typography: Inter font family, 7 size scales
   - Colors: 10-level neutral + primary (indigo) + accent (teal)
   - Spacing: 13-level scale (0-64px)
   - Radii: 4 levels (sm, md, lg, xl)
   - Shadows: 2 levels + focus ring
   - Breakpoints: 6 responsive levels

4. **Current Implementation**:
   - Router: go_router with shell route
   - Theme: Light/dark mode with tokens
   - Views: PageEditor, DatabaseTable, BoardView, Sidebar

---

## ⚠️ Architecture Gaps

### Gap 1: No Integration Bridge 🚨 **CRITICAL**

**Problem**: Canvas and Notion systems exist independently with zero communication.

**Missing Components**:
- Bridge service to coordinate between systems
- Event propagation mechanism
- Shared state synchronization
- Lifecycle management

**Impact**: 
- Cannot place documents on canvas
- Cannot reference canvas objects from documents
- No unified user experience

### Gap 2: DocumentBlock Implementation Missing 🚨 **CRITICAL**

**Problem**: No canvas object type for documents.

**Missing Components**:
```dart
class DocumentBlock extends CanvasObject {
  final String documentId;
  final DocumentContent content;
  final DocumentViewMode mode; // collapsed/preview/expanded
  final List<CanvasReference> canvasRefs;
  
  @override
  void draw(Canvas canvas, Matrix4 transform) {
    // MISSING: Document rendering logic
  }
  
  @override
  bool hitTest(Offset worldPoint) {
    // MISSING: Hit detection for document interactions
  }
}
```

**Impact**:
- Core feature non-functional
- No visual representation of documents on canvas

### Gap 3: Hybrid Editing Modes Not Architected 🚨 **CRITICAL**

**Problem**: No design for simultaneous canvas navigation + document editing.

**Missing Components**:
- Mode state machine
- Gesture conflict resolution
- Input routing logic
- Visual mode indicators

**Required Modes**:
1. **Canvas Only**: Pure canvas interaction
2. **Document Only**: Full-screen document editing
3. **Overlay**: Floating document editor over canvas
4. **Split View**: Side-by-side canvas and document
5. **Hybrid**: Edit document + pan canvas simultaneously

**Impact**:
- Users cannot reference canvas while editing
- Poor user experience
- Gesture conflicts

### Gap 4: Cross-Reference System Missing 🚨 **CRITICAL**

**Problem**: No linking between canvas objects and document blocks.

**Missing Components**:
```dart
class CanvasReference {
  final String id;
  final String canvasObjectId;
  final String documentBlockId;
  final ReferenceType type; // mention, embed, link
  final Offset? position;
  
  // MISSING: Navigation methods
  void navigateToCanvas();
  void navigateToDocument();
  
  // MISSING: Validation
  bool isValid();
  void resolveReference();
}
```

**Impact**:
- No semantic connections between spatial and structured content
- Cannot navigate between canvas and documents
- References can become stale/broken

### Gap 5: Document Persistence Architecture Incomplete 🚨 **CRITICAL**

**Problem**: Canvas has persistence, but documents don't have separate storage.

**Current State**:
- Canvas: Auto-save every 30s to JSON files ✅
- Documents: No persistence mechanism ❌

**Missing Components**:
- Document serialization/deserialization
- Separate file storage for documents
- Reference tracking in canvas metadata
- Thumbnail generation for previews
- Version control for documents

**Required File Structure**:
```
/storage/
  canvas_metadata.json        # Canvas state + document refs
  /documents/
    doc_abc123.json          # Individual documents
    doc_def456.json
  /thumbnails/
    doc_abc123.png           # For canvas previews
```

**Impact**:
- Documents not saved
- Data loss on restart
- Cannot share documents independently

### Gap 6: State Synchronization Not Designed 🚨 **CRITICAL**

**Problem**: No mechanism to keep canvas and document states in sync.

**Scenarios Requiring Sync**:
1. Document edited → Canvas preview updates
2. Document deleted → Canvas block updates
3. Canvas object moved → Document references update
4. Undo/redo across systems

**Missing Components**:
- Event bus or observer pattern
- State diff computation
- Conflict resolution strategy
- Transaction coordinator

**Impact**:
- Stale UI state
- Data inconsistencies
- Broken undo/redo

### Gap 7: Performance Optimizations Missing ⚠️ **HIGH**

**Problem**: No design for rendering many documents on canvas.

**Scenarios**:
- 100+ document blocks on canvas
- Large documents (1000+ blocks)
- Zooming in/out frequently
- Panning across large canvases

**Missing Components**:
- Level-of-detail (LOD) rendering
- Document virtualization
- Lazy loading strategy
- Thumbnail caching
- Render priority queue

**Impact**:
- Frame drops below 60 FPS
- High memory usage
- Poor user experience

### Gap 8: Event Handling Conflicts ⚠️ **HIGH**

**Problem**: Gesture ambiguity between canvas and document interactions.

**Conflict Scenarios**:
1. **Pan vs Text Selection**: Single-finger drag
2. **Zoom vs Font Size**: Pinch gesture
3. **Click vs Edit**: Tap on document
4. **Context Menu**: Long press

**Missing Components**:
- Gesture priority system
- Input mode state machine
- Conflict resolution rules
- User preference settings

**Impact**:
- Frustrating user experience
- Unintended actions
- Accessibility issues

---

## 🏗️ Revised Architecture

### Layer 1: Integration Bridge

**Purpose**: Coordinate communication between canvas and document systems.

```dart
class HybridCanvasDocumentBridge extends ChangeNotifier {
  final CanvasService canvasService;
  final DocumentService documentService;
  final CrossReferenceManager refManager;
  final HybridViewController modeController;
  
  HybridCanvasDocumentBridge({
    required this.canvasService,
    required this.documentService,
    required this.refManager,
    required this.modeController,
  }) {
    // Setup bidirectional listeners
    canvasService.addListener(_onCanvasChange);
    documentService.addListener(_onDocumentChange);
  }
  
  // Canvas → Document communication
  void _onCanvasChange() {
    if (canvasService.hasDocumentBlockChanges) {
      documentService.syncFromCanvas(canvasService.changedDocuments);
    }
  }
  
  // Document → Canvas communication
  void _onDocumentChange() {
    if (documentService.isDirty) {
      canvasService.updateDocumentPreviews(documentService.changedDocuments);
    }
  }
  
  // User actions
  void openDocumentEditor(String documentId) {
    modeController.enterHybridMode(documentId);
    documentService.loadDocument(documentId);
  }
  
  void closeDocumentEditor() {
    documentService.saveCurrentDocument();
    modeController.exitHybridMode();
  }
  
  // Cross-reference management
  void createReference(String canvasObjectId, String documentBlockId) {
    final ref = refManager.create(canvasObjectId, documentBlockId);
    documentService.addReference(ref);
    canvasService.addReference(ref);
  }
  
  void navigateToReference(CanvasReference ref) {
    if (ref.type == ReferenceType.canvas) {
      modeController.enterCanvasMode();
      canvasService.panToObject(ref.canvasObjectId);
      canvasService.highlightObject(ref.canvasObjectId);
    } else {
      modeController.enterDocumentMode(ref.documentBlockId);
      documentService.scrollToBlock(ref.documentBlockId);
    }
  }
  
  @override
  void dispose() {
    canvasService.removeListener(_onCanvasChange);
    documentService.removeListener(_onDocumentChange);
    super.dispose();
  }
}
```

### Layer 2: Enhanced Data Models

#### DocumentBlock (Extends CanvasObject)

```dart
class DocumentBlock extends CanvasObject {
  final String documentId;
  DocumentContent content;
  DocumentViewMode viewMode;
  final List<CanvasReference> canvasReferences;
  
  // Canvas-specific properties
  Size size;
  bool isExpanded;
  bool isEditing;
  DocumentBlockStyle style;
  
  // Cached rendering
  ui.Image? _cachedThumbnail;
  Path? _cachedPath;
  
  DocumentBlock({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    required this.documentId,
    required this.content,
    this.viewMode = DocumentViewMode.preview,
    this.canvasReferences = const [],
    this.size = const Size(400, 300),
    this.isExpanded = false,
    this.isEditing = false,
    this.style = const DocumentBlockStyle(),
  });
  
  @override
  Rect calculateBoundingRect() {
    return Rect.fromLTWH(
      worldPosition.dx,
      worldPosition.dy,
      size.width,
      size.height,
    );
  }
  
  @override
  bool hitTest(Offset worldPoint) {
    return getBoundingRect().contains(worldPoint);
  }
  
  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = getBoundingRect();
    
    switch (viewMode) {
      case DocumentViewMode.collapsed:
        _drawCollapsed(canvas, rect, worldToScreen);
        break;
      case DocumentViewMode.preview:
        _drawPreview(canvas, rect, worldToScreen);
        break;
      case DocumentViewMode.expanded:
        _drawExpanded(canvas, rect, worldToScreen);
        break;
    }
    
    if (isEditing) {
      _drawEditingIndicator(canvas, rect);
    }
  }
  
  void _drawCollapsed(Canvas canvas, Rect rect, Matrix4 transform) {
    // Draw icon + title only
    final paint = Paint()
      ..color = style.backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      paint,
    );
    
    // Draw title
    final title = content.getTitle() ?? 'Untitled';
    final textPainter = TextPainter(
      text: TextSpan(text: title, style: style.titleStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: rect.width - 32);
    textPainter.paint(canvas, rect.topLeft + Offset(16, 16));
  }
  
  void _drawPreview(Canvas canvas, Rect rect, Matrix4 transform) {
    // Draw thumbnail if available, otherwise render first few blocks
    if (_cachedThumbnail != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: _cachedThumbnail!,
        fit: BoxFit.cover,
      );
    } else {
      _drawExpanded(canvas, rect, transform, maxBlocks: 3);
    }
  }
  
  void _drawExpanded(Canvas canvas, Rect rect, Matrix4 transform, {int? maxBlocks}) {
    // Render actual document blocks
    final blocksToRender = maxBlocks != null
        ? content.blocks.take(maxBlocks).toList()
        : content.blocks;
    
    double offsetY = rect.top + 16;
    
    for (final block in blocksToRender) {
      final blockWidget = block.render();
      // TODO: Render Flutter widget to canvas
      offsetY += block.getHeight();
      
      if (offsetY > rect.bottom) break;
    }
  }
  
  void _drawEditingIndicator(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      paint,
    );
  }
  
  @override
  void move(Offset delta) {
    worldPosition += delta;
    invalidateCache();
  }
  
  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    // Resize document block
    double newWidth = initialBounds.width;
    double newHeight = initialBounds.height;
    
    switch (handle) {
      case ResizeHandle.bottomRight:
        newWidth += delta.dx;
        newHeight += delta.dy;
        break;
      // Handle other resize cases...
    }
    
    size = Size(
      max(200.0, newWidth),
      max(150.0, newHeight),
    );
    invalidateCache();
  }
  
  @override
  CanvasObject clone() {
    return DocumentBlock(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      documentId: documentId,
      content: content, // Shallow copy
      viewMode: viewMode,
      canvasReferences: List.from(canvasReferences),
      size: size,
      style: style,
    );
  }
  
  // Document-specific methods
  void enterEditMode() {
    isEditing = true;
    viewMode = DocumentViewMode.expanded;
  }
  
  void exitEditMode() {
    isEditing = false;
    viewMode = DocumentViewMode.preview;
  }
  
  void toggleExpanded() {
    isExpanded = !isExpanded;
    viewMode = isExpanded 
        ? DocumentViewMode.expanded 
        : DocumentViewMode.preview;
  }
  
  void addCanvasReference(CanvasObject object) {
    final ref = CanvasReference(
      id: generateUuid(),
      canvasObjectId: object.id,
      documentBlockId: documentId,
      type: ReferenceType.mention,
    );
    canvasReferences.add(ref);
  }
  
  void invalidateThumbnail() {
    _cachedThumbnail = null;
  }
}

enum DocumentViewMode {
  collapsed,  // Icon + title only
  preview,    // Thumbnail or first few blocks
  expanded,   // Full document rendering
}

class DocumentBlockStyle {
  final Color backgroundColor;
  final TextStyle titleStyle;
  final double borderRadius;
  final double padding;
  
  const DocumentBlockStyle({
    this.backgroundColor = Colors.white,
    this.titleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    this.borderRadius = 8.0,
    this.padding = 16.0,
  });
}
```

#### DocumentContent (Notion Blocks)

```dart
class DocumentContent {
  final String id;
  final List<Block> blocks;
  final Map<String, Block> _blockMap;
  final BlockHierarchy hierarchy;
  
  bool isDirty;
  DateTime lastModified;
  int version;
  
  DocumentContent({
    required this.id,
    required this.blocks,
    required this.hierarchy,
    this.isDirty = false,
    DateTime? lastModified,
    this.version = 1,
  }) : _blockMap = {for (var block in blocks) block.id: block},
       lastModified = lastModified ?? DateTime.now();
  
  // Block operations
  void addBlock(Block block, {String? parentId, int? index}) {
    blocks.insert(index ?? blocks.length, block);
    _blockMap[block.id] = block;
    hierarchy.addBlock(block, parentId: parentId);
    markDirty();
  }
  
  void removeBlock(String blockId) {
    final block = _blockMap[blockId];
    if (block != null) {
      blocks.remove(block);
      _blockMap.remove(blockId);
      hierarchy.removeBlock(blockId);
      markDirty();
    }
  }
  
  void updateBlock(String blockId, Map<String, dynamic> changes) {
    final block = _blockMap[blockId];
    if (block != null) {
      block.update(changes);
      markDirty();
    }
  }
  
  void moveBlock(String blockId, String newParentId, int newIndex) {
    final block = _blockMap[blockId];
    if (block != null) {
      blocks.remove(block);
      blocks.insert(newIndex, block);
      hierarchy.moveBlock(blockId, newParentId, newIndex);
      markDirty();
    }
  }
  
  // Query methods
  Block? getBlock(String blockId) => _blockMap[blockId];
  
  String? getTitle() {
    final titleBlock = blocks.firstWhere(
      (b) => b.type == BlockType.heading1 || b.type == BlockType.paragraph,
      orElse: () => null as Block,
    );
    return titleBlock?.getPlainText();
  }
  
  List<CanvasReference> extractReferences() {
    final refs = <CanvasReference>[];
    for (final block in blocks) {
      refs.addAll(block.extractReferences());
    }
    return refs;
  }
  
  // State management
  void markDirty() {
    isDirty = true;
    lastModified = DateTime.now();
    version++;
  }
  
  void markClean() {
    isDirty = false;
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'lastModified': lastModified.toIso8601String(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'hierarchy': hierarchy.toJson(),
    };
  }
  
  factory DocumentContent.fromJson(Map<String, dynamic> json) {
    final blocks = (json['blocks'] as List)
        .map((b) => Block.fromJson(b))
        .toList();
    
    return DocumentContent(
      id: json['id'],
      blocks: blocks,
      hierarchy: BlockHierarchy.fromJson(json['hierarchy']),
      version: json['version'] ?? 1,
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}
```

#### CanvasReference (Cross-linking)

```dart
class CanvasReference {
  final String id;
  final String canvasObjectId;
  final String documentBlockId;
  final ReferenceType type;
  final Offset? position;
  final String? label;
  final DateTime createdAt;
  
  bool _isValid;
  
  CanvasReference({
    required this.id,
    required this.canvasObjectId,
    required this.documentBlockId,
    required this.type,
    this.position,
    this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       _isValid = true;
  
  bool get isValid => _isValid;
  
  void markInvalid() {
    _isValid = false;
  }
  
  // Navigation methods (to be implemented by services)
  void navigateToCanvas(CanvasService service) {
    service.panToObject(canvasObjectId);
    service.highlightObject(canvasObjectId, duration: Duration(seconds: 2));
  }
  
  void navigateToDocument(DocumentService service) {
    service.scrollToBlock(documentBlockId);
    service.highlightBlock(documentBlockId, duration: Duration(seconds: 2));
  }
  
  // Validation
  bool validate(CanvasRepository canvasRepo, DocumentRepository docRepo) {
    final canvasObject = canvasRepo.getById(canvasObjectId);
    final docBlock = docRepo.getBlock(documentBlockId);
    
    _isValid = canvasObject != null && docBlock != null;
    return _isValid;
  }
  
  // Visual representation
  Widget buildCanvasIndicator() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getTypeIcon(),
        size: 16,
        color: _getTypeColor(),
      ),
    );
  }
  
  Widget buildDocumentLink() {
    return InkWell(
      onTap: () {
        // Navigate to canvas object
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getTypeColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _getTypeColor()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTypeIcon(), size: 16, color: _getTypeColor()),
            SizedBox(width: 4),
            Text(
              label ?? 'Canvas Object',
              style: TextStyle(color: _getTypeColor()),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTypeColor() {
    switch (type) {
      case ReferenceType.mention:
        return Colors.blue;
      case ReferenceType.embed:
        return Colors.purple;
      case ReferenceType.link:
        return Colors.green;
    }
  }
  
  IconData _getTypeIcon() {
    switch (type) {
      case ReferenceType.mention:
        return Icons.alternate_email;
      case ReferenceType.embed:
        return Icons.insert_photo;
      case ReferenceType.link:
        return Icons.link;
    }
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canvasObjectId': canvasObjectId,
      'documentBlockId': documentBlockId,
      'type': type.toString(),
      'position': position != null
          ? {'dx': position!.dx, 'dy': position!.dy}
          : null,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory CanvasReference.fromJson(Map<String, dynamic> json) {
    return CanvasReference(
      id: json['id'],
      canvasObjectId: json['canvasObjectId'],
      documentBlockId: json['documentBlockId'],
      type: ReferenceType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
      position: json['position'] != null
          ? Offset(json['position']['dx'], json['position']['dy'])
          : null,
      label: json['label'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum ReferenceType {
  mention,  // @canvas-object in document
  embed,    // Embed canvas object visual in document
  link,     // Hyperlink to canvas object
}
```

### Layer 3: Hybrid View State Machine

```dart
enum HybridMode {
  canvasOnly,      // Pure canvas interaction
  documentOnly,    // Full-screen document editing
  overlay,         // Document floats over canvas
  splitView,       // Side-by-side canvas and document
  hybrid,          // Document editing + canvas panning (two-finger)
}

class HybridViewController extends ChangeNotifier {
  HybridMode _currentMode;
  String? _activeDocumentId;
  DocumentBlock? _activeDocumentBlock;
  
  // Gesture state
  bool _canPanCanvas;
  bool _canEditDocument;
  int _fingerCount;
  
  HybridViewController({
    HybridMode initialMode = HybridMode.canvasOnly,
  }) : _currentMode = initialMode,
       _canPanCanvas = true,
       _canEditDocument = false,
       _fingerCount = 0;
  
  // Getters
  HybridMode get currentMode => _currentMode;
  String? get activeDocumentId => _activeDocumentId;
  bool get canPanCanvas => _canPanCanvas;
  bool get canEditDocument => _canEditDocument;
  bool get isHybridMode => _currentMode == HybridMode.hybrid;
  
  // Mode transitions
  void enterCanvasMode() {
    _currentMode = HybridMode.canvasOnly;
    _activeDocumentId = null;
    _activeDocumentBlock = null;
    _canPanCanvas = true;
    _canEditDocument = false;
    notifyListeners();
  }
  
  void enterDocumentMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.documentOnly;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = false;
    _canEditDocument = true;
    notifyListeners();
  }
  
  void enterOverlayMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.overlay;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = true;
    _canEditDocument = true;
    notifyListeners();
  }
  
  void enterSplitView(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.splitView;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = true;
    _canEditDocument = true;
    notifyListeners();
  }
  
  void enterHybridMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.hybrid;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = false; // Will be enabled with two-finger gesture
    _canEditDocument = true;
    notifyListeners();
  }
  
  void exitHybridMode() {
    enterCanvasMode();
  }
  
  // Gesture handling
  void handleGesture(GestureType type, {int fingerCount = 1}) {
    _fingerCount = fingerCount;
    
    switch (_currentMode) {
      case HybridMode.canvasOnly:
        _canPanCanvas = true;
        _canEditDocument = false;
        break;
        
      case HybridMode.documentOnly:
        _canPanCanvas = false;
        _canEditDocument = true;
        break;
        
      case HybridMode.overlay:
        _canPanCanvas = type != GestureType.tap;
        _canEditDocument = true;
        break;
        
      case HybridMode.splitView:
        _canPanCanvas = true;
        _canEditDocument = true;
        break;
        
      case HybridMode.hybrid:
        // Two-finger pan for canvas, one-finger for document
        _canPanCanvas = fingerCount >= 2;
        _canEditDocument = fingerCount == 1;
        break;
    }
    
    notifyListeners();
  }
  
  // Keyboard shortcuts
  void handleKeyPress(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      if (_currentMode != HybridMode.canvasOnly) {
        exitHybridMode();
      }
    } else if (key == LogicalKeyboardKey.space && _currentMode == HybridMode.hybrid) {
      // Hold space to enable canvas pan
      _canPanCanvas = true;
      notifyListeners();
    }
  }
  
  void handleKeyRelease(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space && _currentMode == HybridMode.hybrid) {
      _canPanCanvas = false;
      notifyListeners();
    }
  }
}

enum GestureType {
  tap,
  pan,
  pinch,
  longPress,
}
```

---

## 🎯 UX Failure Points & Mitigations

### Failure Point 1: Mode Confusion 🚨

**Problem**: Users don't know what mode they're in or what actions are available.

**Symptoms**:
- Unexpected behavior when tapping/dragging
- Cannot find edit button
- Confusion about pan vs edit gestures

**Mitigation Strategy**:

1. **Visual Indicators**:
   - Mode badge in corner of screen
   - Color-coded borders (blue = document, green = canvas)
   - Cursor changes (hand for pan, I-beam for edit)
   - Glow effect on active mode

2. **UI Feedback**:
   ```dart
   Widget buildModeIndicator() {
     return AnimatedContainer(
       duration: Duration(milliseconds: 200),
       padding: EdgeInsets.all(8),
       decoration: BoxDecoration(
         color: _getModeColor().withOpacity(0.9),
         borderRadius: BorderRadius.circular(8),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(_getModeIcon(), color: Colors.white),
           SizedBox(width: 4),
           Text(_getModeLabel(), style: TextStyle(color: Colors.white)),
         ],
       ),
     );
   }
   ```

3. **Keyboard Shortcuts**:
   - `Esc`: Exit current mode → Canvas mode
   - `Space`: Hold to temporarily enable canvas pan
   - `E`: Enter document edit mode
   - `C`: Return to canvas mode

4. **Tutorial Overlay** (first time):
   - Show mode indicators
   - Explain gestures
   - Interactive walkthrough

**Success Metric**: <5% mode-related support tickets

### Failure Point 2: Gesture Conflicts 🚨

**Problem**: Pan gesture conflicts with text selection and scrolling.

**Conflict Matrix**:
| Gesture | Canvas Mode | Document Mode | Hybrid Mode |
|---------|-------------|---------------|-------------|
| One-finger drag | Pan canvas | Select text | Edit document |
| Two-finger drag | Pan canvas | Scroll doc | Pan canvas |
| Pinch | Zoom canvas | Zoom doc | Zoom canvas |
| Tap | Select object | Edit block | Edit block |
| Long press | Context menu | Context menu | Context menu |

**Mitigation Strategy**:

1. **Gesture Resolver**:
   ```dart
   class GestureResolver {
     HybridViewController modeController;
     
     GestureType resolveGesture(PointerEvent event) {
       final fingerCount = event.pointerCount;
       
       if (modeController.currentMode == HybridMode.hybrid) {
         // In hybrid mode, two-finger = canvas, one-finger = document
         if (fingerCount >= 2) {
           return GestureType.canvasPan;
         } else {
           return GestureType.documentEdit;
         }
       }
       
       // In other modes, follow standard rules
       return _standardGestureResolution(event);
     }
   }
   ```

2. **Spacebar Pan** (like Figma):
   - Hold spacebar → Enable canvas pan in any mode
   - Release spacebar → Return to previous mode

3. **User Preferences**:
   - Toggle: "Two-finger pan in hybrid mode" (default: ON)
   - Toggle: "Spacebar to pan" (default: ON)
   - Custom gesture mapping

**Success Metric**: <3% gesture-related complaints

### Failure Point 3: Performance Degradation 🚨

**Problem**: Many documents on canvas cause lag.

**Scenarios**:
- 100+ document blocks on canvas
- Documents with 500+ blocks
- Zooming in/out frequently
- Panning quickly across large canvas

**Performance Targets**:
- 60 FPS (16ms per frame)
- <500ms to load document
- <100ms to switch modes

**Mitigation Strategy**:

1. **Level-of-Detail (LOD) Rendering**:
   ```dart
   void renderDocumentBlock(Canvas canvas, DocumentBlock block, double scale) {
     if (scale < 0.3) {
       // Zoomed out: Show icon only
       _drawIcon(canvas, block);
     } else if (scale < 0.7) {
       // Medium zoom: Show thumbnail
       _drawThumbnail(canvas, block);
     } else {
       // Zoomed in: Render full content
       _drawFullDocument(canvas, block);
     }
   }
   ```

2. **Lazy Loading**:
   - Only load documents in viewport
   - Unload documents outside viewport + 500px margin
   - Pre-cache adjacent documents

3. **Virtualization**:
   - For large documents, only render visible blocks
   - Use Flutter's `ListView.builder` for block lists
   - Recycle block widgets

4. **Thumbnail Caching**:
   ```dart
   class DocumentThumbnailService {
     final Map<String, ui.Image> _cache = {};
     
     Future<ui.Image> getThumbnail(String documentId) async {
       if (_cache.containsKey(documentId)) {
         return _cache[documentId]!;
       }
       
       final thumbnail = await _generateThumbnail(documentId);
       _cache[documentId] = thumbnail;
       return thumbnail;
     }
     
     Future<ui.Image> _generateThumbnail(String documentId) async {
       // Render document to image
       final recorder = ui.PictureRecorder();
       final canvas = Canvas(recorder);
       // ... render document ...
       final picture = recorder.endRecording();
       return picture.toImage(400, 300);
     }
   }
   ```

5. **Render Priority Queue**:
   - High priority: Documents in viewport
   - Medium priority: Documents in edit mode
   - Low priority: Background documents

**Success Metric**: 60 FPS with 100 documents

### Failure Point 4: State Desynchronization 🚨

**Problem**: Changes in document not reflected on canvas, and vice versa.

**Scenarios**:
- Edit document → Canvas preview stale
- Delete canvas object → Document reference broken
- Undo in document → Canvas state inconsistent
- Concurrent edits

**Mitigation Strategy**:

1. **Event Sourcing**:
   ```dart
   abstract class HybridEvent {
     final DateTime timestamp;
     HybridEvent() : timestamp = DateTime.now();
   }
   
   class DocumentChangedEvent extends HybridEvent {
     final String documentId;
     final List<BlockChange> changes;
     DocumentChangedEvent(this.documentId, this.changes);
   }
   
   class CanvasObjectChangedEvent extends HybridEvent {
     final String objectId;
     final Map<String, dynamic> changes;
     CanvasObjectChangedEvent(this.objectId, this.changes);
   }
   ```

2. **Event Bus**:
   ```dart
   class HybridEventBus {
     final StreamController<HybridEvent> _controller;
     
     Stream<HybridEvent> get events => _controller.stream;
     
     void emit(HybridEvent event) {
       _controller.add(event);
     }
   }
   
   // Usage
   eventBus.events.listen((event) {
     if (event is DocumentChangedEvent) {
       canvasService.updateDocumentPreview(event.documentId);
     }
   });
   ```

3. **Debounced Updates**:
   ```dart
   Timer? _updateTimer;
   
   void onDocumentChanged() {
     _updateTimer?.cancel();
     _updateTimer = Timer(Duration(milliseconds: 16), () {
       canvasService.refreshDocumentPreviews();
     });
   }
   ```

4. **Version Conflicts**:
   ```dart
   class VersionConflictResolver {
     ConflictResolution resolve(DocumentContent local, DocumentContent remote) {
       if (local.version == remote.version) {
         return ConflictResolution.noConflict;
       }
       
       // Last-write-wins with user notification
       if (local.lastModified.isAfter(remote.lastModified)) {
         return ConflictResolution(
           resolution: ResolutionType.keepLocal,
           message: 'Your changes are newer. Keeping local version.',
         );
       } else {
         return ConflictResolution(
           resolution: ResolutionType.showDialog,
           message: 'Conflict detected. Choose version to keep.',
           localVersion: local,
           remoteVersion: remote,
         );
       }
     }
   }
   ```

**Success Metric**: <1% state sync errors

### Failure Point 5: Reference Integrity 🚨

**Problem**: Deleted/moved canvas objects break document references.

**Scenarios**:
- Delete canvas object → References become orphaned
- Move canvas object → Position-based references invalid
- Rename canvas object → Label-based references stale

**Mitigation Strategy**:

1. **Reference Validation**:
   ```dart
   class ReferenceValidator {
     bool validateReferences(DocumentContent doc, CanvasRepository canvasRepo) {
       final refs = doc.extractReferences();
       bool allValid = true;
       
       for (final ref in refs) {
         final canvasObj = canvasRepo.getById(ref.canvasObjectId);
         if (canvasObj == null) {
           ref.markInvalid();
           allValid = false;
         }
       }
       
       return allValid;
     }
   }
   ```

2. **Cascade Delete with Confirmation**:
   ```dart
   Future<bool> deleteCanvasObject(String objectId) async {
     final referencingDocs = findDocsReferencingObject(objectId);
     
     if (referencingDocs.isNotEmpty) {
       final confirmed = await showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
           title: Text('Delete Object?'),
           content: Text(
             'This object is referenced in ${referencingDocs.length} documents. '
             'References will be marked as broken.',
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context, false),
               child: Text('Cancel'),
             ),
             ElevatedButton(
               onPressed: () => Navigator.pop(context, true),
               child: Text('Delete Anyway'),
             ),
           ],
         ),
       );
       
       if (confirmed != true) return false;
     }
     
     // Delete and invalidate references
     canvasRepository.remove(objectId);
     for (final doc in referencingDocs) {
       doc.invalidateReferences(objectId);
     }
     
     return true;
   }
   ```

3. **Visual Indicators for Broken References**:
   ```dart
   Widget buildReference(CanvasReference ref) {
     if (!ref.isValid) {
       return Container(
         padding: EdgeInsets.all(4),
         decoration: BoxDecoration(
           color: Colors.red.withOpacity(0.1),
           border: Border.all(color: Colors.red),
           borderRadius: BorderRadius.circular(4),
         ),
         child: Row(
           children: [
             Icon(Icons.broken_image, color: Colors.red, size: 16),
             Text('Broken reference', style: TextStyle(color: Colors.red)),
           ],
         ),
       );
     }
     
     return ref.buildDocumentLink();
   }
   ```

4. **Reference Repair Tool**:
   - Scan all documents for broken references
   - Attempt to resolve by object name matching
   - Allow user to manually re-link

**Success Metric**: <1% broken references

### Failure Point 6: Auto-save Conflicts 🚨

**Problem**: Canvas auto-save (30s) and document auto-save can conflict.

**Scenarios**:
- Both save simultaneously → File corruption
- App crash during save → Partial data loss
- Network/disk error during save → Data loss

**Mitigation Strategy**:

1. **Separate Save Timers**:
   ```dart
   class AutoSaveCoordinator {
     Timer? _canvasTimer;
     Timer? _documentTimer;
     
     void start() {
       // Canvas: Save every 30 seconds
       _canvasTimer = Timer.periodic(Duration(seconds: 30), (_) {
         _saveCanvas();
       });
       
       // Documents: Save every 10 seconds (more frequent)
       _documentTimer = Timer.periodic(Duration(seconds: 10), (_) {
         _saveDocuments();
       });
     }
   }
   ```

2. **Write-Ahead Logging (WAL)**:
   ```dart
   class WriteAheadLog {
     final File _logFile;
     
     void logChange(String operation, Map<String, dynamic> data) {
       final entry = {
         'timestamp': DateTime.now().toIso8601String(),
         'operation': operation,
         'data': data,
       };
       
       _logFile.writeAsStringSync(
         jsonEncode(entry) + '\n',
         mode: FileMode.append,
       );
     }
     
     Future<void> replay() async {
       final lines = await _logFile.readAsLines();
       for (final line in lines) {
         final entry = jsonDecode(line);
         _applyOperation(entry['operation'], entry['data']);
       }
     }
   }
   ```

3. **Atomic File Writes**:
   ```dart
   Future<void> saveDocument(DocumentContent doc) async {
     final tempFile = File('${doc.id}.tmp.json');
     final targetFile = File('${doc.id}.json');
     
     try {
       // Write to temp file
       await tempFile.writeAsString(jsonEncode(doc.toJson()));
       
       // Atomic rename
       await tempFile.rename(targetFile.path);
       
       doc.markClean();
     } catch (e) {
       // Cleanup temp file on error
       if (await tempFile.exists()) {
         await tempFile.delete();
       }
       rethrow;
     }
   }
   ```

4. **Crash Recovery**:
   ```dart
   Future<void> recoverFromCrash() async {
     // Check for write-ahead log
     if (await walFile.exists()) {
       await wal.replay();
       await walFile.delete();
     }
     
     // Check for temp files (incomplete saves)
     final tempFiles = Directory('documents')
         .listSync()
         .where((f) => f.path.endsWith('.tmp.json'));
     
     for (final tempFile in tempFiles) {
       // Restore from temp if newer than target
       final targetPath = tempFile.path.replaceAll('.tmp', '');
       final targetFile = File(targetPath);
       
       if (!await targetFile.exists() || 
           (await tempFile.stat()).modified.isAfter((await targetFile.stat()).modified)) {
         await tempFile.rename(targetPath);
       } else {
         await tempFile.delete();
       }
     }
   }
   ```

**Success Metric**: Zero data loss on crash

### Failure Point 7: Memory Leaks 🚨

**Problem**: Document editors not disposed, leading to memory growth.

**Scenarios**:
- Rapidly open/close many documents
- Long session with many mode switches
- Large documents not garbage collected

**Mitigation Strategy**:

1. **Weak References**:
   ```dart
   class DocumentBlockController {
     final WeakReference<DocumentContent> _content;
     
     DocumentBlockController(DocumentContent content)
         : _content = WeakReference(content);
     
     DocumentContent? get content => _content.target;
   }
   ```

2. **Explicit Cleanup**:
   ```dart
   class HybridViewController {
     DocumentEditor? _activeEditor;
     
     void exitHybridMode() {
       _activeEditor?.dispose();
       _activeEditor = null;
       
       _activeDocumentBlock = null;
       _activeDocumentId = null;
       
       notifyListeners();
     }
     
     @override
     void dispose() {
       _activeEditor?.dispose();
       super.dispose();
     }
   }
   ```

3. **Memory Profiling**:
   ```dart
   class MemoryMonitor {
     Timer? _monitorTimer;
     
     void startMonitoring() {
       _monitorTimer = Timer.periodic(Duration(seconds: 30), (_) {
         final info = ProcessInfo.currentRss;
         debugPrint('Memory usage: ${info ~/ 1024 ~/ 1024} MB');
         
         if (info > 500 * 1024 * 1024) { // 500 MB threshold
           debugPrint('⚠️ High memory usage detected!');
           _triggerGarbageCollection();
         }
       });
     }
     
     void _triggerGarbageCollection() {
       // Force GC (Flutter specific)
       ServicesBinding.instance.performReassemble();
     }
   }
   ```

4. **Object Pool for Blocks**:
   ```dart
   class BlockWidgetPool {
     final Queue<Widget> _availableWidgets = Queue();
     final int maxSize;
     
     BlockWidgetPool({this.maxSize = 50});
     
     Widget acquire(Block block) {
       if (_availableWidgets.isNotEmpty) {
         final widget = _availableWidgets.removeFirst();
         // Reconfigure widget for new block
         return widget;
       }
       
       return BlockWidget(block: block);
     }
     
     void release(Widget widget) {
       if (_availableWidgets.length < maxSize) {
         _availableWidgets.add(widget);
       }
     }
   }
   ```

**Success Metric**: <300MB memory after 1 hour session

---

## 🚀 Implementation Strategy

See separate file: `BlockDocTaskList.md`

---

## 📐 Technical Specifications

### DocumentBlock Rendering Pipeline

```
User Action (Open Document)
  ↓
HybridViewController.enterHybridMode()
  ↓
DocumentService.loadDocument(documentId)
  ↓
DocumentBlock.enterEditMode()
  ↓
DocumentBlock.draw() called by CanvasService
  ↓
Based on viewMode:
  - Collapsed: Icon + title
  - Preview: Thumbnail or first 3 blocks
  - Expanded: Full block rendering
  ↓
Blocks rendered via Flutter widgets
  ↓
Canvas updated at 60 FPS
```

### Cross-Reference Flow

```
User types @ in document
  ↓
Show canvas object picker
  ↓
User selects canvas object
  ↓
Create CanvasReference
  ↓
Add to DocumentContent.references
  ↓
Add to CanvasObject.incomingReferences
  ↓
Render reference as inline widget
  ↓
Click reference
  ↓
HybridViewController.navigateToCanvas()
  ↓
CanvasService.panToObject()
  ↓
CanvasService.highlightObject()
```

### Auto-save Sequence

```
Timer fires (10s for docs, 30s for canvas)
  ↓
Check if dirty
  ↓
If dirty:
  - Log to WAL
  - Create temp file
  - Write JSON
  - Atomic rename
  - Mark clean
  - Clear WAL entry
```

---

## 📁 File Structure

See implementation details in `BlockDocTaskList.md`

---

## 🎯 Key Architectural Decisions

### 1. DocumentBlock as CanvasObject ✅

**Rationale**: 
- Leverages existing spatial indexing (QuadTree)
- Inherits transform system (Matrix4)
- Automatic persistence via canvas serialization
- Consistent interaction model

**Trade-offs**:
- Documents constrained by canvas object API
- Need to bridge document-specific features
- Rendering complexity increases

**Alternative Considered**: Separate layer system
- Rejected due to complexity and duplication

### 2. Separate Document File Storage ✅

**Rationale**:
- Allows standalone document viewing
- Reduces canvas file size
- Enables independent versioning
- Supports document templates

**Trade-offs**:
- More complex file management
- Reference integrity challenges
- Additional persistence logic

**Alternative Considered**: Embed documents in canvas JSON
- Rejected due to file size and coupling

### 3. Mode-Based Interaction ✅

**Rationale**:
- Clear user mental model
- Avoids gesture conflicts
- Explicit state transitions
- Better accessibility

**Trade-offs**:
- Mode switching overhead
- More UI complexity
- Learning curve

**Alternative Considered**: Context-sensitive gestures
- Rejected due to ambiguity

### 4. Event Sourcing for Sync ✅

**Rationale**:
- Reliable state synchronization
- Enables undo/redo across systems
- Audit trail for debugging
- Supports real-time collaboration (future)

**Trade-offs**:
- Increased complexity
- Memory overhead for event log
- Replay performance

**Alternative Considered**: Direct state mutation
- Rejected due to sync reliability

### 5. Level-of-Detail Rendering ✅

**Rationale**:
- Maintains 60 FPS with many documents
- Reduces memory usage
- Better battery life on mobile

**Trade-offs**:
- Visual quality trade-offs when zoomed out
- Implementation complexity
- Thumbnail generation overhead

**Alternative Considered**: Always render full documents
- Rejected due to performance

---

## ✅ Success Criteria

### Functional Requirements
- [ ] Users can place documents on canvas
- [ ] Documents editable in overlay/split/floating modes
- [ ] Canvas pannable while editing documents
- [ ] Cross-references work bidirectionally
- [ ] Auto-save prevents data loss
- [ ] Standalone document viewing works

### Performance Requirements
- [ ] 60 FPS with 100 document blocks
- [ ] <16ms render time per frame
- [ ] <500ms to load document
- [ ] <100ms to switch modes
- [ ] <300MB memory after 1 hour session

### Reliability Requirements
- [ ] Zero data loss on crash (WAL + atomic writes)
- [ ] <1% state sync errors
- [ ] <1% broken references
- [ ] Auto-save success rate >99.9%

### UX Requirements
- [ ] <5% mode-related confusion (user testing)
- [ ] <3% gesture-related complaints
- [ ] Intuitive mode transitions
- [ ] Clear visual feedback
- [ ] Keyboard shortcuts work

### Accessibility Requirements
- [ ] Full keyboard navigation
- [ ] Screen reader support
- [ ] High contrast mode support
- [ ] Reduced motion support

---

## 🔄 Next Steps

1. **Validate Architecture**
   - Review with stakeholders
   - Technical feasibility assessment
   - Performance simulation

2. **Create Detailed Specs**
   - DocumentBlock API specification
   - Document serialization format
   - Reference schema

3. **Prototype Hybrid Mode**
   - Test gesture handling
   - Validate UX flow
   - Performance benchmarking

4. **Begin Phase 1**
   - Implement DocumentBlock
   - Create integration bridge
   - Add document tool to canvas

5. **Iterate**
   - User testing after each phase
   - Performance profiling
   - Bug fixes and refinements

---

## 📚 Related Documents

- `BlockDocTaskList.md`: Detailed task breakdown
- `NotionCloneSpecs.md`: Notion feature specifications
- `HybridCanvasDocumentArchitecture.md`: Original architecture proposal
- `NotionClone_UIUX_Spec.md`: UI/UX design specifications

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-11  
**Status**: Architecture Complete, Ready for Implementation
