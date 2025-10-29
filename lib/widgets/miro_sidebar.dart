import 'package:flutter/material.dart';

// Miro-style sidebar with all the tools from the image
class MiroSidebar extends StatefulWidget {
  final Function(String tool) onToolSelected;
  final String? selectedTool;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const MiroSidebar({
    Key? key,
    required this.onToolSelected,
    this.selectedTool,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  }) : super(key: key);

  @override
  State<MiroSidebar> createState() => _MiroSidebarState();
}

class _MiroSidebarState extends State<MiroSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI/Templates (Sparkles) - Purple highlighted
            _SidebarButton(
            icon: Icons.auto_awesome,
            isSelected: widget.selectedTool == 'ai_templates',
            isHighlighted: true,
            highlightColor: Colors.purple,
            onTap: () => widget.onToolSelected('ai_templates'),
            tooltip: 'AI Templates & Suggestions',
          ),
          
          const SizedBox(height: 8),
          
          // Select/Cursor (Blue highlighted) - using near_me icon for better E2E test compatibility
          _SidebarButton(
            icon: Icons.near_me,
            isSelected: widget.selectedTool == 'select',
            isHighlighted: true,
            highlightColor: Colors.blue,
            onTap: () => widget.onToolSelected('select'),
            tooltip: 'Select Tool (V)',
          ),
          
          const SizedBox(height: 4),
          
          // Pan Tool
          _SidebarButton(
            icon: Icons.pan_tool,
            isSelected: widget.selectedTool == 'pan',
            onTap: () => widget.onToolSelected('pan'),
            tooltip: 'Pan Tool (P)',
          ),
          
          const SizedBox(height: 8),
          
          // Frame/Layout
          _SidebarButton(
            icon: Icons.crop_free,
            isSelected: widget.selectedTool == 'frame',
            onTap: () => widget.onToolSelected('frame'),
            tooltip: 'Frame/Layout Tool',
          ),
          
          const SizedBox(height: 4),
          
          // Text Tool
          _SidebarButton(
            icon: Icons.text_fields,
            isSelected: widget.selectedTool == 'text',
            onTap: () => widget.onToolSelected('text'),
            tooltip: 'Text Tool (T)',
          ),
          
          const SizedBox(height: 4),
          
          // Sticky Note
          _SidebarButton(
            icon: Icons.note_add,
            isSelected: widget.selectedTool == 'sticky_note',
            onTap: () => widget.onToolSelected('sticky_note'),
            tooltip: 'Sticky Note',
          ),

          const SizedBox(height: 4),

          // Document Block
          _SidebarButton(
            icon: Icons.description,
            isSelected: widget.selectedTool == 'document_block',
            onTap: () => widget.onToolSelected('document_block'),
            tooltip: 'Document Block (D)',
          ),

          const SizedBox(height: 4),

          // Shapes/Objects (shows panel)
          _SidebarButton(
            icon: Icons.category,
            isSelected: widget.selectedTool == 'shapes',
            onTap: () => widget.onToolSelected('shapes'),
            tooltip: 'Shapes & Objects',
          ),

          const SizedBox(height: 4),

          // Rectangle (direct access)
          _SidebarButton(
            icon: Icons.rectangle_outlined,
            isSelected: widget.selectedTool == 'rectangle',
            onTap: () => widget.onToolSelected('rectangle'),
            tooltip: 'Rectangle (R)',
          ),

          const SizedBox(height: 4),

          // Circle (direct access)
          _SidebarButton(
            icon: Icons.circle_outlined,
            isSelected: widget.selectedTool == 'circle',
            onTap: () => widget.onToolSelected('circle'),
            tooltip: 'Circle (O)',
          ),

          const SizedBox(height: 4),
          
          // Pen/Drawing
          _SidebarButton(
            icon: Icons.brush,
            isSelected: widget.selectedTool == 'pen',
            onTap: () => widget.onToolSelected('pen'),
            tooltip: 'Pen/Drawing Tool (B)',
          ),

          const SizedBox(height: 4),

          // Connector Tool - using timeline icon for better visual identification
          _SidebarButton(
            icon: Icons.timeline,
            isSelected: widget.selectedTool == 'connector',
            onTap: () => widget.onToolSelected('connector'),
            tooltip: 'Connector Tool (C)',
          ),

          const SizedBox(height: 4),
          
          // Comment/Chat
          _SidebarButton(
            icon: Icons.chat_bubble_outline,
            isSelected: widget.selectedTool == 'comment',
            onTap: () => widget.onToolSelected('comment'),
            tooltip: 'Comment Tool',
          ),
          
          const SizedBox(height: 4),
          
          // Table/Grid
          _SidebarButton(
            icon: Icons.grid_on,
            isSelected: widget.selectedTool == 'table',
            onTap: () => widget.onToolSelected('table'),
            tooltip: 'Table/Grid Tool',
          ),
          
          const SizedBox(height: 4),
          
          // Upload
          _SidebarButton(
            icon: Icons.upload_file,
            isSelected: widget.selectedTool == 'upload',
            onTap: () => widget.onToolSelected('upload'),
            tooltip: 'Upload Files',
          ),

          const SizedBox(height: 40), // Separator space instead of Spacer

          // Plus/Add More
          _SidebarButton(
            icon: Icons.add,
            isSelected: false,
            onTap: () => widget.onToolSelected('add_more'),
            tooltip: 'Add More Tools',
          ),
          
          const SizedBox(height: 8),
          
          // Undo
          _SidebarButton(
            icon: Icons.undo,
            isSelected: false,
            isEnabled: widget.canUndo,
            onTap: widget.canUndo ? widget.onUndo : null,
            tooltip: 'Undo (Ctrl+Z)',
          ),
          
          const SizedBox(height: 4),
          
          // Redo (grayed out when not available)
          _SidebarButton(
            icon: Icons.redo,
            isSelected: false,
            isEnabled: widget.canRedo,
            isGrayedOut: !widget.canRedo,
            onTap: widget.canRedo ? widget.onRedo : null,
            tooltip: 'Redo (Ctrl+Y)',
          ),
          
          const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isHighlighted;
  final Color? highlightColor;
  final bool isEnabled;
  final bool isGrayedOut;
  final VoidCallback? onTap;
  final String tooltip;

  const _SidebarButton({
    required this.icon,
    required this.isSelected,
    this.isHighlighted = false,
    this.highlightColor,
    this.isEnabled = true,
    this.isGrayedOut = false,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.black87;
    Color? backgroundColor;
    
    if (isGrayedOut) {
      iconColor = Colors.grey.shade400;
    } else if (isHighlighted) {
      iconColor = highlightColor ?? Colors.purple;
      backgroundColor = (highlightColor ?? Colors.purple).withOpacity(0.1);
    } else if (isSelected) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (!isEnabled) {
      iconColor = Colors.grey.shade400;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected || isHighlighted
              ? Border.all(
                  color: isHighlighted 
                      ? (highlightColor ?? Colors.purple)
                      : Colors.blue,
                  width: 2,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isEnabled ? onTap : null,
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tool definitions for reference
class MiroTools {
  static const Map<String, String> toolDescriptions = {
    'ai_templates': 'AI-powered templates and suggestions',
    'select': 'Select and move objects on the canvas',
    'frame': 'Create frames and layouts for organizing content',
    'text': 'Add text boxes and labels',
    'sticky_note': 'Create sticky notes for quick ideas',
    'document_block': 'Create document blocks for rich text editing',
    'shapes': 'Add geometric shapes (rectangles, circles, etc.)',
    'pen': 'Freehand drawing and annotations',
    'connector': 'Connect shapes with lines and arrows',
    'comment': 'Add comments and discussions',
    'table': 'Create tables and structured data',
    'upload': 'Upload files, images, and documents',
    'add_more': 'Access additional tools and features',
  };

  static const Map<String, String> keyboardShortcuts = {
    'select': 'V',
    'pan': 'P',
    'text': 'T',
    'pen': 'B',
    'frame': 'F',
    'shapes': 'S',
    'connector': 'C',
    'document_block': 'D',
  };
}
