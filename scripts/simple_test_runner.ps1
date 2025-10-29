# Simple test runner without video generation
param(
    [Parameter(Mandatory=$true)]
    [string]$TestFile
)

Write-Host "`n🧪 Running Test: $TestFile" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Check if test exists
if (-not (Test-Path $TestFile)) {
    Write-Host "❌ Test file not found: $TestFile" -ForegroundColor Red
    exit 1
}

# Run the test
dart pub global run patrol_cli test $TestFile

$testResult = $LASTEXITCODE

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan

if ($testResult -eq 0) {
    Write-Host "✅ TEST PASSED!" -ForegroundColor Green
} else {
    Write-Host "❌ TEST FAILED!" -ForegroundColor Red
}

Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

exit $testResult
