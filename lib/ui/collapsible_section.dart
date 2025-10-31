import 'package:flutter/material.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Widget? trailing; // optional action on the right side of header

  const CollapsibleSection({
    Key? key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.padding,
    this.margin,
    this.trailing,
  }) : super(key: key);

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: widget.margin ?? const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    // Keep actions next to the collapse arrow
                    widget.trailing!,
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Content (collapsible)
          if (_isExpanded)
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(12.0),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
