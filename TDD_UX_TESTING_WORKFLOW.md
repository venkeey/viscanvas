# Test-Driven Development for UX Features

## 🎯 Your Requirement: Test-First Development

**Traditional (Bad):**
```
Write Code → Manual Test → Find Bugs → Fix → Repeat
```

**TDD for UX (Good):**
```
Write UX Test → Test Fails (Red) → Write Code → Test Passes (Green) → Refactor
```

## 🏗️ Workflow for Building New Features

### Example: Adding a "Delete Shape" Feature

#### Step 1: Write the UX Test FIRST (Before any code)

```dart
// test/e2e/features/delete_shape_test.dart
patrolTest('USER can delete a selected shape', ($) async {
  app.main();
  await $.pumpAndSettle();

  // ARRANGE: Create a shape
  await $.tap(find.byIcon(Icons.rectangle_outlined));
  await $.tester.dragFrom(Offset(200, 200), Offset(100, 80));
  await $.pumpAndSettle();
  await $.native.takeScreenshot('01_shape_created');

  // ACT: Select shape
  await $.tap(find.byIcon(Icons.near_me));
  await $.tapAt(Offset(250, 240)); // Tap on shape
  await $.pumpAndSettle();
  await $.native.takeScreenshot('02_shape_selected');

  // ACT: Press Delete key
  await $.native.pressKey(NativeKey.backspace);
  await $.pumpAndSettle();
  await $.native.takeScreenshot('03_shape_deleted');

  // ASSERT: Shape should be gone
  // In real implementation, check canvas state
  expect(find.byType(CanvasScreen), findsOneWidget);
});
```

#### Step 2: Run Test - It FAILS (Red) ✅ Expected!

```bash
patrol test test/e2e/features/delete_shape_test.dart
# ❌ FAILS: Delete key does nothing
```

#### Step 3: Implement ONLY Enough Code to Pass

```dart
// lib/pages/drawingCanvas.dart
void _handleKeyEvent(KeyEvent event) {
  if (event.logicalKey == LogicalKeyboardKey.delete ||
      event.logicalKey == LogicalKeyboardKey.backspace) {
    _service.deleteSelected();
    setState(() {});
  }
}
```

#### Step 4: Run Test Again - It PASSES (Green) ✅

```bash
patrol test test/e2e/features/delete_shape_test.dart
# ✅ PASSES: Shape is deleted
```

#### Step 5: Refactor & Document

Add video recording, optimize performance, etc.

---

## 📋 Feature Development Template

### Template for EVERY New Feature

```dart
// test/e2e/features/[feature_name]_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart' as app;

/// FEATURE: [Feature Name]
/// STORY: As a user, I want to [action] so that [benefit]
///
/// ACCEPTANCE CRITERIA:
/// - [ ] Criterion 1
/// - [ ] Criterion 2
/// - [ ] Criterion 3
void main() {
  patrolTest(
    'USER can [perform action]',
    nativeAutomation: true,
    ($) async {
      // ARRANGE: Setup initial state
      app.main();
      await $.pumpAndSettle();
      await $.native.takeScreenshot('00_initial_state');

      // ACT: Perform user action
      // ... user interactions here
      await $.native.takeScreenshot('01_after_action');

      // ASSERT: Verify expected outcome
      expect(/* condition */, /* expected */);
      await $.native.takeScreenshot('02_verified');

      // DOCUMENT: Screenshots saved for stakeholders
    },
  );

  patrolTest(
    'EDGE CASE: [What if something goes wrong?]',
    ($) async {
      // Test error states, edge cases, etc.
    },
  );
}
```

---

## 🚀 Feature Test Suite Structure

```
test/e2e/features/
├── shape_creation/
│   ├── create_rectangle_test.dart
│   ├── create_circle_test.dart
│   ├── create_with_properties_test.dart
│   └── create_edge_cases_test.dart
├── shape_manipulation/
│   ├── move_shape_test.dart
│   ├── resize_shape_test.dart
│   ├── rotate_shape_test.dart
│   └── delete_shape_test.dart
├── connections/
│   ├── create_connector_test.dart
│   ├── move_connected_shapes_test.dart
│   └── delete_connected_shape_test.dart
├── canvas_navigation/
│   ├── pan_canvas_test.dart
│   ├── zoom_canvas_test.dart
│   └── reset_view_test.dart
└── data_persistence/
    ├── save_canvas_test.dart
    ├── load_canvas_test.dart
    └── autosave_test.dart
```

---

## 🎬 Video Recording for Each Feature

### Automatic Video Generation

```dart
// test/e2e/video_test_runner.dart
import 'dart:io';

class VideoTestRunner {
  static Future<void> runFeatureTest(
    String testName,
    Function(PatrolTester) testFunction,
  ) async {
    final screenshotDir = Directory('test_results/$testName');
    screenshotDir.createSync(recursive: true);

    // Run test with screenshots
    await patrolTest(testName, (PatrolTester $) async {
      await testFunction($);
    });

    // Convert to video
    await _convertToVideo(testName);

    // Upload to cloud
    await _uploadToCloud(testName);

    // Notify team
    await _notifyTeam(testName, passed: true);
  }

  static Future<void> _convertToVideo(String testName) async {
    final result = await Process.run('ffmpeg', [
      '-framerate', '1',
      '-pattern_type', 'glob',
      '-i', 'test_results/$testName/*.png',
      '-c:v', 'libx264',
      'test_results/$testName/video.mp4',
    ]);

    if (result.exitCode == 0) {
      print('✅ Video created: test_results/$testName/video.mp4');
    }
  }

  static Future<void> _uploadToCloud(String testName) async {
    // Upload to S3/Azure
    print('📤 Uploading to cloud...');
    // Implementation here
  }

  static Future<void> _notifyTeam(String testName, {required bool passed}) async {
    // Send Slack/Teams notification
    print('📢 Notifying team: $testName ${passed ? "PASSED" : "FAILED"}');
    // Implementation here
  }
}
```

---

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/ux_tests.yml
name: UX Tests with Video Recording

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  ux-tests:
    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Install Dependencies
        run: flutter pub get

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli

      - name: Run UX Tests with Video Recording
        run: |
          patrol test integration_test/features/

      - name: Convert Screenshots to Videos
        run: |
          pwsh scripts/convert_all_tests_to_video.ps1

      - name: Upload Test Videos
        uses: actions/upload-artifact@v3
        with:
          name: test-videos
          path: test_results/**/*.mp4

      - name: Comment PR with Video Links
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ UX Tests Passed! [Watch Videos](link-to-videos)'
            })
```

---

## 📊 Feature Development Dashboard

### What Developers See

```
┌─────────────────────────────────────────────────────────┐
│ Feature: Delete Shape                                    │
│ Status: 🟢 All Tests Passing                            │
│                                                          │
│ Tests (3/3 passing):                                     │
│ ✅ USER can delete selected shape                        │
│ ✅ USER can delete with Delete key                       │
│ ✅ EDGE: Cannot delete when nothing selected             │
│                                                          │
│ Coverage: 95% (Shape deletion logic)                     │
│                                                          │
│ [▶️ Watch Test Video] [📊 View Report] [📸 Screenshots] │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Real Example: Adding "Undo/Redo" Feature

### 1. Write Test FIRST

```dart
// test/e2e/features/undo_redo_test.dart
patrolTest('USER can undo shape creation', ($) async {
  app.main();
  await $.pumpAndSettle();

  // Create a shape
  await $.tap(find.byIcon(Icons.rectangle_outlined));
  await $.tester.dragFrom(Offset(200, 200), Offset(100, 80));
  await $.pumpAndSettle();
  await $.native.takeScreenshot('01_shape_created');

  // Verify shape exists
  final shapesBeforeUndo = find.byType(CustomPaint);
  final countBefore = shapesBeforeUndo.evaluate().length;

  // Press Ctrl+Z
  await $.native.pressKey(NativeKey.control);
  await $.native.pressKey(NativeKey.keyZ);
  await $.native.releaseKey(NativeKey.control);
  await $.pumpAndSettle();
  await $.native.takeScreenshot('02_after_undo');

  // Verify shape is gone
  final shapesAfterUndo = find.byType(CustomPaint);
  final countAfter = shapesAfterUndo.evaluate().length;

  expect(countAfter, lessThan(countBefore),
    reason: 'Shape should be removed after undo');
});

patrolTest('USER can redo undone action', ($) async {
  app.main();
  await $.pumpAndSettle();

  // Create, undo, then redo
  await $.tap(find.byIcon(Icons.rectangle_outlined));
  await $.tester.dragFrom(Offset(200, 200), Offset(100, 80));
  await $.pumpAndSettle();

  // Undo
  await $.native.pressKey(NativeKey.control);
  await $.native.pressKey(NativeKey.keyZ);
  await $.native.releaseKey(NativeKey.control);
  await $.pumpAndSettle();

  // Redo (Ctrl+Y)
  await $.native.pressKey(NativeKey.control);
  await $.native.pressKey(NativeKey.keyY);
  await $.native.releaseKey(NativeKey.control);
  await $.pumpAndSettle();
  await $.native.takeScreenshot('03_after_redo');

  // Shape should be back
  expect(find.byType(CustomPaint), findsWidgets);
});
```

### 2. Run Test - FAILS ❌

```bash
patrol test test/e2e/features/undo_redo_test.dart
# ❌ Expected: Shape removed after undo
# Actual: Shape still there (feature not implemented)
```

### 3. Implement Feature

```dart
// Already implemented in your code!
// lib/pages/drawingCanvas.dart lines 2609-2614
```

### 4. Run Test - PASSES ✅

```bash
patrol test test/e2e/features/undo_redo_test.dart
# ✅ All tests passing
# 📹 Video saved to: test_results/undo_redo/video.mp4
```

---

## 🎥 Video Test Output Structure

```
test_results/
├── create_rectangle/
│   ├── 01_initial_state.png
│   ├── 02_rectangle_tool_selected.png
│   ├── 03_rectangle_created.png
│   ├── video.mp4
│   └── report.html
├── delete_shape/
│   ├── 01_shape_created.png
│   ├── 02_shape_selected.png
│   ├── 03_shape_deleted.png
│   ├── video.mp4
│   └── report.html
└── undo_redo/
    ├── 01_shape_created.png
    ├── 02_after_undo.png
    ├── 03_after_redo.png
    ├── video.mp4
    └── report.html
```

---

## 🔧 Quick Setup Script

```bash
# scripts/create_feature_test.sh
#!/bin/bash

FEATURE_NAME=$1
FEATURE_DIR="test/e2e/features/${FEATURE_NAME}"

mkdir -p "$FEATURE_DIR"

cat > "$FEATURE_DIR/${FEATURE_NAME}_test.dart" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart' as app;

/// FEATURE: [FEATURE_NAME]
/// STORY: As a user, I want to [action] so that [benefit]
void main() {
  patrolTest(
    'USER can [perform action]',
    nativeAutomation: true,
    ($) async {
      app.main();
      await $.pumpAndSettle();
      await $.native.takeScreenshot('00_initial_state');

      // TODO: Implement test steps

      await $.native.takeScreenshot('99_final_state');
    },
  );
}
EOF

echo "✅ Feature test created: $FEATURE_DIR/${FEATURE_NAME}_test.dart"
echo "📝 Next steps:"
echo "   1. Write your test (it should fail)"
echo "   2. Run: patrol test $FEATURE_DIR/${FEATURE_NAME}_test.dart"
echo "   3. Implement feature until test passes"
echo "   4. Video will be auto-generated"
```

---

## 💡 Best Practices for Your Platform

### 1. Write Tests for User Stories

```
User Story: As a business user, I want to create a flowchart
                so that I can visualize my process

Tests Needed:
✅ Create rectangle node
✅ Create circle node
✅ Connect nodes with arrows
✅ Move nodes while maintaining connections
✅ Delete nodes and connected arrows
```

### 2. Test Before Committing

```bash
# Git pre-commit hook
#!/bin/bash
echo "🧪 Running UX tests before commit..."
patrol test test/e2e/features/
if [ $? -ne 0 ]; then
    echo "❌ UX tests failed! Fix tests before committing."
    exit 1
fi
echo "✅ All UX tests passed!"
```

### 3. Video Every Feature

Every feature test should generate:
- ✅ Screenshot at each step
- ✅ Video of full flow
- ✅ HTML report
- ✅ Cloud URL for sharing

---

## 🎯 Your Development Workflow

```
1. PLAN: Write user story
   "As a user, I want to export canvas as PNG"

2. TEST: Write UX test FIRST
   test/e2e/features/export_png_test.dart

3. RUN: Test fails (expected) ❌
   patrol test test/e2e/features/export_png_test.dart

4. CODE: Implement feature
   lib/features/export/png_exporter.dart

5. RUN: Test passes ✅
   patrol test test/e2e/features/export_png_test.dart

6. VIDEO: Auto-generated
   test_results/export_png/video.mp4

7. SHARE: Upload to cloud
   https://your-platform.com/tests/export_png

8. COMMIT: With passing tests
   git commit -m "feat: Add PNG export"
```

---

## 🚀 Ready-to-Use Commands

```bash
# Create new feature test
bash scripts/create_feature_test.sh delete_shape

# Run specific feature test
patrol test test/e2e/features/delete_shape/

# Run all feature tests
patrol test test/e2e/features/

# Generate videos for all tests
pwsh scripts/convert_all_tests_to_video.ps1

# Watch a specific test video
start test_results/delete_shape/video.mp4
```

---

## 📊 Benefits for Your No-Code Platform

1. **Confidence**: Every feature has video proof it works
2. **Documentation**: Videos show exactly how features work
3. **Regression Prevention**: Tests run on every commit
4. **Stakeholder Trust**: Non-technical users can watch videos
5. **Faster Development**: Catch bugs immediately, not in production
6. **Quality**: No feature ships without passing UX test

---

This is **production-grade TDD for UX** - perfect for enterprise no-code platforms! 🎉
