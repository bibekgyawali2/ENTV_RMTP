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
        builder: (_) => CameraPage(streamUrl: streamUrl, autoStart: false),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Stream Configuration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _RtmpFields(
              urlController: _rtmpUrlController,
              keyController: _rtmpKeyController,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _goToCameraOnly,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade700,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect Only', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _goToCamera,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Connect & Start Streaming',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 24),
          ],
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
    final fullUrl =
        '${urlController.text.trimRight().replaceAll(RegExp(r'/+$'), '')}'
        '/${keyController.text.trim()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'RTMP URL',
            hintText: 'rtmp://[ip]:[port]/[app]',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: keyController,
          decoration: const InputDecoration(
            labelText: 'Stream Name / Key',
            hintText: 'e.g. mystream',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Full URL: $fullUrl',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
