import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/canvas_service.dart';
import '../widgets/miro_sidebar.dart';
import '../widgets/shapes_panel.dart';
import '../models/canvas_objects/sticky_note.dart';
import '../models/canvas_objects/document_block.dart';
import '../domain/canvas_domain.dart';
import '../models/documents/document_content.dart';
import '../models/documents/block_types.dart';
import '../utils/logger.dart';
import 'canvas_widgets.dart';
import 'canvas_painter.dart';
import 'document_editor_overlay.dart';

// ===== 4. PRESENTATION LAYER =====

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({Key? key}) : super(key: key);

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  late final CanvasService _service;

  final FocusNode _focusNode = FocusNode();
  String? _selectedShape;
  bool _showShapesPanel = false;

  @override
  void initState() {
    super.initState();
    _service = CanvasService();
    _service.onOpenDocumentEditor = _openDocumentEditor;

    // _focusNode.requestFocus(); // Temporarily disabled to test keyboard issue
  }

  @override
  void dispose() {
    _service.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // Debug logging for keyboard events
    print('🔍 KeyEvent received: ${event.runtimeType} - ${event.logicalKey} - physical: ${event.physicalKey} - character: ${event.character}');
    print('🔍 HardwareKeyboard state - Ctrl: ${HardwareKeyboard.instance.isControlPressed}, Shift: ${HardwareKeyboard.instance.isShiftPressed}');

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace) {
        _service.deleteSelected();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _service.setTool(ToolType.select);
        setState(() {
          _showShapesPanel = false;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        _service.setTool(ToolType.pan);
      } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
        _service.setTool(ToolType.select);
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        _service.setTool(ToolType.pen);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _service.setTool(ToolType.document_block);
      } else if (HardwareKeyboard.instance.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          _service.undo();
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          _service.redo();
        }
      }
    }
  }

  void _handleToolSelected(String tool) {
    setState(() {
      _showShapesPanel = false;
    });

    switch (tool) {
      case 'ai_templates':
        _service.setTool(ToolType.ai_templates);
        _showAITemplatesDialog();
        break;
      case 'select':
        _service.setTool(ToolType.select);
        break;
      case 'pan':
        _service.setTool(ToolType.pan);
        break;
      case 'frame':
        _service.setTool(ToolType.frame);
        break;
      case 'text':
        _service.setTool(ToolType.text);
        break;
      case 'sticky_note':
        _service.setTool(ToolType.sticky_note);
        break;
      case 'shapes':
        _service.setTool(ToolType.shapes);
        setState(() {
          _showShapesPanel = true;
        });
        break;
      case 'pen':
        _service.setTool(ToolType.pen);
        break;
      case 'rectangle':
        _service.setTool(ToolType.rectangle);
        break;
      case 'circle':
        _service.setTool(ToolType.circle);
        break;
      case 'connector':
        _service.setTool(ToolType.connector);
        break;
      case 'comment':
        _service.setTool(ToolType.comment);
        break;
      case 'table':
        _service.setTool(ToolType.table);
        break;
      case 'upload':
        _service.setTool(ToolType.upload);
        _showUploadDialog();
        break;
      case 'add_more':
        _showMoreToolsDialog();
        break;
      case 'document_block':
        _service.setTool(ToolType.document_block);
        break;
    }
  }

  void _handleShapeSelected(String shape) {
    setState(() {
      _selectedShape = shape;
    });

    switch (shape) {
      case 'rectangle':
        _service.setTool(ToolType.rectangle);
        break;
      case 'circle':
        _service.setTool(ToolType.circle);
        break;
      case 'triangle':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
      case 'arrow':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
      case 'diamond':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
      case 'star':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
      case 'heart':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
      case 'cloud':
        _service.setTool(ToolType.freehand); // Use freehand for now
        break;
    }
  }

  void _showAITemplatesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Templates'),
        content: const Text('AI-powered templates and suggestions coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Files'),
        content: const Text('File upload functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMoreToolsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('More Tools'),
        content: const Text('Additional tools and features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleCanvasTap() {
    // For now, we'll use a simple approach - show text editing dialog if a sticky note is selected
    final selectedObjects = _service.objects.where((obj) => obj.isSelected).toList();
    if (selectedObjects.isNotEmpty && selectedObjects.first is StickyNote) {
      _showTextEditingDialog(selectedObjects.first as StickyNote);
    }
  }

  void _showTextEditingDialog(StickyNote stickyNote) {
    final controller = TextEditingController(text: stickyNote.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Sticky Note'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter your text here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _service.updateStickyNoteText(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openDocumentEditor(DocumentBlock documentBlock) {
    CanvasLogger.canvasScreen('Opening document editor for block: ${documentBlock.id}');
    CanvasLogger.canvasScreen('Current content blocks: ${documentBlock.content?.blocks.length ?? 0}');

    // Load the document content and open the editor overlay
    // For now, create a simple document if none exists
    final documentContent = documentBlock.content ?? DocumentContent(
      id: documentBlock.documentId,
      blocks: [
        BasicBlock(
          id: 'block_1',
          type: BlockType.heading1,
          content: {'text': 'Document Title'},
        ),
        BasicBlock(
          id: 'block_2',
          type: BlockType.paragraph,
          content: {'text': 'Double-click blocks to edit them. This is a rich text document editor integrated with the canvas.'},
        ),
      ],
      hierarchy: BlockHierarchy(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentEditorOverlay(
        document: documentContent,
        onClose: () {
          CanvasLogger.canvasScreen('Document editor closed');
          Navigator.of(context).pop();
        },
        onDocumentChanged: (updatedDocument) {
          CanvasLogger.canvasScreen('Document changed callback triggered');
          CanvasLogger.canvasScreen('Updated document has ${updatedDocument.blocks.length} blocks');
          for (var block in updatedDocument.blocks) {
            CanvasLogger.canvasScreen('Block ${block.id}: ${block.getPlainText()}');
          }

          // Update the document block with new content through the service
          _service.updateDocumentBlockContent(documentBlock.id, updatedDocument);
          // Switch to expanded mode so user can see all the content they just edited
          documentBlock.viewMode = DocumentViewMode.expanded;
          CanvasLogger.canvasScreen('Switched document block to expanded mode');

          // Force immediate save to ensure content persists
          _service.saveCanvasToFile(fileName: 'autosave_canvas').then((_) {
            CanvasLogger.canvasScreen('Manual save completed after document edit');
          }).catchError((error) {
            CanvasLogger.canvasScreen('Manual save failed: $error');
          });

          // Service.notifyListeners() will trigger canvas rebuild, no need for setState()
        },
      ),
    );
  }

  Future<void> _handleBackButton() async {
    // Show confirmation dialog
    final shouldGoBack = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Canvas'),
        content: const Text('Do you want to save your canvas before going back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Don\'t Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (shouldGoBack == true) {
      // Save canvas before going back
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _service.saveCanvasToFile(fileName: 'canvas_$timestamp');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canvas saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save canvas: $e')),
          );
        }
      }
    }

    // Go back to main screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: ListenableBuilder(
          listenable: _service,
          builder: (context, child) {
            return Row(
              children: [
                // Miro Sidebar
                MiroSidebar(
                  onToolSelected: _handleToolSelected,
                  selectedTool: _getSelectedToolString(),
                  onUndo: _service.undo,
                  onRedo: _service.redo,
                  canUndo: _service.canUndo,
                  canRedo: _service.canRedo,
                ),

                // Main content area
                Expanded(
                  child: Stack(
                    children: [
                      // Main Canvas
                      Positioned.fill(
                        child: GestureDetector(
                          onScaleStart: (details) => _service.onPanStart(details.localFocalPoint),
                          onScaleUpdate: (details) {
                            if (details.scale != 1.0) {
                              _service.updateTransform(
                                _service.transform.translation,
                                _service.transform.scale * details.scale,
                              );
                            } else {
                              _service.onPanUpdate(details.localFocalPoint, details.focalPointDelta);
                            }
                          },
                          onScaleEnd: (details) => _service.onPanEnd(),
                          onTapDown: (details) {
                            _service.onTap(details.localPosition);
                            _handleCanvasTap();
                          },
                          child: CustomPaint(
                            painter: AdvancedCanvasPainter(_service),
                            size: Size.infinite,
                          ),
                        ),
                      ),

                      // Back Button
                      Positioned(
                        top: 16,
                        left: 80, // Position next to sidebar
                        child: CanvasBackButton(
                          onBack: _handleBackButton,
                        ),
                      ),

                      // Notion Demo Button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/notion-demo');
                            },
                            icon: const Icon(Icons.description, color: Colors.white),
                            label: const Text(
                              'Notion Demo',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),

                      // Shapes Panel (when shapes tool is selected)
                      if (_showShapesPanel)
                        Positioned(
                          top: 80, // Position below back button
                          left: 80, // Position next to sidebar
                          child: ShapesPanel(
                            onShapeSelected: _handleShapeSelected,
                            selectedShape: _selectedShape,
                          ),
                        ),

                      // Properties Panel
                      Positioned(
                        top: 16,
                        right: 16,
                        child: PropertiesPanel(service: _service),
                      ),

                      // Bottom Controls
                      Positioned(
                        bottom: 16,
                        left: 80, // Position next to sidebar
                        child: BottomControls(service: _service),
                      ),

                      // Auto-save Controls
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AutoSaveControls(service: _service),
                      ),

                      // Performance Metrics
                      Positioned(
                        top: 16,
                        left: 80,
                        right: 0,
                        child: Center(
                          child: PerformanceMetrics(service: _service),
                        ),
                      ),

                      // Connector Confirmation Dialog
                      if (_service.showConnectorConfirmation)
                        Positioned(
                          top: 100,
                          left: 100,
                          child: ConnectorConfirmationDialog(
                            onConfirm: () => _service.confirmFreehandConnection(),
                            onCancel: () => _service.cancelFreehandConnection(),
                          ),
                        ),

                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _getSelectedToolString() {
    switch (_service.currentTool) {
      case ToolType.ai_templates:
        return 'ai_templates';
      case ToolType.select:
        return 'select';
      case ToolType.pan:
        return 'pan';
      case ToolType.frame:
        return 'frame';
      case ToolType.text:
        return 'text';
      case ToolType.sticky_note:
        return 'sticky_note';
      case ToolType.shapes:
        return 'shapes';
      case ToolType.pen:
        return 'pen';
      case ToolType.rectangle:
        return 'rectangle';
      case ToolType.circle:
        return 'circle';
      case ToolType.connector:
        return 'connector';
      case ToolType.comment:
        return 'comment';
      case ToolType.table:
        return 'table';
      case ToolType.upload:
        return 'upload';
      case ToolType.add_more:
        return 'add_more';
      case ToolType.document_block:
        return 'document_block';
      default:
        return null;
    }
  }
}