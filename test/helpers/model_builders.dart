import 'dart:math' as math;

class TestShapeSpec {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotationRadians;

  const TestShapeSpec({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotationRadians = 0.0,
  });
}

List<TestShapeSpec> buildGridOfRects({int cols = 5, int rows = 4, double cell = 80}) {
  final List<TestShapeSpec> shapes = <TestShapeSpec>[];
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final String id = 'rect_${r}_$c';
      shapes.add(TestShapeSpec(id: id, x: c * cell, y: r * cell, width: cell * 0.8, height: cell * 0.6));
    }
  }
  return shapes;
}

double deg(double degrees) => degrees * math.pi / 180.0;











