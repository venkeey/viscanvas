# PowerShell script to run Patrol test with Flutter test fallback
Write-Host "Running Patrol Test on Windows" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Add Patrol to PATH for this session
$env:Path += ";C:\Users\Lenovo\AppData\Local\Pub\Cache\bin"

# Check if patrol is available
Write-Host "Checking if Patrol CLI is available..." -ForegroundColor Yellow
try {
    $patrolVersion = & patrol --version 2>&1
    if ($LASTEXITCODE -ne 0 -and $patrolVersion -match "not found") {
        throw "Patrol not found"
    }
    Write-Host $patrolVersion
    Write-Host "Patrol CLI found!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Patrol CLI not found in PATH" -ForegroundColor Red
    Write-Host "Please add C:\Users\Lenovo\AppData\Local\Pub\Cache\bin to your system PATH" -ForegroundColor Yellow
    Write-Host "Or run: dart pub global activate patrol_cli" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Falling back to Flutter test directly..." -ForegroundColor Yellow
    Write-Host ""
    $skipPatrol = $true
}

if (-not $skipPatrol) {
    Write-Host "Available Flutter devices:" -ForegroundColor Yellow
    flutter devices
    Write-Host ""
    
    Write-Host "Attempting to run Patrol test..." -ForegroundColor Yellow
    Write-Host "Note: If you get 'No devices attached', Patrol may not fully support Windows desktop" -ForegroundColor Yellow
    Write-Host ""
    
    # Try running the test with Patrol first
    Write-Host "Running Patrol test..." -ForegroundColor Cyan
    & patrol test integration_test/canvas_end_to_end_test.dart
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Yellow
        Write-Host "Patrol test failed or device not detected" -ForegroundColor Yellow
        Write-Host "Falling back to Flutter test..." -ForegroundColor Yellow
        Write-Host "=======================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Note: Some Patrol-specific features may not work with Flutter test" -ForegroundColor Yellow
        Write-Host ""
        $skipPatrol = $true
    } else {
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Green
        Write-Host "Test completed successfully using Patrol" -ForegroundColor Green
        Write-Host "=======================================" -ForegroundColor Green
        exit 0
    }
}

if ($skipPatrol) {
    # Try Flutter test as fallback
    Write-Host "Running Flutter test..." -ForegroundColor Cyan
    & flutter test integration_test/canvas_end_to_end_test.dart -d windows
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Red
        Write-Host "Both Patrol and Flutter test failed" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Red
        exit 1
    } else {
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Green
        Write-Host "Test completed using Flutter test" -ForegroundColor Green
        Write-Host "=======================================" -ForegroundColor Green
        exit 0
    }
}

