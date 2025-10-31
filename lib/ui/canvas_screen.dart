import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/canvas/canvas_service.dart';
import '../widgets/miro_sidebar.dart';
import '../widgets/shapes_panel.dart';
import '../models/canvas_objects/sticky_note.dart';
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/document_block.dart';
import '../models/canvas_objects/canvas_text.dart';
import '../models/canvas_objects/canvas_comment.dart';
import '../domain/canvas_domain.dart';
import '../models/documents/document_content.dart';
import '../models/documents/block_types.dart';
import '../utils/logger.dart';
import 'canvas_widgets.dart';
import 'canvas_painter.dart';
import 'document_editor_overlay.dart';
import 'draggable_right_panel.dart';

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
  MouseCursor _currentCursor = SystemMouseCursors.basic;

  // Inline text editing state
  CanvasText? _editingTextObject;
  final TextEditingController _inlineTextController = TextEditingController();
  final FocusNode _inlineTextFocusNode = FocusNode();

  // Public getter for testing
  CanvasService get service => _service;

  @override
  void initState() {
    super.initState();
    _service = CanvasService();
    _service.onOpenDocumentEditor = _openDocumentEditor;
    _service.onStartEditingText = _startInlineTextEditing;
    _service.onStartEditingComment = _showCommentEditingDialog;

    _focusNode.requestFocus(); // Enable keyboard focus for backspace deletion

    // Listen to focus changes to save text when focus is lost
    _inlineTextFocusNode.addListener(() {
      if (!_inlineTextFocusNode.hasFocus && _editingTextObject != null) {
        _finishInlineTextEditing();
      }
    });
  }

  @override
  void dispose() {
    _service.dispose();
    _focusNode.dispose();
    _inlineTextController.dispose();
    _inlineTextFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // Only handle shortcuts with modifiers (Ctrl+ or Shift+)
    // Don't intercept regular character input at all
    if (event is KeyDownEvent) {
      // If this is character input (not a shortcut), ignore it completely
      // This allows TextFields in dialogs to receive input
      if (event.character != null && event.character!.isNotEmpty && 
          !HardwareKeyboard.instance.isControlPressed && 
          !HardwareKeyboard.instance.isShiftPressed) {
        return;
      }
      
      // Check if any TextField or editable widget has focus
      // This prevents keyboard handler from intercepting text input
      final focusManager = FocusManager.instance;
      if (focusManager.primaryFocus != null) {
        final focusedContext = focusManager.primaryFocus?.context;
        if (focusedContext != null) {
          // Check if focused widget or any ancestor is a TextField/TextFormField
          final focusedWidget = focusedContext.findAncestorWidgetOfExactType<TextField>() ??
              focusedContext.findAncestorWidgetOfExactType<TextFormField>();
          if (focusedWidget != null) {
            // TextField has focus, don't intercept keyboard events
            return;
          }
        }
      }
      
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      
      // Test-friendly shortcut: Ctrl+Shift+Delete clears the canvas
      if (isCtrl && isShift &&
          (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace)) {
        _service.deleteAll();
        return;
      }
      
      // Test-friendly shortcut: Ctrl+Shift+5 sets zoom to 50%
      if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.digit5) {
        _service.updateTransform(_service.transform.translation, 0.5);
        return;
      }
      
      // Tool shortcuts with Ctrl modifier
      if (isCtrl && !isShift) {
        if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          _service.undo();
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          _service.redo();
        } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
          _service.setTool(ToolType.pan);
        } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
          _service.setTool(ToolType.select);
        } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
          _service.setTool(ToolType.pen);
        } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
          _service.setTool(ToolType.connector);
        } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
          _service.setTool(ToolType.rectangle);
        } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
          _service.setTool(ToolType.circle);
        } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
          _service.setTool(ToolType.document_block);
        }
      }
      
      // Delete selected with Shift+Delete (only when no modifier conflicts)
      if (isShift && !isCtrl &&
          (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace)) {
        _service.deleteSelected();
      }
      
      // Escape key always works (no modifier needed)
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _service.setTool(ToolType.select);
        setState(() {
          _showShapesPanel = false;
        });
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
      _showStickyNoteEditingDialog(selectedObjects.first as StickyNote);
    }
  }

  void _showStickyNoteEditingDialog(StickyNote stickyNote) {
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

  // Inline text editing methods
  void _startInlineTextEditing(CanvasText canvasText) {
    print('🖊️ Starting inline text editing for ${canvasText.id}');
    setState(() {
      _editingTextObject = canvasText;
      _inlineTextController.text = canvasText.text;
      canvasText.isEditing = true;
    });

    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inlineTextFocusNode.requestFocus();
    });
  }

  void _finishInlineTextEditing() {
    if (_editingTextObject == null) return;

    print('💾 Finishing inline text editing');
    final textObj = _editingTextObject!;
    textObj.text = _inlineTextController.text;
    textObj.isEditing = false;
    textObj.invalidateCache();

    setState(() {
      _editingTextObject = null;
      _inlineTextController.clear();
    });

    // Return focus to canvas
    _focusNode.requestFocus();
  }

  void _cancelInlineTextEditing() {
    if (_editingTextObject == null) return;

    print('❌ Canceling inline text editing');
    _editingTextObject!.isEditing = false;

    setState(() {
      _editingTextObject = null;
      _inlineTextController.clear();
    });

    // Return focus to canvas
    _focusNode.requestFocus();
  }

  Widget _buildInlineTextEditor(CanvasText textObj) {
    // Convert world position to screen position
    final screenPos = _service.transform.worldToScreen(textObj.worldPosition);
    final bounds = textObj.getBoundingRect();
    final screenWidth = bounds.width * _service.transform.scale;
    final screenHeight = bounds.height * _service.transform.scale;

    return Positioned(
      left: screenPos.dx,
      top: screenPos.dy,
      child: Container(
        width: screenWidth.clamp(100.0, 500.0),
        constraints: BoxConstraints(
          minHeight: screenHeight.clamp(30.0, double.infinity),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                _finishInlineTextEditing();
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                _cancelInlineTextEditing();
              }
            }
          },
          child: TextField(
            controller: _inlineTextController,
            focusNode: _inlineTextFocusNode,
            maxLines: null,
            style: TextStyle(
              fontSize: textObj.fontSize.clamp(12.0, 24.0),
              fontWeight: textObj.fontWeight,
              color: textObj.textColor,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            textAlign: textObj.textAlign,
            onSubmitted: (_) => _finishInlineTextEditing(),
          ),
        ),
      ),
    );
  }

  void _showTextEditingDialog(CanvasText canvasText) {
    final controller = TextEditingController(text: canvasText.text);
    TextAlign selectedAlign = canvasText.textAlign;
    FontWeight selectedWeight = canvasText.fontWeight;
    double selectedSize = canvasText.fontSize;
    Color selectedColor = canvasText.textColor;

    // Create a FocusNode for the text field
    final textFieldFocusNode = FocusNode();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Request focus after dialog is built - only once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (textFieldFocusNode.canRequestFocus) {
            textFieldFocusNode.requestFocus();
          }
        });
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Text'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      focusNode: textFieldFocusNode,
                      maxLines: null,
                      enabled: true,
                      readOnly: false,
                      showCursor: true,
                      cursorWidth: 2.0,
                      cursorColor: Colors.blue,
                      cursorRadius: const Radius.circular(1.0),
                      decoration: const InputDecoration(
                        hintText: 'Enter your text here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Font Size'),
                  Slider(
                    value: selectedSize,
                    min: 8,
                    max: 72,
                    divisions: 64,
                    label: selectedSize.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() => selectedSize = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Text Alignment'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_align_left),
                        onPressed: () {
                          setState(() => selectedAlign = TextAlign.left);
                        },
                        color: selectedAlign == TextAlign.left ? Colors.blue : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_align_center),
                        onPressed: () {
                          setState(() => selectedAlign = TextAlign.center);
                        },
                        color: selectedAlign == TextAlign.center ? Colors.blue : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_align_right),
                        onPressed: () {
                          setState(() => selectedAlign = TextAlign.right);
                        },
                        color: selectedAlign == TextAlign.right ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Font Weight'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => selectedWeight = FontWeight.normal);
                        },
                        child: Text(
                          'Normal',
                          style: TextStyle(
                            fontWeight: selectedWeight == FontWeight.normal
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => selectedWeight = FontWeight.bold);
                        },
                        child: Text(
                          'Bold',
                          style: TextStyle(
                            fontWeight: selectedWeight == FontWeight.bold
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Text Color'),
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.black,
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ].map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color ? Colors.blue : Colors.grey,
                              width: selectedColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  textFieldFocusNode.dispose();
                  canvasText.isEditing = false;
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  canvasText.text = controller.text;
                  canvasText.fontSize = selectedSize;
                  canvasText.textAlign = selectedAlign;
                  canvasText.fontWeight = selectedWeight;
                  canvasText.textColor = selectedColor;
                  canvasText.isEditing = false;
                  canvasText.invalidateCache();
                  // Trigger service update notification
                  setState(() {});
                  textFieldFocusNode.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
        );
      },
    );
  }

  void _showCommentEditingDialog(CanvasComment canvasComment) {
    final controller = TextEditingController(text: canvasComment.text);
    String? authorName = canvasComment.author;
    bool isResolved = canvasComment.isResolved;
    final commentFocusNode = FocusNode();
    final authorFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        // Request focus after dialog is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (commentFocusNode.canRequestFocus) {
            commentFocusNode.requestFocus();
          }
        });
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Comment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comment'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      focusNode: commentFocusNode,
                      maxLines: 5,
                      enabled: true,
                      readOnly: false,
                      showCursor: true,
                      cursorWidth: 2.0,
                      cursorColor: Colors.blue,
                      cursorRadius: const Radius.circular(1.0),
                      decoration: const InputDecoration(
                        hintText: 'Enter your comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Author (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: authorFocusNode,
                    onChanged: (value) {
                      setState(() => authorName = value.isEmpty ? null : value);
                    },
                    enabled: true,
                    readOnly: false,
                    showCursor: true,
                    cursorWidth: 2.0,
                    cursorColor: Colors.blue,
                    cursorRadius: const Radius.circular(1.0),
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    controller: TextEditingController(text: authorName ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isResolved,
                        onChanged: (value) {
                          setState(() => isResolved = value ?? false);
                        },
                      ),
                      const Text('Mark as resolved'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  commentFocusNode.dispose();
                  authorFocusNode.dispose();
                  canvasComment.isEditing = false;
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  canvasComment.text = controller.text;
                  canvasComment.author = authorName;
                  canvasComment.isResolved = isResolved;
                  canvasComment.isEditing = false;
                  canvasComment.invalidateCache();
                  setState(() {});
                  commentFocusNode.dispose();
                  authorFocusNode.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
        );
      },
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
            SnackBar(content: Text('Canvas saved successfully!')),
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
                        child: MouseRegion(
                          cursor: _currentCursor,
                          onHover: (event) {
                            final cursor = _service.getCursorForHover(event.localPosition);
                            if (cursor != null) {
                              setState(() {
                                _currentCursor = cursor;
                              });
                            } else {
                              setState(() {
                                _currentCursor = SystemMouseCursors.basic;
                              });
                            }
                          },
                          onExit: (event) {
                            setState(() {
                              _currentCursor = SystemMouseCursors.basic;
                            });
                          },
                          child: GestureDetector(
                            key: const Key('canvasRoot'),
                            onSecondaryTapDown: (details) {
                              // Right-click: select object under cursor (if any) and open properties
                              _service.onTap(details.localPosition);
                              final selected = _service.objects.where((o) => o.isSelected).toList();
                              if (selected.isNotEmpty) {
                                _openObjectPropertiesPopup(selected.first);
                              }
                            },
                            onTapDown: (details) {
                              _service.onTap(details.localPosition);
                              _handleCanvasTap();
                            },
                            // Add double-tap handler for text editing
                            onDoubleTap: () {
                              print('🖱️ Double-tap detected on canvas');
                              // Double-tap detected, check if a text object is selected
                              final selected = _service.objects.where((o) => o.isSelected).toList();
                              if (selected.isNotEmpty) {
                                final selectedObj = selected.first;
                                print('  Selected object: ${selectedObj.runtimeType}');
                                if (selectedObj is CanvasText) {
                                  print('  Opening inline text editor for CanvasText');
                                  _startInlineTextEditing(selectedObj);
                                } else if (selectedObj is StickyNote) {
                                  print('  Opening sticky note editor');
                                  selectedObj.isEditing = true;
                                  _showStickyNoteEditingDialog(selectedObj);
                                } else if (selectedObj is CanvasComment) {
                                  print('  Opening comment editor');
                                  selectedObj.isEditing = true;
                                  _showCommentEditingDialog(selectedObj);
                                }
                              }
                            },
                            onScaleStart: (details) {
                              _service.onPanStart(details.localFocalPoint);
                            },
                            onScaleUpdate: (details) {
                              if (details.scale != 1.0) {
                                // Handle zoom/scale gestures
                                _service.updateTransform(
                                  _service.transform.translation,
                                  _service.transform.scale * details.scale,
                                );
                              } else {
                                // Handle pan gestures (when scale is 1.0)
                                _service.onPanUpdate(details.localFocalPoint, details.focalPointDelta);
                              }
                            },
                            onScaleEnd: (details) => _service.onPanEnd(),
                            child: CustomPaint(
                              painter: AdvancedCanvasPainter(_service),
                              size: Size.infinite,
                            ),
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
                            key: const Key('notionDemoButton'),
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

                      // Bottom Controls
                      Positioned(
                        bottom: 16,
                        left: 80, // Position next to sidebar
                        child: BottomControls(service: _service),
                      ),

                      // Draggable Right Panel (contains PropertiesPanel and AutoSaveControls)
                      DraggableRightPanel(service: _service),

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

                      // Inline Text Editor Overlay
                      if (_editingTextObject != null)
                        _buildInlineTextEditor(_editingTextObject!),

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

  void _openObjectPropertiesPopup(CanvasObject obj) {
    // Compute default display name same as Objects panel
    final typeName = obj.getDisplayTypeName();
    final sameType = _service.objects.where((o) => o.runtimeType == obj.runtimeType).toList();
    final index = sameType.indexOf(obj) + 1;
    final defaultName = obj.label ?? '$typeName #$index';
    final nameController = TextEditingController(text: defaultName);
    double tempStrokeWidth = obj.strokeWidth;
    Color tempStroke = obj.strokeColor;
    Color? tempFill = obj.fillColor;

    // Sticky note specifics (dynamic to avoid tight coupling)
    final isSticky = obj is StickyNote;
    final sticky = isSticky ? obj as StickyNote : null;
    final stickyTextController = isSticky ? TextEditingController(text: sticky!.text) : null;
    Color? stickyBg = isSticky ? sticky!.backgroundColor : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Properties'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a display name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => _service.setObjectLabel(obj.id, v),
                    ),
                    const SizedBox(height: 12),
                    const Text('Stroke Color'),
                    const SizedBox(height: 6),
                    _buildColorRow(tempStroke, (c) {
                      setState(() => tempStroke = c);
                      _service.setStrokeColor(c);
                    }),
                    const SizedBox(height: 12),
                    const Text('Fill Color'),
                    const SizedBox(height: 6),
                    _buildColorRow(tempFill ?? Colors.transparent, (c) {
                      setState(() => tempFill = c);
                      _service.setFillColor(c);
                    }, includeTransparent: true),
                    const SizedBox(height: 12),
                    const Text('Stroke Width'),
                    Slider(
                      value: tempStrokeWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: tempStrokeWidth.toStringAsFixed(0),
                      onChanged: (v) {
                        setState(() => tempStrokeWidth = v);
                        _service.setStrokeWidth(v);
                      },
                    ),
                    if (isSticky) ...[
                      const SizedBox(height: 12),
                      const Text('Sticky Note Text'),
                      TextField(
                        controller: stickyTextController,
                        maxLines: null,
                        onChanged: (v) => _service.updateStickyNoteText(v),
                      ),
                      const SizedBox(height: 12),
                      const Text('Sticky Note Color'),
                      _buildColorRow(stickyBg ?? Colors.yellow, (c) {
                        setState(() => stickyBg = c);
                        _service.setStickyNoteBackgroundColor(c);
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete object?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _service.selectObjectById(obj.id);
                      _service.deleteSelected();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorRow(Color current, ValueChanged<Color> onPick, {bool includeTransparent = false}) {
    final colors = <Color>[
      Colors.black, Colors.white, Colors.red, Colors.green,
      Colors.blue, Colors.yellow, Colors.orange, Colors.purple,
      Colors.pink, Colors.brown, Colors.grey,
      if (includeTransparent) Colors.transparent,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final selected = c.value == current.value;
        return GestureDetector(
          onTap: () => onPick(c),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? Colors.blue : Colors.grey, width: selected ? 2 : 1),
            ),
          ),
        );
      }).toList(),
    );
  }
}