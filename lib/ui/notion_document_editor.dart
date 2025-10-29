import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/documents/notion_blocks.dart';
import '../models/documents/rich_text.dart';
import '../models/documents/block_types.dart';
import 'notion_block_editor.dart';

/// Notion-style document editor with rich blocks
class NotionDocumentEditor extends StatefulWidget {
  final List<NotionBlock> blocks;
  final Function(List<NotionBlock>)? onBlocksChanged;
  final String? title;
  final Function(String)? onTitleChanged;

  const NotionDocumentEditor({
    Key? key,
    required this.blocks,
    this.onBlocksChanged,
    this.title,
    this.onTitleChanged,
  }) : super(key: key);

  @override
  State<NotionDocumentEditor> createState() => _NotionDocumentEditorState();
}

class _NotionDocumentEditorState extends State<NotionDocumentEditor> {
  late List<NotionBlock> _blocks;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  String? _selectedBlockId;
  int _selectedBlockIndex = -1;

  @override
  void initState() {
    super.initState();
    _blocks = List.from(widget.blocks);
    _titleController = TextEditingController(text: widget.title ?? '');
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _updateBlocks() {
    widget.onBlocksChanged?.call(_blocks);
  }

  void _onBlockChanged(NotionBlock updatedBlock) {
    final index = _blocks.indexWhere((b) => b.id == updatedBlock.id);
    if (index != -1) {
      setState(() {
        _blocks[index] = updatedBlock;
      });
      _updateBlocks();
    }
  }

  void _onBlockCreated(NotionBlock newBlock) {
    // Find the current block index or use the end of the list
    final currentIndex = _selectedBlockIndex != -1 ? _selectedBlockIndex : _blocks.length - 1;
    final insertIndex = (currentIndex + 1).clamp(0, _blocks.length);
    
    setState(() {
      _blocks.insert(insertIndex, newBlock);
      _selectedBlockId = newBlock.id;
      _selectedBlockIndex = insertIndex;
    });
    
    _updateBlocks();
    
    // Force a rebuild to ensure the new block is rendered and can receive focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Trigger a rebuild to ensure the new block is properly rendered
      });
    });
  }

  void _onBlockDeleted(String blockId) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index != -1 && _blocks.length > 1) {
      setState(() {
        _blocks.removeAt(index);
        if (_selectedBlockIndex >= index) {
          _selectedBlockIndex = (_selectedBlockIndex - 1).clamp(0, _blocks.length - 1);
        }
        _selectedBlockId = _blocks.isNotEmpty ? _blocks[_selectedBlockIndex].id : null;
      });
      _updateBlocks();
    }
  }

  void _onBlockSelected(String blockId) {
    setState(() {
      _selectedBlockId = blockId;
      _selectedBlockIndex = _blocks.indexWhere((b) => b.id == blockId);
    });
  }

  void _onTitleChanged(String title) {
    widget.onTitleChanged?.call(title);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1);
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _indentBlock(-1);
        } else {
          _indentBlock(1);
        }
      }
    }
  }

  void _moveSelection(int direction) {
    if (_selectedBlockIndex == -1) return;
    
    final newIndex = (_selectedBlockIndex + direction).clamp(0, _blocks.length - 1);
    if (newIndex != _selectedBlockIndex) {
      setState(() {
        _selectedBlockIndex = newIndex;
        _selectedBlockId = _blocks[newIndex].id;
      });
    }
  }

  void _indentBlock(int direction) {
    if (_selectedBlockIndex == -1) return;
    
    // TODO: Implement block indentation
    // This would involve updating the block's parent/level in the hierarchy
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildDocumentContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Text(
            'Workspace > Documents',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          // Title
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            onChanged: _onTitleChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Untitled',
            ),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _blocks.length,
        itemBuilder: (context, index) {
          final block = _blocks[index];
          final isSelected = block.id == _selectedBlockId;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: NotionBlockEditor(
              block: block,
              isSelected: isSelected,
              onBlockChanged: _onBlockChanged,
              onBlockCreated: _onBlockCreated,
              onBlockDeleted: _onBlockDeleted,
              onTap: () => _onBlockSelected(block.id),
            ),
          );
        },
      ),
    );
  }
}

/// Floating document editor overlay
class NotionDocumentOverlay extends StatefulWidget {
  final List<NotionBlock> initialBlocks;
  final String? initialTitle;
  final Function(List<NotionBlock>, String?)? onSave;
  final VoidCallback? onClose;

  const NotionDocumentOverlay({
    Key? key,
    this.initialBlocks = const [],
    this.initialTitle,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<NotionDocumentOverlay> createState() => _NotionDocumentOverlayState();
}

class _NotionDocumentOverlayState extends State<NotionDocumentOverlay> {
  late List<NotionBlock> _blocks;
  late String? _title;

  @override
  void initState() {
    super.initState();
    _blocks = widget.initialBlocks.isEmpty 
        ? [_createDefaultBlock()]
        : List.from(widget.initialBlocks);
    _title = widget.initialTitle;
  }

  NotionBlock _createDefaultBlock() {
    return NotionBlock.fromJson({
      'id': 'block_${DateTime.now().millisecondsSinceEpoch}',
      'type': BlockType.paragraph.toString(),
      'richText': RichTextContent.empty().toJson(),
      'properties': {},
    });
  }

  void _onBlocksChanged(List<NotionBlock> blocks) {
    setState(() {
      _blocks = blocks;
    });
  }

  void _onTitleChanged(String? title) {
    setState(() {
      _title = title;
    });
  }

  void _save() {
    widget.onSave?.call(_blocks, _title);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: NotionDocumentEditor(
                  blocks: _blocks,
                  title: _title,
                  onBlocksChanged: _onBlocksChanged,
                  onTitleChanged: _onTitleChanged,
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _title ?? 'Untitled Document',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            '${_blocks.length} blocks',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
