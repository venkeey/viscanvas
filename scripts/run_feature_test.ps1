# Run a feature test and generate video automatically
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureName
)

Write-Host "🧪 Running Feature Test: $FeatureName" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

$testFile = "test/e2e/features/${FeatureName}_test.dart"

# Check if test exists
if (-not (Test-Path $testFile)) {
    Write-Host "❌ Test file not found: $testFile" -ForegroundColor Red
    Write-Host "`nAvailable feature tests:" -ForegroundColor Yellow
    Get-ChildItem "test/e2e/features" -Filter "*_test.dart" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "   - $($_.BaseName)" -ForegroundColor Yellow
    }
    exit 1
}

# Create results directory
$resultsDir = "test_results/$FeatureName"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

Write-Host "📁 Results directory: $resultsDir`n" -ForegroundColor Cyan

# Run the test
Write-Host "▶️  Running test...`n" -ForegroundColor Green
dart pub global run patrol_cli test $testFile

$testResult = $LASTEXITCODE

if ($testResult -eq 0) {
    Write-Host "`n✅ TEST PASSED!" -ForegroundColor Green
} else {
    Write-Host "`n❌ TEST FAILED!" -ForegroundColor Red
    Write-Host "Fix the code and run again.`n" -ForegroundColor Yellow
    exit $testResult
}

# Check for screenshots
$screenshotDir = "build/app/outputs/patrol_screenshots"
if (Test-Path $screenshotDir) {
    $screenshots = Get-ChildItem -Path $screenshotDir -Filter "${FeatureName}*.png" -ErrorAction SilentlyContinue

    if ($screenshots.Count -gt 0) {
        Write-Host "`n📸 Found $($screenshots.Count) screenshots" -ForegroundColor Cyan

        # Copy screenshots to results
        $screenshots | ForEach-Object {
            Copy-Item $_.FullName -Destination $resultsDir
        }

        # Check if FFmpeg is available
        $ffmpegExists = Get-Command ffmpeg -ErrorAction SilentlyContinue

        if ($ffmpegExists) {
            Write-Host "🎬 Converting to video..." -ForegroundColor Cyan

            # Create file list for FFmpeg
            $fileList = Join-Path $resultsDir "file_list.txt"
            $screenshots | Sort-Object Name | ForEach-Object {
                "file '$($_.Name)'" | Out-File -FilePath $fileList -Append -Encoding UTF8
                "duration 2" | Out-File -FilePath $fileList -Append -Encoding UTF8
            }

            # Convert to video
            $videoFile = Join-Path $resultsDir "${FeatureName}_test.mp4"
            ffmpeg -y -f concat -safe 0 -i $fileList -c:v libx264 -pix_fmt yuv420p -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" $videoFile 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Video created: $videoFile" -ForegroundColor Green

                # Create HTML report
                $reportFile = Join-Path $resultsDir "report.html"
                $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Report: $FeatureName</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 50px auto; padding: 20px; }
        h1 { color: #2ecc71; }
        .status { padding: 10px; border-radius: 5px; margin: 20px 0; }
        .passed { background: #d4edda; color: #155724; }
        .video { width: 100%; max-width: 800px; margin: 20px 0; }
        .screenshots { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .screenshot { border: 1px solid #ddd; padding: 10px; border-radius: 5px; }
        .screenshot img { width: 100%; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>✅ Test Report: $FeatureName</h1>
    <div class="status passed">
        <strong>Status:</strong> PASSED<br>
        <strong>Date:</strong> $dateTime<br>
        <strong>Screenshots:</strong> $($screenshots.Count)
    </div>

    <h2>📹 Test Video</h2>
    <video class="video" controls>
        <source src="${FeatureName}_test.mp4" type="video/mp4">
    </video>

    <h2>📸 Screenshots</h2>
    <div class="screenshots">
"@

                $screenshots | Sort-Object Name | ForEach-Object {
                    $htmlContent += @"

        <div class="screenshot">
            <img src="$($_.Name)" alt="$($_.Name)">
            <p>$($_.Name)</p>
        </div>
"@
                }

                $htmlContent += @"

    </div>
</body>
</html>
"@

                $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8
                Write-Host "✅ HTML report: $reportFile" -ForegroundColor Green
            }

            Remove-Item $fileList -ErrorAction SilentlyContinue
        } else {
            Write-Host "⚠️  FFmpeg not found. Install to generate video:" -ForegroundColor Yellow
            Write-Host "   choco install ffmpeg" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n⚠️  No screenshots found for this test" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️  Screenshot directory not found: $screenshotDir" -ForegroundColor Yellow
}

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 Feature test complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Test: $FeatureName" -ForegroundColor White
Write-Host "   Status: PASSED ✅" -ForegroundColor Green
Write-Host "   Results: $resultsDir" -ForegroundColor White

$reportPath = Join-Path $resultsDir "report.html"
if (Test-Path $reportPath) {
    Write-Host "   View Report: start $reportPath" -ForegroundColor Cyan
}

Write-Host ""
