import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rtmp_broadcaster/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tv_app/utils/audio_manager.dart';
import 'package:tv_app/widgets/volume_indicator.dart';

/// Overall lifecycle state of the camera page.
/// The page steps through these before showing the camera UI.
enum _PageState {
  checkingConnection, // Step 1 – TCP reachability test against RTMP host:port
  connectionFailed, // TCP check failed – show error + retry
  requestingPermissions,
  permissionDenied,
  initializingCamera, // Camera hardware init (also reused on lifecycle resume)
  cameraError,
  cameraReady, // Camera live – streaming controls are visible
}

/// Streaming-specific overlay status (only relevant in [_PageState.cameraReady]).
enum _StreamStatus { idle, connecting, connected, retrying, error, stopped }

class CameraPage extends StatefulWidget {
  /// The full RTMP stream URL (e.g. rtmp://192.168.1.1:1935/live/mystream).
  final String streamUrl;

  /// When true the stream starts automatically once the camera is ready.
  final bool autoStart;

  /// Target video bitrate in bits-per-second. Defaults to 1.2 Mbps.
  final int bitrate;

  const CameraPage({
    super.key,
    required this.streamUrl,
    this.autoStart = false,
    this.bitrate = 1200 * 1024,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  // ── Page state ───────────────────────────────────────────────────────────────
  _PageState _pageState = _PageState.checkingConnection;
  String? _pageError;

  // ── Camera ───────────────────────────────────────────────────────────────────
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isSwitchingCamera = false;

  /// Set to true inside [dispose] to prevent any async callback from touching
  /// the widget tree or controller after teardown.
  bool _isDisposed = false;

  // ── Streaming ────────────────────────────────────────────────────────────────
  bool _isStreaming = false;
  bool _isStreamingPaused = false;
  bool _isMuted = false;
  _StreamStatus _streamStatus = _StreamStatus.idle;
  String? _streamError;
  Timer? _connectionTimer;

  // ────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _checkConnection();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Pause the stream before releasing hardware.
      if (_isStreaming && !_isStreamingPaused) {
        debugPrint('Lifecycle: pausing stream');
        await _pauseStreaming();
      }
      // Release camera hardware to avoid black-screen on Android.
      if (_controller != null) {
        _controller!.removeListener(_onControllerUpdate);
        await _controller!.dispose();
        _controller = null;
        if (mounted) setState(() => _pageState = _PageState.initializingCamera);
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialise only if we previously tore down the controller.
      if (_controller == null &&
          _pageState == _PageState.initializingCamera &&
          !_isDisposed) {
        await _initCamera();
        if (_isStreaming && _isStreamingPaused) {
          debugPrint('Lifecycle: resuming stream');
          await _resumeStreaming();
        }
      }
    }
  }

  @override
  void dispose() {
    debugPrint('CameraPage: dispose');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _connectionTimer?.cancel();
    _connectionTimer = null;

    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      ctrl.removeListener(_onControllerUpdate);
      // Only stop the stream if one is actually running to avoid
      // CameraException("stopVideoStreaming was called when no video is streaming").
      final isStreaming = ctrl.value.isStreamingVideoRtmp ?? false;
      if (isStreaming) {
        ctrl
            .stopVideoStreaming()
            .catchError((_) {})
            .whenComplete(() => ctrl.dispose().catchError((_) {}));
      } else {
        ctrl.dispose().catchError((_) {});
      }
    }

    WakelockPlus.disable();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Step 1 – TCP connection check (no camera required)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _checkConnection() async {
    if (_isDisposed || !mounted) return;
    setState(() {
      _pageState = _PageState.checkingConnection;
      _pageError = null;
    });

    try {
      // Replace rtmp:// with http:// so Uri can parse host/port correctly.
      final uri = Uri.parse(
        widget.streamUrl.replaceFirst('rtmp://', 'http://'),
      );
      final host = uri.host;
      final port = uri.hasPort ? uri.port : 1935;

      if (host.isEmpty) {
        throw const SocketException('Invalid RTMP URL – no host found');
      }

      debugPrint('TCP check → $host:$port');
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
      socket.destroy();
      debugPrint('TCP check passed');

      if (_isDisposed || !mounted) return;
      await _requestPermissions();
    } on SocketException catch (e) {
      if (!mounted) return;
      setState(() {
        _pageState = _PageState.connectionFailed;
        _pageError = 'Cannot reach RTMP server:\n${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageState = _PageState.connectionFailed;
        _pageError = 'Connection error:\n$e';
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Step 2 – Permission request
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (_isDisposed || !mounted) return;
    setState(() {
      _pageState = _PageState.requestingPermissions;
      _pageError = null;
    });

    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (_isDisposed || !mounted) return;

    if (cameraStatus.isGranted && micStatus.isGranted) {
      await _initCamera();
    } else if (cameraStatus.isPermanentlyDenied ||
        micStatus.isPermanentlyDenied) {
      setState(() {
        _pageState = _PageState.permissionDenied;
        _pageError =
            'Camera/microphone permissions are permanently denied.\nPlease enable them in app settings.';
      });
    } else {
      setState(() {
        _pageState = _PageState.permissionDenied;
        _pageError = 'Camera and microphone permissions are required.';
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Step 3 – Camera initialisation
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (_isDisposed || !mounted) return;
    // Guard against re-entry (e.g. lifecycle resume while already initialising).
    if (_controller != null && _controller!.value.isInitialized == true) {
      debugPrint('_initCamera: controller already ready, skipping');
      return;
    }

    setState(() {
      _pageState = _PageState.initializingCamera;
      _pageError = null;
    });

    try {
      _cameras = await availableCameras();
      if (_isDisposed || !mounted) return;
      if (_cameras.isEmpty) throw Exception('No cameras found on this device');

      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        streamingPreset: ResolutionPreset.high,
        enableAudio: true,
        androidUseOpenGL: true,
      );

      await controller.initialize();

      // Check if the widget was disposed or page closed during the async gap.
      if (_isDisposed || !mounted) {
        await controller.dispose();
        return;
      }

      if (controller.value.isInitialized != true) {
        await controller.dispose();
        throw Exception('Camera failed to initialise');
      }

      _controller = controller;
      _controller!.addListener(_onControllerUpdate);

      setState(() => _pageState = _PageState.cameraReady);
      _syncMuteState();

      // Auto-start now that the server was already verified reachable.
      if (widget.autoStart && !_isDisposed && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_isDisposed) _toggleStreaming();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _pageState = _PageState.cameraError;
          _pageError = 'Failed to initialise camera:\n$e';
        });
      }
    }
  }

  Future<void> _syncMuteState() async {
    final isMuted = await AudioManager.isMicrophoneMute();
    if (mounted && !_isDisposed) setState(() => _isMuted = isMuted);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Controller update listener
  // ────────────────────────────────────────────────────────────────────────────

  void _onControllerUpdate() {
    if (_isDisposed || !mounted || _isSwitchingCamera) return;
    if (_controller == null || _controller!.value.isInitialized != true) return;

    // Keep _isStreaming flag in sync with the native layer.
    final bool actuallyStreaming =
        _controller!.value.isStreamingVideoRtmp ?? false;
    if (actuallyStreaming && !_isStreaming) {
      setState(() {
        _isStreaming = true;
        _streamStatus = _StreamStatus.connected;
      });
    } else if (!actuallyStreaming &&
        _isStreaming &&
        _streamStatus != _StreamStatus.connecting) {
      setState(() {
        _isStreaming = false;
        _isStreamingPaused = false;
      });
    }

    final event = _controller!.value.event;
    if (event == null) return;

    final String? eventType = event['eventType'] as String?;
    final String? errorDescription = event['errorDescription'] as String?;

    switch (eventType) {
      case 'rtmp_connected':
        debugPrint('RTMP connected');
        _connectionTimer?.cancel();
        _connectionTimer = null;
        setState(() {
          _streamStatus = _StreamStatus.connected;
          _streamError = null;
          _isStreaming = true;
        });

      case 'rtmp_retry':
        final msg = errorDescription ?? 'Unknown server error';
        debugPrint('RTMP retry: $msg');
        setState(() {
          _streamStatus = _StreamStatus.retrying;
          _streamError = msg;
        });
        _showErrorBanner('Connection lost – retrying: $msg');

      case 'rtmp_stopped':
        _connectionTimer?.cancel();
        _connectionTimer = null;
        final msg = errorDescription ?? 'Stream stopped by server';
        debugPrint('RTMP stopped: $msg');
        if (_isStreaming) {
          setState(() {
            _isStreaming = false;
            _streamStatus = _StreamStatus.stopped;
            _streamError = msg;
          });
          _showErrorBanner('Stream stopped: $msg');
        } else {
          setState(() {
            _streamStatus = _StreamStatus.idle;
            _streamError = null;
          });
        }

      case 'error':
        _connectionTimer?.cancel();
        _connectionTimer = null;
        final msg = errorDescription ?? 'Unknown error';
        debugPrint('RTMP error: $msg');
        setState(() {
          _isStreaming = false;
          _streamStatus = _StreamStatus.error;
          _streamError = msg;
        });
        _showErrorBanner('RTMP error: $msg');

      case 'camera_closing':
        _connectionTimer?.cancel();
        _connectionTimer = null;
        if (_isStreaming) {
          setState(() {
            _isStreaming = false;
            _streamStatus = _StreamStatus.idle;
          });
        }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Streaming control
  // ────────────────────────────────────────────────────────────────────────────

  void _startConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _isDisposed) return;
      if (_streamStatus == _StreamStatus.connecting ||
          _streamStatus == _StreamStatus.retrying) {
        debugPrint('RTMP: connection timed out after 30 s');
        setState(() {
          _isStreaming = false;
          _streamStatus = _StreamStatus.error;
          _streamError = 'Connection timed out after 30 s';
        });
        _showErrorBanner(
          'RTMP: No response from server after 30 s. Check URL and server.',
        );
        _controller?.stopVideoStreaming().catchError((_) {});
      }
    });
  }

  Future<void> _toggleStreaming() async {
    if (_controller == null || _controller!.value.isInitialized != true) return;

    if (_isStreaming) {
      try {
        await _controller!.stopVideoStreaming();
      } catch (e) {
        debugPrint('Stop streaming error: $e');
      }
      setState(() {
        _isStreaming = false;
        _isStreamingPaused = false;
        _streamStatus = _StreamStatus.idle;
        _streamError = null;
      });
      WakelockPlus.disable();
    } else {
      debugPrint('RTMP: initiating handshake');
      setState(() {
        _streamStatus = _StreamStatus.connecting;
        _streamError = null;
      });
      try {
        await _controller!.startVideoStreaming(
          widget.streamUrl,
          bitrate: widget.bitrate,
        );
        // _isStreaming flips to true via the 'rtmp_connected' event.
        _startConnectionTimer();
      } catch (e) {
        _connectionTimer?.cancel();
        _connectionTimer = null;
        final msg = e is CameraException
            ? (e.description ?? e.code)
            : e.toString();
        debugPrint('RTMP start error: $msg');
        setState(() {
          _streamStatus = _StreamStatus.error;
          _streamError = msg;
        });
        _showErrorBanner('Failed to connect (RTMP): $msg');
      }
    }
  }

  Future<void> _pauseStreaming() async {
    if (_controller == null ||
        !_isStreaming ||
        _isStreamingPaused ||
        _isDisposed)
      return;
    if (_controller!.value.isInitialized != true) return;
    try {
      await _controller!.pauseVideoStreaming();
      if (mounted) setState(() => _isStreamingPaused = true);
      debugPrint('Streaming paused');
    } catch (e) {
      debugPrint('Pause error: $e');
    }
  }

  Future<void> _resumeStreaming() async {
    if (_controller == null ||
        !_isStreaming ||
        !_isStreamingPaused ||
        _isDisposed)
      return;
    if (_controller!.value.isInitialized != true) return;
    try {
      await _controller!.resumeVideoStreaming();
      if (mounted) setState(() => _isStreamingPaused = false);
      debugPrint('Streaming resumed');
    } catch (e) {
      debugPrint('Resume error: $e');
    }
  }

  Future<void> _togglePauseResume() async {
    if (_isStreamingPaused) {
      await _resumeStreaming();
    } else {
      await _pauseStreaming();
    }
  }

  Future<void> _forceStopStreaming() async {
    debugPrint('Force stopping stream');
    _connectionTimer?.cancel();
    _connectionTimer = null;
    try {
      await _controller?.stopVideoStreaming().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Force stop error (ignored): $e');
    }
    if (mounted) {
      setState(() {
        _isStreaming = false;
        _isStreamingPaused = false;
        _streamStatus = _StreamStatus.idle;
        _streamError = null;
      });
      WakelockPlus.disable();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stream force stopped'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _controller == null ||
        _isStreaming ||
        _isSwitchingCamera)
      return;

    setState(() {
      _isSwitchingCamera = true;
      _pageState = _PageState.initializingCamera;
    });

    try {
      final currentDir = _controller!.description.lensDirection;
      final nextCamera = _cameras.firstWhere(
        (c) => c.lensDirection != currentDir,
        orElse: () => _cameras.first,
      );

      _controller!.removeListener(_onControllerUpdate);
      final old = _controller;
      _controller = null;
      await old?.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      if (_isDisposed || !mounted) return;

      final nc = CameraController(
        nextCamera,
        ResolutionPreset.high,
        streamingPreset: ResolutionPreset.high,
        enableAudio: true,
        androidUseOpenGL: true,
      );

      await nc.initialize();
      if (_isDisposed || !mounted) {
        await nc.dispose();
        return;
      }
      if (nc.value.isInitialized != true) {
        await nc.dispose();
        throw Exception('New camera failed to initialise');
      }

      _controller = nc;
      _controller!.addListener(_onControllerUpdate);
      debugPrint('Camera switched successfully');
    } catch (e) {
      debugPrint('Camera switch error: $e');
      _showErrorBanner('Failed to switch camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _pageState = _PageState.cameraReady;
          _isSwitchingCamera = false;
        });
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  void _showErrorBanner(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> _toggleMute() async {
    final newState = !_isMuted;
    await AudioManager.setMicrophoneMute(newState);
    if (mounted) setState(() => _isMuted = newState);
  }

  Color get _fabColor {
    switch (_streamStatus) {
      case _StreamStatus.connecting:
      case _StreamStatus.retrying:
        return Colors.orange;
      case _StreamStatus.connected:
        return Colors.red;
      case _StreamStatus.error:
      case _StreamStatus.stopped:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Status badge
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildStatusBadge() {
    switch (_streamStatus) {
      case _StreamStatus.connecting:
        return _badge(Colors.orange, child: _spinnerRow('CONNECTING (RTMP)'));
      case _StreamStatus.retrying:
        return _badge(
          Colors.deepOrange,
          child: _labelColumn('RETRYING (RTMP)', _streamError),
        );
      case _StreamStatus.connected:
        return _badge(
          _isStreamingPaused ? Colors.orange : Colors.red,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isStreamingPaused ? Icons.pause_circle : Icons.circle,
                color: Colors.white,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                _isStreamingPaused ? 'PAUSED · RTMP' : 'LIVE · RTMP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case _StreamStatus.error:
      case _StreamStatus.stopped:
        return _badge(
          Colors.black54,
          child: _labelColumn('DISCONNECTED (RTMP)', _streamError),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _spinnerRow(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ],
  );

  Widget _labelColumn(String title, String? subtitle) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
    ],
  );

  Widget _badge(Color color, {required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Scaffold helpers for pre-camera states
  // ────────────────────────────────────────────────────────────────────────────

  Widget _loadingScaffold(String message) => Scaffold(
    appBar: AppBar(title: const Text('Live Stream · RTMP')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );

  Widget _errorScaffold(
    String message, {
    required VoidCallback onRetry,
    String retryLabel = 'Retry',
  }) => Scaffold(
    appBar: AppBar(title: const Text('Live Stream · RTMP')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    ),
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Render the appropriate screen for each pre-camera state.
    switch (_pageState) {
      case _PageState.checkingConnection:
        return _loadingScaffold('Checking connection to server…');

      case _PageState.connectionFailed:
        return _errorScaffold(
          _pageError ?? 'Could not reach the RTMP server.',
          onRetry: _checkConnection,
        );

      case _PageState.requestingPermissions:
        return _loadingScaffold('Requesting permissions…');

      case _PageState.permissionDenied:
        final isPermanent = _pageError?.contains('permanently') ?? false;
        return _errorScaffold(
          _pageError ?? 'Permissions denied.',
          onRetry: isPermanent
              ? () async => openAppSettings()
              : _requestPermissions,
          retryLabel: isPermanent ? 'Open Settings' : 'Grant Permissions',
        );

      case _PageState.initializingCamera:
        return _loadingScaffold('Initialising camera…');

      case _PageState.cameraError:
        return _errorScaffold(
          _pageError ?? 'Camera error.',
          onRetry: _initCamera,
        );

      case _PageState.cameraReady:
        break; // Fall through to camera UI.
    }

    // Safety net – should not normally occur.
    if (_controller == null || _controller!.value.isInitialized != true) {
      return _loadingScaffold('Starting camera…');
    }

    final bool isBusy =
        _streamStatus == _StreamStatus.connecting ||
        _streamStatus == _StreamStatus.retrying;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stream · RTMP'),
        actions: [
          if (_isStreaming)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              color: Colors.red,
              tooltip: 'Force Stop',
              onPressed: _forceStopStreaming,
            ),
          if (!_isStreaming)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: _isSwitchingCamera ? null : _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Streaming status badge (top-right)
          Positioned(top: 20, right: 20, child: _buildStatusBadge()),

          // Volume indicator while live (top-left)
          if (_streamStatus == _StreamStatus.connected && !_isStreamingPaused)
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: _toggleMute,
                child: VolumeIndicator(
                  isStreaming: _isStreaming,
                  isMuted: _isMuted,
                ),
              ),
            ),

          // Mute toggle when idle (top-left)
          if (!_isStreaming)
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.redAccent : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: _toggleMute,
              ),
            ),

          // Stream controls (bottom-centre)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isStreaming) ...[
                  FloatingActionButton(
                    heroTag: 'pause',
                    backgroundColor: Colors.orange,
                    onPressed: isBusy ? null : _togglePauseResume,
                    child: Icon(
                      _isStreamingPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                FloatingActionButton(
                  heroTag: 'stream',
                  backgroundColor: _fabColor,
                  onPressed: isBusy ? null : _toggleStreaming,
                  child: isBusy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isStreaming ? Icons.stop : Icons.videocam,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
