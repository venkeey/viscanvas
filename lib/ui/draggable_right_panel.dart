import 'package:flutter/material.dart';
import '../services/canvas/canvas_service.dart';
import '../models/canvas_objects/sticky_note.dart';
import 'objects_list_panel.dart';
import 'collapsible_section.dart';

class DraggableRightPanel extends StatefulWidget {
  final CanvasService service;

  const DraggableRightPanel({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<DraggableRightPanel> createState() => _DraggableRightPanelState();
}

class _DraggableRightPanelState extends State<DraggableRightPanel> {
  double _topOffset = 16.0;
  double _rightOffset = 16.0;
  double _width = 300.0;
  double _initialTop = 0.0;
  double _initialRight = 0.0;
  double _initialWidth = 0.0;
  double _initialPanY = 0.0;
  double _initialPanX = 0.0;
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Constrain width
    final constrainedWidth = _isCollapsed ? 50.0 : _width.clamp(200.0, 600.0);

    return Positioned(
      top: _topOffset.clamp(0.0, screenHeight - 500), // Constrain with reasonable max
      right: _rightOffset.clamp(0.0, screenWidth - constrainedWidth),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight - _topOffset - 16,
          maxWidth: constrainedWidth,
        ),
        child: Container(
          width: constrainedWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
            // Drag Handle
            GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _initialTop = _topOffset;
                      _initialRight = _rightOffset;
                      _initialPanY = details.globalPosition.dy;
                      _initialPanX = details.globalPosition.dx;
                    });
                  },
                  onPanUpdate: (details) {
                    if (_isDragging) {
                      final deltaY = details.globalPosition.dy - _initialPanY;
                      final deltaX = _initialPanX - details.globalPosition.dx;
                      setState(() {
                        _topOffset = (_initialTop + deltaY).clamp(0.0, screenHeight - 500);
                        _rightOffset = (_initialRight + deltaX).clamp(0.0, screenWidth - constrainedWidth);
                      });
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.move,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isDragging ? Colors.grey[200] : Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: _isCollapsed
                          ? Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!, width: 1),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.keyboard_arrow_left,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCollapsed = false;
                                    });
                                  },
                                  tooltip: 'Expand Panel',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Collapse button
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_right),
                                  onPressed: () {
                                    setState(() {
                                      _isCollapsed = true;
                                    });
                                  },
                                  tooltip: 'Collapse Panel',
                                  iconSize: 16,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // Panel Content
                if (!_isCollapsed)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Resize Handle (on the left edge)
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _isResizing = true;
                            _initialWidth = _width;
                            _initialPanX = details.globalPosition.dx;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isResizing) {
                            final deltaX = _initialPanX - details.globalPosition.dx;
                            setState(() {
                              _width = (_initialWidth + deltaX).clamp(200.0, 600.0);
                            });
                          }
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _isResizing = false;
                          });
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: _isResizing ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Panel Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Objects Section (moved to first)
                              CollapsibleSection(
                                title: 'Objects',
                                child: SizedBox(
                                  height: 200, // Fixed height for the objects list
                                  child: ObjectsListPanel(service: widget.service),
                                ),
                              ),
                              
                              // Properties Section
                              CollapsibleSection(
                                title: 'Properties',
                                child: _buildPropertiesContent(),
                              ),
                              
                              // Auto-save Section
                              CollapsibleSection(
                                title: 'Auto-save',
                                child: _buildAutoSaveContent(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPropertiesContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Row(
            children: [
              const Text('Stroke: '),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final color = await _showColorPicker(context, widget.service.strokeColor);
                  if (color != null) widget.service.setStrokeColor(color);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.service.strokeColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text('Fill:     '),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final color = await _showColorPicker(context, widget.service.fillColor);
                  if (color != null) widget.service.setFillColor(color);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.service.fillColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sticky Note Background Color (only show if sticky note is selected)
          if (_hasSelectedStickyNote(widget.service))
            Row(
              children: [
                const Text('Note:     '),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final selectedStickyNote = _getSelectedStickyNote(widget.service);
                    if (selectedStickyNote != null) {
                      final color = await _showColorPicker(context, selectedStickyNote.backgroundColor);
                      if (color != null) widget.service.setStickyNoteBackgroundColor(color);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getSelectedStickyNote(widget.service)?.backgroundColor ?? Colors.yellow,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text('Width: '),
              Expanded(
                child: Slider(
                  value: widget.service.strokeWidth,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  onChanged: (value) => widget.service.setStrokeWidth(value),
                ),
              ),
              Text('${widget.service.strokeWidth.round()}'),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text('Zoom: ${(widget.service.transform.scale * 100).round()}%'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final currentScale = widget.service.transform.scale;
                  widget.service.updateTransform(Offset.zero, currentScale * 0.9);
                },
                tooltip: 'Zoom Out',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final currentScale = widget.service.transform.scale;
                  widget.service.updateTransform(Offset.zero, currentScale * 1.1);
                },
                tooltip: 'Zoom In',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  widget.service.updateTransform(Offset.zero, 1.0);
                },
                tooltip: 'Reset Zoom',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveContent() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Auto-save toggle
          Row(
            children: [
              const Text('Auto-save: '),
              Switch(
                value: widget.service.isAutoSaveEnabled,
                onChanged: (value) => widget.service.setAutoSaveEnabled(value),
              ),
            ],
          ),
          const Divider(),

          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showSaveDialog(context),
            tooltip: 'Save Canvas',
          ),

          // Load button
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _showLoadDialog(context),
            tooltip: 'Load Canvas',
          ),
        ],
      ),
    );
  }

  // Helper methods for sticky note detection
  bool _hasSelectedStickyNote(CanvasService service) {
    return service.objects.any((obj) => obj is StickyNote && obj.isSelected);
  }

  StickyNote? _getSelectedStickyNote(CanvasService service) {
    try {
      return service.objects.firstWhere((obj) => obj is StickyNote && obj.isSelected) as StickyNote;
    } catch (e) {
      return null;
    }
  }

  // Color picker method
  Future<Color?> _showColorPicker(BuildContext context, Color currentColor) async {
    return await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorOption(context, Colors.black),
              _buildColorOption(context, Colors.red),
              _buildColorOption(context, Colors.green),
              _buildColorOption(context, Colors.blue),
              _buildColorOption(context, Colors.yellow),
              _buildColorOption(context, Colors.orange),
              _buildColorOption(context, Colors.purple),
              _buildColorOption(context, Colors.pink),
              _buildColorOption(context, Colors.brown),
              _buildColorOption(context, Colors.grey),
              _buildColorOption(context, Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, Color color) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(color.toString().split('(0x')[1].split(')')[0]),
      onTap: () => Navigator.of(context).pop(color),
    );
  }

  // Save dialog method
  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController(text: 'my_canvas');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Canvas'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Canvas Name',
            hintText: 'Enter a name for your canvas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Save logic would go here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Canvas "$result" saved!')),
      );
    }
  }

  // Load dialog method
  Future<void> _showLoadDialog(BuildContext context) async {
    // Load logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Load functionality not implemented yet')),
    );
  }
}

