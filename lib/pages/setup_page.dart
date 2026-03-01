import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  // ── RTMP ────────────────────────────────────────────────────────────────────
  final TextEditingController _rtmpUrlController = TextEditingController(
    text: 'rtmp://192.168.1.75:1935/live',
  );
  final TextEditingController _rtmpKeyController = TextEditingController(
    text: 'mystream',
  );

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Rebuild preview line when RTMP fields change.
    _rtmpUrlController.addListener(() => setState(() {}));
    _rtmpKeyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _rtmpUrlController.dispose();
    _rtmpKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // RTMP
    final rtmpUrl = prefs.getString('rtmpUrl');
    final rtmpKey = prefs.getString('streamKey');
    if (rtmpUrl != null) _rtmpUrlController.text = rtmpUrl;
    if (rtmpKey != null) _rtmpKeyController.text = rtmpKey;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rtmpUrl', _rtmpUrlController.text);
    await prefs.setString('streamKey', _rtmpKeyController.text);
  }

  void _goToCamera() async {
    if (_rtmpUrlController.text.isEmpty || _rtmpKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an RTMP URL and Stream Key'),
        ),
      );
      return;
    }

    final streamUrl =
        '${_rtmpUrlController.text.trimRight().replaceAll(RegExp(r'/+$'), '')}'
        '/${_rtmpKeyController.text.trim()}';

    setState(() => _isLoading = true);
    await _saveSettings();
    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraPage(streamUrl: streamUrl, autoStart: true),
      ),
    );
  }

  void _goToCameraOnly() async {
    if (_rtmpUrlController.text.isEmpty || _rtmpKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an RTMP URL and Stream Key'),
        ),
      );
      return;
    }

    final streamUrl =
        '${_rtmpUrlController.text.trimRight().replaceAll(RegExp(r'/+$'), '')}'
        '/${_rtmpKeyController.text.trim()}';

    setState(() => _isLoading = true);
    await _saveSettings();
    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraPage(
          streamUrl: streamUrl,
          autoStart: false,
          testConnection: true,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STREAM SETUP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.live_tv_rounded, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Ready to go live?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your RTMP endpoint details below.',
                style: TextStyle(fontSize: 14, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RtmpFields(
                urlController: _rtmpUrlController,
                keyController: _rtmpKeyController,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _goToCameraOnly,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.preview_rounded),
                label: const Text('LAUNCH CAMERA PREVIEW'),
                style: ElevatedButton.styleFrom(elevation: 0),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _goToCamera,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.stream),
                label: const Text('CONNECT & STREAM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── RTMP fields widget ────────────────────────────────────────────────────────

class _RtmpFields extends StatelessWidget {
  const _RtmpFields({required this.urlController, required this.keyController});

  final TextEditingController urlController;
  final TextEditingController keyController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'RTMP URL',
            hintText: 'rtmp://[ip]:[port]/[app]',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: keyController,
          decoration: const InputDecoration(
            labelText: 'Stream Key',
            hintText: 'e.g. mystream',
            prefixIcon: Icon(Icons.key),
          ),
        ),
      ],
    );
  }
}
