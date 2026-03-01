# TV App - RTMP Live Streaming Application

## Overview
This is a Flutter mobile application that enables live video streaming to RTMP servers. It's designed for camera-based streaming with audio, featuring real-time volume indicators, mute controls, and connection management.

## App Architecture

### Core Pages
1. **SetupPage** (`lib/pages/setup_page.dart`)
   - Entry point for the app
   - Allows users to configure RTMP server URL and stream key
   - Saves settings using SharedPreferences
   - Two modes: "LAUNCH CAMERA PREVIEW" (test mode) and "CONNECT & STREAM" (auto-start streaming)

2. **CameraPage** (`lib/pages/camera_page.dart`)
   - Main streaming interface
   - Handles camera initialization, preview, and RTMP streaming
   - Manages app lifecycle (handles screen lock/unlock, background/foreground transitions)
   - Features connection testing, auto-retry logic, and connection timeout handling
   - Parameters:
     - `streamUrl`: Full RTMP URL with stream key
     - `autoStart`: Whether to auto-start streaming when camera is ready
     - `testConnection`: Whether to test connection only without streaming

### Widgets
1. **VolumeIndicator** (`lib/widgets/volume_indicator.dart`)
   - Visual representation of microphone volume levels
   - Real-time audio level monitoring

### Utils
1. **AudioManager** (`lib/utils/audio_manager.dart`)
   - Manages microphone mute/unmute functionality
   - Platform-specific audio control

## Key Features

### 1. Camera & Streaming
- Uses `rtmp_broadcaster` package (v2.3.4) for RTMP streaming
- Camera resolution: High preset for both preview and streaming
- OpenGL rendering enabled for Android
- Audio enabled by default

### 2. Permission Handling
- **Required Permissions:**
  - Camera (CAMERA)
  - Microphone (RECORD_AUDIO)
  - Internet (INTERNET)
  - Audio Settings Modification (MODIFY_AUDIO_SETTINGS)
- Runtime permission requests using `permission_handler`
- Graceful handling of denied/permanently denied permissions
- User can open app settings if permissions are permanently denied

### 3. App Lifecycle Management
- **WakelockPlus**: Keeps screen on during streaming to prevent camera blackout
- **WidgetsBindingObserver**: Monitors app lifecycle states
- **Lifecycle States:**
  - `paused/inactive`: Pauses stream, disposes camera (releases hardware)
  - `resumed`: Re-initializes camera and resumes stream if it was active

### 4. Connection Management
- **Connection States:**
  - `idle`: No active connection
  - `connecting`: Attempting to connect to RTMP server
  - `connected`: Successfully streaming
  - `retrying`: Connection lost, attempting to reconnect
  - `error`: Connection failed
  - `stopped`: Stream stopped by server or user

- **Timeout Handling:**
  - Test mode: 60 seconds
  - Streaming mode: 160 seconds
  - Shows clear error messages on timeout

### 5. Audio Features
- Mute/unmute toggle
- Real-time volume level indicator
- Persistent mute state across app lifecycle

## Dependencies

```yaml
dependencies:
  rtmp_broadcaster: ^2.3.4          # RTMP streaming
  shared_preferences: ^2.5.4        # Settings persistence
  wakelock_plus: ^1.2.8             # Prevent screen sleep
  permission_handler: ^11.3.1       # Runtime permissions
  package_info_plus: ^9.0.0         # App info
```

## Common Issues & Solutions

### Issue 1: "Failed to initialize camera"
**Causes:**
1. Missing runtime permissions (Camera/Microphone)
2. Another app is using the camera
3. Device has no camera
4. Camera hardware issue

**Solutions:**
- Ensure permissions are granted at runtime (app now requests them automatically)
- Close other apps using the camera
- Check device camera functionality
- Review error messages in debug console for specific details

**Code Location:** [lib/pages/camera_page.dart](lib/pages/camera_page.dart#L96-L170)

### Issue 2: Camera preview goes black after screen lock
**Cause:** Camera resources not properly released/re-acquired during app lifecycle changes

**Solution:** Already implemented in `didChangeAppLifecycleState`:
- Disposes camera when app goes to background
- Re-initializes camera when app returns to foreground
- Automatically resumes streaming if it was active

**Code Location:** [lib/pages/camera_page.dart](lib/pages/camera_page.dart#L67-L93)

### Issue 3: Connection timeout or retry loops
**Causes:**
1. Incorrect RTMP URL or stream key
2. RTMP server not running or unreachable
3. Network issues
4. Firewall blocking RTMP port (usually 1935)

**Solutions:**
- Verify RTMP server is running (e.g., nginx-rtmp, MediaMTX)
- Check URL format: `rtmp://IP:PORT/APPLICATION/STREAMKEY`
- Test network connectivity
- Check server logs for connection attempts
- Ensure port 1935 is open if using default RTMP port

### Issue 4: Audio not working or mute not persisting
**Cause:** Audio manager not properly initializing or state not syncing

**Solution:** Check AudioManager implementation and ensure:
- MODIFY_AUDIO_SETTINGS permission is granted
- Mute state is checked on camera page init
- Volume indicator is properly receiving audio levels

## Development Guidelines

### Adding New Features
1. **UI Components:** Create widgets in `lib/widgets/`
2. **Utility Functions:** Add to `lib/utils/`
3. **New Pages:** Add to `lib/pages/`
4. **Update this file:** Document changes for future AI agents

### Code Style
- Use meaningful variable names
- Add debug prints for important lifecycle events
- Handle mounted checks before setState
- Dispose controllers and listeners properly
- Use async/await for async operations
- Add null checks for optional values

### Testing
- Test both "LAUNCH CAMERA PREVIEW" and "CONNECT & STREAM" modes
- Test app lifecycle (lock/unlock, background/foreground)
- Test connection timeouts with unreachable servers
- Test permission denial scenarios
- Test on different Android versions

## Platform-Specific Notes

### Android
- Minimum SDK: Check `android/app/build.gradle.kts`
- OpenGL rendering enabled for better performance
- Permissions defined in `android/app/src/main/AndroidManifest.xml`
- Lifecycle handling critical for camera resource management

### iOS
- Camera and microphone permissions: Update Info.plist with usage descriptions
- Background modes may need configuration for streaming

## RTMP Server Setup (for testing)

### Using MediaMTX
```bash
# Download and run MediaMTX
docker run --rm -it -p 1935:1935 -p 8554:8554 bluenviron/mediamtx
```

### Using nginx-rtmp
```nginx
rtmp {
    server {
        listen 1935;
        application live {
            live on;
            record off;
        }
    }
}
```

### App Configuration
- RTMP URL: `rtmp://192.168.1.75:1935/live`
- Stream Key: `mystream`
- Full URL: `rtmp://192.168.1.75:1935/live/mystream`

## Troubleshooting Commands

```bash
# Check Flutter doctor
flutter doctor -v

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check device logs (Android)
adb logcat | grep -i camera

# Check permissions (Android)
adb shell dumpsys package com.example.tv_app | grep permission
```

## Future Enhancements
- [ ] Multi-camera support (front/back switching)
- [ ] Video quality presets (low/medium/high)
- [ ] Stream health monitoring (dropped frames, bitrate)
- [ ] Recording to local storage
- [ ] Stream overlays (text, images)
- [ ] Network bandwidth adaptation
- [ ] Stream analytics and statistics
- [ ] Multiple streaming destinations simultaneously

## File Structure Reference
```
lib/
├── main.dart                 # App entry point, theme configuration
├── pages/
│   ├── setup_page.dart      # RTMP configuration and navigation
│   └── camera_page.dart     # Camera preview and streaming logic
├── widgets/
│   └── volume_indicator.dart # Audio level visualization
└── utils/
    └── audio_manager.dart    # Audio mute/unmute control
```

## Important Code Sections

### Permission Request Flow
[lib/pages/camera_page.dart](lib/pages/camera_page.dart#L96-L146) - `_requestPermissionsAndInitCamera()`

### Camera Initialization
[lib/pages/camera_page.dart](lib/pages/camera_page.dart#L172-L220) - `_initCamera()`

### Lifecycle Management
[lib/pages/camera_page.dart](lib/pages/camera_page.dart#L67-L93) - `didChangeAppLifecycleState()`

### Connection Event Handling
[lib/pages/camera_page.dart](lib/pages/camera_page.dart#L222-L290) - `_onControllerUpdate()`

---

**Last Updated:** March 1, 2026
**For AI Agents:** This document provides comprehensive context about the app's architecture, features, and common issues. Always check error logs and verify permissions first when debugging camera issues.
