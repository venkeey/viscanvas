# Running Patrol Tests on Windows - Setup Guide

## Issue
Patrol CLI reports "No devices attached" even though `flutter devices` shows Windows desktop is available.

## Current Status
- ✅ Patrol CLI is installed (v3.10.0)
- ✅ Flutter detects Windows device (`flutter devices` shows Windows desktop)
- ❌ Patrol CLI doesn't detect Windows device

## Solution 1: Add Patrol to PATH (Recommended for Long-term)

Add `C:\Users\Lenovo\AppData\Local\Pub\Cache\bin` to your Windows PATH:

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click "Environment Variables"
3. Under "System variables", find "Path" and click "Edit"
4. Click "New" and add: `C:\Users\Lenovo\AppData\Local\Pub\Cache\bin`
5. Click OK on all dialogs
6. **Restart your terminal/PowerShell**

After adding to PATH, you can run:
```powershell
patrol test integration_test/canvas_end_to_end_test.dart
```

## Solution 2: Use Temporary PATH (Quick Test)

For a quick test without changing system PATH:
```powershell
$env:Path += ";C:\Users\Lenovo\AppData\Local\Pub\Cache\bin"
patrol test integration_test/canvas_end_to_end_test.dart
```

## Solution 3: Use the Batch Script

Run the provided batch script:
```powershell
.\run_patrol_test.bat
```

## Known Issue: Windows Desktop Device Detection

**Current Problem**: Even after adding to PATH, Patrol may report "No devices attached" because:
- Patrol 3.10.0 may have limited Windows desktop support
- Device detection in Patrol might not fully recognize Windows desktop devices

### Potential Workarounds:

1. **Check Patrol Version**: Try downgrading to Patrol 3.0.0 (which is pinned in pubspec.yaml):
   ```powershell
   dart pub global activate patrol_cli 3.0.0
   ```

2. **Update patrol.yaml**: Ensure Windows is properly configured:
   ```yaml
   devices:
     windows:
       enabled: true
   ```

3. **Use Flutter Test Directly** (Limited - Patrol features won't work):
   ```powershell
   flutter test integration_test/canvas_end_to_end_test.dart -d windows
   ```
   **Note**: This will fail because the test uses `patrolWidgetTest` which requires Patrol infrastructure.

## Next Steps

1. Add Patrol to system PATH (Solution 1)
2. Restart terminal and try: `patrol test integration_test/canvas_end_to_end_test.dart`
3. If still failing, check Patrol GitHub issues for Windows desktop support:
   - https://github.com/leancodepl/patrol/issues

## Verification

Verify Patrol is accessible:
```powershell
patrol --version
```

Should output: `patrol_cli v3.10.0` (or your installed version)

