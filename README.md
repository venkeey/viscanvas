# VisCanvas - Advanced Infinite Canvas Application

A powerful Flutter application combining infinite canvas drawing capabilities with Notion-style document editing in a hybrid architecture.

## Table of Contents

1. [Overview](#overview)
2. [Core Features](#core-features)
3. [Canvas Features](#canvas-features)
4. [Document Editing Features](#document-editing-features)
5. [Hybrid Canvas-Document Features](#hybrid-canvas-document-features)
6. [Architecture](#architecture)
7. [Getting Started](#getting-started)
8. [Keyboard Shortcuts](#keyboard-shortcuts)
9. [Testing](#testing)

---

## Overview

VisCanvas is an advanced infinite canvas application that combines:

- **Infinite Canvas Drawing**: Create, manipulate, and connect shapes on an unlimited canvas space
- **Notion-Style Document Editing**: Rich text editing with blocks, formatting, and structure
- **Hybrid Architecture**: Seamlessly edit documents while maintaining spatial awareness of canvas elements
- **Smart Connectors**: Intelligent connection system with automatic routing and magnetic anchor points
- **Cross-Platform**: Runs on Windows, macOS, Linux, Web, iOS, and Android

---

## Core Features

### 🎨 Canvas System

#### Infinite Canvas
- **Unlimited Workspace**: Pan and zoom across an infinite 2D canvas space
- **Smooth Navigation**: Hardware-accelerated panning and zooming
- **Zoom Range**: 0.1x to 10.0x magnification
- **Coordinate System**: World-to-screen and screen-to-world transformations
- **Viewport Management**: Efficient rendering of visible objects only

#### Spatial Indexing
- **QuadTree Implementation**: O(log n) query performance for object lookup
- **Efficient Hit Testing**: Fast object selection and interaction detection
- **Capacity**: 4 objects per QuadTree node with maximum depth of 8 levels
- **Dynamic Updates**: Automatic spatial index updates on object changes

#### Transform System
- **Matrix4-Based Transforms**: Accurate coordinate transformations
- **Pan Operation**: Translate canvas viewport
- **Zoom Operation**: Scale canvas with zoom-to-cursor support
- **Transform Persistence**: Canvas view state saved and restored

### 🛠️ Drawing Tools

The application provides a comprehensive set of drawing and creation tools:

#### Selection & Navigation
- **Select Tool**: Select, move, resize, and manipulate objects
- **Pan Tool**: Navigate the canvas by dragging
- **Multi-Select**: Select multiple objects with selection box
- **Selection Handles**: Visual resize handles for selected objects

#### Drawing Tools
- **Pen/Freehand Tool**: Natural drawing with pressure-sensitive strokes
- **Rectangle Tool**: Create rectangular shapes with adjustable dimensions
- **Circle Tool**: Create circular shapes
- **Line Tool**: Draw straight lines

#### Shape Tools
- **Shapes Panel**: Access to various geometric shapes
- **Sticky Notes**: Text notes with colored backgrounds
- **Text Tool**: Add text labels and annotations
- **Frames**: Create frames and layouts for organizing content

#### Advanced Tools
- **Connector Tool**: Smart connection lines between objects
- **Document Block Tool**: Create Notion-style document blocks on canvas
- **Comment Tool**: Add comments and discussions
- **Upload Tool**: Upload files, images, and documents
- **AI Templates**: AI-powered templates and suggestions (planned)

### 📦 Canvas Object Types

The application supports multiple types of canvas objects:

#### Basic Shapes
- **FreehandPath**: Stroke-based freehand drawing
- **CanvasRectangle**: Rectangular shapes with customizable properties
- **CanvasCircle**: Circular shapes
- **CanvasText**: Text labels with rich formatting options

#### Advanced Objects
- **StickyNote**: Text notes with background colors and styles
- **Connector**: Intelligent curved connectors between objects
- **CanvasComment**: Comments with discussion threads
- **DocumentBlock**: Notion-style document containers

Each object type supports:
- Customizable colors (stroke and fill)
- Adjustable stroke width
- Transform operations (move, resize, rotate)
- Selection and manipulation
- Event sourcing for undo/redo

### 🔗 Connector System

#### Smart Connectors
- **Automatic Routing**: S-curve and C-curve path calculations
- **Magnetic Anchor Points**: Smart edge detection and connection points
- **Visual Indicators**: Connection point highlights and previews
- **Edge-Based Anchoring**: Connects to object edges (top, bottom, left, right)

#### Connector Features
- **Smart Anchor Detection**: Automatically determines best connection points
- **Curved Paths**: Smooth S-curves and C-curves for visual clarity
- **Connection Validation**: Ensures valid connections between objects
- **Freehand-to-Connector Conversion**: Convert drawn paths to connectors
- **Dynamic Updates**: Connectors update automatically when objects move

#### Anchor System
- **Edge-Based Anchoring**: Connections snap to object edges
- **Positional Anchoring**: Configurable anchor point positions (0.0-1.0 along edge)
- **Normal Vectors**: Outward-facing direction vectors for routing
- **Magnetic Points**: Visual indicators for connection points

### 💾 Persistence & State Management

#### Auto-Save System
- **Automatic Saving**: Canvas auto-saves every 30 seconds
- **Document Auto-Save**: Separate auto-save for document content
- **Recovery**: Automatic loading of last saved state on app restart
- **File Format**: JSON-based storage with versioning

#### Event Sourcing
- **Command Pattern**: All operations tracked as commands
- **Undo/Redo Support**: Full undo/redo with history stack
- **History Limit**: 100 commands in history (configurable)
- **Event Types**: ObjectCreated, ObjectModified, ObjectDeleted events

#### Storage
- **Local File System**: Canvas stored as `.canvas.json` files
- **Web Storage**: Browser localStorage simulation for web builds
- **Version Control**: JSON files include version metadata
- **Separate Document Storage**: Document blocks saved as separate files

### ⌨️ Undo/Redo System

- **Full Undo Support**: Undo all canvas operations
- **Redo Support**: Redo previously undone operations
- **Keyboard Shortcuts**: Ctrl+Z (undo), Ctrl+Y (redo)
- **Command History**: Maintains history stack of all operations
- **Selective History**: Can configure history limits and filtering

---

## Document Editing Features

### 📄 Notion-Style Block Editing

VisCanvas includes a comprehensive Notion-style document editing system with rich text formatting and structured blocks.

#### Block Types

**Text Blocks**
- `paragraph`: Standard text paragraphs with rich formatting
- `heading_1`, `heading_2`, `heading_3`: Three levels of headings
- `bulleted_list_item`: Bullet point lists with nesting
- `numbered_list_item`: Numbered lists with nesting
- `to_do`: Checkbox todo items
- `toggle`: Collapsible toggle blocks

**Formatting Blocks**
- `code`: Code blocks with syntax highlighting and language selection
- `quote`: Block quotes with custom styling
- `callout`: Highlighted callout boxes with icons and colors
- `divider`: Visual separator lines

**Media Blocks**
- `image`: Image embeds with captions
- `video`: Video embeds with captions
- `file`: File attachments
- `pdf`: PDF document embeds
- `bookmark`: Link previews with metadata
- `embed`: Generic embed support for various services

**Layout Blocks**
- `column_list`: Multi-column layouts
- `column`: Individual column containers
- `table`: Data tables with rows and columns
- `table_row`: Table row entries

**Navigation Blocks**
- `table_of_contents`: Auto-generated table of contents
- `breadcrumb`: Navigation breadcrumbs

**Reference Blocks**
- `link_to_page`: Links to other pages/documents
- `child_page`: Nested page references
- `child_database`: Embedded database references
- `synced_block`: Synchronized blocks across documents

### ✏️ Rich Text Features

#### Inline Formatting
- **Bold Text**: `**text**` or Ctrl+B
- **Italic Text**: `*text*` or Ctrl+I
- **Underline**: Ctrl+U
- **Strikethrough**: ~~text~~
- **Code**: Inline code formatting with `` `backticks` ``
- **Links**: Hyperlink support with URL previews
- **Mentions**: @ mentions for users and pages

#### Text Operations
- **Slash Commands**: Quick insertion with `/` command menu
- **Markdown Shortcuts**: Keyboard shortcuts for formatting
- **Drag & Drop**: Reorder blocks by dragging
- **Nested Hierarchy**: Unlimited block nesting levels

### 🗄️ Database Features

#### Database Property Types

**Basic Properties**
- `title`: Main title property
- `rich_text`: Formatted text with inline styling
- `number`: Numeric values with format options
- `checkbox`: Boolean true/false values
- `url`: URL links
- `email`: Email addresses
- `phone_number`: Phone numbers

**Selection Properties**
- `select`: Single selection from options
- `multi_select`: Multiple selections
- `status`: Workflow status with custom states

**Relationship Properties**
- `people`: User assignments
- `files`: File attachments
- `relation`: Links to other database entries
- `rollup`: Aggregated data from related entries

**Computed Properties**
- `formula`: Calculated values using formula engine
- `created_time`: Automatic creation timestamp
- `created_by`: User who created the entry
- `last_edited_time`: Last modification timestamp
- `last_edited_by`: User who last edited
- `unique_id`: Auto-generated unique identifiers

#### Database Views

- **Table View**: Spreadsheet-like table view
- **Board View**: Kanban board view with grouping
- **Calendar View**: Calendar timeline view
- **List View**: List-based view
- **Gallery View**: Visual gallery view
- **Timeline View**: Gantt-style timeline view

#### Database Operations
- **Filtering**: Filter entries by property values
- **Sorting**: Sort by any property type
- **Grouping**: Group entries by property
- **Formulas**: Custom formula calculations
- **Relations**: Link databases together
- **Rollups**: Aggregate data from relations

---

## Hybrid Canvas-Document Features

### 🔄 Hybrid Architecture

VisCanvas uniquely combines canvas and document editing in a hybrid architecture:

#### DocumentBlock Canvas Objects
- **Spatial Documents**: Place full Notion-style documents anywhere on canvas
- **Canvas Integration**: Documents are first-class canvas objects
- **Visual Representation**: Document blocks render as previews on canvas
- **Editing Modes**: Multiple editing modes (collapsed, preview, expanded, editing)

#### Hybrid Editing Modes

**Canvas Only Mode**
- Pure canvas interaction
- Navigate and manipulate canvas objects
- View document blocks as previews

**Document Only Mode**
- Full-screen document editing
- Focus on document content
- Canvas hidden but accessible

**Overlay Mode**
- Floating document editor over canvas
- Edit document while viewing canvas
- Maintains spatial context

**Split View Mode**
- Side-by-side canvas and document
- Edit document while navigating canvas
- Synchronized highlighting

**Hybrid Mode**
- Simultaneous editing and navigation
- Edit document blocks while panning canvas
- Visual connection between editor and canvas block

### 🔗 Cross-Reference System

#### Canvas-to-Document References
- **@ Mentions**: Mention canvas objects in documents
- **Visual Links**: Clickable links from documents to canvas objects
- **Embed References**: Embed canvas object visuals in documents
- **Bidirectional Navigation**: Navigate from documents to canvas and vice versa

#### Reference Types
- **Mentions**: `@canvas-object` style mentions
- **Links**: Hyperlinks to canvas objects
- **Embeds**: Visual embeds of canvas objects in documents

#### Reference Features
- **Auto-Validation**: References validate and mark invalid when objects deleted
- **Visual Indicators**: Icons and highlights show referenced objects
- **Navigation**: Click references to navigate to canvas objects
- **Synchronization**: References stay in sync across systems

### 📝 Document Block Operations

#### Document Block Lifecycle
1. **Creation**: Place document block on canvas
2. **Editing**: Enter edit mode via double-click or Enter
3. **Auto-Save**: Automatic saving of document content
4. **Synchronization**: Canvas preview updates in real-time
5. **Persistence**: Document saved as separate file with canvas reference

#### Document Block Features
- **Standalone Editing**: Documents can be edited independently
- **Canvas Context**: Maintain visual connection to canvas while editing
- **Real-Time Updates**: Canvas preview updates as you type
- **Separate Storage**: Documents stored separately from canvas data
- **Version Control**: Document versioning support

---

## Architecture

### 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────┤
│  Canvas View  │  Document Editor  │  Hybrid Overlay     │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                 APPLICATION LAYER                       │
├─────────────────────────────────────────────────────────┤
│  Canvas Service  │  Document Service  │  Hybrid Bridge  │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                   DOMAIN LAYER                          │
├─────────────────────────────────────────────────────────┤
│  Canvas Objects  │  Document Blocks  │  Cross-Refs     │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                INFRASTRUCTURE LAYER                     │
├─────────────────────────────────────────────────────────┤
│  Persistence  │  Spatial Index  │  Event Sourcing      │
└─────────────────────────────────────────────────────────┘
```

### 📁 Project Structure

```
lib/
├── domain/              # Domain layer - business logic
│   ├── canvas_domain.dart
│   └── connector_system.dart
├── models/              # Data models
│   ├── canvas_objects/  # Canvas object types
│   └── documents/       # Document content models
├── services/            # Application services
│   ├── canvas/          # Canvas-related services
│   └── documents/       # Document-related services
├── ui/                  # UI components
│   ├── canvas_screen.dart
│   ├── document_editor_overlay.dart
│   └── notion_document_editor.dart
├── widgets/             # Reusable widgets
└── theme/               # Theming and styling
```

### 🔧 Service Architecture

#### Canvas Service
- **CanvasService**: Main canvas orchestration service
- **CanvasToolsService**: Tool management and object creation
- **CanvasConnectorService**: Connector operations
- **CanvasDocumentService**: Document block management
- **CanvasTransformService**: Viewport transformations
- **CanvasPersistenceService**: Save/load operations

#### Document Service
- **DocumentService**: Document content management
- **Block Operations**: CRUD operations for document blocks
- **Auto-Save**: Automatic document persistence
- **Version Control**: Document versioning

#### Hybrid Bridge
- **HybridCanvasDocumentBridge**: Coordination between systems
- **CrossReferenceManager**: Cross-reference management
- **CanvasDocumentSync**: State synchronization

---

## Getting Started

### Prerequisites

- Flutter SDK (3.13.0 or later)
- Dart SDK (3.1.0 or later)
- Platform-specific requirements:
  - **Windows**: Visual Studio or Build Tools
  - **macOS**: Xcode
  - **Linux**: Standard development tools
  - **Web**: Chrome browser for development
  - **iOS**: Xcode and CocoaPods
  - **Android**: Android Studio and SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd viscanvas
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Building for Platforms

**Windows**
```bash
flutter build windows
```

**macOS**
```bash
flutter build macos
```

**Linux**
```bash
flutter build linux
```

**Web**
```bash
flutter build web
```

**iOS**
```bash
flutter build ios
```

**Android**
```bash
flutter build apk
```

---

## Keyboard Shortcuts

### Canvas Navigation
- **Ctrl + P**: Switch to Pan tool
- **V**: Switch to Select tool
- **Space + Drag**: Pan canvas (when in select mode)
- **Mouse Wheel**: Zoom in/out
- **Ctrl + Mouse Wheel**: Zoom at cursor position

### Tools
- **V**: Select tool
- **B**: Pen/Freehand tool
- **T**: Text tool
- **R**: Rectangle tool
- **O**: Circle tool
- **C**: Connector tool
- **D**: Document block tool
- **F**: Frame tool

### Object Operations
- **Delete**: Delete selected objects
- **Shift + Delete**: Delete selected objects
- **Ctrl + A**: Select all objects
- **Ctrl + D**: Duplicate selected objects
- **Arrow Keys**: Move selected objects (pixels)
- **Shift + Arrow Keys**: Move selected objects (larger steps)

### Editing
- **Ctrl + Z**: Undo
- **Ctrl + Y**: Redo
- **Enter**: Start editing selected text/document block
- **Escape**: Cancel editing, exit tool
- **Tab**: Focus next element (when editing)

### Canvas Management
- **Ctrl + Shift + Delete**: Clear entire canvas
- **Ctrl + Shift + 5**: Set zoom to 50%
- **Ctrl + S**: Manual save (auto-save is enabled by default)

### Document Editing
- **/** (Slash): Open command menu for block insertion
- **Ctrl + B**: Bold text
- **Ctrl + I**: Italic text
- **Ctrl + U**: Underline text
- **Ctrl + K**: Create link
- **@**: Mention user or page

---

## Testing

The application includes comprehensive testing infrastructure:

### Test Structure
```
test/
├── unit/              # Unit tests for business logic
├── widget/            # Widget tests for UI components
├── integration/       # Integration tests with Patrol
├── visual/            # Golden tests for visual regression
└── performance/       # Performance benchmarks
```

### Running Tests

**Unit Tests**
```bash
flutter test
```

**Widget Tests**
```bash
flutter test test/widget/
```

**Integration Tests**
```bash
flutter test integration_test/
patrol test
```

**Visual Tests**
```bash
flutter test test/visual/
```

**Performance Tests**
```bash
flutter test test/performance/
```

### Test Coverage

Generate test coverage report:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Platform Support

- ✅ **Windows**: Full support
- ✅ **macOS**: Full support
- ✅ **Linux**: Full support
- ✅ **Web**: Full support with storage simulation
- 🚧 **iOS**: In development
- 🚧 **Android**: In development

---

## Performance Features

### Optimization Strategies
- **Spatial Indexing**: QuadTree for efficient object queries
- **Viewport Culling**: Only render visible objects
- **Lazy Loading**: Load document content on demand
- **Event Debouncing**: Debounce frequent operations
- **Auto-Save Throttling**: Throttled auto-save to prevent excessive I/O

### Performance Metrics
- **Rendering**: 60 FPS during interactions
- **Object Limit**: Handles thousands of objects efficiently
- **Zoom Performance**: Smooth zoom at all levels
- **Memory Usage**: Optimized memory footprint

---

## Future Enhancements

### Planned Features
- **Real-Time Collaboration**: Multi-user editing with CRDT
- **Cloud Storage**: Sync canvas and documents across devices
- **Advanced Templates**: AI-powered templates and suggestions
- **Plugin System**: Extensible plugin architecture
- **Export Options**: Export to PDF, PNG, SVG
- **Import Support**: Import from other formats
- **Mobile Gestures**: Optimized mobile interactions
- **Voice Input**: Voice-to-text for document blocks

---

## Contributing

Contributions are welcome! Please see the contributing guidelines for more information.

---

## License

[Specify your license here]

---

## Acknowledgments

- Built with Flutter
- Inspired by Miro, Notion, and Figma
- Uses event sourcing and domain-driven design patterns

---

## Support

For issues, questions, or contributions, please open an issue on the repository.
