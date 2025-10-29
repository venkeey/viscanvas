import 'package:flutter/material.dart';
import 'rich_text.dart';
import 'block_types.dart';

/// Notion-style block with rich text content
abstract class NotionBlock extends Block {
  final RichTextContent richText;
  final Map<String, dynamic> properties;

  NotionBlock({
    required super.id,
    required super.type,
    required this.richText,
    this.properties = const {},
  }) : super(
          content: {'richText': richText.toJson()},
          properties: properties,
        );

  @override
  String getPlainText() => richText.plainText;

  @override
  Widget render() => _buildBlockWidget();

  Widget _buildBlockWidget() {
    switch (type) {
      case BlockType.paragraph:
        return _buildParagraph();
      case BlockType.heading1:
        return _buildHeading1();
      case BlockType.heading2:
        return _buildHeading2();
      case BlockType.heading3:
        return _buildHeading3();
      case BlockType.bulletedListItem:
        return _buildBulletedList();
      case BlockType.numberedListItem:
        return _buildNumberedList();
      case BlockType.toDo:
        return _buildToDo();
      case BlockType.toggle:
        return _buildToggle();
      case BlockType.code:
        return _buildCode();
      case BlockType.quote:
        return _buildQuote();
      case BlockType.callout:
        return _buildCallout();
      case BlockType.divider:
        return _buildDivider();
      case BlockType.image:
        return _buildImage();
      case BlockType.video:
        return _buildVideo();
      case BlockType.file:
        return _buildFile();
      case BlockType.embed:
        return _buildEmbed();
      case BlockType.bookmark:
        return _buildBookmark();
      case BlockType.table:
        return _buildTable();
      case BlockType.tableRow:
        return _buildTableRow();
      case BlockType.columnList:
        return _buildColumnList();
      case BlockType.column:
        return _buildColumn();
      case BlockType.tableOfContents:
        return _buildTableOfContents();
      case BlockType.breadcrumb:
        return _buildBreadcrumb();
      case BlockType.linkToPage:
        return _buildLinkToPage();
      case BlockType.childPage:
        return _buildChildPage();
      case BlockType.childDatabase:
        return _buildChildDatabase();
      case BlockType.syncedBlock:
        return _buildSyncedBlock();
    }
  }

  Widget _buildParagraph() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichTextWidget(
        content: richText,
        baseStyle: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  Widget _buildHeading1() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichTextWidget(
        content: richText,
        baseStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeading2() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichTextWidget(
        content: richText,
        baseStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildHeading3() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichTextWidget(
        content: richText,
        baseStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBulletedList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Text('•', style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: RichTextWidget(
              content: richText,
              baseStyle: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedList() {
    final number = properties['number'] ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Text('$number.', style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: RichTextWidget(
              content: richText,
              baseStyle: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToDo() {
    final isChecked = properties['checked'] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Checkbox(
              value: isChecked,
              onChanged: (value) {
                // TODO: Handle checkbox change
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: RichTextWidget(
              content: richText,
              baseStyle: TextStyle(
                fontSize: 16,
                height: 1.5,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    final isExpanded = properties['expanded'] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: RichTextWidget(
                  content: richText,
                  baseStyle: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            // TODO: Render child blocks
            Container(
              padding: const EdgeInsets.only(left: 20),
              child: const Text('Child blocks would go here'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCode() {
    final language = properties['language'] ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: RichTextWidget(
              content: richText,
              baseStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(left: BorderSide(color: Colors.grey, width: 4)),
        color: Colors.grey.shade50,
      ),
      child: RichTextWidget(
        content: richText,
        baseStyle: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCallout() {
    final icon = properties['icon'] ?? '💡';
    final color = properties['color'] ?? 'blue';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCalloutColor(color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getCalloutColor(color).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: RichTextWidget(
              content: richText,
              baseStyle: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildImage() {
    final url = properties['url'] ?? '';
    final caption = properties['caption'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final url = properties['url'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: url.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 48),
                ),
              )
            : const Center(
                child: Icon(Icons.video_library, size: 48, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildFile() {
    final name = properties['name'] ?? 'Untitled File';
    final size = properties['size'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (size.isNotEmpty)
                  Text(
                    size,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const Icon(Icons.download, size: 16),
        ],
      ),
    );
  }

  Widget _buildEmbed() {
    final url = properties['url'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Embed content would be rendered here'),
        ],
      ),
    );
  }

  Widget _buildBookmark() {
    final url = properties['url'] ?? '';
    final title = properties['title'] ?? '';
    final description = properties['description'] ?? '';
    final imageUrl = properties['imageUrl'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final columns = properties['columns'] ?? 3;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: List.generate(columns, (index) {
                return Expanded(
                  child: Text(
                    'Column ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }),
            ),
          ),
          // Table rows placeholder
          Container(
            padding: const EdgeInsets.all(12),
            child: const Text('Table rows would go here'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Text('Table row content'),
    );
  }

  Widget _buildColumnList() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: const Text('Column list content'),
    );
  }

  Widget _buildColumn() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: const Text('Column content'),
    );
  }

  Widget _buildTableOfContents() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Text('Table of Contents'),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: const Text('Breadcrumb navigation'),
    );
  }

  Widget _buildLinkToPage() {
    final pageTitle = properties['pageTitle'] ?? 'Untitled Page';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pageTitle,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildChildPage() {
    final pageTitle = properties['pageTitle'] ?? 'Untitled Page';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildChildDatabase() {
    final databaseTitle = properties['databaseTitle'] ?? 'Untitled Database';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              databaseTitle,
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSyncedBlock() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.sync, color: Colors.orange),
          SizedBox(width: 8),
          Text('Synced block content'),
        ],
      ),
    );
  }

  Color _getCalloutColor(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'richText': richText.toJson(),
      'properties': properties,
    };
  }

  factory NotionBlock.fromJson(Map<String, dynamic> json) {
    final type = BlockType.values.firstWhere(
      (t) => t.toString() == json['type'],
    );
    
    final richText = RichTextContent.fromJson(
      Map<String, dynamic>.from(json['richText'] ?? {})
    );
    final properties = Map<String, dynamic>.from(json['properties'] ?? {});

    return _NotionBlockImpl(
      id: json['id'],
      type: type,
      richText: richText,
      properties: properties,
    );
  }
}

/// Implementation class for NotionBlock
class _NotionBlockImpl extends NotionBlock {
  _NotionBlockImpl({
    required super.id,
    required super.type,
    required super.richText,
    super.properties,
  });

  @override
  Block clone() {
    return _NotionBlockImpl(
      id: '${id}_copy',
      type: type,
      richText: richText,
      properties: Map.from(properties),
    );
  }
}
