@echo off
echo Running All Patrol Integration Tests...
echo ======================================

echo.
echo Running Drawing Workflow Tests...
flutter test integration_test/patrol/drawing_workflows_test.dart -d windows --no-pub
if %errorlevel% neq 0 (
    echo Drawing Workflow Tests FAILED!
    exit /b 1
)

echo.
echo Running Shape Manipulation Tests...
flutter test integration_test/patrol/shape_manipulation_test.dart -d windows --no-pub
if %errorlevel% neq 0 (
    echo Shape Manipulation Tests FAILED!
    exit /b 1
)

echo.
echo Running Connector Tests...
flutter test integration_test/patrol/connector_tests.dart -d windows --no-pub
if %errorlevel% neq 0 (
    echo Connector Tests FAILED!
    exit /b 1
)

echo.
echo Running Streaming Data Tests...
flutter test integration_test/patrol/streaming_data_test.dart -d windows --no-pub
if %errorlevel% neq 0 (
    echo Streaming Data Tests FAILED!
    exit /b 1
)

echo.
echo ======================================
echo All Patrol Integration Tests PASSED! ✅
echo ======================================