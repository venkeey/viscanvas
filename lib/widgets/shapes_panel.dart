import 'package:flutter/material.dart';

// Shapes panel that appears when shapes tool is selected
class ShapesPanel extends StatelessWidget {
  final Function(String shape) onShapeSelected;
  final String? selectedShape;

  const ShapesPanel({
    Key? key,
    required this.onShapeSelected,
    this.selectedShape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.category, size: 16),
                SizedBox(width: 8),
                Text(
                  'Shapes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Shapes grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Basic shapes row
                Row(
                  children: [
                    _ShapeButton(
                      icon: Icons.rectangle_outlined,
                      label: 'Rectangle',
                      isSelected: selectedShape == 'rectangle',
                      onTap: () => onShapeSelected('rectangle'),
                    ),
                    const SizedBox(width: 8),
                    _ShapeButton(
                      icon: Icons.circle_outlined,
                      label: 'Circle',
                      isSelected: selectedShape == 'circle',
                      onTap: () => onShapeSelected('circle'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _ShapeButton(
                      icon: Icons.change_history,
                      label: 'Triangle',
                      isSelected: selectedShape == 'triangle',
                      onTap: () => onShapeSelected('triangle'),
                    ),
                    const SizedBox(width: 8),
                    _ShapeButton(
                      icon: Icons.keyboard_arrow_up,
                      label: 'Arrow',
                      isSelected: selectedShape == 'arrow',
                      onTap: () => onShapeSelected('arrow'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                
                // Advanced shapes
                const Text(
                  'Advanced',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _ShapeButton(
                      icon: Icons.diamond,
                      label: 'Diamond',
                      isSelected: selectedShape == 'diamond',
                      onTap: () => onShapeSelected('diamond'),
                    ),
                    const SizedBox(width: 8),
                    _ShapeButton(
                      icon: Icons.star_outline,
                      label: 'Star',
                      isSelected: selectedShape == 'star',
                      onTap: () => onShapeSelected('star'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _ShapeButton(
                      icon: Icons.favorite_border,
                      label: 'Heart',
                      isSelected: selectedShape == 'heart',
                      onTap: () => onShapeSelected('heart'),
                    ),
                    const SizedBox(width: 8),
                    _ShapeButton(
                      icon: Icons.cloud_outlined,
                      label: 'Cloud',
                      isSelected: selectedShape == 'cloud',
                      onTap: () => onShapeSelected('cloud'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.blue : Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.blue : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
