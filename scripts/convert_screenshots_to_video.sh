#!/bin/bash

# Script to convert test screenshots into a video
# Perfect for your no-code platform - users can watch test execution

echo "🎬 Converting test screenshots to video..."

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg not found. Please install:"
    echo "   Windows: choco install ffmpeg"
    echo "   Mac: brew install ffmpeg"
    echo "   Linux: sudo apt-get install ffmpeg"
    exit 1
fi

# Input/Output paths
INPUT_DIR="test_screenshots"
OUTPUT_FILE="test_execution_video.mp4"

# Check if screenshots exist
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Screenshot directory not found: $INPUT_DIR"
    exit 1
fi

# Count screenshots
SCREENSHOT_COUNT=$(ls -1 $INPUT_DIR/*.png 2>/dev/null | wc -l)
if [ $SCREENSHOT_COUNT -eq 0 ]; then
    echo "❌ No screenshots found in $INPUT_DIR"
    exit 1
fi

echo "📊 Found $SCREENSHOT_COUNT screenshots"
echo "📁 Input: $INPUT_DIR"
echo "📁 Output: $OUTPUT_FILE"

# Convert screenshots to video
# Each screenshot shows for 2 seconds
ffmpeg -y \
  -framerate 0.5 \
  -pattern_type glob \
  -i "$INPUT_DIR/*.png" \
  -c:v libx264 \
  -pix_fmt yuv420p \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  $OUTPUT_FILE

if [ $? -eq 0 ]; then
    echo "✅ Video created successfully!"
    echo "📹 Video file: $OUTPUT_FILE"
    echo "⏱️  Duration: $((SCREENSHOT_COUNT * 2)) seconds"
    echo ""
    echo "🎉 Users can now watch this video to verify functionality!"
else
    echo "❌ Video creation failed"
    exit 1
fi
