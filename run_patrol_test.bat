@echo off
echo Running Patrol Test on Windows
echo ======================================
echo.

REM Add Patrol to PATH for this session
set PATH=%PATH%;C:\Users\Lenovo\AppData\Local\Pub\Cache\bin

REM Check if patrol is available
echo Checking if Patrol CLI is available...
patrol --version 2>&1
set PATROL_STATUS=%errorlevel%
if %PATROL_STATUS% neq 0 (
    echo.
    echo ERROR: Patrol CLI not found in PATH
    echo Please add C:\Users\Lenovo\AppData\Local\Pub\Cache\bin to your system PATH
    echo Or run: dart pub global activate patrol_cli
    echo.
    echo Falling back to Flutter test directly...
    echo.
    goto :run_flutter_test
)
echo Patrol CLI found!
echo.

echo.
echo Available Flutter devices:
flutter devices

echo.
echo Attempting to run Patrol test...
echo Note: If you get "No devices attached", Patrol may not fully support Windows desktop
echo.

REM Try running the test with Patrol first
echo Running Patrol test...
patrol test integration_test/canvas_end_to_end_test.dart
set PATROL_TEST_STATUS=%errorlevel%
if %PATROL_TEST_STATUS% neq 0 (
    echo.
    echo ======================================
    echo Patrol test failed or device not detected
    echo Falling back to Flutter test...
    echo ======================================
    echo.
    echo Note: Some Patrol-specific features may not work with Flutter test
    echo.
    goto :run_flutter_test
) else (
    echo.
    echo ======================================
    echo Test completed successfully using Patrol
    echo ======================================
    goto :end
)

:run_flutter_test
REM Try Flutter test as fallback
echo Running Flutter test...
flutter test integration_test/canvas_end_to_end_test.dart -d windows
set FLUTTER_TEST_STATUS=%errorlevel%
if %FLUTTER_TEST_STATUS% neq 0 (
    echo.
    echo ======================================
    echo Both Patrol and Flutter test failed
    echo ======================================
    goto :end
) else (
    echo.
    echo ======================================
    echo Test completed using Flutter test
    echo ======================================
)

:end

pause

