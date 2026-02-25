import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rtmp_broadcaster/camera.dart';

/// Represents the streaming connection state shown in the UI.
enum _StreamStatus { idle, connecting, connected, retrying, error, stopped }

class CameraPage extends StatefulWidget {
  /// The full stream URL.
  final String streamUrl;

  const CameraPage({super.key, required this.streamUrl});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isStreaming = false;
  bool _isInitializing = true;

  _StreamStatus _streamStatus = _StreamStatus.idle;
  String? _streamError;
  Timer? _connectionTimer;
  StreamSubscription? _streamStateSubscription;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          streamingPreset: ResolutionPreset.high,
        );
        await _controller!.initialize();
        _controller!.addListener(_onControllerUpdate);
        _setupStreamStateListener();
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  /// Listens to every CameraValue change and reacts to streaming lifecycle events.
  void _onControllerUpdate() {
    if (_controller == null || !mounted) return;

    final event = _controller!.value.event;
    if (event == null) return;

    final String? eventType = event['eventType'] as String?;
    final String? errorDescription = event['errorDescription'] as String?;
    const String proto = 'RTMP';

    switch (eventType) {
      case 'rtmp_connected':
        _connectionTimer?.cancel();
        _connectionTimer = null;
        setState(() {
          _streamStatus = _StreamStatus.connected;
          _streamError = null;
          _isStreaming = true;
        });

      case 'rtmp_retry':
        // Server rejected / dropped the connection; the plugin will retry.
        // Keep the timer running – if it fires the user gets a clear timeout msg.
        final msg = errorDescription ?? 'Unknown server error';
        debugPrint('$proto retry: $msg');
        setState(() {
          _streamStatus = _StreamStatus.retrying;
          _streamError = msg;
        });
        _showErrorBanner('Connection lost – retrying: $msg');

      case 'rtmp_stopped':
        _connectionTimer?.cancel();
        _connectionTimer = null;
        // Stream ended (either manually or because all retries were exhausted).
        final msg = errorDescription ?? 'Stream stopped by server';
        debugPrint('$proto stopped: $msg');
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
        debugPrint('$proto error: $msg');
        setState(() {
          _isStreaming = false;
          _streamStatus = _StreamStatus.error;
          _streamError = msg;
        });
        _showErrorBanner('$proto error: $msg');

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

  /// Sets up the RTMP stream state listener.
  void _setupStreamStateListener() {
    _streamStateSubscription?.cancel();

    _streamStateSubscription = RTMPBroadcaster.streamStateListener((status) {
      if (!mounted) return;

      switch (status) {
        case StreamState.CONNECTING:
          debugPrint("Step 1: RTMP Handshake initiated...");
          setState(() {
            _streamStatus = _StreamStatus.connecting;
            _streamError = null;
          });
          break;

        case StreamState.CONNECTED:
          debugPrint("Step 2: RTMP 'connect' and 'createStream' successful!");
          _connectionTimer?.cancel();
          _connectionTimer = null;
          setState(() {
            _streamStatus = _StreamStatus.connected;
            _streamError = null;
            _isStreaming = true;
          });
          break;

        case StreamState.DISCONNECTED:
          debugPrint("Connection closed.");
          _connectionTimer?.cancel();
          _connectionTimer = null;
          setState(() {
            _isStreaming = false;
            _streamStatus = _StreamStatus.stopped;
          });
          break;

        case StreamState.FAILED:
          debugPrint("Handshake failed. Check Server URL/Network.");
          _connectionTimer?.cancel();
          _connectionTimer = null;
          setState(() {
            _isStreaming = false;
            _streamStatus = _StreamStatus.error;
            _streamError = 'Handshake failed. Check Server URL/Network.';
          });
          _showErrorBanner(
            'RTMP handshake failed. Check server URL and network connection.',
          );
          break;
      }
    });
  }

  /// Starts a watchdog timer after calling [startVideoStreaming].
  void _startConnectionTimer() {
    _connectionTimer?.cancel();
    const timeout = Duration(seconds: 160);
    const String proto = 'RTMP';
    _connectionTimer = Timer(timeout, () {
      if (!mounted) return;
      // Only fire if we are still waiting (not yet connected).
      if (_streamStatus == _StreamStatus.connecting ||
          _streamStatus == _StreamStatus.retrying) {
        debugPrint('$proto connection timed out after ${timeout.inSeconds}s');
        setState(() {
          _isStreaming = false;
          _streamStatus = _StreamStatus.error;
          _streamError = 'Connection timed out after ${timeout.inSeconds}s';
        });
        _showErrorBanner(
          '$proto: No response from server after ${timeout.inSeconds}s. '
          'Check the URL/host and that the server is running.',
        );
        // Best-effort stop so the native side also cleans up.
        _controller?.stopVideoStreaming().catchError((_) {});
      }
    });
  }

  void _showErrorBanner(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _toggleStreaming() async {
    if (_controller == null || !_controller!.value.isInitialized!) return;

    if (_isStreaming) {
      try {
        await _controller!.stopVideoStreaming();
      } catch (e) {
        debugPrint('Stop streaming error: $e');
      }
      setState(() {
        _isStreaming = false;
        _streamStatus = _StreamStatus.idle;
        _streamError = null;
      });
    } else {
      setState(() {
        _streamStatus = _StreamStatus.connecting;
        _streamError = null;
      });
      try {
        await _controller!.startVideoStreaming(
          widget.streamUrl,
          bitrate: 1200 * 1024,
        );
        // _isStreaming flips to true via the 'rtmp_connected' event.
        // Start a watchdog in case the server never replies.
        _startConnectionTimer();
      } catch (e) {
        _connectionTimer?.cancel();
        _connectionTimer = null;
        debugPrint('Streaming Error: $e');
        final msg = e is CameraException
            ? (e.description ?? e.code)
            : e.toString();
        setState(() {
          _streamStatus = _StreamStatus.error;
          _streamError = msg;
        });
        _showErrorBanner('Failed to connect (RTMP): $msg');
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2 || _controller == null || _isStreaming) return;

    final currentCamera = _controller!.description;
    final nextCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => _cameras.first,
    );

    setState(() => _isInitializing = true);
    _controller!.removeListener(_onControllerUpdate);
    await _controller!.dispose();
    _controller = CameraController(
      nextCamera,
      ResolutionPreset.high,
      streamingPreset: ResolutionPreset.high,
    );
    await _controller!.initialize();
    _controller!.addListener(_onControllerUpdate);
    _setupStreamStateListener();
    setState(() => _isInitializing = false);
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _streamStateSubscription?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    if (_isStreaming) {
      _controller?.stopVideoStreaming();
    }
    _controller?.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color get _fabColor {
    switch (_streamStatus) {
      case _StreamStatus.connecting:
        return Colors.orange;
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

  Widget _buildStatusBadge() {
    const String proto = 'RTMP';

    switch (_streamStatus) {
      case _StreamStatus.connecting:
        return _badge(
          Colors.orange,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CONNECTING ($proto)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case _StreamStatus.retrying:
        return _badge(
          Colors.deepOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RETRYING ($proto)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (_streamError != null)
                Text(
                  _streamError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        );

      case _StreamStatus.connected:
        return _badge(
          Colors.red,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 12),
              const SizedBox(width: 8),
              Text(
                'LIVE · $proto',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISCONNECTED ($proto)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (_streamError != null)
                Text(
                  _streamError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(Color color, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_controller == null || !_controller!.value.isInitialized!) {
      return const Scaffold(
        body: Center(child: Text("Failed to initialize camera.")),
      );
    }

    final bool isBusy =
        _streamStatus == _StreamStatus.connecting ||
        _streamStatus == _StreamStatus.retrying;
    const String proto = 'RTMP';

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Stream · $proto'),
        actions: [
          if (!_isStreaming)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Status badge (top-right)
          Positioned(top: 20, right: 20, child: _buildStatusBadge()),

          // Stream control button (bottom-center)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
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
