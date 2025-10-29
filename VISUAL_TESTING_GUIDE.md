# Visual Testing Guide - How to View UX During Tests

## 🐛 Why Your Bug Wasn't Caught

Your tests passed but the real app failed because:

1. **Unit tests test isolated components** - They test `CanvasState` but your UI uses `CanvasService`
2. **Integration tests don't verify visual behavior** - They verify data but not rendering
3. **No end-to-end user journey tests** - No test actually *uses* the app like a user would

## ✅ Solution: Visual & E2E Testing

### Method 1: Run Tests with Visual Browser (RECOMMENDED)

```bash
# View tests in Chrome browser
flutter test --platform chrome test/e2e/visual_user_journey_test.dart

# The browser window will show the actual UI
# Add delays in tests to see what's happening:
await tester.pump(Duration(seconds: 2)); // Pause for 2 seconds
```

### Method 2: Integration Tests with Patrol (Best for Mobile)

```bash
# Run on actual device/emulator with visual feedback
patrol test integration_test/drawing_workflows_test.dart

# You'll see the app running on the screen
```

### Method 3: Golden File Testing (Screenshots)

```bash
# Generate screenshots
flutter test --update-goldens test/visual/golden/

# Compare changes visually
flutter test test/visual/golden/
```

### Method 4: Manual Debug Mode

Add this to any test to pause and inspect:

```dart
testWidgets('Debug test', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Do some action
  await tester.tap(find.byIcon(Icons.rectangle));
  await tester.pumpAndSettle();

  // PAUSE HERE - Look at the screen!
  await tester.pump(Duration(seconds: 10));

  // Take a screenshot programmatically
  await expectLater(
    find.byType(CanvasScreen),
    matchesGoldenFile('screenshots/my_test.png'),
  );
});
```

## 🔍 How to Diagnose Your Specific Bug

### Run the Bug Reproduction Test:

```bash
flutter test test/e2e/visual_user_journey_test.dart --platform chrome
```

Watch the browser window - you'll see:
1. Shapes being created
2. Attempts to select them
3. Attempts to connect them
4. What actually happens vs. what should happen

### Add Debug Prints

The test already has debug prints. When you run it, you'll see:

```
✅ Step 1: App loaded
✅ Step 2: Rectangle tool selected
✅ Step 3: First rectangle drawn
❌ Step 4: Rectangle not selectable <- YOUR BUG
```

## 🛠️ Create Tests That Catch Real Bugs

### Bad Test (What you had):
```dart
test('should create connection between nodes', () {
  canvasState.startConnecting(node1, offset);
  canvasState.endConnecting(node2);
  expect(canvasState.edges.length, 1); // ✅ Passes but app is broken
});
```

**Why it fails:** Tests the data model but not the actual UI interaction.

### Good Test (What you need):
```dart
testWidgets('USER can create connection between shapes', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 1. Create first shape (REAL user action)
  await tester.tap(find.byIcon(Icons.rectangle));
  await tester.dragFrom(Offset(100, 100), Offset(50, 50));
  await tester.pumpAndSettle();

  // 2. Create second shape
  await tester.dragFrom(Offset(300, 100), Offset(50, 50));
  await tester.pumpAndSettle();

  // 3. Select connector tool
  await tester.tap(find.byIcon(Icons.timeline));
  await tester.pumpAndSettle();

  // 4. Draw connection
  await tester.dragFrom(Offset(125, 125), Offset(325, 125));
  await tester.pumpAndSettle();

  // 5. VERIFY visually rendered connector exists
  expect(find.byType(Connector), findsOneWidget); // ❌ Would fail with your bug

  // 6. Screenshot for visual verification
  await expectLater(
    find.byType(CanvasScreen),
    matchesGoldenFile('connected_shapes.png'),
  );
});
```

## 📊 Test Coverage Pyramid (Fixed)

```
         /\
        /E2\      ← E2E (5%) - Full user journeys
       /----\
      /Visual\    ← Visual (10%) - Screenshots, golden files
     /--------\
    /Integration\ ← Integration (25%) - Multi-component
   /------------\
  /  Unit Tests  \ ← Unit (60%) - Individual functions
 /________________\
```

**Your issue:** You had 95% unit, 5% integration, 0% E2E, 0% visual

## 🎯 Critical Tests You Need Now

### 1. Smoke Test (Run First)
```bash
flutter test test/e2e/visual_user_journey_test.dart --name "SMOKE TEST"
```

### 2. Bug Reproduction Test
```bash
flutter test test/e2e/visual_user_journey_test.dart --name "BUG REPRODUCTION"
```

### 3. Diagnostic Test
```bash
flutter test test/e2e/visual_user_journey_test.dart --name "DIAGNOSTIC"
```

## 🔧 How to Fix Your Architecture Issue

Your codebase has **two canvas systems**:

1. **Old System:** `connectors.dart` with `CanvasState` + `Node` class
2. **New System:** `drawingCanvas.dart` with `CanvasService` + `CanvasObject` class

**Problem:** Your tests use OLD system, but UI uses NEW system!

### Quick Fix:

1. Pick ONE system (I recommend the new `CanvasService`)
2. Delete or deprecate the other
3. Rewrite tests to use the correct system

### Test the ACTUAL Implementation:

```dart
testWidgets('Shapes are actually selectable', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Get actual CanvasService from widget tree
  final context = tester.element(find.byType(CanvasScreen));
  // Now test against REAL service, not mock CanvasState
});
```

## 📸 Visual Debugging Tools

### 1. Flutter DevTools
```bash
flutter run
# Press 'w' to open DevTools
# Widget Inspector shows visual hierarchy
# Performance tab shows rendering issues
```

### 2. Test with Screenshots
```dart
await tester.takeScreenshot('test_screenshot.png');
```

### 3. Record Video of Tests (Patrol)
```bash
patrol test --record integration_test/
```

## 🚨 Anti-Patterns That Hide Bugs

❌ **Don't:**
- Test only data models without UI
- Mock everything (then you're not testing real code)
- Only test happy paths
- Ignore visual rendering

✅ **Do:**
- Test actual user workflows end-to-end
- Verify visual output with screenshots
- Test error states and edge cases
- Watch tests run visually

## 📝 Test Checklist for Critical Features

For "Create and connect two shapes":

- [ ] Can create first shape (visual confirmation)
- [ ] Can create second shape (visual confirmation)
- [ ] Shapes render correctly (screenshot match)
- [ ] Can select shape with mouse/touch
- [ ] Selected shape shows selection indicator
- [ ] Can drag selected shape
- [ ] Dragged shape moves visually
- [ ] Can activate connector tool
- [ ] Can drag from shape1 to shape2
- [ ] Connector line appears
- [ ] Connector connects to correct points
- [ ] Connection persists after drag

**Your bug fails at step 4: "Can select shape with mouse/touch"**

## 🎬 Next Steps

1. **Run the E2E test I created:**
   ```bash
   flutter test test/e2e/visual_user_journey_test.dart --platform chrome
   ```

2. **Watch what happens in the browser**

3. **Look at console output for which step fails**

4. **Add more `await tester.pump(Duration(seconds: 5))` to slow down and watch**

5. **Take screenshots at each step:**
   ```dart
   await expectLater(
     find.byType(CanvasScreen),
     matchesGoldenFile('step_1_created_shapes.png'),
   );
   ```

6. **Fix the actual bug** (likely in event handlers or widget tree)

7. **Re-run tests to verify fix**

## 💡 Pro Tip: Golden File Workflow

Best way to catch visual bugs:

```bash
# 1. Generate baseline (when UI is correct)
flutter test --update-goldens test/visual/

# 2. Make changes to code

# 3. Run tests (will fail if UI changed)
flutter test test/visual/

# 4. Check diff images in failures/ directory
# 5. If change is intended, update goldens
# 6. If not, you found a bug!
```

This would have caught your bug immediately because the shapes wouldn't match the golden file.
