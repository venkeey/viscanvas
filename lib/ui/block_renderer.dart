import 'package:flutter/material.dart';
import '../models/documents/block_types.dart';

/// Basic block renderer for document display
class BlockRenderer extends StatelessWidget {
  final Block block;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(String)? onTextChanged;

  const BlockRenderer({
    Key? key,
    required this.block,
    this.isSelected = false,
    this.onTap,
    this.onTextChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isSelected ? Border.all(color: Colors.blue, width: 1) : null,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _buildBlockContent(context),
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    final text = block.getPlainText();

    switch (block.type) {
      case BlockType.heading1:
        return Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );

      case BlockType.heading2:
        return Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );

      case BlockType.heading3:
        return Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );

      case BlockType.bulletedListItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );

      case BlockType.numberedListItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );

      case BlockType.quote:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: const Border(left: BorderSide(color: Colors.grey, width: 4)),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );

      case BlockType.code:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        );

      default:
        return Text(text, style: Theme.of(context).textTheme.bodyMedium);
    }
  }
}

/// Simple inline text editor for blocks
class BlockEditor extends StatefulWidget {
  final Block block;
  final Function(String)? onTextChanged;
  final VoidCallback? onSave;

  const BlockEditor({
    Key? key,
    required this.block,
    this.onTextChanged,
    this.onSave,
  }) : super(key: key);

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.getPlainText());
    _focusNode = FocusNode();

    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: widget.onTextChanged,
        onSubmitted: (_) {
          widget.onSave?.call();
        },
      ),
    );
  }
}