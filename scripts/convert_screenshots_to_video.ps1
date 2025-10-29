# PowerShell script for Windows to convert screenshots to video
# For your no-code platform - users can watch test execution

Write-Host "🎬 Converting test screenshots to video..." -ForegroundColor Cyan

# Check if FFmpeg is installed
$ffmpegExists = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegExists) {
    Write-Host "❌ FFmpeg not found. Please install:" -ForegroundColor Red
    Write-Host "   Run: choco install ffmpeg" -ForegroundColor Yellow
    Write-Host "   Or download from: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    exit 1
}

# Input/Output paths
$inputDir = "test_screenshots"
$outputFile = "test_execution_video.mp4"

# Check if screenshots exist
if (-not (Test-Path $inputDir)) {
    Write-Host "❌ Screenshot directory not found: $inputDir" -ForegroundColor Red
    exit 1
}

# Count screenshots
$screenshots = Get-ChildItem -Path $inputDir -Filter "*.png"
$screenshotCount = $screenshots.Count

if ($screenshotCount -eq 0) {
    Write-Host "❌ No screenshots found in $inputDir" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $screenshotCount screenshots" -ForegroundColor Green
Write-Host "📁 Input: $inputDir" -ForegroundColor Cyan
Write-Host "📁 Output: $outputFile" -ForegroundColor Cyan
Write-Host ""

# Create a text file listing all images (FFmpeg Windows workaround)
$fileList = "$inputDir\file_list.txt"
$screenshots | Sort-Object Name | ForEach-Object {
    "file '$($_.Name)'" | Out-File -FilePath $fileList -Append -Encoding UTF8
    "duration 2" | Out-File -FilePath $fileList -Append -Encoding UTF8
}

# Convert screenshots to video
Write-Host "🎬 Creating video..." -ForegroundColor Cyan
ffmpeg -y -f concat -safe 0 -i $fileList -c:v libx264 -pix_fmt yuv420p -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" $outputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Video created successfully!" -ForegroundColor Green
    Write-Host "📹 Video file: $outputFile" -ForegroundColor Cyan
    Write-Host "⏱️  Duration: $($screenshotCount * 2) seconds" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎉 Users can now watch this video to verify functionality!" -ForegroundColor Green

    # Clean up temp file
    Remove-Item $fileList -ErrorAction SilentlyContinue
} else {
    Write-Host "❌ Video creation failed" -ForegroundColor Red
    exit 1
}
