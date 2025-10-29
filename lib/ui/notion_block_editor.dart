import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/documents/notion_blocks.dart';
import '../models/documents/rich_text.dart';
import '../models/documents/block_types.dart';

/// Notion-style block editor with rich text and slash commands
class NotionBlockEditor extends StatefulWidget {
  final NotionBlock block;
  final Function(NotionBlock)? onBlockChanged;
  final Function(NotionBlock)? onBlockCreated;
  final Function(String)? onBlockDeleted;
  final bool isSelected;
  final VoidCallback? onTap;

  const NotionBlockEditor({
    Key? key,
    required this.block,
    this.onBlockChanged,
    this.onBlockCreated,
    this.onBlockDeleted,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotionBlockEditor> createState() => _NotionBlockEditorState();
}

class _NotionBlockEditorState extends State<NotionBlockEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showSlashMenu = false;
  String _slashQuery = '';
  int _slashStartIndex = 0;
  int _selectedSlashIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.richText.plainText);
    _focusNode = FocusNode();
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;
    
    // Check for slash command
    if (text.contains('/') && cursorPosition > 0) {
      final beforeCursor = text.substring(0, cursorPosition);
      final lastSlashIndex = beforeCursor.lastIndexOf('/');
      
      if (lastSlashIndex != -1) {
        final afterSlash = beforeCursor.substring(lastSlashIndex + 1);
        
        // Check if there are spaces or newlines AFTER the slash (not before)
        final hasInvalidChars = afterSlash.contains(' ') || afterSlash.contains('\n');
        
        if (!hasInvalidChars) {
          print('🔍 Setting slash menu to true with query: "$afterSlash"');
          setState(() {
            _showSlashMenu = true;
            _slashQuery = afterSlash;
            _slashStartIndex = lastSlashIndex;
            _selectedSlashIndex = 0; // Reset selection
          });
          // Don't update block content when showing slash menu
          return;
        }
      }
    }
    
    // Hide slash menu if we're not in a slash command context
    if (_showSlashMenu) {
      final beforeCursor = text.substring(0, cursorPosition);
      final lastSlashIndex = beforeCursor.lastIndexOf('/');
      
      // Hide if no slash found
      if (lastSlashIndex == -1) {
        setState(() {
          _showSlashMenu = false;
          _selectedSlashIndex = 0;
        });
      } else {
        // Check if there are spaces or newlines AFTER the slash
        final afterSlash = beforeCursor.substring(lastSlashIndex + 1);
        if (afterSlash.contains(' ') || afterSlash.contains('\n')) {
          setState(() {
            _showSlashMenu = false;
            _selectedSlashIndex = 0;
          });
        }
      }
    }
    
    // Update block content only if we're not showing the slash menu
    if (!_showSlashMenu) {
      _updateBlockContent();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showSlashMenu) {
      setState(() {
        _showSlashMenu = false;
      });
    }
  }

  void _updateBlockContent() {
    final newRichText = RichTextContent.plain(_controller.text);
    final updatedBlock = NotionBlock.fromJson({
      'id': widget.block.id,
      'type': widget.block.type.toString(),
      'richText': newRichText.toJson(),
      'properties': widget.block.properties,
    });
    widget.onBlockChanged?.call(updatedBlock);
  }

  void _handleSlashCommand(BlockType blockType) {
    final text = _controller.text;
    final beforeSlash = text.substring(0, _slashStartIndex);
    
    // Create new block with selected type
    final newBlock = NotionBlock.fromJson({
      'id': 'block_${DateTime.now().millisecondsSinceEpoch}',
      'type': blockType.toString(),
      'richText': RichTextContent.empty().toJson(),
      'properties': {},
    });
    
    // Update current block
    _controller.text = beforeSlash;
    _updateBlockContent();
    
    // Create new block
    widget.onBlockCreated?.call(newBlock);
    
    setState(() {
      _showSlashMenu = false;
      _selectedSlashIndex = 0;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_showSlashMenu) {
        // Handle slash menu navigation
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          final filteredCommands = _getSlashCommands()
              .where((cmd) => cmd.title.toLowerCase().contains(_slashQuery.toLowerCase()))
              .toList();
          setState(() {
            _selectedSlashIndex = (_selectedSlashIndex + 1) % filteredCommands.length;
          });
          return;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          final filteredCommands = _getSlashCommands()
              .where((cmd) => cmd.title.toLowerCase().contains(_slashQuery.toLowerCase()))
              .toList();
          setState(() {
            _selectedSlashIndex = (_selectedSlashIndex - 1 + filteredCommands.length) % filteredCommands.length;
          });
          return;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          // Select the highlighted command
          final filteredCommands = _getSlashCommands()
              .where((cmd) => cmd.title.toLowerCase().contains(_slashQuery.toLowerCase()))
              .toList();
          if (_selectedSlashIndex < filteredCommands.length) {
            _handleSlashCommand(filteredCommands[_selectedSlashIndex].blockType);
          }
          return;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            _showSlashMenu = false;
            _selectedSlashIndex = 0;
          });
          return;
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controller.text.isEmpty) {
          // Delete block if empty
          widget.onBlockDeleted?.call(widget.block.id);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (!HardwareKeyboard.instance.isShiftPressed) {
          // Only create new paragraph block if slash menu is not open
          if (!_showSlashMenu) {
            final newBlock = NotionBlock.fromJson({
              'id': 'block_${DateTime.now().millisecondsSinceEpoch}',
              'type': BlockType.paragraph.toString(),
              'richText': RichTextContent.empty().toJson(),
              'properties': {},
            });
            widget.onBlockCreated?.call(newBlock);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isSelected 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: widget.isSelected 
                  ? Border.all(color: Colors.blue, width: 1) 
                  : null,
            ),
            child: GestureDetector(
              onTap: widget.onTap,
              child: _buildBlockContent(),
            ),
          ),
          if (_showSlashMenu) 
            Positioned(
              top: 50,
              left: 50,
              child: Container(
                width: 300,
                height: 200,
                color: Colors.red,
                child: const Center(
                  child: Text('SLASH MENU', style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockContent() {
    switch (widget.block.type) {
      case BlockType.paragraph:
        return _buildParagraphEditor();
      case BlockType.heading1:
        return _buildHeadingEditor(32, FontWeight.bold);
      case BlockType.heading2:
        return _buildHeadingEditor(24, FontWeight.bold);
      case BlockType.heading3:
        return _buildHeadingEditor(20, FontWeight.bold);
      case BlockType.bulletedListItem:
        return _buildListEditor('•');
      case BlockType.numberedListItem:
        return _buildListEditor('1.');
      case BlockType.toDo:
        return _buildToDoEditor();
      case BlockType.code:
        return _buildCodeEditor();
      case BlockType.quote:
        return _buildQuoteEditor();
      default:
        return _buildParagraphEditor();
    }
  }

  Widget _buildParagraphEditor() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'Type "/" for commands',
      ),
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }

  Widget _buildHeadingEditor(double fontSize, FontWeight fontWeight) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'Heading',
      ),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.2,
      ),
    );
  }

  Widget _buildListEditor(String prefix) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Text(prefix, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'List item',
            ),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildToDoEditor() {
    final isChecked = widget.block.properties['checked'] ?? false;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Checkbox(
            value: isChecked,
            onChanged: (value) {
              final updatedBlock = NotionBlock.fromJson({
                'id': widget.block.id,
                'type': widget.block.type.toString(),
                'richText': widget.block.richText.toJson(),
                'properties': {
                  ...widget.block.properties,
                  'checked': value ?? false,
                },
              });
              widget.onBlockChanged?.call(updatedBlock);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'To-do',
            ),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked ? Colors.grey : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Code',
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildQuoteEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(left: BorderSide(color: Colors.grey, width: 4)),
        color: Colors.grey.shade50,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Quote',
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSlashMenu() {
    print('🔍 Building slash menu with query: "$_slashQuery"');
    final filteredCommands = _getSlashCommands()
        .where((cmd) => cmd.title.toLowerCase().contains(_slashQuery.toLowerCase()))
        .toList();
    print('🔍 Found ${filteredCommands.length} filtered commands');

    // Calculate menu dimensions based on content
    final itemHeight = 60.0; // Height per item
    final maxVisibleItems = 6; // Maximum items to show before scrolling
    final menuWidth = 320.0; // Fixed width for better readability
    final menuHeight = (filteredCommands.length * itemHeight).clamp(
      itemHeight * 2, // Minimum 2 items
      itemHeight * maxVisibleItems, // Maximum 6 items
    );

    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 50)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Get the position of the text field
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null || !renderBox.hasSize) return const SizedBox.shrink();

            final textFieldPosition = renderBox.localToGlobal(Offset.zero);
            final textFieldSize = renderBox.size;
            final screenSize = MediaQuery.of(context).size;

        // Calculate optimal position
        double menuTop;
        double menuLeft;

        // Determine if we should show menu above or below the text field
        final spaceBelow = screenSize.height - textFieldPosition.dy - textFieldSize.height;
        final spaceAbove = textFieldPosition.dy;

        if (spaceBelow >= menuHeight + 20 || spaceBelow > spaceAbove) {
          // Show below the text field
          menuTop = textFieldPosition.dy + textFieldSize.height + 8;
        } else {
          // Show above the text field
          menuTop = textFieldPosition.dy - menuHeight - 8;
        }

        // Center horizontally, but keep within screen bounds
        menuLeft = (textFieldPosition.dx + textFieldSize.width / 2 - menuWidth / 2)
            .clamp(16, screenSize.width - menuWidth - 16);

        return Positioned(
          top: 100, // Fixed position for testing
          left: 100, // Fixed position for testing
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black.withOpacity(0.3),
            child: Container(
              width: menuWidth,
              height: menuHeight,
              decoration: BoxDecoration(
                color: Colors.red.shade100, // Make it more visible for testing
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2), // Make border more visible
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Insert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredCommands.length} items',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu items
                  Expanded(
                    child: filteredCommands.isEmpty 
                        ? const Center(child: Text('No commands found', style: TextStyle(color: Colors.black)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filteredCommands.length,
                            itemBuilder: (context, index) {
                              final command = filteredCommands[index];
                              return _buildSlashMenuItem(command, index == _selectedSlashIndex);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildSlashMenuItem(SlashCommand command, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _handleSlashCommand(command.blockType);
            },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1) : null,
            ),
            child: Row(
              children: [
                // Icon with background
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getCommandColor(command.blockType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    command.icon,
                    size: 18,
                    color: _getCommandColor(command.blockType),
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        command.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Keyboard shortcut hint
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ENTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCommandColor(BlockType blockType) {
    switch (blockType) {
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return Colors.blue;
      case BlockType.bulletedListItem:
      case BlockType.numberedListItem:
        return Colors.green;
      case BlockType.toDo:
        return Colors.orange;
      case BlockType.code:
        return Colors.purple;
      case BlockType.quote:
        return Colors.teal;
      case BlockType.callout:
        return Colors.amber;
      case BlockType.image:
      case BlockType.video:
        return Colors.pink;
      case BlockType.table:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  List<SlashCommand> _getSlashCommands() {
    return [
      SlashCommand(
        title: 'Text',
        description: 'Just start typing with plain text',
        icon: Icons.text_fields,
        blockType: BlockType.paragraph,
      ),
      SlashCommand(
        title: 'Heading 1',
        description: 'Big section heading',
        icon: Icons.title,
        blockType: BlockType.heading1,
      ),
      SlashCommand(
        title: 'Heading 2',
        description: 'Medium section heading',
        icon: Icons.title,
        blockType: BlockType.heading2,
      ),
      SlashCommand(
        title: 'Heading 3',
        description: 'Small section heading',
        icon: Icons.title,
        blockType: BlockType.heading3,
      ),
      SlashCommand(
        title: 'Bulleted list',
        description: 'Create a simple bulleted list',
        icon: Icons.format_list_bulleted,
        blockType: BlockType.bulletedListItem,
      ),
      SlashCommand(
        title: 'Numbered list',
        description: 'Create a list with numbering',
        icon: Icons.format_list_numbered,
        blockType: BlockType.numberedListItem,
      ),
      SlashCommand(
        title: 'To-do',
        description: 'Track tasks with a to-do list',
        icon: Icons.check_box_outline_blank,
        blockType: BlockType.toDo,
      ),
      SlashCommand(
        title: 'Toggle',
        description: 'Toggleable content',
        icon: Icons.keyboard_arrow_right,
        blockType: BlockType.toggle,
      ),
      SlashCommand(
        title: 'Code',
        description: 'Capture a code snippet',
        icon: Icons.code,
        blockType: BlockType.code,
      ),
      SlashCommand(
        title: 'Quote',
        description: 'Capture a quote',
        icon: Icons.format_quote,
        blockType: BlockType.quote,
      ),
      SlashCommand(
        title: 'Callout',
        description: 'Make writing stand out',
        icon: Icons.sticky_note_2,
        blockType: BlockType.callout,
      ),
      SlashCommand(
        title: 'Divider',
        description: 'Visually divide blocks',
        icon: Icons.horizontal_rule,
        blockType: BlockType.divider,
      ),
      SlashCommand(
        title: 'Image',
        description: 'Upload or embed an image',
        icon: Icons.image,
        blockType: BlockType.image,
      ),
      SlashCommand(
        title: 'Video',
        description: 'Embed a video',
        icon: Icons.video_library,
        blockType: BlockType.video,
      ),
      SlashCommand(
        title: 'File',
        description: 'Upload any type of file',
        icon: Icons.attach_file,
        blockType: BlockType.file,
      ),
      SlashCommand(
        title: 'Embed',
        description: 'Embed from URL',
        icon: Icons.link,
        blockType: BlockType.embed,
      ),
      SlashCommand(
        title: 'Bookmark',
        description: 'Save a link as a bookmark',
        icon: Icons.bookmark,
        blockType: BlockType.bookmark,
      ),
      SlashCommand(
        title: 'Table',
        description: 'Create a table',
        icon: Icons.table_chart,
        blockType: BlockType.table,
      ),
      SlashCommand(
        title: 'Table of contents',
        description: 'Generate a table of contents',
        icon: Icons.list_alt,
        blockType: BlockType.tableOfContents,
      ),
    ];
  }
}

class SlashCommand {
  final String title;
  final String description;
  final IconData icon;
  final BlockType blockType;

  const SlashCommand({
    required this.title,
    required this.description,
    required this.icon,
    required this.blockType,
  });
}
