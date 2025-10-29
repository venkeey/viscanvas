# Screen Recording for UX Tests

## 🎥 Three Methods for Recording Tests

### Method 1: FFmpeg (Recommended - Automatic)

**Pros:** Fully automated, works in CI/CD, programmatic control
**Cons:** Requires FFmpeg installation

#### Setup:
```bash
# Install FFmpeg
choco install ffmpeg

# Verify installation
ffmpeg -version
```

#### Usage:
```bash
# Run test with automatic recording
flutter test integration_test/recorded_desktop_connection_test.dart -d windows
```

**Output:**
- Video saved to: `test_results/create_and_connect_shapes/*.mp4`
- Automatic start/stop
- 30 FPS screen capture

---

### Method 2: Windows Game Bar (Built-in)

**Pros:** No installation needed (built into Windows 10/11), high quality
**Cons:** Manual start/stop, videos in user Videos folder

#### Setup:
Enable Game Bar:
1. Open Settings → Gaming → Xbox Game Bar
2. Enable "Record game clips, screenshots, and broadcast using Game bar"

#### Usage:
```bash
# Start recording (press Win+Alt+R)
# Or use PowerShell:
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('^%r')"

# Run your test
flutter test integration_test/desktop_connection_test.dart -d windows

# Stop recording (press Win+Alt+R again)
```

**Output:**
- Videos saved to: `C:\Users\YourName\Videos\Captures\`
- MP4 format
- High quality

---

### Method 3: OBS Studio (Professional)

**Pros:** Highest quality, most control, free and open source
**Cons:** Requires setup

#### Setup:
```bash
# Install OBS Studio
choco install obs-studio

# Install obs-cli for command line control
npm install -g obs-cli
```

#### Configuration:
1. Open OBS Studio
2. Add "Display Capture" source
3. Set output to `test_results/` folder
4. File → Settings → Output → Recording Format: MP4

#### Usage:
```dart
// In your test
await OBSRecorder.startRecording();

// Run test...

await OBSRecorder.stopRecording();
```

---

## 🚀 Quick Start (FFmpeg Method)

### Step 1: Install FFmpeg
```bash
choco install ffmpeg
```

### Step 2: Run Recorded Test
```bash
flutter test integration_test/recorded_desktop_connection_test.dart -d windows
```

### Step 3: View Video
```bash
# Video is saved to test_results/create_and_connect_shapes/
start test_results/create_and_connect_shapes/*.mp4
```

---

## 📊 Comparison

| Method | Automatic | Quality | Setup Time | Best For |
|--------|-----------|---------|------------|----------|
| **FFmpeg** | ✅ Yes | Good | 2 min | CI/CD, automation |
| **Game Bar** | ❌ Manual | High | 0 min | Quick manual tests |
| **OBS Studio** | ⚠️ Semi-auto | Highest | 10 min | Professional demos |

---

## 🎬 For Your No-Code Platform

### Recommended Architecture:

```
User Runs Test in Your Platform
         ↓
Backend Triggers Test
         ↓
FFmpeg Starts Recording
         ↓
Flutter Test Runs
         ↓
FFmpeg Stops Recording
         ↓
Upload Video to S3/Azure
         ↓
Show Video in Dashboard
```

### Backend API Example:

```typescript
// Express.js endpoint
app.post('/api/run-test-with-video', async (req, res) => {
  const { testName } = req.body;

  // 1. Start recording
  const recordingProcess = spawn('ffmpeg', [
    '-f', 'gdigrab',
    '-framerate', '30',
    '-i', 'desktop',
    '-c:v', 'libx264',
    '-preset', 'ultrafast',
    `-`, `test_${testName}.mp4`
  ]);

  // 2. Run test
  const testProcess = spawn('flutter', [
    'test',
    `integration_test/${testName}_test.dart`,
    '-d', 'windows'
  ]);

  await new Promise(resolve => testProcess.on('close', resolve));

  // 3. Stop recording (send 'q' to FFmpeg)
  recordingProcess.stdin.write('q');
  await new Promise(resolve => recordingProcess.on('close', resolve));

  // 4. Upload to cloud
  const videoUrl = await uploadToS3(`test_${testName}.mp4`);

  // 5. Return URL
  res.json({ videoUrl });
});
```

---

## 🐛 Troubleshooting

### FFmpeg not found:
```bash
# Add FFmpeg to PATH
setx PATH "%PATH%;C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin"

# Restart terminal and verify
ffmpeg -version
```

### Permission denied:
```bash
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Recording is black screen:
- Check if app window is visible
- Try adding delay before recording starts
- Use Game Bar method instead

### Video file too large:
```bash
# Compress video after recording
ffmpeg -i input.mp4 -vcodec libx265 -crf 28 output.mp4
```

---

## 🎯 Next Steps

### For Development:
```bash
# Use Game Bar for quick manual tests
Win+Alt+R → Run test → Win+Alt+R
```

### For CI/CD:
```bash
# Use FFmpeg for automated recording
flutter test integration_test/recorded_desktop_connection_test.dart -d windows
```

### For Production (Your Platform):
1. Set up FFmpeg on test servers
2. Create REST API for running tests
3. Automatically upload videos to cloud storage
4. Display videos in user dashboard
5. Allow users to share video links with team

---

## 💡 Pro Tips

1. **Add Cursor Highlighting:**
   ```bash
   # Highlight mouse clicks in recording
   ffmpeg -f gdigrab -draw_mouse 1 -i desktop output.mp4
   ```

2. **Record Specific Window Only:**
   ```bash
   # Record only Flutter window (requires window title)
   ffmpeg -f gdigrab -i title="viscanvas" output.mp4
   ```

3. **Add Text Overlay:**
   ```bash
   # Add test step descriptions
   ffmpeg -i input.mp4 -vf "drawtext=text='Step 1: Create Shape':x=10:y=10" output.mp4
   ```

4. **Generate Thumbnail:**
   ```bash
   # Create preview image
   ffmpeg -i test_video.mp4 -ss 00:00:05 -vframes 1 thumbnail.png
   ```

---

## 📹 Example Output

After running the recorded test, you'll have:

```
test_results/
└── create_and_connect_shapes/
    ├── create_and_connect_shapes_1234567890.mp4  (Full test video)
    └── thumbnail.png                              (Preview image)
```

**Video shows:**
- App launching
- Rectangle tool being selected
- First rectangle being drawn
- Second rectangle being drawn
- Connector tool being selected
- Connection line being drawn
- All in 30 seconds of real-time footage

Perfect for showing stakeholders! 🎉
