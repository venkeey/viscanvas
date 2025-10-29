import 'dart:io';

/// Screen recorder for automated tests
/// Captures video of test execution on Windows
class ScreenRecorder {
  Process? _recordingProcess;
  final String outputPath;
  final String testName;

  ScreenRecorder({
    required this.testName,
    String? outputDir,
  }) : outputPath = outputDir ?? 'test_results/$testName';

  /// Start recording the screen
  Future<void> startRecording() async {
    // Create output directory
    final dir = Directory(outputPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final videoFile = '$outputPath/${testName}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    print('🎥 Starting screen recording...');
    print('📁 Output: $videoFile');

    // Use FFmpeg to record screen on Windows
    // Install: choco install ffmpeg
    try {
      _recordingProcess = await Process.start(
        'ffmpeg',
        [
          '-f', 'gdigrab', // Windows screen capture
          '-framerate', '30',
          '-i', 'desktop',
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-y', // Overwrite output file
          videoFile,
        ],
        runInShell: true,
      );

      // Give FFmpeg time to start
      await Future.delayed(const Duration(seconds: 2));
      print('✅ Recording started');
    } catch (e) {
      print('❌ Failed to start recording: $e');
      print('💡 Make sure FFmpeg is installed: choco install ffmpeg');
    }
  }

  /// Stop recording and save video
  Future<String?> stopRecording() async {
    if (_recordingProcess == null) {
      print('⚠️  No recording in progress');
      return null;
    }

    print('🛑 Stopping recording...');

    // Send 'q' to FFmpeg to stop gracefully
    _recordingProcess!.stdin.write('q');
    await _recordingProcess!.stdin.flush();
    await _recordingProcess!.stdin.close();

    // Wait for process to finish
    await Future.delayed(const Duration(seconds: 2));

    final exitCode = await _recordingProcess!.exitCode;
    _recordingProcess = null;

    if (exitCode == 0 || exitCode == 255) {
      // 255 is normal for FFmpeg when stopped with 'q'
      print('✅ Recording saved');

      // Find the most recent video file
      final dir = Directory(outputPath);
      final videos = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (videos.isNotEmpty) {
        final videoPath = videos.first.path;
        print('📹 Video saved: $videoPath');
        return videoPath;
      }
    }

    print('⚠️  Recording may not have been saved properly');
    return null;
  }

  /// Record a test execution
  static Future<String?> recordTest({
    required String testName,
    required Future<void> Function() testFunction,
  }) async {
    final recorder = ScreenRecorder(testName: testName);

    try {
      await recorder.startRecording();
      await testFunction();
      return await recorder.stopRecording();
    } catch (e) {
      print('❌ Test failed: $e');
      await recorder.stopRecording();
      rethrow;
    }
  }
}

/// Alternative: Use OBS Studio for recording
class OBSRecorder {
  /// Start OBS recording via command line
  /// Requires OBS Studio with obs-cli plugin
  static Future<void> startRecording() async {
    try {
      await Process.run('obs-cli', ['recording', 'start']);
      print('✅ OBS recording started');
    } catch (e) {
      print('❌ OBS not available: $e');
    }
  }

  /// Stop OBS recording
  static Future<void> stopRecording() async {
    try {
      await Process.run('obs-cli', ['recording', 'stop']);
      print('✅ OBS recording stopped');
    } catch (e) {
      print('❌ Failed to stop OBS: $e');
    }
  }
}

/// Windows Game Bar recorder (built into Windows 10/11)
class WindowsGameBarRecorder {
  /// Start recording using Windows Game Bar
  /// Win+Alt+R shortcut
  static Future<void> startRecording() async {
    print('🎮 Starting Windows Game Bar recording...');
    print('💡 Press Win+Alt+R manually or use PowerShell automation');

    // Use PowerShell to send Win+Alt+R
    await Process.run('powershell', [
      '-Command',
      '''
      Add-Type -AssemblyName System.Windows.Forms
      [System.Windows.Forms.SendKeys]::SendWait("^%r")
      '''
    ]);

    await Future.delayed(const Duration(seconds: 2));
    print('✅ Game Bar recording should be active');
  }

  /// Stop recording
  static Future<void> stopRecording() async {
    print('🛑 Stopping Windows Game Bar recording...');

    await Process.run('powershell', [
      '-Command',
      '''
      Add-Type -AssemblyName System.Windows.Forms
      [System.Windows.Forms.SendKeys]::SendWait("^%r")
      '''
    ]);

    print('✅ Recording stopped');
    print('📁 Videos saved to: ~/Videos/Captures/');
  }
}
