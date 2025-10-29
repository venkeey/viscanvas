import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// 1. Enhanced Shape-Aware Data Models
abstract class NodeShape {
  String get type;
  Path get path;
  Rect get bounds;
  List<Offset> get suggestedConnectionPoints;
  Offset getClosestEdgePoint(Offset fromPoint);
  bool containsPoint(Offset point);
}

class RectangleShape implements NodeShape {
  final Rect bounds;
  
  RectangleShape(this.bounds);
  
  @override String get type => 'rectangle';
  
  @override Path get path => Path()..addRect(bounds);
  
  @override List<Offset> get suggestedConnectionPoints => [
    Offset(bounds.center.dx, bounds.top),    // Top
    Offset(bounds.right, bounds.center.dy),  // Right
    Offset(bounds.center.dx, bounds.bottom), // Bottom
    Offset(bounds.left, bounds.center.dy),   // Left
  ];
  
  @override Offset getClosestEdgePoint(Offset fromPoint) {
    final center = bounds.center;
    final dx = fromPoint.dx - center.dx;
    final dy = fromPoint.dy - center.dy;
    
    // Calculate intersection with rectangle bounds
    if (dx.abs() > dy.abs()) {
      // Horizontal dominance
      return dx > 0 
          ? Offset(bounds.right, center.dy)
          : Offset(bounds.left, center.dy);
    } else {
      // Vertical dominance
      return dy > 0
          ? Offset(center.dx, bounds.bottom)
          : Offset(center.dx, bounds.top);
    }
  }
  
  @override bool containsPoint(Offset point) => bounds.contains(point);
}

class CircleShape implements NodeShape {
  final Offset center;
  final double radius;
  
  CircleShape(this.center, this.radius);
  
  @override String get type => 'circle';
  
  @override Path get path => Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  
  @override Rect get bounds => Rect.fromCircle(center: center, radius: radius);
  
  @override List<Offset> get suggestedConnectionPoints {
    // 8 points around the circle
    return List.generate(8, (index) {
      final angle = 2 * pi * index / 8;
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });
  }
  
  @override Offset getClosestEdgePoint(Offset fromPoint) {
    final angle = atan2(fromPoint.dy - center.dy, fromPoint.dx - center.dx);
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }
  
  @override bool containsPoint(Offset point) {
    return (point.dx - center.dx) * (point.dx - center.dx) + 
           (point.dy - center.dy) * (point.dy - center.dy) <= radius * radius;
  }
}

class TriangleShape implements NodeShape {
  final Offset center;
  final double size;
  
  TriangleShape(this.center, this.size);
  
  @override String get type => 'triangle';
  
  @override Path get path {
    final path = Path();
    path.moveTo(center.dx, center.dy - size); // Top
    path.lineTo(center.dx - size, center.dy + size); // Bottom left
    path.lineTo(center.dx + size, center.dy + size); // Bottom right
    path.close();
    return path;
  }
  
  @override Rect get bounds => Rect.fromCenter(
    center: center,
    width: size * 2,
    height: size * 2,
  );
  
  @override List<Offset> get suggestedConnectionPoints {
    return [
      Offset(center.dx, center.dy - size), // Top vertex
      Offset(center.dx + size * 0.7, center.dy + size * 0.3), // Right side
      Offset(center.dx - size * 0.7, center.dy + size * 0.3), // Left side
      Offset(center.dx, center.dy + size * 0.6), // Bottom center
    ];
  }
  
  @override Offset getClosestEdgePoint(Offset fromPoint) {
    final vertices = [
      Offset(center.dx, center.dy - size), // Top
      Offset(center.dx - size, center.dy + size), // Bottom left
      Offset(center.dx + size, center.dy + size), // Bottom right
    ];
    
    // Find closest point on triangle edges
    double minDistance = double.infinity;
    Offset closestPoint = vertices[0];
    
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      
      final edgePoint = _closestPointOnLine(fromPoint, p1, p2);
      final distance = (fromPoint - edgePoint).distance;
      
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = edgePoint;
      }
    }
    
    return closestPoint;
  }
  
  Offset _closestPointOnLine(Offset point, Offset lineStart, Offset lineEnd) {
    final lineVector = lineEnd - lineStart;
    final pointVector = point - lineStart;
    
    final lineLength = lineVector.distance;
    final normalizedVector = lineVector / lineLength;
    
    double t = (pointVector.dx * normalizedVector.dx + pointVector.dy * normalizedVector.dy) / lineLength;
    t = t.clamp(0.0, 1.0);
    
    return lineStart + lineVector * t;
  }
  
  @override bool containsPoint(Offset point) {
    // Simple triangle point-in-polygon test
    final vertices = [
      Offset(center.dx, center.dy - size),
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx + size, center.dy + size),
    ];
    
    return _pointInPolygon(point, vertices);
  }
  
  bool _pointInPolygon(Offset point, List<Offset> vertices) {
    int i, j = vertices.length - 1;
    bool oddNodes = false;
    
    for (i = 0; i < vertices.length; i++) {
      if ((vertices[i].dy < point.dy && vertices[j].dy >= point.dy) ||
          (vertices[j].dy < point.dy && vertices[i].dy >= point.dy)) {
        if (vertices[i].dx + (point.dy - vertices[i].dy) / 
            (vertices[j].dy - vertices[i].dy) * (vertices[j].dx - vertices[i].dx) < point.dx) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    
    return oddNodes;
  }
}

// 2. Enhanced Node with Shape Support
class Node {
  final String id;
  Offset position;
  NodeShape shape;
  final List<ConnectionPoint> connectionPoints = [];

  Node(this.id, this.position, this.shape);

  void updateShape(NodeShape newShape) {
    shape = newShape;
    // Update connection points based on new shape
    connectionPoints.clear();
    connectionPoints.addAll(
      shape.suggestedConnectionPoints.map((point) => ConnectionPoint(point, shape)),
    );
  }

  Rect get bounds => shape.bounds;

  Offset getClosestConnectionPoint(Offset fromPoint) {
    return shape.getClosestEdgePoint(fromPoint);
  }

  bool containsPoint(Offset point) {
    return shape.containsPoint(point - position);
  }
}

class ConnectionPoint {
  final Offset position;
  final NodeShape shape;

  ConnectionPoint(this.position, this.shape);
}

// 3. Freehand Drawing System
class FreehandStroke {
  final List<Offset> points = [];
  final Paint paint;
  
  FreehandStroke({Color color = Colors.blue, double strokeWidth = 3.0})
      : paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
  
  void addPoint(Offset point) {
    points.add(point);
  }
  
  Path get path {
    final path = Path();
    if (points.isEmpty) return path;
    
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }
  
  // Analyze stroke to detect connection intent
  StrokeAnalysis analyzeStroke(List<Node> nodes) {
    if (points.length < 5) return StrokeAnalysis(); // Too short
    
    final startPoint = points.first;
    final endPoint = points.last;
    
    // Find nodes near start and end of stroke
    final startNode = _findClosestNode(startPoint, nodes);
    final endNode = _findClosestNode(endPoint, nodes);
    
    return StrokeAnalysis(
      startNode: startNode,
      endNode: endNode,
      confidence: _calculateConfidence(startNode, endNode, points),
    );
  }
  
  Node? _findClosestNode(Offset point, List<Node> nodes) {
    for (final node in nodes) {
      // Expand hit area for connection detection
      final expandedBounds = node.bounds.inflate(30.0);
      if (expandedBounds.contains(point)) {
        return node;
      }
    }
    return null;
  }
  
  double _calculateConfidence(Node? startNode, Node? endNode, List<Offset> points) {
    if (startNode == null || endNode == null) return 0.0;
    
    // Calculate straightness of line (confidence decreases with squiggles)
    double totalDeviation = 0.0;
    final straightLine = Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..lineTo(points.last.dx, points.last.dy);
    
    // Simple deviation calculation
    for (final point in points) {
      // This is simplified - you'd want a more robust calculation
      totalDeviation += _distanceToLine(point, points.first, points.last);
    }
    
    final avgDeviation = totalDeviation / points.length;
    final straightness = 1.0 / (1.0 + avgDeviation * 0.1);
    
    return straightness.clamp(0.0, 1.0);
  }
  
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final normalLength = sqrt(pow(lineEnd.dx - lineStart.dx, 2) + pow(lineEnd.dy - lineStart.dy, 2));
    if (normalLength == 0.0) return sqrt(pow(point.dx - lineStart.dx, 2) + pow(point.dy - lineStart.dy, 2));

    return ((point.dx - lineStart.dx) * (lineEnd.dy - lineStart.dy) -
            (point.dy - lineStart.dy) * (lineEnd.dx - lineStart.dx))
            .abs() / normalLength;
  }
}

class StrokeAnalysis {
  final Node? startNode;
  final Node? endNode;
  final double confidence;
  
  StrokeAnalysis({this.startNode, this.endNode, this.confidence = 0.0});
  
  bool get isPotentialConnection => startNode != null && endNode != null && confidence > 0.3;
}

// 4. Enhanced State Management with Freehand Support
class CanvasState with ChangeNotifier {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];
  final List<FreehandStroke> _freehandStrokes = [];
  int _nodeCounter = 0;

  // Connection state
  Node? _sourceNode;
  Offset? _dragPosition;
  ConnectionPoint? _sourceConnectionPoint;
  Edge? _selectedEdge;

  // Selection state
  final List<Node> _selectedNodes = [];

  // Freehand drawing state
  FreehandStroke? _currentStroke;
  StrokeAnalysis? _currentStrokeAnalysis;
  bool _showConnectionConfirmation = false;

  List<Node> get nodes => _nodes;
  List<Edge> get edges => _edges;
  List<FreehandStroke> get freehandStrokes => _freehandStrokes;
  List<Node> get selectedNodes => _selectedNodes;
  Node? get sourceNode => _sourceNode;
  Offset? get dragPosition => _dragPosition;
  ConnectionPoint? get sourceConnectionPoint => _sourceConnectionPoint;
  Edge? get selectedEdge => _selectedEdge;
  FreehandStroke? get currentStroke => _currentStroke;
  bool get showConnectionConfirmation => _showConnectionConfirmation;
  StrokeAnalysis? get currentStrokeAnalysis => _currentStrokeAnalysis;

  CanvasState() {
    // Add sample nodes with different shapes
    _addNode(Offset(100, 200), RectangleShape(Rect.fromLTWH(0, 0, 120, 120)));
    _addNode(Offset(400, 200), CircleShape(Offset(60, 60), 60));
    _addNode(Offset(250, 400), TriangleShape(Offset(60, 60), 50));
  }

  void _addNode(Offset position, NodeShape shape) {
    _nodeCounter++;
    final id = '${shape.type} $_nodeCounter';
    final node = Node(id, position, shape);
    _nodes.add(node);
    notifyListeners();
  }

  void addNode(NodeShape shape) {
    _addNode(Offset(150, 150), shape);
  }

  // Freehand drawing methods
  void startFreehandStroke(Offset position) {
    _currentStroke = FreehandStroke();
    _currentStroke!.addPoint(position);
    _showConnectionConfirmation = false;
    notifyListeners();
  }

  void updateFreehandStroke(Offset position) {
    if (_currentStroke != null) {
      _currentStroke!.addPoint(position);
      notifyListeners();
    }
  }

  void endFreehandStroke(Offset position) {
    if (_currentStroke != null) {
      _currentStroke!.addPoint(position);
      
      // Analyze the stroke for connection intent
      _currentStrokeAnalysis = _currentStroke!.analyzeStroke(_nodes);
      
      if (_currentStrokeAnalysis!.isPotentialConnection) {
        _showConnectionConfirmation = true;
      } else {
        // Keep as freehand drawing
        _freehandStrokes.add(_currentStroke!);
        _currentStroke = null;
      }
      
      notifyListeners();
    }
  }

  void confirmFreehandConnection() {
    if (_currentStrokeAnalysis != null && 
        _currentStrokeAnalysis!.isPotentialConnection &&
        _currentStroke != null) {
      
      final startNode = _currentStrokeAnalysis!.startNode!;
      final endNode = _currentStrokeAnalysis!.endNode!;
      
      // Convert freehand stroke to proper edge
      final startPoint = startNode.getClosestConnectionPoint(_currentStroke!.points.first);
      final endPoint = endNode.getClosestConnectionPoint(_currentStroke!.points.last);
      
      _edges.add(Edge(
        sourceNode: startNode,
        targetNode: endNode,
        sourcePoint: startPoint,
        targetPoint: endPoint,
      ));
      
      _freehandStrokes.remove(_currentStroke);
      _cleanupFreehand();
    }
  }

  void cancelFreehandConnection() {
    if (_currentStroke != null) {
      _freehandStrokes.add(_currentStroke!);
    }
    _cleanupFreehand();
  }

  void _cleanupFreehand() {
    _currentStroke = null;
    _currentStrokeAnalysis = null;
    _showConnectionConfirmation = false;
    notifyListeners();
  }

  // Traditional connection methods
  void startConnecting(Node node, Offset position) {
    _sourceNode = node;
    _dragPosition = position;
    _sourceConnectionPoint = ConnectionPoint(
      node.getClosestConnectionPoint(position),
      node.shape,
    );
    _selectedEdge = null;
    notifyListeners();
  }

  void updateDrag(Offset position) {
    if (_sourceNode != null) {
      _dragPosition = position;
      notifyListeners();
    }
  }

  void endConnecting(Node? targetNode) {
    if (_sourceNode != null && targetNode != null && _sourceNode != targetNode) {
      final existingEdge = _edges.any((edge) =>
          edge.sourceNode == _sourceNode && edge.targetNode == targetNode);
      
      if (!existingEdge) {
        final sourcePoint = _sourceNode!.getClosestConnectionPoint(_dragPosition!);
        final targetPoint = targetNode.getClosestConnectionPoint(_dragPosition!);
        
        _edges.add(Edge(
          sourceNode: _sourceNode!,
          targetNode: targetNode,
          sourcePoint: sourcePoint,
          targetPoint: targetPoint,
        ));
      }
    }
    
    _cleanupConnection();
  }

  void _cleanupConnection() {
    _sourceNode = null;
    _sourceConnectionPoint = null;
    _dragPosition = null;
    notifyListeners();
  }

  void moveNode(Node node, Offset newPosition) {
    node.position = newPosition;
    
    // Update edges connected to this node
    for (var edge in _edges) {
      if (edge.sourceNode == node || edge.targetNode == node) {
        edge.updatePoints();
      }
    }
    notifyListeners();
  }

  void changeNodeShape(Node node, NodeShape newShape) {
    node.updateShape(newShape);
    notifyListeners();
  }

  void clearSelection() {
    _selectedEdge = null;
    _selectedNodes.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedNodes.clear();
    _selectedNodes.addAll(_nodes);
    notifyListeners();
  }

  void deleteSelected() {
    _nodes.removeWhere((node) => _selectedNodes.contains(node));
    // Also remove edges connected to deleted nodes
    _edges.removeWhere((edge) =>
        _selectedNodes.contains(edge.sourceNode) ||
        _selectedNodes.contains(edge.targetNode));
    _selectedNodes.clear();
    notifyListeners();
  }
}

// 5. Edge with shape-aware connections
class Edge {
  final Node sourceNode;
  final Node targetNode;
  Offset sourcePoint;
  Offset targetPoint;
  Path? _path;

  Edge({
    required this.sourceNode,
    required this.targetNode,
    required this.sourcePoint,
    required this.targetPoint,
  });

  Path get path {
    _path ??= _computePath();
    return _path!;
  }

  Path _computePath() {
    return ConnectorCalculator.createCurvedPath(
      sourcePoint,
      targetPoint,
      _estimateEdgeDirection(sourcePoint, sourceNode.bounds.center),
      _estimateEdgeDirection(targetPoint, targetNode.bounds.center),
    );
  }

  String _estimateEdgeDirection(Offset point, Offset center) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? 'right' : 'left';
    } else {
      return dy > 0 ? 'bottom' : 'top';
    }
  }

  void updatePoints() {
    _path = null; // Invalidate cache
  }

  bool containsPoint(Offset point, double tolerance) {
    return _pointToLineDistance(point, sourcePoint, targetPoint) < tolerance;
  }

  double _pointToLineDistance(Offset point, Offset p1, Offset p2) {
    final double l2 = (p1.dx - p2.dx) * (p1.dx - p2.dx) + (p1.dy - p2.dy) * (p1.dy - p2.dy);
    if (l2 == 0.0) return sqrt(pow(point.dx - p1.dx, 2) + pow(point.dy - p1.dy, 2));

    double t = ((point.dx - p1.dx) * (p2.dx - p1.dx) + (point.dy - p1.dy) * (p2.dy - p1.dy)) / l2;
    t = t.clamp(0.0, 1.0);

    final Offset projection = Offset(
      p1.dx + t * (p2.dx - p1.dx),
      p1.dy + t * (p2.dy - p1.dy),
    );

    return sqrt(pow(point.dx - projection.dx, 2) + pow(point.dy - projection.dy, 2));
  }
}

// Connector Calculator for creating curved paths
class ConnectorCalculator {
  static Path createCurvedPath(Offset start, Offset end, String startDir, String endDir) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Simple quadratic bezier curve
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final controlOffset = 50.0; // Arbitrary curve amount

    // Adjust control point based on direction (simplified)
    double controlX = midX;
    double controlY = midY - controlOffset;

    if (startDir == 'right' && endDir == 'left') {
      controlY = midY;
    } else if (startDir == 'left' && endDir == 'right') {
      controlY = midY;
    }

    path.quadraticBezierTo(controlX, controlY, end.dx, end.dy);
    return path;
  }
}

// 6. Enhanced UI Components
class ShapeAwareNodeWidget extends StatelessWidget {
  final Node node;
  final VoidCallback? onShapeChange;

  const ShapeAwareNodeWidget({Key? key, required this.node, this.onShapeChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canvasState = Provider.of<CanvasState>(context, listen: false);

    return GestureDetector(
      onTapDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);

        // Check if tap is on the node itself (not connection area)
        if (node.containsPoint(localPosition - node.position)) {
          canvasState.endConnecting(node);
        }
      },
      child: CustomPaint(
        painter: NodeShapePainter(node, canvasState.selectedNodes.contains(node)),
        child: Container(
          width: node.bounds.width,
          height: node.bounds.height,
          child: Center(
            child: Text(
              node.id,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class NodeShapePainter extends CustomPainter {
  final Node node;
  final bool isSelected;

  NodeShapePainter(this.node, this.isSelected);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.red : Colors.blueGrey
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    // Draw the shape
    canvas.drawPath(node.shape.path, paint);
    canvas.drawPath(node.shape.path, borderPaint);

    // Draw connection points
    final connectionPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    for (final point in node.connectionPoints) {
      canvas.drawCircle(point.position, 4, connectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 7. Main App with Freehand Drawing
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CanvasState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Shape-Aware Mindmap'),
          actions: [
            Consumer<CanvasState>(
              builder: (context, state, child) {
                return PopupMenuButton<String>(
                  onSelected: (shape) {
                    switch (shape) {
                      case 'rectangle':
                        state.addNode(RectangleShape(Rect.fromLTWH(0, 0, 120, 120)));
                        break;
                      case 'circle':
                        state.addNode(CircleShape(Offset(60, 60), 60));
                        break;
                      case 'triangle':
                        state.addNode(TriangleShape(Offset(60, 60), 50));
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'rectangle', child: Text('Add Rectangle')),
                    PopupMenuItem(value: 'circle', child: Text('Add Circle')),
                    PopupMenuItem(value: 'triangle', child: Text('Add Triangle')),
                  ],
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const NodeCanvas(),
            // Connection confirmation dialog
            Consumer<CanvasState>(
              builder: (context, state, child) {
                if (state.showConnectionConfirmation) {
                  return Positioned(
                    top: 100,
                    left: 100,
                    child: ConnectionConfirmationDialog(
                      onConfirm: () => state.confirmFreehandConnection(),
                      onCancel: () => state.cancelFreehandConnection(),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            // Delete button
            Consumer<CanvasState>(
              builder: (context, state, child) {
                if (state.selectedNodes.isNotEmpty) {
                  return Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () => state.deleteSelected(),
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConnectionConfirmationDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Connection?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Convert freehand line to connection'),
            SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onConfirm, child: Text('Yes')),
                SizedBox(width: 8),
                TextButton(onPressed: onCancel, child: Text('No')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NodeCanvas extends StatefulWidget {
  const NodeCanvas({Key? key}) : super(key: key);

  @override
  _NodeCanvasState createState() => _NodeCanvasState();
}

class _NodeCanvasState extends State<NodeCanvas> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = Provider.of<CanvasState>(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyA) {
          canvasState.selectAll();
        }
      },
      child: GestureDetector(
        onPanStart: (details) {
          canvasState.startFreehandStroke(details.localPosition);
        },
        onPanUpdate: (details) {
          canvasState.updateFreehandStroke(details.localPosition);
          canvasState.updateDrag(details.localPosition);
        },
        onPanEnd: (details) {
          canvasState.endFreehandStroke(details.localPosition);
          canvasState.endConnecting(null);
        },
        child: Stack(
          children: [
            // Background
            Container(color: Colors.grey[50]),

            // Custom painter for edges and freehand strokes
            Positioned.fill(
              child: CustomPaint(
                painter: EnhancedEdgePainter(canvasState),
              ),
            ),

            // Positioned nodes
            ...canvasState.nodes.map((node) {
              return Positioned(
                left: node.position.dx,
                top: node.position.dy,
                child: Draggable(
                  feedback: ShapeAwareNodeWidget(node: node),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: ShapeAwareNodeWidget(node: node),
                  ),
                  onDragStarted: () {
                    canvasState.clearSelection();
                  },
                  onDragEnd: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(details.offset);
                    canvasState.moveNode(node, localPosition);
                  },
                  child: ShapeAwareNodeWidget(node: node),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class EnhancedEdgePainter extends CustomPainter {
  final CanvasState state;

  EnhancedEdgePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw freehand strokes
    for (final stroke in state.freehandStrokes) {
      canvas.drawPath(stroke.path, stroke.paint);
    }
    
    // Draw current freehand stroke
    if (state.currentStroke != null) {
      canvas.drawPath(state.currentStroke!.path, state.currentStroke!.paint);
    }
    
    // Draw proper edges
    for (final edge in state.edges) {
      final paint = Paint()
        ..color = edge == state.selectedEdge ? Colors.orange : Colors.blueGrey
        ..strokeWidth = edge == state.selectedEdge ? 4.0 : 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(edge.path, paint);
    }
    
    // Draw drag preview
    if (state.sourceNode != null && state.dragPosition != null) {
      final sourcePoint = state.sourceNode!.getClosestConnectionPoint(state.dragPosition!);
      final previewPath = ConnectorCalculator.createCurvedPath(
        sourcePoint, 
        state.dragPosition!, 
        'auto', 
        'auto',
      );
      
      final paint = Paint()
        ..color = Colors.deepOrange.withOpacity(0.7)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(previewPath, paint);
      canvas.drawCircle(state.dragPosition!, 6, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}